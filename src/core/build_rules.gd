class_name BuildRules
extends RefCounted

const OK := ""
const INVALID := "invalid"
const LOCKED := "locked"
const MONEY := "money"
const BOUNDS := "bounds"
const BLOCKED := "blocked"
const SLIME := "slime"
const WATER_ONLY := "water_only"
const OVERLAP := "overlap"
const ENEMY_NEAR := "enemy_near"
const ENEMY_ZONE := "enemy_zone"
const TOO_FAR := "too_far"
const UNEXPLORED := "unexplored"
const UNITS := "units"
const SCOUT_FAR := "scout_far"
const PHASE := "phase"
const IMMOBILE := "immobile"
const SAME := "same"


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
	if not state.can_afford(Formulas.build_cost(state, kind)):
		return MONEY
	return _site_reason(state, Building.new(-1, kind, position), -1)


static func relocate_reason(state: BattleState, building: Building, position: Vector2) -> String:
	if building == null or not building.is_player() or not building.is_alive() or state.is_over():
		return INVALID
	if building.id == state.core_id or GameConfig.is_mobile(building.kind):
		return IMMOBILE
	if not state.can_afford(Formulas.relocate_cost(building, state.is_planning())):
		return MONEY
	var probe := Building.new(-1, building.kind, position)
	if probe.origin == building.origin:
		return SAME
	return _site_reason(state, probe, building.id)


static func _site_reason(state: BattleState, probe: Building, ignore_id: int) -> String:
	var terrain := _terrain_reason(state, probe, ignore_id)
	if terrain != OK:
		return terrain
	if not in_build_reach(state, probe.position, ignore_id):
		return TOO_FAR
	return _enemy_reason(state, probe, enemy_clearance(state))


static func enemy_clearance(state: BattleState) -> float:
	return GameConfig.ENEMY_PLAN_CLEAR if state.is_planning() else GameConfig.ENEMY_NO_BUILD


static func in_build_reach(state: BattleState, position: Vector2, ignore_id: int = -1) -> bool:
	for building in state.player_buildings():
		if building.id != ignore_id and building.position.distance_to(position) <= Formulas.build_radius(building):
			return true
	return false


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


static func _terrain_reason(state: BattleState, probe: Building, ignore_id: int = -1) -> String:
	if not state.map.contains(probe.position, probe.half_extent()):
		return BOUNDS
	var needs_water := bool(probe.definition().get("water_only", false))
	for cell in probe.footprint():
		if not state.fog.is_explored(cell):
			return UNEXPLORED
		if state.map.is_slimed(cell):
			return SLIME
		if needs_water:
			if state.map.tile(cell) != LevelMap.Tile.POND:
				return WATER_ONLY
		elif not state.map.is_buildable(cell):
			return BLOCKED
		var occupant := state.nav.occupant_at(cell)
		if occupant != NavGrid.FREE and occupant != ignore_id:
			return OVERLAP
	for enemy in state.enemies:
		if enemy.is_alive() and not enemy.is_air() and probe.edge_distance(enemy.position) < enemy.radius():
			return UNITS
	return OK


static func _enemy_reason(state: BattleState, probe: Building, clearance: float) -> String:
	for building in state.enemy_buildings():
		var distance := building.edge_distance(probe.position)
		if distance < clearance:
			return ENEMY_ZONE if distance >= GameConfig.ENEMY_NO_BUILD and state.is_planning() else ENEMY_NEAR
	return OK


static func can_place(state: BattleState, kind: String, position: Vector2) -> bool:
	return reason(state, kind, position) == OK
