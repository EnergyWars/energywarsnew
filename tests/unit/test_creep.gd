extends GutTest

var battle: Battle
var state: BattleState
var core: Building


func before_each() -> void:
	battle = BattleFixtures.battle(0)
	state = battle.state
	core = state.core()
	state.money = 5000
	battle.events.drain()


func _plant(cells: Array[Vector2i]) -> void:
	var entries: Array[Dictionary] = []
	for cell in cells:
		entries.append({"cell": cell, "alive": true, "fade": 1.0})
	state.creep.restore(entries)


func _gap(nest: CreepNest) -> float:
	return Vector2(nest.cell - state.map.cell_of(core.position)).length()


func _deployed() -> Battle:
	var fresh := Battle.start(0)
	fresh.state.scout.drop_left = 0.0
	fresh.state.fog.reveal(fresh.state.map.drop, 600.0)
	fresh.deploy_core(fresh.state.map.drop)
	return fresh


func test_nest_radius_shrinks_with_fade() -> void:
	var nest := CreepNest.new(3, Vector2i(4, 5), Vector2(10, 20))
	assert_eq(nest.id, 3)
	assert_true(nest.alive)
	assert_true(nest.is_active())
	assert_almost_eq(nest.radius_cells(), GameConfig.CREEP_RADIUS, 0.001)
	nest.fade = 0.5
	assert_almost_eq(nest.radius_cells(), GameConfig.CREEP_RADIUS * 0.5, 0.001)
	nest.fade = 0.0
	assert_false(nest.is_active())


func test_disk_has_every_cell_within_the_radius() -> void:
	var disk := Creep.disk()
	assert_eq(disk.size(), 113)
	assert_true(disk.has(Vector2i(6, 0)))
	assert_true(disk.has(Vector2i(0, -6)))
	assert_false(disk.has(Vector2i(5, 5)))


func test_rim_is_slimed_and_sealed_before_the_core() -> void:
	var fresh := Battle.start(0)
	var map := fresh.state.map
	assert_true(fresh.state.creep.is_sealed())
	for cell in [Vector2i(0, 0), Vector2i(5, 20), Vector2i(20, 5), Vector2i(map.width - 1, 30), Vector2i(30, map.height - 6)]:
		assert_true(map.is_slimed(cell), str(cell))
		assert_true(map.is_sealed(cell), str(cell))
		assert_true(fresh.state.nav.walker.is_point_solid(cell), str(cell))
		assert_false(map.is_buildable(cell), str(cell))
	for cell in [Vector2i(6, 20), Vector2i(20, 6), Vector2i(map.width - 7, 30), map.cell_of(map.drop)]:
		assert_false(map.is_slimed(cell), str(cell))
		assert_false(map.is_sealed(cell), str(cell))
	assert_true(fresh.state.creep.nests.is_empty())


func test_soldier_cannot_walk_into_the_rim() -> void:
	var fresh := Battle.start(0)
	BattleFixtures.open_terrain(fresh.state)
	var map := fresh.state.map
	var scout := fresh.state.scout
	scout.position = map.center_of(Vector2i(map.width / 2, GameConfig.CREEP_RIM + 2))
	assert_eq(fresh.steer_scout(Vector2.UP), ScoutControl.OK)
	for i in 180:
		fresh.tick(GameConfig.TICK)
	assert_gte(scout.position.y, float(GameConfig.CREEP_RIM) * GameConfig.CELL)


func test_core_cannot_be_placed_in_the_rim() -> void:
	var fresh := Battle.start(0)
	var map := fresh.state.map
	fresh.state.scout.drop_left = 0.0
	var spot := map.center_of(Vector2i(3, 3))
	fresh.state.scout.position = spot
	fresh.state.fog.reveal(spot, 300.0)
	assert_eq(BuildRules.reason(fresh.state, GameConfig.CORE, spot), BuildRules.SLIME)


func test_placing_the_core_releases_the_rim() -> void:
	var map := state.map
	assert_false(state.creep.is_sealed())
	assert_false(map.is_slimed(Vector2i(0, 0)))
	assert_false(map.is_sealed(Vector2i(2, 2)))
	assert_false(state.nav.walker.is_point_solid(Vector2i(2, 2)))
	assert_true(state.creep.nests.is_empty())


