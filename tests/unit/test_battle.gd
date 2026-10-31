extends GutTest

var battle: Battle
var core: Building


func before_each() -> void:
	battle = BattleFixtures.battle(0)
	core = battle.state.core()


func test_start_begins_with_a_parachuting_scout() -> void:
	var fresh := Battle.start(0)
	assert_eq(fresh.state.money, int(GameConfig.level(0).money))
	assert_eq(fresh.state.phase, BattleState.Phase.SCOUT)
	assert_null(fresh.state.core())
	assert_true(fresh.state.player_buildings().is_empty())
	assert_true(fresh.state.enemy_buildings().is_empty())
	assert_false(fresh.state.structures_spawned)
	assert_eq(fresh.state.scout.position, fresh.state.map.drop)
	assert_false(fresh.state.scout.is_landed())
	assert_true(fresh.state.fog.is_visible(fresh.state.map.drop))


func test_scouting_freezes_time_and_spawns() -> void:
	var fresh := Battle.start(0)
	for i in int(5.0 / GameConfig.TICK):
		fresh.tick(GameConfig.TICK)
	assert_eq(fresh.state.time, 0.0)
	assert_eq(fresh.state.phase, BattleState.Phase.SCOUT)
	assert_true(fresh.state.enemies.is_empty())
	assert_true(fresh.state.scout.is_landed())
	assert_true(BattleFixtures.types(fresh).has("landed"))


func test_deploy_core_starts_planning() -> void:
	var fresh := Battle.start(0)
	assert_eq(fresh.deploy_core(fresh.state.map.drop), BuildRules.PHASE)
	fresh.state.scout.drop_left = 0.0
	var reason := fresh.place(GameConfig.CORE, fresh.state.map.drop)
	assert_eq(reason, BuildRules.OK)
	var core_now := fresh.state.core()
	assert_not_null(core_now)
	assert_eq(fresh.state.phase, BattleState.Phase.PLAN)
	assert_eq(fresh.state.round_number, 1)
	assert_gt(core_now.energy, 0.0)
	var events := fresh.events.drain()
	assert_eq(BattleFixtures.of_type(events, "core_deployed").size(), 1)
	var spawned := BattleFixtures.of_type(events, "structures_spawned")
	assert_eq(spawned.size(), 1)
	assert_eq(int(spawned[0].count), GameConfig.level(0).structures.size())
	assert_eq(fresh.state.enemy_buildings().size(), GameConfig.level(0).structures.size())
	for nest in fresh.state.enemy_buildings():
		assert_gte(nest.position.distance_to(core_now.position), GameConfig.CORE_ENEMY_CLEAR)
	assert_true(fresh.state.scout.boarded)
	assert_eq(fresh.deploy_core(fresh.state.map.drop + Vector2(300, 0)), BuildRules.INVALID)


func test_scout_commands_delegate() -> void:
	var fresh := Battle.start(0)
	assert_eq(fresh.steer_scout(Vector2.RIGHT), ScoutControl.LANDING)
	assert_eq(fresh.clear_with_scout(fresh.state.map.drop), ScoutControl.LANDING)


func test_advance_uses_fixed_steps() -> void:
	battle.start_round()
	assert_eq(battle.advance(GameConfig.TICK * 3.5), 3)
	assert_almost_eq(battle.state.time, GameConfig.TICK * 3.0, 0.0001)
	assert_eq(battle.advance(GameConfig.TICK * 0.6), 1)
	assert_eq(battle.advance(-1.0), 0)


func test_advance_caps_steps() -> void:
	assert_eq(battle.advance(10.0), GameConfig.MAX_STEPS_PER_FRAME)
	assert_eq(battle.advance(0.0), 0)


func test_place_building() -> void:
	var position := core.position + Vector2(120, 0)
	var start := battle.state.money
	var cost := Formulas.build_cost(battle.state, GameConfig.SOLAR)
	assert_eq(battle.place(GameConfig.SOLAR, position), BuildRules.OK)
	assert_eq(battle.state.money, start - cost)
	assert_eq(battle.state.player_buildings().size(), 2)
	var placed := BattleFixtures.of_type(battle.events.drain(), "placed")[0]
	assert_eq(placed.kind, GameConfig.SOLAR)
	assert_eq(placed.position, LevelMap.snap(position, 1))
	assert_eq(battle.state.nav.occupant_at(battle.state.map.cell_of(position)), placed.id)
	assert_eq(battle.place(GameConfig.SOLAR, position), BuildRules.OVERLAP)
	assert_eq(battle.state.money, start - cost)


