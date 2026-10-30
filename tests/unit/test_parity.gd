extends GutTest

const WAVES := {"interval": 9.0, "base": 1.3, "ramp": 1.5, "night": 1.2, "growth": 0.4, "roster": [["crawler", 0, 1.0]], "night_roster": [["stalker", 0, 1.0]]}


func after_each() -> void:
	ContentOverrides.reset()


func test_armor_reference_values_match_armor_js() -> void:
	assert_almost_eq(Formulas.armor_reduction(100.0), 0.5, 1e-9)
	assert_almost_eq(Formulas.armor_reduction(300.0), 0.75, 1e-9)
	assert_almost_eq(Formulas.armor_reduction(1.0e6), 0.9, 1e-9)
	assert_almost_eq(Formulas.mitigate(40.0, 100.0), 20.0, 1e-9)
	assert_almost_eq(Formulas.mitigate(1.0, 60.0), 1.0, 1e-9)
	assert_almost_eq(Formulas.mitigate(1.0, 60.0, 1.0 / 30.0), 0.625, 1e-9)
	assert_almost_eq(Formulas.mitigate(0.5, 1.0e6), 0.5, 1e-9)
	assert_almost_eq(Formulas.mitigate(0.01, 1.0e6, 1.0 / 30.0), 0.01, 1e-9)
	assert_almost_eq(Formulas.mitigate(3.0, 0.0), 3.0, 1e-9)


func test_wave_reference_values_match_waves_js() -> void:
	assert_almost_eq(Formulas.wave_count(WAVES, 3, 0.5, true), 4.914, 1e-9)
	assert_eq(Formulas.wave_times({"day": 80.0, "night": 60.0, "waves": WAVES}), 16)
	assert_eq(Formulas.wave_time({"waves": WAVES}, 5), 48.0)
	var extras := {"day": 40.0, "night": 30.0, "waves": WAVES, "extra_waves": [{"day": 2, "night": false, "kind": "wasp", "count": 2}, {"day": 3, "night": true, "kind": "stalker", "count": 1}]}
	assert_eq(Formulas.extra_waves(extras, 2, 0).map(func(entry: Dictionary) -> String: return entry.kind), ["wasp"])
	assert_eq(Formulas.extra_waves(extras, 2, 1), [])
	assert_eq(Formulas.extra_waves(extras, 3, 5).map(func(entry: Dictionary) -> String: return entry.kind), ["stalker"])
	assert_eq(Formulas.extra_waves(extras, 3, 6), [])


func test_spawner_wave_units_match_round_waves_js() -> void:
	var battle := BattleFixtures.battle(0)
	battle.spawns.start_round()
	battle.state.round_number = 2
	battle.state.level = {"id": "parity", "day": 20.0, "night": 10.0, "waves": WAVES}
	var spawner: Building = battle.state.enemy_buildings().filter(func(b: Building) -> bool: return b.spawner)[0]
	var units: Array[int] = []
	var nights: Array[bool] = []
	for index in Formulas.wave_times(battle.state.level):
		battle.state.round_time = Formulas.wave_time(battle.state.level, index)
		spawner.spawn_queue = 0
		battle.spawns.send_wave()
		units.append(spawner.spawn_queue)
		nights.append(battle.state.is_night())
	assert_eq(units, [2, 4, 6] as Array[int])
	assert_eq(nights, [false, false, true] as Array[bool])


func test_buff_reference_values_match_monsters_js() -> void:
	assert_almost_eq(Formulas.enemy_buff("colossus", "hp", true, 7), 2.125, 1e-9)
	assert_almost_eq(Formulas.enemy_buff("colossus", "armor", true, 7), 1.633, 1e-9)
	assert_almost_eq(Formulas.enemy_buff("colossus", "speed", false, 7), 1.0, 1e-9)
	assert_almost_eq(Formulas.enemy_buff("crawler", "hp", false, 0), 1.0, 1e-9)
	var custom: Dictionary = GameConfig.ENEMIES.crawler.duplicate(true)
	custom["buffs"] = {"night": {"hp": -0.999}}
	ContentOverrides.set_data({"enemies": {"crawler": custom}})
	assert_almost_eq(Formulas.enemy_buff("crawler", "hp", true, 0), 0.001, 1e-9)


func test_route_and_layout_reference_values_match_world_layout_js() -> void:
	assert_eq(Campaign.connect_all([Vector2i(0, 2)] as Array[Vector2i], 4), [Vector2i(0, 2), Vector2i(0, 1), Vector2i(2, 3)] as Array[Vector2i])
	assert_eq(Campaign.connect_all([Vector2i(1, 2)] as Array[Vector2i], 4), [Vector2i(1, 2), Vector2i(0, 1), Vector2i(2, 3)] as Array[Vector2i])
	assert_eq(Campaign.connect_all([Vector2i(0, 1), Vector2i(2, 3)] as Array[Vector2i], 4), [Vector2i(0, 1), Vector2i(2, 3), Vector2i(1, 2)] as Array[Vector2i])
	assert_eq(Campaign.connect_all([Vector2i(0, 9), Vector2i(1, 1)] as Array[Vector2i], 2), [Vector2i(0, 1)] as Array[Vector2i])
	var list := []
	for world: Variant in [[0.5, 0.9], null, null, null]:
		var level: Dictionary = GameConfig.LEVELS[0].duplicate(true)
		level["id"] = "p%d" % list.size()
		level["cells"] = [52, 64]
		level["world"] = world
		list.append(level)
	ContentOverrides.set_data({"levels": list})
	var expected: Array[Vector2] = [Vector2(0.5, 0.9), Vector2(0.72, 0.71), Vector2(0.28, 0.52), Vector2(0.72, 0.33)]
	for index in expected.size():
		assert_almost_eq(Campaign.position(index), expected[index], Vector2(1e-6, 1e-6))
