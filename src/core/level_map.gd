class_name LevelMap
extends RefCounted

enum Tile { OPEN, RAMP, CLIFF, CHASM, TREE, ROCK }

const TREE := "tree"
const ROCK := "rock"
const NEIGHBOURS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var width := 0
var height := 0
var size := Vector2.ZERO
var drop := Vector2.ZERO
var structures: Array[Dictionary] = []
var tiles := PackedByteArray()
var heights := PackedByteArray()
var version := 0


static func create(level: Dictionary) -> LevelMap:
	return MapGenerator.generate(level)


static func blank(cells: Vector2i) -> LevelMap:
	var map := LevelMap.new()
	map.width = cells.x
	map.height = cells.y
	map.size = Vector2(cells) * GameConfig.CELL
	map.tiles.resize(cells.x * cells.y)
	map.tiles.fill(Tile.OPEN)
	map.heights.resize(cells.x * cells.y)
	map.heights.fill(0)
	return map


static func footprint_origin(position: Vector2, cells: int) -> Vector2i:
	return Vector2i(roundi(position.x / GameConfig.CELL - cells * 0.5), roundi(position.y / GameConfig.CELL - cells * 0.5))


static func footprint_center(origin: Vector2i, cells: int) -> Vector2:
	return (Vector2(origin) + Vector2(cells, cells) * 0.5) * GameConfig.CELL


static func snap(position: Vector2, cells: int) -> Vector2:
	return footprint_center(footprint_origin(position, cells), cells)


static func footprint(origin: Vector2i, cells: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in cells:
		for x in cells:
			result.append(origin + Vector2i(x, y))
	return result


func cell_of(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / GameConfig.CELL), floori(position.y / GameConfig.CELL))


func center_of(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * GameConfig.CELL


func has_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func index(cell: Vector2i) -> int:
	return cell.y * width + cell.x


func cell_at(index_value: int) -> Vector2i:
	return Vector2i(index_value % width, index_value / width)


func tile(cell: Vector2i) -> int:
	return tiles[index(cell)] if has_cell(cell) else Tile.CLIFF


func set_tile(cell: Vector2i, value: int) -> void:
	if has_cell(cell):
		tiles[index(cell)] = value
		version += 1


func elevation(cell: Vector2i) -> int:
	return heights[index(cell)] if has_cell(cell) and tiles[index(cell)] != Tile.RAMP else 0


func raw_height(cell: Vector2i) -> int:
	return heights[index(cell)] if has_cell(cell) else 0


func elevation_at(position: Vector2) -> int:
	return elevation(cell_of(position))


func is_walkable(cell: Vector2i) -> bool:
	var value := tile(cell)
	return has_cell(cell) and (value == Tile.OPEN or value == Tile.RAMP)


func is_buildable(cell: Vector2i) -> bool:
	return is_walkable(cell)


func is_clearable(cell: Vector2i) -> bool:
	var value := tile(cell)
	return has_cell(cell) and (value == Tile.TREE or value == Tile.ROCK)


func obstacle_type(cell: Vector2i) -> String:
	match tile(cell):
		Tile.TREE:
			return TREE
		Tile.ROCK:
			return ROCK
	return ""


func clear(cell: Vector2i) -> bool:
	if not is_clearable(cell):
		return false
	set_tile(cell, Tile.OPEN)
	return true


func contains(position: Vector2, radius: float = 0.0) -> bool:
	return position.x >= radius and position.y >= radius and position.x <= size.x - radius and position.y <= size.y - radius


func walkable_components() -> PackedInt32Array:
	var labels := PackedInt32Array()
	labels.resize(width * height)
	labels.fill(-1)
	var next := 0
	var queue := PackedInt32Array()
	for start in width * height:
		if labels[start] >= 0 or not is_walkable(cell_at(start)):
			continue
		labels[start] = next
		queue.clear()
		queue.append(start)
		var head := 0
		while head < queue.size():
			var cell := cell_at(queue[head])
			head += 1
			for offset in NEIGHBOURS:
				var other := cell + offset
				if is_walkable(other) and labels[index(other)] < 0:
					labels[index(other)] = next
					queue.append(index(other))
		next += 1
	return labels
