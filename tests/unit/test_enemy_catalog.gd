extends GutTest

const STATS: Array[String] = ["hp", "damage", "speed", "armor"]
const REQUIRED: Array[String] = ["class", "faction", "look", "armor", "hp", "speed", "damage", "cooldown", "reach", "radius", "bounty", "buffs"]


func after_all() -> void:
	TranslationServer.set_locale("en")


func _count(unit_class: String, boss: bool) -> int:
	var total := 0
	for kind: String in GameConfig.ENEMIES:
		var definition := GameConfig.enemy(kind)
		if definition.class == unit_class and bool(definition.get("boss", false)) == boss:
			total += 1
	return total


func test_catalog_has_the_specified_number_of_monsters() -> void:
	assert_eq(_count(GameConfig.CLASS_AIR, false), 5)
	assert_eq(_count(GameConfig.CLASS_MELEE, false), 10)
	assert_eq(_count(GameConfig.CLASS_RANGED, false), 5)
	var bosses := 0
	for kind: String in GameConfig.ENEMIES:
		bosses += 1 if bool(GameConfig.enemy(kind).get("boss", false)) else 0
	assert_eq(bosses, 10)
	assert_eq(GameConfig.ENEMIES.size(), 30)


func test_bosses_cover_every_class() -> void:
	for unit_class in GameConfig.CLASSES:
		assert_gt(_count(unit_class, true), 0, unit_class)
	assert_true(GameConfig.enemy("behemoth").boss)
	assert_true(GameConfig.enemy("tank").boss)


func test_every_enemy_has_all_required_fields() -> void:
	for kind: String in GameConfig.ENEMIES:
		var definition := GameConfig.enemy(kind)
		for key in REQUIRED:
			assert_true(definition.has(key), "%s %s" % [kind, key])
		assert_true(GameConfig.CLASSES.has(definition.class), kind)
		assert_gt(float(definition.hp), 0.0, kind)
		assert_gt(float(definition.speed), 0.0, kind)
		assert_gt(float(definition.damage), 0.0, kind)
		assert_gt(float(definition.cooldown), 0.0, kind)
		assert_gt(float(definition.radius), 0.0, kind)
		assert_gt(int(definition.bounty), 0, kind)
		assert_gte(float(definition.armor), 0.0, kind)
		assert_gte(float(definition.reach), 0.0, kind)


func test_ranged_enemies_have_reach_and_melee_enemies_have_none() -> void:
	for kind: String in GameConfig.ENEMIES:
		var definition := GameConfig.enemy(kind)
		if definition.class == GameConfig.CLASS_RANGED:
			assert_gt(float(definition.reach), 0.0, kind)
		elif definition.class == GameConfig.CLASS_MELEE:
			assert_eq(float(definition.reach), 0.0, kind)


func test_every_enemy_has_a_known_faction_and_look() -> void:
	for kind: String in GameConfig.ENEMIES:
		var definition := GameConfig.enemy(kind)
		assert_true(GameConfig.SPAWNER_FACTIONS.has(definition.faction), kind)
		assert_true(GameConfig.SPAWNER_FACTIONS[definition.faction].has(kind), kind)
		assert_true(EnemyPainter.LOOKS.has(definition.look), kind)


func test_factions_list_each_enemy_exactly_once() -> void:
	var seen := {}
	for spawner: String in GameConfig.SPAWNER_FACTIONS:
		for kind: String in GameConfig.SPAWNER_FACTIONS[spawner]:
			assert_false(seen.has(kind), kind)
			seen[kind] = true
			assert_true(GameConfig.ENEMIES.has(kind), kind)
			assert_eq(GameConfig.enemy(kind).faction, spawner, kind)
	assert_eq(seen.size(), GameConfig.ENEMIES.size())


func test_factions_are_balanced_by_class() -> void:
	for spawner: String in GameConfig.SPAWNER_FACTIONS:
		var classes := {}
		var bosses := 0
		for kind: String in GameConfig.SPAWNER_FACTIONS[spawner]:
			classes[GameConfig.enemy(kind).class] = true
			bosses += 1 if bool(GameConfig.enemy(kind).get("boss", false)) else 0
		assert_eq(classes.size(), GameConfig.CLASSES.size(), spawner)
		assert_gte(bosses, 3, spawner)


