extends GutTest

const PROGRESS := "user://test_ui_progress.json"
const SETTINGS := "user://test_ui_settings.cfg"

var settings: AppSettings
var progress: Progress
var sfx: SfxPlayer


func before_each() -> void:
	settings = AppSettings.new(SETTINGS)
	settings.sound = false
	settings.haptics = false
	progress = Progress.new(PROGRESS)
	sfx = SfxPlayer.new().setup(settings)
	add_child_autofree(sfx)


func after_each() -> void:
	DirAccess.remove_absolute(PROGRESS)
	DirAccess.remove_absolute(SETTINGS)


func _screen(level: int = 0) -> BattleScreen:
	var screen := BattleScreen.new().setup(level, progress, settings, sfx)
	add_child_autofree(screen)
	return screen


func _frames(screen: BattleScreen, count: int, delta: float = 1.0 / 30.0) -> void:
	for i in count:
		screen._process(delta)


func _deployed(level: int = 0) -> BattleScreen:
	var screen := _screen(level)
	BattleFixtures.open_terrain(screen.battle.state)
	screen.battle.deploy_core(screen.battle.state.map.drop)
	_frames(screen, 1)
	return screen


func test_battle_screen_starts_with_scouting() -> void:
	var screen := _screen()
	_frames(screen, 5)
	assert_not_null(screen.battle)
	assert_true(screen.battle.state.is_scouting())
	assert_true(screen.tutorial.is_active())
	assert_eq(screen.tutorial_text(), Texts.tutorial(Tutorial.MOVE_SCOUT))
	assert_eq(screen.battle.state.time, 0.0)
	assert_true(screen.build_bar.visible)
	assert_eq(screen.build_bar.kinds, [GameConfig.CORE] as Array[String])
	assert_false(screen.build_bar.collapsible)
	assert_true(screen.build_bar.shows_cards())
	assert_eq(screen.view.mode, BattleView.Mode.MOVE)
	assert_false(screen.mode_button.visible)
	assert_false(screen.scout_button.visible)
	assert_gt(screen.hud.top_height(), 0.0)
	assert_gt(screen.view.chunk_count(), 1)


func _joysticks(screen: BattleScreen) -> int:
	return screen.find_children("*", "VirtualJoystick", true, false).size()


func _release_steering() -> void:
	for action in [&"steer_left", &"steer_right", &"steer_up", &"steer_down"]:
		Input.action_release(action)


func test_scout_lands_steers_and_boards_the_core() -> void:
	var screen := _screen()
	var state := screen.battle.state
	_frames(screen, int(GameConfig.DROP_TIME * 30) + 3)
	assert_true(state.scout.is_landed())
	assert_true(screen.view.scout_active)
	assert_true(screen.scout_chip.visible)
	assert_true(screen.scout_button.visible)
	assert_true(screen.steering_enabled())
	assert_eq(_joysticks(screen), 0)
	var start := state.scout.position
	Input.action_press(&"steer_up")
	assert_eq(screen.steering_input(), Vector2.UP)
	_frames(screen, 30)
	_release_steering()
	_frames(screen, 2)
	assert_lt(state.scout.position.y, start.y - 50.0)
	assert_false(state.scout.is_moving())
	assert_almost_eq(screen.view.center.distance_to(state.scout.position), 0.0, 200.0)
	assert_eq(screen.tutorial.step, Tutorial.DEPLOY_CORE)
	screen.choose_kind(GameConfig.CORE)
	assert_eq(screen.view.build_kind, GameConfig.CORE)
	screen.view.begin(state.map.drop)
	screen.view.tap(state.map.drop)
	assert_not_null(state.core())
	_frames(screen, 1)
	assert_eq(state.phase, BattleState.Phase.PLAN)
	assert_true(state.scout.boarded)
	assert_eq(screen.build_bar.kinds, GameConfig.STARTER_KINDS)
	assert_false(screen.view.scout_active)
	assert_false(screen.steering_enabled())
	assert_false(screen.scout_button.visible)
	assert_eq(screen.tutorial.step, Tutorial.BUILD_SOLAR)
	assert_true(screen.mode_button.visible)
	assert_eq(screen.view.mode, BattleView.Mode.CONNECT)
	assert_true(screen.mode_button.text.contains(Texts.t("MODE_CONNECT")))
	assert_true(screen.build_bar.collapsible)
	assert_false(screen.build_bar.shows_cards())
	assert_true(screen.build_bar.build_button.visible)
	assert_eq(screen.steering_input(), Vector2.ZERO)


func test_scout_clears_by_tap_while_scouting() -> void:
	var screen := _screen()
	var state := screen.battle.state
	BattleFixtures.open_terrain(state)
	_frames(screen, 2)
	assert_true(screen.view.scout_active)
	var origin := state.map.cell_of(state.scout.position)
	state.scout.position = state.map.center_of(origin)
	var tree := origin + Vector2i(-1, 0)
	state.map.set_tile(tree, LevelMap.Tile.TREE)
	state.nav.terrain_changed(tree)
	screen.view.begin(state.map.center_of(tree))
	screen.view.tap(state.map.center_of(tree))
	assert_false(state.scout.is_clearing())
	assert_true(state.map.is_walkable(tree))
	var far := origin + Vector2i(6, 0)
	state.map.set_tile(far, LevelMap.Tile.ROCK)
	state.nav.terrain_changed(far)
	watch_signals(screen.view)
	screen.view.begin(state.map.center_of(far))
	screen.view.tap(state.map.center_of(far))
	assert_signal_not_emitted(screen.view, "action_failed")
	assert_true(state.scout.is_walking())
	assert_eq(state.scout.pending_cell, far)
	_frames(screen, 90)
	assert_false(state.scout.is_walking())
	assert_true(state.scout.is_clearing() or state.map.is_walkable(far))
	_frames(screen, 60)
	assert_true(state.map.is_walkable(far))
	var spot := state.map.cell_of(state.scout.position) + Vector2i(0, 4)
	screen.view.begin(state.map.center_of(spot))
	screen.view.tap(state.map.center_of(spot))
	assert_true(state.scout.is_walking())
	_frames(screen, 60)
	assert_eq(state.map.cell_of(state.scout.position), spot)
	var walled := state.map.cell_of(state.scout.position) + Vector2i(5, 0)
	for y in range(-1, 2):
		for x in range(-1, 2):
			if x != 0 or y != 0:
				state.map.set_tile(walled + Vector2i(x, y), LevelMap.Tile.CLIFF)
				state.nav.terrain_changed(walled + Vector2i(x, y))
	screen.view.begin(state.map.center_of(walled))
	screen.view.tap(state.map.center_of(walled))
	assert_signal_emitted(screen.view, "action_failed")
	assert_false(state.scout.is_walking())
	screen.focus_scout()
	assert_true(screen.view.scout_active)


func test_panel_connect_button_links_by_tapping() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var core := state.core()
	screen.battle.place(GameConfig.SOLAR, core.position + Vector2(150, 0))
	var solar: Building = state.player_buildings().back()
	screen.battle.place(GameConfig.SOLAR, core.position + Vector2(-150, 0))
	var other: Building = state.player_buildings().back()
	screen.view.select(solar.id)
	_frames(screen, 1)
	assert_true(screen.panel._link.visible)
	assert_false(screen.panel._relocate.disabled)
	assert_true(screen.panel._link.text.contains("0/1"))
	screen.panel._link.pressed.emit()
	assert_eq(screen.view.pick, BattleView.Pick.LINK)
	assert_eq(screen.panel.active_pick, "link")
	assert_eq(screen.view.link_candidates(solar), [core] as Array[Building])
	_frames(screen, 2)
	watch_signals(screen.view)
	screen.view.begin(other.position)
	assert_eq(screen.view.gesture, BattleView.Gesture.PICK)
	screen.view.tap(other.position)
	assert_signal_emitted(screen.view, "action_failed")
	assert_eq(screen.view.pick, BattleView.Pick.LINK)
	screen.view.begin(core.position)
	screen.view.tap(core.position)
	assert_not_null(state.find_link(solar.id, core.id))
	assert_eq(screen.view.pick, BattleView.Pick.NONE)
	assert_eq(screen.view.selected_id, solar.id)
	_frames(screen, 2)
	assert_true(screen.panel._link.disabled)
	screen.start_link_pick(solar.id)
	assert_eq(screen.view.pick, BattleView.Pick.NONE)
	screen.start_link_pick(core.id)
	screen.start_link_pick(core.id)
	assert_eq(screen.view.pick, BattleView.Pick.NONE)
	screen.start_link_pick(core.id)
	screen.view.begin(core.position + Vector2(0, 400))
	screen.view.drag_to(core.position + Vector2(0, 300), true, Vector2(0, 40))
	assert_eq(screen.view.gesture, BattleView.Gesture.PAN)
	screen.view.finish(core.position + Vector2(0, 300))
	assert_eq(screen.view.pick, BattleView.Pick.LINK)
	screen.view.begin(core.position + Vector2(0, 400))
	screen.view.tap(core.position + Vector2(0, 400))
	assert_eq(screen.view.pick, BattleView.Pick.NONE)
	screen.start_link_pick(core.id)
	screen.handle_back()
	assert_eq(screen.view.pick, BattleView.Pick.NONE)
	screen.view.start_pick(BattleView.Pick.LINK, 9999)
	assert_eq(screen.view.pick, BattleView.Pick.NONE)


func test_panel_focus_button_orders_an_attack() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var core := state.core()
	var zapper := BattleFixtures.add(screen.battle, GameConfig.ZAPPER, core.position + Vector2(0, -150))
	zapper.energy = Formulas.capacity(zapper)
	var beetle := BattleFixtures.enemy(screen.battle, "beetle", zapper.position + Vector2(0, -120))
	screen.view.select(zapper.id)
	_frames(screen, 1)
	assert_true(screen.panel._focus.visible)
	assert_true(screen.panel._focus.text.contains(Texts.t("PANEL_FOCUS")))
	screen.panel._focus.pressed.emit()
	assert_eq(screen.view.pick, BattleView.Pick.FOCUS)
	_frames(screen, 2)
	watch_signals(screen.view)
	screen.view.begin(core.position)
	screen.view.tap(core.position)
	assert_signal_emitted(screen.view, "action_failed")
	screen.view.begin(beetle.position)
	screen.view.tap(beetle.position)
	assert_eq(zapper.focus, beetle)
	assert_eq(screen.view.pick, BattleView.Pick.NONE)
	_frames(screen, 3)
	assert_true(screen.panel._focus.text.contains(Texts.t("PANEL_UNFOCUS")))
	screen.panel._focus.pressed.emit()
	assert_null(zapper.focus)
	screen.toggle_focus(zapper.id)
	screen.toggle_focus(zapper.id)
	assert_eq(screen.view.pick, BattleView.Pick.NONE)
	screen.toggle_focus(zapper.id)
	screen.view.begin(core.position + Vector2(400, -400))
	screen.view.tap(core.position + Vector2(400, -400))
	assert_eq(screen.view.pick, BattleView.Pick.NONE)
	screen.toggle_focus(9999)
	screen.toggle_focus(zapper.id)
	screen.view.select(core.id)
	assert_eq(screen.view.pick, BattleView.Pick.NONE)


func test_relocating_a_building_through_the_panel() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var core := state.core()
	screen.battle.place(GameConfig.RELAY, core.position + Vector2(150, 0))
	var relay: Building = state.player_buildings().back()
	screen.view.select(core.id)
	_frames(screen, 1)
	assert_false(screen.panel._relocate.visible)
	screen.view.select(relay.id)
	_frames(screen, 1)
	assert_true(screen.panel._relocate.visible)
	assert_true(screen.panel._relocate.text.contains(Texts.t("PANEL_RELOCATE_FREE")))
	screen.panel._relocate.pressed.emit()
	assert_true(screen.view.is_relocating())
	assert_eq(screen.view.build_kind, GameConfig.RELAY)
	assert_eq(screen.view.selected_id, -1)
	_frames(screen, 2)
	assert_eq(screen.view.coverage_mode(), "build")
	watch_signals(screen.view)
	screen.view.begin(core.position)
	screen.view.tap(core.position)
	assert_signal_emitted(screen.view, "action_failed")
	assert_true(screen.view.is_relocating())
	var money := state.money
	var target := core.position + Vector2(-150, 0)
	screen.view.begin(target)
	screen.view.drag_to(target + Vector2(60, 0), true)
	screen.view.finish(target)
	assert_eq(relay.position, LevelMap.snap(target, 1))
	assert_eq(state.money, money)
	assert_false(screen.view.is_relocating())
	assert_eq(screen.view.selected_id, relay.id)
	screen.start_relocate(relay.id)
	screen.handle_back()
	assert_false(screen.view.is_relocating())
	screen.start_round()
	screen.panel.refresh()
	assert_true(screen.panel._relocate.text.contains(str(Formulas.relocate_cost(relay, false))))
	state.money = 0
	screen.start_relocate(relay.id)
	assert_false(screen.view.is_relocating())
	screen.start_relocate(9999)
	screen.view.start_relocate(9999)
	assert_false(screen.view.is_relocating())
	state.money = 500
	screen.start_relocate(relay.id)
	screen.battle.sell(relay.id)
	_frames(screen, 1)
	assert_false(screen.view.is_relocating())


func test_build_mode_highlights_energy_coverage() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	screen.choose_kind(GameConfig.ZAPPER)
	_frames(screen, 1)
	assert_eq(screen.view.coverage_mode(), "build")
	var spot := state.core().position + Vector2(0, -230)
	assert_eq(screen.view.coverage_levels[state.map.index(state.map.cell_of(spot))], Coverage.ONE)
	screen.choose_kind(GameConfig.ZAPPER)
	_frames(screen, 1)
	assert_eq(screen.view.coverage_mode(), "")
	assert_true(screen.view.coverage_levels.is_empty())
	screen.choose_kind(GameConfig.BULWARK)
	_frames(screen, 1)
	assert_eq(screen.view.coverage_mode(), "")


