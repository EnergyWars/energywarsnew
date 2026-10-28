extends GutTest


func after_all() -> void:
	TranslationServer.set_locale("en")


func before_each() -> void:
	TranslationServer.set_locale("en")


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


func test_every_metric_row_is_translated() -> void:
	for locale in ["en", "de"]:
		TranslationServer.set_locale(locale)
		for row: Dictionary in EnergyStatsText.ROWS:
			assert_ne(Texts.t(row.key), row.key, "%s %s" % [locale, row.key])
		for key in ["STATS_TITLE", "STATS_ENDLESS", "STATS_NEVER", "STATS_FULL", "STATS_WAS", "STATS_NOTE", "TOAST_UNDO", "TOAST_RESET",
				"RESET_TITLE", "RESET_TEXT", "RESET_CONFIRM", "DIALOG_CANCEL", "STAT_FIRE_DRAW", "STAT_SELF_RESERVE",
				"STAT_SHOTS_PER_CHARGE", "STAT_HEALS_PER_CHARGE", "PANEL_DRAW_CHANGE"]:
			assert_ne(Texts.t(key), key, "%s %s" % [locale, key])
	TranslationServer.set_locale("de")
	assert_eq(Texts.t("STATS_TITLE"), "Energiebilanz")
	assert_eq(Texts.t("RESET_TITLE"), "Planung zurücksetzen?")


func test_value_formats() -> void:
	var stats := _stats({
		EnergyStats.Metric.GENERATION_DAY: 11.0,
		EnergyStats.Metric.CAPACITY: 1330.0,
		EnergyStats.Metric.STORED: 665.0,
		EnergyStats.Metric.FILL_RATIO: 0.5,
		EnergyStats.Metric.FILL_TIME: 75.0,
		EnergyStats.Metric.FIRE_DRAW: 12.3,
		EnergyStats.Metric.NET_DAY: -4.0,
		EnergyStats.Metric.NET_NIGHT: 2.0,
		EnergyStats.Metric.RESERVE_DAY: INF,
		EnergyStats.Metric.RESERVE_NIGHT: 125.0,
	})
	assert_eq(EnergyStatsText.value_text(stats, _row(EnergyStats.Metric.GENERATION_DAY)), "+11.0/s")
	assert_eq(EnergyStatsText.value_text(stats, _row(EnergyStats.Metric.CAPACITY)), "1,330")
	assert_eq(EnergyStatsText.value_text(stats, _row(EnergyStats.Metric.STORED)), "665 (50%)")
	assert_eq(EnergyStatsText.value_text(stats, _row(EnergyStats.Metric.FILL_TIME)), "1:15")
	assert_eq(EnergyStatsText.value_text(stats, _row(EnergyStats.Metric.FIRE_DRAW)), "12.3/s")
	assert_eq(EnergyStatsText.value_text(stats, _row(EnergyStats.Metric.NET_DAY)), "−4.0/s")
	assert_eq(EnergyStatsText.value_text(stats, _row(EnergyStats.Metric.NET_NIGHT)), "+2.0/s")
	assert_eq(EnergyStatsText.value_text(stats, _row(EnergyStats.Metric.RESERVE_DAY)), Texts.t("STATS_ENDLESS"))
	assert_eq(EnergyStatsText.value_text(stats, _row(EnergyStats.Metric.RESERVE_NIGHT)), "2:05")


func test_fill_time_states() -> void:
	var row := _row(EnergyStats.Metric.FILL_TIME)
	assert_eq(EnergyStatsText.value_text(_stats({EnergyStats.Metric.FILL_TIME: 0.0}), row), Texts.t("STATS_FULL"))
	assert_eq(EnergyStatsText.value_text(_stats({EnergyStats.Metric.FILL_TIME: INF}), row), Texts.t("STATS_NEVER"))


