class_name EnemyPainter
extends RefCounted

const SHAPE_BUG := "bug"
const SHAPE_WASP := "wasp"
const SHAPE_BAT := "bat"
const SHAPE_SOLDIER := "soldier"
const SHAPE_TANK := "tank"
const SHAPE_DRONE := "drone"

const EYES_HEAD := "head"
const EYES_FACE := "face"
const EYES_NONE := "none"

const FALLBACK_LOOK := "crawler"
const BONE := Color("#e8d8c0")
const GUN := Color("#1b1b1b")
const GLOW := Color("#ff4d6d")
const BOSS_RING := 1.4
const BOSS_ARCS := 4

const LOOKS := {
	"crawler": {"shape": SHAPE_BUG, "body": AppTheme.BUG_RED, "shell": AppTheme.BUG_DARK, "legs": 3},
	"larva": {"shape": SHAPE_BUG, "body": Color("#c9d36a"), "shell": Color("#8a9a3a"), "legs": 2, "scale": 0.9},
	"mauler": {"shape": SHAPE_BUG, "body": Color("#a8552a"), "shell": Color("#6b2f14"), "legs": 4, "horns": 2},
	"beetle": {"shape": SHAPE_BUG, "body": AppTheme.BEETLE, "shell": AppTheme.BEETLE_SHELL, "legs": 3, "plates": 1},
	"stalker": {"shape": SHAPE_BUG, "body": AppTheme.STALKER, "shell": AppTheme.STALKER_SHELL, "legs": 4, "fangs": true},
	"ravager": {"shape": SHAPE_BUG, "body": Color("#3d1f2a"), "shell": Color("#8a2438"), "legs": 4, "spikes": 3, "fangs": true, "scale": 1.05},
	"spitter": {"shape": SHAPE_BUG, "body": AppTheme.SPITTER, "shell": Color("#4c6a24"), "legs": 3, "spit": Color("#d6ff7a")},
	"slinger": {"shape": SHAPE_BUG, "body": Color("#4f8a6a"), "shell": Color("#2c5a44"), "legs": 3, "horns": 1, "spit": Color("#9af0c8")},
	"wasp": {"shape": SHAPE_WASP, "body": AppTheme.WASP, "shell": AppTheme.WASP_DARK, "wings": 1, "stripes": 2},
	"gnat": {"shape": SHAPE_WASP, "body": Color("#9fe05a"), "shell": Color("#2f4a14"), "wings": 1, "stripes": 1, "scale": 0.8},
	"nightwing": {"shape": SHAPE_BAT, "body": AppTheme.NIGHTWING, "shell": AppTheme.NIGHTWING_WING},
	"behemoth": {"shape": SHAPE_BUG, "body": AppTheme.BEHEMOTH, "shell": Color("#8a3a2a"), "legs": 4, "spikes": 5},
	"juggernaut": {"shape": SHAPE_BUG, "body": Color("#3a3f4a"), "shell": Color("#7a8394"), "legs": 4, "plates": 4, "horns": 2},
	"broodmother": {"shape": SHAPE_BUG, "body": Color("#6a2a7a"), "shell": Color("#a64bbf"), "legs": 6, "spikes": 3, "spit": Color("#f0a0ff")},
	"dreadwing": {"shape": SHAPE_BAT, "body": Color("#5a1a3a"), "shell": Color("#c0305a"), "spikes": 3, "scale": 1.15},
	"soldier": {"shape": SHAPE_SOLDIER, "body": AppTheme.SOLDIER, "shell": AppTheme.SOLDIER_HELMET, "gun": 1.0},
	"raider": {"shape": SHAPE_SOLDIER, "body": AppTheme.RAIDER, "shell": AppTheme.RAIDER_HELMET, "gun": 1.0, "mark": AppTheme.DANGER},
	"sniper": {"shape": SHAPE_SOLDIER, "body": Color("#3a4a3f"), "shell": Color("#1f2a22"), "gun": 2.2, "mark": Color("#ffd24d")},
	"sprinter": {"shape": SHAPE_SOLDIER, "body": Color("#c47a2a"), "shell": Color("#7a4a14"), "gun": 0.0, "scale": 0.9, "mark": Color("#fff0c0")},
	"saboteur": {"shape": SHAPE_SOLDIER, "body": AppTheme.SABOTEUR, "shell": Color("#16161f"), "gun": 0.0, "mark": Color("#c070ff")},
	"breacher": {"shape": SHAPE_SOLDIER, "body": Color("#6a3a3a"), "shell": Color("#3a1f1f"), "gun": 0.0, "plates": 3, "scale": 1.1},
	"brute": {"shape": SHAPE_SOLDIER, "body": Color("#4a4f58"), "shell": Color("#2a2d33"), "gun": 0.0, "plates": 4, "scale": 1.2},
	"colossus": {"shape": SHAPE_SOLDIER, "body": Color("#2f2f36"), "shell": Color("#6b6b78"), "gun": 0.0, "plates": 6, "mark": AppTheme.DANGER},
	"reaper": {"shape": SHAPE_BUG, "body": Color("#2a0f14"), "shell": Color("#c0222e"), "legs": 6, "horns": 2, "fangs": true},
	"drone": {"shape": SHAPE_DRONE, "body": AppTheme.DRONE, "shell": AppTheme.DRONE, "rotors": 4},
	"phantom": {"shape": SHAPE_DRONE, "body": AppTheme.DRONE, "shell": AppTheme.DRONE, "rotors": 4, "core": AppTheme.IMMUNE},
	"gunship": {"shape": SHAPE_DRONE, "body": Color("#4a525e"), "shell": Color("#2b3140"), "rotors": 6, "gun": 1.2, "plates": 2},
	"tank": {"shape": SHAPE_TANK, "body": AppTheme.TANK, "shell": AppTheme.TANK_DARK, "barrels": 1},
	"artillery": {"shape": SHAPE_TANK, "body": Color("#6a5a3a"), "shell": Color("#3a321f"), "barrels": 1, "barrel": 2.3},
	"warlord": {"shape": SHAPE_TANK, "body": Color("#6a2f2f"), "shell": Color("#3a1818"), "barrels": 2, "plates": 2},
}


