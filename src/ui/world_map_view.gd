class_name WorldMapView
extends Control

signal region_tapped(index: int)
signal arrived(index: int)

const NODE_RADIUS := 30.0
const LAND_RADIUS := 78.0
const COAST := 8.0
const TAP_SLACK := 18.0
const TAP_TRAVEL := 24.0
const MARGIN := 56.0
const DASH := 14.0
const TREES := 7
const AVATAR_LIFT := 40.0
const WHEEL_STEP := 60.0

var progress: Progress
var walker: WorldWalker
var top_inset := 0.0
var bottom_inset := 0.0
var clock := 0.0
var pan := 0.0
var _press := Vector2.INF
var _dragging := false
var _centered := false


func setup(p_progress: Progress) -> WorldMapView:
	progress = p_progress
	walker = WorldWalker.new(progress.location)
	return self


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	clock += delta
	if not _centered and size.y > 1.0:
		_centered = true
		if max_pan() > 0.0:
			center_on(walker.anchor())
	set_pan(pan)
	if walker.update(delta):
		arrived.emit(walker.location)
	queue_redraw()


func map_rect() -> Rect2:
	var top := top_inset + MARGIN
	var height := maxf(size.y - top - bottom_inset - MARGIN, 1.0)
	return Rect2(MARGIN, top, maxf(size.x - MARGIN * 2.0, 1.0), height)


func to_screen(normalized: Vector2) -> Vector2:
	var rect := map_rect()
	return rect.position + normalized * rect.size + Vector2(0.0, pan)


func max_pan() -> float:
	return -Campaign.top() * map_rect().size.y


func set_pan(value: float) -> void:
	pan = clampf(value, 0.0, max_pan())


func center_on(index: int) -> void:
	var rect := map_rect()
	var wanted := rect.position.y + rect.size.y * 0.5 - Campaign.position(index).y * rect.size.y
	set_pan(wanted - rect.position.y)


func node_position(index: int) -> Vector2:
	return to_screen(Campaign.position(index))


func node_at(point: Vector2) -> int:
	var best := -1
	var best_distance := NODE_RADIUS + TAP_SLACK
	for index in Campaign.region_count():
		var distance := node_position(index).distance_to(point)
		if distance <= best_distance:
			best = index
			best_distance = distance
	return best


func _gui_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null:
		if _press != Vector2.INF and (_dragging or _press.distance_to(motion.position) > TAP_TRAVEL):
			_dragging = true
			set_pan(pan + motion.relative.y)
		return
	var button := event as InputEventMouseButton
	if button == null:
		return
	if button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_UP:
		set_pan(pan + WHEEL_STEP)
	elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		set_pan(pan - WHEEL_STEP)
	if button.button_index != MOUSE_BUTTON_LEFT:
		return
	if button.pressed:
		_press = button.position
		_dragging = false
		return
	if _press != Vector2.INF and not _dragging and _press.distance_to(button.position) <= TAP_TRAVEL:
		tap(button.position)
	_press = Vector2.INF
	_dragging = false


func tap(point: Vector2) -> void:
	var index := node_at(point)
	if index >= 0:
		region_tapped.emit(index)


func walk_to(index: int) -> bool:
	return walker.follow(Campaign.route(progress, walker.anchor(), index))


func _draw() -> void:
	_paint_sea()
	_paint_land()
	_paint_routes()
	for index in Campaign.region_count():
		_paint_node(index)
	var avatar := to_screen(walker.point) + Vector2(0, -AVATAR_LIFT)
	Painter.scout(self, avatar, walker.heading if walker.is_walking() else Vector2.DOWN, clock, 0.0, false)


func _paint_sea() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), AppTheme.WORLD_SEA)
	var rows := 14
	for i in rows:
		var y := size.y * (float(i) + 0.5) / rows + sin(clock * 0.6 + i) * 6.0
		var offset := fposmod(clock * 18.0 + i * 47.0, 120.0)
		var x := -120.0 + offset
		while x < size.x:
			draw_line(Vector2(x, y), Vector2(x + 44.0, y), Color(AppTheme.WORLD_SEA_LIGHT, 0.8), 2.0, true)
			x += 120.0


func _paint_land() -> void:
	for pass_index in 2:
		var color := AppTheme.WORLD_COAST if pass_index == 0 else AppTheme.WORLD_LAND
		var grow := COAST if pass_index == 0 else 0.0
		for route in Campaign.routes():
			draw_line(node_position(route.x), node_position(route.y), color, (LAND_RADIUS + grow) * 1.3, true)
		for index in Campaign.region_count():
			draw_circle(node_position(index), LAND_RADIUS + grow, color)
	for index in Campaign.region_count():
		var center := node_position(index)
		draw_circle(center, LAND_RADIUS * 0.62, AppTheme.WORLD_LAND_LIGHT)
		for i in TREES:
			var angle := i * TAU / TREES + index * 0.7
			var tree := center + Vector2.from_angle(angle) * LAND_RADIUS * (0.72 + 0.12 * sin(i * 3.1 + index))
			draw_circle(tree + Vector2(2, 3), 7.0, AppTheme.SHADOW)
			draw_circle(tree, 7.0, AppTheme.TREE)
			draw_circle(tree + Vector2(-2, -2), 3.5, AppTheme.TREE_LIGHT)


