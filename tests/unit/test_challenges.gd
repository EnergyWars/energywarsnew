extends GutTest


func _won(level: int = 0) -> BattleState:
	var battle := BattleFixtures.battle(level)
	var state := battle.state
	state.phase = BattleState.Phase.WON
	return state


func _challenge(id: String, value: int) -> Dictionary:
	return {"id": id, "value": value, "points": 1}


func test_level_list_starts_with_conquest() -> void:
	var list := Challenges.of_level(0)
	assert_eq_deep(list[0], {"id": Challenges.CONQUER, "value": 0, "points": Challenges.CONQUER_POINTS})
	assert_eq(list.size(), 1 + GameConfig.level(0).challenges.size())
	assert_eq(Challenges.ids(0)[0], Challenges.CONQUER)
	assert_eq(Challenges.find(0, Challenges.SURVIVE).id, Challenges.SURVIVE)
	assert_true(Challenges.find(0, "bogus").is_empty())


func test_points_count_only_completed() -> void:
	assert_eq(Challenges.points(0, []), 0)
	assert_eq(Challenges.points(0, [Challenges.CONQUER]), Challenges.CONQUER_POINTS)
	assert_eq(Challenges.points(0, Challenges.ids(0)), Challenges.CONQUER_POINTS + GameConfig.level(0).challenges.size())
	assert_eq(Challenges.points(0, ["bogus"]), 0)
	assert_eq(Challenges.max_points(), GameConfig.level_count() * (Challenges.CONQUER_POINTS + 2))


func test_campaign_challenges_need_a_victory() -> void:
	var state := _won()
	assert_true(Challenges.is_met(_challenge(Challenges.CONQUER, 0), state))
	state.phase = BattleState.Phase.LOST
	for id in [Challenges.CONQUER, Challenges.CORE, Challenges.LOST, Challenges.DAYS, Challenges.COMBO]:
		assert_false(Challenges.is_met(_challenge(id, 0), state), id)


func test_campaign_challenge_thresholds() -> void:
	var state := _won()
	state.core().hp = state.core().max_hp() * 0.75
	assert_true(Challenges.is_met(_challenge(Challenges.CORE, 70), state))
	assert_false(Challenges.is_met(_challenge(Challenges.CORE, 80), state))
	state.lost = 3
	assert_true(Challenges.is_met(_challenge(Challenges.LOST, 3), state))
	assert_false(Challenges.is_met(_challenge(Challenges.LOST, 2), state))
	state.round_number = 4
	assert_true(Challenges.is_met(_challenge(Challenges.DAYS, 4), state))
	assert_false(Challenges.is_met(_challenge(Challenges.DAYS, 3), state))
	state.best_combo = 20
	assert_true(Challenges.is_met(_challenge(Challenges.COMBO, 20), state))
	assert_false(Challenges.is_met(_challenge(Challenges.COMBO, 21), state))
	assert_false(Challenges.is_met(_challenge("bogus", 0), state))


func test_survive_counts_days_in_survival_only() -> void:
	var state := _won()
	state.days_survived = 6
	assert_false(Challenges.is_met(_challenge(Challenges.SURVIVE, 5), state))
	state.setup = BattleSetup.survival(0)
	state.phase = BattleState.Phase.LOST
	assert_true(Challenges.is_met(_challenge(Challenges.SURVIVE, 5), state))
	assert_false(Challenges.is_met(_challenge(Challenges.SURVIVE, 7), state))
	state.phase = BattleState.Phase.WON
	assert_false(Challenges.is_met(_challenge(Challenges.CONQUER, 0), state))


func test_completed_lists_met_challenges() -> void:
	var state := _won()
	state.core().hp = state.core().max_hp()
	assert_eq(Challenges.completed(state), [Challenges.CONQUER, Challenges.CORE] as Array[String])
	var report := BattleReport.from_state(state)
	assert_true(report.won)
	assert_false(report.survival)
	assert_eq(report.completed, [Challenges.CONQUER, Challenges.CORE] as Array[String])
	assert_eq(report.level_index, 0)
	assert_false(report.is_endless())
