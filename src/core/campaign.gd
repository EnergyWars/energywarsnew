class_name Campaign
extends RefCounted

const AUTO_LEFT := 0.28
const AUTO_RIGHT := 0.72
const AUTO_START := 0.9
const AUTO_STEP := 0.19
const AUTO_PAD := 0.1

static var _version := -1
static var _positions: Array[Vector2] = []
static var _routes: Array[Vector2i] = []
static var _neighbors: Array = []
static var _top := 0.0


static func region_count() -> int:
	return GameConfig.level_count()


static func is_valid(index: int) -> bool:
	return index >= 0 and index < region_count()


static func position(index: int) -> Vector2:
	_refresh()
	return _positions[clampi(index, 0, _positions.size() - 1)]


static func positions() -> Array[Vector2]:
	_refresh()
	return _positions


static func top() -> float:
	_refresh()
	return _top


static func routes() -> Array[Vector2i]:
	_refresh()
	return _routes


static func neighbors(index: int) -> Array[int]:
	_refresh()
	if index < 0 or index >= _neighbors.size():
		return [] as Array[int]
	return _neighbors[index]


static func _refresh() -> void:
	var version := ContentOverrides.version()
	if version == _version:
		return
	_version = version
	_positions = layout()
	_positions.make_read_only()
	_top = 0.0
	for point in _positions:
		_top = minf(_top, point.y - AUTO_PAD)
	_routes = connect_all(_base_routes(), region_count())
	_routes.make_read_only()
	_neighbors = []
	for index in region_count():
		_neighbors.append([] as Array[int])
	for route in _routes:
		_neighbors[route.x].append(route.y)
		_neighbors[route.y].append(route.x)
	for list: Array[int] in _neighbors:
		list.make_read_only()


static func layout() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for index in region_count():
		var world: Variant = GameConfig.level(index).get("world")
		if world is Vector2:
			result.append(world)
		elif result.is_empty():
			result.append(Vector2(AUTO_LEFT if index % 2 == 0 else AUTO_RIGHT, AUTO_START))
		else:
			var previous: Vector2 = result[index - 1]
			var column := AUTO_RIGHT if previous.x <= 0.5 else AUTO_LEFT
			result.append(Vector2(column, previous.y - AUTO_STEP))
	return result


static func _base_routes() -> Array[Vector2i]:
	var custom: Variant = ContentOverrides.routes()
	var result: Array[Vector2i] = []
	if custom is Array:
		result.assign(custom)
	elif ContentOverrides.levels().is_empty():
		result.assign(GameConfig.WORLD_ROUTES)
	return result


static func connect_all(base: Array[Vector2i], count: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var parent: Array[int] = []
	for index in count:
		parent.append(index)
	for route in base:
		if route.x >= 0 and route.y >= 0 and route.x < count and route.y < count and route.x != route.y:
			result.append(route)
			_join(parent, route.x, route.y)
	for index in range(1, count):
		if _root(parent, index) != _root(parent, 0):
			result.append(Vector2i(index - 1, index))
			_join(parent, index - 1, index)
	return result


static func _root(parent: Array[int], index: int) -> int:
	var current := index
	while parent[current] != current:
		parent[current] = parent[parent[current]]
		current = parent[current]
	return current


static func _join(parent: Array[int], a: int, b: int) -> void:
	parent[_root(parent, a)] = _root(parent, b)


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
