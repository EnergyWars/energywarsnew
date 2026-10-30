class_name StatText
extends RefCounted


static func cells(pixels: float) -> String:
	return ("%.2f" % (pixels / GameConfig.CELL)).rstrip("0").rstrip(".")


static func track_value(building: Building, track: String) -> String:
	match track:
		GameConfig.TRACK_RATE:
			if Formulas.export_rate(building) > 0.0:
				return "%d/s" % int(round(Formulas.export_rate(building)))
			return "%d/s" % int(round(Formulas.rate(building)))
		GameConfig.TRACK_RANGE:
			if GameConfig.is_tower(building.kind):
				return cells(Formulas.attack_range(building))
			if building.kind == GameConfig.SHIELD:
				return cells(Formulas.shield_radius(building))
			if building.definition().has("heal"):
				return cells(Formulas.heal_range(building))
			return cells(Formulas.link_range(building))
		GameConfig.TRACK_LINKS:
			return str(Formulas.max_links(building))
		GameConfig.TRACK_OUTPUT:
			return "%.1f/s" % Formulas.output(building)
		GameConfig.TRACK_CAPACITY:
			return str(int(round(Formulas.capacity(building))))
		GameConfig.TRACK_POWER:
			if building.kind == GameConfig.SHIELD:
				return "%.1f" % Formulas.shield_ratio(building)
			if building.definition().has("heal"):
				return str(int(round(Formulas.heal_amount(building))))
			return str(int(round(Formulas.damage(building))))
		GameConfig.TRACK_HULL:
			return NumberFormat.grouped(int(round(building.max_hp())))
		GameConfig.TRACK_SPEED:
			if building.definition().has("heal"):
				return "%.2f/s" % (1.0 / maxf(Formulas.heal_cooldown(building), 0.001))
			return "%.2f/s" % (1.0 / maxf(Formulas.cooldown(building), 0.001))
		GameConfig.TRACK_EFFICIENCY:
			return "%d%%" % int(round(Formulas.efficiency(building) * 100.0))
		GameConfig.TRACK_CRIT:
			return "%d%%" % int(round(Formulas.crit_chance(building) * 100.0))
		GameConfig.TRACK_CHAIN:
			return str(Formulas.chain_count(building))
		GameConfig.TRACK_SPLASH:
			return cells(Formulas.splash(building))
		GameConfig.TRACK_OVERCLOCK:
			return "%d  %s%.1f" % [int(round(Formulas.damage(building))), Icons.BOLT, Formulas.shot_energy(building)]
		GameConfig.TRACK_TRANSFER:
			return Texts.format("STAT_TRANSFER_VALUE", [loss_per_cell(building) * 100.0])
	return ""


static func light_state(building: Building) -> String:
	if not building.lit:
		return Texts.t("STAT_LIGHT_OFF")
	return Texts.format("STAT_LIGHT_ON_VALUE", [Formulas.lit_reach(building) / GameConfig.CELL])


static func coins(value: float) -> String:
	return str(int(roundf(value))) if is_equal_approx(value, roundf(value)) else "%.2f" % value


static func loss_per_cell(building: Building) -> float:
	return Formulas.beam_loss(building, GameConfig.CELL)


static func range_loss(building: Building) -> float:
	var free := (building.half_extent() + GameConfig.CELL * 0.5) * sqrt(2.0) + GameConfig.BEAM_FREE_MARGIN
	return Formulas.beam_loss(building, maxf(Formulas.link_range(building) - free, 0.0))


static func overload_change(building: Building, track: String) -> String:
	var now := Formulas.is_overloaded(building)
	var next := Formulas.is_overloaded(upgraded(building, track))
	if next and not now:
		return Texts.format("PANEL_OVERLOAD_NEXT", [Icons.WARNING])
	if now and not next:
		return Texts.format("PANEL_OVERLOAD_FIXED", [Icons.CHECK])
	return ""


static func next_value(building: Building, track: String) -> String:
	return track_value(upgraded(building, track), track)


static func upgraded(building: Building, track: String) -> Building:
	var probe := Building.new(building.id, building.kind, building.position)
	probe.boosts = building.boosts
	probe.levels = building.levels.duplicate()
	probe.elevation = building.elevation
	probe.light_radius = building.light_radius
	probe.set_level(track, building.level(track) + 1)
	return probe


