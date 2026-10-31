class_name UpgradeOverrides
extends RefCounted

const PATH := "res://data/upgrade_overrides.json"
const MAX_BYTES := 4194304
const MAX_LEVELS := 200
const MAX_COST := 1000000000000
const MAX_GROUPS := 20
const MAX_TITLE := 60

static var _plans := {}
static var _layouts := {}
static var _loaded := false


static func table(kind: String, track: String) -> Dictionary:
	_ensure_loaded()
	return _plans.get(kind, GameConfig.EMPTY).get(track, GameConfig.EMPTY)


static func layout(kind: String) -> Array:
	_ensure_loaded()
	return _layouts.get(kind, [])


static func set_layouts(layouts: Dictionary) -> void:
	_layouts = _build_layouts(layouts)
	_loaded = true


static func set_plans(plans: Dictionary) -> void:
	_plans = _build(plans)
	_loaded = true


static func reset() -> void:
	_plans = {}
	_layouts = {}
	_loaded = false


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var parsed: Variant = SafeFile.read_json(PATH, MAX_BYTES)
	if parsed is Dictionary:
		_plans = _build(parsed.get("plans"))
		_layouts = _build_layouts(parsed.get("layouts"))


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


static func _build_layouts(layouts: Variant) -> Dictionary:
	var result := {}
	if not layouts is Dictionary:
		return result
	for kind: Variant in layouts:
		if not GameConfig.BUILDINGS.has(str(kind)) or not layouts[kind] is Array:
			continue
		var groups := _groups(str(kind), layouts[kind])
		if not groups.is_empty():
			result[str(kind)] = groups
	return result


static func _groups(kind: String, raw: Array) -> Array:
	var allowed: Array = GameConfig.building(kind).get("tracks", [])
	var used := {}
	var groups := []
	for entry: Variant in raw.slice(0, MAX_GROUPS):
		if not entry is Dictionary or not entry.get("tracks") is Array:
			continue
		var members := []
		for track: Variant in entry.tracks:
			if track is String and allowed.has(track) and not used.has(track):
				members.append(track)
				used[track] = true
		if members.is_empty():
			continue
		var title: Variant = entry.get("title", "")
		groups.append({"title": str(title).substr(0, MAX_TITLE) if title is String else "", "tracks": members})
	var missing := []
	for track: String in allowed:
		if not used.has(track):
			missing.append(track)
	if groups.is_empty() or missing.is_empty():
		return groups if missing.is_empty() else []
	groups[groups.size() - 1].tracks.append_array(missing)
	return groups


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