func test_deploying_the_core_spawns_nests() -> void:
	var fresh := _deployed()
	var spawned := BattleFixtures.of_type(fresh.events.drain(), "creep_spawned")
	assert_eq(spawned.size(), 1)
	assert_gt(int(spawned[0].count), 3)
	assert_eq(int(spawned[0].count), fresh.state.creep.nests.size())
	assert_false(fresh.state.creep.is_sealed())


func test_nests_keep_their_distance_from_the_core() -> void:
	state.creep.spawn(core.position)
	assert_gt(state.creep.nests.size(), 3)
	for nest in state.creep.nests:
		assert_gte(_gap(nest), GameConfig.CREEP_CORE_CLEAR, str(nest.cell))


func test_nests_stand_on_free_walkable_cells() -> void:
	state.creep.spawn(core.position)
	for nest in state.creep.nests:
		assert_true(state.map.is_walkable(nest.cell), str(nest.cell))
		assert_eq(state.nav.occupant_at(nest.cell), NavGrid.FREE, str(nest.cell))
		assert_eq(state.map.center_of(nest.cell), nest.position)
		assert_true(nest.alive)
		assert_eq(nest.fade, 1.0)


func test_first_nest_sits_in_the_rim_as_far_as_possible() -> void:
	state.creep.spawn(core.position)
	var first := state.creep.nests[0]
	assert_true(state.creep.in_rim(first.cell))
	for nest in state.creep.nests:
		if state.creep.in_rim(nest.cell):
			assert_lte(_gap(nest), _gap(first) + 0.001)


func test_slime_covers_the_map_outside_the_core_zone() -> void:
	state.creep.spawn(core.position)
	var map := state.map
	var core_cell := map.cell_of(core.position)
	var total := 0
	var covered := 0
	for i in map.width * map.height:
		var cell := map.cell_at(i)
		var gap := Vector2(cell - core_cell).length()
		if gap < GameConfig.CREEP_CORE_CLEAR - GameConfig.CREEP_RADIUS:
			assert_false(map.is_slimed(cell), str(cell))
		elif gap >= GameConfig.CREEP_CORE_CLEAR - GameConfig.CREEP_RADIUS + 2.0:
			total += 1
			covered += 1 if map.is_slimed(cell) else 0
	assert_gte(float(covered) / float(total), 0.97)


func test_nests_do_not_pile_up() -> void:
	state.creep.spawn(core.position)
	var map := state.map
	var layers := PackedInt32Array()
	layers.resize(map.width * map.height)
	for nest in state.creep.nests:
		for offset in Creep.disk():
			var cell := nest.cell + offset
			if map.has_cell(cell):
				layers[map.index(cell)] += 1
	var covered := 0
	var stacked := 0
	var triple := 0
	for value in layers:
		if value > 0:
			covered += 1
			stacked += value
			triple += 1 if value >= 3 else 0
	assert_lte(state.creep.nests.size(), 50)
	assert_lte(float(stacked) / covered, 1.6)
	assert_lte(float(triple) / covered, 0.12)


func test_slime_blocks_building_and_leaves_the_core_surroundings_free() -> void:
	state.creep.spawn(core.position)
	var nest := state.creep.nests[0]
	assert_eq(BuildRules.reason(state, GameConfig.SOLAR, nest.position), BuildRules.SLIME)
	assert_eq(BuildRules.reason(state, GameConfig.SOLAR, core.position + Vector2(120, 0)), BuildRules.OK)


func test_slime_marks_cells_unbuildable_across_cliffs() -> void:
	var cliff := state.map.cell_of(Vector2(300, 300))
	_plant([cliff + Vector2i(1, 0)])
	state.map.set_tile(cliff, LevelMap.Tile.CLIFF)
	assert_true(state.map.is_slimed(cliff))
	assert_true(state.map.is_slimed(cliff + Vector2i(1, 0) + Vector2i(6, 0)))
	assert_false(state.map.is_slimed(cliff + Vector2i(1, 0) + Vector2i(7, 0)))


func test_spawn_is_deterministic() -> void:
	state.creep.spawn(core.position)
	var first: Array[Vector2i] = []
	for nest in state.creep.nests:
		first.append(nest.cell)
	state.creep.spawn(core.position)
	var second: Array[Vector2i] = []
	for nest in state.creep.nests:
		second.append(nest.cell)
	assert_eq(first, second)


