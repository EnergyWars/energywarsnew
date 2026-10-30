extends GutTest


func _building(kind: String) -> Building:
	return Building.new(1, kind, Vector2.ZERO)


func test_base_values_without_upgrades() -> void:
	var solar := _building(GameConfig.SOLAR)
	assert_eq(Formulas.capacity(solar), 30.0)
	assert_eq(Formulas.output(solar), 8.0)
	assert_eq(Formulas.rate(solar), 8.0)
	assert_eq(Formulas.link_range(solar), 240.0)
	assert_eq(Formulas.max_links(solar), 1)
	assert_eq(Formulas.build_radius(solar), 240.0)


func test_solar_rate_equals_output_and_splits_over_beams() -> void:
	var solar := _building(GameConfig.SOLAR)
	solar.levels = {GameConfig.TRACK_OUTPUT: 2, GameConfig.TRACK_RATE: 3}
	assert_almost_eq(Formulas.rate(solar), Formulas.output(solar), 0.001)
	assert_almost_eq(Formulas.beam_rate(solar, 2), Formulas.output(solar) / 2.0, 0.001)
	assert_almost_eq(Formulas.beam_rate(solar, 0), Formulas.output(solar), 0.001)
	var relay := _building(GameConfig.RELAY)
	assert_eq(Formulas.beam_rate(relay, 3), Formulas.rate(relay))


func test_relocate_cost_and_mobility() -> void:
	var relay := _building(GameConfig.RELAY)
	relay.spent = 30 + 50
	assert_eq(Formulas.relocate_cost(relay, false), 16)
	assert_eq(Formulas.relocate_cost(relay, true), 0)
	relay.spent = 1
	assert_eq(Formulas.relocate_cost(relay, false), 1)
	var rover := _building(GameConfig.ROVER)
	assert_gt(Formulas.move_speed(rover), 0.0)
	assert_gt(Formulas.move_energy(rover), 0.0)
	assert_eq(Formulas.move_speed(relay), 0.0)
	assert_eq(Formulas.move_energy(relay), 0.0)


func test_upgrades_scale_values() -> void:
	var relay := _building(GameConfig.RELAY)
	relay.levels = {GameConfig.TRACK_RATE: 2, GameConfig.TRACK_RANGE: 1, GameConfig.TRACK_LINKS: 2}
	assert_almost_eq(Formulas.rate(relay), 30.0 * 1.24, 0.001)
	assert_almost_eq(Formulas.link_range(relay), 330.0 * 1.04, 0.001)
	assert_eq(Formulas.max_links(relay), 5)
	var battery := _building(GameConfig.BATTERY)
	battery.levels = {GameConfig.TRACK_CAPACITY: 1}
	assert_almost_eq(Formulas.capacity(battery), 480.0, 0.001)


func test_towers_have_no_links_even_with_levels() -> void:
	var zapper := _building(GameConfig.ZAPPER)
	zapper.levels = {GameConfig.TRACK_LINKS: 2}
	assert_eq(Formulas.max_links(zapper), 0)


func test_tower_attack_values() -> void:
	var zapper := _building(GameConfig.ZAPPER)
	zapper.levels = {GameConfig.TRACK_POWER: 2, GameConfig.TRACK_SPEED: 2, GameConfig.TRACK_RANGE: 2}
	assert_almost_eq(Formulas.damage(zapper), 26.0 * 1.2, 0.001)
	assert_almost_eq(Formulas.cooldown(zapper), 0.45 / 1.12, 0.001)
	assert_almost_eq(Formulas.attack_range(zapper), 230.0 * 1.08, 0.001)
	assert_eq(Formulas.shot_energy(zapper), 4.0)


func test_efficiency_lowers_energy_use() -> void:
	var zapper := _building(GameConfig.ZAPPER)
	zapper.levels = {GameConfig.TRACK_EFFICIENCY: 4}
	assert_almost_eq(Formulas.efficiency(zapper), 1.2, 0.001)
	assert_almost_eq(Formulas.shot_energy(zapper), 4.0 / 1.2, 0.001)
	var healer := _building(GameConfig.HEALER)
	healer.levels = {GameConfig.TRACK_EFFICIENCY: 10}
	assert_almost_eq(Formulas.heal_energy(healer), 6.0 / 1.5, 0.001)
	var rover := _building(GameConfig.ROVER)
	var base := Formulas.move_energy(rover)
	rover.levels = {GameConfig.TRACK_EFFICIENCY: 20}
	assert_almost_eq(Formulas.move_energy(rover), base / 2.0, 0.0001)


