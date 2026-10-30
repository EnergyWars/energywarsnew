class_name NavGrid
extends RefCounted

const FREE := -1
const NEAREST_SEARCH := 6
const RING: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]

var map: LevelMap
var occupant := PackedInt32Array()
var hostile := PackedByteArray()
var ground := AStarGrid2D.new()
var walker := AStarGrid2D.new()
var version := 0
var _blocked := PackedByteArray()
var _width := 0
var _height := 0
var _labels := PackedInt32Array()
var _labels_version := -1
var _reachable := {}


func _init(p_map: LevelMap) -> void:
	map = p_map
	_width = map.width
	_height = map.height
	_blocked.resize(map.width * map.height)
	_blocked.fill(0)
	occupant.resize(map.width * map.height)
	occupant.fill(FREE)
	hostile.resize(map.width * map.height)
	hostile.fill(0)
	for grid: AStarGrid2D in [ground, walker]:
		grid.region = Rect2i(0, 0, map.width, map.height)
		grid.cell_size = Vector2(GameConfig.CELL, GameConfig.CELL)
		grid.offset = Vector2(GameConfig.CELL, GameConfig.CELL) * 0.5
		grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
		grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
		grid.update()
	for i in map.width * map.height:
		_refresh(map.cell_at(i))


func _refresh(cell: Vector2i) -> void:
	var walkable := map.is_walkable(cell)
	var index := map.index(cell)
	var blocked := not walkable or occupant[index] != FREE
	_blocked[index] = 1 if blocked else 0
	ground.set_point_solid(cell, blocked)
	walker.set_point_solid(cell, not walkable or hostile[index] == 1 or map.is_sealed(cell))


func occupy(building: Building) -> void:
	for cell in building.footprint():
		if map.has_cell(cell):
			occupant[map.index(cell)] = building.id
			hostile[map.index(cell)] = 0 if building.is_player() else 1
			_refresh(cell)
	version += 1


func release(building: Building) -> void:
	for cell in building.footprint():
		if map.has_cell(cell) and occupant[map.index(cell)] == building.id:
			occupant[map.index(cell)] = FREE
			hostile[map.index(cell)] = 0
			_refresh(cell)
	version += 1


func terrain_changed(cell: Vector2i) -> void:
	if map.has_cell(cell):
		_refresh(cell)
		version += 1


func occupant_at(cell: Vector2i) -> int:
	return occupant[map.index(cell)] if map.has_cell(cell) else FREE


func is_free(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < _width and cell.y < _height and _blocked[cell.y * _width + cell.x] == 0


func is_blocked_at(position: Vector2) -> bool:
	return not is_free(Vector2i(floori(position.x / GameConfig.CELL), floori(position.y / GameConfig.CELL)))


func component(cell: Vector2i) -> int:
	_update_components()
	return _labels[map.index(cell)] if map.has_cell(cell) else -1


func component_at(position: Vector2) -> int:
	var cell := nearest_free(position)
	return component(cell) if cell != Vector2i(-1, -1) else -1


func reachable(component_id: int) -> Dictionary:
	_update_components()
	return _reachable.get(component_id, {})


func _update_components() -> void:
	if _labels_version == version:
		return
	_labels_version = version
	var width := map.width
	var count := width * map.height
	var open := PackedByteArray()
	open.resize(count)
	for i in count:
		var tile := map.tiles[i]
		open[i] = 1 if (tile == LevelMap.Tile.OPEN or tile == LevelMap.Tile.RAMP) and occupant[i] == FREE else 0
	_labels.resize(count)
	_labels.fill(-1)
	_reachable = {}
	var next := 0
	var queue := PackedInt32Array()
	queue.resize(count)
	for start in count:
		if _labels[start] >= 0 or open[start] == 0:
			continue
		_labels[start] = next
		queue[0] = start
		var head := 0
		var tail := 1
		var touched := {}
		while head < tail:
			var current := queue[head]
			head += 1
			var x := current % width
			for other in [current - 1 if x > 0 else -1, current + 1 if x < width - 1 else -1, current - width, current + width]:
				if other < 0 or other >= count:
					continue
				if open[other] == 1:
					if _labels[other] < 0:
						_labels[other] = next
						queue[tail] = other
						tail += 1
				elif occupant[other] != FREE:
					touched[occupant[other]] = true
		_reachable[next] = touched
		next += 1


func nearest_free(position: Vector2) -> Vector2i:
	var origin := map.cell_of(position)
	if is_free(origin):
		return origin
	var best := Vector2i(-1, -1)
	var best_distance := INF
	for radius in range(1, NEAREST_SEARCH + 1):
		for y in range(origin.y - radius, origin.y + radius + 1):
			for x in range(origin.x - radius, origin.x + radius + 1):
				if maxi(absi(x - origin.x), absi(y - origin.y)) != radius:
					continue
				var cell := Vector2i(x, y)
				if not is_free(cell):
					continue
				var distance := map.center_of(cell).distance_squared_to(position)
				if distance < best_distance:
					best = cell
					best_distance = distance
		if best != Vector2i(-1, -1):
			return best
	return best


func path_to_building(from: Vector2, building: Building) -> PackedVector2Array:
	var start := nearest_free(from)
	if start == Vector2i(-1, -1):
		return PackedVector2Array()
	var cells := building.footprint()
	for cell in cells:
		if map.has_cell(cell):
			ground.set_point_solid(cell, false)
	var goal := building.origin if map.has_cell(building.origin) else start
	var ids := ground.get_id_path(start, goal)
	for cell in cells:
		if map.has_cell(cell):
			_refresh(cell)
	var result := PackedVector2Array()
	for cell: Vector2i in ids:
		if occupant_at(cell) == building.id:
			break
		result.append(map.center_of(cell))
	return result


func path_to_cell(grid: AStarGrid2D, from: Vector2, goal: Vector2i) -> PackedVector2Array:
	var start := map.cell_of(from)
	if not map.has_cell(start) or not map.has_cell(goal):
		return PackedVector2Array()
	var start_solid := grid.is_point_solid(start)
	var goal_solid := grid.is_point_solid(goal)
	grid.set_point_solid(start, false)
	grid.set_point_solid(goal, false)
	var ids := grid.get_id_path(start, goal)
	grid.set_point_solid(start, start_solid)
	grid.set_point_solid(goal, goal_solid)
	var result := PackedVector2Array()
	for cell: Vector2i in ids:
		if cell == goal and goal_solid:
			break
		result.append(map.center_of(cell))
	return result


func ground_path(from: Vector2, goal: Vector2i) -> PackedVector2Array:
	return path_to_cell(ground, from, goal)
