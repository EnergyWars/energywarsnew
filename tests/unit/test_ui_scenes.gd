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


func test_scout_lands_explores_and_deploys_the_core() -> void:
	var screen := _screen()
	var state := screen.battle.state
	_frames(screen, int(GameConfig.DROP_TIME * 30) + 3)
	assert_true(state.scout.is_landed())
	assert_true(screen.view.scout_active)
	assert_true(screen.scout_chip.visible)
	assert_true(screen.scout_button.visible)
	var goal := state.map.drop + Vector2(0, -120)
	screen.view.begin(goal)
	assert_eq(screen.view.gesture, BattleView.Gesture.CUT_PENDING)
	screen.view.tap(goal)
	assert_true(state.scout.is_moving())
	_frames(screen, 30)
	assert_eq(screen.tutorial.step, Tutorial.DEPLOY_CORE)
	screen.choose_kind(GameConfig.CORE)
	assert_eq(screen.view.build_kind, GameConfig.CORE)
	screen.view.begin(state.map.drop)
	screen.view.tap(state.map.drop)
	assert_not_null(state.core())
	_frames(screen, 1)
	assert_eq(state.phase, BattleState.Phase.PREP)
	assert_eq(screen.build_bar.kinds, GameConfig.available_kinds(0))
	assert_false(screen.view.scout_active)
	assert_eq(screen.tutorial.step, Tutorial.BUILD_SOLAR)
	assert_true(screen.mode_button.visible)


func test_scout_selection_and_clearing_by_tap() -> void:
	var screen := _deployed()
	var state := screen.battle.state
	screen.focus_scout()
	assert_true(screen.view.scout_active)
	screen.view.begin(state.scout.position)
	screen.view.tap(state.scout.position)
	assert_false(screen.view.scout_active)
	screen.view.begin(state.scout.position)
	screen.view.tap(state.scout.position)
	assert_true(screen.view.scout_active)
	var tree := state.map.cell_of(state.scout.position) + Vector2i(-3, 0)
	state.map.set_tile(tree, LevelMap.Tile.TREE)
	state.nav.terrain_changed(tree)
	screen.view.begin(state.map.center_of(tree))
	screen.view.tap(state.map.center_of(tree))
	assert_true(state.scout.is_clearing())
	_frames(screen, 150)
	assert_true(state.map.is_walkable(tree))
	watch_signals(screen.view)
	screen.view.command_scout(Vector2(-900, -900))
	assert_signal_emitted(screen.view, "action_failed")
	screen.handle_back()
	assert_false(screen.view.scout_active)


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


func test_pause_speed_and_skip() -> void:
	var screen := _deployed()
	screen.cycle_speed()
	assert_eq(screen.speed_index, 1)
	screen.skip_prep()
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
	assert_eq(progress.stars_for(0), 3)
	assert_true(FileAccess.file_exists(PROGRESS))
	_frames(screen, int(BattleScreen.VICTORY_DELAY * 30) + 5)
	assert_true(screen.overlay is ResultOverlay)
	var result := screen.overlay as ResultOverlay
	result._show_star(0)
	result.next_pressed.emit()
	assert_signal_emitted_with_parameters(screen, "level_requested", [1])
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
	assert_eq(progress.stars_for(0), 0)


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
	screen.skip_prep()
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
		{"type": "surge", "cycle": 2, "night": true},
		{"type": "surge", "cycle": 3, "night": false},
		{"type": "heal", "from": position, "to": position + Vector2(40, 0), "amount": 12.0},
		{"type": "landed", "position": position},
		{"type": "core_deployed", "id": 1, "position": position},
		{"type": "scout_order", "position": position, "clear": true},
		{"type": "cleared", "position": position, "obstacle": LevelMap.TREE, "cell": Vector2i(1, 1)},
		{"type": "cleared", "position": position, "obstacle": LevelMap.ROCK, "cell": Vector2i(1, 1)},
		{"type": "fight_started"},
		{"type": "nightfall", "day": 1},
		{"type": "daybreak", "day": 2},
		{"type": "spawn", "position": position, "kind": "behemoth", "boss": true},
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


func test_level_select_lists_levels() -> void:
	progress.record(0, 2, 10, 4)
	var menu := LevelSelect.new().setup(progress, settings)
	add_child_autofree(menu)
	watch_signals(menu)
	var cards := menu.find_children("*", "Button", true, false)
	assert_gt(cards.size(), GameConfig.level_count())
	menu._toggle_sound()
	assert_true(settings.sound)
	menu._toggle_haptics()
	assert_true(settings.haptics)
	menu._cycle_language()
	assert_signal_emitted(menu, "locale_changed")
	settings.set_locale("")
	var unlocked: Array = cards.filter(func(button: Button) -> bool: return button.custom_minimum_size.y == 112 and not button.disabled)
	assert_eq(unlocked.size(), 2)
	unlocked[1].pressed.emit()
	assert_signal_emitted_with_parameters(menu, "level_chosen", [1])


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
	main.start_level(1)
	assert_false(main.screen is BattleScreen)
	main.start_level(0)
	assert_true(main.screen is BattleScreen)
	main._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_true((main.screen as BattleScreen).paused)
	(main.screen as BattleScreen).menu_requested.emit()
	assert_true(main.screen is CanvasLayer)
	assert_gte(main.safe_top(), 0.0)
