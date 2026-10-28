class_name BattleScreen
extends Node

signal menu_requested
signal retry_requested

const VICTORY_DELAY := 1.8
const DEFEAT_DELAY := 2.0
const PANEL_REFRESH := 0.1
const MODE_MARGIN := 16.0
const JOYSTICK_SIZE := 190.0
const PULSE_EVENTS: Array[String] = ["placed", "upgraded", "sold", "relocated", "link", "unlink", "plan_restored", "round_cleared"]

var level_index := 0
var rules: BattleSetup
var report: BattleReport
var progress: Progress
var settings: AppSettings
var sfx: SfxPlayer
var safe_top := 0.0
var battle: Battle
var tutorial: Tutorial
var view: BattleView
var hud: BattleHud
var build_bar: BuildBar
var panel: BuildingPanel
var celebrations: CelebrationLayer
var mode_button: Button
var scout_button: Button
var scout_chip: PanelContainer
var joystick: VirtualJoystick
var rewards: RewardDirector
var root: Control
var speed_index := 0
var paused := false
var elapsed := 0.0
var overlay: Control
var _result_timer := -1.0
var _recorded := false
var _panel_timer := 0.0
var _steered_id := -1


func setup(p_level: int, p_progress: Progress, p_settings: AppSettings, p_sfx: SfxPlayer, p_safe_top: float = 0.0, p_rules: BattleSetup = null) -> BattleScreen:
	level_index = p_level
	progress = p_progress
	rules = p_rules if p_rules != null else BattleSetup.campaign(progress.arsenal())
	settings = p_settings
	sfx = p_sfx
	safe_top = p_safe_top
	return self


func _ready() -> void:
	battle = Battle.start(level_index, 0, rules)
	tutorial = Tutorial.new(level_index == 0 and not rules.is_survival() and not progress.is_conquered(0))
	view = BattleView.new().setup(battle)
	add_child(view)
	var layer := CanvasLayer.new()
	add_child(layer)
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = AppTheme.build()
	layer.add_child(root)
	hud = BattleHud.new().setup(safe_top)
	root.add_child(hud)
	build_bar = BuildBar.new().setup(bar_kinds())
	root.add_child(build_bar)
	build_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	build_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel = BuildingPanel.new().setup(battle)
	panel.visible = false
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	mode_button = UiKit.button("", "Button", toggle_mode)
	mode_button.custom_minimum_size = Vector2(0, 64)
	root.add_child(mode_button)
	scout_button = UiKit.icon_button(Icons.SCOUT, focus_scout, 64.0)
	root.add_child(scout_button)
	scout_chip = PanelContainer.new()
	scout_chip.theme_type_variation = "Chip"
	scout_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var chip_label := UiKit.label(Texts.t("SCOUT_HINT"), "Caption")
	chip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chip_label.custom_minimum_size = Vector2(420, 0)
	scout_chip.add_child(chip_label)
	scout_chip.visible = false
	root.add_child(scout_chip)
	joystick = VirtualJoystick.new()
	joystick.joystick_mode = VirtualJoystick.JOYSTICK_FIXED
	joystick.joystick_size = JOYSTICK_SIZE
	joystick.tip_size = JOYSTICK_SIZE * 0.42
	joystick.deadzone_ratio = 0.12
	joystick.action_left = &"steer_left"
	joystick.action_right = &"steer_right"
	joystick.action_up = &"steer_up"
	joystick.action_down = &"steer_down"
	joystick.custom_minimum_size = Vector2(JOYSTICK_SIZE, JOYSTICK_SIZE) * 1.15
	joystick.visible = false
	root.add_child(joystick)
	celebrations = CelebrationLayer.new()
	root.add_child(celebrations)
	rewards = RewardDirector.new(view, hud, celebrations, sfx)
	celebrations.coin_arrived.connect(rewards.coin_arrived)
	hud.pause_pressed.connect(toggle_pause)
	hud.speed_pressed.connect(cycle_speed)
	hud.start_pressed.connect(start_round)
	hud.undo_pressed.connect(undo_plan)
	hud.reset_pressed.connect(confirm_reset)
	build_bar.kind_pressed.connect(choose_kind)
	panel.closed.connect(func() -> void: view.select(-1))
	panel.upgrade_pressed.connect(upgrade)
	panel.sell_pressed.connect(sell)
	panel.target_toggled.connect(func(id: int, unit_class: String) -> void:
		battle.toggle_target_class(id, unit_class)
		panel.refresh())
	panel.target_raised.connect(func(id: int, unit_class: String) -> void:
		battle.raise_target_class(id, unit_class)
		panel.refresh())
	panel.link_pressed.connect(start_link_pick)
	panel.focus_pressed.connect(toggle_focus)
	panel.relocate_pressed.connect(start_relocate)
	view.building_selected.connect(_on_selected)
	view.action_failed.connect(_on_failed)
	view.camera_moved.connect(func() -> void: tutorial.handle({"type": "camera"}))
	view.mode_changed.connect(_on_mode_changed)
	view.scout_selected.connect(func(active: bool) -> void: scout_chip.visible = active)
	view.pick_changed.connect(_on_pick_changed)
	_show_mode(view.mode)


