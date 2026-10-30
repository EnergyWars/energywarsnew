extends GutTest


func _building(kind: String) -> Building:
	return Building.new(1, kind, Vector2.ZERO)


func test_cells_converts_pixels_to_field_widths() -> void:
	assert_eq(StatText.cells(GameConfig.CELL), "1")
	assert_eq(StatText.cells(GameConfig.CELL * 1.5), "1.5")
	assert_eq(StatText.cells(0.0), "0")
	assert_eq(StatText.cells(GameConfig.CELL * 3.25), "3.25")


func test_track_values() -> void:
	var relay := _building(GameConfig.RELAY)
	assert_eq(StatText.track_value(relay, GameConfig.TRACK_RATE), "30/s")
	assert_eq(StatText.track_value(relay, GameConfig.TRACK_RANGE), "5.89")
	assert_eq(StatText.track_value(relay, GameConfig.TRACK_LINKS), "3")
	assert_eq(StatText.next_value(relay, GameConfig.TRACK_LINKS), "4")
	assert_eq(relay.level(GameConfig.TRACK_LINKS), 0)
	assert_eq(StatText.track_value(_building(GameConfig.SOLAR), GameConfig.TRACK_OUTPUT), "8.0/s")
	assert_eq(StatText.track_value(_building(GameConfig.BATTERY), GameConfig.TRACK_CAPACITY), "400")
	assert_eq(StatText.track_value(_building(GameConfig.ZAPPER), GameConfig.TRACK_POWER), "26")
	assert_eq(StatText.track_value(_building(GameConfig.ZAPPER), GameConfig.TRACK_RANGE), "4.11")
	assert_eq(StatText.track_value(_building(GameConfig.ZAPPER), GameConfig.TRACK_SPEED), "2.22/s")
	assert_eq(StatText.track_value(_building(GameConfig.SHIELD), GameConfig.TRACK_RANGE), "3.75")
	assert_eq(StatText.track_value(_building(GameConfig.SHIELD), GameConfig.TRACK_POWER), "2.0")
	assert_eq(StatText.track_value(_building(GameConfig.EXPORTER), GameConfig.TRACK_RATE), "8/s")
	assert_eq(StatText.track_value(_building(GameConfig.BULWARK), GameConfig.TRACK_HULL), "1,600")
	assert_eq(StatText.next_value(_building(GameConfig.BULWARK), GameConfig.TRACK_HULL), "4,800")
	assert_eq(StatText.track_value(_building(GameConfig.ZAPPER), GameConfig.TRACK_EFFICIENCY), "100%")
	assert_eq(StatText.next_value(_building(GameConfig.ZAPPER), GameConfig.TRACK_EFFICIENCY), "105%")
	assert_eq(StatText.track_value(_building(GameConfig.ZAPPER), GameConfig.TRACK_CRIT), "12%")
	assert_eq(StatText.next_value(_building(GameConfig.ZAPPER), GameConfig.TRACK_CRIT), "13%")
	assert_eq(StatText.track_value(_building(GameConfig.TESLA), GameConfig.TRACK_CHAIN), "5")
	assert_eq(StatText.next_value(_building(GameConfig.TESLA), GameConfig.TRACK_CHAIN), "6")
	assert_eq(StatText.track_value(_building(GameConfig.PLASMA), GameConfig.TRACK_SPLASH), "1.52")
	assert_eq(StatText.track_value(relay, "unknown"), "")


func test_armour_track_shows_the_armour_and_its_reduction() -> void:
	var zapper := _building(GameConfig.ZAPPER)
	assert_eq(StatText.track_value(zapper, GameConfig.TRACK_ARMOR), StatText.armor_value(Formulas.armor(zapper)))
	assert_eq(StatText.track_value(zapper, GameConfig.TRACK_ARMOR), "6 (−6%)")
	assert_eq(StatText.next_value(zapper, GameConfig.TRACK_ARMOR), "7 (−6%)")
	assert_eq(zapper.level(GameConfig.TRACK_ARMOR), 0)
	zapper.set_level(GameConfig.TRACK_ARMOR, 20)
	assert_eq(StatText.track_value(zapper, GameConfig.TRACK_ARMOR), "24 (−19%)")


