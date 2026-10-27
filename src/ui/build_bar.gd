class_name BuildBar
extends PanelContainer

signal kind_pressed(kind: String)

const BUTTON_SIZE := Vector2(84, 108)

var kinds: Array[String] = []
var selected := ""
var _row: HBoxContainer
var _buttons := {}
var _costs := {}
var _icons := {}


func setup(p_kinds: Array[String]) -> BuildBar:
	kinds = p_kinds
	return self


func _ready() -> void:
	theme_type_variation = "Bar"
	mouse_filter = Control.MOUSE_FILTER_STOP
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, BUTTON_SIZE.y + 4)
	add_child(scroll)
	_row = UiKit.hbox(AppTheme.SPACING_XS)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_row)
	set_kinds(kinds)


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
	selected = p_selected
	for kind: String in _buttons:
		var cost := Formulas.build_cost(state, kind)
		var affordable := state.money >= cost
		(_costs[kind] as Label).text = str(cost)
		var button: Button = _buttons[kind]
		button.modulate = Color(1, 1, 1, 1.0 if affordable or kind == selected else 0.45)
		var active := kind == selected
		if active:
			button.add_theme_stylebox_override(&"normal", AppTheme.glow_box(AppTheme.SURFACE_HIGH, AppTheme.RADIUS_BUTTON, AppTheme.ENERGY, AppTheme.SPACING_XS))
		else:
			button.remove_theme_stylebox_override(&"normal")
		(_icons[kind] as BuildingIcon).scale_factor = 1.12 if active else 1.0
		(_costs[kind] as Label).add_theme_color_override(&"font_color", AppTheme.GOLD if affordable else AppTheme.DANGER)


func button_for(kind: String) -> Button:
	return _buttons.get(kind)
