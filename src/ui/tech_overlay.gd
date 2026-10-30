class_name TechOverlay
extends Control

signal closed
signal changed

var progress: Progress
var safe_top := 0.0
var buttons := {}
var reset_button: Button
var dialog: ConfirmOverlay
var _points: Label
var _list: VBoxContainer


func setup(p_progress: Progress, p_safe_top: float = 0.0) -> TechOverlay:
	progress = p_progress
	safe_top = p_safe_top
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
	header.add_child(UiKit.icon(Icons.SCIENCE, AppTheme.ENERGY, 40))
	var title := UiKit.label(Texts.t("TECH_TITLE"), "Headline")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var chip := PanelContainer.new()
	chip.theme_type_variation = "Chip"
	_points = UiKit.label("", "Title")
	_points.add_theme_color_override(&"font_color", AppTheme.ENERGY)
	chip.add_child(_points)
	header.add_child(chip)
	header.add_child(UiKit.icon_button(Icons.CLOSE, close, 56.0))
	column.add_child(header)
	var hint := UiKit.label(Texts.t("TECH_HINT"), "Caption")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_list = UiKit.vbox(AppTheme.SPACING_SM)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	reset_button = UiKit.button("%s  %s" % [Icons.RESET, Texts.t("TECH_RESET")], "Button", confirm_reset)
	column.add_child(reset_button)
	refresh()


func refresh() -> void:
	_points.text = Texts.format("SKILL_POINTS", [progress.skill_points()])
	reset_button.disabled = progress.techs.is_empty()
	UiKit.clear(_list)
	buttons = {}
	for branch in GameConfig.BRANCHES:
		var label := UiKit.label(Texts.branch_name(branch), "Title")
		label.add_theme_color_override(&"font_color", AppTheme.GOLD)
		_list.add_child(label)
		for id in TechTree.of_branch(branch):
			_list.add_child(_row(id))


func _row(id: String) -> PanelContainer:
	var reason := TechTree.reason(progress, id)
	var owned := reason == TechTree.OWNED
	var card := PanelContainer.new()
	var border := AppTheme.SUCCESS if owned else (AppTheme.ENERGY if reason == TechTree.OK else AppTheme.OUTLINE)
	card.add_theme_stylebox_override(&"panel", AppTheme.box(Color(AppTheme.SURFACE, 0.94), AppTheme.RADIUS_CARD, border, AppTheme.SPACING_MD))
	var row := UiKit.hbox(AppTheme.SPACING_MD)
	card.add_child(row)
	row.add_child(BuildingIcon.new().setup(icon_kind(id), 56.0))
	var texts := UiKit.vbox(2)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_child(UiKit.label(Texts.tech_name(id), "Title"))
	var info := UiKit.label(Texts.tech_info(id), "Caption")
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(info)
	if reason == TechTree.REQUIRES:
		var names: Array[String] = []
		for required in TechTree.missing(progress, id):
			names.append(Texts.tech_name(required))
		var needs := UiKit.label(Texts.format("TECH_REQUIRES", [", ".join(PackedStringArray(names))]), "Tiny")
		needs.add_theme_color_override(&"font_color", AppTheme.WARNING)
		needs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texts.add_child(needs)
	row.add_child(texts)
	var text := "%s  %s" % [Icons.CHECK, Texts.t("TECH_OWNED")] if owned else Texts.format("TECH_BUY", [TechTree.cost(id)])
	var button := UiKit.button(text, "PrimaryButton" if reason == TechTree.OK else "Button", buy.bind(id))
	button.disabled = reason != TechTree.OK
	button.custom_minimum_size = Vector2(150, 56)
	buttons[id] = button
	row.add_child(button)
	return card


static func icon_kind(id: String) -> String:
	var tech := GameConfig.tech(id)
	if tech.has("unlock"):
		return str(tech.unlock)
	var scope := str(tech.get("kind", ""))
	if scope == GameConfig.ALL_TOWERS:
		return GameConfig.ZAPPER
	if scope == GameConfig.ALL_BUILDINGS or scope.is_empty():
		return GameConfig.CORE if tech.has("money") else GameConfig.BULWARK
	return scope


func buy(id: String) -> void:
	if TechTree.buy(progress, id) != TechTree.OK:
		return
	progress.save()
	refresh()
	changed.emit()


func confirm_reset() -> void:
	if progress.techs.is_empty():
		return
	dialog = ConfirmOverlay.new().setup(Texts.t("TECH_RESET_TITLE"), Texts.format("TECH_RESET_TEXT", [progress.spent_points()]), Texts.t("TECH_RESET_CONFIRM"))
	dialog.cancelled.connect(dialog.queue_free)
	dialog.confirmed.connect(_reset_confirmed)
	add_child(dialog)


func _reset_confirmed() -> void:
	if is_instance_valid(dialog):
		dialog.queue_free()
	progress.reset_techs()
	progress.save()
	refresh()
	changed.emit()


func handle_back() -> void:
	if is_instance_valid(dialog) and not dialog.is_queued_for_deletion():
		dialog.queue_free()
	else:
		close()


func close() -> void:
	closed.emit()
	queue_free()
