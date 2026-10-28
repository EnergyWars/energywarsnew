extends GutTest

var progress: Progress


func before_each() -> void:
	progress = Progress.new("user://test_tech.json")


func _earn_all() -> void:
	for index in GameConfig.level_count():
		progress.mark_conquered(index)


func test_lists_and_costs() -> void:
	assert_eq(TechTree.ids().size(), GameConfig.TECHS.size())
	var total := 0
	for branch in GameConfig.BRANCHES:
		total += TechTree.of_branch(branch).size()
	assert_eq(total, GameConfig.TECHS.size())
	assert_eq(TechTree.cost("laser"), 2)
	assert_eq(TechTree.cost("bogus"), 0)
	assert_eq(TechTree.requirements("plasma"), ["laser"] as Array[String])
	assert_true(TechTree.requirements("laser").is_empty())
	assert_eq(TechTree.total_cost(["laser", "plasma"]), 5)
	assert_eq(TechTree.unlocked_kind("tesla"), GameConfig.TESLA)
	assert_eq(TechTree.unlocked_kind("weapons_1"), "")


func test_reasons() -> void:
	assert_eq(TechTree.reason(progress, "bogus"), TechTree.UNKNOWN)
	assert_eq(TechTree.reason(progress, "laser"), TechTree.POINTS)
	assert_eq(TechTree.reason(progress, "plasma"), TechTree.REQUIRES)
	assert_eq(TechTree.missing(progress, "plasma"), ["laser"] as Array[String])
	progress.mark_conquered(0)
	assert_eq(TechTree.reason(progress, "laser"), TechTree.OK)


func test_buying_spends_points_and_unlocks() -> void:
	progress.mark_conquered(0)
	assert_eq(TechTree.buy(progress, "laser"), TechTree.OK)
	assert_eq(progress.skill_points(), 0)
	assert_eq(TechTree.reason(progress, "laser"), TechTree.OWNED)
	assert_eq(TechTree.buy(progress, "laser"), TechTree.OWNED)
	assert_eq(TechTree.buy(progress, "plasma"), TechTree.POINTS)
	assert_eq(progress.techs, ["laser"] as Array[String])
	assert_true(progress.arsenal().has(GameConfig.LASER))
	assert_false(progress.arsenal().has(GameConfig.PLASMA))


func test_everything_can_be_researched_in_order() -> void:
	_earn_all()
	for i in 5:
		for id in TechTree.ids():
			TechTree.buy(progress, id)
	assert_lt(progress.techs.size(), TechTree.ids().size())
	assert_gte(progress.skill_points(), 0)
	for id in progress.techs:
		assert_true(TechTree.missing(progress, id).is_empty(), id)
