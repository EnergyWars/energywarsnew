extends GutTest


func _spawner_factions(level: Dictionary) -> Array:
	var kinds := []
	for entry: Array in level.structures:
		if GameConfig.SPAWNER_FACTIONS.has(entry[0]):
			for kind: String in GameConfig.SPAWNER_FACTIONS[entry[0]]:
				if not kinds.has(kind):
					kinds.append(kind)
	return kinds


func _rosters(level: Dictionary) -> Array:
	return [["roster", level.waves.roster], ["night_roster", level.waves.night_roster]]


func test_rosters_contain_only_known_kinds_with_valid_numbers() -> void:
	for level: Dictionary in GameConfig.levels():
		for pair: Array in _rosters(level):
			var seen := {}
			for entry: Array in pair[1]:
				var label := "%s %s %s" % [level.id, pair[0], entry[0]]
				assert_true(GameConfig.enemy_kinds().has(entry[0]), label)
				assert_false(seen.has(entry[0]), label)
				seen[entry[0]] = true
				assert_gte(int(entry[1]), 0, label)
				assert_gt(float(entry[2]), 0.0, label)


func test_rosters_only_use_kinds_of_the_level_spawners() -> void:
	for level: Dictionary in GameConfig.levels():
		var allowed := _spawner_factions(level)
		for pair: Array in _rosters(level):
			for entry: Array in pair[1]:
				assert_true(allowed.has(entry[0]), "%s %s %s" % [level.id, pair[0], entry[0]])


func test_rosters_exclude_air_units_which_come_as_raids() -> void:
	for level: Dictionary in GameConfig.levels():
		for pair: Array in _rosters(level):
			for entry: Array in pair[1]:
				assert_ne(GameConfig.enemy(entry[0]).get("class", ""), GameConfig.CLASS_AIR, "%s %s" % [level.id, entry[0]])


func test_day_and_night_rosters_match_nocturnal_flag() -> void:
	for level: Dictionary in GameConfig.levels():
		for entry: Array in level.waves.roster:
			assert_false(GameConfig.is_nocturnal(entry[0]), "%s %s" % [level.id, entry[0]])
		for entry: Array in level.waves.night_roster:
			assert_true(GameConfig.is_nocturnal(entry[0]), "%s %s" % [level.id, entry[0]])


func test_every_spawner_faction_has_starters_day_and_night() -> void:
	for level: Dictionary in GameConfig.levels():
		for entry: Array in level.structures:
			if not GameConfig.SPAWNER_FACTIONS.has(entry[0]):
				continue
			var faction: Array = GameConfig.SPAWNER_FACTIONS[entry[0]]
			for pair: Array in _rosters(level):
				var starters: Array = pair[1].filter(func(row: Array) -> bool: return faction.has(row[0]) and int(row[1]) == 0)
				assert_false(starters.is_empty(), "%s %s %s" % [level.id, pair[0], entry[0]])


func test_bosses_are_rare_and_appear_late() -> void:
	for level: Dictionary in GameConfig.levels():
		for pair: Array in _rosters(level):
			for entry: Array in pair[1]:
				if bool(GameConfig.enemy(entry[0]).get("boss", false)):
					assert_gte(int(entry[1]), 3, "%s %s" % [level.id, entry[0]])
					assert_lte(float(entry[2]), 0.15, "%s %s" % [level.id, entry[0]])


func test_tier_rises_with_enemy_strength() -> void:
	for level: Dictionary in GameConfig.levels():
		for pair: Array in _rosters(level):
			for entry: Array in pair[1]:
				var definition := GameConfig.enemy(entry[0])
				if float(definition.hp) >= 400.0 and not bool(definition.get("boss", false)):
					assert_gte(int(entry[1]), 2, "%s %s" % [level.id, entry[0]])


func test_later_levels_offer_at_least_as_many_kinds() -> void:
	var first := GameConfig.level(0)
	var last := GameConfig.level(GameConfig.level_count() - 1)
	var early: int = first.waves.roster.size() + first.waves.night_roster.size()
	var late: int = last.waves.roster.size() + last.waves.night_roster.size()
	assert_gt(late, early)


func test_every_non_air_kind_is_used_by_some_level() -> void:
	var used := {}
	for level: Dictionary in GameConfig.levels():
		for pair: Array in _rosters(level):
			for entry: Array in pair[1]:
				used[entry[0]] = true
	for kind: String in GameConfig.ENEMIES:
		if GameConfig.ENEMIES[kind].class != GameConfig.CLASS_AIR:
			assert_true(used.has(kind), kind)
