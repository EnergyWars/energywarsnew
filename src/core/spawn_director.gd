class_name SpawnDirector
extends RefCounted

var state: BattleState
var events: BattleEvents


func _init(p_state: BattleState, p_events: BattleEvents) -> void:
	state = p_state
	events = p_events


func update(delta: float) -> void:
	if state.phase != BattleState.Phase.FIGHT:
		return
	burn(delta)
	if state.night_over:
		return
	reinforce(delta)
	var level := state.level
	while state.waves_sent < Formulas.wave_times(level) and state.round_time >= Formulas.wave_time(level, state.waves_sent):
		send_wave()
	for spawner in state.enemy_buildings():
		if spawner.spawner and spawner.spawn_queue > 0:
			_release(spawner, delta)


func start_round() -> bool:
	if state.phase != BattleState.Phase.PLAN:
		return false
	state.phase = BattleState.Phase.FIGHT
	state.round_time = 0.0
	state.waves_sent = 0
	state.last_raid_wave = -GameConfig.AIR_RAID_GAP
	state.night_over = false
	for building in state.player_buildings():
		building.plan_spent = 0
	for spawner in state.enemy_buildings():
		spawner.spawn_queue = 0
		spawner.spawn_progress = 0.0
		spawner.guard_timer = GameConfig.GUARD_FIRST
	events.emit("fight_started", {"round": state.round_number})
	return true


func end_night() -> void:
	if state.night_over:
		return
	state.night_over = true
	for spawner in state.enemy_buildings():
		spawner.spawn_queue = 0
	var ignited := 0
	for enemy in state.enemies:
		if enemy.is_attacker() and enemy.is_nocturnal():
			ignite(enemy)
			ignited += 1
	events.emit("night_over", {"round": state.round_number, "left": state.attackers() - ignited, "burning": ignited})


func ignite(enemy: Enemy) -> void:
	if not enemy.is_burning():
		enemy.burn = state.rng.randf_range(GameConfig.BURN_MIN, GameConfig.BURN_MAX)


func ignite_guards() -> int:
	var count := 0
	for enemy in state.enemies:
		if enemy.is_alive() and enemy.is_guard() and not enemy.is_burning():
			ignite(enemy)
			count += 1
	if count > 0:
		events.emit("guards_ignited", {"count": count})
	return count


func guard_counts() -> Dictionary:
	var counts := {}
	for enemy in state.enemies:
		if enemy.is_alive() and enemy.is_guard() and not enemy.is_burning():
			counts[enemy.post] = int(counts.get(enemy.post, 0)) + 1
	return counts


func reinforce(delta: float) -> int:
	for enemy in state.enemies:
		if enemy.is_alive() and enemy.is_guard() and not enemy.is_burning() and not _post_alive(enemy):
			ignite(enemy)
	var counts := guard_counts()
	var spawned := 0
	var target := Formulas.guard_count(state.round_number)
	for spawner in state.enemy_buildings():
		if not spawner.spawner or not spawner.is_alive() or GameConfig.guard(spawner.kind).is_empty():
			continue
		var count := int(counts.get(spawner.id, 0))
		if count >= target:
			spawner.guard_timer = GameConfig.GUARD_RESPAWN
			continue
		spawner.guard_timer -= delta
		if spawner.guard_timer > 0.0:
			continue
		spawn_guard(spawner)
		spawned += 1
		spawner.guard_timer = GameConfig.GUARD_TRICKLE if count + 1 < target else GameConfig.GUARD_RESPAWN
	return spawned


func _post_alive(enemy: Enemy) -> bool:
	var post := state.building(enemy.post)
	return post != null and post.is_alive()


func spawn_guard(spawner: Building) -> Enemy:
	var config := GameConfig.guard(spawner.kind)
	var kind := str(config.kind)
	var angle := state.rng.randf() * TAU
	var point := spawner.position + Vector2.from_angle(angle) * Formulas.guard_ring(spawner)
	if GameConfig.enemy(kind).get("class", "") != GameConfig.CLASS_AIR:
		var cell := state.nav.nearest_free(point)
		if cell != Vector2i(-1, -1):
			point = state.map.center_of(cell)
	var round_number := state.round_number
	var hp_scale := float(config.hp) * Formulas.enemy_hp_scale(round_number)
	var bounty_scale := GameConfig.GUARD_BOUNTY * Formulas.enemy_bounty_scale(round_number)
	var enemy := Enemy.new(state.next_id(), kind, point, hp_scale, Formulas.enemy_damage_scale(round_number), bounty_scale)
	enemy.make_guard(spawner.id, angle, 1.0 if state.rng.randf() < 0.5 else -1.0)
	state.enemies.append(enemy)
	events.emit("spawn", {"position": enemy.position, "kind": kind, "boss": false, "guard": true})
	return enemy


func burn(delta: float) -> int:
	var burned := 0
	for enemy in state.enemies:
		if not enemy.is_alive() or not enemy.is_burning():
			continue
		enemy.burn -= delta
		if enemy.burn > 0.0:
			continue
		enemy.burn = 0.0
		enemy.hp = 0.0
		burned += 1
		events.emit("burned", {"position": enemy.position, "kind": enemy.kind, "boss": enemy.is_boss()})
	return burned


