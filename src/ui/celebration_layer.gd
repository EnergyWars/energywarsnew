class_name CelebrationLayer
extends Control

signal coin_arrived(value: int)

const COIN_TIME := 0.55
const MAX_COINS := 40
const CONFETTI_GRAVITY := 900.0
const MAX_CONFETTI := 260

var coins: Array[Dictionary] = []
var confetti: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rng.seed = 99


func fly_coin(from: Vector2, to: Vector2, value: int) -> void:
	if coins.size() >= MAX_COINS:
		var oldest: Dictionary = coins.pop_front()
		coin_arrived.emit(int(oldest.value))
	var control := from + Vector2(rng.randf_range(-80.0, 80.0), rng.randf_range(-120.0, -20.0))
	coins.append({"from": from, "control": control, "to": to, "time": 0.0, "value": value})


func burst_confetti(origin: Vector2, count: int, spread: float = 900.0) -> void:
	var colors := AppTheme.confetti_colors()
	for i in count:
		if confetti.size() >= MAX_CONFETTI:
			confetti.pop_front()
		var angle := rng.randf_range(-PI * 0.95, -PI * 0.05)
		confetti.append({"position": origin, "velocity": Vector2.from_angle(angle) * rng.randf_range(spread * 0.3, spread),
			"color": colors[rng.randi() % colors.size()], "spin": rng.randf_range(-12.0, 12.0), "angle": rng.randf() * TAU,
			"life": rng.randf_range(1.4, 2.4), "size": rng.randf_range(6.0, 12.0)})


func _process(delta: float) -> void:
	var arrived := 0
	var remaining: Array[Dictionary] = []
	for coin in coins:
		coin.time += delta
		if coin.time >= COIN_TIME:
			arrived += int(coin.value)
		else:
			remaining.append(coin)
	coins = remaining
	if arrived > 0:
		coin_arrived.emit(arrived)
	var alive: Array[Dictionary] = []
	for piece in confetti:
		piece.life -= delta
		if piece.life <= 0.0:
			continue
		piece.velocity = piece.velocity * maxf(1.0 - 1.2 * delta, 0.0) + Vector2(0, CONFETTI_GRAVITY * delta)
		piece.position += piece.velocity * delta
		piece.angle += piece.spin * delta
		alive.append(piece)
	confetti = alive
	if not coins.is_empty() or not confetti.is_empty() or arrived > 0:
		queue_redraw()


func in_flight() -> int:
	var total := 0
	for coin in coins:
		total += int(coin.value)
	return total


static func bezier(from: Vector2, control: Vector2, to: Vector2, t: float) -> Vector2:
	var a := from.lerp(control, t)
	var b := control.lerp(to, t)
	return a.lerp(b, t)


func _draw() -> void:
	for coin in coins:
		var t := ease(clampf(coin.time / COIN_TIME, 0.0, 1.0), 2.2)
		var position := bezier(coin.from, coin.control, coin.to, t)
		var radius := lerpf(11.0, 8.0, t)
		draw_circle(position, radius * 1.8, Color(AppTheme.GOLD, 0.18))
		Painter.coin(self, position, radius, coin.time * 3.0)
	for piece in confetti:
		draw_set_transform(piece.position, piece.angle, Vector2.ONE)
		var size := float(piece.size)
		draw_rect(Rect2(-size * 0.5, -size * 0.25, size, size * 0.5), Color(piece.color, clampf(piece.life, 0.0, 1.0)))
	draw_set_transform_matrix(Transform2D.IDENTITY)
