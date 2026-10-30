extends GutTest

var battle: Battle
var core: Building
var map: LevelMap


func before_each() -> void:
	battle = BattleFixtures.battle(GameConfig.level_count() - 1, false)
	core = battle.state.core()
	map = battle.state.map


func _cell(offset: Vector2i) -> Vector2:
	return map.center_of(core.origin + offset)


func _enclose(low: Vector2i, high: Vector2i) -> void:
	var cells: Array[Vector2i] = []
	for x in range(low.x, high.x + 1):
		cells.append(core.origin + Vector2i(x, low.y))
		cells.append(core.origin + Vector2i(x, high.y))
	for y in range(low.y + 1, high.y):
		cells.append(core.origin + Vector2i(low.x, y))
		cells.append(core.origin + Vector2i(high.x, y))
	BattleFixtures.wall(battle, cells)


func _powered(kind: String, offset: Vector2i) -> Building:
	var building := BattleFixtures.add(battle, kind, _cell(offset))
	building.energy = Formulas.capacity(building)
	return building


func _run(seconds: float) -> void:
	for i in int(seconds / GameConfig.TICK):
		battle.ai.update(GameConfig.TICK)


func test_enemy_walks_toward_target() -> void:
	var crawler := BattleFixtures.enemy(battle, "crawler", core.position + Vector2(0, -500))
	var before := core.edge_distance(crawler.position)
	_run(1.0)
	assert_lt(core.edge_distance(crawler.position), before - 40.0)
	assert_eq(crawler.target_id, core.id)


func test_melee_attack_when_in_reach() -> void:
	var crawler := BattleFixtures.enemy(battle, "crawler", core.position + Vector2(0, -core.half_extent() - 8.0))
	var bite := float(GameConfig.enemy("crawler").damage)
	battle.ai.update(0.1)
	assert_eq(core.hp, core.max_hp() - bite)
	assert_almost_eq(crawler.cooldown, float(GameConfig.enemy("crawler").cooldown), 0.001)
	battle.ai.update(0.1)
	assert_eq(core.hp, core.max_hp() - bite)
	var attack := BattleFixtures.of_type(battle.events.drain(), "enemy_attack")
	assert_false(attack[0].ranged)


func test_ranged_enemy_stops_at_reach() -> void:
	var start := core.position + Vector2(0, -core.half_extent() - 105.0)
	var soldier := BattleFixtures.enemy(battle, "soldier", start)
	battle.ai.update(0.1)
	assert_eq(soldier.position, start)
	assert_eq(core.hp, core.max_hp() - float(GameConfig.enemy("soldier").damage))
	assert_true(BattleFixtures.of_type(battle.events.drain(), "enemy_attack")[0].ranged)


func test_reach_helpers() -> void:
	var crawler := Enemy.new(1, "crawler", Vector2.ZERO)
	var soldier := Enemy.new(2, "soldier", Vector2.ZERO)
	assert_eq(EnemyAI.reach_distance(crawler), 10.0 + GameConfig.MELEE_GAP)
	assert_eq(EnemyAI.reach_distance(soldier), 120.0)
	crawler.position = core.position + Vector2(core.half_extent() + 10.0, 0)
	assert_true(EnemyAI.in_reach(crawler, core))
	crawler.position.x += 10.0
	assert_false(EnemyAI.in_reach(crawler, core))
	assert_eq(EnemyAI.closest_point(core, core.position + Vector2(500, 0)), core.position + Vector2(core.half_extent(), 0))


func test_move_does_not_overshoot() -> void:
	var crawler := BattleFixtures.enemy(battle, "crawler", Vector2(100, 100))
	battle.ai.move(crawler, Vector2(110, 100), 1.0)
	assert_eq(crawler.position, Vector2(110, 100))


