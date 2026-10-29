extends GutTest

var battle: Battle
var state: BattleState
var core: Building


func before_each() -> void:
	TranslationServer.set_locale("en")
	battle = BattleFixtures.battle(0, false)
	state = battle.state
	core = state.core()


func after_all() -> void:
	TranslationServer.set_locale("en")


func _add(kind: String, position: Vector2) -> Building:
	return BattleFixtures.add(battle, kind, position)


func _stats(values: Dictionary) -> EnergyStats:
	var stats := EnergyStats.new()
	for metric: int in values:
		stats.values[metric] = values[metric]
	return stats


func _row(metric: EnergyStats.Metric) -> Dictionary:
	for row: Dictionary in EnergyStatsText.ROWS:
		if row.metric == metric:
			return row
	return {}


func test_every_verdict_has_icon_colour_and_translated_title() -> void:
	for locale in ["en", "de"]:
		TranslationServer.set_locale(locale)
		for verdict in StatusText.LEGEND:
			assert_true(StatusText.has_style(verdict))
			assert_ne(StatusText.icon(verdict), "")
			assert_ne(StatusText.title(verdict), StatusText.STYLES[verdict].key, "%s %d" % [locale, verdict])
		for key: String in StatusText.CAUSE_KEYS.values():
			assert_ne(Texts.t(key), key, "%s %s" % [locale, key])
		for key in ["STATUS_UNKNOWN", "STATUS_SUMMARY", "STATUS_LINK_RANGE", "STATUS_LINK_OUT", "STATUS_WHEN_DAY", "STATUS_WHEN_NIGHT", "TOAST_STATUS_ON", "TOAST_STATUS_OFF", "TOAST_GUARDS",
				"TOAST_GUARDS_BURN", "TOAST_OVERLOADED", "PANEL_SELL_FULL", "PANEL_SELL_LOSS", "PANEL_OVERLOAD_NEXT", "PANEL_OVERLOAD_FIXED",
				"STAT_BEAM_LOSS", "STAT_EXPORT_RATIO", "STAT_EXPORT_CYCLE", "STAT_EXPORT_CYCLE_VALUE", "STAT_EXPORT_ROUND", "STAT_NEED",
				"STAT_SUPPLY_DAY", "STAT_SUPPLY_NIGHT", "STAT_NIGHT_RESERVE", "STAT_EXPORT_REAL", "STAT_FLOW", "STATS_INCOME_VALUE"]:
			assert_ne(Texts.t(key), key, "%s %s" % [locale, key])
	TranslationServer.set_locale("de")
	assert_eq(StatusText.title(EnergyAudit.Verdict.OVERLOADED), "Überladen")
	assert_eq(StatusText.when(EnergyAudit.NIGHT), "nachts")
	assert_eq(StatusText.when(EnergyAudit.WORST), "")
	assert_eq(StatusText.LEGEND, [EnergyAudit.Verdict.OK, EnergyAudit.Verdict.LOW, EnergyAudit.Verdict.OVERLOADED] as Array[int])
	assert_eq(StatusText.icon(EnergyAudit.Verdict.OK), Icons.CHECK)
	assert_eq(StatusText.icon(EnergyAudit.Verdict.LOW), Icons.WARNING)
	assert_eq(StatusText.color(EnergyAudit.Verdict.OK), AppTheme.SUCCESS)
	assert_eq(StatusText.color(EnergyAudit.Verdict.LOW), AppTheme.WARNING)
	assert_eq(Texts.track_name(GameConfig.TRACK_TRANSFER, GameConfig.RELAY), "Strahlübertragung")
	assert_eq(StatusText.icon(EnergyAudit.Verdict.NONE), "")
	assert_eq(StatusText.title(EnergyAudit.Verdict.NONE), "")
	assert_eq(StatusText.color(EnergyAudit.Verdict.NONE), AppTheme.ON_SURFACE_VARIANT)
	assert_false(StatusText.has_style(EnergyAudit.Verdict.NONE))