func test_crit_chain_and_splash_tracks() -> void:
	var zapper := _building(GameConfig.ZAPPER)
	assert_almost_eq(Formulas.crit_chance(zapper), GameConfig.CRIT_CHANCE, 0.0001)
	zapper.levels = {GameConfig.TRACK_CRIT: 8}
	assert_almost_eq(Formulas.crit_chance(zapper), GameConfig.CRIT_CHANCE + 0.08, 0.0001)
	var tesla := _building(GameConfig.TESLA)
	assert_eq(Formulas.chain_count(tesla), 5)
	tesla.levels = {GameConfig.TRACK_CHAIN: 3}
	assert_eq(Formulas.chain_count(tesla), 8)
	assert_eq(Formulas.chain_count(zapper), 1)
	var plasma := _building(GameConfig.PLASMA)
	assert_eq(Formulas.splash(plasma), 85.0)
	plasma.levels = {GameConfig.TRACK_SPLASH: 10}
	assert_almost_eq(Formulas.splash(plasma), 85.0 * 1.5, 0.001)
	assert_eq(Formulas.splash(zapper), 0.0)


func test_towers_can_grow_much_stronger() -> void:
	var zapper := _building(GameConfig.ZAPPER)
	for track: String in zapper.definition().tracks:
		zapper.set_level(track, Formulas.max_level(zapper, track))
	assert_almost_eq(Formulas.damage(zapper), 26.0 * 5.0 * Formulas.multiplier(zapper, GameConfig.TRACK_OVERCLOCK), 0.001)
	assert_gt(1.0 / Formulas.cooldown(zapper), 2.4 / 0.45)
	assert_gt(zapper.max_hp(), 90.0 * 5.0)
	assert_gte(Formulas.max_level(zapper, GameConfig.TRACK_POWER), 30)


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
	assert_almost_eq(Formulas.shield_ratio(shield), GameConfig.SHIELD_RATIO * 1.1, 0.001)
	assert_eq(Formulas.shield_radius(_building(GameConfig.SOLAR)), 0.0)


func test_export_rate() -> void:
	var exporter := _building(GameConfig.EXPORTER)
	assert_eq(Formulas.export_rate(exporter), 8.0)
	exporter.levels = {GameConfig.TRACK_RATE: 1}
	assert_almost_eq(Formulas.export_rate(exporter), 8.0 * Formulas.multiplier(exporter, GameConfig.TRACK_RATE), 0.001)
	assert_eq(Formulas.export_rate(_building(GameConfig.BATTERY)), 0.0)
	assert_eq(Formulas.max_links(exporter), 0)


func test_upgrade_cost_grows_in_small_steps() -> void:
	var solar := _building(GameConfig.SOLAR)
	assert_eq(Formulas.upgrade_cost(solar, GameConfig.TRACK_OUTPUT), int(round(40 * 0.25)))
	solar.set_level(GameConfig.TRACK_OUTPUT, 2)
	assert_eq(Formulas.upgrade_cost(solar, GameConfig.TRACK_OUTPUT), int(round(40 * 0.25 * pow(GameConfig.TRACK_GROWTH, 2))))
	var relay := _building(GameConfig.RELAY)
	relay.set_level(GameConfig.TRACK_LINKS, 2)
	assert_eq(Formulas.upgrade_cost(relay, GameConfig.TRACK_LINKS), int(round(30 * 0.8 * pow(1.6, 2))))
	var wall := _building(GameConfig.BULWARK)
	assert_eq(Formulas.upgrade_cost(wall, GameConfig.TRACK_HULL), 5)
	wall.set_level(GameConfig.TRACK_HULL, 3)
	assert_eq(Formulas.upgrade_cost(wall, GameConfig.TRACK_HULL), int(round(40 * 0.125 * pow(1.75, 3))))
	assert_eq(Formulas.upgrade_base(GameConfig.CORE), 120)


