extends GutTest

var battle: Battle


func before_each() -> void:
	battle = BattleFixtures.battle(0)


func _nest() -> Building:
	return battle.state.enemy_buildings()[0]


func _run(seconds: float) -> void:
	for i in int(seconds / GameConfig.TICK):
		battle.state.round_time += GameConfig.TICK
		battle.spawns.update(GameConfig.TICK)


func test_planning_has_no_enemies() -> void:
	assert_eq(battle.state.phase, BattleState.Phase.PLAN)
	battle.spawns.update(100.0)
	assert_true(battle.state.enemies.is_empty())
	assert_eq(battle.state.waves_sent, 0)


func test_start_round_switches_to_fight_once() -> void:
	assert_true(battle.spawns.start_round())
	assert_eq(battle.state.phase, BattleState.Phase.FIGHT)
	assert_eq(battle.state.round_time, 0.0)
	assert_false(battle.spawns.start_round())
	var started := BattleFixtures.of_type(battle.events.drain(), "fight_started")
	assert_eq(started.size(), 1)
	assert_eq(started[0].round, 1)


func test_start_round_ends_full_refunds() -> void:
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, battle.state.core().position + Vector2(0, -150))
	relay.plan_spent = 30
	battle.spawns.start_round()
	assert_eq(relay.plan_spent, 0)


func test_first_wave_comes_quickly() -> void:
	battle.spawns.start_round()
	_run(GameConfig.WAVE_FIRST + 0.5)
	assert_eq(battle.state.waves_sent, 1)
	assert_false(battle.state.enemies.is_empty())
	var waves := BattleFixtures.of_type(battle.events.drain(), "wave")
	assert_eq(waves.size(), 1)
	assert_eq(waves[0].index, 1)
	assert_false(waves[0].night)


func test_every_wave_sends_at_least_one_enemy_per_spawner() -> void:
	battle.spawns.start_round()
	assert_gte(battle.spawns.send_wave(), 1)
	assert_gte(_nest().spawn_queue, 1)


func test_waves_trickle_out_of_the_spawner() -> void:
	battle.spawns.start_round()
	var nest := _nest()
	nest.spawn_queue = 4
	battle.spawns.update(GameConfig.TICK)
	assert_eq(battle.state.enemies.size(), 1)
	battle.spawns.update(GameConfig.TICK)
	assert_eq(battle.state.enemies.size(), 1)
	battle.spawns.update(GameConfig.WAVE_TRICKLE)
	assert_eq(battle.state.enemies.size(), 2)
	assert_eq(nest.spawn_queue, 2)


func test_wave_queue_is_capped() -> void:
	battle.spawns.start_round()
	battle.state.round_number = 400
	battle.spawns.send_wave()
	assert_eq(_nest().spawn_queue, GameConfig.WAVE_MAX)


func test_waves_get_bigger_towards_night() -> void:
	battle.spawns.start_round()
	var nest := _nest()
	var first := battle.spawns.send_wave()
	nest.spawn_queue = 0
	battle.state.round_time = float(battle.state.level.day) + 10.0
	var night := 0
	for i in 5:
		night += battle.spawns.send_wave()
	assert_gt(night / 5.0, float(first))


func test_whole_round_sends_all_waves_then_stops() -> void:
	battle.spawns.start_round()
	_run(DayCycle.length(battle.state.level) + 1.0)
	assert_eq(battle.state.waves_sent, Formulas.wave_times(battle.state.level))
	battle.spawns.end_night()
	var count := battle.state.enemies.size()
	_run(20.0)
	assert_eq(battle.state.enemies.size(), count)
	assert_eq(_nest().spawn_queue, 0)


func test_end_night_is_announced_once() -> void:
	battle.spawns.start_round()
	battle.spawns.end_night()
	battle.spawns.end_night()
	assert_true(battle.state.night_over)
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "night_over").size(), 1)


func test_night_waves_are_marked() -> void:
	battle.spawns.start_round()
	battle.state.round_time = float(battle.state.level.day) + 1.0
	battle.spawns.send_wave()
	var waves := BattleFixtures.of_type(battle.events.drain(), "wave")
	assert_true(waves[0].night)
	assert_eq(waves[0].total, Formulas.wave_times(battle.state.level))


