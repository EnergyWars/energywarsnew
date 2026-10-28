class_name WorldWalker
extends RefCounted

var location := 0
var point := Vector2.ZERO
var heading := Vector2.UP
var path: Array[int] = []


func _init(p_location: int = 0) -> void:
	location = clampi(p_location, 0, Campaign.region_count() - 1)
	point = Campaign.position(location)


func is_walking() -> bool:
	return not path.is_empty()


func destination() -> int:
	return path.back() if is_walking() else location


func anchor() -> int:
	return path[0] if is_walking() else location


func follow(route: Array[int]) -> bool:
	if route.is_empty() or route[0] != anchor():
		return false
	var fresh: Array[int] = []
	if is_walking():
		fresh.append(path[0])
	fresh.append_array(route.slice(1))
	path = fresh
	return true


func update(delta: float, speed: float = GameConfig.WORLD_WALK_SPEED) -> bool:
	if not is_walking():
		return false
	var budget := speed * maxf(delta, 0.0)
	while budget > 0.0 and is_walking():
		var target := Campaign.position(path[0])
		var offset := target - point
		var distance := offset.length()
		if distance > 0.0001:
			heading = offset / distance
		if distance > budget:
			point += offset / distance * budget
			return false
		budget -= distance
		point = target
		location = path.pop_front()
	return not is_walking()
