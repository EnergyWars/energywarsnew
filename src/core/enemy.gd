class_name Enemy
extends RefCounted

var id: int
var kind: String
var position: Vector2
var hp: float
var max_hp: float
var bounty: int
var cooldown := 0.0
var target_id := -1
var target_link := ""
var link_cell := Vector2i(-1, -1)
var retarget_timer := 0.0
var approach := Vector2.ZERO
var heading := Vector2.DOWN
var path := PackedVector2Array()
var path_index := 0
var path_target := -1
var path_version := -1
var _class := ""
var _radius := 0.0


func _init(p_id: int, p_kind: String, p_position: Vector2, cycle: int = 0) -> void:
	id = p_id
	kind = p_kind
	position = p_position
	_class = str(definition().get("class", GameConfig.CLASS_MELEE))
	_radius = float(definition().radius)
	max_hp = float(definition().hp) * (1.0 + GameConfig.HP_GROWTH * clampi(cycle, 0, GameConfig.HP_GROWTH_CYCLES))
	hp = max_hp
	bounty = int(round(float(definition().bounty) * (1.0 + GameConfig.BOUNTY_GROWTH * maxi(cycle, 0))))


func definition() -> Dictionary:
	return GameConfig.enemy(kind)


func is_alive() -> bool:
	return hp > 0.0


func radius() -> float:
	return _radius


func speed() -> float:
	return float(definition().speed)


func unit_class() -> String:
	return _class


func is_air() -> bool:
	return unit_class() == GameConfig.CLASS_AIR


func is_ranged() -> bool:
	return unit_class() == GameConfig.CLASS_RANGED


func is_saboteur() -> bool:
	return bool(definition().get("sabotage", false))


func is_boss() -> bool:
	return bool(definition().get("boss", false))


func reach() -> float:
	return float(definition().reach)


func hp_ratio() -> float:
	return clampf(hp / max_hp, 0.0, 1.0)
