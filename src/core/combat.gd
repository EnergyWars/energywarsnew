class_name Combat
extends RefCounted

const OK := ""
const INVALID := "invalid"
const MISSING := "missing"
const CANNOT := "cannot"
const RANGE := "range"

var state: BattleState
var events: BattleEvents
var economy: Economy
var network: EnergyNetwork
var lighting: Lighting


func _init(p_state: BattleState, p_events: BattleEvents, p_economy: Economy, p_network: EnergyNetwork) -> void:
	state = p_state
	events = p_events
	economy = p_economy
	network = p_network


func update(delta: float) -> void:
	var groups := group_enemies()
	for building in state.combatants():
		if not building.is_alive():
			continue
		if building.is_player():
			if building.armed:
				_tower(building, delta, groups)
			else:
				_healer(building, delta)
		else:
			_turret(building, delta)
	_garrison(delta, groups)
	_projectiles(delta)


func group_enemies() -> Dictionary:
	var groups := {"structures": state.enemy_buildings()}
	for unit_class in GameConfig.CLASSES:
		groups[unit_class] = [] as Array[Enemy]
	for enemy in state.enemies:
		if enemy.is_alive():
			groups[enemy.unit_class()].append(enemy)
	return groups


func _tower(tower: Building, delta: float, groups: Dictionary) -> void:
	tower.cooldown = maxf(tower.cooldown - delta, 0.0)
	tower.scan_timer -= delta
	var mode := str(Formulas.attack(tower).mode)
	if mode == GameConfig.MODE_LASER:
		_laser(tower, _laser_target(tower, groups), delta)
		return
	if tower.cooldown > 0.0 or tower.scan_timer > 0.0 or tower.energy < Formulas.shot_energy(tower):
		return
	var target := find_target(tower, groups)
	if target == null:
		tower.scan_timer = GameConfig.TARGET_SCAN
		return
	tower.energy -= Formulas.shot_energy(tower)
	tower.cooldown = Formulas.cooldown(tower)
	tower.target_id = target.id
	var crit := state.rng.randf() < Formulas.crit_chance(tower)
	var amount := Formulas.damage(tower) * (GameConfig.CRIT_FACTOR if crit else 1.0)
	match mode:
		GameConfig.MODE_BOLT:
			events.emit("bolt", {"from": tower.position, "to": target.position, "crit": crit})
			damage(target, amount, crit)
		GameConfig.MODE_CHAIN:
			_chain(tower, target, amount, crit)
		GameConfig.MODE_PLASMA:
			var splash := Formulas.splash(tower)
			var projectile := Projectile.new(tower.position, target.position, amount, splash, crit)
			projectile.obstacle = target as Obstacle
			state.projectiles.append(projectile)
			events.emit("plasma_launch", {"from": tower.position, "to": target.position})


func _laser_target(tower: Building, groups: Dictionary) -> Object:
	var focus := focus_in_range(tower)
	if focus != null:
		tower.laser_target = focus
		return focus
	var current: Object = tower.laser_target
	var valid: bool = current != null and current.is_alive() and tower.position.distance_to(current.position) <= Formulas.attack_range(tower) + current.radius() and can_see(current)
	if tower.scan_timer > 0.0 and (valid or current == null):
		return current if valid else null
	tower.scan_timer = GameConfig.TARGET_SCAN
	tower.laser_target = find_target(tower, groups)
	return tower.laser_target


func _laser(tower: Building, target: Object, delta: float) -> void:
	var cost := Formulas.shot_energy(tower) * delta
	tower.firing = target != null and tower.energy >= cost
	if not tower.firing:
		tower.target_id = -1
		return
	tower.energy -= cost
	tower.target_id = target.id
	var amount := Formulas.damage(tower) * delta
	tower.laser_damage += amount
	tower.laser_timer += delta
	var report := tower.laser_timer >= GameConfig.LASER_REPORT
	if report:
		events.emit("hit", {"position": target.position, "amount": tower.laser_damage, "crit": false})
		tower.laser_damage = 0.0
		tower.laser_timer = 0.0
	damage(target, amount, false, false)


