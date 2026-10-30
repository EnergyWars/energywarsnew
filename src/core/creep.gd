class_name Creep
extends RefCounted

static var _disk: Array[Vector2i] = []

var state: BattleState
var map: LevelMap
var nests: Array[CreepNest] = []
var version := 0
var _dirty := false


func _init(p_state: BattleState) -> void:
	state = p_state
	map = state.map


static func disk() -> Array[Vector2i]:
	if _disk.is_empty():
		var limit := int(GameConfig.CREEP_RADIUS)
		var square := GameConfig.CREEP_RADIUS * GameConfig.CREEP_RADIUS
		for y in range(-limit, limit + 1):
			for x in range(-limit, limit + 1):
				if float(x * x + y * y) <= square:
					_disk.append(Vector2i(x, y))
	return _disk


func in_rim(cell: Vector2i) -> bool:
	return map.edge_distance(cell) < GameConfig.CREEP_RIM


func seal_rim() -> void:
	for i in map.width * map.height:
		if in_rim(map.cell_at(i)):
			map.slime[i] = 1
			map.sealed[i] = 1
	version += 1


func release_rim() -> void:
	var released: Array[Vector2i] = []
	for i in map.width * map.height:
		if map.sealed[i] != 0:
			released.append(map.cell_at(i))
			map.sealed[i] = 0
			map.slime[i] = 0
	for cell in released:
		state.nav.terrain_changed(cell)
	if not released.is_empty():
		version += 1


func is_sealed() -> bool:
	return map.sealed.has(1)


func spawn(center: Vector2) -> Array[CreepNest]:
	nests.clear()
	var core_cell := map.cell_of(center)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([state.rng.seed, core_cell.x, core_cell.y, 31])
	for cell in CreepPlanner.new(map, core_cell, rng, _fits).plan():
		nests.append(CreepNest.new(nests.size(), cell, map.center_of(cell)))
	rebuild()
	return nests


func restore(entries: Array[Dictionary]) -> void:
	nests.clear()
	for entry in entries:
		var cell: Vector2i = entry.cell
		var nest := CreepNest.new(nests.size(), cell, map.center_of(cell))
		nest.alive = bool(entry.alive)
		nest.fade = float(entry.fade)
		nests.append(nest)
	rebuild()


func export() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for nest in nests:
		result.append({"cell": nest.cell, "alive": nest.alive, "fade": nest.fade})
	return result


func alive_nests() -> Array[CreepNest]:
	var result: Array[CreepNest] = []
	for nest in nests:
		if nest.alive:
			result.append(nest)
	return result


func kill(nest: CreepNest) -> bool:
	if not nest.alive:
		return false
	nest.alive = false
	_dirty = true
	return true


func recede(delta: float) -> bool:
	var step := delta / GameConfig.CREEP_RECEDE_TIME
	for nest in nests:
		if not nest.alive and nest.fade > 0.0:
			nest.fade = maxf(nest.fade - step, 0.0)
			_dirty = true
	return _dirty


func flush() -> bool:
	if not _dirty:
		return false
	_dirty = false
	rebuild()
	return true


func rebuild() -> void:
	map.slime.fill(0)
	for i in map.sealed.size():
		if map.sealed[i] != 0:
			map.slime[i] = 1
	var offsets := disk()
	var width := map.width
	for nest in nests:
		if not nest.is_active():
			continue
		var square := nest.radius_cells() * nest.radius_cells()
		for offset in offsets:
			if float(offset.x * offset.x + offset.y * offset.y) > square:
				continue
			var cell := nest.cell + offset
			if map.has_cell(cell):
				map.slime[cell.y * width + cell.x] = 1
	version += 1


func nest_at(cell: Vector2i) -> CreepNest:
	for nest in nests:
		if nest.alive and nest.cell == cell:
			return nest
	return null


func _fits(cell: Vector2i) -> bool:
	return map.is_walkable(cell) and state.nav.occupant_at(cell) == NavGrid.FREE