func test_respawning_replaces_old_nests() -> void:
	state.creep.spawn(core.position)
	var count := state.creep.nests.size()
	state.creep.spawn(core.position)
	assert_eq(state.creep.nests.size(), count)
	assert_eq(state.creep.nests[0].id, 0)


func test_towers_in_reach_destroy_a_nest_with_one_strike() -> void:
	_plant([Vector2i(10, 10)])
	var nest := state.creep.nests[0]
	var tower := BattleFixtures.add(battle, GameConfig.ZAPPER, nest.position + Vector2(GameConfig.CELL * 4.0, 0))
	assert_true(battle.creeping.reaches(nest, tower))
	assert_eq(battle.creeping.strike(), 1)
	assert_false(nest.alive)
	var killed := BattleFixtures.of_type(battle.events.drain(), "nest_killed")
	assert_eq(killed.size(), 1)
	assert_eq(killed[0].position, nest.position)
	assert_eq(killed[0].left, 0)
	assert_eq(battle.creeping.strike(), 0)


func test_far_towers_do_not_reach_a_nest() -> void:
	_plant([Vector2i(10, 10)])
	var nest := state.creep.nests[0]
	var tower := BattleFixtures.add(battle, GameConfig.ZAPPER, nest.position + Vector2(800, 0))
	assert_false(battle.creeping.reaches(nest, tower))
	assert_eq(battle.creeping.strike(), 0)
	assert_true(nest.alive)
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "nest_killed").size(), 0)


func test_unarmed_buildings_do_not_destroy_nests() -> void:
	_plant([Vector2i(10, 10)])
	var nest := state.creep.nests[0]
	BattleFixtures.add(battle, GameConfig.RELAY, nest.position + Vector2(GameConfig.CELL * 2.0, 0))
	assert_eq(battle.creeping.strike(), 0)
	assert_true(nest.alive)


func test_the_core_reaches_nests_too() -> void:
	_plant([state.map.cell_of(core.position) + Vector2i(0, -5)])
	assert_eq(battle.creeping.strike(), 1)


func test_nests_fall_during_the_planning_phase() -> void:
	_plant([Vector2i(10, 10)])
	var nest := state.creep.nests[0]
	BattleFixtures.add(battle, GameConfig.ZAPPER, nest.position + Vector2(GameConfig.CELL * 3.0, 0))
	assert_true(state.is_planning())
	battle.tick(GameConfig.TICK)
	assert_false(nest.alive)
	assert_true(state.is_planning())


func test_killing_reports_the_remaining_nests() -> void:
	_plant([Vector2i(10, 10), Vector2i(40, 10)])
	var near := state.creep.nests[0]
	BattleFixtures.add(battle, GameConfig.ZAPPER, near.position + Vector2(GameConfig.CELL * 3.0, 0))
	battle.creeping.strike()
	var killed := BattleFixtures.of_type(battle.events.drain(), "nest_killed")
	assert_eq(killed.size(), 1)
	assert_eq(killed[0].left, 1)
	assert_eq(state.creep.alive_nests().size(), 1)


func test_killing_twice_does_nothing() -> void:
	_plant([Vector2i(10, 10)])
	var nest := state.creep.nests[0]
	assert_true(state.creep.kill(nest))
	assert_false(state.creep.kill(nest))


func test_slime_recedes_from_the_outside_in() -> void:
	_plant([Vector2i(10, 10)])
	var map := state.map
	state.creep.kill(state.creep.nests[0])
	battle.creeping.update(GameConfig.CREEP_RECEDE_TIME * 0.5)
	assert_almost_eq(state.creep.nests[0].fade, 0.5, 0.001)
	assert_true(map.is_slimed(Vector2i(10, 10)))
	assert_true(map.is_slimed(Vector2i(13, 10)))
	assert_false(map.is_slimed(Vector2i(14, 10)))
	assert_false(map.is_slimed(Vector2i(16, 10)))


func test_slime_disappears_completely() -> void:
	_plant([Vector2i(10, 10)])
	var map := state.map
	var version := state.creep.version
	state.creep.kill(state.creep.nests[0])
	battle.creeping.update(GameConfig.CREEP_RECEDE_TIME + 1.0)
	assert_eq(state.creep.nests[0].fade, 0.0)
	assert_false(map.is_slimed(Vector2i(10, 10)))
	assert_false(map.slime.has(1))
	assert_gt(state.creep.version, version)
	assert_false(state.creep.flush())


