class_name EnergyNetwork
extends RefCounted

const OK := ""
const MISSING := "missing"
const SAME := "same"
const NO_SEND := "no_send"
const NO_RECEIVE := "no_receive"
const EXISTS := "exists"
const FULL := "full"
const RANGE := "range"
const FLOW_SMOOTHING := 0.2

var state: BattleState
var events: BattleEvents
var _groups: Array = []
var _groups_version := -1


func _init(p_state: BattleState, p_events: BattleEvents) -> void:
	state = p_state
	events = p_events


static func can_send(building: Building) -> bool:
	return building.is_player() and Formulas.max_links(building) > 0


static func can_receive(building: Building) -> bool:
	return building.is_player() and Formulas.capacity(building) > 0.0 and bool(building.definition().get("receives", true))


func link_reason(from_id: int, to_id: int) -> String:
	var source := state.building(from_id)
	var target := state.building(to_id)
	if source == null or target == null or not source.is_alive() or not target.is_alive():
		return MISSING
	if from_id == to_id:
		return SAME
	if not can_send(source):
		return NO_SEND
	if not can_receive(target):
		return NO_RECEIVE
	if state.find_link(from_id, to_id) != null or state.find_link(to_id, from_id) != null:
		return EXISTS
	if state.outgoing(from_id).size() >= Formulas.max_links(source):
		return FULL
	if source.position.distance_to(target.position) > Formulas.link_range(source):
		return RANGE
	return OK


func connect_buildings(from_id: int, to_id: int) -> bool:
	if link_reason(from_id, to_id) != OK:
		return false
	var link := EnergyLink.new(from_id, to_id)
	state.add_link(link)
	var target := state.building(to_id)
	events.emit("link", {"source": from_id, "target": to_id, "from": state.building(from_id).position, "to": target.position, "tower": GameConfig.is_tower(target.kind)})
	return true


func remove_link(link: EnergyLink, cause: String) -> void:
	var index := state.links.find(link)
	if index < 0:
		return
	state.remove_link_at(index)
	var points := state.link_points(link)
	events.emit("unlink", {"source": link.source, "target": link.target, "from": points[0], "to": points[1], "cause": cause})


func remove_links_of(id: int) -> void:
	for link: EnergyLink in state.links.duplicate():
		if link.source == id or link.target == id:
			remove_link(link, "destroyed")


func drop_out_of_range(id: int) -> int:
	var count := 0
	for link: EnergyLink in state.links.duplicate():
		if (link.source == id or link.target == id) and not in_range(link):
			remove_link(link, "range")
			count += 1
	return count


func in_range(link: EnergyLink) -> bool:
	var source := state.building(link.source)
	var target := state.building(link.target)
	return source != null and target != null and source.position.distance_to(target.position) <= Formulas.link_range(source)


func cut(from: Vector2, to: Vector2) -> int:
	var count := 0
	for link: EnergyLink in state.links.duplicate():
		if _crossed(link, from, to):
			remove_link(link, "cut")
			count += 1
	return count


func crosses(from: Vector2, to: Vector2) -> bool:
	for link in state.links:
		if _crossed(link, from, to):
			return true
	return false


func _crossed(link: EnergyLink, from: Vector2, to: Vector2) -> bool:
	var points := state.link_points(link)
	return Geometry2D.segment_intersects_segment(from, to, points[0], points[1]) != null


func flow(delta: float) -> void:
	var sun := state.light()
	for building in state.producers():
		var amount := Formulas.output(building)
		if amount <= 0.0:
			continue
		if building.definition().get("solar", false):
			amount *= sun
		building.energy = minf(Formulas.capacity(building), building.energy + amount * delta)
	for group: Array in groups():
		var source := state.building(group[0])
		if source != null:
			_push(source, group[1], delta)


func groups() -> Array:
	if _groups_version == state.links_version:
		return _groups
	_groups_version = state.links_version
	var grouped := {}
	_groups = []
	for link in state.links:
		if not grouped.has(link.source):
			grouped[link.source] = []
			_groups.append([link.source, grouped[link.source]])
		grouped[link.source].append(link)
	return _groups


func _push(source: Building, outgoing: Array, delta: float) -> void:
	var active: Array[EnergyLink] = []
	for link: EnergyLink in outgoing:
		link.active = in_range(link)
		if link.active:
			active.append(link)
		else:
			link.flow = lerpf(link.flow, 0.0, FLOW_SMOOTHING)
	var limit := Formulas.beam_rate(source, active.size()) * delta
	var remaining := active.size()
	for link: EnergyLink in active:
		var target := state.building(link.target)
		var share := source.energy / remaining
		remaining -= 1
		var space := maxf(Formulas.capacity(target) - target.energy, 0.0)
		var amount := minf(minf(limit, share), space)
		source.energy -= amount
		target.energy += amount
		link.flow = lerpf(link.flow, amount / delta, FLOW_SMOOTHING) if delta > 0.0 else 0.0
