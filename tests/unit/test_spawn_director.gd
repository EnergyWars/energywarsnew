extends GutTest

var battle: Battle


func before_each() -> void:
	battle = BattleFixtures.battle(0)


func _cycle_length() -> float:
	return float(battle.state.level.spawns.cycle)


func test_prep_counts_down_then_fight_starts() -> void:
	var prep := battle.state.prep_left
	battle.spawns.update(1.0)
	assert_almost_eq(battle.state.prep_left, prep - 1.0, 0.001)
	assert_eq(battle.state.phase, BattleState.Phase.PREP)
	battle.spawns.update(prep)
	assert_eq(battle.state.phase, BattleState.Phase.FIGHT)
	assert_true(BattleFixtures.types(battle).has("fight_started"))
	assert_eq(battle.state.cycle, 0)


func test_skip_prep_grants_bonus() -> void:
	battle.state.prep_left = 20.5
	var money := battle.state.money
	assert_eq(battle.spawns.skip_prep(), 20)
	assert_eq(battle.state.money, money + 20)
	assert_eq(battle.state.phase, BattleState.Phase.FIGHT)
	assert_eq(battle.spawns.skip_prep(), 0)
	battle.spawns.start_fight()
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "fight_started").size(), 1)


func test_no_enemies_right_after_fight_starts() -> void:
	battle.spawns.start_fight()
	for i in int(5.0 / GameConfig.TICK):
		battle.spawns.update(GameConfig.TICK)
	assert_true(battle.state.enemies.is_empty())


func test_packs_arrive_more_often_towards_cycle_end() -> void:
	battle.spawns.start_fight()
	var length := _cycle_length()
	var steps := int(length / GameConfig.TICK)
	var first_half := 0
	var second_half := 0
	for i in steps:
		var before := battle.state.enemies.size()
		battle.spawns.update(GameConfig.TICK)
		var added := battle.state.enemies.size() - before
		if i < steps / 2:
			first_half += added
		else:
			second_half += added
	var expected := Formulas.cycle_count(battle.state.level.spawns, 0, false)
	assert_almost_eq(float(first_half + second_half), expected, float(GameConfig.PACK_BASE))
	assert_eq((first_half + second_half) % GameConfig.PACK_BASE, 0)
	assert_gt(second_half, first_half)


func test_cycle_advances_and_announces_surge_once() -> void:
	battle.spawns.start_fight()
	var length := _cycle_length()
	battle.spawns.update(length * GameConfig.SURGE_PHASE + 0.01)
	battle.spawns.update(0.5)
	var surges := BattleFixtures.of_type(battle.events.drain(), "surge")
	assert_eq(surges.size(), 1)
	assert_eq(surges[0].cycle, 0)
	assert_true(battle.state.surge_announced)
	battle.spawns.update(length * 0.3)
	assert_eq(battle.state.cycle, 1)
	assert_false(battle.state.surge_announced)
	assert_almost_eq(battle.spawns.phase(), (length * (GameConfig.SURGE_PHASE + 0.3 - 1.0) + 0.51) / length, 0.001)


func test_night_spawns_more() -> void:
	var spawns: Dictionary = battle.state.level.spawns
	assert_gt(Formulas.spawn_rate(spawns, 0, 0.5, true), Formulas.spawn_rate(spawns, 0, 0.5, false))


func test_enemies_spawn_in_packs_once_per_tick() -> void:
	battle.spawns.start_fight()
	var nest: Building = battle.state.enemy_buildings()[0]
	nest.spawn_progress = GameConfig.PACK_BASE - 0.5
	battle.spawns.update(GameConfig.TICK * 0.01)
	assert_true(battle.state.enemies.is_empty())
	nest.spawn_progress = 30.0
	battle.spawns.update(GameConfig.TICK)
	assert_eq(battle.state.enemies.size(), GameConfig.PACK_BASE)
	assert_almost_eq(nest.spawn_progress, 30.0 - GameConfig.PACK_BASE, 0.1)
	var center := Vector2.ZERO
	for enemy in battle.state.enemies:
		center += enemy.position - nest.position
	assert_gt(center.length() / battle.state.enemies.size(), nest.half_extent() * 0.5)


