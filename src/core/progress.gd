class_name Progress
extends RefCounted

const DEFAULT_PATH := "user://progress.json"
const VERSION := 2
const LEGACY_VERSION := 1
const MAX_STARS := 3

var path: String
var regions := {}
var techs: Array[String] = []
var location := 0
var total_kills := 0
var best_combo := 0


func _init(p_path: String = DEFAULT_PATH) -> void:
	path = p_path


func load_progress() -> Progress:
	if not FileAccess.file_exists(path):
		return self
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) == OK and json.data is Dictionary:
		apply(json.data)
	return self


func apply(data: Dictionary) -> void:
	regions = {}
	techs = []
	location = 0
	total_kills = 0
	best_combo = 0
	var version := int(data.get("version", 0))
	if version == LEGACY_VERSION:
		_apply_legacy(data)
	elif version == VERSION:
		_apply_current(data)
	else:
		return
	total_kills = maxi(int(data.get("total_kills", 0)), 0)
	best_combo = maxi(int(data.get("best_combo", 0)), 0)


func _apply_legacy(data: Dictionary) -> void:
	var stored: Variant = data.get("stars", {})
	if not stored is Dictionary:
		return
	for id: Variant in stored:
		var index := GameConfig.level_index(str(id))
		if index >= 0 and int(stored[id]) > 0:
			mark_conquered(index)
			location = maxi(location, index)


func _apply_current(data: Dictionary) -> void:
	var stored: Variant = data.get("regions", {})
	if stored is Dictionary:
		for id: Variant in stored:
			var index := GameConfig.level_index(str(id))
			if index >= 0 and stored[id] is Dictionary:
				regions[str(id)] = _sanitize_region(index, stored[id])
	var owned: Variant = data.get("techs", [])
	if owned is Array:
		for id: Variant in owned:
			if GameConfig.TECHS.has(str(id)) and not techs.has(str(id)):
				techs.append(str(id))
	if spent_points() > earned_points():
		techs = []
	location = clampi(int(data.get("location", 0)), 0, GameConfig.level_count() - 1)


static func _sanitize_region(index: int, raw: Dictionary) -> Dictionary:
	var done: Array[String] = []
	var stored: Variant = raw.get("done", [])
	if stored is Array:
		var valid := Challenges.ids(index)
		for id: Variant in stored:
			if valid.has(str(id)) and not done.has(str(id)):
				done.append(str(id))
	var conquered: Variant = raw.get("conquered", false)
	return {
		"conquered": (conquered is bool and conquered) or done.has(Challenges.CONQUER),
		"stars": clampi(int(raw.get("stars", 0)), 0, MAX_STARS),
		"best_days": maxi(int(raw.get("best_days", 0)), 0),
		"done": done,
	}


func to_dict() -> Dictionary:
	return {"version": VERSION, "regions": regions.duplicate(true), "techs": techs.duplicate(), "location": location,
		"total_kills": total_kills, "best_combo": best_combo}


func save() -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(to_dict()))
	file.close()
	return true


func _region(index: int) -> Dictionary:
	if index < 0 or index >= GameConfig.level_count():
		return GameConfig.EMPTY
	return regions.get(GameConfig.LEVELS[index].id, GameConfig.EMPTY)


func _writable(index: int) -> Dictionary:
	var id := str(GameConfig.LEVELS[index].id)
	if not regions.has(id):
		regions[id] = {"conquered": false, "stars": 0, "best_days": 0, "done": [] as Array[String]}
	return regions[id]


func mark_conquered(index: int) -> void:
	if index < 0 or index >= GameConfig.level_count():
		return
	var region := _writable(index)
	region.conquered = true
	if not region.done.has(Challenges.CONQUER):
		region.done.append(Challenges.CONQUER)


func is_conquered(index: int) -> bool:
	return bool(_region(index).get("conquered", false))


func stars_for(index: int) -> int:
	return int(_region(index).get("stars", 0))


func best_days(index: int) -> int:
	return int(_region(index).get("best_days", 0))


func completed(index: int) -> Array:
	return _region(index).get("done", GameConfig.EMPTY_LIST)


func is_done(index: int, challenge: String) -> bool:
	return completed(index).has(challenge)


func conquered_count() -> int:
	var count := 0
	for index in GameConfig.level_count():
		if is_conquered(index):
			count += 1
	return count


func total_stars() -> int:
	var total := 0
	for index in GameConfig.level_count():
		total += stars_for(index)
	return total


func earned_points() -> int:
	var total := 0
	for index in GameConfig.level_count():
		total += Challenges.points(index, completed(index))
	return total


func spent_points() -> int:
	return TechTree.total_cost(techs)


func skill_points() -> int:
	return earned_points() - spent_points()


func has_tech(id: String) -> bool:
	return techs.has(id)


func reset_techs() -> int:
	var refund := spent_points()
	techs = []
	return refund


func arsenal() -> Arsenal:
	return Arsenal.from_techs(techs)


func record(report: BattleReport) -> BattleReport:
	total_kills += maxi(report.kills, 0)
	best_combo = maxi(best_combo, report.combo)
	var index := report.level_index
	if index < 0 or index >= GameConfig.level_count():
		return report
	var region := _writable(index)
	report.first_conquest = not report.survival and report.won and not bool(region.conquered)
	if report.first_conquest:
		region.conquered = true
		location = index
	report.new_challenges = []
	for id in report.completed:
		if not region.done.has(id):
			region.done.append(id)
			report.new_challenges.append(id)
	report.points = Challenges.points(index, report.new_challenges)
	if report.is_endless():
		report.improved = report.days > int(region.best_days)
		region.best_days = maxi(int(region.best_days), report.days)
	elif report.survival:
		report.improved = report.stars > int(region.stars)
		region.stars = maxi(int(region.stars), report.stars)
		region.best_days = maxi(int(region.best_days), report.days)
	return report
