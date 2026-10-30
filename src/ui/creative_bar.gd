class_name CreativeBar
extends PanelContainer

signal day_requested(day: int)
signal clear_pressed
signal money_toggled(unlimited: bool)

var stepper: DayStepper
var clear_button: Button
var money_button: Button
var unlimited := true


func _ready() -> void:
	theme_type_variation = "Card"
	add_theme_stylebox_override(&"panel", AppTheme.box(AppTheme.PANEL, AppTheme.RADIUS_CARD, AppTheme.PRIMARY_OUTLINE, AppTheme.SPACING_SM))
	mouse_filter = Control.MOUSE_FILTER_STOP
	var column := UiKit.vbox(AppTheme.SPACING_SM)
	var row := UiKit.hbox(AppTheme.SPACING_SM)
	row.add_child(UiKit.icon(Icons.PALETTE, AppTheme.ENERGY, 26))
	stepper = DayStepper.new()
	stepper.day_changed.connect(func(day: int) -> void: day_requested.emit(day))
	row.add_child(stepper)
	clear_button = UiKit.button("%s  %s" % [Icons.SWEEP, Texts.t("CREATIVE_CLEAR")], "PrimaryButton", func() -> void: clear_pressed.emit())
	clear_button.custom_minimum_size = Vector2(0, 52)
	row.add_child(clear_button)
	column.add_child(row)
	money_button = UiKit.button("", "PrimaryButton", func() -> void: money_toggled.emit(not unlimited))
	money_button.custom_minimum_size = Vector2(0, 52)
	money_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(money_button)
	add_child(column)
	_show_money()


func refresh(state: BattleState) -> void:
	stepper.set_value(state.round_number)
	stepper.set_enabled(state.day_editable())
	clear_button.disabled = state.enemies.is_empty() and not state.is_fighting()
	set_unlimited(state.has_unlimited_money())


func set_unlimited(value: bool) -> void:
	if value == unlimited:
		return
	unlimited = value
	_show_money()


func _show_money() -> void:
	money_button.theme_type_variation = "PrimaryButton" if unlimited else "Button"
	money_button.text = "%s  %s" % [Icons.INFINITY if unlimited else Icons.PAID, Texts.t("CREATIVE_MONEY_ON" if unlimited else "CREATIVE_MONEY_OFF")]