func test_living_nests_keep_their_slime() -> void:
	_plant([Vector2i(10, 10)])
	battle.creeping.update(GameConfig.CREEP_RECEDE_TIME * 3.0)
	assert_eq(state.creep.nests[0].fade, 1.0)
	assert_true(state.map.is_slimed(Vector2i(16, 10)))


func test_overlapping_slime_stays_until_the_last_nest_is_gone() -> void:
	_plant([Vector2i(10, 10), Vector2i(15, 10)])
	var map := state.map
	state.creep.kill(state.creep.nests[0])
	battle.creeping.update(GameConfig.CREEP_RECEDE_TIME + 1.0)
	assert_true(map.is_slimed(Vector2i(12, 10)))
	assert_false(map.is_slimed(Vector2i(8, 10)))
	assert_true(map.is_slimed(Vector2i(15, 10)))


func test_recede_only_runs_for_dead_nests() -> void:
	_plant([Vector2i(10, 10)])
	assert_false(state.creep.recede(1.0))
	state.creep.kill(state.creep.nests[0])
	assert_true(state.creep.recede(1.0))


func test_building_is_possible_again_after_the_slime_receded() -> void:
	_plant([state.map.cell_of(core.position) + Vector2i(0, -6)])
	var nest := state.creep.nests[0]
	var spot := nest.position + Vector2(GameConfig.CELL * 3.0, 0)
	assert_eq(BuildRules.reason(state, GameConfig.SOLAR, spot), BuildRules.SLIME)
	state.creep.kill(nest)
	battle.creeping.update(GameConfig.CREEP_RECEDE_TIME + 1.0)
	assert_ne(BuildRules.reason(state, GameConfig.SOLAR, spot), BuildRules.SLIME)


func test_export_and_restore_keep_every_nest() -> void:
	state.creep.spawn(core.position)
	state.creep.kill(state.creep.nests[1])
	state.creep.nests[1].fade = 0.4
	state.creep.rebuild()
	var data := state.creep.export()
	var slime := state.map.slime.duplicate()
	var original := state.creep.nests.size()
	state.creep.nests.clear()
	state.creep.rebuild()
	assert_false(state.map.slime.has(1))
	state.creep.restore(data)
	assert_eq(state.creep.nests.size(), original)
	assert_false(state.creep.nests[1].alive)
	assert_almost_eq(state.creep.nests[1].fade, 0.4, 0.001)
	assert_eq(state.map.slime, slime)


func test_checkpoint_restores_the_nests() -> void:
	var fresh := _deployed()
	var creep := fresh.state.creep
	creep.kill(creep.nests[0])
	creep.nests[0].fade = 0.0
	creep.rebuild()
	var restored := BattleCheckpoint.capture(fresh.state).restore()
	assert_eq(restored.state.creep.nests.size(), creep.nests.size())
	assert_false(restored.state.creep.nests[0].alive)
	assert_eq(restored.state.creep.nests[0].fade, 0.0)
	assert_true(restored.state.creep.nests[1].alive)
	assert_eq(restored.state.map.slime, fresh.state.map.slime)
	assert_false(restored.state.creep.is_sealed())
	assert_false(restored.state.map.is_sealed(Vector2i(2, 2)))


func test_nest_at_finds_living_nests_only() -> void:
	_plant([Vector2i(10, 10)])
	assert_not_null(state.creep.nest_at(Vector2i(10, 10)))
	assert_null(state.creep.nest_at(Vector2i(11, 10)))
	state.creep.kill(state.creep.nests[0])
	assert_null(state.creep.nest_at(Vector2i(10, 10)))


func test_control_without_nests_does_nothing() -> void:
	var version := state.creep.version
	battle.creeping.update(5.0)
	assert_eq(state.creep.version, version)
	assert_eq(battle.creeping.strike(), 0)


func test_slime_blocks_building_but_not_walking() -> void:
	_plant([Vector2i(10, 10)])
	assert_false(state.map.is_buildable(Vector2i(10, 10)))
	assert_true(state.map.is_walkable(Vector2i(10, 10)))