func test_pack_size_grows_and_caps() -> void:
	assert_eq(Formulas.pack_size(0), GameConfig.PACK_BASE)
	assert_eq(Formulas.pack_size(-3), GameConfig.PACK_BASE)
	assert_eq(Formulas.pack_size(GameConfig.PACK_EVERY), GameConfig.PACK_BASE + 1)
	assert_eq(Formulas.pack_size(200), GameConfig.PACK_MAX)


func test_turrets_do_not_spawn() -> void:
	battle = BattleFixtures.battle(3)
	battle.spawns.start_fight()
	for i in int(_cycle_length() / GameConfig.TICK):
		battle.spawns.update(GameConfig.TICK)
	for building in battle.state.enemy_buildings():
		if building.kind == GameConfig.TURRET:
			assert_eq(building.spawn_progress, 0.0)
	for enemy in battle.state.enemies:
		assert_true(GameConfig.SPAWNER_FACTIONS[GameConfig.CAMP].has(enemy.kind))


func test_spawned_enemies_appear_near_spawner() -> void:
	var nest: Building = battle.state.enemy_buildings()[0]
	var enemy := battle.spawns.spawn(nest)
	assert_eq(enemy.kind, "crawler")
	assert_lte(enemy.position.distance_to(nest.position), nest.half_extent() + GameConfig.CELL * (1.5 + GameConfig.SPAWN_RING))
	assert_true(battle.state.nav.is_free(battle.state.map.cell_of(enemy.position)))
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "spawn").size(), 1)


func test_pick_kind_respects_cycle_and_faction() -> void:
	battle = BattleFixtures.battle(7)
	battle.state.cycle = 0
	var nest_kinds := battle.spawns.candidates(GameConfig.NEST).map(func(entry: Array) -> String: return entry[0])
	assert_eq(nest_kinds, ["crawler"])
	assert_eq(battle.spawns.candidates(GameConfig.CAMP).map(func(entry: Array) -> String: return entry[0]), ["soldier"])
	battle.state.cycle = 10
	assert_eq(battle.spawns.candidates(GameConfig.NEST).size(), 5)
	for i in 50:
		assert_true(GameConfig.SPAWNER_FACTIONS[GameConfig.CAMP].has(battle.spawns.pick_kind(GameConfig.CAMP)))


func test_flyers_spawn_without_grid_snapping() -> void:
	battle.state.level = battle.state.level.duplicate(true)
	battle.state.level.spawns.roster = [["wasp", 0, 1.0]]
	var nest: Building = battle.state.enemy_buildings()[0]
	var wasp := battle.spawns.spawn(nest)
	assert_eq(wasp.kind, "wasp")
	assert_lte(wasp.position.distance_to(nest.position), nest.half_extent() + GameConfig.CELL * (0.5 + GameConfig.SPAWN_RING) + 0.01)


func test_pick_kind_falls_back_to_faction() -> void:
	assert_eq(battle.spawns.pick_kind(GameConfig.CAMP), "soldier")
	assert_eq(battle.spawns.pick_kind("unknown"), "crawler")


func test_enemy_hp_scales_with_cycle() -> void:
	var early := Enemy.new(1, "crawler", Vector2.ZERO, 0)
	var late := Enemy.new(2, "crawler", Vector2.ZERO, 3)
	var base := float(GameConfig.enemy("crawler").hp)
	assert_eq(early.max_hp, base)
	assert_almost_eq(late.max_hp, base * (1.0 + GameConfig.HP_GROWTH * 3), 0.001)
	assert_gt(late.bounty, early.bounty)
	var capped := Enemy.new(3, "crawler", Vector2.ZERO, GameConfig.HP_GROWTH_CYCLES + 40)
	assert_almost_eq(capped.max_hp, base * (1.0 + GameConfig.HP_GROWTH * GameConfig.HP_GROWTH_CYCLES), 0.001)