func test_targets_follow_priority() -> void:
	var crawler := BattleFixtures.enemy(battle, "crawler", _cell(Vector2i(0, -9)))
	var relay := _powered(GameConfig.RELAY, Vector2i(4, 0))
	assert_eq(battle.ai.choose_target(crawler), relay)
	var wall := BattleFixtures.add(battle, GameConfig.BULWARK, _cell(Vector2i(-4, 0)))
	assert_eq(battle.ai.choose_target(crawler), wall)
	var zapper := _powered(GameConfig.ZAPPER, Vector2i(6, 2))
	assert_eq(battle.ai.choose_target(crawler), zapper)
	var healer := _powered(GameConfig.HEALER, Vector2i(-6, 2))
	assert_eq(battle.ai.choose_target(crawler), healer)
	var exporter := _powered(GameConfig.EXPORTER, Vector2i(0, 4))
	assert_eq(battle.ai.choose_target(crawler), exporter)


func test_powerless_buildings_rank_just_above_core() -> void:
	var crawler := BattleFixtures.enemy(battle, "crawler", _cell(Vector2i(0, -9)))
	var zapper := BattleFixtures.add(battle, GameConfig.ZAPPER, _cell(Vector2i(0, -4)))
	zapper.energy = 0.0
	var relay := _powered(GameConfig.RELAY, Vector2i(5, 3))
	assert_eq(battle.ai.choose_target(crawler), relay)
	relay.energy = 0.0
	assert_eq(battle.ai.choose_target(crawler), zapper)
	battle.state.remove_building(zapper.id)
	battle.state.remove_building(relay.id)
	assert_eq(battle.ai.choose_target(crawler), core)


func test_walled_base_forces_melee_onto_bulwarks() -> void:
	_enclose(Vector2i(-3, -3), Vector2i(4, 4))
	var zapper := _powered(GameConfig.ZAPPER, Vector2i(0, -2))
	var crawler := BattleFixtures.enemy(battle, "crawler", _cell(Vector2i(0, -9)))
	battle.ai.update(GameConfig.TICK)
	var target := battle.state.building(crawler.target_id)
	assert_eq(target.kind, GameConfig.BULWARK)
	_run(12.0)
	assert_lt(target.hp, target.max_hp())
	assert_eq(zapper.hp, zapper.max_hp())
	assert_eq(core.hp, core.max_hp())


func test_ranged_cannot_hit_unreachable_buildings_in_range() -> void:
	_enclose(Vector2i(-3, -3), Vector2i(4, 4))
	var zapper := _powered(GameConfig.ZAPPER, Vector2i(0, -2))
	var soldier := BattleFixtures.enemy(battle, "soldier", _cell(Vector2i(0, -4)) + Vector2(0, -20))
	assert_lt(zapper.edge_distance(soldier.position), EnemyAI.reach_distance(soldier))
	_run(3.0)
	assert_eq(zapper.hp, zapper.max_hp())
	assert_eq(battle.state.building(soldier.target_id).kind, GameConfig.BULWARK)


func test_flyers_ignore_walls() -> void:
	_enclose(Vector2i(-3, -3), Vector2i(4, 4))
	var zapper := _powered(GameConfig.ZAPPER, Vector2i(0, -2))
	var wasp := BattleFixtures.enemy(battle, "wasp", _cell(Vector2i(0, -9)))
	_run(8.0)
	assert_eq(wasp.target_id, zapper.id)
	assert_lt(zapper.hp, zapper.max_hp())


func test_flyers_prefer_bastion_over_everything() -> void:
	_powered(GameConfig.ZAPPER, Vector2i(0, -2))
	var bastion := _powered(GameConfig.BASTION, Vector2i(6, 6))
	var wasp := BattleFixtures.enemy(battle, "wasp", _cell(Vector2i(0, -9)))
	assert_eq(battle.ai.choose_target(wasp), bastion)


func test_ground_units_ignore_bastion_lure() -> void:
	var bastion := _powered(GameConfig.BASTION, Vector2i(6, 6))
	var crawler := BattleFixtures.enemy(battle, "crawler", _cell(Vector2i(0, -9)))
	assert_ne(battle.ai.choose_target(crawler), bastion)


