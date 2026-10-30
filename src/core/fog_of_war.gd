class_name FogOfWar
extends RefCounted

const HIDDEN := 0
const EXPLORED := 1
const VISIBLE := 2
const SCOUT_MARK := -1

var map: LevelMap
var cells := PackedByteArray()
var version := 0
var lifted := false
var _timer := 0.0
var _seen := PackedInt32Array()
var _marks := {}
var _static_key := -1
var _full := false


func _init(p_map: LevelMap) -> void:
	map = p_map
	cells.resize(map.width * map.height)
	cells.fill(HIDDEN)
	_seen.resize(cells.size())
	_seen.fill(0)


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
	_full = true


func lift() -> void:
	lifted = true
	cells.fill(VISIBLE)
	version += 1


func refresh(state: BattleState) -> void:
	if lifted:
		return
	var changed := false
	if _static_key != state.nav.version:
		_static_key = state.nav.version
		changed = _sync_buildings(state)
	var scout := state.scout
	if scout != null and not scout.boarded:
		changed = _set_mark(SCOUT_MARK, scout.position, GameConfig.SCOUT_VISION) or changed
	elif _marks.has(SCOUT_MARK):
		_unmark(SCOUT_MARK)
		changed = true
	if _full:
		_full = false
		_settle()
		changed = true
	if changed:
		version += 1


func reveal(center: Vector2, radius: float) -> void:
	_mark(center, radius)
	_full = true
	version += 1


func _sync_buildings(state: BattleState) -> bool:
	var changed := false
	var present := {}
	for building in state.player_buildings():
		present[building.id] = true
		changed = _set_mark(building.id, building.position, Formulas.vision(building)) or changed
	for id: int in _marks.keys():
		if id != SCOUT_MARK and not present.has(id):
			_unmark(id)
			changed = true
	return changed


func _set_mark(id: int, center: Vector2, radius: float) -> bool:
	var mark: Array = _marks.get(id, [])
	if not mark.is_empty() and mark[0] == center and mark[1] == radius:
		return false
	if not mark.is_empty():
		_apply(mark[0], mark[1], -1)
	_marks[id] = [center, radius]
	_apply(center, radius, 1)
	return true


func _unmark(id: int) -> void:
	var mark: Array = _marks[id]
	_marks.erase(id)
	_apply(mark[0], mark[1], -1)


func _settle() -> void:
	for i in cells.size():
		if _seen[i] > 0:
			cells[i] = VISIBLE
		elif cells[i] == VISIBLE:
			cells[i] = EXPLORED


func _apply(center: Vector2, radius: float, delta: int) -> void:
	var low := map.cell_of(center - Vector2(radius, radius))
	var high := map.cell_of(center + Vector2(radius, radius))
	var limit := radius * radius
	var width := map.width
	for y in range(maxi(low.y, 0), mini(high.y, map.height - 1) + 1):
		for x in range(maxi(low.x, 0), mini(high.x, width - 1) + 1):
			if map.center_of(Vector2i(x, y)).distance_squared_to(center) > limit:
				continue
			var index := y * width + x
			var count := _seen[index] + delta
			_seen[index] = count
			if count > 0:
				cells[index] = VISIBLE
			elif cells[index] == VISIBLE:
				cells[index] = EXPLORED


func _mark(center: Vector2, radius: float) -> void:
	var low := map.cell_of(center - Vector2(radius, radius))
	var high := map.cell_of(center + Vector2(radius, radius))
	var limit := radius * radius
	for y in range(maxi(low.y, 0), mini(high.y, map.height - 1) + 1):
		for x in range(maxi(low.x, 0), mini(high.x, map.width - 1) + 1):
			if map.center_of(Vector2i(x, y)).distance_squared_to(center) <= limit:
				cells[y * map.width + x] = VISIBLE
