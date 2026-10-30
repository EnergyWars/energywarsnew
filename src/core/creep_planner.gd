class_name CreepPlanner
extends RefCounted

const NO_CELL := Vector2i(-1, -1)
const SNAP_REACH := 3
const LATTICE_MARGIN := 3
const RING_BAND := 4.0
const ORIGIN_STEP := 3
const HOLES_PER_NEST := 40

static var _snap: Array[Vector2i] = []

var map: LevelMap
var core: Vector2i
var rng: RandomNumberGenerator
var needed := PackedByteArray()
var allowed := PackedByteArray()
var sites: Array[Vector2i] = []
var _covered := PackedByteArray()
var _counts := PackedInt32Array()
var _column := 0
var _row := 0


func _init(p_map: LevelMap, p_core: Vector2i, p_rng: RandomNumberGenerator, fits: Callable) -> void:
	map = p_map
	core = p_core
	rng = p_rng
	var count := map.width * map.height
	needed.resize(count)
	allowed.resize(count)
	_covered.resize(count)
	var inner := inner_radius()
	for i in count:
		var cell := map.cell_at(i)
		var gap := Vector2(cell - core).length()
		needed[i] = 1 if gap >= inner else 0
		allowed[i] = 1 if gap >= GameConfig.CREEP_CORE_CLEAR and fits.call(cell) else 0
	var spacing := lattice_spacing()
	_column = spacing.x
	_row = spacing.y


static func inner_radius() -> float:
	return GameConfig.CREEP_CORE_CLEAR - GameConfig.CREEP_RADIUS + GameConfig.CREEP_FRINGE


static func lattice_spacing() -> Vector2i:
	var radius := GameConfig.CREEP_RADIUS
	return Vector2i(2 * floori(sqrt(3.0) * radius * 0.5), floori(1.5 * radius))


static func ring_steps() -> int:
	var clear := GameConfig.CREEP_CORE_CLEAR
	var radius := GameConfig.CREEP_RADIUS
	var inner := inner_radius()
	var cosine := (clear * clear + inner * inner - radius * radius) / (2.0 * clear * inner)
	return ceili(PI / maxf(acos(clampf(cosine, -1.0, 1.0)), 1.0 / clear))


static func snap_offsets() -> Array[Vector2i]:
	if _snap.is_empty():
		for square in SNAP_REACH * SNAP_REACH + 1:
			for y in range(-SNAP_REACH, SNAP_REACH + 1):
				for x in range(-SNAP_REACH, SNAP_REACH + 1):
					if x * x + y * y == square:
						_snap.append(Vector2i(x, y))
	return _snap


func plan() -> Array[Vector2i]:
	sites.clear()
	_covered.fill(0)
	var first := _farthest()
	if first == NO_CELL:
		return sites
	_plant(first)
	_ring()
	_lattice(_best_origin())
	_fill()
	compact()
	return sites


func compact() -> void:
	_counts = PackedInt32Array()
	_counts.resize(needed.size())
	for site in sites:
		_tally(site, 1)
	_prune()
	_merge()
	_prune()


func coverage(cell: Vector2i) -> int:
	var count := 0
	for site in sites:
		if _within(cell, site):
			count += 1
	return count


func _farthest() -> Vector2i:
	var best := NO_CELL
	var best_gap := -1
	var best_rim := false
	for i in allowed.size():
		if allowed[i] == 0:
			continue
		var cell := map.cell_at(i)
		var rim := map.edge_distance(cell) < GameConfig.CREEP_RIM
		var gap := (cell - core).length_squared()
		if (rim and not best_rim) or (rim == best_rim and gap > best_gap):
			best = cell
			best_gap = gap
			best_rim = rim
	return best


func _ring() -> void:
	var steps := ring_steps()
	var phase := rng.randf() * TAU
	for k in steps:
		var offset := Vector2.from_angle(phase + TAU * k / steps) * GameConfig.CREEP_CORE_CLEAR
		_offer(core + Vector2i(offset.round()))


func _best_origin() -> Vector2i:
	var covered := _covered.duplicate()
	var planted := sites.size()
	var best := NO_CELL
	var best_score := 0
	for y in range(0, _row, ORIGIN_STEP):
		for x in range(0, _column, ORIGIN_STEP):
			var score := _lattice(Vector2i(x, y))
			if best == NO_CELL or score < best_score:
				best = Vector2i(x, y)
				best_score = score
			_covered = covered.duplicate()
			sites.resize(planted)
	return best


func _lattice(origin: Vector2i) -> int:
	var score := 0
	var shifted := false
	var y := posmod(origin.y + LATTICE_MARGIN, _row) - LATTICE_MARGIN
	while y < map.height + LATTICE_MARGIN:
		var x := posmod(origin.x + (_column / 2 if shifted else 0) + LATTICE_MARGIN, _column) - LATTICE_MARGIN
		while x < map.width + LATTICE_MARGIN:
			var point := Vector2i(x, y)
			if Vector2(point - core).length() >= GameConfig.CREEP_CORE_CLEAR + RING_BAND:
				var gain := _offer(point)
				if gain > 0:
					score += HOLES_PER_NEST - gain
			x += _column
		y += _row
		shifted = not shifted
	return score


