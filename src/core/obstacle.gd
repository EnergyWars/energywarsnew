class_name Obstacle
extends RefCounted

var id: int
var cell: Vector2i
var type: String
var position: Vector2
var hp: float
var max_hp: float


func _init(p_id: int, p_cell: Vector2i, p_type: String, p_position: Vector2) -> void:
	id = p_id
	cell = p_cell
	type = p_type
	position = p_position
	max_hp = float(GameConfig.OBSTACLE_HP.get(type, 1.0))
	hp = max_hp


func is_alive() -> bool:
	return hp > 0.0


func radius() -> float:
	return GameConfig.CELL * 0.5


func hp_ratio() -> float:
	return clampf(hp / max_hp, 0.0, 1.0)
