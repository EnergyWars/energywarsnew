class_name EnergyStatsText
extends RefCounted

enum Format { GAIN, DRAW, BALANCE, AMOUNT, STORED, FILL_TIME, RESERVE, PERCENT, INCOME }

const ROWS := [
	{"metric": EnergyStats.Metric.GENERATION_DAY, "key": "STATS_GENERATION_DAY", "format": Format.GAIN, "better": 1},
	{"metric": EnergyStats.Metric.GENERATION_NIGHT, "key": "STATS_GENERATION_NIGHT", "format": Format.GAIN, "better": 1},
	{"metric": EnergyStats.Metric.CAPACITY, "key": "STATS_CAPACITY", "format": Format.AMOUNT, "better": 1},
	{"metric": EnergyStats.Metric.STORED, "key": "STATS_STORED", "format": Format.STORED, "better": 1},
	{"metric": EnergyStats.Metric.FILL_TIME, "key": "STATS_FILL_TIME", "format": Format.FILL_TIME, "better": -1},
	{"metric": EnergyStats.Metric.FIRE_DRAW, "key": "STATS_FIRE_DRAW", "format": Format.DRAW, "better": 0},
	{"metric": EnergyStats.Metric.EXPORT_DRAW, "key": "STATS_EXPORT_DRAW", "format": Format.DRAW, "better": 0},
	{"metric": EnergyStats.Metric.EXPORT_INCOME, "key": "STATS_EXPORT_INCOME", "format": Format.INCOME, "better": 1},
	{"metric": EnergyStats.Metric.BEAM_LOSS, "key": "STATS_BEAM_LOSS", "format": Format.DRAW, "better": -1},
	{"metric": EnergyStats.Metric.BEAM_EFFICIENCY, "key": "STATS_BEAM_EFFICIENCY", "format": Format.PERCENT, "better": 1},
	{"metric": EnergyStats.Metric.SUPPLY_DAY, "key": "STATS_SUPPLY_DAY", "format": Format.PERCENT, "better": 1},
	{"metric": EnergyStats.Metric.SUPPLY_NIGHT, "key": "STATS_SUPPLY_NIGHT", "format": Format.PERCENT, "better": 1},
	{"metric": EnergyStats.Metric.NET_DAY, "key": "STATS_NET_DAY", "format": Format.BALANCE, "better": 1},
	{"metric": EnergyStats.Metric.NET_NIGHT, "key": "STATS_NET_NIGHT", "format": Format.BALANCE, "better": 1},
	{"metric": EnergyStats.Metric.RESERVE_DAY, "key": "STATS_RESERVE_DAY", "format": Format.RESERVE, "better": 1},
	{"metric": EnergyStats.Metric.RESERVE_NIGHT, "key": "STATS_RESERVE_NIGHT", "format": Format.RESERVE, "better": 1},
	{"metric": EnergyStats.Metric.RESERVE_FULL, "key": "STATS_RESERVE_FULL", "format": Format.RESERVE, "better": 1},
]
const RATE_STEP := 0.05
const AMOUNT_STEP := 0.5
const TIME_STEP := 0.5
const PERCENT_STEP := 0.005


static func value_text(stats: EnergyStats, row: Dictionary) -> String:
	var value := stats.value(row.metric)
	match int(row.format):
		Format.GAIN:
			return "+%.1f/s" % value
		Format.DRAW:
			return "%.1f/s" % value
		Format.PERCENT:
			return percent(value)
		Format.INCOME:
			return Texts.format("STATS_INCOME_VALUE", ["%.2f" % value])
		Format.BALANCE:
			return signed_rate(value) + "/s"
		Format.AMOUNT:
			return NumberFormat.grouped(int(round(value)))
		Format.STORED:
			return "%s (%d%%)" % [NumberFormat.grouped(int(round(value))), int(round(stats.value(EnergyStats.Metric.FILL_RATIO) * 100.0))]
		Format.FILL_TIME:
			if value <= 0.0:
				return Texts.t("STATS_FULL")
			return Texts.t("STATS_NEVER") if is_inf(value) else NumberFormat.clock(value)
	return duration(value)


static func delta_text(stats: EnergyStats, baseline: EnergyStats, row: Dictionary) -> String:
	if baseline == null:
		return ""
	var current := stats.value(row.metric)
	var before := baseline.value(row.metric)
	if is_inf(current) and is_inf(before):
		return ""
	if is_inf(current) or is_inf(before):
		return Texts.format("STATS_WAS", [value_text(baseline, row)])
	var diff := current - before
	match int(row.format):
		Format.GAIN, Format.DRAW, Format.BALANCE:
			return signed_rate(diff) if absf(diff) >= RATE_STEP else ""
		Format.INCOME:
			return ("−%.2f" % absf(diff) if diff < 0.0 else "+%.2f" % diff) if absf(diff) >= RATE_STEP * 0.1 else ""
		Format.PERCENT:
			return signed_percent(diff) if absf(diff) >= PERCENT_STEP else ""
		Format.AMOUNT, Format.STORED:
			return signed_amount(diff) if absf(diff) >= AMOUNT_STEP else ""
	if absf(diff) < TIME_STEP:
		return ""
	if current <= 0.0 or before <= 0.0:
		return Texts.format("STATS_WAS", [value_text(baseline, row)])
	return ("+" if diff > 0.0 else "−") + NumberFormat.clock(absf(diff))


static func trend(stats: EnergyStats, baseline: EnergyStats, row: Dictionary) -> int:
	if delta_text(stats, baseline, row).is_empty():
		return 0
	var diff := stats.value(row.metric) - baseline.value(row.metric)
	return int(signf(diff)) * int(row.better)


static func signed_rate(value: float) -> String:
	return ("−%.1f" % absf(value)) if value < 0.0 else ("+%.1f" % value)


static func signed_amount(value: float) -> String:
	var amount := int(round(absf(value)))
	return ("−%d" % amount) if value < 0.0 else ("+%d" % amount)


static func percent(ratio: float) -> String:
	return "%d%%" % int(round(ratio * 100.0))


static func signed_percent(ratio: float) -> String:
	var points := int(round(absf(ratio) * 100.0))
	return ("−%d%%" % points) if ratio < 0.0 else ("+%d%%" % points)


static func duration(seconds: float) -> String:
	return Texts.t("STATS_ENDLESS") if is_inf(seconds) else NumberFormat.clock(seconds)
