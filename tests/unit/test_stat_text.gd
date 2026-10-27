extends GutTest


func _building(kind: String) -> Building:
	return Building.new(1, kind, Vector2.ZERO)


func test_track_values() -> void:
	var relay := _building(GameConfig.RELAY)
	assert_eq(StatText.track_value(relay, GameConfig.TRACK_RATE), "30/s")
	assert_eq(StatText.track_value(relay, GameConfig.TRACK_RANGE), "330")
	assert_eq(StatText.track_value(relay, GameConfig.TRACK_LINKS), "3")
	assert_eq(StatText.next_value(relay, GameConfig.TRACK_LINKS), "4")
	assert_eq(relay.level(GameConfig.TRACK_LINKS), 0)
	assert_eq(StatText.track_value(_building(GameConfig.SOLAR), GameConfig.TRACK_OUTPUT), "8.0/s")
	assert_eq(StatText.track_value(_building(GameConfig.BATTERY), GameConfig.TRACK_CAPACITY), "400")
	assert_eq(StatText.track_value(_building(GameConfig.ZAPPER), GameConfig.TRACK_POWER), "26")
	assert_eq(StatText.track_value(_building(GameConfig.ZAPPER), GameConfig.TRACK_RANGE), "230")
	assert_eq(StatText.track_value(_building(GameConfig.ZAPPER), GameConfig.TRACK_SPEED), "2.22/s")
	assert_eq(StatText.track_value(_building(GameConfig.SHIELD), GameConfig.TRACK_RANGE), "210")
	assert_eq(StatText.track_value(_building(GameConfig.SHIELD), GameConfig.TRACK_POWER), "2.0")
	assert_eq(StatText.track_value(_building(GameConfig.EXPORTER), GameConfig.TRACK_RATE), "8/s")
	assert_eq(StatText.track_value(_building(GameConfig.BULWARK), GameConfig.TRACK_HULL), "2000")
	assert_eq(StatText.next_value(_building(GameConfig.BULWARK), GameConfig.TRACK_HULL), "3000")
	assert_eq(StatText.track_value(relay, "unknown"), "")


func test_pips() -> void:
	var relay := _building(GameConfig.RELAY)
	relay.levels[GameConfig.TRACK_LINKS] = 1
	assert_eq(StatText.pips(relay, GameConfig.TRACK_LINKS), "●○○")


func test_stats_for_each_kind() -> void:
	var battle := BattleFixtures.battle(GameConfig.level_count() - 1)
	for kind: String in GameConfig.BUILDINGS:
		var building := Building.new(500, kind, Vector2.ZERO)
		var rows := StatText.stats(building, battle.state)
		assert_gt(rows.size(), 1, kind)
		assert_eq(rows[0][0], "STAT_HP")
	var laser := StatText.stats(_building(GameConfig.LASER), battle.state)
	assert_true(laser.any(func(row: Array) -> bool: return row[0] == "STAT_DPS"))
	var exporter := StatText.stats(_building(GameConfig.EXPORTER), battle.state)
	assert_true(exporter.any(func(row: Array) -> bool: return row[0] == "STAT_EXPORT_INCOME" and row[1] == "%.1f/s" % (8.0 / GameConfig.ENERGY_PER_COIN)))
	var wall := StatText.stats(_building(GameConfig.BULWARK), battle.state)
	assert_true(wall.any(func(row: Array) -> bool: return row[0] == "STAT_BLOCKS"))
	assert_false(wall.any(func(row: Array) -> bool: return row[0] == "STAT_ENERGY"))
	var high := _building(GameConfig.ZAPPER)
	high.elevation = 1
	assert_true(StatText.stats(high, battle.state).any(func(row: Array) -> bool: return row[0] == "STAT_HIGH_GROUND"))
	var nest := StatText.stats(_building(GameConfig.NEST), battle.state)
	assert_true(nest.any(func(row: Array) -> bool: return row[0] == "STAT_SPAWNS"))
