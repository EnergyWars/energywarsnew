class_name ContentOverrides
extends RefCounted

const MAX_EXTRA_COUNT := 200
const MIN_CELLS := 20
const MAX_CELLS := 400
const PATH := "res://data/content_overrides.json"
const ARMOR_KEYS: Array[String] = ["constant", "max_reduction", "min_damage"]
const ENEMY_POSITIVE: Array[String] = ["hp", "speed", "cooldown", "radius"]
const ENEMY_NON_NEGATIVE: Array[String] = ["damage", "reach", "armor"]
const ENEMY_FLAGS: Array[String] = ["boss", "nocturnal", "sabotage"]
const BUFF_SCOPES: Array[String] = ["night", "level"]
const BUFF_STATS: Array[String] = ["hp", "damage", "speed", "armor"]
const WAVE_DEFAULTS := {"interval": 9.0, "base": 0.5, "ramp": 1.5, "night": 1.2, "growth": 0.4}
const DEFAULT_DAY := 80.0
const DEFAULT_NIGHT := 60.0
const LOWEST_BUFF := -1.0
const MAX_BYTES := 4194304
const MAX_LEVELS := 200
const MAX_ITEMS := 64
const MAX_ROUTES := 2000
const MAX_TERRAIN := 100
const MAX_TEXT := 48

static var _data := {}
static var _loaded := false
static var _version := 0


static func armor() -> Dictionary:
	_ensure_loaded()
	return _data.get("armor", GameConfig.ARMOR)


static func enemy(kind: String) -> Dictionary:
	_ensure_loaded()
	return _data.get("enemies", GameConfig.EMPTY).get(kind, GameConfig.EMPTY)


static func enemy_kinds() -> Array:
	_ensure_loaded()
	return _data.get("enemies", GameConfig.EMPTY).keys()


static func building_armor(kind: String, fallback: float = 0.0) -> float:
	_ensure_loaded()
	return float(_data.get("buildings", GameConfig.EMPTY).get(kind, GameConfig.EMPTY).get("armor", fallback))


static func levels() -> Array:
	_ensure_loaded()
	return _data.get("levels", GameConfig.EMPTY_LIST)


static func routes() -> Variant:
	_ensure_loaded()
	return _data.get("routes")


static func version() -> int:
	_ensure_loaded()
	return _version


static func set_data(raw: Variant) -> void:
	_data = _build(raw)
	_loaded = true
	_version += 1


static func reset() -> void:
	_data = {}
	_loaded = false
	_version += 1


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_version += 1
	if not FileAccess.file_exists(PATH):
		return
	_data = _build(SafeFile.read_json(PATH, MAX_BYTES))


static func _head(raw: Variant, limit: int) -> Array:
	return raw.slice(0, limit) if raw is Array else []


static func _build(raw: Variant) -> Dictionary:
	var result := {}
	if not raw is Dictionary:
		return result
	var armor_config := _armor(raw.get("armor"))
	if not armor_config.is_empty():
		result["armor"] = armor_config
	var enemies := _enemies(raw.get("enemies"))
	if not enemies.is_empty():
		result["enemies"] = enemies
	var buildings := _buildings(raw.get("buildings"))
	if not buildings.is_empty():
		result["buildings"] = buildings
	var kinds := {}
	for kind: String in GameConfig.ENEMIES:
		kinds[kind] = true
	for kind: String in enemies:
		kinds[kind] = true
	var levels := _levels(raw.get("levels"), kinds)
	if not levels.is_empty():
		result["levels"] = levels
		var routes: Variant = _routes(raw.get("routes"), levels.size())
		if routes != null:
			result["routes"] = routes
	elif raw.get("routes") is Array:
		var routes: Variant = _routes(raw.get("routes"), GameConfig.LEVELS.size())
		if routes != null:
			result["routes"] = routes
	return result


static func _armor(raw: Variant) -> Dictionary:
	if not raw is Dictionary:
		return {}
	var result: Dictionary = GameConfig.ARMOR.duplicate()
	for key in ARMOR_KEYS:
		if _is_number(raw.get(key)):
			result[key] = float(raw[key])
	result["constant"] = maxf(float(result.constant), 0.001)
	result["max_reduction"] = clampf(float(result.max_reduction), 0.0, 1.0)
	result["min_damage"] = maxf(float(result.min_damage), 0.0)
	return result


static func _enemies(raw: Variant) -> Dictionary:
	var result := {}
	if not raw is Dictionary:
		return result
	for kind: Variant in raw:
		if raw[kind] is Dictionary and not raw[kind].is_empty():
			var enemy := _enemy(str(kind), raw[kind])
			if not enemy.is_empty():
				result[str(kind)] = enemy
	return result


