class_name Formulas
extends RefCounted

enum Stat { CAPACITY, OUTPUT, RATE, LINK_RANGE, ATTACK_RANGE, DAMAGE, COOLDOWN, SHOT_ENERGY, MAX_HP, COUNT }


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
		stats[Stat.DAMAGE] = base_damage * multiplier(building, GameConfig.TRACK_POWER) * building.boost(GameConfig.BOOST_DAMAGE)
		stats[Stat.COOLDOWN] = base_cooldown / multiplier(building, GameConfig.TRACK_SPEED)
	else:
		stats[Stat.ATTACK_RANGE] = base_range
		stats[Stat.DAMAGE] = base_damage
		stats[Stat.COOLDOWN] = base_cooldown
	stats[Stat.SHOT_ENERGY] = float(attack(building).get("energy", 0.0)) / efficiency(building)
	stats[Stat.MAX_HP] = float(building.definition().get("hp", 1.0)) * multiplier(building, GameConfig.TRACK_HULL) * building.boost(GameConfig.BOOST_HP)
	return stats


static func multiplier(building: Building, track: String) -> float:
	return 1.0 + float(GameConfig.TRACKS[track].step) * building.level(track)


static func efficiency(building: Building) -> float:
	return multiplier(building, GameConfig.TRACK_EFFICIENCY)


static func capacity(building: Building) -> float:
	return building.stat(Stat.CAPACITY)


static func output(building: Building) -> float:
	return building.stat(Stat.OUTPUT)


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


static func damage(building: Building) -> float:
	return building.stat(Stat.DAMAGE)


static func cooldown(building: Building) -> float:
	return building.stat(Stat.COOLDOWN)


static func shot_energy(building: Building) -> float:
	return building.stat(Stat.SHOT_ENERGY)


static func crit_chance(building: Building) -> float:
	return GameConfig.CRIT_CHANCE + float(GameConfig.TRACKS[GameConfig.TRACK_CRIT].step) * building.level(GameConfig.TRACK_CRIT)


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


static func upgrade_base(kind: String) -> int:
	var definition := GameConfig.building(kind)
	return int(definition.get("upgrade_base", definition.get("cost", 0)))


static func upgrade_cost(building: Building, track: String) -> int:
	var config: Dictionary = GameConfig.TRACKS[track]
	var growth := float(config.get("growth", GameConfig.TRACK_GROWTH))
	return maxi(int(round(upgrade_base(building.kind) * float(config.price) * pow(growth, building.level(track)))), 1)


static func max_level(track: String) -> int:
	return int(GameConfig.TRACKS[track].max)


static func is_maxed(building: Building, track: String) -> bool:
	return building.level(track) >= max_level(track)


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


static func wave_times(level: Dictionary) -> int:
	var span := DayCycle.length(level) - GameConfig.WAVE_FIRST
	return int(ceil(span / float(level.waves.interval))) if span > 0.0 else 0


static func wave_time(level: Dictionary, index: int) -> float:
	return GameConfig.WAVE_FIRST + float(level.waves.interval) * index


static func wave_count(waves: Dictionary, round_number: int, progress: float, night: bool) -> float:
	var count := float(waves.base) * (1.0 + float(waves.ramp) * clampf(progress, 0.0, 1.0)) * (1.0 + float(waves.growth) * maxi(round_number - 1, 0))
	return count * float(waves.night) if night else count


static func wave_tier(round_number: int) -> int:
	return maxi(round_number - 1, 0)


static func enemy_hp_scale(round_number: int) -> float:
	return pow(GameConfig.ROUND_HP_GROWTH, maxi(round_number - 1, 0))


static func enemy_damage_scale(round_number: int) -> float:
	return 1.0 + GameConfig.ROUND_DAMAGE_GROWTH * maxi(round_number - 1, 0)


static func enemy_bounty_scale(round_number: int) -> float:
	return 1.0 + GameConfig.ROUND_BOUNTY_GROWTH * maxi(round_number - 1, 0)


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
