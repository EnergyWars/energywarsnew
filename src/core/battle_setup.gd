class_name BattleSetup
extends RefCounted

enum Mode { CAMPAIGN, SURVIVAL }

var mode := Mode.CAMPAIGN
var days := 0
var arsenal: Arsenal


func _init(p_mode: Mode = Mode.CAMPAIGN, p_days: int = 0, p_arsenal: Arsenal = null) -> void:
	mode = p_mode
	days = maxi(p_days, 0)
	arsenal = p_arsenal if p_arsenal != null else Arsenal.new()


static func campaign(p_arsenal: Arsenal = null) -> BattleSetup:
	return BattleSetup.new(Mode.CAMPAIGN, 0, p_arsenal)


static func survival(p_days: int, p_arsenal: Arsenal = null) -> BattleSetup:
	return BattleSetup.new(Mode.SURVIVAL, p_days, p_arsenal)


func is_survival() -> bool:
	return mode == Mode.SURVIVAL


func is_endless() -> bool:
	return is_survival() and days == 0
