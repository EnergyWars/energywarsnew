class_name Coverage
extends RefCounted

const NONE := 0
const ONE := 1
const TWO := 2
const MANY := 3
const FULL := 4
const MAX_COUNT := 255


static func level(count: int) -> int:
	return clampi(count, NONE, MANY)


static func counts(state: BattleState, sources: Array[Building]) -> PackedByteArray:
	var map := state.map
	var result := PackedByteArray()
	result.resize(map.width * map.height)
	for source in sources:
		var reach := Formulas.link_range(source)
		var limit := reach * reach
		var low := map.cell_of(source.position - Vector2(reach, reach))
		var high := map.cell_of(source.position + Vector2(reach, reach))
		for y in range(maxi(low.y, 0), mini(high.y, map.height - 1) + 1):
			for x in range(maxi(low.x, 0), mini(high.x, map.width - 1) + 1):
				var index := y * map.width + x
				if result[index] < MAX_COUNT and map.center_of(Vector2i(x, y)).distance_squared_to(source.position) <= limit:
					result[index] += 1
	return result


static func for_building(state: BattleState, exclude_id: int = -1) -> PackedByteArray:
	var open: Array[Building] = []
	var full: Array[Building] = []
	for building in state.player_buildings():
		if building.id == exclude_id or not EnergyNetwork.can_send(building):
			continue
		if state.outgoing(building.id).size() < Formulas.max_links(building):
			open.append(building)
		else:
			full.append(building)
	var open_counts := counts(state, open)
	var full_counts := counts(state, full)
	var reach := build_reach(state, exclude_id)
	var map := state.map
	var enemies := state.enemy_buildings()
	var result := PackedByteArray()
	result.resize(open_counts.size())
	for i in result.size():
		if (open_counts[i] == 0 and full_counts[i] == 0) or reach[i] == 0 or not _buildable(state, map.cell_at(i), exclude_id, enemies):
			continue
		if open_counts[i] > 0:
			result[i] = level(open_counts[i])
		elif full_counts[i] > 0:
			result[i] = FULL
	return result


static func for_receiver(state: BattleState, receiver: Building) -> PackedByteArray:
	var sources: Array[Building] = []
	for link in state.links:
		if link.target == receiver.id:
			var source := state.building(link.source)
			if source != null and source.is_alive():
				sources.append(source)
	var raw := counts(state, sources)
	var map := state.map
	var result := PackedByteArray()
	result.resize(raw.size())
	for i in result.size():
		if raw[i] > 0 and map.is_walkable(map.cell_at(i)):
			result[i] = level(raw[i])
	return result


static func build_reach(state: BattleState, exclude_id: int) -> PackedByteArray:
	var builders: Array[Building] = []
	for building in state.player_buildings():
		if building.id != exclude_id and Formulas.build_radius(building) > 0.0:
			builders.append(building)
	var map := state.map
	var result := PackedByteArray()
	result.resize(map.width * map.height)
	for builder in builders:
		var reach := Formulas.build_radius(builder)
		var limit := reach * reach
		var low := map.cell_of(builder.position - Vector2(reach, reach))
		var high := map.cell_of(builder.position + Vector2(reach, reach))
		for y in range(maxi(low.y, 0), mini(high.y, map.height - 1) + 1):
			for x in range(maxi(low.x, 0), mini(high.x, map.width - 1) + 1):
				if map.center_of(Vector2i(x, y)).distance_squared_to(builder.position) <= limit:
					result[y * map.width + x] = 1
	return result


static func _buildable(state: BattleState, cell: Vector2i, exclude_id: int, enemies: Array[Building]) -> bool:
	if not state.fog.is_explored(cell) or not state.map.is_buildable(cell):
		return false
	var occupant := state.nav.occupant_at(cell)
	if occupant != NavGrid.FREE and occupant != exclude_id:
		return false
	var center := state.map.center_of(cell)
	for building in enemies:
		if building.edge_distance(center) < GameConfig.ENEMY_NO_BUILD:
			return false
	return true