static func look_of(kind: String) -> Dictionary:
	return _look(GameConfig.enemy(kind), kind)


static func _look(definition: Dictionary, kind: String) -> Dictionary:
	return LOOKS.get(definition.get("look", kind), LOOKS[FALLBACK_LOOK])


static func paint(ci: CanvasItem, kind: String, center: Vector2, radius: float, heading: Vector2, time: float, night: float) -> void:
	var definition := GameConfig.enemy(kind)
	var look := _look(definition, kind)
	var size := radius * float(look.get("scale", 1.0))
	var air: bool = definition.get("class", "") == GameConfig.CLASS_AIR
	Painter.shadow(ci, center, size, 3.0 if air else 1.0)
	if bool(definition.get("boss", false)):
		_boss_ring(ci, center, size, time)
	ci.draw_set_transform(center, heading.angle(), Vector2.ONE)
	match str(look.shape):
		SHAPE_BUG:
			_bug(ci, size, time, look)
		SHAPE_WASP:
			_wasp(ci, size, time, look)
		SHAPE_BAT:
			_bat(ci, size, time, look)
		SHAPE_SOLDIER:
			_soldier(ci, size, look)
		SHAPE_TANK:
			_tank(ci, size, look)
		SHAPE_DRONE:
			_drone(ci, size, time, look)
	_eyes(ci, size, str(look.shape), night)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


static func _boss_ring(ci: CanvasItem, center: Vector2, size: float, time: float) -> void:
	var pulse := 0.55 + 0.25 * sin(time * 4.0)
	ci.draw_arc(center, size * BOSS_RING, 0.0, TAU, 28, Color(AppTheme.DANGER, pulse * 0.6), 2.0, true)
	for i in BOSS_ARCS:
		var from := time * 0.8 + TAU * i / BOSS_ARCS
		ci.draw_arc(center, size * (BOSS_RING + 0.18), from, from + TAU / 10.0, 6, Color(AppTheme.GOLD, pulse), 3.0, true)


static func _eyes(ci: CanvasItem, size: float, shape: String, night: float) -> void:
	var mode := _eye_mode(shape)
	if mode == EYES_NONE:
		return
	var eye_color := Color(1.0, 0.85, 0.2).lerp(Color(1.0, 0.25, 0.2), night)
	var eye_x := size * (0.95 if mode == EYES_HEAD else 0.35)
	for side in [-1.0, 1.0]:
		var eye := Vector2(eye_x, side * size * 0.22)
		if night > 0.2:
			ci.draw_circle(eye, size * 0.3, Color(eye_color, 0.25 * night))
		ci.draw_circle(eye, maxf(size * 0.1, 1.5), eye_color)


static func _eye_mode(shape: String) -> String:
	match shape:
		SHAPE_BUG, SHAPE_WASP, SHAPE_BAT:
			return EYES_HEAD
		SHAPE_SOLDIER:
			return EYES_FACE
	return EYES_NONE


