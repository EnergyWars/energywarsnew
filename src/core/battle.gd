class_name Battle
extends RefCounted

const STEP_LIGHT := "light"
const STEP_CUT := "cut"

var state: BattleState
var events := BattleEvents.new()
var network: EnergyNetwork
var economy: Economy
var combat: Combat
var ai: EnemyAI
var spawns: SpawnDirector
var scouting: ScoutControl
var mobility: MobileControl
var lighting: Lighting
var fuel: FuelControl
var checkpoint: BattleCheckpoint
var history := PlanHistory.new()
var _accumulator := 0.0
var _was_night := false
var _audit: EnergyAudit
var _audit_key := Vector3i(-1, -1, -1)


func _init(p_state: BattleState) -> void:
	state = p_state
	network = EnergyNetwork.new(state, events)
	economy = Economy.new(state, events)
	combat = Combat.new(state, events, economy, network)
	ai = EnemyAI.new(state, events, combat, network)
	spawns = SpawnDirector.new(state, events)
	scouting = ScoutControl.new(state, events)
	mobility = MobileControl.new(state, events)
	lighting = Lighting.new(state)
	fuel = FuelControl.new(state, events)
	combat.lighting = lighting
	_was_night = state.is_night()
	if state.is_planning():
		history.begin(state)


static func start(level_index: int, seed_value: int = 0, setup: BattleSetup = null) -> Battle:
	return Battle.new(BattleState.create(level_index, seed_value, setup))


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
		economy.update_pickups(delta)
		return
	scouting.update(delta)
	state.fog.update(state, delta)
	if state.phase != BattleState.Phase.FIGHT:
		economy.update_pickups(delta)
		if state.is_planning() and not state.enemies.is_empty():
			spawns.burn(delta)
			_sweep()
		if not state.is_scouting():
			_check_end()
		return
	state.time += delta
	state.round_time += delta
	spawns.update(delta)
	mobility.update(delta)
	fuel.update(delta)
	network.flow(delta)
	lighting.update(delta)
	combat.update(delta)
	ai.update(delta)
	_sweep()
	economy.update(delta)
	_check_daylight()
	_check_end()
	_check_round()


func _sweep() -> void:
	for enemy in state.enemies:
		if not enemy.is_alive():
			var alive: Array[Enemy] = []
			for unit in state.enemies:
				if unit.is_alive():
					alive.append(unit)
			state.enemies = alive
			return


func _check_daylight() -> void:
	var night := state.is_night()
	if night != _was_night:
		_was_night = night
		if night:
			events.emit("nightfall", {"round": state.round_number})
	if not state.night_over and DayCycle.is_finished(state.round_time, state.level):
		spawns.end_night()


func _check_round() -> void:
	if state.phase != BattleState.Phase.FIGHT or not state.night_over or state.has_attackers():
		return
	state.projectiles.clear()
	economy.reset_combo()
	economy.collect_all()
	var survived := state.round_number
	state.days_survived = survived
	if state.is_survival() and state.setup.days > 0 and survived >= state.setup.days:
		state.phase = BattleState.Phase.WON
		events.emit("victory", {"stars": state.stars()})
		return
	state.phase = BattleState.Phase.PLAN
	state.round_number += 1
	state.round_time = 0.0
	state.waves_sent = 0
	_was_night = false
	spawns.ignite_guards()
	history.begin(state)
	events.emit("round_cleared", {"round": survived, "next": state.round_number})


func audit() -> EnergyAudit:
	var key := Vector3i(state.roster_version, state.links_version, state.layout_version)
	if _audit == null or key != _audit_key:
		_audit = EnergyAudit.measure(state)
		_audit_key = key
	return _audit


func start_round() -> bool:
	if not state.is_planning():
		return false
	var saved := BattleCheckpoint.capture(state)
	if not spawns.start_round():
		return false
	checkpoint = saved
	history.end()
	return true


