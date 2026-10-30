class_name EnemyAI
extends RefCounted

const LINK_PATH := -2
const PATROL_PATH := -3

var state: BattleState
var events: BattleEvents
var combat: Combat
var network: EnergyNetwork
var path_budget := 0
var _ranked := []
var _ranked_valid := false
var _ranked_version := -1
var _rank_timer := 0.0
var _by_component := {}
var _cut_cells := {}
var _cut_version := -1
var _load := {}


func _init(p_state: BattleState, p_events: BattleEvents, p_combat: Combat, p_network: EnergyNetwork) -> void:
	state = p_state
	events = p_events
	combat = p_combat
	network = p_network


func update(delta: float) -> void:
	path_budget = GameConfig.PATHS_PER_TICK
	_rank_timer -= delta
	if _rank_timer <= 0.0 or _ranked_version != state.nav.version:
		_ranked_valid = false
	_count_load()
	for enemy in state.enemies:
		if enemy.is_alive():
			_update(enemy, delta)


func _update(enemy: Enemy, delta: float) -> void:
	enemy.cooldown = maxf(enemy.cooldown - delta, 0.0)
	enemy.retarget_timer -= delta
	if enemy.is_guard():
		_patrol(enemy, delta)
		return
	if enemy.is_saboteur() and _sabotage(enemy, delta):
		return
	var target := state.building(enemy.target_id)
	if target == null or not target.is_alive() or enemy.retarget_timer <= 0.0:
		target = _choose(enemy)
		_assign(enemy, target)
		enemy.retarget_timer = GameConfig.RETARGET_TIME + state.rng.randf() * GameConfig.RETARGET_JITTER
	if target == null:
		return
	if in_reach(enemy, target):
		_attack(enemy, target)
		return
	if enemy.is_air():
		move(enemy, target.position, delta)
		return
	if enemy.path_target != target.id:
		if not _plan(enemy, target.id, func() -> PackedVector2Array: return state.nav.path_to_building(enemy.position, target)):
			return
	if not _follow(enemy, delta):
		move(enemy, closest_point(target, enemy.position), delta)


func choose_target(enemy: Enemy) -> Building:
	_ranked_valid = false
	_count_load()
	return _choose(enemy)


func load_of(id: int) -> int:
	return int(_load.get(id, 0))


func _count_load() -> void:
	_load.clear()
	for enemy in state.enemies:
		if enemy.is_attacker() and enemy.target_id >= 0 and enemy.target_link.is_empty():
			_load[enemy.target_id] = load_of(enemy.target_id) + 1


func _assign(enemy: Enemy, target: Building) -> void:
	var id := target.id if target != null else -1
	if id == enemy.target_id:
		return
	if load_of(enemy.target_id) > 0:
		_load[enemy.target_id] = load_of(enemy.target_id) - 1
	if id >= 0:
		_load[id] = load_of(id) + 1
	enemy.target_id = id


func _choose(enemy: Enemy) -> Building:
	if not _ranked_valid:
		_ranked_valid = true
		_ranked_version = state.nav.version
		_rank_timer = GameConfig.TARGET_SCAN
		_ranked = Targeting.rank(state.player_buildings())
		_by_component = {}
	if enemy.is_air():
		var players := state.player_buildings()
		var lure := Targeting.lure(enemy.position, players)
		if lure != null:
			return _settle(enemy, lure, func() -> Array[Building]: return Targeting.lures(players))
		return _settle(enemy, Targeting.best_ranked(enemy.position, _ranked), func() -> Array[Building]: return Targeting.peers(_ranked))
	var component := state.nav.component_at(enemy.position)
	if not _by_component.has(component):
		var reachable := state.nav.reachable(component)
		_by_component[component] = _ranked.filter(func(entry: Array) -> bool: return reachable.has(entry[0].id))
	var ranked: Array = _by_component[component]
	return _settle(enemy, Targeting.best_ranked(enemy.position, ranked), func() -> Array[Building]: return Targeting.peers(ranked))


