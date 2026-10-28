class_name EnergyAudit
extends RefCounted

enum Verdict { NONE, OK, LOW, OVERLOADED }
enum Cause { NONE, OVERLOAD, NO_SOURCE, OUT_OF_RANGE, BEAM_RATE, BEAM_LOSS, GENERATION, NIGHT, STORAGE }

const DAY := 0
const NIGHT := 1
const WORST := 2
const SCENARIOS := 2
const SATISFIED := 0.98
const SATURATED := 0.98
const HEAVY_LOSS := 0.15
const LOSSLESS := 0.005
const RESERVE_SHARE := 0.1
const EPSILON := 0.001
const MAX_PASSES := 12
const MIN_YIELD := 0.01

var order: Array[int] = []
var demand := {}
var needs := {}
var generation: Array[Dictionary] = [{}, {}]
var storage: Array[Dictionary] = [{}, {}]
var gathered: Array[Dictionary] = [{}, {}]
var served: Array[Dictionary] = [{}, {}]
var received: Array[Dictionary] = [{}, {}]
var forwarded: Array[Dictionary] = [{}, {}]
var sent: Array[Dictionary] = [{}, {}]
var wanted: Array[Dictionary] = [{}, {}]
var lost := PackedFloat64Array([0.0, 0.0])
var moved := PackedFloat64Array([0.0, 0.0])
var yields := {}
var caps := {}
var active := {}
var verdicts: Array[Dictionary] = [{}, {}]
var causes: Array[Dictionary] = [{}, {}]
var culprits: Array[Dictionary] = [{}, {}]
var culprit_links: Array[Dictionary] = [{}, {}]
var _buildings := {}
var _incoming := {}
var _outgoing := {}
var _sourced := {}
var _producers := {}
var _targets := {}
var _links: Array[EnergyLink] = []
var _cyclic := false


static func measure(state: BattleState) -> EnergyAudit:
	var audit := EnergyAudit.new()
	audit._collect(state)
	audit._needs()
	for scenario in SCENARIOS:
		audit._solve(scenario)
	for scenario in SCENARIOS:
		audit._judge(scenario)
	return audit


static func draw(building: Building) -> float:
	if building.exporting:
		return Formulas.export_rate(building)
	return EnergyStats.fire_draw(building)


static func view_scenario(state: BattleState) -> int:
	if state.is_fighting():
		return NIGHT if state.is_night() else DAY
	return WORST


static func water_fill(budget: float, limits: PackedFloat64Array) -> PackedFloat64Array:
	var result := PackedFloat64Array()
	result.resize(limits.size())
	var open: Array[int] = []
	for i in limits.size():
		if limits[i] > EPSILON:
			open.append(i)
	var left := maxf(budget, 0.0)
	while not open.is_empty() and left > EPSILON:
		var share := left / open.size()
		var still: Array[int] = []
		for i in open:
			var room := limits[i] - result[i]
			if room <= share:
				result[i] += room
				left -= room
			else:
				still.append(i)
		if still.size() == open.size():
			for i in still:
				result[i] += share
			break
		open = still
	return result


func has(id: int) -> bool:
	return _buildings.has(id)


func shows(id: int) -> bool:
	return has(id) and not _producers.has(id)


func resolve(id: int, scenario: int = WORST) -> int:
	if scenario != WORST:
		return scenario
	return NIGHT if _ratio(id, NIGHT) < _ratio(id, DAY) - EPSILON else DAY


func link_scenario(key: String, scenario: int = WORST) -> int:
	return resolve(int(_targets.get(key, -1)), scenario)


func verdict(id: int, scenario: int = WORST) -> Verdict:
	if not shows(id):
		return Verdict.NONE
	return verdicts[resolve(id, scenario)].get(id, Verdict.NONE)


func cause(id: int, scenario: int = WORST) -> Cause:
	if not shows(id):
		return Cause.NONE
	return causes[resolve(id, scenario)].get(id, Cause.NONE)


func culprit(id: int, scenario: int = WORST) -> int:
	return int(culprits[resolve(id, scenario)].get(id, -1))


func culprit_link(id: int, scenario: int = WORST) -> String:
	return str(culprit_links[resolve(id, scenario)].get(id, ""))


func need_of(id: int) -> float:
	return float(needs.get(id, 0.0))


func demand_of(id: int) -> float:
	return float(demand.get(id, 0.0))


func available(id: int, scenario: int = WORST) -> float:
	return float(gathered[resolve(id, scenario)].get(id, 0.0))


