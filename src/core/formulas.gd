class_name Formulas
extends RefCounted

enum Stat { CAPACITY, OUTPUT, RATE, LINK_RANGE, ATTACK_RANGE, DAMAGE, COOLDOWN, SHOT_ENERGY, MAX_HP, ARMOR, COUNT }


static func compute_stats(building: Building) -> PackedFloat64Array:
	var stats := PackedFloat64Array()
	stats.resize(Stat.COUNT)
	stats[Stat.CAPACITY] = float(building.definition().get("capacity", 0.0)) * multiplier(building, GameConfig.TRACK_CAPACITY) * building.boost(GameConfig.BOOST_CAPACITY)
	stats[Stat.OUTPUT] = float(building.definition().get("output", 0.0)) * multiplier(building, GameConfig.TRACK_OUTPUT) * building.boost(GameConfig.BOOST_OUTPUT)
	if building.definition().get("rate_from_output", false):
		stats[Stat.RATE] = stats[Stat.OUTPUT]
	else:
		stats[Stat.RATE] = float(building.definition().get("rate", 0.0)) * multiplier(building, GameConfig.TRACK_RATE)
	stats[Stat.LINK_RANGE] = float(building.definition().get("range", 0.0)) * multiplier(building, GameConfig.TRACK_RANGE)
	var base_range := float(attack(building).get("range", 0.0))
	var base_damage := float(attack(building).get("damage", 0.0))
	var base_cooldown := float(attack(building).get("cooldown", 0.0))
	if building.is_player():
		stats[Stat.ATTACK_RANGE] = base_range * multiplier(building, GameConfig.TRACK_RANGE) * high_ground(building) * building.boost(GameConfig.BOOST_RANGE)
		stats[Stat.DAMAGE] = base_damage * multiplier(building, GameConfig.TRACK_POWER) * multiplier(building, GameConfig.TRACK_OVERCLOCK) * building.boost(GameConfig.BOOST_DAMAGE)
		stats[Stat.COOLDOWN] = base_cooldown / multiplier(building, GameConfig.TRACK_SPEED)
	else:
		stats[Stat.ATTACK_RANGE] = base_range
		stats[Stat.DAMAGE] = base_damage
		stats[Stat.COOLDOWN] = base_cooldown
	stats[Stat.SHOT_ENERGY] = float(attack(building).get("energy", 0.0)) * overclock_energy(building) / efficiency(building)
	stats[Stat.MAX_HP] = float(building.definition().get("hp", 1.0)) * multiplier(building, GameConfig.TRACK_HULL) * building.boost(GameConfig.BOOST_HP)
	stats[Stat.ARMOR] = base_armor(building) * multiplier(building, GameConfig.TRACK_ARMOR)
	return stats


static func track_config(building: Building, track: String) -> Dictionary:
	var table := UpgradeOverrides.table(building.kind, track)
	if not table.is_empty():
		return table
	return building.definition().get("curves", GameConfig.EMPTY).get(track, GameConfig.TRACKS[track])


static func multiplier(building: Building, track: String) -> float:
	var config := track_config(building, track)
	var level := building.level(track)
	if config.has("levels"):
		return 1.0 if level <= 0 else float(config.levels[mini(level, config.levels.size()) - 1].effect)
	if config.has("gain"):
		var growth := float(config.gain_growth)
		return 1.0 + float(config.gain) * (pow(growth, level) - 1.0) / (growth - 1.0)
	return 1.0 + float(config.step) * level


static func gain(building: Building, track: String) -> float:
	var config := track_config(building, track)
	if config.has("levels"):
		return multiplier(building, track) - 1.0
	return float(GameConfig.TRACKS[track].step) * building.level(track)


static func efficiency(building: Building) -> float:
	return multiplier(building, GameConfig.TRACK_EFFICIENCY)


static func overclock_energy(building: Building) -> float:
	return pow(float(GameConfig.TRACKS[GameConfig.TRACK_OVERCLOCK].energy), building.level(GameConfig.TRACK_OVERCLOCK))


static func transfer_factor(building: Building) -> float:
	return maxf(1.0 - gain(building, GameConfig.TRACK_TRANSFER), 0.0)


static func beam_span(source: Building, target: Building) -> float:
	var free := (source.half_extent() + target.half_extent()) * sqrt(2.0) + GameConfig.BEAM_FREE_MARGIN
	return maxf(source.position.distance_to(target.position) - free, 0.0)


