class_name Challenges
extends RefCounted

const CONQUER := "conquer"
const CORE := "core"
const LOST := "lost"
const DAYS := "days"
const COMBO := "combo"
const SURVIVE := "survive"
const TYPES: Array[String] = [CONQUER, CORE, LOST, DAYS, COMBO, SURVIVE]
const CONQUER_POINTS := 2
const DEFAULT_POINTS := 1


static func of_level(index: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = [{"id": CONQUER, "value": 0, "points": CONQUER_POINTS}]
	for entry: Array in GameConfig.level(index).get("challenges", GameConfig.EMPTY_LIST):
		result.append({"id": str(entry[0]), "value": int(entry[1]), "points": DEFAULT_POINTS})
	return result


static func ids(index: int) -> Array[String]:
	var result: Array[String] = []
	for challenge in of_level(index):
		result.append(str(challenge.id))
	return result


static func find(index: int, id: String) -> Dictionary:
	for challenge in of_level(index):
		if challenge.id == id:
			return challenge
	return GameConfig.EMPTY


static func points(index: int, completed: Array) -> int:
	var total := 0
	for challenge in of_level(index):
		if completed.has(challenge.id):
			total += int(challenge.points)
	return total


static func max_points() -> int:
	var total := 0
	for index in GameConfig.level_count():
		total += points(index, ids(index))
	return total


static func completed(state: BattleState) -> Array[String]:
	var result: Array[String] = []
	for challenge in of_level(state.level_index):
		if is_met(challenge, state):
			result.append(str(challenge.id))
	return result


static func is_met(challenge: Dictionary, state: BattleState) -> bool:
	var value := int(challenge.get("value", 0))
	if str(challenge.id) == SURVIVE:
		return state.is_survival() and state.days_survived >= value
	if state.is_survival() or state.phase != BattleState.Phase.WON:
		return false
	match str(challenge.id):
		CONQUER:
			return true
		CORE:
			return state.core_ratio() * 100.0 >= value
		LOST:
			return state.lost <= value
		DAYS:
			return state.round_number <= value
		COMBO:
			return state.best_combo >= value
	return false
