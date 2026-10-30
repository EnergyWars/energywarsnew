extends GutTest

var battle: Battle
var core: Building


func before_each() -> void:
	battle = BattleFixtures.battle()
	core = battle.state.core()


func test_valid_spot_near_core() -> void:
	assert_eq(BuildRules.reason(battle.state, GameConfig.SOLAR, core.position + Vector2(120, 0)), BuildRules.OK)
	assert_true(BuildRules.can_place(battle.state, GameConfig.SOLAR, core.position + Vector2(120, 0)))


func test_invalid_kinds() -> void:
	assert_eq(BuildRules.reason(battle.state, "castle", core.position + Vector2(120, 0)), BuildRules.INVALID)
	assert_eq(BuildRules.reason(battle.state, GameConfig.CORE, core.position + Vector2(120, 0)), BuildRules.INVALID)
	assert_eq(BuildRules.reason(battle.state, GameConfig.NEST, core.position + Vector2(120, 0)), BuildRules.INVALID)


func test_locked_kind() -> void:
	assert_eq(BuildRules.reason(battle.state, GameConfig.PLASMA, core.position + Vector2(120, 0)), BuildRules.LOCKED)


func test_money_uses_dynamic_cost() -> void:
	battle.state.money = 10
	assert_eq(BuildRules.reason(battle.state, GameConfig.SOLAR, core.position + Vector2(120, 0)), BuildRules.MONEY)
	assert_eq(BuildRules.reason(battle.state, GameConfig.BULWARK, core.position + Vector2(120, 0)), BuildRules.OK)
	battle.state.money = 3
	assert_eq(BuildRules.reason(battle.state, GameConfig.BULWARK, core.position + Vector2(120, 0)), BuildRules.MONEY)


func test_bounds() -> void:
	core.position = Vector2(30, battle.state.map.size.y - 200)
	assert_eq(BuildRules.reason(battle.state, GameConfig.SOLAR, Vector2(-10, battle.state.map.size.y - 200)), BuildRules.BOUNDS)


func test_blocked_by_terrain() -> void:
	var spot := core.position + Vector2(150, 0)
	for tile in [LevelMap.Tile.TREE, LevelMap.Tile.ROCK, LevelMap.Tile.CLIFF, LevelMap.Tile.CHASM, LevelMap.Tile.POND]:
		battle.state.map.set_tile(battle.state.map.cell_of(spot), tile)
		assert_eq(BuildRules.reason(battle.state, GameConfig.SOLAR, spot), BuildRules.BLOCKED, str(tile))
	battle.state.map.set_tile(battle.state.map.cell_of(spot), LevelMap.Tile.RAMP)
	assert_eq(BuildRules.reason(battle.state, GameConfig.SOLAR, spot), BuildRules.OK)


func test_water_wheel_needs_pond() -> void:
	var spot := core.position + Vector2(150, 0)
	var cell := battle.state.map.cell_of(spot)
	assert_eq(BuildRules.reason(battle.state, GameConfig.WATER, spot), BuildRules.WATER_ONLY)
	battle.state.map.set_tile(cell, LevelMap.Tile.POND)
	assert_eq(BuildRules.reason(battle.state, GameConfig.WATER, spot), BuildRules.OK)
	assert_eq(BuildRules.reason(battle.state, GameConfig.SOLAR, spot), BuildRules.BLOCKED)
	battle.state.map.set_tile(cell, LevelMap.Tile.TREE)
	assert_eq(BuildRules.reason(battle.state, GameConfig.WATER, spot), BuildRules.WATER_ONLY)


func test_overlap_uses_grid_cells() -> void:
	assert_eq(BuildRules.reason(battle.state, GameConfig.SOLAR, core.position + Vector2(20, 0)), BuildRules.OVERLAP)
	BattleFixtures.add(battle, GameConfig.BULWARK, core.position + Vector2(84, 0))
	assert_eq(BuildRules.reason(battle.state, GameConfig.SOLAR, core.position + Vector2(84, 0)), BuildRules.OVERLAP)
	assert_eq(BuildRules.reason(battle.state, GameConfig.SOLAR, core.position + Vector2(140, 0)), BuildRules.OK)


func test_unexplored_cells_cannot_be_built() -> void:
	var spot := core.position + Vector2(150, 0)
	battle.state.fog.cells[battle.state.map.index(battle.state.map.cell_of(spot))] = FogOfWar.HIDDEN
	assert_eq(BuildRules.reason(battle.state, GameConfig.SOLAR, spot), BuildRules.UNEXPLORED)


