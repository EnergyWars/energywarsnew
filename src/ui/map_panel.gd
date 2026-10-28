class_name MapPanel
extends PanelContainer

signal closed
signal focus_requested(world: Vector2)

const LEGEND := [
	[MiniMap.SPAWNER, "MAP_LEGEND_SPAWNER"],
	[MiniMap.TURRET, "MAP_LEGEND_TURRET"],
	[MiniMap.CORE, "MAP_LEGEND_CORE"],
	[MiniMap.SCOUT, "MAP_LEGEND_SCOUT"],
]

var state: BattleState
var minimap: MiniMap
var _summary: Label


func setup(p_state: BattleState) -> MapPanel:
	state = p_state
	return self


func _ready() -> void:
	theme_type_variation = "Card"
	add_theme_stylebox_override(&"panel", AppTheme.box(AppTheme.PANEL, AppTheme.RADIUS_CARD, AppTheme.OUTLINE, AppTheme.SPACING_MD))
	mouse_filter = Control.MOUSE_FILTER_STOP
	var column := UiKit.vbox(AppTheme.SPACING_SM)
	add_child(column)
	var header := UiKit.hbox(AppTheme.SPACING_SM)
	header.add_child(UiKit.icon(Icons.MAP, AppTheme.ENERGY, 26))
	var titles := UiKit.vbox(0)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(UiKit.label(Texts.t("MAP_TITLE"), "Title"))
	_summary = UiKit.label("", "Tiny")
	titles.add_child(_summary)
	header.add_child(titles)
	header.add_child(UiKit.icon_button(Icons.CLOSE, func() -> void: closed.emit(), 48.0))
	column.add_child(header)
	minimap = MiniMap.new().setup(state)
	minimap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	minimap.focus_requested.connect(func(world: Vector2) -> void: focus_requested.emit(world))
	column.add_child(minimap)
	var legend := HFlowContainer.new()
	legend.add_theme_constant_override(&"h_separation", AppTheme.SPACING_MD)
	legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for entry: Array in LEGEND:
		var item := UiKit.hbox(4)
		item.add_child(UiKit.icon(Icons.DOT, MiniMap.COLORS[entry[0]], 16))
		item.add_child(UiKit.label(Texts.t(entry[1]), "Tiny"))
		legend.add_child(item)
	column.add_child(legend)
	refresh(Rect2())


func summary_text() -> String:
	if not state.structures_spawned:
		return Texts.t("MAP_PENDING")
	return Texts.format("MAP_STRUCTURES", [minimap.structure_count()])


func refresh(view_rect: Rect2) -> void:
	if minimap == null:
		return
	_summary.text = summary_text()
	minimap.refresh(view_rect)
