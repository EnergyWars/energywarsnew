class_name BattleEvents
extends RefCounted

var _queue: Array[Dictionary] = []


func emit(type: String, data: Dictionary = {}) -> void:
	var event := data.duplicate()
	event["type"] = type
	_queue.append(event)


func drain() -> Array[Dictionary]:
	var result := _queue
	_queue = []
	return result


func pending() -> int:
	return _queue.size()


func peek() -> Array[Dictionary]:
	return _queue
