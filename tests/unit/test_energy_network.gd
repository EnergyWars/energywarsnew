extends GutTest

var battle: Battle
var core: Building


func before_each() -> void:
	battle = BattleFixtures.battle(0, false)
	core = battle.state.core()


func test_send_and_receive_capabilities() -> void:
	var solar := BattleFixtures.add(battle, GameConfig.SOLAR, core.position + Vector2(120, 0))
	var zapper := BattleFixtures.add(battle, GameConfig.ZAPPER, core.position + Vector2(-120, 0))
	assert_true(EnergyNetwork.can_send(solar))
	assert_false(EnergyNetwork.can_receive(solar))
	assert_false(EnergyNetwork.can_send(zapper))
	assert_true(EnergyNetwork.can_receive(zapper))
	assert_true(EnergyNetwork.can_send(core))
	assert_true(EnergyNetwork.can_receive(core))


func test_link_reasons() -> void:
	var solar := BattleFixtures.add(battle, GameConfig.SOLAR, core.position + Vector2(120, 0))
	var zapper := BattleFixtures.add(battle, GameConfig.ZAPPER, core.position + Vector2(-120, 0))
	var far := BattleFixtures.add(battle, GameConfig.ZAPPER, core.position + Vector2(0, -900))
	var network := battle.network
	assert_eq(network.link_reason(solar.id, 999), EnergyNetwork.MISSING)
	assert_eq(network.link_reason(solar.id, solar.id), EnergyNetwork.SAME)
	assert_eq(network.link_reason(zapper.id, core.id), EnergyNetwork.NO_SEND)
	assert_eq(network.link_reason(core.id, solar.id), EnergyNetwork.NO_RECEIVE)
	assert_eq(network.link_reason(core.id, far.id), EnergyNetwork.RANGE)
	assert_eq(network.link_reason(solar.id, core.id), EnergyNetwork.OK)
	assert_true(network.connect_buildings(solar.id, core.id))
	assert_eq(network.link_reason(solar.id, core.id), EnergyNetwork.EXISTS)
	assert_eq(network.link_reason(core.id, solar.id), EnergyNetwork.NO_RECEIVE)
	var battery := BattleFixtures.add(battle, GameConfig.BATTERY, core.position + Vector2(0, -150))
	assert_eq(network.link_reason(solar.id, battery.id), EnergyNetwork.FULL)


func test_reverse_link_counts_as_existing() -> void:
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(150, 0))
	assert_true(battle.network.connect_buildings(core.id, relay.id))
	assert_eq(battle.network.link_reason(relay.id, core.id), EnergyNetwork.EXISTS)


func test_connect_emits_event_and_rejects_invalid() -> void:
	var solar := BattleFixtures.add(battle, GameConfig.SOLAR, core.position + Vector2(120, 0))
	assert_false(battle.network.connect_buildings(core.id, solar.id))
	assert_true(battle.network.connect_buildings(solar.id, core.id))
	assert_eq(BattleFixtures.types(battle), ["link"] as Array[String])


func test_solar_generates_only_in_daylight() -> void:
	var solar := BattleFixtures.add(battle, GameConfig.SOLAR, core.position + Vector2(120, 0))
	battle.network.flow(1.0)
	assert_almost_eq(solar.energy, 8.0, 0.001)
	battle.start_round()
	battle.state.round_time = float(battle.state.level.day)
	solar.energy = 0.0
	battle.network.flow(1.0)
	assert_eq(solar.energy, 0.0)


func test_generation_is_capped() -> void:
	var solar := BattleFixtures.add(battle, GameConfig.SOLAR, core.position + Vector2(120, 0))
	battle.network.flow(100.0)
	assert_eq(solar.energy, Formulas.capacity(solar))


func test_flow_respects_rate_and_space() -> void:
	var solar := BattleFixtures.add(battle, GameConfig.SOLAR, core.position + Vector2(120, 0))
	var battery := BattleFixtures.add(battle, GameConfig.BATTERY, core.position + Vector2(250, 0))
	battle.network.connect_buildings(solar.id, battery.id)
	solar.energy = 30.0
	battle.network.flow(1.0)
	var link := battle.state.links[0]
	assert_lt(battle.network.efficiency(link), 1.0)
	assert_almost_eq(battery.energy, Formulas.output(solar) * battle.network.efficiency(link), 0.001)
	assert_almost_eq(solar.energy, 30.0 - Formulas.output(solar), 0.001)
	assert_gt(link.flow, 0.0)
	battery.energy = Formulas.capacity(battery)
	var before := solar.energy
	battle.network.flow(0.1)
	assert_almost_eq(battery.energy, Formulas.capacity(battery), 0.001)
	assert_gte(solar.energy, before)


