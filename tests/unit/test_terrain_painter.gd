extends GutTest


func test_noise_is_deterministic_and_normalised() -> void:
	for x in 20:
		for y in 20:
			var value := TerrainPainter.noise(Vector2i(x, y), 3)
			assert_between(value, 0.0, 1.0)
			assert_eq(value, TerrainPainter.noise(Vector2i(x, y), 3))
	assert_ne(TerrainPainter.noise(Vector2i(4, 4), 1), TerrainPainter.noise(Vector2i(4, 4), 2))


func test_chunks_cover_the_map() -> void:
	var painter := TerrainPainter.new(LevelMap.blank(Vector2i(25, 13)))
	assert_eq(painter.chunk_count(), Vector2i(3, 2))
	assert_eq(painter.chunk_of(Vector2i(0, 0)), Vector2i.ZERO)
	assert_eq(painter.chunk_of(Vector2i(24, 12)), Vector2i(2, 1))


func test_every_tile_paints_without_errors() -> void:
	var map := LevelMap.blank(Vector2i(12, 12))
	var tiles := [LevelMap.Tile.RAMP, LevelMap.Tile.CLIFF, LevelMap.Tile.CHASM, LevelMap.Tile.TREE, LevelMap.Tile.ROCK]
	for i in tiles.size():
		map.set_tile(Vector2i(2 + i * 2, 5), tiles[i])
		map.set_tile(Vector2i(2 + i * 2, 6), tiles[i])
	map.heights[map.index(Vector2i(4, 4))] = 1
	var painter := TerrainPainter.new(map)
	var painted := [false]
	var layer := DrawLayer.new().setup(func(ci: CanvasItem) -> void:
		painter.paint_border(ci)
		painter.paint_chunk(ci, Vector2i.ZERO)
		painter.paint_frame(ci)
		painted[0] = true)
	add_child_autofree(layer)
	layer.queue_redraw()
	await wait_physics_frames(2)
	assert_true(painted[0])
