class_name BattleScreen
extends Node

signal menu_requested
signal level_requested(index: int)

const VICTORY_DELAY := 1.8
const DEFEAT_DELAY := 2.0
const PANEL_REFRESH := 0.1
const MODE_MARGIN := 16.0

var level_index := 0
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
var rewards: RewardDirector
var root: Control
var speed_index := 0
var paused := false
var elapsed := 0.0
var overlay: Control
var _result_timer := -1.0
var _recorded := false
var _improved := false
var _panel_timer := 0.0


func setup(p_level: int, p_progress: Progress, p_settings: AppSettings, p_sfx: SfxPlayer, p_safe_top: float = 0.0) -> BattleScreen:
	level_index = p_level
	progress = p_progress
	settings = p_settings
	sfx = p_sfx
	safe_top = p_safe_top
	return self


func _ready() -> void:
	battle = Battle.start(level_index)
	tutorial = Tutorial.new(level_index == 0 and progress.stars_for(0) == 0)
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
	celebrations = CelebrationLayer.new()
	root.add_child(celebrations)
	rewards = RewardDirector.new(view, hud, celebrations, sfx)
	celebrations.coin_arrived.connect(rewards.coin_arrived)
	hud.pause_pressed.connect(toggle_pause)
	hud.speed_pressed.connect(cycle_speed)
	hud.skip_pressed.connect(skip_prep)
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
	view.building_selected.connect(_on_selected)
	view.action_failed.connect(_on_failed)
	view.camera_moved.connect(func() -> void: tutorial.handle({"type": "camera"}))
	view.mode_changed.connect(_on_mode_changed)
	view.scout_selected.connect(func(active: bool) -> void: scout_chip.visible = active)
	_show_mode(view.mode)


func bar_kinds() -> Array[String]:
	if battle.state.is_scouting():
		return [GameConfig.CORE] as Array[String]
	return GameConfig.available_kinds(level_index)


func _process(delta: float) -> void:
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


func _refresh_ui(delta: float) -> void:
	var state := battle.state
	hud.refresh(state, GameConfig.SPEEDS[speed_index], tutorial_text(), state.money - celebrations.in_flight())
	build_bar.visible = view.selected_id < 0 and not state.is_over()
	build_bar.refresh(state, view.build_kind)
	view.top_inset = hud.top_height()
	view.bottom_inset = panel.size.y if panel.visible else (build_bar.size.y if build_bar.visible else 0.0)
	mode_button.visible = not state.is_over() and not state.is_scouting()
	mode_button.reset_size()
	var bottom := root.size.y - view.bottom_inset - MODE_MARGIN
	mode_button.position = Vector2(root.size.x - mode_button.size.x - MODE_MARGIN, bottom - mode_button.size.y)
	scout_button.visible = not state.is_over() and state.scout != null and state.scout.is_landed()
	scout_button.position = Vector2(MODE_MARGIN, bottom - scout_button.size.y)
	scout_chip.reset_size()
	scout_chip.position = Vector2((root.size.x - scout_chip.size.x) * 0.5, bottom - scout_button.size.y - scout_chip.size.y - AppTheme.SPACING_SM)
	_panel_timer -= delta
	if panel.visible and _panel_timer <= 0.0:
		_panel_timer = PANEL_REFRESH
		panel.refresh()


func _on_event(event: Dictionary) -> void:
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
		_improved = progress.record(level_index, state.stars(), state.kills, state.best_combo)
		progress.save()
		_result_timer = VICTORY_DELAY if state.phase == BattleState.Phase.WON else DEFEAT_DELAY
	if _result_timer > 0.0:
		_result_timer -= delta
		if _result_timer <= 0.0:
			show_result()


func show_result() -> void:
	var state := battle.state
	var won := state.phase == BattleState.Phase.WON
	var stats: Array[Array] = [
		["RESULT_KILLS", NumberFormat.grouped(state.kills)],
		["RESULT_COMBO", "×%d" % state.best_combo],
		["RESULT_EARNED", NumberFormat.grouped(state.earned)],
		["RESULT_LOST", str(state.lost)],
		["RESULT_TIME", NumberFormat.clock(elapsed)],
	]
	var has_next := level_index + 1 < GameConfig.level_count()
	var result := ResultOverlay.new().setup(won, state.stars(), stats, has_next, _improved and won)
	result.next_pressed.connect(func() -> void: level_requested.emit(level_index + 1))
	result.retry_pressed.connect(func() -> void: level_requested.emit(level_index))
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
	menu.restart_pressed.connect(func() -> void: level_requested.emit(level_index))
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


func skip_prep() -> void:
	var bonus := battle.skip_prep()
	if bonus > 0:
		hud.toast(Texts.format("TOAST_SKIP_BONUS", [bonus]), AppTheme.GOLD)
		if sfx != null:
			sfx.play(SoundBank.CASH)


func choose_kind(kind: String) -> void:
	if view.build_kind == kind:
		view.set_build_kind("")
		return
	if battle.state.money < Formulas.build_cost(battle.state, kind):
		_on_failed(Texts.reason("build_money"), Vector2.INF)
		return
	view.set_build_kind(kind)
	hud.toast(Texts.format("TOAST_PLACE", [Texts.building_name(kind)]), AppTheme.ENERGY)


func upgrade(id: int, track: String) -> void:
	if not battle.upgrade(id, track):
		_on_failed(Texts.reason("upgrade_money"), Vector2.INF)
		return
	panel.refresh()


func sell(id: int) -> void:
	if battle.sell(id) > 0:
		view.select(-1)


func _on_selected(id: int) -> void:
	if id >= 0:
		view.build_kind = ""
		panel.show_building(id)
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
	if view.build_kind != "":
		view.set_build_kind("")
	elif view.selected_id >= 0:
		view.select(-1)
	elif view.scout_active and not battle.state.is_scouting():
		view.set_scout_active(false)
	elif view.mode == BattleView.Mode.CONNECT and not battle.state.is_over():
		view.set_mode(BattleView.Mode.MOVE)
	elif battle.state.is_over():
		menu_requested.emit()
	else:
		toggle_pause()
