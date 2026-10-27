extends GutTest

var battle: Battle
var core: Building


func before_each() -> void:
	battle = BattleFixtures.battle(GameConfig.level_count() - 1, false)
	core = battle.state.core()
	core.energy = 0.0


func _tower(kind: String, offset: Vector2 = Vector2(0, -100)) -> Building:
	var tower := BattleFixtures.add(battle, kind, core.position + offset)
	tower.energy = Formulas.capacity(tower)
	return tower


func test_zapper_fires_at_enemy_in_range() -> void:
	var zapper := _tower(GameConfig.ZAPPER)
	var crawler := BattleFixtures.enemy(battle, "beetle", zapper.position + Vector2(0, -150))
	battle.combat.update(0.1)
	var hit := Formulas.damage(zapper)
	assert_between(crawler.hp, crawler.max_hp - hit * GameConfig.CRIT_FACTOR, crawler.max_hp - hit)
	assert_almost_eq(zapper.energy, Formulas.capacity(zapper) - Formulas.shot_energy(zapper), 0.001)
	assert_almost_eq(zapper.cooldown, Formulas.cooldown(zapper), 0.001)
	assert_eq(zapper.target_id, crawler.id)
	var types := BattleFixtures.types(battle)
	assert_true(types.has("bolt"))
	assert_true(types.has("hit"))


func test_zapper_waits_for_cooldown_and_energy() -> void:
	var zapper := _tower(GameConfig.ZAPPER)
	var beetle := BattleFixtures.enemy(battle, "beetle", zapper.position + Vector2(0, -150))
	battle.combat.update(0.1)
	var hp := beetle.hp
	battle.combat.update(0.1)
	assert_eq(beetle.hp, hp)
	zapper.cooldown = 0.0
	zapper.energy = 1.0
	battle.combat.update(0.1)
	assert_eq(beetle.hp, hp)


func test_zapper_ignores_enemies_out_of_range() -> void:
	var zapper := _tower(GameConfig.ZAPPER)
	var beetle := BattleFixtures.enemy(battle, "beetle", zapper.position + Vector2(0, -400))
	battle.combat.update(0.1)
	assert_eq(beetle.hp, beetle.max_hp)
	assert_null(battle.combat.find_target(zapper))


func test_towers_attack_structures_when_no_units() -> void:
	var zapper := _tower(GameConfig.ZAPPER)
	var nest := BattleFixtures.add(battle, GameConfig.NEST, zapper.position + Vector2(0, -200))
	assert_eq(battle.combat.find_target(zapper), nest)
	var crawler := BattleFixtures.enemy(battle, "crawler", zapper.position + Vector2(0, -220))
	assert_eq(battle.combat.find_target(zapper), crawler)
	crawler.hp = 0.0
	battle.combat.update(0.1)
	assert_lt(nest.hp, nest.max_hp())


func test_laser_drains_energy_continuously() -> void:
	var laser := _tower(GameConfig.LASER)
	var beetle := BattleFixtures.enemy(battle, "beetle", laser.position + Vector2(0, -150))
	for i in 10:
		battle.combat.update(0.1)
	assert_almost_eq(beetle.hp, beetle.max_hp - Formulas.damage(laser), 0.01)
	assert_almost_eq(laser.energy, Formulas.capacity(laser) - Formulas.shot_energy(laser), 0.01)
	assert_true(laser.firing)
	assert_gt(BattleFixtures.of_type(battle.events.drain(), "hit").size(), 0)


func test_laser_stops_without_energy_or_target() -> void:
	var laser := _tower(GameConfig.LASER)
	laser.energy = 0.0
	var beetle := BattleFixtures.enemy(battle, "beetle", laser.position + Vector2(0, -150))
	battle.combat.update(0.1)
	assert_false(laser.firing)
	assert_eq(beetle.hp, beetle.max_hp)
	assert_eq(laser.target_id, -1)


