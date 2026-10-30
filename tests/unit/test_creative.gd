extends GutTest


func _creative(start_day: int = 1, arsenal: Arsenal = null) -> Battle:
	var state := BattleState.create(0, 1234, BattleSetup.creative(start_day, arsenal))
	BattleFixtures.open_terrain(state)
	state.spawn_structures(state.map.structures)
	state.place_core(state.map.drop)
	return Battle.new(state)


func _spawner(battle: Battle) -> Building:
	for building in battle.state.enemy_buildings():
		if building.spawner:
			return building
	return null


func _all_visible(fog: FogOfWar) -> bool:
	return fog.cells.count(FogOfWar.VISIBLE) == fog.cells.size()


func test_creative_setup_unlocks_every_building_and_keeps_research() -> void:
	var research := Arsenal.from_techs(["weapons_1", "funding_1"])
	var setup := BattleSetup.creative(7, research)
	assert_true(setup.is_creative())
	assert_false(setup.is_campaign())
	assert_false(setup.is_survival())
	assert_false(setup.is_endless())
	assert_eq(setup.days, 0)
	assert_eq(setup.start_day, 7)
	assert_eq(setup.arsenal.kinds(), GameConfig.BUILD_ORDER)
	assert_gt(setup.arsenal.boost(GameConfig.LASER, GameConfig.BOOST_DAMAGE), 1.0)
	assert_almost_eq(setup.arsenal.boost(GameConfig.LASER, GameConfig.BOOST_DAMAGE), research.boost(GameConfig.LASER, GameConfig.BOOST_DAMAGE), 0.0001)
	assert_eq(setup.arsenal.money_bonus, research.money_bonus)
	assert_false(research.has(GameConfig.LASER))
	assert_eq(BattleSetup.creative().arsenal.kinds(), GameConfig.BUILD_ORDER)


func test_start_day_is_clamped_and_only_used_in_creative() -> void:
	assert_eq(BattleSetup.creative().start_day, 1)
	assert_eq(BattleSetup.creative(0).start_day, 1)
	assert_eq(BattleSetup.creative(GameConfig.CREATIVE_MAX_DAY + 5).start_day, GameConfig.CREATIVE_MAX_DAY)
	assert_eq(BattleSetup.new(BattleSetup.Mode.CAMPAIGN, 0, null, 9).start_day, 1)
	assert_eq(BattleSetup.new(BattleSetup.Mode.SURVIVAL, 5, null, 9).start_day, 1)
	assert_eq(BattleSetup.clamp_day(-3), 1)
	assert_eq(BattleSetup.clamp_day(42), 42)
	assert_true(BattleSetup.campaign().is_campaign())
	assert_false(BattleSetup.survival(5).is_campaign())
	assert_false(BattleSetup.campaign().is_creative())


func test_renewed_keeps_the_rules_with_a_fresh_arsenal() -> void:
	var creative := BattleSetup.creative(12).renewed(Arsenal.new())
	assert_true(creative.is_creative())
	assert_eq(creative.start_day, 12)
	assert_eq(creative.arsenal.kinds(), GameConfig.BUILD_ORDER)
	var survival := BattleSetup.survival(10).renewed(Arsenal.from_techs(["laser"]))
	assert_true(survival.is_survival())
	assert_eq(survival.days, 10)
	assert_eq(survival.start_day, 1)
	assert_true(survival.arsenal.has(GameConfig.LASER))
	assert_false(survival.arsenal.has(GameConfig.TESLA))
	var campaign := BattleSetup.campaign().renewed(null)
	assert_true(campaign.is_campaign())
	assert_eq(campaign.arsenal.kinds(), GameConfig.STARTER_KINDS)