func test_coverage_texture_paints_levels() -> void:
	var map := LevelMap.blank(Vector2i(4, 3))
	var texture := CoverageTexture.new(map)
	var levels := PackedByteArray([0, 1, 2, 3, 4, 0, 0, 0, 0, 0, 0, 9])
	texture.update(levels)
	var image := texture.image
	assert_eq(image.get_size(), Vector2i(4, 3))
	assert_eq(image.get_pixel(0, 0).a, 0.0)
	assert_almost_eq(image.get_pixel(1, 0).r, AppTheme.DANGER.r, 0.01)
	assert_almost_eq(image.get_pixel(3, 0).g, AppTheme.SUCCESS.g, 0.01)
	assert_almost_eq(image.get_pixel(0, 1).b, AppTheme.SHIELD_BLUE.b, 0.01)
	assert_almost_eq(image.get_pixel(3, 2).a, CoverageTexture.ALPHA, 0.01)
	assert_eq(CoverageTexture.palette().size(), 5)


func test_mobile_tower_is_steered_with_keys() -> void:
	var screen := _deployed(1)
	var state := screen.battle.state
	var core := state.core()
	var rover := BattleFixtures.add(screen.battle, GameConfig.ROVER, core.position + Vector2(0, -150))
	rover.energy = Formulas.capacity(rover)
	screen.battle.connect_buildings(core.id, rover.id)
	screen.start_round()
	_frames(screen, 1)
	assert_false(screen.steering_enabled())
	screen.view.select(rover.id)
	_frames(screen, 1)
	assert_true(screen.steering_enabled())
	assert_eq(screen.view.selected_mobile(), rover)
	assert_eq(screen.view.coverage_mode(), "mobile")
	assert_gt(screen.view.coverage_levels[state.map.index(rover.origin)], 0)
	assert_false(screen.panel._relocate.visible)
	assert_true(screen.panel._focus.visible)
	var start := rover.position
	Input.action_press(&"steer_right")
	_frames(screen, 20)
	assert_gt(rover.position.x, start.x + 20.0)
	assert_eq(rover.steer, Vector2.RIGHT)
	screen.view.select(-1)
	_frames(screen, 1)
	_release_steering()
	assert_eq(rover.steer, Vector2.ZERO)
	assert_false(screen.steering_enabled())


func test_build_flow_through_view() -> void:
	var screen := _deployed()
	var core := screen.battle.state.core()
	screen.choose_kind(GameConfig.SOLAR)
	assert_eq(screen.view.build_kind, GameConfig.SOLAR)
	screen.view.begin(core.position + Vector2(130, 0))
	screen.view.drag_to(core.position + Vector2(140, 0), true)
	screen.view.finish(core.position + Vector2(140, 0))
	assert_eq(screen.battle.state.player_buildings().size(), 2)
	assert_eq(screen.view.build_kind, "")
	_frames(screen, 1)
	assert_eq(screen.tutorial.step, Tutorial.CONNECT)
	screen.choose_kind(GameConfig.SOLAR)
	assert_eq(screen.view.build_kind, GameConfig.SOLAR)
	screen.choose_kind(GameConfig.SOLAR)
	assert_eq(screen.view.build_kind, "")


func test_bulwarks_are_placed_one_by_one_like_other_buildings() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var start := state.core().position + Vector2(-200, -150)
	screen.choose_kind(GameConfig.BULWARK)
	screen.view.begin(start)
	screen.view.drag_to(start + Vector2(40, 0), true)
	screen.view.drag_to(start + Vector2(400, 0), true)
	screen.view.finish(start + Vector2(400, 0))
	assert_eq(state.count_kind(GameConfig.BULWARK), 1)
	assert_eq(state.of_kind(GameConfig.BULWARK)[0].position, LevelMap.snap(start + Vector2(400, 0), 1))
	assert_eq(screen.view.build_kind, "")


func test_multi_placement_keeps_the_building_selected() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var start := state.core().position + Vector2(-200, -150)
	screen.build_bar.set_repeat(true)
	assert_true(screen.view.build_repeat)
	screen.choose_kind(GameConfig.BULWARK)
	for i in 3:
		var spot := start + Vector2(GameConfig.CELL * i, 0)
		screen.view.begin(spot)
		screen.view.tap(spot)
	assert_eq(state.count_kind(GameConfig.BULWARK), 3)
	assert_eq(screen.view.build_kind, GameConfig.BULWARK)
	state.money = Formulas.build_cost(state, GameConfig.BULWARK)
	screen.view.begin(start + Vector2(0, -100))
	screen.view.tap(start + Vector2(0, -100))
	assert_eq(state.count_kind(GameConfig.BULWARK), 4)
	assert_eq(screen.view.build_kind, "")
	screen.build_bar.set_repeat(false)
	assert_false(screen.view.build_repeat)


func test_failed_placement_is_reported() -> void:
	var screen := _deployed()
	watch_signals(screen.view)
	screen.choose_kind(GameConfig.SOLAR)
	screen.view.begin(Vector2(10, 10))
	screen.view.finish(Vector2(10, 10))
	assert_signal_emitted(screen.view, "action_failed")
	screen.battle.state.money = 0
	screen.choose_kind(GameConfig.RELAY)
	assert_eq(screen.view.build_kind, GameConfig.SOLAR)


func test_link_and_cut_gestures() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var core := state.core()
	screen.battle.place(GameConfig.SOLAR, core.position + Vector2(150, 0))
	var solar: Building = state.player_buildings().back()
	assert_eq(screen.view.mode, BattleView.Mode.CONNECT)
	screen.view.begin(solar.position)
	assert_eq(screen.view.gesture, BattleView.Gesture.LINK_PENDING)
	screen.view.drag_to(core.position, true)
	assert_eq(screen.view.gesture, BattleView.Gesture.LINK)
	_frames(screen, 1)
	screen.view.finish(core.position)
	assert_eq(state.links.size(), 1)
	screen.view.begin(core.position + Vector2(75, -60))
	screen.view.drag_to(core.position + Vector2(75, -40), true)
	assert_eq(screen.view.gesture, BattleView.Gesture.CUT)
	screen.view.drag_to(core.position + Vector2(75, 60), true)
	screen.view.finish(core.position + Vector2(75, 60))
	assert_true(state.links.is_empty())
	_frames(screen, 2)


func test_invalid_link_reports_reason() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var core := state.core()
	screen.battle.place(GameConfig.SOLAR, core.position + Vector2(150, 0))
	var solar: Building = state.player_buildings().back()
	watch_signals(screen.view)
	screen.view.set_mode(BattleView.Mode.CONNECT)
	screen.view.begin(core.position)
	screen.view.drag_to(solar.position, true)
	_frames(screen, 1)
	screen.view.finish(solar.position)
	assert_signal_emitted(screen.view, "action_failed")


func test_move_mode_drag_pans_instead_of_linking() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var core := state.core()
	screen.battle.place(GameConfig.SOLAR, core.position + Vector2(150, 0))
	var solar: Building = state.player_buildings().back()
	screen.toggle_mode()
	assert_eq(screen.view.mode, BattleView.Mode.MOVE)
	screen.view.zoom = 1.0
	screen.view.focus(core.position + Vector2(0, -300))
	var before := screen.view.center
	screen.view.begin(solar.position)
	assert_eq(screen.view.gesture, BattleView.Gesture.TAP_PENDING)
	screen.view.drag_to(core.position, true, Vector2(0, 60))
	assert_eq(screen.view.gesture, BattleView.Gesture.PAN)
	screen.view.finish(core.position)
	assert_true(state.links.is_empty())
	assert_almost_eq(screen.view.center.y, before.y - 60.0, 0.5)
	screen.view.begin(core.position + Vector2(300, -200))
	assert_eq(screen.view.gesture, BattleView.Gesture.CUT_PENDING)
	screen.view.drag_to(core.position + Vector2(300, -100), false, Vector2(0, 5))
	assert_eq(screen.view.gesture, BattleView.Gesture.CUT_PENDING)
	screen.view.tap(core.position + Vector2(300, -100))
	assert_eq(screen.view.gesture, BattleView.Gesture.NONE)


func test_connect_mode_double_tap_hold_pans_without_linking() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var core := state.core()
	screen.view.set_mode(BattleView.Mode.CONNECT)
	screen.view.zoom = 1.0
	screen.view.focus(core.position + Vector2(0, -300))
	var before := screen.view.center
	screen.view.tracker.double = true
	screen.view.begin(core.position)
	assert_eq(screen.view.gesture, BattleView.Gesture.PAN)
	screen.view.drag_to(core.position + Vector2(0, 80), true, Vector2(0, 80))
	assert_almost_eq(screen.view.center.y, before.y - 80.0, 0.5)
	screen.view.finish(core.position + Vector2(0, 80))
	assert_true(state.links.is_empty())
	assert_eq(screen.view.gesture, BattleView.Gesture.NONE)


func test_two_fingers_cancel_linking_in_connect_mode() -> void:
	var screen := _deployed()
	var core := screen.battle.state.core()
	screen.view.set_mode(BattleView.Mode.CONNECT)
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = screen.view.to_screen(core.position)
	screen.view._on_touch(touch)
	assert_eq(screen.view.gesture, BattleView.Gesture.LINK_PENDING)
	var second := InputEventScreenTouch.new()
	second.index = 1
	second.pressed = true
	second.position = touch.position + Vector2(120, 0)
	screen.view._on_touch(second)
	assert_eq(screen.view.gesture, BattleView.Gesture.NONE)
	var drag := InputEventScreenDrag.new()
	drag.index = 1
	drag.position = second.position + Vector2(80, 0)
	var zoom := screen.view.zoom
	screen.view._on_drag(drag)
	assert_ne(screen.view.zoom, zoom)
	assert_eq(screen.view.gesture, BattleView.Gesture.NONE)


func test_target_priority_panel() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var zapper := BattleFixtures.add(screen.battle, GameConfig.ZAPPER, state.core().position + Vector2(0, -150))
	screen.view.select(zapper.id)
	_frames(screen, 2)
	assert_true(screen.panel._targets.visible)
	assert_eq(screen.panel._target_buttons.size(), 3)
	assert_true(screen.panel._target_buttons[0].text.contains(Texts.t("CLASS_AIR")))
	assert_eq(screen.panel.target_label(zapper, 2), "3  %s" % Texts.t("CLASS_MELEE"))
	screen.panel._toggle(0)
	assert_false(zapper.can_target(GameConfig.CLASS_AIR))
	assert_eq(screen.panel.target_label(zapper, 0), "1  %s  %s" % [Texts.t("CLASS_AIR"), Icons.CLOSE])
	assert_true(screen.panel._target_buttons[0].text.contains(Icons.CLOSE))
	screen.panel._raise(2)
	assert_eq(zapper.target_order[1], GameConfig.CLASS_MELEE)
	var relay := BattleFixtures.add(screen.battle, GameConfig.RELAY, state.core().position + Vector2(150, 0))
	screen.view.select(relay.id)
	assert_false(screen.panel._targets.visible)
	var plasma := BattleFixtures.add(screen.battle, GameConfig.PLASMA, state.core().position + Vector2(-150, 0))
	screen.view.select(plasma.id)
	_frames(screen, 4)
	assert_true(screen.panel._target_buttons[0].disabled)


func test_mode_button_toggles_and_shows_mode() -> void:
	var screen := _deployed()
	_frames(screen, 1)
	assert_true(screen.mode_button.visible)
	assert_eq(screen.view.mode, BattleView.Mode.CONNECT)
	assert_true(screen.mode_button.text.contains(Texts.t("MODE_CONNECT")))
	assert_eq(screen.mode_button.theme_type_variation, "PrimaryButton")
	screen.mode_button.pressed.emit()
	assert_eq(screen.view.mode, BattleView.Mode.MOVE)
	assert_true(screen.mode_button.text.contains(Texts.t("MODE_MOVE")))
	assert_eq(screen.mode_button.theme_type_variation, "Button")
	assert_eq(screen.hud._toast_label.text, Texts.t("TOAST_MODE_MOVE"))
	screen.mode_button.pressed.emit()
	assert_eq(screen.view.mode, BattleView.Mode.CONNECT)
	_frames(screen, 1)
	assert_lt(screen.mode_button.position.y + screen.mode_button.size.y, screen.root.size.y - screen.view.bottom_inset)
	screen.handle_back()
	assert_eq(screen.view.mode, BattleView.Mode.CONNECT)
	assert_true(screen.paused)


func test_beams_only_visible_while_energy_flows() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var core := state.core()
	var zapper := BattleFixtures.add(screen.battle, GameConfig.ZAPPER, core.position + Vector2(0, -150))
	zapper.energy = 0.0
	screen.battle.connect_buildings(core.id, zapper.id)
	screen.start_round()
	var link := state.links[0]
	assert_eq(screen.view.beam_visibility(link), 0.0)
	for i in 10:
		screen.battle.tick(GameConfig.TICK)
	assert_gt(screen.view.beam_visibility(link), 0.5)
	zapper.energy = Formulas.capacity(zapper)
	for i in 120:
		screen.battle.tick(GameConfig.TICK)
	assert_eq(screen.view.beam_visibility(link), 0.0)
	screen.view.set_mode(BattleView.Mode.CONNECT)
	_frames(screen, 2)


func test_tap_selects_and_panel_upgrades_and_sells() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var core := state.core()
	screen.battle.place(GameConfig.RELAY, core.position + Vector2(0, -150))
	var relay: Building = state.player_buildings().back()
	screen.view.begin(relay.position)
	screen.view.tap(relay.position)
	assert_eq(screen.view.selected_id, relay.id)
	assert_true(screen.panel.visible)
	_frames(screen, 2)
	assert_false(screen.build_bar.visible)
	screen.upgrade(relay.id, GameConfig.TRACK_LINKS)
	assert_eq(relay.level(GameConfig.TRACK_LINKS), 1)
	state.money = 0
	screen.upgrade(relay.id, GameConfig.TRACK_RATE)
	assert_eq(relay.level(GameConfig.TRACK_RATE), 0)
	screen.sell(relay.id)
	assert_null(state.building(relay.id))
	assert_eq(screen.view.selected_id, -1)
	screen.view.begin(core.position + Vector2(300, 0))
	screen.view.tap(core.position + Vector2(300, 0))
	assert_false(screen.panel.visible)


