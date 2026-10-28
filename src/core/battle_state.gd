class_name BattleState
extends RefCounted

const EMPTY_LIST: Array[Building] = []

enum Phase { SCOUT, PLAN, FIGHT, WON, LOST }

var level_index: int
var level: Dictionary
var map: LevelMap
var nav: NavGrid
var fog: FogOfWar
var scout: Scout
var phase := Phase.SCOUT
var money := 0
var time := 0.0
var round_number := 1
var round_time := 0.0
var waves_sent := 0
var night_over := false
var days_survived := 0
var setup := BattleSetup.new()
var buildings := {}
var links: Array[EnergyLink] = []
var enemies: Array[Enemy] = []
var projectiles: Array[Projectile] = []
var pickups: Array[Pickup] = []
var obstacles := {}
var rng := RandomNumberGenerator.new()
var core_id := -1
var kills := 0
var lost := 0
var earned := 0
var best_combo := 0
var structures_destroyed := 0
var roster_version := 0
var links_version := 0
var layout_version := 0
var _next_id := 1
var _cache_version := -1
var _players: Array[Building] = []
var _structures: Array[Building] = []
var _by_kind := {}
var _combatants: Array[Building] = []
var _producers: Array[Building] = []
var _stores: Array[Building] = []
var _beam_counts := {}
var _beam_version := -1


static func create(index: int, seed_value: int = 0, p_setup: BattleSetup = null) -> BattleState:
	var state := BattleState.new()
	if p_setup != null:
		state.setup = p_setup
	state.level_index = clampi(index, 0, GameConfig.level_count() - 1)
	state.level = GameConfig.level(state.level_index)
	state.map = LevelMap.create(state.level)
	state.nav = NavGrid.new(state.map)
	state.fog = FogOfWar.new(state.map)
	state.scout = Scout.new(state.map.drop)
	state.money = int(state.level.money) + state.setup.arsenal.money_bonus
	state.rng.seed = seed_value if seed_value != 0 else int(state.level.seed) * 7919
	for structure in state.map.structures:
		var building := state.add_building(structure.kind, structure.position)
		building.immune = building.spawner and state.is_survival()
	state.fog.refresh(state)
	return state


func place_core(position: Vector2) -> Building:
	var core := add_building(GameConfig.CORE, position)
	core.energy = Formulas.capacity(core) * 0.5
	core_id = core.id
	phase = Phase.PLAN
	return core


func next_id() -> int:
	_next_id += 1
	return _next_id - 1


func add_building(kind: String, position: Vector2) -> Building:
	var building := Building.new(next_id(), kind, position)
	if building.is_player():
		building.boosts = setup.arsenal.boosts_for(kind)
		building.hp = building.max_hp()
	building.elevation = _elevation_of(building)
	buildings[building.id] = building
	roster_version += 1
	nav.occupy(building)
	return building


func _elevation_of(building: Building) -> int:
	var result := 1
	for cell in building.footprint():
		result = mini(result, map.elevation(cell))
	return result


func move_building(building: Building, position: Vector2) -> void:
	nav.release(building)
	building.origin = LevelMap.footprint_origin(position, building.cells())
	building.position = LevelMap.footprint_center(building.origin, building.cells())
	building.elevation = _elevation_of(building)
	nav.occupy(building)
	mark_changed()


func drive(building: Building, position: Vector2) -> void:
	building.position = position
	mark_changed()
	var cell := map.cell_of(position)
	if cell == building.origin:
		return
	nav.release(building)
	building.origin = cell
	building.elevation = _elevation_of(building)
	nav.occupy(building)


func remove_building(id: int) -> void:
	var building := building(id)
	if building == null:
		return
	buildings.erase(id)
	roster_version += 1
	nav.release(building)


func mark_changed() -> void:
	layout_version += 1


func reinstate(building: Building) -> void:
	buildings[building.id] = building
	roster_version += 1
	nav.occupy(building)


func obstacle_at(cell: Vector2i) -> Obstacle:
	if not map.is_clearable(cell):
		obstacles.erase(cell)
		return null
	if not obstacles.has(cell):
		obstacles[cell] = Obstacle.new(next_id(), cell, map.obstacle_type(cell), map.center_of(cell))
	return obstacles[cell]