func test_every_faction_has_a_day_and_a_night_fallback() -> void:
	for spawner: String in GameConfig.SPAWNER_FACTIONS:
		var kinds: Array = GameConfig.SPAWNER_FACTIONS[spawner]
		assert_true(kinds.any(func(kind: String) -> bool: return GameConfig.is_nocturnal(kind)), spawner)
		assert_true(kinds.any(func(kind: String) -> bool: return not GameConfig.is_nocturnal(kind)), spawner)


func test_every_enemy_has_complete_buffs() -> void:
	for kind: String in GameConfig.ENEMIES:
		var buffs: Dictionary = GameConfig.enemy(kind).buffs
		for phase in ["night", "level"]:
			assert_true(buffs.has(phase), "%s %s" % [kind, phase])
			for stat in STATS:
				assert_true(buffs[phase].has(stat), "%s %s %s" % [kind, phase, stat])
				assert_gte(float(buffs[phase][stat]), 0.0, kind)


func test_bosses_are_larger_and_tougher_than_regular_monsters() -> void:
	var strongest_regular := 0.0
	for kind: String in GameConfig.ENEMIES:
		var definition := GameConfig.enemy(kind)
		if not bool(definition.get("boss", false)):
			strongest_regular = maxf(strongest_regular, float(definition.hp))
	for kind: String in GameConfig.ENEMIES:
		var definition := GameConfig.enemy(kind)
		if bool(definition.get("boss", false)):
			assert_gt(float(definition.hp), strongest_regular, kind)
			assert_gte(float(definition.radius), 20.0, kind)
			assert_gt(float(definition.armor), 10.0, kind)


func test_every_enemy_has_name_and_description_in_both_languages() -> void:
	for locale in ["en", "de"]:
		TranslationServer.set_locale(locale)
		for kind: String in GameConfig.ENEMIES:
			var name_key := "ENEMY_%s" % kind.to_upper()
			assert_ne(Texts.enemy_name(kind), name_key, "%s %s" % [locale, kind])
			assert_ne(Texts.enemy_desc(kind), "%s_DESC" % name_key, "%s %s" % [locale, kind])
			assert_gt(Texts.enemy_desc(kind).length(), 20, "%s %s" % [locale, kind])


func test_names_are_unique_per_language() -> void:
	for locale in ["en", "de"]:
		TranslationServer.set_locale(locale)
		var names := {}
		for kind: String in GameConfig.ENEMIES:
			var text := Texts.enemy_name(kind)
			assert_false(names.has(text), "%s %s" % [locale, text])
			names[text] = true


func test_buff_without_modifiers_is_neutral() -> void:
	for stat in STATS:
		assert_eq(Formulas.enemy_buff("crawler", stat, false, 0), 1.0, stat)


func test_night_buff_applies_only_at_night() -> void:
	var night: float = GameConfig.enemy("mauler").buffs.night.hp
	assert_almost_eq(Formulas.enemy_buff("mauler", "hp", true, 0), 1.0 + night, 0.0001)
	assert_eq(Formulas.enemy_buff("mauler", "hp", false, 0), 1.0)


func test_level_buff_grows_per_level_index() -> void:
	var step: float = GameConfig.enemy("mauler").buffs.level.damage
	assert_almost_eq(Formulas.enemy_buff("mauler", "damage", false, 3), 1.0 + step * 3.0, 0.0001)
	assert_gt(Formulas.enemy_buff("mauler", "damage", false, 4), Formulas.enemy_buff("mauler", "damage", false, 3))


func test_night_and_level_buffs_multiply() -> void:
	var buffs: Dictionary = GameConfig.enemy("brute").buffs
	var expected := (1.0 + float(buffs.night.armor)) * (1.0 + float(buffs.level.armor) * 2.0)
	assert_almost_eq(Formulas.enemy_buff("brute", "armor", true, 2), expected, 0.0001)


