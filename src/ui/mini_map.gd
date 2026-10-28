class_name MiniMap
extends Control

signal focus_requested(world: Vector2)

const MAX_SIZE := Vector2(520, 560)
const TAP_TRAVEL := 24.0
const SPAWNER_RADIUS := 9.0
const TURRET_RADIUS := 6.0
const CORE_RADIUS := 8.0
const BUILDING_RADIUS := 2.5
const SCOUT_RADIUS := 5.0
const RIM := 2.0
const SPAWNER := "spawner"
const TURRET := "turret"
const CORE := "core"
const BUILDING := "building"
const SCOUT := "scout"
const COLORS := {
	SPAWNER: AppTheme.DANGER,
	TURRET: AppTheme.PLASMA_ORANGE,
	CORE: AppTheme.ENERGY_CORE,
	BUILDING: AppTheme.ENERGY,
	SCOUT: AppTheme.GOLD,
}
const RADII := {SPAWNER: SPAWNER_RADIUS, TURRET: TURRET_RADIUS, CORE: CORE_RADIUS, BUILDING: BUILDING_RADIUS, SCOUT: SCOUT_RADIUS}

var state: BattleState
var terrain: MiniMapTexture
var view_rect := Rect2()
var _press := Vector2.INF


func setup(p_state: BattleState) -> MiniMap:
	state = p_state
	terrain = MiniMapTexture.new(state.map, state.fog)
	custom_minimum_size = fit(state.map.size, MAX_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return self


static func fit(world: Vector2, bounds: Vector2) -> Vector2:
	var factor := minf(bounds.x / world.x, bounds.y / world.y)
	return (world * factor).floor()


func to_map(world: Vector2) -> Vector2:
	return world / state.map.size * size


func to_world(point: Vector2) -> Vector2:
	return (point / size * state.map.size).clamp(Vector2.ZERO, state.map.size)


func refresh(p_view_rect: Rect2) -> void:
	view_rect = p_view_rect
	terrain.refresh()
	queue_redraw()


func markers() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for building in state.player_buildings():
		if building.id != state.core_id:
			result.append({"type": BUILDING, "position": building.position})
	var core := state.core()
	if core != null:
		result.append({"type": CORE, "position": core.position})
	var scout := state.scout
	if scout != null and not scout.boarded:
		result.append({"type": SCOUT, "position": scout.position})
	for building in state.enemy_buildings():
		if building.is_alive():
			result.append({"type": SPAWNER if building.spawner else TURRET, "position": building.position})
	return result


func structure_count() -> int:
	var count := 0
	for building in state.enemy_buildings():
		if building.is_alive():
			count += 1
	return count


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if button.pressed:
		_press = button.position
		return
	if _press != Vector2.INF and _press.distance_to(button.position) <= TAP_TRAVEL:
		tap(button.position)
	_press = Vector2.INF


func tap(point: Vector2) -> void:
	focus_requested.emit(to_world(point))


func _draw() -> void:
	draw_texture_rect(terrain.texture, Rect2(Vector2.ZERO, size), false)
	for marker in markers():
		var type := str(marker.type)
		var center := to_map(marker.position)
		var radius := float(RADII[type])
		if type != BUILDING:
			draw_circle(center, radius + RIM, AppTheme.ON_ACCENT)
		draw_circle(center, radius, COLORS[type])
	if view_rect.has_area():
		draw_rect(Rect2(to_map(view_rect.position), to_map(view_rect.size)), Color(AppTheme.ON_SURFACE, 0.85), false, RIM)
	draw_rect(Rect2(Vector2.ZERO, size), AppTheme.OUTLINE, false, RIM)
