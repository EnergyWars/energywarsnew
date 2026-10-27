class_name ScoutControl
extends RefCounted

const OK := ""
const MISSING := "missing"
const LANDING := "landing"
const BOUNDS := "bounds"
const BLOCKED := "blocked"
const UNREACHABLE := "unreachable"

var state: BattleState
var events: BattleEvents


func _init(p_state: BattleState, p_events: BattleEvents) -> void:
	state = p_state
	events = p_events


func command(world: Vector2) -> String:
	var scout := state.scout
	if scout == null:
		return MISSING
	if not scout.is_landed():
		return LANDING
	var map := state.map
	var cell := map.cell_of(world)
	if not map.has_cell(cell):
		return BOUNDS
	var clearing := map.is_clearable(cell)
	if not clearing and state.nav.walker.is_point_solid(cell):
		return BLOCKED
	var path := state.nav.walker_path(scout.position, cell)
	if path.is_empty() and map.cell_of(scout.position) != cell:
		return UNREACHABLE
	scout.path = path
	scout.path_index = 0
	scout.clear_cell = cell if clearing else Scout.NO_CELL
	scout.clear_progress = 0.0
	events.emit("scout_order", {"position": map.center_of(cell), "clear": clearing})
	return OK


func update(delta: float) -> void:
	var scout := state.scout
	if scout == null:
		return
	if not scout.is_landed():
		scout.drop_left -= delta
		if scout.is_landed():
			events.emit("landed", {"position": scout.position})
		return
	if scout.is_moving():
		_walk(scout, delta)
		return
	if scout.is_clearing():
		_clear(scout, delta)


func _walk(scout: Scout, delta: float) -> void:
	var budget := GameConfig.SCOUT_SPEED * delta
	while budget > 0.0 and scout.is_moving():
		var goal := scout.path[scout.path_index]
		var offset := goal - scout.position
		if offset.length() <= budget:
			scout.position = goal
			budget -= offset.length()
			scout.path_index += 1
		else:
			scout.heading = offset.normalized()
			scout.position += scout.heading * budget
			budget = 0.0


func _clear(scout: Scout, delta: float) -> void:
	var map := state.map
	var cell := scout.clear_cell
	var target := map.center_of(cell)
	if not map.is_clearable(cell) or scout.position.distance_to(target) > GameConfig.CELL * GameConfig.CLEAR_REACH:
		scout.clear_cell = Scout.NO_CELL
		return
	scout.heading = (target - scout.position).normalized() if target != scout.position else scout.heading
	scout.clear_progress += delta
	var type := map.obstacle_type(cell)
	if scout.clear_progress < float(GameConfig.CLEAR_TIME[type]):
		return
	map.clear(cell)
	state.nav.terrain_changed(cell)
	scout.clear_cell = Scout.NO_CELL
	scout.clear_progress = 0.0
	events.emit("cleared", {"position": target, "obstacle": type, "cell": cell})


func clear_ratio() -> float:
	var scout := state.scout
	if scout == null or not scout.is_clearing():
		return 0.0
	var type := state.map.obstacle_type(scout.clear_cell)
	return clampf(scout.clear_progress / float(GameConfig.CLEAR_TIME.get(type, 1.0)), 0.0, 1.0)