func test_buff_edge_cases() -> void:
	assert_eq(Formulas.enemy_buff("unknown", "hp", true, 5), 1.0)
	assert_eq(Formulas.enemy_buff("crawler", "unknown", true, 5), 1.0)
	assert_eq(Formulas.enemy_buff("crawler", "hp", false, -3), 1.0)
	assert_eq(Formulas.enemy_buff("crawler", "armor", true, 9), 1.0)


func test_enemy_applies_buffs_to_all_stats() -> void:
	var definition := GameConfig.enemy("brute")
	var plain := Enemy.new(1, "brute", Vector2.ZERO)
	var buffed := Enemy.new(2, "brute", Vector2.ZERO, 1.0, 1.0, 1.0, true, 4)
	assert_almost_eq(plain.max_hp, float(definition.hp), 0.001)
	assert_almost_eq(buffed.max_hp, float(definition.hp) * Formulas.enemy_buff("brute", "hp", true, 4), 0.001)
	assert_almost_eq(buffed.damage(), float(definition.damage) * Formulas.enemy_buff("brute", "damage", true, 4), 0.001)
	assert_almost_eq(buffed.speed(), float(definition.speed) * Formulas.enemy_buff("brute", "speed", true, 4), 0.001)
	assert_almost_eq(buffed.armor(), float(definition.armor) * Formulas.enemy_buff("brute", "armor", true, 4), 0.001)
	assert_gt(buffed.armor(), plain.armor())
	assert_eq(plain.armor(), float(definition.armor))


func test_guard_speed_keeps_the_speed_buff() -> void:
	var guard := Enemy.new(1, "crawler", Vector2.ZERO, 1.0, 1.0, 1.0, true, 3)
	var speed := guard.speed()
	guard.make_guard(5, 0.0, 1.0)
	assert_almost_eq(guard.speed(), speed * GameConfig.GUARD_SPEED, 0.001)


func test_spawn_uses_night_and_level_for_new_kinds() -> void:
	var battle := BattleFixtures.battle(0)
	battle.state.level = battle.state.level.duplicate(true)
	battle.state.level.waves.night_roster = [["ravager", 0, 1.0]]
	battle.state.level.waves.roster = [["larva", 0, 1.0]]
	battle.state.level_index = 3
	battle.spawns.start_round()
	var nest: Building = battle.state.enemy_buildings().filter(func(b: Building) -> bool: return b.kind == GameConfig.NEST)[0]
	var day := battle.spawns.spawn(nest)
	assert_eq(day.kind, "larva")
	assert_almost_eq(day.max_hp, float(GameConfig.enemy("larva").hp) * Formulas.enemy_buff("larva", "hp", false, 3), 0.001)
	battle.state.round_time = float(battle.state.level.day) + 1.0
	var night := battle.spawns.spawn(nest)
	assert_eq(night.kind, "ravager")
	assert_almost_eq(night.max_hp, float(GameConfig.enemy("ravager").hp) * Formulas.enemy_buff("ravager", "hp", true, 3), 0.001)
	assert_gt(night.armor(), float(GameConfig.enemy("ravager").armor))


func test_new_kinds_are_picked_from_their_faction_only() -> void:
	var battle := BattleFixtures.battle(0)
	battle.state.level = battle.state.level.duplicate(true)
	battle.state.level.waves.roster = [["larva", 0, 1.0], ["sprinter", 0, 1.0], ["gnat", 0, 1.0]]
	battle.spawns.start_round()
	battle.state.round_number = 5
	var nest_kinds := battle.spawns.candidates(GameConfig.NEST).map(func(entry: Array) -> String: return entry[0])
	var camp_kinds := battle.spawns.candidates(GameConfig.CAMP).map(func(entry: Array) -> String: return entry[0])
	assert_eq(nest_kinds, ["larva", "gnat"])
	assert_eq(camp_kinds, ["sprinter"])
	for i in 20:
		assert_true(nest_kinds.has(battle.spawns.pick_kind(GameConfig.NEST)))
		assert_eq(battle.spawns.pick_kind(GameConfig.CAMP), "sprinter")


