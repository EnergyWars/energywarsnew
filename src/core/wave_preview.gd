class_name WavePreview
extends RefCounted

const DAY := "day"
const NIGHT := "night"
const KINDS := "kinds"
const RAID := "raid"


static func of(state: BattleState) -> Dictionary:
	return for_round(state.level, state.round_number, spawner_kinds(state))


static func spawner_kinds(state: BattleState) -> Array[String]:
	var kinds: Array[String] = []
	for building in state.enemy_buildings():
		if building.spawner and building.is_alive() and not kinds.has(building.kind):
			kinds.append(building.kind)
	return kinds


static func for_round(level: Dictionary, round_number: int, spawners: Array[String]) -> Dictionary:
	var waves: Dictionary = level.get("waves", GameConfig.EMPTY)
	return {
		DAY: section(level, waves.get("roster", GameConfig.EMPTY_LIST), round_number, spawners, false),
		NIGHT: section(level, waves.get("night_roster", GameConfig.EMPTY_LIST), round_number, spawners, true),
	}


static func section(level: Dictionary, roster: Array, round_number: int, spawners: Array[String], night: bool) -> Dictionary:
	var kinds: Array[String] = []
	var raid: Array[String] = []
	if spawners.is_empty():
		return {KINDS: kinds, RAID: raid}
	for spawner in spawners:
		var options := SpawnDirector.eligible(roster, spawner, round_number)
		if options.is_empty():
			_add(kinds, SpawnDirector.fallback_for(spawner, night))
		for entry: Array in options:
			_add(kinds, str(entry[0]))
	for entry: Dictionary in level.get("extra_waves", GameConfig.EMPTY_LIST):
		if int(entry.get("day", 0)) == round_number and bool(entry.get("night", false)) == night and not GameConfig.enemy(str(entry.get("kind", ""))).is_empty():
			_add(kinds, str(entry.kind))
	if raids_possible(round_number):
		for kind: String in SpawnDirector.air_kinds(spawners, night):
			_add(raid, kind)
	return {KINDS: kinds, RAID: raid}


static func raids_possible(round_number: int) -> bool:
	return round_number >= GameConfig.AIR_RAID_FIRST_ROUND


static func _add(list: Array[String], kind: String) -> void:
	if not kind.is_empty() and not list.has(kind):
		list.append(kind)
