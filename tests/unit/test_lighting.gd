extends GutTest

var battle: Battle
var state: BattleState
var core: Building


func before_each() -> void:
	battle = BattleFixtures.battle(GameConfig.level_count() - 1, false)
	state = battle.state
	core = state.core()
	core.energy = 0.0
	battle.events.drain()


func _night() -> void:
	state.phase = BattleState.Phase.FIGHT
	state.round_time = float(state.level.day) + 1.0


func _lamp(offset: Vector2) -> Building:
	var lamp := BattleFixtures.add(battle, GameConfig.LAMP, core.position + offset)
	lamp.energy = Formulas.capacity(lamp)
	return lamp


func _tower(kind: String, offset: Vector2) -> Building:
	var tower := BattleFixtures.add(battle, kind, core.position + offset)
	tower.energy = Formulas.capacity(tower)
	return tower


func _core_reach() -> float:
	return core.half_extent() + GameConfig.CORE_LIGHT * GameConfig.CELL


func test_core_lights_three_tiles_around_itself() -> void:
	assert_almost_eq(Formulas.light_reach(core), _core_reach(), 0.001)
	assert_eq(Formulas.light_reach(BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(200, 0))), 0.0)
	var sources := battle.lighting.current()
	assert_eq(sources.size(), 1)
	assert_eq(Vector2(sources[0].x, sources[0].y), core.position)
	assert_almost_eq(sources[0].z, _core_reach(), 0.001)


func test_everything_is_visible_during_the_day() -> void:
	assert_false(battle.lighting.is_dark())
	assert_true(battle.lighting.sees(core.position + Vector2(5000, 0)))
	state.phase = BattleState.Phase.FIGHT
	state.round_time = 0.0
	assert_false(battle.lighting.is_dark())
	assert_true(battle.lighting.sees(core.position + Vector2(5000, 0)))


func test_night_hides_everything_outside_the_light() -> void:
	_night()
	var lighting := battle.lighting
	assert_true(lighting.is_dark())
	assert_true(lighting.sees(core.position + Vector2(0, -(_core_reach() - 1.0))))
	assert_false(lighting.sees(core.position + Vector2(0, -(_core_reach() + 20.0))))
	assert_true(lighting.sees(core.position + Vector2(0, -(_core_reach() + 20.0)), 25.0))
	assert_false(lighting.is_lit(core.position + Vector2(800, 0)))


func test_destroyed_core_gives_no_light() -> void:
	_night()
	battle.combat.destroy(core)
	assert_true(battle.lighting.current().is_empty())
	assert_false(battle.lighting.sees(core.position))


func test_lamp_shines_only_at_night_and_uses_energy() -> void:
	var lamp := _lamp(Vector2(0, -500))
	var full := lamp.energy
	battle.lighting.update(0.5)
	assert_false(lamp.lit)
	assert_eq(lamp.energy, full)
	assert_eq(battle.lighting.current().size(), 1)
	_night()
	battle.lighting.update(0.5)
	assert_true(lamp.lit)
	assert_almost_eq(lamp.energy, full - Formulas.lamp_draw(lamp) * 0.5, 0.001)
	assert_eq(battle.lighting.current().size(), 2)
	assert_almost_eq(Formulas.light_reach(lamp), GameConfig.LAMP_RADIUS * GameConfig.CELL, 0.001)
	var reach := Formulas.lit_reach(lamp)
	assert_almost_eq(reach, Formulas.light_reach(lamp) * lamp.energy / Formulas.capacity(lamp), 0.001)
	assert_almost_eq(battle.lighting.current()[1].z, reach, 0.001)
	assert_true(battle.lighting.sees(lamp.position + Vector2(reach - 1.0, 0)))
	assert_false(battle.lighting.sees(lamp.position + Vector2(reach + 5.0, 0)))