func test_flow_splits_between_links() -> void:
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(0, -200))
	var left := BattleFixtures.add(battle, GameConfig.ZAPPER, relay.position + Vector2(-100, 0))
	var right := BattleFixtures.add(battle, GameConfig.ZAPPER, relay.position + Vector2(100, 0))
	battle.network.connect_buildings(relay.id, left.id)
	battle.network.connect_buildings(relay.id, right.id)
	relay.energy = 10.0
	battle.network.flow(1.0)
	assert_almost_eq(left.energy, 5.0 * battle.network.efficiency(battle.state.find_link(relay.id, left.id)), 0.001)
	assert_almost_eq(right.energy, 5.0 * battle.network.efficiency(battle.state.find_link(relay.id, right.id)), 0.001)
	assert_almost_eq(relay.energy, 0.0, 0.001)


func test_cut_removes_crossed_links() -> void:
	var solar := BattleFixtures.add(battle, GameConfig.SOLAR, core.position + Vector2(200, 0))
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(0, -200))
	battle.network.connect_buildings(solar.id, core.id)
	battle.network.connect_buildings(core.id, relay.id)
	battle.events.drain()
	var count := battle.network.cut(core.position + Vector2(100, -50), core.position + Vector2(100, 50))
	assert_eq(count, 1)
	assert_eq(battle.state.links.size(), 1)
	var events := battle.events.drain()
	assert_eq(events[0].type, "unlink")
	assert_eq(events[0].cause, "cut")
	assert_eq(battle.network.cut(Vector2.ZERO, Vector2(1, 1)), 0)


func test_remove_links_of_building() -> void:
	var solar := BattleFixtures.add(battle, GameConfig.SOLAR, core.position + Vector2(200, 0))
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(0, -200))
	battle.network.connect_buildings(solar.id, core.id)
	battle.network.connect_buildings(core.id, relay.id)
	battle.network.remove_links_of(core.id)
	assert_true(battle.state.links.is_empty())
	battle.network.remove_link(EnergyLink.new(1, 2), "cut")
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "unlink").size(), 2)


func test_beam_loss_grows_with_distance() -> void:
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(0, -200))
	var near := BattleFixtures.add(battle, GameConfig.BATTERY, relay.position + Vector2(-112, 0))
	var far := BattleFixtures.add(battle, GameConfig.BATTERY, relay.position + Vector2(280, 0))
	battle.network.connect_buildings(relay.id, near.id)
	battle.network.connect_buildings(relay.id, far.id)
	var close_link := battle.state.find_link(relay.id, near.id)
	var long_link := battle.state.find_link(relay.id, far.id)
	assert_gt(battle.network.loss(long_link), battle.network.loss(close_link))
	assert_almost_eq(battle.network.loss(close_link), GameConfig.BEAM_LOSS_PER_CELL * battle.network.length(close_link) / GameConfig.CELL, 0.0001)
	relay.energy = 20.0
	battle.network.flow(1.0)
	assert_gt(near.energy, far.energy)
	assert_almost_eq(near.energy + far.energy, 10.0 * battle.network.efficiency(close_link) + 10.0 * battle.network.efficiency(long_link), 0.001)


func test_transfer_upgrades_and_superconductor_reduce_loss() -> void:
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(0, -200))
	var plain := Formulas.beam_loss(relay, 280.0)
	relay.set_level(GameConfig.TRACK_TRANSFER, 4)
	var upgraded := Formulas.beam_loss(relay, 280.0)
	assert_lt(upgraded, plain)
	assert_almost_eq(upgraded, plain / Formulas.multiplier(relay, GameConfig.TRACK_TRANSFER), 0.0001)
	relay.boosts = {GameConfig.BOOST_TRANSFER: 1.25}
	assert_almost_eq(Formulas.beam_loss(relay, 280.0), upgraded / 1.25, 0.0001)
	assert_almost_eq(Formulas.beam_efficiency(relay, 280.0), 1.0 - Formulas.beam_loss(relay, 280.0), 0.0001)


func test_beam_loss_is_capped_and_never_negative() -> void:
	assert_eq(Formulas.beam_loss(core, 0.0), 0.0)
	assert_eq(Formulas.beam_loss(core, -50.0), 0.0)
	assert_eq(Formulas.beam_loss(core, 100000.0), GameConfig.BEAM_LOSS_MAX)
	assert_eq(battle.network.loss(EnergyLink.new(9998, 9999)), GameConfig.BEAM_LOSS_MAX)
	assert_true(is_inf(battle.network.length(EnergyLink.new(9998, 9999))))


func test_full_target_wastes_no_energy() -> void:
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(0, -200))
	var battery := BattleFixtures.add(battle, GameConfig.BATTERY, relay.position + Vector2(224, 0))
	battle.network.connect_buildings(relay.id, battery.id)
	var link := battle.state.find_link(relay.id, battery.id)
	battery.energy = Formulas.capacity(battery) - 1.0
	relay.energy = 20.0
	battle.network.flow(1.0)
	assert_almost_eq(battery.energy, Formulas.capacity(battery), 0.001)
	assert_almost_eq(relay.energy, 20.0 - 1.0 / battle.network.efficiency(link), 0.001)
