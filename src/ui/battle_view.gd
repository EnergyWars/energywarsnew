class_name BattleView
extends Node2D

signal building_selected(id: int)
signal action_failed(message: String, world: Vector2)
signal build_mode_changed(kind: String)
signal camera_moved
signal mode_changed(mode: Mode)
signal scout_selected(active: bool)
signal pick_changed(pick: Pick)
signal status_mode_changed(active: bool)
signal notice_shown(message: String)

enum Mode { MOVE, CONNECT }
enum Gesture { NONE, BUILD, LINK_PENDING, LINK, TAP_PENDING, CUT_PENDING, CUT, PAN, PICK, STEER_PENDING, STEER }
enum Pick { NONE, LINK, FOCUS, FUEL }

const BEAM_REFRESH := 0.06
const PICK_SLACK := 14.0
const LINK_SNAP := 26.0
const TRAIL_LIFE := 0.22
const COVERAGE_REFRESH := 0.25
const WHEEL_ZOOM := 1.12
const INITIAL_ZOOM := 0.8
const AIM_SPEED := 10.0
const DEFAULT_AIM := -PI / 2.0
const BEAM_VISIBLE_FLOW := 1.5
const BEAM_MIN_FLOW := 0.05
const CULL_MARGIN := 120.0
const STICK_RADIUS := 90.0
const STICK_DEADZONE := 0.12
const STATUS_TEXT := 17
const STATUS_BADGE := 22
const STATUS_RING := 3.0

var battle: Battle
var fx := EffectPool.new(7)
var camera := Camera2D.new()
var tracker := GestureTracker.new()
var center := Vector2.ZERO
var zoom := INITIAL_ZOOM
var top_inset := 0.0
var bottom_inset := 0.0
var build_kind := ""
var build_repeat := false
var selected_id := -1
var scout_active := false
var pick := Pick.NONE
var pick_id := -1
var relocate_id := -1
var coverage_levels := PackedByteArray()
var gesture := Gesture.NONE
var mode := Mode.MOVE
var status_mode := false
var stick_origin := Vector2.INF
var stick_point := Vector2.INF
var stick_vector := Vector2.ZERO
var ghost := Vector2.ZERO
var link_source := -1
var link_end := Vector2.ZERO
var cut_last := Vector2.ZERO
var trail: Array[Dictionary] = []
var clock := 0.0
var _beams := {}
var _beam_timer := 0.0
var _aims := {}
var _enemy_index := {}
var _camera_reported := false
var _coverage_timer := 0.0
var _coverage_key := ""
var _terrain_painter: TerrainPainter
var _fog_texture: FogTexture
var _coverage_texture: CoverageTexture
var _slime_texture: SlimeTexture
var _rim_texture: SlimeTexture
var _slime_version := -1
var _terrain: Node2D
var _chunks := {}
var _coverage: DrawLayer
var _slime: DrawLayer
var _rim: DrawLayer
var _walls: DrawLayer
var _walls_version := -1
var _view_rect := Rect2()
var _world: DrawLayer
var _fog: DrawLayer
var _night: DrawLayer
var _night_shade := NightShade.new()
var _glow: DrawLayer
var _overlay: DrawLayer


func setup(p_battle: Battle) -> BattleView:
	battle = p_battle
	_terrain_painter = TerrainPainter.new(battle.state.map)
	_fog_texture = FogTexture.new(battle.state.fog)
	_coverage_texture = CoverageTexture.new(battle.state.map)
	_slime_texture = SlimeTexture.new(battle.state.map)
	_rim_texture = SlimeTexture.new(battle.state.map)
	_night_shade.bind(battle.lighting)
	return self


func _ready() -> void:
	_terrain = Node2D.new()
	add_child(_terrain)
	_terrain.add_child(DrawLayer.new().setup(_terrain_painter.paint_border))
	var counts := _terrain_painter.chunk_count()
	for y in counts.y:
		for x in counts.x:
			var chunk := Vector2i(x, y)
			var layer := DrawLayer.new().setup(func(ci: CanvasItem) -> void: _terrain_painter.paint_chunk(ci, chunk))
			_chunks[chunk] = layer
			_terrain.add_child(layer)
	_terrain.add_child(DrawLayer.new().setup(_terrain_painter.paint_frame))
	_slime = DrawLayer.new().setup(_paint_slime)
	_slime.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_slime)
	_coverage = DrawLayer.new().setup(_paint_coverage)
	_coverage.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_coverage)
	_walls = DrawLayer.new().setup(_paint_walls)
	add_child(_walls)
	_world = DrawLayer.new().setup(_paint_world)
	_fog = DrawLayer.new().setup(_paint_fog)
	_fog.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_fog.material = _fog_texture.material
	_night = DrawLayer.new().setup(_paint_night)
	_night.material = _night_shade.material
	_glow = DrawLayer.new().setup(_paint_glow)
	_overlay = DrawLayer.new().setup(_paint_overlay)
	_rim = DrawLayer.new().setup(_paint_rim)
	_rim.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	for layer in [_world, _fog, _rim, _night, _glow, _overlay]:
		add_child(layer)
	add_child(camera)
	camera.make_current()
	var core := battle.state.core()
	focus(core.position if core != null else battle.state.map.drop)


func terrain_changed(cell: Vector2i) -> void:
	for y in range(-1, 2):
		for x in range(-1, 2):
			var layer: DrawLayer = _chunks.get(_terrain_painter.chunk_of(cell + Vector2i(x, y)))
			if layer != null:
				layer.queue_redraw()


func chunk_count() -> int:
	return _chunks.size()


func view_size() -> Vector2:
	return get_viewport_rect().size


func world_rect() -> Rect2:
	var extent := view_size() / zoom
	return Rect2(center - extent * 0.5, extent)


func focus(world: Vector2) -> void:
	zoom = CameraMath.clamp_zoom(zoom, view_size(), battle.state.map.size)
	center = CameraMath.clamp_center(world, zoom, view_size(), battle.state.map.size)
	_apply_camera()


func _apply_camera() -> void:
	camera.position = center + fx.shake_offset()
	camera.zoom = Vector2(zoom, zoom)
	_view_rect = visible_world_rect()


func to_world(screen: Vector2) -> Vector2:
	return CameraMath.screen_to_world(screen, center, zoom, view_size())