func test_night_brings_night_monsters() -> void:
	battle.state.level = battle.state.level.duplicate(true)
	battle.state.level.waves.roster = [["crawler", 0, 1.0]]
	battle.state.level.waves.night_roster = [["stalker", 0, 1.0]]
	battle.spawns.start_round()
	var day := battle.spawns.spawn(_nest())
	battle.state.round_time = float(battle.state.level.day) + 1.0
	var night := battle.spawns.spawn(_nest())
	assert_eq(day.kind, "crawler")
	assert_eq(night.kind, "stalker")
	assert_false(day.is_nocturnal())
	assert_true(night.is_nocturnal())
	assert_gt(night.max_hp, day.max_hp)
	assert_gt(night.damage(), day.damage())


func test_dawn_sets_night_monsters_on_fire() -> void:
	battle.spawns.start_round()
	var day := BattleFixtures.enemy(battle, "crawler", _nest().position + Vector2(0, 300))
	var night := BattleFixtures.enemy(battle, "stalker", _nest().position + Vector2(0, 320))
	var boss := BattleFixtures.enemy(battle, "behemoth", _nest().position + Vector2(0, 340))
	battle.events.drain()
	battle.spawns.end_night()
	assert_false(day.is_burning())
	assert_true(night.is_burning())
	assert_between(night.burn, GameConfig.BURN_MIN, GameConfig.BURN_MAX)
	var over := BattleFixtures.of_type(battle.events.drain(), "night_over")[0]
	assert_eq(over.left, 1)
	assert_eq(over.burning, 2)
	var kills := battle.state.kills
	assert_eq(battle.spawns.burn(GameConfig.BURN_MAX + 0.1), 2)
	assert_false(night.is_alive())
	assert_false(boss.is_alive())
	assert_true(day.is_alive())
	assert_eq(battle.state.kills, kills)
	assert_true(battle.state.pickups.is_empty())
	var burned := BattleFixtures.of_type(battle.events.drain(), "burned")
	assert_eq(burned.size(), 2)
	assert_eq(battle.spawns.burn(1.0), 0)


func test_burning_runs_after_the_night() -> void:
	battle.spawns.start_round()
	var night := BattleFixtures.enemy(battle, "raider", _nest().position + Vector2(0, 300))
	battle.spawns.end_night()
	battle.spawns.update(GameConfig.BURN_MIN * 0.5)
	assert_true(night.is_alive())
	battle.spawns.update(GameConfig.BURN_MAX)
	assert_false(night.is_alive())


func test_burning_waits_while_planning() -> void:
	var night := BattleFixtures.enemy(battle, "stalker", _nest().position + Vector2(0, 300))
	night.burn = 0.1
	battle.spawns.update(1.0)
	assert_true(night.is_alive())


func test_later_rounds_spawn_stronger_enemies() -> void:
	battle.state.level = battle.state.level.duplicate(true)
	battle.state.level.waves.roster = [["crawler", 0, 1.0]]
	battle.spawns.start_round()
	var first := battle.spawns.spawn(_nest())
	battle.state.round_number = 5
	var later := battle.spawns.spawn(_nest())
	assert_almost_eq(later.max_hp, first.max_hp * pow(GameConfig.ROUND_HP_GROWTH, 4), 0.01)
	assert_gt(later.bounty, first.bounty)


func test_turrets_do_not_spawn() -> void:
	battle = BattleFixtures.battle(3)
	battle.spawns.start_round()
	battle.spawns.send_wave()
	for building in battle.state.enemy_buildings():
		if building.kind == GameConfig.TURRET:
			assert_eq(building.spawn_queue, 0)
	_run(10.0)
	for enemy in battle.state.enemies:
		assert_true(GameConfig.SPAWNER_FACTIONS[GameConfig.CAMP].has(enemy.kind))


func test_spawned_enemies_appear_near_spawner() -> void:
	var nest := _nest()
	var enemy := battle.spawns.spawn(nest)
	assert_eq(enemy.kind, "crawler")
	assert_lte(enemy.position.distance_to(nest.position), nest.half_extent() + GameConfig.CELL * (1.5 + GameConfig.SPAWN_RING))
	assert_true(battle.state.nav.is_free(battle.state.map.cell_of(enemy.position)))
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "spawn").size(), 1)


