class_name UpgradeOverrides
extends RefCounted

const PATH := "res://data/upgrade_overrides.json"
const MAX_BYTES := 4194304
const MAX_LEVELS := 200
const MAX_COST := 1000000000000

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
	var parsed: Variant = SafeFile.read_json(PATH, MAX_BYTES)
	if parsed is Dictionary:
		_plans = _build(parsed.get("plans"))


static func _build(plans: Variant) -> Dictionary:
	var result := {}
	if not plans is Dictionary:
		return result
	for kind: Variant in plans:
		if not plans[kind] is Dictionary:
			continue
		var tracks := {}
		for track: Variant in plans[kind]:
			var levels := _levels(plans[kind][track])
			if not levels.is_empty():
				tracks[str(track)] = {"levels": levels, "max": levels.size()}
		if not tracks.is_empty():
			result[str(kind)] = tracks
	return result


static func _levels(plan: Variant) -> Array:
	var result := []
	if not plan is Dictionary or not plan.get("levels") is Array:
		return result
	for entry: Variant in plan.levels.slice(0, MAX_LEVELS):
		if entry is Dictionary and _is_number(entry.get("cost")) and _is_number(entry.get("effect")):
			result.append({"cost": int(clampf(float(entry.cost), 1.0, MAX_COST)), "effect": float(entry.effect)})
	return result


static func _is_number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))