func supply(id: int, scenario: int = WORST) -> float:
	return minf(available(id, scenario), need_of(id))


func ratio(id: int, scenario: int = WORST) -> float:
	return _ratio(id, resolve(id, scenario))


func missing(id: int, scenario: int = WORST) -> float:
	return 1.0 - ratio(id, scenario) if verdict(id, scenario) == Verdict.LOW else 0.0


func shortfall(id: int, scenario: int = WORST) -> float:
	return maxf(need_of(id) - available(id, scenario), 0.0)


func served_of(id: int, scenario: int = DAY) -> float:
	return float(served[scenario].get(id, 0.0))


func inflow(id: int, scenario: int = WORST) -> float:
	return float(received[resolve(id, scenario)].get(id, 0.0))


func throughput(id: int, scenario: int = WORST) -> float:
	return float(forwarded[resolve(id, scenario)].get(id, 0.0))


func reserve_rate(id: int) -> float:
	return float(storage[NIGHT].get(id, 0.0))


func night_reserve(id: int) -> float:
	var building: Building = _buildings.get(id)
	if building == null or reserve_rate(id) <= 0.0:
		return INF
	var drain := need_of(id) - float(generation[NIGHT][id]) - float(received[NIGHT][id])
	return Formulas.capacity(building) / drain if drain > EPSILON else INF


func flow(key: String, scenario: int = WORST) -> float:
	return float(sent[link_scenario(key, scenario)].get(key, 0.0))


func delivered(key: String, scenario: int = WORST) -> float:
	return flow(key, scenario) * link_yield(key)


func link_cap(key: String) -> float:
	return float(caps.get(key, 0.0))


func link_yield(key: String) -> float:
	return float(yields.get(key, 1.0))


func link_loss(key: String) -> float:
	return 1.0 - link_yield(key)


func is_active(key: String) -> bool:
	return bool(active.get(key, false))


func is_saturated(key: String, scenario: int = WORST) -> bool:
	return _saturated(key, link_scenario(key, scenario))


func loss_rate(scenario: int = DAY) -> float:
	return lost[scenario]


func transfer_efficiency(scenario: int = DAY) -> float:
	return (moved[scenario] - lost[scenario]) / moved[scenario] if moved[scenario] > EPSILON else 1.0


func supply_ratio(scenario: int = DAY) -> float:
	var wish := 0.0
	var got := 0.0
	for id: int in demand:
		wish += float(demand[id])
		got += served_of(id, scenario)
	return got / wish if wish > EPSILON else 1.0


func export_income(scenario: int = DAY) -> float:
	var energy := 0.0
	for id: int in _buildings:
		if (_buildings[id] as Building).exporting:
			energy += served_of(id, scenario)
	return Formulas.export_income(energy)


func chain(id: int) -> Dictionary:
	var buildings: Array[int] = []
	var links: Array[String] = []
	if not has(id):
		return {"buildings": buildings, "links": links}
	var seen := {id: true}
	var queue: Array[int] = [id]
	var head := 0
	while head < queue.size():
		var current := queue[head]
		head += 1
		for link: EnergyLink in _incoming[current]:
			links.append(link.key())
			if not seen.has(link.source):
				seen[link.source] = true
				buildings.append(link.source)
				queue.append(link.source)
	return {"buildings": buildings, "links": links}


func _ratio(id: int, scenario: int) -> float:
	if not has(id):
		return 1.0
	var wish := need_of(id)
	if wish <= EPSILON:
		return 1.0 if _sourced.has(id) else 0.0
	return clampf(float(gathered[scenario][id]) / wish, 0.0, 1.0)


func _saturated(key: String, scenario: int) -> bool:
	var cap := float(caps.get(key, 0.0))
	return cap > 0.0 and float(wanted[scenario].get(key, 0.0)) > cap + EPSILON and float(sent[scenario].get(key, 0.0)) >= cap * SATURATED


