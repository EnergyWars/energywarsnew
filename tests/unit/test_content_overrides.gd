extends GutTest


func _level(id: String, world: Variant = null) -> Dictionary:
	return {"id": id, "cells": [20, 30], "money": 100, "day": 50.0, "night": 40.0, "seed": 3,
		"drop": [0.5, 0.8], "structures": [["nest", [0.5, 0.1]]],
		"terrain": {"plateaus": 1, "chasms": 0, "ponds": 0, "groves": 0, "forests": 2, "rocks": 1, "spots": [[[0.3, 0.7], 5, [[1, 0]]]]},
		"waves": {"interval": 9.0, "base": 0.5, "ramp": 1.5, "night": 1.2, "growth": 0.4, "roster": [["crawler", 0, 1.0]], "night_roster": []},
		"world": world, "challenges": [["core", 60]]}


func _many(count: int) -> Array:
	var list := []
	for i in count:
		list.append(_level("lvl%d" % i, [0.5, 0.9] if i == 0 else null))
	return list


func after_each() -> void:
	ContentOverrides.reset()


func test_empty_and_broken_data_fall_back_to_defaults() -> void:
	for raw in [{}, null, "text", 5, [], {"armor": "x", "enemies": 3, "levels": "x", "routes": "x", "buildings": []}]:
		ContentOverrides.set_data(raw)
		assert_eq(ContentOverrides.armor(), GameConfig.ARMOR)
		assert_eq(ContentOverrides.levels(), [])
		assert_null(ContentOverrides.routes())
		assert_eq(GameConfig.level_count(), GameConfig.LEVELS.size())
		assert_eq(ContentOverrides.enemy("crawler"), {})


func test_missing_file_is_harmless() -> void:
	ContentOverrides.reset()
	assert_eq(GameConfig.level_count(), GameConfig.LEVELS.size())
	assert_eq(ContentOverrides.building_armor("nothing", 7.0), 7.0)


func test_partial_armor_override_keeps_other_defaults() -> void:
	ContentOverrides.set_data({"armor": {"constant": 50.0}})
	assert_eq(float(ContentOverrides.armor().constant), 50.0)
	assert_eq(float(ContentOverrides.armor().max_reduction), float(GameConfig.ARMOR.max_reduction))
	assert_almost_eq(Formulas.armor_reduction(50.0), 0.5, 0.0001)
	assert_almost_eq(Formulas.mitigate(40.0, 50.0), 20.0, 0.0001)


func test_armor_values_are_sanitized() -> void:
	ContentOverrides.set_data({"armor": {"constant": -4, "max_reduction": 7, "min_damage": -1}})
	assert_gt(float(ContentOverrides.armor().constant), 0.0)
	assert_eq(float(ContentOverrides.armor().max_reduction), 1.0)
	assert_eq(float(ContentOverrides.armor().min_damage), 0.0)


func test_enemy_override_replaces_the_dictionary() -> void:
	var custom: Dictionary = GameConfig.ENEMIES.crawler.duplicate()
	custom["hp"] = 12345.0
	ContentOverrides.set_data({"enemies": {"crawler": custom, "invented": custom, "bad": 5}})
	assert_eq(float(GameConfig.enemy("crawler").hp), 12345.0)
	assert_eq(float(GameConfig.enemy("invented").hp), 12345.0)
	assert_eq(GameConfig.enemy("bad"), {})
	assert_true(GameConfig.enemy_kinds().has("invented"))
	assert_true(GameConfig.enemy_kinds().has("beetle"))
	assert_eq(float(GameConfig.enemy("beetle").hp), float(GameConfig.ENEMIES.beetle.hp))


func test_building_armor_override_changes_tank_value() -> void:
	ContentOverrides.set_data({"buildings": {"battery": {"armor": 55.0}, "solar": {"armor": -3}, "relay": {}}})
	var battery := Building.new(1, "battery", Vector2.ZERO)
	var solar := Building.new(2, "solar", Vector2.ZERO)
	var relay := Building.new(3, "relay", Vector2.ZERO)
	assert_eq(Formulas.armor(battery), 55.0)
	assert_eq(Formulas.armor(solar), 0.0)
	assert_eq(Formulas.armor(relay), float(GameConfig.building("relay").armor))