static func beam_loss(source: Building, span: float, receiver: float = 1.0) -> float:
	var raw := GameConfig.BEAM_LOSS_PER_CELL * maxf(span, 0.0) / GameConfig.CELL
	return clampf(raw * transfer_factor(source) * receiver / source.boost(GameConfig.BOOST_TRANSFER), 0.0, GameConfig.BEAM_LOSS_MAX)


static func link_loss(source: Building, target: Building) -> float:
	return beam_loss(source, beam_span(source, target), transfer_factor(target))


static func link_efficiency(source: Building, target: Building) -> float:
	return 1.0 - link_loss(source, target)


static func capacity(building: Building) -> float:
	return building.stat(Stat.CAPACITY)


static func output(building: Building) -> float:
	return building.stat(Stat.OUTPUT)


static func generation(building: Building, sun: float) -> float:
	var amount := output(building)
	if building.definition().get("solar", false):
		return amount * sun
	if building.burner and building.fuel.is_empty():
		return 0.0
	return amount


static func forecast_output(building: Building, night: bool) -> float:
	return generation(building, 0.0 if night else 1.0)


static func fuel_reach(building: Building) -> float:
	return GameConfig.FIRE_REACH * GameConfig.CELL if building.burner else 0.0


static func fuel_time(building: Building) -> float:
	if not building.burner or building.fuel.is_empty():
		return 0.0
	var started := building.burn_progress if building.burn_cell == building.fuel[0] else 0.0
	return maxf(GameConfig.FIRE_BURN_TIME * building.fuel.size() - started, 0.0)


static func clamp_light(radius_cells: float) -> float:
	return clampf(snappedf(radius_cells, GameConfig.LAMP_RADIUS_STEP), GameConfig.LAMP_RADIUS_MIN, GameConfig.LAMP_RADIUS_MAX)


static func lamp_draw(building: Building) -> float:
	return lamp_draw_at(building, building.light_radius)


static func lamp_draw_at(building: Building, radius_cells: float) -> float:
	if not building.lighting:
		return 0.0
	return GameConfig.LAMP_BASE_DRAW * pow(maxf(radius_cells, 0.0) / GameConfig.LAMP_BASE_RADIUS, GameConfig.LAMP_EXPONENT) / efficiency(building)


static func light_reach(building: Building) -> float:
	if building.lighting:
		return building.light_radius * GameConfig.CELL
	if building.kind == GameConfig.CORE:
		return building.half_extent() + GameConfig.CORE_LIGHT * GameConfig.CELL
	return 0.0


static func light_fill(building: Building) -> float:
	var full := capacity(building)
	return clampf(building.energy / full, 0.0, 1.0) if full > 0.0 else 0.0


static func lit_reach(building: Building) -> float:
	var reach := light_reach(building)
	return reach * light_fill(building) if building.lighting else reach


static func glows(building: Building) -> bool:
	return building.is_player() and building.is_alive() and building.energy >= GameConfig.GLOW_ENERGY


static func rate(building: Building) -> float:
	return building.stat(Stat.RATE)


static func beam_rate(building: Building, beams: int) -> float:
	if building.definition().get("rate_from_output", false):
		return rate(building) / maxi(beams, 1)
	return rate(building)


static func export_rate(building: Building) -> float:
	return float(building.definition().get("export", 0.0)) * multiplier(building, GameConfig.TRACK_RATE) * building.boost(GameConfig.BOOST_EXPORT)


static func link_range(building: Building) -> float:
	return building.stat(Stat.LINK_RANGE)


static func max_links(building: Building) -> int:
	var base := int(building.definition().get("links", 0))
	return base + building.level(GameConfig.TRACK_LINKS) if base > 0 else 0


static func build_radius(building: Building) -> float:
	return float(building.definition().get("build_radius", 0.0))


static func attack(building: Building) -> Dictionary:
	return building.definition().get("attack", GameConfig.EMPTY)


static func attack_range(building: Building) -> float:
	return building.stat(Stat.ATTACK_RANGE)


static func high_ground(building: Building) -> float:
	return 1.0 + GameConfig.HIGH_GROUND_BONUS * building.elevation


static func vision(building: Building) -> float:
	var base := float(building.definition().get("vision", GameConfig.VISION_DEFAULT))
	if GameConfig.has_attack(building.kind):
		base = maxf(base, attack_range(building) + GameConfig.VISION_MARGIN)
	return base * high_ground(building)


static func build_cost(state: BattleState, kind: String) -> int:
	var definition := GameConfig.building(kind)
	var cost := int(definition.get("cost", 0))
	var every := int(definition.get("cost_every", 0))
	return cost + state.count_kind(kind) / every if every > 0 else cost


