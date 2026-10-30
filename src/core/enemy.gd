class_name Enemy
extends RefCounted

var id: int
var kind: String
var position: Vector2
var hp: float
var max_hp: float
var bounty: int
var damage_scale := 1.0
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
var burn := -1.0
var post := -1
var patrol_angle := 0.0
var patrol_turn := 1.0
var _class := ""
var _radius := 0.0
var _speed := 0.0
var _speed_factor := 1.0
var _armor := 0.0
var _reach := 0.0
var _saboteur := false
var _boss := false
var _nocturnal := false
var _definition: Dictionary


func _init(p_id: int, p_kind: String, p_position: Vector2, hp_scale: float = 1.0, p_damage_scale: float = 1.0, bounty_scale: float = 1.0, is_night: bool = false, level_index: int = 0) -> void:
	id = p_id
	kind = p_kind
	position = p_position
	_definition = GameConfig.enemy(kind)
	_class = str(_definition.get("class", GameConfig.CLASS_MELEE))
	_radius = float(_definition.radius)
	_speed_factor = Formulas.enemy_buff(kind, "speed", is_night, level_index)
	_speed = float(_definition.speed) * _speed_factor
	_armor = float(_definition.get("armor", 0.0)) * Formulas.enemy_buff(kind, "armor", is_night, level_index)
	_reach = float(_definition.reach)
	_saboteur = bool(_definition.get("sabotage", false))
	_boss = bool(_definition.get("boss", false))
	_nocturnal = bool(_definition.get("nocturnal", false))
	max_hp = float(_definition.hp) * maxf(hp_scale, 0.01) * Formulas.enemy_buff(kind, "hp", is_night, level_index)
	hp = max_hp
	damage_scale = maxf(p_damage_scale, 0.0) * Formulas.enemy_buff(kind, "damage", is_night, level_index)
	bounty = maxi(int(round(float(_definition.bounty) * bounty_scale)), 1)


func definition() -> Dictionary:
	return _definition


func damage() -> float:
	return float(_definition.damage) * damage_scale


func armor() -> float:
	return _armor


func is_alive() -> bool:
	return hp > 0.0


func radius() -> float:
	return _radius


func speed() -> float:
	return _speed


func unit_class() -> String:
	return _class


func is_air() -> bool:
	return _class == GameConfig.CLASS_AIR


func is_ranged() -> bool:
	return _class == GameConfig.CLASS_RANGED


func is_saboteur() -> bool:
	return _saboteur


func is_boss() -> bool:
	return _boss


func is_nocturnal() -> bool:
	return _nocturnal


func is_burning() -> bool:
	return burn >= 0.0


func is_guard() -> bool:
	return post >= 0


func is_attacker() -> bool:
	return is_alive() and post < 0


func make_guard(post_id: int, angle: float, turn: float) -> void:
	post = post_id
	patrol_angle = angle
	patrol_turn = 1.0 if turn >= 0.0 else -1.0
	_speed = float(_definition.speed) * _speed_factor * GameConfig.GUARD_SPEED


func reach() -> float:
	return _reach


func hp_ratio() -> float:
	return clampf(hp / max_hp, 0.0, 1.0)
