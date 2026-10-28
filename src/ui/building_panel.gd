class_name BuildingPanel
extends PanelContainer

signal closed
signal upgrade_pressed(id: int, track: String)
signal sell_pressed(id: int)
signal target_toggled(id: int, unit_class: String)
signal target_raised(id: int, unit_class: String)
signal link_pressed(id: int)
signal focus_pressed(id: int)
signal relocate_pressed(id: int)

const VISIBLE_TRACKS := 4
const TRACK_ROW_HEIGHT := 62.0
const TRACK_SCROLL_DEADZONE := 12
const PULSE := 1.2

var battle: Battle
var building_id := -1
var _icon: BuildingIcon
var _title: Label
var _info: Label
var _stats: GridContainer
var _tracks: VBoxContainer
var _track_scroll: ScrollContainer
var _targets: VBoxContainer
var _target_row: HBoxContainer
var _target_buttons: Array[Button] = []
var _sell: Button
var _actions: HBoxContainer
var _link: Button
var _focus: Button
var _relocate: Button
var active_pick := ""
var _track_rows := {}
var _stat_values: Array[Label] = []
var _pulse := false


func setup(p_battle: Battle) -> BuildingPanel:
	battle = p_battle
	return self


func _ready() -> void:
	theme_type_variation = "Card"
	add_theme_stylebox_override(&"panel", AppTheme.box(AppTheme.PANEL, AppTheme.RADIUS_CARD, AppTheme.OUTLINE, AppTheme.SPACING_LG))
	mouse_filter = Control.MOUSE_FILTER_STOP
	var column := UiKit.vbox(AppTheme.SPACING_SM)
	add_child(column)
	var header := UiKit.hbox(AppTheme.SPACING_MD)
	_icon = BuildingIcon.new().setup("", 64.0)
	header.add_child(_icon)
	var titles := UiKit.vbox(0)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title = UiKit.label("", "Title")
	titles.add_child(_title)
	_info = UiKit.label("", "Caption")
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(300, 0)
	titles.add_child(_info)
	header.add_child(titles)
	header.add_child(UiKit.icon_button(Icons.CLOSE, func() -> void: closed.emit(), 52.0))
	column.add_child(header)
	_stats = GridContainer.new()
	_stats.columns = 4
	_stats.add_theme_constant_override(&"h_separation", AppTheme.SPACING_LG)
	_stats.add_theme_constant_override(&"v_separation", 2)
	_stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_stats)
	_targets = UiKit.vbox(2)
	_targets.add_child(UiKit.label(Texts.t("PANEL_TARGETS"), "Caption"))
	_target_row = UiKit.hbox(AppTheme.SPACING_XS)
	_targets.add_child(_target_row)
	column.add_child(_targets)
	_track_scroll = ScrollContainer.new()
	_track_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_track_scroll.scroll_deadzone = TRACK_SCROLL_DEADZONE
	_tracks = UiKit.vbox(AppTheme.SPACING_XS)
	_tracks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_track_scroll.add_child(_tracks)
	column.add_child(_track_scroll)
	_actions = UiKit.hbox(AppTheme.SPACING_XS)
	_link = _action_button(func() -> void: link_pressed.emit(building_id))
	_focus = _action_button(func() -> void: focus_pressed.emit(building_id))
	_relocate = _action_button(func() -> void: relocate_pressed.emit(building_id))
	column.add_child(_actions)
	_sell = UiKit.button("", "DangerButton", func() -> void: sell_pressed.emit(building_id))
	column.add_child(_sell)


func _action_button(callback: Callable) -> Button:
	var button := UiKit.button("", "Button", callback)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override(&"font_size", AppTheme.SIZE_SMALL)
	_actions.add_child(button)
	return button


func show_building(id: int) -> void:
	building_id = id
	var building := battle.state.building(id)
	visible = building != null
	if building == null:
		return
	_icon.kind = building.kind
	_title.text = Texts.building_name(building.kind)
	_info.text = Texts.building_info(building.kind)
	_rebuild(building)
	refresh()


func _rebuild(building: Building) -> void:
	for child in _stats.get_children():
		child.queue_free()
	for child in _tracks.get_children():
		child.queue_free()
	_track_rows.clear()
	_stat_values.clear()
	for row in StatText.stats(building, battle.state):
		_stats.add_child(UiKit.label(Texts.t(row[0]), "Caption"))
		var value := UiKit.label(str(row[1]), "Body")
		_stats.add_child(value)
		_stat_values.append(value)
	var tracks: Array = building.definition().get("tracks", []) if building.is_player() else []
	for track: String in tracks:
		_tracks.add_child(_track_row(building, track))
	_track_scroll.visible = not tracks.is_empty()
	_track_scroll.custom_minimum_size.y = mini(tracks.size(), VISIBLE_TRACKS) * TRACK_ROW_HEIGHT
	_track_scroll.scroll_vertical = 0
	_rebuild_targets(building)
	_sell.visible = building.is_player() and building.id != battle.state.core_id
	_link.visible = EnergyNetwork.can_send(building)
	_focus.visible = building.is_player() and GameConfig.has_attack(building.kind)
	_relocate.visible = building.is_player() and building.id != battle.state.core_id and not GameConfig.is_mobile(building.kind)
	_actions.visible = _link.visible or _focus.visible or _relocate.visible


