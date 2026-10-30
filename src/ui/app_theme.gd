class_name AppTheme
extends RefCounted

const FONT_REGULAR: FontFile = preload("res://assets/fonts/Geist-Regular.ttf")
const FONT_SEMIBOLD: FontFile = preload("res://assets/fonts/Geist-SemiBold.ttf")
const FONT_BOLD: FontFile = preload("res://assets/fonts/Geist-Bold.ttf")
const FONT_ICONS: FontFile = preload("res://assets/fonts/MaterialIcons-Regular.ttf")

const BACKGROUND := Color("#0b1020")
const SURFACE := Color("#141b2e")
const SURFACE_VARIANT := Color("#1d2640")
const SURFACE_HIGH := Color("#28334f")
const OUTLINE := Color("#3a4770")
const ON_SURFACE := Color("#eef3ff")
const ON_SURFACE_VARIANT := Color("#a9b4d0")
const SCRIM := Color(0.02, 0.03, 0.08, 0.7)
const PANEL := Color(0.06, 0.08, 0.15, 0.9)

const ENERGY := Color("#3ee8ff")
const ENERGY_CORE := Color("#e6fdff")
const ENERGY_DIM := Color("#1b6b80")
const GOLD := Color("#ffc83d")
const GOLD_DARK := Color("#b8860b")
const DANGER := Color("#ff4d6d")
const SUCCESS := Color("#4be38a")
const WARNING := Color("#ffb020")
const VIOLET := Color("#b57bff")
const PLASMA_ORANGE := Color("#ff8a3d")
const SHIELD_BLUE := Color("#5aa9ff")
const HEAL := Color("#6dff9e")
const ON_ACCENT := Color("#08111f")
const PRIMARY_CONTAINER := Color("#0f3352")
const PRIMARY_OUTLINE := Color("#1d5f8a")

const GROUND := Color("#35502f")
const GROUND_LIGHT := Color("#42633a")
const GROUND_DARK := Color("#2a4126")
const GROUND_EDGE := Color("#1a2818")
const ROCK := Color("#6d717c")
const ROCK_LIGHT := Color("#8c909b")
const ROCK_DARK := Color("#4b4e57")
const GROUND_HIGH := Color("#5a6b3a")
const GROUND_HIGH_LIGHT := Color("#6b7d45")
const CLIFF := Color("#6e604c")
const CLIFF_DARK := Color("#3f362b")
const CLIFF_LIGHT := Color("#9a8a6e")
const CHASM := Color("#07090e")
const CHASM_MID := Color("#151a24")
const CHASM_EDGE := Color("#4a3c2c")
const WATER := Color("#2f6f9a")
const WATER_DEEP := Color("#1d4a72")
const WATER_LIGHT := Color("#9fdcff")
const WATER_SHORE := Color("#b5a27a")
const TREE_DARK := Color("#173a1f")
const TREE := Color("#25592c")
const TREE_LIGHT := Color("#3f8a3f")
const TRUNK := Color("#4a3522")
const FOG := Color("#04060b")
const SCOUT := Color("#3f6b8f")
const SCOUT_DARK := Color("#22394d")
const CHUTE := Color("#e8eef8")
const CHUTE_STRIPE := Color("#3ee8ff")
const SPITTER := Color("#7aa83a")
const DRONE := Color("#5d6470")
const METAL := Color("#8b97ad")
const METAL_DARK := Color("#4a5468")
const METAL_DEEP := Color("#2b3244")
const SOLAR_CELL := Color("#1f4fa8")
const SOLAR_LINE := Color("#7fb2ff")
const NEST_FLESH := Color("#7a2a5c")
const NEST_SPOT := Color("#d14b8f")
const SLIME := Color("#6fd63a")
const SLIME_DEEP := Color("#2f7a1c")
const CAMP_CANVAS := Color("#6b6a3e")
const CAMP_DARK := Color("#454428")
const ENEMY_RED := Color("#e0384f")
const BUG_RED := Color("#c2352c")
const BUG_DARK := Color("#6e1a14")
const BEETLE := Color("#4c3a6e")
const BEETLE_SHELL := Color("#7a5fb0")
const WASP := Color("#f0c330")
const WASP_DARK := Color("#3a2e10")
const BEHEMOTH := Color("#5a2a2a")
const SOLDIER := Color("#5c6b3a")
const SOLDIER_HELMET := Color("#3c4626")
const SABOTEUR := Color("#2c2c3a")
const TANK := Color("#55603a")
const TANK_DARK := Color("#343b22")
const STALKER := Color("#2a1838")
const STALKER_SHELL := Color("#5b2f7a")
const NIGHTWING := Color("#2b2140")
const NIGHTWING_WING := Color("#6a4a9a")
const RAIDER := Color("#2f3340")
const RAIDER_HELMET := Color("#1a1c24")
const PHANTOM := Color("#3a3550")
const FLAME := Color("#ff7a1a")
const FLAME_CORE := Color("#ffe27a")
const LAMP_LIGHT := Color("#ffe9a8")
const LAMP_OFF := Color("#5a5446")
const IMMUNE := Color("#b57bff")
const WORLD_SEA := Color("#0d1a33")
const WORLD_SEA_LIGHT := Color("#14274a")
const WORLD_LAND := Color("#2c4a2c")
const WORLD_LAND_LIGHT := Color("#3c6238")
const WORLD_COAST := Color("#c8b48a")
const SHADOW := Color(0.0, 0.0, 0.0, 0.3)
const HP_GOOD := Color("#4be38a")
const HP_LOW := Color("#ff4d6d")