func _chain(tower: Building, first: Object, amount: float, crit: bool) -> void:
	var points := PackedVector2Array([tower.position])
	var hit := {}
	var current: Object = first
	var strength := amount
	for jump in Formulas.chain_count(tower):
		if current == null:
			break
		hit[current.id] = true
		points.append(current.position)
		var origin: Vector2 = current.position
		damage(current, strength, crit)
		strength *= GameConfig.CHAIN_DECAY
		current = _nearest_enemy(origin, GameConfig.CHAIN_JUMP, hit, tower)
	events.emit("chain", {"points": points, "crit": crit})


func _projectiles(delta: float) -> void:
	if state.projectiles.is_empty():
		return
	for projectile: Projectile in state.projectiles.duplicate():
		projectile.elapsed += delta
		if not projectile.is_done():
			continue
		state.projectiles.erase(projectile)
		var center := projectile.destination
		events.emit("plasma_hit", {"position": center, "splash": projectile.splash, "crit": projectile.crit})
		for enemy in state.enemies:
			if enemy.is_alive() and not enemy.is_air() and center.distance_to(enemy.position) <= projectile.splash + enemy.radius():
				damage(enemy, projectile.damage, projectile.crit)
		for building in state.enemy_buildings():
			if center.distance_to(building.position) <= projectile.splash + building.radius():
				damage(building, projectile.damage, projectile.crit)
		if projectile.obstacle != null and projectile.obstacle.is_alive():
			damage(projectile.obstacle, projectile.damage, projectile.crit)


func _turret(turret: Building, delta: float) -> void:
	turret.cooldown = maxf(turret.cooldown - delta, 0.0)
	if turret.cooldown > 0.0:
		return
	var target := turret_target(turret)
	if target == null:
		return
	turret.cooldown = Formulas.cooldown(turret)
	events.emit("enemy_shot", {"from": turret.position, "to": target.position, "heavy": true})
	damage_building(target, Formulas.damage(turret))


func _healer(healer: Building, delta: float) -> void:
	healer.cooldown = maxf(healer.cooldown - delta, 0.0)
	if healer.cooldown > 0.0 or healer.energy < Formulas.heal_energy(healer):
		return
	var patient := heal_target(healer)
	if patient == null:
		healer.target_id = -1
		return
	var amount := minf(Formulas.heal_amount(healer), patient.max_hp() - patient.hp)
	patient.hp += amount
	healer.energy -= Formulas.heal_energy(healer)
	healer.cooldown = Formulas.heal_cooldown(healer)
	healer.target_id = patient.id
	events.emit("heal", {"from": healer.position, "to": patient.position, "amount": amount})


func heal_target(healer: Building) -> Building:
	var reach := Formulas.heal_range(healer)
	var best: Building = null
	var best_score := -INF
	for building in state.player_buildings():
		if building.hp >= building.max_hp() or healer.position.distance_to(building.position) > reach + building.radius():
			continue
		var score := heal_priority(building) + state.rng.randf() * GameConfig.HEAL_JITTER
		if score > best_score:
			best = building
			best_score = score
	return best


func heal_priority(building: Building) -> float:
	var score := 1.0 - building.hp_ratio()
	if state.time - building.hit_time <= GameConfig.HEAL_RECENT:
		score += GameConfig.HEAL_UNDER_FIRE
	if building.id == state.core_id:
		score += GameConfig.HEAL_CORE_BONUS
	return score


func turret_target(turret: Building) -> Building:
	var reach := Formulas.attack_range(turret)
	var candidates: Array[Building] = []
	for building in state.player_buildings():
		if building.edge_distance(turret.position) <= reach:
			candidates.append(building)
	return Targeting.best(turret.position, candidates)


