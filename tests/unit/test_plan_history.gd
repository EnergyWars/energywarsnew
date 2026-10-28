extends GutTest

var battle: Battle
var state: BattleState
var core: Building


func before_each() -> void:
	battle = BattleFixtures.battle(1, false)
	state = battle.state
	core = state.core()
	state.money = 1000
	battle.history.begin(state)
	battle.events.drain()


func _place(kind: String, offset: Vector2) -> Building:
	assert_eq(battle.place(kind, core.position + offset), BuildRules.OK)
	return state.player_buildings().back()


func test_fresh_plan_has_nothing_to_undo() -> void:
	assert_true(battle.history.is_active())
	assert_false(battle.can_undo())
	assert_false(battle.undo())
	assert_false(battle.reset_plan())
	assert_eq(battle.history.size(), 0)


func test_battle_starts_history_when_created_in_planning() -> void:
	assert_true(BattleFixtures.battle(0).history.is_active())
	assert_false(Battle.start(0).history.is_active())


func test_deploying_the_core_starts_history() -> void:
	var fresh := BattleFixtures.deployed(0)
	assert_true(fresh.history.is_active())
	assert_eq(fresh.history.baseline.money, fresh.state.money)
	assert_not_null(fresh.history.baseline_stats)


func test_undo_place_returns_money_and_frees_cells() -> void:
	var relay := _place(GameConfig.RELAY, Vector2(150, 0))
	var cell := relay.origin
	assert_eq(state.money, 970)
	assert_true(battle.can_undo())
	assert_true(battle.undo())
	assert_null(state.building(relay.id))
	assert_eq(state.money, 1000)
	assert_eq(state.count_kind(GameConfig.RELAY), 0)
	assert_eq(state.nav.occupant_at(cell), NavGrid.FREE)
	assert_false(battle.can_undo())
	var restored := BattleFixtures.of_type(battle.events.drain(), "plan_restored")
	assert_eq(restored.size(), 1)
	assert_eq(restored[0].steps, 0)


func test_undo_upgrade_restores_level_hull_and_money() -> void:
	var relay := _place(GameConfig.RELAY, Vector2(150, 0))
	assert_true(battle.upgrade(relay.id, GameConfig.TRACK_HULL))
	assert_gt(relay.hp, 90.0)
	assert_true(battle.undo())
	assert_eq(relay.level(GameConfig.TRACK_HULL), 0)
	assert_almost_eq(relay.max_hp(), 90.0, 0.001)
	assert_almost_eq(relay.hp, 90.0, 0.001)
	assert_eq(relay.spent, 30)
	assert_eq(relay.plan_spent, 30)
	assert_eq(state.money, 970)
	assert_eq(state.building(relay.id), relay)


func test_undo_sell_brings_back_building_energy_and_links() -> void:
	var relay := _place(GameConfig.RELAY, Vector2(150, 0))
	assert_eq(battle.connect_buildings(core.id, relay.id), EnergyNetwork.OK)
	relay.energy = 12.0
	var money := state.money
	var links := state.links_version
	var roster := state.roster_version
	assert_gt(battle.sell(relay.id), 0)
	assert_null(state.building(relay.id))
	assert_null(state.find_link(core.id, relay.id))
	assert_true(battle.undo())
	assert_eq(state.building(relay.id), relay)
	assert_true(state.player_buildings().has(relay))
	assert_almost_eq(relay.energy, 12.0, 0.001)
	assert_not_null(state.find_link(core.id, relay.id))
	assert_eq(state.nav.occupant_at(relay.origin), relay.id)
	assert_eq(state.money, money)
	assert_gt(state.links_version, links)
	assert_gt(state.roster_version, roster)
	assert_eq(battle.network.groups().size(), 1)


