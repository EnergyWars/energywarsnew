extends GutTest


func test_create_scales_grid_to_pixels() -> void:
	var level := GameConfig.level(0)
	var map := LevelMap.create(level)
	assert_eq(Vector2i(map.width, map.height), level.cells as Vector2i)
	assert_eq(map.size, Vector2(level.cells as Vector2i) * GameConfig.CELL)
	assert_eq(map.tiles.size(), map.width * map.height)
	assert_eq(map.structures.size(), level.structures.size())


func test_maps_are_much_larger_than_the_screen() -> void:
	for index in GameConfig.level_count():
		var map := LevelMap.create(GameConfig.level(index))
		assert_gt(map.size.x * map.size.y, 2800.0 * 3500.0, str(index))


func test_generation_is_deterministic() -> void:
	var first := LevelMap.create(GameConfig.level(2))
	var second := LevelMap.create(GameConfig.level(2))
	assert_eq(first.tiles, second.tiles)
	assert_eq(first.heights, second.heights)


func test_every_level_has_all_terrain_features() -> void:
	for index in GameConfig.level_count():
		var map := LevelMap.create(GameConfig.level(index))
		var seen := {}
		for value in map.tiles:
			seen[value] = true
		for tile in [LevelMap.Tile.OPEN, LevelMap.Tile.RAMP, LevelMap.Tile.CLIFF, LevelMap.Tile.CHASM, LevelMap.Tile.TREE, LevelMap.Tile.ROCK, LevelMap.Tile.POND]:
			assert_true(seen.has(tile), "%d %d" % [index, tile])
		assert_true(map.heights.has(1), str(index))


func test_walkable_terrain_is_fully_connected() -> void:
	for index in GameConfig.level_count():
		var map := LevelMap.create(GameConfig.level(index))
		var labels := map.walkable_components()
		var drop := labels[map.index(map.cell_of(map.drop))]
		assert_gte(drop, 0)
		for i in labels.size():
			if labels[i] >= 0 and labels[i] != drop:
				fail_test("level %d cell %s is cut off" % [index, map.cell_at(i)])
				return


func test_drop_zone_and_structures_are_clear() -> void:
	for index in GameConfig.level_count():
		var map := LevelMap.create(GameConfig.level(index))
		assert_true(map.is_buildable(map.cell_of(map.drop)))
		for structure in map.structures:
			var origin := LevelMap.footprint_origin(structure.position, GameConfig.cells(structure.kind))
			for cell in LevelMap.footprint(origin, GameConfig.cells(structure.kind)):
				assert_true(map.is_walkable(cell), "%d %s" % [index, structure.kind])


func test_plateau_ramps_reach_high_ground() -> void:
	var map := LevelMap.create(GameConfig.level(0))
	var found := false
	for i in map.tiles.size():
		var cell := map.cell_at(i)
		if map.tile(cell) != LevelMap.Tile.RAMP:
			continue
		var high := false
		var low := false
		for offset in LevelMap.NEIGHBOURS:
			if map.is_walkable(cell + offset) and map.tile(cell + offset) == LevelMap.Tile.OPEN:
				high = high or map.elevation(cell + offset) == 1
				low = low or map.elevation(cell + offset) == 0
		found = found or (high and low)
	assert_true(found)


func test_cell_helpers() -> void:
	var map := LevelMap.blank(Vector2i(10, 8))
	assert_eq(map.size, Vector2(10, 8) * GameConfig.CELL)
	assert_eq(map.cell_of(Vector2(GameConfig.CELL * 2.5, GameConfig.CELL * 1.2)), Vector2i(2, 1))
	assert_eq(map.center_of(Vector2i(2, 1)), Vector2(2.5, 1.5) * GameConfig.CELL)
	assert_eq(map.cell_at(map.index(Vector2i(3, 4))), Vector2i(3, 4))
	assert_false(map.has_cell(Vector2i(-1, 0)))
	assert_false(map.has_cell(Vector2i(10, 0)))
	assert_eq(map.tile(Vector2i(-1, 0)), LevelMap.Tile.CLIFF)
	assert_false(map.is_walkable(Vector2i(99, 99)))
	assert_true(map.contains(Vector2(5, 5)))
	assert_false(map.contains(Vector2(5, 5), 10.0))
	assert_eq(map.edge_distance(Vector2i(0, 4)), 0)
	assert_eq(map.edge_distance(Vector2i(9, 4)), 0)
	assert_eq(map.edge_distance(Vector2i(4, 7)), 0)
	assert_eq(map.edge_distance(Vector2i(3, 2)), 2)
	assert_eq(map.edge_distance(Vector2i(5, 4)), 3)


