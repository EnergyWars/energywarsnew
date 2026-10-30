extends GutTest


func _building(kind: String, energy: float = -1.0) -> Building:
	var building := Building.new(1, kind, Vector2.ZERO)
	building.energy = Formulas.capacity(building) if energy < 0.0 else energy
	return building


func test_tiers_follow_requested_order() -> void:
	var exporter := Targeting.tier(_building(GameConfig.EXPORTER))
	var healer := Targeting.tier(_building(GameConfig.HEALER))
	var tower := Targeting.tier(_building(GameConfig.ZAPPER))
	var wall := Targeting.tier(_building(GameConfig.BULWARK))
	var relay := Targeting.tier(_building(GameConfig.RELAY))
	var battery := Targeting.tier(_building(GameConfig.BATTERY))
	var core := Targeting.tier(_building(GameConfig.CORE))
	assert_gt(exporter, healer)
	assert_gt(healer, tower)
	assert_gt(tower, wall)
	assert_gt(wall, relay)
	assert_eq(relay, battery)
	assert_gt(relay, core)
	assert_eq(Targeting.tier(_building(GameConfig.SHIELD)), tower)
	assert_eq(Targeting.tier(_building(GameConfig.PLASMA)), tower)


func test_idle_buildings_drop_to_just_above_core() -> void:
	assert_eq(Targeting.tier(_building(GameConfig.EXPORTER, 0.0)), Targeting.TIER_IDLE)
	assert_eq(Targeting.tier(_building(GameConfig.ZAPPER, 1.0)), Targeting.TIER_IDLE)
	assert_eq(Targeting.tier(_building(GameConfig.HEALER, 2.0)), Targeting.TIER_IDLE)
	assert_eq(Targeting.tier(_building(GameConfig.BATTERY, 0.0)), Targeting.TIER_IDLE)
	assert_eq(Targeting.tier(_building(GameConfig.CORE, 0.0)), Targeting.TIER_CORE)
	assert_eq(Targeting.tier(_building(GameConfig.BULWARK, 0.0)), Targeting.TIER_WALL)
	assert_gt(Targeting.TIER_IDLE, Targeting.TIER_CORE)
	assert_lt(Targeting.TIER_IDLE, Targeting.TIER_GRID)


func test_needed_energy() -> void:
	assert_eq(Targeting.needed_energy(_building(GameConfig.ZAPPER)), 4.0)
	assert_almost_eq(Targeting.needed_energy(_building(GameConfig.LASER)), 0.5, 0.001)
	assert_eq(Targeting.needed_energy(_building(GameConfig.HEALER)), 6.0)
	assert_eq(Targeting.needed_energy(_building(GameConfig.RELAY)), 0.5)


func test_best_prefers_tier_then_distance() -> void:
	var near := Building.new(1, GameConfig.RELAY, Vector2(100, 0))
	var far := Building.new(2, GameConfig.RELAY, Vector2(400, 0))
	var tower := Building.new(3, GameConfig.ZAPPER, Vector2(900, 0))
	for building in [near, far, tower]:
		building.energy = Formulas.capacity(building)
	assert_eq(Targeting.best(Vector2.ZERO, [near, far] as Array[Building]), near)
	assert_eq(Targeting.best(Vector2.ZERO, [far, near, tower] as Array[Building]), tower)
	assert_null(Targeting.best(Vector2.ZERO, [] as Array[Building]))


func test_base_tier_and_idle_flags() -> void:
	assert_eq(Targeting.base_tier(GameConfig.CORE), Targeting.TIER_CORE)
	assert_eq(Targeting.base_tier(GameConfig.EXPORTER), Targeting.TIER_EXPORTER)
	assert_eq(Targeting.base_tier(GameConfig.HEALER), Targeting.TIER_HEALER)
	assert_false(Targeting.is_idle(_building(GameConfig.BULWARK, 0.0)))
	assert_true(Targeting.is_idle(_building(GameConfig.RELAY, 0.0)))
	assert_false(Targeting.is_idle(_building(GameConfig.RELAY)))


func test_best_ranked_skips_destroyed_buildings() -> void:
	var tower := Building.new(1, GameConfig.ZAPPER, Vector2(100, 0))
	var relay := Building.new(2, GameConfig.RELAY, Vector2(300, 0))
	tower.energy = Formulas.capacity(tower)
	relay.energy = Formulas.capacity(relay)
	var ranked := Targeting.rank([tower, relay] as Array[Building])
	assert_eq(ranked[0][1], Targeting.TIER_DEFENSE)
	assert_eq(Targeting.best_ranked(Vector2.ZERO, ranked), tower)
	tower.hp = 0.0
	assert_eq(Targeting.best_ranked(Vector2.ZERO, ranked), relay)