func test_core_defends_itself() -> void:
	core.energy = Formulas.capacity(core)
	var crawler := BattleFixtures.enemy(battle, "crawler", core.position + Vector2(0, -150))
	battle.combat.update(0.1)
	assert_lt(crawler.hp, crawler.max_hp)
	assert_almost_eq(core.energy, Formulas.capacity(core) - Formulas.shot_energy(core), 0.001)


func test_tesla_chains_with_decay() -> void:
	var tesla := _tower(GameConfig.TESLA)
	var first := BattleFixtures.enemy(battle, "beetle", tesla.position + Vector2(0, -100))
	var second := BattleFixtures.enemy(battle, "beetle", first.position + Vector2(0, -100))
	var third := BattleFixtures.enemy(battle, "beetle", second.position + Vector2(0, -100))
	var lonely := BattleFixtures.enemy(battle, "beetle", third.position + Vector2(0, -400))
	battle.combat.update(0.1)
	var first_damage := first.max_hp - first.hp
	assert_gt(first_damage, 0.0)
	assert_almost_eq(second.max_hp - second.hp, first_damage * GameConfig.CHAIN_DECAY, 0.01)
	assert_almost_eq(third.max_hp - third.hp, first_damage * GameConfig.CHAIN_DECAY * GameConfig.CHAIN_DECAY, 0.01)
	assert_eq(lonely.hp, lonely.max_hp)
	var chain := BattleFixtures.of_type(battle.events.drain(), "chain")
	assert_eq(chain[0].points.size(), 4)


func test_plasma_splashes_ground_only() -> void:
	var plasma := _tower(GameConfig.PLASMA)
	var target := BattleFixtures.enemy(battle, "beetle", plasma.position + Vector2(0, -300))
	var neighbour := BattleFixtures.enemy(battle, "beetle", target.position + Vector2(40, 0))
	var wasp := BattleFixtures.enemy(battle, "wasp", target.position + Vector2(-20, 0))
	battle.combat.update(0.1)
	assert_eq(battle.state.projectiles.size(), 1)
	assert_eq(target.hp, target.max_hp)
	for i in 10:
		battle.combat.update(0.1)
	assert_true(battle.state.projectiles.is_empty())
	assert_lt(target.hp, target.max_hp)
	assert_lt(neighbour.hp, neighbour.max_hp)
	assert_eq(wasp.hp, wasp.max_hp)
	var types := BattleFixtures.types(battle)
	assert_true(types.has("plasma_launch"))
	assert_true(types.has("plasma_hit"))


func test_plasma_splash_hits_structures() -> void:
	var plasma := _tower(GameConfig.PLASMA)
	var camp := BattleFixtures.add(battle, GameConfig.CAMP, plasma.position + Vector2(0, -350))
	battle.combat.update(0.1)
	for i in 30:
		battle.combat.update(0.1)
	assert_lt(camp.hp, camp.max_hp())


func test_plasma_respects_min_range_and_air() -> void:
	var plasma := _tower(GameConfig.PLASMA)
	BattleFixtures.enemy(battle, "beetle", plasma.position + Vector2(0, -50))
	BattleFixtures.enemy(battle, "wasp", plasma.position + Vector2(0, -200))
	assert_null(battle.combat.find_target(plasma))


func test_enemy_turret_shoots_player_buildings() -> void:
	var turret := BattleFixtures.add(battle, GameConfig.TURRET, core.position + Vector2(0, -200))
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(0, -100))
	battle.combat.update(0.1)
	assert_almost_eq(relay.hp, relay.max_hp() - Formulas.damage(turret), 0.001)
	assert_almost_eq(turret.cooldown, Formulas.cooldown(turret), 0.001)
	battle.combat.update(0.1)
	assert_almost_eq(relay.hp, relay.max_hp() - Formulas.damage(turret), 0.001)
	assert_true(BattleFixtures.types(battle).has("enemy_shot"))


func test_turret_without_target_stays_ready() -> void:
	var turret := BattleFixtures.add(battle, GameConfig.TURRET, core.position + Vector2(0, -900))
	battle.combat.update(0.1)
	assert_eq(turret.cooldown, 0.0)


