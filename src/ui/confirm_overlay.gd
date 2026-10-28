class_name ConfirmOverlay
extends Control

signal confirmed
signal cancelled

var title := ""
var message := ""
var confirm_label := ""
var confirm_button: Button
var cancel_button: Button


func setup(p_title: String, p_message: String, p_confirm: String) -> ConfirmOverlay:
	title = p_title
	message = p_message
	confirm_label = p_confirm
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
	column.add_child(UiKit.icon(Icons.WARNING, AppTheme.WARNING, 40))
	column.add_child(UiKit.label(title, "Headline", HORIZONTAL_ALIGNMENT_CENTER))
	var text := UiKit.label(message, "Body", HORIZONTAL_ALIGNMENT_CENTER)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(440, 0)
	column.add_child(text)
	var buttons := UiKit.hbox(AppTheme.SPACING_MD)
	cancel_button = UiKit.button(Texts.t("DIALOG_CANCEL"), "Button", func() -> void: cancelled.emit())
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(cancel_button)
	confirm_button = UiKit.button(confirm_label, "DangerButton", func() -> void: confirmed.emit())
	confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(confirm_button)
	column.add_child(buttons)
	Juice.pop_in(card)
