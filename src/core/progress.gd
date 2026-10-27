class_name Progress
extends RefCounted

const DEFAULT_PATH := "user://progress.json"
const VERSION := 1
const MAX_STARS := 3

var path: String
var stars := {}
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
	stars = {}
	total_kills = 0
	best_combo = 0
	if int(data.get("version", 0)) != VERSION:
		return
	var stored: Variant = data.get("stars", {})
	if stored is Dictionary:
		for id: Variant in stored:
			if _level_index(str(id)) >= 0:
				stars[str(id)] = clampi(int(stored[id]), 0, MAX_STARS)
	total_kills = maxi(int(data.get("total_kills", 0)), 0)
	best_combo = maxi(int(data.get("best_combo", 0)), 0)


func to_dict() -> Dictionary:
	return {"version": VERSION, "stars": stars.duplicate(), "total_kills": total_kills, "best_combo": best_combo}


func save() -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(to_dict()))
	file.close()
	return true


static func _level_index(id: String) -> int:
	for i in GameConfig.level_count():
		if GameConfig.LEVELS[i].id == id:
			return i
	return -1


func stars_for(index: int) -> int:
	if index < 0 or index >= GameConfig.level_count():
		return 0
	return int(stars.get(GameConfig.LEVELS[index].id, 0))


func is_unlocked(index: int) -> bool:
	if index < 0 or index >= GameConfig.level_count():
		return false
	return index == 0 or stars_for(index - 1) > 0


func total_stars() -> int:
	var total := 0
	for value: int in stars.values():
		total += value
	return total


func next_level() -> int:
	for i in GameConfig.level_count():
		if is_unlocked(i) and stars_for(i) == 0:
			return i
	return GameConfig.level_count() - 1


func record(index: int, result_stars: int, kills: int, combo: int) -> bool:
	total_kills += maxi(kills, 0)
	best_combo = maxi(best_combo, combo)
	if index < 0 or index >= GameConfig.level_count():
		return false
	var improved := result_stars > stars_for(index)
	if improved:
		stars[GameConfig.LEVELS[index].id] = clampi(result_stars, 0, MAX_STARS)
	return improved
