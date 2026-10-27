class_name TerrainPainter
extends RefCounted

const CHUNK := 12
const EDGE := 7.0
const GRASS: Array[Color] = [Color("#4f7a3e"), Color("#5d8a4c"), Color("#6d9a52")]
const FLOWERS: Array[Color] = [Color("#f2e36b"), Color("#f29bd1"), Color("#ffffff")]

var map: LevelMap


func _init(p_map: LevelMap) -> void:
	map = p_map


static func noise(cell: Vector2i, salt: int = 0) -> float:
	var value := (cell.x * 73856093) ^ (cell.y * 19349663) ^ (salt * 83492791)
	value = (value ^ (value >> 13)) * 1274126177
	return float((value ^ (value >> 16)) & 0xffff) / 65535.0


func chunk_count() -> Vector2i:
	return Vector2i(ceili(float(map.width) / CHUNK), ceili(float(map.height) / CHUNK))


func chunk_of(cell: Vector2i) -> Vector2i:
	return Vector2i(cell.x / CHUNK, cell.y / CHUNK)


func paint_border(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(Vector2(-2000, -2000), map.size + Vector2(4000, 4000)), AppTheme.GROUND_EDGE)


func paint_frame(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, map.size), Color(0, 0, 0, 0.45), false, 6.0)


func paint_chunk(ci: CanvasItem, chunk: Vector2i) -> void:
	var low := chunk * CHUNK
	var high := Vector2i(mini(low.x + CHUNK, map.width), mini(low.y + CHUNK, map.height))
	for y in range(low.y, high.y):
		for x in range(low.x, high.x):
			_ground(ci, Vector2i(x, y))
	for y in range(low.y, high.y):
		for x in range(low.x, high.x):
			_feature(ci, Vector2i(x, y))


func _rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * GameConfig.CELL, Vector2(GameConfig.CELL, GameConfig.CELL))


func _ground_color(cell: Vector2i) -> Color:
	var high := map.raw_height(cell) == 1
	var base := AppTheme.GROUND_HIGH if high else AppTheme.GROUND
	var light := AppTheme.GROUND_HIGH_LIGHT if high else AppTheme.GROUND_LIGHT
	var shade := noise(cell) * 0.35 + (0.12 if (cell.x / 3 + cell.y / 3) % 2 == 0 else 0.0)
	return base.lerp(light, shade)


func _ground(ci: CanvasItem, cell: Vector2i) -> void:
	var rect := _rect(cell)
	match map.tile(cell):
		LevelMap.Tile.CHASM:
			ci.draw_rect(rect, AppTheme.CHASM)
		LevelMap.Tile.RAMP:
			ci.draw_rect(rect, AppTheme.GROUND.lerp(AppTheme.GROUND_HIGH, 0.55).lerp(AppTheme.CLIFF_LIGHT, 0.12))
		_:
			ci.draw_rect(rect, _ground_color(cell))


func _feature(ci: CanvasItem, cell: Vector2i) -> void:
	match map.tile(cell):
		LevelMap.Tile.OPEN:
			_decor(ci, cell)
		LevelMap.Tile.RAMP:
			_ramp(ci, cell)
		LevelMap.Tile.CLIFF:
			_cliff(ci, cell)
		LevelMap.Tile.CHASM:
			_chasm(ci, cell)
		LevelMap.Tile.TREE:
			_tree(ci, cell)
		LevelMap.Tile.ROCK:
			_rock(ci, cell)


func _decor(ci: CanvasItem, cell: Vector2i) -> void:
	var roll := noise(cell, 1)
	if roll > 0.45:
		return
	var center := map.center_of(cell) + Vector2(noise(cell, 2) - 0.5, noise(cell, 3) - 0.5) * GameConfig.CELL * 0.7
	var scale := 0.7 + noise(cell, 4) * 0.7
	if roll < 0.06:
		ci.draw_circle(center, 2.6 * scale, FLOWERS[int(noise(cell, 5) * 2.99)])
	elif roll < 0.1:
		ci.draw_circle(center, 4.0 * scale, AppTheme.ROCK_DARK)
		ci.draw_circle(center - Vector2(1, 1), 2.5 * scale, AppTheme.ROCK)
	else:
		var color: Color = GRASS[int(noise(cell, 6) * 2.99)]
		for i in 3:
			var tip := center + Vector2((i - 1) * 4.0 * scale, -9.0 * scale)
			ci.draw_line(center + Vector2((i - 1) * 2.0, 0), tip, color, 2.0)


func _lower(cell: Vector2i, offset: Vector2i) -> bool:
	var other := cell + offset
	if not map.has_cell(other):
		return true
	return map.raw_height(other) == 0 and map.tile(other) != LevelMap.Tile.CLIFF and map.tile(other) != LevelMap.Tile.RAMP


