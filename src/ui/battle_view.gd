class_name BattleView
extends Node2D

signal building_selected(id: int)
signal action_failed(message: String, world: Vector2)
signal build_mode_changed(kind: String)
signal camera_moved
signal mode_changed(mode: Mode)
signal scout_selected(active: bool)

enum Mode { MOVE, CONNECT }
enum Gesture { NONE, BUILD, LINK_PENDING, LINK, TAP_PENDING, CUT_PENDING, CUT, PAN }

const BEAM_REFRESH := 0.06
const PICK_SLACK := 14.0
const LINK_SNAP := 26.0
const TRAIL_LIFE := 0.22
const SCOUT_PICK := 40.0
const WHEEL_ZOOM := 1.12
const INITIAL_ZOOM := 0.8
const AIM_SPEED := 10.0
const DEFAULT_AIM := -PI / 2.0
const BEAM_VISIBLE_FLOW := 1.5
const BEAM_MIN_FLOW := 0.05

var battle: Battle
var fx := EffectPool.new(7)
var camera := Camera2D.new()
var tracker := GestureTracker.new()
var center := Vector2.ZERO
var zoom := INITIAL_ZOOM
var top_inset := 0.0
var bottom_inset := 0.0
var build_kind := ""
var selected_id := -1
var scout_active := false
var gesture := Gesture.NONE
var mode := Mode.MOVE
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
var _tap_scout := false
var _painted := false
var _paint_last := Vector2.INF
var _terrain_painter: TerrainPainter
var _fog_texture: FogTexture
var _terrain: Node2D
var _chunks := {}
var _world: DrawLayer
var _fog: DrawLayer
var _night: DrawLayer
var _glow: DrawLayer
var _overlay: DrawLayer


func setup(p_battle: Battle) -> BattleView:
	battle = p_battle
	_terrain_painter = TerrainPainter.new(battle.state.map)
	_fog_texture = FogTexture.new(battle.state.fog)
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
	_world = DrawLayer.new().setup(_paint_world)
	_fog = DrawLayer.new().setup(_paint_fog)
	_fog.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_fog.material = _fog_texture.material
	_night = DrawLayer.new().setup(_paint_night)
	_glow = DrawLayer.new().setup(_paint_glow)
	_overlay = DrawLayer.new().setup(_paint_overlay)
	for layer in [_world, _fog, _night, _glow, _overlay]:
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


func focus(world: Vector2) -> void:
	zoom = CameraMath.clamp_zoom(zoom, view_size(), battle.state.map.size)
	center = CameraMath.clamp_center(world, zoom, view_size(), battle.state.map.size)
	_apply_camera()


func _apply_camera() -> void:
	camera.position = center + fx.shake_offset()
	camera.zoom = Vector2(zoom, zoom)


func to_world(screen: Vector2) -> Vector2:
	return CameraMath.screen_to_world(screen, center, zoom, view_size())


