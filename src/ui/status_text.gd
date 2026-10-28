class_name StatusText
extends RefCounted

const STYLES := {
	EnergyAudit.Verdict.OK: {"icon": Icons.CHECK, "color": AppTheme.SUCCESS, "key": "STATUS_OK"},
	EnergyAudit.Verdict.NIGHT: {"icon": Icons.MOON, "color": AppTheme.VIOLET, "key": "STATUS_NIGHT"},
	EnergyAudit.Verdict.LOW: {"icon": Icons.WARNING, "color": AppTheme.WARNING, "key": "STATUS_LOW"},
	EnergyAudit.Verdict.STARVED: {"icon": Icons.POWER_OFF, "color": AppTheme.DANGER, "key": "STATUS_STARVED"},
	EnergyAudit.Verdict.OFFLINE: {"icon": Icons.FLASH_OFF, "color": AppTheme.DANGER, "key": "STATUS_OFFLINE"},
	EnergyAudit.Verdict.OVERLOADED: {"icon": Icons.ERROR, "color": AppTheme.DANGER, "key": "STATUS_OVERLOADED"},
}
const LEGEND: Array[int] = [
	EnergyAudit.Verdict.OK,
	EnergyAudit.Verdict.NIGHT,
	EnergyAudit.Verdict.LOW,
	EnergyAudit.Verdict.STARVED,
	EnergyAudit.Verdict.OFFLINE,
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
}


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


static func label(building: Building, audit: EnergyAudit) -> String:
	if Formulas.is_overloaded(building):
		return Texts.format("STATUS_LABEL_OVERLOAD", [amount(Formulas.action_energy(building)), amount(Formulas.capacity(building))])
	var parts: Array[String] = []
	if building.exporting:
		var draw := Formulas.export_rate(building)
		parts.append(Texts.format("STATUS_LABEL_EXPORT", [rate(draw), "%.2f" % Formulas.export_income(draw)]))
	elif building.healing:
		parts.append(Texts.format("STATUS_LABEL_HEAL", [amount(Formulas.heal_energy(building)), rate(EnergyStats.fire_draw(building))]))
	elif building.armed and Formulas.is_laser(building):
		parts.append(Texts.format("STATUS_LABEL_BEAM", [rate(Formulas.shot_energy(building))]))
	elif building.armed:
		parts.append(Texts.format("STATUS_LABEL_SHOT", [amount(Formulas.shot_energy(building)), rate(EnergyStats.fire_draw(building))]))
	elif Formulas.output(building) > 0.0:
		parts.append(Texts.format("STATUS_LABEL_OUTPUT", [rate(Formulas.output(building))]))
	elif audit != null and audit.throughput(building.id) > 0.0:
		parts.append(Texts.format("STATUS_LABEL_RELAY", [rate(audit.throughput(building.id))]))
	if audit != null and audit.need_of(building.id) > 0.0 and audit.ratio(building.id) < EnergyAudit.SATISFIED:
		parts.append(Texts.format("STATUS_LABEL_SUPPLY", [EnergyStatsText.percent(audit.ratio(building.id))]))
	return " · ".join(parts)


static func link_label(audit: EnergyAudit, key: String) -> String:
	if not audit.is_active(key):
		return Texts.t("STATUS_LINK_RANGE")
	var loss := EnergyStatsText.percent(1.0 - audit.link_yield(key))
	var delivered := audit.flow(key) * audit.link_yield(key)
	return Texts.format("STATUS_LINK_LABEL", [loss, rate(delivered)])


static func link_color(audit: EnergyAudit, key: String) -> Color:
	if not audit.is_active(key):
		return AppTheme.DANGER
	if audit.is_saturated(key):
		return AppTheme.WARNING
	if 1.0 - audit.link_yield(key) >= EnergyAudit.HEAVY_LOSS:
		return AppTheme.PLASMA_ORANGE
	return AppTheme.ENERGY


static func cause_text(audit: EnergyAudit, building: Building, state: BattleState) -> String:
	var reason := audit.cause(building.id)
	if not CAUSE_KEYS.has(reason):
		return ""
	var key: String = CAUSE_KEYS[reason]
	match reason:
		EnergyAudit.Cause.OVERLOAD:
			return Texts.format(key, [amount(Formulas.action_energy(building)), amount(Formulas.capacity(building))])
		EnergyAudit.Cause.OUT_OF_RANGE, EnergyAudit.Cause.BEAM_RATE:
			return Texts.format(key, [culprit_name(audit, building, state)])
		EnergyAudit.Cause.BEAM_LOSS:
			return Texts.format(key, [culprit_name(audit, building, state), EnergyStatsText.percent(1.0 - audit.link_yield(audit.culprit_link(building.id)))])
		EnergyAudit.Cause.NIGHT:
			return Texts.format(key, [EnergyStatsText.percent(audit.ratio(building.id, EnergyAudit.NIGHT))])
	return Texts.t(key)


static func culprit_name(audit: EnergyAudit, building: Building, state: BattleState) -> String:
	var culprit := state.building(audit.culprit(building.id))
	return Texts.building_name(culprit.kind) if culprit != null else Texts.t("STATUS_UNKNOWN")


static func summary(audit: EnergyAudit, building: Building) -> String:
	var verdict := audit.verdict(building.id)
	if audit.need_of(building.id) <= 0.0 or verdict == EnergyAudit.Verdict.OVERLOADED or verdict == EnergyAudit.Verdict.OFFLINE:
		return title(verdict)
	return Texts.format("STATUS_SUMMARY", [title(verdict), EnergyStatsText.percent(audit.ratio(building.id, EnergyAudit.DAY)), EnergyStatsText.percent(audit.ratio(building.id, EnergyAudit.NIGHT))])