const BUILDING_COLORS := {
	GameConfig.CORE: Color("#3ee8ff"),
	GameConfig.SOLAR: Color("#ffc83d"),
	GameConfig.RELAY: Color("#7fdfff"),
	GameConfig.BATTERY: Color("#4be38a"),
	GameConfig.ZAPPER: Color("#9ff3ff"),
	GameConfig.LASER: Color("#ff5d7a"),
	GameConfig.TESLA: Color("#b57bff"),
	GameConfig.PLASMA: Color("#ff8a3d"),
	GameConfig.SHIELD: Color("#5aa9ff"),
	GameConfig.EXPORTER: Color("#ffc83d"),
	GameConfig.WATER: Color("#4fb3ff"),
	GameConfig.FIRE: Color("#ff7a1a"),
	GameConfig.LAMP: Color("#ffe9a8"),
	GameConfig.HEALER: Color("#6dff9e"),
	GameConfig.BULWARK: Color("#ff9f43"),
	GameConfig.BASTION: Color("#ffb86b"),
	GameConfig.ROVER: Color("#c6ff5a"),
	GameConfig.NEST: Color("#d14b8f"),
	GameConfig.CAMP: Color("#c9b458"),
	GameConfig.TURRET: Color("#e0384f"),
}

const ENEMY_COLORS := {
	"crawler": Color("#ff5a4a"),
	"beetle": Color("#9b7bff"),
	"wasp": Color("#ffd23f"),
	"behemoth": Color("#ff3b3b"),
	"soldier": Color("#a8c060"),
	"saboteur": Color("#c070ff"),
	"tank": Color("#c8d070"),
	"spitter": Color("#a8e05a"),
	"drone": Color("#9fb0c8"),
	"stalker": Color("#a060e0"),
	"nightwing": Color("#8a6ad0"),
	"raider": Color("#8890b0"),
	"phantom": Color("#b090ff"),
}

const COMBO_COLORS: Array[Color] = [Color("#ffffff"), Color("#9ff3ff"), Color("#4be38a"), Color("#ffc83d"), Color("#ff8a3d"), Color("#ff4d6d"), Color("#b57bff"), Color("#ffffff")]

const RADIUS_CARD := 22
const RADIUS_BUTTON := 18
const RADIUS_PILL := 999

const SPACING_XS := 4
const SPACING_SM := 8
const SPACING_MD := 12
const SPACING_LG := 16
const SPACING_XL := 24

const SIZE_DISPLAY := 56
const SIZE_HEADLINE := 34
const SIZE_TITLE := 24
const SIZE_BODY := 19
const SIZE_SMALL := 16
const SIZE_TINY := 13
const SIZE_ICON := 26


static func building_color(kind: String) -> Color:
	return BUILDING_COLORS.get(kind, ENERGY)


static func enemy_color(kind: String) -> Color:
	return ENEMY_COLORS.get(kind, ENEMY_RED)


static func combo_color(tier: int) -> Color:
	return COMBO_COLORS[clampi(tier, 0, COMBO_COLORS.size() - 1)]


static func confetti_colors() -> Array[Color]:
	return [ENERGY, GOLD, SUCCESS, VIOLET, DANGER, PLASMA_ORANGE, ENERGY_CORE]


