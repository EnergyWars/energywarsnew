class_name Scout
extends RefCounted

const NO_CELL := Vector2i(-1, -1)

var position: Vector2
var heading := Vector2.DOWN
var drop_left := GameConfig.DROP_TIME
var steer := Vector2.ZERO
var clear_cell := NO_CELL
var clear_progress := 0.0
var boarded := false
var cooldown := 0.0
var target_id := -1


func _init(p_position: Vector2) -> void:
	position = p_position


func is_landed() -> bool:
	return drop_left <= 0.0


func is_controllable() -> bool:
	return is_landed() and not boarded


func is_moving() -> bool:
	return is_controllable() and steer != Vector2.ZERO


func is_clearing() -> bool:
	return clear_cell != NO_CELL


func drop_ratio() -> float:
	return clampf(drop_left / GameConfig.DROP_TIME, 0.0, 1.0)
