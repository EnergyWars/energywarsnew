extends GutTest

var progress: Progress


func before_each() -> void:
	progress = Progress.new("user://test_campaign_dynamic.json")


func after_each() -> void:
	ContentOverrides.reset()
	if FileAccess.file_exists("user://test_campaign_dynamic.json"):
		DirAccess.remove_absolute("user://test_campaign_dynamic.json")


func _level(id: String, world: Variant = null) -> Dictionary:
	var level: Dictionary = GameConfig.LEVELS[0].duplicate(true)
	level["id"] = id
	level["world"] = world
	var arrays: Dictionary = {"cells": [52, 64], "drop": [0.5, 0.84], "structures": [["nest", [0.5, 0.1]]]}
	for key: String in arrays:
		level[key] = arrays[key]
	level.terrain.spots = []
	return level


func _install(count: int, routes: Variant = null) -> void:
	var list := []
	for i in count:
		list.append(_level("lvl%d" % i, [0.5, 0.9] if i == 0 else null))
	ContentOverrides.set_data({"levels": list, "routes": routes})


func test_auto_layout_has_no_overlap_and_is_deterministic() -> void:
	_install(15)
	var first := Campaign.positions()
	assert_eq(first.size(), 15)
	assert_eq(first, Campaign.positions())
	for a in first.size():
		for b in range(a + 1, first.size()):
			var delta := (first[a] - first[b]) * Vector2(600.0, 700.0)
			assert_gt(delta.length(), 120.0, "%d/%d" % [a, b])
	for i in range(1, 15):
		assert_lt(first[i].y, first[i - 1].y)


func test_top_extends_for_many_levels_only() -> void:
	assert_eq(Campaign.top(), 0.0)
	_install(15)
	assert_lt(Campaign.top(), -1.0)


func test_default_routes_are_used_without_overrides() -> void:
	assert_eq(Campaign.routes(), GameConfig.WORLD_ROUTES)


func test_auto_routes_chain_levels() -> void:
	_install(12)
	assert_eq(Campaign.routes().size(), 11)
	assert_true(Campaign.routes().has(Vector2i(10, 11)))
	assert_eq(Campaign.neighbors(5).size(), 2)


func test_custom_routes_get_automatic_edges_for_unlinked_levels() -> void:
	_install(5, [[0, 1], [0, 2]])
	var routes := Campaign.routes()
	assert_true(routes.has(Vector2i(0, 1)) and routes.has(Vector2i(0, 2)))
	assert_true(routes.has(Vector2i(2, 3)) and routes.has(Vector2i(3, 4)))


func test_unlocking_walks_up_the_long_chain() -> void:
	_install(14)
	assert_true(Campaign.is_unlocked(progress, 0))
	assert_false(Campaign.is_unlocked(progress, 1))
	for i in 13:
		progress.mark_conquered(i)
		assert_true(Campaign.is_unlocked(progress, i + 1), str(i))
		assert_false(Campaign.is_unlocked(progress, i + 2) and i + 2 < 14)


func test_route_bfs_over_many_levels() -> void:
	_install(12)
	for i in 8:
		progress.mark_conquered(i)
	var path := Campaign.route(progress, 0, 8)
	assert_eq(path.size(), 9)
	assert_eq(path[0], 0)
	assert_eq(path[8], 8)
	assert_true(Campaign.route(progress, 0, 10).is_empty())


func test_progress_with_extra_levels_keeps_unknown_ids_out() -> void:
	_install(12)
	progress.mark_conquered(11)
	progress.location = 11
	assert_true(progress.is_conquered(11))
	assert_true(progress.regions.has("lvl11"))
	var saved := progress.to_dict()
	ContentOverrides.reset()
	var other := Progress.new("user://test_campaign_dynamic.json")
	other.apply(saved)
	assert_false(other.regions.has("lvl11"))
	assert_true(other.location < GameConfig.level_count())
	_install(12)
	var again := Progress.new("user://test_campaign_dynamic.json")
	again.apply(saved)
	assert_true(again.is_conquered(11))
	assert_eq(again.location, 11)