func test_upgrade_building() -> void:
	var start := battle.state.money
	var cost := Formulas.upgrade_cost(core, GameConfig.TRACK_RATE)
	assert_true(battle.can_upgrade(core.id, GameConfig.TRACK_RATE))
	assert_true(battle.upgrade(core.id, GameConfig.TRACK_RATE))
	assert_eq(core.level(GameConfig.TRACK_RATE), 1)
	assert_eq(battle.state.money, start - cost)
	assert_eq(core.spent, cost)
	assert_eq(core.plan_spent, cost)
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "upgraded")[0].level, 1)
	battle.start_round()
	assert_true(battle.upgrade(core.id, GameConfig.TRACK_RATE))
	assert_eq(core.plan_spent, 0)


func test_hull_upgrade_heals_by_the_added_hp() -> void:
	battle.state.money = 1000
	var wall := BattleFixtures.add(battle, GameConfig.BULWARK, core.position + Vector2(0, -150))
	wall.hp = 100.0
	assert_true(battle.upgrade(wall.id, GameConfig.TRACK_HULL))
	assert_almost_eq(wall.hp, 100.0 + 1600.0 * float(GameConfig.WALL_HULL.gain), 0.001)


func test_armour_upgrade_is_bought_like_any_track() -> void:
	battle.state.money = 1000
	var zapper := BattleFixtures.add(battle, GameConfig.ZAPPER, core.position + Vector2(0, -150))
	var armor := Formulas.armor(zapper)
	var hp := zapper.hp
	var cost := Formulas.upgrade_cost(zapper, GameConfig.TRACK_ARMOR)
	assert_true(battle.upgrade(zapper.id, GameConfig.TRACK_ARMOR))
	assert_eq(zapper.level(GameConfig.TRACK_ARMOR), 1)
	assert_gt(Formulas.armor(zapper), armor)
	assert_eq(zapper.hp, hp)
	assert_eq(battle.state.money, 1000 - cost)
	var solar := BattleFixtures.add(battle, GameConfig.SOLAR, core.position + Vector2(150, 0))
	assert_true(battle.can_upgrade(solar.id, GameConfig.TRACK_ARMOR))


func test_target_priority_controls() -> void:
	assert_eq(core.target_order, GameConfig.CLASSES)
	assert_true(battle.raise_target_class(core.id, GameConfig.CLASS_MELEE))
	assert_eq(core.target_order, [GameConfig.CLASS_AIR, GameConfig.CLASS_MELEE, GameConfig.CLASS_RANGED] as Array[String])
	assert_false(battle.raise_target_class(core.id, GameConfig.CLASS_AIR))
	assert_true(battle.toggle_target_class(core.id, GameConfig.CLASS_AIR))
	assert_false(core.can_target(GameConfig.CLASS_AIR))
	assert_true(battle.toggle_target_class(core.id, GameConfig.CLASS_AIR))
	assert_true(core.can_target(GameConfig.CLASS_AIR))
	assert_false(battle.toggle_target_class(core.id, "space"))
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(0, -150))
	assert_false(battle.toggle_target_class(relay.id, GameConfig.CLASS_AIR))
	assert_false(battle.raise_target_class(relay.id, GameConfig.CLASS_MELEE))
	assert_false(battle.toggle_target_class(999, GameConfig.CLASS_AIR))


func test_upgrade_rejections() -> void:
	assert_false(battle.upgrade(core.id, GameConfig.TRACK_SPLASH))
	assert_false(battle.upgrade(999, GameConfig.TRACK_RATE))
	var nest: Building = battle.state.enemy_buildings()[0]
	assert_false(battle.upgrade(nest.id, GameConfig.TRACK_RATE))
	core.set_level(GameConfig.TRACK_LINKS, Formulas.max_level(core, GameConfig.TRACK_LINKS))
	assert_false(battle.upgrade(core.id, GameConfig.TRACK_LINKS))
	battle.state.money = 0
	assert_false(battle.upgrade(core.id, GameConfig.TRACK_RATE))


func test_sell_in_planning_refunds_full_price() -> void:
	battle.place(GameConfig.BATTERY, core.position + Vector2(150, 0))
	var battery: Building = battle.state.of_kind(GameConfig.BATTERY)[0]
	assert_eq(battery.plan_spent, 80)
	var money := battle.state.money
	assert_eq(battle.sell(battery.id), 80)
	assert_eq(battle.state.money, money + 80)


func test_full_refund_ends_with_the_planning_phase() -> void:
	battle.place(GameConfig.BATTERY, core.position + Vector2(150, 0))
	var battery: Building = battle.state.of_kind(GameConfig.BATTERY)[0]
	battle.start_round()
	battle.state.phase = BattleState.Phase.PLAN
	assert_eq(battle.sell(battery.id), 40)


