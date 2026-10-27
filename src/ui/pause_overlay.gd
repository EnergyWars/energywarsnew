class_name PauseOverlay
extends Control

signal resume_pressed
signal restart_pressed
signal menu_pressed

var settings: AppSettings
var _sound: Button
var _haptics: Button


func setup(p_settings: AppSettings) -> PauseOverlay:
	settings = p_settings
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
	card.custom_minimum_size = Vector2(480, 0)
	center.add_child(card)
	var column := UiKit.vbox(AppTheme.SPACING_MD)
	card.add_child(column)
	column.add_child(UiKit.label(Texts.t("PAUSE_TITLE"), "Headline", HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(UiKit.button(Texts.t("PAUSE_RESUME"), "PrimaryButton", func() -> void: resume_pressed.emit()))
	column.add_child(UiKit.button(Texts.t("PAUSE_RESTART"), "Button", func() -> void: restart_pressed.emit()))
	column.add_child(UiKit.button(Texts.t("PAUSE_MENU"), "Button", func() -> void: menu_pressed.emit()))
	var toggles := UiKit.hbox(AppTheme.SPACING_MD)
	toggles.alignment = BoxContainer.ALIGNMENT_CENTER
	_sound = UiKit.button("", "Button", _toggle_sound)
	_haptics = UiKit.button("", "Button", _toggle_haptics)
	toggles.add_child(_sound)
	toggles.add_child(_haptics)
	column.add_child(toggles)
	_refresh()
	Juice.pop_in(card)


func _toggle_sound() -> void:
	settings.set_sound(not settings.sound)
	_refresh()


func _toggle_haptics() -> void:
	settings.set_haptics(not settings.haptics)
	_refresh()


func _refresh() -> void:
	_sound.text = "%s  %s" % [Icons.VOLUME_ON if settings.sound else Icons.VOLUME_OFF, Texts.t("SETTINGS_SOUND")]
	_haptics.text = "%s  %s" % [Icons.VIBRATION, Texts.t("SETTINGS_HAPTICS_ON" if settings.haptics else "SETTINGS_HAPTICS_OFF")]
