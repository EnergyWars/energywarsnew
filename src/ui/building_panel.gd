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
signal rename_submitted(id: int, text: String)
signal cut_all_pressed(id: int, incoming: bool)
signal cut_pressed(from_id: int, to_id: int)
signal building_picked(id: int)
signal light_changed(id: int, radius: float)
signal light_drag_started(id: int)
signal light_drag_ended(id: int)
signal fuel_pressed(id: int)

const SCROLL_DEADZONE := 12
const PULSE := 1.2
const HOLD_DELAY := 0.45
const HOLD_REPEAT := 0.09
const HOLD_REPEAT_MIN := 0.03
const HOLD_ACCELERATION := 0.88
const MINIMIZED_PADDING := AppTheme.SPACING_SM

var battle: Battle
var building_id := -1
var _icon: BuildingIcon
var _title: Label
var _name: LineEdit
var _info: Label
var _desc_toggle: Button
var _desc: Label
var desc_open := false
var _header: HBoxContainer
var _scroll: ScrollContainer
var _links: VBoxContainer
var _cut_in: Button
var _cut_out: Button
var _link_list: VBoxContainer
var _link_rows: Array[Dictionary] = []
var _link_signature := ""
var _minimize: Button
var _body: VBoxContainer
var _stats: GridContainer
var _status: HBoxContainer
var _status_icon: Label
var _status_title: Label
var _status_cause: Label
var _status_grid: GridContainer
var _status_values: Array[Label] = []
var _tracks: VBoxContainer
var _targets: VBoxContainer
var _target_row: HBoxContainer
var _target_buttons: Array[Button] = []
var _sell: Button
var _actions: HBoxContainer
var _link: Button
var _focus: Button
var _relocate: Button
var _fuel: Button
var _light_box: VBoxContainer
var _light_value: Label
var _light_hint: Label
var light_slider: HSlider
var _light_dragging := false
var active_pick := ""
var _track_rows := {}
var _stat_values: Array[Label] = []
var _pulse := false
var _held_track := ""
var _hold_timer := 0.0
var _hold_interval := HOLD_REPEAT
var _hold_fired := false
var minimized := false
var _name_shown := false
var _status_shown := false


func setup(p_battle: Battle) -> BuildingPanel:
	battle = p_battle
	return self


func _ready() -> void:
	theme_type_variation = "Card"
	_apply_padding(AppTheme.SPACING_LG)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var column := UiKit.vbox(AppTheme.SPACING_SM)
	add_child(column)
	var header := UiKit.hbox(AppTheme.SPACING_MD)
	_header = header
	_icon = BuildingIcon.new().setup("", 64.0)
	header.add_child(_icon)
	var titles := UiKit.vbox(0)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title = UiKit.label("", "Title")
	_title.clip_text = true
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	titles.add_child(_title)
	_name = _name_field()
	titles.add_child(_name)
	_info = UiKit.label("", "Caption")
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(300, 0)
	titles.add_child(_info)
	header.add_child(titles)
	_minimize = UiKit.icon_button(Icons.EXPAND_MORE, toggle_minimized, 52.0)
	header.add_child(_minimize)
	header.add_child(UiKit.icon_button(Icons.CLOSE, func() -> void: closed.emit(), 52.0))
	column.add_child(header)
	_status = UiKit.hbox(AppTheme.SPACING_SM)
	_status_icon = UiKit.icon(Icons.CHECK, AppTheme.SUCCESS, 30)
	_status.add_child(_status_icon)
	var status_texts := UiKit.vbox(0)
	status_texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_title = UiKit.label("", "Body")
	status_texts.add_child(_status_title)
	_status_cause = UiKit.label("", "Caption")
	_status_cause.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_cause.custom_minimum_size = Vector2(420, 0)
	status_texts.add_child(_status_cause)
	_status.add_child(status_texts)
	column.add_child(_status)
	_build_light(column)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.scroll_deadzone = SCROLL_DEADZONE
	_body = UiKit.vbox(AppTheme.SPACING_SM)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_body)
	column.add_child(_scroll)
	_desc_toggle = UiKit.button("", "Button", toggle_description)
	_body.add_child(_desc_toggle)
	_desc = UiKit.label("", "Caption")
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size = Vector2(300, 0)
	_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(_desc)
	_stats = _grid()
	_body.add_child(_stats)
	_status_grid = _grid()
	_body.add_child(_status_grid)
	_targets = UiKit.vbox(2)
	_targets.add_child(UiKit.label(Texts.t("PANEL_TARGETS"), "Caption"))
	_target_row = UiKit.hbox(AppTheme.SPACING_XS)
	_targets.add_child(_target_row)
	_body.add_child(_targets)
	_tracks = UiKit.vbox(AppTheme.SPACING_XS)
	_tracks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(_tracks)
	_actions = UiKit.hbox(AppTheme.SPACING_XS)
	_link = _action_button(func() -> void: link_pressed.emit(building_id))
	_focus = _action_button(func() -> void: focus_pressed.emit(building_id))
	_relocate = _action_button(func() -> void: relocate_pressed.emit(building_id))
	_fuel = _action_button(func() -> void: fuel_pressed.emit(building_id))
	_body.add_child(_actions)
	_build_links()
	_sell = UiKit.button("", "DangerButton", func() -> void: sell_pressed.emit(building_id))
	_body.add_child(_sell)
	_apply_minimized()


