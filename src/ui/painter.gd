class_name Painter
extends RefCounted

const SHADOW_OFFSET := Vector2(4, 7)
const ELLIPSE_POINTS := 20


static func ellipse(center: Vector2, radii: Vector2, points: int = ELLIPSE_POINTS) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in points:
		var angle := TAU * i / points
		result.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return result


static func polygon(center: Vector2, radius: float, sides: int, rotation: float = 0.0) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in sides:
		result.append(center + Vector2.from_angle(rotation + TAU * i / sides) * radius)
	return result


static func glow(ci: CanvasItem, center: Vector2, radius: float, color: Color, strength: float = 1.0) -> void:
	ci.draw_circle(center, radius * 2.2, Color(color, 0.07 * strength))
	ci.draw_circle(center, radius * 1.5, Color(color, 0.16 * strength))
	ci.draw_circle(center, radius, Color(color, 0.9 * strength))
	ci.draw_circle(center, radius * 0.45, Color(AppTheme.ENERGY_CORE, strength))


static func shadow(ci: CanvasItem, center: Vector2, radius: float, lift: float = 1.0) -> void:
	ci.draw_colored_polygon(ellipse(center + SHADOW_OFFSET * lift, Vector2(radius, radius * 0.75)), AppTheme.SHADOW)


static func bar(ci: CanvasItem, center: Vector2, width: float, ratio: float, color: Color, height: float = 6.0) -> void:
	var origin := center - Vector2(width * 0.5, height * 0.5)
	ci.draw_rect(Rect2(origin - Vector2(2, 2), Vector2(width + 4, height + 4)), Color(0, 0, 0, 0.65))
	ci.draw_rect(Rect2(origin, Vector2(width * clampf(ratio, 0.0, 1.0), height)), color)


static func hp_color(ratio: float) -> Color:
	return AppTheme.HP_LOW.lerp(AppTheme.HP_GOOD, clampf(ratio * 1.4 - 0.2, 0.0, 1.0))


static func building(ci: CanvasItem, kind: String, center: Vector2, radius: float, time: float, fill: float = 0.0, aim: float = -PI / 2.0, light: float = 1.0) -> void:
	match kind:
		GameConfig.CORE:
			_core(ci, center, radius, time, fill)
		GameConfig.SOLAR:
			_solar(ci, center, radius, time, light)
		GameConfig.RELAY:
			_relay(ci, center, radius, time, fill)
		GameConfig.BATTERY:
			_battery(ci, center, radius, fill)
		GameConfig.ZAPPER:
			_zapper(ci, center, radius, time, fill)
		GameConfig.LASER:
			_laser(ci, center, radius, aim, fill)
		GameConfig.TESLA:
			_tesla(ci, center, radius, time, fill)
		GameConfig.PLASMA:
			_plasma(ci, center, radius, aim, fill)
		GameConfig.SHIELD:
			_shield(ci, center, radius, time, fill)
		GameConfig.EXPORTER:
			_exporter(ci, center, radius, time, fill)
		GameConfig.WATER:
			_water(ci, center, radius, time)
		GameConfig.FIRE:
			_fire(ci, center, radius, time, fill)
		GameConfig.LAMP:
			_lamp(ci, center, radius, time, fill)
		GameConfig.HEALER:
			_healer(ci, center, radius, time, fill)
		GameConfig.BULWARK:
			_bulwark(ci, center, radius, time, fill)
		GameConfig.BASTION:
			_bastion(ci, center, radius, time, aim, fill)
		GameConfig.ROVER:
			_rover(ci, center, radius, time, aim, fill)
		GameConfig.NEST:
			_nest(ci, center, radius, time)
		GameConfig.CAMP:
			_camp(ci, center, radius, time)
		GameConfig.TURRET:
			_turret(ci, center, radius, aim)


static func _base(ci: CanvasItem, center: Vector2, radius: float, sides: int = 8) -> void:
	shadow(ci, center, radius)
	ci.draw_colored_polygon(polygon(center, radius, sides, PI / sides), AppTheme.METAL_DEEP)
	ci.draw_colored_polygon(polygon(center, radius * 0.84, sides, PI / sides), AppTheme.METAL_DARK)