func test_deltas_for_rates_amounts_and_times() -> void:
	var before := _stats({EnergyStats.Metric.GENERATION_DAY: 3.0, EnergyStats.Metric.CAPACITY: 300.0, EnergyStats.Metric.RESERVE_NIGHT: 60.0, EnergyStats.Metric.NET_DAY: 1.0})
	var after := _stats({EnergyStats.Metric.GENERATION_DAY: 11.0, EnergyStats.Metric.CAPACITY: 270.0, EnergyStats.Metric.RESERVE_NIGHT: 45.0, EnergyStats.Metric.NET_DAY: 1.02})
	var gen := _row(EnergyStats.Metric.GENERATION_DAY)
	var capacity := _row(EnergyStats.Metric.CAPACITY)
	var reserve := _row(EnergyStats.Metric.RESERVE_NIGHT)
	var net := _row(EnergyStats.Metric.NET_DAY)
	assert_eq(EnergyStatsText.delta_text(after, before, gen), "+8.0")
	assert_eq(EnergyStatsText.trend(after, before, gen), 1)
	assert_eq(EnergyStatsText.delta_text(after, before, capacity), "−30")
	assert_eq(EnergyStatsText.trend(after, before, capacity), -1)
	assert_eq(EnergyStatsText.delta_text(after, before, reserve), "−0:15")
	assert_eq(EnergyStatsText.trend(after, before, reserve), -1)
	assert_eq(EnergyStatsText.delta_text(before, after, reserve), "+0:15")
	assert_eq(EnergyStatsText.delta_text(after, before, net), "")
	assert_eq(EnergyStatsText.trend(after, before, net), 0)
	assert_eq(EnergyStatsText.delta_text(after, null, gen), "")


func test_deltas_with_unlimited_or_full_values() -> void:
	var reserve := _row(EnergyStats.Metric.RESERVE_DAY)
	var endless := _stats({EnergyStats.Metric.RESERVE_DAY: INF, EnergyStats.Metric.FILL_TIME: 0.0})
	var finite := _stats({EnergyStats.Metric.RESERVE_DAY: 30.0, EnergyStats.Metric.FILL_TIME: 40.0})
	assert_eq(EnergyStatsText.delta_text(endless, endless, reserve), "")
	assert_eq(EnergyStatsText.delta_text(endless, finite, reserve), Texts.format("STATS_WAS", ["0:30"]))
	assert_eq(EnergyStatsText.trend(endless, finite, reserve), 1)
	assert_eq(EnergyStatsText.delta_text(finite, endless, reserve), Texts.format("STATS_WAS", [Texts.t("STATS_ENDLESS")]))
	assert_eq(EnergyStatsText.trend(finite, endless, reserve), -1)
	var fill := _row(EnergyStats.Metric.FILL_TIME)
	assert_eq(EnergyStatsText.delta_text(endless, finite, fill), Texts.format("STATS_WAS", ["0:40"]))
	assert_eq(EnergyStatsText.trend(endless, finite, fill), 1)
	assert_eq(EnergyStatsText.trend(finite, endless, fill), -1)


func test_neutral_rows_never_color() -> void:
	var draw := _row(EnergyStats.Metric.FIRE_DRAW)
	var low := _stats({EnergyStats.Metric.FIRE_DRAW: 4.0})
	var high := _stats({EnergyStats.Metric.FIRE_DRAW: 9.0})
	assert_eq(EnergyStatsText.delta_text(high, low, draw), "+5.0")
	assert_eq(EnergyStatsText.trend(high, low, draw), 0)


func test_helpers() -> void:
	assert_eq(EnergyStatsText.signed_rate(2.26), "+2.3")
	assert_eq(EnergyStatsText.signed_amount(-4.4), "−4")
	assert_eq(EnergyStatsText.signed_amount(7.0), "+7")
	assert_eq(EnergyStatsText.signed_rate(-1.0), "−1.0")
	assert_eq(EnergyStatsText.signed_rate(0.0), "+0.0")
	assert_eq(EnergyStatsText.duration(INF), Texts.t("STATS_ENDLESS"))
	assert_eq(EnergyStatsText.duration(61.0), "1:01")
