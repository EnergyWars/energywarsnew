extends GutTest

const LOCALES: Array[String] = ["en", "de"]


func after_all() -> void:
	TranslationServer.set_locale("en")


func _keys() -> Array[String]:
	var keys: Array[String] = ["APP_TITLE", "MENU_TAGLINE", "COMBO_LABEL", "LANGUAGE_AUTO", "LANGUAGE_DE", "LANGUAGE_EN"]
	for kind: String in GameConfig.BUILDINGS:
		keys.append("BUILDING_%s" % kind.to_upper())
		keys.append("BUILDING_%s_INFO" % kind.to_upper())
	for kind in GameConfig.BUILD_ORDER:
		keys.append("BUILDING_%s_SHORT" % kind.to_upper())
	for kind: String in GameConfig.ENEMIES:
		keys.append("ENEMY_%s" % kind.to_upper())
	for track: String in GameConfig.TRACKS:
		keys.append("TRACK_%s" % track.to_upper())
	for level: Dictionary in GameConfig.LEVELS:
		keys.append("LEVEL_%s" % str(level.id).to_upper())
		keys.append("LEVEL_%s_INFO" % str(level.id).to_upper())
	for code in [BuildRules.INVALID, BuildRules.LOCKED, BuildRules.MONEY, BuildRules.BOUNDS, BuildRules.BLOCKED, BuildRules.OVERLAP, BuildRules.ENEMY_NEAR, BuildRules.TOO_FAR]:
		keys.append("REASON_BUILD_%s" % code.to_upper())
	for code in [EnergyNetwork.MISSING, EnergyNetwork.SAME, EnergyNetwork.NO_SEND, EnergyNetwork.NO_RECEIVE, EnergyNetwork.EXISTS, EnergyNetwork.FULL, EnergyNetwork.RANGE]:
		keys.append("REASON_LINK_%s" % code.to_upper())
	for tier in GameConfig.COMBO_TIERS.size():
		keys.append("COMBO_TIER_%d" % (tier + 1))
	for step in Tutorial.ORDER:
		keys.append("TUTORIAL_%s" % step.to_upper())
	return keys


func test_all_dynamic_keys_are_translated() -> void:
	for locale in LOCALES:
		TranslationServer.set_locale(locale)
		for key in _keys():
			assert_ne(Texts.t(key), key, "%s %s" % [locale, key])


func test_german_differs_where_expected() -> void:
	TranslationServer.set_locale("de")
	assert_eq(Texts.building_name(GameConfig.BATTERY), "Energiespeicher")
	assert_eq(Texts.track_name(GameConfig.TRACK_POWER, GameConfig.SHIELD), "Schildstärke")
	assert_eq(Texts.track_name(GameConfig.TRACK_POWER, GameConfig.ZAPPER), "Schaden")
	assert_eq(Texts.format("HUD_DAY", [3]), "Tag 3")
	assert_eq(Texts.reason("build_money"), "Nicht genug Geld!")
	assert_eq(Texts.level_name(0), "Erstes Licht")
	assert_ne(Texts.level_info(0), "")
	assert_eq(Texts.enemy_name("crawler"), "Krabbler")
	assert_eq(Texts.combo_title(99), Texts.t("COMBO_TIER_7"))
	assert_eq(Texts.tutorial(Tutorial.CUT), Texts.t("TUTORIAL_CUT"))
	TranslationServer.set_locale("en")
	assert_eq(Texts.building_name(GameConfig.BATTERY), "Storage")
