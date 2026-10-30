class_name BattleSetup
extends RefCounted

enum Mode { CAMPAIGN, SURVIVAL, CREATIVE }

var mode := Mode.CAMPAIGN
var days := 0
var start_day := 1
var arsenal: Arsenal


func _init(p_mode: Mode = Mode.CAMPAIGN, p_days: int = 0, p_arsenal: Arsenal = null, p_start_day: int = 1) -> void:
	mode = p_mode
	days = maxi(p_days, 0)
	arsenal = p_arsenal if p_arsenal != null else Arsenal.new()
	if is_creative():
		arsenal = arsenal.with_all_kinds()
		start_day = clamp_day(p_start_day)


static func campaign(p_arsenal: Arsenal = null) -> BattleSetup:
	return BattleSetup.new(Mode.CAMPAIGN, 0, p_arsenal)


static func survival(p_days: int, p_arsenal: Arsenal = null) -> BattleSetup:
	return BattleSetup.new(Mode.SURVIVAL, p_days, p_arsenal)


static func creative(p_start_day: int = 1, p_arsenal: Arsenal = null) -> BattleSetup:
	return BattleSetup.new(Mode.CREATIVE, 0, p_arsenal, p_start_day)


static func clamp_day(day: int) -> int:
	return clampi(day, 1, GameConfig.CREATIVE_MAX_DAY)


func renewed(p_arsenal: Arsenal) -> BattleSetup:
	return BattleSetup.new(mode, days, p_arsenal, start_day)


func is_campaign() -> bool:
	return mode == Mode.CAMPAIGN


func is_survival() -> bool:
	return mode == Mode.SURVIVAL


func is_creative() -> bool:
	return mode == Mode.CREATIVE


func is_endless() -> bool:
	return is_survival() and days == 0