func _settle(enemy: Enemy, best: Building, peers: Callable) -> Building:
	if best == null or enemy.target_id == best.id or load_of(best.id) < GameConfig.SPREAD_CROWD:
		return best
	var candidates: Array[Building] = peers.call()
	var current := state.building(enemy.target_id)
	if current != null and current.is_alive() and candidates.has(current):
		return current
	if state.rng.randf() >= GameConfig.SPREAD_CHANCE:
		return best
	var choice := Targeting.spread(enemy.position, best, candidates, _load, state.rng)
	return choice if choice != null else best


static func reach_distance(enemy: Enemy) -> float:
	return enemy.reach() if enemy.reach() > 0.0 else enemy.radius() + GameConfig.MELEE_GAP


static func in_reach(enemy: Enemy, target: Building) -> bool:
	return target.edge_distance(enemy.position) <= reach_distance(enemy)


static func closest_point(target: Building, from: Vector2) -> Vector2:
	var half := Vector2(target.half_extent(), target.half_extent())
	return from.clamp(target.position - half, target.position + half)


func _attack(enemy: Enemy, target: Building) -> void:
	if enemy.cooldown > 0.0:
		return
	enemy.cooldown = float(enemy.definition().cooldown)
	enemy.heading = (target.position - enemy.position).normalized() if target.position != enemy.position else enemy.heading
	events.emit("enemy_attack", {"from": enemy.position, "to": target.position, "ranged": enemy.reach() > 0.0, "kind": enemy.kind})
	combat.damage_building(target, enemy.damage())


func _patrol(enemy: Enemy, delta: float) -> void:
	var post := state.building(enemy.post)
	if post == null or not post.is_alive() or enemy.is_burning() or enemy.retarget_timer > 0.0:
		return
	var goal := patrol_point(enemy, post)
	if enemy.is_air():
		move(enemy, goal, delta)
		if enemy.position == goal:
			_next_waypoint(enemy)
		return
	if enemy.path_target != PATROL_PATH:
		var cell := state.nav.nearest_free(goal)
		if cell == Vector2i(-1, -1):
			_next_waypoint(enemy)
			return
		if not _plan(enemy, PATROL_PATH, func() -> PackedVector2Array: return state.nav.ground_path(enemy.position, cell)):
			return
	if not _follow(enemy, delta):
		_next_waypoint(enemy)


static func patrol_point(enemy: Enemy, post: Building) -> Vector2:
	return post.position + Vector2.from_angle(enemy.patrol_angle) * Formulas.guard_ring(post)


func _next_waypoint(enemy: Enemy) -> void:
	enemy.patrol_angle = fposmod(enemy.patrol_angle + GameConfig.GUARD_STEP * enemy.patrol_turn, TAU)
	enemy.path_target = -1
	enemy.retarget_timer = state.rng.randf_range(GameConfig.GUARD_PAUSE_MIN, GameConfig.GUARD_PAUSE_MAX)


func _plan(enemy: Enemy, key: int, finder: Callable) -> bool:
	if path_budget <= 0:
		return enemy.path_index < enemy.path.size()
	path_budget -= 1
	enemy.path = finder.call()
	enemy.path_index = 1 if enemy.path.size() > 1 and state.map.cell_of(enemy.position) == state.map.cell_of(enemy.path[0]) else 0
	enemy.path_target = key
	enemy.path_version = state.nav.version
	return true


func _follow(enemy: Enemy, delta: float) -> bool:
	if enemy.path_index >= enemy.path.size():
		return false
	var waypoint := enemy.path[enemy.path_index]
	if state.nav.is_blocked_at(waypoint):
		enemy.path_target = -1
		return true
	var goal := waypoint + enemy.approach * GameConfig.CELL * GameConfig.SPREAD
	move(enemy, goal, delta)
	if enemy.position == goal:
		enemy.path_index += 1
	return true


