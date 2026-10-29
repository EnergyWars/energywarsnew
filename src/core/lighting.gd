class_name Lighting
extends RefCounted

const EPSILON := 0.0001
const GLOW_ON := 255

var state: BattleState
var sources := PackedVector3Array()
var glow := PackedByteArray()
var glow_version := 0
var _glowing := PackedInt32Array()
var _key := Vector2i(-1, -1)


func _init(p_state: BattleState) -> void:
	state = p_state
	glow.resize(state.map.width * state.map.height)


func update(delta: float) -> void:
	var night := state.is_night()
	for lamp in state.of_kind(GameConfig.LAMP):
		var cost := Formulas.lamp_draw(lamp) * delta
		lamp.lit = night and lamp.is_alive() and lamp.energy + EPSILON >= cost
		if lamp.lit:
			lamp.energy = maxf(lamp.energy - cost, 0.0)
	refresh()
	refresh_glow()


func refresh() -> void:
	_key = Vector2i(state.roster_version, state.layout_version)
	sources.clear()
	var core := state.core()
	if core != null and core.is_alive():
		sources.append(_source(core))
	for lamp in state.of_kind(GameConfig.LAMP):
		if lamp.lit and lamp.is_alive():
			sources.append(_source(lamp))


func refresh_glow() -> bool:
	var map := state.map
	var fresh := PackedInt32Array()
	for building in state.player_buildings():
		if Formulas.glows(building):
			for cell in building.footprint():
				if map.has_cell(cell):
					fresh.append(map.index(cell))
	if fresh == _glowing:
		return false
	for index in _glowing:
		glow[index] = 0
	for index in fresh:
		glow[index] = GLOW_ON
	_glowing = fresh
	glow_version += 1
	return true


func current() -> PackedVector3Array:
	if _key != Vector2i(state.roster_version, state.layout_version):
		refresh()
	return sources


func _source(building: Building) -> Vector3:
	return Vector3(building.position.x, building.position.y, Formulas.lit_reach(building))


func is_dark() -> bool:
	return state.is_night()


func sees(position: Vector2, radius: float = 0.0) -> bool:
	return not is_dark() or is_lit(position, radius)


func is_lit(position: Vector2, radius: float = 0.0) -> bool:
	for source in current():
		var reach := source.z + radius
		if position.distance_squared_to(Vector2(source.x, source.y)) <= reach * reach:
			return true
	return is_glowing(position, radius)


func is_glowing(position: Vector2, radius: float = 0.0) -> bool:
	if _glowing.is_empty():
		return false
	var map := state.map
	var reach := GameConfig.GLOW_REACH * GameConfig.CELL + radius
	var low := map.cell_of(position - Vector2(reach, reach))
	var high := map.cell_of(position + Vector2(reach, reach))
	for y in range(maxi(low.y, 0), mini(high.y, map.height - 1) + 1):
		for x in range(maxi(low.x, 0), mini(high.x, map.width - 1) + 1):
			var cell := Vector2i(x, y)
			if glow[map.index(cell)] == 0:
				continue
			var corner := Vector2(cell) * GameConfig.CELL
			var dx := maxf(maxf(corner.x - position.x, position.x - corner.x - GameConfig.CELL), 0.0)
			var dy := maxf(maxf(corner.y - position.y, position.y - corner.y - GameConfig.CELL), 0.0)
			if dx * dx + dy * dy <= reach * reach:
				return true
	return false
