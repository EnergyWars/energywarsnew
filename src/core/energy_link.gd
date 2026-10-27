class_name EnergyLink
extends RefCounted

var source: int
var target: int
var flow := 0.0


func _init(p_source: int, p_target: int) -> void:
	source = p_source
	target = p_target


func key() -> String:
	return key_of(source, target)


static func key_of(from_id: int, to_id: int) -> String:
	return "%d>%d" % [from_id, to_id]
