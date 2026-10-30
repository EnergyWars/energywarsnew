class_name BestiaryOverlay
extends Control

signal closed

const COLUMNS := 2
const ICON_SIZE := 68.0

var progress: Progress
var safe_top := 0.0
var focus_kind := ""
var cards := {}
var scroll: ScrollContainer
var _count: Label
var _pending_focus := false


func setup(p_progress: Progress, p_safe_top: float = 0.0, p_focus: String = "") -> BestiaryOverlay:
	progress = p_progress
	safe_top = p_safe_top
	focus_kind = p_focus
	return self


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(MenuBackdrop.new())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, AppTheme.SPACING_LG)
	margin.add_theme_constant_override(&"margin_top", int(safe_top) + AppTheme.SPACING_LG)
	add_child(margin)
	var column := UiKit.vbox(AppTheme.SPACING_MD)
	margin.add_child(column)
	column.add_child(_header())
	var hint := UiKit.label(Texts.t("BESTIARY_HINT"), "Caption")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hint)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override(&"h_separation", AppTheme.SPACING_SM)
	grid.add_theme_constant_override(&"v_separation", AppTheme.SPACING_SM)
	scroll.add_child(grid)
	for kind: String in GameConfig.enemy_kinds():
		grid.add_child(_card(kind))
	_count.text = count_text(progress)
	_pending_focus = cards.has(focus_kind)


func _header() -> HBoxContainer:
	var header := UiKit.hbox(AppTheme.SPACING_SM)
	header.add_child(UiKit.icon(Icons.BUG, AppTheme.DANGER, 40))
	var title := UiKit.label(Texts.t("BESTIARY_TITLE"), "Headline")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	header.add_child(title)
	var chip := PanelContainer.new()
	chip.theme_type_variation = "Chip"
	_count = UiKit.label("", "Title")
	_count.add_theme_color_override(&"font_color", AppTheme.ENERGY)
	chip.add_child(_count)
	header.add_child(chip)
	header.add_child(UiKit.icon_button(Icons.CLOSE, close, 56.0))
	return header


static func count_text(p_progress: Progress) -> String:
	return "%d / %d" % [p_progress.seen_count(), GameConfig.enemy_kinds().size()]


func _card(kind: String) -> PanelContainer:
	var known := progress.has_seen(kind)
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var border := AppTheme.ENERGY if kind == focus_kind else AppTheme.OUTLINE
	card.add_theme_stylebox_override(&"panel", AppTheme.box(Color(AppTheme.SURFACE, 0.94), AppTheme.RADIUS_CARD, border, AppTheme.SPACING_MD))
	var column := UiKit.vbox(AppTheme.SPACING_XS)
	card.add_child(column)
	var head := UiKit.hbox(AppTheme.SPACING_SM)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override(&"panel", AppTheme.box(AppTheme.SURFACE_HIGH, AppTheme.RADIUS_PILL))
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	frame.add_child(EnemyIcon.new().setup(kind, ICON_SIZE, known))
	head.add_child(frame)
	var titles := UiKit.vbox(AppTheme.SPACING_XS)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := UiKit.label(BestiaryText.name_of(kind, known), "Title")
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(name_label)
	if known:
		titles.add_child(_badges(kind))
	head.add_child(titles)
	column.add_child(head)
	var description := UiKit.label(BestiaryText.description_of(kind, known), "Caption")
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(description)
	column.add_child(_stats(kind, known))
	cards[kind] = card
	return card


func _badges(kind: String) -> HFlowContainer:
	var flow := HFlowContainer.new()
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flow.add_theme_constant_override(&"h_separation", AppTheme.SPACING_XS)
	flow.add_theme_constant_override(&"v_separation", AppTheme.SPACING_XS)
	for badge: Array in BestiaryText.badges(kind):
		var chip := PanelContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_theme_stylebox_override(&"panel", AppTheme.box(Color(badge[1], 0.16), AppTheme.RADIUS_PILL, badge[1], AppTheme.SPACING_XS, 1))
		var text := UiKit.label(Texts.t(str(badge[0])), "Tiny")
		text.add_theme_color_override(&"font_color", badge[1])
		chip.add_child(text)
		flow.add_child(chip)
	return flow


func _stats(kind: String, known: bool) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_theme_constant_override(&"h_separation", AppTheme.SPACING_SM)
	grid.add_theme_constant_override(&"v_separation", 2)
	for row: Array in BestiaryText.rows(kind, known):
		var caption := UiKit.label(Texts.t(str(row[0])), "Tiny")
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		grid.add_child(caption)
		var value := UiKit.label(str(row[1]), "Tiny", HORIZONTAL_ALIGNMENT_RIGHT)
		value.add_theme_color_override(&"font_color", AppTheme.ON_SURFACE)
		grid.add_child(value)
	return grid


func _process(_delta: float) -> void:
	if not _pending_focus:
		return
	var card: Control = cards[focus_kind]
	if card.size.y <= 0.0:
		return
	_pending_focus = false
	scroll.ensure_control_visible(card)
	Juice.pop(card, 1.04)


func handle_back() -> void:
	close()


func close() -> void:
	closed.emit()
	queue_free()
