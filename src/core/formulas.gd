class_name Formulas
extends RefCounted


static func multiplier(building: Building, track: String) -> float:
	return 1.0 + float(GameConfig.TRACKS[track].step) * building.level(track)


static func capacity(building: Building) -> float:
	return float(building.definition().get("capacity", 0.0)) * multiplier(building, GameConfig.TRACK_CAPACITY)


static func output(building: Building) -> float:
	return float(building.definition().get("output", 0.0)) * multiplier(building, GameConfig.TRACK_OUTPUT)


static func rate(building: Building) -> float:
	return float(building.definition().get("rate", 0.0)) * multiplier(building, GameConfig.TRACK_RATE)


static func export_rate(building: Building) -> float:
	return float(building.definition().get("export", 0.0)) * multiplier(building, GameConfig.TRACK_RATE)


static func link_range(building: Building) -> float:
	return float(building.definition().get("range", 0.0)) * multiplier(building, GameConfig.TRACK_RANGE)


static func max_links(building: Building) -> int:
	var base := int(building.definition().get("links", 0))
	return base + building.level(GameConfig.TRACK_LINKS) if base > 0 else 0


static func build_radius(building: Building) -> float:
	return float(building.definition().get("build_radius", 0.0))


static func attack(building: Building) -> Dictionary:
	return building.definition().get("attack", {})


static func attack_range(building: Building) -> float:
	var base := float(attack(building).get("range", 0.0))
	return base * multiplier(building, GameConfig.TRACK_RANGE) * high_ground(building) if building.is_player() else base


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
	var base := float(attack(building).get("damage", 0.0))
	return base * multiplier(building, GameConfig.TRACK_POWER) if building.is_player() else base


static func cooldown(building: Building) -> float:
	var base := float(attack(building).get("cooldown", 0.0))
	return base / multiplier(building, GameConfig.TRACK_SPEED) if building.is_player() else base


static func shot_energy(building: Building) -> float:
	return float(attack(building).get("energy", 0.0))


static func shield_radius(building: Building) -> float:
	return float(building.definition().get("shield", {}).get("radius", 0.0)) * multiplier(building, GameConfig.TRACK_RANGE)


static func shield_ratio(building: Building) -> float:
	return GameConfig.SHIELD_RATIO * multiplier(building, GameConfig.TRACK_POWER)


static func heal(building: Building) -> Dictionary:
	return building.definition().get("heal", {})


static func heal_amount(building: Building) -> float:
	return float(heal(building).get("amount", 0.0)) * multiplier(building, GameConfig.TRACK_POWER)


static func heal_cooldown(building: Building) -> float:
	return float(heal(building).get("cooldown", 0.0)) / multiplier(building, GameConfig.TRACK_SPEED)


static func heal_range(building: Building) -> float:
	return float(heal(building).get("range", 0.0)) * multiplier(building, GameConfig.TRACK_RANGE)


static func heal_energy(building: Building) -> float:
	return float(heal(building).get("energy", 0.0))


static func upgrade_base(kind: String) -> int:
	var definition := GameConfig.building(kind)
	return int(definition.get("upgrade_base", definition.get("cost", 0)))


static func upgrade_cost(building: Building, track: String) -> int:
	var price := float(GameConfig.TRACKS[track].price)
	return int(round(upgrade_base(building.kind) * price * pow(GameConfig.TRACK_GROWTH, building.level(track))))


static func is_maxed(building: Building, track: String) -> bool:
	return building.level(track) >= int(GameConfig.TRACKS[track].max)


static func sell_value(building: Building) -> int:
	return int(floor(building.spent * GameConfig.SELL_REFUND))


static func cycle_count(spawns: Dictionary, cycle: int, night: bool) -> float:
	var count := minf(float(spawns.base) + float(spawns.growth) * maxi(cycle, 0), GameConfig.MAX_CYCLE_COUNT)
	return count * float(spawns.night) if night else count


static func pack_size(cycle: int) -> int:
	return mini(GameConfig.PACK_BASE + maxi(cycle, 0) / GameConfig.PACK_EVERY, GameConfig.PACK_MAX)


static func spawn_density(phase: float) -> float:
	var t := clampf(phase, 0.0, 1.0)
	return GameConfig.SPAWN_CALM + (1.0 - GameConfig.SPAWN_CALM) * 4.0 * t * t * t


static func spawn_rate(spawns: Dictionary, cycle: int, phase: float, night: bool) -> float:
	return cycle_count(spawns, cycle, night) / float(spawns.cycle) * spawn_density(phase)


static func combo_tier(count: int) -> int:
	var tier := 0
	for threshold in GameConfig.COMBO_TIERS:
		if count >= threshold:
			tier += 1
	return tier


static func combo_bonus(count: int) -> int:
	return count if GameConfig.COMBO_TIERS.has(count) else 0


static func stars(core_ratio: float, lost: int) -> int:
	if core_ratio >= GameConfig.STAR_CORE_GOOD and lost <= GameConfig.STAR_MAX_LOST:
		return 3
	if core_ratio >= GameConfig.STAR_CORE_OK:
		return 2
	return 1