func to_screen(world: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world


func set_build_kind(kind: String) -> void:
	build_kind = kind
	if not kind.is_empty():
		select(-1)
	_painted = false
	_paint_last = Vector2.INF
	build_mode_changed.emit(kind)


func set_mode(value: Mode) -> void:
	mode = value
	gesture = Gesture.NONE
	trail.clear()
	mode_changed.emit(mode)


func toggle_mode() -> void:
	set_mode(Mode.CONNECT if mode == Mode.MOVE else Mode.MOVE)


func select(id: int) -> void:
	selected_id = id
	if id >= 0:
		set_scout_active(false)
	building_selected.emit(id)


func set_scout_active(active: bool) -> void:
	var value := active and battle.state.scout != null
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
	if _fog_texture.refresh():
		_fog.queue_redraw()
	_apply_camera()
	for layer in [_world, _night, _glow, _overlay]:
		layer.queue_redraw()


func _refresh_beams() -> void:
	var fresh := {}
	for link in battle.state.links:
		var points := battle.state.link_points(link)
		var flow := _flow_ratio(link)
		fresh[link.key()] = Lightning.path(points[0], points[1], 5.0 + 9.0 * flow, fx.rng)
	_beams = fresh


func beam_visibility(link: EnergyLink) -> float:
	return clampf((link.flow - BEAM_MIN_FLOW) / BEAM_VISIBLE_FLOW, 0.0, 1.0)


func _flow_ratio(link: EnergyLink) -> float:
	var source := battle.state.building(link.source)
	if source == null:
		return 0.0
	return clampf(link.flow / maxf(Formulas.rate(source), 0.001), 0.0, 1.0)


func _update_aims(delta: float) -> void:
	for building: Building in battle.state.buildings.values():
		if not building.definition().has("attack"):
			continue
		var target := _target_position(building)
		var desired: float = (target - building.position).angle() if target != Vector2.INF else float(_aims.get(building.id, DEFAULT_AIM))
		var current := float(_aims.get(building.id, DEFAULT_AIM))
		_aims[building.id] = lerp_angle(current, desired, clampf(AIM_SPEED * delta, 0.0, 1.0))


func _target_position(building: Building) -> Vector2:
	if building.target_id < 0:
		return Vector2.INF
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
			begin(to_world(touch.position))
		else:
			gesture = Gesture.NONE
			trail.clear()
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


func begin(world: Vector2) -> void:
	cut_last = world
	trail.clear()
	_tap_scout = false
	if not build_kind.is_empty():
		gesture = Gesture.BUILD
		ghost = world
		_paint_last = world
		return
	if mode == Mode.CONNECT and tracker.double:
		gesture = Gesture.PAN
		link_source = -1
		return
	var building := battle.building_at(world, PICK_SLACK)
	if is_scout_at(world) and (mode == Mode.MOVE or building == null):
		gesture = Gesture.TAP_PENDING
		link_source = -1
		_tap_scout = true
		return
	if mode == Mode.MOVE:
		gesture = Gesture.TAP_PENDING if building != null else Gesture.CUT_PENDING
		link_source = building.id if building != null else -1
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


func is_scout_at(world: Vector2) -> bool:
	var scout := battle.state.scout
	return scout != null and scout.is_landed() and scout.position.distance_to(world) <= SCOUT_PICK


func drag_to(world: Vector2, moved: bool, screen_delta: Vector2 = Vector2.ZERO) -> void:
	if gesture == Gesture.PAN and mode == Mode.CONNECT:
		pan(-screen_delta / zoom)
		return
	if mode == Mode.MOVE and gesture != Gesture.BUILD:
		if moved and gesture != Gesture.NONE:
			gesture = Gesture.PAN
			pan(-screen_delta / zoom)
		return
	match gesture:
		Gesture.BUILD:
			ghost = world
			if moved and GameConfig.is_wall(build_kind):
				_paint_to(world)
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


func _paint_to(world: Vector2) -> void:
	var from := world if _paint_last == Vector2.INF else _paint_last
	var steps := maxi(int(ceil(from.distance_to(world) / (GameConfig.CELL * 0.5))), 1)
	for i in steps + 1:
		var point := LevelMap.snap(from.lerp(world, float(i) / steps), GameConfig.cells(build_kind))
		if battle.state.nav.occupant_at(battle.state.map.cell_of(point)) != NavGrid.FREE:
			continue
		var reason := battle.place(build_kind, point)
		if reason == BuildRules.OK:
			_painted = true
		elif reason == BuildRules.MONEY:
			action_failed.emit(Texts.reason("build_" + reason), point)
			set_build_kind("")
			gesture = Gesture.NONE
			return
	_paint_last = world


func finish(world: Vector2) -> void:
	match gesture:
		Gesture.BUILD:
			if not _painted:
				place_at(world)
			_painted = false
		Gesture.LINK:
			var target := link_target(world)
			if target != null and target.id != link_source:
				var reason := battle.connect_buildings(link_source, target.id)
				if reason != EnergyNetwork.OK:
					action_failed.emit(Texts.reason("link_" + reason), world)
	gesture = Gesture.NONE
	link_source = -1


func tap(world: Vector2) -> void:
	match gesture:
		Gesture.BUILD:
			place_at(world)
		Gesture.LINK_PENDING, Gesture.TAP_PENDING:
			if _tap_scout:
				set_scout_active(not scout_active)
				if scout_active:
					select(-1)
			else:
				select(link_source if link_source != selected_id else -1)
		Gesture.CUT_PENDING:
			if scout_active:
				command_scout(world)
			else:
				select(-1)
	gesture = Gesture.NONE
	link_source = -1
	_tap_scout = false


func command_scout(world: Vector2) -> void:
	var reason := battle.command_scout(world)
	if reason != ScoutControl.OK:
		action_failed.emit(Texts.reason("scout_" + reason), world)


func place_at(world: Vector2) -> void:
	var reason := battle.place(build_kind, world)
	if reason != BuildRules.OK:
		action_failed.emit(Texts.reason("build_" + reason), world)
		return
	if not GameConfig.is_wall(build_kind):
		set_build_kind("")


func link_target(world: Vector2) -> Building:
	var target := battle.building_at(world, LINK_SNAP)
	return target if target != null and target.is_player() else null


func _paint_world(ci: CanvasItem) -> void:
	var state := battle.state
	var light := state.light()
	for building in state.player_buildings():
		if building.kind == GameConfig.SHIELD and building.energy > 1.0:
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
		for building in state.enemy_buildings():
			ci.draw_circle(building.position, building.half_extent() + GameConfig.ENEMY_NO_BUILD, Color(AppTheme.DANGER, 0.1))
	for building: Building in state.buildings.values():
		var fill := building.energy / Formulas.capacity(building) if Formulas.capacity(building) > 0.0 else 0.0
		Painter.building(ci, building.kind, building.position, building.radius(), clock, fill, float(_aims.get(building.id, DEFAULT_AIM)), light)
	for pickup in state.pickups:
		var bob := sin(clock * 8.0 + pickup.position.x) * 2.0
		Painter.coin(ci, pickup.position + Vector2(0, bob), 7.0, clock + pickup.position.y)
	for projectile in state.projectiles:
		ci.draw_circle(projectile.position(), 8.0, AppTheme.SHADOW)
	for enemy in state.enemies:
		if state.fog.is_visible(enemy.position):
			Painter.enemy(ci, enemy.kind, enemy.position, enemy.radius(), enemy.heading, clock + enemy.id * 0.37, 1.0 - light)
	_paint_scout(ci)


func _paint_scout(ci: CanvasItem) -> void:
	var scout := battle.state.scout
	if scout == null:
		return
	if scout.is_clearing():
		var target := battle.state.map.center_of(scout.clear_cell)
		ci.draw_arc(target, GameConfig.CELL * 0.55, 0.0, TAU, 32, Color(AppTheme.GOLD, 0.8), 3.0, true)
		Painter.bar(ci, target + Vector2(0, -GameConfig.CELL * 0.6), GameConfig.CELL * 0.9, battle.scouting.clear_ratio(), AppTheme.GOLD, 5.0)
	if scout_active:
		var pulse := 1.0 + 0.08 * sin(clock * 6.0)
		ci.draw_arc(scout.position, 22.0 * pulse, 0.0, TAU, 32, AppTheme.ENERGY_CORE, 3.0, true)
		if scout.is_moving():
			_dashed_line(ci, scout.position, scout.path[scout.path.size() - 1], Color(AppTheme.ENERGY_CORE, 0.6))
			ci.draw_circle(scout.path[scout.path.size() - 1], 6.0, Color(AppTheme.ENERGY_CORE, 0.7))
	Painter.scout(ci, scout.position, scout.heading, clock, scout.drop_ratio(), scout.is_clearing() and not scout.is_moving())


func _paint_fog(ci: CanvasItem) -> void:
	ci.draw_texture_rect(_fog_texture.texture, Rect2(Vector2.ZERO, battle.state.map.size), false)


func darkness() -> float:
	return 1.0 - battle.state.light()


func _paint_night(ci: CanvasItem) -> void:
	var dark := darkness()
	if dark <= 0.01:
		return
	var size := battle.state.map.size
	ci.draw_rect(Rect2(Vector2(-2000, -2000), size + Vector2(4000, 4000)), Color(AppTheme.NIGHT_TINT, AppTheme.NIGHT_TINT.a * dark))


func _paint_glow(ci: CanvasItem) -> void:
	var state := battle.state
	var dark := darkness()
	for link in state.links:
		var straight := state.link_points(link)
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
		if building.kind == GameConfig.LASER and building.firing:
			var target := _target_position(building)
			if target != Vector2.INF:
				var color := AppTheme.building_color(GameConfig.LASER)
				var flicker := 0.8 + 0.2 * sin(clock * 60.0)
				ci.draw_line(building.position, target, Color(color, 0.25 * flicker), 12.0, true)
				ci.draw_line(building.position, target, Color(color, 0.9), 4.0, true)
				ci.draw_line(building.position, target, Color(1, 1, 1, 0.9), 1.5, true)
				ci.draw_circle(target, 7.0 * flicker, Color(1, 0.9, 0.9, 0.8))
		elif dark > 0.2 and building.energy > 0.5:
			ci.draw_circle(building.position, building.radius() * 0.5, Color(AppTheme.building_color(building.kind), 0.12 * dark))
	if dark > 0.2:
		for enemy in state.enemies:
			if not state.fog.is_visible(enemy.position):
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
		if building.hp < building.max_hp():
			Painter.bar(ci, building.position + Vector2(0, -building.radius() - 12.0), building.radius() * 1.6, building.hp_ratio(), Painter.hp_color(building.hp_ratio()))
		if building.is_player() and GameConfig.uses_energy_actively(building.kind):
			var fill := building.energy / Formulas.capacity(building)
			Painter.bar(ci, building.position + Vector2(0, building.radius() + 9.0), building.radius() * 1.4, fill, AppTheme.ENERGY, 4.0)
			if building.energy < Targeting.needed_energy(building) and fmod(clock, 1.0) < 0.6:
				_icon(ci, Icons.BOLT, building.position + Vector2(0, -building.radius() - 30.0), 26, AppTheme.WARNING)
	for enemy in state.enemies:
		if enemy.hp < enemy.max_hp and state.fog.is_visible(enemy.position):
			Painter.bar(ci, enemy.position + Vector2(0, -enemy.radius() - 9.0), maxf(enemy.radius() * 2.0, 20.0), enemy.hp_ratio(), Painter.hp_color(enemy.hp_ratio()), 4.0)
	_paint_selection(ci)
	_paint_gesture(ci)
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
		return
	if Formulas.max_links(building) > 0:
		_dashed_circle(ci, building.position, Formulas.link_range(building), AppTheme.ENERGY)
	if GameConfig.has_attack(building.kind):
		_dashed_circle(ci, building.position, Formulas.attack_range(building), AppTheme.DANGER)
		var minimum := float(Formulas.attack(building).get("min_range", 0.0))
		if minimum > 0.0:
			_dashed_circle(ci, building.position, minimum, Color(AppTheme.DANGER, 0.5))
	_paint_support_ranges(ci, building, 1.0)


func _paint_support_ranges(ci: CanvasItem, building: Building, alpha: float) -> void:
	if building.kind == GameConfig.SHIELD:
		_dashed_circle(ci, building.position, Formulas.shield_radius(building), Color(AppTheme.SHIELD_BLUE, alpha))
	if building.definition().has("heal"):
		_dashed_circle(ci, building.position, Formulas.heal_range(building), Color(AppTheme.HEAL, alpha))


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
	var color := AppTheme.SUCCESS if valid else AppTheme.DANGER
	var radius := float(definition.radius)
	var probe := Building.new(-1, build_kind, ghost)
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
