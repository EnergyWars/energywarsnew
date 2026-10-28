extends GutTest

var battle: Battle
var state: BattleState
var core: Building


func before_each() -> void:
	battle = BattleFixtures.battle(0, false)
	state = battle.state
	core = state.core()


func _add(kind: String, position: Vector2) -> Building:
	return BattleFixtures.add(battle, kind, position)


func _link(source: Building, target: Building) -> EnergyLink:
	assert_true(battle.network.connect_buildings(source.id, target.id), "%s>%s" % [source.kind, target.kind])
	return state.find_link(source.id, target.id)


func _zapper_draw() -> float:
	return 4.0 / 0.45


func _night_storage(building: Building) -> float:
	return Formulas.capacity(building) / float(state.level.night)


func test_core_is_a_producer_without_indicator() -> void:
	var audit := EnergyAudit.measure(state)
	assert_true(audit.has(core.id))
	assert_false(audit.shows(core.id))
	assert_eq(audit.verdict(core.id), EnergyAudit.Verdict.NONE)
	assert_eq(audit.cause(core.id), EnergyAudit.Cause.NONE)
	assert_eq(audit.missing(core.id), 0.0)
	assert_almost_eq(audit.need_of(core.id), 3.0 / 0.7, 0.001)
	assert_almost_eq(audit.demand_of(core.id), 3.0 / 0.7, 0.001)
	assert_eq(audit.resolve(core.id), EnergyAudit.DAY)
	assert_almost_eq(audit.supply(core.id), 3.0, 0.001)
	assert_almost_eq(audit.ratio(core.id), 0.7, 0.001)
	assert_almost_eq(audit.shortfall(core.id), 3.0 / 0.7 - 3.0, 0.001)
	assert_almost_eq(audit.reserve_rate(core.id), _night_storage(core), 0.001)
	assert_almost_eq(audit.available(core.id, EnergyAudit.NIGHT), 3.0 + _night_storage(core), 0.001)
	assert_almost_eq(audit.ratio(core.id, EnergyAudit.NIGHT), 1.0, 0.001)
	assert_eq(audit.loss_rate(), 0.0)
	assert_eq(audit.transfer_efficiency(), 1.0)


func test_strong_core_supplies_a_tower_day_and_night() -> void:
	core.set_level(GameConfig.TRACK_OUTPUT, 30)
	var zapper := _add(GameConfig.ZAPPER, core.position + Vector2(0, -168))
	var link := _link(core, zapper)
	var audit := EnergyAudit.measure(state)
	var yield_rate := battle.network.efficiency(link)
	assert_almost_eq(audit.link_yield(link.key()), yield_rate, 0.0001)
	assert_almost_eq(audit.link_loss(link.key()), 1.0 - yield_rate, 0.0001)
	assert_almost_eq(audit.link_cap(link.key()), Formulas.beam_rate(core, 1), 0.0001)
	assert_true(audit.is_active(link.key()))
	assert_true(audit.shows(zapper.id))
	assert_almost_eq(audit.need_of(zapper.id), _zapper_draw(), 0.001)
	assert_almost_eq(audit.need_of(core.id), 3.0 / 0.7 + _zapper_draw() / yield_rate, 0.001)
	assert_almost_eq(audit.supply(zapper.id), _zapper_draw(), 0.001)
	assert_almost_eq(audit.inflow(zapper.id), _zapper_draw(), 0.001)
	assert_almost_eq(audit.flow(link.key()), _zapper_draw() / yield_rate, 0.001)
	assert_almost_eq(audit.delivered(link.key()), _zapper_draw(), 0.001)
	assert_almost_eq(audit.throughput(core.id), _zapper_draw() / yield_rate, 0.001)
	assert_almost_eq(audit.loss_rate(), _zapper_draw() / yield_rate * (1.0 - yield_rate), 0.001)
	assert_almost_eq(audit.transfer_efficiency(), yield_rate, 0.0001)
	assert_eq(audit.verdict(zapper.id), EnergyAudit.Verdict.OK)
	assert_eq(audit.verdict(zapper.id, EnergyAudit.NIGHT), EnergyAudit.Verdict.OK)
	assert_eq(audit.cause(zapper.id), EnergyAudit.Cause.NONE)
	assert_eq(audit.missing(zapper.id), 0.0)
	assert_almost_eq(audit.ratio(zapper.id, EnergyAudit.NIGHT), 1.0, 0.001)
	assert_false(audit.is_saturated(link.key()))
	var chain := audit.chain(zapper.id)
	assert_eq(chain.buildings, [core.id] as Array[int])
	assert_eq(chain.links, [link.key()] as Array[String])