func _collect(state: BattleState) -> void:
	var night := maxf(float(state.level.get("night", 1.0)), 1.0)
	for building in state.player_buildings():
		if Formulas.capacity(building) <= 0.0 and Formulas.output(building) <= 0.0:
			continue
		var id := building.id
		_buildings[id] = building
		_incoming[id] = []
		_outgoing[id] = []
		demand[id] = 0.0 if Formulas.is_overloaded(building) else draw(building)
		var output := Formulas.output(building)
		var solar := bool(building.definition().get("solar", false))
		if output > 0.0:
			_producers[id] = true
		generation[DAY][id] = output
		generation[NIGHT][id] = 0.0 if solar else output
		storage[DAY][id] = 0.0
		storage[NIGHT][id] = Formulas.capacity(building) / night if Formulas.max_links(building) > 0 and not solar else 0.0
	for link in state.links:
		if not _buildings.has(link.source) or not _buildings.has(link.target):
			continue
		var source: Building = _buildings[link.source]
		var target: Building = _buildings[link.target]
		var key := link.key()
		var live := source.position.distance_to(target.position) <= Formulas.link_range(source)
		_links.append(link)
		_incoming[link.target].append(link)
		_targets[key] = link.target
		active[key] = live
		yields[key] = Formulas.link_efficiency(source, target)
		if live:
			_outgoing[link.source].append(link)
	for id: int in _outgoing:
		var beams: int = _outgoing[id].size()
		for link: EnergyLink in _outgoing[id]:
			caps[link.key()] = Formulas.beam_rate(_buildings[id], beams)
	order = _topological()
	_mark_sources()
	for id: int in _buildings:
		if not _sourced.has(id):
			storage[NIGHT][id] = 0.0


func _topological() -> Array[int]:
	var indegree := {}
	for id: int in _buildings:
		indegree[id] = 0
	for id: int in _outgoing:
		for link: EnergyLink in _outgoing[id]:
			indegree[link.target] = int(indegree[link.target]) + 1
	var queue: Array[int] = []
	for id: int in _buildings:
		if int(indegree[id]) == 0:
			queue.append(id)
	var head := 0
	while head < queue.size():
		var id := queue[head]
		head += 1
		for link: EnergyLink in _outgoing[id]:
			indegree[link.target] = int(indegree[link.target]) - 1
			if int(indegree[link.target]) == 0:
				queue.append(link.target)
	if queue.size() < _buildings.size():
		_cyclic = true
		var placed := {}
		for id in queue:
			placed[id] = true
		for id: int in _buildings:
			if not placed.has(id):
				queue.append(id)
	return queue


func _mark_sources() -> void:
	var queue: Array[int] = []
	for id: int in _producers:
		_sourced[id] = true
		queue.append(id)
	var head := 0
	while head < queue.size():
		var id := queue[head]
		head += 1
		for link: EnergyLink in _outgoing[id]:
			if not _sourced.has(link.target):
				_sourced[link.target] = true
				queue.append(link.target)


func _needs() -> void:
	for id: int in _buildings:
		needs[id] = float(demand[id])
	var reverse := order.duplicate()
	reverse.reverse()
	for pass_index in MAX_PASSES:
		var change := 0.0
		for id: int in reverse:
			var total := float(demand[id])
			for link: EnergyLink in _outgoing[id]:
				var key := link.key()
				total += minf(float(caps[key]), float(needs[link.target]) / maxf(float(yields[key]), MIN_YIELD))
			change = maxf(change, absf(total - float(needs[id])))
			needs[id] = total
		if change < EPSILON or not _cyclic:
			break


func _own(scenario: int, id: int) -> float:
	return float(generation[scenario][id]) + float(storage[scenario][id])


func _solve(scenario: int) -> void:
	var delivered_by := {}
	var flows := {}
	for link in _links:
		delivered_by[link.key()] = 0.0
		flows[link.key()] = 0.0
	var passes := MAX_PASSES if _cyclic else 1
	for pass_index in passes:
		var change := 0.0
		for id in order:
			change = maxf(change, _distribute(scenario, id, delivered_by, flows))
		if change < EPSILON:
			break
	for id: int in _buildings:
		var incoming := 0.0
		for link: EnergyLink in _incoming[id]:
			incoming += float(delivered_by[link.key()])
		var out := 0.0
		for link: EnergyLink in _outgoing[id]:
			out += float(flows[link.key()])
		var total := _own(scenario, id) + incoming
		received[scenario][id] = incoming
		forwarded[scenario][id] = out
		gathered[scenario][id] = total
		served[scenario][id] = clampf(total - out, 0.0, float(demand[id]))
	for link in _links:
		var key := link.key()
		var amount := float(flows[key])
		sent[scenario][key] = amount
		moved[scenario] += amount
		lost[scenario] += amount * (1.0 - float(yields[key]))


