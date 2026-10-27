extends SceneTree

const MAX_TIME := 1800.0
const TOWERS: Array[Vector2i] = [Vector2i(-3, -3), Vector2i(4, -3), Vector2i(-3, 4), Vector2i(4, 4)]
const EXTRA: Array[Vector2i] = [Vector2i(0, -4), Vector2i(1, 5), Vector2i(-4, 0), Vector2i(5, 1), Vector2i(-2, -4), Vector2i(3, 5), Vector2i(-4, 2), Vector2i(5, -1)]

var _levels: Array[int] = []
var _towers := 4
var _ring := 5


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			_levels.append(arg.trim_prefix("--level=").to_int())
		elif arg.begins_with("--ring="):
			_ring = arg.trim_prefix("--ring=").to_int()
		elif arg.begins_with("--towers="):
			_towers = arg.trim_prefix("--towers=").to_int()
	if _levels.is_empty():
		_levels.append(0)
	for index in _levels:
		var wall_money := _run(index, true, 0)
		_run(index, false, 0)
		_run(index, false, wall_money / int(GameConfig.building(GameConfig.ZAPPER).cost))
	quit()


func _run(index: int, walls: bool, extra: int) -> int:
	var battle := Battle.start(index)
	var state := battle.state
	BattleFixtures.open_terrain(state)
	state.rng.seed = 1
	battle.deploy_core(state.map.drop)
	state.money = 100000
	var core := state.core()
	var cells: Array[Vector2i] = []
	for i in _towers:
		cells.append(TOWERS[i % TOWERS.size()] + Vector2i(0, i / TOWERS.size()))
	for i in extra:
		cells.append(EXTRA[i % EXTRA.size()] + Vector2i(i / EXTRA.size(), 0))
	for cell in cells:
		battle.place(GameConfig.ZAPPER, state.map.center_of(core.origin + cell))
	var before := state.money
	if walls:
		for x in range(-_ring + 1, _ring + 1):
			for y in [-_ring + 1, _ring]:
				battle.place(GameConfig.BULWARK, state.map.center_of(core.origin + Vector2i(x, y)))
		for y in range(-_ring + 2, _ring):
			for x in [-_ring + 1, _ring]:
				battle.place(GameConfig.BULWARK, state.map.center_of(core.origin + Vector2i(x, y)))
	var spent := before - state.money
	battle.skip_prep()
	var first_loss := -1.0
	var lost_walls := 0
	var lost_towers := 0
	while not state.is_over() and state.time < MAX_TIME:
		for building in state.player_buildings():
			building.energy = Formulas.capacity(building)
		battle.tick(GameConfig.TICK)
		for event in battle.events.drain():
			if event.type != "building_destroyed":
				continue
			if event.kind == GameConfig.BULWARK:
				lost_walls += 1
			else:
				lost_towers += 1
				if first_loss < 0.0:
					first_loss = state.time
	var label := "walls" if walls else ("towers+%d" % extra if extra > 0 else "towers")
	print("%-12s %-10s spent=%4d %-5s t=%4d cycle=%2d first_loss=%5d lost_towers=%2d lost_walls=%3d kills=%4d core=%.2f" % [
		state.level.id, label, spent, BattleState.Phase.keys()[state.phase], int(state.time), state.cycle, int(first_loss), lost_towers, lost_walls, state.kills, state.core_ratio()])
	return spent