func test_shield_absorbs_damage() -> void:
	var shield := _tower(GameConfig.SHIELD, Vector2(100, 0))
	shield.energy = 10.0
	battle.combat.damage_building(core, 30.0)
	assert_almost_eq(core.hp, core.max_hp() - 10.0, 0.001)
	assert_almost_eq(shield.energy, 0.0, 0.001)
	assert_true(BattleFixtures.types(battle).has("shielded"))


func test_full_absorb_leaves_building_untouched() -> void:
	var shield := _tower(GameConfig.SHIELD, Vector2(100, 0))
	battle.combat.damage_building(core, 10.0)
	assert_eq(core.hp, core.max_hp())
	assert_almost_eq(shield.energy, Formulas.capacity(shield) - 5.0, 0.001)


func test_shield_out_of_range_does_nothing() -> void:
	_tower(GameConfig.SHIELD, Vector2(600, 0))
	battle.combat.damage_building(core, 10.0)
	assert_eq(core.hp, core.max_hp() - 10.0)


func test_destroying_player_building() -> void:
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(0, -150))
	battle.network.connect_buildings(core.id, relay.id)
	battle.events.drain()
	battle.combat.damage_building(relay, 1000.0)
	assert_null(battle.state.building(relay.id))
	assert_true(battle.state.links.is_empty())
	assert_eq(battle.state.lost, 1)
	var destroyed := BattleFixtures.of_type(battle.events.drain(), "building_destroyed")
	assert_eq(destroyed.size(), 1)
	assert_false(destroyed[0].core)
	battle.combat.damage_building(relay, 10.0)
	assert_eq(battle.state.lost, 1)


func test_destroying_structure_drops_bounty() -> void:
	var nest := BattleFixtures.add(battle, GameConfig.NEST, core.position + Vector2(0, -500))
	battle.combat.damage(nest, 5000.0, true)
	assert_null(battle.state.building(nest.id))
	assert_eq(battle.state.structures_destroyed, 1)
	var total := 0
	for pickup in battle.state.pickups:
		total += pickup.value
	assert_eq(total, int(GameConfig.building(GameConfig.NEST).bounty))
	var events := battle.events.drain()
	assert_eq(BattleFixtures.of_type(events, "structure_destroyed")[0].left, 0)
	assert_eq(BattleFixtures.of_type(events, "hit").size(), 1)


func test_killing_enemy_notifies_economy() -> void:
	var crawler := BattleFixtures.enemy(battle, "crawler", core.position)
	battle.combat.damage_enemy(crawler, 100.0, false)
	assert_false(crawler.is_alive())
	assert_eq(battle.state.kills, 1)
	battle.combat.damage_enemy(crawler, 100.0, false)
	assert_eq(battle.state.kills, 1)


func test_nearest_player_building() -> void:
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(0, -300))
	assert_eq(battle.combat.nearest_player_building(relay.position + Vector2(0, -10)), relay)
	assert_null(battle.combat.nearest_player_building(relay.position + Vector2(0, -500), 100.0))


func test_healer_repairs_most_urgent_building() -> void:
	var healer := _tower(GameConfig.HEALER, Vector2(0, -120))
	var scratched := BattleFixtures.add(battle, GameConfig.RELAY, healer.position + Vector2(100, 0))
	var wrecked := BattleFixtures.add(battle, GameConfig.ZAPPER, healer.position + Vector2(-100, 0))
	scratched.hp = scratched.max_hp() * 0.9
	wrecked.hp = wrecked.max_hp() * 0.3
	var before := wrecked.hp
	battle.combat.update(0.1)
	assert_almost_eq(wrecked.hp, before + Formulas.heal_amount(healer), 0.001)
	assert_eq(healer.target_id, wrecked.id)
	assert_almost_eq(healer.energy, Formulas.capacity(healer) - Formulas.heal_energy(healer), 0.001)
	assert_almost_eq(healer.cooldown, Formulas.heal_cooldown(healer), 0.001)
	var heal := BattleFixtures.of_type(battle.events.drain(), "heal")
	assert_eq(heal.size(), 1)
	assert_eq(heal[0].to, wrecked.position)