func test_building_armor_override_is_raised_by_the_armour_track() -> void:
	ContentOverrides.set_data({"buildings": {"zapper": {"armor": 20.0}}})
	var zapper := Building.new(1, "zapper", Vector2.ZERO)
	zapper.set_level(GameConfig.TRACK_ARMOR, 2)
	assert_eq(Formulas.base_armor(zapper), 20.0)
	assert_almost_eq(Formulas.armor(zapper), 20.0 + GameConfig.ARMOR_UNIT * 2.0 * float(GameConfig.TRACKS[GameConfig.TRACK_ARMOR].step), 0.0001)


func test_levels_convert_vectors() -> void:
	ContentOverrides.set_data({"levels": [_level("a", [0.1, 0.2]), _level("b")]})
	var level := GameConfig.level(0)
	assert_eq(level.cells, Vector2i(20, 30))
	assert_eq(level.drop, Vector2(0.5, 0.8))
	assert_eq(level.world, Vector2(0.1, 0.2))
	assert_eq(level.structures[0][1], Vector2(0.5, 0.1))
	assert_eq(level.terrain.spots[0][0], Vector2(0.3, 0.7))
	assert_eq(level.terrain.spots[0][2][0], Vector2i(1, 0))
	assert_null(GameConfig.level(1).world)
	assert_eq(GameConfig.level_count(), 2)
	assert_eq(GameConfig.level_index("b"), 1)
	assert_eq(GameConfig.level_index("dawn"), -1)
	assert_eq(GameConfig.level(99).id, "b")


func test_invalid_levels_are_dropped() -> void:
	ContentOverrides.set_data({"levels": [5, {"id": "x"}, _level("ok")]})
	assert_eq(GameConfig.level_count(), 1)
	assert_eq(GameConfig.level(0).id, "ok")
	ContentOverrides.set_data({"levels": [5]})
	assert_eq(GameConfig.level_count(), GameConfig.LEVELS.size())


func test_routes_are_converted_and_filtered() -> void:
	ContentOverrides.set_data({"levels": _many(3), "routes": [[0, 1], [1, 2], [1, 2], [2, 2], [0, 9], "x", [0]]})
	assert_eq(ContentOverrides.routes(), [Vector2i(0, 1), Vector2i(1, 2)] as Array[Vector2i])


func test_reset_restores_defaults() -> void:
	ContentOverrides.set_data({"levels": _many(3)})
	assert_eq(GameConfig.level_count(), 3)
	ContentOverrides.reset()
	assert_eq(GameConfig.level_count(), GameConfig.LEVELS.size())


func test_version_changes_with_every_data_switch() -> void:
	var start := ContentOverrides.version()
	ContentOverrides.set_data({})
	var after_set := ContentOverrides.version()
	assert_gt(after_set, start)
	ContentOverrides.reset()
	assert_gt(ContentOverrides.version(), after_set)
	var stable := ContentOverrides.version()
	assert_eq(ContentOverrides.version(), stable)


func test_enemy_overrides_are_sanitized_against_the_defaults() -> void:
	var broken: Dictionary = GameConfig.ENEMIES.crawler.duplicate(true)
	broken.erase("radius")
	broken["hp"] = -5.0
	broken["damage"] = -3.0
	broken["class"] = "flying"
	broken["faction"] = "castle"
	broken["look"] = ""
	broken["boss"] = "yes"
	broken["buffs"] = {"night": {"hp": -4.0, "damage": 0.5, "speed": "x"}, "level": 3}
	ContentOverrides.set_data({"enemies": {"crawler": broken, "ghost": {"class": "air", "speed": 50.0}}})
	var crawler := GameConfig.enemy("crawler")
	assert_eq(float(crawler.radius), float(GameConfig.ENEMIES.crawler.radius))
	assert_eq(float(crawler.hp), float(GameConfig.ENEMIES.crawler.hp))
	assert_eq(float(crawler.damage), 0.0)
	assert_eq(crawler["class"], GameConfig.ENEMIES.crawler["class"])
	assert_eq(crawler.faction, GameConfig.NEST)
	assert_eq(crawler.look, "crawler")
	assert_false(crawler.has("boss"))
	assert_eq(crawler.buffs, {"night": {"damage": 0.5}})
	assert_eq(GameConfig.enemy("ghost"), {})
	var enemy := Enemy.new(1, "crawler", Vector2.ZERO, 1.0, 1.0, 1.0, true, 3)
	assert_gt(enemy.max_hp, 0.0)
	assert_gt(enemy.radius(), 0.0)