static func _core(ci: CanvasItem, center: Vector2, radius: float, time: float, fill: float) -> void:
	shadow(ci, center, radius)
	ci.draw_colored_polygon(polygon(center, radius, 6, PI / 6.0), AppTheme.METAL_DEEP)
	ci.draw_colored_polygon(polygon(center, radius * 0.86, 6, PI / 6.0), AppTheme.METAL_DARK)
	var outline := polygon(center, radius * 0.86, 6, PI / 6.0)
	outline.append(outline[0])
	ci.draw_polyline(outline, Color(AppTheme.ENERGY, 0.8), 3.0, true)
	ci.draw_arc(center, radius * 0.62, -PI / 2.0, -PI / 2.0 + TAU * clampf(fill, 0.0, 1.0), 40, AppTheme.ENERGY, 5.0, true)
	var pulse := 1.0 + 0.08 * sin(time * 4.0)
	glow(ci, center, radius * 0.34 * pulse, AppTheme.ENERGY)


static func _solar(ci: CanvasItem, center: Vector2, radius: float, time: float, light: float) -> void:
	shadow(ci, center, radius)
	var half := radius * 0.9
	ci.draw_rect(Rect2(center - Vector2(half, half), Vector2(half, half) * 2.0), AppTheme.METAL_DARK)
	var inner := half * 0.86
	ci.draw_rect(Rect2(center - Vector2(inner, inner), Vector2(inner, inner) * 2.0), AppTheme.SOLAR_CELL.lerp(Color("#3d74d9"), light * 0.5))
	var line := Color(AppTheme.SOLAR_LINE, 0.55)
	for i in range(1, 3):
		var offset := -inner + inner * 2.0 * i / 3.0
		ci.draw_line(center + Vector2(offset, -inner), center + Vector2(offset, inner), line, 1.5)
		ci.draw_line(center + Vector2(-inner, offset), center + Vector2(inner, offset), line, 1.5)
	if light > 0.05:
		var sweep := fposmod(time * 0.35 + center.x * 0.001, 1.0) * 2.0 - 0.5
		var a := center + Vector2(-inner + inner * 2.0 * sweep, -inner)
		ci.draw_line(a, a + Vector2(-inner * 0.6, inner * 2.0).limit_length(inner * 1.2), Color(1, 1, 1, 0.35 * light), 4.0)
		ci.draw_circle(center + Vector2(inner, -inner) * 0.7, 3.0, Color(AppTheme.GOLD, light))


static func _relay(ci: CanvasItem, center: Vector2, radius: float, time: float, fill: float) -> void:
	shadow(ci, center, radius * 0.9)
	ci.draw_circle(center, radius, AppTheme.METAL_DEEP)
	for i in 3:
		var tip := center + Vector2.from_angle(-PI / 2.0 + TAU * i / 3.0) * radius
		ci.draw_line(center, tip, AppTheme.METAL, 4.0, true)
		ci.draw_circle(tip, 3.5, AppTheme.METAL)
	glow(ci, center, radius * (0.3 + 0.12 * fill) * (1.0 + 0.1 * sin(time * 6.0 + center.y)), AppTheme.ENERGY, 0.5 + fill * 0.5)


static func _battery(ci: CanvasItem, center: Vector2, radius: float, fill: float) -> void:
	shadow(ci, center, radius)
	var size := Vector2(radius * 1.3, radius * 1.85)
	var rect := Rect2(center - size * 0.5, size)
	ci.draw_rect(rect, AppTheme.METAL_DEEP)
	ci.draw_rect(Rect2(center + Vector2(-size.x * 0.22, -size.y * 0.5 - 6.0), Vector2(size.x * 0.44, 6.0)), AppTheme.METAL)
	var inner := rect.grow(-4.0)
	ci.draw_rect(inner, Color("#0d1a14"))
	var level := clampf(fill, 0.0, 1.0)
	var filled := Rect2(inner.position + Vector2(0, inner.size.y * (1.0 - level)), Vector2(inner.size.x, inner.size.y * level))
	ci.draw_rect(filled, AppTheme.SUCCESS.lerp(AppTheme.ENERGY, level * 0.4))
	for i in range(1, 4):
		var y := inner.position.y + inner.size.y * i / 4.0
		ci.draw_line(Vector2(inner.position.x, y), Vector2(inner.end.x, y), Color(0, 0, 0, 0.35), 2.0)
	ci.draw_rect(rect, AppTheme.METAL, false, 2.0)