func _offer(target: Vector2i) -> int:
	var anchor := target.clamp(Vector2i.ZERO, Vector2i(map.width - 1, map.height - 1))
	for offset in snap_offsets():
		var cell := anchor + offset
		if map.has_cell(cell) and allowed[map.index(cell)] != 0:
			var gain := _gain(cell)
			if gain > 0:
				_plant(cell)
			return gain
	return 0


func _fill() -> void:
	var cursor := 0
	while cursor < needed.size():
		if needed[cursor] == 0 or _covered[cursor] != 0:
			cursor += 1
			continue
		var pick := _best_site(map.cell_at(cursor))
		if pick == NO_CELL:
			_covered[cursor] = 1
		else:
			_plant(pick)


func _best_site(target: Vector2i) -> Vector2i:
	for stride: int in [GameConfig.CREEP_STRIDE, 1]:
		var best := NO_CELL
		var best_score := 0
		var ties := 0
		for offset in Creep.disk():
			if offset.x % stride != 0 or offset.y % stride != 0:
				continue
			var site := target + offset
			if not map.has_cell(site) or allowed[map.index(site)] == 0:
				continue
			var score := _gain(site)
			if score > best_score:
				best = site
				best_score = score
				ties = 1
			elif score == best_score and score > 0:
				ties += 1
				if rng.randi_range(1, ties) == 1:
					best = site
		if best != NO_CELL:
			return best
	return NO_CELL


func _gain(site: Vector2i) -> int:
	var score := 0
	for offset in Creep.disk():
		var cell := site + offset
		if map.has_cell(cell):
			var index := map.index(cell)
			if needed[index] != 0 and _covered[index] == 0:
				score += 1
	return score


func _plant(site: Vector2i) -> void:
	sites.append(site)
	for offset in Creep.disk():
		var cell := site + offset
		if map.has_cell(cell):
			_covered[map.index(cell)] = 1


func _tally(site: Vector2i, delta: int) -> void:
	for offset in Creep.disk():
		var cell := site + offset
		if map.has_cell(cell):
			var index := map.index(cell)
			if needed[index] != 0:
				_counts[index] += delta


func _redundant(site: Vector2i) -> bool:
	for offset in Creep.disk():
		var cell := site + offset
		if map.has_cell(cell):
			var index := map.index(cell)
			if needed[index] != 0 and _counts[index] < 2:
				return false
	return true


func _prune() -> void:
	for k in range(sites.size() - 1, 0, -1):
		if _redundant(sites[k]):
			_tally(sites[k], -1)
			sites.remove_at(k)


func _merge() -> void:
	var span := int(2.0 * GameConfig.CREEP_RADIUS)
	var merged := true
	while merged:
		merged = false
		var a := 1
		while a < sites.size():
			var b := a + 1
			while b < sites.size():
				var joint := NO_CELL
				if (sites[a] - sites[b]).length_squared() <= span * span:
					joint = _joint(sites[a], sites[b])
				if joint == NO_CELL:
					b += 1
					continue
				_tally(sites[a], -1)
				_tally(sites[b], -1)
				_tally(joint, 1)
				sites[a] = joint
				sites.remove_at(b)
				merged = true
			a += 1


func _joint(a: Vector2i, b: Vector2i) -> Vector2i:
	var orphans := _orphans(a, b, false)
	orphans.append_array(_orphans(b, a, true))
	if orphans.is_empty():
		return a
	var low := orphans[0]
	var high := orphans[0]
	for cell in orphans:
		low = low.min(cell)
		high = high.max(cell)
	var reach := int(GameConfig.CREEP_RADIUS)
	if high.x - low.x > 2 * reach or high.y - low.y > 2 * reach:
		return NO_CELL
	for y in range(maxi(high.y - reach, 0), mini(low.y + reach, map.height - 1) + 1):
		for x in range(maxi(high.x - reach, 0), mini(low.x + reach, map.width - 1) + 1):
			var site := Vector2i(x, y)
			if allowed[map.index(site)] != 0 and _covers(site, orphans):
				return site
	return NO_CELL


func _orphans(site: Vector2i, other: Vector2i, skip_shared: bool) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset in Creep.disk():
		var cell := site + offset
		if not map.has_cell(cell):
			continue
		var index := map.index(cell)
		if needed[index] == 0:
			continue
		var shared := _within(cell, other)
		if shared and skip_shared:
			continue
		if _counts[index] <= (2 if shared else 1):
			result.append(cell)
	return result


func _covers(site: Vector2i, cells: Array[Vector2i]) -> bool:
	for cell in cells:
		if not _within(cell, site):
			return false
	return true


func _within(cell: Vector2i, site: Vector2i) -> bool:
	return float((cell - site).length_squared()) <= GameConfig.CREEP_RADIUS * GameConfig.CREEP_RADIUS
