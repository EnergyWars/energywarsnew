class_name BuildBar
extends PanelContainer

signal kind_pressed(kind: String)
signal cancel_pressed
signal repeat_changed(repeat: bool)

const BUTTON_HEIGHT := 108.0
const COLUMNS := 4
const ACTION_HEIGHT := 72.0
const ALL := "all"
const OTHER := "other"
const INFO_HOLD := 0.45
const INFO_ICON := 56.0

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
var category := ""
var _tabs: HBoxContainer
var _grid: GridContainer
var _tab_buttons := {}
var _buttons := {}
var _costs := {}
var _icons := {}
var _groups := []
var info_kind := ""
var info_mode := false
var info_button: Button
var info_build_button: Button
var _info: PanelContainer
var _info_icon: BuildingIcon
var _info_title: Label
var _info_short: Label
var _info_desc: Label
var _info_cost: Label
var _hold_kind := ""
var _hold_time := 0.0
var _suppressed := ""


func setup(p_kinds: Array[String], p_collapsible: bool = true) -> BuildBar:
	kinds = p_kinds
	collapsible = p_collapsible
	return self


func _ready() -> void:
	theme_type_variation = "Bar"
	mouse_filter = Control.MOUSE_FILTER_STOP
	var column := UiKit.vbox(AppTheme.SPACING_SM)
	add_child(column)
	column.add_child(_build_info())
	_options = UiKit.hbox(AppTheme.SPACING_SM)
	once_button = _option(Icons.ONCE, "BUILD_ONCE", false)
	multi_button = _option(Icons.REPEAT, "BUILD_MULTI", true)
	_options.add_child(once_button)
	_options.add_child(multi_button)
	info_button = UiKit.button(Icons.DETAILS, "Button", toggle_info_mode)
	info_button.custom_minimum_size = Vector2(56, 56)
	_options.add_child(info_button)
	collapse_button = UiKit.icon_button(Icons.EXPAND_MORE, collapse, 56.0)
	_options.add_child(collapse_button)
	column.add_child(_options)
	_tabs = UiKit.hbox(AppTheme.SPACING_XS)
	column.add_child(_tabs)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override(&"h_separation", AppTheme.SPACING_XS)
	_grid.add_theme_constant_override(&"v_separation", AppTheme.SPACING_XS)
	column.add_child(_grid)
	build_button = UiKit.button("%s  %s" % [Icons.BUILD, Texts.t("BUILD_OPEN")], "PrimaryButton", expand)
	build_button.custom_minimum_size = Vector2(0, ACTION_HEIGHT)
	column.add_child(build_button)
	cancel_button = UiKit.button("", "DangerButton", func() -> void: cancel_pressed.emit())
	cancel_button.custom_minimum_size = Vector2(0, ACTION_HEIGHT)
	column.add_child(cancel_button)
	set_kinds(kinds)
	_layout()


func _build_info() -> PanelContainer:
	_info = PanelContainer.new()
	_info.add_theme_stylebox_override(&"panel", AppTheme.box(AppTheme.SURFACE, AppTheme.RADIUS_CARD, AppTheme.ENERGY, AppTheme.SPACING_MD))
	_info.visible = false
	var column := UiKit.vbox(AppTheme.SPACING_SM)
	_info.add_child(column)
	var head := UiKit.hbox(AppTheme.SPACING_MD)
	_info_icon = BuildingIcon.new().setup("", INFO_ICON)
	head.add_child(_info_icon)
	var titles := UiKit.vbox(2)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_title = UiKit.label("", "Title")
	titles.add_child(_info_title)
	_info_short = UiKit.label("", "Caption")
	_info_short.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(_info_short)
	head.add_child(titles)
	head.add_child(UiKit.icon_button(Icons.CLOSE, hide_info, 52.0))
	column.add_child(head)
	_info_desc = UiKit.label("", "Body")
	_info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_info_desc)
	var footer := UiKit.hbox(AppTheme.SPACING_SM)
	footer.add_child(UiKit.icon(Icons.PAID, AppTheme.GOLD, 24))
	_info_cost = UiKit.label("", "Title")
	_info_cost.add_theme_color_override(&"font_color", AppTheme.GOLD)
	_info_cost.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_info_cost)
	info_build_button = UiKit.button("", "PrimaryButton", _build_from_info)
	footer.add_child(info_build_button)
	column.add_child(footer)
	return _info


func show_info(kind: String) -> void:
	if not kinds.has(kind):
		return
	info_kind = kind
	_info_icon.kind = kind
	_info_icon.queue_redraw()
	_info_title.text = Texts.building_name(kind)
	_info_short.text = Texts.building_info(kind)
	var description := Texts.building_desc(kind)
	_info_desc.text = description
	_info_desc.visible = not description.is_empty()
	_info_cost.text = (_costs[kind] as Label).text if _costs.has(kind) else str(int(GameConfig.building(kind).get("cost", 0)))
	info_build_button.text = "%s  %s" % [Icons.BUILD, Texts.t("BUILD_INFO_PLACE")]
	_layout()


