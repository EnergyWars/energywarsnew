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
