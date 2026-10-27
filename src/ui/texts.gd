class_name Texts
extends RefCounted


static func t(key: String) -> String:
	return String(TranslationServer.translate(key))


static func building_name(kind: String) -> String:
	return t("BUILDING_%s" % kind.to_upper())


static func building_info(kind: String) -> String:
	return t("BUILDING_%s_INFO" % kind.to_upper())


static func enemy_name(kind: String) -> String:
	return t("ENEMY_%s" % kind.to_upper())


static func track_name(track: String, kind: String) -> String:
	var specific := "TRACK_%s_%s" % [track.to_upper(), kind.to_upper()]
	var text := t(specific)
	return text if text != specific else t("TRACK_%s" % track.to_upper())


static func reason(code: String) -> String:
	return t("REASON_%s" % code.to_upper())


static func level_name(index: int) -> String:
	return t("LEVEL_%s" % str(GameConfig.level(index).id).to_upper())


static func level_info(index: int) -> String:
	return t("LEVEL_%s_INFO" % str(GameConfig.level(index).id).to_upper())


static func combo_title(tier: int) -> String:
	return t("COMBO_TIER_%d" % clampi(tier, 1, GameConfig.COMBO_TIERS.size()))


static func tutorial(step: String) -> String:
	return t("TUTORIAL_%s" % step.to_upper())


static func format(key: String, values: Array) -> String:
	return t(key) % values
