extends GutTest

var battle: Battle
var state: BattleState
var core: Building


func before_each() -> void:
	battle = BattleFixtures.battle(GameConfig.level_count() - 1, false)
	state = battle.state
	core = state.core()
	core.energy = 0.0


func _tower(kind: String, offset: Vector2 = Vector2(0, -150)) -> Building:
	var tower := BattleFixtures.add(battle, kind, core.position + offset)
	tower.energy = Formulas.capacity(tower)
	return tower


func _obstacle(tower: Building, offset: Vector2i, tile: int = LevelMap.Tile.TREE) -> Obstacle:
	var cell := state.map.cell_of(tower.position) + offset
	state.map.set_tile(cell, tile)
	state.nav.terrain_changed(cell)
	return state.obstacle_at(cell)


func _run(seconds: float) -> void:
	for i in int(seconds / GameConfig.TICK):
		battle.combat.update(GameConfig.TICK)


func test_focus_overrides_target_priority() -> void:
	var zapper := _tower(GameConfig.ZAPPER)
	var near := BattleFixtures.enemy(battle, "beetle", zapper.position + Vector2(0, -60))
	var focus := BattleFixtures.enemy(battle, "beetle", zapper.position + Vector2(0, -200))
	assert_eq(battle.focus(zapper.id, focus), Combat.OK)
	assert_eq(zapper.focus, focus)
	assert_true(BattleFixtures.types(battle).has("focus"))
	battle.combat.update(GameConfig.TICK)
	assert_eq(zapper.target_id, focus.id)
	assert_eq(near.hp, near.max_hp)
	focus.position = zapper.position + Vector2(0, -900)
	assert_eq(battle.combat.find_target(zapper), near)
	assert_eq(battle.combat.focused(zapper), focus)
	focus.hp = 0.0
	assert_null(battle.combat.focused(zapper))
	assert_null(zapper.focus)


func test_focus_reasons() -> void:
	var zapper := _tower(GameConfig.ZAPPER)
	var plasma := _tower(GameConfig.PLASMA, Vector2(200, 0))
	var wasp := BattleFixtures.enemy(battle, "wasp", plasma.position + Vector2(0, -200))
	assert_eq(battle.focus(plasma.id, wasp), Combat.CANNOT)
	assert_eq(battle.focus(zapper.id, core), Combat.INVALID)
	assert_eq(battle.focus(zapper.id, BattleFixtures.enemy(battle, "crawler", Vector2.ZERO)), Combat.OK)
	var dead := BattleFixtures.enemy(battle, "crawler", zapper.position)
	dead.hp = 0.0
	assert_eq(battle.focus(zapper.id, dead), Combat.MISSING)
	assert_eq(battle.focus(core.id + 999, dead), Combat.INVALID)
	var relay := _tower(GameConfig.RELAY, Vector2(-200, 0))
	assert_eq(battle.focus(relay.id, wasp), Combat.INVALID)
	var tree := _obstacle(zapper, Vector2i(9, 0))
	assert_eq(battle.focus(zapper.id, tree), Combat.RANGE)
	assert_eq(battle.focus(zapper.id, null), Combat.OK)
	assert_null(zapper.focus)


func test_towers_destroy_trees_and_rocks_on_order() -> void:
	var zapper := _tower(GameConfig.ZAPPER)
	var tree := _obstacle(zapper, Vector2i(2, 0))
	assert_eq(battle.focus(zapper.id, tree), Combat.OK)
	assert_eq(battle.combat.find_target(zapper), tree)
	battle.combat.update(GameConfig.TICK)
	assert_lt(tree.hp, tree.max_hp)
	zapper.energy = 9999.0
	_run(12.0)
	assert_true(state.map.is_walkable(tree.cell))
	assert_false(state.nav.ground.is_point_solid(tree.cell))
	assert_false(state.obstacles.has(tree.cell))
	assert_null(zapper.focus)
	var cleared := BattleFixtures.of_type(battle.events.drain(), "cleared")
	assert_eq(cleared.size(), 1)
	assert_eq(cleared[0].obstacle, LevelMap.TREE)