func test_battery_bridges_the_night_with_its_storage() -> void:
	var battery := _add(GameConfig.BATTERY, core.position + Vector2(0, -476))
	var left := _add(GameConfig.SOLAR, battery.position + Vector2(-112, 0))
	var right := _add(GameConfig.SOLAR, battery.position + Vector2(112, 0))
	var zapper := _add(GameConfig.ZAPPER, battery.position + Vector2(0, -112))
	_link(left, battery)
	_link(right, battery)
	var feed := _link(battery, zapper)
	var audit := EnergyAudit.measure(state)
	var yield_rate := battle.network.efficiency(feed)
	var night := _night_storage(battery) * yield_rate / _zapper_draw()
	assert_almost_eq(audit.reserve_rate(battery.id), _night_storage(battery), 0.001)
	assert_eq(audit.reserve_rate(left.id), 0.0)
	assert_almost_eq(audit.need_of(battery.id), _zapper_draw() / yield_rate, 0.001)
	assert_almost_eq(audit.ratio(zapper.id, EnergyAudit.DAY), 1.0, 0.001)
	assert_gt(night, 0.5)
	assert_almost_eq(audit.ratio(zapper.id, EnergyAudit.NIGHT), night, 0.001)
	assert_almost_eq(audit.missing(zapper.id, EnergyAudit.NIGHT), 1.0 - night, 0.001)
	assert_eq(audit.verdict(zapper.id, EnergyAudit.DAY), EnergyAudit.Verdict.OK)
	assert_eq(audit.verdict(zapper.id, EnergyAudit.NIGHT), EnergyAudit.Verdict.LOW)
	assert_eq(audit.resolve(zapper.id), EnergyAudit.NIGHT)
	assert_eq(audit.verdict(zapper.id), EnergyAudit.Verdict.LOW)
	assert_eq(audit.cause(zapper.id), EnergyAudit.Cause.STORAGE)
	assert_eq(audit.culprit(zapper.id), battery.id)
	assert_eq(audit.cause(battery.id), EnergyAudit.Cause.STORAGE)
	assert_eq(audit.culprit(battery.id), battery.id)
	assert_almost_eq(audit.night_reserve(battery.id), Formulas.capacity(battery) / audit.need_of(battery.id), 0.01)
	assert_eq(audit.link_scenario(feed.key()), EnergyAudit.NIGHT)
	assert_almost_eq(audit.flow(feed.key()), audit.flow(feed.key(), EnergyAudit.NIGHT), 0.0001)
	assert_eq(audit.verdict(left.id), EnergyAudit.Verdict.NONE)
	var chain := audit.chain(zapper.id)
	assert_true(chain.buildings.has(battery.id))
	assert_true(chain.buildings.has(left.id))
	assert_true(chain.buildings.has(right.id))
	assert_false(chain.buildings.has(core.id))
	assert_eq(chain.links.size(), 3)
	assert_lt(audit.loss_rate(EnergyAudit.NIGHT), audit.loss_rate(EnergyAudit.DAY))
	assert_lt(audit.supply_ratio(EnergyAudit.NIGHT), audit.supply_ratio(EnergyAudit.DAY))


