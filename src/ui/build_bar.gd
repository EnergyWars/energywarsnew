class_name BuildBar
extends PanelContainer

signal kind_pressed(kind: String)
signal cancel_pressed
signal repeat_changed(repeat: bool)

const BUTTON_SIZE := Vector2(84, 108)
const ACTION_HEIGHT := 72.0

var kinds: Array[String] = []
var selected := ""
var expanded := false
var collapsible := true
var repeat := false
var build_button: Button
var cancel_button: Button
var once_button: Button
var multi_button: Button
var collapse_button: Button
var _options: HBoxContainer
var _scroll: ScrollContainer
var _row: HBoxContainer
var _buttons := {}
var _costs := {}
var _icons := {}


func setup(p_kinds: Array[String], p_collapsible: bool = true) -> BuildBar:
	kinds = p_kinds
	collapsible = p_collapsible
	return self


func _ready() -> void:
	theme_type_variation = "Bar"
	mouse_filter = Control.MOUSE_FILTER_STOP
	var column := UiKit.vbox(AppTheme.SPACING_SM)
	add_child(column)
	_options = UiKit.hbox(AppTheme.SPACING_SM)
	once_button = _option(Icons.ONCE, "BUILD_ONCE", false)
	multi_button = _option(Icons.REPEAT, "BUILD_MULTI", true)
	_options.add_child(once_button)
	_options.add_child(multi_button)
	collapse_button = UiKit.icon_button(Icons.EXPAND_MORE, collapse, 56.0)
	_options.add_child(collapse_button)
	column.add_child(_options)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.custom_minimum_size = Vector2(0, BUTTON_SIZE.y + 4)
	column.add_child(_scroll)
	_row = UiKit.hbox(AppTheme.SPACING_XS)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_row)
	build_button = UiKit.button("%s  %s" % [Icons.BUILD, Texts.t("BUILD_OPEN")], "PrimaryButton", expand)
	build_button.custom_minimum_size = Vector2(0, ACTION_HEIGHT)
	column.add_child(build_button)
	cancel_button = UiKit.button("", "DangerButton", func() -> void: cancel_pressed.emit())
	cancel_button.custom_minimum_size = Vector2(0, ACTION_HEIGHT)
	column.add_child(cancel_button)
	set_kinds(kinds)
	_layout()


func _option(glyph: String, key: String, value: bool) -> Button:
	var button := UiKit.button("%s  %s" % [glyph, Texts.t(key)], "Button", func() -> void: set_repeat(value))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button


func set_kinds(p_kinds: Array[String]) -> void:
	kinds = p_kinds
	if _row == null:
		return
	for child in _row.get_children():
		child.queue_free()
	_buttons.clear()
	_costs.clear()
	_icons.clear()
	for kind in kinds:
		_row.add_child(_make_button(kind))


func set_collapsible(value: bool) -> void:
	collapsible = value
	expanded = false
	_layout()


func expand() -> void:
	set_expanded(true)


func collapse() -> void:
	set_expanded(false)


func set_expanded(value: bool) -> void:
	expanded = value
	_layout()


func set_repeat(value: bool) -> void:
	if repeat == value:
		return
	repeat = value
	_layout()
	repeat_changed.emit(repeat)


func shows_cards() -> bool:
	return selected.is_empty() and (expanded or not collapsible)


func _layout() -> void:
	if _scroll == null:
		return
	var cards := shows_cards()
	_scroll.visible = cards
	_options.visible = cards and collapsible
	build_button.visible = selected.is_empty() and collapsible and not expanded
	cancel_button.visible = not selected.is_empty()
	once_button.theme_type_variation = "Button" if repeat else "PrimaryButton"
	multi_button.theme_type_variation = "PrimaryButton" if repeat else "Button"
	if not selected.is_empty():
		cancel_button.text = "%s  %s" % [Icons.CANCEL, Texts.format("BUILD_CANCEL", [Texts.building_name(selected)])]


func _make_button(kind: String) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = BUTTON_SIZE
	button.theme_type_variation = "Button"
	button.pressed.connect(func() -> void: kind_pressed.emit(kind))
	var column := UiKit.vbox(0)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var icon := BuildingIcon.new().setup(kind, 62.0)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(icon)
	var name_label := UiKit.label(Texts.t("BUILDING_%s_SHORT" % kind.to_upper()), "Tiny", HORIZONTAL_ALIGNMENT_CENTER)
	name_label.clip_text = true
	column.add_child(name_label)
	var cost := UiKit.label(str(int(GameConfig.building(kind).cost)), "Tiny", HORIZONTAL_ALIGNMENT_CENTER)
	cost.add_theme_color_override(&"font_color", AppTheme.GOLD)
	column.add_child(cost)
	button.add_child(column)
	_buttons[kind] = button
	_costs[kind] = cost
	_icons[kind] = icon
	return button


func refresh(state: BattleState, p_selected: String) -> void:
	if p_selected != selected:
		selected = p_selected
		_layout()
	if not shows_cards():
		return
	for kind: String in _buttons:
		var cost := Formulas.build_cost(state, kind)
		var affordable := state.money >= cost
		(_costs[kind] as Label).text = str(cost)
		var button: Button = _buttons[kind]
		button.modulate = Color(1, 1, 1, 1.0 if affordable else 0.45)
		(_costs[kind] as Label).add_theme_color_override(&"font_color", AppTheme.GOLD if affordable else AppTheme.DANGER)


func button_for(kind: String) -> Button:
	return _buttons.get(kind)