func test_building_labels_show_energy_per_shot_and_per_second() -> void:
	var audit := battle.audit()
	var zapper := Building.new(500, GameConfig.ZAPPER, Vector2.ZERO)
	assert_eq(StatusText.label(zapper, audit), Texts.format("STATUS_LABEL_SHOT", ["4.0", "%.1f/s" % (4.0 / 0.45)]))
	var laser := Building.new(501, GameConfig.LASER, Vector2.ZERO)
	assert_eq(StatusText.label(laser, audit), Texts.format("STATUS_LABEL_BEAM", ["10.0/s"]))
	var healer := Building.new(502, GameConfig.HEALER, Vector2.ZERO)
	assert_eq(StatusText.label(healer, audit), Texts.format("STATUS_LABEL_HEAL", ["6.0", "%.1f/s" % (6.0 / 0.9)]))
	var exporter := Building.new(503, GameConfig.EXPORTER, Vector2.ZERO)
	assert_eq(StatusText.label(exporter, audit), Texts.format("STATUS_LABEL_EXPORT", ["8.0/s", "%.2f" % (8.0 / GameConfig.ENERGY_PER_COIN)]))
	var solar := Building.new(504, GameConfig.SOLAR, Vector2.ZERO)
	assert_eq(StatusText.label(solar, audit), Texts.format("STATUS_LABEL_OUTPUT", ["8.0/s"]))
	assert_eq(StatusText.label(Building.new(505, GameConfig.RELAY, Vector2.ZERO), audit), "")
	zapper.set_level(GameConfig.TRACK_OVERCLOCK, 11)
	assert_eq(StatusText.label(zapper, audit), Texts.format("STATUS_LABEL_OVERLOAD", ["%.1f" % Formulas.action_energy(zapper), "40.0"]))


func test_labels_never_show_percentages_but_relay_throughput() -> void:
	var label := StatusText.label(core, battle.audit())
	assert_eq(label, Texts.format("STATUS_LABEL_SHOT", ["3.0", "%.1f/s" % (3.0 / 0.7)]))
	assert_false(label.contains("%"))
	core.set_level(GameConfig.TRACK_OUTPUT, 30)
	var relay := _add(GameConfig.RELAY, core.position + Vector2(0, -224))
	var zapper := _add(GameConfig.ZAPPER, relay.position + Vector2(0, -112))
	battle.network.connect_buildings(core.id, relay.id)
	battle.network.connect_buildings(relay.id, zapper.id)
	var audit := battle.audit()
	assert_eq(StatusText.label(relay, audit), Texts.format("STATUS_LABEL_RELAY", ["%.1f/s" % audit.throughput(relay.id)]))
	assert_eq(StatusText.label(relay, audit, EnergyAudit.NIGHT), Texts.format("STATUS_LABEL_RELAY", ["%.1f/s" % audit.throughput(relay.id, EnergyAudit.NIGHT)]))
	assert_false(StatusText.label(zapper, audit).contains("%"))


func test_link_labels_show_the_rate_and_only_outgoing_beams_the_loss() -> void:
	core.set_level(GameConfig.TRACK_OUTPUT, 30)
	var zapper := _add(GameConfig.ZAPPER, core.position + Vector2(0, -168))
	var near := _add(GameConfig.ZAPPER, core.position + Vector2(84, 28))
	battle.network.connect_buildings(core.id, zapper.id)
	battle.network.connect_buildings(core.id, near.id)
	var link := state.find_link(core.id, zapper.id)
	var key := link.key()
	var touching := state.find_link(core.id, near.id).key()
	var audit := battle.audit()
	var loss := EnergyStatsText.percent(audit.link_loss(key))
	assert_gt(audit.link_loss(key), 0.0)
	assert_eq(StatusText.link_label(audit, key, false), "%.1f/s" % audit.delivered(key))
	assert_eq(StatusText.link_label(audit, key, true), Texts.format("STATUS_LINK_OUT", ["%.1f/s" % audit.flow(key), loss]))
	assert_eq(StatusText.link_label(audit, key, true), "%.1f/s (−%s)" % [audit.flow(key), loss])
	assert_eq(StatusText.link_label(audit, touching, true), "%.1f/s (−0%%)" % audit.flow(touching))
	assert_eq(StatusText.link_label(audit, touching, false), "%.1f/s" % audit.delivered(touching))
	assert_eq(StatusText.link_label(audit, key, false, EnergyAudit.NIGHT), "%.1f/s" % audit.delivered(key, EnergyAudit.NIGHT))
	assert_false(StatusText.link_label(audit, key, false).contains("%"))
	assert_eq(StatusText.link_color(audit, key), AppTheme.ENERGY)
	assert_eq(StatusText.link_color(audit, touching), AppTheme.ENERGY)
	TranslationServer.set_locale("de")
	assert_eq(StatusText.link_label(audit, key, true), "%.1f/s (−%s)" % [audit.flow(key), loss])
	TranslationServer.set_locale("en")
	state.move_building(zapper, core.position + Vector2(0, -600))
	var broken := battle.audit()
	assert_eq(StatusText.link_label(broken, key, true), Texts.t("STATUS_LINK_RANGE"))
	assert_eq(StatusText.link_label(broken, key, false), Texts.t("STATUS_LINK_RANGE"))
	assert_eq(StatusText.link_color(broken, key), AppTheme.DANGER)


