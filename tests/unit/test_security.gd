extends GutTest

const PROBE := "res://tests/support/security_probe.gd"
const MARK := "security_probe_created"
const SETTINGS := "user://test_security_settings.json"
const LEGACY := "user://test_security_settings.cfg"
const SAVE := "user://test_security_progress.json"
const PAYLOAD := "[general]\nlocale=Object(RefCounted,\"script\":Resource(\"%s\"))\n[feedback]\nsound=Resource(\"%s\")\nhaptics=false\n"
const FORBIDDEN: Array[String] = ["ConfigFile", "str_to_var", "bytes_to_var", "get_var(", "OS.execute", "OS.create_process",
	"OS.shell_open", "HTTPRequest", "HTTPClient", "WebSocket", "StreamPeerTCP", "PacketPeerUDP", "JavaScriptBridge"]
const DEBUG_OUTPUT := "(?<![A-Za-z0-9_.])(print|printerr|print_debug|print_rich|prints|printt|printraw)\\("


func before_each() -> void:
	_clear_mark()
	for target in [SETTINGS, LEGACY, SAVE]:
		SafeFile.remove(target)


func after_each() -> void:
	before_each()
	ContentOverrides.reset()
	UpgradeOverrides.reset()


func _clear_mark() -> void:
	if Engine.has_meta(MARK):
		Engine.remove_meta(MARK)


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _payload() -> String:
	return PAYLOAD % [PROBE, PROBE]


func test_the_probe_detects_object_instantiation() -> void:
	var config := ConfigFile.new()
	assert_eq(config.parse(_payload()), OK)
	assert_true(Engine.has_meta(MARK), "ConfigFile builds objects from text, so it must never read user files")


func test_settings_never_instantiate_objects_from_files() -> void:
	_write(LEGACY, _payload())
	var settings := AppSettings.new(SETTINGS, LEGACY).load_settings()
	assert_false(Engine.has_meta(MARK))
	assert_eq(settings.locale, "")
	assert_true(settings.sound)
	assert_false(settings.haptics)
	_write(SETTINGS, JSON.stringify({"locale": "Object(RefCounted)", "sound": "Resource(\"%s\")" % PROBE, "haptics": {"script": PROBE}}))
	settings = AppSettings.new(SETTINGS, LEGACY).load_settings()
	assert_false(Engine.has_meta(MARK))
	assert_eq(settings.locale, "")
	assert_true(settings.sound)
	assert_true(settings.haptics)


func test_legacy_settings_migrate_to_json() -> void:
	_write(LEGACY, "[general]\n\nlocale=\"de\"\n\n[feedback]\n\nsound=false\nhaptics=false\n")
	var settings := AppSettings.new(SETTINGS, LEGACY).load_settings()
	assert_eq(settings.locale, "de")
	assert_false(settings.sound)
	assert_false(settings.haptics)
	settings.save()
	assert_false(FileAccess.file_exists(LEGACY))
	var stored: Variant = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS))
	assert_eq(stored, {"locale": "de", "sound": false, "haptics": false})
	var reloaded := AppSettings.new(SETTINGS, LEGACY).load_settings()
	assert_eq(reloaded.locale, "de")
	assert_false(reloaded.sound)


func test_legacy_parser_only_accepts_plain_values() -> void:
	assert_eq(AppSettings.parse_legacy("locale=\"xx\"\nsound=1\nhaptics=TRUE\nother=true\nlocale\n=\n"), {})
	assert_eq(AppSettings.parse_legacy("  locale = \"en\"  \nsound=true"), {"locale": "en", "sound": true})


func test_settings_reject_wrong_types_and_oversized_files() -> void:
	_write(SETTINGS, JSON.stringify({"locale": 5, "sound": "no", "haptics": null}))
	var settings := AppSettings.new(SETTINGS).load_settings()
	assert_eq(settings.locale, "")
	assert_true(settings.sound)
	assert_true(settings.haptics)
	_write(SETTINGS, JSON.stringify({"locale": "de", "sound": false, "pad": "x".repeat(AppSettings.MAX_BYTES)}))
	settings = AppSettings.new(SETTINGS).load_settings()
	assert_eq(settings.locale, "")
	assert_true(settings.sound)
	_write(SETTINGS, "[1, 2")
	assert_true(AppSettings.new(SETTINGS).load_settings().sound)


func test_default_settings_path_is_json() -> void:
	assert_eq(AppSettings.DEFAULT_PATH.get_extension(), "json")
	assert_eq(AppSettings.new().legacy_path, AppSettings.LEGACY_PATH)
	assert_eq(AppSettings.new(SETTINGS).legacy_path, "")


