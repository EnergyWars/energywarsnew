class_name ResultOverlay
extends Control

signal next_pressed
signal retry_pressed
signal menu_pressed
signal star_shown(index: int)

const STAR_DELAY := 0.45

var won := false
var stars := 0
var stats: Array[Array] = []
var has_next := false
var improved := false
var _stars_row: HBoxContainer


func setup(p_won: bool, p_stars: int, p_stats: Array[Array], p_has_next: bool, p_improved: bool) -> ResultOverlay:
	won = p_won
	stars = p_stars
	stats = p_stats
	has_next = p_has_next
	improved = p_improved
	return self


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var scrim := ColorRect.new()
	scrim.color = AppTheme.SCRIM
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card := PanelContainer.new()
	card.theme_type_variation = "Card"
	var glow := AppTheme.GOLD if won else AppTheme.DANGER
	card.add_theme_stylebox_override(&"panel", AppTheme.glow_box(AppTheme.SURFACE, AppTheme.RADIUS_CARD, glow, AppTheme.SPACING_XL))
	card.custom_minimum_size = Vector2(560, 0)
	center.add_child(card)
	var column := UiKit.vbox(AppTheme.SPACING_MD)
	card.add_child(column)
	var title := UiKit.label(Texts.t("RESULT_VICTORY" if won else "RESULT_DEFEAT"), "Display", HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_color_override(&"font_color", glow)
	title.add_theme_constant_override(&"outline_size", 10)
	column.add_child(title)
	column.add_child(UiKit.label(Texts.t("RESULT_VICTORY_TEXT" if won else "RESULT_DEFEAT_TEXT"), "Caption", HORIZONTAL_ALIGNMENT_CENTER))
	if won:
		_stars_row = UiKit.hbox(AppTheme.SPACING_SM)
		_stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
		for i in Progress.MAX_STARS:
			var star := UiKit.icon(Icons.STAR_EMPTY, AppTheme.OUTLINE, 84)
			_stars_row.add_child(star)
		column.add_child(_stars_row)
		if improved:
			var record := UiKit.label(Texts.t("RESULT_NEW_RECORD"), "Title", HORIZONTAL_ALIGNMENT_CENTER)
			record.add_theme_color_override(&"font_color", AppTheme.SUCCESS)
			column.add_child(record)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", AppTheme.SPACING_XL)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for row in stats:
		grid.add_child(UiKit.label(Texts.t(row[0]), "Body"))
		var value := UiKit.label(str(row[1]), "Title", HORIZONTAL_ALIGNMENT_RIGHT)
		grid.add_child(value)
	column.add_child(grid)
	column.add_child(UiKit.spacer(AppTheme.SPACING_SM))
	if won and has_next:
		column.add_child(UiKit.button(Texts.t("RESULT_NEXT"), "PrimaryButton", func() -> void: next_pressed.emit()))
	column.add_child(UiKit.button(Texts.t("RESULT_RETRY"), "GoldButton" if not won else "Button", func() -> void: retry_pressed.emit()))
	column.add_child(UiKit.button(Texts.t("RESULT_MENU"), "Button", func() -> void: menu_pressed.emit()))
	Juice.pop_in(card)
	if won:
		for i in stars:
			get_tree().create_timer(STAR_DELAY * (i + 1)).timeout.connect(_show_star.bind(i))


func _show_star(index: int) -> void:
	if not is_inside_tree() or _stars_row == null:
		return
	var star: Label = _stars_row.get_child(index)
	star.text = Icons.STAR
	star.add_theme_color_override(&"font_color", AppTheme.GOLD)
	Juice.pop(star, 1.6)
	star_shown.emit(index)