func test_ground_units_path_around_chasms() -> void:
	for x in range(-12, 13):
		if x != 8:
			map.set_tile(core.origin + Vector2i(x, -5), LevelMap.Tile.CHASM)
			battle.state.nav.terrain_changed(core.origin + Vector2i(x, -5))
	var crawler := BattleFixtures.enemy(battle, "crawler", _cell(Vector2i(0, -9)))
	for i in int(20.0 / GameConfig.TICK):
		battle.ai.update(GameConfig.TICK)
		assert_ne(map.tile(map.cell_of(crawler.position)), LevelMap.Tile.CHASM)
	assert_lt(core.hp, core.max_hp())


func test_unrelated_changes_keep_the_path() -> void:
	var crawler := BattleFixtures.enemy(battle, "crawler", _cell(Vector2i(0, -9)))
	battle.ai.update(GameConfig.TICK)
	var version := crawler.path_version
	BattleFixtures.add(battle, GameConfig.BULWARK, _cell(Vector2i(8, 6)))
	battle.ai.update(GameConfig.TICK)
	assert_eq(crawler.path_version, version)


func test_wall_on_the_path_triggers_repath() -> void:
	var crawler := BattleFixtures.enemy(battle, "crawler", _cell(Vector2i(0, -9)))
	battle.ai.update(GameConfig.TICK)
	var waypoint := map.cell_of(crawler.path[crawler.path_index])
	BattleFixtures.add(battle, GameConfig.BULWARK, map.center_of(waypoint))
	battle.ai.update(GameConfig.TICK)
	battle.ai.update(GameConfig.TICK)
	assert_eq(crawler.path_version, battle.state.nav.version)
	for point in crawler.path:
		assert_ne(map.cell_of(point), waypoint)


func test_path_budget_limits_planning() -> void:
	var crawlers: Array[Enemy] = []
	for i in GameConfig.PATHS_PER_TICK + 3:
		crawlers.append(BattleFixtures.enemy(battle, "crawler", _cell(Vector2i(-6 + i, -10))))
	battle.ai.update(GameConfig.TICK)
	var planned := crawlers.filter(func(enemy: Enemy) -> bool: return enemy.path_version == battle.state.nav.version).size()
	assert_eq(planned, GameConfig.PATHS_PER_TICK)
	battle.ai.update(GameConfig.TICK)
	planned = crawlers.filter(func(enemy: Enemy) -> bool: return enemy.path_version == battle.state.nav.version).size()
	assert_eq(planned, crawlers.size())


func test_retarget_after_destruction() -> void:
	var relay := _powered(GameConfig.RELAY, Vector2i(0, -6))
	var crawler := BattleFixtures.enemy(battle, "crawler", _cell(Vector2i(0, -8)))
	battle.ai.update(0.1)
	assert_eq(crawler.target_id, relay.id)
	battle.combat.destroy(relay)
	battle.ai.update(0.1)
	assert_eq(crawler.target_id, core.id)


func test_idle_without_targets() -> void:
	battle.state.remove_building(core.id)
	var crawler := BattleFixtures.enemy(battle, "crawler", Vector2(300, 300))
	battle.ai.update(0.5)
	assert_eq(crawler.position, Vector2(300, 300))
	assert_eq(crawler.target_id, -1)


func test_saboteur_cuts_links() -> void:
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, _cell(Vector2i(4, 0)))
	battle.network.connect_buildings(core.id, relay.id)
	var saboteur := BattleFixtures.enemy(battle, "saboteur", _cell(Vector2i(2, -5)))
	_run(6.0)
	assert_true(battle.state.links.is_empty())
	var unlink := BattleFixtures.of_type(battle.events.drain(), "unlink")
	assert_eq(unlink[0].cause, "sabotage")
	assert_eq(saboteur.target_link, "")