func test_damaged_buildings_sell_for_less() -> void:
	battle.start_round()
	battle.place(GameConfig.BATTERY, core.position + Vector2(150, 0))
	var battery: Building = battle.state.of_kind(GameConfig.BATTERY)[0]
	battery.hp = battery.max_hp() * 0.25
	assert_eq(battle.sell(battery.id), 10)


func test_sell_building() -> void:
	battle.start_round()
	battle.place(GameConfig.BATTERY, core.position + Vector2(150, 0))
	var battery: Building = battle.state.player_buildings().filter(func(b: Building) -> bool: return b.kind == GameConfig.BATTERY)[0]
	battle.connect_buildings(core.id, battery.id)
	var money := battle.state.money
	assert_eq(battle.sell(battery.id), 40)
	assert_eq(battle.state.money, money + 40)
	assert_null(battle.state.building(battery.id))
	assert_eq(battle.state.nav.occupant_at(battle.state.map.cell_of(battery.position)), NavGrid.FREE)
	assert_true(battle.state.links.is_empty())
	assert_eq(battle.state.lost, 0)
	assert_eq(battle.sell(core.id), 0)
	assert_eq(battle.sell(battery.id), 0)


func test_connect_and_cut() -> void:
	battle.place(GameConfig.RELAY, core.position + Vector2(0, -200))
	var relay: Building = battle.state.player_buildings().filter(func(b: Building) -> bool: return b.kind == GameConfig.RELAY)[0]
	assert_eq(battle.connect_buildings(relay.id, core.id), EnergyNetwork.OK)
	assert_eq(battle.connect_buildings(relay.id, core.id), EnergyNetwork.EXISTS)
	assert_eq(battle.cut(core.position + Vector2(-50, -100), core.position + Vector2(50, -100)), 1)


func test_start_round() -> void:
	assert_true(battle.start_round())
	assert_eq(battle.state.phase, BattleState.Phase.FIGHT)
	assert_false(battle.start_round())


func test_planning_freezes_energy_time_and_combat() -> void:
	var solar := BattleFixtures.add(battle, GameConfig.SOLAR, core.position + Vector2(150, 0))
	var zapper := BattleFixtures.add(battle, GameConfig.ZAPPER, core.position + Vector2(-150, 0))
	var exporter := BattleFixtures.add(battle, GameConfig.EXPORTER, core.position + Vector2(0, 150))
	zapper.energy = Formulas.capacity(zapper)
	exporter.energy = Formulas.capacity(exporter)
	battle.connect_buildings(core.id, zapper.id)
	var crawler := BattleFixtures.enemy(battle, "crawler", zapper.position + Vector2(0, -80))
	var energy := core.energy
	var money := battle.state.money
	for i in 90:
		battle.tick(GameConfig.TICK)
	assert_eq(battle.state.time, 0.0)
	assert_eq(core.energy, energy)
	assert_eq(solar.energy, 0.0)
	assert_eq(zapper.energy, Formulas.capacity(zapper))
	assert_eq(exporter.energy, Formulas.capacity(exporter))
	assert_eq(crawler.hp, crawler.max_hp)
	assert_eq(battle.state.money, money)
	assert_eq(battle.state.light(), 1.0)
	assert_false(battle.state.is_night())


func test_round_runs_day_night_and_returns_to_planning() -> void:
	var level := battle.state.level
	battle.state.money = 0
	battle.start_round()
	battle.state.round_time = float(level.day) - GameConfig.TICK * 0.5
	battle.tick(GameConfig.TICK)
	assert_true(battle.state.is_night())
	assert_true(BattleFixtures.types(battle).has("nightfall"))
	battle.state.round_time = DayCycle.length(level) - GameConfig.TICK * 0.5
	battle.tick(GameConfig.TICK)
	assert_true(battle.state.night_over)
	assert_false(battle.state.is_night())
	assert_eq(battle.state.phase, BattleState.Phase.FIGHT)
	assert_true(BattleFixtures.types(battle).has("night_over"))
	assert_false(battle.state.enemies.is_empty())
	for enemy in battle.state.enemies:
		battle.combat.damage_enemy(enemy, 100000.0, false)
	battle.tick(GameConfig.TICK)
	assert_eq(battle.state.phase, BattleState.Phase.PLAN)
	assert_eq(battle.state.round_number, 2)
	assert_eq(battle.state.round_time, 0.0)
	assert_eq(battle.state.waves_sent, 0)
	assert_true(battle.state.pickups.is_empty())
	assert_gt(battle.state.money, 0)
	var cleared := BattleFixtures.of_type(battle.events.drain(), "round_cleared")
	assert_eq(cleared.size(), 1)
	assert_eq(cleared[0].round, 1)
	assert_eq(cleared[0].next, 2)
	assert_true(battle.start_round())
	assert_eq(battle.state.round_number, 2)