static func _zapper(ci: CanvasItem, center: Vector2, radius: float, time: float, fill: float) -> void:
	_base(ci, center, radius)
	for i in 3:
		ci.draw_arc(center, radius * (0.72 - i * 0.14), 0.0, TAU, 24, Color(AppTheme.ENERGY, 0.25 + i * 0.15), 2.5, true)
	var flicker := 0.85 + 0.15 * sin(time * 23.0 + center.x)
	glow(ci, center, radius * 0.28 * flicker, AppTheme.building_color(GameConfig.ZAPPER), 0.35 + fill * 0.65)


static func _laser(ci: CanvasItem, center: Vector2, radius: float, aim: float, fill: float) -> void:
	_base(ci, center, radius, 6)
	var direction := Vector2.from_angle(aim)
	ci.draw_line(center, center + direction * radius * 1.15, AppTheme.METAL_DEEP, 10.0, true)
	ci.draw_line(center, center + direction * radius * 1.1, AppTheme.METAL, 6.0, true)
	ci.draw_circle(center, radius * 0.5, AppTheme.METAL)
	ci.draw_circle(center, radius * 0.32, AppTheme.METAL_DARK)
	glow(ci, center + direction * radius * 1.1, 4.0, AppTheme.building_color(GameConfig.LASER), 0.3 + fill * 0.7)


static func _tesla(ci: CanvasItem, center: Vector2, radius: float, time: float, fill: float) -> void:
	_base(ci, center, radius, 10)
	var color := AppTheme.building_color(GameConfig.TESLA)
	for i in 3:
		ci.draw_circle(center, radius * (0.7 - i * 0.16), color.darkened(0.55 - i * 0.15))
	if fill > 0.2:
		for i in 3:
			var angle := time * 7.0 + i * 2.1 + sin(time * 13.0 + i) * 0.8
			var from := center + Vector2.from_angle(angle) * radius * 0.25
			var to := center + Vector2.from_angle(angle + 0.4) * radius * 0.95
			ci.draw_line(from, to, Color(color.lightened(0.4), 0.8), 1.5, true)
	glow(ci, center, radius * 0.24, color, 0.4 + fill * 0.6)


static func _plasma(ci: CanvasItem, center: Vector2, radius: float, aim: float, fill: float) -> void:
	_base(ci, center, radius, 8)
	var direction := Vector2.from_angle(aim)
	var muzzle := center + direction * radius * 0.25
	ci.draw_circle(muzzle, radius * 0.55, AppTheme.METAL_DEEP)
	ci.draw_circle(muzzle, radius * 0.45, AppTheme.METAL)
	ci.draw_circle(muzzle, radius * 0.3, Color("#1a0d05"))
	ci.draw_circle(muzzle, radius * 0.22, Color(AppTheme.PLASMA_ORANGE, 0.3 + fill * 0.7))


static func _shield(ci: CanvasItem, center: Vector2, radius: float, time: float, fill: float) -> void:
	_base(ci, center, radius, 8)
	var color := AppTheme.SHIELD_BLUE
	ci.draw_circle(center, radius * 0.62, Color(color, 0.35 + 0.5 * fill))
	ci.draw_arc(center, radius * 0.62, -2.6, -1.0, 12, Color(1, 1, 1, 0.6), 3.0, true)
	ci.draw_arc(center, radius * 0.75, time * 2.0, time * 2.0 + PI * 0.6, 16, Color(color, 0.8), 2.0, true)


static func _exporter(ci: CanvasItem, center: Vector2, radius: float, time: float, fill: float) -> void:
	_base(ci, center, radius, 6)
	for i in 3:
		var tip := center + Vector2.from_angle(-PI / 2.0 + TAU * i / 3.0 + PI / 3.0) * radius * 0.78
		ci.draw_line(center, tip, AppTheme.METAL, 3.0, true)
	var spin := absf(cos(time * (1.5 + 3.0 * fill)))
	ci.draw_colored_polygon(ellipse(center, Vector2(radius * 0.5 * maxf(spin, 0.2), radius * 0.5), 16), AppTheme.GOLD_DARK)
	ci.draw_colored_polygon(ellipse(center, Vector2(radius * 0.38 * maxf(spin, 0.15), radius * 0.38), 16), AppTheme.GOLD.lerp(Color.WHITE, 0.2 * fill))
	ci.draw_arc(center, radius * 1.12, 0.0, TAU, 40, Color(AppTheme.METAL_DEEP, 0.85), 6.0, true)
	ci.draw_arc(center, radius * 1.12, -PI / 2.0, -PI / 2.0 + TAU * clampf(fill, 0.0, 1.0), 40, AppTheme.ENERGY, 6.0, true)


