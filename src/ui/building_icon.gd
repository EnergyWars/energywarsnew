class_name BuildingIcon
extends Control

var kind := ""
var fill := 0.6
var clock := 0.0
var scale_factor := 1.0


func setup(p_kind: String, p_size: float = 64.0) -> BuildingIcon:
	kind = p_kind
	custom_minimum_size = Vector2(p_size, p_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self


func _process(delta: float) -> void:
	clock += delta
	queue_redraw()


func _draw() -> void:
	if kind.is_empty():
		return
	var radius := float(GameConfig.building(kind).get("radius", 24.0))
	var target := minf(size.x, size.y) * 0.36
	var factor := target / radius * scale_factor
	draw_set_transform(size * 0.5, 0.0, Vector2(factor, factor))
	Painter.building(self, kind, Vector2.ZERO, radius, clock, fill)
	draw_set_transform_matrix(Transform2D.IDENTITY)