func can_undo() -> bool:
	return state.is_planning() and history.can_undo()


func undo() -> bool:
	if not can_undo():
		return false
	_restore(history.pop())
	return true


func reset_plan() -> bool:
	if not can_undo():
		return false
	_restore(history.rewind())
	return true


func _restore(snapshot: PlanSnapshot) -> void:
	snapshot.restore(state)
	state.mark_changed()
	state.fog.invalidate()
	events.emit("plan_restored", {"steps": history.size()})


func begin_stroke() -> void:
	history.open_stroke()


func end_stroke() -> void:
	history.close_stroke()


func _checkpoint(tag: String = "") -> PlanSnapshot:
	return PlanSnapshot.capture(state) if state.is_planning() and history.wants(tag) else null


func _commit(snapshot: PlanSnapshot, tag: String = "") -> void:
	history.record(snapshot, tag)


func _check_end() -> void:
	var core := state.core()
	if core == null or not core.is_alive():
		state.phase = BattleState.Phase.LOST
		events.emit("defeat")
		return
	if not state.is_survival() and state.enemy_buildings().is_empty():
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
	scouting.board(core)
	state.fog.refresh(state)
	_was_night = state.is_night()
	history.begin(state)
	events.emit("core_deployed", {"id": core.id, "position": core.position})
	events.emit("structures_spawned", {"count": state.enemy_buildings().size()})
	return reason


func steer_scout(direction: Vector2) -> String:
	return scouting.steer(direction)


func clear_with_scout(world: Vector2) -> String:
	return scouting.clear(world)


func walk_scout(world: Vector2) -> String:
	return scouting.walk_to(world)


func place(kind: String, position: Vector2) -> String:
	if kind == GameConfig.CORE:
		return deploy_core(position)
	var reason := BuildRules.reason(state, kind, position)
	if reason != BuildRules.OK:
		return reason
	var before := _checkpoint()
	var cost := Formulas.build_cost(state, kind)
	state.money -= cost
	var building := state.add_building(kind, position)
	building.spent = cost
	building.plan_spent = cost if state.is_planning() else 0
	_commit(before)
	events.emit("placed", {"id": building.id, "kind": kind, "position": building.position})
	return reason


func relocate(id: int, position: Vector2) -> String:
	var building := state.building(id)
	var reason := BuildRules.relocate_reason(state, building, position)
	if reason != BuildRules.OK:
		return reason
	var before := _checkpoint()
	var cost := Formulas.relocate_cost(building, state.is_planning())
	var from := building.position
	state.money -= cost
	state.move_building(building, position)
	network.drop_out_of_range(id)
	_commit(before)
	state.fog.invalidate()
	events.emit("relocated", {"id": id, "kind": building.kind, "from": from, "position": building.position, "cost": cost})
	return reason


func steer(id: int, direction: Vector2) -> String:
	return mobility.steer(id, direction)


func toggle_target_class(id: int, unit_class: String) -> bool:
	var building := state.building(id)
	if building == null or not GameConfig.has_attack(building.kind) or not GameConfig.CLASSES.has(unit_class):
		return false
	_commit(_checkpoint())
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
	_commit(_checkpoint())
	building.target_order[index] = building.target_order[index - 1]
	building.target_order[index - 1] = unit_class
	return true


func focus(id: int, target: Object) -> String:
	var before := _checkpoint()
	var reason := combat.set_focus(state.building(id), target)
	if reason == Combat.OK:
		_commit(before)
	return reason


func focus_candidate(world: Vector2, slack: float = 0.0) -> Object:
	var best: Object = null
	var best_distance := INF
	for enemy in state.enemies:
		var distance := enemy.position.distance_to(world)
		if enemy.is_alive() and state.fog.is_visible(enemy.position) and distance <= enemy.radius() + slack and distance < best_distance:
			best = enemy
			best_distance = distance
	if best != null:
		return best
	var building := building_at(world, slack)
	if building != null:
		return building
	var cell := state.map.cell_of(world)
	return state.obstacle_at(cell) if state.fog.is_explored(cell) else null