func test_plasma_and_laser_hit_focused_obstacles() -> void:
	var plasma := _tower(GameConfig.PLASMA)
	var rock := _obstacle(plasma, Vector2i(4, 0), LevelMap.Tile.ROCK)
	assert_eq(battle.focus(plasma.id, rock), Combat.OK)
	battle.combat.update(GameConfig.TICK)
	assert_eq(state.projectiles.size(), 1)
	assert_eq(state.projectiles[0].obstacle, rock)
	_run(1.0)
	assert_lt(rock.hp, rock.max_hp)
	var laser := _tower(GameConfig.LASER, Vector2(300, 0))
	var tree := _obstacle(laser, Vector2i(0, 2))
	battle.focus(laser.id, tree)
	_run(0.5)
	assert_true(laser.firing)
	assert_eq(laser.laser_target, tree)
	assert_lt(tree.hp, tree.max_hp)


func test_focus_on_enemy_structure_and_chain_from_obstacle() -> void:
	var tesla := _tower(GameConfig.TESLA)
	var turret := BattleFixtures.add(battle, GameConfig.TURRET, tesla.position + Vector2(0, -180))
	assert_eq(battle.focus(tesla.id, turret), Combat.OK)
	battle.combat.update(GameConfig.TICK)
	assert_lt(turret.hp, turret.max_hp())
	var tree := _obstacle(tesla, Vector2i(-2, 0))
	var crawler := BattleFixtures.enemy(battle, "beetle", tree.position + Vector2(0, 40))
	battle.focus(tesla.id, tree)
	tesla.cooldown = 0.0
	tesla.scan_timer = 0.0
	battle.combat.update(GameConfig.TICK)
	assert_lt(tree.hp, tree.max_hp)
	assert_lt(crawler.hp, crawler.max_hp)


func test_obstacle_registry() -> void:
	var cell := state.map.cell_of(core.position) + Vector2i(4, 4)
	assert_null(state.obstacle_at(cell))
	state.map.set_tile(cell, LevelMap.Tile.ROCK)
	var rock := state.obstacle_at(cell)
	assert_eq(rock.type, LevelMap.ROCK)
	assert_eq(rock.max_hp, float(GameConfig.OBSTACLE_HP.rock))
	assert_eq(state.obstacle_at(cell), rock)
	assert_eq(rock.hp_ratio(), 1.0)
	state.map.clear(cell)
	assert_null(state.obstacle_at(cell))
	assert_false(state.obstacles.has(cell))
	var zapper := _tower(GameConfig.ZAPPER)
	var tree := _obstacle(zapper, Vector2i(1, 0))
	battle.focus(zapper.id, tree)
	state.clear_obstacle(tree.cell)
	assert_false(tree.is_alive())
	assert_null(battle.combat.focused(zapper))
	battle.combat.damage_obstacle(tree, 10.0, false)
	assert_eq(tree.hp, 0.0)


func test_focus_candidate_prefers_units_then_buildings_then_obstacles() -> void:
	var zapper := _tower(GameConfig.ZAPPER)
	var tree := _obstacle(zapper, Vector2i(2, 0))
	var crawler := BattleFixtures.enemy(battle, "crawler", tree.position)
	assert_eq(battle.focus_candidate(tree.position, 10.0), crawler)
	crawler.hp = 0.0
	assert_eq(battle.focus_candidate(tree.position, 10.0), tree)
	assert_eq(battle.focus_candidate(zapper.position, 10.0), zapper)
	assert_null(battle.focus_candidate(core.position + Vector2(500, 500)))
	state.fog.cells.fill(FogOfWar.HIDDEN)
	assert_null(battle.focus_candidate(tree.position))
