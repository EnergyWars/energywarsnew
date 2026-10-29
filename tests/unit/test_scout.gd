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


func _block(cell: Vector2i, tile: int = LevelMap.Tile.CLIFF) -> void:
	map.set_tile(cell, tile)
	state.nav.terrain_changed(cell)


func test_parachute_drop_then_landing() -> void:
	assert_false(state.scout.is_landed())
	assert_false(state.scout.is_controllable())
	assert_eq(state.scout.drop_ratio(), 1.0)
	assert_eq(battle.steer_scout(Vector2.RIGHT), ScoutControl.LANDING)
	battle.scouting.update(1.0)
	assert_almost_eq(state.scout.drop_ratio(), (GameConfig.DROP_TIME - 1.0) / GameConfig.DROP_TIME, 0.001)
	battle.scouting.update(GameConfig.DROP_TIME)
	assert_true(state.scout.is_landed())
	assert_true(state.scout.is_controllable())
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "landed").size(), 1)


func test_steering_moves_scout_and_reveals_fog() -> void:
	_land()
	state.fog.cells.fill(FogOfWar.HIDDEN)
	var start := state.scout.position
	assert_eq(battle.steer_scout(Vector2(0, -2)), ScoutControl.OK)
	assert_eq(state.scout.steer, Vector2.UP)
	assert_true(state.scout.is_moving())
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "scout_steer").size(), 1)
	battle.steer_scout(Vector2.UP)
	assert_true(BattleFixtures.of_type(battle.events.drain(), "scout_steer").is_empty())
	_walk(2.0)
	assert_almost_eq(state.scout.position.y, start.y - GameConfig.SCOUT_SPEED * 2.0, 6.0)
	assert_eq(state.scout.heading, Vector2.UP)
	assert_true(state.fog.is_visible(state.scout.position))
	battle.steer_scout(Vector2(0.5, 0))
	var before := state.scout.position
	_walk(1.0)
	assert_almost_eq(state.scout.position.x, before.x + GameConfig.SCOUT_SPEED * 0.5, 6.0)
	battle.steer_scout(Vector2.ZERO)
	before = state.scout.position
	_walk(0.5)
	assert_eq(state.scout.position, before)
	assert_false(state.scout.is_moving())


func test_scout_collides_and_slides_along_walls() -> void:
	_land()
	var origin := map.cell_of(state.scout.position)
	state.scout.position = map.center_of(origin)
	for x in range(-3, 4):
		_block(origin + Vector2i(x, -1))
	battle.steer_scout(Vector2(1, -1))
	_walk(1.0)
	assert_gt(state.scout.position.x, map.center_of(origin).x + 60.0)
	assert_gte(state.scout.position.y, map.center_of(origin).y - GameConfig.CELL * 0.5 + GameConfig.SCOUT_RADIUS - 0.5)
	for y in range(-3, 4):
		_block(map.cell_of(state.scout.position) + Vector2i(1, y))
	battle.steer_scout(Vector2.RIGHT)
	var before := state.scout.position
	_walk(1.0)
	assert_almost_eq(state.scout.position.x, before.x, GameConfig.CELL * 0.5)


func test_steering_helper_edges() -> void:
	var never := func(_cell: Vector2i) -> bool: return false
	var always := func(_cell: Vector2i) -> bool: return true
	assert_eq(Steering.slide(map, Vector2(100, 100), Vector2.ZERO, 10.0, never), Vector2(100, 100))
	assert_false(Steering.fits(map, Vector2(5, 5), 10.0, never))
	assert_eq(Steering.slide(map, Vector2(100, 100), Vector2(5, 0), 10.0, always), Vector2(100, 100))
	var stuck := func(cell: Vector2i) -> bool: return cell == map.cell_of(Vector2(100, 100))
	assert_eq(Steering.slide(map, Vector2(100, 100), Vector2(-60, 0), 10.0, stuck), Vector2(40, 100))


func test_scout_respects_enemy_structures_not_player_buildings() -> void:
	_land()
	assert_true(state.enemy_buildings().is_empty())
	state.spawn_structures(map.structures)
	var nest: Building = state.enemy_buildings()[0]
	assert_true(state.nav.walker.is_point_solid(nest.origin))
	state.place_core(map.drop + Vector2(0, -300))
	state.phase = BattleState.Phase.SCOUT
	assert_false(state.nav.walker.is_point_solid(state.core().origin))


