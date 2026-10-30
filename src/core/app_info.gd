class_name AppInfo
extends RefCounted

const PRIVACY_POLICY_URL := ""
const VERSION_SETTING := "application/config/version"
const SECURE_SCHEME := "https://"
const CODE_MAJOR := 10000
const CODE_MINOR := 100
const VERSION_PARTS := 3


static func version() -> String:
	return str(ProjectSettings.get_setting(VERSION_SETTING, ""))


static func version_code(name: String) -> int:
	var parts := name.split(".")
	if parts.size() != VERSION_PARTS:
		return 0
	var numbers: Array[int] = []
	for part in parts:
		if not part.is_valid_int() or int(part) < 0:
			return 0
		numbers.append(int(part))
	if numbers[1] >= CODE_MINOR or numbers[2] >= CODE_MINOR:
		return 0
	return numbers[0] * CODE_MAJOR + numbers[1] * CODE_MINOR + numbers[2]


static func privacy_url(url: String = PRIVACY_POLICY_URL) -> String:
	var trimmed := url.strip_edges()
	if not trimmed.begins_with(SECURE_SCHEME) or trimmed.length() <= SECURE_SCHEME.length() or trimmed.contains(" "):
		return ""
	return trimmed
