class_name FuelControl
extends RefCounted

const OK := ""
const INVALID := "invalid"
const NOT_TREE := "not_tree"
const RANGE := "range"
const UNEXPLORED := "unexplored"

var state: BattleState
var events: BattleEvents


func _init(p_state: BattleState, p_events: BattleEvents) -> void:
	state = p_state
	events = p_events


func reason(fire: Building, cell: Vector2i) -> String:
	if fire == null or not fire.is_player() or not fire.burner or not fire.is_alive() or state.is_over():
		return INVALID
	if not state.fog.is_explored(cell):
		return UNEXPLORED
	if state.map.tile(cell) != LevelMap.Tile.TREE:
		return NOT_TREE
	if not in_reach(fire, cell):
		return RANGE
	return OK


func in_reach(fire: Building, cell: Vector2i) -> bool:
	return fire.position.distance_to(state.map.center_of(cell)) <= Formulas.fuel_reach(fire)


func candidates(fire: Building) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if fire == null or not fire.burner:
		return result
	var map := state.map
	var reach := Formulas.fuel_reach(fire)
	var low := map.cell_of(fire.position - Vector2(reach, reach))
	var high := map.cell_of(fire.position + Vector2(reach, reach))
	for y in range(low.y, high.y + 1):
		for x in range(low.x, high.x + 1):
			var cell := Vector2i(x, y)
			if map.has_cell(cell) and reason(fire, cell) == OK:
				result.append(cell)
	return result


func toggle(fire: Building, cell: Vector2i) -> String:
	var index := fire.fuel.find(cell) if fire != null else -1
	if index >= 0:
		fire.fuel.remove_at(index)
		if fire.burn_cell == cell:
			fire.burn_cell = Building.NO_CELL
			fire.burn_progress = 0.0
		state.mark_changed()
		events.emit("fuel_unmarked", {"id": fire.id, "cell": cell, "position": state.map.center_of(cell)})
		return OK
	var result := reason(fire, cell)
	if result != OK:
		return result
	fire.fuel.append(cell)
	state.mark_changed()
	events.emit("fuel_marked", {"id": fire.id, "cell": cell, "position": state.map.center_of(cell)})
	return OK


func update(delta: float) -> void:
	for fire in state.of_kind(GameConfig.FIRE):
		_burn(fire, delta)


func _burn(fire: Building, delta: float) -> void:
	while not fire.fuel.is_empty() and state.map.tile(fire.fuel[0]) != LevelMap.Tile.TREE:
		fire.fuel.remove_at(0)
		state.mark_changed()
	if fire.fuel.is_empty():
		fire.burn_cell = Building.NO_CELL
		fire.burn_progress = 0.0
		return
	var cell := fire.fuel[0]
	if fire.burn_cell != cell:
		fire.burn_cell = cell
		fire.burn_progress = 0.0
	fire.burn_progress += delta
	if fire.burn_progress < GameConfig.FIRE_BURN_TIME:
		return
	var position := state.map.center_of(cell)
	state.clear_obstacle(cell)
	fire.burn_cell = Building.NO_CELL
	fire.burn_progress = 0.0
	events.emit("cleared", {"position": position, "obstacle": LevelMap.TREE, "cell": cell, "fire": fire.id})
	if fire.fuel.is_empty():
		events.emit("fuel_empty", {"id": fire.id, "position": fire.position})


func burn_ratio(fire: Building) -> float:
	if fire == null or fire.burn_cell == Building.NO_CELL:
		return 0.0
	return clampf(fire.burn_progress / GameConfig.FIRE_BURN_TIME, 0.0, 1.0)
