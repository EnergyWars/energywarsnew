class_name Pickup
extends RefCounted

var position: Vector2
var value: int
var age := 0.0
var velocity: Vector2


func _init(p_position: Vector2, p_value: int, p_velocity: Vector2 = Vector2.ZERO) -> void:
	position = p_position
	value = p_value
	velocity = p_velocity