func test_scout_fells_trees_with_one_hit() -> void:
	_land()
	var origin := map.cell_of(state.scout.position)
	state.scout.position = map.center_of(origin)
	var cell := origin + Vector2i(1, 0)
	_block(cell, LevelMap.Tile.TREE)
	assert_eq(battle.scouting.clear_time(cell), 0.0)
	assert_eq(battle.clear_with_scout(map.center_of(cell)), ScoutControl.OK)
	assert_true(map.is_walkable(cell))
	assert_false(state.scout.is_clearing())
	assert_eq(battle.scouting.clear_ratio(), 0.0)
	assert_false(state.nav.ground.is_point_solid(cell))
	assert_eq(state.scout.heading, Vector2.RIGHT)
	var events := battle.events.drain()
	assert_eq(BattleFixtures.of_type(events, "clear_order").size(), 1)
	var cleared := BattleFixtures.of_type(events, "cleared")
	assert_eq(cleared.size(), 1)
	assert_eq(cleared[0].obstacle, LevelMap.TREE)
	assert_eq(cleared[0].cell, cell)


func test_scout_clears_rocks_quickly() -> void:
	_land()
	var origin := map.cell_of(state.scout.position)
	state.scout.position = map.center_of(origin)
	var cell := origin + Vector2i(0, 1)
	_block(cell, LevelMap.Tile.ROCK)
	assert_lt(GameConfig.CLEAR_TIME[LevelMap.ROCK], 1.5)
	assert_eq(battle.clear_with_scout(map.center_of(cell)), ScoutControl.OK)
	assert_true(state.scout.is_clearing())
	_walk(0.5)
	assert_gt(battle.scouting.clear_ratio(), 0.0)
	assert_lt(battle.scouting.clear_ratio(), 1.0)
	assert_false(map.is_walkable(cell))
	_walk(float(GameConfig.CLEAR_TIME[LevelMap.ROCK]))
	assert_true(map.is_walkable(cell))
	assert_false(state.scout.is_clearing())
	assert_eq(state.scout.heading, Vector2.DOWN)
	var events := battle.events.drain()
	assert_eq(BattleFixtures.of_type(events, "clear_order").size(), 1)
	var cleared := BattleFixtures.of_type(events, "cleared")
	assert_eq(cleared.size(), 1)
	assert_eq(cleared[0].obstacle, LevelMap.ROCK)


func test_clear_time_of_open_ground_is_zero() -> void:
	assert_eq(battle.scouting.clear_time(map.cell_of(map.drop)), 0.0)
	assert_eq(battle.scouting.clear_ratio(), 0.0)


func test_soldier_is_fast_and_sees_far() -> void:
	assert_gte(GameConfig.SCOUT_SPEED, 190.0)
	assert_gte(GameConfig.SCOUT_VISION, 450.0)
	assert_eq(float(GameConfig.CLEAR_TIME[LevelMap.TREE]), 0.0)


func test_clear_orders_need_an_obstacle() -> void:
	_land()
	var origin := map.cell_of(state.scout.position)
	assert_eq(battle.clear_with_scout(map.center_of(origin + Vector2i(1, 0))), ScoutControl.NOTHING)
	assert_false(state.scout.is_walking())


func test_soldier_reaches_about_two_tiles_diagonally() -> void:
	_land()
	var origin := map.cell_of(state.scout.position)
	state.scout.position = map.center_of(origin)
	var diagonal := origin + Vector2i(2, 2)
	_block(diagonal, LevelMap.Tile.ROCK)
	assert_true(battle.scouting.in_reach(diagonal))
	assert_false(battle.scouting.in_reach(origin + Vector2i(3, 2)))
	assert_eq(battle.clear_with_scout(map.center_of(diagonal)), ScoutControl.OK)
	assert_true(state.scout.is_clearing())
	assert_false(state.scout.is_walking())


func test_far_obstacle_makes_the_soldier_walk_there_first() -> void:
	_land()
	var origin := map.cell_of(state.scout.position)
	state.scout.position = map.center_of(origin)
	var tree := origin + Vector2i(8, 0)
	_block(tree, LevelMap.Tile.TREE)
	assert_eq(battle.clear_with_scout(map.center_of(tree)), ScoutControl.OK)
	assert_false(state.scout.is_clearing())
	assert_true(state.scout.is_walking())
	assert_true(state.scout.is_moving())
	assert_eq(state.scout.pending_cell, tree)
	assert_eq(map.cell_of(state.scout.destination()), tree - Vector2i(1, 0))
	var events := battle.events.drain()
	var route := BattleFixtures.of_type(events, "scout_route")
	assert_eq(route.size(), 1)
	assert_eq(route[0].target, map.center_of(tree))
	assert_eq(BattleFixtures.of_type(events, "scout_steer").size(), 1)
	_walk(2.0)
	assert_true(map.is_walkable(tree))
	assert_false(state.scout.is_walking())
	assert_eq(state.scout.pending_cell, Scout.NO_CELL)
	assert_lte(state.scout.position.distance_to(map.center_of(tree)), GameConfig.CELL * GameConfig.CLEAR_REACH + 1.0)
	assert_gt(state.scout.position.distance_to(map.center_of(tree)), GameConfig.CELL * 2.0)
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "cleared").size(), 1)