func toggle_minimized() -> void:
	set_minimized(not minimized)


func toggle_description() -> void:
	desc_open = not desc_open
	_refresh_description()


func _refresh_description() -> void:
	var text := Texts.building_desc(_kind())
	_desc_toggle.visible = not text.is_empty()
	_desc_toggle.text = "%s  %s" % [Icons.EXPAND_LESS if desc_open else Icons.EXPAND_MORE, Texts.t("PANEL_INFO")]
	_desc.text = text
	_desc.visible = desc_open and not text.is_empty()


func _kind() -> String:
	var building := battle.state.building(building_id) if battle != null else null
	return building.kind if building != null else ""


func set_minimized(value: bool) -> void:
	minimized = value
	_apply_minimized()
	refresh()


func _apply_minimized() -> void:
	_scroll.visible = not minimized
	_info.visible = not minimized
	_icon.visible = not minimized
	_status.visible = not minimized and _status_shown
	_name.visible = not minimized and _name_shown
	_light_hint.visible = not minimized
	_minimize.text = Icons.EXPAND_LESS if minimized else Icons.EXPAND_MORE
	_apply_padding(MINIMIZED_PADDING if minimized else AppTheme.SPACING_LG)


func _apply_padding(padding: int) -> void:
	add_theme_stylebox_override(&"panel", AppTheme.box(AppTheme.PANEL, AppTheme.RADIUS_CARD, AppTheme.OUTLINE, padding))


func fit(max_height: float) -> void:
	if minimized or not visible:
		_scroll.custom_minimum_size.y = 0.0
		return
	var chrome := get_combined_minimum_size().y - _scroll.custom_minimum_size.y
	var wanted := _body.get_combined_minimum_size().y
	_scroll.custom_minimum_size.y = clampf(wanted, 0.0, maxf(max_height - chrome, 0.0))


func _name_field() -> LineEdit:
	var field := LineEdit.new()
	field.placeholder_text = Texts.t("PANEL_NAME_HINT")
	field.max_length = Building.LABEL_MAX
	field.add_theme_font_override(&"font", AppTheme.FONT_REGULAR)
	field.add_theme_font_size_override(&"font_size", AppTheme.SIZE_SMALL)
	field.add_theme_color_override(&"font_color", AppTheme.ON_SURFACE)
	field.add_theme_color_override(&"font_placeholder_color", AppTheme.ON_SURFACE_VARIANT)
	field.add_theme_stylebox_override(&"normal", AppTheme.box(AppTheme.SURFACE_VARIANT, AppTheme.RADIUS_CARD, AppTheme.OUTLINE, AppTheme.SPACING_SM, 1))
	field.add_theme_stylebox_override(&"focus", AppTheme.box(AppTheme.SURFACE_VARIANT, AppTheme.RADIUS_CARD, AppTheme.ENERGY, AppTheme.SPACING_SM, 2))
	field.text_submitted.connect(func(_text: String) -> void:
		_commit_name()
		field.release_focus())
	field.focus_exited.connect(_commit_name)
	return field


func _commit_name() -> void:
	var building := battle.state.building(building_id)
	if building == null or not building.is_player() or _name.text.strip_edges() == building.label:
		return
	rename_submitted.emit(building_id, _name.text)