func test_progress_survives_manipulated_types() -> void:
	var progress := Progress.new(SAVE)
	for broken: Variant in [null, [2], "two", {"x": 1}, INF, "inf"]:
		progress.apply({"version": broken, "total_kills": 5})
		assert_eq(progress.total_kills, 0)
	var dawn := str(GameConfig.level(0).id)
	var regions := {dawn: {"stars": [1], "best_days": null, "conquered": "yes", "done": "conquer"}, "x": 5}
	progress.apply({"version": 2, "regions": regions, "techs": "all", "location": {}, "seen": {}, "total_kills": null, "best_combo": "7"})
	assert_eq(progress.best_combo, 7)
	assert_eq(progress.total_kills, 0)
	assert_eq(progress.location, 0)
	assert_eq(progress.techs, [] as Array[String])
	assert_eq(progress.stars_for(0), 0)
	assert_eq(progress.best_days(0), 0)
	assert_false(progress.is_conquered(0))
	progress.apply({"version": 1, "stars": {dawn: null}})
	assert_false(progress.is_conquered(0))


func test_progress_numbers_are_clamped() -> void:
	var dawn := str(GameConfig.level(0).id)
	var progress := Progress.new(SAVE)
	progress.apply({"version": 2.0, "regions": {dawn: {"stars": 1e300, "best_days": -5.0, "conquered": true, "done": []}}, "total_kills": 1e300, "best_combo": -1e300, "location": 1e300})
	assert_eq(progress.stars_for(0), Progress.MAX_STARS)
	assert_eq(progress.best_days(0), 0)
	assert_true(progress.is_conquered(0))
	assert_eq(progress.total_kills, int(Progress.MAX_NUMBER))
	assert_eq(progress.best_combo, 0)
	assert_eq(progress.location, GameConfig.level_count() - 1)


func test_retained_regions_are_bounded_and_sanitized() -> void:
	var regions := {}
	for i in Progress.MAX_RETAINED + 50:
		regions["gone%d" % i] = {"conquered": true, "stars": 9, "done": ["conquer", 5, "x".repeat(60)], "evil": "x".repeat(1000)}
	regions["y".repeat(100)] = {"conquered": true}
	var progress := Progress.new(SAVE)
	progress.apply({"version": 2, "regions": regions})
	var stored: Dictionary = progress.to_dict().regions
	assert_eq(stored.size(), Progress.MAX_RETAINED)
	assert_false(stored.has("y".repeat(100)))
	var entry: Dictionary = stored.values()[0]
	assert_eq(entry.keys().size(), 4)
	assert_eq(entry.stars, Progress.MAX_STARS)
	assert_eq(entry.done, ["conquer"] as Array[String])


func test_oversized_or_broken_saves_are_ignored() -> void:
	var dawn := str(GameConfig.level(0).id)
	_write(SAVE, JSON.stringify({"version": 2, "regions": {dawn: {"conquered": true}}, "pad": "x".repeat(Progress.MAX_BYTES)}))
	assert_false(Progress.new(SAVE).load_progress().is_conquered(0))
	_write(SAVE, "{\"version\": 2,")
	assert_false(Progress.new(SAVE).load_progress().is_conquered(0))
	_write(SAVE, JSON.stringify({"version": 2, "regions": {dawn: {"conquered": true}}}))
	assert_true(Progress.new(SAVE).load_progress().is_conquered(0))


func test_safe_file_reads_bounded_json_only() -> void:
	assert_null(SafeFile.read_json("user://does_not_exist.json", 100))
	_write(SAVE, "{\"a\": 1}")
	assert_eq(SafeFile.read_json(SAVE, 100), {"a": 1.0})
	assert_null(SafeFile.read_json(SAVE, 3))
	_write(SAVE, "Object(RefCounted)")
	assert_null(SafeFile.read_json(SAVE, 100))


func _level(id: String) -> Dictionary:
	return {"id": id, "cells": [20, 30], "money": 100, "day": 50.0, "night": 40.0, "seed": 3, "drop": [0.5, 0.8], "structures": [],
		"terrain": {"plateaus": 0, "chasms": 0, "ponds": 0, "groves": 0, "forests": 0, "rocks": 0, "spots": []},
		"waves": {"interval": 9.0, "base": 0.5, "ramp": 1.5, "night": 1.2, "growth": 0.4, "roster": [["crawler", 0, 1.0]], "night_roster": []},
		"world": null, "challenges": []}