func test_enemy_structure_panel() -> void:
	var screen := _deployed()
	var nest: Building = screen.battle.state.enemy_buildings()[0]
	screen.view.select(nest.id)
	assert_true(screen.panel.visible)
	_frames(screen, 2)


func test_planning_card_and_start_button() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	_frames(screen, 1)
	assert_true(screen.hud._prep.visible)
	assert_true(screen.hud._start.visible)
	assert_true(screen.hud._start.text.contains(Texts.format("HUD_START", [1])))
	assert_eq(screen.hud._cycle_label.text, Texts.t("HUD_PLAN"))
	assert_eq(BattleHud.day_text(state), Texts.format("HUD_DAY", [1]))
	screen.choose_kind(GameConfig.SOLAR)
	screen.hud._start.pressed.emit()
	assert_eq(state.phase, BattleState.Phase.FIGHT)
	assert_eq(screen.view.build_kind, "")
	_frames(screen, 1)
	assert_false(screen.hud._prep.visible)
	assert_eq(BattleHud.day_text(state), Texts.format("HUD_DAY_WAVE", [Texts.format("HUD_DAY", [1]), state.waves_sent, Formulas.wave_times(state.level)]))
	BattleFixtures.enemy(screen.battle, "crawler", state.core().position + Vector2(0, -900))
	screen.battle.spawns.end_night()
	_frames(screen, 1)
	assert_true(screen.hud._prep.visible)
	assert_false(screen.hud._start.visible)
	assert_eq(screen.hud._prep_label.text, Texts.format("HUD_MOP_UP", [state.attackers()]))
	screen.start_round()
	assert_eq(state.phase, BattleState.Phase.FIGHT)


func test_rover_steering_only_while_fighting() -> void:
	var screen := _deployed(1)
	var state := screen.battle.state
	var rover := BattleFixtures.add(screen.battle, GameConfig.ROVER, state.core().position + Vector2(0, -150))
	screen.view.select(rover.id)
	_frames(screen, 1)
	assert_false(screen.steering_enabled())
	Input.action_press(&"steer_right")
	assert_eq(screen.steering_input(), Vector2.ZERO)
	_release_steering()
	screen.start_round()
	_frames(screen, 1)
	assert_true(screen.steering_enabled())
	assert_eq(_joysticks(screen), 0)


func test_map_button_opens_the_map_and_marks_structures() -> void:
	var screen := _screen()
	var hud := screen.hud
	_frames(screen, 1)
	assert_true(hud.map_button.visible)
	assert_lt(hud.map_button.position.y + hud.map_button.size.y, screen.scout_button.position.y)
	assert_gt(hud.map_button.position.x, screen.root.size.x * 0.5)
	assert_false(hud.map_visible())
	hud.map_button.pressed.emit()
	assert_true(hud.map_visible())
	_frames(screen, 1)
	assert_eq(hud.map_panel._summary.text, Texts.t("MAP_PENDING"))
	assert_eq(hud.map_panel.minimap.view_rect, screen.view.world_rect())
	var state := screen.battle.state
	BattleFixtures.open_terrain(state)
	screen.battle.deploy_core(state.map.drop)
	_frames(screen, 1)
	var count := state.enemy_buildings().size()
	assert_eq(count, GameConfig.level(0).structures.size())
	assert_eq(hud.map_panel._summary.text, Texts.format("MAP_STRUCTURES", [count]))
	assert_eq(hud._toast_label.text, Texts.format("TOAST_CREEP_SPAWNED", [state.creep.alive_nests().size()]))
	hud.announce_structures(count)
	assert_eq(hud._toast_label.text, Texts.format("MAP_SPAWNED", [count]))
	await wait_process_frames(2)


func test_map_tap_jumps_there_and_closes() -> void:
	var screen := _deployed()
	var hud := screen.hud
	hud.toggle_map()
	_frames(screen, 1)
	await wait_process_frames(2)
	var minimap := hud.map_panel.minimap
	assert_gt(minimap.size.x, 0.0)
	var nest: Building = screen.battle.state.enemy_buildings()[0]
	minimap.tap(minimap.to_map(nest.position))
	assert_false(hud.map_visible())
	var view := screen.view
	var expected := CameraMath.clamp_center(minimap.to_world(minimap.to_map(nest.position)), view.zoom, view.view_size(), screen.battle.state.map.size)
	assert_almost_eq(view.center.distance_to(expected), 0.0, 0.5)


func test_map_and_stats_take_turns_and_back_closes_the_map() -> void:
	var screen := _deployed()
	var hud := screen.hud
	hud.toggle_stats()
	assert_true(hud.stats_panel.visible)
	hud.toggle_map()
	assert_true(hud.map_visible())
	assert_false(hud.stats_panel.visible)
	hud.toggle_stats()
	assert_false(hud.map_visible())
	hud.hide_stats()
	hud.toggle_map()
	screen.handle_back()
	assert_false(hud.map_visible())
	assert_false(screen.paused)
	hud.toggle_map()
	hud.map_panel.closed.emit()
	assert_false(hud.map_visible())
	hud.toggle_map()
	hud.toggle_map()
	assert_false(hud.map_visible())


func test_hud_without_map_hides_the_button() -> void:
	var hud := BattleHud.new().setup(0.0)
	add_child_autofree(hud)
	assert_false(hud.map_button.visible)
	assert_false(hud.map_visible())
	hud.toggle_map()
	hud.hide_map()
	hud.announce_structures(0)
	assert_false(hud.map_visible())
	hud.announce_structures(2)
	assert_eq(hud._toast_label.text, Texts.format("MAP_SPAWNED", [2]))


func test_world_rect_matches_the_camera() -> void:
	var screen := _deployed()
	var view := screen.view
	var rect := view.world_rect()
	assert_almost_eq(rect.get_center().distance_to(view.center), 0.0, 0.01)
	assert_almost_eq(rect.size.distance_to(view.view_size() / view.zoom), 0.0, 0.01)


func test_upgrade_list_shows_every_track_without_inner_scroll() -> void:
	var screen := _deployed()
	var core := screen.battle.state.core()
	screen.view.select(core.id)
	_frames(screen, 2)
	assert_true(screen.panel._tracks.visible)
	assert_eq(screen.panel._track_rows.size(), core.definition().tracks.size())
	var nest: Building = screen.battle.state.enemy_buildings()[0]
	screen.view.select(nest.id)
	_frames(screen, 1)
	assert_false(screen.panel._tracks.visible)


func test_tower_panel_lists_health_and_armour_separately() -> void:
	var screen := _deployed()
	var core := screen.battle.state.core()
	var zapper := BattleFixtures.add(screen.battle, GameConfig.ZAPPER, core.position + Vector2(0, -150))
	screen.view.select(zapper.id)
	_frames(screen, 2)
	assert_true(screen.panel._track_rows.has(GameConfig.TRACK_HULL))
	assert_true(screen.panel._track_rows.has(GameConfig.TRACK_ARMOR))
	var detail: Label = screen.panel._track_rows[GameConfig.TRACK_ARMOR].detail
	assert_string_contains(detail.text, StatText.track_value(zapper, GameConfig.TRACK_ARMOR))
	screen.view.select(core.id)
	_frames(screen, 2)
	assert_true(screen.panel._track_rows.has(GameConfig.TRACK_ARMOR))


func test_holding_an_upgrade_button_repeats_upgrades() -> void:
	var screen := _deployed()
	var core := screen.battle.state.core()
	screen.battle.state.money = 1000000000
	screen.view.select(core.id)
	_frames(screen, 2)
	var panel: BuildingPanel = screen.panel
	var track: String = panel._track_rows.keys()[0]
	var button: Button = panel._track_rows[track].button
	var before := core.level(track)
	button.button_down.emit()
	panel._process(BuildingPanel.HOLD_DELAY - 0.01)
	assert_eq(core.level(track), before)
	panel._process(0.01 + BuildingPanel.HOLD_REPEAT * 2.0)
	assert_gt(core.level(track), before)
	var held_level := core.level(track)
	button.button_up.emit()
	panel._process(5.0)
	assert_eq(core.level(track), held_level)
	button.pressed.emit()
	assert_eq(core.level(track), held_level)
	button.button_down.emit()
	button.pressed.emit()
	assert_eq(core.level(track), held_level + 1)
	button.button_up.emit()
	button.button_down.emit()
	panel._process(60.0)
	assert_true(Formulas.is_maxed(core, track))
	assert_eq(panel._held_track, "")
	panel.begin_hold(track)
	panel.show_building(-1)
	assert_eq(panel._held_track, "")


func test_panel_fits_its_content_and_stops_below_the_top_bar() -> void:
	var screen := _deployed()
	var core := screen.battle.state.core()
	screen.view.select(core.id)
	_frames(screen, 1)
	var panel := screen.panel
	panel.fit(100000.0)
	assert_almost_eq(panel._scroll.custom_minimum_size.y, panel._body.get_combined_minimum_size().y, 0.01)
	panel.fit(300.0)
	var chrome := panel.get_combined_minimum_size().y - panel._scroll.custom_minimum_size.y
	assert_almost_eq(panel._scroll.custom_minimum_size.y, maxf(300.0 - chrome, 0.0), 0.01)
	panel.fit(0.0)
	assert_eq(panel._scroll.custom_minimum_size.y, 0.0)
	panel.set_minimized(true)
	panel.fit(300.0)
	assert_eq(panel._scroll.custom_minimum_size.y, 0.0)


func test_minimized_panel_is_only_one_button_high() -> void:
	var screen := _deployed()
	var core := screen.battle.state.core()
	var zapper := BattleFixtures.add(screen.battle, GameConfig.ZAPPER, core.position + Vector2(0, -168))
	screen.battle.connect_buildings(core.id, zapper.id)
	screen.view.select(zapper.id)
	_frames(screen, 2)
	var panel := screen.panel
	panel.set_minimized(true)
	assert_false(panel._icon.visible)
	assert_false(panel._status.visible)
	assert_false(panel._name.visible)
	assert_false(panel._scroll.visible)
	assert_lte(panel.get_combined_minimum_size().y, 52.0 + AppTheme.SPACING_SM * 2.0 + 2.0)


func test_custom_name_keeps_the_minimized_panel_one_row_high() -> void:
	var screen := _deployed()
	var battle := screen.battle
	var core := battle.state.core()
	var zapper := BattleFixtures.add(battle, GameConfig.ZAPPER, core.position + Vector2(0, -168))
	screen.view.select(zapper.id)
	_frames(screen, 1)
	var panel := screen.panel
	assert_eq(panel._title.text, Texts.building_name(GameConfig.ZAPPER))
	panel.set_minimized(true)
	var plain := panel.get_combined_minimum_size().y
	assert_true(battle.rename(zapper.id, "Northern gate keeper"))
	panel.refresh()
	assert_eq(panel._title.text, BuildingPanel.building_label(zapper))
	assert_false(panel._name.visible)
	assert_true(panel._title.clip_text)
	assert_almost_eq(panel.get_combined_minimum_size().y, plain, 0.5)
	await wait_process_frames(2)
	assert_almost_eq(panel.size.y, panel.get_combined_minimum_size().y, 1.0)
	panel.set_minimized(false)
	assert_eq(panel._title.text, Texts.building_name(GameConfig.ZAPPER))
	assert_true(panel._name.visible)


func test_minimized_lamp_panel_keeps_the_light_slider() -> void:
	var screen := _deployed()
	var lamp := BattleFixtures.add(screen.battle, GameConfig.LAMP, screen.battle.state.core().position + Vector2(0, -168))
	screen.view.select(lamp.id)
	_frames(screen, 1)
	var panel := screen.panel
	assert_true(panel._light_box.visible)
	assert_true(panel._light_hint.visible)
	panel.set_minimized(true)
	assert_false(panel._scroll.visible)
	assert_true(panel._light_box.visible)
	assert_true(panel.light_slider.is_visible_in_tree())
	assert_false(panel._light_hint.visible)
	panel.light_slider.value = 5.0
	assert_eq(lamp.light_radius, 5.0)
	panel.refresh()
	assert_eq(panel._light_value.text, Texts.format("PANEL_LIGHT_VALUE", [5.0, Formulas.lamp_draw(lamp)]))
	panel.set_minimized(false)
	assert_true(panel._light_hint.visible)
	screen.view.select(screen.battle.state.core_id)
	_frames(screen, 1)
	assert_false(panel._light_box.visible)


func test_link_and_relocate_minimize_the_panel() -> void:
	var screen := _deployed()
	var core := screen.battle.state.core()
	var zapper := BattleFixtures.add(screen.battle, GameConfig.ZAPPER, core.position + Vector2(0, -168))
	screen.view.select(core.id)
	_frames(screen, 1)
	assert_false(screen.panel.minimized)
	screen.start_link_pick(core.id)
	assert_true(screen.panel.minimized)
	screen.panel.set_minimized(false)
	screen.view.cancel_pick()
	screen.view.select(zapper.id)
	screen.start_relocate(zapper.id)
	assert_true(screen.panel.minimized)


func test_panel_lists_connections_and_cuts_them() -> void:
	var screen := _deployed()
	var battle := screen.battle
	var core := battle.state.core()
	var zapper := BattleFixtures.add(battle, GameConfig.ZAPPER, core.position + Vector2(0, -168))
	var second := BattleFixtures.add(battle, GameConfig.ZAPPER, core.position + Vector2(168, 0))
	battle.connect_buildings(core.id, zapper.id)
	battle.connect_buildings(core.id, second.id)
	screen.view.select(core.id)
	_frames(screen, 2)
	var panel := screen.panel
	assert_true(panel._links.visible)
	assert_eq(panel._link_rows.size(), 2)
	assert_true(panel._cut_out.visible)
	assert_false(panel._cut_in.visible)
	assert_eq(panel._cut_out.text, Texts.format("PANEL_CUT_OUT", [2]))
	assert_ne(panel._link_rows[0].data.text, "")
	screen.view.select(zapper.id)
	_frames(screen, 2)
	assert_eq(panel._link_rows.size(), 1)
	assert_true(panel._cut_in.visible)
	assert_false(panel._cut_out.visible)
	panel.building_picked.emit(core.id)
	assert_eq(screen.view.selected_id, core.id)
	panel.cut_pressed.emit(core.id, zapper.id)
	_frames(screen, 2)
	assert_null(battle.state.find_link(core.id, zapper.id))
	assert_not_null(battle.state.find_link(core.id, second.id))
	assert_eq(panel._link_rows.size(), 1)
	panel.cut_all_pressed.emit(core.id, false)
	_frames(screen, 2)
	assert_true(battle.state.links.is_empty())
	assert_false(panel._links.visible)


