class_name RegionPanel
extends PanelContainer

signal campaign_pressed(index: int)
signal survival_pressed(index: int, days: int)
signal creative_pressed(index: int, day: int)

var progress: Progress
var index := 0
var ready_to_start := true
var survival_days := -1
var creative_day := 1
var campaign_button: Button
var survival_button: Button
var creative_button: Button
var day_stepper: DayStepper
var option_buttons: Array[Button] = []
var _column: VBoxContainer


func setup(p_progress: Progress) -> RegionPanel:
	progress = p_progress
	return self


func _ready() -> void:
	theme_type_variation = "Card"
	add_theme_stylebox_override(&"panel", AppTheme.box(Color(AppTheme.SURFACE, 0.96), AppTheme.RADIUS_CARD, AppTheme.OUTLINE, AppTheme.SPACING_LG))
	mouse_filter = Control.MOUSE_FILTER_STOP
	_column = UiKit.vbox(AppTheme.SPACING_SM)
	add_child(_column)


static func survival_options() -> Array[int]:
	var options: Array[int] = GameConfig.SURVIVAL_TARGETS.duplicate()
	options.append(0)
	return options


func default_days(region: int) -> int:
	var stars := progress.stars_for(region)
	return GameConfig.SURVIVAL_TARGETS[mini(stars, GameConfig.SURVIVAL_TARGETS.size() - 1)]


func show_region(region: int, p_ready: bool = true) -> void:
	if region != index or survival_days < 0:
		survival_days = default_days(region)
	index = region
	ready_to_start = p_ready
	_rebuild()


func status_key() -> String:
	if progress.is_conquered(index):
		return "REGION_CONQUERED"
	if Campaign.is_unlocked(progress, index):
		return "REGION_ENEMY"
	return "REGION_LOCKED"


func _rebuild() -> void:
	UiKit.clear(_column)
	option_buttons = []
	campaign_button = null
	survival_button = null
	creative_button = null
	day_stepper = null
	var conquered := progress.is_conquered(index)
	var unlocked := Campaign.is_unlocked(progress, index)
	var header := UiKit.hbox(AppTheme.SPACING_SM)
	var title := UiKit.label(Texts.level_name(index), "Headline")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var status := UiKit.label(Texts.t(status_key()), "Tiny")
	status.add_theme_color_override(&"font_color", AppTheme.ENERGY if conquered else (AppTheme.DANGER if unlocked else AppTheme.OUTLINE))
	header.add_child(status)
	_column.add_child(header)
	var info := UiKit.label(Texts.level_info(index) if unlocked else Texts.t("REGION_LOCKED_INFO"), "Caption")
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_column.add_child(info)
	if not unlocked:
		return
	for challenge in Challenges.of_level(index):
		_column.add_child(_challenge_row(challenge))
	if conquered:
		_column.add_child(_survival_section())
	var actions := UiKit.hbox(AppTheme.SPACING_SM)
	campaign_button = UiKit.button("%s  %s" % [Icons.FLAG, Texts.t("REGION_REPLAY" if conquered else "REGION_ATTACK")], "Button" if conquered else "PrimaryButton", func() -> void: campaign_pressed.emit(index))
	campaign_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campaign_button.disabled = not ready_to_start
	actions.add_child(campaign_button)
	if conquered:
		survival_button = UiKit.button("%s  %s" % [Icons.MOON, Texts.t("REGION_SURVIVAL")], "PrimaryButton", func() -> void: survival_pressed.emit(index, survival_days))
		survival_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		survival_button.disabled = not ready_to_start
		actions.add_child(survival_button)
	_column.add_child(actions)
	_column.add_child(_creative_section())


func _challenge_row(challenge: Dictionary) -> HBoxContainer:
	var done := progress.is_done(index, str(challenge.id))
	var row := UiKit.hbox(AppTheme.SPACING_SM)
	row.add_child(UiKit.icon(Icons.CHECK if done else Icons.CIRCLE, AppTheme.SUCCESS if done else AppTheme.OUTLINE, 22))
	var label := UiKit.label(Texts.challenge(challenge), "Body" if not done else "Caption")
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var points := UiKit.label(Texts.format("SKILL_POINTS_GAIN", [int(challenge.points)]), "Tiny")
	points.add_theme_color_override(&"font_color", AppTheme.OUTLINE if done else AppTheme.ENERGY)
	row.add_child(points)
	return row


func _survival_section() -> VBoxContainer:
	var box := UiKit.vbox(AppTheme.SPACING_XS)
	var summary := UiKit.hbox(AppTheme.SPACING_SM)
	summary.add_child(UiKit.label(Texts.t("REGION_SURVIVAL_TITLE"), "Title"))
	summary.add_child(UiKit.stars(progress.stars_for(index), 22))
	var record := UiKit.label(Texts.format("REGION_RECORD", [progress.best_days(index)]), "Caption", HORIZONTAL_ALIGNMENT_RIGHT)
	record.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_child(record)
	box.add_child(summary)
	var options := UiKit.hbox(AppTheme.SPACING_XS)
	for days in survival_options():
		var stars := Formulas.survival_stars(days)
		var text := Texts.survival_target(days) if days > 0 else "%s  %s" % [Icons.INFINITY, Texts.t("SURVIVAL_ENDLESS")]
		if stars > 0:
			text = "%s %s" % [text, Icons.STAR.repeat(stars)]
		var option := UiKit.button(text, "PrimaryButton" if days == survival_days else "Button", select_days.bind(days))
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.add_theme_font_size_override(&"font_size", AppTheme.SIZE_SMALL)
		option_buttons.append(option)
		options.add_child(option)
	box.add_child(options)
	return box


func _creative_section() -> VBoxContainer:
	var box := UiKit.vbox(AppTheme.SPACING_XS)
	var info := UiKit.label(Texts.t("REGION_CREATIVE_INFO"), "Caption")
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(info)
	var row := UiKit.hbox(AppTheme.SPACING_SM)
	day_stepper = DayStepper.new().setup(creative_day)
	day_stepper.day_changed.connect(func(day: int) -> void: creative_day = day)
	row.add_child(day_stepper)
	creative_button = UiKit.button("%s  %s" % [Icons.PALETTE, Texts.t("REGION_CREATIVE")], "Button", func() -> void: creative_pressed.emit(index, creative_day))
	creative_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	creative_button.disabled = not ready_to_start
	row.add_child(creative_button)
	box.add_child(row)
	return box


func select_days(days: int) -> void:
	survival_days = maxi(days, 0)
	_rebuild()