static func base_armor(building: Building) -> float:
	return ContentOverrides.building_armor(building.kind, float(building.definition().get("armor", 0.0)))


static func armor(building: Building) -> float:
	return building.stat(Stat.ARMOR)


static func damage(building: Building) -> float:
	return building.stat(Stat.DAMAGE)


static func cooldown(building: Building) -> float:
	return building.stat(Stat.COOLDOWN)


static func shot_energy(building: Building) -> float:
	return building.stat(Stat.SHOT_ENERGY)


static func is_laser(building: Building) -> bool:
	return str(attack(building).get("mode", "")) == GameConfig.MODE_LASER


static func action_energy(building: Building) -> float:
	if building.healing:
		return heal_energy(building)
	if not building.armed:
		return 0.0
	return shot_energy(building) * (GameConfig.TICK if is_laser(building) else 1.0)


static func is_overloaded(building: Building) -> bool:
	return building.is_player() and action_energy(building) > capacity(building) + 0.0001


static func crit_chance(building: Building) -> float:
	return GameConfig.CRIT_CHANCE + gain(building, GameConfig.TRACK_CRIT)


static func chain_count(building: Building) -> int:
	return int(round(float(attack(building).get("chain", 1)) * building.boost(GameConfig.BOOST_CHAIN))) + building.level(GameConfig.TRACK_CHAIN)


static func splash(building: Building) -> float:
	return float(attack(building).get("splash", 0.0)) * multiplier(building, GameConfig.TRACK_SPLASH) * building.boost(GameConfig.BOOST_SPLASH)


static func shield_radius(building: Building) -> float:
	return float(building.definition().get("shield", GameConfig.EMPTY).get("radius", 0.0)) * multiplier(building, GameConfig.TRACK_RANGE)


static func shield_ratio(building: Building) -> float:
	return GameConfig.SHIELD_RATIO * multiplier(building, GameConfig.TRACK_POWER)


static func heal(building: Building) -> Dictionary:
	return building.definition().get("heal", GameConfig.EMPTY)


static func heal_amount(building: Building) -> float:
	return float(heal(building).get("amount", 0.0)) * multiplier(building, GameConfig.TRACK_POWER) * building.boost(GameConfig.BOOST_HEAL)


static func heal_cooldown(building: Building) -> float:
	return float(heal(building).get("cooldown", 0.0)) / multiplier(building, GameConfig.TRACK_SPEED)


static func heal_range(building: Building) -> float:
	return float(heal(building).get("range", 0.0)) * multiplier(building, GameConfig.TRACK_RANGE)


static func heal_energy(building: Building) -> float:
	return float(heal(building).get("energy", 0.0)) / efficiency(building)


static func repair_rate(building: Building) -> float:
	return float(building.definition().get("repair", GameConfig.EMPTY).get("rate", 0.0))


static func repair_draw(building: Building) -> float:
	return float(building.definition().get("repair", GameConfig.EMPTY).get("energy", 0.0))


static func repair_cost(building: Building) -> float:
	var rate := repair_rate(building)
	return repair_draw(building) / rate if rate > 0.0 else 0.0


static func upgrade_base(kind: String) -> int:
	var definition := GameConfig.building(kind)
	return int(definition.get("upgrade_base", definition.get("cost", 0)))


static func upgrade_cost(building: Building, track: String) -> int:
	var config := track_config(building, track)
	if config.has("levels"):
		return int(config.levels[clampi(building.level(track), 0, config.levels.size() - 1)].cost)
	var growth := float(config.get("growth", GameConfig.TRACK_GROWTH))
	return maxi(int(round(upgrade_base(building.kind) * float(config.price) * pow(growth, building.level(track)))), 1)


static func max_level(building: Building, track: String) -> int:
	return int(track_config(building, track).max)


static func is_maxed(building: Building, track: String) -> bool:
	return building.level(track) >= max_level(building, track)


static func is_fresh(building: Building) -> bool:
	return building.plan_spent > 0 and building.plan_spent >= building.spent


static func sell_loss(building: Building) -> int:
	return maxi(building.spent - sell_value(building), 0)


static func sell_value(building: Building) -> int:
	var older := maxi(building.spent - building.plan_spent, 0)
	return building.plan_spent + int(floor(older * GameConfig.SELL_REFUND * building.hp_ratio()))


static func relocate_cost(building: Building, planning: bool) -> int:
	if planning:
		return 0
	return maxi(int(round(building.spent * GameConfig.RELOCATE_SHARE)), 1)