func _build_links() -> void:
	_links = UiKit.vbox(AppTheme.SPACING_XS)
	_links.add_child(UiKit.label(Texts.t("PANEL_LINKS"), "Caption"))
	var cuts := UiKit.hbox(AppTheme.SPACING_XS)
	_cut_in = _cut_button(cuts, true)
	_cut_out = _cut_button(cuts, false)
	_links.add_child(cuts)
	_link_list = UiKit.vbox(AppTheme.SPACING_XS)
	_links.add_child(_link_list)
	_body.add_child(_links)


func _build_light(parent: Container) -> void:
	_light_box = UiKit.vbox(AppTheme.SPACING_XS)
	var header := UiKit.hbox(AppTheme.SPACING_SM)
	header.add_child(UiKit.icon(Icons.LIGHT, AppTheme.LAMP_LIGHT, 26))
	var caption := UiKit.label(Texts.t("PANEL_LIGHT"), "Caption")
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(caption)
	_light_value = UiKit.label("", "Body")
	header.add_child(_light_value)
	_light_box.add_child(header)
	light_slider = HSlider.new()
	light_slider.min_value = GameConfig.LAMP_RADIUS_MIN
	light_slider.max_value = GameConfig.LAMP_RADIUS_MAX
	light_slider.step = GameConfig.LAMP_RADIUS_STEP
	light_slider.focus_mode = Control.FOCUS_NONE
	light_slider.custom_minimum_size = Vector2(0, 48)
	light_slider.value_changed.connect(func(value: float) -> void: light_changed.emit(building_id, value))
	light_slider.drag_started.connect(func() -> void:
		_light_dragging = true
		light_drag_started.emit(building_id))
	light_slider.drag_ended.connect(func(_changed: bool) -> void:
		_light_dragging = false
		light_drag_ended.emit(building_id))
	_light_box.add_child(light_slider)
	_light_hint = UiKit.label(Texts.t("PANEL_LIGHT_HINT"), "Tiny")
	_light_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_light_hint.custom_minimum_size = Vector2(300, 0)
	_light_box.add_child(_light_hint)
	parent.add_child(_light_box)


func _refresh_light(building: Building) -> void:
	if not _light_box.visible:
		return
	if not _light_dragging and not is_equal_approx(light_slider.value, building.light_radius):
		light_slider.set_value_no_signal(building.light_radius)
	_light_value.text = Texts.format("PANEL_LIGHT_VALUE", [building.light_radius, Formulas.lamp_draw(building)])


func _cut_button(parent: Container, incoming: bool) -> Button:
	var button := UiKit.button("", "DangerButton", func() -> void: cut_all_pressed.emit(building_id, incoming))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override(&"font_size", AppTheme.SIZE_SMALL)
	parent.add_child(button)
	return button


static func building_label(building: Building) -> String:
	var name := Texts.building_name(building.kind)
	return name if building.label.is_empty() else "%s · %s" % [name, building.label]


func _links_of(building: Building) -> Array[EnergyLink]:
	var result: Array[EnergyLink] = []
	for link in battle.state.links:
		if link.source == building.id or link.target == building.id:
			result.append(link)
	return result


func _rebuild_links(building: Building) -> void:
	for child in _link_list.get_children():
		child.queue_free()
	_link_rows.clear()
	var connected: Array[EnergyLink] = []
	if building.is_player():
		connected = _links_of(building)
	_links.visible = not connected.is_empty()
	var state := battle.state
	for link: EnergyLink in connected:
		var incoming := link.target == building.id
		var other := state.building(link.source if incoming else link.target)
		if other == null:
			continue
		var row := UiKit.hbox(AppTheme.SPACING_XS)
		var texts := UiKit.vbox(0)
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var other_id := other.id
		var pick := UiKit.button("%s  %s" % ["←" if incoming else "→", building_label(other)], "Button", func() -> void: building_picked.emit(other_id))
		pick.add_theme_font_size_override(&"font_size", AppTheme.SIZE_SMALL)
		pick.alignment = HORIZONTAL_ALIGNMENT_LEFT
		pick.clip_text = true
		texts.add_child(pick)
		var data := UiKit.label("", "Caption")
		texts.add_child(data)
		row.add_child(texts)
		var source_id := link.source
		var target_id := link.target
		row.add_child(UiKit.icon_button(Icons.CLOSE, func() -> void: cut_pressed.emit(source_id, target_id), 52.0))
		_link_list.add_child(row)
		_link_rows.append({"key": link.key(), "data": data, "outgoing": not incoming})
	_link_signature = _signature(building)


