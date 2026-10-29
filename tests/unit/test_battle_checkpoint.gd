extends GutTest

var battle: Battle
var state: BattleState
var core: Building


func before_each() -> void:
	battle = BattleFixtures.battle(0)
	state = battle.state
	core = state.core()
	state.money = 1000
	battle.events.drain()


func _tree(offset: Vector2i) -> Vector2i:
	var cell := state.map.cell_of(core.position) + offset
	state.map.set_tile(cell, LevelMap.Tile.TREE)
	state.nav.terrain_changed(cell)
	return cell


func _far_corner() -> Vector2i:
	var best := Vector2i.ZERO
	for corner in [Vector2i(1, 1), Vector2i(state.map.width - 2, 1), Vector2i(1, state.map.height - 2), Vector2i(state.map.width - 2, state.map.height - 2)]:
		if state.map.center_of(corner).distance_to(core.position) > state.map.center_of(best).distance_to(core.position):
			best = corner
	return best


func test_starting_a_round_remembers_the_plan() -> void:
	assert_null(battle.checkpoint)
	assert_eq(battle.place(GameConfig.RELAY, core.position + Vector2(0, -150)), BuildRules.OK)
	var money := state.money
	assert_true(battle.start_round())
	var checkpoint := battle.checkpoint
	assert_not_null(checkpoint)
	assert_eq(checkpoint.level_index, state.level_index)
	assert_eq(checkpoint.money, money)
	assert_eq(checkpoint.round_number, state.round_number)
	assert_eq(checkpoint.buildings.size(), state.buildings.size())
	assert_eq(checkpoint.core_id, core.id)
	assert_eq(checkpoint.next_id, state.id_counter())
	assert_false(battle.start_round())
	assert_eq(battle.checkpoint, checkpoint)


func test_failed_start_keeps_no_checkpoint() -> void:
	var scouting := Battle.start(0)
	assert_false(scouting.start_round())
	assert_null(scouting.checkpoint)


func test_restore_brings_back_buildings_links_and_money() -> void:
	assert_eq(battle.place(GameConfig.RELAY, core.position + Vector2(0, -150)), BuildRules.OK)
	var relay: Building = state.of_kind(GameConfig.RELAY)[0]
	relay.label = "North"
	assert_eq(battle.connect_buildings(core.id, relay.id), EnergyNetwork.OK)
	assert_true(battle.upgrade(core.id, GameConfig.TRACK_RATE))
	var lamp := BattleFixtures.add(battle, GameConfig.LAMP, core.position + Vector2(150, 0))
	lamp.light_radius = 5.0
	var money := state.money
	var structures := state.enemy_buildings().size()
	state.kills = 7
	state.round_number = 3
	state.days_survived = 2
	battle.start_round()
	var checkpoint := battle.checkpoint
	state.money = 0
	battle.combat.destroy(relay)
	core.hp = 1.0
	state.kills = 50
	var restored := checkpoint.restore()
	var again := restored.state
	assert_true(again.is_planning())
	assert_eq(again.money, money)
	assert_eq(again.kills, 7)
	assert_eq(again.round_number, 3)
	assert_eq(again.days_survived, 2)
	assert_eq(again.enemy_buildings().size(), structures)
	var copy := again.building(relay.id)
	assert_not_null(copy)
	assert_ne(copy, relay)
	assert_eq(copy.position, relay.position)
	assert_eq(copy.label, "North")
	assert_eq(again.core().level(GameConfig.TRACK_RATE), 1)
	assert_almost_eq(again.core().hp, core.max_hp(), 0.001)
	assert_eq(again.building(lamp.id).light_radius, 5.0)
	assert_not_null(again.find_link(core.id, relay.id))
	assert_eq(again.nav.occupant_at(copy.origin), copy.id)
	assert_eq(again.id_counter(), checkpoint.next_id)
	assert_eq(restored.checkpoint, checkpoint)
	assert_true(restored.history.is_active())
	assert_false(restored.can_undo())
	assert_true(again.scout.boarded)
	assert_eq(again.scout.position, again.core().position)
	assert_true(again.structures_spawned)


