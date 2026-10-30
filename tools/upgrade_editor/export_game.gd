extends SceneTree

const SCHEMA := 1
const CONTENT_OVERRIDES := "res://data/content_overrides.json"
const OUTPUT := "res://tools/upgrade_editor/data/game.json"
const TRANSLATIONS_CSV := "res://i18n/translations.csv"
const TEXT_PREFIXES: Array[String] = ["BUILDING_", "TRACK_", "BUILD_CATEGORY_", "ENEMY_"]
const OVERRIDES := "res://data/upgrade_overrides.json"
const VECTOR_STEP := 0.000001
const HISTORY_KINDS: Array[String] = ["cost", "effect"]
const HISTORY_LIMIT := 30
const HISTORY_TEXT_LIMIT := 500
const STAT_SKIP: Array[String] = ["team", "cells", "cost", "hp", "upgrade_base", "armor"]


var _plans := {}
var _content := {}


func _initialize() -> void:
	var previous := _load_previous()
	_plans = _load_plans()
	_content = _load_content()
	var buildings: Array = []
	var costs := {}
	for kind in _kinds():
		buildings.append(_building(kind))
		costs[kind] = _costs(kind)
	var document := {
		"schema": SCHEMA,
		"system": {"track_growth": GameConfig.TRACK_GROWTH, "cell": GameConfig.CELL},
		"tracks": GameConfig.TRACKS.duplicate(true),
		"buildings": buildings,
		"categories": GameConfig.BUILD_CATEGORIES.duplicate(true),
		"starters": GameConfig.STARTER_KINDS.duplicate(),
		"names": _names(),
		"check": costs,
		"armor": _armor(),
		"enemies": _enemies(),
		"levels": _levels(),
	}
	document["routes"] = _routes(document["levels"].size())
	document["defaults"] = _defaults()
	_keep_groups(document, previous)
	_keep_history(document, previous)
	var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
	file.store_string(JSON.stringify(document, "\t", false))
	file.close()
	print("exported %d buildings, %d tracks" % [buildings.size(), GameConfig.TRACKS.size()])
	quit()


func _kinds() -> Array[String]:
	var kinds: Array[String] = [GameConfig.CORE]
	for kind in GameConfig.BUILD_ORDER:
		kinds.append(kind)
	return kinds


func _building(kind: String) -> Dictionary:
	var definition := GameConfig.building(kind)
	var entry := {
		"id": kind,
		"cost": int(definition.get("cost", 0)),
		"upgrade_base": Formulas.upgrade_base(kind),
		"hp": float(definition.hp),
		"armor": _building_armor(kind, definition),
		"description_key": "BUILDING_%s_DESC" % kind.to_upper(),
		"tracks": definition.get("tracks", []).duplicate(),
		"curves": definition.get("curves", {}).duplicate(true),
		"stats": _stats(definition),
	}
	var plans := _entry_plans(kind)
	if not plans.is_empty():
		entry["plans"] = plans
	if definition.has("cost_every"):
		entry["cost_every"] = int(definition.cost_every)
	return entry


func _stats(definition: Dictionary) -> Dictionary:
	var result := {}
	for key: String in definition:
		var value: Variant = definition[key]
		if STAT_SKIP.has(key):
			continue
		if value is int or value is float:
			result[key] = value
		elif value is Dictionary and key != "curves":
			var nested := {}
			for inner: String in value:
				if value[inner] is int or value[inner] is float:
					nested[inner] = value[inner]
			if not nested.is_empty():
				result[key] = nested
	return result


func _load_previous() -> Dictionary:
	if not FileAccess.file_exists(OUTPUT):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(OUTPUT))
	return parsed if parsed is Dictionary else {}


func _keep_groups(document: Dictionary, previous: Dictionary) -> void:
	var groups: Variant = previous.get("groups")
	if not groups is Array:
		return
	var known := {}
	for entry: Dictionary in document["buildings"]:
		for track: String in entry["tracks"]:
			known["%s:%s" % [entry["id"], track]] = true
	var kept: Array = []
	for area: Variant in groups:
		if not area is Dictionary or not area.get("name") is String:
			continue
		var sections: Array = []
		var listed: Variant = area.get("sections", [])
		if listed is Array:
			for section: Variant in listed:
				if section is Dictionary and section.get("name") is String:
					sections.append({"name": section["name"], "items": _known_items(section.get("items", []), known)})
		kept.append({"name": area["name"], "items": _known_items(area.get("items", []), known), "sections": sections})
	document["groups"] = kept


func _keep_history(document: Dictionary, previous: Dictionary) -> void:
	var history: Variant = previous.get("formula_history")
	if not history is Dictionary:
		return
	var kept := {}
	for kind: String in HISTORY_KINDS:
		var items: Variant = history.get(kind)
		if not items is Array:
			continue
		var list: Array = []
		for item: Variant in items:
			if item is String and not item.strip_edges().is_empty() and item.length() <= HISTORY_TEXT_LIMIT and not list.has(item) and list.size() < HISTORY_LIMIT:
				list.append(item)
		kept[kind] = list
	document["formula_history"] = kept


