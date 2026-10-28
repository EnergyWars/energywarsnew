class_name EnergyAudit
extends RefCounted

enum Verdict { NONE, OK, NIGHT, LOW, STARVED, OFFLINE, OVERLOADED }
enum Cause { NONE, OVERLOAD, NO_SOURCE, OUT_OF_RANGE, BEAM_RATE, BEAM_LOSS, GENERATION, NIGHT }

const DAY := 0
const NIGHT := 1
const SCENARIOS := 2
const SATISFIED := 0.98
const STARVED_BELOW := 0.02
const SATURATED := 0.98
const HEAVY_LOSS := 0.2
const EPSILON := 0.001
const MAX_PASSES := 12
const MIN_YIELD := 0.01

var order: Array[int] = []
var demand := {}
var generation: Array[Dictionary] = [{}, {}]
var supplied: Array[Dictionary] = [{}, {}]
var received: Array[Dictionary] = [{}, {}]
var forwarded: Array[Dictionary] = [{}, {}]
var sent: Array[Dictionary] = [{}, {}]
var wanted: Array[Dictionary] = [{}, {}]
var lost := PackedFloat64Array([0.0, 0.0])
var moved := PackedFloat64Array([0.0, 0.0])
var yields := {}
var caps := {}
var active := {}
var verdicts := {}
var causes := {}
var culprits := {}
var culprit_links := {}
var _buildings := {}
var _incoming := {}
var _outgoing := {}
var _sourced := {}
var _links: Array[EnergyLink] = []
var _cyclic := false


static func measure(state: BattleState) -> EnergyAudit:
	var audit := EnergyAudit.new()
	audit._collect(state)
	var need := audit._needs()
	for scenario in SCENARIOS:
		audit._solve(scenario, need)
	audit._judge()
	return audit


static func draw(building: Building) -> float:
	if building.exporting:
		return Formulas.export_rate(building)
	return EnergyStats.fire_draw(building)


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


func verdict(id: int) -> Verdict:
	return verdicts.get(id, Verdict.NONE)


func cause(id: int) -> Cause:
	return causes.get(id, Cause.NONE)


func culprit(id: int) -> int:
	return int(culprits.get(id, -1))


func culprit_link(id: int) -> String:
	return str(culprit_links.get(id, ""))


func need_of(id: int) -> float:
	return float(demand.get(id, 0.0))


func supply(id: int, scenario: int = DAY) -> float:
	return float(supplied[scenario].get(id, 0.0))


func ratio(id: int, scenario: int = DAY) -> float:
	var wish := need_of(id)
	return 1.0 if wish <= 0.0 else clampf(supply(id, scenario) / wish, 0.0, 1.0)


func shortfall(id: int, scenario: int = DAY) -> float:
	return maxf(need_of(id) - supply(id, scenario), 0.0)


func inflow(id: int, scenario: int = DAY) -> float:
	return float(received[scenario].get(id, 0.0))


func throughput(id: int, scenario: int = DAY) -> float:
	return float(forwarded[scenario].get(id, 0.0))


func flow(key: String, scenario: int = DAY) -> float:
	return float(sent[scenario].get(key, 0.0))


func link_yield(key: String) -> float:
	return float(yields.get(key, 1.0))


func is_active(key: String) -> bool:
	return bool(active.get(key, false))


func is_saturated(key: String, scenario: int = DAY) -> bool:
	var cap := float(caps.get(key, 0.0))
	return cap > 0.0 and float(wanted[scenario].get(key, 0.0)) > cap + EPSILON and flow(key, scenario) >= cap * SATURATED


func loss_rate(scenario: int = DAY) -> float:
	return lost[scenario]


func transfer_efficiency(scenario: int = DAY) -> float:
	return (moved[scenario] - lost[scenario]) / moved[scenario] if moved[scenario] > EPSILON else 1.0


func supply_ratio(scenario: int = DAY) -> float:
	var wish := 0.0
	var got := 0.0
	for id: int in demand:
		wish += float(demand[id])
		got += supply(id, scenario)
	return got / wish if wish > EPSILON else 1.0


func export_income(scenario: int = DAY) -> float:
	var energy := 0.0
	for id: int in _buildings:
		if (_buildings[id] as Building).exporting:
			energy += supply(id, scenario)
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


func _collect(state: BattleState) -> void:
	for building in state.player_buildings():
		if Formulas.capacity(building) <= 0.0 and Formulas.output(building) <= 0.0:
			continue
		var id := building.id
		_buildings[id] = building
		_incoming[id] = []
		_outgoing[id] = []
		demand[id] = 0.0 if Formulas.is_overloaded(building) else draw(building)
		var output := Formulas.output(building)
		generation[DAY][id] = output
		generation[NIGHT][id] = 0.0 if bool(building.definition().get("solar", false)) else output
	for link in state.links:
		if not _buildings.has(link.source) or not _buildings.has(link.target):
			continue
		var source: Building = _buildings[link.source]
		var target: Building = _buildings[link.target]
		var key := link.key()
		var distance := source.position.distance_to(target.position)
		var live := distance <= Formulas.link_range(source)
		_links.append(link)
		_incoming[link.target].append(link)
		active[key] = live
		yields[key] = Formulas.beam_efficiency(source, distance)
		if live:
			_outgoing[link.source].append(link)
	for id: int in _outgoing:
		var beams: int = _outgoing[id].size()
		for link: EnergyLink in _outgoing[id]:
			caps[link.key()] = Formulas.beam_rate(_buildings[id], beams)
	order = _topological()
	_mark_sources()


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
	for id: int in _buildings:
		if float(generation[DAY][id]) > 0.0:
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