func test_restore_brings_back_trees_destroyed_after_the_start() -> void:
	var before := _tree(Vector2i(4, 0))
	var after := _tree(Vector2i(-4, 0))
	state.clear_obstacle(before)
	battle.start_round()
	state.clear_obstacle(after)
	assert_true(state.map.is_walkable(after))
	var again := battle.checkpoint.restore().state
	assert_eq(again.map.tile(after), LevelMap.Tile.TREE)
	assert_true(again.nav.walker.is_point_solid(after))
	assert_eq(again.map.tile(before), LevelMap.Tile.OPEN)
	assert_false(again.nav.walker.is_point_solid(before))
	assert_eq(state.map.tile(after), LevelMap.Tile.OPEN)


func test_restore_keeps_fog_obstacle_damage_and_focus() -> void:
	var hidden := _far_corner()
	state.fog.cells[state.map.index(hidden)] = FogOfWar.HIDDEN
	var tree := _tree(Vector2i(3, 0))
	var obstacle := state.obstacle_at(tree)
	obstacle.hp = 50.0
	var lost := _tree(Vector2i(-3, 0))
	state.obstacle_at(lost).hp = 0.0
	var zapper := BattleFixtures.add(battle, GameConfig.ZAPPER, core.position + Vector2(0, 150))
	assert_eq(battle.focus(core.id, obstacle), Combat.OK)
	var nest: Building = state.enemy_buildings()[0]
	zapper.focus = nest
	battle.start_round()
	var again := battle.checkpoint.restore().state
	assert_false(again.fog.is_explored(hidden))
	assert_true(again.fog.is_explored(state.map.cell_of(core.position)))
	var copy := again.obstacle_at(tree)
	assert_ne(copy, obstacle)
	assert_eq(copy.id, obstacle.id)
	assert_almost_eq(copy.hp, 50.0, 0.001)
	assert_eq(again.core().focus, copy)
	assert_eq(again.building(zapper.id).focus, again.building(nest.id))
	assert_ne(again.building(zapper.id).focus, nest)


func test_restore_can_run_more_than_once() -> void:
	battle.place(GameConfig.RELAY, core.position + Vector2(0, -150))
	var tree := _tree(Vector2i(4, 0))
	battle.start_round()
	var checkpoint := battle.checkpoint
	var first := checkpoint.restore()
	first.state.clear_obstacle(tree)
	first.state.money = 0
	first.state.of_kind(GameConfig.RELAY)[0].hp = 1.0
	var second := checkpoint.restore()
	assert_eq(second.state.map.tile(tree), LevelMap.Tile.TREE)
	assert_eq(second.state.money, checkpoint.money)
	var relay: Building = second.state.of_kind(GameConfig.RELAY)[0]
	assert_almost_eq(relay.hp, relay.max_hp(), 0.001)
	assert_true(second.start_round())
	assert_ne(second.checkpoint, checkpoint)


func test_restore_keeps_marked_fuel_and_the_rules() -> void:
	var survival := Battle.new(BattleState.create(0, 77, BattleSetup.survival(10)))
	var fresh := survival.state
	BattleFixtures.open_terrain(fresh)
	fresh.spawn_structures(fresh.map.structures)
	fresh.place_core(fresh.map.drop)
	survival.history.begin(fresh)
	var fire := BattleFixtures.add(survival, GameConfig.FIRE, fresh.core().position + Vector2(-168, 0))
	var tree := fresh.map.cell_of(fire.position) + Vector2i(0, -2)
	fresh.map.set_tile(tree, LevelMap.Tile.TREE)
	fresh.nav.terrain_changed(tree)
	assert_eq(survival.toggle_fuel(fire.id, tree), FuelControl.OK)
	assert_true(survival.start_round())
	var checkpoint := survival.checkpoint
	assert_eq(checkpoint.rng_seed, fresh.rng.seed)
	var again := checkpoint.restore().state
	assert_true(again.is_survival())
	assert_eq(again.setup.days, 10)
	assert_eq(again.building(fire.id).fuel, [tree] as Array[Vector2i])
	assert_eq(again.rng.seed, fresh.rng.seed)
	assert_true(again.enemy_buildings()[0].immune)


func test_restored_soldier_sits_in_the_core() -> void:
	state.scout.position = core.position + Vector2(300, 20)
	var again := BattleCheckpoint.capture(state).restore().state
	assert_true(again.scout.boarded)
	assert_true(again.scout.is_landed())
	assert_false(again.scout.is_controllable())
	assert_eq(again.scout.position, again.core().position)
