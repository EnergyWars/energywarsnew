extends GutTest


func _state(level: int) -> BattleState:
	var state := BattleState.create(level, 1234)
	BattleFixtures.open_terrain(state)
	state.core_id = state.add_building(GameConfig.CORE, state.map.drop).id
	return state


func _renav(state: BattleState) -> void:
	state.nav = NavGrid.new(state.map)
	for building: Building in state.buildings.values():
		state.nav.occupy(building)


func _sites(state: BattleState, seed_value: int = 7) -> Array[Dictionary]:
	return StructurePlacer.new(state, seed_value).place(state.map.drop)


func _footprint(site: Dictionary) -> Rect2i:
	var cells := GameConfig.cells(str(site.kind))
	return Rect2i(LevelMap.footprint_origin(site.position, cells), Vector2i(cells, cells))


func test_sites_keep_the_level_order_and_kinds() -> void:
	var state := _state(GameConfig.level_count() - 1)
	var sites := _sites(state)
	assert_eq(sites.size(), state.map.structures.size())
	for i in sites.size():
		assert_eq(sites[i].kind, state.map.structures[i].kind)
		assert_true(state.map.contains(sites[i].position, GameConfig.CELL))


func test_spawners_land_far_from_the_core() -> void:
	for level in [0, 1, 6]:
		var state := _state(level)
		var placer := StructurePlacer.new(state, 11)
		var limit := StructurePlacer.far_limit(placer.candidates(GameConfig.cells(GameConfig.NEST), state.map.drop))
		assert_gte(limit, GameConfig.CORE_ENEMY_CLEAR)
		for site in placer.place(state.map.drop):
			if StructurePlacer.is_spawner(str(site.kind)):
				assert_gte((site.position as Vector2).distance_to(state.map.drop), limit - 0.01, str(level))


func test_spawners_keep_their_distance_from_each_other() -> void:
	var state := _state(1)
	var sites := _sites(state)
	var gap := (sites[0].position as Vector2).distance_to(sites[1].position)
	assert_gte(gap, GameConfig.STRUCTURE_SPACING * GameConfig.CELL)


func test_turrets_guard_a_spawner() -> void:
	var state := _state(3)
	var sites := _sites(state)
	var camp: Vector2 = sites[0].position
	assert_eq(sites[0].kind, GameConfig.CAMP)
	for i in range(1, sites.size()):
		assert_eq(sites[i].kind, GameConfig.TURRET)
		var gap := (sites[i].position as Vector2).distance_to(camp)
		assert_between(gap, GameConfig.TURRET_POST_RING.x * GameConfig.CELL, GameConfig.TURRET_POST_RING.y * GameConfig.CELL)
		assert_gte((sites[i].position as Vector2).distance_to(state.map.drop), GameConfig.CORE_ENEMY_CLEAR)


func test_sites_never_overlap_and_stand_on_open_ground() -> void:
	var state := _state(GameConfig.level_count() - 1)
	var sites := _sites(state)
	for i in sites.size():
		var rect := _footprint(sites[i])
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				assert_eq(state.map.tile(Vector2i(x, y)), LevelMap.Tile.OPEN)
				assert_true(state.nav.is_free(Vector2i(x, y)))
		for j in range(i + 1, sites.size()):
			assert_false(rect.grow(GameConfig.STRUCTURE_MARGIN).intersects(_footprint(sites[j])), "%d %d" % [i, j])