func can_upgrade(id: int, track: String) -> bool:
	var building := state.building(id)
	if building == null or not building.is_player() or not building.has_track(track) or Formulas.is_maxed(building, track):
		return false
	return state.money >= Formulas.upgrade_cost(building, track) and not state.is_over()


func upgrade(id: int, track: String) -> bool:
	if not can_upgrade(id, track):
		return false
	var building := state.building(id)
	_commit(_checkpoint())
	var cost := Formulas.upgrade_cost(building, track)
	state.money -= cost
	building.spent += cost
	if state.is_planning():
		building.plan_spent += cost
	var old_max := building.max_hp()
	building.set_level(track, building.level(track) + 1)
	building.hp += building.max_hp() - old_max
	state.mark_changed()
	state.fog.invalidate()
	events.emit("upgraded", {"id": id, "track": track, "level": building.level(track), "position": building.position, "overloaded": Formulas.is_overloaded(building)})
	return true


func sell(id: int) -> int:
	var building := state.building(id)
	if building == null or not building.is_player() or id == state.core_id or state.is_over():
		return 0
	_commit(_checkpoint())
	var refund := Formulas.sell_value(building)
	state.money += refund
	network.remove_links_of(id)
	state.remove_building(id)
	events.emit("sold", {"id": id, "kind": building.kind, "position": building.position, "refund": refund})
	return refund


func connect_buildings(from_id: int, to_id: int) -> String:
	var reason := network.link_reason(from_id, to_id)
	if reason == EnergyNetwork.OK:
		_commit(_checkpoint())
		network.connect_buildings(from_id, to_id)
	return reason


func cut_link(from_id: int, to_id: int) -> bool:
	var link := state.find_link(from_id, to_id)
	if link == null or state.is_over():
		return false
	_commit(_checkpoint())
	network.remove_link(link, "cut")
	return true


func cut_links_of(id: int, incoming: bool) -> int:
	var building := state.building(id)
	if building == null or not building.is_player() or state.is_over():
		return 0
	var any := state.links.any(func(link: EnergyLink) -> bool: return (link.target if incoming else link.source) == id)
	if not any:
		return 0
	_commit(_checkpoint())
	return network.remove_links_where(id, incoming, "cut")


func toggle_fuel(id: int, cell: Vector2i) -> String:
	var fire := state.building(id)
	var marked := fire != null and fire.fuel.has(cell)
	if not marked:
		var reason := fuel.reason(fire, cell)
		if reason != FuelControl.OK:
			return reason
	elif state.is_over():
		return FuelControl.INVALID
	_commit(_checkpoint())
	return fuel.toggle(fire, cell)


func set_light_radius(id: int, radius_cells: float) -> bool:
	var lamp := state.building(id)
	if lamp == null or not lamp.lighting or not lamp.is_player() or state.is_over():
		return false
	var value := Formulas.clamp_light(radius_cells)
	if is_equal_approx(value, lamp.light_radius):
		return false
	_commit(_checkpoint(STEP_LIGHT), STEP_LIGHT)
	lamp.light_radius = value
	state.mark_changed()
	return true


func rename(id: int, text: String) -> bool:
	var building := state.building(id)
	if building == null or not building.is_player():
		return false
	building.label = text.strip_edges().left(Building.LABEL_MAX)
	return true


func cut(from: Vector2, to: Vector2) -> int:
	if not network.crosses(from, to):
		return 0
	_commit(_checkpoint(STEP_CUT), STEP_CUT)
	return network.cut(from, to)


func building_at(position: Vector2, slack: float = 0.0) -> Building:
	var best: Building = null
	var best_distance := INF
	for building: Building in state.buildings.values():
		var distance := position.distance_to(building.position)
		if distance <= building.radius() + slack and distance < best_distance:
			best = building
			best_distance = distance
	return best
