class_name MapGenerator
extends RefCounted

const DROP_CLEAR := 4
const STRUCTURE_CLEAR := 4
const PLATEAU_MIN := 4
const PLATEAU_MAX := 7
const PLATEAU_GAP := 4
const EDGE_MARGIN := 3
const ATTEMPTS := 40
const RAMP_DIRECTIONS: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]

var map: LevelMap
var rng := RandomNumberGenerator.new()
var protected := PackedByteArray()
var plateaus: Array[Dictionary] = []


static func generate(level: Dictionary) -> LevelMap:
	var generator := MapGenerator.new()
	generator.build(level)
	return generator.map


func build(level: Dictionary) -> void:
	var cells: Vector2i = level.cells
	map = LevelMap.blank(cells)
	rng.seed = int(level.seed)
	map.drop = map.center_of(Vector2i(Vector2(cells) * (level.drop as Vector2)))
	for entry: Array in level.structures:
		var kind: String = entry[0]
		var count := GameConfig.cells(kind)
		var origin := LevelMap.footprint_origin(Vector2(cells) * (entry[1] as Vector2) * GameConfig.CELL, count)
		map.structures.append({"kind": kind, "position": LevelMap.footprint_center(origin, count)})
	_protect()
	var terrain: Dictionary = level.get("terrain", {})
	for spot: Array in terrain.get("spots", []):
		var center := Vector2i(Vector2(cells) * (spot[0] as Vector2))
		var ramps: Array[Vector2i] = []
		for direction: Vector2i in spot[2]:
			ramps.append(direction)
		_plateau(center, int(spot[1]), ramps)
	for i in int(terrain.get("plateaus", 0)):
		_random_plateau()
	for i in int(terrain.get("chasms", 0)):
		_chasm()
	for i in int(terrain.get("forests", 0)):
		_forest()
	for i in int(terrain.get("rocks", 0)):
		_rocks()
	connect_all(map, map.cell_of(map.drop))


func _protect() -> void:
	protected.resize(map.width * map.height)
	protected.fill(0)
	_protect_around(map.cell_of(map.drop), DROP_CLEAR)
	for structure in map.structures:
		_protect_around(map.cell_of(structure.position), STRUCTURE_CLEAR + GameConfig.cells(structure.kind))


func _protect_around(center: Vector2i, radius: int) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var cell := Vector2i(x, y)
			if map.has_cell(cell) and Vector2(cell - center).length() <= radius + 0.5:
				protected[map.index(cell)] = 1


func is_protected(cell: Vector2i) -> bool:
	return map.has_cell(cell) and protected[map.index(cell)] == 1


func _random_plateau() -> void:
	for attempt in ATTEMPTS:
		var radius := rng.randi_range(PLATEAU_MIN, PLATEAU_MAX)
		var margin := radius + EDGE_MARGIN
		if map.width <= margin * 2 or map.height <= margin * 2:
			return
		var center := Vector2i(rng.randi_range(margin, map.width - margin - 1), rng.randi_range(margin, map.height - margin - 1))
		if not _plateau_fits(center, radius):
			continue
		var ramps: Array[Vector2i] = []
		var shuffled := RAMP_DIRECTIONS.duplicate()
		for i in shuffled.size():
			var j := rng.randi_range(i, shuffled.size() - 1)
			var swap: Vector2i = shuffled[i]
			shuffled[i] = shuffled[j]
			shuffled[j] = swap
		for i in rng.randi_range(1, 2):
			ramps.append(shuffled[i])
		_plateau(center, radius, ramps)
		return


func _plateau_fits(center: Vector2i, radius: int) -> bool:
	for other in plateaus:
		if Vector2(center - (other.center as Vector2i)).length() < radius + int(other.radius) + PLATEAU_GAP:
			return false
	for y in range(center.y - radius - 1, center.y + radius + 2):
		for x in range(center.x - radius - 1, center.x + radius + 2):
			if is_protected(Vector2i(x, y)):
				return false
	return true


func _plateau(center: Vector2i, radius: int, ramps: Array[Vector2i]) -> void:
	plateaus.append({"center": center, "radius": radius})
	var phase_a := rng.randf() * TAU
	var phase_b := rng.randf() * TAU
	var cells: Array[Vector2i] = []
	for y in range(center.y - radius - 2, center.y + radius + 3):
		for x in range(center.x - radius - 2, center.x + radius + 3):
			var cell := Vector2i(x, y)
			if not map.has_cell(cell) or is_protected(cell):
				continue
			var offset := Vector2(cell - center)
			var angle := offset.angle()
			var limit := radius * (1.0 + 0.16 * sin(angle * 3.0 + phase_a) + 0.08 * sin(angle * 5.0 + phase_b))
			if offset.length() <= limit:
				map.heights[map.index(cell)] = 1
				cells.append(cell)
	for cell in cells:
		for offset in LevelMap.NEIGHBOURS:
			if not map.has_cell(cell + offset) or map.raw_height(cell + offset) == 0:
				map.set_tile(cell, LevelMap.Tile.CLIFF)
				break
	for direction in ramps:
		_ramp(center, direction)


