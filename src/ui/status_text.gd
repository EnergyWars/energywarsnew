class_name StatusText
extends RefCounted

const STYLES := {
	EnergyAudit.Verdict.OK: {"icon": Icons.CHECK, "color": AppTheme.SUCCESS, "key": "STATUS_OK"},
	EnergyAudit.Verdict.LOW: {"icon": Icons.WARNING, "color": AppTheme.WARNING, "key": "STATUS_LOW"},
	EnergyAudit.Verdict.OVERLOADED: {"icon": Icons.ERROR, "color": AppTheme.DANGER, "key": "STATUS_OVERLOADED"},
}
const LEGEND: Array[int] = [
	EnergyAudit.Verdict.OK,
	EnergyAudit.Verdict.LOW,
	EnergyAudit.Verdict.OVERLOADED,
]
const CAUSE_KEYS := {
	EnergyAudit.Cause.OVERLOAD: "STATUS_CAUSE_OVERLOAD",
	EnergyAudit.Cause.NO_SOURCE: "STATUS_CAUSE_NO_SOURCE",
	EnergyAudit.Cause.OUT_OF_RANGE: "STATUS_CAUSE_OUT_OF_RANGE",
	EnergyAudit.Cause.BEAM_RATE: "STATUS_CAUSE_BEAM_RATE",
	EnergyAudit.Cause.BEAM_LOSS: "STATUS_CAUSE_BEAM_LOSS",
	EnergyAudit.Cause.GENERATION: "STATUS_CAUSE_GENERATION",
	EnergyAudit.Cause.NIGHT: "STATUS_CAUSE_NIGHT",
	EnergyAudit.Cause.STORAGE: "STATUS_CAUSE_STORAGE",
}
const WHEN_KEYS: Array[String] = ["STATUS_WHEN_DAY", "STATUS_WHEN_NIGHT"]


static func has_style(verdict: int) -> bool:
	return STYLES.has(verdict)


static func icon(verdict: int) -> String:
	return str(STYLES[verdict].icon) if STYLES.has(verdict) else ""


static func color(verdict: int) -> Color:
	return STYLES[verdict].color if STYLES.has(verdict) else AppTheme.ON_SURFACE_VARIANT


static func title(verdict: int) -> String:
	return Texts.t(STYLES[verdict].key) if STYLES.has(verdict) else ""


static func rate(value: float) -> String:
	return "%.1f/s" % value


static func amount(value: float) -> String:
	return "%.1f" % value


static func when(scenario: int) -> String:
	return Texts.t(WHEN_KEYS[scenario]) if scenario >= 0 and scenario < WHEN_KEYS.size() else ""


static func label(building: Building, audit: EnergyAudit, scenario: int = EnergyAudit.WORST) -> String:
	if Formulas.is_overloaded(building):
		return Texts.format("STATUS_LABEL_OVERLOAD", [amount(Formulas.action_energy(building)), amount(Formulas.capacity(building))])
	if building.exporting:
		var draw := Formulas.export_rate(building)
		return Texts.format("STATUS_LABEL_EXPORT", [rate(draw), "%.2f" % Formulas.export_income(draw)])
	if building.healing:
		return Texts.format("STATUS_LABEL_HEAL", [amount(Formulas.heal_energy(building)), rate(EnergyStats.fire_draw(building))])
	if building.armed and Formulas.is_laser(building):
		return Texts.format("STATUS_LABEL_BEAM", [rate(Formulas.shot_energy(building))])
	if building.armed:
		return Texts.format("STATUS_LABEL_SHOT", [amount(Formulas.shot_energy(building)), rate(EnergyStats.fire_draw(building))])
	if Formulas.output(building) > 0.0:
		return Texts.format("STATUS_LABEL_OUTPUT", [rate(Formulas.output(building))])
	if audit != null and audit.throughput(building.id, scenario) > 0.0:
		return Texts.format("STATUS_LABEL_RELAY", [rate(audit.throughput(building.id, scenario))])
	return ""


static func link_label(audit: EnergyAudit, key: String, scenario: int = EnergyAudit.WORST) -> String:
	if not audit.is_active(key):
		return Texts.t("STATUS_LINK_RANGE")
	var arriving := rate(audit.delivered(key, scenario))
	var limit := rate(audit.link_cap(key))
	if audit.link_loss(key) < EnergyAudit.LOSSLESS:
		return Texts.format("STATUS_LINK_LOSSLESS", [arriving, limit])
	return Texts.format("STATUS_LINK_LABEL", [EnergyStatsText.percent(audit.link_loss(key)), arriving, limit])


static func link_color(audit: EnergyAudit, key: String, scenario: int = EnergyAudit.WORST) -> Color:
	if not audit.is_active(key):
		return AppTheme.DANGER
	if audit.is_saturated(key, scenario):
		return AppTheme.WARNING
	if audit.link_loss(key) >= EnergyAudit.HEAVY_LOSS:
		return AppTheme.PLASMA_ORANGE
	return AppTheme.ENERGY


static func cause_text(audit: EnergyAudit, building: Building, state: BattleState, scenario: int = EnergyAudit.WORST) -> String:
	var reason := audit.cause(building.id, scenario)
	if not CAUSE_KEYS.has(reason):
		return ""
	var key: String = CAUSE_KEYS[reason]
	match reason:
		EnergyAudit.Cause.OVERLOAD:
			return Texts.format(key, [amount(Formulas.action_energy(building)), amount(Formulas.capacity(building))])
		EnergyAudit.Cause.OUT_OF_RANGE, EnergyAudit.Cause.BEAM_RATE:
			return Texts.format(key, [culprit_name(audit, building, state, scenario)])
		EnergyAudit.Cause.BEAM_LOSS:
			return Texts.format(key, [culprit_name(audit, building, state, scenario), EnergyStatsText.percent(audit.link_loss(audit.culprit_link(building.id, scenario)))])
		EnergyAudit.Cause.STORAGE:
			return Texts.format(key, [culprit_name(audit, building, state, scenario), EnergyStatsText.duration(audit.night_reserve(audit.culprit(building.id, scenario)))])
	return Texts.t(key)


static func culprit_name(audit: EnergyAudit, building: Building, state: BattleState, scenario: int = EnergyAudit.WORST) -> String:
	var culprit := state.building(audit.culprit(building.id, scenario))
	return Texts.building_name(culprit.kind) if culprit != null else Texts.t("STATUS_UNKNOWN")


static func summary(audit: EnergyAudit, building: Building, scenario: int = EnergyAudit.WORST) -> String:
	var verdict := audit.verdict(building.id, scenario)
	if verdict != EnergyAudit.Verdict.LOW or audit.need_of(building.id) <= EnergyAudit.EPSILON:
		return title(verdict)
	var resolved := audit.resolve(building.id, scenario)
	return Texts.format("STATUS_SUMMARY", [title(verdict), when(resolved), rate(audit.shortfall(building.id, scenario))])


static func supply_value(audit: EnergyAudit, id: int, scenario: int) -> String:
	var glyph := Icons.CHECK if audit.ratio(id, scenario) >= EnergyAudit.SATISFIED else Icons.WARNING
	return "%s %s" % [glyph, rate(audit.supply(id, scenario))]
