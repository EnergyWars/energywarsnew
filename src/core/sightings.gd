class_name Sightings
extends RefCounted

const SCAN := 0.5

var state: BattleState
var events: BattleEvents
var lighting: Lighting
var seen := {}
var _timer := 0.0


func _init(p_state: BattleState, p_events: BattleEvents, p_lighting: Lighting) -> void:
	state = p_state
	events = p_events
	lighting = p_lighting


func update(delta: float) -> int:
	_timer -= delta
	if _timer > 0.0:
		return 0
	_timer = SCAN
	return scan()


func scan() -> int:
	var found := 0
	for enemy in state.enemies:
		if seen.has(enemy.kind) or not enemy.is_alive() or not spots(enemy):
			continue
		seen[enemy.kind] = true
		events.emit("enemy_sighted", {"kind": enemy.kind, "position": enemy.position, "boss": enemy.is_boss()})
		found += 1
	return found


func spots(enemy: Enemy) -> bool:
	return state.fog.is_visible(enemy.position) and lighting.sees(enemy.position, enemy.radius())