static func _enemy(kind: String, raw: Dictionary) -> Dictionary:
	var fallback: Dictionary = GameConfig.ENEMIES.get(kind, GameConfig.EMPTY)
	var result: Dictionary = raw.duplicate(true)
	for key in ENEMY_POSITIVE:
		var value: Variant = raw.get(key)
		if _is_number(value) and float(value) > 0.0:
			result[key] = float(value)
		elif fallback.has(key):
			result[key] = float(fallback[key])
		else:
			return {}
	for key in ENEMY_NON_NEGATIVE:
		var value: Variant = raw.get(key)
		result[key] = maxf(float(value), 0.0) if _is_number(value) else float(fallback.get(key, 0.0))
	var bounty: Variant = raw.get("bounty")
	result["bounty"] = maxi(int(bounty), 0) if _is_number(bounty) else int(fallback.get("bounty", 0))
	var klass: Variant = raw.get("class")
	result["class"] = klass if klass is String and GameConfig.CLASSES.has(klass) else str(fallback.get("class", GameConfig.CLASS_MELEE))
	var faction: Variant = raw.get("faction")
	result["faction"] = faction if faction is String and GameConfig.SPAWNER_FACTIONS.has(faction) else str(fallback.get("faction", GameConfig.NEST))
	var look: Variant = raw.get("look")
	result["look"] = look if look is String and not look.strip_edges().is_empty() and look.length() <= MAX_TEXT else str(fallback.get("look", kind))
	for flag in ENEMY_FLAGS:
		if result.has(flag) and not result[flag] is bool:
			result.erase(flag)
	var buffs := _buffs(raw.get("buffs"))
	if buffs.is_empty():
		result.erase("buffs")
	else:
		result["buffs"] = buffs
	return result


static func _buffs(raw: Variant) -> Dictionary:
	var result := {}
	if not raw is Dictionary:
		return result
	for scope in BUFF_SCOPES:
		var values: Variant = raw.get(scope)
		if not values is Dictionary:
			continue
		var entry := {}
		for stat in BUFF_STATS:
			var value: Variant = values.get(stat)
			if _is_number(value) and float(value) > LOWEST_BUFF:
				entry[stat] = float(value)
		result[scope] = entry
	return result


static func _buildings(raw: Variant) -> Dictionary:
	var result := {}
	if not raw is Dictionary:
		return result
	for kind: String in raw:
		if raw[kind] is Dictionary and _is_number(raw[kind].get("armor")):
			result[kind] = {"armor": maxf(float(raw[kind].armor), 0.0)}
	return result


static func _levels(raw: Variant, kinds: Dictionary) -> Array:
	var result := []
	if not raw is Array:
		return result
	var ids := {}
	for entry: Variant in _head(raw, MAX_LEVELS):
		var level := _level(entry, kinds)
		if not level.is_empty() and not ids.has(level.id):
			ids[level.id] = true
			result.append(level)
	return result


static func _level(entry: Variant, kinds: Dictionary) -> Dictionary:
	if not entry is Dictionary or not entry.has("id") or str(entry.id).strip_edges().is_empty() or str(entry.id).length() > MAX_TEXT or not _vec(entry.get("cells")) is Vector2:
		return {}
	var level := {}
	level["id"] = str(entry.id)
	var cells: Vector2 = _vec(entry.cells)
	level["cells"] = Vector2i(clampi(int(cells.x), MIN_CELLS, MAX_CELLS), clampi(int(cells.y), MIN_CELLS, MAX_CELLS))
	level["drop"] = _unit(_vec(entry.get("drop"), Vector2(0.5, 0.8)))
	var world: Variant = _vec(entry.get("world"))
	level["world"] = _unit(world) if world is Vector2 else null
	var structures := []
	for item: Variant in _head(entry.get("structures"), MAX_ITEMS):
		if item is Array and item.size() >= 2 and _is_structure(item[0]) and _vec(item[1]) is Vector2:
			structures.append([str(item[0]), _unit(_vec(item[1]))])
	level["structures"] = structures
	level["terrain"] = _terrain(entry.get("terrain"))
	level["money"] = maxi(int(entry.get("money", 0)), 0) if _is_number(entry.get("money")) else 0
	level["seed"] = int(entry.get("seed", 0)) if _is_number(entry.get("seed")) else 0
	level["day"] = _positive(entry.get("day"), DEFAULT_DAY)
	level["night"] = _positive(entry.get("night"), DEFAULT_NIGHT)
	level["waves"] = _waves(entry.get("waves"), kinds)
	level["challenges"] = _challenges(entry.get("challenges"))
	var extras := _extra_waves(entry.get("extra_waves"), kinds)
	if extras.is_empty():
		level.erase("extra_waves")
	else:
		level["extra_waves"] = extras
	return level