static func _bug(ci: CanvasItem, size: float, time: float, look: Dictionary) -> void:
	var body: Color = look.body
	var shell: Color = look.shell
	var legs := int(look.get("legs", 3))
	var swing := sin(time * 18.0) * size * 0.25
	for i in legs:
		var x := size * (0.5 - float(i) / maxf(legs - 1, 1))
		var phase := swing if i % 2 == 0 else -swing
		ci.draw_line(Vector2(x, 0), Vector2(x + phase, size * 1.15), body.darkened(0.4), 2.5)
		ci.draw_line(Vector2(x, 0), Vector2(x - phase, -size * 1.15), body.darkened(0.4), 2.5)
	ci.draw_colored_polygon(Painter.ellipse(Vector2(-size * 0.15, 0), Vector2(size, size * 0.8)), body)
	ci.draw_colored_polygon(Painter.ellipse(Vector2(-size * 0.2, 0), Vector2(size * 0.75, size * 0.6)), shell)
	ci.draw_circle(Vector2(size * 0.8, 0), size * 0.45, body.darkened(0.35))
	_stripes(ci, size, int(look.get("plates", 0)), shell.darkened(0.45))
	_spikes(ci, size, int(look.get("spikes", 0)))
	_horns(ci, size, int(look.get("horns", 0)))
	if bool(look.get("fangs", false)):
		_fangs(ci, size)
	if look.has("spit"):
		ci.draw_circle(Vector2(size * 1.05, 0), size * 0.3, look.spit)


static func _stripes(ci: CanvasItem, size: float, count: int, color: Color) -> void:
	for i in count:
		var x := -size * 0.75 + size * 1.3 * (i + 0.5) / count
		ci.draw_line(Vector2(x, -size * 0.55), Vector2(x, size * 0.55), color, 2.0)


static func _spikes(ci: CanvasItem, size: float, count: int) -> void:
	for i in count:
		var spike := Vector2.from_angle(PI * 0.6 + PI * 0.8 * i / maxf(count - 1, 1)) * size
		var side := spike.orthogonal().normalized() * 5.0
		ci.draw_colored_polygon(PackedVector2Array([spike * 0.8 + side, spike * 1.35, spike * 0.8 - side]), BONE)


static func _horns(ci: CanvasItem, size: float, count: int) -> void:
	for i in count:
		var side := -1.0 if i % 2 == 0 else 1.0
		var base := Vector2(size * 1.0, side * size * 0.2)
		var tip := Vector2(size * 1.65, side * size * (0.35 + 0.15 * (i / 2)))
		ci.draw_colored_polygon(PackedVector2Array([base + Vector2(0, -3), tip, base + Vector2(0, 3)]), BONE)


static func _fangs(ci: CanvasItem, size: float) -> void:
	for side in [-1.0, 1.0]:
		ci.draw_line(Vector2(size * 0.9, side * size * 0.3), Vector2(size * 1.5, side * size * 0.55), Color("#e8d8f0"), 2.5)


static func _wasp(ci: CanvasItem, size: float, time: float, look: Dictionary) -> void:
	var flap := 0.5 + 0.5 * absf(sin(time * 40.0))
	var pairs := int(look.get("wings", 1))
	for pair in pairs:
		for side in [-1.0, 1.0]:
			var wing := Painter.ellipse(Vector2(-size * 0.3 * pair, side * size * 0.9), Vector2(size * 0.7, size * 0.9 * flap))
			ci.draw_colored_polygon(wing, Color(0.9, 0.95, 1.0, 0.45))
	ci.draw_colored_polygon(Painter.ellipse(Vector2(-size * 0.3, 0), Vector2(size * 1.1, size * 0.55)), look.body)
	for i in int(look.get("stripes", 2)):
		var x := -size * (0.1 + i * 0.5)
		ci.draw_line(Vector2(x, -size * 0.5), Vector2(x, size * 0.5), look.shell, 3.0)
	ci.draw_circle(Vector2(size * 0.75, 0), size * 0.45, look.shell)


static func _bat(ci: CanvasItem, size: float, time: float, look: Dictionary) -> void:
	var flap := 0.6 + 0.4 * sin(time * 16.0)
	for side in [-1.0, 1.0]:
		var tip := Vector2(-size * 0.2, side * size * 1.9 * flap)
		var wing := PackedVector2Array([Vector2(size * 0.3, side * size * 0.2), tip, Vector2(-size * 0.9, side * size * 0.9 * flap), Vector2(-size * 0.5, side * size * 0.2)])
		ci.draw_colored_polygon(wing, look.shell)
	ci.draw_colored_polygon(Painter.ellipse(Vector2(-size * 0.1, 0), Vector2(size * 0.8, size * 0.45)), look.body)
	ci.draw_circle(Vector2(size * 0.7, 0), size * 0.4, Color(look.body).darkened(0.3))
	for i in int(look.get("spikes", 0)):
		var x := -size * 0.8 + size * 0.35 * i
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, -size * 0.2), Vector2(x - size * 0.3, 0), Vector2(x, size * 0.2)]), BONE)