static func _water(ci: CanvasItem, center: Vector2, radius: float, time: float) -> void:
	_base(ci, center, radius, 8)
	ci.draw_circle(center, radius * 0.72, AppTheme.WATER_DEEP)
	ci.draw_circle(center, radius * 0.56, AppTheme.WATER)
	for i in 6:
		var angle := time * 1.8 + TAU * i / 6.0
		var tip := center + Vector2.from_angle(angle) * radius * 0.7
		ci.draw_line(center, tip, AppTheme.METAL, 3.0, true)
		ci.draw_circle(tip, 3.0, AppTheme.WATER_LIGHT)
	ci.draw_circle(center, radius * 0.18, AppTheme.METAL_DARK)


static func _fire(ci: CanvasItem, center: Vector2, radius: float, time: float, fill: float) -> void:
	shadow(ci, center, radius)
	ci.draw_colored_polygon(polygon(center, radius, 10, 0.0), AppTheme.ROCK_DARK)
	ci.draw_colored_polygon(polygon(center, radius * 0.78, 10, 0.0), AppTheme.ROCK)
	ci.draw_circle(center, radius * 0.6, AppTheme.METAL_DEEP)
	for i in 3:
		var angle := TAU * i / 3.0 + 0.4
		ci.draw_line(center + Vector2.from_angle(angle) * radius * 0.5, center - Vector2.from_angle(angle) * radius * 0.5, AppTheme.TRUNK, 5.0, true)
	if fill > 0.0:
		glow(ci, center, radius * 0.35, AppTheme.FLAME, 0.6 * fill)
		flames(ci, center + Vector2(0, -radius * 0.1), radius * 0.45, time, fill)
	else:
		ci.draw_circle(center, radius * 0.2, Color(AppTheme.FLAME, 0.25))


static func _lamp(ci: CanvasItem, center: Vector2, radius: float, time: float, fill: float) -> void:
	shadow(ci, center, radius * 0.7)
	ci.draw_circle(center, radius * 0.72, AppTheme.METAL_DEEP)
	ci.draw_circle(center, radius * 0.56, AppTheme.METAL_DARK)
	var lit := clampf(fill, 0.0, 1.0)
	var flicker := 1.0 + 0.04 * sin(time * 11.0 + center.x)
	ci.draw_circle(center, radius * 0.38, AppTheme.LAMP_OFF.lerp(AppTheme.LAMP_LIGHT, lit))
	if lit > 0.05:
		glow(ci, center, radius * 0.4 * flicker, AppTheme.LAMP_LIGHT, lit)


static func _healer(ci: CanvasItem, center: Vector2, radius: float, time: float, fill: float) -> void:
	_base(ci, center, radius, 8)
	var color := AppTheme.building_color(GameConfig.HEALER)
	var pulse := 1.0 + 0.08 * sin(time * 3.0)
	ci.draw_circle(center, radius * 0.6, AppTheme.METAL)
	ci.draw_circle(center, radius * 0.5, Color(color, 0.25 + 0.55 * fill))
	var arm := radius * 0.36 * pulse
	var width := radius * 0.16
	ci.draw_rect(Rect2(center - Vector2(arm, width), Vector2(arm * 2.0, width * 2.0)), Color.WHITE)
	ci.draw_rect(Rect2(center - Vector2(width, arm), Vector2(width * 2.0, arm * 2.0)), Color.WHITE)
	ci.draw_arc(center, radius * 0.72, time * 1.5, time * 1.5 + PI * 0.5, 12, Color(color, 0.8), 2.5, true)
	ci.draw_arc(center, radius * 0.72, time * 1.5 + PI, time * 1.5 + PI * 1.5, 12, Color(color, 0.8), 2.5, true)