func test_footprint_snapping() -> void:
	var cell := GameConfig.CELL
	assert_eq(LevelMap.snap(Vector2(cell * 3.2, cell * 4.9), 1), Vector2(3.5, 4.5) * cell)
	assert_eq(LevelMap.snap(Vector2(cell * 3.2, cell * 4.9), 2), Vector2(3, 5) * cell)
	assert_eq(LevelMap.footprint(Vector2i(1, 2), 2), [Vector2i(1, 2), Vector2i(2, 2), Vector2i(1, 3), Vector2i(2, 3)] as Array[Vector2i])


func test_elevation_ignores_ramps() -> void:
	var map := LevelMap.blank(Vector2i(4, 4))
	map.heights[map.index(Vector2i(1, 1))] = 1
	map.heights[map.index(Vector2i(2, 1))] = 1
	map.set_tile(Vector2i(2, 1), LevelMap.Tile.RAMP)
	assert_eq(map.elevation(Vector2i(1, 1)), 1)
	assert_eq(map.elevation(Vector2i(2, 1)), 0)
	assert_eq(map.raw_height(Vector2i(2, 1)), 1)
	assert_eq(map.elevation_at(map.center_of(Vector2i(1, 1))), 1)


func test_clearing_obstacles() -> void:
	var map := LevelMap.blank(Vector2i(4, 4))
	map.set_tile(Vector2i(1, 1), LevelMap.Tile.TREE)
	map.set_tile(Vector2i(2, 1), LevelMap.Tile.ROCK)
	map.set_tile(Vector2i(3, 1), LevelMap.Tile.CHASM)
	map.set_tile(Vector2i(0, 1), LevelMap.Tile.CLIFF)
	assert_eq(map.obstacle_type(Vector2i(1, 1)), LevelMap.TREE)
	assert_eq(map.obstacle_type(Vector2i(2, 1)), LevelMap.ROCK)
	assert_eq(map.obstacle_type(Vector2i(3, 1)), "")
	assert_false(map.is_walkable(Vector2i(1, 1)))
	assert_true(map.clear(Vector2i(1, 1)))
	assert_true(map.is_walkable(Vector2i(1, 1)))
	assert_true(map.clear(Vector2i(2, 1)))
	assert_false(map.clear(Vector2i(3, 1)))
	assert_false(map.clear(Vector2i(0, 1)))
	assert_false(map.is_walkable(Vector2i(3, 1)))


func test_connect_all_carves_through_blockers() -> void:
	var map := LevelMap.blank(Vector2i(7, 3))
	for y in 3:
		map.set_tile(Vector2i(2, y), LevelMap.Tile.CHASM)
		map.set_tile(Vector2i(4, y), LevelMap.Tile.CLIFF)
	assert_eq(_component_count(map), 3)
	MapGenerator.connect_all(map, Vector2i(0, 0))
	assert_eq(_component_count(map), 1)


func test_connect_all_fords_ponds() -> void:
	var map := LevelMap.blank(Vector2i(5, 3))
	for y in 3:
		map.set_tile(Vector2i(2, y), LevelMap.Tile.POND)
	assert_eq(_component_count(map), 2)
	MapGenerator.connect_all(map, Vector2i(0, 0))
	assert_eq(_component_count(map), 1)
	assert_eq(map.tiles.count(LevelMap.Tile.POND), 2)


func test_ponds_block_walking_building_and_clearing() -> void:
	var map := LevelMap.blank(Vector2i(4, 4))
	var cell := Vector2i(1, 2)
	map.set_tile(cell, LevelMap.Tile.POND)
	assert_false(map.is_walkable(cell))
	assert_false(map.is_buildable(cell))
	assert_false(map.is_clearable(cell))
	assert_eq(map.obstacle_type(cell), "")
	assert_false(map.clear(cell))
	assert_eq(map.tile(cell), LevelMap.Tile.POND)
	assert_true(NavGrid.new(map).ground.is_point_solid(cell))


func test_blob_covers_a_round_area_inside_the_map() -> void:
	var generator := MapGenerator.new().prepare(LevelMap.blank(Vector2i(30, 30)), 1)
	var cells := generator.blob(Vector2i(15, 15), 4.0, 0.0, 0.0)
	assert_true(cells.has(Vector2i(15, 15)))
	assert_true(cells.has(Vector2i(19, 15)))
	assert_false(cells.has(Vector2i(19, 19)))
	for cell in cells:
		assert_lte(Vector2(cell - Vector2i(15, 15)).length(), 4.0)
	var corner := generator.blob(Vector2i(0, 0), 4.0, 0.0, 0.0)
	assert_gt(corner.size(), 0)
	assert_lt(corner.size(), cells.size())
	for cell in corner:
		assert_true(generator.map.has_cell(cell))


