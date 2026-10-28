extends SceneTree

const THINK_INTERVAL := 1.5
const MAX_TIME := 3000.0
const RELAY_STEP := 250.0
const TOWER_OFFSET := 95.0
const RESERVE := 120

var _levels: Array[int] = []
var _verbose := false
var _extra_money := 0
var _seed := -1
var _profile := false
var _walls := false
var _hold := false
var _lost_walls := 0
var _lost_other := 0
var _first_loss := -1.0
var _tick_usec := 0
var _think_usec := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			_levels.append(arg.trim_prefix("--level=").to_int())
		elif arg.begins_with("--money="):
			_extra_money = arg.trim_prefix("--money=").to_int()
		elif arg.begins_with("--seed="):
			_seed = arg.trim_prefix("--seed=").to_int()
		elif arg == "--hold":
			_hold = true
		elif arg == "--walls":
			_walls = true
		elif arg == "--profile":
			_profile = true
		elif arg == "--verbose":
			_verbose = true
	if _levels.is_empty():
		for i in GameConfig.level_count():
			_levels.append(i)
	for index in _levels:
		_play(index)
	quit()


func _play(index: int) -> void:
	_lost_walls = 0
	_lost_other = 0
	_first_loss = -1.0
	var battle := Battle.start(index)
	var state := battle.state
	state.scout.drop_left = 0.0
	state.fog.cells.fill(FogOfWar.EXPLORED)
	battle.deploy_core(state.map.drop)
	state.money += _extra_money
	if _seed >= 0:
		state.rng.seed = _seed
	var think := 0.0
	var min_core := 1.0
	var min_energy_night := INF
	while not state.is_over() and state.time < MAX_TIME:
		if state.is_planning():
			_think(battle)
			battle.start_round()
		var started := Time.get_ticks_usec()
		battle.tick(GameConfig.TICK)
		_tick_usec += Time.get_ticks_usec() - started
		for event in battle.events.drain():
			if event.type != "building_destroyed":
				continue
			if event.kind == GameConfig.BULWARK:
				_lost_walls += 1
			else:
				_lost_other += 1
				if _first_loss < 0.0:
					_first_loss = state.time
		think -= GameConfig.TICK
		if think <= 0.0:
			think = THINK_INTERVAL
			started = Time.get_ticks_usec()
			_think(battle)
			_think_usec += Time.get_ticks_usec() - started
		if _profile and fmod(state.time, 60.0) < GameConfig.TICK:
			print("  t=%4d enemies=%3d buildings=%3d tick_ms=%.2f think_ms=%.1f" % [int(state.time), state.enemies.size(), state.player_buildings().size(), _tick_usec / 1000.0 / (60.0 / GameConfig.TICK), _think_usec / 1000.0 / (60.0 / THINK_INTERVAL)])
			_tick_usec = 0
			_think_usec = 0
		min_core = minf(min_core, state.core_ratio())
		if state.is_night():
			min_energy_night = minf(min_energy_night, state.stored_energy())
		if _verbose and fmod(state.time, 30.0) < GameConfig.TICK:
			_report(state)
	print("%-12s lost_walls=%4d lost_other=%4d first_loss=%5ds" % [state.level.id, _lost_walls, _lost_other, int(_first_loss)])
	print("%-12s %-5s walls=%3d t=%4ds rounds=%2d kills=%4d lost=%2d core_min=%.2f stars=%d money=%d earned=%d buildings=%d night_min_energy=%d" % [
		state.level.id, BattleState.Phase.keys()[state.phase], state.count_kind(GameConfig.BULWARK), int(state.time), state.round_number, state.kills, state.lost, min_core,
		state.stars(), state.money, state.earned, state.player_buildings().size(), int(min_energy_night if min_energy_night != INF else -1)])


