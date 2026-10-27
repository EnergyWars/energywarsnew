class_name SpawnDirector
extends RefCounted

var state: BattleState
var events: BattleEvents


func _init(p_state: BattleState, p_events: BattleEvents) -> void:
	state = p_state
	events = p_events


func update(delta: float) -> void:
	match state.phase:
		BattleState.Phase.PREP:
			state.prep_left = maxf(state.prep_left - delta, 0.0)
			if state.prep_left <= 0.0:
				start_fight()
		BattleState.Phase.FIGHT:
			_advance_cycle(delta)
			var rate_phase := phase()
			var night := state.is_night()
			for spawner in state.enemy_buildings():
				if spawner.definition().get("spawns", false):
					_feed(spawner, Formulas.spawn_rate(state.level.spawns, state.cycle, rate_phase, night) * delta)


func start_fight() -> void:
	if state.phase != BattleState.Phase.PREP:
		return
	state.phase = BattleState.Phase.FIGHT
	state.prep_left = 0.0
	state.cycle = 0
	state.cycle_time = 0.0
	state.surge_announced = false
	events.emit("fight_started")


func skip_prep() -> int:
	if state.phase != BattleState.Phase.PREP:
		return 0
	var bonus := int(floor(state.prep_left)) * GameConfig.SKIP_PREP_BONUS
	state.money += bonus
	start_fight()
	return bonus


func phase() -> float:
	return clampf(state.cycle_time / float(state.level.spawns.cycle), 0.0, 1.0)


func _advance_cycle(delta: float) -> void:
	var length := float(state.level.spawns.cycle)
	state.cycle_time += delta
	if state.cycle_time >= length:
		state.cycle_time -= length
		state.cycle += 1
		state.surge_announced = false
	if not state.surge_announced and phase() >= GameConfig.SURGE_PHASE:
		state.surge_announced = true
		events.emit("surge", {"cycle": state.cycle, "night": state.is_night()})


func _feed(spawner: Building, amount: float) -> void:
	spawner.spawn_progress += amount
	var pack := Formulas.pack_size(state.cycle)
	if spawner.spawn_progress < pack:
		return
	spawner.spawn_progress -= pack
	var heading := state.rng.randf() * TAU
	for i in pack:
		spawn(spawner, heading + (state.rng.randf() - 0.5) * GameConfig.PACK_SPREAD * TAU)


func spawn(spawner: Building, angle: float = INF) -> Enemy:
	var kind := pick_kind(spawner.kind)
	if is_inf(angle):
		angle = state.rng.randf() * TAU
	var distance := spawner.half_extent() + GameConfig.CELL * (0.5 + state.rng.randf() * GameConfig.SPAWN_RING)
	var point := spawner.position + Vector2.from_angle(angle) * distance
	if GameConfig.enemy(kind).get("class", "") != GameConfig.CLASS_AIR:
		var cell := state.nav.nearest_free(point)
		if cell != Vector2i(-1, -1):
			point = state.map.center_of(cell)
	var enemy := Enemy.new(state.next_id(), kind, point, state.cycle)
	enemy.approach = Vector2.from_angle(state.rng.randf() * TAU) * state.rng.randf()
	state.enemies.append(enemy)
	events.emit("spawn", {"position": enemy.position, "kind": kind, "boss": enemy.is_boss()})
	return enemy


func candidates(spawner_kind: String) -> Array:
	var faction: Array = GameConfig.SPAWNER_FACTIONS.get(spawner_kind, [])
	var result := []
	for entry: Array in state.level.spawns.roster:
		if faction.has(entry[0]) and state.cycle >= int(entry[1]):
			result.append(entry)
	return result


func pick_kind(spawner_kind: String) -> String:
	var options := candidates(spawner_kind)
	if options.is_empty():
		var faction: Array = GameConfig.SPAWNER_FACTIONS.get(spawner_kind, ["crawler"])
		return str(faction[0])
	var total := 0.0
	for entry: Array in options:
		total += float(entry[2])
	var roll := state.rng.randf() * total
	for entry: Array in options:
		roll -= float(entry[2])
		if roll <= 0.0:
			return str(entry[0])
	return str(options[options.size() - 1][0])