func _ramp(ci: CanvasItem, cell: Vector2i) -> void:
	var rect := _rect(cell)
	var vertical := map.raw_height(cell + Vector2i(0, 1)) != map.raw_height(cell + Vector2i(0, -1))
	for i in range(1, 5):
		var t := i / 5.0
		if vertical:
			var y := rect.position.y + rect.size.y * t
			ci.draw_line(Vector2(rect.position.x + 4, y), Vector2(rect.end.x - 4, y), Color(AppTheme.CLIFF_DARK, 0.35), 2.0)
		else:
			var x := rect.position.x + rect.size.x * t
			ci.draw_line(Vector2(x, rect.position.y + 4), Vector2(x, rect.end.y - 4), Color(AppTheme.CLIFF_DARK, 0.35), 2.0)


func _cliff(ci: CanvasItem, cell: Vector2i) -> void:
	var rect := _rect(cell)
	ci.draw_rect(rect, AppTheme.CLIFF)
	var size := GameConfig.CELL
	if _lower(cell, Vector2i(0, 1)):
		ci.draw_rect(Rect2(rect.position + Vector2(0, size * 0.45), Vector2(size, size * 0.55)), AppTheme.CLIFF_DARK)
		ci.draw_rect(Rect2(rect.end - Vector2(size, 6.0), Vector2(size, 6.0)), Color(0, 0, 0, 0.35))
	if _lower(cell, Vector2i(0, -1)):
		ci.draw_rect(Rect2(rect.position, Vector2(size, 5.0)), AppTheme.CLIFF_LIGHT)
	if _lower(cell, Vector2i(-1, 0)):
		ci.draw_rect(Rect2(rect.position, Vector2(6.0, size)), Color(AppTheme.CLIFF_LIGHT, 0.7))
	if _lower(cell, Vector2i(1, 0)):
		ci.draw_rect(Rect2(rect.position + Vector2(size - 8.0, 0), Vector2(8.0, size)), Color(AppTheme.CLIFF_DARK, 0.85))
	for i in 3:
		var spot := rect.position + Vector2(noise(cell, 10 + i), noise(cell, 20 + i)) * size
		ci.draw_circle(spot, 3.0 + noise(cell, 30 + i) * 4.0, AppTheme.CLIFF_DARK.lerp(AppTheme.CLIFF_LIGHT, noise(cell, 40 + i)))


func _chasm(ci: CanvasItem, cell: Vector2i) -> void:
	var rect := _rect(cell)
	var size := GameConfig.CELL
	ci.draw_rect(rect.grow(-EDGE), AppTheme.CHASM_MID.lerp(AppTheme.CHASM, 0.5 + noise(cell) * 0.5))
	for offset: Vector2i in LevelMap.NEIGHBOURS:
		if map.tile(cell + offset) == LevelMap.Tile.CHASM:
			continue
		var band := Rect2(rect.position, Vector2(size, EDGE * 2.2))
		if offset.x > 0:
			band = Rect2(rect.position + Vector2(size - EDGE, 0), Vector2(EDGE, size))
		elif offset.x < 0:
			band = Rect2(rect.position, Vector2(EDGE, size))
		elif offset.y > 0:
			band = Rect2(rect.position + Vector2(0, size - EDGE), Vector2(size, EDGE))
		ci.draw_rect(band, AppTheme.CHASM_EDGE)


func _tree(ci: CanvasItem, cell: Vector2i) -> void:
	var center := map.center_of(cell) + Vector2(noise(cell, 7) - 0.5, noise(cell, 8) - 0.5) * 10.0
	var radius := GameConfig.CELL * (0.42 + noise(cell, 9) * 0.14)
	Painter.shadow(ci, center, radius * 0.9, 1.6)
	ci.draw_circle(center + Vector2(0, radius * 0.25), radius * 0.92, AppTheme.TREE_DARK)
	ci.draw_circle(center, radius * 0.8, AppTheme.TREE)
	ci.draw_circle(center + Vector2(-radius * 0.35, radius * 0.1), radius * 0.45, AppTheme.TREE.lerp(AppTheme.TREE_DARK, 0.3))
	ci.draw_circle(center + Vector2(radius * 0.3, -radius * 0.05), radius * 0.42, AppTheme.TREE.lerp(AppTheme.TREE_LIGHT, 0.3))
	ci.draw_circle(center - Vector2(radius * 0.25, radius * 0.3), radius * 0.28, AppTheme.TREE_LIGHT)


func _rock(ci: CanvasItem, cell: Vector2i) -> void:
	var center := map.center_of(cell)
	var radius := GameConfig.CELL * 0.48
	var points := PackedVector2Array()
	var phase := noise(cell, 11) * TAU
	for i in 9:
		var angle := TAU * i / 9.0
		points.append(center + Vector2.from_angle(angle) * radius * (0.8 + 0.2 * sin(angle * 4.0 + phase)))
	Painter.shadow(ci, center, radius, 1.5)
	ci.draw_colored_polygon(points, AppTheme.ROCK_DARK)
	var top := PackedVector2Array()
	for point in points:
		top.append(center + (point - center) * 0.76 - Vector2(3, 5))
	ci.draw_colored_polygon(top, AppTheme.ROCK)
	ci.draw_circle(center - Vector2(radius * 0.3, radius * 0.35), radius * 0.16, AppTheme.ROCK_LIGHT)
