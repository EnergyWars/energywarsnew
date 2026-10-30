class_name AboutOverlay
extends Control

signal closed

var safe_top := 0.0
var privacy_url := ""
var opener := Callable(OS, "shell_open")
var version_label: Label
var privacy_text: Label
var privacy_button: Button
var toggles := {}
var bodies := {}
var titles := {}


func setup(p_safe_top: float = 0.0, p_privacy_url: String = AppInfo.PRIVACY_POLICY_URL) -> AboutOverlay:
	safe_top = p_safe_top
	privacy_url = AppInfo.privacy_url(p_privacy_url)
	return self


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(MenuBackdrop.new())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, AppTheme.SPACING_LG)
	margin.add_theme_constant_override(&"margin_top", int(safe_top) + AppTheme.SPACING_LG)
	add_child(margin)
	var column := UiKit.vbox(AppTheme.SPACING_MD)
	margin.add_child(column)
	var header := UiKit.hbox(AppTheme.SPACING_SM)
	header.add_child(UiKit.icon(Icons.INFO, AppTheme.ENERGY, 40))
	var title := UiKit.label(Texts.t("ABOUT_TITLE"), "Headline")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(UiKit.icon_button(Icons.CLOSE, close, 56.0))
	column.add_child(header)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := UiKit.vbox(AppTheme.SPACING_MD)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	list.add_child(_app_card())
	list.add_child(_privacy_card())
	list.add_child(_licenses_card())


func _app_card() -> PanelContainer:
	var column := UiKit.vbox(AppTheme.SPACING_XS)
	var app_name := UiKit.label(Texts.t("APP_TITLE"), "Title")
	app_name.add_theme_color_override(&"font_color", AppTheme.ENERGY)
	column.add_child(app_name)
	version_label = UiKit.label(Texts.format("ABOUT_VERSION", [AppInfo.version()]), "Caption")
	column.add_child(version_label)
	column.add_child(_paragraph(Texts.t("ABOUT_CREDITS")))
	return _card(column)


func _privacy_card() -> PanelContainer:
	var column := UiKit.vbox(AppTheme.SPACING_SM)
	column.add_child(_heading(Icons.PRIVACY, Texts.t("ABOUT_PRIVACY_TITLE")))
	privacy_text = _paragraph(Texts.t("ABOUT_PRIVACY_TEXT"))
	column.add_child(privacy_text)
	privacy_button = UiKit.button("%s  %s" % [Icons.OPEN_IN_NEW, Texts.t("ABOUT_PRIVACY_OPEN")], "Button", open_privacy)
	privacy_button.visible = not privacy_url.is_empty()
	column.add_child(privacy_button)
	return _card(column)


func _licenses_card() -> PanelContainer:
	var column := UiKit.vbox(AppTheme.SPACING_SM)
	column.add_child(_heading(Icons.GAVEL, Texts.t("ABOUT_LICENSES_TITLE")))
	column.add_child(_paragraph(Texts.t("ABOUT_LICENSES_HINT"), "Caption"))
	for entry in LicenseCatalog.entries():
		column.add_child(_license_row(entry))
	return _card(column)


func _license_row(entry: Dictionary) -> VBoxContainer:
	var id := str(entry.id)
	var row := UiKit.vbox(AppTheme.SPACING_XS)
	var toggle := UiKit.button("", "Button", toggle_license.bind(id))
	toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	toggle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	toggle.clip_text = true
	row.add_child(toggle)
	row.add_child(_paragraph(str(entry.info), "Tiny"))
	var body := _paragraph("", "Tiny")
	body.add_theme_color_override(&"font_color", AppTheme.ON_SURFACE)
	body.visible = false
	row.add_child(body)
	toggles[id] = toggle
	bodies[id] = body
	titles[id] = str(entry.title)
	_refresh_toggle(id)
	return row


func _card(content: Control) -> PanelContainer:
	var card := PanelContainer.new()
	card.theme_type_variation = "Card"
	card.add_child(content)
	return card


func _heading(glyph: String, text: String) -> HBoxContainer:
	var row := UiKit.hbox(AppTheme.SPACING_SM)
	row.add_child(UiKit.icon(glyph, AppTheme.GOLD, 28))
	var label := UiKit.label(text, "Title")
	label.add_theme_color_override(&"font_color", AppTheme.GOLD)
	row.add_child(label)
	return row


func _paragraph(text: String, variation: String = "Body") -> Label:
	var label := UiKit.label(text, variation)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _refresh_toggle(id: String) -> void:
	var glyph := Icons.EXPAND_LESS if is_expanded(id) else Icons.EXPAND_MORE
	(toggles[id] as Button).text = "%s  %s" % [glyph, titles[id]]


func is_expanded(id: String) -> bool:
	return bodies.has(id) and (bodies[id] as Label).visible


func license_text(id: String) -> String:
	return (bodies[id] as Label).text if bodies.has(id) else ""


func toggle_license(id: String) -> void:
	if not bodies.has(id):
		return
	var body: Label = bodies[id]
	if body.text.is_empty():
		body.text = LicenseCatalog.text(id)
	body.visible = not body.visible
	_refresh_toggle(id)


func open_privacy() -> void:
	if not privacy_url.is_empty():
		opener.call(privacy_url)


func handle_back() -> void:
	close()


func close() -> void:
	closed.emit()
	queue_free()