func test_lamp_without_enough_energy_goes_dark() -> void:
	var lamp := _lamp(Vector2(0, -500))
	_night()
	lamp.energy = Formulas.lamp_draw(lamp) * 0.05
	battle.lighting.update(0.1)
	assert_false(lamp.lit)
	assert_almost_eq(lamp.energy, Formulas.lamp_draw(lamp) * 0.05, 0.0001)
	assert_eq(battle.lighting.current().size(), 1)
	lamp.energy = Formulas.lamp_draw(lamp) * 0.1
	battle.lighting.update(0.1)
	assert_true(lamp.lit)
	assert_almost_eq(lamp.energy, 0.0, 0.0001)


func test_dead_lamp_is_skipped() -> void:
	var lamp := _lamp(Vector2(0, -500))
	_night()
	lamp.hp = 0.0
	battle.lighting.update(0.1)
	assert_false(lamp.lit)
	assert_eq(battle.lighting.current().size(), 1)


func test_light_cache_follows_radius_and_roster_changes() -> void:
	var lamp := _lamp(Vector2(0, -500))
	_night()
	battle.lighting.update(0.1)
	var before := Formulas.lit_reach(lamp)
	assert_almost_eq(battle.lighting.current()[1].z, before, 0.001)
	lamp.light_radius = 6.0
	assert_almost_eq(battle.lighting.current()[1].z, before, 0.001)
	state.mark_changed()
	assert_almost_eq(battle.lighting.current()[1].z, 6.0 * GameConfig.CELL * Formulas.light_fill(lamp), 0.001)
	state.remove_building(lamp.id)
	assert_eq(battle.lighting.current().size(), 1)


func test_lamp_draw_grows_disproportionately_with_the_radius() -> void:
	var lamp := _lamp(Vector2(0, -500))
	assert_almost_eq(Formulas.lamp_draw_at(lamp, GameConfig.LAMP_BASE_RADIUS), GameConfig.LAMP_BASE_DRAW, 0.0001)
	var small := Formulas.lamp_draw_at(lamp, 2.0)
	var double := Formulas.lamp_draw_at(lamp, 4.0)
	assert_almost_eq(double / small, pow(2.0, GameConfig.LAMP_EXPONENT), 0.0001)
	assert_gt(double / small, 4.0)
	assert_gt(Formulas.lamp_draw_at(lamp, 7.0) - Formulas.lamp_draw_at(lamp, 6.0), Formulas.lamp_draw_at(lamp, 3.0) - Formulas.lamp_draw_at(lamp, 2.0))
	assert_eq(Formulas.lamp_draw_at(lamp, -1.0), 0.0)
	assert_almost_eq(Formulas.lamp_draw(lamp), Formulas.lamp_draw_at(lamp, GameConfig.LAMP_RADIUS), 0.0001)
	assert_eq(Formulas.lamp_draw(core), 0.0)


func test_efficiency_upgrades_make_the_lamp_cheaper() -> void:
	var lamp := _lamp(Vector2(0, -500))
	var before := Formulas.lamp_draw(lamp)
	lamp.levels[GameConfig.TRACK_EFFICIENCY] = 3
	assert_lt(Formulas.lamp_draw(lamp), before)
	var expected := GameConfig.LAMP_BASE_DRAW * pow(GameConfig.LAMP_RADIUS / GameConfig.LAMP_BASE_RADIUS, GameConfig.LAMP_EXPONENT) / Formulas.efficiency(lamp)
	assert_almost_eq(Formulas.lamp_draw(lamp), expected, 0.0001)
	assert_true(GameConfig.building(GameConfig.LAMP).tracks.has(GameConfig.TRACK_EFFICIENCY))


func test_light_radius_snaps_and_clamps() -> void:
	assert_eq(Formulas.clamp_light(4.2), 4.0)
	assert_eq(Formulas.clamp_light(4.3), 4.5)
	assert_eq(Formulas.clamp_light(0.0), GameConfig.LAMP_RADIUS_MIN)
	assert_eq(Formulas.clamp_light(50.0), GameConfig.LAMP_RADIUS_MAX)