func test_undo_relocate_moves_back() -> void:
	var relay := _place(GameConfig.RELAY, Vector2(150, 0))
	var origin := relay.origin
	var position := relay.position
	assert_eq(battle.relocate(relay.id, core.position + Vector2(-150, 60)), BuildRules.OK)
	var moved := relay.origin
	assert_true(battle.undo())
	assert_eq(relay.origin, origin)
	assert_eq(relay.position, position)
	assert_eq(state.nav.occupant_at(origin), relay.id)
	assert_eq(state.nav.occupant_at(moved), NavGrid.FREE)


func test_undo_link_and_cut() -> void:
	var relay := _place(GameConfig.RELAY, Vector2(150, 0))
	battle.connect_buildings(core.id, relay.id)
	assert_true(battle.undo())
	assert_null(state.find_link(core.id, relay.id))
	battle.connect_buildings(core.id, relay.id)
	var steps := battle.history.size()
	assert_eq(battle.cut(core.position + Vector2(100, 200), core.position + Vector2(160, 200)), 0)
	assert_eq(battle.history.size(), steps)
	assert_eq(battle.cut(core.position + Vector2(100, -50), core.position + Vector2(100, 50)), 1)
	assert_null(state.find_link(core.id, relay.id))
	assert_true(battle.undo())
	assert_not_null(state.find_link(core.id, relay.id))


func test_undo_target_priorities_and_focus() -> void:
	var order := core.target_order.duplicate()
	assert_true(battle.toggle_target_class(core.id, GameConfig.CLASS_AIR))
	assert_true(battle.raise_target_class(core.id, GameConfig.CLASS_MELEE))
	var crawler := BattleFixtures.enemy(battle, "crawler", core.position + Vector2(100, 0))
	assert_eq(battle.focus(core.id, crawler), Combat.OK)
	assert_eq(core.focus, crawler)
	var steps := battle.history.size()
	assert_eq(battle.focus(core.id, core), Combat.INVALID)
	assert_eq(battle.history.size(), steps)
	assert_true(battle.undo())
	assert_null(core.focus)
	assert_true(battle.undo())
	assert_eq(core.target_order, order)
	assert_true(core.target_disabled.get(GameConfig.CLASS_AIR, false))
	assert_true(battle.undo())
	assert_false(core.target_disabled.has(GameConfig.CLASS_AIR))


func test_reset_restores_the_phase_start() -> void:
	var relay := _place(GameConfig.RELAY, Vector2(150, 0))
	var solar := _place(GameConfig.SOLAR, Vector2(-150, 0))
	battle.connect_buildings(solar.id, core.id)
	battle.upgrade(core.id, GameConfig.TRACK_RATE)
	battle.sell(relay.id)
	battle.events.drain()
	assert_true(battle.reset_plan())
	assert_eq(state.player_buildings(), [core] as Array[Building])
	assert_eq(state.money, 1000)
	assert_eq(core.level(GameConfig.TRACK_RATE), 0)
	assert_true(state.links.is_empty())
	assert_eq(state.nav.occupant_at(solar.origin), NavGrid.FREE)
	assert_false(battle.can_undo())
	assert_false(battle.undo())
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "plan_restored").size(), 1)


func test_income_during_planning_survives_undo() -> void:
	_place(GameConfig.RELAY, Vector2(150, 0))
	battle.economy.credit(50)
	assert_true(battle.reset_plan())
	assert_eq(state.money, 1050)


func test_failed_actions_record_nothing() -> void:
	assert_ne(battle.place(GameConfig.RELAY, core.position + Vector2(5000, 0)), BuildRules.OK)
	assert_eq(battle.sell(core.id), 0)
	assert_ne(battle.connect_buildings(core.id, core.id), EnergyNetwork.OK)
	assert_false(battle.toggle_target_class(core.id, "unknown"))
	assert_false(battle.raise_target_class(core.id, core.target_order[0]))
	state.money = 0
	assert_false(battle.upgrade(core.id, GameConfig.TRACK_RATE))
	assert_eq(battle.history.size(), 0)


