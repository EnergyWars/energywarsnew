extends GutTest

var battle: Battle


func before_each() -> void:
	battle = BattleFixtures.battle(GameConfig.level_count() - 1, false)


func test_armor_reduction_follows_the_configured_formula() -> void:
	var constant: float = GameConfig.armor_config().constant
	assert_eq(Formulas.armor_reduction(0.0), 0.0)
	assert_eq(Formulas.armor_reduction(-5.0), 0.0)
	assert_almost_eq(Formulas.armor_reduction(constant), 0.5, 0.0001)
	assert_almost_eq(Formulas.armor_reduction(constant * 3.0), 0.75, 0.0001)


func test_armor_reduction_is_capped() -> void:
	assert_almost_eq(Formulas.armor_reduction(1000000.0), float(GameConfig.armor_config().max_reduction), 0.0001)


func test_mitigate_scales_damage_and_keeps_a_minimum() -> void:
	var constant: float = GameConfig.armor_config().constant
	assert_almost_eq(Formulas.mitigate(40.0, constant), 20.0, 0.0001)
	assert_eq(Formulas.mitigate(40.0, 0.0), 40.0)
	assert_eq(Formulas.mitigate(0.0, constant), 0.0)
	assert_eq(Formulas.mitigate(-3.0, constant), 0.0)
	assert_almost_eq(Formulas.mitigate(1.0, 1000000.0), minf(1.0, float(GameConfig.armor_config().min_damage)), 0.0001)
	assert_eq(Formulas.mitigate(0.5, 1000000.0), 0.5)


func test_every_enemy_and_building_has_a_non_negative_armor() -> void:
	for kind in GameConfig.enemy_kinds():
		assert_true(GameConfig.enemy(kind).has("armor"), kind)
		assert_gte(float(GameConfig.enemy(kind).armor), 0.0, kind)
	for kind in GameConfig.BUILDINGS:
		assert_true(GameConfig.building(kind).has("armor"), kind)
		assert_gte(float(GameConfig.building(kind).armor), 0.0, kind)


func test_enemy_armor_reduces_damage_taken() -> void:
	var tank := BattleFixtures.enemy(battle, "tank", Vector2(300, 300))
	var crawler := BattleFixtures.enemy(battle, "crawler", Vector2(400, 300))
	battle.combat.damage_enemy(tank, 100.0, false)
	battle.combat.damage_enemy(crawler, 30.0, false)
	assert_almost_eq(tank.max_hp - tank.hp, Formulas.mitigate(100.0, tank.armor()), 0.0001)
	assert_lt(tank.max_hp - tank.hp, 100.0)
	assert_almost_eq(crawler.max_hp - crawler.hp, 30.0, 0.0001)


func test_building_armor_reduces_damage_taken() -> void:
	var core := battle.state.core()
	var bulwark := BattleFixtures.add(battle, GameConfig.BULWARK, core.position + Vector2(0, -150))
	var solar := BattleFixtures.add(battle, GameConfig.SOLAR, core.position + Vector2(150, 0))
	var before_wall := bulwark.hp
	var before_solar := solar.hp
	battle.combat.damage_building(bulwark, 100.0)
	battle.combat.damage_building(solar, 20.0)
	assert_almost_eq(before_wall - bulwark.hp, Formulas.mitigate(100.0, Formulas.armor(bulwark)), 0.0001)
	assert_almost_eq(before_solar - solar.hp, 20.0, 0.0001)


func test_armour_upgrades_reduce_damage_taken() -> void:
	var core := battle.state.core()
	var plain := BattleFixtures.add(battle, GameConfig.BASTION, core.position + Vector2(0, -150))
	var plated := BattleFixtures.add(battle, GameConfig.BASTION, core.position + Vector2(150, 0))
	plated.set_level(GameConfig.TRACK_ARMOR, 10)
	var plain_before := plain.hp
	var plated_before := plated.hp
	battle.combat.damage_building(plain, 100.0)
	battle.combat.damage_building(plated, 100.0)
	assert_gt(Formulas.armor(plated), Formulas.armor(plain))
	assert_almost_eq(plated_before - plated.hp, Formulas.mitigate(100.0, Formulas.armor(plated)), 0.0001)
	assert_lt(plated_before - plated.hp, plain_before - plain.hp)


