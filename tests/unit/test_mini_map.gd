extends GutTest


func _battle() -> Battle:
	return BattleFixtures.battle(3)


func _minimap(battle: Battle, size: Vector2 = Vector2(260, 330)) -> MiniMap:
	var minimap := MiniMap.new().setup(battle.state)
	add_child_autofree(minimap)
	minimap.custom_minimum_size = Vector2.ZERO
	minimap.size = size
	return minimap


func test_tile_colors_tell_terrain_apart() -> void:
	var seen := {}
	for tile in LevelMap.Tile.size():
		seen[MiniMapTexture.tile_color(tile, false)] = true
	assert_eq(seen.size(), LevelMap.Tile.size())
	assert_eq(MiniMapTexture.tile_color(LevelMap.Tile.POND, false), AppTheme.WATER)
	assert_eq(MiniMapTexture.tile_color(LevelMap.Tile.TREE, false), AppTheme.TREE_DARK)
	assert_ne(MiniMapTexture.tile_color(LevelMap.Tile.OPEN, true), MiniMapTexture.tile_color(LevelMap.Tile.OPEN, false))


func test_fog_shades_the_terrain() -> void:
	var color := AppTheme.WATER
	assert_eq(MiniMapTexture.shade(color, FogOfWar.HIDDEN), AppTheme.FOG)
	assert_eq(MiniMapTexture.shade(color, FogOfWar.VISIBLE), color)
	assert_lt(MiniMapTexture.shade(color, FogOfWar.EXPLORED).get_luminance(), color.get_luminance())


func test_texture_follows_tiles_and_fog() -> void:
	var map := LevelMap.blank(Vector2i(6, 4))
	var fog := FogOfWar.new(map)
	fog.cells.fill(FogOfWar.VISIBLE)
	map.set_tile(Vector2i(2, 1), LevelMap.Tile.POND)
	var texture := MiniMapTexture.new(map, fog)
	assert_eq(texture.image.get_size(), Vector2i(6, 4))
	assert_eq(texture.color_at(Vector2i(2, 1)), AppTheme.WATER)
	assert_almost_eq(texture.image.get_pixel(2, 1).b, AppTheme.WATER.b, 0.01)
	assert_false(texture.refresh())
	fog.cells[map.index(Vector2i(0, 0))] = FogOfWar.HIDDEN
	fog.version += 1
	assert_true(texture.refresh())
	assert_eq(texture.color_at(Vector2i(0, 0)), AppTheme.FOG)
	assert_almost_eq(texture.image.get_pixel(0, 0).r, AppTheme.FOG.r, 0.01)
	map.set_tile(Vector2i(4, 2), LevelMap.Tile.ROCK)
	assert_true(texture.refresh())
	assert_eq(texture.color_at(Vector2i(4, 2)), AppTheme.ROCK)
	map.heights[map.index(Vector2i(5, 3))] = 1
	assert_eq(texture.color_at(Vector2i(5, 3)), MiniMapTexture.tile_color(LevelMap.Tile.OPEN, true))


func test_fit_keeps_the_aspect_inside_the_bounds() -> void:
	var size := MiniMap.fit(Vector2(2800, 3500), Vector2(520, 560))
	assert_lte(size.x, 520.0)
	assert_lte(size.y, 560.0)
	assert_almost_eq(size.x / size.y, 0.8, 0.01)
	assert_eq(MiniMap.fit(Vector2(1000, 500), Vector2(200, 200)), Vector2(200, 100))


func test_coordinates_round_trip() -> void:
	var battle := _battle()
	var minimap := _minimap(battle)
	var world := battle.state.map.size * Vector2(0.25, 0.75)
	assert_almost_eq(minimap.to_map(world).distance_to(Vector2(65, 247.5)), 0.0, 0.01)
	assert_almost_eq(minimap.to_world(minimap.to_map(world)).distance_to(world), 0.0, 0.01)
	assert_eq(minimap.to_world(Vector2(-50, 9999)), Vector2(0, battle.state.map.size.y))
	var fitted := MiniMap.new().setup(battle.state)
	add_child_autofree(fitted)
	assert_eq(fitted.custom_minimum_size, MiniMap.fit(battle.state.map.size, MiniMap.MAX_SIZE))
	assert_gt(fitted.custom_minimum_size.x, 0.0)


