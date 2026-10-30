class_name BattleCheckpoint
extends RefCounted

var level_index := 0
var setup: BattleSetup
var rng_seed := 0
var rng_state := 0
var money := 0
var unlimited_money := true
var earned := 0
var kills := 0
var lost := 0
var best_combo := 0
var structures_destroyed := 0
var round_number := 1
var days_survived := 0
var time := 0.0
var core_id := -1
var next_id := 1
var elapsed := 0.0
var tiles := PackedByteArray()
var fog := PackedByteArray()
var obstacles: Array[Dictionary] = []
var buildings: Array[Building] = []
var creep: Array[Dictionary] = []
var focus := {}
var links: Array[Vector2i] = []


static func capture(state: BattleState) -> BattleCheckpoint:
	var checkpoint := BattleCheckpoint.new()
	checkpoint.level_index = state.level_index
	checkpoint.setup = state.setup
	checkpoint.rng_seed = state.rng.seed
	checkpoint.rng_state = state.rng.state
	checkpoint.money = state.money
	checkpoint.unlimited_money = state.unlimited_money
	checkpoint.earned = state.earned
	checkpoint.kills = state.kills
	checkpoint.lost = state.lost
	checkpoint.best_combo = state.best_combo
	checkpoint.structures_destroyed = state.structures_destroyed
	checkpoint.round_number = state.round_number
	checkpoint.days_survived = state.days_survived
	checkpoint.time = state.time
	checkpoint.core_id = state.core_id
	checkpoint.next_id = state.id_counter()
	checkpoint.tiles = state.map.tiles.duplicate()
	checkpoint.fog = state.fog.cells.duplicate()
	checkpoint.creep = state.creep.export()
	for cell: Vector2i in state.obstacles:
		var obstacle: Obstacle = state.obstacles[cell]
		if obstacle.is_alive():
			checkpoint.obstacles.append({"id": obstacle.id, "cell": cell, "hp": obstacle.hp})
	for building: Building in state.buildings.values():
		checkpoint.buildings.append(building.copy())
		var target: Object = building.focus
		if target is Building:
			checkpoint.focus[building.id] = (target as Building).id
		elif target is Obstacle:
			checkpoint.focus[building.id] = (target as Obstacle).cell
	for link in state.links:
		checkpoint.links.append(Vector2i(link.source, link.target))
	return checkpoint


func restore() -> Battle:
	var state := BattleState.create(level_index, rng_seed, setup)
	state.map.tiles = tiles.duplicate()
	state.map.version += 1
	state.nav = NavGrid.new(state.map)
	state.fog = FogOfWar.new(state.map)
	state.fog.cells = fog.duplicate()
	state.creep.release_rim()
	state.creep.restore(creep)
	if state.is_creative():
		state.fog.lift()
	state.rng.seed = rng_seed
	state.rng.state = rng_state
	state.phase = BattleState.Phase.PLAN
	state.money = money
	state.unlimited_money = unlimited_money
	state.earned = earned
	state.kills = kills
	state.lost = lost
	state.best_combo = best_combo
	state.structures_destroyed = structures_destroyed
	state.round_number = round_number
	state.days_survived = days_survived
	state.time = time
	state.core_id = core_id
	state.structures_spawned = true
	for building in buildings:
		state.reinstate(building.copy())
	state.raise_id_counter(next_id)
	for entry in obstacles:
		var cell: Vector2i = entry.cell
		var obstacle := Obstacle.new(int(entry.id), cell, state.map.obstacle_type(cell), state.map.center_of(cell))
		obstacle.hp = float(entry.hp)
		state.obstacles[cell] = obstacle
	for id: int in focus:
		var building := state.building(id)
		var target: Variant = focus[id]
		if building != null:
			building.focus = state.obstacle_at(target) if target is Vector2i else state.building(int(target))
	var restored: Array[EnergyLink] = []
	for pair in links:
		restored.append(EnergyLink.new(pair.x, pair.y))
	state.replace_links(restored)
	var core := state.core()
	state.scout.drop_left = 0.0
	state.scout.boarded = true
	if core != null:
		state.scout.position = core.position
	state.fog.invalidate()
	state.fog.refresh(state)
	state.mark_changed()
	var battle := Battle.new(state)
	battle.checkpoint = self
	return battle