func clear_obstacle(cell: Vector2i) -> void:
	var obstacle: Obstacle = obstacles.get(cell)
	if obstacle != null:
		obstacle.hp = 0.0
		obstacles.erase(cell)
	if map.clear(cell):
		nav.terrain_changed(cell)


func building(id: int) -> Building:
	return buildings.get(id)


func core() -> Building:
	return building(core_id)


func count_kind(kind: String) -> int:
	return of_kind(kind).size()


func of_kind(kind: String) -> Array[Building]:
	_refresh_roster()
	return _by_kind.get(kind, EMPTY_LIST)


func is_scouting() -> bool:
	return phase == Phase.SCOUT


func is_planning() -> bool:
	return phase == Phase.PLAN


func is_fighting() -> bool:
	return phase == Phase.FIGHT


func player_buildings() -> Array[Building]:
	_refresh_roster()
	return _players


func enemy_buildings() -> Array[Building]:
	_refresh_roster()
	return _structures


func producers() -> Array[Building]:
	_refresh_roster()
	return _producers


func combatants() -> Array[Building]:
	_refresh_roster()
	return _combatants


func _refresh_roster() -> void:
	if _cache_version == roster_version:
		return
	_cache_version = roster_version
	_players = []
	_structures = []
	_combatants = []
	_producers = []
	_stores = []
	_by_kind = {}
	for item: Building in buildings.values():
		if not item.is_alive():
			continue
		if item.armed or (item.healing and item.is_player()):
			_combatants.append(item)
		if item.is_player() and item.definition().has("output"):
			_producers.append(item)
		if item.is_player() and float(item.definition().get("capacity", 0.0)) > 0.0:
			_stores.append(item)
		if item.is_player():
			_players.append(item)
		else:
			_structures.append(item)
		if not _by_kind.has(item.kind):
			_by_kind[item.kind] = [] as Array[Building]
		_by_kind[item.kind].append(item)


func is_available(kind: String) -> bool:
	return setup.arsenal.has(kind)


func available_kinds() -> Array[String]:
	return setup.arsenal.kinds()


func is_survival() -> bool:
	return setup.is_survival()


func attackers() -> int:
	var count := 0
	for enemy in enemies:
		if enemy.is_attacker():
			count += 1
	return count


func has_attackers() -> bool:
	for enemy in enemies:
		if enemy.is_attacker():
			return true
	return false


func is_over() -> bool:
	return phase == Phase.WON or phase == Phase.LOST


func is_night() -> bool:
	return phase == Phase.FIGHT and DayCycle.is_night(round_time, level)


func light() -> float:
	return DayCycle.light(round_time, level) if phase == Phase.FIGHT else 1.0


func add_link(link: EnergyLink) -> void:
	links.append(link)
	links_version += 1


func remove_link_at(index: int) -> void:
	links.remove_at(index)
	links_version += 1


func replace_links(fresh: Array[EnergyLink]) -> void:
	links = fresh
	links_version += 1


func find_link(from_id: int, to_id: int) -> EnergyLink:
	for link in links:
		if link.source == from_id and link.target == to_id:
			return link
	return null


func outgoing(id: int) -> Array[EnergyLink]:
	var result: Array[EnergyLink] = []
	for link in links:
		if link.source == id:
			result.append(link)
	return result


func outgoing_count(id: int) -> int:
	if _beam_version != links_version:
		_beam_version = links_version
		_beam_counts = {}
		for link in links:
			_beam_counts[link.source] = int(_beam_counts.get(link.source, 0)) + 1
	return int(_beam_counts.get(id, 0))


func link_points(link: EnergyLink) -> PackedVector2Array:
	return PackedVector2Array([building(link.source).position, building(link.target).position])


func stores() -> Array[Building]:
	_refresh_roster()
	return _stores


func stored_energy() -> float:
	var total := 0.0
	for item in stores():
		total += item.energy
	return total


func storage_capacity() -> float:
	var total := 0.0
	for item in stores():
		total += Formulas.capacity(item)
	return total


func generation() -> float:
	var total := 0.0
	var sun := light()
	for item in producers():
		var amount := Formulas.output(item)
		total += amount * sun if item.definition().get("solar", false) else amount
	return total


func core_ratio() -> float:
	var item := core()
	return item.hp_ratio() if item != null else 0.0


func stars() -> int:
	return Formulas.survival_stars(setup.days) if phase == Phase.WON and is_survival() else 0