func test_panel_name_field_renames_and_shows_under_the_title() -> void:
	var screen := _deployed()
	var battle := screen.battle
	var core := battle.state.core()
	var zapper := BattleFixtures.add(battle, GameConfig.ZAPPER, core.position + Vector2(0, -168))
	screen.view.select(zapper.id)
	_frames(screen, 1)
	var panel := screen.panel
	assert_true(panel._name.visible)
	panel._name.text = "  North  "
	panel._name.text_submitted.emit(panel._name.text)
	assert_eq(zapper.label, "North")
	assert_eq(BuildingPanel.building_label(zapper), "%s · North" % Texts.building_name(GameConfig.ZAPPER))
	screen.view.select(core.id)
	_frames(screen, 1)
	assert_eq(panel._name.text, "")
	screen.view.select(zapper.id)
	_frames(screen, 1)
	assert_eq(panel._name.text, "North")
	var nest: Building = battle.state.enemy_buildings()[0]
	screen.view.select(nest.id)
	_frames(screen, 1)
	assert_false(panel._name.visible)


func test_pause_speed_and_skip() -> void:
	var screen := _deployed()
	screen.cycle_speed()
	assert_eq(screen.speed_index, 1)
	screen.start_round()
	assert_eq(screen.battle.state.phase, BattleState.Phase.FIGHT)
	screen.toggle_pause()
	assert_true(screen.paused)
	assert_true(screen.overlay is PauseOverlay)
	var time := screen.battle.state.time
	_frames(screen, 3)
	assert_eq(screen.battle.state.time, time)
	screen.toggle_pause()
	assert_false(screen.paused)
	screen.handle_back()
	assert_true(screen.paused)


func test_back_clears_modes_first() -> void:
	var screen := _deployed()
	screen.choose_kind(GameConfig.SOLAR)
	screen.handle_back()
	assert_eq(screen.view.build_kind, "")
	screen.view.select(screen.battle.state.core_id)
	screen.handle_back()
	assert_eq(screen.view.selected_id, -1)


func test_victory_shows_result_and_records() -> void:
	var screen := _deployed()
	watch_signals(screen)
	for building in screen.battle.state.enemy_buildings():
		screen.battle.combat.destroy(building)
	_frames(screen, 3)
	assert_eq(screen.battle.state.phase, BattleState.Phase.WON)
	assert_true(progress.is_conquered(0))
	assert_true(screen.report.first_conquest)
	assert_gte(screen.report.points, Challenges.CONQUER_POINTS)
	assert_eq(progress.skill_points(), screen.report.points)
	assert_true(FileAccess.file_exists(PROGRESS))
	_frames(screen, int(BattleScreen.VICTORY_DELAY * 30) + 5)
	assert_true(screen.overlay is ResultOverlay)
	var result := screen.overlay as ResultOverlay
	assert_eq(result.title_key(), "RESULT_CONQUERED")
	assert_false(result.shows_stars())
	result._show_star(0)
	result.retry_pressed.emit()
	assert_signal_emitted(screen, "retry_requested")
	result.menu_pressed.emit()
	screen.toggle_pause()
	assert_false(screen.paused)
	screen.handle_back()
	assert_signal_emitted(screen, "menu_requested")


func test_defeat_shows_result() -> void:
	var screen := _deployed()
	screen.battle.combat.destroy(screen.battle.state.core())
	_frames(screen, int(BattleScreen.DEFEAT_DELAY * 30) + 5)
	assert_eq(screen.battle.state.phase, BattleState.Phase.LOST)
	assert_true(screen.overlay is ResultOverlay)
	assert_false((screen.overlay as ResultOverlay).won)
	assert_eq((screen.overlay as ResultOverlay).title_key(), "RESULT_DEFEAT")
	assert_false((screen.overlay as ResultOverlay).can_resume)
	assert_false(screen.can_resume())
	assert_false(progress.is_conquered(0))


func test_long_fight_survives_all_feedback() -> void:
	var screen := _deployed(GameConfig.level_count() - 1)
	var state := screen.battle.state
	var core := state.core()
	state.money = 10000
	for kind in GameConfig.BUILD_ORDER:
		for attempt in 12:
			var spot := core.position + Vector2.from_angle(attempt * 0.52) * (120.0 + attempt * 18.0)
			if screen.battle.place(kind, spot) == BuildRules.OK:
				break
	for building in state.player_buildings():
		building.energy = Formulas.capacity(building)
	screen.start_round()
	screen.cycle_speed()
	screen.cycle_speed()
	_frames(screen, 900, 0.1)
	assert_gt(state.kills, 0)
	assert_gt(screen.view.fx.particles.size() + screen.view.fx.floaters.size(), -1)


func test_reward_director_handles_every_event() -> void:
	var screen := _screen()
	var position := Vector2(500, 500)
	var events: Array[Dictionary] = [
		{"type": "kill", "position": position, "kind": "behemoth", "bounty": 90, "combo": 12, "boss": true},
		{"type": "purge", "position": position, "kind": "crawler", "bounty": 4},
		{"type": "combo", "count": 35, "tier": 4, "bonus": 35, "position": position},
		{"type": "combo_end", "count": 35},
		{"type": "hit", "position": position, "amount": 12.0, "crit": false},
		{"type": "hit", "position": position, "amount": 40.0, "crit": true},
		{"type": "bolt", "from": position, "to": position + Vector2(100, 0), "crit": true},
		{"type": "chain", "points": PackedVector2Array([position, position + Vector2(50, 0)]), "crit": false},
		{"type": "plasma_launch", "from": position, "to": position},
		{"type": "plasma_hit", "position": position, "splash": 80.0, "crit": false},
		{"type": "enemy_attack", "from": position, "to": position, "ranged": true, "kind": "tank"},
		{"type": "enemy_attack", "from": position, "to": position, "ranged": false, "kind": "crawler"},
		{"type": "enemy_shot", "from": position, "to": position, "heavy": true},
		{"type": "building_hit", "id": 1, "position": position, "amount": 5.0, "player": true},
		{"type": "building_hit", "id": 1, "position": position, "amount": 5.0, "player": false},
		{"type": "shielded", "position": position, "shield": position, "amount": 3.0},
		{"type": "building_destroyed", "position": position, "kind": GameConfig.RELAY, "core": false},
		{"type": "structure_destroyed", "position": position, "kind": GameConfig.NEST, "bounty": 160, "left": 0},
		{"type": "collect", "position": position, "value": 5},
		{"type": "export", "position": position, "value": 5},
		{"type": "wave", "index": 9, "total": 16, "night": true, "round": 1, "count": 3},
		{"type": "wave", "index": 2, "total": 16, "night": false, "round": 1, "count": 1},
		{"type": "heal", "from": position, "to": position + Vector2(40, 0), "amount": 12.0},
		{"type": "landed", "position": position},
		{"type": "core_deployed", "id": 1, "position": position},
		{"type": "clear_order", "position": position},
		{"type": "scout_steer", "position": position},
		{"type": "scout_boarded", "position": position},
		{"type": "rifle", "from": position, "to": position + Vector2(80, 0)},
		{"type": "focus", "id": 1, "from": position, "to": position},
		{"type": "relocated", "id": 1, "kind": GameConfig.RELAY, "from": position, "position": position + Vector2(56, 0), "cost": 6},
		{"type": "stalled", "id": 1, "position": position},
		{"type": "cleared", "position": position, "obstacle": LevelMap.TREE, "cell": Vector2i(1, 1)},
		{"type": "cleared", "position": position, "obstacle": LevelMap.ROCK, "cell": Vector2i(1, 1)},
		{"type": "cleared", "position": position, "obstacle": LevelMap.TREE, "cell": Vector2i(1, 1), "fire": 3},
		{"type": "fuel_marked", "id": 3, "cell": Vector2i(1, 1), "position": position},
		{"type": "fuel_unmarked", "id": 3, "cell": Vector2i(1, 1), "position": position},
		{"type": "fuel_empty", "id": 3, "position": position},
		{"type": "scout_route", "position": position, "target": position},
		{"type": "fight_started", "round": 1},
		{"type": "nightfall", "round": 1},
		{"type": "night_over", "round": 1, "left": 3},
		{"type": "night_over", "round": 1, "left": 1, "burning": 4},
		{"type": "burned", "position": position, "kind": "stalker", "boss": false},
		{"type": "burned", "position": position, "kind": "behemoth", "boss": true},
		{"type": "round_cleared", "round": 1, "next": 2},
		{"type": "spawn", "position": position, "kind": "behemoth", "boss": true},
		{"type": "spawn", "position": position, "kind": "beetle", "boss": false, "guard": true},
		{"type": "spawn", "position": position, "kind": "beetle", "boss": false, "guard": true},
		{"type": "guards_ignited", "count": 3},
		{"type": "upgraded", "id": 1, "track": GameConfig.TRACK_OVERCLOCK, "level": 11, "position": position, "overloaded": true},
		{"type": "placed", "id": 9, "kind": GameConfig.SOLAR, "position": position},
		{"type": "link", "source": 1, "target": 2, "from": position, "to": position, "tower": false},
		{"type": "unlink", "source": 1, "target": 2, "from": position, "to": position, "cause": "cut"},
		{"type": "unlink", "source": 1, "target": 2, "from": position, "to": position, "cause": "sabotage"},
		{"type": "upgraded", "id": 1, "track": GameConfig.TRACK_RATE, "level": 2, "position": position},
		{"type": "sold", "id": 1, "kind": GameConfig.RELAY, "position": position, "refund": 15},
		{"type": "enemies_cleared", "count": 2, "units": [{"position": position, "kind": "crawler"}, {"position": Vector2(-90000, -90000), "kind": "beetle"}]},
		{"type": "day_changed", "day": 3},
		{"type": "victory", "stars": 3},
		{"type": "defeat"},
		{"type": "unknown_event"},
	]
	screen.rewards.handle(events)
	assert_gt(screen.view.fx.particles.size(), 0)
	assert_gt(screen.celebrations.confetti.size(), 0)
	assert_eq(screen.celebrations.coins.size(), 2)
	assert_eq(screen.rewards.time_scale(), RewardDirector.SLOWMO_SCALE)
	screen.rewards.update(RewardDirector.SLOWMO_TIME + 0.1)
	assert_eq(screen.rewards.time_scale(), 1.0)
	screen.rewards.coin_arrived(5)


func test_celebration_layer_coins_arrive() -> void:
	var layer := CelebrationLayer.new()
	add_child_autofree(layer)
	watch_signals(layer)
	layer.fly_coin(Vector2.ZERO, Vector2(100, 100), 7)
	assert_eq(layer.in_flight(), 7)
	layer._process(CelebrationLayer.COIN_TIME + 0.01)
	assert_eq(layer.in_flight(), 0)
	assert_signal_emitted_with_parameters(layer, "coin_arrived", [7])
	for i in CelebrationLayer.MAX_COINS + 2:
		layer.fly_coin(Vector2.ZERO, Vector2.ONE, 1)
	assert_eq(layer.coins.size(), CelebrationLayer.MAX_COINS)
	layer.burst_confetti(Vector2.ZERO, CelebrationLayer.MAX_CONFETTI + 10)
	assert_eq(layer.confetti.size(), CelebrationLayer.MAX_CONFETTI)
	layer._process(5.0)
	assert_true(layer.confetti.is_empty())
	assert_eq(CelebrationLayer.bezier(Vector2.ZERO, Vector2(50, 0), Vector2(100, 0), 1.0), Vector2(100, 0))


func _world() -> WorldMapScreen:
	var menu := WorldMapScreen.new().setup(progress, settings)
	add_child_autofree(menu)
	return menu


func test_world_map_walks_to_regions() -> void:
	progress.mark_conquered(0)
	var menu := _world()
	watch_signals(menu)
	menu._process(0.1)
	assert_eq(menu.panel.index, 0)
	assert_not_null(menu.panel.campaign_button)
	assert_not_null(menu.panel.survival_button)
	assert_gt(menu.map.top_inset, 0.0)
	assert_eq(menu.map.node_at(menu.map.node_position(1)), 1)
	assert_eq(menu.map.node_at(Vector2(-500, -500)), -1)
	menu.map.tap(menu.map.node_position(7))
	assert_false(menu.map.walker.is_walking())
	assert_eq(menu.panel.index, 7)
	assert_null(menu.panel.campaign_button)
	menu.map.tap(menu.map.node_position(1))
	assert_true(menu.map.walker.is_walking())
	assert_true(menu.panel.campaign_button.disabled)
	for i in 300:
		menu.map._process(0.05)
		if not menu.map.walker.is_walking():
			break
	assert_eq(menu.map.walker.location, 1)
	assert_eq(progress.location, 1)
	assert_false(menu.panel.campaign_button.disabled)
	assert_null(menu.panel.survival_button)
	menu.panel.campaign_button.pressed.emit()
	assert_signal_emitted_with_parameters(menu, "campaign_chosen", [1])
	menu._on_region_tapped(1)
	assert_eq(menu.panel.index, 1)
	menu.map.queue_redraw()


