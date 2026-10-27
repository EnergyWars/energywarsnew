class_name Juice
extends RefCounted

const POP_SCALE := 1.18
const POP_TIME := 0.36
const POP_IN_FROM := 0.4


static func center_pivot(control: Control) -> void:
	if is_instance_valid(control):
		control.pivot_offset = control.size * 0.5


static func pop(control: Control, strength: float = POP_SCALE) -> Tween:
	if not control.is_inside_tree():
		return null
	center_pivot(control)
	var tween := control.create_tween()
	tween.tween_property(control, "scale", Vector2.ONE * strength, POP_TIME * 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, POP_TIME * 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return tween


static func pop_in(control: Control, delay: float = 0.0) -> Tween:
	if not control.is_inside_tree():
		return null
	center_pivot(control)
	control.scale = Vector2.ONE * POP_IN_FROM
	control.modulate.a = 0.0
	var tween := control.create_tween().set_parallel()
	tween.tween_callback(center_pivot.bind(control)).set_delay(delay)
	tween.tween_property(control, "scale", Vector2.ONE, POP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
	tween.tween_property(control, "modulate:a", 1.0, POP_TIME * 0.5).set_delay(delay)
	return tween


static func breathe(control: Control, amount: float = 1.06, period: float = 0.55) -> Tween:
	if not control.is_inside_tree():
		return null
	center_pivot(control)
	var tween := control.create_tween().set_loops()
	tween.tween_callback(center_pivot.bind(control))
	tween.tween_property(control, "scale", Vector2.ONE * amount, period).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, period).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween


static func float_scale(elapsed: float) -> float:
	var rise := 0.12
	if elapsed <= 0.0:
		return 0.4
	if elapsed < rise:
		return lerpf(0.4, 1.35, elapsed / rise)
	if elapsed < rise * 2.0:
		return lerpf(1.35, 1.0, (elapsed - rise) / rise)
	return 1.0