static func _bastion(ci: CanvasItem, center: Vector2, radius: float, time: float, aim: float, fill: float) -> void:
	_base(ci, center, radius, 8)
	var color := AppTheme.building_color(GameConfig.BASTION)
	ci.draw_rect(Rect2(center - Vector2(radius * 0.78, radius * 0.78), Vector2(radius * 1.56, radius * 1.56)), AppTheme.METAL_DARK)
	ci.draw_circle(center, radius * 0.5, AppTheme.METAL)
	ci.draw_circle(center, radius * 0.34, Color(color, 0.25 + 0.55 * fill))
	ci.draw_line(center, center + Vector2.from_angle(aim) * radius * 1.0, AppTheme.METAL_DEEP, 5.0, true)
	ci.draw_arc(center, radius * 0.9, time, time + PI * 0.6, 12, Color(color, 0.8), 2.5, true)


static func _rover(ci: CanvasItem, center: Vector2, radius: float, time: float, aim: float, fill: float) -> void:
	shadow(ci, center, radius)
	var color := AppTheme.building_color(GameConfig.ROVER)
	for side in [-1.0, 1.0]:
		var track := Rect2(center + Vector2(-radius, side * radius * 0.62 - radius * 0.26), Vector2(radius * 2.0, radius * 0.52))
		ci.draw_rect(track, AppTheme.METAL_DEEP)
		for i in 5:
			var x := track.position.x + fposmod(time * 30.0 + i * radius * 0.4, radius * 2.0)
			ci.draw_line(Vector2(x, track.position.y), Vector2(x, track.end.y), AppTheme.METAL_DARK, 2.0)
	ci.draw_rect(Rect2(center - Vector2(radius * 0.8, radius * 0.5), Vector2(radius * 1.6, radius)), AppTheme.METAL_DARK)
	ci.draw_circle(center, radius * 0.48, AppTheme.METAL)
	ci.draw_line(center, center + Vector2.from_angle(aim) * radius * 1.05, AppTheme.METAL_DEEP, 6.0, true)
	glow(ci, center, radius * 0.22, color, 0.35 + fill * 0.65)


static func _bulwark(ci: CanvasItem, center: Vector2, radius: float, _time: float, _fill: float) -> void:
	var color := AppTheme.building_color(GameConfig.BULWARK)
	var half := Vector2(radius, radius)
	ci.draw_rect(Rect2(center - half + SHADOW_OFFSET * 0.6, half * 2.0), AppTheme.SHADOW)
	ci.draw_rect(Rect2(center - half, half * 2.0), AppTheme.METAL_DEEP)
	ci.draw_rect(Rect2(center - half * 0.86, half * 1.72), AppTheme.METAL_DARK)
	var brick := radius * 0.86
	for row in 2:
		var y := center.y - brick + brick * row
		ci.draw_line(Vector2(center.x - brick, y + brick), Vector2(center.x + brick, y + brick), AppTheme.METAL_DEEP, 2.0)
		var x := center.x + (brick * 0.5 if row == 0 else -brick * 0.5)
		ci.draw_line(Vector2(x, y), Vector2(x, y + brick), AppTheme.METAL_DEEP, 2.0)
	ci.draw_rect(Rect2(center - Vector2(radius * 0.86, radius * 0.86), Vector2(radius * 1.72, radius * 0.22)), Color(color, 0.85))
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		ci.draw_circle(center + corner * radius * 0.7, radius * 0.08, AppTheme.METAL)


static func _nest(ci: CanvasItem, center: Vector2, radius: float, time: float) -> void:
	shadow(ci, center, radius * 1.05)
	var points := PackedVector2Array()
	for i in 24:
		var angle := TAU * i / 24.0
		var wobble := 1.0 + 0.08 * sin(angle * 5.0 + time * 2.0) + 0.05 * sin(angle * 3.0 - time * 1.3)
		points.append(center + Vector2.from_angle(angle) * radius * wobble)
	ci.draw_colored_polygon(points, AppTheme.NEST_FLESH)
	ci.draw_circle(center, radius * 0.55, AppTheme.NEST_FLESH.darkened(0.3))
	ci.draw_circle(center, radius * 0.32, Color("#1a0612"))
	for i in 7:
		var angle := TAU * i / 7.0 + 0.4
		var spot := center + Vector2.from_angle(angle) * radius * 0.75
		var pulse := 0.5 + 0.5 * sin(time * 3.0 + i)
		ci.draw_circle(spot, radius * (0.09 + 0.04 * pulse), AppTheme.NEST_SPOT.lightened(pulse * 0.3))


