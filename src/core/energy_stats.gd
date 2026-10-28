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
	COUNT,
}

const FULL_EPSILON := 0.01

var values := PackedFloat64Array()


func _init() -> void:
	values.resize(Metric.COUNT)


func value(metric: Metric) -> float:
	return values[metric]


static func measure(state: BattleState) -> EnergyStats:
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
	stats.values[Metric.GENERATION_DAY] = day
	stats.values[Metric.GENERATION_NIGHT] = night
	stats.values[Metric.CAPACITY] = capacity
	stats.values[Metric.STORED] = stored
	stats.values[Metric.FILL_RATIO] = stored / capacity if capacity > 0.0 else 0.0
	stats.values[Metric.FILL_TIME] = 0.0 if missing <= FULL_EPSILON else drain_time(missing, day - exported)
	stats.values[Metric.FIRE_DRAW] = fire
	stats.values[Metric.EXPORT_DRAW] = exported
	stats.values[Metric.NET_DAY] = day - exported - fire
	stats.values[Metric.NET_NIGHT] = night - exported - fire
	stats.values[Metric.RESERVE_DAY] = drain_time(stored, fire + exported - day)
	stats.values[Metric.RESERVE_NIGHT] = drain_time(stored, fire + exported - night)
	stats.values[Metric.RESERVE_FULL] = drain_time(capacity, fire + exported - night)
	return stats


static func fire_draw(building: Building) -> float:
	if building.healing:
		return Formulas.heal_energy(building) / maxf(Formulas.heal_cooldown(building), GameConfig.TICK)
	if not building.armed:
		return 0.0
	if str(Formulas.attack(building).get("mode", "")) == GameConfig.MODE_LASER:
		return Formulas.shot_energy(building)
	return Formulas.shot_energy(building) / maxf(Formulas.cooldown(building), GameConfig.TICK)


static func self_reserve(building: Building) -> float:
	return drain_time(Formulas.capacity(building), fire_draw(building))


static func shots_per_charge(building: Building) -> int:
	var cost := Formulas.heal_energy(building) if building.healing else Formulas.shot_energy(building)
	return int(floor(Formulas.capacity(building) / cost)) if cost > 0.0 else 0


static func drain_time(amount: float, rate: float) -> float:
	return amount / rate if rate > 0.0 else INF