func test_towers_ignore_enemies_in_the_dark() -> void:
	var zapper := _tower(GameConfig.ZAPPER, Vector2(0, -150))
	var hidden := BattleFixtures.enemy(battle, "crawler", core.position + Vector2(0, -320))
	assert_eq(battle.combat.find_target(zapper), hidden)
	_night()
	assert_null(battle.combat.find_target(zapper))
	var seen := BattleFixtures.enemy(battle, "crawler", core.position + Vector2(0, -200))
	assert_eq(battle.combat.find_target(zapper), seen)
	seen.hp = 0.0
	_lamp(Vector2(0, -340))
	battle.lighting.update(0.1)
	assert_eq(battle.combat.find_target(zapper), hidden)


func test_towers_ignore_structures_in_the_dark() -> void:
	var zapper := _tower(GameConfig.ZAPPER, Vector2(0, -150))
	var nest := BattleFixtures.add(battle, GameConfig.NEST, zapper.position + Vector2(0, -200))
	assert_eq(battle.combat.find_target(zapper), nest)
	_night()
	assert_null(battle.combat.find_target(zapper))


func test_focus_needs_light_at_night() -> void:
	var zapper := _tower(GameConfig.ZAPPER, Vector2(0, -150))
	var target := BattleFixtures.enemy(battle, "crawler", core.position + Vector2(0, -320))
	assert_eq(battle.combat.set_focus(zapper, target), Combat.OK)
	assert_eq(battle.combat.focus_in_range(zapper), target)
	_night()
	assert_null(battle.combat.focus_in_range(zapper))
	assert_eq(zapper.focus, target)


func test_laser_drops_a_target_that_leaves_the_light() -> void:
	var laser := _tower(GameConfig.LASER, Vector2(0, -150))
	var enemy := BattleFixtures.enemy(battle, "beetle", core.position + Vector2(0, -200))
	_night()
	battle.combat.update(0.1)
	assert_true(laser.firing)
	enemy.position = core.position + Vector2(0, -330)
	laser.scan_timer = 0.0
	battle.combat.update(0.1)
	assert_false(laser.firing)


func test_tesla_chain_does_not_jump_into_the_dark() -> void:
	var tesla := _tower(GameConfig.TESLA, Vector2(0, -100))
	var first := BattleFixtures.enemy(battle, "beetle", core.position + Vector2(0, -200))
	var second := BattleFixtures.enemy(battle, "beetle", core.position + Vector2(0, -280))
	_night()
	battle.combat.update(0.1)
	assert_lt(first.hp, first.max_hp)
	assert_eq(second.hp, second.max_hp)
	var chain := BattleFixtures.of_type(battle.events.drain(), "chain")
	assert_eq(chain[0].points.size(), 2)
	assert_eq(tesla.target_id, first.id)


func test_soldier_in_the_core_only_shoots_lit_enemies() -> void:
	state.scout.boarded = true
	var hidden := BattleFixtures.enemy(battle, "crawler", core.position + Vector2(0, -245))
	_night()
	battle.combat.update(0.1)
	assert_eq(hidden.hp, hidden.max_hp)
	assert_eq(state.scout.target_id, -1)
	var seen := BattleFixtures.enemy(battle, "crawler", core.position + Vector2(0, -150))
	state.scout.cooldown = 0.0
	battle.combat.update(0.1)
	assert_eq(state.scout.target_id, seen.id)
	assert_lt(seen.hp, seen.max_hp)


func test_battle_tick_lights_lamps_at_night() -> void:
	var lamp := _lamp(Vector2(0, -500))
	battle.start_round()
	state.round_time = float(state.level.day) + 1.0
	battle.tick(GameConfig.TICK)
	assert_true(lamp.lit)
	assert_eq(battle.combat.lighting, battle.lighting)


