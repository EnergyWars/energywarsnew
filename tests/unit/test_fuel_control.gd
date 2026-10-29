extends GutTest

var battle: Battle
var state: BattleState
var core: Building
var fire: Building


func before_each() -> void:
	battle = BattleFixtures.battle(GameConfig.level_count() - 1, false)
	state = battle.state
	core = state.core()
	fire = BattleFixtures.add(battle, GameConfig.FIRE, core.position + Vector2(-224, 0))
	battle.events.drain()


func _tree(offset: Vector2i) -> Vector2i:
	var cell := state.map.cell_of(fire.position) + offset
	state.map.set_tile(cell, LevelMap.Tile.TREE)
	state.nav.terrain_changed(cell)
	return cell


func _fight() -> void:
	state.phase = BattleState.Phase.FIGHT


func test_fire_pit_is_a_cheap_strong_burner() -> void:
	var definition := GameConfig.building(GameConfig.FIRE)
	assert_true(GameConfig.is_burner(GameConfig.FIRE))
	assert_false(GameConfig.is_burner(GameConfig.SOLAR))
	assert_true(fire.burner)
	assert_lt(int(definition.cost), int(GameConfig.building(GameConfig.SOLAR).cost))
	assert_gt(float(definition.output), float(GameConfig.building(GameConfig.SOLAR).output))
	assert_false(GameConfig.STARTER_KINDS.has(GameConfig.FIRE))
	assert_eq(GameConfig.tech("fire").unlock, GameConfig.FIRE)


func test_marking_needs_an_explored_tree_in_reach() -> void:
	var fuel := battle.fuel
	var tree := _tree(Vector2i(0, -2))
	assert_eq(fuel.reason(fire, tree), FuelControl.OK)
	assert_eq(fuel.reason(fire, tree + Vector2i(0, 1)), FuelControl.NOT_TREE)
	var far := _tree(Vector2i(0, -6))
	assert_eq(fuel.reason(fire, far), FuelControl.RANGE)
	assert_false(fuel.in_reach(fire, far))
	var hidden := _tree(Vector2i(2, 2))
	state.fog.cells[state.map.index(hidden)] = FogOfWar.HIDDEN
	assert_eq(fuel.reason(fire, hidden), FuelControl.UNEXPLORED)
	assert_eq(fuel.reason(null, tree), FuelControl.INVALID)
	assert_eq(fuel.reason(core, tree), FuelControl.INVALID)
	var nest := BattleFixtures.add(battle, GameConfig.NEST, core.position + Vector2(0, -900))
	assert_eq(fuel.reason(nest, tree), FuelControl.INVALID)
	fire.hp = 0.0
	assert_eq(fuel.reason(fire, tree), FuelControl.INVALID)
	fire.hp = fire.max_hp()
	state.phase = BattleState.Phase.LOST
	assert_eq(fuel.reason(fire, tree), FuelControl.INVALID)


func test_candidates_list_every_markable_tree() -> void:
	var near := _tree(Vector2i(0, -2))
	var side := _tree(Vector2i(-3, 0))
	_tree(Vector2i(0, -6))
	var candidates := battle.fuel.candidates(fire)
	assert_true(candidates.has(near))
	assert_true(candidates.has(side))
	assert_eq(candidates.size(), 2)
	assert_true(battle.fuel.candidates(core).is_empty())
	assert_true(battle.fuel.candidates(null).is_empty())


func test_toggle_marks_and_unmarks_trees() -> void:
	var tree := _tree(Vector2i(0, -2))
	var layout := state.layout_version
	assert_eq(battle.fuel.toggle(fire, tree), FuelControl.OK)
	assert_eq(fire.fuel, [tree] as Array[Vector2i])
	assert_gt(state.layout_version, layout)
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "fuel_marked").size(), 1)
	assert_eq(battle.fuel.toggle(fire, tree), FuelControl.OK)
	assert_true(fire.fuel.is_empty())
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "fuel_unmarked").size(), 1)
	assert_eq(battle.fuel.toggle(fire, tree + Vector2i(0, 1)), FuelControl.NOT_TREE)
	assert_true(fire.fuel.is_empty())
	assert_eq(battle.fuel.toggle(null, tree), FuelControl.INVALID)


func test_fire_produces_nothing_without_marked_trees() -> void:
	assert_eq(Formulas.generation(fire, 1.0), 0.0)
	assert_eq(Formulas.forecast_output(fire, false), 0.0)
	var without := state.generation()
	battle.fuel.toggle(fire, _tree(Vector2i(0, -2)))
	assert_eq(Formulas.generation(fire, 0.0), Formulas.output(fire))
	assert_eq(Formulas.forecast_output(fire, true), Formulas.output(fire))
	assert_almost_eq(state.generation() - without, Formulas.output(fire), 0.001)