func test_world_map_view_pans_to_reach_all_levels() -> void:
	_install(14)
	var view := WorldMapView.new().setup(progress)
	var host := Control.new()
	host.size = Vector2(700.0, 1200.0)
	add_child_autofree(host)
	host.add_child(view)
	assert_gt(view.max_pan(), 0.0)
	view.set_pan(1.0e9)
	assert_eq(view.pan, view.max_pan())
	var rect := view.map_rect()
	assert_true(rect.grow(80.0).has_point(view.node_position(13)))
	view.set_pan(-5.0)
	assert_eq(view.pan, 0.0)
	view.center_on(13)
	assert_gt(view.pan, 0.0)
	assert_eq(view.node_at(view.node_position(13)), 13)


func test_layout_and_routes_are_cached_until_the_content_changes() -> void:
	_install(6)
	var routes := Campaign.routes()
	assert_true(routes.is_read_only())
	assert_true(Campaign.positions().is_read_only())
	assert_true(Campaign.neighbors(2).is_read_only())
	assert_same(Campaign.routes(), routes)
	_install(4)
	assert_eq(Campaign.routes().size(), 3)
	assert_eq(Campaign.positions().size(), 4)
	assert_eq(Campaign.neighbors(99), [] as Array[int])


func test_disconnected_custom_routes_are_joined_to_the_start() -> void:
	_install(4, [[0, 1], [2, 3]])
	assert_true(Campaign.routes().has(Vector2i(1, 2)))
	for i in 3:
		progress.mark_conquered(i)
	assert_true(Campaign.is_unlocked(progress, 3))
	assert_eq(Campaign.route(progress, 0, 3), [0, 1, 2, 3] as Array[int])


func test_isolated_start_region_still_reaches_the_world() -> void:
	_install(3, [[1, 2]])
	assert_true(Campaign.routes().has(Vector2i(0, 1)))
	progress.mark_conquered(0)
	assert_true(Campaign.is_unlocked(progress, 1))


func test_location_is_restored_by_id_after_reordering() -> void:
	_install(5)
	progress.location = 3
	var saved := progress.to_dict()
	assert_eq(saved.location_id, "lvl3")
	var reordered := []
	for i in [4, 3, 2, 1, 0]:
		reordered.append(_level("lvl%d" % i, [0.5, 0.9] if i == 4 else null))
	ContentOverrides.set_data({"levels": reordered})
	var loaded := Progress.new("user://test_campaign_dynamic.json")
	loaded.apply(saved)
	assert_eq(loaded.location, 1)
	saved.erase("location_id")
	loaded.apply(saved)
	assert_eq(loaded.location, 3)


func test_regions_of_unknown_levels_survive_a_save() -> void:
	_install(6)
	progress.mark_conquered(5)
	var saved := progress.to_dict()
	_install(3)
	var smaller := Progress.new("user://test_campaign_dynamic.json")
	smaller.apply(saved)
	assert_false(smaller.regions.has("lvl5"))
	assert_true(smaller.to_dict().regions.has("lvl5"))
	_install(6)
	var restored := Progress.new("user://test_campaign_dynamic.json")
	restored.apply(smaller.to_dict())
	assert_true(restored.is_conquered(5))
	restored.reset_all()
	assert_true(restored.to_dict().regions.is_empty())


func test_old_version_two_saves_still_load() -> void:
	var old := {"version": 2, "regions": {"dawn": {"conquered": true, "stars": 2, "best_days": 4, "done": ["conquer"]}}, "techs": [], "location": 1, "total_kills": 12, "best_combo": 3}
	var loaded := Progress.new("user://test_campaign_dynamic.json")
	loaded.apply(old)
	assert_eq(loaded.location, 1)
	assert_eq(loaded.total_kills, 12)
	assert_eq(loaded.is_conquered(GameConfig.level_index("dawn")), GameConfig.level_index("dawn") >= 0)
	assert_eq(loaded.to_dict().location_id, str(GameConfig.level(1).id))