func test_bigger_battery_keeps_the_tower_supplied_at_night() -> void:
	var battery := _add(GameConfig.BATTERY, core.position + Vector2(0, -476))
	var left := _add(GameConfig.SOLAR, battery.position + Vector2(-112, 0))
	var right := _add(GameConfig.SOLAR, battery.position + Vector2(112, 0))
	var zapper := _add(GameConfig.ZAPPER, battery.position + Vector2(0, -112))
	_link(left, battery)
	_link(right, battery)
	_link(battery, zapper)
	battery.set_level(GameConfig.TRACK_CAPACITY, 5)
	var audit := EnergyAudit.measure(state)
	assert_almost_eq(audit.ratio(zapper.id, EnergyAudit.NIGHT), 1.0, 0.001)
	assert_eq(audit.verdict(zapper.id), EnergyAudit.Verdict.OK)
	assert_eq(audit.verdict(battery.id), EnergyAudit.Verdict.OK)
	assert_lt(audit.night_reserve(battery.id), INF)
	assert_gt(audit.night_reserve(battery.id), float(state.level.night))


func test_solar_without_storage_is_dark_at_night() -> void:
	var zapper := _add(GameConfig.ZAPPER, core.position + Vector2(0, -476))
	var left := _add(GameConfig.SOLAR, zapper.position + Vector2(-112, 0))
	var right := _add(GameConfig.SOLAR, zapper.position + Vector2(112, 0))
	_link(left, zapper)
	_link(right, zapper)
	var audit := EnergyAudit.measure(state)
	assert_eq(audit.verdict(zapper.id, EnergyAudit.DAY), EnergyAudit.Verdict.OK)
	assert_eq(audit.ratio(zapper.id, EnergyAudit.NIGHT), 0.0)
	assert_eq(audit.missing(zapper.id), 1.0)
	assert_eq(audit.cause(zapper.id), EnergyAudit.Cause.NIGHT)
	assert_eq(audit.culprit(zapper.id), -1)
	assert_true(is_inf(audit.night_reserve(zapper.id)))


func test_tiny_relay_storage_is_not_blamed_at_night() -> void:
	var relay := _add(GameConfig.RELAY, core.position + Vector2(0, -476))
	var left := _add(GameConfig.SOLAR, relay.position + Vector2(-112, 0))
	var right := _add(GameConfig.SOLAR, relay.position + Vector2(112, 0))
	var zapper := _add(GameConfig.ZAPPER, relay.position + Vector2(0, -112))
	_link(left, relay)
	_link(right, relay)
	_link(relay, zapper)
	var audit := EnergyAudit.measure(state)
	assert_almost_eq(audit.reserve_rate(relay.id), _night_storage(relay), 0.001)
	assert_lt(audit.reserve_rate(relay.id), EnergyAudit.RESERVE_SHARE * audit.need_of(relay.id))
	assert_eq(audit.verdict(zapper.id, EnergyAudit.DAY), EnergyAudit.Verdict.OK)
	assert_eq(audit.cause(zapper.id), EnergyAudit.Cause.NIGHT)
	assert_eq(audit.cause(relay.id), EnergyAudit.Cause.NIGHT)


func test_relay_and_battery_need_what_they_forward() -> void:
	core.set_level(GameConfig.TRACK_OUTPUT, 30)
	var relay := _add(GameConfig.RELAY, core.position + Vector2(0, -224))
	var zapper := _add(GameConfig.ZAPPER, relay.position + Vector2(GameConfig.CELL, 0))
	var idle := _add(GameConfig.BATTERY, core.position + Vector2(-224, 0))
	var feed := _link(core, relay)
	var beam := _link(relay, zapper)
	_link(core, idle)
	var audit := EnergyAudit.measure(state)
	assert_eq(audit.link_loss(beam.key()), 0.0)
	assert_eq(audit.demand_of(relay.id), 0.0)
	assert_almost_eq(audit.need_of(relay.id), _zapper_draw(), 0.001)
	assert_almost_eq(audit.need_of(core.id), 3.0 / 0.7 + _zapper_draw() / audit.link_yield(feed.key()), 0.001)
	assert_almost_eq(audit.delivered(beam.key()), _zapper_draw(), 0.001)
	assert_almost_eq(audit.link_cap(beam.key()), Formulas.beam_rate(relay, 1), 0.001)
	assert_eq(audit.verdict(relay.id), EnergyAudit.Verdict.OK)
	assert_eq(audit.verdict(zapper.id), EnergyAudit.Verdict.OK)
	assert_eq(audit.need_of(idle.id), 0.0)
	assert_eq(audit.ratio(idle.id), 1.0)
	assert_eq(audit.verdict(idle.id), EnergyAudit.Verdict.OK)


