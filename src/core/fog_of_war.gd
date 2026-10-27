class_name FogOfWar
extends RefCounted

const HIDDEN := 0
const EXPLORED := 1
const VISIBLE := 2

var map: LevelMap
var cells := PackedByteArray()
var version := 0
var _timer := 0.0
var _static := PackedByteArray()
var _static_key := -1


func _init(p_map: LevelMap) -> void:
	map = p_map
	cells.resize(map.width * map.height)
	cells.fill(HIDDEN)
	_static.resize(cells.size())


func state_of(cell: Vector2i) -> int:
	return cells[map.index(cell)] if map.has_cell(cell) else HIDDEN


func is_explored(cell: Vector2i) -> bool:
	return state_of(cell) != HIDDEN


func is_visible(position: Vector2) -> bool:
	return state_of(map.cell_of(position)) == VISIBLE


func is_explored_at(position: Vector2) -> bool:
	return is_explored(map.cell_of(position))


func update(state: BattleState, delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = GameConfig.FOG_INTERVAL
	refresh(state)


func invalidate() -> void:
	_static_key = -1


func refresh(state: BattleState) -> void:
	if _static_key != state.nav.version:
		_static_key = state.nav.version
		_static.fill(0)
		for building in state.player_buildings():
			_mark(_static, building.position, Formulas.vision(building), 1)
	for i in cells.size():
		if _static[i] == 1:
			cells[i] = VISIBLE
		elif cells[i] == VISIBLE:
			cells[i] = EXPLORED
	if state.scout != null:
		_mark(cells, state.scout.position, GameConfig.SCOUT_VISION, VISIBLE)
	version += 1


func reveal(center: Vector2, radius: float) -> void:
	_mark(cells, center, radius, VISIBLE)
	version += 1


func _mark(target: PackedByteArray, center: Vector2, radius: float, value: int) -> void:
	var low := map.cell_of(center - Vector2(radius, radius))
	var high := map.cell_of(center + Vector2(radius, radius))
	var limit := radius * radius
	for y in range(maxi(low.y, 0), mini(high.y, map.height - 1) + 1):
		for x in range(maxi(low.x, 0), mini(high.x, map.width - 1) + 1):
			var cell := Vector2i(x, y)
			if map.center_of(cell).distance_squared_to(center) <= limit:
				target[y * map.width + x] = value