func test_creative_battle_starts_on_the_chosen_day_without_fog() -> void:
	var state := BattleState.create(0, 1234, BattleSetup.creative(6))
	assert_true(state.is_creative())
	assert_true(state.is_scouting())
	assert_eq(state.round_number, 6)
	assert_true(state.fog.lifted)
	assert_true(_all_visible(state.fog))
	assert_true(state.fog.is_visible(state.map.structures[0].position))
	assert_eq(state.available_kinds(), GameConfig.BUILD_ORDER)
	state.scout.position = state.map.drop + Vector2(0, -1200)
	state.fog.invalidate()
	state.fog.update(state, GameConfig.FOG_INTERVAL)
	state.fog.refresh(state)
	assert_true(_all_visible(state.fog))


func test_other_modes_keep_fog_and_day_one() -> void:
	for setup: BattleSetup in [BattleSetup.campaign(), BattleSetup.survival(5)]:
		var state := BattleState.create(0, 1234, setup)
		assert_false(state.is_creative())
		assert_eq(state.round_number, 1)
		assert_false(state.fog.lifted)
		assert_false(_all_visible(state.fog))


func test_money_is_unlimited_in_creative() -> void:
	var battle := _creative()
	var state := battle.state
	state.money = 0
	assert_true(state.unlimited_money)
	assert_true(state.has_unlimited_money())
	assert_true(state.can_afford(1000000))
	state.pay(500)
	assert_eq(state.money, 0)
	var core := state.core()
	assert_eq(battle.place(GameConfig.LASER, core.position + Vector2(168, 0)), BuildRules.OK)
	assert_eq(state.money, 0)
	var laser: Building = state.of_kind(GameConfig.LASER)[0]
	assert_true(battle.can_upgrade(laser.id, GameConfig.TRACK_POWER))
	assert_true(battle.upgrade(laser.id, GameConfig.TRACK_POWER))
	assert_eq(laser.level(GameConfig.TRACK_POWER), 1)
	battle.start_round()
	assert_true(battle.upgrade(laser.id, GameConfig.TRACK_POWER))
	assert_eq(BuildRules.reason(state, GameConfig.SOLAR, core.position + Vector2(-168, 0)), BuildRules.OK)
	assert_eq(battle.relocate(laser.id, core.position + Vector2(0, 168)), BuildRules.OK)
	assert_eq(state.money, 0)


func test_unlimited_money_still_records_the_costs() -> void:
	var battle := _creative()
	var state := battle.state
	state.money = 0
	var cost := Formulas.build_cost(state, GameConfig.LASER)
	assert_gt(cost, 0)
	assert_eq(battle.place(GameConfig.LASER, state.core().position + Vector2(168, 0)), BuildRules.OK)
	var laser: Building = state.of_kind(GameConfig.LASER)[0]
	assert_eq(laser.spent, cost)
	assert_eq(laser.plan_spent, cost)
	var upgrade := Formulas.upgrade_cost(laser, GameConfig.TRACK_POWER)
	assert_true(battle.upgrade(laser.id, GameConfig.TRACK_POWER))
	assert_eq(laser.spent, cost + upgrade)
	assert_eq(state.money, 0)


func test_unlimited_money_can_be_switched_off_and_on() -> void:
	var battle := _creative()
	var state := battle.state
	var core := state.core()
	state.money = 1000
	battle.events.drain()
	assert_false(battle.set_unlimited_money(true))
	assert_true(battle.events.drain().is_empty())
	assert_true(battle.set_unlimited_money(false))
	assert_false(state.unlimited_money)
	assert_false(state.has_unlimited_money())
	var toggled := BattleFixtures.of_type(battle.events.drain(), "money_mode_changed")
	assert_eq(toggled.size(), 1)
	assert_false(toggled[0].unlimited)
	assert_false(battle.set_unlimited_money(false))
	var cost := Formulas.build_cost(state, GameConfig.LASER)
	assert_eq(battle.place(GameConfig.LASER, core.position + Vector2(168, 0)), BuildRules.OK)
	assert_eq(state.money, 1000 - cost)
	var laser: Building = state.of_kind(GameConfig.LASER)[0]
	var upgrade := Formulas.upgrade_cost(laser, GameConfig.TRACK_POWER)
	assert_true(battle.upgrade(laser.id, GameConfig.TRACK_POWER))
	assert_eq(state.money, 1000 - cost - upgrade)
	state.money = 0
	assert_false(state.can_afford(1))
	assert_eq(BuildRules.reason(state, GameConfig.SOLAR, core.position + Vector2(-168, 0)), BuildRules.MONEY)
	assert_false(battle.can_upgrade(laser.id, GameConfig.TRACK_POWER))
	state.pay(5)
	assert_eq(state.money, -5)
	state.money = 0
	assert_true(battle.set_unlimited_money(true))
	assert_true(state.has_unlimited_money())
	assert_true(BattleFixtures.of_type(battle.events.drain(), "money_mode_changed")[0].unlimited)
	assert_true(state.can_afford(1000000))
	assert_true(battle.can_upgrade(laser.id, GameConfig.TRACK_POWER))
	var solar_cost := Formulas.build_cost(state, GameConfig.SOLAR)
	assert_eq(battle.place(GameConfig.SOLAR, core.position + Vector2(-168, 0)), BuildRules.OK)
	assert_eq(state.of_kind(GameConfig.SOLAR)[0].spent, solar_cost)
	assert_eq(state.money, 0)


