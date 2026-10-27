class_name Scout
extends RefCounted

const NO_CELL := Vector2i(-1, -1)

var position: Vector2
var heading := Vector2.DOWN
var drop_left := GameConfig.DROP_TIME
var path := PackedVector2Array()
var path_index := 0
var clear_cell := NO_CELL
var clear_progress := 0.0


func _init(p_position: Vector2) -> void:
	position = p_position


func is_landed() -> bool:
	return drop_left <= 0.0


func is_moving() -> bool:
	return path_index < path.size()


func is_clearing() -> bool:
	return clear_cell != NO_CELL


func drop_ratio() -> float:
	return clampf(drop_left / GameConfig.DROP_TIME, 0.0, 1.0)
