extends GutTest

var battle: Battle
var core: Building


func before_each() -> void:
	TranslationServer.set_locale("en")
	battle = BattleFixtures.battle(GameConfig.level_count() - 1, false)
	core = battle.state.core()
	core.energy = 0.0


func _tower(kind: String) -> Building:
	var tower := BattleFixtures.add(battle, kind, core.position + Vector2(0, -100))
	tower.energy = Formulas.capacity(tower)
	return tower


func test_overcharge_trades_energy_for_damage() -> void:
	var zapper := Building.new(1, GameConfig.ZAPPER, Vector2.ZERO)
	zapper.set_level(GameConfig.TRACK_OVERCLOCK, 3)
	assert_almost_eq(Formulas.damage(zapper), 26.0 * 1.6, 0.001)
	assert_almost_eq(Formulas.shot_energy(zapper), 4.0 * pow(1.25, 3), 0.001)
	assert_almost_eq(Formulas.overclock_energy(zapper), pow(1.25, 3), 0.0001)
	assert_almost_eq(Formulas.cooldown(zapper), 0.45, 0.0001)
	zapper.set_level(GameConfig.TRACK_EFFICIENCY, 4)
	assert_almost_eq(Formulas.shot_energy(zapper), 4.0 * pow(1.25, 3) / 1.2, 0.001)


func test_overcharged_tower_is_overloaded_once_a_shot_exceeds_its_storage() -> void:
	var zapper := Building.new(1, GameConfig.ZAPPER, Vector2.ZERO)
	zapper.set_level(GameConfig.TRACK_OVERCLOCK, 10)
	assert_false(Formulas.is_overloaded(zapper))
	zapper.set_level(GameConfig.TRACK_OVERCLOCK, 11)
	assert_true(Formulas.is_overloaded(zapper))
	assert_gt(Formulas.action_energy(zapper), Formulas.capacity(zapper))
	zapper.set_level(GameConfig.TRACK_CAPACITY, 2)
	assert_false(Formulas.is_overloaded(zapper))


func test_action_energy_per_role() -> void:
	var laser := Building.new(1, GameConfig.LASER, Vector2.ZERO)
	assert_almost_eq(Formulas.action_energy(laser), 10.0 * GameConfig.TICK, 0.0001)
	assert_true(Formulas.is_laser(laser))
	var healer := Building.new(2, GameConfig.HEALER, Vector2.ZERO)
	assert_almost_eq(Formulas.action_energy(healer), Formulas.heal_energy(healer), 0.0001)
	assert_eq(Formulas.action_energy(Building.new(3, GameConfig.RELAY, Vector2.ZERO)), 0.0)
	assert_false(Formulas.is_overloaded(Building.new(4, GameConfig.RELAY, Vector2.ZERO)))
	assert_false(Formulas.is_overloaded(Building.new(5, GameConfig.TURRET, Vector2.ZERO)))


func test_overloaded_tower_never_fires() -> void:
	var zapper := _tower(GameConfig.ZAPPER)
	zapper.set_level(GameConfig.TRACK_OVERCLOCK, 11)
	zapper.energy = Formulas.capacity(zapper)
	var beetle := BattleFixtures.enemy(battle, "beetle", zapper.position + Vector2(0, -150))
	for i in 30:
		battle.combat.update(GameConfig.TICK)
	assert_eq(beetle.hp, beetle.max_hp)
	assert_eq(zapper.energy, Formulas.capacity(zapper))
	zapper.set_level(GameConfig.TRACK_CAPACITY, 2)
	zapper.energy = Formulas.capacity(zapper)
	battle.combat.update(GameConfig.TICK)
	assert_lt(beetle.hp, beetle.max_hp)


func test_overcharge_upgrades_are_allowed_and_reported() -> void:
	var zapper := _tower(GameConfig.ZAPPER)
	zapper.set_level(GameConfig.TRACK_OVERCLOCK, 10)
	battle.state.money = 100000
	battle.events.drain()
	assert_true(battle.upgrade(zapper.id, GameConfig.TRACK_OVERCLOCK))
	var upgraded := BattleFixtures.of_type(battle.events.drain(), "upgraded")
	assert_true(bool(upgraded[0].overloaded))
	assert_true(battle.upgrade(zapper.id, GameConfig.TRACK_SPEED))
	assert_true(bool(BattleFixtures.of_type(battle.events.drain(), "upgraded")[0].overloaded))


func test_panel_texts_warn_before_and_after_overload() -> void:
	var zapper := Building.new(1, GameConfig.ZAPPER, Vector2.ZERO)
	zapper.set_level(GameConfig.TRACK_OVERCLOCK, 10)
	assert_eq(StatText.overload_change(zapper, GameConfig.TRACK_OVERCLOCK), Texts.format("PANEL_OVERLOAD_NEXT", [Icons.WARNING]))
	assert_eq(StatText.overload_change(zapper, GameConfig.TRACK_POWER), "")
	zapper.set_level(GameConfig.TRACK_OVERCLOCK, 11)
	assert_eq(StatText.overload_change(zapper, GameConfig.TRACK_EFFICIENCY), "")
	assert_eq(StatText.overload_change(zapper, GameConfig.TRACK_CAPACITY), Texts.format("PANEL_OVERLOAD_FIXED", [Icons.CHECK]))
	assert_eq(StatText.overload_change(zapper, GameConfig.TRACK_OVERCLOCK), "")
	assert_ne(StatText.draw_change(Building.new(2, GameConfig.ZAPPER, Vector2.ZERO), GameConfig.TRACK_OVERCLOCK), "")


func test_overcharge_track_value_shows_damage_and_shot_energy() -> void:
	var zapper := Building.new(1, GameConfig.ZAPPER, Vector2.ZERO)
	assert_eq(StatText.track_value(zapper, GameConfig.TRACK_OVERCLOCK), "26  %s4.0" % Icons.BOLT)
	assert_eq(StatText.next_value(zapper, GameConfig.TRACK_OVERCLOCK), "31  %s5.0" % Icons.BOLT)


func test_overcharge_is_offered_on_every_firing_tower() -> void:
	for kind in [GameConfig.ZAPPER, GameConfig.LASER, GameConfig.TESLA, GameConfig.PLASMA, GameConfig.ROVER]:
		assert_true(GameConfig.building(kind).tracks.has(GameConfig.TRACK_OVERCLOCK), kind)
	assert_false(GameConfig.building(GameConfig.CORE).tracks.has(GameConfig.TRACK_OVERCLOCK))
