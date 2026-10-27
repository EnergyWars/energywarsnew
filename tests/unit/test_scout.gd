extends GutTest

var battle: Battle
var state: BattleState
var map: LevelMap


func before_each() -> void:
	battle = Battle.start(0)
	state = battle.state
	BattleFixtures.open_terrain(state)
	map = state.map
	state.scout.drop_left = GameConfig.DROP_TIME


func _land() -> void:
	battle.scouting.update(GameConfig.DROP_TIME + 0.01)
	battle.events.drain()


func _walk(seconds: float) -> void:
	for i in int(seconds / GameConfig.TICK):
		battle.tick(GameConfig.TICK)


func test_parachute_drop_then_landing() -> void:
	assert_false(state.scout.is_landed())
	assert_eq(state.scout.drop_ratio(), 1.0)
	assert_eq(battle.command_scout(map.drop + Vector2(100, 0)), ScoutControl.LANDING)
	battle.scouting.update(1.0)
	assert_almost_eq(state.scout.drop_ratio(), (GameConfig.DROP_TIME - 1.0) / GameConfig.DROP_TIME, 0.001)
	battle.scouting.update(GameConfig.DROP_TIME)
	assert_true(state.scout.is_landed())
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "landed").size(), 1)


func test_scout_walks_to_target_and_reveals_fog() -> void:
	_land()
	state.fog.cells.fill(FogOfWar.HIDDEN)
	var goal := map.center_of(map.cell_of(map.drop) + Vector2i(-10, -6))
	assert_eq(battle.command_scout(goal), ScoutControl.OK)
	assert_true(state.scout.is_moving())
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "scout_order").size(), 1)
	_walk(8.0)
	assert_eq(state.scout.position, goal)
	assert_false(state.scout.is_moving())
	assert_true(state.fog.is_visible(goal))
	assert_true(state.fog.is_explored_at(map.drop))


func test_invalid_orders() -> void:
	_land()
	assert_eq(battle.command_scout(Vector2(-500, -500)), ScoutControl.BOUNDS)
	var chasm := map.cell_of(map.drop) + Vector2i(3, 0)
	map.set_tile(chasm, LevelMap.Tile.CHASM)
	state.nav.terrain_changed(chasm)
	assert_eq(battle.command_scout(map.center_of(chasm)), ScoutControl.BLOCKED)
	var island := map.cell_of(map.drop) + Vector2i(0, -8)
	for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		map.set_tile(island + offset, LevelMap.Tile.CLIFF)
		state.nav.terrain_changed(island + offset)
	assert_eq(battle.command_scout(map.center_of(island)), ScoutControl.UNREACHABLE)
	state.scout = null
	assert_eq(battle.command_scout(map.drop), ScoutControl.MISSING)
	battle.scouting.update(1.0)
	assert_eq(battle.scouting.clear_ratio(), 0.0)


func test_scout_ignores_player_buildings() -> void:
	_land()
	state.place_core(map.drop + Vector2(0, -200))
	var behind := state.core().position + Vector2(0, -200)
	assert_eq(battle.command_scout(behind), ScoutControl.OK)
	assert_true(state.nav.ground.is_point_solid(state.core().origin))
	assert_false(state.nav.walker.is_point_solid(state.core().origin))


func test_scout_clears_trees_and_rocks() -> void:
	_land()
	for entry in [[Vector2i(4, 0), LevelMap.Tile.TREE, LevelMap.TREE], [Vector2i(4, 3), LevelMap.Tile.ROCK, LevelMap.ROCK]]:
		var cell: Vector2i = map.cell_of(state.scout.position) + entry[0]
		map.set_tile(cell, entry[1])
		state.nav.terrain_changed(cell)
		assert_eq(battle.command_scout(map.center_of(cell)), ScoutControl.OK)
		assert_true(state.scout.is_clearing())
		while state.scout.is_moving():
			battle.tick(GameConfig.TICK)
		_walk(0.5)
		assert_gt(battle.scouting.clear_ratio(), 0.0)
		assert_false(map.is_walkable(cell))
		_walk(float(GameConfig.CLEAR_TIME[entry[2]]))
		assert_true(map.is_walkable(cell), str(entry[2]))
		assert_false(state.scout.is_clearing())
		assert_false(state.nav.ground.is_point_solid(cell))
		var cleared := BattleFixtures.of_type(battle.events.drain(), "cleared")
		assert_eq(cleared.size(), 1)
		assert_eq(cleared[0].obstacle, entry[2])


func test_clearing_aborts_when_obstacle_vanishes() -> void:
	_land()
	var cell := map.cell_of(state.scout.position) + Vector2i(1, 0)
	map.set_tile(cell, LevelMap.Tile.TREE)
	state.nav.terrain_changed(cell)
	battle.command_scout(map.center_of(cell))
	map.clear(cell)
	_walk(0.5)
	assert_false(state.scout.is_clearing())


func test_deploy_core_through_battle() -> void:
	_land()
	assert_eq(battle.place(GameConfig.CORE, map.drop), BuildRules.OK)
	assert_eq(state.phase, BattleState.Phase.PREP)
	assert_true(BattleFixtures.types(battle).has("core_deployed"))
	assert_true(state.fog.is_visible(state.core().position + Vector2(400, 0)))
