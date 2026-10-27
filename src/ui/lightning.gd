class_name Lightning
extends RefCounted

const SEGMENT_LENGTH := 26.0
const MAX_SEGMENTS := 24


static func segments(from: Vector2, to: Vector2) -> int:
	return clampi(int(from.distance_to(to) / SEGMENT_LENGTH), 1, MAX_SEGMENTS)


static func path(from: Vector2, to: Vector2, jitter: float, rng: RandomNumberGenerator) -> PackedVector2Array:
	var count := segments(from, to)
	var points := PackedVector2Array()
	points.resize(count + 1)
	var normal := (to - from).orthogonal().normalized()
	for i in count + 1:
		var t := float(i) / count
		var offset := 0.0
		if i > 0 and i < count:
			offset = rng.randf_range(-jitter, jitter) * sin(t * PI)
		points[i] = from.lerp(to, t) + normal * offset
	return points