func test_region_panel_offers_survival_targets() -> void:
	progress.mark_conquered(0)
	var menu := _world()
	watch_signals(menu)
	var panel := menu.panel
	assert_eq(panel.survival_days, GameConfig.SURVIVAL_TARGETS[0])
	assert_eq(panel.option_buttons.size(), GameConfig.SURVIVAL_TARGETS.size() + 1)
	assert_eq(panel.status_key(), "REGION_CONQUERED")
	panel.option_buttons.back().pressed.emit()
	assert_eq(panel.survival_days, 0)
	panel.survival_button.pressed.emit()
	assert_signal_emitted_with_parameters(menu, "survival_chosen", [0, 0])
	panel.select_days(GameConfig.SURVIVAL_TARGETS[2])
	panel.survival_button.pressed.emit()
	assert_signal_emitted_with_parameters(menu, "survival_chosen", [0, GameConfig.SURVIVAL_TARGETS[2]])
	progress.regions["dawn"].stars = 2
	panel.show_region(1)
	assert_eq(panel.status_key(), "REGION_ENEMY")
	panel.show_region(0)
	assert_eq(panel.survival_days, GameConfig.SURVIVAL_TARGETS[2])
	panel.show_region(5)
	assert_eq(panel.status_key(), "REGION_LOCKED")
	assert_eq(RegionPanel.survival_options().back(), 0)


func test_world_map_progress_reset_needs_confirmation() -> void:
	progress.mark_conquered(0)
	var menu := _world()
	watch_signals(menu)
	menu.reset_button.pressed.emit()
	assert_not_null(menu.reset_dialog)
	menu.confirm_reset_progress()
	menu.reset_dialog.cancel_button.pressed.emit()
	assert_signal_not_emitted(menu, "progress_reset")
	assert_true(progress.is_conquered(0))
	menu.confirm_reset_progress()
	assert_true(menu.handle_back())
	menu.confirm_reset_progress()
	menu.reset_dialog.confirm_button.pressed.emit()
	assert_signal_emitted(menu, "progress_reset")
	assert_false(progress.is_conquered(0))


func test_world_map_settings_and_tech() -> void:
	progress.mark_conquered(0)
	var menu := _world()
	watch_signals(menu)
	menu._toggle_sound()
	assert_true(settings.sound)
	menu._toggle_haptics()
	assert_true(settings.haptics)
	menu._cycle_language()
	assert_signal_emitted(menu, "locale_changed")
	settings.set_locale("")
	assert_false(menu.handle_back())
	menu.tech_button.pressed.emit()
	assert_true(is_instance_valid(menu.tech))
	menu.open_tech()
	var tech := menu.tech
	assert_true(tech.buttons.has("laser"))
	assert_false((tech.buttons["laser"] as Button).disabled)
	assert_true((tech.buttons["plasma"] as Button).disabled)
	assert_true(tech.reset_button.disabled)
	(tech.buttons["laser"] as Button).pressed.emit()
	assert_true(progress.has_tech("laser"))
	assert_eq(progress.skill_points(), 0)
	assert_true(menu.tech_button.text.contains(Texts.format("WORLD_TECH", [0])))
	tech.buy("plasma")
	assert_false(progress.has_tech("plasma"))
	assert_false(tech.reset_button.disabled)
	tech.confirm_reset()
	assert_not_null(tech.dialog)
	assert_true(menu.handle_back())
	tech.confirm_reset()
	tech._reset_confirmed()
	assert_false(progress.has_tech("laser"))
	assert_eq(progress.skill_points(), Challenges.CONQUER_POINTS)
	assert_true(menu.handle_back())
	assert_true(tech.is_queued_for_deletion())
	assert_eq(TechOverlay.icon_kind("laser"), GameConfig.LASER)
	assert_eq(TechOverlay.icon_kind("weapons_1"), GameConfig.ZAPPER)
	assert_eq(TechOverlay.icon_kind("plating_1"), GameConfig.BULWARK)
	assert_eq(TechOverlay.icon_kind("funding_1"), GameConfig.CORE)
	assert_eq(TechOverlay.icon_kind("solar_output"), GameConfig.SOLAR)
	assert_eq(WorldMapView.faction_of(3), GameConfig.CAMP)
	assert_eq(WorldMapView.faction_of(0), GameConfig.NEST)


func test_survival_battle_screen() -> void:
	progress.mark_conquered(0)
	var screen := BattleScreen.new().setup(0, progress, settings, sfx, 0.0, BattleSetup.survival(GameConfig.SURVIVAL_TARGETS[0]))
	add_child_autofree(screen)
	assert_false(screen.tutorial.is_active())
	var state := screen.battle.state
	assert_true(state.is_survival())
	BattleFixtures.open_terrain(state)
	screen.battle.deploy_core(state.map.drop)
	_frames(screen, 1)
	assert_eq(BattleHud.day_text(state), Texts.format("HUD_DAY_OF", [1, GameConfig.SURVIVAL_TARGETS[0]]))
	state.round_number = GameConfig.SURVIVAL_TARGETS[0]
	screen.start_round()
	screen.battle.spawns.end_night()
	state.enemies.clear()
	_frames(screen, 2)
	assert_eq(state.phase, BattleState.Phase.WON)
	assert_eq(progress.stars_for(0), 1)
	assert_true(progress.is_done(0, Challenges.SURVIVE))
	_frames(screen, int(BattleScreen.VICTORY_DELAY * 30) + 5)
	var result := screen.overlay as ResultOverlay
	assert_eq(result.title_key(), "RESULT_SURVIVED")
	assert_true(result.shows_stars())
	result._show_star(0)
	result._show_star(9)


func test_result_overlay_texts() -> void:
	var report := BattleReport.new()
	report.survival = true
	report.days = 12
	var endless := ResultOverlay.new().setup(report, [] as Array[Array])
	assert_eq(endless.title_key(), "RESULT_ENDLESS")
	assert_eq(endless.subtitle(), Texts.format("RESULT_ENDLESS_TEXT", [12]))
	assert_false(endless.shows_stars())
	report.target = 15
	assert_eq(endless.title_key(), "RESULT_DEFEAT")
	assert_eq(endless.subtitle(), Texts.format("RESULT_SURVIVAL_LOST_TEXT", [12, 15]))
	report.survival = false
	assert_eq(endless.subtitle(), Texts.t("RESULT_DEFEAT_TEXT"))
	add_child_autofree(endless)


func test_pause_overlay_toggles_settings() -> void:
	var overlay := PauseOverlay.new().setup(settings)
	add_child_autofree(overlay)
	overlay._toggle_sound()
	overlay._toggle_haptics()
	assert_true(settings.sound)
	assert_true(settings.haptics)


func test_main_switches_screens() -> void:
	var main: Node = load("res://src/ui/main.gd").new()
	add_child_autofree(main)
	main.progress = progress
	main.show_menu()
	assert_true(main.menu is WorldMapScreen)
	main.start_campaign(1)
	assert_false(main.screen is BattleScreen)
	main.start_survival(0, 5)
	assert_false(main.screen is BattleScreen)
	main.start_campaign(0)
	assert_true(main.screen is BattleScreen)
	assert_false(main.last_rules.is_survival())
	main.retry()
	assert_true(main.screen is BattleScreen)
	main.resume(null)
	var saved := BattleFixtures.deployed(0)
	saved.start_round()
	main.resume(saved.checkpoint)
	assert_true(main.screen is BattleScreen)
	assert_eq((main.screen as BattleScreen).resume, saved.checkpoint)
	assert_eq(main.last_index, 0)
	progress.mark_conquered(0)
	main.start_survival(0, 10)
	assert_true(main.last_rules.is_survival())
	assert_eq(main.last_rules.days, 10)
	main._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_true((main.screen as BattleScreen).paused)
	(main.screen as BattleScreen).menu_requested.emit()
	assert_true(main.screen is CanvasLayer)
	assert_gte(main.safe_top(), 0.0)



func test_view_culls_everything_off_screen() -> void:
	var screen := _deployed()
	var view := screen.view
	_frames(screen, 1)
	var rect := view.visible_world_rect()
	assert_true(rect.has_point(view.center))
	assert_true(view.is_on_screen(view.center))
	var outside := view.center + Vector2(rect.size.x, 0)
	assert_false(view.is_on_screen(outside))
	assert_true(view.is_on_screen(outside, rect.size.x))
	assert_true(view._segment_on_screen(outside, view.center))
	assert_false(view._segment_on_screen(outside, outside + Vector2(50, 50)))
	var zoomed := rect.size
	view.zoom *= 0.5
	_frames(screen, 1)
	assert_gt(view.visible_world_rect().size.x, zoomed.x)


func test_energy_stats_panel_shows_changes_since_planning_began() -> void:
	var scouting := _screen()
	_frames(scouting, 1)
	assert_false(scouting.hud._stats_button.visible)
	var screen := _deployed()
	var state := screen.battle.state
	var hud := screen.hud
	_frames(screen, 1)
	assert_true(hud._stats_button.visible)
	assert_false(hud.stats_panel.visible)
	hud._stats_button.pressed.emit()
	_frames(screen, 1)
	assert_true(hud.stats_panel.visible)
	assert_eq(hud.stats_panel.value_text(2), NumberFormat.grouped(int(Formulas.capacity(state.core()))))
	assert_eq(hud.stats_panel.delta_text(2), "")
	state.money = 1000
	assert_eq(screen.battle.place(GameConfig.BATTERY, state.core().position + Vector2(0, -150)), BuildRules.OK)
	_frames(screen, 1)
	assert_eq(hud.stats_panel.delta_text(2), "+400")
	assert_false(hud.stats_panel._pulse)
	screen.handle_back()
	assert_false(hud.stats_panel.visible)
	hud.toggle_stats()
	assert_true(hud.stats_panel.visible)
	hud.stats_panel.closed.emit()
	assert_false(hud.stats_panel.visible)


func test_energy_stats_panel_helpers() -> void:
	var detached := EnergyStatsPanel.new()
	detached.refresh(BattleFixtures.battle(0).state, null)
	detached.free()
	assert_eq(EnergyStatsPanel.trend_color(1), AppTheme.SUCCESS)
	assert_eq(EnergyStatsPanel.trend_color(-1), AppTheme.DANGER)
	assert_eq(EnergyStatsPanel.trend_color(0), AppTheme.ON_SURFACE_VARIANT)


func test_undo_button_reverts_the_last_planning_step() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var core := state.core()
	_frames(screen, 1)
	assert_true(screen.hud._undo.visible)
	assert_true(screen.hud._undo.disabled)
	assert_true(screen.hud._reset.disabled)
	var money := state.money
	screen.battle.place(GameConfig.RELAY, core.position + Vector2(0, -150))
	var relay: Building = state.player_buildings().back()
	screen.view.select(relay.id)
	_frames(screen, 1)
	assert_false(screen.hud._undo.disabled)
	assert_false(screen.hud._reset.disabled)
	screen.hud._undo.pressed.emit()
	assert_null(state.building(relay.id))
	assert_eq(state.money, money)
	assert_eq(screen.view.selected_id, -1)
	assert_false(screen.panel.visible)
	_frames(screen, 1)
	assert_true(screen.hud._undo.disabled)
	screen.undo_plan()
	assert_eq(state.money, money)


func test_reset_asks_first_and_restores_the_phase_start() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var core := state.core()
	state.money = 1000
	screen.battle.history.begin(state)
	screen.battle.place(GameConfig.RELAY, core.position + Vector2(0, -150))
	screen.battle.upgrade(core.id, GameConfig.TRACK_RATE)
	screen.view.select(core.id)
	_frames(screen, 1)
	screen.hud._reset.pressed.emit()
	assert_true(screen.overlay is ConfirmOverlay)
	(screen.overlay as ConfirmOverlay).cancel_button.pressed.emit()
	assert_false(screen.is_overlay_open())
	assert_eq(core.level(GameConfig.TRACK_RATE), 1)
	screen.confirm_reset()
	assert_true(screen.is_overlay_open())
	(screen.overlay as ConfirmOverlay).confirm_button.pressed.emit()
	assert_false(screen.is_overlay_open())
	assert_eq(core.level(GameConfig.TRACK_RATE), 0)
	assert_eq(state.money, 1000)
	assert_eq(state.player_buildings().size(), 1)
	assert_eq(screen.view.selected_id, core.id)
	assert_true(screen.panel.visible)
	screen.confirm_reset()
	assert_false(screen.is_overlay_open())
	screen.start_round()
	_frames(screen, 1)
	assert_false(screen.hud._undo.visible)
	assert_false(screen.hud._reset.visible)


func test_upgrade_rows_preview_energy_draw() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var zapper := BattleFixtures.add(screen.battle, GameConfig.ZAPPER, state.core().position + Vector2(0, -150))
	screen.view.select(zapper.id)
	_frames(screen, 1)
	var speed: Label = screen.panel._track_rows[GameConfig.TRACK_SPEED].detail
	assert_true(speed.text.contains(StatText.draw_change(zapper, GameConfig.TRACK_SPEED)))
	var power: Label = screen.panel._track_rows[GameConfig.TRACK_POWER].detail
	assert_false(power.text.contains(Icons.BOLT))
	state.money = 1000
	screen.upgrade(zapper.id, GameConfig.TRACK_SPEED)
	assert_eq(zapper.level(GameConfig.TRACK_SPEED), 1)
	assert_false(screen.panel._pulse)


func _touch(index: int, position: Vector2, pressed: bool) -> InputEventScreenTouch:
	var touch := InputEventScreenTouch.new()
	touch.index = index
	touch.position = position
	touch.pressed = pressed
	return touch


func _drag(index: int, position: Vector2) -> InputEventScreenDrag:
	var drag := InputEventScreenDrag.new()
	drag.index = index
	drag.position = position
	return drag


func _landed_scout() -> BattleScreen:
	var screen := _screen()
	BattleFixtures.open_terrain(screen.battle.state)
	_frames(screen, int(GameConfig.DROP_TIME * 30) + 3)
	return screen


