extends GutTest

var battle: Battle
var state: BattleState
var nest: Building


func before_each() -> void:
	battle = BattleFixtures.battle(0)
	state = battle.state
	nest = state.enemy_buildings()[0]


func _guards() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for enemy in state.enemies:
		if enemy.is_guard():
			result.append(enemy)
	return result


func test_guard_count_grows_with_the_days_and_is_capped() -> void:
	assert_eq(Formulas.guard_count(1), GameConfig.GUARD_BASE)
	assert_eq(Formulas.guard_count(2), GameConfig.GUARD_BASE)
	assert_eq(Formulas.guard_count(3), GameConfig.GUARD_BASE + 1)
	assert_eq(Formulas.guard_count(0), GameConfig.GUARD_BASE)
	assert_eq(Formulas.guard_count(999), GameConfig.GUARD_MAX)
	assert_gt(Formulas.guard_ring(nest), nest.half_extent())


func test_no_guards_while_planning() -> void:
	battle.spawns.update(100.0)
	assert_true(state.enemies.is_empty())
	for i in 60:
		battle.tick(GameConfig.TICK)
	assert_true(state.enemies.is_empty())


func test_guards_arrive_after_the_fight_starts_and_trickle_in() -> void:
	battle.spawns.start_round()
	assert_eq(nest.guard_timer, GameConfig.GUARD_FIRST)
	assert_eq(battle.spawns.reinforce(GameConfig.GUARD_FIRST - 0.1), 0)
	assert_eq(battle.spawns.reinforce(0.2), 1)
	assert_eq(battle.spawns.reinforce(GameConfig.GUARD_TRICKLE * 0.5), 0)
	assert_eq(battle.spawns.reinforce(GameConfig.GUARD_TRICKLE), 1)
	assert_eq(_guards().size(), Formulas.guard_count(state.round_number))
	assert_eq(battle.spawns.reinforce(1000.0), 0)
	assert_eq(nest.guard_timer, GameConfig.GUARD_RESPAWN)
	var spawned := BattleFixtures.of_type(battle.events.drain(), "spawn")
	assert_eq(spawned.size(), 2)
	assert_true(bool(spawned[0].guard))


func test_killed_guards_are_replaced_after_a_while() -> void:
	battle.spawns.start_round()
	battle.spawns.reinforce(GameConfig.GUARD_FIRST)
	battle.spawns.reinforce(GameConfig.GUARD_TRICKLE)
	battle.spawns.reinforce(0.0)
	var first := _guards()[0]
	first.hp = 0.0
	assert_eq(battle.spawns.reinforce(GameConfig.GUARD_RESPAWN - 1.0), 0)
	assert_eq(battle.spawns.reinforce(1.0), 1)


func test_guards_are_tough_slow_and_worth_more() -> void:
	battle.spawns.start_round()
	var guard := battle.spawns.spawn_guard(nest)
	var normal := Enemy.new(999, "beetle", Vector2.ZERO)
	assert_eq(guard.kind, str(GameConfig.guard(GameConfig.NEST).kind))
	assert_true(guard.is_guard())
	assert_false(guard.is_attacker())
	assert_eq(guard.post, nest.id)
	assert_almost_eq(guard.max_hp, normal.max_hp * float(GameConfig.guard(GameConfig.NEST).hp), 0.01)
	assert_almost_eq(guard.speed(), normal.speed() * GameConfig.GUARD_SPEED, 0.001)
	assert_gt(guard.bounty, normal.bounty)
	assert_almost_eq(guard.position.distance_to(nest.position), Formulas.guard_ring(nest), GameConfig.CELL)
	var camp := BattleFixtures.add(battle, GameConfig.CAMP, nest.position + Vector2(600, 0))
	assert_eq(battle.spawns.spawn_guard(camp).kind, "soldier")


func test_guards_patrol_around_their_base_and_never_attack() -> void:
	battle.spawns.start_round()
	var guard := battle.spawns.spawn_guard(nest)
	var bait := BattleFixtures.add(battle, GameConfig.RELAY, guard.position + Vector2(0, 40))
	var start := guard.position
	var hp := bait.hp
	var farthest := 0.0
	var nearest := INF
	for i in 600:
		battle.ai.update(GameConfig.TICK)
		var distance := guard.position.distance_to(nest.position)
		farthest = maxf(farthest, distance)
		nearest = minf(nearest, distance)
	assert_eq(bait.hp, hp)
	assert_gt(guard.position.distance_to(start), 10.0)
	assert_lt(farthest, Formulas.guard_ring(nest) + GameConfig.CELL * 1.5)
	assert_gt(nearest, nest.half_extent())
	assert_eq(guard.target_id, -1)


func test_patrol_points_lie_on_the_ring() -> void:
	var guard := battle.spawns.spawn_guard(nest)
	guard.patrol_angle = 1.0
	assert_almost_eq(EnemyAI.patrol_point(guard, nest).distance_to(nest.position), Formulas.guard_ring(nest), 0.001)


func test_guards_do_not_hold_up_the_end_of_the_night() -> void:
	battle.start_round()
	var guard := battle.spawns.spawn_guard(nest)
	var crawler := BattleFixtures.enemy(battle, "crawler", nest.position + Vector2(0, 400))
	assert_eq(state.attackers(), 1)
	assert_true(state.has_attackers())
	battle.spawns.end_night()
	var night := BattleFixtures.of_type(battle.events.drain(), "night_over")
	assert_eq(night[0].left, 1)
	assert_false(guard.is_burning())
	crawler.hp = 0.0
	battle.tick(GameConfig.TICK)
	assert_eq(state.phase, BattleState.Phase.PLAN)
	assert_true(guard.is_burning())
	var events := battle.events.drain()
	assert_eq(BattleFixtures.of_type(events, "guards_ignited")[0].count, 1)
	var money := state.money
	for i in int(GameConfig.BURN_MAX / GameConfig.TICK) + 2:
		battle.tick(GameConfig.TICK)
	assert_false(guard.is_alive())
	assert_true(state.enemies.is_empty())
	assert_eq(state.money, money)
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "burned").size(), 1)


func test_guards_burn_when_their_base_falls() -> void:
	battle.spawns.start_round()
	var guard := battle.spawns.spawn_guard(nest)
	nest.hp = 0.0
	assert_eq(battle.spawns.reinforce(100.0), 0)
	assert_true(guard.is_burning())


func test_ignite_guards_only_once() -> void:
	battle.spawns.start_round()
	battle.spawns.spawn_guard(nest)
	battle.spawns.spawn_guard(nest)
	assert_eq(battle.spawns.ignite_guards(), 2)
	assert_eq(battle.spawns.ignite_guards(), 0)
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "guards_ignited").size(), 1)
	assert_true(battle.spawns.guard_counts().is_empty())


func test_spawners_without_guard_config_get_none() -> void:
	assert_true(GameConfig.guard(GameConfig.TURRET).is_empty())
	assert_false(GameConfig.guard(GameConfig.NEST).is_empty())
	assert_false(GameConfig.guard(GameConfig.CAMP).is_empty())
	assert_true(GameConfig.enemy_kinds().has(str(GameConfig.guard(GameConfig.NEST).kind)))
	assert_true(GameConfig.enemy_kinds().has(str(GameConfig.guard(GameConfig.CAMP).kind)))
