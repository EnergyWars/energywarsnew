class_name Building
extends RefCounted

var id: int
var kind: String
var position: Vector2
var hp: float
var energy := 0.0
var levels := {}
var cooldown := 0.0
var target_id := -1
var spent := 0
var spawn_progress := 0.0
var hit_time := -INF
var laser_damage := 0.0
var laser_timer := 0.0
var firing := false
var laser_target: Object = null
var scan_timer := 0.0
var export_buffer := 0.0
var origin := Vector2i.ZERO
var elevation := 0
var target_order: Array[String] = GameConfig.CLASSES.duplicate()
var target_disabled := {}
var _team := GameConfig.TEAM_PLAYER


func _init(p_id: int, p_kind: String, p_position: Vector2) -> void:
	id = p_id
	kind = p_kind
	_team = int(definition().get("team", GameConfig.TEAM_PLAYER))
	origin = LevelMap.footprint_origin(p_position, cells())
	position = LevelMap.footprint_center(origin, cells())
	hp = max_hp()
	spent = int(definition().get("cost", 0))


func definition() -> Dictionary:
	return GameConfig.building(kind)


func team() -> int:
	return _team


func is_player() -> bool:
	return _team == GameConfig.TEAM_PLAYER


func is_alive() -> bool:
	return hp > 0.0


func max_hp() -> float:
	return float(definition().get("hp", 1.0)) * Formulas.multiplier(self, GameConfig.TRACK_HULL)


func cells() -> int:
	return GameConfig.cells(kind)


func footprint() -> Array[Vector2i]:
	return LevelMap.footprint(origin, cells())


func half_extent() -> float:
	return cells() * GameConfig.CELL * 0.5


func edge_distance(point: Vector2) -> float:
	var offset := (point - position).abs() - Vector2(half_extent(), half_extent())
	return Vector2(maxf(offset.x, 0.0), maxf(offset.y, 0.0)).length()


func can_target(unit_class: String) -> bool:
	if target_disabled.get(unit_class, false):
		return false
	var attack: Dictionary = definition().get("attack", {})
	if unit_class == GameConfig.CLASS_AIR:
		return bool(attack.get("air", true))
	return bool(attack.get("ground", true))


func radius() -> float:
	return float(definition().get("radius", 20.0))


func level(track: String) -> int:
	return int(levels.get(track, 0))


func has_track(track: String) -> bool:
	return definition().get("tracks", []).has(track)


func hp_ratio() -> float:
	return clampf(hp / max_hp(), 0.0, 1.0)