func test_pick_kind_respects_round_night_and_faction() -> void:
	battle = BattleFixtures.battle(7)
	battle.spawns.start_round()
	var nest_kinds := battle.spawns.candidates(GameConfig.NEST).map(func(entry: Array) -> String: return entry[0])
	assert_eq(nest_kinds, ["crawler"])
	assert_eq(battle.spawns.candidates(GameConfig.CAMP).map(func(entry: Array) -> String: return entry[0]), ["soldier"])
	battle.state.round_time = float(battle.state.level.day) + 1.0
	assert_eq(battle.spawns.candidates(GameConfig.NEST).map(func(entry: Array) -> String: return entry[0]), ["stalker"])
	assert_eq(battle.spawns.candidates(GameConfig.CAMP).map(func(entry: Array) -> String: return entry[0]), ["raider"])
	battle.state.round_number = 3
	for entry: Array in battle.spawns.candidates(GameConfig.NEST) + battle.spawns.candidates(GameConfig.CAMP):
		assert_true(GameConfig.is_nocturnal(entry[0]), entry[0])
	battle.state.round_time = 0.0
	battle.state.round_number = 10
	assert_eq(battle.spawns.candidates(GameConfig.NEST).size(), 3)
	for i in 50:
		assert_true(GameConfig.SPAWNER_FACTIONS[GameConfig.CAMP].has(battle.spawns.pick_kind(GameConfig.CAMP)))


func test_flyers_spawn_without_grid_snapping() -> void:
	battle.state.level = battle.state.level.duplicate(true)
	battle.state.level.waves.roster = [["wasp", 0, 1.0]]
	var nest := _nest()
	var wasp := battle.spawns.spawn(nest)
	assert_eq(wasp.kind, "wasp")
	assert_lte(wasp.position.distance_to(nest.position), nest.half_extent() + GameConfig.CELL * (0.5 + GameConfig.SPAWN_RING) + 0.01)


func test_pick_kind_falls_back_to_faction() -> void:
	assert_eq(battle.spawns.pick_kind(GameConfig.CAMP), "soldier")
	assert_eq(battle.spawns.pick_kind("unknown"), "crawler")
	battle.spawns.start_round()
	battle.state.round_time = float(battle.state.level.day) + 1.0
	assert_eq(battle.spawns.pick_kind(GameConfig.CAMP), "raider")
	assert_eq(battle.spawns.fallback_kind(GameConfig.NEST), "stalker")
	assert_eq(battle.spawns.pick_kind("unknown"), "crawler")


func test_enemy_scales() -> void:
	var base := float(GameConfig.enemy("crawler").hp)
	var plain := Enemy.new(1, "crawler", Vector2.ZERO)
	var strong := Enemy.new(2, "crawler", Vector2.ZERO, 3.0, 2.0, 2.0)
	assert_eq(plain.max_hp, base)
	assert_eq(strong.max_hp, base * 3.0)
	assert_eq(strong.hp, strong.max_hp)
	assert_eq(strong.damage(), float(GameConfig.enemy("crawler").damage) * 2.0)
	assert_eq(strong.bounty, int(GameConfig.enemy("crawler").bounty) * 2)
	assert_eq(Enemy.new(3, "crawler", Vector2.ZERO, 1.0, 1.0, 0.0).bounty, 1)


func test_rosters_contain_no_flyers() -> void:
	for level: Dictionary in GameConfig.LEVELS:
		for key in ["roster", "night_roster"]:
			for entry: Array in level.waves[key]:
				assert_ne(GameConfig.enemy(entry[0]).get("class", ""), GameConfig.CLASS_AIR, "%s %s" % [level.id, entry[0]])


func test_ground_enemies_deal_bonus_damage_and_flyers_do_not() -> void:
	var crawler := battle.spawns.spawn(_nest())
	assert_almost_eq(crawler.damage_scale, GameConfig.GROUND_DAMAGE_BONUS, 0.0001)
	assert_eq(battle.spawns._damage_bonus("wasp"), 1.0)


func test_waves_are_larger_by_ground_bonus() -> void:
	battle.spawns.start_round()
	var expected := Formulas.wave_count(battle.state.level.waves, 1, 0.0, false) * GameConfig.GROUND_WAVE_BONUS
	var nest := _nest()
	battle.spawns.send_wave()
	assert_almost_eq(nest.spawn_progress + float(nest.spawn_queue), expected, 0.0001)


func test_no_raids_in_early_rounds() -> void:
	battle.state.round_number = GameConfig.AIR_RAID_FIRST_ROUND - 1
	battle.state.waves_sent = 20
	for i in 200:
		assert_false(battle.spawns.raid_due())