func _needs() -> Dictionary:
	var need := {}
	for id: int in _buildings:
		need[id] = float(demand[id])
	var reverse := order.duplicate()
	reverse.reverse()
	for pass_index in MAX_PASSES:
		var change := 0.0
		for id: int in reverse:
			var total := float(demand[id])
			for link: EnergyLink in _outgoing[id]:
				var key := link.key()
				total += minf(float(caps[key]), float(need[link.target]) / maxf(float(yields[key]), MIN_YIELD))
			change = maxf(change, absf(total - float(need[id])))
			need[id] = total
		if change < EPSILON or not _cyclic:
			break
	return need


func _solve(scenario: int, need: Dictionary) -> void:
	var delivered := {}
	var flows := {}
	for link in _links:
		delivered[link.key()] = 0.0
		flows[link.key()] = 0.0
	var passes := MAX_PASSES if _cyclic else 1
	for pass_index in passes:
		var change := 0.0
		for id in order:
			change = maxf(change, _distribute(scenario, id, need, delivered, flows))
		if change < EPSILON:
			break
	for id: int in _buildings:
		var gathered := 0.0
		for link: EnergyLink in _incoming[id]:
			gathered += float(delivered[link.key()])
		var out := 0.0
		for link: EnergyLink in _outgoing[id]:
			out += float(flows[link.key()])
		received[scenario][id] = gathered
		forwarded[scenario][id] = out
		supplied[scenario][id] = clampf(float(generation[scenario][id]) + gathered - out, 0.0, float(demand[id]))
	for link in _links:
		var key := link.key()
		var amount := float(flows[key])
		sent[scenario][key] = amount
		moved[scenario] += amount
		lost[scenario] += amount * (1.0 - float(yields[key]))


func _distribute(scenario: int, id: int, need: Dictionary, delivered: Dictionary, flows: Dictionary) -> float:
	var links: Array = _outgoing[id]
	if links.is_empty():
		return 0.0
	var budget := float(generation[scenario][id])
	for link: EnergyLink in _incoming[id]:
		budget += float(delivered[link.key()])
	var limits := PackedFloat64Array()
	for link: EnergyLink in links:
		var key := link.key()
		var other := float(generation[scenario][link.target])
		for incoming: EnergyLink in _incoming[link.target]:
			if incoming != link:
				other += float(delivered[incoming.key()])
		var want := maxf(float(need[link.target]) - other, 0.0) / maxf(float(yields[key]), MIN_YIELD)
		wanted[scenario][key] = want
		limits.append(minf(float(caps[key]), want))
	var shares := water_fill(budget, limits)
	var change := 0.0
	for i in links.size():
		var key: String = (links[i] as EnergyLink).key()
		change = maxf(change, absf(shares[i] - float(flows[key])))
		flows[key] = shares[i]
		delivered[key] = shares[i] * float(yields[key])
	return change


func _judge() -> void:
	for id: int in _buildings:
		var building: Building = _buildings[id]
		if Formulas.is_overloaded(building):
			_rule(id, Verdict.OVERLOADED, Cause.OVERLOAD)
		elif not _sourced.has(id):
			_offline(id)
		elif float(demand[id]) <= 0.0:
			_rule(id, Verdict.OK, Cause.NONE)
		elif ratio(id, DAY) >= SATISFIED:
			if ratio(id, NIGHT) >= SATISFIED:
				_rule(id, Verdict.OK, Cause.NONE)
			else:
				_rule(id, Verdict.NIGHT, Cause.NIGHT)
		else:
			_rule(id, Verdict.LOW if ratio(id, DAY) > STARVED_BELOW else Verdict.STARVED, Cause.GENERATION)
			_bottleneck(id)


func _rule(id: int, value: Verdict, reason: Cause, link: EnergyLink = null) -> void:
	verdicts[id] = value
	causes[id] = reason
	culprits[id] = link.source if link != null else -1
	culprit_links[id] = link.key() if link != null else ""


func _offline(id: int) -> void:
	var seen := {id: true}
	var queue: Array[int] = [id]
	var head := 0
	while head < queue.size():
		var current := queue[head]
		head += 1
		for link: EnergyLink in _incoming[current]:
			if not is_active(link.key()):
				_rule(id, Verdict.OFFLINE, Cause.OUT_OF_RANGE, link)
				return
			if not seen.has(link.source):
				seen[link.source] = true
				queue.append(link.source)
	_rule(id, Verdict.OFFLINE, Cause.NO_SOURCE)


func _bottleneck(id: int) -> void:
	var seen := {id: true}
	var queue: Array[int] = [id]
	var head := 0
	var broken: EnergyLink = null
	var lossy: EnergyLink = null
	while head < queue.size():
		var current := queue[head]
		head += 1
		for link: EnergyLink in _incoming[current]:
			var key := link.key()
			if not is_active(key):
				if broken == null:
					broken = link
				continue
			if is_saturated(key, DAY):
				_rule(id, verdicts[id], Cause.BEAM_RATE, link)
				return
			if lossy == null and 1.0 - link_yield(key) >= HEAVY_LOSS:
				lossy = link
			if not seen.has(link.source):
				seen[link.source] = true
				queue.append(link.source)
	if broken != null:
		_rule(id, verdicts[id], Cause.OUT_OF_RANGE, broken)
	elif lossy != null:
		_rule(id, verdicts[id], Cause.BEAM_LOSS, lossy)