func _report(state: BattleState) -> void:
	var target := _nearest_structure(state, state.core().position if state.core() != null else state.map.drop)
	var front := _front(state, target.position) if target != null else null
	var towers := state.player_buildings().filter(func(b: Building) -> bool: return GameConfig.is_tower(b.kind) and b.kind != GameConfig.CORE).size()
	var starved := state.player_buildings().filter(func(b: Building) -> bool: return GameConfig.is_tower(b.kind) and b.energy < Formulas.shot_energy(b)).size()
	var unlinked := state.player_buildings().filter(func(b: Building) -> bool: return GameConfig.is_tower(b.kind) and b.kind != GameConfig.CORE and not state.links.any(func(l: EnergyLink) -> bool: return l.target == b.id)).size()
	print("  starved=%d unlinked=%d links=%d exporters=%d full=%.2f" % [starved, unlinked, state.links.size(), _count(state, GameConfig.EXPORTER), state.stored_energy() / state.storage_capacity()])
	print("  t=%4d cycle=%2d money=%4d towers=%2d relays=%2d solar=%2d enemies=%3d front_dist=%4d target_hp=%4d core=%.2f energy=%d" % [
		int(state.time), state.round_number, state.money, towers, _count(state, GameConfig.RELAY), _count(state, GameConfig.SOLAR), state.enemies.size(),
		int(front.position.distance_to(target.position)) if front != null else -1, int(target.hp) if target != null else -1, state.core_ratio(), int(state.stored_energy())])


func _think(battle: Battle) -> void:
	var state := battle.state
	var core := state.core()
	if core == null:
		return
	var kinds := GameConfig.available_kinds(state.level_index)
	var target := _nearest_structure(state, core.position)
	if target == null:
		return
	_defend(battle, core, kinds, target.position)
	if _walls:
		_fortify(battle, target.position)
	_economy(battle, core)
	_feed_towers(battle)
	_upgrade(battle)
	if _hold:
		return
	var front := _front(state, target.position)
	var distance := front.position.distance_to(target.position)
	var escort := _best_tower(kinds, state.money - 30)
	var step_cost := Formulas.build_cost(battle.state, GameConfig.RELAY) + 2 * Formulas.build_cost(battle.state, escort)
	if front != core and _towers_near(state, front.position, 200.0) < 4:
		_siege(battle, front, target, kinds)
		return
	if distance <= 300.0:
		_siege(battle, front, target, kinds)
		return
	if state.money < step_cost:
		return
	var step := front.position + (target.position - front.position).normalized() * minf(RELAY_STEP, distance - 240.0)
	var relay := _place_near(battle, GameConfig.RELAY, step)
	if relay == null:
		if _verbose:
			print("    step failed: ", BuildRules.reason(state, GameConfig.RELAY, step), " dist=", int(distance))
		return
	_link(battle, front, relay)
	_siege(battle, relay, target, kinds)
	_siege(battle, relay, target, kinds)


func _fortify(battle: Battle, enemy: Vector2) -> void:
	var state := battle.state
	var inner := {}
	var ring := {}
	for building in state.player_buildings():
		if GameConfig.is_wall(building.kind):
			continue
		var n := building.cells()
		if not GameConfig.has_attack(building.kind):
			for y in range(-1, n + 1):
				for x in range(-1, n + 1):
					inner[building.origin + Vector2i(x, y)] = true
			continue
		for y in range(-2, n + 2):
			for x in range(-2, n + 2):
				var cell := building.origin + Vector2i(x, y)
				if x >= -1 and x <= n and y >= -1 and y <= n:
					inner[cell] = true
				else:
					ring[cell] = true
	var spots: Array[Vector2i] = []
	for cell: Vector2i in ring:
		if not inner.has(cell) and state.map.is_buildable(cell) and state.nav.is_free(cell):
			spots.append(cell)
	spots.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return state.map.center_of(a).distance_squared_to(enemy) < state.map.center_of(b).distance_squared_to(enemy))
	var placed := 0
	for cell in spots:
		if placed >= 16 or state.money < Formulas.build_cost(state, GameConfig.BULWARK):
			return
		if battle.place(GameConfig.BULWARK, state.map.center_of(cell)) == BuildRules.OK:
			placed += 1