func _distribute(scenario: int, id: int, delivered_by: Dictionary, flows: Dictionary) -> float:
	var links: Array = _outgoing[id]
	if links.is_empty():
		return 0.0
	var budget := _own(scenario, id)
	for link: EnergyLink in _incoming[id]:
		budget += float(delivered_by[link.key()])
	var limits := PackedFloat64Array()
	for link: EnergyLink in links:
		var key := link.key()
		var other := _own(scenario, link.target)
		for incoming: EnergyLink in _incoming[link.target]:
			if incoming != link:
				other += float(delivered_by[incoming.key()])
		var want := maxf(float(needs[link.target]) - other, 0.0) / maxf(float(yields[key]), MIN_YIELD)
		wanted[scenario][key] = want
		limits.append(minf(float(caps[key]), want))
	var shares := water_fill(budget, limits)
	var change := 0.0
	for i in links.size():
		var key: String = (links[i] as EnergyLink).key()
		change = maxf(change, absf(shares[i] - float(flows[key])))
		flows[key] = shares[i]
		delivered_by[key] = shares[i] * float(yields[key])
	return change


func _judge(scenario: int) -> void:
	for id: int in _buildings:
		if _producers.has(id):
			continue
		var building: Building = _buildings[id]
		if Formulas.is_overloaded(building):
			_rule(scenario, id, Verdict.OVERLOADED, Cause.OVERLOAD)
		elif not _sourced.has(id):
			_offline(scenario, id)
		elif _ratio(id, scenario) >= SATISFIED:
			_rule(scenario, id, Verdict.OK, Cause.NONE)
		else:
			_rule(scenario, id, Verdict.LOW, Cause.GENERATION)
			_bottleneck(scenario, id)


func _rule(scenario: int, id: int, value: Verdict, reason: Cause, link: EnergyLink = null, blamed: int = -1) -> void:
	verdicts[scenario][id] = value
	causes[scenario][id] = reason
	culprits[scenario][id] = link.source if link != null else blamed
	culprit_links[scenario][id] = link.key() if link != null else ""


func _offline(scenario: int, id: int) -> void:
	var seen := {id: true}
	var queue: Array[int] = [id]
	var head := 0
	while head < queue.size():
		var current := queue[head]
		head += 1
		for link: EnergyLink in _incoming[current]:
			if not is_active(link.key()):
				_rule(scenario, id, Verdict.LOW, Cause.OUT_OF_RANGE, link)
				return
			if not seen.has(link.source):
				seen[link.source] = true
				queue.append(link.source)
	_rule(scenario, id, Verdict.LOW, Cause.NO_SOURCE)


func _drains(id: int) -> bool:
	var reserve := float(storage[NIGHT][id])
	return reserve > 0.0 and reserve >= RESERVE_SHARE * need_of(id) and _ratio(id, NIGHT) < SATISFIED


func _bottleneck(scenario: int, id: int) -> void:
	var night_only := scenario == NIGHT and _ratio(id, DAY) >= SATISFIED
	var seen := {id: true}
	var queue: Array[int] = [id]
	var head := 0
	var broken: EnergyLink = null
	var lossy: EnergyLink = null
	var saturated: EnergyLink = null
	var drained := -1
	while head < queue.size():
		var current := queue[head]
		head += 1
		if drained < 0 and _drains(current):
			drained = current
		for link: EnergyLink in _incoming[current]:
			var key := link.key()
			if not is_active(key):
				if broken == null:
					broken = link
				continue
			if saturated == null and _saturated(key, scenario):
				saturated = link
			if lossy == null and link_loss(key) >= HEAVY_LOSS:
				lossy = link
			if not seen.has(link.source):
				seen[link.source] = true
				queue.append(link.source)
	var darker := scenario == NIGHT and _ratio(id, NIGHT) < _ratio(id, DAY) - EPSILON
	if night_only:
		_blame_night(scenario, id, drained)
	elif saturated != null:
		_rule(scenario, id, Verdict.LOW, Cause.BEAM_RATE, saturated)
	elif broken != null:
		_rule(scenario, id, Verdict.LOW, Cause.OUT_OF_RANGE, broken)
	elif lossy != null:
		_rule(scenario, id, Verdict.LOW, Cause.BEAM_LOSS, lossy)
	elif darker:
		_blame_night(scenario, id, drained)


func _blame_night(scenario: int, id: int, drained: int) -> void:
	if drained >= 0:
		_rule(scenario, id, Verdict.LOW, Cause.STORAGE, null, drained)
	else:
		_rule(scenario, id, Verdict.LOW, Cause.NIGHT)