func test_healer_prefers_buildings_under_fire() -> void:
	var healer := _tower(GameConfig.HEALER, Vector2(0, -120))
	var calm := BattleFixtures.add(battle, GameConfig.RELAY, healer.position + Vector2(100, 0))
	var attacked := BattleFixtures.add(battle, GameConfig.RELAY, healer.position + Vector2(-100, 0))
	calm.hp = calm.max_hp() * 0.6
	attacked.hp = attacked.max_hp() * 0.8
	battle.state.time = 10.0
	attacked.hit_time = 9.0
	assert_gt(battle.combat.heal_priority(attacked), battle.combat.heal_priority(calm))
	assert_eq(battle.combat.heal_target(healer), attacked)


func test_healer_does_not_overheal_or_waste_energy() -> void:
	var healer := _tower(GameConfig.HEALER, Vector2(0, -120))
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, healer.position + Vector2(100, 0))
	relay.hp = relay.max_hp() - 2.0
	battle.combat.update(0.1)
	assert_eq(relay.hp, relay.max_hp())
	var energy := healer.energy
	healer.cooldown = 0.0
	battle.combat.update(0.1)
	assert_eq(healer.energy, energy)
	assert_eq(healer.target_id, -1)


func test_healer_ignores_far_buildings_and_needs_energy() -> void:
	var healer := _tower(GameConfig.HEALER, Vector2(0, -120))
	var far := BattleFixtures.add(battle, GameConfig.RELAY, healer.position + Vector2(Formulas.heal_range(healer) + 100.0, 0))
	far.hp = 10.0
	assert_null(battle.combat.heal_target(healer))
	var near := BattleFixtures.add(battle, GameConfig.RELAY, healer.position + Vector2(90, 0))
	near.hp = 10.0
	healer.energy = 0.0
	battle.combat.update(0.1)
	assert_eq(near.hp, 10.0)


func test_damage_marks_hit_time() -> void:
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(0, -150))
	battle.state.time = 42.0
	battle.combat.damage_building(relay, 1.0)
	assert_eq(relay.hit_time, 42.0)


func test_towers_default_priority_is_air_ranged_melee() -> void:
	var zapper := _tower(GameConfig.ZAPPER)
	var crawler := BattleFixtures.enemy(battle, "crawler", zapper.position + Vector2(0, -60))
	var soldier := BattleFixtures.enemy(battle, "soldier", zapper.position + Vector2(0, -120))
	var wasp := BattleFixtures.enemy(battle, "wasp", zapper.position + Vector2(0, -200))
	assert_eq(battle.combat.find_target(zapper), wasp)
	wasp.hp = 0.0
	assert_eq(battle.combat.find_target(zapper), soldier)
	soldier.hp = 0.0
	assert_eq(battle.combat.find_target(zapper), crawler)


func test_custom_priority_per_tower() -> void:
	var zapper := _tower(GameConfig.ZAPPER)
	var other := _tower(GameConfig.ZAPPER, Vector2(0, -170))
	var crawler := BattleFixtures.enemy(battle, "crawler", zapper.position + Vector2(0, -60))
	BattleFixtures.enemy(battle, "wasp", zapper.position + Vector2(0, -200))
	battle.raise_target_class(zapper.id, GameConfig.CLASS_MELEE)
	battle.raise_target_class(zapper.id, GameConfig.CLASS_MELEE)
	assert_eq(battle.combat.find_target(zapper), crawler)
	assert_eq(battle.combat.find_target(other).kind, "wasp")


func test_air_only_tower_ignores_ground_and_structures() -> void:
	var zapper := _tower(GameConfig.ZAPPER)
	battle.toggle_target_class(zapper.id, GameConfig.CLASS_MELEE)
	battle.toggle_target_class(zapper.id, GameConfig.CLASS_RANGED)
	BattleFixtures.enemy(battle, "crawler", zapper.position + Vector2(0, -60))
	BattleFixtures.add(battle, GameConfig.NEST, zapper.position + Vector2(0, -200))
	assert_null(battle.combat.find_target(zapper))
	var drone := BattleFixtures.enemy(battle, "drone", zapper.position + Vector2(0, -150))
	assert_eq(battle.combat.find_target(zapper), drone)


