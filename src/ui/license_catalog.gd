class_name LicenseCatalog
extends RefCounted

const GEIST := "geist"
const MATERIAL_ICONS := "material_icons"
const GODOT := "godot"
const GODOT_PARTS := "godot_parts"
const ANDROID_LIBRARIES := "android_libraries"
const APACHE_LICENSE := "Apache-2.0"
const LICENSE_PREFIX := "license:"
const FILES := {
	GEIST: "res://assets/fonts/OFL.txt",
	MATERIAL_ICONS: "res://assets/fonts/MaterialIcons-LICENSE.txt",
}


static func entries() -> Array[Dictionary]:
	var list: Array[Dictionary] = [
		_entry(GEIST, Texts.t("ABOUT_LIB_GEIST"), Texts.t("ABOUT_LIB_GEIST_INFO")),
		_entry(MATERIAL_ICONS, Texts.t("ABOUT_LIB_ICONS"), Texts.t("ABOUT_LIB_ICONS_INFO")),
		_entry(GODOT, Texts.t("ABOUT_LIB_GODOT"), Texts.t("ABOUT_LIB_GODOT_INFO")),
		_entry(GODOT_PARTS, Texts.t("ABOUT_LIB_GODOT_PARTS"), Texts.format("ABOUT_LIB_GODOT_PARTS_INFO", [Engine.get_copyright_info().size()])),
		_entry(ANDROID_LIBRARIES, Texts.t("ABOUT_LIB_ANDROID"), Texts.t("ABOUT_LIB_ANDROID_INFO")),
	]
	for name in license_names():
		list.append(_entry(LICENSE_PREFIX + name, name, Texts.t("ABOUT_LICENSE_TEXT_INFO")))
	return list


static func license_names() -> Array[String]:
	var names: Array[String] = []
	for name: Variant in Engine.get_license_info():
		names.append(str(name))
	names.sort()
	return names


static func _entry(id: String, title: String, info: String) -> Dictionary:
	return {"id": id, "title": title, "info": info}


static func text(id: String) -> String:
	if FILES.has(id):
		return FileAccess.get_file_as_string(FILES[id]).strip_edges()
	if id == GODOT:
		return Engine.get_license_text().strip_edges()
	if id == GODOT_PARTS:
		return components()
	if id == ANDROID_LIBRARIES:
		return engine_license(APACHE_LICENSE)
	if id.begins_with(LICENSE_PREFIX):
		return engine_license(id.trim_prefix(LICENSE_PREFIX))
	return ""


static func engine_license(name: String) -> String:
	return str(Engine.get_license_info().get(name, "")).strip_edges()


static func components() -> String:
	var blocks := PackedStringArray()
	for component: Dictionary in Engine.get_copyright_info():
		var holders := PackedStringArray()
		var licenses := PackedStringArray()
		for part: Dictionary in component.get("parts", []):
			for holder: Variant in part.get("copyright", []):
				if not holders.has(str(holder)):
					holders.append(str(holder))
			if not licenses.has(str(part.get("license", ""))):
				licenses.append(str(part.get("license", "")))
		var lines := PackedStringArray([str(component.get("name", ""))])
		for holder in holders:
			lines.append(Texts.format("ABOUT_COMPONENT_COPYRIGHT", [holder]))
		lines.append(Texts.format("ABOUT_COMPONENT_LICENSE", [", ".join(licenses)]))
		blocks.append("\n".join(lines))
	return "\n\n".join(blocks)
