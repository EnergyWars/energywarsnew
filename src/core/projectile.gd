class_name Projectile
extends RefCounted

var origin: Vector2
var destination: Vector2
var damage: float
var splash: float
var crit: bool
var obstacle: Obstacle
var elapsed := 0.0
var duration: float


func _init(p_origin: Vector2, p_destination: Vector2, p_damage: float, p_splash: float, p_crit: bool) -> void:
	origin = p_origin
	destination = p_destination
	damage = p_damage
	splash = p_splash
	crit = p_crit
	duration = maxf(origin.distance_to(destination) / GameConfig.PLASMA_SPEED, 0.05)


func progress() -> float:
	return clampf(elapsed / duration, 0.0, 1.0)


func position() -> Vector2:
	return origin.lerp(destination, progress())


func height() -> float:
	var t := progress()
	return 4.0 * t * (1.0 - t) * origin.distance_to(destination) * 0.35


func is_done() -> bool:
	return elapsed >= duration