func test_overloaded_tower_needs_nothing_and_is_flagged() -> void:
	var zapper := _add(GameConfig.ZAPPER, core.position + Vector2(0, -168))
	_link(core, zapper)
	zapper.set_level(GameConfig.TRACK_OVERCLOCK, 11)
	assert_true(Formulas.is_overloaded(zapper))
	var audit := EnergyAudit.measure(state)
	assert_eq(audit.need_of(zapper.id), 0.0)
	assert_eq(audit.verdict(zapper.id), EnergyAudit.Verdict.OVERLOADED)
	assert_eq(audit.verdict(zapper.id, EnergyAudit.NIGHT), EnergyAudit.Verdict.OVERLOADED)
	assert_eq(audit.cause(zapper.id), EnergyAudit.Cause.OVERLOAD)
	assert_eq(audit.missing(zapper.id), 0.0)


func test_unconnected_buildings_have_no_source() -> void:
	var relay := _add(GameConfig.RELAY, core.position + Vector2(0, -224))
	var zapper := _add(GameConfig.ZAPPER, core.position + Vector2(224, 0))
	var audit := EnergyAudit.measure(state)
	assert_eq(audit.verdict(relay.id), EnergyAudit.Verdict.LOW)
	assert_eq(audit.cause(relay.id), EnergyAudit.Cause.NO_SOURCE)
	assert_eq(audit.ratio(relay.id), 0.0)
	assert_eq(audit.missing(relay.id), 1.0)
	assert_eq(audit.reserve_rate(relay.id), 0.0)
	assert_eq(audit.verdict(zapper.id), EnergyAudit.Verdict.LOW)
	assert_eq(audit.cause(zapper.id, EnergyAudit.DAY), EnergyAudit.Cause.NO_SOURCE)
	assert_eq(audit.missing(zapper.id), 1.0)
	assert_true(audit.chain(zapper.id).buildings.is_empty())


func test_out_of_range_beam_is_named() -> void:
	var relay := _add(GameConfig.RELAY, core.position + Vector2(0, -224))
	var zapper := _add(GameConfig.ZAPPER, relay.position + Vector2(0, -112))
	var feed := _link(core, relay)
	_link(relay, zapper)
	state.move_building(relay, core.position + Vector2(0, -700))
	var audit := EnergyAudit.measure(state)
	assert_false(audit.is_active(feed.key()))
	assert_eq(audit.verdict(relay.id), EnergyAudit.Verdict.LOW)
	assert_eq(audit.cause(relay.id), EnergyAudit.Cause.OUT_OF_RANGE)
	assert_eq(audit.culprit(relay.id), core.id)
	assert_eq(audit.culprit_link(relay.id), feed.key())
	assert_eq(audit.cause(zapper.id), EnergyAudit.Cause.OUT_OF_RANGE)
	assert_true(audit.chain(zapper.id).links.has(feed.key()))


func test_saturated_beam_is_the_bottleneck() -> void:
	var solar := _add(GameConfig.SOLAR, core.position + Vector2(-336, -336))
	var exporter := _add(GameConfig.EXPORTER, solar.position + Vector2(168, 0))
	var link := _link(solar, exporter)
	var audit := EnergyAudit.measure(state)
	assert_true(audit.is_saturated(link.key(), EnergyAudit.DAY))
	assert_false(audit.is_saturated(link.key(), EnergyAudit.NIGHT))
	assert_almost_eq(audit.flow(link.key(), EnergyAudit.DAY), Formulas.output(solar), 0.001)
	assert_eq(audit.verdict(exporter.id, EnergyAudit.DAY), EnergyAudit.Verdict.LOW)
	assert_eq(audit.cause(exporter.id, EnergyAudit.DAY), EnergyAudit.Cause.BEAM_RATE)
	assert_eq(audit.culprit(exporter.id, EnergyAudit.DAY), solar.id)
	assert_eq(audit.culprit_link(exporter.id, EnergyAudit.DAY), link.key())
	assert_eq(audit.cause(exporter.id, EnergyAudit.NIGHT), EnergyAudit.Cause.NIGHT)
	assert_eq(audit.resolve(exporter.id), EnergyAudit.NIGHT)
	assert_almost_eq(audit.served_of(exporter.id), Formulas.output(solar) * battle.network.efficiency(link), 0.001)
	assert_almost_eq(audit.export_income(), Formulas.export_income(Formulas.output(solar) * battle.network.efficiency(link)), 0.001)
	assert_eq(audit.export_income(EnergyAudit.NIGHT), 0.0)