func test_maxed() -> void:
	var relay := _building(GameConfig.RELAY)
	assert_false(Formulas.is_maxed(relay, GameConfig.TRACK_LINKS))
	relay.set_level(GameConfig.TRACK_LINKS, Formulas.max_level(relay, GameConfig.TRACK_LINKS))
	assert_true(Formulas.is_maxed(relay, GameConfig.TRACK_LINKS))
	assert_eq(Formulas.max_level(relay, GameConfig.TRACK_LINKS), 5)
	var wall := _building(GameConfig.BULWARK)
	assert_eq(Formulas.max_level(wall, GameConfig.TRACK_HULL), int(GameConfig.WALL_HULL.max))
	wall.set_level(GameConfig.TRACK_HULL, int(GameConfig.WALL_HULL.max))
	assert_true(Formulas.is_maxed(wall, GameConfig.TRACK_HULL))


func test_sell_value_is_half_of_spent_scaled_by_health() -> void:
	var battery := _building(GameConfig.BATTERY)
	battery.spent = 125
	assert_eq(Formulas.sell_value(battery), 62)
	battery.hp = battery.max_hp() * 0.5
	assert_eq(Formulas.sell_value(battery), 31)
	battery.hp = 0.0
	assert_eq(Formulas.sell_value(battery), 0)


func test_sell_value_refunds_this_planning_in_full() -> void:
	var battery := _building(GameConfig.BATTERY)
	battery.spent = 200
	battery.plan_spent = 80
	assert_eq(Formulas.sell_value(battery), 80 + 60)
	battery.plan_spent = 200
	assert_eq(Formulas.sell_value(battery), 200)


func test_wave_schedule() -> void:
	var level := {"day": 80.0, "night": 60.0, "waves": {"interval": 9.0}}
	assert_eq(Formulas.wave_times(level), 16)
	assert_eq(Formulas.wave_time(level, 0), GameConfig.WAVE_FIRST)
	assert_eq(Formulas.wave_time(level, 2), GameConfig.WAVE_FIRST + 18.0)
	assert_lt(Formulas.wave_time(level, Formulas.wave_times(level) - 1), DayCycle.length(level))
	assert_gte(Formulas.wave_time(level, Formulas.wave_times(level)), DayCycle.length(level))
	assert_eq(Formulas.wave_times({"day": 1.0, "night": 1.0, "waves": {"interval": 9.0}}), 0)


func test_wave_count_grows_over_round_rounds_and_night() -> void:
	var waves := {"base": 2.0, "ramp": 1.0, "growth": 0.5, "night": 1.5}
	assert_eq(Formulas.wave_count(waves, 1, 0.0, false), 2.0)
	assert_eq(Formulas.wave_count(waves, 3, 0.5, true), 2.0 * 1.5 * 2.0 * 1.5)
	assert_eq(Formulas.wave_count(waves, 1, 4.0, false), 4.0)
	assert_eq(Formulas.wave_count(waves, 0, 0.0, false), 2.0)


func test_wave_tier_grows_with_days() -> void:
	assert_eq(Formulas.wave_tier(1), 0)
	assert_eq(Formulas.wave_tier(3), 2)
	assert_eq(Formulas.wave_tier(0), 0)


func test_enemies_grow_stronger_every_round_without_cap() -> void:
	assert_eq(Formulas.enemy_hp_scale(1), 1.0)
	assert_almost_eq(Formulas.enemy_hp_scale(4), pow(GameConfig.ROUND_HP_GROWTH, 3), 0.0001)
	assert_gt(Formulas.enemy_hp_scale(40), 100.0)
	assert_eq(Formulas.enemy_damage_scale(1), 1.0)
	assert_almost_eq(Formulas.enemy_damage_scale(3), 1.0 + 2.0 * GameConfig.ROUND_DAMAGE_GROWTH, 0.0001)
	assert_eq(Formulas.enemy_bounty_scale(1), 1.0)
	assert_almost_eq(Formulas.enemy_bounty_scale(2), 1.0 + GameConfig.ROUND_BOUNTY_GROWTH, 0.0001)
	assert_eq(Formulas.enemy_hp_scale(0), 1.0)


