extends GutTest

var battle: Battle
var state: BattleState
var core: Building


func before_each() -> void:
	battle = BattleFixtures.battle(GameConfig.level_count() - 1, false)
	state = battle.state
	core = state.core()


func _add(kind: String, offset: Vector2) -> Building:
	return BattleFixtures.add(battle, kind, core.position + offset)


func _core_draw() -> float:
	return 3.0 / 0.7


func test_core_alone() -> void:
	var stats := EnergyStats.measure(state)
	assert_almost_eq(stats.value(EnergyStats.Metric.GENERATION_DAY), 3.0, 0.001)
	assert_almost_eq(stats.value(EnergyStats.Metric.GENERATION_NIGHT), 3.0, 0.001)
	assert_almost_eq(stats.value(EnergyStats.Metric.CAPACITY), 300.0, 0.001)
	assert_almost_eq(stats.value(EnergyStats.Metric.STORED), 150.0, 0.001)
	assert_almost_eq(stats.value(EnergyStats.Metric.FILL_RATIO), 0.5, 0.001)
	assert_almost_eq(stats.value(EnergyStats.Metric.FILL_TIME), 50.0, 0.001)
	assert_almost_eq(stats.value(EnergyStats.Metric.FIRE_DRAW), _core_draw(), 0.001)
	assert_eq(stats.value(EnergyStats.Metric.EXPORT_DRAW), 0.0)
	assert_almost_eq(stats.value(EnergyStats.Metric.NET_DAY), 3.0 - _core_draw(), 0.001)
	assert_almost_eq(stats.value(EnergyStats.Metric.NET_NIGHT), 3.0 - _core_draw(), 0.001)
	assert_almost_eq(stats.value(EnergyStats.Metric.RESERVE_DAY), 150.0 / (_core_draw() - 3.0), 0.01)
	assert_almost_eq(stats.value(EnergyStats.Metric.RESERVE_NIGHT), 150.0 / (_core_draw() - 3.0), 0.01)
	assert_almost_eq(stats.value(EnergyStats.Metric.RESERVE_FULL), 300.0 / (_core_draw() - 3.0), 0.01)


func test_solar_counts_only_by_day() -> void:
	_add(GameConfig.SOLAR, Vector2(168, 0))
	var stats := EnergyStats.measure(state)
	assert_almost_eq(stats.value(EnergyStats.Metric.GENERATION_DAY), 11.0, 0.001)
	assert_almost_eq(stats.value(EnergyStats.Metric.GENERATION_NIGHT), 3.0, 0.001)
	assert_almost_eq(stats.value(EnergyStats.Metric.CAPACITY), 330.0, 0.001)
	assert_true(is_inf(stats.value(EnergyStats.Metric.RESERVE_DAY)))
	assert_false(is_inf(stats.value(EnergyStats.Metric.RESERVE_NIGHT)))


func test_towers_healers_and_exporters_add_their_draw() -> void:
	var zapper := _add(GameConfig.ZAPPER, Vector2(168, 0))
	var laser := _add(GameConfig.LASER, Vector2(-168, 0))
	var healer := _add(GameConfig.HEALER, Vector2(0, 168))
	_add(GameConfig.EXPORTER, Vector2(0, -168))
	_add(GameConfig.RELAY, Vector2(168, 168))
	assert_almost_eq(EnergyStats.fire_draw(zapper), 4.0 / 0.45, 0.001)
	assert_almost_eq(EnergyStats.fire_draw(laser), 10.0, 0.001)
	assert_almost_eq(EnergyStats.fire_draw(healer), 6.0 / 0.9, 0.001)
	var stats := EnergyStats.measure(state)
	var fire := _core_draw() + 4.0 / 0.45 + 10.0 + 6.0 / 0.9
	assert_almost_eq(stats.value(EnergyStats.Metric.FIRE_DRAW), fire, 0.001)
	assert_almost_eq(stats.value(EnergyStats.Metric.EXPORT_DRAW), 8.0, 0.001)
	assert_almost_eq(stats.value(EnergyStats.Metric.NET_DAY), 3.0 - 8.0 - fire, 0.001)
	assert_true(is_inf(stats.value(EnergyStats.Metric.FILL_TIME)))


func test_enemy_turrets_are_ignored() -> void:
	_add(GameConfig.TURRET, Vector2(400, 0))
	assert_almost_eq(EnergyStats.measure(state).value(EnergyStats.Metric.FIRE_DRAW), _core_draw(), 0.001)


