class_name BattleHud
extends Control

signal pause_pressed
signal speed_pressed
signal start_pressed
signal undo_pressed
signal reset_pressed

const BANNER_TIME := 1.8
const TOAST_TIME := 1.6
const COMBO_FADE := 0.6

var safe_top := 0.0
var money_roll := RollingNumber.new()
var _top: PanelContainer
var _money: Label
var _energy_bar: ProgressBar
var _energy_label: Label
var _cycle_icon: Label
var _cycle_label: Label
var _day_label: Label
var _speed: Button
var _prep: PanelContainer
var _prep_label: Label
var _prep_icon: Label
var _start: Button
var _undo: Button
var _reset: Button
var _stats_button: Button
var stats_panel: EnergyStatsPanel
var _hint: PanelContainer
var _hint_label: Label
var _combo: VBoxContainer
var _combo_count: Label
var _combo_title: Label
var _banner: VBoxContainer
var _banner_title: Label
var _banner_subtitle: Label
var _toast: PanelContainer
var _toast_label: Label
var _banner_queue: Array[Dictionary] = []
var _banner_timer := 0.0
var _toast_timer := 0.0
var _combo_timer := 0.0
var _night := false


func setup(p_safe_top: float) -> BattleHud:
	safe_top = p_safe_top
	return self


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_top()
	_build_prep()
	_build_stats()
	_build_hint()
	_build_combo()
	_build_banner()
	_build_toast()


func _build_top() -> void:
	_top = PanelContainer.new()
	_top.theme_type_variation = "Bar"
	_top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_top.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_top)
	var column := UiKit.vbox(0)
	column.add_child(UiKit.spacer(safe_top))
	var row := UiKit.hbox(AppTheme.SPACING_SM)
	column.add_child(row)
	_top.add_child(column)
	row.add_child(UiKit.icon(Icons.PAID, AppTheme.GOLD, 30))
	_money = UiKit.label("0", "Money")
	_money.custom_minimum_size = Vector2(96, 0)
	row.add_child(_money)
	var energy := UiKit.vbox(2)
	energy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var energy_row := UiKit.hbox(4)
	energy_row.add_child(UiKit.icon(Icons.BOLT, AppTheme.ENERGY, 22))
	_energy_label = UiKit.label("", "Tiny")
	energy_row.add_child(_energy_label)
	energy.add_child(energy_row)
	_energy_bar = UiKit.progress_bar(AppTheme.ENERGY, 10.0)
	energy.add_child(_energy_bar)
	row.add_child(energy)
	_stats_button = UiKit.icon_button(Icons.CHART, toggle_stats, 52.0)
	row.add_child(_stats_button)
	var cycle := UiKit.vbox(0)
	var cycle_row := UiKit.hbox(2)
	_cycle_icon = UiKit.icon(Icons.SUN, AppTheme.GOLD, 24)
	cycle_row.add_child(_cycle_icon)
	_cycle_label = UiKit.label("", "Title")
	cycle_row.add_child(_cycle_label)
	cycle.add_child(cycle_row)
	_day_label = UiKit.label("", "Tiny", HORIZONTAL_ALIGNMENT_CENTER)
	cycle.add_child(_day_label)
	row.add_child(cycle)
	_speed = UiKit.button("1×", "Button", func() -> void: speed_pressed.emit())
	_speed.custom_minimum_size = Vector2(60, 52)
	row.add_child(_speed)
	row.add_child(UiKit.icon_button(Icons.PAUSE, func() -> void: pause_pressed.emit(), 52.0))


func _build_prep() -> void:
	_prep = PanelContainer.new()
	_prep.theme_type_variation = "Card"
	_prep.add_theme_stylebox_override(&"panel", AppTheme.glow_box(AppTheme.PANEL, AppTheme.RADIUS_CARD, AppTheme.ENERGY, AppTheme.SPACING_MD))
	_prep.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_prep)
	var row := UiKit.hbox(AppTheme.SPACING_MD)
	_prep_icon = UiKit.icon(Icons.FLAG, AppTheme.ENERGY, 30)
	row.add_child(_prep_icon)
	_prep_label = UiKit.label("", "Title")
	row.add_child(_prep_label)
	_undo = UiKit.icon_button(Icons.UNDO, func() -> void: undo_pressed.emit(), 52.0)
	row.add_child(_undo)
	_reset = UiKit.icon_button(Icons.RESET, func() -> void: reset_pressed.emit(), 52.0)
	row.add_child(_reset)
	_start = UiKit.button("", "PrimaryButton", func() -> void: start_pressed.emit())
	row.add_child(_start)
	_prep.add_child(row)


