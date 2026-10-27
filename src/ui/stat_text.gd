class_name StatText
extends RefCounted


static func track_value(building: Building, track: String) -> String:
	match track:
		GameConfig.TRACK_RATE:
			if Formulas.export_rate(building) > 0.0:
				return "%d/s" % int(round(Formulas.export_rate(building)))
			return "%d/s" % int(round(Formulas.rate(building)))
		GameConfig.TRACK_RANGE:
			if GameConfig.is_tower(building.kind):
				return str(int(round(Formulas.attack_range(building))))
			if building.kind == GameConfig.SHIELD:
				return str(int(round(Formulas.shield_radius(building))))
			if building.definition().has("heal"):
				return str(int(round(Formulas.heal_range(building))))
			return str(int(round(Formulas.link_range(building))))
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
			return str(int(round(building.max_hp())))
		GameConfig.TRACK_SPEED:
			if building.definition().has("heal"):
				return "%.2f/s" % (1.0 / maxf(Formulas.heal_cooldown(building), 0.001))
			return "%.2f/s" % (1.0 / maxf(Formulas.cooldown(building), 0.001))
	return ""


static func next_value(building: Building, track: String) -> String:
	var probe := Building.new(building.id, building.kind, building.position)
	probe.levels = building.levels.duplicate()
	probe.levels[track] = building.level(track) + 1
	return track_value(probe, track)


static func pips(building: Building, track: String) -> String:
	var maximum := int(GameConfig.TRACKS[track].max)
	var level := building.level(track)
	return "●".repeat(level) + "○".repeat(maxi(maximum - level, 0))


static func stats(building: Building, state: BattleState) -> Array[Array]:
	var rows: Array[Array] = []
	rows.append(["STAT_HP", "%d / %d" % [int(ceil(building.hp)), int(building.max_hp())]])
	if not building.is_player():
		if building.definition().has("attack"):
			rows.append(["STAT_DAMAGE", str(int(Formulas.damage(building)))])
			rows.append(["STAT_RANGE", str(int(Formulas.attack_range(building)))])
		if building.definition().get("spawns", false):
			rows.append(["STAT_SPAWNS", Texts.t("STAT_SPAWNS_VALUE")])
		rows.append(["STAT_BOUNTY", str(int(building.definition().get("bounty", 0)))])
		return rows
	if Formulas.capacity(building) > 0.0:
		rows.append(["STAT_ENERGY", "%d / %d" % [int(building.energy), int(Formulas.capacity(building))]])
	if GameConfig.is_wall(building.kind):
		rows.append(["STAT_BLOCKS", Texts.t("STAT_BLOCKS_VALUE")])
	if building.elevation > 0:
		rows.append(["STAT_HIGH_GROUND", "+%d%%" % int(round(GameConfig.HIGH_GROUND_BONUS * 100.0))])
	if Formulas.output(building) > 0.0:
		var key := "STAT_SOLAR_OUTPUT" if building.definition().get("solar", false) else "STAT_OUTPUT"
		rows.append([key, "%.1f/s" % Formulas.output(building)])
	if Formulas.max_links(building) > 0:
		rows.append(["STAT_LINKS", "%d / %d" % [state.outgoing(building.id).size(), Formulas.max_links(building)]])
		rows.append(["STAT_RATE", "%d/s" % int(round(Formulas.rate(building)))])
		rows.append(["STAT_LINK_RANGE", str(int(round(Formulas.link_range(building))))])
	if GameConfig.has_attack(building.kind):
		var laser := str(Formulas.attack(building).mode) == GameConfig.MODE_LASER
		rows.append(["STAT_DPS" if laser else "STAT_DAMAGE", str(int(round(Formulas.damage(building))))])
		if not laser:
			rows.append(["STAT_FIRE_RATE", "%.2f/s" % (1.0 / maxf(Formulas.cooldown(building), 0.001))])
		rows.append(["STAT_RANGE", str(int(round(Formulas.attack_range(building))))])
		rows.append(["STAT_ENERGY_USE_LASER" if laser else "STAT_ENERGY_USE", "%.0f" % Formulas.shot_energy(building)])
	if Formulas.export_rate(building) > 0.0:
		rows.append(["STAT_EXPORT", "%d/s" % int(round(Formulas.export_rate(building)))])
		rows.append(["STAT_EXPORT_INCOME", "%.1f/s" % (Formulas.export_rate(building) / GameConfig.ENERGY_PER_COIN)])
	if building.kind == GameConfig.SHIELD:
		rows.append(["STAT_SHIELD_RADIUS", str(int(round(Formulas.shield_radius(building))))])
		rows.append(["STAT_SHIELD_RATIO", "%.1f" % Formulas.shield_ratio(building)])
	if building.definition().has("heal"):
		rows.append(["STAT_HEAL", str(int(round(Formulas.heal_amount(building))))])
		rows.append(["STAT_HEAL_RATE", "%.2f/s" % (1.0 / maxf(Formulas.heal_cooldown(building), 0.001))])
		rows.append(["STAT_RANGE", str(int(round(Formulas.heal_range(building))))])
		rows.append(["STAT_ENERGY_USE", "%.0f" % Formulas.heal_energy(building)])
	return rows