func test_saboteur_ignores_walled_links() -> void:
	_enclose(Vector2i(-3, -3), Vector2i(6, 4))
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, _cell(Vector2i(4, 0)))
	battle.network.connect_buildings(core.id, relay.id)
	var saboteur := BattleFixtures.enemy(battle, "saboteur", _cell(Vector2i(2, -6)))
	assert_true(battle.ai.reachable_link(saboteur).is_empty())
	_run(4.0)
	assert_eq(battle.state.links.size(), 1)
	assert_eq(battle.state.building(saboteur.target_id).kind, GameConfig.BULWARK)


func test_saboteur_attacks_buildings_without_links() -> void:
	BattleFixtures.enemy(battle, "saboteur", core.position + Vector2(0, -core.half_extent() - 8.0))
	battle.ai.update(0.1)
	assert_eq(core.hp, core.max_hp() - float(GameConfig.enemy("saboteur").damage))


func test_nearest_link() -> void:
	assert_null(battle.ai.nearest_link(Vector2.ZERO))
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(200, 0))
	battle.network.connect_buildings(core.id, relay.id)
	assert_eq(battle.ai.nearest_link(core.position + Vector2(100, 30)), battle.state.links[0])


func test_cached_ranking_refreshes_on_new_buildings_and_over_time() -> void:
	var crawler := BattleFixtures.enemy(battle, "crawler", _cell(Vector2i(0, -9)))
	battle.ai.update(GameConfig.TICK)
	assert_eq(crawler.target_id, core.id)
	var relay := _powered(GameConfig.RELAY, Vector2i(4, 0))
	crawler.retarget_timer = 0.0
	battle.ai.update(GameConfig.TICK)
	assert_eq(crawler.target_id, relay.id)
	var zapper := BattleFixtures.add(battle, GameConfig.ZAPPER, _cell(Vector2i(-4, 0)))
	zapper.energy = 0.0
	crawler.retarget_timer = 0.0
	battle.ai.update(GameConfig.TICK)
	assert_eq(crawler.target_id, relay.id)
	zapper.energy = Formulas.capacity(zapper)
	crawler.retarget_timer = 0.0
	battle.ai.update(GameConfig.TICK)
	assert_eq(crawler.target_id, relay.id)
	_run(GameConfig.TARGET_SCAN + 0.05)
	crawler.retarget_timer = 0.0
	battle.ai.update(GameConfig.TICK)
	assert_eq(crawler.target_id, zapper.id)


func test_cut_cells_lie_next_to_the_beam_and_skip_blocked_cells() -> void:
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, _cell(Vector2i(5, 0)))
	battle.network.connect_buildings(core.id, relay.id)
	var link: EnergyLink = battle.state.links[0]
	var cells := battle.ai.cut_cells(link)
	assert_false(cells.is_empty())
	var points := battle.state.link_points(link)
	for cell in cells:
		assert_true(battle.state.nav.is_free(cell))
		var middle := map.center_of(cell)
		assert_lte(middle.distance_to(Geometry2D.get_closest_point_to_segment(middle, points[0], points[1])), GameConfig.CELL * GameConfig.SABOTAGE_CUT)
	var blocked := cells[0]
	BattleFixtures.add(battle, GameConfig.BULWARK, map.center_of(blocked))
	assert_false(battle.ai.cut_cells(link).has(blocked))


func test_saboteur_replans_when_switching_links() -> void:
	var left := BattleFixtures.add(battle, GameConfig.RELAY, _cell(Vector2i(-3, 0)))
	var right := BattleFixtures.add(battle, GameConfig.RELAY, _cell(Vector2i(5, 0)))
	battle.network.connect_buildings(core.id, left.id)
	var saboteur := BattleFixtures.enemy(battle, "saboteur", _cell(Vector2i(6, -8)))
	assert_eq(battle.state.links.size(), 1)
	battle.ai.update(GameConfig.TICK)
	assert_eq(saboteur.target_link, battle.state.links[0].key())
	var first_cell := saboteur.link_cell
	battle.network.connect_buildings(core.id, right.id)
	saboteur.retarget_timer = 0.0
	battle.ai.update(GameConfig.TICK)
	assert_eq(saboteur.target_link, EnergyLink.key_of(core.id, right.id))
	assert_ne(saboteur.link_cell, first_cell)
	assert_eq(map.cell_of(saboteur.path[saboteur.path.size() - 1]), saboteur.link_cell)
	_run(8.0)
	assert_false(battle.state.links.any(func(link: EnergyLink) -> bool: return link.target == right.id))


