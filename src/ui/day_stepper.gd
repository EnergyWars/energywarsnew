class_name DayStepper
extends HBoxContainer

signal day_changed(day: int)

const HOLD_DELAY := 0.4
const HOLD_REPEAT := 0.08
const LABEL_WIDTH := 108.0

var value := 1
var enabled := true
var minus_button: Button
var plus_button: Button
var value_label: Label
var _held := 0
var _hold_timer := 0.0


func setup(p_value: int) -> DayStepper:
	value = BattleSetup.clamp_day(p_value)
	return self


func _ready() -> void:
	add_theme_constant_override(&"separation", AppTheme.SPACING_XS)
	alignment = BoxContainer.ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	minus_button = _arrow(Icons.REMOVE, -1)
	add_child(minus_button)
	value_label = UiKit.label("", "Title", HORIZONTAL_ALIGNMENT_CENTER)
	value_label.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
	add_child(value_label)
	plus_button = _arrow(Icons.ADD, 1)
	add_child(plus_button)
	_refresh()


func _arrow(glyph: String, direction: int) -> Button:
	var button := UiKit.icon_button(glyph, Callable(), 52.0)
	button.button_down.connect(begin_hold.bind(direction))
	button.button_up.connect(end_hold)
	return button


func set_value(day: int) -> void:
	var clamped := BattleSetup.clamp_day(day)
	if clamped == value:
		return
	value = clamped
	_refresh()


func set_enabled(p_enabled: bool) -> void:
	if p_enabled == enabled:
		return
	enabled = p_enabled
	if not enabled:
		end_hold()
	_refresh()


func step(direction: int) -> bool:
	var next := BattleSetup.clamp_day(value + direction)
	if not enabled or next == value:
		return false
	value = next
	_refresh()
	day_changed.emit(value)
	return true


func begin_hold(direction: int) -> void:
	_held = direction
	_hold_timer = HOLD_DELAY
	step(direction)


func end_hold() -> void:
	_held = 0


func _process(delta: float) -> void:
	if _held == 0:
		return
	_hold_timer -= delta
	while _hold_timer <= 0.0 and _held != 0:
		_hold_timer += HOLD_REPEAT
		if not step(_held):
			end_hold()


func _refresh() -> void:
	if not is_instance_valid(value_label):
		return
	value_label.text = Texts.format("HUD_DAY", [value])
	minus_button.disabled = not enabled or value <= 1
	plus_button.disabled = not enabled or value >= GameConfig.CREATIVE_MAX_DAY