func test_plasma_can_never_target_air() -> void:
	var plasma := _tower(GameConfig.PLASMA)
	assert_false(plasma.can_target(GameConfig.CLASS_AIR))
	assert_true(plasma.can_target(GameConfig.CLASS_MELEE))
	battle.toggle_target_class(plasma.id, GameConfig.CLASS_AIR)
	assert_false(plasma.can_target(GameConfig.CLASS_AIR))


func test_tesla_chain_skips_disabled_classes() -> void:
	var tesla := _tower(GameConfig.TESLA)
	battle.toggle_target_class(tesla.id, GameConfig.CLASS_AIR)
	var first := BattleFixtures.enemy(battle, "beetle", tesla.position + Vector2(0, -100))
	var wasp := BattleFixtures.enemy(battle, "wasp", first.position + Vector2(0, -60))
	battle.combat.update(0.1)
	assert_lt(first.hp, first.max_hp)
	assert_eq(wasp.hp, wasp.max_hp)


func test_turret_uses_attack_priority() -> void:
	var turret := BattleFixtures.add(battle, GameConfig.TURRET, core.position + Vector2(0, -400))
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, turret.position + Vector2(0, 90))
	var zapper := _tower(GameConfig.ZAPPER, turret.position + Vector2(120, 140) - core.position)
	assert_eq(battle.combat.turret_target(turret), zapper)
	zapper.energy = 0.0
	relay.energy = Formulas.capacity(relay)
	assert_eq(battle.combat.turret_target(turret), relay)
	var far := BattleFixtures.add(battle, GameConfig.EXPORTER, turret.position + Vector2(0, -400))
	far.energy = Formulas.capacity(far)
	assert_eq(battle.combat.turret_target(turret), relay)


func test_walls_soak_disproportionate_damage() -> void:
	var wall := BattleFixtures.add(battle, GameConfig.BULWARK, core.position + Vector2(0, -150))
	var zapper := _tower(GameConfig.ZAPPER, Vector2(150, -150))
	for i in 20:
		battle.combat.damage_building(wall, 50.0)
		battle.combat.damage_building(zapper, 50.0)
	assert_null(battle.state.building(zapper.id))
	assert_not_null(battle.state.building(wall.id))
	assert_eq(battle.state.nav.occupant_at(battle.state.map.cell_of(zapper.position)), NavGrid.FREE)


func test_idle_towers_pause_scanning() -> void:
	var zapper := _tower(GameConfig.ZAPPER)
	battle.combat.update(GameConfig.TICK)
	assert_gt(zapper.scan_timer, 0.0)
	var crawler := BattleFixtures.enemy(battle, "crawler", zapper.position + Vector2(0, -60))
	battle.combat.update(GameConfig.TICK)
	assert_eq(crawler.hp, crawler.max_hp)
	for i in int(GameConfig.TARGET_SCAN / GameConfig.TICK) + 1:
		battle.combat.update(GameConfig.TICK)
	assert_lt(crawler.hp, crawler.max_hp)


func test_laser_keeps_target_but_rescans_for_priority() -> void:
	var laser := _tower(GameConfig.LASER)
	var crawler := BattleFixtures.enemy(battle, "crawler", laser.position + Vector2(0, -60))
	battle.combat.update(GameConfig.TICK)
	assert_eq(laser.target_id, crawler.id)
	var wasp := BattleFixtures.enemy(battle, "wasp", laser.position + Vector2(0, -90))
	battle.combat.update(GameConfig.TICK)
	assert_eq(laser.target_id, crawler.id)
	for i in int(GameConfig.TARGET_SCAN / GameConfig.TICK) + 1:
		battle.combat.update(GameConfig.TICK)
	assert_eq(laser.target_id, wasp.id)
	wasp.hp = 0.0
	battle.combat.update(GameConfig.TICK)
	assert_eq(laser.target_id, crawler.id)