func test_round_does_not_end_while_enemies_live() -> void:
	battle.start_round()
	battle.spawns.end_night()
	BattleFixtures.enemy(battle, "crawler", core.position + Vector2(0, -900))
	battle.tick(GameConfig.TICK)
	assert_eq(battle.state.phase, BattleState.Phase.FIGHT)


func test_victory_purges_enemies_and_collects() -> void:
	battle.start_round()
	var crawler := BattleFixtures.enemy(battle, "crawler", core.position + Vector2(0, -900))
	var nest: Building = battle.state.enemy_buildings()[0]
	battle.combat.destroy(nest)
	battle.tick(GameConfig.TICK)
	assert_eq(battle.state.phase, BattleState.Phase.WON)
	assert_true(battle.state.enemies.is_empty())
	assert_false(crawler.is_alive())
	assert_true(battle.state.pickups.is_empty())
	assert_eq(battle.state.stars(), 0)
	var events := battle.events.drain()
	assert_eq(BattleFixtures.of_type(events, "purge").size(), 1)
	assert_eq(BattleFixtures.of_type(events, "victory")[0].stars, 0)
	var time := battle.state.time
	battle.tick(1.0)
	assert_eq(battle.state.time, time)
	assert_eq(battle.place(GameConfig.SOLAR, core.position + Vector2(120, 0)), BuildRules.OK)
	assert_eq(battle.sell(core.id), 0)


func test_defeat_when_core_destroyed() -> void:
	battle.start_round()
	battle.combat.damage_building(core, 100000.0)
	battle.tick(GameConfig.TICK)
	assert_eq(battle.state.phase, BattleState.Phase.LOST)
	assert_eq(battle.state.stars(), 0)
	assert_true(BattleFixtures.types(battle).has("defeat"))
	assert_false(battle.can_upgrade(core.id, GameConfig.TRACK_RATE))


func test_building_at() -> void:
	assert_eq(battle.building_at(core.position + Vector2(30, 0)), core)
	assert_null(battle.building_at(core.position + Vector2(80, 0)))
	assert_eq(battle.building_at(core.position + Vector2(80, 0), 40.0), core)


func test_state_totals() -> void:
	var solar := BattleFixtures.add(battle, GameConfig.SOLAR, core.position + Vector2(150, 0))
	solar.energy = 10.0
	assert_almost_eq(battle.state.stored_energy(), core.energy + 10.0, 0.001)
	assert_eq(battle.state.storage_capacity(), 330.0)
	assert_almost_eq(battle.state.generation(), Formulas.output(core) + Formulas.output(solar), 0.001)
	battle.start_round()
	battle.state.round_time = float(battle.state.level.day)
	assert_almost_eq(battle.state.generation(), Formulas.output(core), 0.001)
	assert_true(battle.state.is_available(GameConfig.ZAPPER))
	assert_false(battle.state.is_available(GameConfig.TESLA))
	assert_eq(battle.state.outgoing(core.id).size(), 0)
	assert_null(battle.state.find_link(core.id, solar.id))


func test_undefended_core_falls() -> void:
	var fresh := BattleFixtures.deployed(0)
	for i in 2400:
		if fresh.state.is_planning():
			fresh.start_round()
		for j in 5:
			fresh.advance(1.0 / 6.0)
		if fresh.state.is_over():
			break
	assert_eq(fresh.state.phase, BattleState.Phase.LOST)


func test_defended_core_survives_the_first_round() -> void:
	var fresh := BattleFixtures.deployed(0)
	var center := fresh.state.core().position
	for offset: Vector2 in [Vector2(-110, -40), Vector2(110, -40), Vector2(0, -120)]:
		var zapper := fresh.state.add_building(GameConfig.ZAPPER, center + offset)
		zapper.energy = Formulas.capacity(zapper)
		fresh.network.connect_buildings(fresh.state.core_id, zapper.id) if fresh.state.outgoing(fresh.state.core_id).size() < 2 else null
	var battery := fresh.state.add_building(GameConfig.BATTERY, center + Vector2(0, -230))
	battery.energy = Formulas.capacity(battery)
	var third: Building = fresh.state.player_buildings().filter(func(b: Building) -> bool: return b.kind == GameConfig.ZAPPER)[2]
	fresh.network.connect_buildings(battery.id, third.id)
	fresh.start_round()
	for i in 240 * 30:
		fresh.tick(GameConfig.TICK)
		if fresh.state.is_planning():
			break
	assert_eq(fresh.state.phase, BattleState.Phase.PLAN)
	assert_eq(fresh.state.round_number, 2)
	assert_gt(fresh.state.kills, 10)
	assert_gt(fresh.state.core_ratio(), 0.5)
