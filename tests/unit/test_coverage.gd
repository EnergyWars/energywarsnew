extends GutTest

var battle: Battle
var state: BattleState
var core: Building


func before_each() -> void:
	battle = BattleFixtures.battle(1, false)
	state = battle.state
	core = state.core()


func _level(position: Vector2, levels: PackedByteArray) -> int:
	return levels[state.map.index(state.map.cell_of(position))]


func test_counts_cells_in_link_range() -> void:
	var counts := Coverage.counts(state, [core] as Array[Building])
	assert_eq(_level(core.position + Vector2(Formulas.link_range(core) - 30.0, 0), counts), 1)
	assert_eq(_level(core.position + Vector2(Formulas.link_range(core) + 60.0, 0), counts), 0)
	assert_eq(Coverage.level(7), Coverage.MANY)
	assert_eq(Coverage.level(0), Coverage.NONE)


func test_build_coverage_colors_by_open_senders() -> void:
	var spot := core.position + Vector2(0, -230)
	var levels := Coverage.for_building(state)
	assert_eq(_level(spot, levels), Coverage.ONE)
	assert_eq(_level(core.position, levels), Coverage.NONE)
	BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(100, -200))
	assert_eq(_level(spot, Coverage.for_building(state)), Coverage.TWO)
	var battery := BattleFixtures.add(battle, GameConfig.BATTERY, core.position + Vector2(-100, -200))
	assert_eq(_level(spot, Coverage.for_building(state)), Coverage.MANY)
	assert_eq(_level(spot, Coverage.for_building(state, battery.id)), Coverage.TWO)
	assert_eq(_level(core.position + Vector2(0, -2000), Coverage.for_building(state)), Coverage.NONE)


func test_full_senders_show_blue() -> void:
	var spot := core.position + Vector2(0, -230)
	for i in Formulas.max_links(core):
		var zapper := BattleFixtures.add(battle, GameConfig.ZAPPER, core.position + Vector2(-120 + i * 120, 160))
		battle.connect_buildings(core.id, zapper.id)
	assert_eq(_level(spot, Coverage.for_building(state)), Coverage.FULL)


func test_build_coverage_skips_unbuildable_cells() -> void:
	var spot := core.position + Vector2(0, -230)
	var cell := state.map.cell_of(spot)
	state.map.set_tile(cell, LevelMap.Tile.TREE)
	assert_eq(_level(spot, Coverage.for_building(state)), Coverage.NONE)
	state.map.set_tile(cell, LevelMap.Tile.OPEN)
	state.fog.cells[state.map.index(cell)] = FogOfWar.HIDDEN
	assert_eq(_level(spot, Coverage.for_building(state)), Coverage.NONE)
	state.fog.cells[state.map.index(cell)] = FogOfWar.VISIBLE
	BattleFixtures.add(battle, GameConfig.BULWARK, spot)
	assert_eq(_level(spot, Coverage.for_building(state)), Coverage.NONE)
	var nest := BattleFixtures.add(battle, GameConfig.NEST, core.position + Vector2(260, 0))
	assert_eq(_level(nest.position + Vector2(-90, 0), Coverage.for_building(state)), Coverage.NONE)


func test_receiver_coverage_follows_its_sources() -> void:
	var rover := BattleFixtures.add(battle, GameConfig.ROVER, core.position + Vector2(0, -150))
	var empty := Coverage.for_receiver(state, rover)
	assert_eq(_level(rover.position, empty), Coverage.NONE)
	battle.connect_buildings(core.id, rover.id)
	var relay := BattleFixtures.add(battle, GameConfig.RELAY, core.position + Vector2(200, -100))
	battle.connect_buildings(relay.id, rover.id)
	var levels := Coverage.for_receiver(state, rover)
	assert_eq(_level(core.position + Vector2(100, -100), levels), Coverage.TWO)
	assert_eq(_level(core.position + Vector2(-250, 0), levels), Coverage.ONE)
	assert_eq(_level(core.position + Vector2(0, -900), levels), Coverage.NONE)