func _garrison(delta: float, groups: Dictionary) -> void:
	var scout := state.scout
	var core := state.core()
	if scout == null or not scout.boarded or core == null:
		return
	scout.position = core.position
	scout.cooldown = maxf(scout.cooldown - delta, 0.0)
	if scout.cooldown > 0.0:
		return
	var reach := float(GameConfig.SCOUT_GUN.range)
	var target: Enemy = null
	var best := INF
	for unit_class in GameConfig.CLASSES:
		for enemy: Enemy in groups[unit_class]:
			var distance := core.position.distance_to(enemy.position)
			if enemy.is_alive() and distance <= reach + enemy.radius() and distance < best and can_see(enemy):
				target = enemy
				best = distance
	if target == null:
		scout.target_id = -1
		scout.cooldown = GameConfig.TARGET_SCAN
		return
	scout.cooldown = float(GameConfig.SCOUT_GUN.cooldown)
	scout.target_id = target.id
	scout.heading = (target.position - core.position).normalized()
	events.emit("rifle", {"from": core.position, "to": target.position})
	damage(target, float(GameConfig.SCOUT_GUN.damage), false)


func focus_reason(tower: Building, target: Object) -> String:
	if tower == null or not tower.is_player() or not GameConfig.has_attack(tower.kind):
		return INVALID
	if target == null or not target.is_alive():
		return MISSING
	if target is Building and (target as Building).is_player():
		return INVALID
	if target is Building and (target as Building).immune:
		return CANNOT
	var attack := Formulas.attack(tower)
	var air := target is Enemy and (target as Enemy).is_air()
	if not bool(attack.get("air" if air else "ground", true)):
		return CANNOT
	if not target is Enemy and not in_attack_range(tower, target):
		return RANGE
	return OK


func set_focus(tower: Building, target: Object) -> String:
	if target == null and tower != null and tower.is_player():
		tower.focus = null
		return OK
	var reason := focus_reason(tower, target)
	if reason == OK:
		tower.focus = target
		tower.scan_timer = 0.0
		events.emit("focus", {"id": tower.id, "from": tower.position, "to": target.position})
	return reason


func focused(tower: Building) -> Object:
	var focus: Object = tower.focus
	if focus == null:
		return null
	var valid: bool = focus.is_alive()
	if focus is Obstacle:
		valid = valid and state.map.is_clearable((focus as Obstacle).cell)
	if not valid:
		tower.focus = null
		return null
	return focus


func focus_in_range(tower: Building) -> Object:
	var focus := focused(tower)
	return focus if focus != null and in_attack_range(tower, focus) and can_see(focus) else null


func can_see(target: Object) -> bool:
	return lighting == null or lighting.sees(target.position, float(target.radius()))


func in_attack_range(tower: Building, target: Object) -> bool:
	var distance := tower.position.distance_to(target.position)
	var minimum := float(Formulas.attack(tower).get("min_range", 0.0))
	return distance >= minimum and distance <= Formulas.attack_range(tower) + float(target.radius())


func find_target(tower: Building, groups: Dictionary = {}) -> Object:
	var focus := focus_in_range(tower)
	if focus != null:
		return focus
	if groups.is_empty():
		groups = group_enemies()
	var attack := Formulas.attack(tower)
	var reach := Formulas.attack_range(tower)
	var minimum := float(attack.get("min_range", 0.0))
	for unit_class in tower.target_order:
		if not tower.can_target(unit_class):
			continue
		var best: Enemy = null
		var best_distance := INF
		for enemy: Enemy in groups[unit_class]:
			if not enemy.is_alive():
				continue
			var distance := tower.position.distance_to(enemy.position)
			if distance >= minimum and distance <= reach + enemy.radius() and distance < best_distance and can_see(enemy):
				best = enemy
				best_distance = distance
		if best != null:
			return best
	if not tower.can_target(GameConfig.CLASS_MELEE) and not tower.can_target(GameConfig.CLASS_RANGED):
		return null
	var structure: Building = null
	var structure_distance := INF
	for building: Building in groups.structures:
		if not building.is_alive() or building.immune:
			continue
		var distance := tower.position.distance_to(building.position)
		if distance >= minimum and distance <= reach + building.radius() and distance < structure_distance and can_see(building):
			structure = building
			structure_distance = distance
	return structure


