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
	assert_false(screen.mode_button.visible)
	assert_false(screen.scout_button.visible)
	assert_gt(screen.hud.top_height(), 0.0)
	assert_gt(screen.view.chunk_count(), 1)


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
	assert_true(screen.joystick.visible)
	assert_eq(screen.joystick.action_up, &"steer_up")
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
	assert_false(screen.joystick.visible)
	assert_false(screen.scout_button.visible)
	assert_eq(screen.tutorial.step, Tutorial.BUILD_SOLAR)
	assert_true(screen.mode_button.visible)
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
	assert_true(state.scout.is_clearing())
	_frames(screen, 80)
	assert_true(state.map.is_walkable(tree))
	var far := origin + Vector2i(6, 0)
	state.map.set_tile(far, LevelMap.Tile.ROCK)
	state.nav.terrain_changed(far)
	watch_signals(screen.view)
	screen.view.begin(state.map.center_of(far))
	screen.view.tap(state.map.center_of(far))
	assert_signal_emitted(screen.view, "action_failed")
	assert_false(state.scout.is_clearing())
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


func test_mobile_tower_is_steered_with_the_joystick() -> void:
	var screen := _deployed(1)
	var state := screen.battle.state
	var core := state.core()
	var rover := BattleFixtures.add(screen.battle, GameConfig.ROVER, core.position + Vector2(0, -150))
	rover.energy = Formulas.capacity(rover)
	screen.battle.connect_buildings(core.id, rover.id)
	screen.start_round()
	_frames(screen, 1)
	assert_false(screen.joystick.visible)
	screen.view.select(rover.id)
	_frames(screen, 1)
	assert_true(screen.joystick.visible)
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
	assert_false(screen.joystick.visible)


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


func test_wall_painting_keeps_build_mode() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	var start := state.core().position + Vector2(-200, -150)
	screen.choose_kind(GameConfig.BULWARK)
	screen.view.begin(start)
	screen.view.drag_to(start + Vector2(40, 0), true)
	screen.view.drag_to(start + Vector2(400, 0), true)
	screen.view.finish(start + Vector2(400, 0))
	assert_eq(state.count_kind(GameConfig.BULWARK), 8)
	assert_eq(screen.view.build_kind, GameConfig.BULWARK)
	screen.view.begin(start + Vector2(0, -200))
	screen.view.tap(start + Vector2(0, -200))
	assert_eq(state.count_kind(GameConfig.BULWARK), 9)
	state.money = 0
	watch_signals(screen.view)
	screen.view.begin(start + Vector2(0, -300))
	screen.view.drag_to(start + Vector2(200, -300), true)
	assert_signal_emitted(screen.view, "action_failed")
	assert_eq(screen.view.build_kind, "")


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
	screen.toggle_mode()
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
	assert_eq(screen.panel.target_label(zapper, 0), "1  %s  ✕" % Texts.t("CLASS_AIR"))
	assert_true(screen.panel._target_buttons[0].text.contains("✕"))
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
	assert_true(screen.mode_button.text.contains(Texts.t("MODE_MOVE")))
	screen.mode_button.pressed.emit()
	assert_eq(screen.view.mode, BattleView.Mode.CONNECT)
	assert_true(screen.mode_button.text.contains(Texts.t("MODE_CONNECT")))
	assert_eq(screen.mode_button.theme_type_variation, "PrimaryButton")
	_frames(screen, 1)
	assert_lt(screen.mode_button.position.y + screen.mode_button.size.y, screen.root.size.y - screen.view.bottom_inset)
	screen.handle_back()
	assert_eq(screen.view.mode, BattleView.Mode.MOVE)


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
	var screen := _screen()
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


func test_rover_joystick_only_while_fighting() -> void:
	var screen := _deployed(1)
	var state := screen.battle.state
	var rover := BattleFixtures.add(screen.battle, GameConfig.ROVER, state.core().position + Vector2(0, -150))
	screen.view.select(rover.id)
	_frames(screen, 1)
	assert_false(screen.joystick.visible)
	screen.start_round()
	_frames(screen, 1)
	assert_true(screen.joystick.visible)


func test_upgrade_list_scrolls_for_many_tracks() -> void:
	var screen := _deployed()
	var core := screen.battle.state.core()
	screen.view.select(core.id)
	_frames(screen, 1)
	assert_true(screen.panel._track_scroll.visible)
	assert_eq(screen.panel._track_rows.size(), core.definition().tracks.size())
	assert_eq(screen.panel._track_scroll.custom_minimum_size.y, BuildingPanel.VISIBLE_TRACKS * BuildingPanel.TRACK_ROW_HEIGHT)
	var nest: Building = screen.battle.state.enemy_buildings()[0]
	screen.view.select(nest.id)
	_frames(screen, 1)
	assert_false(screen.panel._track_scroll.visible)


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
		{"type": "export", "position": position, "value": GameConfig.EXPORT_BATCH},
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
	assert_true(audit.chain(zapper.id).buildings.has(core.id))
	assert_eq(audit.verdict(lonely.id), EnergyAudit.Verdict.OFFLINE)
	assert_true(screen.panel._status.visible)
	assert_eq(screen.panel._status_title.text, StatusText.summary(audit, zapper))
	assert_eq(screen.panel._status_values.size(), StatText.status_rows(zapper, audit).size())
	screen.view.select(relay.id)
	_frames(screen, 1)
	assert_true(screen.panel._sell.text.contains(Texts.format("PANEL_SELL_FULL", [relay.spent])))
	screen.view.select(-1)
	await wait_process_frames(1)


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
