extends GutTest

var battle: Battle
var state: BattleState
var core: Building
var rover: Building


func before_each() -> void:
	battle = BattleFixtures.battle(1, false)
	state = battle.state
	core = state.core()
	rover = BattleFixtures.add(battle, GameConfig.ROVER, core.position + Vector2(0, -150))
	rover.energy = Formulas.capacity(rover)


func _drive(seconds: float) -> void:
	for i in int(seconds / GameConfig.TICK):
		battle.mobility.update(GameConfig.TICK)


func test_steer_reasons() -> void:
	assert_eq(battle.steer(rover.id, Vector2(3, 0)), MobileControl.OK)
	assert_eq(rover.steer, Vector2.RIGHT)
	assert_eq(battle.steer(core.id, Vector2.RIGHT), MobileControl.IMMOBILE)
	assert_eq(battle.steer(9999, Vector2.RIGHT), MobileControl.MISSING)


func test_driving_moves_and_costs_energy() -> void:
	var start := rover.position
	var version := state.nav.version
	battle.steer(rover.id, Vector2.UP)
	_drive(1.0)
	var travelled := start.y - rover.position.y
	assert_almost_eq(travelled, Formulas.move_speed(rover), 4.0)
	assert_almost_eq(rover.energy, Formulas.capacity(rover) - travelled * Formulas.move_energy(rover), 0.01)
	assert_eq(rover.origin, state.map.cell_of(rover.position))
	assert_eq(state.nav.occupant_at(rover.origin), rover.id)
	assert_eq(state.nav.occupant_at(state.map.cell_of(start)), NavGrid.FREE)
	assert_gt(state.nav.version, version)
	battle.steer(rover.id, Vector2.ZERO)
	var parked := rover.position
	_drive(0.5)
	assert_eq(rover.position, parked)


func test_driving_stops_without_energy() -> void:
	rover.energy = Formulas.move_energy(rover) * 10.0
	battle.steer(rover.id, Vector2.LEFT)
	var start := rover.position
	_drive(1.0)
	assert_almost_eq(start.x - rover.position.x, 10.0, 0.5)
	assert_almost_eq(rover.energy, 0.0, 0.01)
	assert_true(rover.stalled)
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "stalled").size(), 1)
	_drive(0.5)
	assert_true(BattleFixtures.of_type(battle.events.drain(), "stalled").is_empty())
	rover.energy = 50.0
	_drive(0.2)
	assert_false(rover.stalled)


func test_driving_is_blocked_by_buildings_and_terrain() -> void:
	var cell := rover.origin + Vector2i(0, -2)
	BattleFixtures.wall(battle, [cell + Vector2i(-1, 0), cell, cell + Vector2i(1, 0)])
	battle.steer(rover.id, Vector2.UP)
	_drive(2.0)
	assert_gt(rover.position.y, state.map.center_of(cell).y + GameConfig.CELL * 0.5)
	var chasm := rover.origin + Vector2i(2, 0)
	for y in range(-2, 3):
		state.map.set_tile(chasm + Vector2i(0, y), LevelMap.Tile.CHASM)
		state.nav.terrain_changed(chasm + Vector2i(0, y))
	battle.steer(rover.id, Vector2.RIGHT)
	_drive(2.0)
	assert_lt(rover.position.x, state.map.center_of(chasm).x - GameConfig.CELL * 0.5)


func test_driving_updates_elevation() -> void:
	var high := rover.origin + Vector2i(1, 0)
	for y in range(-1, 2):
		for x in range(0, 3):
			state.map.heights[state.map.index(high + Vector2i(x, y))] = 1
	assert_eq(rover.elevation, 0)
	battle.steer(rover.id, Vector2.RIGHT)
	_drive(1.0)
	assert_eq(rover.elevation, 1)
	assert_gt(Formulas.attack_range(rover), float(Formulas.attack(rover).range))


func test_links_pause_out_of_range_and_resume() -> void:
	rover.energy = 0.0
	core.energy = Formulas.capacity(core)
	assert_eq(battle.connect_buildings(core.id, rover.id), EnergyNetwork.OK)
	var link := state.links[0]
	battle.network.flow(0.5)
	assert_gt(rover.energy, 0.0)
	assert_true(link.active)
	state.drive(rover, core.position + Vector2(0, -Formulas.link_range(core) - 100.0))
	var stored := rover.energy
	for i in 30:
		battle.network.flow(GameConfig.TICK)
	assert_false(link.active)
	assert_eq(rover.energy, stored)
	assert_lt(link.flow, 0.5)
	assert_eq(state.links.size(), 1)
	state.drive(rover, core.position + Vector2(0, -150))
	battle.network.flow(0.5)
	assert_true(link.active)
	assert_gt(rover.energy, stored)


func test_planning_freezes_driving() -> void:
	battle.steer(rover.id, Vector2.UP)
	var start := rover.position
	for i in 10:
		battle.tick(GameConfig.TICK)
	assert_eq(rover.position, start)


func test_full_battle_tick_drives_and_fights() -> void:
	battle.start_round()
	battle.steer(rover.id, Vector2.UP)
	var start := rover.position
	var crawler := BattleFixtures.enemy(battle, "beetle", rover.position + Vector2(0, -150))
	for i in 10:
		battle.tick(GameConfig.TICK)
	assert_lt(rover.position.y, start.y)
	assert_lt(crawler.hp, crawler.max_hp)