static func draw_change(building: Building, track: String) -> String:
	var before := EnergyAudit.draw(building)
	var after := EnergyAudit.draw(upgraded(building, track))
	if absf(after - before) < EnergyStatsText.RATE_STEP:
		return ""
	return Texts.format("PANEL_DRAW_CHANGE", [Icons.BOLT, before, after])


static func level_text(building: Building, track: String) -> String:
	return Texts.format("PANEL_LEVEL", [building.level(track), Formulas.max_level(building, track)])


static func stats(building: Building, state: BattleState) -> Array[Array]:
	var rows: Array[Array] = []
	rows.append(["STAT_HP", "%s / %s" % [NumberFormat.grouped(int(ceil(building.hp))), NumberFormat.grouped(int(building.max_hp()))]])
	if not building.is_player():
		if building.definition().has("attack"):
			rows.append(["STAT_DAMAGE", str(int(Formulas.damage(building)))])
			rows.append(["STAT_RANGE", cells(Formulas.attack_range(building))])
		if building.definition().get("spawns", false):
			rows.append(["STAT_SPAWNS", Texts.t("STAT_SPAWNS_VALUE")])
		rows.append(["STAT_BOUNTY", str(int(building.definition().get("bounty", 0)))])
		return rows
	if Formulas.capacity(building) > 0.0:
		rows.append(["STAT_ENERGY", "%d / %d" % [int(building.energy), int(Formulas.capacity(building))]])
	if GameConfig.is_wall(building.kind):
		rows.append(["STAT_BLOCKS", Texts.t("STAT_BLOCKS_VALUE")])
	if building.repairing:
		rows.append(["STAT_REPAIR", "%.0f/s" % Formulas.repair_rate(building)])
		rows.append(["STAT_REPAIR_DRAW", "%.1f/s" % Formulas.repair_draw(building)])
	if building.elevation > 0:
		rows.append(["STAT_HIGH_GROUND", "+%d%%" % int(round(GameConfig.HIGH_GROUND_BONUS * 100.0))])
	if Formulas.output(building) > 0.0:
		var key := "STAT_SOLAR_OUTPUT" if building.definition().get("solar", false) else "STAT_OUTPUT"
		rows.append([key, "%.1f/s" % Formulas.output(building)])
	if Formulas.max_links(building) > 0:
		rows.append(["STAT_LINKS", "%d / %d" % [state.outgoing(building.id).size(), Formulas.max_links(building)]])
		rows.append(["STAT_RATE", "%d/s" % int(round(Formulas.rate(building)))])
		rows.append(["STAT_LINK_RANGE", cells(Formulas.link_range(building))])
		rows.append(["STAT_BEAM_LOSS", "−%d%%" % int(round(range_loss(building) * 100.0))])
	if GameConfig.has_attack(building.kind):
		var laser := Formulas.is_laser(building)
		rows.append(["STAT_DPS" if laser else "STAT_DAMAGE", str(int(round(Formulas.damage(building))))])
		if not laser:
			rows.append(["STAT_FIRE_RATE", "%.2f/s" % (1.0 / maxf(Formulas.cooldown(building), 0.001))])
		rows.append(["STAT_RANGE", cells(Formulas.attack_range(building))])
		rows.append(["STAT_ENERGY_USE_LASER" if laser else "STAT_ENERGY_USE", "%.1f" % Formulas.shot_energy(building)])
		if not laser:
			rows.append(["STAT_CRIT", "%d%%" % int(round(Formulas.crit_chance(building) * 100.0))])
		_energy_rows(building, rows, "" if laser else "STAT_SHOTS_PER_CHARGE")
	if GameConfig.is_mobile(building.kind):
		rows.append(["STAT_MOVE_ENERGY", "%.1f" % (Formulas.move_energy(building) * GameConfig.CELL)])
	if building.id == state.core_id and state.scout != null and state.scout.boarded:
		rows.append(["STAT_GARRISON", Texts.t("STAT_GARRISON_VALUE")])
	if Formulas.export_rate(building) > 0.0:
		rows.append(["STAT_EXPORT", "%d/s" % int(round(Formulas.export_rate(building)))])
		rows.append(["STAT_EXPORT_INCOME", "%.1f/s" % Formulas.export_income(Formulas.export_rate(building))])
		rows.append(["STAT_EXPORT_RATIO", Texts.format("STAT_EXPORT_RATIO_VALUE", [GameConfig.ENERGY_PER_COIN])])
		rows.append(["STAT_EXPORT_CYCLE", Texts.format("STAT_EXPORT_CYCLE_VALUE", [coins(Formulas.export_payout(building)), int(GameConfig.EXPORT_CYCLE)])])
		rows.append(["STAT_EXPORT_PROGRESS", "%d%%" % int(floor(Formulas.export_progress(building) * 100.0))])
		rows.append(["STAT_EXPORT_ROUND", "+%d" % int(round(Formulas.export_income(Formulas.export_rate(building)) * DayCycle.length(state.level)))])
	if building.burner:
		rows.append(["STAT_FUEL", str(building.fuel.size())])
		rows.append(["STAT_FUEL_TIME", NumberFormat.clock(Formulas.fuel_time(building))])
	if building.lighting:
		rows.append(["STAT_LIGHT_RADIUS", Texts.format("STAT_LIGHT_RADIUS_VALUE", [building.light_radius])])
		rows.append(["STAT_LIGHT_DRAW", "%.1f/s" % Formulas.lamp_draw(building)])
		rows.append(["STAT_LIGHT_STATE", light_state(building)])
	if building.kind == GameConfig.SHIELD:
		rows.append(["STAT_SHIELD_RADIUS", cells(Formulas.shield_radius(building))])
		rows.append(["STAT_SHIELD_RATIO", "%.1f" % Formulas.shield_ratio(building)])
	if building.definition().has("heal"):
		rows.append(["STAT_HEAL", str(int(round(Formulas.heal_amount(building))))])
		rows.append(["STAT_HEAL_RATE", "%.2f/s" % (1.0 / maxf(Formulas.heal_cooldown(building), 0.001))])
		rows.append(["STAT_RANGE", cells(Formulas.heal_range(building))])
		rows.append(["STAT_ENERGY_USE", "%.1f" % Formulas.heal_energy(building)])
		_energy_rows(building, rows, "STAT_HEALS_PER_CHARGE")
	return rows