func to_screen(world: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world


func set_build_kind(kind: String) -> void:
	build_kind = kind
	relocate_id = -1
	if not kind.is_empty():
		select(-1)
	build_mode_changed.emit(kind)


func set_mode(value: Mode, announce: bool = true) -> void:
	mode = value
	gesture = Gesture.NONE
	release_stick()
	trail.clear()
	if announce:
		mode_changed.emit(mode)


func toggle_mode() -> void:
	set_mode(Mode.CONNECT if mode == Mode.MOVE else Mode.MOVE)


func start_relocate(id: int) -> void:
	var building := battle.state.building(id)
	if building == null:
		return
	set_build_kind(building.kind)
	relocate_id = id


func is_relocating() -> bool:
	return relocate_id >= 0 and not build_kind.is_empty()


func start_pick(value: Pick, id: int) -> void:
	if battle.state.building(id) == null:
		value = Pick.NONE
	pick = value
	pick_id = id if value != Pick.NONE else -1
	pick_changed.emit(pick)


func cancel_pick() -> void:
	if pick != Pick.NONE:
		start_pick(Pick.NONE, -1)


func select(id: int) -> void:
	if id != pick_id:
		cancel_pick()
	selected_id = id
	building_selected.emit(id)


func set_status_mode(active: bool) -> void:
	if status_mode == active:
		return
	status_mode = active
	status_mode_changed.emit(active)


func toggle_status_mode() -> void:
	set_status_mode(not status_mode)


func can_steer() -> bool:
	if mode != Mode.MOVE or not build_kind.is_empty() or pick != Pick.NONE or battle.state.is_over():
		return false
	return scout_active or (selected_mobile() != null and battle.state.is_fighting())


func is_steering() -> bool:
	return gesture == Gesture.STEER_PENDING or gesture == Gesture.STEER


func steer_to(screen: Vector2) -> void:
	if stick_origin == Vector2.INF:
		stick_origin = screen
	var offset := screen - stick_origin
	if offset.length() > STICK_RADIUS:
		stick_origin = screen - offset.normalized() * STICK_RADIUS
		offset = screen - stick_origin
	stick_point = screen
	var vector := offset / STICK_RADIUS
	stick_vector = vector if vector.length() >= STICK_DEADZONE else Vector2.ZERO


func release_stick() -> void:
	stick_origin = Vector2.INF
	stick_point = Vector2.INF
	stick_vector = Vector2.ZERO


func selected_mobile() -> Building:
	var building := battle.state.building(selected_id)
	return building if building != null and building.is_player() and GameConfig.is_mobile(building.kind) else null


func set_scout_active(active: bool) -> void:
	var value := active and battle.state.scout != null and battle.state.scout.is_controllable()
	if value == scout_active:
		return
	scout_active = value
	scout_selected.emit(value)


func advance(delta: float) -> void:
	clock += delta
	fx.update(delta)
	_beam_timer -= delta
	if _beam_timer <= 0.0:
		_beam_timer = BEAM_REFRESH
		_refresh_beams()
	_update_aims(delta)
	_enemy_index.clear()
	for enemy in battle.state.enemies:
		_enemy_index[enemy.id] = enemy
	var now := clock
	trail = trail.filter(func(point: Dictionary) -> bool: return now - float(point.time) < TRAIL_LIFE)
	if selected_id >= 0 and battle.state.building(selected_id) == null:
		select(-1)
	if relocate_id >= 0 and battle.state.building(relocate_id) == null:
		set_build_kind("")
	var scout := battle.state.scout
	var controllable := battle.state.is_scouting() and scout != null and scout.is_controllable()
	if controllable != scout_active:
		set_scout_active(controllable)
	if is_steering() and not can_steer():
		gesture = Gesture.NONE
		release_stick()
	_update_coverage(delta)
	_night_shade.apply(battle.lighting.current(), darkness())
	_night_shade.refresh_glow()
	if _fog_texture.refresh():
		_fog.queue_redraw()
	if _slime_version != battle.state.creep.version:
		_slime_version = battle.state.creep.version
		sync_slime()
	_apply_camera()
	if _walls_version != battle.state.roster_version:
		_walls_version = battle.state.roster_version
		_walls.queue_redraw()
	for layer in [_world, _night, _glow, _overlay]:
		layer.queue_redraw()


func visible_world_rect() -> Rect2:
	var size := view_size() / maxf(zoom, 0.01)
	return Rect2(center - size * 0.5, size).grow(CULL_MARGIN)


func is_on_screen(point: Vector2, radius: float = 0.0) -> bool:
	return _view_rect.grow(radius).has_point(point)


func _segment_on_screen(from: Vector2, to: Vector2) -> bool:
	return _view_rect.intersects(Rect2(from, Vector2.ZERO).expand(to))


func coverage_mode() -> String:
	if not build_kind.is_empty() and build_kind != GameConfig.CORE and not GameConfig.is_wall(build_kind):
		return "build"
	if selected_mobile() != null:
		return "mobile"
	return ""


func _update_coverage(delta: float) -> void:
	var mode_key := coverage_mode()
	var key := "%s:%d:%d" % [mode_key, selected_id, relocate_id]
	_coverage_timer -= delta
	if key == _coverage_key and (_coverage_timer > 0.0 or mode_key.is_empty()):
		return
	_coverage_key = key
	_coverage_timer = COVERAGE_REFRESH
	match mode_key:
		"build":
			coverage_levels = Coverage.for_building(battle.state, relocate_id)
		"mobile":
			coverage_levels = Coverage.for_receiver(battle.state, selected_mobile())
		_:
			coverage_levels = PackedByteArray()
	_coverage_texture.update(coverage_levels)
	_coverage.queue_redraw()


func _refresh_beams() -> void:
	var fresh := {}
	for link in battle.state.links:
		var points := battle.state.link_points(link)
		if not _segment_on_screen(points[0], points[1]) or beam_visibility(link) <= 0.0:
			continue
		var flow := _flow_ratio(link)
		fresh[link.key()] = Lightning.path(points[0], points[1], 5.0 + 9.0 * flow, fx.rng)
	_beams = fresh


func beam_visibility(link: EnergyLink) -> float:
	return clampf((link.flow - BEAM_MIN_FLOW) / BEAM_VISIBLE_FLOW, 0.0, 1.0)


func _flow_ratio(link: EnergyLink) -> float:
	var source := battle.state.building(link.source)
	if source == null:
		return 0.0
	return clampf(link.flow / maxf(Formulas.beam_rate(source, battle.state.outgoing_count(source.id)), 0.001), 0.0, 1.0)


func _update_aims(delta: float) -> void:
	for building in battle.state.combatants():
		if not building.armed:
			continue
		var target := _target_position(building)
		var desired: float = (target - building.position).angle() if target != Vector2.INF else float(_aims.get(building.id, DEFAULT_AIM))
		var current := float(_aims.get(building.id, DEFAULT_AIM))
		_aims[building.id] = lerp_angle(current, desired, clampf(AIM_SPEED * delta, 0.0, 1.0))


func _target_position(building: Building) -> Vector2:
	if building.target_id < 0:
		return Vector2.INF
	if building.focus != null and building.focus.id == building.target_id:
		return building.focus.position
	var enemy: Enemy = _enemy_index.get(building.target_id)
	if enemy != null:
		return enemy.position
	var other := battle.state.building(building.target_id)
	return other.position if other != null else Vector2.INF


func _unhandled_input(event: InputEvent) -> void:
	if battle == null:
		return
	if event is InputEventScreenTouch:
		_on_touch(event as InputEventScreenTouch)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		_on_drag(event as InputEventScreenDrag)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		_on_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if motion.button_mask & (MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE):
			pan(-motion.relative / zoom)
	elif event is InputEventMagnifyGesture:
		var magnify := event as InputEventMagnifyGesture
		zoom_by(magnify.factor, magnify.position)
	elif event is InputEventPanGesture:
		pan((event as InputEventPanGesture).delta * 12.0 / zoom)


func in_ui_zone(screen: Vector2) -> bool:
	return screen.y < top_inset or screen.y > view_size().y - bottom_inset


func _on_touch(touch: InputEventScreenTouch) -> void:
	if touch.pressed:
		if not tracker.is_active() and in_ui_zone(touch.position):
			return
		if tracker.press(touch.index, touch.position):
			begin(to_world(touch.position), touch.position)
		else:
			gesture = Gesture.NONE
			trail.clear()
			release_stick()
		return
	var result := tracker.release(touch.index, touch.position)
	match str(result.get("kind", "")):
		GestureTracker.TAP:
			tap(to_world(touch.position))
		GestureTracker.DRAG_END:
			finish(to_world(touch.position))


func _on_drag(drag: InputEventScreenDrag) -> void:
	var result := tracker.move(drag.index, drag.position)
	match str(result.get("kind", "")):
		GestureTracker.PINCH:
			zoom_by(float(result.zoom), result.center)
			pan(-(result.pan as Vector2) / zoom)
		GestureTracker.DRAG:
			if is_steering():
				if bool(result.moved):
					gesture = Gesture.STEER
					steer_to(drag.position)
				return
			drag_to(to_world(drag.position), bool(result.moved), drag.relative)


func _on_mouse_button(button: InputEventMouseButton) -> void:
	if not button.pressed:
		return
	if button.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom_by(WHEEL_ZOOM, button.position)
	elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom_by(1.0 / WHEEL_ZOOM, button.position)


func zoom_by(factor: float, focus_screen: Vector2) -> void:
	var next := CameraMath.clamp_zoom(zoom * factor, view_size(), battle.state.map.size)
	center = CameraMath.zoom_at(center, zoom, next, focus_screen, view_size())
	zoom = next
	center = CameraMath.clamp_center(center, zoom, view_size(), battle.state.map.size)
	_report_camera()


func pan(offset: Vector2) -> void:
	center = CameraMath.clamp_center(center + offset, zoom, view_size(), battle.state.map.size)
	_report_camera()


func _report_camera() -> void:
	if not _camera_reported:
		_camera_reported = true
		camera_moved.emit()


func begin(world: Vector2, screen: Vector2 = Vector2.INF) -> void:
	battle.begin_stroke()
	cut_last = world
	trail.clear()
	if not build_kind.is_empty():
		gesture = Gesture.BUILD
		ghost = world
		return
	if mode == Mode.CONNECT and tracker.double:
		gesture = Gesture.PAN
		link_source = -1
		return
	if pick != Pick.NONE:
		gesture = Gesture.PICK
		link_source = -1
		return
	var building := battle.building_at(world, PICK_SLACK)
	if mode == Mode.MOVE:
		link_source = building.id if building != null else -1
		if screen != Vector2.INF and can_steer():
			gesture = Gesture.STEER_PENDING
			release_stick()
			stick_origin = screen
			return
		gesture = Gesture.TAP_PENDING if building != null else Gesture.CUT_PENDING
		return
	if building != null and EnergyNetwork.can_send(building):
		gesture = Gesture.LINK_PENDING
		link_source = building.id
		link_end = world
	elif building != null:
		gesture = Gesture.TAP_PENDING
		link_source = building.id
	else:
		gesture = Gesture.CUT_PENDING
		link_source = -1


func drag_to(world: Vector2, moved: bool, screen_delta: Vector2 = Vector2.ZERO) -> void:
	if gesture == Gesture.PAN:
		pan(-screen_delta / zoom)
		return
	if gesture == Gesture.PICK or (mode == Mode.MOVE and gesture != Gesture.BUILD):
		if moved and gesture != Gesture.NONE:
			gesture = Gesture.PAN
			pan(-screen_delta / zoom)
		return
	match gesture:
		Gesture.BUILD:
			ghost = world
		Gesture.LINK_PENDING:
			if moved:
				gesture = Gesture.LINK
				link_end = world
		Gesture.LINK:
			link_end = world
		Gesture.TAP_PENDING, Gesture.CUT_PENDING:
			if moved:
				gesture = Gesture.CUT
				_cut_to(world)
		Gesture.CUT:
			_cut_to(world)


func _cut_to(world: Vector2) -> void:
	battle.cut(cut_last, world)
	cut_last = world
	trail.append({"position": world, "time": clock})


func finish(world: Vector2) -> void:
	match gesture:
		Gesture.BUILD:
			place_at(world)
		Gesture.LINK:
			var target := link_target(world)
			if target != null and target.id != link_source:
				var reason := battle.connect_buildings(link_source, target.id)
				if reason != EnergyNetwork.OK:
					action_failed.emit(Texts.reason("link_" + reason), world)
	gesture = Gesture.NONE
	link_source = -1
	release_stick()
	battle.end_stroke()


func tap(world: Vector2) -> void:
	match gesture:
		Gesture.BUILD:
			place_at(world)
		Gesture.PICK:
			resolve_pick(world)
		Gesture.LINK_PENDING, Gesture.TAP_PENDING:
			select(link_source if link_source != selected_id else -1)
		Gesture.CUT_PENDING:
			_tap_ground(world)
		Gesture.STEER_PENDING:
			if link_source >= 0:
				select(link_source if link_source != selected_id else -1)
			else:
				_tap_ground(world)
	gesture = Gesture.NONE
	link_source = -1
	release_stick()
	battle.end_stroke()


func _tap_ground(world: Vector2) -> void:
	if not scout_active:
		select(-1)
		return
	var reason := battle.walk_scout(world)
	if reason != ScoutControl.OK and reason != ScoutControl.NOTHING:
		action_failed.emit(Texts.reason("scout_" + reason), world)


func resolve_pick(world: Vector2) -> void:
	match pick:
		Pick.LINK:
			var target := link_target(world)
			if target == null or target.id == pick_id:
				cancel_pick()
				return
			var reason := battle.connect_buildings(pick_id, target.id)
			if reason != EnergyNetwork.OK:
				action_failed.emit(Texts.reason("link_" + reason), world)
				return
			cancel_pick()
		Pick.FOCUS:
			var candidate := battle.focus_candidate(world, PICK_SLACK)
			if candidate == null:
				cancel_pick()
				return
			var reason := battle.focus(pick_id, candidate)
			if reason != Combat.OK:
				action_failed.emit(Texts.reason("focus_" + reason), world)
				return
			cancel_pick()
		Pick.FUEL:
			_mark_fuel(world)


func _mark_fuel(world: Vector2) -> void:
	var fire := battle.state.building(pick_id)
	var cell := battle.state.map.cell_of(world)
	if fire == null or (not fire.fuel.has(cell) and battle.state.map.tile(cell) != LevelMap.Tile.TREE):
		cancel_pick()
		return
	var reason := battle.toggle_fuel(pick_id, cell)
	if reason != FuelControl.OK:
		action_failed.emit(Texts.reason("fuel_" + reason), world)


func clear_with_scout(world: Vector2) -> void:
	var reason := battle.clear_with_scout(world)
	if reason != ScoutControl.OK:
		action_failed.emit(Texts.reason("scout_" + reason), world)


func place_at(world: Vector2) -> void:
	if is_relocating():
		var id := relocate_id
		var moved := battle.relocate(id, world)
		if moved != BuildRules.OK:
			action_failed.emit(Texts.reason("build_" + moved), world)
			return
		set_build_kind("")
		select(id)
		return
	var reason := battle.place(build_kind, world)
	if reason == BuildRules.SCOUT_FAR and battle.walk_scout(world) == ScoutControl.OK:
		notice_shown.emit(Texts.t("TOAST_SCOUT_WALKS"))
		return
	if reason != BuildRules.OK:
		action_failed.emit(Texts.reason("build_" + reason), world)
		return
	if build_kind.is_empty() or build_kind == GameConfig.CORE:
		return
	if not build_repeat or not battle.state.can_afford(Formulas.build_cost(battle.state, build_kind)):
		set_build_kind("")


func link_target(world: Vector2) -> Building:
	var target := battle.building_at(world, LINK_SNAP)
	return target if target != null and target.is_player() else null


func _paint_coverage(ci: CanvasItem) -> void:
	if coverage_levels.is_empty():
		return
	ci.draw_texture_rect(_coverage_texture.texture, Rect2(Vector2.ZERO, battle.state.map.size), false)


func _paint_walls(ci: CanvasItem) -> void:
	for building in battle.state.of_kind(GameConfig.BULWARK):
		Painter.building(ci, building.kind, building.position, building.radius(), 0.0)


func _paint_world(ci: CanvasItem) -> void:
	var state := battle.state
	var light := state.light()
	for building in state.of_kind(GameConfig.SHIELD):
		if building.energy > 1.0:
			var fill := building.energy / Formulas.capacity(building)
			ci.draw_circle(building.position, Formulas.shield_radius(building), Color(AppTheme.SHIELD_BLUE, 0.05 + 0.06 * fill))
	if build_kind == GameConfig.CORE and state.scout != null:
		ci.draw_circle(state.scout.position, GameConfig.CORE_DEPLOY_RANGE, Color(1, 1, 1, 0.06))
		for building in state.enemy_buildings():
			if state.fog.is_explored_at(building.position):
				ci.draw_circle(building.position, building.half_extent() + GameConfig.CORE_ENEMY_CLEAR, Color(AppTheme.DANGER, 0.08))
	elif not build_kind.is_empty():
		for building in state.player_buildings():
			if Formulas.build_radius(building) > 0.0:
				ci.draw_circle(building.position, Formulas.build_radius(building), Color(1, 1, 1, 0.05))
		var clearance := BuildRules.enemy_clearance(state)
		for building in state.enemy_buildings():
			if state.fog.is_explored_at(building.position):
				ci.draw_circle(building.position, building.half_extent() + clearance, Color(AppTheme.DANGER, 0.1))
	for building: Building in state.buildings.values():
		if building.kind == GameConfig.BULWARK or not is_on_screen(building.position, building.half_extent()):
			continue
		Painter.building(ci, building.kind, building.position, building.radius(), clock, paint_fill(building), float(_aims.get(building.id, DEFAULT_AIM)), light)
	for fire in state.of_kind(GameConfig.FIRE):
		_paint_fuel(ci, fire)
	for pickup in state.pickups:
		if not is_on_screen(pickup.position):
			continue
		var bob := sin(clock * 8.0 + pickup.position.x) * 2.0
		Painter.coin(ci, pickup.position + Vector2(0, bob), 7.0, clock + pickup.position.y)
	_paint_nests(ci)
	_paint_rest(ci, light)


func paint_fill(building: Building) -> float:
	if building.exporting:
		return Formulas.export_progress(building)
	if building.burner:
		return 0.0 if building.fuel.is_empty() else 1.0
	if building.lighting:
		return 1.0 if building.lit else 0.0
	var capacity := Formulas.capacity(building)
	return building.energy / capacity if capacity > 0.0 else 0.0


func _paint_fuel(ci: CanvasItem, fire: Building) -> void:
	var map := battle.state.map
	for cell in fire.fuel:
		var center := map.center_of(cell)
		if not is_on_screen(center, GameConfig.CELL):
			continue
		if cell == fire.burn_cell:
			Painter.flames(ci, center + Vector2(0, GameConfig.CELL * 0.1), GameConfig.CELL * 0.32, clock + cell.x * 0.7 + cell.y * 0.3)
			Painter.bar(ci, center + Vector2(0, -GameConfig.CELL * 0.55), GameConfig.CELL * 0.8, battle.fuel.burn_ratio(fire), AppTheme.FLAME, 5.0)
		else:
			ci.draw_arc(center, GameConfig.CELL * 0.42, 0.0, TAU, 24, Color(AppTheme.FLAME, 0.75), 3.0, true)
			ci.draw_circle(center + Vector2(0, -GameConfig.CELL * 0.3), 4.0, AppTheme.FLAME_CORE)


func _paint_rest(ci: CanvasItem, light: float) -> void:
	var state := battle.state
	for projectile in state.projectiles:
		ci.draw_circle(projectile.position(), 8.0, AppTheme.SHADOW)
	for enemy in state.enemies:
		if is_on_screen(enemy.position) and shows_enemy(enemy):
			Painter.enemy(ci, enemy.kind, enemy.position, enemy.radius(), enemy.heading, clock + enemy.id * 0.37, 1.0 - light)
			if enemy.is_burning():
				Painter.flames(ci, enemy.position, enemy.radius(), clock + enemy.id * 0.53, 1.4 if enemy.is_guard() else 1.0)
			elif enemy.is_guard():
				Painter.guard(ci, enemy.position, enemy.radius(), clock + enemy.id * 0.29)
	for building in state.enemy_buildings():
		_paint_immune(ci, building)
	var core := state.core()
	if core != null:
		_paint_immune(ci, core)
	_paint_scout(ci)


func _paint_immune(ci: CanvasItem, building: Building) -> void:
	if building.immune and is_on_screen(building.position, building.half_extent() + 20.0):
		var pulse := 0.5 + 0.5 * sin(clock * 2.5 + building.id)
		ci.draw_arc(building.position, building.half_extent() + 14.0 + pulse * 4.0, 0.0, TAU, 48, Color(AppTheme.IMMUNE, 0.35 + 0.3 * pulse), 4.0, true)


func _paint_scout(ci: CanvasItem) -> void:
	var scout := battle.state.scout
	if scout == null:
		return
	if scout.boarded:
		var core := battle.state.core()
		if core != null:
			Painter.scout(ci, core.position, scout.heading, clock, 0.0, false)
		return
	if scout_active:
		_paint_clearable(ci, scout)
	if scout.is_walking():
		_paint_route(ci, scout)
	if scout.is_clearing():
		var target := battle.state.map.center_of(scout.clear_cell)
		ci.draw_arc(target, GameConfig.CELL * 0.55, 0.0, TAU, 32, Color(AppTheme.GOLD, 0.8), 3.0, true)
		Painter.bar(ci, target + Vector2(0, -GameConfig.CELL * 0.6), GameConfig.CELL * 0.9, battle.scouting.clear_ratio(), AppTheme.GOLD, 5.0)
	if scout_active:
		var pulse := 1.0 + 0.08 * sin(clock * 6.0)
		ci.draw_arc(scout.position, 22.0 * pulse, 0.0, TAU, 32, AppTheme.ENERGY_CORE, 3.0, true)
	Painter.scout(ci, scout.position, scout.heading, clock, scout.drop_ratio(), scout.is_clearing() and not scout.is_moving())


func _paint_route(ci: CanvasItem, scout: Scout) -> void:
	var from := scout.position
	for point in scout.route:
		_dashed_line(ci, from, point, Color(AppTheme.ENERGY_CORE, 0.6))
		from = point
	if scout.pending_cell != Scout.NO_CELL:
		_crosshair(ci, battle.state.map.center_of(scout.pending_cell), GameConfig.CELL * 0.45, AppTheme.GOLD)
	else:
		ci.draw_arc(scout.destination(), 12.0, 0.0, TAU, 20, AppTheme.ENERGY_CORE, 3.0, true)


func _paint_clearable(ci: CanvasItem, scout: Scout) -> void:
	var map := battle.state.map
	var origin := map.cell_of(scout.position)
	var span := int(ceil(GameConfig.CLEAR_REACH))
	for y in range(-span, span + 1):
		for x in range(-span, span + 1):
			var cell := origin + Vector2i(x, y)
			if cell != scout.clear_cell and map.is_clearable(cell) and battle.scouting.in_reach(cell):
				ci.draw_arc(map.center_of(cell), GameConfig.CELL * 0.45, 0.0, TAU, 24, Color(AppTheme.GOLD, 0.35 + 0.15 * sin(clock * 5.0)), 2.0, true)


func sync_slime() -> void:
	_slime_texture.update(battle.state.map.slime)
	_rim_texture.update(battle.state.map.sealed)
	_slime.queue_redraw()
	_rim.queue_redraw()


func _paint_slime(ci: CanvasItem) -> void:
	ci.draw_texture_rect(_slime_texture.texture, Rect2(Vector2.ZERO, battle.state.map.size), false)


func _paint_rim(ci: CanvasItem) -> void:
	ci.draw_texture_rect(_rim_texture.texture, Rect2(Vector2.ZERO, battle.state.map.size), false)


func _paint_nests(ci: CanvasItem) -> void:
	var fog := battle.state.fog
	for nest in battle.state.creep.alive_nests():
		if is_on_screen(nest.position, GameConfig.CELL) and fog.is_explored_at(nest.position):
			Painter.creep_nest(ci, nest.position, GameConfig.CELL * 0.8, clock)


func _paint_fog(ci: CanvasItem) -> void:
	ci.draw_texture_rect(_fog_texture.texture, Rect2(Vector2.ZERO, battle.state.map.size), false)


func darkness() -> float:
	return 1.0 - battle.state.light()


func reveals(target: Object) -> bool:
	return battle.lighting.sees(target.position, float(target.radius()))


func shows_enemy(enemy: Enemy) -> bool:
	return battle.state.fog.is_visible(enemy.position) and reveals(enemy)


func _paint_night(ci: CanvasItem) -> void:
	var dark := darkness()
	if dark <= 0.01:
		return
	var size := battle.state.map.size
	ci.draw_rect(Rect2(Vector2(-2000, -2000), size + Vector2(4000, 4000)), Color.WHITE)


func _paint_glow(ci: CanvasItem) -> void:
	var state := battle.state
	var dark := darkness()
	for link in state.links:
		if status_mode and not touches_selected(link):
			continue
		var straight := state.link_points(link)
		if not _segment_on_screen(straight[0], straight[1]):
			continue
		if mode == Mode.CONNECT:
			_dashed_line(ci, straight[0], straight[1], Color(AppTheme.ENERGY, 0.45))
		var visible := beam_visibility(link)
		if visible <= 0.0:
			continue
		var points: PackedVector2Array = _beams.get(link.key(), straight)
		var flow := _flow_ratio(link)
		ci.draw_polyline(points, Color(AppTheme.ENERGY, (0.1 + 0.12 * flow + 0.08 * dark) * visible), 16.0 + 10.0 * flow, true)
		ci.draw_polyline(points, Color(AppTheme.ENERGY, (0.5 + 0.4 * flow) * visible), 5.0 + 3.0 * flow, true)
		ci.draw_polyline(points, Color(AppTheme.ENERGY_CORE, (0.55 + 0.45 * flow) * visible), 2.0 + flow, true)
		for i in 3:
			var t := fposmod(clock * (0.5 + 1.4 * flow) + i / 3.0, 1.0)
			ci.draw_circle(straight[0].lerp(straight[1], t), (3.0 + 2.0 * flow) * visible, AppTheme.ENERGY_CORE)
	for building in state.player_buildings():
		if building.kind == GameConfig.BULWARK or not is_on_screen(building.position):
			continue
		if building.kind == GameConfig.LASER and building.firing:
			var target := _target_position(building)
			if target != Vector2.INF:
				var color := AppTheme.building_color(GameConfig.LASER)
				var flicker := 0.8 + 0.2 * sin(clock * 60.0)
				ci.draw_line(building.position, target, Color(color, 0.25 * flicker), 12.0, true)
				ci.draw_line(building.position, target, Color(color, 0.9), 4.0, true)
				ci.draw_line(building.position, target, Color(1, 1, 1, 0.9), 1.5, true)
				ci.draw_circle(target, 7.0 * flicker, Color(1, 0.9, 0.9, 0.8))
		elif building.lighting and building.lit:
			ci.draw_circle(building.position, Formulas.lit_reach(building) * 0.6, Color(AppTheme.LAMP_LIGHT, 0.05 * dark))
			ci.draw_circle(building.position, building.radius() * 1.4, Color(AppTheme.LAMP_LIGHT, 0.25 * dark))
		elif building.burner and not building.fuel.is_empty():
			ci.draw_circle(building.position, building.radius() * 2.2, Color(AppTheme.FLAME, 0.08 + 0.1 * dark))
		elif dark > 0.2 and Formulas.glows(building):
			ci.draw_circle(building.position, building.radius() * 0.5, Color(AppTheme.building_color(building.kind), 0.12 * dark))
	if dark > 0.2:
		for enemy in state.enemies:
			if not is_on_screen(enemy.position) or not shows_enemy(enemy):
				continue
			var forward := enemy.heading * enemy.radius() * 0.95
			var side := enemy.heading.orthogonal() * enemy.radius() * 0.22
			for eye in [enemy.position + forward + side, enemy.position + forward - side]:
				ci.draw_circle(eye, maxf(enemy.radius() * 0.12, 1.8), Color(1.0, 0.3, 0.2, dark))
	for projectile in state.projectiles:
		var position := projectile.position() - Vector2(0, projectile.height())
		Painter.glow(ci, position, 7.0, AppTheme.PLASMA_ORANGE)
	for ring_item in fx.rings:
		var ratio := EffectPool.ratio(ring_item)
		var radius := lerpf(float(ring_item.to), float(ring_item.from), ratio)
		ci.draw_arc(ring_item.position, radius, 0.0, TAU, 40, Color(ring_item.color, ratio), float(ring_item.width) * (0.4 + ratio), true)
	for trail_item in fx.trails:
		var ratio := EffectPool.ratio(trail_item)
		ci.draw_line(trail_item.from, trail_item.to, Color(trail_item.color, ratio), float(trail_item.width), true)
	for bolt_item in fx.bolts:
		var ratio := EffectPool.ratio(bolt_item)
		ci.draw_polyline(bolt_item.points, Color(bolt_item.color, 0.3 * ratio), float(bolt_item.width) * 3.0, true)
		ci.draw_polyline(bolt_item.points, Color(bolt_item.color, ratio), float(bolt_item.width), true)
		ci.draw_polyline(bolt_item.points, Color(1, 1, 1, ratio), maxf(float(bolt_item.width) * 0.4, 1.0), true)
	for particle in fx.particles:
		var ratio := EffectPool.ratio(particle)
		ci.draw_circle(particle.position, float(particle.size) * (0.4 + 0.6 * ratio), Color(particle.color, ratio))


func _paint_overlay(ci: CanvasItem) -> void:
	var state := battle.state
	for building: Building in state.buildings.values():
		if not is_on_screen(building.position, building.half_extent()):
			continue
		if building.hp < building.max_hp() and (building.is_player() or reveals(building)):
			Painter.bar(ci, building.position + Vector2(0, -building.radius() - 12.0), building.radius() * 1.6, building.hp_ratio(), Painter.hp_color(building.hp_ratio()))
		if building.is_player() and GameConfig.uses_energy_actively(building.kind):
			var fill := building.energy / Formulas.capacity(building)
			Painter.bar(ci, building.position + Vector2(0, building.radius() + 9.0), building.radius() * 1.4, fill, AppTheme.ENERGY, 4.0)
			if not status_mode and building.energy < Targeting.needed_energy(building) and fmod(clock, 1.0) < 0.6:
				_icon(ci, Icons.BOLT, building.position + Vector2(0, -building.radius() - 30.0), 26, AppTheme.WARNING)
	for obstacle: Obstacle in state.obstacles.values():
		if obstacle.hp < obstacle.max_hp:
			Painter.bar(ci, obstacle.position + Vector2(0, -obstacle.radius() - 6.0), GameConfig.CELL * 0.8, obstacle.hp_ratio(), AppTheme.GOLD, 5.0)
	for enemy in state.enemies:
		if enemy.hp < enemy.max_hp and is_on_screen(enemy.position) and shows_enemy(enemy):
			Painter.bar(ci, enemy.position + Vector2(0, -enemy.radius() - 9.0), maxf(enemy.radius() * 2.0, 20.0), enemy.hp_ratio(), Painter.hp_color(enemy.hp_ratio()), 4.0)
	if status_mode:
		_paint_status(ci)
	elif shows_beam_labels():
		_paint_beam_labels(ci)
	_paint_selection(ci)
	_paint_pick(ci)
	_paint_gesture(ci)
	_paint_stick(ci)
	for floater_item in fx.floaters:
		var ratio := EffectPool.ratio(floater_item)
		var age := float(floater_item.max) - float(floater_item.life)
		var size := int(round(22.0 * float(floater_item.scale) * Juice.float_scale(age)))
		_text(ci, str(floater_item.text), floater_item.position, size, Color(floater_item.color, minf(ratio * 2.0, 1.0)))


func _paint_selection(ci: CanvasItem) -> void:
	var building := battle.state.building(selected_id)
	if building == null:
		return
	var pulse := 1.0 + 0.05 * sin(clock * 6.0)
	ci.draw_arc(building.position, (building.radius() + 8.0) * pulse, 0.0, TAU, 40, AppTheme.ENERGY_CORE, 3.0, true)
	if not building.is_player():
		if building.definition().has("attack"):
			_dashed_circle(ci, building.position, Formulas.attack_range(building), AppTheme.DANGER)
		if building.spawner and not GameConfig.guard(building.kind).is_empty():
			_dashed_circle(ci, building.position, Formulas.guard_ring(building), Color(AppTheme.WARNING, 0.6))
		return
	_paint_links_of(ci, building)
	if Formulas.max_links(building) > 0:
		_dashed_circle(ci, building.position, Formulas.link_range(building), AppTheme.ENERGY)
	if GameConfig.has_attack(building.kind):
		_dashed_circle(ci, building.position, Formulas.attack_range(building), AppTheme.DANGER)
		var minimum := float(Formulas.attack(building).get("min_range", 0.0))
		if minimum > 0.0:
			_dashed_circle(ci, building.position, minimum, Color(AppTheme.DANGER, 0.5))
		var focus := battle.combat.focused(building)
		if focus != null:
			_dashed_line(ci, building.position, focus.position, Color(AppTheme.DANGER, 0.7))
			_crosshair(ci, focus.position, float(focus.radius()) + 8.0, AppTheme.DANGER)
	_paint_support_ranges(ci, building, 1.0)


func shows_beam_labels() -> bool:
	var building := battle.state.building(selected_id)
	return status_mode or (building != null and building.is_player())


func labeled_links() -> Array[EnergyLink]:
	var result: Array[EnergyLink] = []
	if not shows_beam_labels():
		return result
	for link in battle.state.links:
		if touches_selected(link):
			result.append(link)
	return result


func _paint_beam_labels(ci: CanvasItem) -> void:
	var state := battle.state
	var audit := battle.audit()
	var scenario := EnergyAudit.view_scenario(state)
	for link in labeled_links():
		var points := state.link_points(link)
		if _segment_on_screen(points[0], points[1]):
			_paint_link_label(ci, link, points, audit, scenario)


func beam_label(link: EnergyLink) -> String:
	return StatusText.link_label(battle.audit(), link.key(), link.source == selected_id, EnergyAudit.view_scenario(battle.state))


func _paint_link_label(ci: CanvasItem, link: EnergyLink, points: PackedVector2Array, audit: EnergyAudit, scenario: int) -> void:
	var key := link.key()
	_text(ci, beam_label(link), points[0].lerp(points[1], 0.5) + Vector2(0, -8.0), STATUS_TEXT, StatusText.link_color(audit, key, scenario))


func _paint_badge(ci: CanvasItem, building: Building, audit: EnergyAudit, scenario: int) -> void:
	var verdict := audit.verdict(building.id, scenario)
	if verdict == EnergyAudit.Verdict.NONE:
		return
	var color := StatusText.color(verdict)
	var corner := building.position + Vector2(building.radius(), -building.radius()) * 0.8
	var radius := STATUS_BADGE * 0.7
	ci.draw_circle(corner, radius, Color(AppTheme.SURFACE, 0.92))
	ci.draw_arc(corner, radius, 0.0, TAU, 24, color, STATUS_RING, true)
	var gap := audit.missing(building.id, scenario)
	if gap > 0.0:
		ci.draw_arc(corner, radius, -PI / 2.0, -PI / 2.0 + TAU * gap, maxi(int(24 * gap), 4), AppTheme.DANGER, STATUS_RING, true)
	_icon(ci, StatusText.icon(verdict), corner, STATUS_BADGE, color)


func _paint_status(ci: CanvasItem) -> void:
	var state := battle.state
	var audit := battle.audit()
	var scenario := EnergyAudit.view_scenario(state)
	for link in labeled_links():
		var points := state.link_points(link)
		if not _segment_on_screen(points[0], points[1]):
			continue
		ci.draw_line(points[0], points[1], Color(StatusText.link_color(audit, link.key(), scenario), 0.9), 6.0, true)
		_paint_link_label(ci, link, points, audit, scenario)
	for building in state.player_buildings():
		if audit.has(building.id) and is_on_screen(building.position, building.half_extent()):
			_paint_badge(ci, building, audit, scenario)


func touches_selected(link: EnergyLink) -> bool:
	return selected_id >= 0 and (link.source == selected_id or link.target == selected_id)


func _paint_stick(ci: CanvasItem) -> void:
	if gesture != Gesture.STEER or stick_origin == Vector2.INF:
		return
	var factor := 1.0 / maxf(zoom, 0.01)
	var origin := to_world(stick_origin)
	var knob := to_world(stick_point if stick_point != Vector2.INF else stick_origin)
	ci.draw_circle(origin, STICK_RADIUS * factor, Color(AppTheme.SURFACE, 0.35))
	ci.draw_arc(origin, STICK_RADIUS * factor, 0.0, TAU, 40, Color(AppTheme.ENERGY, 0.6), 3.0 * factor, true)
	ci.draw_circle(knob, STICK_RADIUS * 0.42 * factor, Color(AppTheme.ENERGY, 0.55))


func _paint_links_of(ci: CanvasItem, building: Building) -> void:
	var state := battle.state
	for link in state.links:
		if link.source != building.id and link.target != building.id:
			continue
		var points := state.link_points(link)
		var color := AppTheme.ENERGY_CORE if link.active else AppTheme.DANGER
		ci.draw_line(points[0], points[1], Color(color, 0.25), 10.0, true)
		ci.draw_line(points[0], points[1], Color(color, 0.85), 3.0, true)
		var middle := points[0].lerp(points[1], 0.55)
		var direction := (points[1] - points[0]).normalized()
		var side := direction.orthogonal() * 9.0
		ci.draw_colored_polygon(PackedVector2Array([middle + direction * 12.0, middle - direction * 6.0 + side, middle - direction * 6.0 - side]), color)
		var other := state.building(link.target if link.source == building.id else link.source)
		if other != null:
			ci.draw_arc(other.position, other.radius() + 7.0, 0.0, TAU, 32, Color(color, 0.8), 3.0, true)


func _paint_pick(ci: CanvasItem) -> void:
	var source := battle.state.building(pick_id)
	if source == null:
		return
	var pulse := 1.0 + 0.08 * sin(clock * 7.0)
	match pick:
		Pick.LINK:
			_dashed_circle(ci, source.position, Formulas.link_range(source), Color(AppTheme.ENERGY, 0.9))
			for target in link_candidates(source):
				ci.draw_arc(target.position, (target.radius() + 10.0) * pulse, 0.0, TAU, 32, AppTheme.SUCCESS, 4.0, true)
		Pick.FUEL:
			_dashed_circle(ci, source.position, Formulas.fuel_reach(source), Color(AppTheme.FLAME, 0.9))
			for cell in battle.fuel.candidates(source):
				if not source.fuel.has(cell):
					ci.draw_arc(battle.state.map.center_of(cell), GameConfig.CELL * 0.42 * pulse, 0.0, TAU, 20, Color(AppTheme.SUCCESS, 0.8), 2.5, true)
		Pick.FOCUS:
			for enemy in battle.state.enemies:
				if enemy.is_alive() and shows_enemy(enemy) and battle.combat.focus_reason(source, enemy) == Combat.OK and battle.combat.in_attack_range(source, enemy):
					ci.draw_arc(enemy.position, (enemy.radius() + 6.0) * pulse, 0.0, TAU, 20, AppTheme.DANGER, 3.0, true)


func link_candidates(source: Building) -> Array[Building]:
	var result: Array[Building] = []
	for building in battle.state.player_buildings():
		if battle.network.link_reason(source.id, building.id) == EnergyNetwork.OK:
			result.append(building)
	return result


func _paint_support_ranges(ci: CanvasItem, building: Building, alpha: float) -> void:
	if building.kind == GameConfig.SHIELD:
		_dashed_circle(ci, building.position, Formulas.shield_radius(building), Color(AppTheme.SHIELD_BLUE, alpha))
	if building.definition().has("heal"):
		_dashed_circle(ci, building.position, Formulas.heal_range(building), Color(AppTheme.HEAL, alpha))
	if building.lighting:
		_dashed_circle(ci, building.position, Formulas.light_reach(building), Color(AppTheme.LAMP_LIGHT, alpha))
	if building.burner:
		_dashed_circle(ci, building.position, Formulas.fuel_reach(building), Color(AppTheme.FLAME, alpha))


func _paint_gesture(ci: CanvasItem) -> void:
	match gesture:
		Gesture.BUILD:
			_paint_ghost(ci)
		Gesture.LINK:
			_paint_link_preview(ci)
	if trail.size() >= 2:
		var points := PackedVector2Array()
		for point in trail:
			points.append(point.position)
		ci.draw_polyline(points, Color(1, 1, 1, 0.25), 14.0, true)
		ci.draw_polyline(points, Color(AppTheme.ENERGY_CORE, 0.9), 4.0, true)


func _paint_ghost(ci: CanvasItem) -> void:
	var definition := GameConfig.building(build_kind)
	var valid := BuildRules.can_place(battle.state, build_kind, ghost)
	if is_relocating():
		var moving := battle.state.building(relocate_id)
		valid = BuildRules.relocate_reason(battle.state, moving, ghost) == BuildRules.OK
		_dashed_line(ci, moving.position, LevelMap.snap(ghost, moving.cells()), Color(AppTheme.ENERGY_CORE, 0.6))
	var color := AppTheme.SUCCESS if valid else AppTheme.DANGER
	var radius := float(definition.radius)
	var probe := Building.new(-1, build_kind, ghost)
	probe.boosts = battle.state.setup.arsenal.boosts_for(build_kind)
	probe.elevation = battle.state.map.elevation(probe.origin) if probe.cells() == 1 else 0
	var center := probe.position
	if definition.has("attack"):
		_dashed_circle(ci, center, Formulas.attack_range(probe), Color(AppTheme.DANGER, 0.7))
	elif Formulas.max_links(probe) > 0:
		_dashed_circle(ci, center, Formulas.link_range(probe), Color(AppTheme.ENERGY, 0.7))
	_paint_support_ranges(ci, probe, 0.7)
	var half := Vector2(probe.half_extent(), probe.half_extent())
	ci.draw_rect(Rect2(center - half, half * 2.0), Color(color, 0.25))
	Painter.building(ci, build_kind, center, radius, clock, 0.5)
	ci.draw_rect(Rect2(center - half, half * 2.0), color, false, 3.0)


func _paint_link_preview(ci: CanvasItem) -> void:
	var source := battle.state.building(link_source)
	if source == null:
		return
	_dashed_circle(ci, source.position, Formulas.link_range(source), Color(AppTheme.ENERGY, 0.8))
	var target := link_target(link_end)
	var end := link_end
	var color := AppTheme.ENERGY
	if target != null and target.id != link_source:
		end = target.position
		var valid := battle.network.link_reason(link_source, target.id) == EnergyNetwork.OK
		color = AppTheme.SUCCESS if valid else AppTheme.DANGER
		ci.draw_arc(target.position, target.radius() + 10.0, 0.0, TAU, 32, color, 4.0, true)
	elif source.position.distance_to(link_end) > Formulas.link_range(source):
		color = AppTheme.DANGER
	var path := Lightning.path(source.position, end, 10.0, fx.rng)
	ci.draw_polyline(path, Color(color, 0.3), 12.0, true)
	ci.draw_polyline(path, color, 3.0, true)


func _dashed_circle(ci: CanvasItem, position: Vector2, radius: float, color: Color) -> void:
	var count := clampi(int(radius / 12.0), 12, 90)
	for i in count:
		if i % 2 == 0:
			var from := TAU * i / count + clock * 0.2
			ci.draw_arc(position, radius, from, from + TAU / count, 4, color, 2.5, true)


func _crosshair(ci: CanvasItem, position: Vector2, radius: float, color: Color) -> void:
	ci.draw_arc(position, radius, 0.0, TAU, 32, color, 3.0, true)
	for angle in [0.0, PI / 2.0, PI, PI * 1.5]:
		var direction := Vector2.from_angle(angle + clock * 0.8)
		ci.draw_line(position + direction * radius * 0.6, position + direction * radius * 1.35, color, 3.0, true)


func _dashed_line(ci: CanvasItem, from: Vector2, to: Vector2, color: Color) -> void:
	var length := from.distance_to(to)
	var count := maxi(int(length / 14.0), 1)
	for i in range(0, count, 2):
		ci.draw_line(from.lerp(to, float(i) / count), from.lerp(to, float(i + 1) / count), color, 2.5, true)


func _text(ci: CanvasItem, text: String, position: Vector2, size: int, color: Color) -> void:
	var font := AppTheme.FONT_BOLD
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var origin := position - Vector2(width * 0.5, 0)
	ci.draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, maxi(size / 5, 3), Color(0, 0, 0, color.a * 0.85))
	ci.draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _icon(ci: CanvasItem, glyph: String, position: Vector2, size: int, color: Color) -> void:
	var font := AppTheme.FONT_ICONS
	var width := font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	ci.draw_string_outline(font, position - Vector2(width * 0.5, -size * 0.4), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(0, 0, 0, 0.8))
	ci.draw_string(font, position - Vector2(width * 0.5, -size * 0.4), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