func test_healer_values() -> void:
	var healer := _building(GameConfig.HEALER)
	assert_eq(Formulas.heal_amount(healer), 20.0)
	assert_eq(Formulas.heal_cooldown(healer), 0.9)
	assert_eq(Formulas.heal_range(healer), 230.0)
	assert_eq(Formulas.heal_energy(healer), 6.0)
	healer.levels = {GameConfig.TRACK_POWER: 1, GameConfig.TRACK_SPEED: 2, GameConfig.TRACK_RANGE: 1}
	assert_almost_eq(Formulas.heal_amount(healer), 20.0 * 1.1, 0.001)
	assert_almost_eq(Formulas.heal_cooldown(healer), 0.9 / 1.12, 0.001)
	assert_almost_eq(Formulas.heal_range(healer), 230.0 * 1.04, 0.001)
	assert_eq(Formulas.heal_amount(_building(GameConfig.ZAPPER)), 0.0)


func test_bulwark_is_cheap_and_disproportionately_tough() -> void:
	var bulwark := _building(GameConfig.BULWARK)
	var zapper := _building(GameConfig.ZAPPER)
	assert_eq(bulwark.max_hp(), 1600.0)
	assert_gt(bulwark.max_hp() / float(GameConfig.building(GameConfig.BULWARK).cost), 50.0 * zapper.max_hp() / float(GameConfig.building(GameConfig.ZAPPER).cost))
	bulwark.levels = {GameConfig.TRACK_HULL: 1}
	assert_almost_eq(bulwark.max_hp(), 1600.0 * 3.0, 0.001)
	bulwark.levels = {GameConfig.TRACK_HULL: 2}
	assert_almost_eq(bulwark.max_hp(), 1600.0 * (1.0 + 2.0 * (1.0 + 1.85)), 0.001)
	assert_eq(Formulas.capacity(bulwark), 12.0)
	assert_eq(Formulas.build_radius(bulwark), 0.0)


func test_bulwark_upgrades_beat_new_blocks_and_grow_ever_more_efficient() -> void:
	var bulwark := _building(GameConfig.BULWARK)
	var fresh := bulwark.max_hp() / float(GameConfig.building(GameConfig.BULWARK).cost)
	var gains := PackedFloat64Array()
	var total := 0
	for level in Formulas.max_level(bulwark, GameConfig.TRACK_HULL):
		var before := bulwark.max_hp()
		var cost := Formulas.upgrade_cost(bulwark, GameConfig.TRACK_HULL)
		bulwark.set_level(GameConfig.TRACK_HULL, level + 1)
		gains.append((bulwark.max_hp() - before) / float(cost))
		total += cost
	assert_gt(gains[0], fresh * 1.5)
	for i in range(1, gains.size()):
		assert_gt(gains[i], gains[i - 1], "level %d" % (i + 1))
	assert_gt(bulwark.max_hp(), 1600.0 * 100.0)
	assert_gt(total, 100 * int(GameConfig.building(GameConfig.BULWARK).cost))


func test_boosts_scale_the_whole_bulwark_curve() -> void:
	var bulwark := _building(GameConfig.BULWARK)
	bulwark.boosts = {GameConfig.BOOST_HP: 1.25}
	bulwark.set_level(GameConfig.TRACK_HULL, 3)
	assert_almost_eq(bulwark.max_hp(), 1600.0 * 1.25 * Formulas.multiplier(bulwark, GameConfig.TRACK_HULL), 0.01)


func test_track_config_prefers_kind_curves() -> void:
	assert_eq(Formulas.track_config(_building(GameConfig.BULWARK), GameConfig.TRACK_HULL), GameConfig.WALL_HULL)
	assert_eq(Formulas.track_config(_building(GameConfig.ZAPPER), GameConfig.TRACK_HULL), GameConfig.TRACKS[GameConfig.TRACK_HULL])
	var zapper := _building(GameConfig.ZAPPER)
	zapper.set_level(GameConfig.TRACK_HULL, 2)
	assert_almost_eq(Formulas.multiplier(zapper, GameConfig.TRACK_HULL), 1.0 + 2.0 * float(GameConfig.TRACKS[GameConfig.TRACK_HULL].step), 0.0001)
	assert_eq(Formulas.multiplier(_building(GameConfig.BULWARK), GameConfig.TRACK_HULL), 1.0)


