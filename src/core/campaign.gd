class_name Campaign
extends RefCounted


static func region_count() -> int:
	return GameConfig.level_count()


static func is_valid(index: int) -> bool:
	return index >= 0 and index < region_count()


static func position(index: int) -> Vector2:
	return GameConfig.level(index).get("world", Vector2(0.5, 0.5))


static func neighbors(index: int) -> Array[int]:
	var result: Array[int] = []
	for route in GameConfig.WORLD_ROUTES:
		if route.x == index:
			result.append(route.y)
		elif route.y == index:
			result.append(route.x)
	return result


static func is_unlocked(progress: Progress, index: int) -> bool:
	if not is_valid(index):
		return false
	if index == 0 or progress.is_conquered(index):
		return true
	for neighbor in neighbors(index):
		if progress.is_conquered(neighbor):
			return true
	return false


static func is_frontier(progress: Progress, index: int) -> bool:
	return is_unlocked(progress, index) and not progress.is_conquered(index)


static func is_route_open(progress: Progress, from: int, to: int) -> bool:
	return (progress.is_conquered(from) and is_unlocked(progress, to)) or (progress.is_conquered(to) and is_unlocked(progress, from))


static func route(progress: Progress, from: int, to: int) -> Array[int]:
	var empty: Array[int] = []
	if not is_valid(from) or not is_unlocked(progress, to):
		return empty
	if from == to:
		return [from] as Array[int]
	var previous := {from: -1}
	var queue: Array[int] = [from]
	while not queue.is_empty():
		var current: int = queue.pop_front()
		var held := progress.is_conquered(current)
		if current != from and not held:
			continue
		for neighbor in neighbors(current):
			if previous.has(neighbor) or not is_unlocked(progress, neighbor):
				continue
			if not held and not progress.is_conquered(neighbor):
				continue
			previous[neighbor] = current
			if neighbor == to:
				return _trace(previous, to)
			queue.append(neighbor)
	return empty


static func _trace(previous: Dictionary, to: int) -> Array[int]:
	var path: Array[int] = []
	var current := to
	while current >= 0:
		path.push_front(current)
		current = int(previous[current])
	return path
