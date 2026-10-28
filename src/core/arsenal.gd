class_name Arsenal
extends RefCounted

var money_bonus := 0
var _unlocked := {}
var _boosts := {}


func _init() -> void:
	for kind in GameConfig.STARTER_KINDS:
		_unlocked[kind] = true


static func from_techs(ids: Array) -> Arsenal:
	var arsenal := Arsenal.new()
	for id: Variant in ids:
		arsenal.apply(str(id))
	return arsenal


static func everything() -> Arsenal:
	return from_techs(GameConfig.TECHS.keys())


func apply(id: String) -> void:
	var tech := GameConfig.tech(id)
	if tech.has("unlock"):
		_unlocked[str(tech.unlock)] = true
	if tech.has("money"):
		money_bonus += int(tech.money)
	if tech.has("boost"):
		for kind in targets(str(tech.kind)):
			_add_boost(kind, str(tech.boost), float(tech.value))


static func targets(scope: String) -> Array[String]:
	var result: Array[String] = []
	for kind: String in GameConfig.BUILDINGS:
		if int(GameConfig.BUILDINGS[kind].team) != GameConfig.TEAM_PLAYER:
			continue
		if scope == GameConfig.ALL_BUILDINGS or kind == scope or (scope == GameConfig.ALL_TOWERS and GameConfig.is_tower(kind)):
			result.append(kind)
	return result


func _add_boost(kind: String, boost: String, value: float) -> void:
	if not _boosts.has(kind):
		_boosts[kind] = {}
	_boosts[kind][boost] = float(_boosts[kind].get(boost, 1.0)) + value


func has(kind: String) -> bool:
	return _unlocked.has(kind)


func kinds() -> Array[String]:
	var result: Array[String] = []
	for kind in GameConfig.BUILD_ORDER:
		if has(kind):
			result.append(kind)
	return result


func boosts_for(kind: String) -> Dictionary:
	return _boosts.get(kind, GameConfig.EMPTY)


func boost(kind: String, name: String) -> float:
	return float(boosts_for(kind).get(name, 1.0))