func test_new_enemy_kinds_need_the_positive_basics() -> void:
	var full := {"class": "air", "hp": 30.0, "speed": 80.0, "cooldown": 1.0, "radius": 8.0, "faction": "camp"}
	ContentOverrides.set_data({"enemies": {"ghost": full}})
	var ghost := GameConfig.enemy("ghost")
	assert_eq(float(ghost.armor), 0.0)
	assert_eq(float(ghost.reach), 0.0)
	assert_eq(int(ghost.bounty), 0)
	assert_eq(ghost.look, "ghost")
	assert_true(GameConfig.faction_kinds(GameConfig.CAMP).has("ghost"))


func test_levels_are_sanitized_so_the_game_cannot_break() -> void:
	var level := _level("odd")
	level["cells"] = [3, 9000]
	level["day"] = 0.0
	level["night"] = "long"
	level["money"] = -50
	level["drop"] = [1.5, -0.2]
	level["world"] = [2.0, 0.5]
	level["structures"] = [["castle", [0.5, 0.1]], ["camp", [0.4, 0.2]], ["core", [0.3, 0.3]]]
	level["waves"] = {"interval": 0.0, "base": -1.0, "ramp": 2.0, "roster": [["crawler", 0, 1.0], ["unknown", 0, 1.0], ["beetle", 1, 0.0], "x"], "night_roster": "x"}
	level["challenges"] = [["core", 60], ["lost"], 5]
	level["extra_waves"] = [{"day": 2, "night": true, "kind": "unknown", "count": 3}, {"day": 0, "night": false, "kind": "wasp", "count": 999}]
	ContentOverrides.set_data({"levels": [level, _level("odd"), _level("next")]})
	assert_eq(GameConfig.level_count(), 2)
	var parsed := GameConfig.level(0)
	assert_eq(parsed.cells, Vector2i(ContentOverrides.MIN_CELLS, ContentOverrides.MAX_CELLS))
	assert_eq(parsed.day, ContentOverrides.DEFAULT_DAY)
	assert_eq(parsed.night, ContentOverrides.DEFAULT_NIGHT)
	assert_eq(parsed.money, 0)
	assert_eq(parsed.drop, Vector2(1.0, 0.0))
	assert_eq(parsed.world, Vector2(1.0, 0.5))
	assert_eq(parsed.structures, [["camp", Vector2(0.4, 0.2)]])
	assert_eq(parsed.waves.interval, ContentOverrides.WAVE_DEFAULTS.interval)
	assert_eq(parsed.waves.base, ContentOverrides.WAVE_DEFAULTS.base)
	assert_eq(parsed.waves.ramp, 2.0)
	assert_eq(parsed.waves.roster, [["crawler", 0, 1.0]])
	assert_eq(parsed.waves.night_roster, [])
	assert_eq(parsed.challenges, [["core", 60]])
	assert_eq(parsed.extra_waves, [{"day": 1, "night": false, "kind": "wasp", "count": ContentOverrides.MAX_EXTRA_COUNT}])
	assert_gt(Formulas.wave_times(parsed), 0)
	assert_eq(GameConfig.level(1).id, "next")


func test_faction_kinds_follow_the_faction_field() -> void:
	for spawner: String in GameConfig.SPAWNER_FACTIONS:
		assert_eq(GameConfig.faction_kinds(spawner), GameConfig.SPAWNER_FACTIONS[spawner])
	assert_eq(GameConfig.faction_kinds(GameConfig.TURRET), [])
	var moved: Dictionary = GameConfig.ENEMIES.crawler.duplicate(true)
	moved["faction"] = GameConfig.CAMP
	ContentOverrides.set_data({"enemies": {"crawler": moved}})
	assert_false(GameConfig.faction_kinds(GameConfig.NEST).has("crawler"))
	assert_true(GameConfig.faction_kinds(GameConfig.CAMP).has("crawler"))
	assert_true(GameConfig.faction_kinds(GameConfig.CAMP).is_read_only())
	assert_eq(SpawnDirector.eligible([["crawler", 0, 1.0]], GameConfig.CAMP, 1), [["crawler", 0, 1.0]])
	assert_eq(SpawnDirector.eligible([["crawler", 0, 1.0]], GameConfig.NEST, 1), [])
	ContentOverrides.reset()
	assert_true(GameConfig.faction_kinds(GameConfig.NEST).has("crawler"))
