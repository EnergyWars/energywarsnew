class_name PlanSnapshot
extends RefCounted

var money := 0
var earned := 0
var entries: Array[Dictionary] = []
var links: Array[Vector2i] = []


static func capture(state: BattleState) -> PlanSnapshot:
	var snapshot := PlanSnapshot.new()
	snapshot.money = state.money
	snapshot.earned = state.earned
	for building in state.player_buildings():
		snapshot.entries.append({
			"building": building,
			"label": building.label,
			"origin": building.origin,
			"position": building.position,
			"elevation": building.elevation,
			"hp": building.hp,
			"energy": building.energy,
			"levels": building.levels.duplicate(),
			"spent": building.spent,
			"plan_spent": building.plan_spent,
			"target_order": building.target_order.duplicate(),
			"target_disabled": building.target_disabled.duplicate(),
			"focus": building.focus,
			"fuel": building.fuel.duplicate(),
			"light_radius": building.light_radius,
		})
	for link in state.links:
		snapshot.links.append(Vector2i(link.source, link.target))
	return snapshot


func restore(state: BattleState) -> void:
	for building: Building in state.player_buildings().duplicate():
		state.remove_building(building.id)
	for entry in entries:
		var building: Building = entry.building
		building.label = entry.label
		building.origin = entry.origin
		building.position = entry.position
		building.elevation = entry.elevation
		building.levels = (entry.levels as Dictionary).duplicate()
		building.hp = entry.hp
		building.energy = entry.energy
		building.spent = entry.spent
		building.plan_spent = entry.plan_spent
		building.target_order.assign(entry.target_order)
		building.target_disabled = (entry.target_disabled as Dictionary).duplicate()
		building.focus = entry.focus
		building.fuel.assign(entry.fuel)
		building.light_radius = entry.light_radius
		building.steer = Vector2.ZERO
		state.reinstate(building)
	var restored: Array[EnergyLink] = []
	for pair in links:
		restored.append(EnergyLink.new(pair.x, pair.y))
	state.replace_links(restored)
	state.money = money + state.earned - earned