func _signature(building: Building) -> String:
	var parts: PackedStringArray = []
	for link in _links_of(building):
		var other := battle.state.building(link.source if link.target == building.id else link.target)
		parts.append("%s:%s" % [link.key(), other.label if other != null else ""])
	return ",".join(parts)


func _refresh_links(building: Building) -> void:
	if _signature(building) != _link_signature:
		_rebuild_links(building)
	if not _links.visible:
		return
	var state := battle.state
	var incoming := 0
	for link in state.links:
		if link.target == building.id:
			incoming += 1
	var outgoing := state.outgoing(building.id).size()
	_cut_in.visible = incoming > 0
	_cut_out.visible = outgoing > 0
	_cut_in.text = Texts.format("PANEL_CUT_IN", [incoming])
	_cut_out.text = Texts.format("PANEL_CUT_OUT", [outgoing])
	var audit := battle.audit()
	var current := scenario()
	for row in _link_rows:
		var data: Label = row.data
		var key: String = row.key
		data.text = StatusText.link_label(audit, key, bool(row.outgoing), current)
		data.add_theme_color_override(&"font_color", StatusText.link_color(audit, key, current))


func _grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override(&"h_separation", AppTheme.SPACING_LG)
	grid.add_theme_constant_override(&"v_separation", 2)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return grid


func _action_button(callback: Callable) -> Button:
	var button := UiKit.button("", "Button", callback)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override(&"font_size", AppTheme.SIZE_SMALL)
	_actions.add_child(button)
	return button


func show_building(id: int) -> void:
	if id != building_id:
		end_hold()
		_commit_name()
		_name.release_focus()
	building_id = id
	var building := battle.state.building(id)
	visible = building != null
	if building == null:
		return
	_icon.kind = building.kind
	_refresh_title(building)
	_name_shown = building.is_player()
	_name.text = building.label
	_name.visible = _name_shown and not minimized
	_info.text = Texts.building_info(building.kind)
	_refresh_description()
	_rebuild(building)
	refresh()


func _rebuild(building: Building) -> void:
	for child in _stats.get_children():
		child.queue_free()
	for child in _tracks.get_children():
		child.queue_free()
	for child in _status_grid.get_children():
		child.queue_free()
	_track_rows.clear()
	_stat_values.clear()
	_status_values.clear()
	for row in StatText.stats(building, battle.state):
		_stats.add_child(UiKit.label(Texts.t(row[0]), "Caption"))
		var value := UiKit.label(str(row[1]), "Body")
		_stats.add_child(value)
		_stat_values.append(value)
	var audit := battle.audit() if building.is_player() else null
	for row in StatText.status_rows(building, audit, scenario()):
		_status_grid.add_child(UiKit.label(Texts.t(row[0]), "Caption"))
		var value := UiKit.label(str(row[1]), "Body")
		_status_grid.add_child(value)
		_status_values.append(value)
	_status_shown = audit != null and audit.shows(building.id)
	_status.visible = _status_shown and not minimized
	_status_grid.visible = not _status_values.is_empty()
	var tracks: Array = building.definition().get("tracks", []) if building.is_player() else []
	if not tracks.is_empty():
		for group: Dictionary in Formulas.track_layout(building.kind):
			if not str(group.title).is_empty():
				_tracks.add_child(UiKit.label(Texts.t(str(group.title)), "Caption"))
			for track: String in group.tracks:
				_tracks.add_child(_track_row(building, track))
	_tracks.visible = not tracks.is_empty()
	_scroll.scroll_vertical = 0
	_rebuild_links(building)
	_rebuild_targets(building)
	_sell.visible = building.is_player() and building.id != battle.state.core_id
	_link.visible = EnergyNetwork.can_send(building)
	_focus.visible = building.is_player() and GameConfig.has_attack(building.kind)
	_relocate.visible = building.is_player() and building.id != battle.state.core_id and not GameConfig.is_mobile(building.kind)
	_fuel.visible = building.is_player() and building.burner
	_actions.visible = _link.visible or _focus.visible or _relocate.visible or _fuel.visible
	_light_box.visible = building.is_player() and building.lighting
	if _light_box.visible:
		light_slider.set_value_no_signal(building.light_radius)


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
		return "%d  %s  %s" % [index + 1, name, Icons.CLOSE]
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
	var button := UiKit.button("", "GoldButton", func() -> void: _on_upgrade_released(track))
	button.button_down.connect(begin_hold.bind(track))
	button.button_up.connect(end_hold)
	button.custom_minimum_size = Vector2(150, 56)
	row.add_child(button)
	_track_rows[track] = {"detail": detail, "button": button}
	return row


