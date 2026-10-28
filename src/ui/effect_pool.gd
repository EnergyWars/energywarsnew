class_name EffectPool
extends RefCounted

const MAX_PARTICLES := 400
const MAX_FLOATERS := 60
const MAX_SHAKE := 26.0
const SHAKE_DECAY := 2.6

var particles: Array[Dictionary] = []
var floaters: Array[Dictionary] = []
var bolts: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var trails: Array[Dictionary] = []
var shake := 0.0
var rng := RandomNumberGenerator.new()


func _init(seed_value: int = 1) -> void:
	rng.seed = seed_value


func burst(position: Vector2, color: Color, count: int, speed: float, size: float, life: float, gravity: float = 0.0) -> void:
	count = mini(count, MAX_PARTICLES - particles.size())
	for i in count:
		var velocity := Vector2.from_angle(rng.randf() * TAU) * speed * rng.randf_range(0.3, 1.0)
		particles.append({"position": position, "velocity": velocity, "life": life * rng.randf_range(0.6, 1.0), "max": life,
			"color": color, "size": size * rng.randf_range(0.6, 1.2), "gravity": gravity})


func floater(text: String, position: Vector2, color: Color, scale: float = 1.0, life: float = 0.9) -> void:
	if floaters.size() >= MAX_FLOATERS:
		floaters.pop_front()
	floaters.append({"text": text, "position": position + Vector2(rng.randf_range(-10.0, 10.0), 0.0), "life": life, "max": life, "color": color, "scale": scale})


func bolt(from: Vector2, to: Vector2, color: Color, width: float, life: float = 0.14, jitter: float = 18.0) -> void:
	bolts.append({"points": Lightning.path(from, to, jitter, rng), "life": life, "max": life, "color": color, "width": width})


func bolt_path(points: PackedVector2Array, color: Color, width: float, life: float = 0.18, jitter: float = 14.0) -> void:
	var path := PackedVector2Array()
	for i in points.size() - 1:
		var segment := Lightning.path(points[i], points[i + 1], jitter, rng)
		if i > 0:
			segment.remove_at(0)
		path.append_array(segment)
	bolts.append({"points": path, "life": life, "max": life, "color": color, "width": width})


func ring(position: Vector2, from_radius: float, to_radius: float, color: Color, life: float = 0.4, width: float = 4.0) -> void:
	rings.append({"position": position, "from": from_radius, "to": to_radius, "life": life, "max": life, "color": color, "width": width})


func tracer(from: Vector2, to: Vector2, color: Color, width: float = 3.0, life: float = 0.1) -> void:
	trails.append({"from": from, "to": to, "life": life, "max": life, "color": color, "width": width})


func add_shake(amount: float) -> void:
	shake = minf(shake + amount, MAX_SHAKE)


func shake_offset() -> Vector2:
	if shake <= 0.01:
		return Vector2.ZERO
	return Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * shake


func update(delta: float) -> void:
	shake = maxf(shake - shake * SHAKE_DECAY * delta - delta, 0.0)
	var alive: Array[Dictionary] = []
	for particle in particles:
		particle.life -= delta
		if particle.life <= 0.0:
			continue
		particle.velocity = particle.velocity * maxf(1.0 - 2.5 * delta, 0.0) + Vector2(0.0, particle.gravity * delta)
		particle.position += particle.velocity * delta
		alive.append(particle)
	particles = alive
	for floater_item in floaters:
		floater_item.position += Vector2(0.0, -46.0 * delta)
	floaters = _age(floaters, delta)
	bolts = _age(bolts, delta)
	rings = _age(rings, delta)
	trails = _age(trails, delta)


static func _age(items: Array[Dictionary], delta: float) -> Array[Dictionary]:
	var alive: Array[Dictionary] = []
	for item in items:
		item.life -= delta
		if item.life > 0.0:
			alive.append(item)
	return alive


static func ratio(item: Dictionary) -> float:
	return clampf(float(item.life) / maxf(float(item.max), 0.0001), 0.0, 1.0)


func clear() -> void:
	particles.clear()
	floaters.clear()
	bolts.clear()
	rings.clear()
	trails.clear()
	shake = 0.0
