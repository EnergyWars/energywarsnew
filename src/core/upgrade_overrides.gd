class_name UpgradeOverrides
extends RefCounted

const PATH := "res://data/upgrade_overrides.json"

static var _plans := {}
static var _loaded := false


static func table(kind: String, track: String) -> Dictionary:
	_ensure_loaded()
	return _plans.get(kind, GameConfig.EMPTY).get(track, GameConfig.EMPTY)


static func set_plans(plans: Dictionary) -> void:
	_plans = _build(plans)
	_loaded = true


static func reset() -> void:
	_plans = {}
	_loaded = false


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed is Dictionary:
		_plans = _build(parsed.get("plans", GameConfig.EMPTY))


static func _build(plans: Dictionary) -> Dictionary:
	var result := {}
	for kind: String in plans:
		var tracks := {}
		for track: String in plans[kind]:
			var levels := _levels(plans[kind][track])
			if not levels.is_empty():
				tracks[track] = {"levels": levels, "max": levels.size()}
		if not tracks.is_empty():
			result[kind] = tracks
	return result


static func _levels(plan: Dictionary) -> Array:
	var result := []
	for entry: Variant in plan.get("levels", GameConfig.EMPTY_LIST):
		if entry is Dictionary and entry.has("cost") and entry.has("effect"):
			result.append({"cost": maxi(int(entry.cost), 1), "effect": float(entry.effect)})
	return result
