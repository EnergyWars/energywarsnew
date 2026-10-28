extends GutTest


func test_starts_idle_on_its_location() -> void:
	var walker := WorldWalker.new(2)
	assert_eq(walker.location, 2)
	assert_eq(walker.point, Campaign.position(2))
	assert_false(walker.is_walking())
	assert_eq(walker.destination(), 2)
	assert_eq(walker.anchor(), 2)
	assert_false(walker.update(1.0))
	assert_eq(WorldWalker.new(99).location, Campaign.region_count() - 1)


func test_walks_along_a_route() -> void:
	var walker := WorldWalker.new(0)
	assert_true(walker.follow([0, 1, 3] as Array[int]))
	assert_true(walker.is_walking())
	assert_eq(walker.destination(), 3)
	assert_eq(walker.anchor(), 1)
	assert_false(walker.update(0.01))
	assert_eq(walker.location, 0)
	assert_gt(walker.heading.length(), 0.9)
	var arrived := false
	for i in 200:
		if walker.update(0.1):
			arrived = true
			break
	assert_true(arrived)
	assert_eq(walker.location, 3)
	assert_eq(walker.point, Campaign.position(3))
	assert_false(walker.is_walking())


func test_rejects_routes_from_elsewhere() -> void:
	var walker := WorldWalker.new(0)
	assert_false(walker.follow([] as Array[int]))
	assert_false(walker.follow([1, 3] as Array[int]))
	assert_true(walker.follow([0] as Array[int]))
	assert_false(walker.is_walking())


func test_redirect_while_walking_keeps_the_next_stop() -> void:
	var walker := WorldWalker.new(0)
	walker.follow([0, 1] as Array[int])
	walker.update(0.01)
	assert_false(walker.follow([0, 2] as Array[int]))
	assert_true(walker.follow([1, 0, 2] as Array[int]))
	assert_eq(walker.path, [1, 0, 2] as Array[int])
	walker.update(100.0)
	assert_eq(walker.location, 2)


func test_large_steps_pass_several_stops() -> void:
	var walker := WorldWalker.new(0)
	walker.follow([0, 1, 3, 5] as Array[int])
	assert_true(walker.update(100.0))
	assert_eq(walker.location, 5)
