extends GutTest

var battle: Battle
var state: BattleState
var core: Building


func before_each() -> void:
	battle = BattleFixtures.battle(0)
	state = battle.state
	core = state.core()


func test_roster_lists_follow_building_changes() -> void:
	var solar := BattleFixtures.add(battle, GameConfig.SOLAR, core.position + Vector2(120, 0))
	var zapper := BattleFixtures.add(battle, GameConfig.ZAPPER, core.position + Vector2(0, -120))
	var healer := BattleFixtures.add(battle, GameConfig.HEALER, core.position + Vector2(-120, 0))
	var wall := BattleFixtures.add(battle, GameConfig.BULWARK, core.position + Vector2(0, 120))
	assert_true(state.producers().has(solar))
	assert_false(state.producers().has(wall))
	assert_true(state.stores().has(solar))
	assert_false(state.stores().has(wall))
	assert_true(state.combatants().has(zapper))
	assert_true(state.combatants().has(healer))
	assert_false(state.combatants().has(solar))
	assert_eq(state.of_kind(GameConfig.ZAPPER), [zapper] as Array[Building])
	assert_eq(state.of_kind("missing"), BattleState.EMPTY_LIST)
	assert_true(state.player_buildings().has(wall))
	assert_false(state.enemy_buildings().has(wall))
	var version := state.roster_version
	battle.sell(zapper.id)
	assert_gt(state.roster_version, version)
	assert_false(state.combatants().has(zapper))
	assert_eq(state.count_kind(GameConfig.ZAPPER), 0)


func test_enemy_spawners_are_combatants_only_when_armed() -> void:
	for structure in state.enemy_buildings():
		assert_eq(state.combatants().has(structure), structure.armed)
		assert_false(state.producers().has(structure))


func test_outgoing_count_follows_links() -> void:
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(0, -150))
	var battery := BattleFixtures.add(battle, GameConfig.BATTERY, core.position + Vector2(150, 0))
	assert_eq(state.outgoing_count(core.id), 0)
	var version := state.links_version
	assert_eq(battle.connect_buildings(core.id, relay.id), EnergyNetwork.OK)
	assert_eq(battle.connect_buildings(core.id, battery.id), EnergyNetwork.OK)
	assert_gt(state.links_version, version)
	assert_eq(state.outgoing_count(core.id), 2)
	assert_eq(state.outgoing_count(relay.id), 0)
	battle.network.remove_links_of(battery.id)
	assert_eq(state.outgoing_count(core.id), 1)


func test_network_groups_are_rebuilt_only_when_links_change() -> void:
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(0, -150))
	var solar := BattleFixtures.add(battle, GameConfig.SOLAR, core.position + Vector2(150, 0))
	var battery := BattleFixtures.add(battle, GameConfig.BATTERY, core.position + Vector2(-150, 0))
	assert_eq(battle.connect_buildings(core.id, relay.id), EnergyNetwork.OK)
	assert_eq(battle.connect_buildings(solar.id, core.id), EnergyNetwork.OK)
	var groups := battle.network.groups()
	assert_eq(groups.size(), 2)
	assert_same(battle.network.groups(), groups)
	assert_eq(battle.connect_buildings(core.id, battery.id), EnergyNetwork.OK)
	var rebuilt := battle.network.groups()
	assert_ne(rebuilt.size(), 0)
	var core_group: Array = rebuilt.filter(func(group: Array) -> bool: return group[0] == core.id)[0]
	assert_eq(core_group[1].size(), 2)


func test_building_stats_are_cached_until_levels_or_elevation_change() -> void:
	var zapper := BattleFixtures.add(battle, GameConfig.ZAPPER, core.position + Vector2(0, -150))
	var damage := Formulas.damage(zapper)
	var reach := Formulas.attack_range(zapper)
	var hp := zapper.max_hp()
	zapper.set_level(GameConfig.TRACK_POWER, 3)
	assert_gt(Formulas.damage(zapper), damage)
	zapper.levels = {}
	assert_eq(Formulas.damage(zapper), damage)
	zapper.elevation = 1
	assert_gt(Formulas.attack_range(zapper), reach)
	zapper.set_level(GameConfig.TRACK_HULL, 2)
	assert_gt(zapper.max_hp(), hp)
	state.money = 100000
	var before := Formulas.capacity(zapper)
	assert_true(battle.upgrade(zapper.id, GameConfig.TRACK_CAPACITY))
	assert_gt(Formulas.capacity(zapper), before)