func test_fallback_kind_exists_for_every_faction_and_time() -> void:
	var battle := BattleFixtures.battle(0)
	battle.state.level = battle.state.level.duplicate(true)
	battle.state.level.waves.roster = []
	battle.state.level.waves.night_roster = []
	battle.spawns.start_round()
	for spawner: String in GameConfig.SPAWNER_FACTIONS:
		assert_eq(GameConfig.enemy(battle.spawns.fallback_kind(spawner)).faction, spawner)
		assert_false(GameConfig.is_nocturnal(battle.spawns.fallback_kind(spawner)))
	battle.state.round_time = float(battle.state.level.day) + 1.0
	for spawner: String in GameConfig.SPAWNER_FACTIONS:
		assert_true(GameConfig.is_nocturnal(battle.spawns.fallback_kind(spawner)))


func test_every_kind_can_be_instantiated_with_buffs() -> void:
	for kind: String in GameConfig.ENEMIES:
		var enemy := Enemy.new(1, kind, Vector2.ZERO, 1.0, 1.0, 1.0, true, 6)
		assert_gte(enemy.max_hp, float(GameConfig.enemy(kind).hp), kind)
		assert_gte(enemy.armor(), float(GameConfig.enemy(kind).armor), kind)
		assert_eq(enemy.unit_class(), GameConfig.enemy(kind).class, kind)


func test_painter_draws_every_kind_without_errors() -> void:
	var painted := [0]
	var layer := DrawLayer.new().setup(func(ci: CanvasItem) -> void:
		var x := 0.0
		for kind: String in GameConfig.ENEMIES:
			for night in [0.0, 1.0]:
				Painter.enemy(ci, kind, Vector2(x, 60), float(GameConfig.enemy(kind).radius), Vector2.RIGHT.rotated(x), x * 0.1, night)
				painted[0] += 1
			x += 70.0)
	add_child_autofree(layer)
	layer.queue_redraw()
	await wait_physics_frames(2)
	assert_eq(painted[0], GameConfig.ENEMIES.size() * 2)


func test_painter_falls_back_for_unknown_looks() -> void:
	assert_eq(EnemyPainter.look_of("does_not_exist"), EnemyPainter.LOOKS[EnemyPainter.FALLBACK_LOOK])
	var painted := [false]
	var layer := DrawLayer.new().setup(func(ci: CanvasItem) -> void:
		Painter.enemy(ci, "does_not_exist", Vector2(40, 40), 10.0, Vector2.DOWN, 0.0, 0.0)
		painted[0] = true)
	add_child_autofree(layer)
	layer.queue_redraw()
	await wait_physics_frames(2)
	assert_true(painted[0])


func test_looks_are_visually_distinct() -> void:
	var signatures := {}
	for kind: String in GameConfig.ENEMIES:
		var look := EnemyPainter.look_of(kind)
		var signature := var_to_str(look)
		assert_false(signatures.has(signature), "%s = %s" % [kind, signatures.get(signature, "")])
		signatures[signature] = kind


func test_air_raids_never_contain_bosses() -> void:
	var battle := BattleFixtures.battle(0)
	for night in [false, true]:
		for kind: String in battle.spawns.raid_kinds(night):
			assert_false(bool(GameConfig.enemy(kind).get("boss", false)), kind)


func test_every_enemy_name_key_is_translated() -> void:
	for locale in ["en", "de"]:
		TranslationServer.set_locale(locale)
		for kind: String in GameConfig.ENEMIES:
			var key := "ENEMY_%s" % kind.to_upper()
			assert_ne(Texts.t(key), key, "%s %s" % [locale, kind])


func test_override_kinds_without_texts_get_readable_fallbacks() -> void:
	assert_eq(Texts.enemy_name("night_ghost"), "Night Ghost")
	assert_eq(Texts.enemy_desc("night_ghost"), "")