func _build_stats() -> void:
	stats_panel = EnergyStatsPanel.new()
	stats_panel.visible = false
	stats_panel.closed.connect(hide_stats)
	add_child(stats_panel)


func toggle_stats() -> void:
	stats_panel.visible = not stats_panel.visible
	if stats_panel.visible:
		Juice.pop_in(stats_panel)


func hide_stats() -> void:
	stats_panel.visible = false


func _build_hint() -> void:
	_hint = PanelContainer.new()
	_hint.theme_type_variation = "Card"
	_hint.add_theme_stylebox_override(&"panel", AppTheme.box(Color(AppTheme.SURFACE, 0.94), AppTheme.RADIUS_CARD, AppTheme.GOLD, AppTheme.SPACING_MD))
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.visible = false
	add_child(_hint)
	var row := UiKit.hbox(AppTheme.SPACING_MD)
	row.add_child(UiKit.icon(Icons.FLAG, AppTheme.GOLD, 28))
	_hint_label = UiKit.label("", "Body")
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.custom_minimum_size = Vector2(520, 0)
	row.add_child(_hint_label)
	_hint.add_child(row)


func _build_combo() -> void:
	_combo = UiKit.vbox(0)
	_combo.modulate.a = 0.0
	add_child(_combo)
	_combo_count = UiKit.label("", "Display", HORIZONTAL_ALIGNMENT_RIGHT)
	_combo_count.add_theme_constant_override(&"outline_size", 10)
	_combo.add_child(_combo_count)
	_combo_title = UiKit.label("", "Title", HORIZONTAL_ALIGNMENT_RIGHT)
	_combo_title.add_theme_constant_override(&"outline_size", 6)
	_combo.add_child(_combo_title)


func _build_banner() -> void:
	_banner = UiKit.vbox(0)
	_banner.modulate.a = 0.0
	add_child(_banner)
	_banner_title = UiKit.label("", "Display", HORIZONTAL_ALIGNMENT_CENTER)
	_banner_title.add_theme_constant_override(&"outline_size", 12)
	_banner.add_child(_banner_title)
	_banner_subtitle = UiKit.label("", "Title", HORIZONTAL_ALIGNMENT_CENTER)
	_banner_subtitle.add_theme_constant_override(&"outline_size", 6)
	_banner.add_child(_banner_subtitle)


func _build_toast() -> void:
	_toast = PanelContainer.new()
	_toast.theme_type_variation = "Chip"
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0
	add_child(_toast)
	_toast_label = UiKit.label("", "Body", HORIZONTAL_ALIGNMENT_CENTER)
	_toast.add_child(_toast_label)


func top_height() -> float:
	return _top.size.y if is_instance_valid(_top) else 0.0


func money_anchor() -> Vector2:
	return _money.get_global_rect().get_center()


func pulse_money() -> void:
	Juice.pop(_money, 1.25)


func refresh(state: BattleState, speed: float, tutorial_text: String, shown_money: int, history: PlanHistory = null) -> void:
	money_roll.set_target(shown_money)
	var capacity := maxf(state.storage_capacity(), 1.0)
	var stored := state.stored_energy()
	_energy_bar.value = stored / capacity
	_energy_label.text = "%d / %d   +%d/s" % [int(stored), int(capacity), int(round(state.generation()))]
	var night := state.is_night()
	var fighting := state.is_fighting()
	_cycle_icon.text = Icons.MOON if night else (Icons.SUN if fighting else Icons.FLAG)
	_cycle_icon.add_theme_color_override(&"font_color", AppTheme.VIOLET if night else AppTheme.GOLD)
	_cycle_label.text = NumberFormat.clock(DayCycle.time_to_switch(state.round_time, state.level)) if fighting else Texts.t("HUD_PLAN")
	_day_label.text = day_text(state)
	_speed.text = "%d×" % int(speed)
	var planning := state.is_planning()
	var scouting := state.is_scouting()
	var mopping := fighting and state.night_over
	_prep.visible = planning or scouting or mopping
	_start.visible = planning
	var undoable := planning and history != null and history.can_undo()
	_undo.visible = planning
	_reset.visible = planning
	_undo.disabled = not undoable
	_reset.disabled = not undoable
	_stats_button.visible = not scouting
	if scouting:
		stats_panel.visible = false
	if stats_panel.visible:
		stats_panel.refresh(state, history.baseline_stats if history != null else null)
	_prep_icon.text = Icons.SCOUT if scouting else (Icons.SUN if mopping else Icons.FLAG)
	if scouting:
		_prep_label.text = Texts.t("HUD_SCOUT")
	elif planning:
		_prep_label.text = Texts.format("HUD_PLAN_CARD", [state.round_number])
		_start.text = "%s  %s" % [Icons.PLAY, Texts.format("HUD_START", [state.round_number])]
	elif mopping:
		_prep_label.text = Texts.format("HUD_MOP_UP", [state.enemies.size()])
	_hint.visible = not tutorial_text.is_empty()
	_hint_label.text = tutorial_text
	if night != _night:
		_night = night
		Juice.pop(_cycle_icon, 1.5)


