class_name Building
extends RefCounted

var id: int
var kind: String
var position: Vector2
var hp: float
var energy := 0.0
var levels := {}:
	set(value):
		levels = value
		_stats_valid = false
var cooldown := 0.0
var target_id := -1
var spent := 0
var plan_spent := 0
var spawn_progress := 0.0
var spawn_queue := 0
var spawn_heading := 0.0
var spawn_timer := 0.0
var guard_timer := 0.0
var hit_time := -INF
var laser_damage := 0.0
var laser_timer := 0.0
var firing := false
var laser_target: Object = null
var scan_timer := 0.0
var export_buffer := 0.0
var origin := Vector2i.ZERO
var elevation := 0:
	set(value):
		elevation = value
		_stats_valid = false
var boosts := {}:
	set(value):
		boosts = value
		_stats_valid = false
var immune := false
var target_order: Array[String] = GameConfig.CLASSES.duplicate()
var target_disabled := {}
var focus: Object = null
var steer := Vector2.ZERO
var stalled := false
var armed := false
var healing := false
var shielding := false
var exporting := false
var mobile := false
var spawner := false
var _team := GameConfig.TEAM_PLAYER
var _definition: Dictionary
var _cells := 1
var _half := 0.0
var _radius := 0.0
var _stats := PackedFloat64Array()
var _stats_valid := false


func _init(p_id: int, p_kind: String, p_position: Vector2) -> void:
	id = p_id
	kind = p_kind
	_definition = GameConfig.building(kind)
	_team = int(_definition.get("team", GameConfig.TEAM_PLAYER))
	armed = _definition.has("attack")
	healing = _definition.has("heal")
	shielding = _definition.has("shield")
	exporting = _definition.has("export")
	mobile = _definition.has("mobile")
	spawner = bool(_definition.get("spawns", false))
	_cells = int(_definition.get("cells", 1))
	_half = _cells * GameConfig.CELL * 0.5
	_radius = float(_definition.get("radius", 20.0))
	origin = LevelMap.footprint_origin(p_position, cells())
	position = LevelMap.footprint_center(origin, cells())
	hp = max_hp()
	spent = int(definition().get("cost", 0))


func definition() -> Dictionary:
	return _definition


func team() -> int:
	return _team


func is_player() -> bool:
	return _team == GameConfig.TEAM_PLAYER


func is_alive() -> bool:
	return hp > 0.0


func max_hp() -> float:
	return stat(Formulas.Stat.MAX_HP)


func stat(index: int) -> float:
	if not _stats_valid:
		_stats = Formulas.compute_stats(self)
		_stats_valid = true
	return _stats[index]


func boost(name: String) -> float:
	return float(boosts.get(name, 1.0))


func set_level(track: String, value: int) -> void:
	levels[track] = value
	_stats_valid = false


func cells() -> int:
	return _cells


func footprint() -> Array[Vector2i]:
	return LevelMap.footprint(origin, cells())


func half_extent() -> float:
	return _half


func edge_distance(point: Vector2) -> float:
	var dx := maxf(absf(point.x - position.x) - _half, 0.0)
	var dy := maxf(absf(point.y - position.y) - _half, 0.0)
	return sqrt(dx * dx + dy * dy)


func can_target(unit_class: String) -> bool:
	if target_disabled.get(unit_class, false):
		return false
	var attack: Dictionary = definition().get("attack", GameConfig.EMPTY)
	if unit_class == GameConfig.CLASS_AIR:
		return bool(attack.get("air", true))
	return bool(attack.get("ground", true))


func radius() -> float:
	return _radius


func level(track: String) -> int:
	return int(levels.get(track, 0))


func has_track(track: String) -> bool:
	return definition().get("tracks", GameConfig.EMPTY_LIST).has(track)


func hp_ratio() -> float:
	return clampf(hp / max_hp(), 0.0, 1.0)
