extends SceneTree

const SCHEMA := 1
const OUTPUT := "res://tools/upgrade_editor/data/game.json"
const TRANSLATIONS_CSV := "res://i18n/translations.csv"
const TEXT_PREFIXES: Array[String] = ["BUILDING_", "TRACK_", "BUILD_CATEGORY_"]
const OVERRIDES := "res://data/upgrade_overrides.json"
const STAT_SKIP: Array[String] = ["team", "cells", "cost", "hp", "upgrade_base"]


var _plans := {}


func _initialize() -> void:
	_plans = _load_plans()
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
	}
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
