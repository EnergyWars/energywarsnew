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


func test_levels_define_rounds_and_waves() -> void:
	for level: Dictionary in GameConfig.levels():
		assert_gt(float(level.day), 0.0, level.id)
		assert_gt(float(level.night), 0.0, level.id)
		assert_gt(Formulas.wave_times(level), 4, level.id)
		assert_gt(float(level.waves.base), 0.0, level.id)
		assert_false(level.has("prep"), level.id)
		var starters: Array = level.waves.roster.filter(func(entry: Array) -> bool: return int(entry[1]) == 0)
		assert_false(starters.is_empty(), level.id)
		var night_starters: Array = level.waves.night_roster.filter(func(entry: Array) -> bool: return int(entry[1]) == 0)
		assert_false(night_starters.is_empty(), level.id)
		assert_false(level.has("new"), level.id)


func test_every_track_allows_many_small_steps() -> void:
	for track: String in GameConfig.TRACKS:
		var config: Dictionary = GameConfig.TRACKS[track]
		assert_gte(int(config.max), 5, track)
		assert_gt(float(config.step), 0.0, track)
		assert_gt(float(config.price), 0.0, track)
	assert_lt(GameConfig.TRACK_GROWTH, 1.2)


func test_kind_curves_replace_existing_tracks_and_reward_each_level_more() -> void:
	for kind: String in GameConfig.BUILDINGS:
		var definition: Dictionary = GameConfig.BUILDINGS[kind]
		var curves: Dictionary = definition.get("curves", {})
		for track: String in curves:
			var curve: Dictionary = curves[track]
			assert_true(definition.tracks.has(track), "%s %s" % [kind, track])
			assert_gte(int(curve.max), 1, kind)
			assert_gt(float(curve.gain), 0.0, kind)
			assert_gt(float(curve.price), 0.0, kind)
			assert_gt(float(curve.growth), 1.0, kind)
			assert_gt(float(curve.gain_growth), float(curve.growth), kind)
	assert_true(GameConfig.building(GameConfig.BULWARK).has("curves"))


func test_spread_settings() -> void:
	assert_eq(GameConfig.SPREAD_CROWD, 3)
	assert_gt(GameConfig.SPREAD_CHANCE, 0.0)
	assert_lt(GameConfig.SPREAD_CHANCE, 1.0)
	assert_gte(GameConfig.SPREAD_OPTIONS, 1)
	assert_gt(GameConfig.SPREAD_REACH, 0.0)


func test_every_player_building_can_upgrade_its_health() -> void:
	for kind: String in GameConfig.BUILDINGS:
		if int(GameConfig.BUILDINGS[kind].team) == GameConfig.TEAM_PLAYER:
			assert_true(GameConfig.building(kind).tracks.has(GameConfig.TRACK_HULL), kind)


func test_every_tower_can_upgrade_its_armour() -> void:
	var armored: Array[String] = [GameConfig.ZAPPER, GameConfig.LASER, GameConfig.TESLA, GameConfig.PLASMA, GameConfig.HEALER, GameConfig.ROVER, GameConfig.BASTION]
	for kind: String in GameConfig.BUILDINGS:
		var tracks: Array = GameConfig.building(kind).get("tracks", [])
		assert_eq(tracks.has(GameConfig.TRACK_ARMOR), armored.has(kind), kind)
		if GameConfig.is_tower(kind):
			assert_true(armored.has(kind), kind)
	for kind in armored:
		assert_gt(float(GameConfig.building(kind).armor), 0.0, kind)
	var config: Dictionary = GameConfig.TRACKS[GameConfig.TRACK_ARMOR]
	assert_gt(int(config.max), 0)
	assert_gt(float(config.step), 0.0)
	assert_gt(float(config.price), 0.0)


func test_planning_keeps_a_wide_berth_from_enemy_bases() -> void:
	assert_gt(GameConfig.ENEMY_PLAN_CLEAR, GameConfig.ENEMY_NO_BUILD * 3.0)


func test_level_ids_are_unique() -> void:
	var ids := {}
	for level: Dictionary in GameConfig.levels():
		assert_false(ids.has(level.id), level.id)
		ids[level.id] = true


