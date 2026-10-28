class_name TechTree
extends RefCounted

const OK := ""
const UNKNOWN := "unknown"
const OWNED := "owned"
const REQUIRES := "requires"
const POINTS := "points"


static func ids() -> Array[String]:
	var result: Array[String] = []
	for id: String in GameConfig.TECHS:
		result.append(id)
	return result


static func of_branch(branch: String) -> Array[String]:
	var result: Array[String] = []
	for id: String in GameConfig.TECHS:
		if GameConfig.TECHS[id].branch == branch:
			result.append(id)
	return result


static func cost(id: String) -> int:
	return int(GameConfig.tech(id).get("cost", 0))


static func requirements(id: String) -> Array[String]:
	var result: Array[String] = []
	for required: Variant in GameConfig.tech(id).get("requires", GameConfig.EMPTY_LIST):
		result.append(str(required))
	return result


static func missing(progress: Progress, id: String) -> Array[String]:
	var result: Array[String] = []
	for required in requirements(id):
		if not progress.has_tech(required):
			result.append(required)
	return result


static func total_cost(owned: Array) -> int:
	var total := 0
	for id: Variant in owned:
		total += cost(str(id))
	return total


static func reason(progress: Progress, id: String) -> String:
	if not GameConfig.TECHS.has(id):
		return UNKNOWN
	if progress.has_tech(id):
		return OWNED
	if not missing(progress, id).is_empty():
		return REQUIRES
	if progress.skill_points() < cost(id):
		return POINTS
	return OK


static func buy(progress: Progress, id: String) -> String:
	var result := reason(progress, id)
	if result == OK:
		progress.techs.append(id)
	return result


static func unlocked_kind(id: String) -> String:
	return str(GameConfig.tech(id).get("unlock", ""))