func test_armor_value_rounds_armour_and_reduction() -> void:
	assert_eq(StatText.armor_value(0.0), "0 (−0%)")
	assert_eq(StatText.armor_value(6.9), "7 (−6%)")
	assert_eq(StatText.armor_value(100.0), "100 (−50%)")


func test_level_text() -> void:
	var relay := _building(GameConfig.RELAY)
	relay.set_level(GameConfig.TRACK_LINKS, 1)
	assert_eq(StatText.level_text(relay, GameConfig.TRACK_LINKS), Texts.format("PANEL_LEVEL", [1, Formulas.max_level(relay, GameConfig.TRACK_LINKS)]))


func test_stats_for_each_kind() -> void:
	var battle := BattleFixtures.battle(GameConfig.level_count() - 1)
	for kind: String in GameConfig.BUILDINGS:
		var building := Building.new(500, kind, Vector2.ZERO)
		var rows := StatText.stats(building, battle.state)
		assert_gt(rows.size(), 1, kind)
		assert_eq(rows[0][0], "STAT_HP")
	var laser := StatText.stats(_building(GameConfig.LASER), battle.state)
	assert_true(laser.any(func(row: Array) -> bool: return row[0] == "STAT_DPS"))
	assert_false(laser.any(func(row: Array) -> bool: return row[0] == "STAT_CRIT"))
	var zapper := StatText.stats(_building(GameConfig.ZAPPER), battle.state)
	assert_true(zapper.any(func(row: Array) -> bool: return row[0] == "STAT_CRIT" and row[1] == "12%"))
	var exporter := StatText.stats(_building(GameConfig.EXPORTER), battle.state)
	assert_true(exporter.any(func(row: Array) -> bool: return row[0] == "STAT_EXPORT_INCOME" and row[1] == "%.1f/s" % (8.0 / GameConfig.ENERGY_PER_COIN)))
	assert_true(exporter.any(func(row: Array) -> bool: return row[0] == "STAT_EXPORT_CYCLE" and row[1] == Texts.format("STAT_EXPORT_CYCLE_VALUE", [StatText.coins(8.0 * GameConfig.EXPORT_CYCLE / GameConfig.ENERGY_PER_COIN), int(GameConfig.EXPORT_CYCLE)])))
	var wall := StatText.stats(_building(GameConfig.BULWARK), battle.state)
	assert_true(wall.any(func(row: Array) -> bool: return row[0] == "STAT_BLOCKS"))
	assert_true(wall.any(func(row: Array) -> bool: return row[0] == "STAT_ENERGY" and row[1] == "0 / 12"))
	assert_true(wall.any(func(row: Array) -> bool: return row[0] == "STAT_REPAIR" and row[1] == "5/s"))
	assert_true(wall.any(func(row: Array) -> bool: return row[0] == "STAT_REPAIR_DRAW" and row[1] == "0.4/s"))
	assert_false(zapper.any(func(row: Array) -> bool: return row[0] == "STAT_REPAIR"))
	assert_eq(wall[0][1], "1,600 / 1,600")
	assert_eq(StatText.level_text(_building(GameConfig.BULWARK), GameConfig.TRACK_HULL), Texts.format("PANEL_LEVEL", [0, int(GameConfig.WALL_HULL.max)]))
	var high := _building(GameConfig.ZAPPER)
	high.elevation = 1
	assert_true(StatText.stats(high, battle.state).any(func(row: Array) -> bool: return row[0] == "STAT_HIGH_GROUND"))
	var nest := StatText.stats(_building(GameConfig.NEST), battle.state)
	assert_true(nest.any(func(row: Array) -> bool: return row[0] == "STAT_SPAWNS"))


