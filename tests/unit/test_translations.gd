extends GutTest

const LOCALES: Array[String] = ["en", "de"]


func after_all() -> void:
	TranslationServer.set_locale("en")


func _keys() -> Array[String]:
	var keys: Array[String] = ["APP_TITLE", "MENU_TAGLINE", "COMBO_LABEL", "LANGUAGE_AUTO", "LANGUAGE_DE", "LANGUAGE_EN",
		"HUD_PLAN", "HUD_PLAN_CARD", "HUD_START", "HUD_DAY_WAVE", "HUD_MOP_UP", "BANNER_ROUND_SUB", "BANNER_NIGHT_OVER",
		"BANNER_NIGHT_OVER_SUB", "BANNER_ROUND_CLEARED", "BANNER_ROUND_CLEARED_SUB", "TOAST_NIGHT_WAVE", "PANEL_LEVEL",
		"PANEL_RELOCATE_FREE", "PANEL_INFO", "STAT_CRIT"]
	for kind: String in GameConfig.BUILDINGS:
		keys.append("BUILDING_%s" % kind.to_upper())
		keys.append("BUILDING_%s_INFO" % kind.to_upper())
		if GameConfig.BUILDINGS[kind].team == GameConfig.TEAM_PLAYER:
			keys.append("BUILDING_%s_DESC" % kind.to_upper())
	for kind in GameConfig.BUILD_ORDER:
		keys.append("BUILDING_%s_SHORT" % kind.to_upper())
	for key: String in [BuildBar.ALL, BuildBar.OTHER]:
		keys.append("BUILD_CATEGORY_%s" % key.to_upper())
	for entry: Dictionary in GameConfig.BUILD_CATEGORIES:
		keys.append("BUILD_CATEGORY_%s" % str(entry.key).to_upper())
	for kind: String in GameConfig.enemy_kinds():
		keys.append("ENEMY_%s" % kind.to_upper())
		keys.append("ENEMY_%s_DESC" % kind.to_upper())
	for track: String in GameConfig.TRACKS:
		keys.append("TRACK_%s" % track.to_upper())
	for level: Dictionary in GameConfig.levels():
		keys.append("LEVEL_%s" % str(level.id).to_upper())
		keys.append("LEVEL_%s_INFO" % str(level.id).to_upper())
	for code in [BuildRules.INVALID, BuildRules.LOCKED, BuildRules.MONEY, BuildRules.BOUNDS, BuildRules.BLOCKED, BuildRules.OVERLAP, BuildRules.ENEMY_NEAR, BuildRules.ENEMY_ZONE, BuildRules.TOO_FAR, BuildRules.SLIME]:
		keys.append("REASON_BUILD_%s" % code.to_upper())
	for code in [EnergyNetwork.MISSING, EnergyNetwork.SAME, EnergyNetwork.NO_SEND, EnergyNetwork.NO_RECEIVE, EnergyNetwork.EXISTS, EnergyNetwork.FULL, EnergyNetwork.RANGE]:
		keys.append("REASON_LINK_%s" % code.to_upper())
	for id: String in GameConfig.TECHS:
		keys.append("TECH_%s" % id.to_upper())
		keys.append("TECH_%s_INFO" % id.to_upper())
	for branch in GameConfig.BRANCHES:
		keys.append("BRANCH_%s" % branch.to_upper())
	for type in Challenges.TYPES:
		keys.append("CHALLENGE_%s" % type.to_upper())
	for key in ["RESULT_CONQUERED", "RESULT_CONQUERED_TEXT", "RESULT_SURVIVED", "RESULT_SURVIVED_TEXT", "RESULT_SURVIVAL_LOST_TEXT",
			"RESULT_ENDLESS", "RESULT_ENDLESS_TEXT", "RESULT_DEFEAT", "RESULT_DEFEAT_TEXT", "RESULT_DAYS", "RESULT_CHALLENGES", "RESULT_POINTS",
			"REGION_CONQUERED", "REGION_ENEMY", "REGION_LOCKED", "REGION_LOCKED_INFO", "REGION_ATTACK", "REGION_REPLAY", "REGION_SURVIVAL",
			"REGION_SURVIVAL_TITLE", "REGION_RECORD", "SURVIVAL_DAYS", "SURVIVAL_ENDLESS", "SKILL_POINTS", "SKILL_POINTS_GAIN", "WORLD_TAGLINE",
			"WORLD_LOCKED", "WORLD_TECH", "TECH_TITLE", "TECH_HINT", "TECH_BUY", "TECH_OWNED", "TECH_REQUIRES", "TECH_RESET", "TECH_RESET_TITLE",
			"TECH_RESET_TEXT", "TECH_RESET_CONFIRM", "HUD_DAY_OF", "BANNER_NIGHT_OVER_BURN", "TOAST_BOSS_BURNED"]:
		keys.append(key)
	for tier in GameConfig.COMBO_TIERS.size():
		keys.append("COMBO_TIER_%d" % (tier + 1))
	for step in Tutorial.ORDER:
		keys.append("TUTORIAL_%s" % step.to_upper())
	keys.append_array(["MAP_TITLE", "MAP_PENDING", "MAP_STRUCTURES", "MAP_SPAWNED"] as Array[String])
	keys.append_array(["BUILD_OPEN", "BUILD_ONCE", "BUILD_MULTI", "BUILD_CANCEL", "RESULT_CHECKPOINT", "TOAST_SCOUT_WALKS",
		"TOAST_PICK_FUEL", "TOAST_FUEL_EMPTY", "PANEL_LIGHT", "PANEL_LIGHT_VALUE", "PANEL_LIGHT_HINT", "PANEL_FUEL", "STAT_FUEL",
		"STAT_FUEL_TIME", "STAT_LIGHT_RADIUS", "STAT_LIGHT_RADIUS_VALUE", "STAT_LIGHT_DRAW", "STAT_LIGHT_STATE", "STAT_LIGHT_ON_VALUE", "STATUS_LINK_OUT",
		"STAT_LIGHT_OFF", "STAT_EXPORT_PROGRESS", "TRACK_EFFICIENCY_LAMP", "STAT_REPAIR", "STAT_REPAIR_DRAW", "REGION_CREATIVE",
		"REGION_CREATIVE_INFO", "CREATIVE_CLEAR", "TOAST_ENEMIES_CLEARED", "TOAST_CREEP_SPAWNED", "TOAST_NEST_KILLED", "CREATIVE_MONEY_ON",
		"CREATIVE_MONEY_OFF"] as Array[String])
	for code in [FuelControl.INVALID, FuelControl.NOT_TREE, FuelControl.RANGE, FuelControl.UNEXPLORED]:
		keys.append("REASON_FUEL_%s" % code.to_upper())
	for code in [ScoutControl.MISSING, ScoutControl.LANDING, ScoutControl.BOARDED, ScoutControl.NOTHING, ScoutControl.TOO_FAR]:
		keys.append("REASON_SCOUT_%s" % code.to_upper())
	for entry: Array in MapPanel.LEGEND:
		keys.append(str(entry[1]))
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
	assert_eq(Texts.format("HUD_START", [2]), "Tag 2 starten")
	assert_eq(Texts.track_name(GameConfig.TRACK_EFFICIENCY, GameConfig.ROVER), "Fahreffizienz")
	assert_eq(Texts.track_name(GameConfig.TRACK_EFFICIENCY, GameConfig.ZAPPER), "Effizienz")
	assert_eq(Texts.reason("build_money"), "Nicht genug Geld!")
	assert_eq(Texts.level_name(0), "Erstes Licht")
	assert_ne(Texts.level_info(0), "")
	assert_eq(Texts.enemy_name("crawler"), "Krabbler")
	assert_eq(Texts.combo_title(99), Texts.t("COMBO_TIER_7"))
	assert_eq(Texts.tech_name("laser"), "Laserturm")
	assert_eq(Texts.branch_name(GameConfig.BRANCH_ECONOMY), "Wirtschaft")
	assert_eq(Texts.challenge({"id": Challenges.SURVIVE, "value": 5}), "Überlebe 5 Tage im Survival")
	assert_eq(Texts.challenge({"id": Challenges.CORE, "value": 80}), "Erobere mit mindestens 80 % Kern")
	assert_eq(Texts.survival_target(10), "10 Tage")
	assert_eq(Texts.survival_target(0), "Endlos")
	assert_ne(Texts.tech_info("laser"), "TECH_LASER_INFO")
	assert_eq(Texts.format("HUD_DAY_WAVE", [Texts.format("HUD_DAY_OF", [2, 5]), 1, 9]), "Tag 2/5 · Welle 1/9")
	assert_eq(Texts.tutorial(Tutorial.CUT), Texts.t("TUTORIAL_CUT"))
	assert_eq(Texts.building_name(GameConfig.LAMP), "Lampe")
	assert_eq(Texts.building_name(GameConfig.WATER), "Wasserrad")
	assert_eq(Texts.track_name(GameConfig.TRACK_EFFICIENCY, GameConfig.LAMP), "Lichteffizienz")
	assert_eq(Texts.format("BUILD_CANCEL", [Texts.building_name(GameConfig.FIRE)]), "Abbrechen: Feuerstelle")
	assert_eq(Texts.t("BUILD_CATEGORY_ALL"), "Alle")
	assert_eq(Texts.format("PANEL_LIGHT_VALUE", [3.0, 3.31]), "3.0 Felder · 3.3/s")
	assert_eq(Texts.t("CREATIVE_CLEAR"), "Gegner entfernen")
	assert_eq(Texts.format("TOAST_ENEMIES_CLEARED", [4]), "4 Gegner entfernt")
	assert_eq(Texts.t("CREATIVE_MONEY_ON"), "Unbegrenztes Geld an")
	assert_eq(Texts.t("CREATIVE_MONEY_OFF"), "Unbegrenztes Geld aus")
	assert_eq(Texts.track_name(GameConfig.TRACK_HULL, GameConfig.ZAPPER), "Leben")
	assert_eq(Texts.track_name(GameConfig.TRACK_ARMOR, GameConfig.ZAPPER), "Panzerung")
	assert_eq(Texts.t("STAT_HP"), "Leben")
	assert_eq(Texts.t("STAT_ARMOR"), "Panzerung")
	assert_eq(Texts.tech_name("plating_1"), "Lebenskraft I")
	TranslationServer.set_locale("en")
	assert_eq(Texts.building_name(GameConfig.BATTERY), "Storage")
	assert_eq(Texts.track_name(GameConfig.TRACK_HULL, GameConfig.ZAPPER), "Health")
	assert_eq(Texts.track_name(GameConfig.TRACK_ARMOR, GameConfig.ZAPPER), "Armour")
