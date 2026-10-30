class_name Targeting
extends RefCounted

const TIER_CORE := 0
const TIER_IDLE := 1
const TIER_GRID := 2
const TIER_WALL := 3
const TIER_DEFENSE := 4
const TIER_HEALER := 5
const TIER_EXPORTER := 6


static func base_tier(kind: String) -> int:
	if kind == GameConfig.CORE:
		return TIER_CORE
	if kind == GameConfig.EXPORTER:
		return TIER_EXPORTER
	if GameConfig.building(kind).has("heal"):
		return TIER_HEALER
	if GameConfig.is_tower(kind) or GameConfig.building(kind).has("shield"):
		return TIER_DEFENSE
	if GameConfig.is_wall(kind):
		return TIER_WALL
	return TIER_GRID


static func lure(origin: Vector2, candidates: Array[Building]) -> Building:
	var result: Building = null
	var best_distance := INF
	for building in candidates:
		if not building.is_alive() or not building.definition().has("lure"):
			continue
		var distance := building.edge_distance(origin)
		if distance < best_distance:
			result = building
			best_distance = distance
	return result


static func tier(building: Building) -> int:
	var base := base_tier(building.kind)
	if base != TIER_CORE and is_idle(building):
		return TIER_IDLE
	return base


static func lures(candidates: Array[Building]) -> Array[Building]:
	var result: Array[Building] = []
	for building in candidates:
		if building.is_alive() and building.definition().has("lure"):
			result.append(building)
	return result


static func is_idle(building: Building) -> bool:
	if building.repairing or Formulas.capacity(building) <= 0.0:
		return false
	return building.energy < needed_energy(building)


static func needed_energy(building: Building) -> float:
	if GameConfig.has_attack(building.kind):
		var laser := str(Formulas.attack(building).mode) == GameConfig.MODE_LASER
		return maxf(Formulas.shot_energy(building) * (GameConfig.TICK if laser else 1.0), 0.5)
	if building.definition().has("heal"):
		return Formulas.heal_energy(building)
	return 0.5


static func rank(candidates: Array[Building]) -> Array:
	var buckets := []
	for i in TIER_EXPORTER + 1:
		buckets.append([])
	for building in candidates:
		var value := tier(building)
		buckets[value].append([building, value])
	var ranked := []
	for i in range(TIER_EXPORTER, -1, -1):
		ranked.append_array(buckets[i])
	return ranked


static func best(origin: Vector2, candidates: Array[Building]) -> Building:
	return best_ranked(origin, rank(candidates))


static func best_ranked(origin: Vector2, ranked: Array) -> Building:
	var result: Building = null
	var best_tier := -1
	var best_distance := INF
	for entry: Array in ranked:
		var rank_value: int = entry[1]
		if rank_value < best_tier:
			break
		var building: Building = entry[0]
		if not building.is_alive():
			continue
		var distance := building.edge_distance(origin)
		if rank_value > best_tier or distance < best_distance:
			result = building
			best_tier = rank_value
			best_distance = distance
	return result


static func peers(ranked: Array) -> Array[Building]:
	var result: Array[Building] = []
	var top := -1
	for entry: Array in ranked:
		var building: Building = entry[0]
		if not building.is_alive():
			continue
		var rank_value: int = entry[1]
		if top < 0:
			top = rank_value
		elif rank_value < top:
			break
		result.append(building)
	return result


static func spread(origin: Vector2, best: Building, candidates: Array[Building], loads: Dictionary, rng: RandomNumberGenerator) -> Building:
	var limit := best.edge_distance(origin) + GameConfig.SPREAD_REACH * GameConfig.CELL
	var options := []
	for building in candidates:
		if building == best or not building.is_alive() or int(loads.get(building.id, 0)) >= GameConfig.SPREAD_CROWD:
			continue
		var distance := building.edge_distance(origin)
		if distance <= limit:
			options.append([distance, building])
	if options.is_empty():
		return null
	options.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	return options[rng.randi_range(0, mini(options.size(), GameConfig.SPREAD_OPTIONS) - 1)][1]
