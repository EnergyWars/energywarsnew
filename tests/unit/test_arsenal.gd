extends GutTest


func test_starter_arsenal() -> void:
	var arsenal := Arsenal.new()
	assert_eq(arsenal.kinds(), GameConfig.STARTER_KINDS)
	assert_false(arsenal.has(GameConfig.LASER))
	assert_eq(arsenal.money_bonus, 0)
	assert_true(arsenal.boosts_for(GameConfig.ZAPPER).is_empty())
	assert_eq(arsenal.boost(GameConfig.ZAPPER, GameConfig.BOOST_DAMAGE), 1.0)


func test_unlocks_and_money() -> void:
	var arsenal := Arsenal.from_techs(["laser", "funding_1", "funding_2", "bogus"])
	assert_true(arsenal.has(GameConfig.LASER))
	assert_eq(arsenal.money_bonus, 180)
	assert_eq(arsenal.kinds().find(GameConfig.LASER), GameConfig.STARTER_KINDS.size())


func test_boosts_stack_per_kind() -> void:
	var arsenal := Arsenal.from_techs(["zapper_power", "weapons_1", "weapons_2", "plating_1"])
	assert_almost_eq(arsenal.boost(GameConfig.ZAPPER, GameConfig.BOOST_DAMAGE), 1.4, 0.0001)
	assert_almost_eq(arsenal.boost(GameConfig.LASER, GameConfig.BOOST_DAMAGE), 1.2, 0.0001)
	assert_eq(arsenal.boost(GameConfig.SOLAR, GameConfig.BOOST_DAMAGE), 1.0)
	assert_almost_eq(arsenal.boost(GameConfig.CORE, GameConfig.BOOST_HP), 1.15, 0.0001)
	assert_almost_eq(arsenal.boost(GameConfig.BULWARK, GameConfig.BOOST_HP), 1.15, 0.0001)
	assert_eq(arsenal.boost(GameConfig.CORE, GameConfig.BOOST_DAMAGE), 1.0)


func test_targets() -> void:
	assert_eq(Arsenal.targets(GameConfig.SOLAR), [GameConfig.SOLAR] as Array[String])
	var towers := Arsenal.targets(GameConfig.ALL_TOWERS)
	assert_true(towers.has(GameConfig.ROVER))
	assert_false(towers.has(GameConfig.CORE))
	assert_false(towers.has(GameConfig.TURRET))
	var everything := Arsenal.targets(GameConfig.ALL_BUILDINGS)
	assert_true(everything.has(GameConfig.CORE))
	assert_false(everything.has(GameConfig.NEST))
	assert_true(Arsenal.targets("bogus").is_empty())


func test_everything_unlocks_all_kinds() -> void:
	assert_eq(Arsenal.everything().kinds(), GameConfig.BUILD_ORDER)


func test_battle_applies_the_arsenal() -> void:
	var arsenal := Arsenal.from_techs(["laser", "plating_1", "funding_1"])
	var state := BattleState.create(0, 1, BattleSetup.campaign(arsenal))
	assert_eq(state.money, int(GameConfig.level(0).money) + 60)
	assert_true(state.is_available(GameConfig.LASER))
	assert_false(state.is_available(GameConfig.TESLA))
	assert_eq(state.available_kinds(), arsenal.kinds())
	var zapper := state.add_building(GameConfig.ZAPPER, state.map.drop)
	assert_almost_eq(zapper.max_hp(), float(GameConfig.building(GameConfig.ZAPPER).hp) * 1.15, 0.001)
	assert_eq(zapper.hp, zapper.max_hp())
	state.spawn_structures(state.map.structures)
	var nest: Building = state.enemy_buildings()[0]
	assert_eq(nest.max_hp(), float(GameConfig.building(GameConfig.NEST).hp))
	assert_false(nest.immune)


func test_default_state_uses_the_starter_arsenal() -> void:
	var state := BattleState.create(0)
	assert_false(state.is_survival())
	assert_eq(state.available_kinds(), GameConfig.STARTER_KINDS)
	assert_eq(state.money, int(GameConfig.level(0).money))


func test_with_all_kinds_copies_the_research() -> void:
	var research := Arsenal.from_techs(["zapper_power", "funding_1"])
	var full := research.with_all_kinds()
	assert_eq(full.kinds(), GameConfig.BUILD_ORDER)
	assert_eq(full.money_bonus, research.money_bonus)
	assert_almost_eq(full.boost(GameConfig.ZAPPER, GameConfig.BOOST_DAMAGE), research.boost(GameConfig.ZAPPER, GameConfig.BOOST_DAMAGE), 0.0001)
	assert_false(is_same(full.boosts_for(GameConfig.ZAPPER), research.boosts_for(GameConfig.ZAPPER)))
	assert_false(research.has(GameConfig.LASER))
	assert_eq(research.kinds(), GameConfig.STARTER_KINDS)
