class_name EnemyIcon
extends Control

const FILL := 0.3
const SILHOUETTE := Color(AppTheme.ON_SURFACE_VARIANT, 0.5)
const SILHOUETTE_SHADER: Shader = preload("res://src/ui/silhouette.gdshader")

static var _silhouette: ShaderMaterial

var kind := ""
var known := true
var clock := 0.0


static func silhouette_material() -> ShaderMaterial:
	if _silhouette == null:
		_silhouette = ShaderMaterial.new()
		_silhouette.shader = SILHOUETTE_SHADER
		_silhouette.set_shader_parameter(&"tint", SILHOUETTE)
	return _silhouette


func setup(p_kind: String, p_size: float = 64.0, p_known: bool = true) -> EnemyIcon:
	kind = p_kind
	custom_minimum_size = Vector2(p_size, p_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_known(p_known)
	return self


func set_known(value: bool) -> void:
	known = value
	material = null if known else silhouette_material()
	queue_redraw()


func paint_radius() -> float:
	var scale := float(EnemyPainter.look_of(kind).get("scale", 1.0))
	return minf(size.x, size.y) * FILL / maxf(scale, 0.01)


func _process(delta: float) -> void:
	clock += delta
	queue_redraw()


func _draw() -> void:
	if kind.is_empty() or GameConfig.enemy(kind).is_empty():
		return
	EnemyPainter.paint(self, kind, size * 0.5, paint_radius(), Vector2.RIGHT, clock, 0.0)