func hide_info() -> void:
	if info_kind.is_empty():
		return
	info_kind = ""
	_layout()


func info_visible() -> bool:
	return _info != null and _info.visible


func toggle_info_mode() -> void:
	info_mode = not info_mode
	if not info_mode:
		hide_info()
	_layout()


func _build_from_info() -> void:
	var kind := info_kind
	hide_info()
	if not kind.is_empty():
		kind_pressed.emit(kind)


func _card_pressed(kind: String) -> void:
	if _suppressed == kind:
		_suppressed = ""
		return
	if info_mode:
		show_info(kind)
		return
	kind_pressed.emit(kind)


func begin_hold(kind: String) -> void:
	_hold_kind = kind
	_hold_time = 0.0
	_suppressed = ""


func end_hold() -> void:
	_hold_kind = ""
	_hold_time = 0.0


func _process(delta: float) -> void:
	if _hold_kind.is_empty():
		return
	_hold_time += delta
	if _hold_time < INFO_HOLD:
		return
	_suppressed = _hold_kind
	show_info(_hold_kind)
	end_hold()


func _option(glyph: String, key: String, value: bool) -> Button:
	var button := UiKit.button("%s  %s" % [glyph, Texts.t(key)], "Button", func() -> void: set_repeat(value))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button


static func groups(p_kinds: Array[String]) -> Array:
	var result := []
	var placed := {}
	for entry: Dictionary in GameConfig.BUILD_CATEGORIES:
		var members: Array[String] = []
		for kind: String in entry.kinds:
			if p_kinds.has(kind):
				members.append(kind)
				placed[kind] = true
		if not members.is_empty():
			result.append({"key": entry.key, "kinds": members})
	var rest: Array[String] = []
	for kind in p_kinds:
		if not placed.has(kind):
			rest.append(kind)
	if not rest.is_empty():
		result.append({"key": OTHER, "kinds": rest})
	return result


static func tabs(p_kinds: Array[String]) -> Array:
	var result := groups(p_kinds)
	if result.size() > 1:
		var every: Array[String] = []
		for group: Dictionary in result:
			every.append_array(group.kinds)
		result.push_front({"key": ALL, "kinds": every})
	return result


func set_kinds(p_kinds: Array[String]) -> void:
	kinds = p_kinds
	if _grid == null:
		return
	_groups = tabs(kinds)
	if not _groups.any(func(group: Dictionary) -> bool: return group.key == category):
		category = _groups[0].key if not _groups.is_empty() else ""
	UiKit.clear(_tabs)
	_tab_buttons.clear()
	for group: Dictionary in _groups:
		var key: String = group.key
		var tab := UiKit.button(Texts.t("BUILD_CATEGORY_%s" % key.to_upper()), "Button", func() -> void: select_category(key))
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_tabs.add_child(tab)
		_tab_buttons[key] = tab
	_fill_grid()
	_layout()


func select_category(key: String) -> void:
	if key == category or not _tab_buttons.has(key):
		return
	category = key
	_fill_grid()
	_layout()


func _fill_grid() -> void:
	UiKit.clear(_grid)
	_buttons.clear()
	_costs.clear()
	_icons.clear()
	for group: Dictionary in _groups:
		if group.key != category:
			continue
		for kind: String in group.kinds:
			_grid.add_child(_make_button(kind))


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
	if _grid == null:
		return
	var cards := shows_cards()
	if not cards or not kinds.has(info_kind):
		info_kind = ""
	_info.visible = not info_kind.is_empty()
	info_button.theme_type_variation = "PrimaryButton" if info_mode else "Button"
	_grid.visible = cards
	_tabs.visible = cards and _groups.size() > 1
	for key: String in _tab_buttons:
		(_tab_buttons[key] as Button).theme_type_variation = "PrimaryButton" if key == category else "Button"
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
	button.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.theme_type_variation = "Button"
	button.pressed.connect(_card_pressed.bind(kind))
	button.button_down.connect(begin_hold.bind(kind))
	button.button_up.connect(end_hold)
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
		var affordable := state.can_afford(cost)
		(_costs[kind] as Label).text = str(cost)
		var button: Button = _buttons[kind]
		button.modulate = Color(1, 1, 1, 1.0 if affordable else 0.45)
		(_costs[kind] as Label).add_theme_color_override(&"font_color", AppTheme.GOLD if affordable else AppTheme.DANGER)
	if _costs.has(info_kind):
		_info_cost.text = (_costs[info_kind] as Label).text


func button_for(kind: String) -> Button:
	return _buttons.get(kind)
