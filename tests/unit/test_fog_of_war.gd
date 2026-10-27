extends GutTest


func _state() -> BattleState:
	var state := BattleState.create(0)
	state.fog.cells.fill(FogOfWar.HIDDEN)
	return state


func test_starts_with_drop_zone_revealed() -> void:
	var state := BattleState.create(0)
	assert_true(state.fog.is_visible(state.map.drop))
	assert_false(state.fog.is_explored_at(state.map.structures[0].position))


func test_reveal_marks_cells_in_radius() -> void:
	var state := _state()
	var center := state.map.drop
	state.fog.reveal(center, 200.0)
	assert_true(state.fog.is_visible(center))
	assert_true(state.fog.is_visible(center + Vector2(150, 0)))
	assert_false(state.fog.is_visible(center + Vector2(300, 0)))
	assert_eq(state.fog.state_of(Vector2i(-1, -1)), FogOfWar.HIDDEN)


func test_refresh_downgrades_to_explored_and_follows_sources() -> void:
	var state := _state()
	var old := state.map.drop
	state.fog.refresh(state)
	assert_true(state.fog.is_visible(old))
	state.scout.position = old + Vector2(0, -1200)
	state.fog.refresh(state)
	assert_false(state.fog.is_visible(old))
	assert_true(state.fog.is_explored_at(old))
	assert_true(state.fog.is_visible(state.scout.position))


func test_buildings_reveal_their_vision() -> void:
	var state := _state()
	state.scout = null
	var core := state.place_core(state.map.drop)
	state.fog.refresh(state)
	assert_true(state.fog.is_visible(core.position + Vector2(Formulas.vision(core) - 60.0, 0)))
	assert_false(state.fog.is_visible(core.position + Vector2(Formulas.vision(core) + 80.0, 0)))


func test_update_is_throttled() -> void:
	var state := _state()
	var version := state.fog.version
	state.fog.update(state, 0.01)
	assert_gt(state.fog.version, version)
	version = state.fog.version
	state.fog.update(state, 0.01)
	assert_eq(state.fog.version, version)
	state.fog.update(state, GameConfig.FOG_INTERVAL)
	assert_gt(state.fog.version, version)


func test_is_explored_by_cell() -> void:
	var state := _state()
	assert_false(state.fog.is_explored(Vector2i(0, 0)))
	state.fog.reveal(state.map.center_of(Vector2i(0, 0)), 10.0)
	assert_true(state.fog.is_explored(Vector2i(0, 0)))
	assert_false(state.fog.is_explored(Vector2i(-3, 0)))


func test_building_vision_is_cached_until_buildings_change() -> void:
	var battle := BattleFixtures.deployed(0)
	var state := battle.state
	var core := state.core()
	state.money = 100000
	var zapper := BattleFixtures.add(battle, GameConfig.ZAPPER, core.position + Vector2(0, -280))
	state.fog.cells.fill(FogOfWar.HIDDEN)
	state.fog.refresh(state)
	var near := zapper.position + Vector2(0, -Formulas.vision(zapper) + 20.0)
	var edge := zapper.position + Vector2(0, -Formulas.vision(zapper) - 20.0)
	assert_gt(core.position.distance_to(near), Formulas.vision(core))
	assert_true(state.fog.is_visible(near))
	assert_false(state.fog.is_visible(edge))
	assert_true(battle.upgrade(zapper.id, GameConfig.TRACK_RANGE))
	state.fog.refresh(state)
	assert_true(state.fog.is_visible(edge))
	battle.combat.destroy(zapper)
	state.fog.refresh(state)
	assert_false(state.fog.is_visible(near))
	assert_true(state.fog.is_explored_at(near))
