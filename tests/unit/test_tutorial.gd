extends GutTest


func test_inactive_tutorial_ignores_events() -> void:
	var tutorial := Tutorial.new(false)
	assert_false(tutorial.is_active())
	assert_false(tutorial.handle({"type": "placed", "kind": GameConfig.SOLAR}))


func test_full_sequence() -> void:
	var tutorial := Tutorial.new(true)
	assert_eq(tutorial.step, Tutorial.MOVE_SCOUT)
	assert_false(tutorial.handle({"type": "landed"}))
	assert_true(tutorial.handle({"type": "scout_steer"}))
	assert_eq(tutorial.step, Tutorial.DEPLOY_CORE)
	assert_false(tutorial.handle({"type": "scout_steer"}))
	assert_true(tutorial.handle({"type": "core_deployed"}))
	assert_eq(tutorial.step, Tutorial.BUILD_SOLAR)
	assert_false(tutorial.handle({"type": "placed", "kind": GameConfig.RELAY}))
	assert_true(tutorial.handle({"type": "placed", "kind": GameConfig.SOLAR}))
	assert_eq(tutorial.step, Tutorial.CONNECT)
	assert_true(tutorial.handle({"type": "link", "tower": false}))
	assert_eq(tutorial.step, Tutorial.BUILD_TOWER)
	assert_true(tutorial.handle({"type": "placed", "kind": GameConfig.ZAPPER}))
	assert_false(tutorial.handle({"type": "link", "tower": false}))
	assert_true(tutorial.handle({"type": "link", "tower": true}))
	assert_eq(tutorial.step, Tutorial.BUILD_WALL)
	assert_false(tutorial.handle({"type": "placed", "kind": GameConfig.SOLAR}))
	assert_true(tutorial.handle({"type": "placed", "kind": GameConfig.BULWARK}))
	assert_eq(tutorial.step, Tutorial.CAMERA)
	assert_true(tutorial.handle({"type": "camera"}))
	assert_eq(tutorial.step, Tutorial.START_DAY)
	assert_false(tutorial.handle({"type": "camera"}))
	assert_true(tutorial.handle({"type": "fight_started", "round": 1}))
	assert_eq(tutorial.step, Tutorial.STORAGE)
	assert_true(tutorial.handle({"type": "placed", "kind": GameConfig.BATTERY}))
	assert_eq(tutorial.step, Tutorial.CUT)
	assert_true(tutorial.handle({"type": "unlink"}))
	assert_false(tutorial.is_active())


func test_fallbacks_advance() -> void:
	var tutorial := Tutorial.new(true)
	assert_true(tutorial.handle({"type": "core_deployed"}))
	assert_eq(tutorial.step, Tutorial.BUILD_SOLAR)
	for i in 4:
		tutorial.next()
	assert_eq(tutorial.step, Tutorial.BUILD_WALL)
	assert_true(tutorial.handle({"type": "fight_started"}))
	assert_eq(tutorial.step, Tutorial.STORAGE)
	assert_true(tutorial.handle({"type": "nightfall"}))
	assert_eq(tutorial.step, Tutorial.DONE)
	assert_false(tutorial.handle({"type": "victory"}))


func test_matches_unknown_step() -> void:
	assert_false(Tutorial.matches("nope", {"type": "link"}))


func test_skip() -> void:
	var tutorial := Tutorial.new(true)
	tutorial.skip()
	assert_false(tutorial.is_active())