func test_rover_and_garrison_rows() -> void:
	var battle := BattleFixtures.deployed(1)
	var state := battle.state
	var core := state.core()
	var rows := StatText.stats(core, state)
	assert_true(rows.any(func(row: Array) -> bool: return row[0] == "STAT_GARRISON"))
	var rover := BattleFixtures.add(battle, GameConfig.ROVER, core.position + Vector2(0, -200))
	var rover_rows := StatText.stats(rover, state)
	assert_true(rover_rows.any(func(row: Array) -> bool: return row[0] == "STAT_MOVE_ENERGY"))
	assert_false(rover_rows.any(func(row: Array) -> bool: return row[0] == "STAT_GARRISON"))


func test_energy_rows_per_tower() -> void:
	var battle := BattleFixtures.battle(GameConfig.level_count() - 1)
	var zapper := StatText.stats(_building(GameConfig.ZAPPER), battle.state)
	assert_true(zapper.any(func(row: Array) -> bool: return row[0] == "STAT_FIRE_DRAW" and row[1] == "%.1f/s" % (4.0 / 0.45)))
	assert_true(zapper.any(func(row: Array) -> bool: return row[0] == "STAT_SELF_RESERVE" and row[1] == NumberFormat.clock(4.5)))
	assert_true(zapper.any(func(row: Array) -> bool: return row[0] == "STAT_SHOTS_PER_CHARGE" and row[1] == "10"))
	var laser := StatText.stats(_building(GameConfig.LASER), battle.state)
	assert_false(laser.any(func(row: Array) -> bool: return row[0] == "STAT_FIRE_DRAW"))
	assert_false(laser.any(func(row: Array) -> bool: return row[0] == "STAT_SHOTS_PER_CHARGE"))
	assert_true(laser.any(func(row: Array) -> bool: return row[0] == "STAT_SELF_RESERVE" and row[1] == NumberFormat.clock(6.0)))
	var healer := StatText.stats(_building(GameConfig.HEALER), battle.state)
	assert_true(healer.any(func(row: Array) -> bool: return row[0] == "STAT_HEALS_PER_CHARGE" and row[1] == "13"))
	assert_true(healer.any(func(row: Array) -> bool: return row[0] == "STAT_FIRE_DRAW"))
	var relay := StatText.stats(_building(GameConfig.RELAY), battle.state)
	assert_false(relay.any(func(row: Array) -> bool: return row[0] == "STAT_FIRE_DRAW"))


func test_draw_change_preview() -> void:
	var zapper := _building(GameConfig.ZAPPER)
	var speed := StatText.draw_change(zapper, GameConfig.TRACK_SPEED)
	assert_eq(speed, Texts.format("PANEL_DRAW_CHANGE", [Icons.BOLT, 4.0 / 0.45, 4.0 / (0.45 / 1.06)]))
	assert_ne(StatText.draw_change(zapper, GameConfig.TRACK_EFFICIENCY), "")
	assert_eq(StatText.draw_change(zapper, GameConfig.TRACK_POWER), "")
	assert_eq(StatText.draw_change(_building(GameConfig.RELAY), GameConfig.TRACK_RATE), "")
	assert_eq(StatText.upgraded(zapper, GameConfig.TRACK_SPEED).level(GameConfig.TRACK_SPEED), 1)
	assert_eq(zapper.level(GameConfig.TRACK_SPEED), 0)


func _row(rows: Array[Array], key: String) -> String:
	for row in rows:
		if row[0] == key:
			return str(row[1])
	return ""


