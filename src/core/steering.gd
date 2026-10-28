class_name Steering
extends RefCounted


static func slide(map: LevelMap, from: Vector2, step: Vector2, radius: float, blocked: Callable) -> Vector2:
	if step == Vector2.ZERO:
		return from
	for candidate in [from + step, from + Vector2(step.x, 0.0), from + Vector2(0.0, step.y)]:
		if candidate != from and fits(map, candidate, radius, blocked):
			return candidate
	if not fits(map, from, radius, blocked) and not blocked.call(map.cell_of(from + step)) and map.contains(from + step):
		return from + step
	return from


static func fits(map: LevelMap, position: Vector2, radius: float, blocked: Callable) -> bool:
	if not map.contains(position, radius):
		return false
	var low := map.cell_of(position - Vector2(radius, radius))
	var high := map.cell_of(position + Vector2(radius, radius))
	var limit := radius * radius
	for y in range(low.y, high.y + 1):
		for x in range(low.x, high.x + 1):
			var cell := Vector2i(x, y)
			if not blocked.call(cell):
				continue
			var corner := Vector2(cell) * GameConfig.CELL
			if position.clamp(corner, corner + Vector2(GameConfig.CELL, GameConfig.CELL)).distance_squared_to(position) < limit:
				return false
	return true