func test_lure_picks_nearest_living_bastion() -> void:
	var far := _building(GameConfig.BASTION)
	far.position = Vector2(500, 0)
	var near := _building(GameConfig.BASTION)
	near.position = Vector2(100, 0)
	var zapper := _building(GameConfig.ZAPPER)
	var candidates: Array[Building] = [far, zapper, near]
	assert_eq(Targeting.lure(Vector2.ZERO, candidates), near)
	near.hp = 0.0
	assert_eq(Targeting.lure(Vector2.ZERO, candidates), far)
	far.hp = 0.0
	assert_null(Targeting.lure(Vector2.ZERO, candidates))


func test_lures_lists_living_bastions_only() -> void:
	var bastion := _building(GameConfig.BASTION)
	var fallen := _building(GameConfig.BASTION)
	fallen.hp = 0.0
	var zapper := _building(GameConfig.ZAPPER)
	assert_eq(Targeting.lures([bastion, fallen, zapper] as Array[Building]), [bastion] as Array[Building])
	assert_true(Targeting.lures([] as Array[Building]).is_empty())


func test_walls_keep_their_tier_with_or_without_energy() -> void:
	var wall := _building(GameConfig.BULWARK)
	assert_true(wall.repairing)
	assert_false(Targeting.is_idle(wall))
	assert_eq(Targeting.tier(wall), Targeting.TIER_WALL)
	wall.energy = 0.0
	assert_eq(Targeting.tier(wall), Targeting.TIER_WALL)


func test_peers_are_the_living_buildings_of_the_top_tier() -> void:
	var dead := Building.new(1, GameConfig.ZAPPER, Vector2(50, 0))
	var tower := Building.new(2, GameConfig.ZAPPER, Vector2(100, 0))
	var laser := Building.new(3, GameConfig.LASER, Vector2(400, 0))
	var relay := Building.new(4, GameConfig.RELAY, Vector2(10, 0))
	for building in [dead, tower, laser, relay]:
		building.energy = Formulas.capacity(building)
	dead.hp = 0.0
	var ranked := Targeting.rank([dead, tower, laser, relay] as Array[Building])
	var peers := Targeting.peers(ranked)
	assert_eq(peers.size(), 2)
	assert_true(peers.has(tower))
	assert_true(peers.has(laser))
	tower.hp = 0.0
	laser.hp = 0.0
	assert_eq(Targeting.peers(ranked), [relay] as Array[Building])
	assert_true(Targeting.peers([]).is_empty())


func test_spread_picks_an_uncrowded_peer_nearby() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var best := Building.new(1, GameConfig.BULWARK, Vector2(100, 0))
	var near := Building.new(2, GameConfig.BULWARK, Vector2(160, 0))
	var crowded := Building.new(3, GameConfig.BULWARK, Vector2(130, 0))
	var far := Building.new(4, GameConfig.BULWARK, Vector2(100 + GameConfig.SPREAD_REACH * GameConfig.CELL + 200.0, 0))
	var candidates: Array[Building] = [best, near, crowded, far]
	var loads := {best.id: 5, crowded.id: GameConfig.SPREAD_CROWD}
	for i in 20:
		assert_eq(Targeting.spread(Vector2.ZERO, best, candidates, loads, rng), near)
	near.hp = 0.0
	assert_null(Targeting.spread(Vector2.ZERO, best, candidates, loads, rng))


func test_spread_chooses_randomly_among_the_nearest_options() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var best := Building.new(1, GameConfig.BULWARK, Vector2(100, 0))
	var candidates: Array[Building] = [best]
	for i in GameConfig.SPREAD_OPTIONS + 2:
		candidates.append(Building.new(10 + i, GameConfig.BULWARK, Vector2(100 + 56 * (i + 1), 0)))
	var seen := {}
	for i in 200:
		seen[Targeting.spread(Vector2.ZERO, best, candidates, {}, rng).id] = true
	assert_eq(seen.size(), GameConfig.SPREAD_OPTIONS)
	for i in GameConfig.SPREAD_OPTIONS:
		assert_true(seen.has(10 + i))