func test_burning_a_tree_takes_time_and_opens_the_ground() -> void:
	var tree := _tree(Vector2i(0, -2))
	var second := _tree(Vector2i(1, -2))
	battle.fuel.toggle(fire, tree)
	battle.fuel.toggle(fire, second)
	battle.events.drain()
	assert_almost_eq(Formulas.fuel_time(fire), GameConfig.FIRE_BURN_TIME * 2.0, 0.001)
	battle.fuel.update(1.0)
	assert_eq(fire.burn_cell, tree)
	assert_almost_eq(battle.fuel.burn_ratio(fire), 1.0 / GameConfig.FIRE_BURN_TIME, 0.0001)
	assert_almost_eq(Formulas.fuel_time(fire), GameConfig.FIRE_BURN_TIME * 2.0 - 1.0, 0.001)
	battle.fuel.update(GameConfig.FIRE_BURN_TIME)
	assert_true(state.map.is_walkable(tree))
	assert_false(state.nav.walker.is_point_solid(tree))
	assert_eq(fire.fuel, [second] as Array[Vector2i])
	assert_eq(fire.burn_cell, Building.NO_CELL)
	var cleared := BattleFixtures.of_type(battle.events.drain(), "cleared")
	assert_eq(cleared.size(), 1)
	assert_eq(cleared[0].fire, fire.id)
	assert_eq(cleared[0].cell, tree)
	battle.fuel.update(GameConfig.FIRE_BURN_TIME + 0.1)
	assert_true(fire.fuel.is_empty())
	var events := battle.events.drain()
	assert_eq(BattleFixtures.of_type(events, "fuel_empty").size(), 1)
	assert_eq(Formulas.generation(fire, 1.0), 0.0)
	assert_eq(Formulas.fuel_time(fire), 0.0)
	assert_eq(battle.fuel.burn_ratio(fire), 0.0)
	battle.fuel.update(1.0)
	assert_true(BattleFixtures.of_type(battle.events.drain(), "fuel_empty").is_empty())


func test_unmarking_the_burning_tree_stops_the_fire() -> void:
	var tree := _tree(Vector2i(0, -2))
	battle.fuel.toggle(fire, tree)
	battle.fuel.update(3.0)
	assert_eq(fire.burn_cell, tree)
	battle.fuel.toggle(fire, tree)
	assert_eq(fire.burn_cell, Building.NO_CELL)
	assert_eq(fire.burn_progress, 0.0)
	assert_eq(state.map.tile(tree), LevelMap.Tile.TREE)


func test_trees_removed_elsewhere_drop_out_of_the_fuel() -> void:
	var tree := _tree(Vector2i(0, -2))
	var second := _tree(Vector2i(1, -2))
	battle.fuel.toggle(fire, tree)
	battle.fuel.toggle(fire, second)
	var layout := state.layout_version
	state.clear_obstacle(tree)
	assert_eq(fire.fuel, [second] as Array[Vector2i])
	assert_gt(state.layout_version, layout)
	state.map.set_tile(second, LevelMap.Tile.OPEN)
	battle.fuel.update(0.1)
	assert_true(fire.fuel.is_empty())
	assert_eq(fire.burn_cell, Building.NO_CELL)


func test_fire_only_burns_while_fighting() -> void:
	BattleFixtures.add(battle, GameConfig.NEST, core.position + Vector2(0, -900))
	var tree := _tree(Vector2i(0, -2))
	assert_eq(battle.toggle_fuel(fire.id, tree), FuelControl.OK)
	battle.tick(GameConfig.TICK)
	assert_eq(fire.burn_progress, 0.0)
	assert_true(battle.start_round())
	battle.tick(GameConfig.TICK)
	assert_eq(fire.burn_cell, tree)
	assert_gt(fire.burn_progress, 0.0)
	assert_gt(fire.energy, 0.0)


func test_battle_toggle_validates_and_allows_unmarking() -> void:
	var tree := _tree(Vector2i(0, -2))
	assert_eq(battle.toggle_fuel(-1, tree), FuelControl.INVALID)
	assert_eq(battle.toggle_fuel(fire.id, tree + Vector2i(0, 1)), FuelControl.NOT_TREE)
	assert_eq(battle.toggle_fuel(fire.id, tree), FuelControl.OK)
	_fight()
	state.map.set_tile(tree, LevelMap.Tile.OPEN)
	assert_eq(battle.toggle_fuel(fire.id, tree), FuelControl.OK)
	assert_true(fire.fuel.is_empty())
	assert_eq(battle.toggle_fuel(fire.id, _tree(Vector2i(0, 2))), FuelControl.OK)
	state.phase = BattleState.Phase.LOST
	assert_eq(battle.toggle_fuel(fire.id, state.map.cell_of(fire.position) + Vector2i(0, 2)), FuelControl.INVALID)


func test_fire_pit_feeds_the_network() -> void:
	var tree := _tree(Vector2i(0, -2))
	battle.toggle_fuel(fire.id, tree)
	assert_eq(battle.connect_buildings(fire.id, core.id), EnergyNetwork.OK)
	core.energy = 0.0
	_fight()
	battle.network.flow(1.0)
	assert_gt(core.energy, Formulas.output(core) + 5.0)


func test_copy_keeps_fuel_and_burn_state() -> void:
	var tree := _tree(Vector2i(0, -2))
	battle.fuel.toggle(fire, tree)
	battle.fuel.update(2.0)
	var copy := fire.copy()
	assert_eq(copy.fuel, fire.fuel)
	assert_eq(copy.burn_cell, tree)
	assert_almost_eq(copy.burn_progress, 2.0, 0.0001)
	copy.fuel.clear()
	assert_eq(fire.fuel.size(), 1)
