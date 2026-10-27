extends GutTest


func test_levels_have_valid_layout() -> void:
	for index in GameConfig.level_count():
		var level := GameConfig.level(index)
		var map := LevelMap.create(level)
		assert_true(map.contains(map.drop, GameConfig.CELL * 2.0), level.id)
		assert_false(level.structures.is_empty(), level.id)
		for structure in map.structures:
			assert_true(map.contains(structure.position, GameConfig.CELL), level.id)
			assert_true(GameConfig.BUILDINGS.has(structure.kind), level.id)


func test_level_ids_are_unique() -> void:
	var ids := {}
	for level: Dictionary in GameConfig.LEVELS:
		assert_false(ids.has(level.id), level.id)
		ids[level.id] = true


func test_every_spawner_has_units_in_roster() -> void:
	for index in GameConfig.level_count():
		var level := GameConfig.level(index)
		var roster := []
		for entry: Array in level.spawns.roster:
			assert_true(GameConfig.ENEMIES.has(entry[0]), entry[0])
			roster.append(entry[0])
		for entry: Array in level.structures:
			if GameConfig.SPAWNER_FACTIONS.has(entry[0]):
				var faction: Array = GameConfig.SPAWNER_FACTIONS[entry[0]]
				assert_true(faction.any(func(kind: String) -> bool: return roster.has(kind)), "%s %s" % [level.id, entry[0]])


func test_available_kinds_accumulate_in_build_order() -> void:
	assert_eq(GameConfig.available_kinds(0), [GameConfig.BULWARK, GameConfig.SOLAR, GameConfig.RELAY, GameConfig.BATTERY, GameConfig.EXPORTER, GameConfig.ZAPPER] as Array[String])
	assert_true(GameConfig.available_kinds(1).has(GameConfig.LASER))
	assert_true(GameConfig.available_kinds(1).has(GameConfig.HEALER))
	assert_false(GameConfig.available_kinds(1).has(GameConfig.SHIELD))
	assert_true(GameConfig.available_kinds(2).has(GameConfig.SHIELD))
	assert_eq(GameConfig.available_kinds(GameConfig.level_count() - 1), GameConfig.BUILD_ORDER)
	assert_eq(GameConfig.available_kinds(99), GameConfig.BUILD_ORDER)


func test_level_lookup_clamps() -> void:
	assert_eq(GameConfig.level(-3).id, GameConfig.LEVELS[0].id)
	assert_eq(GameConfig.level(99).id, GameConfig.LEVELS[GameConfig.level_count() - 1].id)


func test_tower_detection() -> void:
	assert_true(GameConfig.is_tower(GameConfig.ZAPPER))
	assert_true(GameConfig.is_tower(GameConfig.PLASMA))
	assert_false(GameConfig.is_tower(GameConfig.TURRET))
	assert_false(GameConfig.is_tower(GameConfig.SOLAR))
	assert_false(GameConfig.is_tower("unknown"))
	assert_false(GameConfig.is_tower(GameConfig.CORE))
	assert_true(GameConfig.has_attack(GameConfig.CORE))
	assert_true(GameConfig.has_attack(GameConfig.LASER))
	assert_false(GameConfig.has_attack(GameConfig.TURRET))
	assert_false(GameConfig.has_attack(GameConfig.EXPORTER))
	assert_true(GameConfig.uses_energy_actively(GameConfig.HEALER))
	assert_false(GameConfig.uses_energy_actively(GameConfig.BULWARK))
	assert_true(GameConfig.is_wall(GameConfig.BULWARK))
	assert_false(GameConfig.is_wall(GameConfig.ZAPPER))
	assert_eq(GameConfig.cells(GameConfig.CORE), 2)
	assert_eq(GameConfig.cells(GameConfig.ZAPPER), 1)
	assert_true(GameConfig.uses_energy_actively(GameConfig.SHIELD))
	assert_true(GameConfig.uses_energy_actively(GameConfig.CORE))
	assert_false(GameConfig.uses_energy_actively(GameConfig.BATTERY))


func test_player_buildings_define_tracks() -> void:
	for kind: String in GameConfig.BUILDINGS:
		var definition: Dictionary = GameConfig.BUILDINGS[kind]
		if int(definition.team) != GameConfig.TEAM_PLAYER:
			continue
		assert_false(definition.tracks.is_empty(), kind)
		for track: String in definition.tracks:
			assert_true(GameConfig.TRACKS.has(track), track)


func test_every_enemy_has_a_class_and_each_class_exists() -> void:
	var seen := {}
	for kind: String in GameConfig.ENEMIES:
		var unit_class := str(GameConfig.enemy(kind).get("class", ""))
		assert_true(GameConfig.CLASSES.has(unit_class), kind)
		seen[unit_class] = true
	assert_eq(seen.size(), GameConfig.CLASSES.size())


func test_every_faction_has_melee_ranged_and_air() -> void:
	for spawner: String in GameConfig.SPAWNER_FACTIONS:
		var classes := {}
		for kind: String in GameConfig.SPAWNER_FACTIONS[spawner]:
			classes[GameConfig.enemy(kind).class] = true
		assert_eq(classes.size(), GameConfig.CLASSES.size(), spawner)


func test_buildings_fit_their_cells() -> void:
	for kind: String in GameConfig.BUILDINGS:
		assert_lte(float(GameConfig.building(kind).radius), GameConfig.cells(kind) * GameConfig.CELL * 0.5, kind)