func test_lamp_radius_shrinks_with_its_charge() -> void:
	var lamp := _lamp(Vector2(0, -500))
	var full := Formulas.light_reach(lamp)
	assert_almost_eq(Formulas.lit_reach(lamp), full, 0.001)
	lamp.energy = Formulas.capacity(lamp) * 0.25
	assert_almost_eq(Formulas.light_fill(lamp), 0.25, 0.0001)
	assert_almost_eq(Formulas.lit_reach(lamp), full * 0.25, 0.001)
	lamp.energy = 0.0
	assert_eq(Formulas.lit_reach(lamp), 0.0)
	lamp.energy = Formulas.capacity(lamp) * 3.0
	assert_almost_eq(Formulas.lit_reach(lamp), full, 0.001)
	assert_almost_eq(Formulas.lit_reach(core), Formulas.light_reach(core), 0.001)
	assert_eq(Formulas.light_fill(BattleFixtures.add(battle, GameConfig.BULWARK, core.position + Vector2(300, 0))), 0.0)
	_night()
	lamp.energy = Formulas.capacity(lamp) * 0.5
	battle.lighting.update(0.1)
	assert_true(lamp.lit)
	var reach := battle.lighting.current()[1].z
	assert_lt(reach, full * 0.5)
	assert_almost_eq(reach, Formulas.lit_reach(lamp), 0.001)
	assert_true(battle.lighting.sees(lamp.position + Vector2(reach - 1.0, 0)))
	assert_false(battle.lighting.sees(lamp.position + Vector2(full * 0.8, 0)))


func test_powered_buildings_glow_half_a_tile() -> void:
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(0, -560))
	relay.energy = 10.0
	var edge := relay.half_extent()
	_night()
	assert_false(battle.lighting.is_glowing(relay.position))
	var version := battle.lighting.glow_version
	battle.lighting.update(0.1)
	assert_eq(battle.lighting.glow_version, version + 1)
	assert_eq(battle.lighting.glow[state.map.index(relay.origin)], Lighting.GLOW_ON)
	assert_true(battle.lighting.sees(relay.position))
	assert_true(battle.lighting.sees(relay.position + Vector2(edge + GameConfig.CELL * 0.45, 0)))
	assert_true(battle.lighting.sees(relay.position + Vector2(0, -(edge + GameConfig.CELL * 0.45))))
	assert_false(battle.lighting.sees(relay.position + Vector2(edge + GameConfig.CELL * 0.6, 0)))
	assert_true(battle.lighting.sees(relay.position + Vector2(edge + GameConfig.CELL * 0.6, 0), 12.0))
	assert_false(battle.lighting.sees(relay.position + Vector2(edge + GameConfig.CELL * 0.4, edge + GameConfig.CELL * 0.4)))
	assert_false(battle.lighting.refresh_glow())
	assert_eq(battle.lighting.glow_version, version + 1)
	relay.energy = GameConfig.GLOW_ENERGY * 0.5
	assert_true(battle.lighting.refresh_glow())
	assert_eq(battle.lighting.glow[state.map.index(relay.origin)], 0)
	assert_false(battle.lighting.sees(relay.position))


func test_only_living_player_buildings_glow() -> void:
	var nest := BattleFixtures.add(battle, GameConfig.NEST, core.position + Vector2(0, -700))
	nest.energy = 50.0
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(400, 0))
	relay.energy = 10.0
	relay.hp = 0.0
	core.energy = 10.0
	assert_false(Formulas.glows(nest))
	assert_false(Formulas.glows(relay))
	assert_true(Formulas.glows(core))
	battle.lighting.refresh_glow()
	for cell in core.footprint():
		assert_eq(battle.lighting.glow[state.map.index(cell)], Lighting.GLOW_ON)
	assert_eq(battle.lighting.glow[state.map.index(nest.origin)], 0)
	assert_eq(battle.lighting.glow[state.map.index(relay.origin)], 0)


func test_towers_see_enemies_next_to_powered_buildings() -> void:
	var zapper := _tower(GameConfig.ZAPPER, Vector2(0, -600))
	var close := BattleFixtures.enemy(battle, "crawler", zapper.position + Vector2(0, -(zapper.half_extent() + 20.0)))
	_night()
	assert_null(battle.combat.find_target(zapper))
	battle.lighting.update(0.1)
	assert_eq(battle.combat.find_target(zapper), close)
	close.position = zapper.position + Vector2(0, -150)
	assert_null(battle.combat.find_target(zapper))
