class_name EnergyStats
extends RefCounted

enum Metric {
	GENERATION_DAY,
	GENERATION_NIGHT,
	CAPACITY,
	STORED,
	FILL_RATIO,
	FILL_TIME,
	FIRE_DRAW,
	EXPORT_DRAW,
	NET_DAY,
	NET_NIGHT,
	RESERVE_DAY,
	RESERVE_NIGHT,
	RESERVE_FULL,
	BEAM_LOSS,
	BEAM_EFFICIENCY,
	SUPPLY_DAY,
	SUPPLY_NIGHT,
	EXPORT_INCOME,
	COUNT,
}

const FULL_EPSILON := 0.01

var values := PackedFloat64Array()


func _init() -> void:
	values.resize(Metric.COUNT)


func value(metric: Metric) -> float:
	return values[metric]


static func measure(state: BattleState, audit: EnergyAudit = null) -> EnergyStats:
	if audit == null:
		audit = EnergyAudit.measure(state)
	var stats := EnergyStats.new()
	var day := 0.0
	var night := 0.0
	for building in state.producers():
		var amount := Formulas.output(building)
		day += amount
		if not building.definition().get("solar", false):
			night += amount
	var fire := 0.0
	for building in state.combatants():
		if building.is_player():
			fire += fire_draw(building)
	var exported := 0.0
	for building in state.of_kind(GameConfig.EXPORTER):
		exported += Formulas.export_rate(building)
	var capacity := state.storage_capacity()
	var stored := minf(state.stored_energy(), capacity)
	var missing := capacity - stored
	var loss_day := audit.loss_rate(EnergyAudit.DAY)
	var loss_night := audit.loss_rate(EnergyAudit.NIGHT)
	stats.values[Metric.GENERATION_DAY] = day
	stats.values[Metric.GENERATION_NIGHT] = night
	stats.values[Metric.CAPACITY] = capacity
	stats.values[Metric.STORED] = stored
	stats.values[Metric.FILL_RATIO] = stored / capacity if capacity > 0.0 else 0.0
	stats.values[Metric.FILL_TIME] = 0.0 if missing <= FULL_EPSILON else drain_time(missing, day - exported)
	stats.values[Metric.FIRE_DRAW] = fire
	stats.values[Metric.EXPORT_DRAW] = exported
	stats.values[Metric.NET_DAY] = day - exported - fire - loss_day
	stats.values[Metric.NET_NIGHT] = night - exported - fire - loss_night
	stats.values[Metric.RESERVE_DAY] = drain_time(stored, fire + exported + loss_day - day)
	stats.values[Metric.RESERVE_NIGHT] = drain_time(stored, fire + exported + loss_night - night)
	stats.values[Metric.RESERVE_FULL] = drain_time(capacity, fire + exported + loss_night - night)
	stats.values[Metric.BEAM_LOSS] = loss_day
	stats.values[Metric.BEAM_EFFICIENCY] = audit.transfer_efficiency(EnergyAudit.DAY)
	stats.values[Metric.SUPPLY_DAY] = audit.supply_ratio(EnergyAudit.DAY)
	stats.values[Metric.SUPPLY_NIGHT] = audit.supply_ratio(EnergyAudit.NIGHT)
	stats.values[Metric.EXPORT_INCOME] = audit.export_income(EnergyAudit.DAY)
	return stats


static func fire_draw(building: Building) -> float:
	if building.healing:
		return Formulas.heal_energy(building) / maxf(Formulas.heal_cooldown(building), GameConfig.TICK)
	if not building.armed:
		return 0.0
	if Formulas.is_laser(building):
		return Formulas.shot_energy(building)
	return Formulas.shot_energy(building) / maxf(Formulas.cooldown(building), GameConfig.TICK)


static func self_reserve(building: Building) -> float:
	return drain_time(Formulas.capacity(building), fire_draw(building))


static func shots_per_charge(building: Building) -> int:
	var cost := Formulas.heal_energy(building) if building.healing else Formulas.shot_energy(building)
	return int(floor(Formulas.capacity(building) / cost)) if cost > 0.0 else 0


static func drain_time(amount: float, rate: float) -> float:
	return amount / rate if rate > 0.0 else INF