static func box(bg: Color, radius: int, border: Color = Color.TRANSPARENT, padding: int = 0, border_width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.corner_detail = 8
	style.anti_aliasing = true
	if border.a > 0.0:
		style.border_color = border
		style.set_border_width_all(border_width)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style


static func glow_box(bg: Color, radius: int, glow: Color, padding: int = 0) -> StyleBoxFlat:
	var style := box(bg, radius, glow, padding)
	style.shadow_color = Color(glow, 0.35)
	style.shadow_size = 10
	return style


static func build() -> Theme:
	for font: FontFile in [FONT_REGULAR, FONT_SEMIBOLD, FONT_BOLD]:
		if not font.fallbacks.has(FONT_ICONS):
			font.fallbacks = [FONT_ICONS]
	var theme := Theme.new()
	theme.default_font = FONT_REGULAR
	theme.default_font_size = SIZE_BODY
	_labels(theme)
	_buttons(theme)
	_panels(theme)
	return theme


static func _label(theme: Theme, name: String, font: Font, size: int, color: Color) -> void:
	theme.set_type_variation(name, "Label")
	theme.set_font(&"font", name, font)
	theme.set_font_size(&"font_size", name, size)
	theme.set_color(&"font_color", name, color)


static func _labels(theme: Theme) -> void:
	theme.set_color(&"font_color", "Label", ON_SURFACE)
	theme.set_color(&"font_outline_color", "Label", Color(0, 0, 0, 0.6))
	_label(theme, "Display", FONT_BOLD, SIZE_DISPLAY, ON_SURFACE)
	_label(theme, "Headline", FONT_BOLD, SIZE_HEADLINE, ON_SURFACE)
	_label(theme, "Title", FONT_SEMIBOLD, SIZE_TITLE, ON_SURFACE)
	_label(theme, "Body", FONT_REGULAR, SIZE_BODY, ON_SURFACE)
	_label(theme, "Caption", FONT_REGULAR, SIZE_SMALL, ON_SURFACE_VARIANT)
	_label(theme, "Tiny", FONT_SEMIBOLD, SIZE_TINY, ON_SURFACE_VARIANT)
	_label(theme, "Money", FONT_BOLD, SIZE_TITLE, GOLD)
	_label(theme, "Icon", FONT_ICONS, SIZE_ICON, ON_SURFACE)


static func _button_variant(theme: Theme, name: String, bg: Color, fg: Color, border: Color, radius: int = RADIUS_BUTTON) -> void:
	if name != "Button":
		theme.set_type_variation(name, "Button")
	var normal := box(bg, radius, border, SPACING_MD)
	normal.content_margin_top = SPACING_SM
	normal.content_margin_bottom = SPACING_SM
	theme.set_stylebox(&"normal", name, normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.08)
	theme.set_stylebox(&"hover", name, hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.15)
	theme.set_stylebox(&"pressed", name, pressed)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(bg, 0.35)
	disabled.border_color = Color(border, 0.3)
	theme.set_stylebox(&"disabled", name, disabled)
	theme.set_stylebox(&"focus", name, StyleBoxEmpty.new())
	theme.set_color(&"font_color", name, fg)
	theme.set_color(&"font_hover_color", name, fg)
	theme.set_color(&"font_pressed_color", name, fg)
	theme.set_color(&"font_focus_color", name, fg)
	theme.set_color(&"font_disabled_color", name, Color(fg, 0.45))
	theme.set_font(&"font", name, FONT_SEMIBOLD)
	theme.set_font_size(&"font_size", name, SIZE_BODY)


static func _buttons(theme: Theme) -> void:
	_button_variant(theme, "Button", SURFACE_VARIANT, ON_SURFACE, OUTLINE)
	_button_variant(theme, "PrimaryButton", PRIMARY_CONTAINER, ENERGY, PRIMARY_OUTLINE)
	_button_variant(theme, "GoldButton", GOLD, ON_ACCENT, Color("#fff1b8"))
	_button_variant(theme, "DangerButton", Color("#5a1a28"), Color("#ffd3dc"), DANGER)
	_button_variant(theme, "IconButton", Color(SURFACE_VARIANT, 0.85), ON_SURFACE, OUTLINE, RADIUS_PILL)
	theme.set_font(&"font", "IconButton", FONT_ICONS)
	theme.set_font_size(&"font_size", "IconButton", SIZE_ICON)


static func _panels(theme: Theme) -> void:
	theme.set_stylebox(&"panel", "PanelContainer", box(PANEL, RADIUS_CARD, OUTLINE, SPACING_LG))
	theme.set_type_variation("Card", "PanelContainer")
	theme.set_stylebox(&"panel", "Card", box(SURFACE, RADIUS_CARD, OUTLINE, SPACING_LG))
	theme.set_type_variation("Bar", "PanelContainer")
	theme.set_stylebox(&"panel", "Bar", box(PANEL, 0, Color.TRANSPARENT, SPACING_SM))
	theme.set_type_variation("Chip", "PanelContainer")
	theme.set_stylebox(&"panel", "Chip", box(Color(SURFACE_VARIANT, 0.9), RADIUS_PILL, OUTLINE, SPACING_SM))
	theme.set_stylebox(&"panel", "ScrollContainer", StyleBoxEmpty.new())
	theme.set_constant(&"separation", "HBoxContainer", SPACING_SM)
	theme.set_constant(&"separation", "VBoxContainer", SPACING_SM)