func test_every_spawner_has_day_and_night_units() -> void:
	for index in GameConfig.level_count():
		var level := GameConfig.level(index)
		for key in ["roster", "night_roster"]:
			var roster := []
			for entry: Array in level.waves[key]:
				assert_true(GameConfig.enemy_kinds().has(entry[0]), entry[0])
				assert_eq(GameConfig.is_nocturnal(entry[0]), key == "night_roster", "%s %s" % [level.id, entry[0]])
				roster.append(entry[0])
			for entry: Array in level.structures:
				if GameConfig.SPAWNER_FACTIONS.has(entry[0]):
					var faction: Array = GameConfig.SPAWNER_FACTIONS[entry[0]]
					assert_true(faction.any(func(kind: String) -> bool: return roster.has(kind)), "%s %s %s" % [level.id, key, entry[0]])


func test_night_monsters_are_stronger_than_day_monsters() -> void:
	var day_best := 0.0
	var night_weakest := INF
	for kind: String in GameConfig.enemy_kinds():
		var hp := float(GameConfig.enemy(kind).hp)
		if GameConfig.is_nocturnal(kind):
			night_weakest = minf(night_weakest, hp)
		elif not bool(GameConfig.enemy(kind).get("boss", false)) and kind != "beetle":
			day_best = maxf(day_best, hp)
	assert_gt(night_weakest, day_best)
	assert_true(GameConfig.is_nocturnal("stalker"))
	assert_false(GameConfig.is_nocturnal("crawler"))
	assert_false(GameConfig.is_nocturnal("unknown"))
	assert_lt(GameConfig.BURN_MIN, GameConfig.BURN_MAX)


func test_world_map_is_connected_and_inside() -> void:
	var seen := {0: true}
	var queue: Array[int] = [0]
	while not queue.is_empty():
		for neighbor in Campaign.neighbors(queue.pop_front()):
			if not seen.has(neighbor):
				seen[neighbor] = true
				queue.append(neighbor)
	assert_eq(seen.size(), GameConfig.level_count())
	for route in GameConfig.WORLD_ROUTES:
		assert_true(Campaign.is_valid(route.x) and Campaign.is_valid(route.y), str(route))
	for index in GameConfig.level_count():
		var point: Vector2 = GameConfig.level(index).world
		assert_true(Rect2(0, 0, 1, 1).has_point(point), str(index))


func test_levels_define_valid_challenges() -> void:
	for index in GameConfig.level_count():
		var challenges := Challenges.of_level(index)
		assert_eq(challenges[0].id, Challenges.CONQUER)
		assert_true(Challenges.ids(index).has(Challenges.SURVIVE), str(index))
		var ids := {}
		for challenge in challenges:
			assert_true(Challenges.TYPES.has(challenge.id), challenge.id)
			assert_false(ids.has(challenge.id))
			ids[challenge.id] = true


func test_techs_are_consistent() -> void:
	for id: String in GameConfig.TECHS:
		var tech := GameConfig.tech(id)
		assert_true(GameConfig.BRANCHES.has(tech.branch), id)
		assert_gt(int(tech.cost), 0, id)
		for required: String in tech.requires:
			assert_true(GameConfig.TECHS.has(required), "%s %s" % [id, required])
			assert_eq(GameConfig.tech(required).branch, tech.branch, id)
		if tech.has("unlock"):
			assert_true(GameConfig.BUILD_ORDER.has(tech.unlock), id)
			assert_false(GameConfig.STARTER_KINDS.has(tech.unlock), id)
		if tech.has("boost"):
			assert_false(Arsenal.targets(str(tech.kind)).is_empty(), id)
	var unlocked := GameConfig.STARTER_KINDS.duplicate()
	for id: String in GameConfig.TECHS:
		if GameConfig.tech(id).has("unlock"):
			unlocked.append(GameConfig.tech(id).unlock)
	for kind in GameConfig.BUILD_ORDER:
		assert_true(unlocked.has(kind), kind)
	assert_gt(TechTree.total_cost(TechTree.ids()), Challenges.max_points())
	assert_eq(GameConfig.tech("missing"), {})
	assert_eq(GameConfig.level_index("dawn"), 0)
	assert_eq(GameConfig.level_index("nowhere"), -1)


func test_level_lookup_clamps() -> void:
	assert_eq(GameConfig.level(-3).id, GameConfig.levels()[0].id)
	assert_eq(GameConfig.level(99).id, GameConfig.levels()[GameConfig.level_count() - 1].id)