func test_route_end_starts_clearing_only_within_reach() -> void:
	_land()
	var tree := map.cell_of(state.scout.position) + Vector2i(4, 0)
	_block(tree, LevelMap.Tile.TREE)
	var center := map.center_of(tree)
	var reach := GameConfig.CELL * GameConfig.CLEAR_REACH
	state.scout.position = center - Vector2(reach + 10.0, 0.0)
	state.scout.route = PackedVector2Array([center - Vector2(reach + 5.0, 0.0)])
	state.scout.pending_cell = tree
	battle.tick(GameConfig.TICK)
	assert_false(state.scout.is_walking())
	assert_eq(state.scout.pending_cell, Scout.NO_CELL)
	assert_false(state.scout.is_clearing())
	assert_true(map.is_clearable(tree))
	battle.events.drain()
	state.scout.position = center - Vector2(reach + 3.0, 0.0)
	state.scout.route = PackedVector2Array([center - Vector2(reach - 2.0, 0.0)])
	state.scout.pending_cell = tree
	battle.tick(GameConfig.TICK)
	assert_false(state.scout.is_walking())
	assert_eq(state.scout.pending_cell, Scout.NO_CELL)
	assert_false(map.is_clearable(tree))
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "cleared").size(), 1)


func test_soldier_walks_to_tapped_ground() -> void:
	_land()
	var origin := map.cell_of(state.scout.position)
	state.scout.position = map.center_of(origin)
	var goal := origin + Vector2i(0, 5)
	assert_eq(battle.walk_scout(map.center_of(goal)), ScoutControl.OK)
	assert_true(state.scout.is_walking())
	assert_eq(state.scout.pending_cell, Scout.NO_CELL)
	assert_eq(state.scout.destination(), map.center_of(goal))
	assert_eq(state.scout.route[0], map.center_of(origin + Vector2i(0, 1)))
	_walk(2.0)
	assert_false(state.scout.is_walking())
	assert_almost_eq(state.scout.position.distance_to(map.center_of(goal)), 0.0, 0.01)
	assert_eq(state.scout.heading, Vector2.DOWN)
	assert_eq(battle.walk_scout(map.center_of(goal)), ScoutControl.OK)
	assert_eq(state.scout.route.size(), 1)
	_walk(0.1)
	assert_false(state.scout.is_walking())


func test_walking_targets_that_cannot_be_reached() -> void:
	_land()
	var origin := map.cell_of(state.scout.position)
	state.scout.position = map.center_of(origin)
	_block(origin + Vector2i(3, 0), LevelMap.Tile.POND)
	assert_eq(battle.walk_scout(map.center_of(origin + Vector2i(3, 0))), ScoutControl.NOTHING)
	var walled := origin + Vector2i(6, 0)
	for y in range(-1, 2):
		for x in range(-1, 2):
			if x != 0 or y != 0:
				_block(walled + Vector2i(x, y))
	assert_eq(battle.walk_scout(map.center_of(walled)), ScoutControl.TOO_FAR)
	_block(walled, LevelMap.Tile.TREE)
	assert_eq(battle.clear_with_scout(map.center_of(walled)), ScoutControl.TOO_FAR)
	assert_false(state.scout.is_walking())
	assert_eq(battle.walk_scout(Vector2(-500, -500)), ScoutControl.NOTHING)
	var nest := BattleFixtures.add(battle, GameConfig.NEST, map.center_of(origin + Vector2i(0, -6)))
	assert_eq(battle.walk_scout(nest.position), ScoutControl.NOTHING)


func test_steering_or_boarding_cancels_the_route() -> void:
	_land()
	var origin := map.cell_of(state.scout.position)
	state.scout.position = map.center_of(origin)
	var tree := origin + Vector2i(8, 0)
	_block(tree, LevelMap.Tile.TREE)
	battle.clear_with_scout(map.center_of(tree))
	assert_true(state.scout.is_walking())
	battle.steer_scout(Vector2.ZERO)
	assert_true(state.scout.is_walking())
	battle.steer_scout(Vector2.UP)
	assert_false(state.scout.is_walking())
	assert_eq(state.scout.pending_cell, Scout.NO_CELL)
	battle.steer_scout(Vector2.ZERO)
	battle.walk_scout(map.center_of(origin + Vector2i(0, 4)))
	assert_true(state.scout.is_walking())
	battle.scouting.board(Building.new(99, GameConfig.CORE, map.drop))
	assert_false(state.scout.is_walking())


