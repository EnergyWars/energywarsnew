class_name StructurePlacer
extends RefCounted

var state: BattleState
var map: LevelMap
var rng := RandomNumberGenerator.new()
var _good := PackedInt32Array()
var _flat := PackedInt32Array()
var _high := PackedInt32Array()
var _candidates := {}
var _taken: Array[Rect2i] = []


func _init(p_state: BattleState, seed_value: int) -> void:
	state = p_state
	map = state.map
	rng.seed = seed_value
	_build_sums()


static func sites(p_state: BattleState, center: Vector2) -> Array[Dictionary]:
	var cell := p_state.map.cell_of(center)
	return StructurePlacer.new(p_state, hash([p_state.rng.seed, cell.x, cell.y])).place(center)


func place(center: Vector2) -> Array[Dictionary]:
	var defaults := map.structures
	var result: Array[Dictionary] = []
	result.resize(defaults.size())
	var hosts: Array[Vector2] = []
	var spawners: Array[int] = []
	var others: Array[int] = []
	for i in defaults.size():
		(spawners if is_spawner(str(defaults[i].kind)) else others).append(i)
	for i in spawners + others:
		var kind := str(defaults[i].kind)
		var cells := GameConfig.cells(kind)
		var spot: Dictionary = {}
		if is_spawner(kind) or hosts.is_empty():
			spot = _far_spot(kind, center, hosts)
		else:
			spot = _guard_spot(kind, center, hosts[rng.randi_range(0, hosts.size() - 1)])
		var position: Vector2 = spot.position if not spot.is_empty() else defaults[i].position
		_taken.append(_rect(LevelMap.footprint_origin(position, cells), cells))
		if is_spawner(kind):
			hosts.append(position)
		result[i] = {"kind": kind, "position": position}
	return result


static func is_spawner(kind: String) -> bool:
	return bool(GameConfig.building(kind).get("spawns", false))


func candidates(cells: int, center: Vector2) -> Array[Dictionary]:
	if _candidates.has(cells):
		return _candidates[cells]
	var margin := GameConfig.STRUCTURE_MARGIN
	var area := (cells + margin * 2) * (cells + margin * 2)
	var footprint := cells * cells
	var home := state.nav.component_at(center)
	var list: Array[Dictionary] = []
	for y in range(margin, map.height - cells - margin + 1):
		for x in range(margin, map.width - cells - margin + 1):
			var origin := Vector2i(x, y)
			var ring := Rect2i(origin - Vector2i(margin, margin), Vector2i(cells + margin * 2, cells + margin * 2))
			if _sum(_good, ring) != area or _sum(_flat, Rect2i(origin, Vector2i(cells, cells))) != footprint:
				continue
			var heights := _sum(_high, Rect2i(origin, Vector2i(cells, cells)))
			if heights != 0 and heights != footprint:
				continue
			if home >= 0 and state.nav.component(ring.position) != home:
				continue
			var position := LevelMap.footprint_center(origin, cells)
			list.append({"origin": origin, "position": position, "distance": position.distance_to(center)})
	_candidates[cells] = list
	return list


static func far_limit(list: Array[Dictionary]) -> float:
	var farthest := 0.0
	for entry in list:
		farthest = maxf(farthest, float(entry.distance))
	return maxf(GameConfig.CORE_ENEMY_CLEAR, farthest * GameConfig.STRUCTURE_FAR_SHARE)


func _far_spot(kind: String, center: Vector2, hosts: Array[Vector2]) -> Dictionary:
	var cells := GameConfig.cells(kind)
	var list := candidates(cells, center)
	var limit := far_limit(list)
	var spacing := GameConfig.STRUCTURE_SPACING * GameConfig.CELL
	var spaced := func(entry: Dictionary) -> bool:
		return float(entry.distance) >= limit and _is_free(entry.origin, cells) and _apart(entry.position, hosts, spacing)
	var picked := _pick(list, spaced)
	if picked.is_empty():
		picked = _pick(list, func(entry: Dictionary) -> bool: return float(entry.distance) >= limit and _is_free(entry.origin, cells))
	return picked


func _guard_spot(kind: String, center: Vector2, host: Vector2) -> Dictionary:
	var cells := GameConfig.cells(kind)
	var low := GameConfig.TURRET_POST_RING.x * GameConfig.CELL
	var high := GameConfig.TURRET_POST_RING.y * GameConfig.CELL
	var near := func(entry: Dictionary) -> bool:
		var gap := (entry.position as Vector2).distance_to(host)
		return gap >= low and gap <= high and float(entry.distance) >= GameConfig.CORE_ENEMY_CLEAR and _is_free(entry.origin, cells)
	var picked := _pick(candidates(cells, center), near)
	return picked if not picked.is_empty() else _far_spot(kind, center, [] as Array[Vector2])


func _pick(list: Array[Dictionary], accept: Callable) -> Dictionary:
	var matches: Array[Dictionary] = []
	for entry in list:
		if accept.call(entry):
			matches.append(entry)
	return matches[rng.randi_range(0, matches.size() - 1)] if not matches.is_empty() else {}


func _is_free(origin: Vector2i, cells: int) -> bool:
	var rect := _rect(origin, cells)
	for taken in _taken:
		if taken.intersects(rect):
			return false
	return true


func _rect(origin: Vector2i, cells: int) -> Rect2i:
	var margin := GameConfig.STRUCTURE_MARGIN
	return Rect2i(origin - Vector2i(margin, margin), Vector2i(cells + margin * 2, cells + margin * 2))


static func _apart(position: Vector2, hosts: Array[Vector2], spacing: float) -> bool:
	for host in hosts:
		if host.distance_to(position) < spacing:
			return false
	return true


func _build_sums() -> void:
	var stride := map.width + 1
	var count := stride * (map.height + 1)
	_good.resize(count)
	_good.fill(0)
	_flat.resize(count)
	_flat.fill(0)
	_high.resize(count)
	_high.fill(0)
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			var free := state.nav.is_free(cell)
			var at := (y + 1) * stride + x + 1
			var good := 1 if free else 0
			var flat := 1 if free and map.tile(cell) == LevelMap.Tile.OPEN else 0
			_good[at] = good + _good[at - 1] + _good[at - stride] - _good[at - stride - 1]
			_flat[at] = flat + _flat[at - 1] + _flat[at - stride] - _flat[at - stride - 1]
			_high[at] = map.raw_height(cell) + _high[at - 1] + _high[at - stride] - _high[at - stride - 1]


func _sum(sums: PackedInt32Array, rect: Rect2i) -> int:
	var stride := map.width + 1
	var low := rect.position
	var high := rect.end
	return sums[high.y * stride + high.x] - sums[low.y * stride + high.x] - sums[high.y * stride + low.x] + sums[low.y * stride + low.x]
