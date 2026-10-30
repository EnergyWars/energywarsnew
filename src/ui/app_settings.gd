class_name AppSettings
extends RefCounted

const DEFAULT_PATH := "user://settings.json"
const LEGACY_PATH := "user://settings.cfg"
const MAX_BYTES := 65536
const LEGACY_KEYS: Array[String] = ["locale", "sound", "haptics"]
const LOCALES: Array[String] = ["", "de", "en"]
const FALLBACK_LOCALE := "en"

var path: String
var legacy_path: String
var locale := ""
var sound := true
var haptics := true


func _init(p_path: String = DEFAULT_PATH, p_legacy_path: String = "") -> void:
	path = p_path
	legacy_path = p_legacy_path if not p_legacy_path.is_empty() else (LEGACY_PATH if p_path == DEFAULT_PATH else "")


func load_settings() -> AppSettings:
	if FileAccess.file_exists(path):
		_apply(SafeFile.read_json(path, MAX_BYTES))
	elif not legacy_path.is_empty() and FileAccess.file_exists(legacy_path):
		var legacy := FileAccess.open(legacy_path, FileAccess.READ)
		if legacy != null and legacy.get_length() <= MAX_BYTES:
			_apply(parse_legacy(legacy.get_as_text()))
	return self


func _apply(data: Variant) -> void:
	if not data is Dictionary:
		return
	var stored: Variant = data.get("locale", "")
	locale = stored if stored is String and LOCALES.has(stored) else ""
	sound = _flag(data.get("sound", true))
	haptics = _flag(data.get("haptics", true))


static func parse_legacy(text: String) -> Dictionary:
	var result := {}
	for line in text.split("\n"):
		var parts := line.split("=", true, 1)
		if parts.size() != 2 or not LEGACY_KEYS.has(parts[0].strip_edges()):
			continue
		var key := parts[0].strip_edges()
		var value := parts[1].strip_edges()
		if value == "true" or value == "false":
			result[key] = value == "true"
		elif value.length() >= 2 and value.begins_with("\"") and value.ends_with("\"") and LOCALES.has(value.substr(1, value.length() - 2)):
			result[key] = value.substr(1, value.length() - 2)
	return result


static func _flag(value: Variant) -> bool:
	return value if value is bool else true


func save() -> void:
	if SafeFile.write_text(path, JSON.stringify({"locale": locale, "sound": sound, "haptics": haptics})) and not legacy_path.is_empty():
		SafeFile.remove(legacy_path)


func set_locale(value: String) -> void:
	locale = value if LOCALES.has(value) else ""
	save()
	apply()


func set_sound(value: bool) -> void:
	sound = value
	save()


func set_haptics(value: bool) -> void:
	haptics = value
	save()


func resolved_locale() -> String:
	if not locale.is_empty():
		return locale
	var system := OS.get_locale_language()
	return system if LOCALES.has(system) else FALLBACK_LOCALE


func apply() -> void:
	TranslationServer.set_locale(resolved_locale())