func test_upgrades_change_the_numbers() -> void:
	var zapper := _add(GameConfig.ZAPPER, Vector2(168, 0))
	var before := EnergyStats.fire_draw(zapper)
	zapper.set_level(GameConfig.TRACK_SPEED, 2)
	assert_gt(EnergyStats.fire_draw(zapper), before)
	zapper.set_level(GameConfig.TRACK_EFFICIENCY, 4)
	assert_almost_eq(EnergyStats.fire_draw(zapper), 4.0 / 1.2 / (0.45 / 1.12), 0.001)
	core.set_level(GameConfig.TRACK_CAPACITY, 1)
	assert_almost_eq(EnergyStats.measure(state).value(EnergyStats.Metric.CAPACITY), 360.0 + 40.0, 0.001)


func test_full_storage_and_empty_state() -> void:
	core.energy = Formulas.capacity(core) + 50.0
	var stats := EnergyStats.measure(state)
	assert_eq(stats.value(EnergyStats.Metric.FILL_TIME), 0.0)
	assert_almost_eq(stats.value(EnergyStats.Metric.STORED), 300.0, 0.001)
	assert_almost_eq(stats.value(EnergyStats.Metric.FILL_RATIO), 1.0, 0.001)
	state.remove_building(core.id)
	var empty := EnergyStats.measure(state)
	assert_eq(empty.value(EnergyStats.Metric.CAPACITY), 0.0)
	assert_eq(empty.value(EnergyStats.Metric.FILL_RATIO), 0.0)
	assert_eq(empty.value(EnergyStats.Metric.FILL_TIME), 0.0)
	assert_true(is_inf(empty.value(EnergyStats.Metric.RESERVE_NIGHT)))


func test_non_combat_buildings_draw_nothing() -> void:
	assert_eq(EnergyStats.fire_draw(_add(GameConfig.BATTERY, Vector2(168, 0))), 0.0)
	assert_eq(EnergyStats.fire_draw(_add(GameConfig.SHIELD, Vector2(-168, 0))), 0.0)


func test_self_reserve_and_shots_per_charge() -> void:
	var zapper := _add(GameConfig.ZAPPER, Vector2(168, 0))
	assert_almost_eq(EnergyStats.self_reserve(zapper), 40.0 / (4.0 / 0.45), 0.001)
	assert_eq(EnergyStats.shots_per_charge(zapper), 10)
	var healer := _add(GameConfig.HEALER, Vector2(-168, 0))
	assert_eq(EnergyStats.shots_per_charge(healer), 13)
	var relay := _add(GameConfig.RELAY, Vector2(0, 168))
	assert_eq(EnergyStats.shots_per_charge(relay), 0)
	assert_true(is_inf(EnergyStats.self_reserve(relay)))


func test_drain_time() -> void:
	assert_almost_eq(EnergyStats.drain_time(100.0, 4.0), 25.0, 0.001)
	assert_true(is_inf(EnergyStats.drain_time(100.0, 0.0)))
	assert_true(is_inf(EnergyStats.drain_time(100.0, -2.0)))
	assert_eq(EnergyStats.drain_time(0.0, 3.0), 0.0)


func test_water_counts_day_and_night_and_lamps_add_draw() -> void:
	var water := _add(GameConfig.WATER, Vector2(168, 0))
	var lamp := _add(GameConfig.LAMP, Vector2(-168, 0))
	var stats := EnergyStats.measure(state)
	assert_almost_eq(stats.value(EnergyStats.Metric.GENERATION_DAY), 3.0 + Formulas.output(water), 0.001)
	assert_almost_eq(stats.value(EnergyStats.Metric.GENERATION_NIGHT), 3.0 + Formulas.output(water), 0.001)
	assert_almost_eq(stats.value(EnergyStats.Metric.FIRE_DRAW), _core_draw() + Formulas.lamp_draw(lamp), 0.001)


func test_fire_pit_only_counts_with_fuel() -> void:
	var fire := _add(GameConfig.FIRE, Vector2(168, 0))
	assert_almost_eq(EnergyStats.measure(state).value(EnergyStats.Metric.GENERATION_DAY), 3.0, 0.001)
	fire.fuel.append(state.map.cell_of(fire.position) + Vector2i(0, -2))
	var stats := EnergyStats.measure(state)
	assert_almost_eq(stats.value(EnergyStats.Metric.GENERATION_DAY), 3.0 + Formulas.output(fire), 0.001)
	assert_almost_eq(stats.value(EnergyStats.Metric.GENERATION_NIGHT), 3.0 + Formulas.output(fire), 0.001)