func test_repair_values() -> void:
	var bulwark := _building(GameConfig.BULWARK)
	assert_eq(Formulas.repair_rate(bulwark), 5.0)
	assert_almost_eq(Formulas.repair_draw(bulwark), 0.4, 0.0001)
	assert_almost_eq(Formulas.repair_cost(bulwark), 0.08, 0.0001)
	var healer := _building(GameConfig.HEALER)
	assert_lt(Formulas.repair_rate(bulwark), Formulas.heal_amount(healer) / Formulas.heal_cooldown(healer))
	assert_lt(Formulas.repair_draw(bulwark), Formulas.heal_energy(healer) / Formulas.heal_cooldown(healer))
	var zapper := _building(GameConfig.ZAPPER)
	assert_eq(Formulas.repair_rate(zapper), 0.0)
	assert_eq(Formulas.repair_draw(zapper), 0.0)
	assert_eq(Formulas.repair_cost(zapper), 0.0)


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


func test_survival_stars_follow_targets() -> void:
	assert_eq(Formulas.survival_stars(0), 0)
	assert_eq(Formulas.survival_stars(4), 0)
	assert_eq(Formulas.survival_stars(GameConfig.SURVIVAL_TARGETS[0]), 1)
	assert_eq(Formulas.survival_stars(GameConfig.SURVIVAL_TARGETS[1]), 2)
	assert_eq(Formulas.survival_stars(GameConfig.SURVIVAL_TARGETS[2]), 3)
	assert_eq(Formulas.survival_stars(999), 3)


func test_boosts_scale_stats() -> void:
	var zapper := Building.new(1, GameConfig.ZAPPER, Vector2.ZERO)
	var base_damage := Formulas.damage(zapper)
	var base_hp := zapper.max_hp()
	var base_range := Formulas.attack_range(zapper)
	zapper.boosts = {GameConfig.BOOST_DAMAGE: 1.2, GameConfig.BOOST_HP: 1.5, GameConfig.BOOST_RANGE: 1.1}
	assert_almost_eq(Formulas.damage(zapper), base_damage * 1.2, 0.001)
	assert_almost_eq(zapper.max_hp(), base_hp * 1.5, 0.001)
	assert_almost_eq(Formulas.attack_range(zapper), base_range * 1.1, 0.001)
	var solar := Building.new(2, GameConfig.SOLAR, Vector2.ZERO)
	var output := Formulas.output(solar)
	solar.boosts = {GameConfig.BOOST_OUTPUT: 1.15, GameConfig.BOOST_CAPACITY: 2.0}
	assert_almost_eq(Formulas.output(solar), output * 1.15, 0.001)
	assert_almost_eq(Formulas.capacity(solar), float(GameConfig.building(GameConfig.SOLAR).capacity) * 2.0, 0.001)
	var exporter := Building.new(3, GameConfig.EXPORTER, Vector2.ZERO)
	var rate := Formulas.export_rate(exporter)
	exporter.boosts = {GameConfig.BOOST_EXPORT: 1.25}
	assert_almost_eq(Formulas.export_rate(exporter), rate * 1.25, 0.001)
	var tesla := Building.new(4, GameConfig.TESLA, Vector2.ZERO)
	tesla.boosts = {GameConfig.BOOST_CHAIN: 1.2}
	assert_eq(Formulas.chain_count(tesla), 6)
	var plasma := Building.new(5, GameConfig.PLASMA, Vector2.ZERO)
	var splash := Formulas.splash(plasma)
	plasma.boosts = {GameConfig.BOOST_SPLASH: 1.25}
	assert_almost_eq(Formulas.splash(plasma), splash * 1.25, 0.001)
	var healer := Building.new(6, GameConfig.HEALER, Vector2.ZERO)
	var amount := Formulas.heal_amount(healer)
	healer.boosts = {GameConfig.BOOST_HEAL: 1.25}
	assert_almost_eq(Formulas.heal_amount(healer), amount * 1.25, 0.001)
	assert_eq(Building.new(7, GameConfig.RELAY, Vector2.ZERO).boost(GameConfig.BOOST_DAMAGE), 1.0)
