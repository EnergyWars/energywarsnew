class_name BattleState
extends RefCounted

enum Phase { SCOUT, PREP, FIGHT, WON, LOST }

var level_index: int
var level: Dictionary
var map: LevelMap
var nav: NavGrid
var fog: FogOfWar
var scout: Scout
var phase := Phase.SCOUT
var money := 0
var time := 0.0
var prep_left := 0.0
var cycle := 0
var cycle_time := 0.0
var surge_announced := false
var buildings := {}
var links: Array[EnergyLink] = []
var enemies: Array[Enemy] = []
var projectiles: Array[Projectile] = []
var pickups: Array[Pickup] = []
var rng := RandomNumberGenerator.new()
var core_id := -1
var kills := 0
var lost := 0
var earned := 0
var best_combo := 0
var structures_destroyed := 0
var _next_id := 1


static func create(index: int, seed_value: int = 0) -> BattleState:
	var state := BattleState.new()
	state.level_index = clampi(index, 0, GameConfig.level_count() - 1)
	state.level = GameConfig.level(state.level_index)
	state.map = LevelMap.create(state.level)
	state.nav = NavGrid.new(state.map)
	state.fog = FogOfWar.new(state.map)
	state.scout = Scout.new(state.map.drop)
	state.money = int(state.level.money)
	state.prep_left = float(state.level.prep)
	state.rng.seed = seed_value if seed_value != 0 else int(state.level.seed) * 7919
	for structure in state.map.structures:
		state.add_building(structure.kind, structure.position)
	state.fog.refresh(state)
	return state


func place_core(position: Vector2) -> Building:
	var core := add_building(GameConfig.CORE, position)
	core.energy = Formulas.capacity(core) * 0.5
	core_id = core.id
	phase = Phase.PREP
	return core


func next_id() -> int:
	_next_id += 1
	return _next_id - 1


func add_building(kind: String, position: Vector2) -> Building:
	var building := Building.new(next_id(), kind, position)
	building.elevation = 1
	for cell in building.footprint():
		building.elevation = mini(building.elevation, map.elevation(cell))
	buildings[building.id] = building
	nav.occupy(building)
	return building


func remove_building(id: int) -> void:
	var building := building(id)
	if building == null:
		return
	buildings.erase(id)
	nav.release(building)


func building(id: int) -> Building:
	return buildings.get(id)


func core() -> Building:
	return building(core_id)


func count_kind(kind: String) -> int:
	var total := 0
	for item: Building in buildings.values():
		if item.kind == kind and item.is_alive():
			total += 1
	return total


func is_scouting() -> bool:
	return phase == Phase.SCOUT


func player_buildings() -> Array[Building]:
	var result: Array[Building] = []
	for item: Building in buildings.values():
		if item.is_player() and item.is_alive():
			result.append(item)
	return result


func enemy_buildings() -> Array[Building]:
	var result: Array[Building] = []
	for item: Building in buildings.values():
		if not item.is_player() and item.is_alive():
			result.append(item)
	return result


func is_available(kind: String) -> bool:
	return GameConfig.available_kinds(level_index).has(kind)


func is_over() -> bool:
	return phase == Phase.WON or phase == Phase.LOST


func is_night() -> bool:
	return DayCycle.is_night(time, level)


func light() -> float:
	return DayCycle.light(time, level)


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


func link_points(link: EnergyLink) -> PackedVector2Array:
	return PackedVector2Array([building(link.source).position, building(link.target).position])


func stored_energy() -> float:
	var total := 0.0
	for item in player_buildings():
		total += item.energy
	return total


func storage_capacity() -> float:
	var total := 0.0
	for item in player_buildings():
		total += Formulas.capacity(item)
	return total


func generation() -> float:
	var total := 0.0
	var sun := light()
	for item in player_buildings():
		var amount := Formulas.output(item)
		total += amount * sun if item.definition().get("solar", false) else amount
	return total


func core_ratio() -> float:
	var item := core()
	return item.hp_ratio() if item != null else 0.0


func stars() -> int:
	return Formulas.stars(core_ratio(), lost) if phase == Phase.WON else 0
