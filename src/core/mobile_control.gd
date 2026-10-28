class_name MobileControl
extends RefCounted

const OK := ""
const MISSING := "missing"
const IMMOBILE := "immobile"
const MIN_STEP := 0.01

var state: BattleState
var events: BattleEvents


func _init(p_state: BattleState, p_events: BattleEvents) -> void:
	state = p_state
	events = p_events


func steer(id: int, direction: Vector2) -> String:
	var building := state.building(id)
	if building == null or not building.is_alive():
		return MISSING
	if not building.is_player() or not GameConfig.is_mobile(building.kind):
		return IMMOBILE
	building.steer = direction.limit_length(1.0)
	return OK


func update(delta: float) -> void:
	for building in state.of_kind(GameConfig.ROVER):
		if building.steer != Vector2.ZERO:
			_drive(building, delta)


func _drive(building: Building, delta: float) -> void:
	var per_pixel := Formulas.move_energy(building)
	var distance := Formulas.move_speed(building) * building.steer.length() * delta
	if per_pixel > 0.0:
		distance = minf(distance, building.energy / per_pixel)
	if distance <= MIN_STEP:
		if not building.stalled:
			building.stalled = true
			events.emit("stalled", {"id": building.id, "position": building.position})
		return
	building.stalled = false
	var blocked := func(cell: Vector2i) -> bool:
		var occupant := state.nav.occupant_at(cell)
		return not state.map.is_walkable(cell) or (occupant != NavGrid.FREE and occupant != building.id)
	var next := Steering.slide(state.map, building.position, building.steer.normalized() * distance, building.radius(), blocked)
	var moved := building.position.distance_to(next)
	if moved <= 0.0:
		return
	building.energy = maxf(building.energy - moved * per_pixel, 0.0)
	state.drive(building, next)
