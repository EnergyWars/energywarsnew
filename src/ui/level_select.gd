class_name LevelSelect
extends Control

signal level_chosen(index: int)
signal locale_changed

var progress: Progress
var settings: AppSettings
var safe_top := 0.0
var _sound: Button
var _haptics: Button
var _language: Button


func setup(p_progress: Progress, p_settings: AppSettings, p_safe_top: float = 0.0) -> LevelSelect:
	progress = p_progress
	settings = p_settings
	safe_top = p_safe_top
	return self


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = AppTheme.build()
	add_child(MenuBackdrop.new())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, AppTheme.SPACING_LG)
	margin.add_theme_constant_override(&"margin_top", int(safe_top) + AppTheme.SPACING_XL)
	add_child(margin)
	var column := UiKit.vbox(AppTheme.SPACING_MD)
	margin.add_child(column)
	var title := UiKit.label(Texts.t("APP_TITLE").to_upper(), "Display", HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_color_override(&"font_color", AppTheme.ENERGY)
	title.add_theme_font_size_override(&"font_size", 64)
	title.add_theme_constant_override(&"outline_size", 14)
	title.add_theme_color_override(&"font_outline_color", Color(AppTheme.ENERGY, 0.25))
	column.add_child(title)
	column.add_child(UiKit.label(Texts.t("MENU_TAGLINE"), "Caption", HORIZONTAL_ALIGNMENT_CENTER))
	var chips := UiKit.hbox(AppTheme.SPACING_MD)
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_child(_chip(Icons.STAR, AppTheme.GOLD, "%d / %d" % [progress.total_stars(), GameConfig.level_count() * Progress.MAX_STARS]))
	chips.add_child(_chip(Icons.BUG, AppTheme.DANGER, NumberFormat.grouped(progress.total_kills)))
	chips.add_child(_chip(Icons.BOLT, AppTheme.ENERGY, "×%d" % progress.best_combo))
	column.add_child(chips)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := UiKit.vbox(AppTheme.SPACING_SM)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for index in GameConfig.level_count():
		list.add_child(_level_card(index))
	var settings_row := UiKit.hbox(AppTheme.SPACING_SM)
	settings_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_sound = UiKit.button("", "Button", _toggle_sound)
	_haptics = UiKit.button("", "Button", _toggle_haptics)
	_language = UiKit.button("", "Button", _cycle_language)
	for button in [_sound, _haptics, _language]:
		settings_row.add_child(button)
	column.add_child(settings_row)
	column.add_child(UiKit.label(Texts.t("MENU_CREDITS"), "Tiny", HORIZONTAL_ALIGNMENT_CENTER))
	_refresh_settings()
	Juice.breathe(title, 1.03, 1.2)


func _chip(glyph: String, color: Color, text: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.theme_type_variation = "Chip"
	var row := UiKit.hbox(AppTheme.SPACING_XS)
	row.add_child(UiKit.icon(glyph, color, 22))
	row.add_child(UiKit.label(text, "Title"))
	chip.add_child(row)
	return chip


func _level_card(index: int) -> Button:
	var unlocked := progress.is_unlocked(index)
	var stars := progress.stars_for(index)
	var card := Button.new()
	card.focus_mode = Control.FOCUS_NONE
	card.custom_minimum_size = Vector2(0, 112)
	card.disabled = not unlocked
	card.pressed.connect(func() -> void: level_chosen.emit(index))
	var current := unlocked and index == progress.next_level() and stars == 0
	var border := AppTheme.ENERGY if current else AppTheme.OUTLINE
	card.add_theme_stylebox_override(&"normal", AppTheme.glow_box(Color(AppTheme.SURFACE, 0.92), AppTheme.RADIUS_CARD, border, AppTheme.SPACING_MD) if current else AppTheme.box(Color(AppTheme.SURFACE, 0.92), AppTheme.RADIUS_CARD, border, AppTheme.SPACING_MD))
	card.add_theme_stylebox_override(&"pressed", AppTheme.box(AppTheme.SURFACE_HIGH, AppTheme.RADIUS_CARD, AppTheme.ENERGY, AppTheme.SPACING_MD))
	card.add_theme_stylebox_override(&"hover", AppTheme.box(AppTheme.SURFACE_VARIANT, AppTheme.RADIUS_CARD, border, AppTheme.SPACING_MD))
	card.add_theme_stylebox_override(&"disabled", AppTheme.box(Color(AppTheme.SURFACE, 0.6), AppTheme.RADIUS_CARD, Color(AppTheme.OUTLINE, 0.4), AppTheme.SPACING_MD))
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, AppTheme.SPACING_MD)
	card.add_child(margin)
	var row := UiKit.hbox(AppTheme.SPACING_MD)
	margin.add_child(row)
	var number := UiKit.label(str(index + 1), "Headline", HORIZONTAL_ALIGNMENT_CENTER)
	number.custom_minimum_size = Vector2(56, 0)
	number.add_theme_color_override(&"font_color", AppTheme.ENERGY if unlocked else AppTheme.OUTLINE)
	row.add_child(number)
	var texts := UiKit.vbox(2)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_child(UiKit.label(Texts.level_name(index), "Title"))
	var info := UiKit.label(Texts.level_info(index), "Caption")
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(info)
	row.add_child(texts)
	if unlocked:
		row.add_child(UiKit.stars(stars, 28))
	else:
		row.add_child(UiKit.icon(Icons.LOCK, AppTheme.OUTLINE, 32))
	card.modulate = Color(1, 1, 1, 1.0 if unlocked else 0.6)
	return card


func _toggle_sound() -> void:
	settings.set_sound(not settings.sound)
	_refresh_settings()


func _toggle_haptics() -> void:
	settings.set_haptics(not settings.haptics)
	_refresh_settings()


func _cycle_language() -> void:
	var locales := AppSettings.LOCALES
	settings.set_locale(locales[(locales.find(settings.locale) + 1) % locales.size()])
	locale_changed.emit()


func _refresh_settings() -> void:
	_sound.text = Icons.VOLUME_ON if settings.sound else Icons.VOLUME_OFF
	_haptics.text = "%s %s" % [Icons.VIBRATION, Texts.t("SETTINGS_ON" if settings.haptics else "SETTINGS_OFF")]
	_language.text = "%s %s" % [Icons.LANGUAGE, Texts.t("LANGUAGE_" + (settings.locale.to_upper() if not settings.locale.is_empty() else "AUTO"))]
