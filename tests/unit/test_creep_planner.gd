extends GutTest

const SIZE := Vector2i(52, 64)
const CORE := Vector2i(26, 53)


func _map() -> LevelMap:
	return LevelMap.blank(SIZE)


func _planner(map: LevelMap, core: Vector2i = CORE, seed_value: int = 7) -> CreepPlanner:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return CreepPlanner.new(map, core, rng, map.is_walkable)


func _coverable(planner: CreepPlanner, cell: Vector2i) -> bool:
	for offset in Creep.disk():
		var site := cell + offset
		if planner.map.has_cell(site) and planner.allowed[planner.map.index(site)] != 0:
			return true
	return false


func _needed_cells(planner: CreepPlanner) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for i in planner.needed.size():
		if planner.needed[i] != 0:
			result.append(planner.map.cell_at(i))
	return result


func _pond(map: LevelMap, center: Vector2i, radius: int) -> void:
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if x * x + y * y <= radius * radius:
				map.set_tile(center + Vector2i(x, y), LevelMap.Tile.POND)


func test_derived_geometry_matches_the_radius() -> void:
	assert_eq(CreepPlanner.inner_radius(), GameConfig.CREEP_CORE_CLEAR - GameConfig.CREEP_RADIUS + GameConfig.CREEP_FRINGE)
	var spacing := CreepPlanner.lattice_spacing()
	assert_eq(spacing, Vector2i(10, 9))
	var half := spacing.x * 0.5
	var lift := (spacing.y * spacing.y - half * half) / (2.0 * spacing.y)
	assert_lte(sqrt(half * half + lift * lift), GameConfig.CREEP_RADIUS)
	assert_eq(CreepPlanner.ring_steps(), 13)


func test_snap_offsets_start_at_the_target_and_grow_outwards() -> void:
	var offsets := CreepPlanner.snap_offsets()
	assert_eq(offsets[0], Vector2i.ZERO)
	assert_eq(offsets.size(), 29)
	for i in range(1, offsets.size()):
		assert_lte(offsets[i - 1].length_squared(), offsets[i].length_squared())
	assert_eq(CreepPlanner.snap_offsets(), offsets)


func test_masks_follow_the_core_distance_and_the_fit_check() -> void:
	var map := _map()
	map.set_tile(Vector2i(2, 2), LevelMap.Tile.ROCK)
	var planner := _planner(map)
	assert_eq(planner.needed[map.index(CORE + Vector2i(0, -10))], 0)
	assert_eq(planner.needed[map.index(CORE + Vector2i(0, -11))], 1)
	assert_eq(planner.allowed[map.index(CORE + Vector2i(0, -15))], 0)
	assert_eq(planner.allowed[map.index(CORE + Vector2i(0, -16))], 1)
	assert_eq(planner.allowed[map.index(Vector2i(2, 2))], 0)
	assert_eq(planner.needed[map.index(Vector2i(2, 2))], 1)


func test_every_coverable_cell_is_covered() -> void:
	var map := _map()
	_pond(map, Vector2i(14, 20), 9)
	var planner := _planner(map)
	planner.plan()
	var holes := 0
	for cell in _needed_cells(planner):
		if planner.coverage(cell) == 0:
			assert_false(_coverable(planner, cell), str(cell))
			holes += 1
	assert_gt(holes, 0)


func test_the_inner_fringe_around_the_core_is_covered_too() -> void:
	var map := LevelMap.blank(Vector2i(60, 60))
	var core := Vector2i(30, 30)
	var planner := _planner(map, core)
	planner.plan()
	for i in planner.needed.size():
		var cell := map.cell_at(i)
		var gap := Vector2(cell - core).length()
		if gap >= CreepPlanner.inner_radius() and gap <= GameConfig.CREEP_CORE_CLEAR:
			assert_gt(planner.coverage(cell), 0, str(cell))


func test_sites_stand_on_allowed_cells_only_once() -> void:
	var map := _map()
	_pond(map, Vector2i(30, 15), 5)
	var planner := _planner(map)
	var sites := planner.plan()
	var seen := {}
	for site in sites:
		assert_eq(planner.allowed[map.index(site)], 1, str(site))
		assert_gte(Vector2(site - CORE).length(), GameConfig.CREEP_CORE_CLEAR, str(site))
		assert_false(seen.has(site), str(site))
		seen[site] = true


func test_first_site_is_the_farthest_rim_cell() -> void:
	var map := _map()
	var planner := _planner(map)
	var sites := planner.plan()
	var first := sites[0]
	assert_lt(map.edge_distance(first), GameConfig.CREEP_RIM)
	for i in planner.allowed.size():
		var cell := map.cell_at(i)
		if planner.allowed[i] != 0 and map.edge_distance(cell) < GameConfig.CREEP_RIM:
			assert_lte((cell - CORE).length_squared(), (first - CORE).length_squared())


