class_name Battle
extends RefCounted

var state: BattleState
var events := BattleEvents.new()
var network: EnergyNetwork
var economy: Economy
var combat: Combat
var ai: EnemyAI
var spawns: SpawnDirector
var scouting: ScoutControl
var _accumulator := 0.0
var _was_night := false


func _init(p_state: BattleState) -> void:
	state = p_state
	network = EnergyNetwork.new(state, events)
	economy = Economy.new(state, events)
	combat = Combat.new(state, events, economy, network)
	ai = EnemyAI.new(state, events, combat, network)
	spawns = SpawnDirector.new(state, events)
	scouting = ScoutControl.new(state, events)
	_was_night = state.is_night()


static func start(level_index: int, seed_value: int = 0) -> Battle:
	return Battle.new(BattleState.create(level_index, seed_value))


func advance(delta: float) -> int:
	_accumulator += maxf(delta, 0.0)
	var steps := 0
	while _accumulator >= GameConfig.TICK and steps < GameConfig.MAX_STEPS_PER_FRAME:
		tick(GameConfig.TICK)
		_accumulator -= GameConfig.TICK
		steps += 1
	if steps >= GameConfig.MAX_STEPS_PER_FRAME:
		_accumulator = 0.0
	return steps


func tick(delta: float) -> void:
	if state.is_over():
		economy.update(delta)
		return
	scouting.update(delta)
	state.fog.update(state, delta)
	if state.is_scouting():
		return
	state.time += delta
	spawns.update(delta)
	network.flow(delta)
	combat.update(delta)
	ai.update(delta)
	_sweep()
	economy.update(delta)
	_check_daylight()
	_check_end()


func _sweep() -> void:
	var alive: Array[Enemy] = []
	for enemy in state.enemies:
		if enemy.is_alive():
			alive.append(enemy)
	state.enemies = alive


func _check_daylight() -> void:
	var night := state.is_night()
	if night != _was_night:
		_was_night = night
		events.emit("nightfall" if night else "daybreak", {"day": DayCycle.day_number(state.time, state.level)})


func _check_end() -> void:
	var core := state.core()
	if core == null or not core.is_alive():
		state.phase = BattleState.Phase.LOST
		events.emit("defeat")
		return
	if state.enemy_buildings().is_empty():
		state.phase = BattleState.Phase.WON
		for enemy in state.enemies:
			enemy.hp = 0.0
			economy.enemy_killed(enemy, "purge")
		state.enemies.clear()
		state.projectiles.clear()
		economy.collect_all()
		events.emit("victory", {"stars": state.stars()})


func deploy_core(position: Vector2) -> String:
	var reason := BuildRules.reason(state, GameConfig.CORE, position)
	if reason != BuildRules.OK:
		return reason
	var core := state.place_core(position)
	_step_aside(core)
	state.fog.refresh(state)
	_was_night = state.is_night()
	events.emit("core_deployed", {"id": core.id, "position": core.position})
	return reason


func _step_aside(core: Building) -> void:
	var scout := state.scout
	if scout == null or core.edge_distance(scout.position) > GameConfig.SCOUT_RADIUS:
		return
	var cell := state.nav.nearest_free(core.position + Vector2(0, core.half_extent() + GameConfig.CELL * 0.5))
	if cell != Vector2i(-1, -1):
		scout.position = state.map.center_of(cell)
	scout.path = PackedVector2Array()
	scout.path_index = 0
	scout.clear_cell = Scout.NO_CELL


func command_scout(world: Vector2) -> String:
	return scouting.command(world)


func place(kind: String, position: Vector2) -> String:
	if kind == GameConfig.CORE:
		return deploy_core(position)
	var reason := BuildRules.reason(state, kind, position)
	if reason != BuildRules.OK:
		return reason
	var cost := Formulas.build_cost(state, kind)
	state.money -= cost
	var building := state.add_building(kind, position)
	building.spent = cost
	events.emit("placed", {"id": building.id, "kind": kind, "position": building.position})
	return reason


func toggle_target_class(id: int, unit_class: String) -> bool:
	var building := state.building(id)
	if building == null or not GameConfig.has_attack(building.kind) or not GameConfig.CLASSES.has(unit_class):
		return false
	if building.target_disabled.get(unit_class, false):
		building.target_disabled.erase(unit_class)
	else:
		building.target_disabled[unit_class] = true
	return true


func raise_target_class(id: int, unit_class: String) -> bool:
	var building := state.building(id)
	if building == null or not GameConfig.has_attack(building.kind):
		return false
	var index := building.target_order.find(unit_class)
	if index <= 0:
		return false
	building.target_order[index] = building.target_order[index - 1]
	building.target_order[index - 1] = unit_class
	return true


func can_upgrade(id: int, track: String) -> bool:
	var building := state.building(id)
	if building == null or not building.is_player() or not building.has_track(track) or Formulas.is_maxed(building, track):
		return false
	return state.money >= Formulas.upgrade_cost(building, track) and not state.is_over()


func upgrade(id: int, track: String) -> bool:
	if not can_upgrade(id, track):
		return false
	var building := state.building(id)
	var cost := Formulas.upgrade_cost(building, track)
	state.money -= cost
	building.spent += cost
	var old_max := building.max_hp()
	building.levels[track] = building.level(track) + 1
	building.hp += building.max_hp() - old_max
	state.fog.invalidate()
	events.emit("upgraded", {"id": id, "track": track, "level": building.level(track), "position": building.position})
	return true


func sell(id: int) -> int:
	var building := state.building(id)
	if building == null or not building.is_player() or id == state.core_id or state.is_over():
		return 0
	var refund := Formulas.sell_value(building)
	state.money += refund
	network.remove_links_of(id)
	state.remove_building(id)
	events.emit("sold", {"id": id, "kind": building.kind, "position": building.position, "refund": refund})
	return refund


func connect_buildings(from_id: int, to_id: int) -> String:
	var reason := network.link_reason(from_id, to_id)
	if reason == EnergyNetwork.OK:
		network.connect_buildings(from_id, to_id)
	return reason


func cut(from: Vector2, to: Vector2) -> int:
	return network.cut(from, to)


func skip_prep() -> int:
	return spawns.skip_prep()


func building_at(position: Vector2, slack: float = 0.0) -> Building:
	var best: Building = null
	var best_distance := INF
	for building: Building in state.buildings.values():
		var distance := position.distance_to(building.position)
		if distance <= building.radius() + slack and distance < best_distance:
			best = building
			best_distance = distance
	return best