func _crowd(target: Building, count: int, kind: String = "crawler") -> void:
	for i in count:
		var unit := BattleFixtures.enemy(battle, kind, _cell(Vector2i(0, -9)))
		unit.target_id = target.id


func _picks(enemy: Enemy, tries: int) -> Dictionary:
	var picks := {}
	for i in tries:
		var target := battle.ai.choose_target(enemy)
		picks[target.id] = int(picks.get(target.id, 0)) + 1
	return picks


func test_crowded_target_sends_further_attackers_to_equal_peers() -> void:
	var near := BattleFixtures.add(battle, GameConfig.BULWARK, _cell(Vector2i(0, -5)))
	var side := BattleFixtures.add(battle, GameConfig.BULWARK, _cell(Vector2i(2, -5)))
	var relay := _powered(GameConfig.RELAY, Vector2i(-1, -7))
	_crowd(near, GameConfig.SPREAD_CROWD)
	var picks := _picks(BattleFixtures.enemy(battle, "crawler", _cell(Vector2i(0, -9))), 60)
	assert_gt(int(picks.get(near.id, 0)), 0)
	assert_gt(int(picks.get(side.id, 0)), 0)
	assert_false(picks.has(relay.id))
	assert_false(picks.has(core.id))


func test_below_the_crowd_limit_everyone_takes_the_best_target() -> void:
	var near := BattleFixtures.add(battle, GameConfig.BULWARK, _cell(Vector2i(0, -5)))
	BattleFixtures.add(battle, GameConfig.BULWARK, _cell(Vector2i(2, -5)))
	_crowd(near, GameConfig.SPREAD_CROWD - 1)
	var picks := _picks(BattleFixtures.enemy(battle, "crawler", _cell(Vector2i(0, -9))), 30)
	assert_eq(picks, {near.id: 30})


func test_spreading_never_drops_to_a_lower_priority() -> void:
	var wall := BattleFixtures.add(battle, GameConfig.BULWARK, _cell(Vector2i(0, -5)))
	_powered(GameConfig.RELAY, Vector2i(1, -6))
	_crowd(wall, GameConfig.SPREAD_CROWD + 2)
	var picks := _picks(BattleFixtures.enemy(battle, "crawler", _cell(Vector2i(0, -9))), 30)
	assert_eq(picks, {wall.id: 30})


func test_spreading_ignores_unreachable_peers() -> void:
	_enclose(Vector2i(-3, -3), Vector2i(4, 4))
	var inner := BattleFixtures.add(battle, GameConfig.BULWARK, _cell(Vector2i(-1, -2)))
	var crawler := BattleFixtures.enemy(battle, "crawler", _cell(Vector2i(0, -9)))
	var best := battle.ai.choose_target(crawler)
	_crowd(best, GameConfig.SPREAD_CROWD)
	var picks := _picks(crawler, 60)
	assert_false(picks.has(inner.id))
	assert_gt(picks.size(), 1)
	for id: int in picks:
		assert_eq(battle.state.building(id).kind, GameConfig.BULWARK)


func test_spreading_stays_close_to_the_crowded_target() -> void:
	var near := BattleFixtures.add(battle, GameConfig.BULWARK, _cell(Vector2i(0, -5)))
	var far := BattleFixtures.add(battle, GameConfig.BULWARK, _cell(Vector2i(int(GameConfig.SPREAD_REACH) + 6, -5)))
	_crowd(near, GameConfig.SPREAD_CROWD)
	var picks := _picks(BattleFixtures.enemy(battle, "crawler", _cell(Vector2i(0, -9))), 30)
	assert_false(picks.has(far.id))


