class_name ScoutControl
extends RefCounted

const OK := ""
const MISSING := "missing"
const LANDING := "landing"
const BOARDED := "boarded"
const NOTHING := "nothing"
const TOO_FAR := "too_far"

var state: BattleState
var events: BattleEvents


func _init(p_state: BattleState, p_events: BattleEvents) -> void:
	state = p_state
	events = p_events


func _availability() -> String:
	var scout := state.scout
	if scout == null:
		return MISSING
	if scout.boarded:
		return BOARDED
	if not scout.is_landed():
		return LANDING
	return OK


func steer(direction: Vector2) -> String:
	var reason := _availability()
	if reason != OK:
		return reason
	var scout := state.scout
	var value := direction.limit_length(1.0)
	if scout.steer == Vector2.ZERO and value != Vector2.ZERO:
		events.emit("scout_steer", {"position": scout.position})
	scout.steer = value
	return OK


func clear(world: Vector2) -> String:
	var reason := _availability()
	if reason != OK:
		return reason
	var scout := state.scout
	var map := state.map
	var cell := map.cell_of(world)
	if not map.is_clearable(cell):
		return NOTHING
	if not in_reach(cell):
		return TOO_FAR
	scout.clear_cell = cell
	scout.clear_progress = 0.0
	events.emit("clear_order", {"position": map.center_of(cell)})
	if clear_time(cell) <= 0.0:
		_finish(scout, cell)
	return OK


func clear_time(cell: Vector2i) -> float:
	return float(GameConfig.CLEAR_TIME.get(state.map.obstacle_type(cell), 0.0))


func in_reach(cell: Vector2i) -> bool:
	return state.scout.position.distance_to(state.map.center_of(cell)) <= GameConfig.CELL * GameConfig.CLEAR_REACH


func board(core: Building) -> void:
	var scout := state.scout
	if scout == null:
		return
	scout.boarded = true
	scout.position = core.position
	scout.steer = Vector2.ZERO
	scout.clear_cell = Scout.NO_CELL
	scout.clear_progress = 0.0
	events.emit("scout_boarded", {"position": core.position})


func update(delta: float) -> void:
	var scout := state.scout
	if scout == null or scout.boarded:
		return
	if not scout.is_landed():
		scout.drop_left -= delta
		if scout.is_landed():
			events.emit("landed", {"position": scout.position})
		return
	if scout.is_moving():
		_walk(scout, delta)
	if scout.is_clearing():
		_clear(scout, delta)


func _walk(scout: Scout, delta: float) -> void:
	scout.heading = scout.steer.normalized()
	var walker := state.nav.walker
	var blocked := func(cell: Vector2i) -> bool: return not state.map.has_cell(cell) or walker.is_point_solid(cell)
	scout.position = Steering.slide(state.map, scout.position, scout.steer * GameConfig.SCOUT_SPEED * delta, GameConfig.SCOUT_RADIUS, blocked)


func _clear(scout: Scout, delta: float) -> void:
	var map := state.map
	var cell := scout.clear_cell
	var target := map.center_of(cell)
	if not map.is_clearable(cell) or not in_reach(cell):
		scout.clear_cell = Scout.NO_CELL
		return
	if not scout.is_moving():
		scout.heading = (target - scout.position).normalized() if target != scout.position else scout.heading
	scout.clear_progress += delta
	if scout.clear_progress >= clear_time(cell):
		_finish(scout, cell)


func _finish(scout: Scout, cell: Vector2i) -> void:
	var map := state.map
	var target := map.center_of(cell)
	var type := map.obstacle_type(cell)
	if target != scout.position:
		scout.heading = (target - scout.position).normalized()
	state.clear_obstacle(cell)
	scout.clear_cell = Scout.NO_CELL
	scout.clear_progress = 0.0
	events.emit("cleared", {"position": target, "obstacle": type, "cell": cell})


func clear_ratio() -> float:
	var scout := state.scout
	if scout == null or not scout.is_clearing():
		return 0.0
	var time := clear_time(scout.clear_cell)
	return 1.0 if time <= 0.0 else clampf(scout.clear_progress / time, 0.0, 1.0)