func test_saturated_and_lossy_links_are_coloured() -> void:
	var solar := _add(GameConfig.SOLAR, core.position + Vector2(-336, -336))
	var exporter := _add(GameConfig.EXPORTER, solar.position + Vector2(168, 0))
	battle.network.connect_buildings(solar.id, exporter.id)
	var audit := battle.audit()
	var key := state.find_link(solar.id, exporter.id).key()
	assert_eq(StatusText.link_color(audit, key, EnergyAudit.DAY), AppTheme.WARNING)
	assert_eq(StatusText.cause_text(audit, exporter, state, EnergyAudit.DAY), Texts.format("STATUS_CAUSE_BEAM_RATE", [Texts.building_name(GameConfig.SOLAR)]))
	assert_eq(StatusText.cause_text(audit, exporter, state), Texts.t("STATUS_CAUSE_NIGHT"))
	core.set_level(GameConfig.TRACK_OUTPUT, 20)
	var relay := _add(GameConfig.RELAY, core.position + Vector2(0, -168))
	relay.set_level(GameConfig.TRACK_RANGE, 15)
	var hub := _add(GameConfig.RELAY, relay.position + Vector2(504, 0))
	for spot in [Vector2(0, -112), Vector2(0, 112), Vector2(112, 0)]:
		battle.network.connect_buildings(hub.id, _add(GameConfig.ZAPPER, hub.position + spot).id)
	battle.network.connect_buildings(core.id, relay.id)
	battle.network.connect_buildings(relay.id, hub.id)
	var lossy := battle.audit()
	var lossy_key := state.find_link(relay.id, hub.id).key()
	assert_eq(StatusText.link_color(lossy, lossy_key), AppTheme.PLASMA_ORANGE)
	var loss := EnergyStatsText.percent(1.0 - lossy.link_yield(lossy_key))
	assert_eq(StatusText.cause_text(lossy, hub, state), Texts.format("STATUS_CAUSE_BEAM_LOSS", [Texts.building_name(GameConfig.RELAY), loss]))


func test_cause_texts() -> void:
	var lonely := _add(GameConfig.ZAPPER, core.position + Vector2(400, 0))
	var audit := battle.audit()
	assert_eq(StatusText.cause_text(audit, lonely, state), Texts.t("STATUS_CAUSE_NO_SOURCE"))
	assert_eq(StatusText.cause_text(audit, core, state), "")
	var tower := _add(GameConfig.ZAPPER, core.position + Vector2(0, -168))
	battle.network.connect_buildings(core.id, tower.id)
	tower.set_level(GameConfig.TRACK_OVERCLOCK, 11)
	state.mark_changed()
	audit = battle.audit()
	assert_eq(StatusText.cause_text(audit, tower, state), Texts.format("STATUS_CAUSE_OVERLOAD", ["%.1f" % Formulas.action_energy(tower), "40.0"]))
	state.move_building(tower, core.position + Vector2(0, -600))
	audit = battle.audit()
	assert_eq(audit.cause(tower.id), EnergyAudit.Cause.OVERLOAD)
	tower.set_level(GameConfig.TRACK_OVERCLOCK, 0)
	state.mark_changed()
	audit = battle.audit()
	assert_eq(StatusText.cause_text(audit, tower, state), Texts.format("STATUS_CAUSE_OUT_OF_RANGE", [Texts.building_name(GameConfig.CORE)]))
	assert_eq(StatusText.cause_text(audit, _add(GameConfig.BULWARK, core.position + Vector2(-400, 0)), state), "")