func test_committed_and_diverted_attackers_keep_their_targets() -> void:
	var near := BattleFixtures.add(battle, GameConfig.BULWARK, _cell(Vector2i(0, -5)))
	var side := BattleFixtures.add(battle, GameConfig.BULWARK, _cell(Vector2i(2, -5)))
	_crowd(near, GameConfig.SPREAD_CROWD)
	var committed := BattleFixtures.enemy(battle, "crawler", _cell(Vector2i(0, -9)))
	committed.target_id = near.id
	assert_eq(_picks(committed, 20), {near.id: 20})
	var diverted := BattleFixtures.enemy(battle, "crawler", _cell(Vector2i(0, -9)))
	diverted.target_id = side.id
	assert_eq(_picks(diverted, 20), {side.id: 20})


func test_diverted_attackers_return_once_the_crowd_thins() -> void:
	var near := BattleFixtures.add(battle, GameConfig.BULWARK, _cell(Vector2i(0, -5)))
	var side := BattleFixtures.add(battle, GameConfig.BULWARK, _cell(Vector2i(2, -5)))
	_crowd(near, GameConfig.SPREAD_CROWD - 1)
	var diverted := BattleFixtures.enemy(battle, "crawler", _cell(Vector2i(0, -9)))
	diverted.target_id = side.id
	assert_eq(battle.ai.choose_target(diverted), near)


func test_flyers_spread_between_bastions() -> void:
	var first := _powered(GameConfig.BASTION, Vector2i(0, -4))
	var second := _powered(GameConfig.BASTION, Vector2i(3, -4))
	var zapper := _powered(GameConfig.ZAPPER, Vector2i(0, -2))
	_crowd(first, GameConfig.SPREAD_CROWD, "wasp")
	var picks := _picks(BattleFixtures.enemy(battle, "wasp", _cell(Vector2i(0, -9))), 60)
	assert_gt(int(picks.get(first.id, 0)), 0)
	assert_gt(int(picks.get(second.id, 0)), 0)
	assert_false(picks.has(zapper.id))


func test_update_tracks_the_load_and_splits_a_wave() -> void:
	var near := BattleFixtures.add(battle, GameConfig.BULWARK, _cell(Vector2i(0, -5)))
	var side := BattleFixtures.add(battle, GameConfig.BULWARK, _cell(Vector2i(2, -5)))
	var wave: Array[Enemy] = []
	for i in 30:
		wave.append(BattleFixtures.enemy(battle, "crawler", _cell(Vector2i(0, -9))))
	battle.ai.update(GameConfig.TICK)
	assert_gte(battle.ai.load_of(near.id), GameConfig.SPREAD_CROWD)
	assert_gt(battle.ai.load_of(side.id), 0)
	assert_eq(battle.ai.load_of(near.id) + battle.ai.load_of(side.id), wave.size())
	for enemy in wave:
		assert_true(enemy.target_id == near.id or enemy.target_id == side.id)
	assert_eq(battle.ai.load_of(near.id), wave.filter(func(enemy: Enemy) -> bool: return enemy.target_id == near.id).size())


func test_guards_and_link_hunters_do_not_count_as_load() -> void:
	var wall := BattleFixtures.add(battle, GameConfig.BULWARK, _cell(Vector2i(0, -5)))
	var guard := BattleFixtures.enemy(battle, "beetle", _cell(Vector2i(0, -12)))
	guard.make_guard(core.id, 0.0, 1.0)
	guard.target_id = wall.id
	var hunter := BattleFixtures.enemy(battle, "saboteur", _cell(Vector2i(0, -12)))
	hunter.target_id = wall.id
	hunter.target_link = "1-2"
	var crawler := BattleFixtures.enemy(battle, "crawler", _cell(Vector2i(0, -9)))
	crawler.target_id = wall.id
	battle.ai.choose_target(crawler)
	assert_eq(battle.ai.load_of(wall.id), 1)
	assert_eq(battle.ai.load_of(4242), 0)