static func creep_nest(ci: CanvasItem, center: Vector2, radius: float, time: float) -> void:
	shadow(ci, center, radius)
	var points := PackedVector2Array()
	for i in 20:
		var angle := TAU * i / 20.0
		var wobble := 1.0 + 0.1 * sin(angle * 4.0 + time * 2.4) + 0.06 * sin(angle * 7.0 - time * 1.7)
		points.append(center + Vector2.from_angle(angle) * radius * wobble)
	ci.draw_colored_polygon(points, AppTheme.SLIME_DEEP)
	ci.draw_circle(center, radius * 0.68, AppTheme.SLIME.darkened(0.25))
	ci.draw_circle(center, radius * 0.36, AppTheme.SLIME_DEEP.darkened(0.5))
	for i in 5:
		var angle := TAU * i / 5.0 + 0.3
		var pulse := 0.5 + 0.5 * sin(time * 3.2 + i * 1.3)
		ci.draw_circle(center + Vector2.from_angle(angle) * radius * 0.62, radius * (0.1 + 0.04 * pulse), AppTheme.SLIME.lightened(0.25 * pulse))


static func _camp(ci: CanvasItem, center: Vector2, radius: float, time: float) -> void:
	shadow(ci, center, radius)
	for i in 14:
		var bag := center + Vector2.from_angle(TAU * i / 14.0) * radius * 0.92
		ci.draw_colored_polygon(ellipse(bag, Vector2(9, 7)), AppTheme.CAMP_CANVAS.lightened(0.15 * (i % 2)))
	ci.draw_circle(center, radius * 0.8, Color("#4a4a30"))
	for offset: Vector2 in [Vector2(-0.35, -0.2), Vector2(0.35, -0.15), Vector2(0.0, 0.32)]:
		var tent := center + offset * radius
		var size := radius * 0.32
		ci.draw_colored_polygon(PackedVector2Array([tent + Vector2(-size, size * 0.7), tent + Vector2(size, size * 0.7), tent + Vector2(0, -size * 0.8)]), AppTheme.CAMP_CANVAS)
		ci.draw_line(tent + Vector2(0, -size * 0.8), tent + Vector2(0, size * 0.7), AppTheme.CAMP_DARK, 2.0)
	var pole := center + Vector2(radius * 0.05, -radius * 0.1)
	ci.draw_line(pole, pole + Vector2(0, -radius * 0.9), Color("#d8d0b0"), 3.0)
	var wave := sin(time * 5.0) * 4.0
	var top := pole + Vector2(0, -radius * 0.9)
	ci.draw_colored_polygon(PackedVector2Array([top, top + Vector2(radius * 0.5, 6 + wave), top + Vector2(0, 16)]), AppTheme.ENEMY_RED)


static func _turret(ci: CanvasItem, center: Vector2, radius: float, aim: float) -> void:
	shadow(ci, center, radius)
	ci.draw_colored_polygon(polygon(center, radius, 4, PI / 4.0), AppTheme.TANK_DARK)
	ci.draw_colored_polygon(polygon(center, radius * 0.8, 4, PI / 4.0), AppTheme.TANK)
	var direction := Vector2.from_angle(aim)
	ci.draw_line(center, center + direction * radius * 1.3, Color("#22261a"), 9.0, true)
	ci.draw_circle(center, radius * 0.5, AppTheme.ENEMY_RED.darkened(0.35))
	ci.draw_circle(center, radius * 0.22, AppTheme.ENEMY_RED)


static func enemy(ci: CanvasItem, kind: String, center: Vector2, radius: float, heading: Vector2, time: float, night: float) -> void:
	EnemyPainter.paint(ci, kind, center, radius, heading, time, night)