func test_candidates_skip_blocked_and_uneven_ground() -> void:
	var state := _state(0)
	var tree := Vector2i(10, 10)
	var high := Vector2i(20, 10)
	state.map.set_tile(tree, LevelMap.Tile.TREE)
	state.map.heights[state.map.index(high)] = 1
	_renav(state)
	var placer := StructurePlacer.new(state, 1)
	var core := state.core()
	for entry in placer.candidates(2, state.map.drop):
		var footprint := Rect2i(entry.origin, Vector2i(2, 2))
		var ring := footprint.grow(GameConfig.STRUCTURE_MARGIN)
		assert_false(ring.has_point(tree))
		assert_false(footprint.has_point(high))
		assert_false(ring.intersects(Rect2i(core.origin, Vector2i(core.cells(), core.cells()))))
	var singles := placer.candidates(1, state.map.drop).map(func(entry: Dictionary) -> Vector2i: return entry.origin)
	assert_true(singles.has(high))
	assert_same(placer.candidates(1, state.map.drop), placer.candidates(1, state.map.drop))


func test_unreachable_ground_is_skipped() -> void:
	var state := _state(0)
	var wall := 30
	for x in state.map.width:
		state.map.set_tile(Vector2i(x, wall), LevelMap.Tile.POND)
	_renav(state)
	var sites := _sites(state)
	assert_gt(state.map.cell_of(sites[0].position).y, wall)
	assert_gte((sites[0].position as Vector2).distance_to(state.map.drop), GameConfig.CORE_ENEMY_CLEAR)


func test_falls_back_to_the_default_sites_without_room() -> void:
	var state := _state(3)
	state.map.tiles.fill(LevelMap.Tile.TREE)
	_renav(state)
	var sites := _sites(state)
	for i in sites.size():
		assert_eq(sites[i].position, state.map.structures[i].position)


func test_far_limit_respects_the_minimum_clearance() -> void:
	assert_eq(StructurePlacer.far_limit([] as Array[Dictionary]), GameConfig.CORE_ENEMY_CLEAR)
	var list: Array[Dictionary] = [{"distance": 500.0}, {"distance": 4000.0}]
	assert_almost_eq(StructurePlacer.far_limit(list), 4000.0 * GameConfig.STRUCTURE_FAR_SHARE, 0.001)


func test_spawner_kinds() -> void:
	assert_true(StructurePlacer.is_spawner(GameConfig.NEST))
	assert_true(StructurePlacer.is_spawner(GameConfig.CAMP))
	assert_false(StructurePlacer.is_spawner(GameConfig.TURRET))
	assert_false(StructurePlacer.is_spawner(GameConfig.CORE))


func test_placement_is_deterministic_per_core_spot() -> void:
	var state := _state(2)
	var first := StructurePlacer.sites(state, state.map.drop)
	assert_eq(StructurePlacer.sites(state, state.map.drop), first)
	var elsewhere := StructurePlacer.sites(state, state.map.drop + Vector2(-900, -400))
	assert_ne(elsewhere, first)


func test_core_placement_spawns_structures_once() -> void:
	var state := BattleState.create(0, 1234)
	BattleFixtures.open_terrain(state)
	assert_false(state.structures_spawned)
	assert_true(state.enemy_buildings().is_empty())
	var core := state.place_core(state.map.drop)
	assert_true(state.structures_spawned)
	assert_eq(state.enemy_buildings().size(), GameConfig.level(0).structures.size())
	var nest: Building = state.enemy_buildings()[0]
	assert_eq(nest.kind, GameConfig.NEST)
	assert_true(nest.spawner)
	assert_false(nest.immune)
	assert_gte(nest.position.distance_to(core.position), GameConfig.CORE_ENEMY_CLEAR)
	assert_true(state.nav.walker.is_point_solid(nest.origin))
	state.place_core(state.map.drop + Vector2(0, -300))
	assert_eq(state.enemy_buildings().size(), GameConfig.level(0).structures.size())


func test_spawned_structures_are_immune_in_survival() -> void:
	var state := BattleState.create(3, 1234, BattleSetup.survival(5))
	BattleFixtures.open_terrain(state)
	var placed := state.spawn_structures(state.map.structures)
	assert_eq(placed.size(), state.map.structures.size())
	for building in placed:
		assert_eq(building.immune, building.spawner, building.kind)
	assert_true(state.spawn_structures([] as Array[Dictionary]).is_empty())
