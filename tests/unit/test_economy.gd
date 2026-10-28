extends GutTest

var battle: Battle


func before_each() -> void:
	battle = BattleFixtures.battle(0, false)


func _kill(kind: String = "beetle") -> Enemy:
	var enemy := BattleFixtures.enemy(battle, kind, Vector2(500, 500))
	enemy.hp = 0.0
	battle.economy.enemy_killed(enemy)
	return enemy


func _pickup_total() -> int:
	var total := 0
	for pickup in battle.state.pickups:
		total += pickup.value
	return total


func _coins(enemy: Enemy) -> int:
	return clampi(enemy.bounty / Economy.KILL_COINS_PER, 1, Economy.MAX_KILL_COINS)


func test_kill_drops_coins_worth_bounty() -> void:
	var enemy := _kill()
	assert_eq(battle.state.kills, 1)
	assert_eq(battle.state.pickups.size(), _coins(enemy))
	assert_eq(_pickup_total(), enemy.bounty)
	var kill := BattleFixtures.of_type(battle.events.drain(), "kill")[0]
	assert_eq(kill.combo, 1)
	assert_eq(kill.bounty, enemy.bounty)
	assert_false(kill.boss)


func test_combo_builds_and_pays_bonus() -> void:
	var money := battle.state.money
	for i in 5:
		_kill("crawler")
	assert_eq(battle.economy.combo, 5)
	assert_eq(battle.state.best_combo, 5)
	assert_eq(battle.state.money, money + 5)
	var combo := BattleFixtures.of_type(battle.events.drain(), "combo")
	assert_eq(combo.size(), 1)
	assert_eq(combo[0].tier, 1)


func test_combo_expires() -> void:
	for i in 5:
		_kill("crawler")
	battle.events.drain()
	battle.economy.update(GameConfig.COMBO_WINDOW + 0.1)
	assert_eq(battle.economy.combo, 0)
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "combo_end")[0].count, 5)
	_kill("crawler")
	battle.economy.update(GameConfig.COMBO_WINDOW + 0.1)
	assert_true(BattleFixtures.of_type(battle.events.drain(), "combo_end").is_empty())


func test_pickups_collect_after_delay() -> void:
	var enemy := _kill()
	var money := battle.state.money
	battle.economy.update(GameConfig.PICKUP_DELAY * 0.5)
	assert_eq(battle.state.money, money)
	battle.economy.update(GameConfig.PICKUP_DELAY)
	assert_true(battle.state.pickups.is_empty())
	assert_eq(battle.state.money, money + enemy.bounty)
	assert_eq(battle.state.earned, enemy.bounty)
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "collect").size(), _coins(enemy))


func test_pickups_move_and_slow_down() -> void:
	battle.economy.drop(Vector2(100, 100), 10, 1)
	var pickup := battle.state.pickups[0]
	var speed := pickup.velocity.length()
	battle.economy.update(0.1)
	assert_ne(pickup.position, Vector2(100, 100))
	assert_lt(pickup.velocity.length(), speed)


func test_drop_splits_value() -> void:
	battle.economy.drop(Vector2.ZERO, 0, 5)
	assert_true(battle.state.pickups.is_empty())
	battle.economy.drop(Vector2.ZERO, 3, 10)
	assert_eq(battle.state.pickups.size(), 3)
	battle.state.pickups.clear()
	battle.economy.drop(Vector2.ZERO, 11, 4)
	assert_eq(_pickup_total(), 11)


func test_collect_all_and_double_collect() -> void:
	battle.economy.drop(Vector2.ZERO, 20, 4)
	var pickup := battle.state.pickups[0]
	battle.economy.collect_all()
	assert_eq(battle.state.money, int(battle.state.level.money) + 20)
	battle.economy.collect(pickup)
	assert_eq(battle.state.money, int(battle.state.level.money) + 20)


func test_structure_bounty() -> void:
	var camp := Building.new(99, GameConfig.CAMP, Vector2(300, 300))
	battle.economy.structure_destroyed(camp)
	assert_eq(_pickup_total(), int(GameConfig.building(GameConfig.CAMP).bounty))
	assert_eq(battle.state.structures_destroyed, 1)


