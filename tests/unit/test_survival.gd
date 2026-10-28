extends GutTest


func _survival(days: int, level: int = 0) -> Battle:
	var state := BattleState.create(level, 1234, BattleSetup.survival(days))
	BattleFixtures.open_terrain(state)
	state.place_core(state.map.drop)
	return Battle.new(state)


func _clear_day(battle: Battle) -> void:
	battle.start_round()
	battle.spawns.end_night()
	for enemy in battle.state.enemies:
		enemy.hp = 0.0
	battle.tick(GameConfig.TICK)


func test_setup_modes() -> void:
	var campaign := BattleSetup.campaign()
	assert_false(campaign.is_survival())
	assert_false(campaign.is_endless())
	assert_not_null(campaign.arsenal)
	var survival := BattleSetup.survival(10)
	assert_true(survival.is_survival())
	assert_false(survival.is_endless())
	assert_true(BattleSetup.survival(0).is_endless())
	assert_eq(BattleSetup.survival(-5).days, 0)


func test_spawners_are_immune_in_survival() -> void:
	var battle := _survival(5)
	var nest: Building = battle.state.enemy_buildings()[0]
	assert_true(nest.immune)
	battle.combat.damage_building(nest, 100000.0)
	assert_true(nest.is_alive())
	var tower := BattleFixtures.add(battle, GameConfig.ZAPPER, nest.position + Vector2(0, 200))
	assert_null(battle.combat.find_target(tower))
	assert_eq(battle.combat.focus_reason(tower, nest), Combat.CANNOT)
	battle.tick(GameConfig.TICK)
	assert_eq(battle.state.phase, BattleState.Phase.PLAN)


func test_turrets_stay_destructible_in_survival() -> void:
	var battle := _survival(5, 3)
	for building in battle.state.enemy_buildings():
		assert_eq(building.immune, building.spawner, building.kind)


func test_surviving_all_days_wins_with_stars() -> void:
	var battle := _survival(GameConfig.SURVIVAL_TARGETS[1])
	for day in GameConfig.SURVIVAL_TARGETS[1] - 1:
		_clear_day(battle)
		assert_eq(battle.state.phase, BattleState.Phase.PLAN)
	assert_eq(battle.state.days_survived, GameConfig.SURVIVAL_TARGETS[1] - 1)
	battle.events.drain()
	_clear_day(battle)
	assert_eq(battle.state.phase, BattleState.Phase.WON)
	assert_eq(battle.state.days_survived, GameConfig.SURVIVAL_TARGETS[1])
	assert_eq(battle.state.stars(), 2)
	var events := battle.events.drain()
	assert_eq(BattleFixtures.of_type(events, "victory")[0].stars, 2)
	assert_true(BattleFixtures.of_type(events, "round_cleared").is_empty())
	var report := BattleReport.from_state(battle.state)
	assert_true(report.survival)
	assert_true(report.won)
	assert_eq(report.target, GameConfig.SURVIVAL_TARGETS[1])
	assert_eq(report.days, GameConfig.SURVIVAL_TARGETS[1])
	assert_true(report.completed.has(Challenges.SURVIVE))
	assert_false(report.completed.has(Challenges.CONQUER))


func test_endless_never_wins() -> void:
	var battle := _survival(0)
	for day in 20:
		_clear_day(battle)
	assert_eq(battle.state.phase, BattleState.Phase.PLAN)
	assert_eq(battle.state.days_survived, 20)
	assert_eq(battle.state.round_number, 21)
	battle.combat.damage_building(battle.state.core(), 1000000.0)
	battle.tick(GameConfig.TICK)
	assert_eq(battle.state.phase, BattleState.Phase.LOST)
	assert_eq(battle.state.stars(), 0)
	var report := BattleReport.from_state(battle.state)
	assert_true(report.is_endless())
	assert_eq(report.days, 20)


func test_campaign_counts_days_too() -> void:
	var battle := BattleFixtures.battle(0)
	_clear_day(battle)
	assert_eq(battle.state.days_survived, 1)
	assert_eq(battle.state.phase, BattleState.Phase.PLAN)