func bar_kinds() -> Array[String]:
	if battle.state.is_scouting():
		return [GameConfig.CORE] as Array[String]
	return battle.state.available_kinds()


func _process(delta: float) -> void:
	_steer()
	if not paused and not is_overlay_open():
		var scaled := delta * GameConfig.SPEEDS[speed_index] * rewards.time_scale()
		battle.advance(scaled)
		if not battle.state.is_over():
			elapsed += scaled
	var events := battle.events.drain()
	for event in events:
		tutorial.handle(event)
		_on_event(event)
	rewards.handle(events)
	rewards.update(delta)
	view.advance(0.0 if paused else delta * rewards.time_scale())
	_check_result(delta)
	_refresh_ui(delta)


func steering_input() -> Vector2:
	if not joystick.visible:
		return Vector2.ZERO
	return Input.get_vector(&"steer_left", &"steer_right", &"steer_up", &"steer_down")


func _steer() -> void:
	var direction := steering_input()
	var mobile := view.selected_mobile()
	var mobile_id := mobile.id if mobile != null else -1
	if _steered_id >= 0 and _steered_id != mobile_id:
		battle.steer(_steered_id, Vector2.ZERO)
	_steered_id = mobile_id
	if view.scout_active:
		battle.steer_scout(direction)
		if direction != Vector2.ZERO:
			view.focus(battle.state.scout.position)
	elif mobile != null:
		battle.steer(mobile.id, direction)
		if direction != Vector2.ZERO:
			view.focus(mobile.position)


func _refresh_ui(delta: float) -> void:
	var state := battle.state
	hud.refresh(state, GameConfig.SPEEDS[speed_index], tutorial_text(), state.money - celebrations.in_flight(), battle.history)
	build_bar.visible = view.selected_id < 0 and not state.is_over()
	build_bar.refresh(state, view.build_kind)
	view.top_inset = hud.top_height()
	view.bottom_inset = panel.size.y if panel.visible else (build_bar.size.y if build_bar.visible else 0.0)
	mode_button.visible = not state.is_over() and not state.is_scouting()
	mode_button.reset_size()
	var bottom := root.size.y - view.bottom_inset - MODE_MARGIN
	mode_button.position = Vector2(root.size.x - mode_button.size.x - MODE_MARGIN, bottom - mode_button.size.y)
	scout_button.visible = not state.is_over() and state.scout != null and state.scout.is_controllable()
	scout_button.position = Vector2(root.size.x - scout_button.size.x - MODE_MARGIN, bottom - scout_button.size.y)
	joystick.visible = not state.is_over() and (view.scout_active or (view.selected_mobile() != null and state.is_fighting()))
	joystick.reset_size()
	joystick.position = Vector2(MODE_MARGIN, bottom - joystick.size.y)
	scout_chip.reset_size()
	scout_chip.position = Vector2((root.size.x - scout_chip.size.x) * 0.5, bottom - joystick.size.y - scout_chip.size.y - AppTheme.SPACING_SM)
	_panel_timer -= delta
	if panel.visible and _panel_timer <= 0.0:
		_panel_timer = PANEL_REFRESH
		panel.refresh()


func _on_event(event: Dictionary) -> void:
	if PULSE_EVENTS.has(str(event.type)):
		hud.stats_panel.pulse_changes()
	match str(event.type):
		"landed":
			if battle.state.is_scouting():
				view.set_scout_active(true)
		"core_deployed":
			view.set_build_kind("")
			view.set_scout_active(false)
			build_bar.set_kinds(bar_kinds())
		"cleared":
			view.terrain_changed(event.cell)