static func move_speed(building: Building) -> float:
	return float(building.definition().get("mobile", GameConfig.EMPTY).get("speed", 0.0))


static func move_energy(building: Building) -> float:
	return float(building.definition().get("mobile", GameConfig.EMPTY).get("energy", 0.0)) / efficiency(building)


static func export_income(energy_rate: float) -> float:
	return maxf(energy_rate, 0.0) / GameConfig.ENERGY_PER_COIN


static func export_batch(building: Building) -> float:
	return export_rate(building) * GameConfig.EXPORT_CYCLE


static func export_payout(building: Building) -> float:
	return export_income(export_batch(building))


static func export_progress(building: Building) -> float:
	var batch := export_batch(building)
	return clampf(building.export_buffer / batch, 0.0, 1.0) if batch > 0.0 else 0.0


static func guard_count(round_number: int) -> int:
	return mini(GameConfig.GUARD_BASE + maxi(round_number - 1, 0) / GameConfig.GUARD_EVERY, GameConfig.GUARD_MAX)


static func guard_ring(post: Building) -> float:
	return post.half_extent() + GameConfig.GUARD_RING * GameConfig.CELL


static func wave_times(level: Dictionary) -> int:
	var span := DayCycle.length(level) - GameConfig.WAVE_FIRST
	return int(ceil(span / float(level.waves.interval))) if span > 0.0 else 0


static func wave_time(level: Dictionary, index: int) -> float:
	return GameConfig.WAVE_FIRST + float(level.waves.interval) * index


static func wave_count(waves: Dictionary, round_number: int, progress: float, night: bool) -> float:
	var count := float(waves.base) * (1.0 + float(waves.ramp) * clampf(progress, 0.0, 1.0)) * (1.0 + float(waves.growth) * maxi(round_number - 1, 0))
	return count * float(waves.night) if night else count


static func extra_waves(level: Dictionary, round_number: int, index: int) -> Array:
	var result := []
	var night := DayCycle.is_night(wave_time(level, index), level)
	var opens := index == 0 or DayCycle.is_night(wave_time(level, index - 1), level) != night
	if not opens:
		return result
	for entry: Dictionary in level.get("extra_waves", GameConfig.EMPTY_LIST):
		if int(entry.day) == round_number and bool(entry.night) == night:
			result.append(entry)
	return result


static func wave_tier(round_number: int) -> int:
	return maxi(round_number - 1, 0)


static func armor_reduction(armor: float) -> float:
	if armor <= 0.0:
		return 0.0
	var config: Dictionary = GameConfig.armor_config()
	return clampf(armor / (armor + float(config.constant)), 0.0, float(config.max_reduction))


static func mitigate(amount: float, armor: float, share: float = 1.0) -> float:
	if amount <= 0.0:
		return 0.0
	if armor <= 0.0:
		return amount
	var reduced := amount * (1.0 - armor_reduction(armor))
	return minf(amount, maxf(reduced, float(GameConfig.armor_config().min_damage) * maxf(share, 0.0)))


static func enemy_hp_scale(round_number: int) -> float:
	return pow(GameConfig.ROUND_HP_GROWTH, maxi(round_number - 1, 0))


static func enemy_damage_scale(round_number: int) -> float:
	return 1.0 + GameConfig.ROUND_DAMAGE_GROWTH * maxi(round_number - 1, 0)


static func enemy_bounty_scale(round_number: int) -> float:
	return 1.0 + GameConfig.ROUND_BOUNTY_GROWTH * maxi(round_number - 1, 0)


static func enemy_buff(kind: String, stat: String, is_night: bool, level_index: int) -> float:
	var buffs: Dictionary = GameConfig.enemy(kind).get("buffs", GameConfig.EMPTY)
	var night_bonus := 0.0
	if is_night:
		night_bonus = float(buffs.get("night", GameConfig.EMPTY).get(stat, 0.0))
	var level_bonus := float(buffs.get("level", GameConfig.EMPTY).get(stat, 0.0)) * maxi(level_index, 0)
	return maxf(1.0 + night_bonus, 0.0) * maxf(1.0 + level_bonus, 0.0)


static func combo_tier(count: int) -> int:
	var tier := 0
	for threshold in GameConfig.COMBO_TIERS:
		if count >= threshold:
			tier += 1
	return tier


static func combo_bonus(count: int) -> int:
	return count if GameConfig.COMBO_TIERS.has(count) else 0


static func survival_stars(days: int) -> int:
	var stars := 0
	for target in GameConfig.SURVIVAL_TARGETS:
		if days >= target:
			stars += 1
	return stars