func test_unlimited_money_needs_a_running_creative_battle() -> void:
	var campaign := BattleFixtures.battle()
	assert_true(campaign.state.unlimited_money)
	assert_false(campaign.state.has_unlimited_money())
	assert_false(campaign.set_unlimited_money(false))
	assert_true(campaign.state.unlimited_money)
	assert_true(BattleFixtures.of_type(campaign.events.drain(), "money_mode_changed").is_empty())
	var creative := _creative()
	creative.state.phase = BattleState.Phase.WON
	assert_false(creative.set_unlimited_money(false))
	assert_true(creative.state.unlimited_money)


func test_money_still_counts_outside_creative() -> void:
	var battle := BattleFixtures.battle()
	var state := battle.state
	state.money = 50
	assert_true(state.can_afford(50))
	assert_false(state.can_afford(51))
	state.pay(20)
	assert_eq(state.money, 30)
	state.money = 0
	assert_eq(BuildRules.reason(state, GameConfig.SOLAR, state.core().position + Vector2(120, 0)), BuildRules.MONEY)
	assert_false(battle.can_upgrade(state.core_id, GameConfig.TRACK_RATE))


func test_core_is_invulnerable_in_creative() -> void:
	var battle := _creative()
	var core := battle.state.core()
	assert_true(core.immune)
	battle.combat.damage_building(core, 1.0e9)
	assert_eq(core.hp, core.max_hp())
	assert_true(battle.start_round())
	battle.combat.damage(core, 1.0e9, true)
	battle.tick(GameConfig.TICK)
	assert_true(core.is_alive())
	assert_true(battle.state.is_fighting())
	assert_false(BattleFixtures.battle().state.core().immune)


func test_destroying_every_structure_does_not_end_creative() -> void:
	var battle := _creative()
	var spawner := _spawner(battle)
	assert_false(spawner.immune)
	for building in battle.state.enemy_buildings().duplicate():
		battle.combat.destroy(building)
	assert_true(battle.state.enemy_buildings().is_empty())
	battle.tick(GameConfig.TICK)
	assert_true(battle.state.is_planning())
	assert_false(battle.state.is_over())
	assert_eq(battle.state.stars(), 0)


func test_day_can_be_changed_while_planning() -> void:
	var battle := _creative(3)
	battle.events.drain()
	assert_true(battle.state.day_editable())
	assert_true(battle.set_day(8))
	assert_eq(battle.state.round_number, 8)
	var changed := BattleFixtures.of_type(battle.events.drain(), "day_changed")
	assert_eq(changed.size(), 1)
	assert_eq(changed[0].day, 8)
	assert_false(battle.set_day(8))
	assert_true(battle.events.drain().is_empty())
	assert_true(battle.set_day(GameConfig.CREATIVE_MAX_DAY + 10))
	assert_eq(battle.state.round_number, GameConfig.CREATIVE_MAX_DAY)
	assert_true(battle.set_day(-4))
	assert_eq(battle.state.round_number, 1)
	assert_true(battle.start_round())
	assert_false(battle.state.day_editable())
	assert_false(battle.set_day(5))
	assert_eq(battle.state.round_number, 1)