func test_scout_is_steered_by_dragging_anywhere_on_the_map() -> void:
	var screen := _landed_scout()
	var view := screen.view
	var state := screen.battle.state
	assert_true(view.scout_active)
	assert_true(view.can_steer())
	var anchor := view.view_size() * 0.5
	view._on_touch(_touch(0, anchor, true))
	assert_eq(view.gesture, BattleView.Gesture.STEER_PENDING)
	assert_true(view.is_steering())
	assert_eq(view.stick_origin, anchor)
	assert_eq(view.stick_vector, Vector2.ZERO)
	view._on_drag(_drag(0, anchor + Vector2(0, -200)))
	assert_eq(view.gesture, BattleView.Gesture.STEER)
	assert_eq(view.stick_vector, Vector2.UP)
	assert_eq(view.stick_origin, anchor + Vector2(0, -200 + BattleView.STICK_RADIUS))
	assert_eq(screen.steering_input(), Vector2.UP)
	var start := state.scout.position
	_frames(screen, 30)
	assert_lt(state.scout.position.y, start.y - 50.0)
	await wait_process_frames(1)
	view._on_touch(_touch(0, anchor + Vector2(0, -200), false))
	assert_eq(view.gesture, BattleView.Gesture.NONE)
	assert_eq(view.stick_vector, Vector2.ZERO)
	assert_eq(view.stick_origin, Vector2.INF)
	assert_eq(screen.steering_input(), Vector2.ZERO)


func test_floating_stick_keeps_a_deadzone_and_follows_the_finger() -> void:
	var screen := _landed_scout()
	var view := screen.view
	view.steer_to(Vector2(300, 600))
	assert_eq(view.stick_origin, Vector2(300, 600))
	view.steer_to(Vector2(305, 600))
	assert_eq(view.stick_vector, Vector2.ZERO)
	view.steer_to(Vector2(345, 600))
	assert_almost_eq(view.stick_vector.x, 45.0 / BattleView.STICK_RADIUS, 0.0001)
	view.steer_to(Vector2(300, 900))
	assert_almost_eq(view.stick_vector.length(), 1.0, 0.0001)
	assert_almost_eq(view.stick_origin.distance_to(Vector2(300, 900)), BattleView.STICK_RADIUS, 0.0001)
	view.release_stick()
	assert_eq(view.stick_point, Vector2.INF)
	assert_eq(view.stick_vector, Vector2.ZERO)


func test_short_tap_while_steering_still_selects_or_clears() -> void:
	var screen := _landed_scout()
	var view := screen.view
	var anchor := view.view_size() * 0.5
	view._on_touch(_touch(0, anchor, true))
	assert_eq(view.gesture, BattleView.Gesture.STEER_PENDING)
	view._on_drag(_drag(0, anchor + Vector2(4, 0)))
	assert_eq(view.gesture, BattleView.Gesture.STEER_PENDING)
	view._on_touch(_touch(0, anchor + Vector2(4, 0), false))
	assert_eq(view.gesture, BattleView.Gesture.NONE)
	assert_eq(view.selected_id, -1)
	assert_eq(view.stick_vector, Vector2.ZERO)


func test_second_finger_cancels_the_floating_stick() -> void:
	var screen := _landed_scout()
	var view := screen.view
	var anchor := view.view_size() * 0.5
	view._on_touch(_touch(0, anchor, true))
	view._on_drag(_drag(0, anchor + Vector2(80, 0)))
	assert_gt(view.stick_vector.x, 0.5)
	view._on_touch(_touch(1, anchor + Vector2(0, 150), true))
	assert_eq(view.gesture, BattleView.Gesture.NONE)
	assert_eq(view.stick_vector, Vector2.ZERO)


func test_rover_is_steered_by_dragging_during_the_fight() -> void:
	var screen := _deployed(1)
	var view := screen.view
	var state := screen.battle.state
	var core := state.core()
	var rover := BattleFixtures.add(screen.battle, GameConfig.ROVER, core.position + Vector2(0, -150))
	rover.energy = Formulas.capacity(rover)
	screen.battle.connect_buildings(core.id, rover.id)
	view.select(rover.id)
	assert_false(view.can_steer())
	view.begin(core.position, view.view_size() * 0.5)
	assert_ne(view.gesture, BattleView.Gesture.STEER_PENDING)
	view.finish(core.position)
	screen.start_round()
	view.select(rover.id)
	_frames(screen, 1)
	assert_false(view.can_steer())
	screen.toggle_mode()
	assert_true(view.can_steer())
	var anchor := view.view_size() * 0.5
	var start := rover.position
	view._on_touch(_touch(0, anchor, true))
	view._on_drag(_drag(0, anchor + Vector2(200, 0)))
	assert_eq(screen.steering_input(), Vector2.RIGHT)
	_frames(screen, 20)
	assert_gt(rover.position.x, start.x + 20.0)
	assert_eq(rover.steer, Vector2.RIGHT)
	view.set_mode(BattleView.Mode.CONNECT)
	assert_false(view.can_steer())
	_frames(screen, 2)
	assert_eq(view.gesture, BattleView.Gesture.NONE)
	assert_eq(view.stick_vector, Vector2.ZERO)
	assert_eq(rover.steer, Vector2.ZERO)
	view.set_mode(BattleView.Mode.MOVE)
	view.set_build_kind(GameConfig.RELAY)
	assert_false(view.can_steer())


func test_status_mode_shows_the_legend_and_back_leaves_it() -> void:
	var scouting := _screen()
	_frames(scouting, 2)
	assert_false(scouting.hud._status_button.visible)
	scouting.toggle_status()
	assert_false(scouting.view.status_mode)
	var screen := _deployed()
	var state := screen.battle.state
	_frames(screen, 1)
	assert_true(screen.hud._status_button.visible)
	assert_false(screen.hud.legend_visible())
	screen.hud.status_pressed.emit()
	assert_true(screen.view.status_mode)
	assert_true(screen.hud.legend_visible())
	assert_eq(screen.hud._toast_label.text, Texts.t("TOAST_STATUS_ON"))
	screen.view.select(state.core_id)
	screen.handle_back()
	assert_eq(screen.view.selected_id, -1)
	assert_true(screen.view.status_mode)
	screen.handle_back()
	assert_false(screen.view.status_mode)
	assert_false(screen.hud.legend_visible())
	assert_eq(screen.hud._toast_label.text, Texts.t("TOAST_STATUS_OFF"))
	screen.toggle_status()
	state.phase = BattleState.Phase.LOST
	_frames(screen, 2)
	assert_false(screen.view.status_mode)
	screen.toggle_status()
	assert_false(screen.view.status_mode)


func test_status_mode_paints_the_supply_chain() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var core := state.core()
	assert_eq(screen.battle.place(GameConfig.RELAY, core.position + Vector2(0, -224)), BuildRules.OK)
	var relay: Building = state.of_kind(GameConfig.RELAY)[0]
	var zapper := BattleFixtures.add(screen.battle, GameConfig.ZAPPER, relay.position + Vector2(0, -112))
	var lonely := BattleFixtures.add(screen.battle, GameConfig.ZAPPER, core.position + Vector2(300, 0))
	screen.battle.connect_buildings(core.id, relay.id)
	screen.battle.connect_buildings(relay.id, zapper.id)
	state.move_building(relay, core.position + Vector2(0, -420))
	screen.toggle_status()
	screen.view.select(zapper.id)
	_frames(screen, 2)
	await wait_process_frames(2)
	var audit := screen.battle.audit()
	var scenario := EnergyAudit.view_scenario(state)
	assert_eq(scenario, EnergyAudit.WORST)
	assert_true(audit.chain(zapper.id).buildings.has(core.id))
	assert_eq(audit.verdict(lonely.id), EnergyAudit.Verdict.LOW)
	assert_eq(audit.cause(lonely.id), EnergyAudit.Cause.NO_SOURCE)
	assert_eq(audit.missing(lonely.id), 1.0)
	assert_true(screen.panel._status.visible)
	assert_eq(screen.panel._status_title.text, StatusText.summary(audit, zapper, scenario))
	assert_eq(screen.panel._status_values.size(), StatText.status_rows(zapper, audit, scenario).size())
	screen.view.select(core.id)
	_frames(screen, 1)
	assert_false(screen.panel._status.visible)
	screen.view.select(relay.id)
	_frames(screen, 1)
	assert_true(screen.panel._sell.text.contains(Texts.format("PANEL_SELL_FULL", [relay.spent])))
	screen.view.select(-1)
	await wait_process_frames(1)


func test_panel_can_be_minimized_while_the_selection_stays() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var core := state.core()
	var zapper := BattleFixtures.add(screen.battle, GameConfig.ZAPPER, core.position + Vector2(0, -168))
	screen.battle.connect_buildings(core.id, zapper.id)
	screen.view.select(zapper.id)
	_frames(screen, 2)
	var panel := screen.panel
	assert_false(panel.minimized)
	assert_true(panel._scroll.visible)
	assert_true(panel._info.visible)
	assert_eq(panel._minimize.text, Icons.EXPAND_MORE)
	var full_height := panel.get_combined_minimum_size().y
	panel._minimize.pressed.emit()
	assert_true(panel.minimized)
	assert_false(panel._scroll.visible)
	assert_false(panel._info.visible)
	assert_false(panel._status.visible)
	assert_false(panel._status_cause.visible)
	assert_eq(panel._minimize.text, Icons.EXPAND_LESS)
	assert_lt(panel.get_combined_minimum_size().y, full_height)
	assert_true(panel.visible)
	assert_eq(screen.view.selected_id, zapper.id)
	assert_true(screen.view.shows_beam_labels())
	_frames(screen, 2)
	await wait_process_frames(1)
	screen.view.select(core.id)
	_frames(screen, 1)
	assert_true(panel.minimized)
	assert_false(panel._scroll.visible)
	panel.toggle_minimized()
	assert_false(panel.minimized)
	assert_true(panel._scroll.visible)
	assert_true(panel._info.visible)


func test_selected_building_labels_only_its_own_beams() -> void:
	var screen := _deployed()
	var battle := screen.battle
	var state := battle.state
	var core := state.core()
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(0, -224))
	var zapper := BattleFixtures.add(battle, GameConfig.ZAPPER, relay.position + Vector2(0, -280))
	battle.connect_buildings(core.id, relay.id)
	battle.connect_buildings(relay.id, zapper.id)
	var feed := state.find_link(core.id, relay.id)
	var beam := state.find_link(relay.id, zapper.id)
	var view := screen.view
	assert_true(view.labeled_links().is_empty())
	view.select(zapper.id)
	assert_eq(view.labeled_links(), [beam] as Array[EnergyLink])
	var audit := battle.audit()
	var scenario := EnergyAudit.view_scenario(state)
	assert_eq(view.beam_label(beam), StatusText.link_label(audit, beam.key(), false, scenario))
	assert_false(view.beam_label(beam).contains("%"))
	view.select(relay.id)
	assert_eq(view.labeled_links().size(), 2)
	assert_true(view.labeled_links().has(feed))
	assert_eq(view.beam_label(beam), StatusText.link_label(audit, beam.key(), true, scenario))
	assert_true(view.beam_label(beam).contains("(−"))
	assert_false(view.beam_label(feed).contains("%"))
	view.select(core.id)
	assert_eq(view.labeled_links(), [feed] as Array[EnergyLink])
	view.select(-1)


func test_selected_building_labels_its_beams() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var core := state.core()
	var zapper := BattleFixtures.add(screen.battle, GameConfig.ZAPPER, core.position + Vector2(0, -168))
	screen.battle.connect_buildings(core.id, zapper.id)
	assert_false(screen.view.status_mode)
	assert_false(screen.view.shows_beam_labels())
	screen.view.select(zapper.id)
	assert_true(screen.view.shows_beam_labels())
	_frames(screen, 2)
	await wait_process_frames(2)
	var nest: Building = state.enemy_buildings()[0] if not state.enemy_buildings().is_empty() else null
	if nest != null:
		screen.view.select(nest.id)
		assert_false(screen.view.shows_beam_labels())
	screen.view.select(-1)
	assert_false(screen.view.shows_beam_labels())
	screen.toggle_status()
	assert_true(screen.view.shows_beam_labels())
	_frames(screen, 2)
	await wait_process_frames(2)


func test_exporter_ring_follows_its_cycle() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var exporter := BattleFixtures.add(screen.battle, GameConfig.EXPORTER, state.core().position + Vector2(0, -168))
	exporter.energy = Formulas.capacity(exporter)
	exporter.export_buffer = Formulas.export_batch(exporter) * 0.5
	assert_almost_eq(Formulas.export_progress(exporter), 0.5, 0.001)
	_frames(screen, 2)
	await wait_process_frames(1)
	assert_true(exporter.exporting)


func test_guards_are_painted_and_burn_in_the_planning_phase() -> void:
	var screen := _deployed()
	var battle := screen.battle
	var nest := battle.state.enemy_buildings()[0]
	battle.start_round()
	var guard := battle.spawns.spawn_guard(nest)
	battle.state.fog.cells.fill(FogOfWar.VISIBLE)
	screen.view.focus(guard.position)
	screen.view.select(nest.id)
	_frames(screen, 1)
	await wait_process_frames(1)
	battle.spawns.ignite_guards()
	_frames(screen, 1)
	await wait_process_frames(1)
	assert_true(guard.is_burning())


func test_status_mode_only_touches_links_of_the_selection() -> void:
	var screen := _deployed()
	var battle := screen.battle
	var core := battle.state.core()
	var near := BattleFixtures.add(battle, GameConfig.ZAPPER, core.position + Vector2(0, -168))
	var far := BattleFixtures.add(battle, GameConfig.ZAPPER, core.position + Vector2(168, 0))
	battle.connect_buildings(core.id, near.id)
	battle.connect_buildings(core.id, far.id)
	var to_near := battle.state.find_link(core.id, near.id)
	var to_far := battle.state.find_link(core.id, far.id)
	assert_false(screen.view.touches_selected(to_near))
	screen.view.select(near.id)
	assert_true(screen.view.touches_selected(to_near))
	assert_false(screen.view.touches_selected(to_far))
	screen.view.select(core.id)
	assert_true(screen.view.touches_selected(to_far))
	screen.toggle_status()
	_frames(screen, 2)
	await wait_process_frames(2)
	screen.view.select(-1)
	await wait_process_frames(1)