func test_bastion_is_an_anti_air_lure_tower() -> void:
	assert_true(GameConfig.is_tower(GameConfig.BASTION))
	assert_true(GameConfig.building(GameConfig.BASTION).has("lure"))
	assert_true(GameConfig.building(GameConfig.BASTION).attack.air)
	assert_false(GameConfig.building(GameConfig.BASTION).attack.ground)
	assert_false(GameConfig.STARTER_KINDS.has(GameConfig.BASTION))
	assert_eq(GameConfig.tech("bastion").unlock, GameConfig.BASTION)


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
	assert_true(GameConfig.is_mobile(GameConfig.ROVER))
	assert_true(GameConfig.is_tower(GameConfig.ROVER))
	assert_false(GameConfig.is_mobile(GameConfig.ZAPPER))


func test_solar_rate_follows_output() -> void:
	assert_false(GameConfig.building(GameConfig.SOLAR).tracks.has(GameConfig.TRACK_RATE))
	assert_true(GameConfig.building(GameConfig.SOLAR).tracks.has(GameConfig.TRACK_OUTPUT))


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
	for kind: String in GameConfig.enemy_kinds():
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


func test_levels_mix_ponds_groves_forests_and_rocks() -> void:
	for level: Dictionary in GameConfig.levels():
		var terrain: Dictionary = level.terrain
		assert_gt(int(terrain.get("ponds", 0)), 0, level.id)
		assert_gt(int(terrain.get("groves", 0)), 0, level.id)
		assert_lt(int(terrain.groves), int(terrain.forests), level.id)
		assert_gte(int(terrain.forests), 11, level.id)
		assert_gte(int(terrain.rocks), 12, level.id)


func test_structure_placement_settings_are_sane() -> void:
	assert_gt(GameConfig.STRUCTURE_FAR_SHARE, 0.0)
	assert_lt(GameConfig.STRUCTURE_FAR_SHARE, 1.0)
	assert_gt(GameConfig.STRUCTURE_SPACING, 0.0)
	assert_gte(GameConfig.STRUCTURE_MARGIN, 1)
	assert_lt(GameConfig.TURRET_POST_RING.x, GameConfig.TURRET_POST_RING.y)


func test_creep_settings_are_sane() -> void:
	assert_gt(GameConfig.CREEP_RADIUS, 0.0)
	assert_gt(GameConfig.CREEP_CORE_CLEAR, GameConfig.CREEP_RADIUS)
	assert_gt(GameConfig.CREEP_FRINGE, 0.0)
	assert_lt(GameConfig.CREEP_FRINGE, GameConfig.CREEP_RADIUS)
	assert_gte(GameConfig.CREEP_STRIDE, 1)


func test_water_wheel_lamp_and_fire_pit_definitions() -> void:
	var water := GameConfig.building(GameConfig.WATER)
	var solar := GameConfig.building(GameConfig.SOLAR)
	assert_lt(float(water.output), float(solar.output))
	assert_false(water.get("solar", false))
	assert_false(bool(water.receives))
	assert_false(GameConfig.STARTER_KINDS.has(GameConfig.WATER))
	assert_eq(GameConfig.tech("water").unlock, GameConfig.WATER)
	var wheel := Building.new(1, GameConfig.WATER, Vector2.ZERO)
	assert_eq(Formulas.forecast_output(wheel, true), Formulas.forecast_output(wheel, false))
	assert_gt(Formulas.forecast_output(wheel, true), 0.0)
	assert_true(GameConfig.STARTER_KINDS.has(GameConfig.LAMP))
	assert_true(GameConfig.is_lamp(GameConfig.LAMP))
	assert_false(GameConfig.is_lamp(GameConfig.RELAY))
	assert_eq(int(GameConfig.building(GameConfig.LAMP).links), 0)
	assert_lt(GameConfig.LAMP_RADIUS_MIN, GameConfig.LAMP_RADIUS)
	assert_lt(GameConfig.LAMP_RADIUS, GameConfig.LAMP_RADIUS_MAX)
	assert_gt(GameConfig.LAMP_EXPONENT, 2.0)
	assert_almost_eq(GameConfig.CORE_LIGHT, 3.0, 0.001)
	assert_true(GameConfig.is_burner(GameConfig.FIRE))
	assert_gt(GameConfig.FIRE_BURN_TIME, 0.0)
	assert_lt(GameConfig.CLEAR_REACH * GameConfig.CELL, GameConfig.CELL * 3.0)
	assert_gt(GameConfig.CLEAR_REACH * GameConfig.CELL, Vector2(2, 2).length() * GameConfig.CELL)