func test_wall_stroke_is_one_step() -> void:
	battle.begin_stroke()
	for i in 3:
		_place(GameConfig.BULWARK, Vector2(56 * i, -168))
	battle.end_stroke()
	assert_eq(battle.history.size(), 1)
	_place(GameConfig.BULWARK, Vector2(0, -280))
	_place(GameConfig.BULWARK, Vector2(56, -280))
	assert_eq(battle.history.size(), 3)
	assert_true(battle.undo())
	assert_true(battle.undo())
	assert_eq(state.count_kind(GameConfig.BULWARK), 3)
	assert_true(battle.undo())
	assert_eq(state.count_kind(GameConfig.BULWARK), 0)


func test_other_actions_split_a_stroke() -> void:
	battle.begin_stroke()
	_place(GameConfig.BULWARK, Vector2(0, -168))
	_place(GameConfig.RELAY, Vector2(150, 0))
	_place(GameConfig.BULWARK, Vector2(56, -168))
	battle.end_stroke()
	assert_eq(battle.history.size(), 3)


func test_cut_stroke_is_one_step() -> void:
	var left := _place(GameConfig.RELAY, Vector2(-150, 0))
	var right := _place(GameConfig.RELAY, Vector2(150, 0))
	battle.connect_buildings(core.id, left.id)
	battle.connect_buildings(core.id, right.id)
	var steps := battle.history.size()
	battle.begin_stroke()
	battle.cut(core.position + Vector2(-100, -50), core.position + Vector2(-100, 50))
	battle.cut(core.position + Vector2(100, -50), core.position + Vector2(100, 50))
	battle.end_stroke()
	assert_true(state.links.is_empty())
	assert_eq(battle.history.size(), steps + 1)
	assert_true(battle.undo())
	assert_eq(state.links.size(), 2)


func test_history_ends_when_the_fight_starts() -> void:
	_place(GameConfig.RELAY, Vector2(150, 0))
	assert_true(battle.start_round())
	assert_false(battle.history.is_active())
	assert_not_null(battle.history.baseline_stats)
	assert_false(battle.can_undo())
	assert_false(battle.undo())
	assert_false(battle.reset_plan())
	_place(GameConfig.RELAY, Vector2(-150, 0))
	assert_eq(battle.history.size(), 0)
	assert_false(battle.start_round())


func test_cleared_round_starts_a_new_baseline() -> void:
	var fresh := BattleFixtures.battle(1)
	fresh.start_round()
	fresh.spawns.end_night()
	fresh.tick(GameConfig.TICK)
	assert_true(fresh.state.is_planning())
	assert_true(fresh.history.is_active())
	assert_eq(fresh.history.baseline.money, fresh.state.money)
	assert_false(fresh.can_undo())


func test_history_caps_its_steps() -> void:
	var history := PlanHistory.new()
	history.record(PlanSnapshot.capture(state))
	assert_eq(history.size(), 0)
	history.begin(state)
	history.record(null)
	assert_eq(history.size(), 0)
	for i in PlanHistory.MAX_STEPS + 5:
		history.record(PlanSnapshot.capture(state))
	assert_eq(history.size(), PlanHistory.MAX_STEPS)
	history.end()
	assert_null(history.pop())
	assert_false(history.can_undo())


func test_snapshot_captures_player_state_only() -> void:
	var nest := BattleFixtures.add(battle, GameConfig.NEST, core.position + Vector2(0, -900))
	var relay := _place(GameConfig.RELAY, Vector2(150, 0))
	battle.connect_buildings(core.id, relay.id)
	var snapshot := PlanSnapshot.capture(state)
	assert_eq(snapshot.entries.size(), 2)
	assert_eq(snapshot.links, [Vector2i(core.id, relay.id)] as Array[Vector2i])
	assert_eq(snapshot.money, state.money)
	snapshot.restore(state)
	assert_eq(state.building(nest.id), nest)
	assert_eq(state.player_buildings().size(), 2)
