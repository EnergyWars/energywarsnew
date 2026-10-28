class_name WorldMapScreen
extends Control

signal campaign_chosen(index: int)
signal survival_chosen(index: int, days: int)
signal locale_changed

var progress: Progress
var settings: AppSettings
var safe_top := 0.0
var map: WorldMapView
var panel: RegionPanel
var tech: TechOverlay
var tech_button: Button
var _top: VBoxContainer
var _bottom: VBoxContainer
var _stars: Label
var _points: Label
var _sound: Button
var _haptics: Button
var _language: Button
var _toast: Label
var _toast_timer := 0.0


func setup(p_progress: Progress, p_settings: AppSettings, p_safe_top: float = 0.0) -> WorldMapScreen:
	progress = p_progress
	settings = p_settings
	safe_top = p_safe_top
	return self


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = AppTheme.build()
	map = WorldMapView.new().setup(progress)
	add_child(map)
	map.region_tapped.connect(_on_region_tapped)
	map.arrived.connect(_on_arrived)
	_build_top()
	_build_bottom()
	_build_toast()
	refresh()
	panel.show_region(map.walker.location)


func _build_top() -> void:
	_top = UiKit.vbox(AppTheme.SPACING_XS)
	_top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_top.offset_top = safe_top + AppTheme.SPACING_LG
	_top.offset_left = AppTheme.SPACING_LG
	_top.offset_right = -AppTheme.SPACING_LG
	add_child(_top)
	var title := UiKit.label(Texts.t("APP_TITLE").to_upper(), "Display", HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_color_override(&"font_color", AppTheme.ENERGY)
	title.add_theme_constant_override(&"outline_size", 12)
	_top.add_child(title)
	_top.add_child(UiKit.label(Texts.t("WORLD_TAGLINE"), "Caption", HORIZONTAL_ALIGNMENT_CENTER))
	var chips := UiKit.hbox(AppTheme.SPACING_MD)
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	_stars = _chip(chips, Icons.STAR, AppTheme.GOLD)
	_points = _chip(chips, Icons.SCIENCE, AppTheme.ENERGY)
	var kills := _chip(chips, Icons.BUG, AppTheme.DANGER)
	kills.text = NumberFormat.grouped(progress.total_kills)
	_top.add_child(chips)


func _chip(row: HBoxContainer, glyph: String, color: Color) -> Label:
	var chip := PanelContainer.new()
	chip.theme_type_variation = "Chip"
	var content := UiKit.hbox(AppTheme.SPACING_XS)
	content.add_child(UiKit.icon(glyph, color, 22))
	var value := UiKit.label("", "Title")
	content.add_child(value)
	chip.add_child(content)
	row.add_child(chip)
	return value


func _build_bottom() -> void:
	_bottom = UiKit.vbox(AppTheme.SPACING_SM)
	_bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_bottom.offset_left = AppTheme.SPACING_LG
	_bottom.offset_right = -AppTheme.SPACING_LG
	_bottom.offset_bottom = -AppTheme.SPACING_LG
	add_child(_bottom)
	panel = RegionPanel.new().setup(progress)
	panel.campaign_pressed.connect(func(index: int) -> void: campaign_chosen.emit(index))
	panel.survival_pressed.connect(func(index: int, days: int) -> void: survival_chosen.emit(index, days))
	_bottom.add_child(panel)
	var row := UiKit.hbox(AppTheme.SPACING_SM)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	tech_button = UiKit.button("", "GoldButton", open_tech)
	tech_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(tech_button)
	_sound = UiKit.button("", "Button", _toggle_sound)
	_haptics = UiKit.button("", "Button", _toggle_haptics)
	_language = UiKit.button("", "Button", _cycle_language)
	for button in [_sound, _haptics, _language]:
		row.add_child(button)
	_bottom.add_child(row)
	_bottom.add_child(UiKit.label(Texts.t("MENU_CREDITS"), "Tiny", HORIZONTAL_ALIGNMENT_CENTER))


func _build_toast() -> void:
	_toast = UiKit.label("", "Title", HORIZONTAL_ALIGNMENT_CENTER)
	_toast.add_theme_constant_override(&"outline_size", 8)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_toast.modulate.a = 0.0
	add_child(_toast)


func refresh() -> void:
	_stars.text = "%d / %d" % [progress.total_stars(), GameConfig.level_count() * Progress.MAX_STARS]
	_points.text = Texts.format("SKILL_POINTS", [progress.skill_points()])
	tech_button.text = "%s  %s" % [Icons.SCIENCE, Texts.format("WORLD_TECH", [progress.skill_points()])]
	_sound.text = Icons.VOLUME_ON if settings.sound else Icons.VOLUME_OFF
	_haptics.text = Icons.VIBRATION if settings.haptics else "%s %s" % [Icons.VIBRATION, Texts.t("SETTINGS_OFF")]
	_language.text = "%s %s" % [Icons.LANGUAGE, Texts.t("LANGUAGE_" + (settings.locale.to_upper() if not settings.locale.is_empty() else "AUTO"))]


func _process(delta: float) -> void:
	map.top_inset = _top.get_rect().end.y
	map.bottom_inset = _bottom.size.y + AppTheme.SPACING_LG
	if _toast_timer > 0.0:
		_toast_timer -= delta
		_toast.modulate.a = clampf(_toast_timer / 0.3, 0.0, 1.0)


func toast(text: String, color: Color = AppTheme.ON_SURFACE) -> void:
	_toast.text = text
	_toast.add_theme_color_override(&"font_color", color)
	_toast.reset_size()
	_toast.position = Vector2((size.x - _toast.size.x) * 0.5, size.y * 0.45)
	_toast_timer = 1.6
	_toast.modulate.a = 1.0


func _on_region_tapped(index: int) -> void:
	if not Campaign.is_unlocked(progress, index):
		panel.show_region(index, false)
		toast(Texts.t("WORLD_LOCKED"), AppTheme.WARNING)
		return
	if index == map.walker.location and not map.walker.is_walking():
		panel.show_region(index)
		return
	if map.walk_to(index):
		panel.show_region(index, false)


func _on_arrived(index: int) -> void:
	progress.location = index
	progress.save()
	panel.show_region(index)


func open_tech() -> void:
	if is_instance_valid(tech):
		return
	tech = TechOverlay.new().setup(progress, safe_top)
	tech.changed.connect(refresh)
	add_child(tech)


func handle_back() -> bool:
	if is_instance_valid(tech) and not tech.is_queued_for_deletion():
		tech.handle_back()
		return true
	return false


func _toggle_sound() -> void:
	settings.set_sound(not settings.sound)
	refresh()


func _toggle_haptics() -> void:
	settings.set_haptics(not settings.haptics)
	refresh()


func _cycle_language() -> void:
	var locales := AppSettings.LOCALES
	settings.set_locale(locales[(locales.find(settings.locale) + 1) % locales.size()])
	locale_changed.emit()