static func day_text(state: BattleState) -> String:
	var target := state.setup.days if state.is_survival() else 0
	var day := Texts.format("HUD_DAY_OF", [state.round_number, target]) if target > 0 else Texts.format("HUD_DAY", [state.round_number])
	if state.is_fighting() and not state.night_over:
		return Texts.format("HUD_DAY_WAVE", [day, state.waves_sent, Formulas.wave_times(state.level)])
	return day


func _process(delta: float) -> void:
	if money_roll.advance(delta):
		_money.text = NumberFormat.grouped(int(round(money_roll.value)))
	elif _money.text != NumberFormat.grouped(int(money_roll.target)):
		_money.text = NumberFormat.grouped(int(money_roll.target))
	_layout()
	_tick_banner(delta)
	if _toast_timer > 0.0:
		_toast_timer -= delta
		_toast.modulate.a = clampf(_toast_timer / 0.3, 0.0, 1.0)
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			var tween := create_tween()
			tween.tween_property(_combo, "modulate:a", 0.0, COMBO_FADE)


func _layout() -> void:
	var width := size.x
	var top := top_height()
	_prep.position = Vector2((width - _prep.size.x) * 0.5, top + AppTheme.SPACING_MD)
	var below := top + AppTheme.SPACING_MD + (_prep.size.y + AppTheme.SPACING_SM if _prep.visible else 0.0)
	stats_panel.position = Vector2((width - stats_panel.size.x) * 0.5, below)
	if stats_panel.visible:
		below += stats_panel.size.y + AppTheme.SPACING_SM
	_hint.position = Vector2((width - _hint.size.x) * 0.5, below)
	_combo.position = Vector2(width - _combo.size.x - AppTheme.SPACING_LG, top + 150.0)
	_banner.size.x = width
	_banner.position = Vector2(0, size.y * 0.34)
	_toast.position = Vector2((width - _toast.size.x) * 0.5, size.y * 0.7)


func banner(title: String, subtitle: String, color: Color, duration: float = BANNER_TIME) -> void:
	_banner_queue.append({"title": title, "subtitle": subtitle, "color": color, "duration": duration})
	if _banner_timer <= 0.0:
		_next_banner()


func _next_banner() -> void:
	if _banner_queue.is_empty():
		return
	var item: Dictionary = _banner_queue.pop_front()
	_banner_title.text = item.title
	_banner_title.add_theme_color_override(&"font_color", item.color)
	_banner_subtitle.text = item.subtitle
	_banner_timer = float(item.duration)
	_banner.modulate.a = 1.0
	_banner.pivot_offset = Vector2(size.x * 0.5, 40)
	_banner.scale = Vector2(0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(_banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _tick_banner(delta: float) -> void:
	if _banner_timer <= 0.0:
		return
	_banner_timer -= delta
	if _banner_timer < 0.35:
		_banner.modulate.a = clampf(_banner_timer / 0.35, 0.0, 1.0)
	if _banner_timer <= 0.0:
		_banner.modulate.a = 0.0
		_next_banner()


func toast(text: String, color: Color = AppTheme.ON_SURFACE) -> void:
	_toast_label.text = text
	_toast_label.add_theme_color_override(&"font_color", color)
	_toast.reset_size()
	_toast_timer = TOAST_TIME
	_toast.modulate.a = 1.0


func show_combo(count: int, tier: int) -> void:
	var color := AppTheme.combo_color(tier)
	_combo_count.text = "×%d" % count
	_combo_count.add_theme_color_override(&"font_color", color)
	_combo_title.text = Texts.combo_title(tier) if tier > 0 else Texts.t("COMBO_LABEL")
	_combo_title.add_theme_color_override(&"font_color", color.lightened(0.3))
	_combo.modulate.a = 1.0
	_combo.reset_size()
	_combo_timer = GameConfig.COMBO_WINDOW
	Juice.pop(_combo_count, 1.15 + 0.05 * tier)


func hide_combo() -> void:
	_combo_timer = minf(_combo_timer, 0.01)