func test_route_stops_when_the_target_vanishes_or_the_way_is_blocked() -> void:
	_land()
	var origin := map.cell_of(state.scout.position)
	state.scout.position = map.center_of(origin)
	var tree := origin + Vector2i(8, 0)
	_block(tree, LevelMap.Tile.TREE)
	battle.clear_with_scout(map.center_of(tree))
	map.clear(tree)
	state.nav.terrain_changed(tree)
	_walk(0.1)
	assert_false(state.scout.is_walking())
	var goal := origin + Vector2i(6, 0)
	battle.walk_scout(map.center_of(goal))
	assert_true(state.scout.is_walking())
	var next := map.cell_of(state.scout.route[0])
	_block(next)
	_walk(0.5)
	assert_false(state.scout.is_walking())
	assert_eq(map.cell_of(state.scout.position), origin)


func test_clearing_aborts_when_walking_away_or_obstacle_vanishes() -> void:
	_land()
	var origin := map.cell_of(state.scout.position)
	state.scout.position = map.center_of(origin)
	var cell := origin + Vector2i(1, 0)
	_block(cell, LevelMap.Tile.ROCK)
	battle.clear_with_scout(map.center_of(cell))
	map.clear(cell)
	_walk(0.2)
	assert_false(state.scout.is_clearing())
	_block(cell, LevelMap.Tile.ROCK)
	battle.clear_with_scout(map.center_of(cell))
	battle.steer_scout(Vector2.LEFT)
	_walk(1.5)
	assert_false(state.scout.is_clearing())
	assert_false(map.is_walkable(cell))


func test_deploy_core_boards_the_scout() -> void:
	_land()
	assert_eq(battle.place(GameConfig.CORE, map.drop), BuildRules.OK)
	assert_eq(state.phase, BattleState.Phase.PLAN)
	assert_true(state.scout.boarded)
	assert_false(state.scout.is_controllable())
	assert_eq(state.scout.position, state.core().position)
	var types := BattleFixtures.types(battle)
	assert_true(types.has("core_deployed"))
	assert_true(types.has("scout_boarded"))
	assert_true(state.fog.is_visible(state.core().position + Vector2(400, 0)))
	assert_eq(battle.steer_scout(Vector2.RIGHT), ScoutControl.BOARDED)
	assert_eq(battle.clear_with_scout(map.drop), ScoutControl.BOARDED)
	battle.scouting.update(1.0)
	assert_eq(state.scout.position, state.core().position)


func test_boarded_scout_fires_from_the_core() -> void:
	_land()
	battle.place(GameConfig.CORE, map.drop)
	var core := state.core()
	core.energy = 0.0
	var crawler := BattleFixtures.enemy(battle, "crawler", core.position + Vector2(0, -200))
	var far := BattleFixtures.enemy(battle, "crawler", core.position + Vector2(0, -700))
	battle.events.drain()
	battle.combat.update(GameConfig.TICK)
	var rifle := BattleFixtures.of_type(battle.events.drain(), "rifle")
	assert_eq(rifle.size(), 1)
	assert_eq(state.scout.target_id, crawler.id)
	assert_almost_eq(crawler.hp, crawler.max_hp - float(GameConfig.SCOUT_GUN.damage), 0.001)
	assert_eq(far.hp, far.max_hp)
	assert_almost_eq(state.scout.heading.y, -1.0, 0.001)
	battle.combat.update(GameConfig.TICK)
	assert_true(BattleFixtures.of_type(battle.events.drain(), "rifle").is_empty())
	crawler.hp = 0.0
	battle.combat.update(float(GameConfig.SCOUT_GUN.cooldown))
	assert_eq(state.scout.target_id, -1)


func test_scout_control_without_scout() -> void:
	state.scout = null
	assert_eq(battle.steer_scout(Vector2.RIGHT), ScoutControl.MISSING)
	assert_eq(battle.clear_with_scout(map.drop), ScoutControl.MISSING)
	battle.scouting.update(1.0)
	assert_eq(battle.scouting.clear_ratio(), 0.0)
	battle.scouting.board(Building.new(1, GameConfig.CORE, map.drop))