func test_exporter_pays_out_after_a_full_cycle() -> void:
	var exporter := BattleFixtures.add(battle, GameConfig.EXPORTER, Vector2(400, 400))
	exporter.energy = Formulas.capacity(exporter)
	var money := battle.state.money
	var payout := int(round(Formulas.export_payout(exporter)))
	assert_almost_eq(Formulas.export_batch(exporter), Formulas.export_rate(exporter) * GameConfig.EXPORT_CYCLE, 0.001)
	assert_eq(payout, int(round(Formulas.export_rate(exporter) / GameConfig.ENERGY_PER_COIN * GameConfig.EXPORT_CYCLE)))
	battle.economy.update(GameConfig.EXPORT_CYCLE * 0.5)
	assert_eq(battle.state.money, money)
	assert_almost_eq(Formulas.export_progress(exporter), 0.5, 0.001)
	battle.economy.update(GameConfig.EXPORT_CYCLE * 0.6)
	assert_eq(battle.state.money, money + payout)
	assert_almost_eq(Formulas.export_progress(exporter), 0.1, 0.001)
	assert_almost_eq(exporter.energy, Formulas.capacity(exporter) - Formulas.export_rate(exporter) * GameConfig.EXPORT_CYCLE * 1.1, 0.01)
	var exported := BattleFixtures.of_type(battle.events.drain(), "export")
	assert_eq(exported.size(), 1)
	assert_eq(exported[0].value, payout)
	assert_eq(exported[0].id, exporter.id)


func test_starved_exporter_takes_longer_for_its_payout() -> void:
	var exporter := BattleFixtures.add(battle, GameConfig.EXPORTER, Vector2(400, 400))
	var money := battle.state.money
	var rate := Formulas.export_rate(exporter)
	for i in 10:
		exporter.energy += rate * 0.5
		battle.economy.update(1.0)
	assert_eq(battle.state.money, money + int(round(Formulas.export_payout(exporter))))
	assert_almost_eq(Formulas.export_progress(exporter), 0.0, 0.001)
	assert_eq(exporter.energy, 0.0)


func test_exporters_pay_out_independently() -> void:
	var early := BattleFixtures.add(battle, GameConfig.EXPORTER, Vector2(400, 400))
	var late := BattleFixtures.add(battle, GameConfig.EXPORTER, Vector2(520, 400))
	early.energy = Formulas.capacity(early)
	late.energy = Formulas.capacity(late)
	late.export_buffer = 0.0
	early.export_buffer = Formulas.export_batch(early) * 0.8
	battle.economy.update(GameConfig.EXPORT_CYCLE * 0.3)
	var exported := BattleFixtures.of_type(battle.events.drain(), "export")
	assert_eq(exported.size(), 1)
	assert_eq(exported[0].id, early.id)
	assert_almost_eq(Formulas.export_progress(late), 0.3, 0.001)


func test_fractional_payouts_carry_over() -> void:
	var exporter := BattleFixtures.add(battle, GameConfig.EXPORTER, Vector2(400, 400))
	exporter.set_level(GameConfig.TRACK_RATE, 2)
	var payout := Formulas.export_payout(exporter)
	assert_ne(payout, floorf(payout))
	var money := battle.state.money
	var cycles := 4
	for i in cycles:
		exporter.energy = Formulas.capacity(exporter)
		battle.economy.update(GameConfig.EXPORT_CYCLE)
	assert_eq(battle.state.money, money + int(floor(payout * cycles + 0.0001)))
	assert_almost_eq(exporter.export_carry, payout * cycles - floorf(payout * cycles + 0.0001), 0.001)
	assert_eq(Formulas.export_progress(Building.new(9, GameConfig.RELAY, Vector2.ZERO)), 0.0)


func test_exporter_without_energy_earns_nothing() -> void:
	var exporter := BattleFixtures.add(battle, GameConfig.EXPORTER, Vector2(400, 400))
	exporter.energy = 0.0
	var money := battle.state.money
	battle.economy.update(10.0)
	assert_eq(battle.state.money, money)
	assert_eq(exporter.export_buffer, 0.0)