func _rebuild_targets(building: Building) -> void:
	for child in _target_row.get_children():
		child.queue_free()
	_target_buttons.clear()
	_targets.visible = building.is_player() and GameConfig.has_attack(building.kind)
	if not _targets.visible:
		return
	for i in GameConfig.CLASSES.size():
		if i > 0:
			var slot := i
			var swap := UiKit.icon_button(Icons.SWAP, func() -> void: _raise(slot), 44.0)
			_target_row.add_child(swap)
		var index := i
		var chip := UiKit.button("", "Button", func() -> void: _toggle(index))
		chip.custom_minimum_size = Vector2(0, 48)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.add_theme_font_size_override(&"font_size", AppTheme.SIZE_SMALL)
		_target_row.add_child(chip)
		_target_buttons.append(chip)


func _toggle(index: int) -> void:
	var building := battle.state.building(building_id)
	if building != null and index < building.target_order.size():
		target_toggled.emit(building_id, building.target_order[index])


func _raise(index: int) -> void:
	var building := battle.state.building(building_id)
	if building != null and index < building.target_order.size():
		target_raised.emit(building_id, building.target_order[index])


func target_label(building: Building, index: int) -> String:
	var unit_class := building.target_order[index]
	var name := Texts.t("CLASS_%s" % unit_class.to_upper())
	if not building.can_target(unit_class):
		return "%d  %s  ✕" % [index + 1, name]
	return "%d  %s" % [index + 1, name]


func _refresh_targets(building: Building) -> void:
	if not _targets.visible:
		return
	for i in mini(_target_buttons.size(), building.target_order.size()):
		var button := _target_buttons[i]
		var unit_class := building.target_order[i]
		var supported := bool(Formulas.attack(building).get("air" if unit_class == GameConfig.CLASS_AIR else "ground", true))
		button.text = target_label(building, i)
		button.disabled = not supported
		button.theme_type_variation = "PrimaryButton" if building.can_target(unit_class) else "Button"


func _track_row(building: Building, track: String) -> Control:
	var row := UiKit.hbox(AppTheme.SPACING_SM)
	var texts := UiKit.vbox(0)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name := UiKit.label(Texts.track_name(track, building.kind), "Body")
	texts.add_child(name)
	var detail := UiKit.label("", "Caption")
	texts.add_child(detail)
	row.add_child(texts)
	var button := UiKit.button("", "GoldButton", func() -> void: upgrade_pressed.emit(building_id, track))
	button.custom_minimum_size = Vector2(150, 56)
	row.add_child(button)
	_track_rows[track] = {"detail": detail, "button": button}
	return row


func pulse_changes() -> void:
	_pulse = true


func refresh() -> void:
	var building := battle.state.building(building_id)
	if building == null:
		visible = false
		return
	var rows := StatText.stats(building, battle.state)
	for i in mini(rows.size(), _stat_values.size()):
		var text := str(rows[i][1])
		if _pulse and _stat_values[i].text != text:
			Juice.pop(_stat_values[i], PULSE)
		_stat_values[i].text = text
	_pulse = false
	for track: String in _track_rows:
		var entry: Dictionary = _track_rows[track]
		var maxed := Formulas.is_maxed(building, track)
		var detail: Label = entry.detail
		var button: Button = entry.button
		if maxed:
			detail.text = "%s  %s" % [StatText.level_text(building, track), StatText.track_value(building, track)]
			button.text = Texts.t("PANEL_MAX")
			button.disabled = true
		else:
			detail.text = "%s  %s → %s" % [StatText.level_text(building, track), StatText.track_value(building, track), StatText.next_value(building, track)]
			var draw := StatText.draw_change(building, track)
			if not draw.is_empty():
				detail.text += "  ·  " + draw
			button.text = "▲ %d" % Formulas.upgrade_cost(building, track)
			button.disabled = not battle.can_upgrade(building_id, track)
	_sell.text = Texts.format("PANEL_SELL", [Formulas.sell_value(building)])
	_refresh_actions(building)
	_refresh_targets(building)


func _refresh_actions(building: Building) -> void:
	var state := battle.state
	if _link.visible:
		var used := state.outgoing(building.id).size()
		var total := Formulas.max_links(building)
		_link.text = "%s  %s %d/%d" % [Icons.LINK, Texts.t("PANEL_CONNECT"), used, total]
		_link.disabled = used >= total and active_pick != "link"
		_link.theme_type_variation = "PrimaryButton" if active_pick == "link" else "Button"
	if _focus.visible:
		var focused := battle.combat.focused(building) != null
		_focus.text = "%s  %s" % [Icons.TARGET, Texts.t("PANEL_UNFOCUS" if focused else "PANEL_FOCUS")]
		_focus.theme_type_variation = "PrimaryButton" if active_pick == "focus" or focused else "Button"
	if _relocate.visible:
		var cost := Formulas.relocate_cost(building, state.is_planning())
		var label := Texts.t("PANEL_RELOCATE_FREE") if cost == 0 else Texts.format("PANEL_RELOCATE", [cost])
		_relocate.text = "%s  %s" % [Icons.MOVE, label]
		_relocate.disabled = state.money < cost or state.is_over()
