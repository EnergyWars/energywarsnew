extends GutTest

var battle: Battle


func before_each() -> void:
	battle = BattleFixtures.battle(0)
	battle.state.level = battle.state.level.duplicate(true)


func after_each() -> void:
	ContentOverrides.reset()


func _extras(list: Array) -> void:
	battle.state.level["extra_waves"] = list


func _count(kind: String) -> int:
	var total := 0
	for enemy in battle.state.enemies:
		if enemy.kind == kind:
			total += 1
	return total


func _first_night_index() -> int:
	var level := battle.state.level
	for index in Formulas.wave_times(level):
		if DayCycle.is_night(Formulas.wave_time(level, index), level):
			return index
	return -1


func test_no_extras_without_the_field() -> void:
	assert_eq(Formulas.extra_waves(battle.state.level, 1, 0), [])
	assert_eq(battle.spawns.send_extras(0), 0)


func test_extras_fire_in_the_first_wave_of_a_day() -> void:
	_extras([{"day": 2, "night": false, "kind": "wasp", "count": 3}])
	assert_eq(Formulas.extra_waves(battle.state.level, 2, 0).size(), 1)
	assert_eq(Formulas.extra_waves(battle.state.level, 2, 1).size(), 0)
	assert_eq(Formulas.extra_waves(battle.state.level, 1, 0).size(), 0)
	assert_eq(Formulas.extra_waves(battle.state.level, 2, _first_night_index()).size(), 0)


func test_extras_fire_in_the_first_wave_of_a_night() -> void:
	_extras([{"day": 3, "night": true, "kind": "nightwing", "count": 2}])
	var index := _first_night_index()
	assert_gt(index, 0)
	assert_eq(Formulas.extra_waves(battle.state.level, 3, index).size(), 1)
	assert_eq(Formulas.extra_waves(battle.state.level, 3, index + 1).size(), 0)
	assert_eq(Formulas.extra_waves(battle.state.level, 3, 0).size(), 0)


func test_send_wave_spawns_the_extra_monsters() -> void:
	battle.state.round_number = 2
	_extras([{"day": 2, "night": false, "kind": "wasp", "count": 4}])
	battle.spawns.start_round()
	battle.state.round_time = 0.0
	var before := _count("wasp")
	var total := battle.spawns.send_wave()
	assert_eq(_count("wasp") - before, 4)
	assert_gte(total, 4)
	assert_eq(battle.state.waves_sent, 1)


func test_other_days_are_unaffected() -> void:
	battle.state.round_number = 1
	_extras([{"day": 2, "night": false, "kind": "wasp", "count": 4}])
	battle.spawns.start_round()
	battle.spawns.send_wave()
	assert_eq(_count("wasp"), 0)


func test_extras_prefer_matching_faction_and_fall_back_to_any_spawner() -> void:
	assert_gt(battle.spawns.extra_spawners("crawler").size(), 0)
	for spawner in battle.spawns.extra_spawners("crawler"):
		assert_true(GameConfig.SPAWNER_FACTIONS.get(spawner.kind, []).has("crawler"))
	assert_gt(battle.spawns.extra_spawners("unknown_kind").size(), 0)


func test_unknown_kind_spawns_nothing() -> void:
	battle.spawns.start_round()
	assert_eq(battle.spawns.spawn_extra("ghost", 3), 0)
	assert_eq(battle.state.enemies.size(), 0)


func test_forced_kind_overrides_the_roster() -> void:
	battle.spawns.start_round()
	var enemy := battle.spawns.spawn(battle.state.enemy_buildings()[0], INF, "behemoth")
	assert_eq(enemy.kind, "behemoth")


func test_overrides_normalise_extra_waves() -> void:
	var level: Dictionary = GameConfig.LEVELS[0].duplicate(true)
	level["cells"] = [52, 64]
	level["extra_waves"] = [
		{"day": 2, "night": true, "kind": "wasp", "count": 3},
		{"day": 0.0, "night": false, "kind": "wasp", "count": 999},
		{"day": 1, "night": "x", "kind": "wasp", "count": 1},
		"junk",
	]
	ContentOverrides.set_data({"levels": [level]})
	var stored: Array = ContentOverrides.levels()[0].extra_waves
	assert_eq(stored.size(), 2)
	assert_eq(stored[0], {"day": 2, "night": true, "kind": "wasp", "count": 3})
	assert_eq(stored[1].day, 1)
	assert_eq(stored[1].count, ContentOverrides.MAX_EXTRA_COUNT)
	level.erase("extra_waves")
	ContentOverrides.set_data({"levels": [level]})
	assert_false(ContentOverrides.levels()[0].has("extra_waves"))