func test_day_can_be_changed_before_the_core_lands() -> void:
	var battle := Battle.new(BattleState.create(0, 1234, BattleSetup.creative()))
	assert_true(battle.state.is_scouting())
	assert_true(battle.state.day_editable())
	assert_true(battle.set_day(4))
	assert_eq(battle.state.round_number, 4)
	battle.state.phase = BattleState.Phase.WON
	assert_false(battle.state.day_editable())
	assert_false(battle.set_day(6))


func test_day_is_fixed_outside_creative() -> void:
	var battle := BattleFixtures.battle()
	assert_false(battle.state.day_editable())
	assert_false(battle.set_day(5))
	assert_eq(battle.state.round_number, 1)


func test_chosen_day_scales_the_next_fight() -> void:
	var battle := _creative()
	assert_true(battle.set_day(6))
	assert_true(battle.start_round())
	var enemy := battle.spawns.spawn(_spawner(battle))
	assert_almost_eq(enemy.max_hp, float(GameConfig.enemy(enemy.kind).hp) * Formulas.enemy_hp_scale(6), 0.01)
	battle.spawns.end_night()
	battle.state.enemies.clear()
	battle.tick(GameConfig.TICK)
	assert_true(battle.state.is_planning())
	assert_eq(battle.state.days_survived, 6)
	assert_eq(battle.state.round_number, 7)
	assert_true(battle.state.day_editable())


func test_clear_enemies_removes_every_unit_and_pending_spawn() -> void:
	var battle := _creative()
	var state := battle.state
	assert_true(battle.start_round())
	var spawner := _spawner(battle)
	var crawler := BattleFixtures.enemy(battle, "crawler", spawner.position + Vector2(GameConfig.CELL * 3, 0))
	var guard := battle.spawns.spawn_guard(spawner)
	var dead := BattleFixtures.enemy(battle, "crawler", spawner.position)
	dead.hp = 0.0
	spawner.spawn_queue = 5
	var kills := state.kills
	battle.events.drain()
	assert_eq(battle.clear_enemies(), 2)
	assert_true(state.enemies.is_empty())
	assert_false(crawler.is_alive())
	assert_false(guard.is_alive())
	assert_eq(spawner.spawn_queue, 0)
	assert_eq(state.kills, kills)
	assert_true(state.pickups.is_empty())
	var events := battle.events.drain()
	var cleared := BattleFixtures.of_type(events, "enemies_cleared")
	assert_eq(cleared.size(), 1)
	assert_eq(cleared[0].count, 2)
	assert_eq(cleared[0].units[0].kind, "crawler")
	assert_eq(cleared[0].units[0].position, crawler.position)
	assert_eq(cleared[0].units[1].kind, guard.kind)
	assert_true(BattleFixtures.of_type(events, "guards_ignited").is_empty())
	assert_eq(battle.clear_enemies(), 0)
	assert_true(battle.events.drain().is_empty())
	battle.tick(GameConfig.TICK)
	assert_true(state.is_planning())


func test_clear_enemies_ends_the_running_day() -> void:
	var battle := _creative(3)
	var state := battle.state
	var lamp := BattleFixtures.add(battle, GameConfig.LAMP, state.core().position + Vector2(168, 0))
	assert_true(battle.start_round())
	assert_false(battle.history.is_active())
	state.round_time = float(state.level.day) + 5.0
	state.waves_sent = 2
	assert_true(state.is_night())
	lamp.energy = Formulas.capacity(lamp)
	lamp.lit = true
	BattleFixtures.enemy(battle, "crawler", _spawner(battle).position + Vector2(GameConfig.CELL * 3, 0))
	battle.events.drain()
	assert_eq(battle.clear_enemies(), 1)
	assert_true(state.is_planning())
	assert_false(state.is_night())
	assert_false(lamp.lit)
	assert_eq(state.days_survived, 3)
	assert_eq(state.round_number, 4)
	assert_eq(state.round_time, 0.0)
	assert_eq(state.waves_sent, 0)
	assert_true(state.projectiles.is_empty())
	assert_true(state.day_editable())
	assert_true(battle.history.is_active())
	var events := battle.events.drain()
	assert_eq(BattleFixtures.of_type(events, "enemies_cleared").size(), 1)
	var rounds := BattleFixtures.of_type(events, "round_cleared")
	assert_eq(rounds.size(), 1)
	assert_eq(rounds[0].round, 3)
	assert_eq(rounds[0].next, 4)
	assert_true(battle.start_round())
	assert_eq(state.round_number, 4)


