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


func test_joystick_moves_scout_and_reveals_fog() -> void:
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
	var nest: Building = state.enemy_buildings()[0]
	assert_true(state.nav.walker.is_point_solid(nest.origin))
	state.place_core(map.drop + Vector2(0, -300))
	state.phase = BattleState.Phase.SCOUT
	assert_false(state.nav.walker.is_point_solid(state.core().origin))


func test_scout_clears_trees_and_rocks_in_reach() -> void:
	_land()
	var origin := map.cell_of(state.scout.position)
	state.scout.position = map.center_of(origin)
	for entry in [[Vector2i(1, 0), LevelMap.Tile.TREE, LevelMap.TREE], [Vector2i(0, 1), LevelMap.Tile.ROCK, LevelMap.ROCK]]:
		var cell: Vector2i = origin + entry[0]
		_block(cell, entry[1])
		assert_eq(battle.clear_with_scout(map.center_of(cell)), ScoutControl.OK)
		assert_true(state.scout.is_clearing())
		_walk(0.5)
		assert_gt(battle.scouting.clear_ratio(), 0.0)
		assert_false(map.is_walkable(cell))
		_walk(float(GameConfig.CLEAR_TIME[entry[2]]))
		assert_true(map.is_walkable(cell), str(entry[2]))
		assert_false(state.scout.is_clearing())
		assert_false(state.nav.ground.is_point_solid(cell))
		var events := battle.events.drain()
		assert_eq(BattleFixtures.of_type(events, "clear_order").size(), 1)
		var cleared := BattleFixtures.of_type(events, "cleared")
		assert_eq(cleared.size(), 1)
		assert_eq(cleared[0].obstacle, entry[2])


func test_clear_orders_need_an_obstacle_in_reach() -> void:
	_land()
	var origin := map.cell_of(state.scout.position)
	assert_eq(battle.clear_with_scout(map.center_of(origin + Vector2i(1, 0))), ScoutControl.NOTHING)
	_block(origin + Vector2i(5, 0), LevelMap.Tile.TREE)
	assert_eq(battle.clear_with_scout(map.center_of(origin + Vector2i(5, 0))), ScoutControl.TOO_FAR)
	assert_false(state.scout.is_clearing())


func test_clearing_aborts_when_walking_away_or_obstacle_vanishes() -> void:
	_land()
	var origin := map.cell_of(state.scout.position)
	state.scout.position = map.center_of(origin)
	var cell := origin + Vector2i(1, 0)
	_block(cell, LevelMap.Tile.TREE)
	battle.clear_with_scout(map.center_of(cell))
	map.clear(cell)
	_walk(0.2)
	assert_false(state.scout.is_clearing())
	_block(cell, LevelMap.Tile.TREE)
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
