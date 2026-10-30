class_name Progress
extends RefCounted

const DEFAULT_PATH := "user://progress.json"
const VERSION := 2
const LEGACY_VERSION := 1
const MAX_STARS := 3
const MAX_BYTES := 1048576
const MAX_NUMBER := 1e15
const MAX_RETAINED := 256
const MAX_ID_LENGTH := 48

var path: String
var regions := {}
var techs: Array[String] = []
var location := 0
var total_kills := 0
var best_combo := 0
var seen: Array[String] = []
var _retained := {}


func _init(p_path: String = DEFAULT_PATH) -> void:
	path = p_path


func load_progress() -> Progress:
	var data: Variant = SafeFile.read_json(path, MAX_BYTES)
	if data is Dictionary:
		apply(data)
	return self


static func _int(value: Variant) -> int:
	if value is int:
		return value
	if value is float and is_finite(value):
		return int(clampf(value, -MAX_NUMBER, MAX_NUMBER))
	if value is String and value.is_valid_float():
		return _int(value.to_float())
	return 0


func apply(data: Dictionary) -> void:
	regions = {}
	_retained = {}
	techs = []
	location = 0
	total_kills = 0
	best_combo = 0
	seen = []
	var version := _int(data.get("version", 0))
	if version == LEGACY_VERSION:
		_apply_legacy(data)
	elif version == VERSION:
		_apply_current(data)
	else:
		return
	total_kills = maxi(_int(data.get("total_kills", 0)), 0)
	best_combo = maxi(_int(data.get("best_combo", 0)), 0)


func _apply_legacy(data: Dictionary) -> void:
	var stored: Variant = data.get("stars", {})
	if not stored is Dictionary:
		return
	for id: Variant in stored:
		var index := GameConfig.level_index(str(id))
		if index >= 0 and _int(stored[id]) > 0:
			mark_conquered(index)
			location = maxi(location, index)


func _apply_current(data: Dictionary) -> void:
	var stored: Variant = data.get("regions", {})
	if stored is Dictionary:
		for id: Variant in stored:
			var index := GameConfig.level_index(str(id))
			if not stored[id] is Dictionary:
				continue
			if index >= 0:
				regions[str(id)] = _sanitize_region(index, stored[id])
			elif _retained.size() < MAX_RETAINED and str(id).length() <= MAX_ID_LENGTH:
				_retained[str(id)] = _sanitize_retained(stored[id])
	var owned: Variant = data.get("techs", [])
	if owned is Array:
		for id: Variant in owned:
			if GameConfig.TECHS.has(str(id)) and not techs.has(str(id)):
				techs.append(str(id))
	_prune_techs()
	if spent_points() > earned_points():
		techs = []
	var located := GameConfig.level_index(str(data.get("location_id", "")))
	location = located if located >= 0 else clampi(_int(data.get("location", 0)), 0, GameConfig.level_count() - 1)
	seen = _sanitize_seen(data.get("seen", []))


static func _sanitize_seen(raw: Variant) -> Array[String]:
	var result: Array[String] = []
	if not raw is Array:
		return result
	var known := GameConfig.enemy_kinds()
	for kind: Variant in raw:
		if known.has(str(kind)) and not result.has(str(kind)):
			result.append(str(kind))
	return result


func _prune_techs() -> void:
	var pruned := true
	while pruned:
		pruned = false
		for id in techs.duplicate():
			if not TechTree.missing(self, id).is_empty():
				techs.erase(id)
				pruned = true


static func _sanitize_region(index: int, raw: Dictionary) -> Dictionary:
	var done: Array[String] = []
	var stored: Variant = raw.get("done", [])
	if stored is Array:
		var valid := Challenges.ids(index)
		for id: Variant in stored:
			if valid.has(str(id)) and not done.has(str(id)):
				done.append(str(id))
	var flag: Variant = raw.get("conquered", false)
	var conquered: bool = (flag is bool and flag) or done.has(Challenges.CONQUER)
	if conquered and not done.has(Challenges.CONQUER):
		done.push_front(Challenges.CONQUER)
	return {
		"conquered": conquered,
		"stars": clampi(_int(raw.get("stars", 0)), 0, MAX_STARS),
		"best_days": maxi(_int(raw.get("best_days", 0)), 0),
		"done": done,
	}


static func _sanitize_retained(raw: Dictionary) -> Dictionary:
	var done: Array[String] = []
	var stored: Variant = raw.get("done", [])
	if stored is Array:
		for id: Variant in stored.slice(0, MAX_RETAINED):
			if id is String and id.length() <= MAX_ID_LENGTH and not done.has(id):
				done.append(id)
	var flag: Variant = raw.get("conquered", false)
	return {
		"conquered": flag is bool and flag,
		"stars": clampi(_int(raw.get("stars", 0)), 0, MAX_STARS),
		"best_days": maxi(_int(raw.get("best_days", 0)), 0),
		"done": done,
	}


func to_dict() -> Dictionary:
	var stored := _retained.duplicate(true)
	stored.merge(regions.duplicate(true), true)
	return {"version": VERSION, "regions": stored, "techs": techs.duplicate(), "location": location, "location_id": str(GameConfig.level(location).id),
		"total_kills": total_kills, "best_combo": best_combo, "seen": seen.duplicate()}


func save() -> bool:
	return SafeFile.write_text(path, JSON.stringify(to_dict()))


func _region(index: int) -> Dictionary:
	if index < 0 or index >= GameConfig.level_count():
		return GameConfig.EMPTY
	return regions.get(GameConfig.level(index).id, GameConfig.EMPTY)


func _writable(index: int) -> Dictionary:
	var id := str(GameConfig.level(index).id)
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


func reset_all() -> void:
	regions = {}
	_retained = {}
	techs = []
	location = 0
	total_kills = 0
	best_combo = 0
	seen = []
	SafeFile.remove(path)


func arsenal() -> Arsenal:
	return Arsenal.from_techs(techs)


func mark_seen(kind: String) -> bool:
	if seen.has(kind) or GameConfig.enemy(kind).is_empty():
		return false
	seen.append(kind)
	return true


func has_seen(kind: String) -> bool:
	return seen.has(kind)


func seen_count() -> int:
	var count := 0
	for kind: String in GameConfig.enemy_kinds():
		if seen.has(kind):
			count += 1
	return count


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