func _ramp(center: Vector2i, direction: Vector2i) -> void:
	var cell := center
	while map.has_cell(cell + direction) and map.raw_height(cell + direction) == 1:
		cell += direction
	if not map.has_cell(cell + direction):
		return
	var side := Vector2i(direction.y, direction.x)
	for lateral in [-1, 0, 1]:
		for depth in [0, -1]:
			var target: Vector2i = cell + side * lateral + direction * depth
			if map.tile(target) == LevelMap.Tile.CLIFF:
				map.set_tile(target, LevelMap.Tile.RAMP)


func _chasm() -> void:
	var position := Vector2(rng.randf_range(0.0, map.width), rng.randf_range(map.height * 0.25, map.height * 0.75))
	var direction := Vector2.from_angle(rng.randf() * TAU)
	var length := rng.randi_range(18, 34)
	var width := rng.randi_range(1, 2)
	var bridge := rng.randi_range(7, 11)
	for step in length:
		position += direction
		direction = direction.rotated(rng.randf_range(-0.35, 0.35))
		bridge -= 1
		if bridge <= 0:
			if bridge <= -2:
				bridge = rng.randi_range(7, 11)
			continue
		for w in width:
			var cell := Vector2i(position + direction.orthogonal() * w)
			if map.has_cell(cell) and not is_protected(cell) and map.raw_height(cell) == 0 and map.tile(cell) == LevelMap.Tile.OPEN:
				map.set_tile(cell, LevelMap.Tile.CHASM)


func _forest() -> void:
	var center := Vector2i(rng.randi_range(0, map.width - 1), rng.randi_range(0, map.height - 1))
	var radius := rng.randf_range(2.0, 5.0)
	var phase := rng.randf() * TAU
	for y in range(center.y - 6, center.y + 7):
		for x in range(center.x - 6, center.x + 7):
			var cell := Vector2i(x, y)
			var offset := Vector2(cell - center)
			var limit := radius * (1.0 + 0.25 * sin(offset.angle() * 3.0 + phase))
			if offset.length() <= limit and rng.randf() < 0.85:
				_place(cell, LevelMap.Tile.TREE)


func _rocks() -> void:
	var cell := Vector2i(rng.randi_range(0, map.width - 1), rng.randi_range(0, map.height - 1))
	for i in rng.randi_range(1, 4):
		_place(cell, LevelMap.Tile.ROCK)
		cell += LevelMap.NEIGHBOURS[rng.randi_range(0, 3)]


func _place(cell: Vector2i, value: int) -> void:
	if map.has_cell(cell) and not is_protected(cell) and map.tile(cell) == LevelMap.Tile.OPEN:
		map.set_tile(cell, value)


static func connect_all(target: LevelMap, anchor: Vector2i) -> void:
	var labels := target.walkable_components()
	if not target.has_cell(anchor) or labels[target.index(anchor)] < 0:
		return
	var main := labels[target.index(anchor)]
	var parents := PackedInt32Array()
	parents.resize(target.width * target.height)
	parents.fill(-2)
	var queue := PackedInt32Array()
	for i in labels.size():
		if labels[i] == main:
			parents[i] = -1
			queue.append(i)
	var joined := {main: true}
	var head := 0
	while head < queue.size():
		var current := queue[head]
		head += 1
		var cell := target.cell_at(current)
		for offset in LevelMap.NEIGHBOURS:
			var other := cell + offset
			if not target.has_cell(other) or parents[target.index(other)] != -2:
				continue
			var other_index := target.index(other)
			parents[other_index] = current
			queue.append(other_index)
			var label := labels[other_index]
			if label >= 0 and not joined.has(label):
				joined[label] = true
				_carve(target, parents, current)
	target.version += 1


static func _carve(target: LevelMap, parents: PackedInt32Array, from: int) -> void:
	var current := from
	while current >= 0:
		var cell := target.cell_at(current)
		match target.tile(cell):
			LevelMap.Tile.CLIFF:
				target.set_tile(cell, LevelMap.Tile.RAMP)
			LevelMap.Tile.CHASM, LevelMap.Tile.TREE, LevelMap.Tile.ROCK:
				target.set_tile(cell, LevelMap.Tile.OPEN)
		current = parents[current]