func test_build_bar_collapses_and_offers_a_big_cancel_button() -> void:
	var screen := _deployed()
	var bar := screen.build_bar
	_frames(screen, 1)
	assert_true(bar.build_button.visible)
	assert_false(bar.shows_cards())
	assert_false(bar.cancel_button.visible)
	bar.build_button.pressed.emit()
	assert_true(bar.expanded)
	assert_true(bar.shows_cards())
	assert_true(bar._options.visible)
	assert_false(bar.build_button.visible)
	assert_eq(bar.once_button.theme_type_variation, "PrimaryButton")
	assert_eq(bar.multi_button.theme_type_variation, "Button")
	assert_not_null(bar.button_for(GameConfig.LAMP))
	bar.button_for(GameConfig.SOLAR).pressed.emit()
	assert_eq(screen.view.build_kind, GameConfig.SOLAR)
	_frames(screen, 1)
	assert_true(bar.expanded)
	assert_false(bar.shows_cards())
	assert_true(bar.cancel_button.visible)
	assert_false(bar.build_button.visible)
	assert_eq(bar.cancel_button.theme_type_variation, "DangerButton")
	assert_true(bar.cancel_button.text.contains(Texts.building_name(GameConfig.SOLAR)))
	bar.cancel_button.pressed.emit()
	assert_eq(screen.view.build_kind, "")
	_frames(screen, 1)
	assert_true(bar.shows_cards())
	assert_false(bar.build_button.visible)
	assert_false(bar.cancel_button.visible)
	bar.collapse_button.pressed.emit()
	assert_false(bar.expanded)
	assert_true(bar.build_button.visible)
	bar.multi_button.pressed.emit()
	assert_true(bar.repeat)
	assert_eq(bar.multi_button.theme_type_variation, "PrimaryButton")
	assert_eq(bar.once_button.theme_type_variation, "Button")
	assert_true(screen.view.build_repeat)
	bar.once_button.pressed.emit()
	assert_false(screen.view.build_repeat)
	bar.set_collapsible(false)
	assert_true(bar.shows_cards())
	assert_false(bar._options.visible)


func test_build_bar_stays_open_after_placing_and_back_closes_it() -> void:
	var screen := _deployed()
	var bar := screen.build_bar
	var state := screen.battle.state
	state.money = 1000
	bar.build_button.pressed.emit()
	screen.choose_kind(GameConfig.RELAY)
	_frames(screen, 1)
	assert_false(bar.shows_cards())
	var count := state.player_buildings().size()
	screen.view.place_at(state.core().position + Vector2(150, 0))
	assert_eq(state.player_buildings().size(), count + 1)
	assert_eq(screen.view.build_kind, "")
	_frames(screen, 1)
	assert_true(bar.expanded)
	assert_true(bar.shows_cards())
	assert_false(bar.build_button.visible)
	screen.handle_back()
	assert_false(bar.expanded)
	assert_true(bar.build_button.visible)
	assert_false(screen.paused)
	await wait_process_frames(2)
	assert_almost_eq(bar.size.y, bar.get_combined_minimum_size().y, 1.0)


func test_primary_buttons_are_dark_blue() -> void:
	var theme := AppTheme.build()
	var normal := theme.get_stylebox(&"normal", "PrimaryButton") as StyleBoxFlat
	assert_eq(normal.bg_color, AppTheme.PRIMARY_CONTAINER)
	assert_eq(normal.border_color, AppTheme.PRIMARY_OUTLINE)
	assert_eq(theme.get_color(&"font_color", "PrimaryButton"), AppTheme.ENERGY)
	assert_lt(AppTheme.PRIMARY_CONTAINER.get_luminance(), 0.25)
	var screen := _deployed()
	screen.hud.set_status_mode(true)
	var active := screen.hud._status_button.get_theme_stylebox(&"normal") as StyleBoxFlat
	assert_eq(active.bg_color, AppTheme.PRIMARY_CONTAINER)
	assert_eq(screen.hud._status_button.get_theme_color(&"font_color"), AppTheme.ENERGY)
	screen.hud.set_status_mode(false)


func test_cancel_during_relocation_keeps_the_building_selected() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	screen.battle.place(GameConfig.RELAY, state.core().position + Vector2(150, 0))
	var relay: Building = state.player_buildings().back()
	screen.start_relocate(relay.id)
	_frames(screen, 1)
	assert_true(screen.build_bar.visible)
	assert_true(screen.build_bar.cancel_button.visible)
	screen.build_bar.cancel_button.pressed.emit()
	assert_false(screen.view.is_relocating())
	assert_eq(screen.view.build_kind, "")
	assert_eq(screen.view.selected_id, relay.id)


func test_far_core_spot_sends_the_soldier_walking() -> void:
	var screen := _landed_scout()
	var state := screen.battle.state
	var distance := GameConfig.CORE_DEPLOY_RANGE + GameConfig.CELL * 4.0
	var far := Vector2.INF
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]:
		var point: Vector2 = state.scout.position + direction * distance
		if state.map.contains(point, GameConfig.CELL * 2.0):
			far = point
			break
	assert_ne(far, Vector2.INF)
	watch_signals(screen.view)
	screen.choose_kind(GameConfig.CORE)
	screen.view.begin(far)
	screen.view.tap(far)
	assert_null(state.core())
	assert_signal_emitted(screen.view, "notice_shown")
	assert_signal_not_emitted(screen.view, "action_failed")
	assert_true(state.scout.is_walking())
	assert_eq(screen.view.build_kind, GameConfig.CORE)
	_frames(screen, 1)
	assert_eq(screen.hud._toast_label.text, Texts.t("TOAST_SCOUT_WALKS"))
	_frames(screen, 30)
	assert_lt(state.scout.position.distance_to(far), distance - 100.0)


func test_lamp_panel_slider_sets_the_light_radius() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var lamp := BattleFixtures.add(screen.battle, GameConfig.LAMP, state.core().position + Vector2(0, -168))
	screen.view.select(lamp.id)
	_frames(screen, 1)
	var panel := screen.panel
	assert_true(panel._light_box.visible)
	assert_false(panel._fuel.visible)
	assert_eq(panel.light_slider.value, GameConfig.LAMP_RADIUS)
	var steps := screen.battle.history.size()
	panel.light_slider.drag_started.emit()
	panel.light_slider.value = 5.0
	panel.light_slider.value = 6.0
	panel.light_slider.drag_ended.emit(true)
	assert_eq(lamp.light_radius, 6.0)
	assert_eq(screen.battle.history.size(), steps + 1)
	assert_eq(panel._light_value.text, Texts.format("PANEL_LIGHT_VALUE", [6.0, Formulas.lamp_draw(lamp)]))
	lamp.light_radius = 2.0
	panel.refresh()
	assert_eq(panel.light_slider.value, 2.0)
	assert_true(screen.battle.undo())
	assert_eq(lamp.light_radius, GameConfig.LAMP_RADIUS)
	screen.view.select(state.core_id)
	_frames(screen, 1)
	assert_false(panel._light_box.visible)


func test_fire_pit_marks_trees_through_the_panel() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var fire := BattleFixtures.add(screen.battle, GameConfig.FIRE, state.core().position + Vector2(-168, 0))
	var tree := state.map.cell_of(fire.position) + Vector2i(0, -2)
	state.map.set_tile(tree, LevelMap.Tile.TREE)
	state.nav.terrain_changed(tree)
	screen.view.select(fire.id)
	_frames(screen, 1)
	var panel := screen.panel
	assert_true(panel._fuel.visible)
	assert_false(panel._light_box.visible)
	assert_true(panel._fuel.text.contains(Texts.format("PANEL_FUEL", [0])))
	panel._fuel.pressed.emit()
	assert_eq(screen.view.pick, BattleView.Pick.FUEL)
	assert_eq(panel.active_pick, "fuel")
	assert_true(panel.minimized)
	assert_true(screen.battle.fuel.candidates(fire).has(tree))
	_frames(screen, 2)
	await wait_process_frames(1)
	screen.view.begin(state.map.center_of(tree))
	screen.view.tap(state.map.center_of(tree))
	assert_eq(fire.fuel, [tree] as Array[Vector2i])
	assert_eq(screen.view.pick, BattleView.Pick.FUEL)
	_frames(screen, 4)
	assert_true(panel._fuel.text.contains(Texts.format("PANEL_FUEL", [1])))
	var far := state.map.cell_of(fire.position) + Vector2i(0, -6)
	state.map.set_tile(far, LevelMap.Tile.TREE)
	state.nav.terrain_changed(far)
	watch_signals(screen.view)
	screen.view.begin(state.map.center_of(far))
	screen.view.tap(state.map.center_of(far))
	assert_signal_emitted_with_parameters(screen.view, "action_failed", [Texts.reason("fuel_" + FuelControl.RANGE), state.map.center_of(far)])
	assert_eq(fire.fuel.size(), 1)
	screen.view.begin(state.map.center_of(tree))
	screen.view.tap(state.map.center_of(tree))
	assert_true(fire.fuel.is_empty())
	var ground := fire.position + Vector2(0, 300)
	screen.view.begin(ground)
	screen.view.tap(ground)
	assert_eq(screen.view.pick, BattleView.Pick.NONE)
	assert_eq(panel.active_pick, "")
	screen.start_fuel_pick(fire.id)
	assert_eq(screen.view.pick, BattleView.Pick.FUEL)
	screen.start_fuel_pick(fire.id)
	assert_eq(screen.view.pick, BattleView.Pick.NONE)


func test_night_view_paints_lights_and_burning_trees() -> void:
	var screen := _deployed()
	var battle := screen.battle
	var state := battle.state
	var core := state.core()
	var lamp := BattleFixtures.add(battle, GameConfig.LAMP, core.position + Vector2(0, -168))
	lamp.energy = Formulas.capacity(lamp)
	var fire := BattleFixtures.add(battle, GameConfig.FIRE, core.position + Vector2(-168, 0))
	var tree := state.map.cell_of(fire.position) + Vector2i(0, -2)
	state.map.set_tile(tree, LevelMap.Tile.TREE)
	state.nav.terrain_changed(tree)
	assert_eq(battle.toggle_fuel(fire.id, tree), FuelControl.OK)
	assert_eq(screen.view.paint_fill(lamp), 0.0)
	assert_eq(screen.view.paint_fill(fire), 1.0)
	battle.start_round()
	state.round_time = float(state.level.day) + 5.0
	battle.tick(GameConfig.TICK)
	assert_true(lamp.lit)
	assert_eq(fire.burn_cell, tree)
	screen.view.select(lamp.id)
	_frames(screen, 2)
	await wait_process_frames(1)
	assert_eq(screen.view._night_shade.material.get_shader_parameter("light_count"), 2)
	assert_eq(screen.view._night_shade.strength, 1.0)
	assert_eq(screen.view.paint_fill(lamp), 1.0)
	screen.start_fuel_pick(fire.id)
	_frames(screen, 1)
	await wait_process_frames(1)
	assert_eq(screen.view.pick, BattleView.Pick.FUEL)


func test_night_shade_passes_lights_to_the_shader() -> void:
	var shade := NightShade.new()
	assert_eq(shade.strength, 0.0)
	assert_eq(shade.apply(PackedVector3Array([Vector3(1, 2, 3)]), 0.5), 1)
	assert_eq(shade.material.get_shader_parameter("light_count"), 1)
	assert_almost_eq(float(shade.material.get_shader_parameter("strength")), 0.5, 0.001)
	assert_eq(shade.lights[0], Vector3(1, 2, 3))
	assert_eq(shade.lights.size(), NightShade.MAX_LIGHTS)
	var many := PackedVector3Array()
	many.resize(NightShade.MAX_LIGHTS + 5)
	assert_eq(shade.apply(many, 3.0), NightShade.MAX_LIGHTS)
	assert_eq(shade.strength, 1.0)
	assert_eq(shade.apply(PackedVector3Array(), -1.0), 0)
	assert_eq(shade.lights[0], Vector3.ZERO)
	assert_false(shade.refresh_glow())
	assert_eq(shade.material.get_shader_parameter("tint"), Color(AppTheme.FOG, 1.0))


func test_night_shade_uploads_the_building_glow() -> void:
	var battle := BattleFixtures.battle(0, false)
	var core := battle.state.core()
	var shade := NightShade.new()
	shade.bind(battle.lighting)
	var map := battle.state.map
	assert_eq(shade.glow_image.get_width(), map.width)
	assert_eq(shade.glow_image.get_height(), map.height)
	assert_eq(shade.material.get_shader_parameter("world_size"), map.size)
	assert_eq(shade.material.get_shader_parameter("glow_mask"), shade.glow_texture)
	assert_false(shade.refresh_glow())
	core.energy = 10.0
	assert_true(battle.lighting.refresh_glow())
	assert_true(shade.refresh_glow())
	assert_eq(shade.glow_image.get_pixelv(core.origin).r8, Lighting.GLOW_ON)
	assert_false(shade.refresh_glow())


func test_view_paints_the_slime_and_the_nests() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	assert_gt(state.creep.nests.size(), 0)
	await wait_process_frames(2)
	assert_eq(screen.view._slime_version, state.creep.version)
	assert_eq(screen.view._slime_texture.covered, state.map.slime.count(1))
	assert_eq(screen.view._rim_texture.covered, 0)
	state.creep.kill(state.creep.nests[0])
	screen.battle.creeping.update(GameConfig.CREEP_RECEDE_TIME + 1.0)
	await wait_process_frames(2)
	assert_eq(screen.view._slime_version, state.creep.version)
	assert_eq(screen.view._slime_texture.covered, state.map.slime.count(1))


func test_view_shows_the_sealed_rim_while_scouting() -> void:
	var screen := _screen()
	await wait_process_frames(2)
	var state := screen.battle.state
	assert_true(state.creep.is_sealed())
	assert_gt(screen.view._rim_texture.covered, 0)
	assert_eq(screen.view._rim_texture.covered, state.map.sealed.count(1))


func test_darkness_hides_enemies_outside_the_light() -> void:
	var screen := _deployed()
	var battle := screen.battle
	var state := battle.state
	var core := state.core()
	state.fog.cells.fill(FogOfWar.VISIBLE)
	var near := BattleFixtures.enemy(battle, "crawler", core.position + Vector2(0, -120))
	var far := BattleFixtures.enemy(battle, "crawler", core.position + Vector2(0, -600))
	assert_true(screen.view.shows_enemy(far))
	battle.start_round()
	state.round_time = float(state.level.day) + 2.0
	assert_true(state.is_night())
	assert_true(screen.view.shows_enemy(near))
	assert_false(screen.view.shows_enemy(far))
	assert_false(screen.view.reveals(far))
	screen.view.focus(far.position)
	_frames(screen, 1)
	await wait_process_frames(1)
	assert_eq(screen.view._night_shade.strength, 1.0)


