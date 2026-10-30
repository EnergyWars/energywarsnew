class_name SafeFile
extends RefCounted

const TEMP_SUFFIX := ".tmp"


static func temp_path(path: String) -> String:
	return path + TEMP_SUFFIX


static func write_text(path: String, text: String) -> bool:
	var temp := temp_path(path)
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	var stored := file.store_string(text)
	file.flush()
	stored = stored and file.get_error() == OK
	file.close()
	if not stored or DirAccess.rename_absolute(temp, path) != OK:
		DirAccess.remove_absolute(temp)
		return false
	return true


static func remove(path: String) -> void:
	for target in [path, temp_path(path)]:
		if FileAccess.file_exists(target):
			DirAccess.remove_absolute(target)


static func read_json(path: String, max_bytes: int) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > max_bytes:
		return null
	var json := JSON.new()
	return json.data if json.parse(file.get_as_text()) == OK else null
