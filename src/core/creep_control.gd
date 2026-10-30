class_name CreepControl
extends RefCounted

var state: BattleState
var events: BattleEvents
var _scan := 0.0
var _refresh := 0.0


func _init(p_state: BattleState, p_events: BattleEvents) -> void:
	state = p_state
	events = p_events


func update(delta: float) -> void:
	var creep := state.creep
	if creep.nests.is_empty():
		return
	_scan -= delta
	if _scan <= 0.0:
		_scan = GameConfig.CREEP_SCAN
		strike()
	creep.recede(delta)
	_refresh -= delta
	if _refresh <= 0.0:
		_refresh = GameConfig.CREEP_REFRESH
		creep.flush()


func strike() -> int:
	var killed := 0
	var towers := _shooters()
	if towers.is_empty():
		return 0
	for nest in state.creep.alive_nests():
		if _reached(nest, towers) and state.creep.kill(nest):
			killed += 1
			events.emit("nest_killed", {"id": nest.id, "position": nest.position, "left": state.creep.alive_nests().size()})
	return killed


func reaches(nest: CreepNest, tower: Building) -> bool:
	var reach := Formulas.attack_range(tower) + GameConfig.CREEP_REACH * GameConfig.CELL
	return tower.position.distance_to(nest.position) <= reach


func _reached(nest: CreepNest, towers: Array[Building]) -> bool:
	for tower in towers:
		if reaches(nest, tower):
			return true
	return false


func _shooters() -> Array[Building]:
	var result: Array[Building] = []
	for building in state.combatants():
		if building.is_player() and building.armed:
			result.append(building)
	return result
