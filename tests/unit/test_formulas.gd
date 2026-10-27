extends GutTest


func _building(kind: String) -> Building:
	return Building.new(1, kind, Vector2.ZERO)


func test_base_values_without_upgrades() -> void:
	var solar := _building(GameConfig.SOLAR)
	assert_eq(Formulas.capacity(solar), 30.0)
	assert_eq(Formulas.output(solar), 8.0)
	assert_eq(Formulas.rate(solar), 10.0)
	assert_eq(Formulas.link_range(solar), 240.0)
	assert_eq(Formulas.max_links(solar), 1)
	assert_eq(Formulas.build_radius(solar), 240.0)


func test_upgrades_scale_values() -> void:
	var relay := _building(GameConfig.RELAY)
	relay.levels = {GameConfig.TRACK_RATE: 2, GameConfig.TRACK_RANGE: 1, GameConfig.TRACK_LINKS: 2}
	assert_almost_eq(Formulas.rate(relay), 60.0, 0.001)
	assert_almost_eq(Formulas.link_range(relay), 330.0 * 1.15, 0.001)
	assert_eq(Formulas.max_links(relay), 5)
	var battery := _building(GameConfig.BATTERY)
	battery.levels = {GameConfig.TRACK_CAPACITY: 1}
	assert_almost_eq(Formulas.capacity(battery), 640.0, 0.001)


func test_towers_have_no_links_even_with_levels() -> void:
	var zapper := _building(GameConfig.ZAPPER)
	zapper.levels = {GameConfig.TRACK_LINKS: 2}
	assert_eq(Formulas.max_links(zapper), 0)


func test_tower_attack_values() -> void:
	var zapper := _building(GameConfig.ZAPPER)
	zapper.levels = {GameConfig.TRACK_POWER: 2, GameConfig.TRACK_SPEED: 2, GameConfig.TRACK_RANGE: 2}
	assert_almost_eq(Formulas.damage(zapper), 26.0 * 1.6, 0.001)
	assert_almost_eq(Formulas.cooldown(zapper), 0.45 / 1.3, 0.001)
	assert_almost_eq(Formulas.attack_range(zapper), 230.0 * 1.3, 0.001)
	assert_eq(Formulas.shot_energy(zapper), 4.0)


func test_enemy_turret_ignores_levels() -> void:
	var turret := _building(GameConfig.TURRET)
	turret.levels = {GameConfig.TRACK_POWER: 5}
	assert_eq(Formulas.damage(turret), 16.0)
	assert_eq(Formulas.cooldown(turret), 1.2)
	assert_eq(Formulas.attack_range(turret), 215.0)


func test_shield_values() -> void:
	var shield := _building(GameConfig.SHIELD)
	assert_eq(Formulas.shield_radius(shield), 210.0)
	shield.levels = {GameConfig.TRACK_POWER: 1}
	assert_almost_eq(Formulas.shield_ratio(shield), GameConfig.SHIELD_RATIO * 1.3, 0.001)
	assert_eq(Formulas.shield_radius(_building(GameConfig.SOLAR)), 0.0)


func test_export_rate() -> void:
	var exporter := _building(GameConfig.EXPORTER)
	assert_eq(Formulas.export_rate(exporter), 8.0)
	exporter.levels = {GameConfig.TRACK_RATE: 1}
	assert_almost_eq(Formulas.export_rate(exporter), 8.0 * Formulas.multiplier(exporter, GameConfig.TRACK_RATE), 0.001)
	assert_eq(Formulas.export_rate(_building(GameConfig.BATTERY)), 0.0)
	assert_eq(Formulas.max_links(exporter), 0)


func test_upgrade_cost_grows() -> void:
	var solar := _building(GameConfig.SOLAR)
	var first := Formulas.upgrade_cost(solar, GameConfig.TRACK_RATE)
	assert_eq(first, int(round(40 * 0.55)))
	solar.levels[GameConfig.TRACK_RATE] = 2
	assert_eq(Formulas.upgrade_cost(solar, GameConfig.TRACK_RATE), int(round(40 * 0.55 * pow(1.7, 2))))
	assert_eq(Formulas.upgrade_base(GameConfig.CORE), 120)


func test_maxed() -> void:
	var relay := _building(GameConfig.RELAY)
	assert_false(Formulas.is_maxed(relay, GameConfig.TRACK_LINKS))
	relay.levels[GameConfig.TRACK_LINKS] = 3
	assert_true(Formulas.is_maxed(relay, GameConfig.TRACK_LINKS))


func test_sell_value_is_half_of_spent() -> void:
	var battery := _building(GameConfig.BATTERY)
	battery.spent = 125
	assert_eq(Formulas.sell_value(battery), 62)


func test_cycle_count() -> void:
	var spawns := {"cycle": 100.0, "base": 2.0, "growth": 1.0, "night": 1.5}
	assert_eq(Formulas.cycle_count(spawns, 0, false), 2.0)
	assert_eq(Formulas.cycle_count(spawns, 2, false), 4.0)
	assert_eq(Formulas.cycle_count(spawns, 2, true), 6.0)
	assert_eq(Formulas.cycle_count(spawns, -3, false), 2.0)
	assert_eq(Formulas.cycle_count(spawns, 1000, false), GameConfig.MAX_CYCLE_COUNT)
	assert_eq(Formulas.cycle_count(spawns, 1000, true), GameConfig.MAX_CYCLE_COUNT * 1.5)


