class_name GestureTracker
extends RefCounted

const TAP_SLOP := 16.0
const DOUBLE_TAP_TIME := 0.35
const DOUBLE_TAP_SLOP := 60.0
const DRAG := "drag"
const PINCH := "pinch"
const TAP := "tap"
const DRAG_END := "drag_end"
const MULTI_END := "multi_end"

var points := {}
var primary := -1
var start := Vector2.ZERO
var moved := false
var multi := false
var double := false
var _last_tap_time := -INF
var _last_tap_position := Vector2.INF
var _last_center := Vector2.ZERO
var _last_span := 0.0


func press(index: int, position: Vector2, time: float = now()) -> bool:
	points[index] = position
	if points.size() == 1 and not multi:
		primary = index
		start = position
		moved = false
		double = time - _last_tap_time <= DOUBLE_TAP_TIME and position.distance_to(_last_tap_position) <= DOUBLE_TAP_SLOP
		_last_tap_time = -INF
		return true
	multi = true
	double = false
	_reset_pinch()
	return false


func move(index: int, position: Vector2) -> Dictionary:
	if not points.has(index):
		return {}
	points[index] = position
	if multi:
		var center := center()
		var span := span()
		var zoom := span / _last_span if _last_span > 0.0 and span > 0.0 else 1.0
		var result := {"kind": PINCH, "center": center, "pan": center - _last_center, "zoom": zoom}
		_last_center = center
		_last_span = span
		return result
	if index != primary:
		return {}
	if not moved and position.distance_to(start) > TAP_SLOP:
		moved = true
	return {"kind": DRAG, "position": position, "moved": moved}


func release(index: int, position: Vector2, time: float = now()) -> Dictionary:
	if not points.has(index):
		return {}
	points.erase(index)
	if multi:
		if points.is_empty():
			multi = false
			primary = -1
			return {"kind": MULTI_END}
		_reset_pinch()
		return {}
	if index != primary:
		return {}
	primary = -1
	var was_double := double
	double = false
	if not moved and not was_double:
		_last_tap_time = time
		_last_tap_position = position
	return {"kind": DRAG_END if moved else TAP, "position": position, "double": was_double}


func cancel() -> void:
	points.clear()
	primary = -1
	moved = false
	multi = false
	double = false


static func now() -> float:
	return Time.get_ticks_msec() / 1000.0


func is_active() -> bool:
	return not points.is_empty()


func center() -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var sum := Vector2.ZERO
	for value: Vector2 in points.values():
		sum += value
	return sum / points.size()


func span() -> float:
	if points.size() < 2:
		return 0.0
	var values := points.values()
	return (values[0] as Vector2).distance_to(values[1])


func _reset_pinch() -> void:
	_last_center = center()
	_last_span = span()
