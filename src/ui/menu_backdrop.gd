class_name MenuBackdrop
extends Control

const BOLT_INTERVAL := 0.7
const SPARKS := 60

var fx := EffectPool.new(3)
var clock := 0.0
var _bolt_timer := 0.0
var _sparks: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in SPARKS:
		_sparks.append({"position": Vector2(fx.rng.randf(), fx.rng.randf()), "speed": fx.rng.randf_range(0.01, 0.05), "size": fx.rng.randf_range(1.0, 3.0)})


func _process(delta: float) -> void:
	clock += delta
	fx.update(delta)
	_bolt_timer -= delta
	if _bolt_timer <= 0.0 and size.x > 0.0:
		_bolt_timer = BOLT_INTERVAL * fx.rng.randf_range(0.5, 1.5)
		var from := Vector2(fx.rng.randf() * size.x, fx.rng.randf() * size.y * 0.5)
		var to := from + Vector2.from_angle(fx.rng.randf() * TAU) * fx.rng.randf_range(120.0, 360.0)
		fx.bolt(from, to, AppTheme.ENERGY, 2.5, 0.35, 24.0)
	for spark in _sparks:
		spark.position.y = fposmod(spark.position.y - spark.speed * delta, 1.0)
	queue_redraw()


func _draw() -> void:
	var height := size.y
	var bands := 12
	for i in bands:
		var t := float(i) / bands
		draw_rect(Rect2(0, height * t, size.x, height / bands + 1.0), AppTheme.BACKGROUND.lerp(Color("#16264a"), t * 0.8))
	for spark in _sparks:
		var flicker := 0.5 + 0.5 * sin(clock * 3.0 + spark.size * 10.0)
		draw_circle(Vector2(spark.position.x * size.x, spark.position.y * height), spark.size, Color(AppTheme.ENERGY, 0.25 + 0.35 * flicker))
	for bolt in fx.bolts:
		var ratio := EffectPool.ratio(bolt)
		draw_polyline(bolt.points, Color(bolt.color, 0.25 * ratio), 10.0, true)
		draw_polyline(bolt.points, Color(AppTheme.ENERGY_CORE, ratio), 2.0, true)