func test_raid_respects_gap() -> void:
	battle.state.round_number = GameConfig.AIR_RAID_FIRST_ROUND
	battle.state.waves_sent = 5
	battle.state.last_raid_wave = 5 - GameConfig.AIR_RAID_GAP + 1
	for i in 200:
		assert_false(battle.spawns.raid_due())


func test_raids_are_rare_but_possible() -> void:
	battle.state.round_number = GameConfig.AIR_RAID_FIRST_ROUND
	battle.state.waves_sent = 50
	var hits := 0
	for i in 1000:
		if battle.spawns.raid_due():
			hits += 1
	assert_gt(hits, 0)
	assert_lt(hits, 300)


func test_raid_kinds_follow_faction_and_daytime() -> void:
	assert_eq(battle.spawns.raid_kinds(false), ["wasp"])
	assert_eq(battle.spawns.raid_kinds(true), ["nightwing"])
	battle = BattleFixtures.battle(3)
	assert_eq(battle.spawns.raid_kinds(false), ["drone"])
	assert_eq(battle.spawns.raid_kinds(true), ["phantom"])


func test_raid_size_grows_and_is_capped() -> void:
	battle.state.round_number = GameConfig.AIR_RAID_FIRST_ROUND
	for i in 50:
		assert_between(battle.spawns.raid_size(), GameConfig.AIR_RAID_MIN, GameConfig.AIR_RAID_MAX)
	battle.state.round_number = 400
	assert_eq(battle.spawns.raid_size(), GameConfig.AIR_RAID_CAP)


func test_raid_origin_lies_on_the_map_border_from_every_side() -> void:
	var extent := Vector2(battle.state.map.width, battle.state.map.height) * GameConfig.CELL
	var sides := {}
	for i in 200:
		var origin := battle.spawns.raid_origin()
		assert_between(origin.x, GameConfig.AIR_RAID_MARGIN, extent.x - GameConfig.AIR_RAID_MARGIN)
		assert_between(origin.y, GameConfig.AIR_RAID_MARGIN, extent.y - GameConfig.AIR_RAID_MARGIN)
		if is_equal_approx(origin.y, GameConfig.AIR_RAID_MARGIN):
			sides["top"] = true
		elif is_equal_approx(origin.y, extent.y - GameConfig.AIR_RAID_MARGIN):
			sides["bottom"] = true
		elif is_equal_approx(origin.x, GameConfig.AIR_RAID_MARGIN):
			sides["left"] = true
		else:
			sides["right"] = true
	assert_eq(sides.size(), 4)


func test_air_raid_spawns_a_group_of_flyers() -> void:
	battle.state.round_number = GameConfig.AIR_RAID_FIRST_ROUND
	battle.state.waves_sent = 3
	var spawned := battle.spawns.air_raid(false)
	assert_between(spawned, GameConfig.AIR_RAID_MIN, GameConfig.AIR_RAID_MAX + 1)
	assert_eq(battle.state.enemies.size(), spawned)
	for enemy in battle.state.enemies:
		assert_true(enemy.is_air())
	assert_eq(battle.state.last_raid_wave, 3)
	var raids := BattleFixtures.of_type(battle.events.drain(), "air_raid")
	assert_eq(raids.size(), 1)
	assert_eq(raids[0].count, spawned)


func test_air_raid_without_flying_kinds_does_nothing() -> void:
	for spawner in battle.state.enemy_buildings():
		spawner.kind = "unknown"
	assert_eq(battle.spawns.air_raid(false), 0)
	assert_true(battle.state.enemies.is_empty())


func test_start_round_resets_raid_gap() -> void:
	battle.state.last_raid_wave = 9
	battle.spawns.start_round()
	assert_eq(battle.state.last_raid_wave, -GameConfig.AIR_RAID_GAP)


func test_send_wave_triggers_raid_when_due() -> void:
	battle.spawns.start_round()
	battle.state.round_number = GameConfig.AIR_RAID_FIRST_ROUND
	var raided := false
	for i in 400:
		battle.state.last_raid_wave = -GameConfig.AIR_RAID_GAP
		battle.spawns.send_wave()
		if battle.state.enemies.any(func(enemy: Enemy) -> bool: return enemy.is_air()):
			raided = true
			break
	assert_true(raided)