func test_enemy_structures_ignore_upgrades_in_stats() -> void:
	var nest: Building = state.enemy_buildings()[0]
	var hp := nest.max_hp()
	nest.set_level(GameConfig.TRACK_POWER, 5)
	assert_eq(Formulas.damage(nest), float(Formulas.attack(nest).get("damage", 0.0)))
	assert_eq(nest.max_hp(), hp)


func test_building_geometry_is_cached_from_definition() -> void:
	var wall := Building.new(1, GameConfig.BULWARK, Vector2(100, 100))
	assert_eq(wall.cells(), GameConfig.cells(GameConfig.BULWARK))
	assert_eq(wall.half_extent(), wall.cells() * GameConfig.CELL * 0.5)
	assert_eq(wall.edge_distance(wall.position), 0.0)
	assert_almost_eq(wall.edge_distance(wall.position + Vector2(wall.half_extent() + 30.0, wall.half_extent() + 40.0)), 50.0, 0.001)
	assert_eq(wall.radius(), float(GameConfig.building(GameConfig.BULWARK).get("radius", 20.0)))


func test_enemy_flags_are_cached_from_definition() -> void:
	for kind: String in GameConfig.ENEMIES:
		var definition: Dictionary = GameConfig.enemy(kind)
		var enemy := Enemy.new(1, kind, Vector2.ZERO)
		assert_eq(enemy.speed(), float(definition.speed), kind)
		assert_eq(enemy.reach(), float(definition.reach), kind)
		assert_eq(enemy.is_saboteur(), bool(definition.get("sabotage", false)), kind)
		assert_eq(enemy.is_boss(), bool(definition.get("boss", false)), kind)
		assert_eq(enemy.is_air(), definition.get("class", GameConfig.CLASS_MELEE) == GameConfig.CLASS_AIR, kind)
		assert_eq(enemy.is_ranged(), definition.get("class", GameConfig.CLASS_MELEE) == GameConfig.CLASS_RANGED, kind)


func test_nav_blocked_cells_follow_occupancy_and_bounds() -> void:
	BattleFixtures.open_terrain(state)
	var spot := core.position + Vector2(0, -200)
	assert_false(state.nav.is_blocked_at(spot))
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, spot)
	assert_true(state.nav.is_blocked_at(relay.position))
	battle.sell(relay.id)
	assert_false(state.nav.is_blocked_at(relay.position))
	assert_true(state.nav.is_blocked_at(Vector2(-5, -5)))
	assert_false(state.nav.is_free(Vector2i(state.map.width, 0)))
	assert_false(state.nav.is_free(Vector2i(0, state.map.height)))


func test_ranked_targets_are_sorted_by_tier() -> void:
	var zapper := BattleFixtures.add(battle, GameConfig.ZAPPER, core.position + Vector2(0, -150))
	var wall := BattleFixtures.add(battle, GameConfig.BULWARK, core.position + Vector2(0, 150))
	zapper.energy = Formulas.capacity(zapper)
	var ranked := Targeting.rank(state.player_buildings())
	assert_eq(ranked.size(), state.player_buildings().size())
	for i in range(1, ranked.size()):
		assert_gte(int(ranked[i - 1][1]), int(ranked[i][1]))
	assert_eq(ranked[ranked.size() - 1][0], core)
	assert_true(ranked.any(func(entry: Array) -> bool: return entry[0] == zapper))
	assert_true(ranked.any(func(entry: Array) -> bool: return entry[0] == wall))
	assert_eq(Targeting.best_ranked(wall.position, ranked), zapper)
	zapper.hp = 0.0
	assert_eq(Targeting.best_ranked(zapper.position, ranked), wall)