func test_storage_cause_summary_and_rows() -> void:
	var battery := _add(GameConfig.BATTERY, core.position + Vector2(0, -476))
	var solar := _add(GameConfig.SOLAR, battery.position + Vector2(-112, 0))
	var other := _add(GameConfig.SOLAR, battery.position + Vector2(112, 0))
	var zapper := _add(GameConfig.ZAPPER, battery.position + Vector2(0, -112))
	battle.network.connect_buildings(solar.id, battery.id)
	battle.network.connect_buildings(other.id, battery.id)
	battle.network.connect_buildings(battery.id, zapper.id)
	var audit := battle.audit()
	var lasts := EnergyStatsText.duration(audit.night_reserve(battery.id))
	assert_eq(StatusText.cause_text(audit, battery, state), Texts.format("STATUS_CAUSE_STORAGE", [Texts.building_name(GameConfig.BATTERY), lasts]))
	assert_eq(StatusText.cause_text(audit, zapper, state), "")
	var shortfall := "%.1f/s" % audit.shortfall(battery.id)
	assert_eq(StatusText.summary(audit, battery), Texts.format("STATUS_SUMMARY", [Texts.t("STATUS_LOW"), Texts.t("STATUS_WHEN_NIGHT"), shortfall]))
	assert_false(StatusText.summary(audit, battery).contains("%"))
	assert_eq(StatusText.summary(audit, battery, EnergyAudit.DAY), Texts.t("STATUS_OK"))
	assert_eq(StatusText.summary(audit, zapper), Texts.t("STATUS_OK"))
	assert_eq(StatusText.summary(audit, solar), "")
	assert_eq(StatusText.supply_value(audit, battery.id, EnergyAudit.DAY), "%s %.1f/s" % [Icons.CHECK, audit.need_of(battery.id)])
	assert_eq(StatusText.supply_value(audit, battery.id, EnergyAudit.NIGHT), "%s %.1f/s" % [Icons.WARNING, audit.supply(battery.id, EnergyAudit.NIGHT)])
	assert_eq(StatusText.supply_value(audit, zapper.id, EnergyAudit.NIGHT), "%s %.1f/s" % [Icons.CHECK, 4.0 / 0.45])
	var rows := StatText.status_rows(battery, audit)
	var keys: Array = rows.map(func(row: Array) -> String: return row[0])
	assert_eq(keys, ["STAT_NEED", "STAT_SUPPLY_DAY", "STAT_SUPPLY_NIGHT", "STAT_NIGHT_RESERVE", "STAT_FLOW"])
	assert_eq(rows[0][1], "%.1f/s" % audit.need_of(battery.id))
	assert_eq(rows[3][1], lasts)


func test_solar_only_supply_names_the_night() -> void:
	var zapper := _add(GameConfig.ZAPPER, core.position + Vector2(0, -476))
	var left := _add(GameConfig.SOLAR, zapper.position + Vector2(-112, 0))
	var right := _add(GameConfig.SOLAR, zapper.position + Vector2(112, 0))
	battle.network.connect_buildings(left.id, zapper.id)
	battle.network.connect_buildings(right.id, zapper.id)
	var audit := battle.audit()
	assert_eq(StatusText.cause_text(audit, zapper, state), Texts.t("STATUS_CAUSE_NIGHT"))
	assert_eq(StatusText.cause_text(audit, zapper, state, EnergyAudit.DAY), "")


func test_unsupplied_building_without_need_has_a_plain_summary() -> void:
	var relay := _add(GameConfig.RELAY, core.position + Vector2(0, -224))
	var audit := battle.audit()
	assert_eq(StatusText.summary(audit, relay), Texts.t("STATUS_LOW"))


func test_culprit_name_falls_back() -> void:
	var audit := battle.audit()
	assert_eq(StatusText.culprit_name(audit, core, state), Texts.t("STATUS_UNKNOWN"))


func test_percent_and_income_formats() -> void:
	assert_eq(EnergyStatsText.percent(0.5), "50%")
	assert_eq(EnergyStatsText.percent(1.0), "100%")
	assert_eq(EnergyStatsText.signed_percent(-0.034), "−3%")
	assert_eq(EnergyStatsText.signed_percent(0.12), "+12%")
	var stats := _stats({
		EnergyStats.Metric.BEAM_LOSS: 1.26,
		EnergyStats.Metric.BEAM_EFFICIENCY: 0.9,
		EnergyStats.Metric.SUPPLY_DAY: 0.75,
		EnergyStats.Metric.EXPORT_INCOME: 1.5,
	})
	assert_eq(EnergyStatsText.value_text(stats, _row(EnergyStats.Metric.BEAM_LOSS)), "1.3/s")
	assert_eq(EnergyStatsText.value_text(stats, _row(EnergyStats.Metric.BEAM_EFFICIENCY)), "90%")
	assert_eq(EnergyStatsText.value_text(stats, _row(EnergyStats.Metric.SUPPLY_DAY)), "75%")
	assert_eq(EnergyStatsText.value_text(stats, _row(EnergyStats.Metric.EXPORT_INCOME)), Texts.format("STATS_INCOME_VALUE", ["1.50"]))
	var before := _stats({EnergyStats.Metric.SUPPLY_DAY: 0.5, EnergyStats.Metric.BEAM_LOSS: 1.0, EnergyStats.Metric.EXPORT_INCOME: 2.0})
	var supply := _row(EnergyStats.Metric.SUPPLY_DAY)
	var loss := _row(EnergyStats.Metric.BEAM_LOSS)
	var income := _row(EnergyStats.Metric.EXPORT_INCOME)
	assert_eq(EnergyStatsText.delta_text(stats, before, supply), "+25%")
	assert_eq(EnergyStatsText.trend(stats, before, supply), 1)
	assert_eq(EnergyStatsText.delta_text(stats, before, loss), "+0.3")
	assert_eq(EnergyStatsText.trend(stats, before, loss), -1)
	assert_eq(EnergyStatsText.delta_text(stats, before, income), "−0.50")
	assert_eq(EnergyStatsText.trend(stats, before, income), -1)
	assert_eq(EnergyStatsText.delta_text(stats, stats, supply), "")