func test_spawn_density_starts_calm_and_peaks_at_end() -> void:
	assert_almost_eq(Formulas.spawn_density(0.0), GameConfig.SPAWN_CALM, 0.0001)
	assert_almost_eq(Formulas.spawn_density(1.0), GameConfig.SPAWN_CALM + (1.0 - GameConfig.SPAWN_CALM) * 4.0, 0.0001)
	assert_lt(Formulas.spawn_density(0.3), Formulas.spawn_density(0.8))
	assert_eq(Formulas.spawn_density(2.0), Formulas.spawn_density(1.0))
	var total := 0.0
	for i in 1000:
		total += Formulas.spawn_density((i + 0.5) / 1000.0) / 1000.0
	assert_almost_eq(total, 1.0, 0.001)


func test_spawn_rate() -> void:
	var spawns := {"cycle": 100.0, "base": 10.0, "growth": 0.0, "night": 2.0}
	assert_almost_eq(Formulas.spawn_rate(spawns, 0, 0.0, false), 0.1 * GameConfig.SPAWN_CALM, 0.0001)
	assert_almost_eq(Formulas.spawn_rate(spawns, 0, 0.0, true), 0.2 * GameConfig.SPAWN_CALM, 0.0001)


func test_healer_values() -> void:
	var healer := _building(GameConfig.HEALER)
	assert_eq(Formulas.heal_amount(healer), 20.0)
	assert_eq(Formulas.heal_cooldown(healer), 0.9)
	assert_eq(Formulas.heal_range(healer), 230.0)
	assert_eq(Formulas.heal_energy(healer), 6.0)
	healer.levels = {GameConfig.TRACK_POWER: 1, GameConfig.TRACK_SPEED: 2, GameConfig.TRACK_RANGE: 1}
	assert_almost_eq(Formulas.heal_amount(healer), 20.0 * 1.3, 0.001)
	assert_almost_eq(Formulas.heal_cooldown(healer), 0.9 / 1.3, 0.001)
	assert_almost_eq(Formulas.heal_range(healer), 230.0 * 1.15, 0.001)
	assert_eq(Formulas.heal_amount(_building(GameConfig.ZAPPER)), 0.0)


func test_bulwark_is_cheap_and_disproportionately_tough() -> void:
	var bulwark := _building(GameConfig.BULWARK)
	var zapper := _building(GameConfig.ZAPPER)
	assert_eq(bulwark.max_hp(), 2000.0)
	assert_gt(bulwark.max_hp() / float(GameConfig.building(GameConfig.BULWARK).cost), 50.0 * zapper.max_hp() / float(GameConfig.building(GameConfig.ZAPPER).cost))
	bulwark.levels = {GameConfig.TRACK_HULL: 2}
	assert_almost_eq(bulwark.max_hp(), 2000.0 * 2.0, 0.001)
	assert_eq(Formulas.capacity(bulwark), 0.0)
	assert_eq(Formulas.build_radius(bulwark), 0.0)


func test_bulwark_cost_grows_slowly_with_count() -> void:
	var state := BattleFixtures.battle(0).state
	assert_eq(Formulas.build_cost(state, GameConfig.BULWARK), 4)
	for i in 6:
		state.add_building(GameConfig.BULWARK, state.map.center_of(Vector2i(2 + i, 2)))
	assert_eq(Formulas.build_cost(state, GameConfig.BULWARK), 5)
	for i in 6:
		state.add_building(GameConfig.BULWARK, state.map.center_of(Vector2i(2 + i, 3)))
	assert_eq(Formulas.build_cost(state, GameConfig.BULWARK), 6)
	assert_eq(Formulas.build_cost(state, GameConfig.SOLAR), 40)


func test_high_ground_boosts_range_and_vision() -> void:
	var zapper := _building(GameConfig.ZAPPER)
	var flat_range := Formulas.attack_range(zapper)
	var flat_vision := Formulas.vision(zapper)
	assert_eq(flat_vision, flat_range + GameConfig.VISION_MARGIN)
	zapper.elevation = 1
	assert_almost_eq(Formulas.attack_range(zapper), flat_range * (1.0 + GameConfig.HIGH_GROUND_BONUS), 0.001)
	assert_gt(Formulas.vision(zapper), flat_vision)
	assert_eq(Formulas.vision(_building(GameConfig.SOLAR)), GameConfig.VISION_DEFAULT)
	assert_eq(Formulas.vision(_building(GameConfig.CORE)), 460.0)


func test_combo_tier_and_bonus() -> void:
	assert_eq(Formulas.combo_tier(4), 0)
	assert_eq(Formulas.combo_tier(5), 1)
	assert_eq(Formulas.combo_tier(36), 4)
	assert_eq(Formulas.combo_bonus(10), 10)
	assert_eq(Formulas.combo_bonus(11), 0)


func test_stars() -> void:
	assert_eq(Formulas.stars(1.0, 0), 3)
	assert_eq(Formulas.stars(0.85, 3), 2)
	assert_eq(Formulas.stars(0.5, 0), 2)
	assert_eq(Formulas.stars(0.1, 0), 1)