func _economy(battle: Battle, core: Building) -> void:
	var state := battle.state
	var solars := _count(state, GameConfig.SOLAR)
	var batteries := _count(state, GameConfig.BATTERY)
	var starved := state.player_buildings().filter(func(b: Building) -> bool: return GameConfig.is_tower(b.kind) and b.energy < Formulas.shot_energy(b)).size()
	if solars < 3 + mini(state.level_index, 3) + starved and solars < 9 and state.money >= 40 + 30 * mini(solars, 3):
		var solar := _place_ring(battle, GameConfig.SOLAR, core.position + Vector2(0, 120), 170.0 + 70.0 * (solars / 6))
		if solar != null:
			var sink := _receiver_near(state, solar)
			if sink != null:
				_link(battle, solar, sink)
	if batteries < 1 + solars / 4 and state.money >= 120:
		var battery := _place_ring(battle, GameConfig.BATTERY, core.position, 120.0)
		if battery != null:
			_link(battle, core, battery)
	_export(battle, core)
	for battery in state.player_buildings():
		if battery.kind != GameConfig.BATTERY or state.outgoing(battery.id).size() >= Formulas.max_links(battery):
			continue
		for target in _by_distance(state, battery.position):
			if (GameConfig.is_tower(target.kind) or target.kind == GameConfig.RELAY) and target.kind != GameConfig.CORE and battle.connect_buildings(battery.id, target.id) == EnergyNetwork.OK:
				break


func _export(battle: Battle, core: Building) -> void:
	var state := battle.state
	if not state.is_available(GameConfig.EXPORTER) or state.is_night():
		_unlink_exporters(battle)
		return
	var full := state.stored_energy() / maxf(state.storage_capacity(), 1.0)
	var exporters := _count(state, GameConfig.EXPORTER)
	if full > 0.6 and exporters < 1 + _count(state, GameConfig.SOLAR) / 3 and state.money >= Formulas.build_cost(battle.state, GameConfig.EXPORTER):
		var exporter := _place_ring(battle, GameConfig.EXPORTER, core.position + Vector2(0, 60), 110.0)
		if exporter != null:
			_power(battle, exporter)
	if full > 0.5:
		for exporter in state.player_buildings():
			if exporter.kind == GameConfig.EXPORTER and not state.links.any(func(l: EnergyLink) -> bool: return l.target == exporter.id):
				_power(battle, exporter)


func _unlink_exporters(battle: Battle) -> void:
	for link in battle.state.links.duplicate():
		var target := battle.state.building(link.target)
		if target != null and target.kind == GameConfig.EXPORTER:
			battle.network.remove_link(link, "cut")


func _defend(battle: Battle, core: Building, kinds: Array[String], enemy: Vector2) -> void:
	var state := battle.state
	var threat := state.enemies.filter(func(e: Enemy) -> bool: return e.position.distance_to(core.position) < 700.0).size()
	var wanted := 2 + (2 if state.core_ratio() < 0.85 else 0) + mini(state.round_number / 2, 2) + threat / 4
	if _towers_near(state, core.position, 300.0) >= wanted:
		return
	var kind := _best_tower(kinds, state.money)
	if state.money < Formulas.build_cost(battle.state, kind):
		return
	var facing := (enemy - core.position).normalized()
	var count := _towers_near(state, core.position, 300.0)
	var spot := core.position + facing.rotated((count % 3 - 1) * 0.7) * (150.0 + 60.0 * (count / 3))
	var tower := _place_near(battle, kind, spot)
	if tower != null:
		_power(battle, tower)


func _upgrade(battle: Battle) -> void:
	var state := battle.state
	for building in state.player_buildings():
		if GameConfig.is_tower(building.kind) and building.energy < Formulas.shot_energy(building):
			for link in state.links:
				if link.target == building.id and state.money >= 220:
					battle.upgrade(link.source, GameConfig.TRACK_RATE)
	if state.money < 200:
		return
	var target := _nearest_structure(state, state.core().position if state.core() != null else state.map.drop)
	if target != null:
		var front := _front(state, target.position)
		for building in _by_distance(state, front.position):
			if GameConfig.is_tower(building.kind) and building.position.distance_to(front.position) < 220.0 and battle.upgrade(building.id, GameConfig.TRACK_POWER):
				return
	if state.money < 260:
		return
	for building in state.player_buildings():
		if GameConfig.is_tower(building.kind) and battle.upgrade(building.id, GameConfig.TRACK_POWER):
			return
		if building.kind == GameConfig.SOLAR and battle.upgrade(building.id, GameConfig.TRACK_OUTPUT):
			return