func focus_scout() -> void:
	var scout := battle.state.scout
	if scout == null:
		return
	view.set_build_kind("")
	view.select(-1)
	view.focus(scout.position)
	view.set_scout_active(true)


func tutorial_text() -> String:
	return Texts.tutorial(tutorial.step) if tutorial.is_active() and not battle.state.is_over() else ""


func is_overlay_open() -> bool:
	return is_instance_valid(overlay) and not overlay.is_queued_for_deletion()


func _check_result(delta: float) -> void:
	var state := battle.state
	if not state.is_over():
		return
	if not _recorded:
		_recorded = true
		view.set_build_kind("")
		view.select(-1)
		report = progress.record(BattleReport.from_state(state))
		progress.save()
		_result_timer = VICTORY_DELAY if state.phase == BattleState.Phase.WON else DEFEAT_DELAY
	if _result_timer > 0.0:
		_result_timer -= delta
		if _result_timer <= 0.0:
			show_result()


func show_result() -> void:
	var state := battle.state
	var stats: Array[Array] = [
		["RESULT_DAYS", str(state.days_survived)],
		["RESULT_KILLS", NumberFormat.grouped(state.kills)],
		["RESULT_COMBO", "×%d" % state.best_combo],
		["RESULT_EARNED", NumberFormat.grouped(state.earned)],
		["RESULT_LOST", str(state.lost)],
		["RESULT_TIME", NumberFormat.clock(elapsed)],
	]
	var result := ResultOverlay.new().setup(report, stats)
	result.retry_pressed.connect(func() -> void: retry_requested.emit())
	result.menu_pressed.connect(func() -> void: menu_requested.emit())
	result.star_shown.connect(func(index: int) -> void:
		if sfx != null:
			sfx.play(SoundBank.STAR, 1.0 + 0.15 * index)
			sfx.vibrate(40)
		celebrations.burst_confetti(Vector2(root.size.x * 0.5, root.size.y * 0.4), 40))
	_open_overlay(result)


func _open_overlay(control: Control) -> void:
	if is_overlay_open():
		overlay.queue_free()
	overlay = control
	root.add_child(control)


func toggle_pause() -> void:
	if battle.state.is_over():
		return
	if is_overlay_open():
		overlay.queue_free()
		paused = false
		return
	paused = true
	var menu := PauseOverlay.new().setup(settings)
	menu.resume_pressed.connect(toggle_pause)
	menu.restart_pressed.connect(func() -> void: retry_requested.emit())
	menu.menu_pressed.connect(func() -> void: menu_requested.emit())
	_open_overlay(menu)


func cycle_speed() -> void:
	speed_index = (speed_index + 1) % GameConfig.SPEEDS.size()


func toggle_mode() -> void:
	view.toggle_mode()


func _on_mode_changed(mode: BattleView.Mode) -> void:
	_show_mode(mode)
	var connecting := mode == BattleView.Mode.CONNECT
	hud.toast(Texts.t("TOAST_MODE_CONNECT" if connecting else "TOAST_MODE_MOVE"), AppTheme.ENERGY if connecting else AppTheme.ON_SURFACE)
	if sfx != null:
		sfx.play(SoundBank.CLICK)


func _show_mode(mode: BattleView.Mode) -> void:
	var connecting := mode == BattleView.Mode.CONNECT
	mode_button.text = "%s  %s" % [Icons.LINK if connecting else Icons.PAN, Texts.t("MODE_CONNECT" if connecting else "MODE_MOVE")]
	mode_button.theme_type_variation = "PrimaryButton" if connecting else "Button"


func start_round() -> void:
	if not battle.start_round():
		return
	view.set_build_kind("")
	view.cancel_pick()


func undo_plan() -> void:
	if battle.undo():
		_after_restore("TOAST_UNDO")


func confirm_reset() -> void:
	if not battle.can_undo():
		return
	var dialog := ConfirmOverlay.new().setup(Texts.t("RESET_TITLE"), Texts.t("RESET_TEXT"), Texts.t("RESET_CONFIRM"))
	dialog.cancelled.connect(dialog.queue_free)
	dialog.confirmed.connect(_reset_confirmed.bind(dialog))
	_open_overlay(dialog)