func test_ground_units_block_placement_but_flyers_do_not() -> void:
	var spot := core.position + Vector2(150, 0)
	var wasp := BattleFixtures.enemy(battle, "wasp", LevelMap.snap(spot, 1))
	assert_eq(BuildRules.reason(battle.state, GameConfig.SOLAR, spot), BuildRules.OK)
	wasp.hp = 0.0
	BattleFixtures.enemy(battle, "crawler", LevelMap.snap(spot, 1))
	assert_eq(BuildRules.reason(battle.state, GameConfig.SOLAR, spot), BuildRules.UNITS)


func test_too_far() -> void:
	assert_eq(BuildRules.reason(battle.state, GameConfig.SOLAR, core.position + Vector2(0, -600)), BuildRules.TOO_FAR)


func test_chain_extends_reach_but_walls_do_not() -> void:
	BattleFixtures.add(battle, GameConfig.BULWARK, core.position + Vector2(0, -400))
	assert_eq(BuildRules.reason(battle.state, GameConfig.SOLAR, core.position + Vector2(0, -600)), BuildRules.TOO_FAR)
	BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(0, -350))
	assert_eq(BuildRules.reason(battle.state, GameConfig.SOLAR, core.position + Vector2(0, -600)), BuildRules.OK)


func test_enemy_near() -> void:
	var nest: Building = battle.state.enemy_buildings()[0]
	BattleFixtures.add(battle, GameConfig.RELAY, nest.position + Vector2(0, 300))
	assert_eq(BuildRules.reason(battle.state, GameConfig.SOLAR, nest.position + Vector2(0, 150)), BuildRules.ENEMY_NEAR)


func test_planning_forbids_building_near_enemy_bases() -> void:
	var nest: Building = battle.state.enemy_buildings()[0]
	BattleFixtures.add(battle, GameConfig.RELAY, nest.position + Vector2(0, 500))
	var spot := nest.position + Vector2(0, 400)
	assert_eq(BuildRules.enemy_clearance(battle.state), GameConfig.ENEMY_PLAN_CLEAR)
	assert_eq(BuildRules.reason(battle.state, GameConfig.ZAPPER, spot), BuildRules.ENEMY_ZONE)
	battle.start_round()
	assert_eq(BuildRules.enemy_clearance(battle.state), GameConfig.ENEMY_NO_BUILD)
	assert_eq(BuildRules.reason(battle.state, GameConfig.ZAPPER, spot), BuildRules.OK)
	assert_eq(battle.place(GameConfig.ZAPPER, spot), BuildRules.OK)


func test_planning_forbids_relocating_into_the_enemy_zone() -> void:
	var nest: Building = battle.state.enemy_buildings()[0]
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, nest.position + Vector2(0, 500))
	BattleFixtures.add(battle, GameConfig.RELAY, nest.position + Vector2(GameConfig.CELL * 2.0, 500))
	battle.state.money = 1000
	assert_eq(battle.relocate(relay.id, nest.position + Vector2(0, 400)), BuildRules.ENEMY_ZONE)
	battle.start_round()
	assert_eq(battle.relocate(relay.id, nest.position + Vector2(0, 400)), BuildRules.OK)


func test_nothing_but_the_core_while_scouting() -> void:
	var fresh := Battle.start(0)
	BattleFixtures.open_terrain(fresh.state)
	var drop := fresh.state.map.drop
	assert_eq(BuildRules.reason(fresh.state, GameConfig.SOLAR, drop), BuildRules.PHASE)
	assert_eq(BuildRules.reason(fresh.state, GameConfig.CORE, drop), BuildRules.OK)
	assert_eq(BuildRules.reason(fresh.state, GameConfig.CORE, drop + Vector2(GameConfig.CORE_DEPLOY_RANGE + 120.0, 0)), BuildRules.SCOUT_FAR)
	fresh.state.scout.drop_left = 1.0
	assert_eq(BuildRules.reason(fresh.state, GameConfig.CORE, drop), BuildRules.PHASE)


func test_core_needs_distance_to_enemies() -> void:
	var fresh := Battle.start(0)
	BattleFixtures.open_terrain(fresh.state)
	fresh.state.spawn_structures(fresh.state.map.structures)
	var nest: Building = fresh.state.enemy_buildings()[0]
	fresh.state.scout.position = nest.position + Vector2(0, 300)
	assert_eq(BuildRules.reason(fresh.state, GameConfig.CORE, nest.position + Vector2(0, 300)), BuildRules.ENEMY_NEAR)
	assert_eq(BuildRules.reason(battle.state, GameConfig.CORE, core.position), BuildRules.INVALID)
