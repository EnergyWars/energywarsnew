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


func test_exporter_sells_energy_in_batches() -> void:
	var exporter := BattleFixtures.add(battle, GameConfig.EXPORTER, Vector2(400, 400))
	exporter.energy = Formulas.capacity(exporter)
	var money := battle.state.money
	var batch_time := GameConfig.EXPORT_BATCH * GameConfig.ENERGY_PER_COIN / Formulas.export_rate(exporter)
	battle.economy.update(batch_time * 0.5)
	assert_eq(battle.state.money, money)
	battle.economy.update(batch_time * 0.6)
	assert_eq(battle.state.money, money + GameConfig.EXPORT_BATCH)
	assert_almost_eq(exporter.energy, Formulas.capacity(exporter) - Formulas.export_rate(exporter) * batch_time * 1.1, 0.01)
	var exported := BattleFixtures.of_type(battle.events.drain(), "export")
	assert_eq(exported.size(), 1)
	assert_eq(exported[0].value, GameConfig.EXPORT_BATCH)


func test_exporter_without_energy_earns_nothing() -> void:
	var exporter := BattleFixtures.add(battle, GameConfig.EXPORTER, Vector2(400, 400))
	exporter.energy = 0.0
	var money := battle.state.money
	battle.economy.update(10.0)
	assert_eq(battle.state.money, money)
	assert_eq(exporter.export_buffer, 0.0)