func _siege(battle: Battle, front: Building, target: Building, kinds: Array[String]) -> void:
	var state := battle.state
	if _towers_near(state, front.position, 200.0) >= 5:
		return
	var direction := (target.position - front.position).normalized()
	var side := _towers_near(state, front.position, 200.0)
	var spot := front.position + direction * (70.0 - 60.0 * (side / 3)) + direction.orthogonal() * TOWER_OFFSET * (side % 3 - 1)
	var kind := _best_tower(kinds, state.money)
	var tower := _place_near(battle, kind, spot)
	if tower != null:
		_link(battle, front, tower)
	elif _verbose and state.money >= Formulas.build_cost(battle.state, kind):
		print("    siege failed: ", BuildRules.reason(state, kind, spot))


func _feed_towers(battle: Battle) -> void:
	var state := battle.state
	for building in state.player_buildings():
		if not GameConfig.is_tower(building.kind):
			continue
		var fed := false
		for link in state.links:
			if link.target == building.id:
				fed = true
		if not fed:
			_power(battle, building)


func _power(battle: Battle, tower: Building) -> void:
	for source in _by_distance(battle.state, tower.position):
		if EnergyNetwork.can_send(source) and battle.connect_buildings(source.id, tower.id) == EnergyNetwork.OK:
			return
		if EnergyNetwork.can_send(source) and battle.state.outgoing(source.id).size() >= Formulas.max_links(source) and battle.state.money >= 250:
			battle.upgrade(source.id, GameConfig.TRACK_LINKS)


func _best_tower(kinds: Array[String], money: int) -> String:
	var best := GameConfig.ZAPPER
	for kind in [GameConfig.LASER, GameConfig.TESLA, GameConfig.PLASMA]:
		if kinds.has(kind) and money >= int(GameConfig.building(kind).cost) + 40:
			best = kind
	return best


func _link(battle: Battle, source: Building, target: Building) -> void:
	var result := battle.connect_buildings(source.id, target.id)
	if result != EnergyNetwork.FULL:
		return
	if battle.upgrade(source.id, GameConfig.TRACK_LINKS) and battle.connect_buildings(source.id, target.id) == EnergyNetwork.OK:
		return
	_power(battle, target)


func _place_near(battle: Battle, kind: String, spot: Vector2) -> Building:
	for attempt in 24:
		var offset := Vector2.ZERO if attempt == 0 else Vector2.from_angle(attempt * 1.7) * (20.0 + attempt * 12.0)
		if battle.place(kind, spot + offset) == BuildRules.OK:
			return battle.state.player_buildings().back()
	return null


func _place_ring(battle: Battle, kind: String, center: Vector2, radius: float) -> Building:
	for attempt in 24:
		var spot := center + Vector2.from_angle(attempt * 0.785 + 0.3) * (radius + (attempt / 8) * 60.0)
		if battle.place(kind, spot) == BuildRules.OK:
			return battle.state.player_buildings().back()
	return null


func _receiver_near(state: BattleState, source: Building) -> Building:
	for building in _by_distance(state, source.position):
		if building.id != source.id and EnergyNetwork.can_receive(building) and not GameConfig.is_tower(building.kind) and building.position.distance_to(source.position) <= Formulas.link_range(source):
			return building
	return null


func _by_distance(state: BattleState, origin: Vector2) -> Array[Building]:
	var list := state.player_buildings()
	list.sort_custom(func(a: Building, b: Building) -> bool: return a.position.distance_to(origin) < b.position.distance_to(origin))
	return list


func _front(state: BattleState, target: Vector2) -> Building:
	var best: Building = state.core()
	for building in state.player_buildings():
		if building.kind == GameConfig.RELAY and building.position.distance_to(target) < best.position.distance_to(target):
			best = building
	return best


func _nearest_structure(state: BattleState, origin: Vector2) -> Building:
	var best: Building = null
	for building in state.enemy_buildings():
		if best == null or building.position.distance_to(origin) < best.position.distance_to(origin):
			best = building
	return best


func _count(state: BattleState, kind: String) -> int:
	return state.player_buildings().filter(func(b: Building) -> bool: return b.kind == kind).size()


func _towers_near(state: BattleState, origin: Vector2, radius: float) -> int:
	return state.player_buildings().filter(func(b: Building) -> bool: return GameConfig.is_tower(b.kind) and b.position.distance_to(origin) <= radius).size()
