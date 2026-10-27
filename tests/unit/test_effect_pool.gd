extends GutTest

var pool: EffectPool


func before_each() -> void:
	pool = EffectPool.new(5)


func test_effects_expire() -> void:
	pool.burst(Vector2.ZERO, Color.RED, 10, 100.0, 4.0, 0.5, 100.0)
	pool.floater("+5", Vector2.ZERO, Color.WHITE)
	pool.bolt(Vector2.ZERO, Vector2(200, 0), Color.WHITE, 3.0)
	pool.bolt_path(PackedVector2Array([Vector2.ZERO, Vector2(100, 0), Vector2(100, 100)]), Color.WHITE, 3.0)
	pool.ring(Vector2.ZERO, 0.0, 50.0, Color.WHITE)
	pool.tracer(Vector2.ZERO, Vector2(10, 10), Color.WHITE)
	assert_eq(pool.particles.size(), 10)
	var start: Vector2 = pool.particles[0].position
	pool.update(0.05)
	assert_ne(pool.particles[0].position, start)
	assert_lt(pool.floaters[0].position.y, 0.0)
	pool.update(2.0)
	assert_true(pool.particles.is_empty())
	assert_true(pool.floaters.is_empty())
	assert_true(pool.bolts.is_empty())
	assert_true(pool.rings.is_empty())
	assert_true(pool.trails.is_empty())


func test_limits() -> void:
	pool.burst(Vector2.ZERO, Color.RED, EffectPool.MAX_PARTICLES + 20, 10.0, 1.0, 1.0)
	assert_eq(pool.particles.size(), EffectPool.MAX_PARTICLES)
	for i in EffectPool.MAX_FLOATERS + 5:
		pool.floater(str(i), Vector2.ZERO, Color.WHITE)
	assert_eq(pool.floaters.size(), EffectPool.MAX_FLOATERS)


func test_shake() -> void:
	assert_eq(pool.shake_offset(), Vector2.ZERO)
	pool.add_shake(100.0)
	assert_eq(pool.shake, EffectPool.MAX_SHAKE)
	assert_ne(pool.shake_offset(), Vector2.ZERO)
	pool.update(5.0)
	assert_eq(pool.shake, 0.0)


func test_ratio_and_clear() -> void:
	assert_eq(EffectPool.ratio({"life": 0.5, "max": 1.0}), 0.5)
	assert_eq(EffectPool.ratio({"life": 2.0, "max": 1.0}), 1.0)
	pool.burst(Vector2.ZERO, Color.RED, 3, 10.0, 1.0, 1.0)
	pool.add_shake(3.0)
	pool.clear()
	assert_true(pool.particles.is_empty())
	assert_eq(pool.shake, 0.0)


func test_lightning_path_keeps_endpoints() -> void:
	var rng := RandomNumberGenerator.new()
	var path := Lightning.path(Vector2(0, 0), Vector2(260, 0), 20.0, rng)
	assert_eq(path.size(), Lightning.segments(Vector2.ZERO, Vector2(260, 0)) + 1)
	assert_eq(path[0], Vector2.ZERO)
	assert_eq(path[path.size() - 1], Vector2(260, 0))
	for point in path:
		assert_lte(absf(point.y), 20.0)
	assert_eq(Lightning.segments(Vector2.ZERO, Vector2.ZERO), 1)
	assert_eq(Lightning.segments(Vector2.ZERO, Vector2(99999, 0)), Lightning.MAX_SEGMENTS)