func send_wave() -> int:
	var night := DayCycle.is_night(state.round_time, state.level)
	var progress := state.round_time / DayCycle.length(state.level)
	var count := Formulas.wave_count(state.level.waves, state.round_number, progress, night) * GameConfig.GROUND_WAVE_BONUS
	var total := 0
	for spawner in state.enemy_buildings():
		if not spawner.spawner:
			continue
		spawner.spawn_progress += count
		var whole := maxi(int(floor(spawner.spawn_progress)), 1)
		spawner.spawn_progress -= whole
		spawner.spawn_queue = mini(spawner.spawn_queue + whole, GameConfig.WAVE_MAX)
		spawner.spawn_heading = state.rng.randf() * TAU
		spawner.spawn_timer = 0.0
		total += whole
	state.waves_sent += 1
	if raid_due():
		total += air_raid(night)
	events.emit("wave", {"index": state.waves_sent, "total": Formulas.wave_times(state.level), "night": night, "round": state.round_number, "count": total})
	return total


func _release(spawner: Building, delta: float) -> void:
	spawner.spawn_timer -= delta
	if spawner.spawn_timer > 0.0:
		return
	spawner.spawn_timer = GameConfig.WAVE_TRICKLE
	spawner.spawn_queue -= 1
	spawn(spawner, spawner.spawn_heading + (state.rng.randf() - 0.5) * GameConfig.PACK_SPREAD * TAU)


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
	var round_number := state.round_number
	var enemy := Enemy.new(state.next_id(), kind, point, Formulas.enemy_hp_scale(round_number), Formulas.enemy_damage_scale(round_number) * _damage_bonus(kind), Formulas.enemy_bounty_scale(round_number))
	enemy.approach = Vector2.from_angle(state.rng.randf() * TAU) * state.rng.randf()
	state.enemies.append(enemy)
	events.emit("spawn", {"position": enemy.position, "kind": kind, "boss": enemy.is_boss()})
	return enemy


func _damage_bonus(kind: String) -> float:
	return 1.0 if GameConfig.enemy(kind).get("class", "") == GameConfig.CLASS_AIR else GameConfig.GROUND_DAMAGE_BONUS


func raid_due() -> bool:
	if state.round_number < GameConfig.AIR_RAID_FIRST_ROUND:
		return false
	if state.waves_sent - state.last_raid_wave < GameConfig.AIR_RAID_GAP:
		return false
	return state.rng.randf() < GameConfig.AIR_RAID_CHANCE


func raid_kinds(night: bool) -> Array:
	var kinds := []
	for spawner in state.enemy_buildings():
		if not spawner.spawner:
			continue
		for kind: String in GameConfig.SPAWNER_FACTIONS.get(spawner.kind, []):
			var definition := GameConfig.enemy(kind)
			if definition.get("class", "") == GameConfig.CLASS_AIR and GameConfig.is_nocturnal(kind) == night and not kinds.has(kind):
				kinds.append(kind)
	return kinds


func raid_size() -> int:
	var growth := (state.round_number - GameConfig.AIR_RAID_FIRST_ROUND) / 2
	return mini(state.rng.randi_range(GameConfig.AIR_RAID_MIN, GameConfig.AIR_RAID_MAX) + growth, GameConfig.AIR_RAID_CAP)


func raid_origin() -> Vector2:
	var extent := Vector2(state.map.width, state.map.height) * GameConfig.CELL
	var margin := GameConfig.AIR_RAID_MARGIN
	var along := state.rng.randf()
	match state.rng.randi_range(0, 3):
		0:
			return Vector2(lerpf(margin, extent.x - margin, along), margin)
		1:
			return Vector2(lerpf(margin, extent.x - margin, along), extent.y - margin)
		2:
			return Vector2(margin, lerpf(margin, extent.y - margin, along))
	return Vector2(extent.x - margin, lerpf(margin, extent.y - margin, along))


func air_raid(night: bool) -> int:
	var kinds := raid_kinds(night)
	if kinds.is_empty():
		return 0
	state.last_raid_wave = state.waves_sent
	var origin := raid_origin()
	var size := raid_size()
	var round_number := state.round_number
	for index in size:
		var kind: String = kinds[state.rng.randi_range(0, kinds.size() - 1)]
		var point := origin + Vector2.from_angle(state.rng.randf() * TAU) * state.rng.randf() * GameConfig.AIR_RAID_SPREAD
		var enemy := Enemy.new(state.next_id(), kind, point, Formulas.enemy_hp_scale(round_number), Formulas.enemy_damage_scale(round_number), Formulas.enemy_bounty_scale(round_number))
		enemy.approach = Vector2.from_angle(state.rng.randf() * TAU) * state.rng.randf()
		state.enemies.append(enemy)
		events.emit("spawn", {"position": enemy.position, "kind": kind, "boss": false})
	events.emit("air_raid", {"position": origin, "count": size, "night": night, "round": round_number})
	return size


func candidates(spawner_kind: String) -> Array:
	var faction: Array = GameConfig.SPAWNER_FACTIONS.get(spawner_kind, [])
	var tier := Formulas.wave_tier(state.round_number)
	var result := []
	for entry: Array in roster():
		if faction.has(entry[0]) and tier >= int(entry[1]):
			result.append(entry)
	return result


func roster() -> Array:
	return state.level.waves.get("night_roster", GameConfig.EMPTY_LIST) if state.is_night() else state.level.waves.roster


func pick_kind(spawner_kind: String) -> String:
	var options := candidates(spawner_kind)
	if options.is_empty():
		return fallback_kind(spawner_kind)
	var total := 0.0
	for entry: Array in options:
		total += float(entry[2])
	var roll := state.rng.randf() * total
	for entry: Array in options:
		roll -= float(entry[2])
		if roll <= 0.0:
			return str(entry[0])
	return str(options[options.size() - 1][0])


func fallback_kind(spawner_kind: String) -> String:
	var faction: Array = GameConfig.SPAWNER_FACTIONS.get(spawner_kind, ["crawler"])
	var night := state.is_night()
	for kind: String in faction:
		if GameConfig.is_nocturnal(kind) == night:
			return kind
	return str(faction[0])