static func flames(ci: CanvasItem, center: Vector2, radius: float, time: float, strength: float = 1.0) -> void:
	for i in 5:
		var phase := time * 9.0 + i * 1.7
		var sway := sin(phase) * radius * 0.25
		var base := center + Vector2((float(i) - 2.0) * radius * 0.35, radius * 0.3)
		var height := radius * (1.1 + 0.5 * absf(sin(phase * 1.3))) * strength
		var tongue := PackedVector2Array([base + Vector2(-radius * 0.28, 0), base + Vector2(sway, -height), base + Vector2(radius * 0.28, 0)])
		ci.draw_colored_polygon(tongue, Color(AppTheme.FLAME, 0.85))
		ci.draw_colored_polygon(PackedVector2Array([tongue[0].lerp(tongue[2], 0.3), base.lerp(tongue[1], 0.6), tongue[0].lerp(tongue[2], 0.7)]), Color(AppTheme.FLAME_CORE, 0.9))


static func guard(ci: CanvasItem, center: Vector2, radius: float, time: float) -> void:
	var ring := radius + 6.0
	for i in 4:
		var from := time * 1.6 + TAU * i / 4.0
		ci.draw_arc(center, ring, from, from + TAU / 7.0, 6, Color(AppTheme.WARNING, 0.75), 2.5, true)
	var tip := center + Vector2(0, -ring - 7.0)
	ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(-5, -4), tip + Vector2(5, -4), tip + Vector2(0, 3)]), AppTheme.WARNING)


static func scout(ci: CanvasItem, center: Vector2, heading: Vector2, time: float, drop: float, working: bool) -> void:
	var altitude := drop * 150.0
	var scale := 1.0 + drop * 0.5
	var radius := GameConfig.SCOUT_RADIUS * scale
	ci.draw_colored_polygon(ellipse(center + SHADOW_OFFSET * 0.5, Vector2(radius, radius * 0.7) * (1.0 - drop * 0.5)), Color(AppTheme.SHADOW, AppTheme.SHADOW.a * (1.0 - drop * 0.6)))
	var body := center - Vector2(0, altitude)
	if drop > 0.0:
		var sway := sin(time * 2.5) * 6.0 * drop
		var canopy := body + Vector2(sway, -radius * 4.2)
		var width := radius * 3.4
		for side in [-1.0, 1.0]:
			ci.draw_line(body, canopy + Vector2(side * width * 0.9, 0), Color(1, 1, 1, 0.7), 1.5, true)
		ci.draw_colored_polygon(ellipse(canopy, Vector2(width, width * 0.55), 24).slice(12, 24) + PackedVector2Array([canopy + Vector2(width, 0)]), AppTheme.CHUTE)
		for i in 3:
			var x := canopy.x - width * 0.6 + width * 0.6 * i
			ci.draw_line(Vector2(x, canopy.y), Vector2(canopy.x + (x - canopy.x) * 0.4, canopy.y - width * 0.5), AppTheme.CHUTE_STRIPE, 2.0, true)
	ci.draw_set_transform(body, heading.angle(), Vector2(scale, scale))
	var r := GameConfig.SCOUT_RADIUS
	ci.draw_colored_polygon(ellipse(Vector2.ZERO, Vector2(r * 0.7, r * 1.1)), AppTheme.SCOUT)
	var tool := Vector2(r * 1.4, r * 0.45)
	if working:
		tool = tool.rotated(sin(time * 14.0) * 0.6)
	ci.draw_line(Vector2(r * 0.2, r * 0.45), tool, Color("#1b1b1b"), 3.5)
	ci.draw_circle(Vector2.ZERO, r * 0.6, AppTheme.SCOUT_DARK)
	ci.draw_circle(Vector2(-r * 0.1, -r * 0.1), r * 0.22, AppTheme.ENERGY)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


static func coin(ci: CanvasItem, center: Vector2, radius: float, time: float) -> void:
	var squash := absf(cos(time * 6.0))
	ci.draw_circle(center + Vector2(2, 4), radius, AppTheme.SHADOW)
	ci.draw_colored_polygon(ellipse(center, Vector2(radius * maxf(squash, 0.25), radius), 14), AppTheme.GOLD_DARK)
	ci.draw_colored_polygon(ellipse(center, Vector2(radius * maxf(squash, 0.2) * 0.75, radius * 0.75), 14), AppTheme.GOLD)
	ci.draw_circle(center + Vector2(-radius * 0.25 * squash, -radius * 0.3), radius * 0.18, Color(1, 1, 1, 0.8))
