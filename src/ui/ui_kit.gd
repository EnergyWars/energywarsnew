class_name UiKit
extends RefCounted


static func label(text: String, variation: String = "Body", align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var item := Label.new()
	item.text = text
	item.theme_type_variation = variation
	item.horizontal_alignment = align
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item


static func icon(glyph: String, color: Color = AppTheme.ON_SURFACE, size: int = AppTheme.SIZE_ICON) -> Label:
	var item := label(glyph, "Icon", HORIZONTAL_ALIGNMENT_CENTER)
	item.add_theme_color_override(&"font_color", color)
	item.add_theme_font_size_override(&"font_size", size)
	return item


static func button(text: String, variation: String = "Button", callback: Callable = Callable()) -> Button:
	var item := Button.new()
	item.text = text
	item.theme_type_variation = variation
	item.focus_mode = Control.FOCUS_NONE
	item.custom_minimum_size = Vector2(0, 56)
	if callback.is_valid():
		item.pressed.connect(callback)
	return item


static func icon_button(glyph: String, callback: Callable = Callable(), size: float = 56.0) -> Button:
	var item := button(glyph, "IconButton", callback)
	item.custom_minimum_size = Vector2(size, size)
	return item


static func dock_bottom(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	control.offset_top = 0.0
	control.grow_vertical = Control.GROW_DIRECTION_BEGIN


static func spacer(height: float = 0.0, expand: bool = false) -> Control:
	var item := Control.new()
	item.custom_minimum_size = Vector2(0, height)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand:
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return item


static func hbox(separation: int = AppTheme.SPACING_SM) -> HBoxContainer:
	var item := HBoxContainer.new()
	item.add_theme_constant_override(&"separation", separation)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item


static func vbox(separation: int = AppTheme.SPACING_SM) -> VBoxContainer:
	var item := VBoxContainer.new()
	item.add_theme_constant_override(&"separation", separation)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item


static func stars(count: int, size: int = 30) -> HBoxContainer:
	var row := hbox(2)
	for i in Progress.MAX_STARS:
		var filled := i < count
		row.add_child(icon(Icons.STAR if filled else Icons.STAR_EMPTY, AppTheme.GOLD if filled else AppTheme.OUTLINE, size))
	return row


static func progress_bar(color: Color, height: float = 12.0) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, height)
	bar.max_value = 1.0
	bar.step = 0.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override(&"background", AppTheme.box(Color(0, 0, 0, 0.5), AppTheme.RADIUS_PILL))
	bar.add_theme_stylebox_override(&"fill", AppTheme.box(color, AppTheme.RADIUS_PILL))
	return bar
