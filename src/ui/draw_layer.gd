class_name DrawLayer
extends Node2D

var paint: Callable


func setup(p_paint: Callable) -> DrawLayer:
	paint = p_paint
	return self


func _draw() -> void:
	if paint.is_valid():
		paint.call(self)
