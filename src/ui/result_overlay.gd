class_name ResultOverlay
extends Control

signal retry_pressed
signal menu_pressed
signal star_shown(index: int)

const STAR_DELAY := 0.45

var report: BattleReport
var stats: Array[Array] = []
var won := false
var _stars_row: HBoxContainer


func setup(p_report: BattleReport, p_stats: Array[Array]) -> ResultOverlay:
	report = p_report
	stats = p_stats
	won = report.won
	return self


func title_key() -> String:
	if report.is_endless():
		return "RESULT_ENDLESS"
	if report.survival:
		return "RESULT_SURVIVED" if won else "RESULT_DEFEAT"
	return "RESULT_CONQUERED" if won else "RESULT_DEFEAT"


func subtitle() -> String:
	if report.is_endless():
		return Texts.format("RESULT_ENDLESS_TEXT", [report.days])
	if report.survival:
		return Texts.format("RESULT_SURVIVED_TEXT", [report.target]) if won else Texts.format("RESULT_SURVIVAL_LOST_TEXT", [report.days, report.target])
	return Texts.t("RESULT_CONQUERED_TEXT" if won else "RESULT_DEFEAT_TEXT")


func shows_stars() -> bool:
	return won and report.survival and not report.is_endless()


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
	var glow := AppTheme.GOLD if won or report.is_endless() else AppTheme.DANGER
	card.add_theme_stylebox_override(&"panel", AppTheme.glow_box(AppTheme.SURFACE, AppTheme.RADIUS_CARD, glow, AppTheme.SPACING_XL))
	card.custom_minimum_size = Vector2(580, 0)
	center.add_child(card)
	var column := UiKit.vbox(AppTheme.SPACING_MD)
	card.add_child(column)
	var title := UiKit.label(Texts.t(title_key()), "Display", HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_color_override(&"font_color", glow)
	title.add_theme_constant_override(&"outline_size", 10)
	column.add_child(title)
	var text := UiKit.label(subtitle(), "Caption", HORIZONTAL_ALIGNMENT_CENTER)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(text)
	if shows_stars():
		_stars_row = UiKit.hbox(AppTheme.SPACING_SM)
		_stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
		for i in Progress.MAX_STARS:
			_stars_row.add_child(UiKit.icon(Icons.STAR_EMPTY, AppTheme.OUTLINE, 84))
		column.add_child(_stars_row)
	if report.improved:
		var record := UiKit.label(Texts.t("RESULT_NEW_RECORD"), "Title", HORIZONTAL_ALIGNMENT_CENTER)
		record.add_theme_color_override(&"font_color", AppTheme.SUCCESS)
		column.add_child(record)
	column.add_child(_challenges())
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", AppTheme.SPACING_XL)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for row in stats:
		grid.add_child(UiKit.label(Texts.t(row[0]), "Body"))
		grid.add_child(UiKit.label(str(row[1]), "Title", HORIZONTAL_ALIGNMENT_RIGHT))
	column.add_child(grid)
	column.add_child(UiKit.spacer(AppTheme.SPACING_SM))
	column.add_child(UiKit.button("%s  %s" % [Icons.MAP, Texts.t("RESULT_MENU")], "PrimaryButton" if won else "Button", func() -> void: menu_pressed.emit()))
	column.add_child(UiKit.button(Texts.t("RESULT_RETRY"), "GoldButton" if not won else "Button", func() -> void: retry_pressed.emit()))
	Juice.pop_in(card)
	if shows_stars():
		for i in report.stars:
			get_tree().create_timer(STAR_DELAY * (i + 1)).timeout.connect(_show_star.bind(i))


func _challenges() -> VBoxContainer:
	var box := UiKit.vbox(AppTheme.SPACING_XS)
	var heading := Texts.format("RESULT_POINTS", [report.points]) if report.points > 0 else Texts.t("RESULT_CHALLENGES")
	var header := UiKit.label(heading, "Title", HORIZONTAL_ALIGNMENT_CENTER)
	header.add_theme_color_override(&"font_color", AppTheme.ENERGY if report.points > 0 else AppTheme.ON_SURFACE_VARIANT)
	box.add_child(header)
	for challenge in Challenges.of_level(report.level_index):
		var id := str(challenge.id)
		var fresh := report.new_challenges.has(id)
		var met := report.completed.has(id)
		var row := UiKit.hbox(AppTheme.SPACING_SM)
		row.add_child(UiKit.icon(Icons.CHECK if met else Icons.CIRCLE, AppTheme.SUCCESS if met else AppTheme.OUTLINE, 24))
		var label := UiKit.label(Texts.challenge(challenge), "Body")
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		if fresh:
			var points := UiKit.label(Texts.format("SKILL_POINTS_GAIN", [int(challenge.points)]), "Title")
			points.add_theme_color_override(&"font_color", AppTheme.ENERGY)
			row.add_child(points)
		box.add_child(row)
	return box


func _show_star(index: int) -> void:
	if not is_inside_tree() or _stars_row == null or index >= _stars_row.get_child_count():
		return
	var star: Label = _stars_row.get_child(index)
	star.text = Icons.STAR
	star.add_theme_color_override(&"font_color", AppTheme.GOLD)
	Juice.pop(star, 1.6)
	star_shown.emit(index)