static func _soldier(ci: CanvasItem, size: float, look: Dictionary) -> void:
	var body: Color = look.body
	var helmet: Color = look.shell
	ci.draw_colored_polygon(Painter.ellipse(Vector2.ZERO, Vector2(size * 0.7, size * 1.1)), body)
	for i in int(look.get("plates", 0)):
		var y := -size * 0.9 + size * 1.8 * (i + 0.5) / int(look.plates)
		ci.draw_line(Vector2(-size * 0.45, y), Vector2(size * 0.45, y), helmet.lightened(0.25), 3.0)
	var gun := float(look.get("gun", 0.0))
	if gun > 0.0:
		ci.draw_line(Vector2(size * 0.2, size * 0.45), Vector2(size * (0.2 + 1.3 * gun), size * 0.45), GUN, 3.5)
	ci.draw_circle(Vector2.ZERO, size * 0.6, helmet)
	ci.draw_circle(Vector2(-size * 0.1, -size * 0.1), size * 0.2, helmet.lightened(0.2))
	if look.has("mark"):
		ci.draw_line(Vector2(size * 0.2, -size * 0.3), Vector2(size * 0.5, -size * 0.3), look.mark, 3.0)


static func _tank(ci: CanvasItem, size: float, look: Dictionary) -> void:
	var hull := Vector2(size * 1.25, size * 0.95)
	var dark: Color = look.shell
	var body: Color = look.body
	ci.draw_rect(Rect2(-hull.x, -hull.y - 4.0, hull.x * 2.0, 8.0), dark)
	ci.draw_rect(Rect2(-hull.x, hull.y - 4.0, hull.x * 2.0, 8.0), dark)
	ci.draw_rect(Rect2(-hull.x * 0.95, -hull.y * 0.8, hull.x * 1.9, hull.y * 1.6), body)
	var plates := int(look.get("plates", 0))
	for i in plates:
		var x := -hull.x * 0.7 + hull.x * 1.4 * (i + 0.5) / plates
		ci.draw_rect(Rect2(x - 3.0, -hull.y * 0.8, 6.0, hull.y * 1.6), dark.lightened(0.15))
	var barrels := int(look.get("barrels", 1))
	var length := size * 1.7 * float(look.get("barrel", 1.0))
	for i in barrels:
		var y := 0.0 if barrels == 1 else lerpf(-size * 0.3, size * 0.3, float(i) / (barrels - 1))
		ci.draw_line(Vector2(0, y), Vector2(length, y), Color("#22261a"), 6.0 if barrels == 1 else 4.0)
	ci.draw_circle(Vector2.ZERO, size * 0.55, body.lightened(0.15))
	ci.draw_circle(Vector2(-size * 0.1, 0), size * 0.2, GLOW)


static func _drone(ci: CanvasItem, size: float, time: float, look: Dictionary) -> void:
	var body: Color = look.body
	var rotors := int(look.get("rotors", 4))
	for i in rotors:
		var arm := Vector2.from_angle(TAU * (i + 0.5) / rotors) * size * 0.95
		ci.draw_line(Vector2.ZERO, arm, body.darkened(0.4), 3.0)
		ci.draw_circle(arm, size * 0.5, Color(0.85, 0.9, 1.0, 0.25 + 0.15 * absf(sin(time * 50.0 + i))))
	ci.draw_rect(Rect2(-size * 0.55, -size * 0.45, size * 1.1, size * 0.9), body)
	var plates := int(look.get("plates", 0))
	for i in plates:
		var y := -size * 0.3 + size * 0.6 * i / maxf(plates - 1, 1)
		ci.draw_line(Vector2(-size * 0.5, y), Vector2(size * 0.5, y), Color(look.shell).lightened(0.2), 2.0)
	var gun := float(look.get("gun", 0.0))
	if gun > 0.0:
		ci.draw_line(Vector2(size * 0.3, 0), Vector2(size * (0.3 + gun), 0), GUN, 3.5)
	ci.draw_circle(Vector2(size * 0.35, 0), size * 0.2, GLOW)
	if look.has("core"):
		ci.draw_circle(Vector2.ZERO, size * 0.35, Color(look.core, 0.8))