static func _is_structure(kind: Variant) -> bool:
	return kind is String and int(GameConfig.BUILDINGS.get(kind, GameConfig.EMPTY).get("team", GameConfig.TEAM_PLAYER)) == GameConfig.TEAM_ENEMY


static func _waves(raw: Variant, kinds: Dictionary) -> Dictionary:
	var waves: Dictionary = WAVE_DEFAULTS.duplicate()
	var source: Dictionary = raw if raw is Dictionary else GameConfig.EMPTY
	for key: String in WAVE_DEFAULTS:
		var value: Variant = source.get(key)
		if _is_number(value) and (float(value) > 0.0 if key == "interval" else float(value) >= 0.0):
			waves[key] = float(value)
	waves["roster"] = _roster(source.get("roster"), kinds)
	waves["night_roster"] = _roster(source.get("night_roster"), kinds)
	return waves


static func _roster(raw: Variant, kinds: Dictionary) -> Array:
	var result := []
	for entry: Variant in _head(raw, MAX_ITEMS):
		if entry is Array and entry.size() >= 3 and entry[0] is String and kinds.has(entry[0]) and _is_number(entry[1]) and _is_number(entry[2]) and float(entry[2]) > 0.0:
			result.append([entry[0], maxi(int(entry[1]), 0), float(entry[2])])
	return result


static func _challenges(raw: Variant) -> Array:
	var result := []
	for entry: Variant in _head(raw, MAX_ITEMS):
		if entry is Array and entry.size() >= 2 and entry[0] is String and _is_number(entry[1]):
			result.append([entry[0], maxi(int(entry[1]), 0)])
	return result


static func _extra_waves(raw: Variant, kinds: Dictionary) -> Array:
	var result := []
	for item: Variant in _head(raw, MAX_ITEMS):
		if item is Dictionary and _is_number(item.get("day")) and _is_number(item.get("count")) and item.get("kind") is String and kinds.has(item.kind) and item.get("night") is bool:
			result.append({"day": maxi(int(item.day), 1), "night": item.night, "kind": item.kind, "count": clampi(int(item.count), 0, MAX_EXTRA_COUNT)})
	return result


static func _terrain(raw: Variant) -> Dictionary:
	var terrain := {"plateaus": 0, "chasms": 0, "ponds": 0, "groves": 0, "forests": 0, "rocks": 0, "spots": []}
	if not raw is Dictionary:
		return terrain
	for key: String in terrain:
		if key != "spots" and _is_number(raw.get(key)):
			terrain[key] = clampi(int(raw[key]), 0, MAX_TERRAIN)
	for spot: Variant in _head(raw.get("spots"), MAX_ITEMS):
		if spot is Array and spot.size() >= 3 and _vec(spot[0]) is Vector2 and _is_number(spot[1]) and spot[2] is Array:
			var offsets := []
			for offset: Variant in _head(spot[2], MAX_ITEMS):
				var parsed: Variant = _vec(offset)
				if parsed is Vector2:
					offsets.append(Vector2i(clampi(int(parsed.x), -MAX_CELLS, MAX_CELLS), clampi(int(parsed.y), -MAX_CELLS, MAX_CELLS)))
			terrain.spots.append([_unit(_vec(spot[0])), clampi(int(spot[1]), 1, MAX_CELLS), offsets])
	return terrain


static func _routes(raw: Variant, count: int) -> Variant:
	if not raw is Array:
		return null
	var result: Array[Vector2i] = []
	var seen := {}
	for edge: Variant in _head(raw, MAX_ROUTES):
		var parsed: Variant = _vec(edge)
		if parsed is Vector2:
			var route := Vector2i(int(parsed.x), int(parsed.y))
			var key := Vector2i(mini(route.x, route.y), maxi(route.x, route.y))
			if route.x != route.y and route.x >= 0 and route.y >= 0 and route.x < count and route.y < count and not seen.has(key):
				seen[key] = true
				result.append(route)
	return result


static func _positive(value: Variant, fallback: float) -> float:
	return float(value) if _is_number(value) and float(value) > 0.0 else fallback


static func _unit(point: Vector2) -> Vector2:
	return point.clamp(Vector2.ZERO, Vector2.ONE)


static func _vec(raw: Variant, fallback: Variant = null) -> Variant:
	if raw is Vector2:
		return raw
	if raw is Vector2i:
		return Vector2(raw)
	if raw is Array and raw.size() == 2 and _is_number(raw[0]) and _is_number(raw[1]):
		return Vector2(float(raw[0]), float(raw[1]))
	return fallback


static func _is_number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))