func test_content_overrides_cap_sizes() -> void:
	var levels := []
	for i in ContentOverrides.MAX_LEVELS + 20:
		levels.append(_level("lvl%d" % i))
	var first: Dictionary = levels[0]
	first["evil"] = "x".repeat(1000)
	first["structures"] = []
	for i in 100:
		first.structures.append(["nest", [0.5, 0.5]])
	first["terrain"]["ponds"] = 1e9
	first["terrain"]["spots"] = [[[0.5, 0.5], 1e9, [[1e9, -1e9]]]]
	first["waves"]["roster"] = []
	for i in 100:
		first.waves.roster.append(["crawler", 0, 1.0])
	first["challenges"] = []
	for i in 100:
		first.challenges.append(["core", 1])
	var routes := []
	for i in 5000:
		routes.append([0, 1])
	routes.append([1, 2])
	ContentOverrides.set_data({"levels": levels, "routes": routes})
	assert_eq(GameConfig.level_count(), ContentOverrides.MAX_LEVELS)
	var level := GameConfig.level(0)
	assert_false(level.has("evil"))
	assert_eq(level.structures.size(), ContentOverrides.MAX_ITEMS)
	assert_eq(level.terrain.ponds, ContentOverrides.MAX_TERRAIN)
	assert_eq(level.terrain.spots[0][1], ContentOverrides.MAX_CELLS)
	assert_eq(level.terrain.spots[0][2][0], Vector2i(ContentOverrides.MAX_CELLS, -ContentOverrides.MAX_CELLS))
	assert_eq(level.waves.roster.size(), ContentOverrides.MAX_ITEMS)
	assert_eq(level.challenges.size(), ContentOverrides.MAX_ITEMS)
	assert_eq(ContentOverrides.routes(), [Vector2i(0, 1)] as Array[Vector2i])


func test_content_overrides_reject_long_texts() -> void:
	var custom: Dictionary = GameConfig.ENEMIES.crawler.duplicate()
	custom["look"] = "x".repeat(ContentOverrides.MAX_TEXT + 1)
	ContentOverrides.set_data({"enemies": {"crawler": custom}, "levels": [_level("x".repeat(ContentOverrides.MAX_TEXT + 1)), _level("ok")]})
	assert_eq(GameConfig.enemy("crawler").look, GameConfig.ENEMIES.crawler.look)
	assert_eq(GameConfig.level_count(), 1)
	assert_eq(GameConfig.level(0).id, "ok")


func test_upgrade_overrides_survive_broken_plans() -> void:
	var many := []
	for i in UpgradeOverrides.MAX_LEVELS + 50:
		many.append({"cost": 5, "effect": 1.0 + i})
	UpgradeOverrides.set_plans({
		"solar": "x",
		"relay": {"output": "y"},
		"zapper": {"crit": {"levels": "z"}},
		"laser": {"rate": {"levels": [{"cost": null, "effect": 1.5}, {"cost": "5", "effect": 2.0}, {"cost": 1e300, "effect": 1.2}, {"cost": 3, "effect": NAN}, 7]}},
		"lamp": {"hull": {"levels": many}},
	})
	assert_true(UpgradeOverrides.table("solar", GameConfig.TRACK_OUTPUT).is_empty())
	assert_true(UpgradeOverrides.table("relay", GameConfig.TRACK_OUTPUT).is_empty())
	assert_true(UpgradeOverrides.table("zapper", GameConfig.TRACK_CRIT).is_empty())
	var laser := UpgradeOverrides.table("laser", GameConfig.TRACK_RATE)
	assert_eq(laser.max, 1)
	assert_eq(laser.levels[0].cost, UpgradeOverrides.MAX_COST)
	assert_eq(UpgradeOverrides.table("lamp", GameConfig.TRACK_HULL).max, UpgradeOverrides.MAX_LEVELS)


func _scripts(dir: String, found: Array[String]) -> Array[String]:
	for name in DirAccess.get_files_at(dir):
		if name.ends_with(".gd"):
			found.append(dir.path_join(name))
	for name in DirAccess.get_directories_at(dir):
		_scripts(dir.path_join(name), found)
	return found


func test_game_code_avoids_unsafe_apis_and_debug_output() -> void:
	var scripts := _scripts("res://src", [] as Array[String])
	var debug := RegEx.create_from_string(DEBUG_OUTPUT)
	assert_gt(scripts.size(), 10)
	assert_not_null(debug.search("\tprint(1)"))
	assert_null(debug.search("for cell in building.footprint():"))
	for path in scripts:
		var text := FileAccess.get_file_as_string(path)
		for token in FORBIDDEN:
			assert_false(text.contains(token), "%s uses %s" % [path, token])
		assert_null(debug.search(text), "%s writes debug output" % path)
