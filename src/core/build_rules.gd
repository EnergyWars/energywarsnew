class_name BuildRules
extends RefCounted

const OK := ""
const INVALID := "invalid"
const LOCKED := "locked"
const MONEY := "money"
const BOUNDS := "bounds"
const BLOCKED := "blocked"
const OVERLAP := "overlap"
const ENEMY_NEAR := "enemy_near"
const TOO_FAR := "too_far"
const UNEXPLORED := "unexplored"
const UNITS := "units"
const SCOUT_FAR := "scout_far"
const PHASE := "phase"


static func reason(state: BattleState, kind: String, position: Vector2) -> String:
	var definition := GameConfig.building(kind)
	if definition.is_empty() or int(definition.team) != GameConfig.TEAM_PLAYER:
		return INVALID
	if kind == GameConfig.CORE:
		return _core_reason(state, position)
	if state.is_scouting():
		return PHASE
	if not state.is_available(kind):
		return LOCKED
	if state.money < Formulas.build_cost(state, kind):
		return MONEY
	var probe := Building.new(-1, kind, position)
	var terrain := _terrain_reason(state, probe)
	if terrain != OK:
		return terrain
	var in_reach := false
	for building in state.player_buildings():
		if building.position.distance_to(probe.position) <= Formulas.build_radius(building):
			in_reach = true
			break
	if not in_reach:
		return TOO_FAR
	return _enemy_reason(state, probe, GameConfig.ENEMY_NO_BUILD)


static func _core_reason(state: BattleState, position: Vector2) -> String:
	var scout := state.scout
	if not state.is_scouting() or scout == null:
		return INVALID
	if not scout.is_landed():
		return PHASE
	var probe := Building.new(-1, GameConfig.CORE, position)
	var terrain := _terrain_reason(state, probe)
	if terrain != OK:
		return terrain
	if probe.position.distance_to(scout.position) > GameConfig.CORE_DEPLOY_RANGE:
		return SCOUT_FAR
	return _enemy_reason(state, probe, GameConfig.CORE_ENEMY_CLEAR)


static func _terrain_reason(state: BattleState, probe: Building) -> String:
	if not state.map.contains(probe.position, probe.half_extent()):
		return BOUNDS
	for cell in probe.footprint():
		if not state.fog.is_explored(cell):
			return UNEXPLORED
		if not state.map.is_buildable(cell):
			return BLOCKED
		if state.nav.occupant_at(cell) != NavGrid.FREE:
			return OVERLAP
	for enemy in state.enemies:
		if enemy.is_alive() and not enemy.is_air() and probe.edge_distance(enemy.position) < enemy.radius():
			return UNITS
	return OK


static func _enemy_reason(state: BattleState, probe: Building, clearance: float) -> String:
	for building in state.enemy_buildings():
		if building.edge_distance(probe.position) < clearance:
			return ENEMY_NEAR
	return OK


static func can_place(state: BattleState, kind: String, position: Vector2) -> bool:
	return reason(state, kind, position) == OK