func test_the_reported_hit_shows_the_reduced_damage() -> void:
	var tank := BattleFixtures.enemy(battle, "tank", Vector2(300, 300))
	battle.events.drain()
	battle.combat.damage_enemy(tank, 100.0, false)
	var hits := BattleFixtures.of_type(battle.events.drain(), "hit")
	assert_eq(hits.size(), 1)
	assert_almost_eq(float(hits[0].amount), Formulas.mitigate(100.0, tank.armor()), 0.0001)


func test_burning_and_unreported_damage_use_the_same_reduction() -> void:
	var tank := BattleFixtures.enemy(battle, "tank", Vector2(300, 300))
	battle.combat.damage_enemy(tank, 100.0, false, false)
	assert_almost_eq(tank.max_hp - tank.hp, Formulas.mitigate(100.0, tank.armor()), 0.0001)


func _laser() -> Building:
	var core := battle.state.core()
	core.energy = 0.0
	var laser := BattleFixtures.add(battle, GameConfig.LASER, core.position + Vector2(0, -100))
	laser.energy = Formulas.capacity(laser)
	return laser


func test_laser_ticks_are_reduced_by_armor_instead_of_hitting_the_floor() -> void:
	var laser := _laser()
	var beetle := BattleFixtures.enemy(battle, "beetle", laser.position + Vector2(0, -150))
	beetle.hp = 1.0e6
	battle.state.phase = BattleState.Phase.FIGHT
	var before := beetle.hp
	for i in 30:
		laser.energy = Formulas.capacity(laser)
		battle.combat.update(GameConfig.TICK)
	var expected := Formulas.mitigate(Formulas.damage(laser), beetle.armor())
	assert_lt(Formulas.damage(laser) * GameConfig.TICK * (1.0 - Formulas.armor_reduction(beetle.armor())), float(GameConfig.armor_config().min_damage))
	assert_almost_eq(before - beetle.hp, expected, 0.01)
	assert_lt(before - beetle.hp, Formulas.damage(laser))


func test_laser_reports_the_damage_it_really_dealt() -> void:
	var laser := _laser()
	var beetle := BattleFixtures.enemy(battle, "beetle", laser.position + Vector2(0, -150))
	beetle.hp = 1.0e6
	battle.state.phase = BattleState.Phase.FIGHT
	battle.events.drain()
	var before := beetle.hp
	for i in int(ceil(GameConfig.LASER_REPORT / GameConfig.TICK)) + 1:
		laser.energy = Formulas.capacity(laser)
		battle.combat.update(GameConfig.TICK)
	var hits := BattleFixtures.of_type(battle.events.drain(), "hit")
	assert_eq(hits.size(), 1)
	assert_lte(float(hits[0].amount), before - beetle.hp + 0.0001)
	assert_gt(float(hits[0].amount), 0.0)


func test_hits_on_enemy_structures_report_the_reduced_damage() -> void:
	var nest := BattleFixtures.add(battle, GameConfig.NEST, battle.state.core().position + Vector2(0, -500))
	battle.events.drain()
	var before := nest.hp
	var dealt := battle.combat.damage(nest, 100.0, false)
	var hits := BattleFixtures.of_type(battle.events.drain(), "hit")
	assert_almost_eq(float(hits[0].amount), Formulas.mitigate(100.0, Formulas.armor(nest)), 0.0001)
	assert_almost_eq(dealt, before - nest.hp, 0.0001)
	assert_lt(dealt, 100.0)


func test_no_enemy_reaches_the_reduction_cap_even_with_all_buffs() -> void:
	var cap := float(GameConfig.armor_config().max_reduction)
	var last := GameConfig.level_count() - 1
	for kind in GameConfig.enemy_kinds():
		var strongest := Enemy.new(1, kind, Vector2.ZERO, 1.0, 1.0, 1.0, true, last)
		assert_lt(Formulas.armor_reduction(strongest.armor()), cap - 0.2, kind)
		assert_gt(Formulas.mitigate(Formulas.damage(Building.new(2, GameConfig.ZAPPER, Vector2.ZERO)), strongest.armor()), float(GameConfig.armor_config().min_damage), kind)


func test_every_enemy_class_can_be_hit_by_a_tower() -> void:
	for klass in GameConfig.CLASSES:
		var air := klass == GameConfig.CLASS_AIR
		var covered := false
		for kind: String in GameConfig.BUILD_ORDER:
			var attack: Dictionary = GameConfig.building(kind).get("attack", GameConfig.EMPTY)
			if not attack.is_empty() and bool(attack.get("air" if air else "ground", false)):
				covered = true
		assert_true(covered, klass)