func _reset_confirmed(dialog: ConfirmOverlay) -> void:
	dialog.queue_free()
	if battle.reset_plan():
		_after_restore("TOAST_RESET")


func _after_restore(toast_key: String) -> void:
	view.cancel_pick()
	view.set_build_kind("")
	if battle.state.building(view.selected_id) == null:
		view.select(-1)
	elif panel.visible:
		panel.show_building(view.selected_id)
	hud.toast(Texts.t(toast_key), AppTheme.ENERGY)
	if sfx != null:
		sfx.play(SoundBank.CLICK)


func choose_kind(kind: String) -> void:
	if view.build_kind == kind:
		view.set_build_kind("")
		return
	if battle.state.money < Formulas.build_cost(battle.state, kind):
		_on_failed(Texts.reason("build_money"), Vector2.INF)
		return
	view.set_build_kind(kind)
	hud.toast(Texts.format("TOAST_PLACE", [Texts.building_name(kind)]), AppTheme.ENERGY)


func start_link_pick(id: int) -> void:
	if view.pick == BattleView.Pick.LINK:
		view.cancel_pick()
		return
	var building := battle.state.building(id)
	if building != null and battle.state.outgoing(id).size() >= Formulas.max_links(building):
		_on_failed(Texts.reason("link_" + EnergyNetwork.FULL), Vector2.INF)
		return
	view.start_pick(BattleView.Pick.LINK, id)
	hud.toast(Texts.t("TOAST_PICK_LINK"), AppTheme.ENERGY)


func toggle_focus(id: int) -> void:
	var building := battle.state.building(id)
	if building == null:
		return
	if view.pick == BattleView.Pick.FOCUS:
		view.cancel_pick()
	elif battle.combat.focused(building) != null:
		battle.focus(id, null)
	else:
		view.start_pick(BattleView.Pick.FOCUS, id)
		hud.toast(Texts.t("TOAST_PICK_FOCUS"), AppTheme.DANGER)
	panel.refresh()


func start_relocate(id: int) -> void:
	var building := battle.state.building(id)
	if building == null:
		return
	if battle.state.money < Formulas.relocate_cost(building, battle.state.is_planning()):
		_on_failed(Texts.reason("build_money"), Vector2.INF)
		return
	view.start_relocate(id)
	hud.toast(Texts.format("TOAST_RELOCATE", [Texts.building_name(building.kind)]), AppTheme.ENERGY)


func _on_pick_changed(pick: BattleView.Pick) -> void:
	match pick:
		BattleView.Pick.LINK:
			panel.active_pick = "link"
		BattleView.Pick.FOCUS:
			panel.active_pick = "focus"
		_:
			panel.active_pick = ""
	if panel.visible:
		panel.refresh()


func upgrade(id: int, track: String) -> void:
	if not battle.upgrade(id, track):
		_on_failed(Texts.reason("upgrade_money"), Vector2.INF)
		return
	panel.pulse_changes()
	panel.refresh()


func sell(id: int) -> void:
	if battle.sell(id) > 0:
		view.select(-1)


func _on_selected(id: int) -> void:
	if id >= 0:
		view.build_kind = ""
		panel.show_building(id)
		if view.selected_mobile() != null:
			hud.toast(Texts.t("TOAST_ROVER"), AppTheme.ENERGY)
	else:
		panel.visible = false


func _on_failed(message: String, world: Vector2) -> void:
	hud.toast(message, AppTheme.DANGER)
	if world != Vector2.INF:
		view.fx.floater("×", world, AppTheme.DANGER, 1.4)
	if sfx != null:
		sfx.play(SoundBank.ERROR)
		sfx.vibrate(30)


func handle_back() -> void:
	if view.pick != BattleView.Pick.NONE:
		view.cancel_pick()
	elif view.build_kind != "":
		view.set_build_kind("")
	elif view.selected_id >= 0:
		view.select(-1)
	elif hud.stats_panel.visible:
		hud.hide_stats()
	elif view.mode == BattleView.Mode.CONNECT and not battle.state.is_over():
		view.set_mode(BattleView.Mode.MOVE)
	elif battle.state.is_over():
		menu_requested.emit()
	else:
		toggle_pause()