func test_energy_stats_include_beam_losses() -> void:
	core.set_level(GameConfig.TRACK_OUTPUT, 30)
	var zapper := _add(GameConfig.ZAPPER, core.position + Vector2(0, -168))
	battle.network.connect_buildings(core.id, zapper.id)
	var audit := battle.audit()
	var stats := EnergyStats.measure(state, audit)
	var fire := 3.0 / 0.7 + 4.0 / 0.45
	assert_almost_eq(stats.value(EnergyStats.Metric.BEAM_LOSS), audit.loss_rate(), 0.0001)
	assert_gt(stats.value(EnergyStats.Metric.BEAM_LOSS), 0.0)
	assert_almost_eq(stats.value(EnergyStats.Metric.NET_DAY), 12.0 - fire - audit.loss_rate(), 0.001)
	assert_almost_eq(stats.value(EnergyStats.Metric.BEAM_EFFICIENCY), audit.transfer_efficiency(), 0.0001)
	assert_almost_eq(stats.value(EnergyStats.Metric.SUPPLY_DAY), audit.supply_ratio(), 0.0001)
	assert_almost_eq(stats.value(EnergyStats.Metric.SUPPLY_NIGHT), audit.supply_ratio(EnergyAudit.NIGHT), 0.0001)
	assert_eq(stats.value(EnergyStats.Metric.EXPORT_INCOME), 0.0)
	assert_almost_eq(EnergyStats.measure(state).value(EnergyStats.Metric.BEAM_LOSS), audit.loss_rate(), 0.0001)


func test_transfer_track_and_beam_rows() -> void:
	var relay := Building.new(1, GameConfig.RELAY, Vector2.ZERO)
	assert_eq(StatText.track_value(relay, GameConfig.TRACK_TRANSFER), Texts.format("STAT_TRANSFER_VALUE", [2.5]))
	var better := StatText.upgraded(relay, GameConfig.TRACK_TRANSFER)
	assert_almost_eq(StatText.loss_per_cell(better), GameConfig.BEAM_LOSS_PER_CELL * 0.9, 0.0001)
	assert_eq(StatText.next_value(relay, GameConfig.TRACK_TRANSFER), Texts.format("STAT_TRANSFER_VALUE", [StatText.loss_per_cell(better) * 100.0]))
	assert_almost_eq(StatText.loss_per_cell(relay), GameConfig.BEAM_LOSS_PER_CELL, 0.0001)
	var rows := StatText.stats(relay, state)
	var expected := "−%d%%" % int(round(StatText.range_loss(relay) * 100.0))
	assert_true(rows.any(func(row: Array) -> bool: return row[0] == "STAT_BEAM_LOSS" and row[1] == expected))
	assert_lt(StatText.range_loss(relay), Formulas.beam_loss(relay, Formulas.link_range(relay)))
	var exporter := StatText.stats(Building.new(2, GameConfig.EXPORTER, Vector2.ZERO), state)
	assert_true(exporter.any(func(row: Array) -> bool: return row[0] == "STAT_EXPORT_RATIO" and row[1] == Texts.format("STAT_EXPORT_RATIO_VALUE", [GameConfig.ENERGY_PER_COIN])))
	var per_day := "+%d" % int(round(8.0 / GameConfig.ENERGY_PER_COIN * DayCycle.length(state.level)))
	assert_true(exporter.any(func(row: Array) -> bool: return row[0] == "STAT_EXPORT_ROUND" and row[1] == per_day))
	for kind in [GameConfig.CORE, GameConfig.SOLAR, GameConfig.RELAY, GameConfig.BATTERY, GameConfig.ZAPPER, GameConfig.EXPORTER]:
		assert_true(GameConfig.building(kind).tracks.has(GameConfig.TRACK_TRANSFER), kind)
	assert_eq(StatText.coins(5.0), "5")
	assert_eq(StatText.coins(6.2), "6.20")