func test_groves_are_large_and_solid() -> void:
	var generator := MapGenerator.new().prepare(LevelMap.blank(Vector2i(40, 40)), 3)
	var center := Vector2i(20, 20)
	generator.grove_at(center)
	var map := generator.map
	var core := MapGenerator.GROVE_RADIUS.x * MapGenerator.GROVE_CORE
	var trees := 0
	for index in map.tiles.size():
		var cell := map.cell_at(index)
		if map.tile(cell) == LevelMap.Tile.TREE:
			trees += 1
			assert_lte(Vector2(cell - center).length(), MapGenerator.GROVE_RADIUS.y * (1.0 + MapGenerator.GROVE_WOBBLE))
		elif Vector2(cell - center).length() <= core:
			fail_test("grove core has a gap at %s" % cell)
	assert_gt(trees, int(PI * core * core))
	assert_gt(MapGenerator.GROVE_RADIUS.x, MapGenerator.FOREST_RADIUS.y)


func test_forests_and_ponds_respect_protection_and_height() -> void:
	var generator := MapGenerator.new().prepare(LevelMap.blank(Vector2i(30, 30)), 4)
	var map := generator.map
	generator.protect_around(Vector2i(8, 8), 2)
	generator.forest_at(Vector2i(8, 8))
	assert_eq(map.tile(Vector2i(8, 8)), LevelMap.Tile.OPEN)
	for y in range(16, 29):
		for x in range(16, 29):
			map.heights[map.index(Vector2i(x, y))] = 1
	assert_eq(generator.pond_at(Vector2i(22, 22)), 0)
	assert_eq(map.tiles.count(LevelMap.Tile.POND), 0)
	var placed := generator.pond_at(Vector2i(8, 22))
	assert_eq(map.tiles.count(LevelMap.Tile.POND), placed)
	assert_eq(map.tile(Vector2i(8, 22)), LevelMap.Tile.POND)
	for offset in LevelMap.NEIGHBOURS:
		assert_eq(map.tile(Vector2i(8, 22) + offset), LevelMap.Tile.POND)


func _component_count(map: LevelMap) -> int:
	var labels := {}
	for value in map.walkable_components():
		if value >= 0:
			labels[value] = true
	return labels.size()


func test_footprint_center_and_clearable() -> void:
	assert_eq(LevelMap.footprint_center(Vector2i(2, 3), 1), Vector2(2.5, 3.5) * GameConfig.CELL)
	assert_eq(LevelMap.footprint_center(Vector2i(2, 3), 2), Vector2(3, 4) * GameConfig.CELL)
	var map := LevelMap.blank(Vector2i(6, 6))
	map.set_tile(Vector2i(1, 1), LevelMap.Tile.TREE)
	map.set_tile(Vector2i(2, 1), LevelMap.Tile.ROCK)
	map.set_tile(Vector2i(3, 1), LevelMap.Tile.CLIFF)
	assert_true(map.is_clearable(Vector2i(1, 1)))
	assert_true(map.is_clearable(Vector2i(2, 1)))
	assert_false(map.is_clearable(Vector2i(3, 1)))
	assert_false(map.is_clearable(Vector2i(-1, 1)))


func test_slime_blocks_building_but_not_walking() -> void:
	var map := LevelMap.blank(Vector2i(6, 6))
	var cell := Vector2i(2, 3)
	assert_true(map.is_buildable(cell))
	assert_false(map.is_slimed(cell))
	map.slime[map.index(cell)] = 1
	assert_true(map.is_slimed(cell))
	assert_false(map.is_buildable(cell))
	assert_true(map.is_walkable(cell))
	assert_false(map.is_slimed(Vector2i(-1, 0)))


func test_sealed_cells_are_reported_inside_the_map_only() -> void:
	var map := LevelMap.blank(Vector2i(6, 6))
	map.sealed[map.index(Vector2i(1, 1))] = 1
	assert_true(map.is_sealed(Vector2i(1, 1)))
	assert_false(map.is_sealed(Vector2i(2, 1)))
	assert_false(map.is_sealed(Vector2i(9, 9)))
	assert_false(LevelMap.new().is_sealed(Vector2i.ZERO))
	assert_false(LevelMap.new().is_slimed(Vector2i.ZERO))