func _paint_routes() -> void:
	for route in Campaign.routes():
		var from := node_position(route.x)
		var to := node_position(route.y)
		if progress.is_conquered(route.x) and progress.is_conquered(route.y):
			draw_line(from, to, Color(AppTheme.ENERGY, 0.35), 12.0, true)
			draw_line(from, to, AppTheme.ENERGY, 4.0, true)
		elif Campaign.is_route_open(progress, route.x, route.y):
			_dashed(from, to, AppTheme.GOLD, 5.0)
		else:
			_dashed(from, to, Color(AppTheme.OUTLINE, 0.7), 3.0)


func _dashed(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var length := from.distance_to(to)
	var direction := (to - from) / maxf(length, 0.001)
	var travelled := fposmod(clock * 20.0, DASH * 2.0) - DASH * 2.0
	while travelled < length:
		var start := maxf(travelled, 0.0)
		var end := minf(travelled + DASH, length)
		if end > start:
			draw_line(from + direction * start, from + direction * end, color, width, true)
		travelled += DASH * 2.0


func _paint_node(index: int) -> void:
	var center := node_position(index)
	var conquered := progress.is_conquered(index)
	var frontier := Campaign.is_frontier(progress, index)
	var selected := index == walker.destination()
	var pulse := 0.5 + 0.5 * sin(clock * 3.0 + index)
	if selected:
		draw_arc(center, NODE_RADIUS + 12.0 + pulse * 3.0, 0.0, TAU, 40, AppTheme.ENERGY_CORE, 3.0, true)
	if conquered:
		draw_circle(center, NODE_RADIUS, Color(AppTheme.ENERGY_DIM, 0.95))
		draw_arc(center, NODE_RADIUS, 0.0, TAU, 40, AppTheme.ENERGY, 4.0, true)
		_glyph(Icons.FLAG, center, AppTheme.ENERGY_CORE, 30)
	elif frontier:
		draw_circle(center, NODE_RADIUS + 6.0 + pulse * 6.0, Color(AppTheme.DANGER, 0.18 * (1.0 - pulse) + 0.08))
		draw_circle(center, NODE_RADIUS, Color(AppTheme.SURFACE, 0.95))
		draw_arc(center, NODE_RADIUS, 0.0, TAU, 40, AppTheme.DANGER, 4.0, true)
		var spawner := faction_of(index)
		var radius := float(GameConfig.building(spawner).get("radius", 24.0))
		draw_set_transform(center, 0.0, Vector2.ONE * (NODE_RADIUS * 0.7 / radius))
		Painter.building(self, spawner, Vector2.ZERO, radius, clock)
		draw_set_transform_matrix(Transform2D.IDENTITY)
	else:
		draw_circle(center, NODE_RADIUS, Color(AppTheme.SURFACE, 0.9))
		draw_arc(center, NODE_RADIUS, 0.0, TAU, 40, AppTheme.OUTLINE, 3.0, true)
		_glyph(Icons.LOCK, center, AppTheme.OUTLINE, 26)
	var label_y := center.y + NODE_RADIUS + 22.0
	_text(Texts.level_name(index), Vector2(center.x, label_y), AppTheme.ON_SURFACE if conquered or frontier else AppTheme.ON_SURFACE_VARIANT, AppTheme.SIZE_SMALL)
	if conquered:
		var stars := progress.stars_for(index)
		for i in Progress.MAX_STARS:
			_glyph(Icons.STAR if i < stars else Icons.STAR_EMPTY, Vector2(center.x + (i - 1) * 20.0, label_y + 18.0), AppTheme.GOLD if i < stars else AppTheme.OUTLINE, 18)


static func faction_of(index: int) -> String:
	for entry: Array in GameConfig.level(index).structures:
		if GameConfig.SPAWNER_FACTIONS.has(entry[0]):
			return str(entry[0])
	return GameConfig.NEST


func _glyph(glyph: String, center: Vector2, color: Color, font_size: int) -> void:
	var font: Font = AppTheme.FONT_ICONS
	var extent := font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, center + Vector2(-extent.x * 0.5, font.get_ascent(font_size) - extent.y * 0.5), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _text(text: String, center: Vector2, color: Color, font_size: int) -> void:
	var font: Font = AppTheme.FONT_SEMIBOLD
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin := Vector2(center.x - width * 0.5, center.y)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0, 0, 0, 0.7))
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