func test_status_rows_follow_the_audit() -> void:
	var solar := _add(GameConfig.SOLAR, core.position + Vector2(-336, -336))
	var exporter := _add(GameConfig.EXPORTER, solar.position + Vector2(112, 0))
	battle.network.connect_buildings(solar.id, exporter.id)
	var audit := battle.audit()
	var rows := StatText.status_rows(exporter, audit)
	var keys: Array = rows.map(func(row: Array) -> String: return row[0])
	assert_eq(keys, ["STAT_NEED", "STAT_SUPPLY_DAY", "STAT_SUPPLY_NIGHT", "STAT_EXPORT_REAL", "STAT_FLOW"])
	assert_eq(rows[0][1], "8.0/s")
	assert_eq(rows[1][1], StatusText.supply_value(audit, exporter.id, EnergyAudit.DAY))
	assert_eq(rows[2][1], "%s 0.0/s" % Icons.WARNING)
	assert_eq(rows[3][1], Texts.format("STAT_EXPORT_REAL_VALUE", ["%.2f" % audit.export_income(), "0.00"]))
	assert_eq(rows[4][1], Texts.format("STAT_FLOW_VALUE", [audit.inflow(exporter.id), audit.throughput(exporter.id)]))
	var day_rows := StatText.status_rows(exporter, audit, EnergyAudit.DAY)
	assert_eq(day_rows[4][1], Texts.format("STAT_FLOW_VALUE", [audit.inflow(exporter.id, EnergyAudit.DAY), 0.0]))
	var solar_rows := StatText.status_rows(solar, audit)
	assert_eq(solar_rows.size(), 1)
	assert_eq(solar_rows[0][0], "STAT_FLOW")
	assert_true(StatText.status_rows(exporter, null).is_empty())
	assert_true(StatText.status_rows(_add(GameConfig.BULWARK, core.position + Vector2(300, 300)), audit).is_empty())


func test_sell_text_shows_refund_or_loss() -> void:
	var battery := Building.new(1, GameConfig.BATTERY, Vector2.ZERO)
	battery.spent = 80
	battery.plan_spent = 80
	assert_true(Formulas.is_fresh(battery))
	assert_eq(Formulas.sell_loss(battery), 0)
	assert_eq(BuildingPanel.sell_text(battery, true), Texts.format("PANEL_SELL_FULL", [80]))
	battery.plan_spent = 0
	assert_false(Formulas.is_fresh(battery))
	assert_eq(Formulas.sell_loss(battery), 40)
	assert_eq(BuildingPanel.sell_text(battery, true), Texts.format("PANEL_SELL_LOSS", [40, 40]))
	battery.plan_spent = 30
	assert_false(Formulas.is_fresh(battery))
	assert_eq(BuildingPanel.sell_text(battery, true), Texts.format("PANEL_SELL_LOSS", [55, 25]))
	var free := Building.new(2, GameConfig.BATTERY, Vector2.ZERO)
	free.spent = 0
	assert_eq(BuildingPanel.sell_text(free, false), Texts.format("PANEL_SELL", [0]))


func test_only_this_planning_is_refunded_in_full() -> void:
	assert_eq(battle.place(GameConfig.BATTERY, core.position + Vector2(168, 0)), BuildRules.OK)
	var fresh: Building = state.of_kind(GameConfig.BATTERY)[0]
	assert_true(Formulas.is_fresh(fresh))
	assert_eq(Formulas.sell_value(fresh), fresh.spent)
	battle.start_round()
	assert_false(Formulas.is_fresh(fresh))
	assert_lt(Formulas.sell_value(fresh), fresh.spent)
	state.money = 1000
	assert_eq(battle.place(GameConfig.BATTERY, core.position + Vector2(-168, 0)), BuildRules.OK)
	var during_fight: Building = state.of_kind(GameConfig.BATTERY)[1]
	assert_false(Formulas.is_fresh(during_fight))
	assert_eq(Formulas.sell_value(during_fight), int(floor(during_fight.spent * GameConfig.SELL_REFUND)))
