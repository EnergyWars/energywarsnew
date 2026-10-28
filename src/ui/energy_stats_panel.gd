class_name EnergyStatsPanel
extends PanelContainer

signal closed

const PULSE := 1.2
const MIN_WIDTH := 560.0

var _values: Array[Label] = []
var _deltas: Array[Label] = []
var _pulse := false


func _ready() -> void:
	theme_type_variation = "Card"
	add_theme_stylebox_override(&"panel", AppTheme.box(AppTheme.PANEL, AppTheme.RADIUS_CARD, AppTheme.OUTLINE, AppTheme.SPACING_LG))
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(MIN_WIDTH, 0)
	var column := UiKit.vbox(AppTheme.SPACING_SM)
	add_child(column)
	var header := UiKit.hbox(AppTheme.SPACING_SM)
	header.add_child(UiKit.icon(Icons.BOLT, AppTheme.ENERGY, 26))
	var title := UiKit.label(Texts.t("STATS_TITLE"), "Title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(UiKit.icon_button(Icons.CLOSE, func() -> void: closed.emit(), 48.0))
	column.add_child(header)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override(&"h_separation", AppTheme.SPACING_MD)
	grid.add_theme_constant_override(&"v_separation", 2)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for row: Dictionary in EnergyStatsText.ROWS:
		var caption := UiKit.label(Texts.t(row.key), "Caption")
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(caption)
		var value := UiKit.label("", "Body", HORIZONTAL_ALIGNMENT_RIGHT)
		grid.add_child(value)
		_values.append(value)
		var delta := UiKit.label("", "Tiny", HORIZONTAL_ALIGNMENT_RIGHT)
		delta.custom_minimum_size = Vector2(90, 0)
		grid.add_child(delta)
		_deltas.append(delta)
	column.add_child(grid)
	var note := UiKit.label(Texts.t("STATS_NOTE"), "Tiny")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(MIN_WIDTH - AppTheme.SPACING_LG * 2, 0)
	column.add_child(note)


func pulse_changes() -> void:
	_pulse = true


func value_text(index: int) -> String:
	return _values[index].text


func delta_text(index: int) -> String:
	return _deltas[index].text


func refresh(state: BattleState, baseline: EnergyStats, audit: EnergyAudit = null) -> void:
	if _values.is_empty():
		return
	var stats := EnergyStats.measure(state, audit)
	for i in EnergyStatsText.ROWS.size():
		var row: Dictionary = EnergyStatsText.ROWS[i]
		var text := EnergyStatsText.value_text(stats, row)
		if _pulse and _values[i].text != text and not _values[i].text.is_empty():
			Juice.pop(_values[i], PULSE)
		_values[i].text = text
		_deltas[i].text = EnergyStatsText.delta_text(stats, baseline, row)
		_deltas[i].add_theme_color_override(&"font_color", trend_color(EnergyStatsText.trend(stats, baseline, row)))
	_pulse = false


static func trend_color(trend: int) -> Color:
	if trend > 0:
		return AppTheme.SUCCESS
	if trend < 0:
		return AppTheme.DANGER
	return AppTheme.ON_SURFACE_VARIANT