static func status_rows(building: Building, audit: EnergyAudit, scenario: int = EnergyAudit.WORST) -> Array[Array]:
	var rows: Array[Array] = []
	if audit == null or not audit.has(building.id):
		return rows
	var id := building.id
	if audit.shows(id) and audit.need_of(id) > EnergyAudit.EPSILON:
		rows.append(["STAT_NEED", StatusText.rate(audit.need_of(id))])
		rows.append(["STAT_SUPPLY_DAY", StatusText.supply_value(audit, id, EnergyAudit.DAY)])
		rows.append(["STAT_SUPPLY_NIGHT", StatusText.supply_value(audit, id, EnergyAudit.NIGHT)])
	if audit.reserve_rate(id) > 0.0 and audit.throughput(id, EnergyAudit.NIGHT) > 0.0:
		rows.append(["STAT_NIGHT_RESERVE", EnergyStatsText.duration(audit.night_reserve(id))])
	if building.exporting:
		rows.append(["STAT_EXPORT_REAL", Texts.format("STAT_EXPORT_REAL_VALUE", ["%.2f" % Formulas.export_income(audit.served_of(id, EnergyAudit.DAY)), "%.2f" % Formulas.export_income(audit.served_of(id, EnergyAudit.NIGHT))])])
	if EnergyNetwork.can_receive(building) or EnergyNetwork.can_send(building):
		rows.append(["STAT_FLOW", Texts.format("STAT_FLOW_VALUE", [audit.inflow(id, scenario), audit.throughput(id, scenario)])])
	return rows


static func _energy_rows(building: Building, rows: Array[Array], charge_key: String) -> void:
	if not Formulas.is_laser(building):
		rows.append(["STAT_FIRE_DRAW", "%.1f/s" % EnergyStats.fire_draw(building)])
	rows.append(["STAT_SELF_RESERVE", EnergyStatsText.duration(EnergyStats.self_reserve(building))])
	if not charge_key.is_empty():
		rows.append([charge_key, str(EnergyStats.shots_per_charge(building))])