func test_lamp_fire_and_exporter_rows() -> void:
	var battle := BattleFixtures.battle(GameConfig.level_count() - 1)
	var lamp := _building(GameConfig.LAMP)
	lamp.light_radius = 4.0
	var lamp_rows := StatText.stats(lamp, battle.state)
	assert_eq(_row(lamp_rows, "STAT_LIGHT_RADIUS"), Texts.format("STAT_LIGHT_RADIUS_VALUE", [4.0]))
	assert_eq(_row(lamp_rows, "STAT_LIGHT_DRAW"), "%.1f/s" % Formulas.lamp_draw(lamp))
	assert_eq(_row(lamp_rows, "STAT_LIGHT_STATE"), Texts.t("STAT_LIGHT_OFF"))
	lamp.lit = true
	lamp.energy = Formulas.capacity(lamp) * 0.5
	assert_eq(_row(StatText.stats(lamp, battle.state), "STAT_LIGHT_STATE"), Texts.format("STAT_LIGHT_ON_VALUE", [2.0]))
	assert_eq(StatText.light_state(lamp), Texts.format("STAT_LIGHT_ON_VALUE", [Formulas.lit_reach(lamp) / GameConfig.CELL]))
	var locale := TranslationServer.get_locale()
	TranslationServer.set_locale("de")
	assert_eq(StatText.light_state(lamp), "An · 2.0 Felder")
	TranslationServer.set_locale(locale)
	lamp.lit = false
	assert_eq(StatText.light_state(lamp), Texts.t("STAT_LIGHT_OFF"))
	var fire := _building(GameConfig.FIRE)
	assert_eq(_row(StatText.stats(fire, battle.state), "STAT_FUEL"), "0")
	fire.fuel.append(Vector2i(3, 3))
	fire.fuel.append(Vector2i(4, 3))
	var fire_rows := StatText.stats(fire, battle.state)
	assert_eq(_row(fire_rows, "STAT_FUEL"), "2")
	assert_eq(_row(fire_rows, "STAT_FUEL_TIME"), NumberFormat.clock(GameConfig.FIRE_BURN_TIME * 2.0))
	assert_eq(_row(lamp_rows, "STAT_FUEL"), "")
	var exporter := _building(GameConfig.EXPORTER)
	exporter.export_buffer = Formulas.export_batch(exporter) * 0.425
	assert_eq(_row(StatText.stats(exporter, battle.state), "STAT_EXPORT_PROGRESS"), "42%")


func test_lamp_upgrades_preview_their_draw() -> void:
	var lamp := _building(GameConfig.LAMP)
	lamp.light_radius = 6.0
	var probe := StatText.upgraded(lamp, GameConfig.TRACK_EFFICIENCY)
	assert_eq(probe.light_radius, 6.0)
	assert_eq(StatText.draw_change(lamp, GameConfig.TRACK_EFFICIENCY), Texts.format("PANEL_DRAW_CHANGE", [Icons.BOLT, Formulas.lamp_draw(lamp), Formulas.lamp_draw(probe)]))
	assert_eq(StatText.draw_change(lamp, GameConfig.TRACK_HULL), "")
	var exporter := _building(GameConfig.EXPORTER)
	assert_ne(StatText.draw_change(exporter, GameConfig.TRACK_RATE), "")


func test_stats_show_armor_with_its_reduction() -> void:
	var state := BattleFixtures.battle(0, false).state
	var bulwark := Building.new(1, GameConfig.BULWARK, Vector2.ZERO)
	var rows := StatText.stats(bulwark, state)
	var found := false
	for row in rows:
		if row[0] == "STAT_ARMOR":
			found = true
			assert_string_contains(row[1], "%d" % int(Formulas.armor(bulwark)))
			assert_string_contains(row[1], "%")
	assert_true(found)
	var solar := Building.new(2, GameConfig.SOLAR, Vector2.ZERO)
	for row in StatText.stats(solar, state):
		assert_ne(row[0], "STAT_ARMOR")


func test_stats_show_the_upgraded_armour() -> void:
	var state := BattleFixtures.battle(0, false).state
	var bastion := Building.new(1, GameConfig.BASTION, Vector2.ZERO)
	bastion.set_level(GameConfig.TRACK_ARMOR, 10)
	var shown := ""
	for row in StatText.stats(bastion, state):
		if row[0] == "STAT_ARMOR":
			shown = row[1]
	assert_eq(shown, StatText.armor_value(Formulas.armor(bastion)))
	assert_eq(shown, "125 (−56%)")
