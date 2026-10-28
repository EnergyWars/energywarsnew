extends GutTest

var map: LevelMap
var nav: NavGrid


func before_each() -> void:
	map = LevelMap.blank(Vector2i(12, 10))
	nav = NavGrid.new(map)


func _building(kind: String, cell: Vector2i, id: int = 1) -> Building:
	var building := Building.new(id, kind, map.center_of(cell))
	nav.occupy(building)
	return building


func test_occupy_and_release() -> void:
	var wall := _building(GameConfig.BULWARK, Vector2i(3, 3))
	var version := nav.version
	assert_eq(nav.occupant_at(Vector2i(3, 3)), wall.id)
	assert_false(nav.is_free(Vector2i(3, 3)))
	assert_true(nav.ground.is_point_solid(Vector2i(3, 3)))
	assert_false(nav.walker.is_point_solid(Vector2i(3, 3)))
	nav.release(wall)
	assert_gt(nav.version, version)
	assert_true(nav.is_free(Vector2i(3, 3)))
	assert_false(nav.ground.is_point_solid(Vector2i(3, 3)))


func test_enemy_structures_block_the_scout() -> void:
	var nest := _building(GameConfig.NEST, Vector2i(6, 6))
	for cell in nest.footprint():
		assert_true(nav.walker.is_point_solid(cell))
	assert_eq(nest.footprint().size(), 4)


func test_terrain_changes_update_solidity() -> void:
	map.set_tile(Vector2i(2, 2), LevelMap.Tile.TREE)
	nav.terrain_changed(Vector2i(2, 2))
	assert_true(nav.ground.is_point_solid(Vector2i(2, 2)))
	assert_true(nav.walker.is_point_solid(Vector2i(2, 2)))
	map.clear(Vector2i(2, 2))
	nav.terrain_changed(Vector2i(2, 2))
	assert_false(nav.ground.is_point_solid(Vector2i(2, 2)))


func test_components_split_by_walls_and_report_reachable_buildings() -> void:
	var walls: Array[Building] = []
	for y in map.height:
		walls.append(_building(GameConfig.BULWARK, Vector2i(5, y), 10 + y))
	var left := nav.component(Vector2i(1, 1))
	var right := nav.component(Vector2i(9, 1))
	assert_ne(left, right)
	assert_eq(nav.component(Vector2i(5, 1)), -1)
	assert_true(nav.reachable(left).has(walls[0].id))
	var relay := _building(GameConfig.RELAY, Vector2i(9, 5), 99)
	assert_true(nav.reachable(right).has(relay.id))
	assert_false(nav.reachable(left).has(relay.id))
	nav.release(walls[4])
	assert_eq(nav.component(Vector2i(1, 1)), nav.component(Vector2i(9, 1)))


func test_component_at_uses_nearest_free_cell() -> void:
	var wall := _building(GameConfig.BULWARK, Vector2i(4, 4))
	assert_eq(nav.component_at(wall.position), nav.component(Vector2i(3, 4)))
	assert_eq(nav.nearest_free(map.center_of(Vector2i(1, 1))), Vector2i(1, 1))


func test_nearest_free_gives_up_when_enclosed() -> void:
	map.tiles.fill(LevelMap.Tile.CHASM)
	nav = NavGrid.new(map)
	assert_eq(nav.nearest_free(Vector2(10, 10)), Vector2i(-1, -1))
	assert_eq(nav.component_at(Vector2(10, 10)), -1)
	assert_true(nav.path_to_building(Vector2(10, 10), Building.new(1, GameConfig.RELAY, Vector2(100, 100))).is_empty())


func test_path_to_building_stops_in_front_of_it() -> void:
	var target := _building(GameConfig.RELAY, Vector2i(9, 5))
	var path := nav.path_to_building(map.center_of(Vector2i(1, 5)), target)
	assert_false(path.is_empty())
	assert_eq(path[0], map.center_of(Vector2i(1, 5)))
	assert_eq(map.cell_of(path[path.size() - 1]), Vector2i(8, 5))
	assert_true(nav.ground.is_point_solid(Vector2i(9, 5)))


func test_path_goes_around_walls() -> void:
	for y in range(0, map.height - 1):
		_building(GameConfig.BULWARK, Vector2i(5, y), 10 + y)
	var target := _building(GameConfig.RELAY, Vector2i(9, 1), 99)
	var path := nav.path_to_building(map.center_of(Vector2i(1, 1)), target)
	assert_false(path.is_empty())
	var passed_gap := false
	for point in path:
		assert_true(nav.is_free(map.cell_of(point)))
		passed_gap = passed_gap or map.cell_of(point) == Vector2i(5, map.height - 1)
	assert_true(passed_gap)


func test_cell_paths_trim_solid_goals() -> void:
	map.set_tile(Vector2i(6, 2), LevelMap.Tile.ROCK)
	nav.terrain_changed(Vector2i(6, 2))
	var path := nav.path_to_cell(nav.walker, map.center_of(Vector2i(1, 2)), Vector2i(6, 2))
	assert_eq(map.cell_of(path[path.size() - 1]), Vector2i(5, 2))
	assert_true(nav.walker.is_point_solid(Vector2i(6, 2)))
	var open_path := nav.ground_path(map.center_of(Vector2i(1, 2)), Vector2i(3, 2))
	assert_eq(map.cell_of(open_path[open_path.size() - 1]), Vector2i(3, 2))
	assert_true(nav.ground_path(Vector2(-100, -100), Vector2i(3, 2)).is_empty())


func test_blocked_queries() -> void:
	_building(GameConfig.BULWARK, Vector2i(2, 2))
	assert_true(nav.is_blocked_at(map.center_of(Vector2i(2, 2))))
	assert_false(nav.is_blocked_at(map.center_of(Vector2i(3, 2))))
	assert_eq(nav.occupant_at(Vector2i(-1, 0)), NavGrid.FREE)