func test_long_lossy_beam_is_named() -> void:
	core.set_level(GameConfig.TRACK_OUTPUT, 20)
	var relay := _add(GameConfig.RELAY, core.position + Vector2(0, -168))
	relay.set_level(GameConfig.TRACK_RANGE, 15)
	var zapper := _add(GameConfig.ZAPPER, relay.position + Vector2(504, 0))
	_link(core, relay)
	var lossy := _link(relay, zapper)
	var audit := EnergyAudit.measure(state)
	assert_gte(audit.link_loss(lossy.key()), EnergyAudit.HEAVY_LOSS)
	assert_eq(audit.resolve(zapper.id), EnergyAudit.DAY)
	assert_eq(audit.verdict(zapper.id), EnergyAudit.Verdict.LOW)
	assert_eq(audit.cause(zapper.id), EnergyAudit.Cause.BEAM_LOSS)
	assert_eq(audit.culprit(zapper.id), relay.id)
	assert_eq(audit.culprit_link(zapper.id), lossy.key())


func test_core_that_forwards_everything_starves_its_towers() -> void:
	var zapper := _add(GameConfig.ZAPPER, core.position + Vector2(0, -168))
	var tesla := _add(GameConfig.TESLA, core.position + Vector2(168, 0))
	var plasma := _add(GameConfig.PLASMA, core.position + Vector2(-168, 0))
	for tower: Building in [zapper, tesla, plasma]:
		_link(core, tower)
	var audit := EnergyAudit.measure(state)
	assert_eq(audit.verdict(core.id), EnergyAudit.Verdict.NONE)
	for tower: Building in [zapper, tesla, plasma]:
		assert_eq(audit.verdict(tower.id), EnergyAudit.Verdict.LOW, tower.kind)
		assert_eq(audit.resolve(tower.id), EnergyAudit.DAY, tower.kind)
		assert_eq(audit.cause(tower.id), EnergyAudit.Cause.GENERATION, tower.kind)
		assert_gt(audit.missing(tower.id), 0.5, tower.kind)
	assert_almost_eq(audit.throughput(core.id), 3.0, 0.001)
	assert_almost_eq(audit.throughput(core.id, EnergyAudit.NIGHT), 3.0 + _night_storage(core), 0.001)


func test_cycles_converge() -> void:
	var a := _add(GameConfig.RELAY, core.position + Vector2(0, -224))
	var b := _add(GameConfig.RELAY, a.position + Vector2(168, 0))
	var c := _add(GameConfig.RELAY, a.position + Vector2(84, -168))
	var zapper := _add(GameConfig.ZAPPER, c.position + Vector2(0, -112))
	_link(core, a)
	_link(a, b)
	_link(b, c)
	_link(c, a)
	_link(c, zapper)
	var audit := EnergyAudit.measure(state)
	assert_true(audit.has(zapper.id))
	assert_gt(audit.supply(zapper.id), 0.0)
	assert_lte(audit.supply(zapper.id), audit.need_of(zapper.id) + 0.001)
	assert_ne(audit.verdict(zapper.id), EnergyAudit.Verdict.NONE)
	assert_ne(audit.cause(zapper.id), EnergyAudit.Cause.NO_SOURCE)
	assert_eq(audit.chain(zapper.id).buildings.size(), 4)


