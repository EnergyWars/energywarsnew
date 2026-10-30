extends RefCounted

const MARK := "security_probe_created"


func _init() -> void:
	Engine.set_meta(MARK, true)