func test_every_site_but_the_first_covers_something_alone() -> void:
	var map := _map()
	_pond(map, Vector2i(12, 12), 4)
	var planner := _planner(map)
	var sites := planner.plan()
	for k in range(1, sites.size()):
		var alone := false
		for offset in Creep.disk():
			var cell := sites[k] + offset
			if map.has_cell(cell) and planner.needed[map.index(cell)] != 0 and planner.coverage(cell) == 1:
				alone = true
				break
		assert_true(alone, str(sites[k]))


func test_open_terrain_needs_few_nests_with_little_overlap() -> void:
	var map := _map()
	var planner := _planner(map)
	var sites := planner.plan()
	var covered := 0
	var layers := 0
	var triple := 0
	for cell in _needed_cells(planner):
		var count := planner.coverage(cell)
		if count == 0:
			continue
		covered += 1
		layers += count
		triple += 1 if count >= 3 else 0
	assert_lte(sites.size(), 50)
	assert_lte(float(layers) / covered, 1.6)
	assert_lte(float(triple) / covered, 0.12)


func test_plan_is_deterministic_per_seed() -> void:
	var map := _map()
	var first := _planner(map, CORE, 3).plan()
	var second := _planner(map, CORE, 3).plan()
	assert_eq(first, second)


func test_planning_twice_starts_over() -> void:
	var planner := _planner(_map())
	var first := planner.plan().duplicate()
	var second := planner.plan()
	assert_eq(second[0], first[0])
	assert_lte(second.size(), 50)
	var seen := {}
	for site in second:
		assert_false(seen.has(site), str(site))
		seen[site] = true


func test_no_allowed_cell_means_no_sites() -> void:
	var map := LevelMap.blank(Vector2i(20, 20))
	var planner := _planner(map, Vector2i(10, 10))
	assert_true(planner.plan().is_empty())


func test_compact_removes_redundant_sites_but_keeps_the_first() -> void:
	var map := LevelMap.blank(Vector2i(40, 40))
	var planner := _planner(map, Vector2i(2, 2))
	var sites: Array[Vector2i] = [Vector2i(30, 30), Vector2i(31, 30), Vector2i(29, 30), Vector2i(30, 30)]
	planner.sites = sites
	planner.needed.fill(0)
	planner.needed[map.index(Vector2i(30, 30))] = 1
	planner.compact()
	assert_eq(planner.sites.size(), 1)
	assert_eq(planner.sites[0], Vector2i(30, 30))


func test_compact_merges_two_sites_one_site_can_replace() -> void:
	var map := LevelMap.blank(Vector2i(40, 40))
	var planner := _planner(map, Vector2i(2, 2))
	var first := Vector2i(37, 37)
	planner.needed.fill(0)
	var target: Array[Vector2i] = []
	for y in range(18, 23):
		for x in range(18, 23):
			planner.needed[map.index(Vector2i(x, y))] = 1
			target.append(Vector2i(x, y))
	var sites: Array[Vector2i] = [first, Vector2i(15, 20), Vector2i(25, 20)]
	planner.sites = sites
	planner.compact()
	assert_eq(planner.sites.size(), 2)
	assert_eq(planner.sites[0], first)
	for cell in target:
		assert_eq(planner.coverage(cell), 1, str(cell))


func test_compact_keeps_sites_no_single_site_can_replace() -> void:
	var map := LevelMap.blank(Vector2i(40, 40))
	var planner := _planner(map, Vector2i(2, 2))
	planner.needed.fill(0)
	planner.needed[map.index(Vector2i(10, 20))] = 1
	planner.needed[map.index(Vector2i(24, 20))] = 1
	var sites: Array[Vector2i] = [Vector2i(37, 37), Vector2i(12, 20), Vector2i(22, 20)]
	planner.sites = sites
	planner.compact()
	assert_eq(planner.sites.size(), 3)


func test_compact_only_merges_onto_allowed_cells() -> void:
	var map := LevelMap.blank(Vector2i(40, 40))
	var planner := _planner(map, Vector2i(2, 2))
	planner.needed.fill(0)
	planner.needed[map.index(Vector2i(16, 20))] = 1
	planner.needed[map.index(Vector2i(24, 20))] = 1
	for y in range(14, 27):
		for x in range(17, 24):
			planner.allowed[map.index(Vector2i(x, y))] = 0
	var sites: Array[Vector2i] = [Vector2i(37, 37), Vector2i(14, 20), Vector2i(26, 20)]
	planner.sites = sites
	planner.compact()
	assert_eq(planner.sites.size(), 3)