func move(enemy: Enemy, goal: Vector2, delta: float) -> void:
	var offset := goal - enemy.position
	var step := enemy.speed() * delta
	if offset.length() <= step:
		enemy.position = goal
		return
	enemy.heading = offset.normalized()
	enemy.position += enemy.heading * step


func _sabotage(enemy: Enemy, delta: float) -> bool:
	if state.links.is_empty():
		return false
	var link := _link_by_key(enemy.target_link)
	if link == null or enemy.retarget_timer <= 0.0:
		enemy.retarget_timer = GameConfig.RETARGET_TIME + state.rng.randf() * GameConfig.RETARGET_JITTER
		var choice := reachable_link(enemy)
		if choice.is_empty():
			enemy.target_link = ""
			return false
		link = choice.link
		if link.key() != enemy.target_link or choice.cell != enemy.link_cell:
			enemy.target_link = link.key()
			enemy.link_cell = choice.cell
			enemy.path_target = -1
	var points := state.link_points(link)
	var distance := enemy.position.distance_to(Geometry2D.get_closest_point_to_segment(enemy.position, points[0], points[1]))
	if distance <= GameConfig.SABOTAGE_REACH or state.map.cell_of(enemy.position) == enemy.link_cell:
		network.remove_link(link, "sabotage")
		enemy.target_link = ""
		enemy.retarget_timer = 0.0
		enemy.path_target = -1
		return true
	if enemy.path_target != LINK_PATH:
		var goal := enemy.link_cell
		if not _plan(enemy, LINK_PATH, func() -> PackedVector2Array: return state.nav.ground_path(enemy.position, goal)):
			return true
	if not _follow(enemy, delta):
		enemy.path_target = -1
		enemy.retarget_timer = 0.0
	return true


func _link_by_key(key: String) -> EnergyLink:
	if key.is_empty():
		return null
	for link in state.links:
		if link.key() == key:
			return link
	return null


func cut_cells(link: EnergyLink) -> Array[Vector2i]:
	if _cut_version != state.nav.version:
		_cut_version = state.nav.version
		_cut_cells = {}
	var key := link.key()
	if _cut_cells.has(key):
		return _cut_cells[key]
	var points := state.link_points(link)
	var reach := GameConfig.CELL * GameConfig.SABOTAGE_CUT
	var found := {}
	var samples := maxi(ceili(points[0].distance_to(points[1]) / GameConfig.CELL), 1)
	for i in samples + 1:
		var center := state.map.cell_of(points[0].lerp(points[1], float(i) / samples))
		for y in range(-1, 2):
			for x in range(-1, 2):
				var cell := center + Vector2i(x, y)
				if found.has(cell) or not state.nav.is_free(cell):
					continue
				var middle := state.map.center_of(cell)
				if middle.distance_to(Geometry2D.get_closest_point_to_segment(middle, points[0], points[1])) <= reach:
					found[cell] = true
	var cells: Array[Vector2i] = []
	cells.assign(found.keys())
	_cut_cells[key] = cells
	return cells


func reachable_link(enemy: Enemy) -> Dictionary:
	var component := state.nav.component_at(enemy.position)
	var best := {}
	var best_distance := INF
	for link in state.links:
		for cell in cut_cells(link):
			var distance := enemy.position.distance_squared_to(state.map.center_of(cell))
			if distance < best_distance and state.nav.component(cell) == component:
				best = {"link": link, "cell": cell}
				best_distance = distance
	return best


func nearest_link(origin: Vector2) -> EnergyLink:
	var best: EnergyLink = null
	var best_distance := INF
	for link in state.links:
		var points := state.link_points(link)
		var distance := origin.distance_to(Geometry2D.get_closest_point_to_segment(origin, points[0], points[1]))
		if distance < best_distance:
			best = link
			best_distance = distance
	return best
