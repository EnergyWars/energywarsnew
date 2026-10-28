extends GutTest

var battle: Battle
var state: BattleState
var core: Building


func before_each() -> void:
	battle = BattleFixtures.battle(1, false)
	state = battle.state
	core = state.core()
	state.money = 1000


func test_relocate_is_free_while_planning() -> void:
	battle.place(GameConfig.RELAY, core.position + Vector2(150, 0))
	var relay: Building = state.player_buildings().back()
	var money := state.money
	battle.events.drain()
	assert_eq(battle.relocate(relay.id, core.position + Vector2(-150, 60)), BuildRules.OK)
	assert_eq(state.money, money)
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "relocated")[0].cost, 0)
	state.money = 0
	assert_eq(battle.relocate(relay.id, core.position + Vector2(-150, 120)), BuildRules.OK)


func test_relocate_moves_building_for_a_fifth_of_its_value() -> void:
	battle.start_round()
	battle.place(GameConfig.RELAY, core.position + Vector2(150, 0))
	var relay: Building = state.player_buildings().back()
	battle.upgrade(relay.id, GameConfig.TRACK_RANGE)
	var cost := Formulas.relocate_cost(relay, false)
	assert_eq(cost, int(round(relay.spent * GameConfig.RELOCATE_SHARE)))
	var old_cell := relay.origin
	var money := state.money
	var spent := relay.spent
	battle.events.drain()
	assert_eq(battle.relocate(relay.id, core.position + Vector2(-150, 60)), BuildRules.OK)
	assert_eq(state.money, money - cost)
	assert_eq(relay.spent, spent)
	assert_eq(relay.position, LevelMap.snap(core.position + Vector2(-150, 60), 1))
	assert_eq(state.nav.occupant_at(old_cell), NavGrid.FREE)
	assert_eq(state.nav.occupant_at(relay.origin), relay.id)
	var moved := BattleFixtures.of_type(battle.events.drain(), "relocated")
	assert_eq(moved.size(), 1)
	assert_eq(moved[0].cost, cost)


func test_relocate_drops_links_out_of_range_only() -> void:
	battle.place(GameConfig.ZAPPER, core.position + Vector2(0, -150))
	var near: Building = state.player_buildings().back()
	battle.place(GameConfig.SOLAR, core.position + Vector2(150, 0))
	var solar: Building = state.player_buildings().back()
	battle.connect_buildings(core.id, near.id)
	battle.connect_buildings(solar.id, core.id)
	battle.events.drain()
	assert_eq(battle.relocate(near.id, core.position + Vector2(0, -340)), BuildRules.OK)
	assert_null(state.find_link(core.id, near.id))
	assert_not_null(state.find_link(solar.id, core.id))
	var unlinks := BattleFixtures.of_type(battle.events.drain(), "unlink")
	assert_eq(unlinks.size(), 1)
	assert_eq(unlinks[0].cause, "range")


func test_relocate_reasons() -> void:
	battle.place(GameConfig.RELAY, core.position + Vector2(150, 0))
	var relay: Building = state.player_buildings().back()
	var rover := BattleFixtures.add(battle, GameConfig.ROVER, core.position + Vector2(-150, 0))
	assert_eq(battle.relocate(core.id, core.position + Vector2(0, 200)), BuildRules.IMMOBILE)
	assert_eq(battle.relocate(rover.id, core.position + Vector2(0, 200)), BuildRules.IMMOBILE)
	assert_eq(battle.relocate(9999, core.position), BuildRules.INVALID)
	assert_eq(battle.relocate(relay.id, relay.position + Vector2(5, 5)), BuildRules.SAME)
	assert_eq(battle.relocate(relay.id, core.position), BuildRules.OVERLAP)
	assert_eq(battle.relocate(relay.id, relay.position + Vector2(Formulas.build_radius(relay) - 20.0, 0)), BuildRules.TOO_FAR)
	assert_eq(battle.relocate(relay.id, relay.position + Vector2(0, GameConfig.CELL)), BuildRules.OK)
	battle.start_round()
	state.money = 0
	assert_eq(battle.relocate(relay.id, core.position + Vector2(0, 200)), BuildRules.MONEY)
	state.money = 1000
	state.phase = BattleState.Phase.LOST
	assert_eq(battle.relocate(relay.id, core.position + Vector2(0, 200)), BuildRules.INVALID)


func test_in_build_reach_can_ignore_a_building() -> void:
	assert_true(BuildRules.in_build_reach(state, core.position + Vector2(200, 0)))
	assert_false(BuildRules.in_build_reach(state, core.position + Vector2(200, 0), core.id))