func test_clear_enemies_ends_a_day_without_enemies() -> void:
	var battle := _creative(2)
	var state := battle.state
	assert_true(battle.start_round())
	assert_true(state.enemies.is_empty())
	battle.events.drain()
	assert_eq(battle.clear_enemies(), 0)
	assert_true(state.is_planning())
	assert_eq(state.round_number, 3)
	var events := battle.events.drain()
	assert_true(BattleFixtures.of_type(events, "enemies_cleared").is_empty())
	assert_eq(BattleFixtures.of_type(events, "round_cleared").size(), 1)


func test_clear_enemies_while_planning_keeps_the_day() -> void:
	var battle := _creative(5)
	var state := battle.state
	var unit := BattleFixtures.enemy(battle, "crawler", state.map.drop + Vector2(400, 0))
	battle.events.drain()
	assert_eq(battle.clear_enemies(), 1)
	assert_false(unit.is_alive())
	assert_true(state.is_planning())
	assert_eq(state.round_number, 5)
	var events := battle.events.drain()
	assert_eq(BattleFixtures.of_type(events, "enemies_cleared").size(), 1)
	assert_true(BattleFixtures.of_type(events, "round_cleared").is_empty())


func test_clear_enemies_needs_a_running_creative_battle() -> void:
	var campaign := BattleFixtures.battle()
	var unit := BattleFixtures.enemy(campaign, "crawler", campaign.state.map.drop + Vector2(400, 0))
	assert_eq(campaign.clear_enemies(), 0)
	assert_true(unit.is_alive())
	assert_eq(campaign.state.enemies.size(), 1)
	var creative := _creative()
	var other := BattleFixtures.enemy(creative, "crawler", creative.state.map.drop + Vector2(400, 0))
	creative.state.phase = BattleState.Phase.LOST
	assert_eq(creative.clear_enemies(), 0)
	assert_true(other.is_alive())


func test_checkpoint_keeps_the_money_switch() -> void:
	var battle := _creative()
	assert_true(battle.set_unlimited_money(false))
	battle.state.money = 77
	assert_true(battle.start_round())
	assert_false(battle.checkpoint.unlimited_money)
	var state := battle.checkpoint.restore().state
	assert_false(state.unlimited_money)
	assert_false(state.has_unlimited_money())
	assert_eq(state.money, 77)
	var fresh := _creative()
	assert_true(fresh.start_round())
	assert_true(fresh.checkpoint.restore().state.has_unlimited_money())


func test_checkpoint_keeps_the_creative_rules() -> void:
	var battle := _creative(4)
	assert_true(battle.start_round())
	var restored := battle.checkpoint.restore()
	var state := restored.state
	assert_true(state.is_creative())
	assert_true(state.fog.lifted)
	assert_true(_all_visible(state.fog))
	assert_eq(state.round_number, 4)
	assert_true(state.core().immune)
	assert_true(state.day_editable())
	state.scout.boarded = false
	state.fog.refresh(state)
	assert_true(_all_visible(state.fog))


func test_plan_undo_keeps_the_core_invulnerable() -> void:
	var battle := _creative()
	var core := battle.state.core()
	assert_eq(battle.place(GameConfig.SOLAR, core.position + Vector2(120, 0)), BuildRules.OK)
	assert_true(battle.undo())
	assert_true(battle.state.core().immune)
	assert_eq(battle.state.of_kind(GameConfig.SOLAR).size(), 0)