func begin_hold(track: String) -> void:
	_held_track = track
	_hold_timer = HOLD_DELAY
	_hold_interval = HOLD_REPEAT
	_hold_fired = false


func end_hold() -> void:
	_held_track = ""


func _on_upgrade_released(track: String) -> void:
	if _hold_fired:
		_hold_fired = false
		return
	upgrade_pressed.emit(building_id, track)


func _process(delta: float) -> void:
	if _held_track.is_empty():
		return
	_hold_timer -= delta
	while _hold_timer <= 0.0 and not _held_track.is_empty():
		_hold_timer += _hold_interval
		_hold_interval = maxf(HOLD_REPEAT_MIN, _hold_interval * HOLD_ACCELERATION)
		_hold_fired = true
		var entry: Dictionary = _track_rows.get(_held_track, {})
		var button: Button = entry.get("button")
		if not visible or button == null or button.disabled:
			end_hold()
			return
		upgrade_pressed.emit(building_id, _held_track)


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
	_refresh_status(building)
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
			var overload := StatText.overload_change(building, track)
			if not overload.is_empty():
				detail.text += "  ·  " + overload
			detail.add_theme_color_override(&"font_color", AppTheme.WARNING if not overload.is_empty() else AppTheme.ON_SURFACE_VARIANT)
			button.text = "▲ %d" % Formulas.upgrade_cost(building, track)
			button.disabled = not battle.can_upgrade(building_id, track)
	_sell.text = sell_text(building, battle.state.is_planning())
	_refresh_actions(building)
	_refresh_title(building)
	_refresh_light(building)
	_refresh_targets(building)
	_refresh_links(building)
	if not _name.has_focus() and _name.text != building.label:
		_name.text = building.label


func _refresh_title(building: Building) -> void:
	_title.text = building_label(building) if minimized else Texts.building_name(building.kind)


static func sell_text(building: Building, planning: bool) -> String:
	var value := Formulas.sell_value(building)
	if planning and Formulas.is_fresh(building):
		return Texts.format("PANEL_SELL_FULL", [value])
	var loss := Formulas.sell_loss(building)
	if loss > 0:
		return Texts.format("PANEL_SELL_LOSS", [value, loss])
	return Texts.format("PANEL_SELL", [value])


func scenario() -> int:
	return EnergyAudit.view_scenario(battle.state)


func _refresh_status(building: Building) -> void:
	if not building.is_player():
		return
	var audit := battle.audit()
	var current := scenario()
	if _status_shown:
		var verdict := audit.verdict(building.id, current)
		_status_icon.text = StatusText.icon(verdict)
		_status_icon.add_theme_color_override(&"font_color", StatusText.color(verdict))
		_status_title.text = StatusText.summary(audit, building, current)
		_status_title.add_theme_color_override(&"font_color", StatusText.color(verdict))
		_status_cause.text = StatusText.cause_text(audit, building, battle.state, current)
		_status_cause.visible = not minimized and not _status_cause.text.is_empty()
	var rows := StatText.status_rows(building, audit, current)
	for i in mini(rows.size(), _status_values.size()):
		_status_values[i].text = str(rows[i][1])


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
	if _fuel.visible:
		_fuel.text = "%s  %s" % [Icons.TREE, Texts.format("PANEL_FUEL", [building.fuel.size()])]
		_fuel.theme_type_variation = "PrimaryButton" if active_pick == "fuel" else "Button"
		_fuel.disabled = state.is_over()
	if _relocate.visible:
		var cost := Formulas.relocate_cost(building, state.is_planning())
		var label := Texts.t("PANEL_RELOCATE_FREE") if cost == 0 else Texts.format("PANEL_RELOCATE", [cost])
		_relocate.text = "%s  %s" % [Icons.MOVE, label]
		_relocate.disabled = not state.can_afford(cost) or state.is_over()