func test_defeat_after_a_start_offers_a_retry_from_that_start() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var core := state.core()
	screen.battle.place(GameConfig.RELAY, core.position + Vector2(0, -150))
	var tree := state.map.cell_of(core.position) + Vector2i(4, 0)
	state.map.set_tile(tree, LevelMap.Tile.TREE)
	state.nav.terrain_changed(tree)
	_frames(screen, 10)
	screen.start_round()
	var checkpoint := screen.battle.checkpoint
	assert_not_null(checkpoint)
	assert_almost_eq(checkpoint.elapsed, screen.elapsed, 0.001)
	state.clear_obstacle(tree)
	screen.battle.combat.destroy(core)
	_frames(screen, int(BattleScreen.DEFEAT_DELAY * 30) + 5)
	var result := screen.overlay as ResultOverlay
	assert_true(screen.can_resume())
	assert_true(result.can_resume)
	watch_signals(screen)
	result.checkpoint_pressed.emit()
	assert_signal_emitted_with_parameters(screen, "checkpoint_requested", [checkpoint])
	var resumed := BattleScreen.new().setup(0, progress, settings, sfx, 0.0, null, checkpoint)
	add_child_autofree(resumed)
	var again := resumed.battle.state
	assert_true(again.is_planning())
	assert_eq(again.count_kind(GameConfig.RELAY), 1)
	assert_eq(again.map.tile(tree), LevelMap.Tile.TREE)
	assert_not_null(again.core())
	assert_false(resumed.tutorial.is_active())
	assert_eq(resumed.view.mode, BattleView.Mode.CONNECT)
	assert_true(resumed.build_bar.collapsible)
	assert_almost_eq(resumed.elapsed, checkpoint.elapsed, 0.001)
	_frames(resumed, 2)
	assert_true(resumed.mode_button.visible)
	assert_false(resumed.scout_button.visible)


func test_result_overlay_offers_the_checkpoint_only_after_defeat() -> void:
	var report := BattleReport.new()
	var lost := ResultOverlay.new().setup(report, [] as Array[Array], true)
	assert_true(lost.can_resume)
	add_child_autofree(lost)
	report = BattleReport.new()
	report.won = true
	var won := ResultOverlay.new().setup(report, [] as Array[Array], true)
	assert_false(won.can_resume)
	add_child_autofree(won)


func test_every_buildable_kind_has_an_icon() -> void:
	var row := HBoxContainer.new()
	add_child_autofree(row)
	for kind in GameConfig.BUILD_ORDER:
		var icon := BuildingIcon.new().setup(kind, 48.0)
		icon.fill = 1.0
		row.add_child(icon)
		assert_ne(Texts.t("BUILDING_%s_SHORT" % kind.to_upper()), "BUILDING_%s_SHORT" % kind.to_upper())
	await wait_process_frames(2)
	assert_eq(row.get_child_count(), GameConfig.BUILD_ORDER.size())


func test_creative_glyphs_exist_in_the_icon_font() -> void:
	for glyph in [Icons.PALETTE, Icons.ADD, Icons.REMOVE, Icons.SWEEP, Icons.INFINITY, Icons.PAID]:
		assert_true(AppTheme.FONT_ICONS.has_char(glyph.unicode_at(0)), glyph)


func test_day_stepper_steps_clamps_and_repeats_while_held() -> void:
	var stepper := DayStepper.new().setup(GameConfig.CREATIVE_MAX_DAY + 3)
	assert_eq(stepper.value, GameConfig.CREATIVE_MAX_DAY)
	stepper.set_value(1)
	add_child_autofree(stepper)
	assert_true(stepper.minus_button.disabled)
	assert_false(stepper.plus_button.disabled)
	assert_eq(stepper.value_label.text, Texts.format("HUD_DAY", [1]))
	watch_signals(stepper)
	assert_false(stepper.step(-1))
	stepper.plus_button.button_down.emit()
	assert_eq(stepper.value, 2)
	assert_signal_emitted_with_parameters(stepper, "day_changed", [2])
	assert_false(stepper.minus_button.disabled)
	stepper._process(DayStepper.HOLD_DELAY - 0.01)
	assert_eq(stepper.value, 2)
	stepper._process(0.01 + DayStepper.HOLD_REPEAT * 2.5)
	assert_eq(stepper.value, 5)
	stepper.plus_button.button_up.emit()
	stepper._process(1.0)
	assert_eq(stepper.value, 5)
	assert_eq(stepper.value_label.text, Texts.format("HUD_DAY", [5]))
	stepper.set_value(GameConfig.CREATIVE_MAX_DAY - 1)
	stepper.begin_hold(1)
	assert_eq(stepper.value, GameConfig.CREATIVE_MAX_DAY)
	assert_true(stepper.plus_button.disabled)
	stepper._process(5.0)
	assert_eq(stepper._held, 0)
	assert_false(stepper.step(1))
	stepper.minus_button.button_down.emit()
	assert_eq(stepper.value, GameConfig.CREATIVE_MAX_DAY - 1)
	stepper.set_enabled(false)
	assert_eq(stepper._held, 0)
	assert_true(stepper.minus_button.disabled)
	assert_true(stepper.plus_button.disabled)
	stepper.set_enabled(false)
	assert_false(stepper.step(-1))
	stepper.begin_hold(-1)
	stepper._process(5.0)
	assert_eq(stepper._held, 0)
	assert_eq(stepper.value, GameConfig.CREATIVE_MAX_DAY - 1)
	stepper.set_enabled(true)
	assert_false(stepper.minus_button.disabled)


func test_region_panel_starts_creative_with_a_day() -> void:
	var menu := _world()
	watch_signals(menu)
	var panel := menu.panel
	assert_not_null(panel.creative_button)
	assert_not_null(panel.day_stepper)
	assert_null(panel.survival_button)
	assert_false(panel.creative_button.disabled)
	panel.day_stepper.step(1)
	panel.day_stepper.step(1)
	assert_eq(panel.creative_day, 3)
	panel.creative_button.pressed.emit()
	assert_signal_emitted_with_parameters(menu, "creative_chosen", [0, 3])
	panel.show_region(0)
	assert_eq(panel.day_stepper.value, 3)
	panel.show_region(0, false)
	assert_true(panel.creative_button.disabled)
	panel.show_region(5)
	assert_null(panel.creative_button)
	assert_null(panel.day_stepper)
	progress.mark_conquered(0)
	panel.show_region(0)
	assert_not_null(panel.survival_button)
	assert_not_null(panel.creative_button)


func test_creative_battle_screen() -> void:
	var screen := BattleScreen.new().setup(0, progress, settings, sfx, 0.0, BattleSetup.creative(4, progress.arsenal()))
	add_child_autofree(screen)
	assert_false(screen.tutorial.is_active())
	var state := screen.battle.state
	var hud := screen.hud
	var bar := hud.creative_bar
	assert_not_null(bar)
	assert_true(state.fog.lifted)
	_frames(screen, 1)
	assert_true(bar.visible)
	assert_eq(bar.stepper.value, 4)
	assert_false(bar.stepper.minus_button.disabled)
	assert_true(bar.clear_button.disabled)
	assert_true(hud._infinite.visible)
	assert_false(hud._money.visible)
	assert_true(bar.unlimited)
	assert_eq(bar.money_button.theme_type_variation, &"PrimaryButton")
	assert_eq(bar.money_button.text, "%s  %s" % [Icons.INFINITY, Texts.t("CREATIVE_MONEY_ON")])
	bar.stepper.step(1)
	assert_eq(state.round_number, 5)
	BattleFixtures.open_terrain(state)
	screen.battle.deploy_core(state.map.drop)
	_frames(screen, 1)
	assert_eq(screen.bar_kinds(), GameConfig.BUILD_ORDER)
	assert_true(state.core().immune)
	bar.stepper.step(-1)
	assert_eq(state.round_number, 4)
	await wait_process_frames(2)
	assert_eq(hud.money_anchor(), hud._infinite.get_global_rect().get_center())
	assert_gte(bar.position.y, hud.top_height())
	screen.start_round()
	_frames(screen, 1)
	assert_true(bar.stepper.plus_button.disabled)
	assert_false(bar.clear_button.disabled)
	bar.stepper.step(1)
	assert_eq(state.round_number, 4)
	var nest: Building = state.enemy_buildings()[0]
	BattleFixtures.enemy(screen.battle, "crawler", nest.position + Vector2(GameConfig.CELL * 3, 0))
	_frames(screen, 1)
	assert_false(bar.clear_button.disabled)
	bar.clear_button.pressed.emit()
	assert_true(state.enemies.is_empty())
	assert_true(state.is_planning())
	assert_eq(state.round_number, 5)
	var events := screen.battle.events.drain()
	assert_eq(BattleFixtures.of_type(events, "enemies_cleared").size(), 1)
	assert_eq(BattleFixtures.of_type(events, "round_cleared").size(), 1)
	screen.rewards.handle(events)
	assert_eq(hud._toast_label.text, Texts.format("TOAST_ENEMIES_CLEARED", [1]))
	_frames(screen, 1)
	assert_true(bar.clear_button.disabled)
	assert_false(bar.stepper.plus_button.disabled)
	assert_eq(bar.stepper.value, 5)
	assert_true(hud._start.visible)
	bar.money_button.pressed.emit()
	assert_false(state.unlimited_money)
	_frames(screen, 1)
	assert_false(bar.unlimited)
	assert_eq(bar.money_button.theme_type_variation, &"Button")
	assert_eq(bar.money_button.text, "%s  %s" % [Icons.PAID, Texts.t("CREATIVE_MONEY_OFF")])
	assert_true(hud._money.visible)
	assert_false(hud._infinite.visible)
	state.money = 0
	assert_false(state.can_afford(1))
	bar.money_button.pressed.emit()
	assert_true(state.unlimited_money)
	_frames(screen, 1)
	assert_true(bar.unlimited)
	assert_eq(bar.money_button.theme_type_variation, &"PrimaryButton")
	assert_true(hud._infinite.visible)
	assert_false(hud._money.visible)
	screen.view.focus(state.core().position)
	await wait_process_frames(1)
	state.phase = BattleState.Phase.LOST
	_frames(screen, 1)
	assert_false(bar.visible)


func test_main_starts_and_retries_creative() -> void:
	var main: Node = load("res://src/ui/main.gd").new()
	add_child_autofree(main)
	main.progress = progress
	main.start_creative(5, 3)
	assert_false(main.screen is BattleScreen)
	main.start_creative(0, 7)
	assert_true(main.screen is BattleScreen)
	assert_true(main.last_rules.is_creative())
	assert_eq(main.last_rules.start_day, 7)
	assert_eq((main.screen as BattleScreen).battle.state.round_number, 7)
	main.retry()
	assert_true(main.last_rules.is_creative())
	assert_eq(main.last_rules.start_day, 7)
	assert_eq(main.last_rules.arsenal.kinds(), GameConfig.BUILD_ORDER)
	main.show_menu()
	main.menu.creative_chosen.emit(0, 2)
	assert_true(main.screen is BattleScreen)
	assert_eq(main.last_rules.start_day, 2)
	assert_eq((main.screen as BattleScreen).battle.state.round_number, 2)


func test_every_player_building_has_a_description_in_both_languages() -> void:
	for locale in ["en", "de"]:
		TranslationServer.set_locale(locale)
		for kind: String in GameConfig.BUILDINGS:
			if GameConfig.BUILDINGS[kind].team == GameConfig.TEAM_PLAYER:
				assert_ne(Texts.building_desc(kind), "", "%s %s" % [locale, kind])
	TranslationServer.set_locale("en")
	assert_ne(Texts.building_desc(GameConfig.ZAPPER), Texts.building_info(GameConfig.ZAPPER))
	assert_eq(Texts.building_desc(GameConfig.NEST), "")


func test_building_panel_shows_description_in_collapsible_info() -> void:
	var screen := _deployed()
	var core := screen.battle.state.core()
	var zapper := BattleFixtures.add(screen.battle, GameConfig.ZAPPER, core.position + Vector2(0, -168))
	screen.view.select(zapper.id)
	_frames(screen, 1)
	var panel := screen.panel
	assert_true(panel._desc_toggle.visible)
	assert_false(panel._desc.visible)
	panel._desc_toggle.pressed.emit()
	assert_true(panel._desc.visible)
	assert_eq(panel._desc.text, Texts.building_desc(GameConfig.ZAPPER))
	panel.toggle_description()
	assert_false(panel._desc.visible)
	var nest: Building = screen.battle.state.enemy_buildings()[0]
	screen.view.select(nest.id)
	_frames(screen, 1)
	assert_false(panel._desc_toggle.visible)
	assert_false(panel._desc.visible)


func test_upgrade_list_shows_the_group_headings_in_layout_order() -> void:
	var screen := _deployed()
	var core := screen.battle.state.core()
	screen.view.select(core.id)
	_frames(screen, 2)
	var layout := Formulas.track_layout(core.kind)
	var headings := 0
	for group: Dictionary in layout:
		if not str(group.title).is_empty():
			headings += 1
	assert_gt(headings, 0)
	assert_eq(screen.panel._tracks.get_child_count(), headings + core.definition().tracks.size())
	var first: Label = screen.panel._tracks.get_child(0)
	assert_eq(first.text, Texts.t(str(layout[0].title)))
	UpgradeOverrides.set_layouts({core.kind: [{"title": "Eigene Gruppe", "tracks": [GameConfig.TRACK_HULL]}]})
	screen.view.select(-1)
	screen.view.select(core.id)
	_frames(screen, 2)
	var custom: Label = screen.panel._tracks.get_child(0)
	assert_eq(custom.text, "Eigene Gruppe")
	UpgradeOverrides.reset()