func _known_items(items: Variant, known: Dictionary) -> Array:
	var result: Array = []
	if not items is Array:
		return result
	for item: Variant in items:
		if item is String and known.has(item) and not result.has(item):
			result.append(item)
	return result


func _load_plans() -> Dictionary:
	if not FileAccess.file_exists(OVERRIDES):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(OVERRIDES))
	return parsed.get("plans", {}) if parsed is Dictionary else {}


func _entry_plans(kind: String) -> Dictionary:
	var result := {}
	for track: String in _plans.get(kind, {}):
		var plan: Dictionary = _plans[kind][track].duplicate(true)
		var levels: Array = []
		for level: Dictionary in plan.get("levels", []):
			levels.append({"cost": int(level.cost), "gain": float(level.gain)})
		plan["levels"] = levels
		result[track] = plan
	return result


func _costs(kind: String) -> Dictionary:
	var result := {}
	var building := Building.new(0, kind, Vector2.ZERO)
	for track: String in GameConfig.building(kind).get("tracks", []):
		var levels: Array = []
		for level in Formulas.max_level(building, track):
			building.levels = {track: level}
			levels.append(Formulas.upgrade_cost(building, track))
		result[track] = levels
	return result


func _names() -> Dictionary:
	var result := {}
	var file := FileAccess.open(TRANSLATIONS_CSV, FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 3 or row[0].is_empty():
			continue
		for prefix in TEXT_PREFIXES:
			if row[0].begins_with(prefix):
				result[row[0]] = {"en": row[1], "de": row[2]}
	return result


func _defaults() -> Dictionary:
	var stored := _content
	_content = {}
	var levels := _levels()
	var result := {"armor": _armor(), "enemies": _enemies(), "levels": levels, "routes": _routes(levels.size())}
	_content = stored
	return result


func _load_content() -> Dictionary:
	if not FileAccess.file_exists(CONTENT_OVERRIDES):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTENT_OVERRIDES))
	return parsed if parsed is Dictionary else {}


func _armor() -> Dictionary:
	var result: Dictionary = GameConfig.ARMOR.duplicate()
	var override: Variant = _content.get("armor")
	if override is Dictionary:
		for key: String in override:
			result[key] = float(override[key])
	return result


func _building_armor(kind: String, definition: Dictionary) -> float:
	var override: Variant = _content.get("buildings", {}).get(kind)
	if override is Dictionary and override.has("armor"):
		return float(override.armor)
	return float(definition.get("armor", 0.0))


func _faction(kind: String) -> String:
	for faction: String in GameConfig.SPAWNER_FACTIONS:
		if GameConfig.SPAWNER_FACTIONS[faction].has(kind):
			return faction
	return GameConfig.NEST


func _enemy(kind: String, definition: Dictionary) -> Dictionary:
	var result: Dictionary = _json(definition)
	result["armor"] = float(result.get("armor", 0.0))
	if not result.has("faction"):
		result["faction"] = _faction(kind)
	if not result.has("look"):
		result["look"] = kind
	var buffs: Dictionary = result.get("buffs", {})
	var complete := {}
	for scope in ["night", "level"]:
		var entry := {}
		for stat in ["hp", "damage", "speed", "armor"]:
			entry[stat] = float(buffs.get(scope, {}).get(stat, 0.0))
		complete[scope] = entry
	result["buffs"] = complete
	return result


func _enemies() -> Dictionary:
	var result := {}
	for kind: String in GameConfig.ENEMIES:
		result[kind] = _enemy(kind, GameConfig.ENEMIES[kind])
	var overrides: Variant = _content.get("enemies")
	if overrides is Dictionary:
		for kind: String in overrides:
			if overrides[kind] is Dictionary:
				result[kind] = _enemy(kind, overrides[kind])
	return result


func _levels() -> Array:
	var source: Variant = _content.get("levels")
	if source is Array and not source.is_empty():
		return _json(source)
	return _json(GameConfig.LEVELS)


func _routes(count: int) -> Array:
	var source: Variant = _content.get("routes")
	if source is Array:
		return _json(source)
	if not _content.get("levels") is Array:
		return _json(GameConfig.WORLD_ROUTES)
	var result: Array = []
	for index in range(1, count):
		result.append([index - 1, index])
	return result


func _json(value: Variant) -> Variant:
	if value is Vector2i:
		return [value.x, value.y]
	if value is Vector2:
		return [snappedf(value.x, VECTOR_STEP), snappedf(value.y, VECTOR_STEP)]
	if value is Array:
		var list: Array = []
		for item in value:
			list.append(_json(item))
		return list
	if value is Dictionary:
		var map := {}
		for key in value:
			map[key] = _json(value[key])
		return map
	return value