func test_view_scenario_follows_the_phase_and_daytime() -> void:
	state.phase = BattleState.Phase.PLAN
	assert_eq(EnergyAudit.view_scenario(state), EnergyAudit.WORST)
	state.phase = BattleState.Phase.FIGHT
	state.round_time = 1.0
	assert_eq(EnergyAudit.view_scenario(state), EnergyAudit.DAY)
	state.round_time = float(state.level.day) + 1.0
	assert_eq(EnergyAudit.view_scenario(state), EnergyAudit.NIGHT)


func test_water_fill_splits_fairly_within_limits() -> void:
	var shares := EnergyAudit.water_fill(10.0, PackedFloat64Array([2.0, 20.0, 20.0]))
	assert_almost_eq(shares[0], 2.0, 0.0001)
	assert_almost_eq(shares[1], 4.0, 0.0001)
	assert_almost_eq(shares[2], 4.0, 0.0001)
	var plenty := EnergyAudit.water_fill(100.0, PackedFloat64Array([2.0, 3.0, 0.0]))
	assert_almost_eq(plenty[0], 2.0, 0.0001)
	assert_almost_eq(plenty[1], 3.0, 0.0001)
	assert_eq(plenty[2], 0.0)
	assert_eq(EnergyAudit.water_fill(-5.0, PackedFloat64Array([1.0]))[0], 0.0)
	assert_true(EnergyAudit.water_fill(5.0, PackedFloat64Array()).is_empty())


func test_unknown_ids_and_walls_are_ignored() -> void:
	var wall := _add(GameConfig.BULWARK, core.position + Vector2(0, -224))
	var audit := EnergyAudit.measure(state)
	assert_false(audit.has(wall.id))
	assert_false(audit.shows(wall.id))
	assert_eq(audit.verdict(wall.id), EnergyAudit.Verdict.NONE)
	assert_eq(audit.cause(4242), EnergyAudit.Cause.NONE)
	assert_eq(audit.culprit(4242), -1)
	assert_eq(audit.culprit_link(4242), "")
	assert_eq(audit.ratio(4242), 1.0)
	assert_eq(audit.missing(4242), 0.0)
	assert_eq(audit.need_of(4242), 0.0)
	assert_eq(audit.reserve_rate(4242), 0.0)
	assert_true(is_inf(audit.night_reserve(4242)))
	assert_true(audit.chain(4242).buildings.is_empty())
	assert_eq(audit.link_yield("nope"), 1.0)
	assert_eq(audit.link_loss("nope"), 0.0)
	assert_eq(audit.link_cap("nope"), 0.0)
	assert_eq(audit.delivered("nope"), 0.0)
	assert_false(audit.is_active("nope"))
	assert_false(audit.is_saturated("nope"))


func test_draw_per_role() -> void:
	assert_almost_eq(EnergyAudit.draw(_add(GameConfig.EXPORTER, core.position + Vector2(0, -224))), 8.0, 0.001)
	assert_almost_eq(EnergyAudit.draw(_add(GameConfig.ZAPPER, core.position + Vector2(224, 0))), _zapper_draw(), 0.001)
	assert_eq(EnergyAudit.draw(_add(GameConfig.RELAY, core.position + Vector2(-224, 0))), 0.0)


func test_battle_caches_the_audit_until_the_layout_changes() -> void:
	var first := battle.audit()
	assert_same(battle.audit(), first)
	var zapper := _add(GameConfig.ZAPPER, core.position + Vector2(0, -168))
	var second := battle.audit()
	assert_ne(second, first)
	assert_true(second.has(zapper.id))
	battle.network.connect_buildings(core.id, zapper.id)
	var third := battle.audit()
	assert_ne(third, second)
	state.money = 10000
	assert_true(battle.upgrade(zapper.id, GameConfig.TRACK_OVERCLOCK))
	assert_ne(battle.audit(), third)
	var fourth := battle.audit()
	state.move_building(zapper, core.position + Vector2(0, -224))
	assert_ne(battle.audit(), fourth)
