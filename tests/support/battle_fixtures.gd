class_name BattleFixtures
extends RefCounted


static func battle(level_index: int = 0, keep_structures: bool = true) -> Battle:
	var state := BattleState.create(level_index, 1234)
	open_terrain(state)
	var sites: Array[Dictionary] = []
	if keep_structures:
		sites = state.map.structures
	state.spawn_structures(sites)
	state.place_core(state.map.drop)
	return Battle.new(state)


static func open_terrain(state: BattleState) -> void:
	state.map.tiles.fill(LevelMap.Tile.OPEN)
	state.map.heights.fill(0)
	state.nav = NavGrid.new(state.map)
	for building: Building in state.buildings.values():
		state.nav.occupy(building)
	state.fog.cells.fill(FogOfWar.VISIBLE)
	state.fog.invalidate()
	state.scout.drop_left = 0.0


static func deployed(level_index: int = 0) -> Battle:
	var fresh := Battle.start(level_index)
	fresh.state.scout.drop_left = 0.0
	fresh.state.fog.reveal(fresh.state.map.drop, 600.0)
	fresh.deploy_core(fresh.state.map.drop)
	fresh.events.drain()
	return fresh


static func add(battle: Battle, kind: String, position: Vector2) -> Building:
	return battle.state.add_building(kind, position)


static func enemy(battle: Battle, kind: String, position: Vector2, hp_scale: float = 1.0) -> Enemy:
	var unit := Enemy.new(battle.state.next_id(), kind, position, hp_scale)
	battle.state.enemies.append(unit)
	return unit


static func wall(battle: Battle, cells: Array[Vector2i]) -> void:
	for cell in cells:
		battle.state.add_building(GameConfig.BULWARK, battle.state.map.center_of(cell))


static func types(battle: Battle) -> Array[String]:
	var result: Array[String] = []
	for event in battle.events.drain():
		result.append(str(event.type))
	return result


static func of_type(events: Array[Dictionary], type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event in events:
		if event.type == type:
			result.append(event)
	return result
