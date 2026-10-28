extends GutTest

var progress: Progress


func before_each() -> void:
	progress = Progress.new("user://test_campaign.json")


func test_only_the_first_region_starts_unlocked() -> void:
	assert_true(Campaign.is_unlocked(progress, 0))
	assert_true(Campaign.is_frontier(progress, 0))
	for index in range(1, Campaign.region_count()):
		assert_false(Campaign.is_unlocked(progress, index), str(index))
	assert_false(Campaign.is_unlocked(progress, -1))
	assert_false(Campaign.is_unlocked(progress, 99))


func test_conquering_unlocks_neighbors() -> void:
	progress.mark_conquered(0)
	assert_false(Campaign.is_frontier(progress, 0))
	for neighbor in Campaign.neighbors(0):
		assert_true(Campaign.is_frontier(progress, neighbor), str(neighbor))
	assert_false(Campaign.is_unlocked(progress, 7))


func test_neighbors_are_symmetric() -> void:
	for index in Campaign.region_count():
		for neighbor in Campaign.neighbors(index):
			assert_true(Campaign.neighbors(neighbor).has(index), "%d %d" % [index, neighbor])
	assert_eq(Campaign.neighbors(99), [] as Array[int])


func test_route_walks_through_conquered_regions_only() -> void:
	assert_eq(Campaign.route(progress, 0, 0), [0] as Array[int])
	assert_eq(Campaign.route(progress, 0, 1), [] as Array[int])
	progress.mark_conquered(0)
	assert_eq(Campaign.route(progress, 0, 1), [0, 1] as Array[int])
	assert_eq(Campaign.route(progress, 0, 3), [] as Array[int])
	progress.mark_conquered(1)
	assert_eq(Campaign.route(progress, 0, 3), [0, 1, 3] as Array[int])
	assert_eq(Campaign.route(progress, 3, 2), [3, 1, 0, 2] as Array[int])
	assert_eq(Campaign.route(progress, 1, 2), [1, 0, 2] as Array[int])
	assert_eq(Campaign.route(progress, -1, 2), [] as Array[int])
	assert_eq(Campaign.route(progress, 0, 99), [] as Array[int])


func test_route_prefers_the_shortest_path() -> void:
	for index in Campaign.region_count():
		progress.mark_conquered(index)
	assert_eq(Campaign.route(progress, 0, 7).size(), 5)
	var route := Campaign.route(progress, 0, 3)
	assert_eq(route.size(), 3)
	assert_eq(route[0], 0)
	assert_eq(route[2], 3)


func test_route_openness() -> void:
	assert_false(Campaign.is_route_open(progress, 0, 1))
	progress.mark_conquered(0)
	assert_true(Campaign.is_route_open(progress, 0, 1))
	assert_true(Campaign.is_route_open(progress, 1, 0))
	assert_false(Campaign.is_route_open(progress, 1, 3))


func test_positions_come_from_levels() -> void:
	assert_eq(Campaign.position(0), GameConfig.level(0).world)
	assert_true(Campaign.is_valid(0))
	assert_false(Campaign.is_valid(Campaign.region_count()))