func test_markers_show_structures_core_and_buildings() -> void:
	var battle := _battle()
	var state := battle.state
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, state.core().position + Vector2(0, -150))
	battle.scouting.board(state.core())
	var minimap := _minimap(battle)
	var types := minimap.markers().map(func(marker: Dictionary) -> String: return marker.type)
	assert_eq(types.count(MiniMap.SPAWNER), 1)
	assert_eq(types.count(MiniMap.TURRET), 2)
	assert_eq(types.count(MiniMap.CORE), 1)
	assert_eq(types.count(MiniMap.BUILDING), 1)
	assert_false(types.has(MiniMap.SCOUT))
	assert_true(minimap.markers().any(func(marker: Dictionary) -> bool: return marker.position == relay.position))
	assert_eq(minimap.structure_count(), 3)
	state.enemy_buildings()[1].hp = 0.0
	assert_eq(minimap.structure_count(), 2)
	assert_eq(minimap.markers().filter(func(marker: Dictionary) -> bool: return marker.type == MiniMap.TURRET).size(), 1)


func test_markers_show_the_soldier_while_scouting() -> void:
	var battle := Battle.start(0)
	var minimap := _minimap(battle)
	var markers := minimap.markers()
	assert_eq(markers.size(), 1)
	assert_eq(markers[0].type, MiniMap.SCOUT)
	assert_eq(markers[0].position, battle.state.scout.position)
	assert_eq(minimap.structure_count(), 0)


func test_tap_requests_focus_on_the_world_spot() -> void:
	var battle := _battle()
	var minimap := _minimap(battle)
	watch_signals(minimap)
	minimap.tap(Vector2(130, 165))
	assert_signal_emitted_with_parameters(minimap, "focus_requested", [battle.state.map.size * 0.5])


func test_short_clicks_tap_and_drags_do_not() -> void:
	var battle := _battle()
	var minimap := _minimap(battle)
	watch_signals(minimap)
	minimap._gui_input(_click(Vector2(10, 10), true))
	minimap._gui_input(_click(Vector2(200, 200), false))
	assert_signal_not_emitted(minimap, "focus_requested")
	var right := _click(Vector2(10, 10), true)
	right.button_index = MOUSE_BUTTON_RIGHT
	minimap._gui_input(right)
	minimap._gui_input(_click(Vector2(10, 10), false))
	assert_signal_not_emitted(minimap, "focus_requested")
	minimap._gui_input(_click(Vector2(20, 20), true))
	minimap._gui_input(_click(Vector2(26, 24), false))
	assert_signal_emit_count(minimap, "focus_requested", 1)


func _click(position: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	return event


func test_refresh_stores_the_camera_frame_and_draws() -> void:
	var battle := _battle()
	var minimap := _minimap(battle)
	var frame := Rect2(Vector2(100, 200), Vector2(720, 1280))
	minimap.refresh(frame)
	assert_eq(minimap.view_rect, frame)
	await wait_process_frames(1)
	assert_eq(Vector2(minimap.terrain.texture.get_size()), Vector2(battle.state.map.width, battle.state.map.height))


func test_map_panel_summarises_the_structures() -> void:
	var fresh := Battle.start(0)
	var panel := MapPanel.new().setup(fresh.state)
	add_child_autofree(panel)
	assert_eq(panel.summary_text(), Texts.t("MAP_PENDING"))
	assert_eq(panel._summary.text, Texts.t("MAP_PENDING"))
	BattleFixtures.open_terrain(fresh.state)
	fresh.deploy_core(fresh.state.map.drop)
	panel.refresh(Rect2())
	assert_eq(panel._summary.text, Texts.format("MAP_STRUCTURES", [fresh.state.enemy_buildings().size()]))
	watch_signals(panel)
	panel.minimap.focus_requested.emit(Vector2(5, 6))
	assert_signal_emitted_with_parameters(panel, "focus_requested", [Vector2(5, 6)])
	await wait_process_frames(1)


func test_map_glyphs_exist_in_the_icon_font() -> void:
	for glyph in [Icons.MAP, Icons.DOT]:
		assert_true(AppTheme.FONT_ICONS.has_char(glyph.unicode_at(0)), glyph)