func _nearest_enemy(origin: Vector2, reach: float, exclude: Dictionary, tower: Building) -> Enemy:
	var best: Enemy = null
	var best_distance := INF
	for enemy in state.enemies:
		if not enemy.is_alive() or exclude.has(enemy.id) or not tower.can_target(enemy.unit_class()):
			continue
		var distance := origin.distance_to(enemy.position)
		if distance <= reach and distance < best_distance and can_see(enemy):
			best = enemy
			best_distance = distance
	return best


func nearest_player_building(origin: Vector2, reach: float = INF) -> Building:
	var best: Building = null
	var best_distance := INF
	for building in state.player_buildings():
		var distance := origin.distance_to(building.position) - building.radius()
		if distance <= reach and distance < best_distance:
			best = building
			best_distance = distance
	return best


func damage(target: Object, amount: float, crit: bool, report: bool = true) -> void:
	if target is Enemy:
		damage_enemy(target as Enemy, amount, crit, report)
	elif target is Obstacle:
		damage_obstacle(target as Obstacle, amount, crit, report)
	elif target is Building:
		var building := target as Building
		if report:
			events.emit("hit", {"position": building.position, "amount": amount, "crit": crit})
		damage_building(building, amount)


func damage_enemy(enemy: Enemy, amount: float, crit: bool, report: bool = true) -> void:
	if not enemy.is_alive():
		return
	enemy.hp -= amount
	if report:
		events.emit("hit", {"position": enemy.position, "amount": amount, "crit": crit})
	if not enemy.is_alive():
		economy.enemy_killed(enemy)


func damage_obstacle(obstacle: Obstacle, amount: float, crit: bool, report: bool = true) -> void:
	if not obstacle.is_alive():
		return
	obstacle.hp -= amount
	if report:
		events.emit("hit", {"position": obstacle.position, "amount": amount, "crit": crit})
	if not obstacle.is_alive():
		state.clear_obstacle(obstacle.cell)
		events.emit("cleared", {"position": obstacle.position, "obstacle": obstacle.type, "cell": obstacle.cell})


func damage_building(building: Building, amount: float) -> void:
	if not building.is_alive() or building.immune:
		return
	var remaining := amount
	if building.is_player():
		building.hit_time = state.time
		remaining = _absorb(building, remaining)
	if remaining <= 0.0:
		return
	building.hp -= remaining
	events.emit("building_hit", {"id": building.id, "position": building.position, "amount": remaining, "player": building.is_player()})
	if not building.is_alive():
		destroy(building)


func _absorb(building: Building, amount: float) -> float:
	var remaining := amount
	for shield in state.of_kind(GameConfig.SHIELD):
		if remaining <= 0.0:
			break
		if shield.energy <= 0.0:
			continue
		if shield.position.distance_to(building.position) > Formulas.shield_radius(shield):
			continue
		var ratio := Formulas.shield_ratio(shield)
		var absorbed := minf(remaining, shield.energy * ratio)
		shield.energy -= absorbed / ratio
		remaining -= absorbed
		events.emit("shielded", {"position": building.position, "shield": shield.position, "amount": absorbed})
	return remaining


func destroy(building: Building) -> void:
	building.hp = 0.0
	network.remove_links_of(building.id)
	state.remove_building(building.id)
	if building.is_player():
		state.lost += 1
		events.emit("building_destroyed", {"position": building.position, "kind": building.kind, "core": building.id == state.core_id})
	else:
		economy.structure_destroyed(building)
		events.emit("structure_destroyed", {"position": building.position, "kind": building.kind, "bounty": int(building.definition().get("bounty", 0)), "left": state.enemy_buildings().size()})
