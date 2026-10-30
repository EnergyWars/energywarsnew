class_name CreepNest
extends RefCounted

var id: int
var cell: Vector2i
var position: Vector2
var alive := true
var fade := 1.0


func _init(p_id: int, p_cell: Vector2i, p_position: Vector2) -> void:
	id = p_id
	cell = p_cell
	position = p_position


func radius_cells() -> float:
	return GameConfig.CREEP_RADIUS * fade


func is_active() -> bool:
	return fade > 0.0
