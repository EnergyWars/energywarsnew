extends SceneTree

var _frames := 0
var _out := "user://screenshot.png"
var _level := -1
var _seconds := 0.0
var _rich := false
var _connect := false
var _locale := ""
var _select := ""
var _build := ""
var _result := ""
var _deploy := false
var _reveal := false
var _zoom := 0.0
var _drop := false
var _main: Node


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--level="):
			_level = arg.trim_prefix("--level=").to_int()
		elif arg.begins_with("--simulate="):
			_seconds = arg.trim_prefix("--simulate=").to_float()
		elif arg == "--rich":
			_rich = true
		elif arg == "--connect":
			_connect = true
		elif arg.begins_with("--locale="):
			_locale = arg.trim_prefix("--locale=")
		elif arg.begins_with("--select="):
			_select = arg.trim_prefix("--select=")
		elif arg.begins_with("--build="):
			_build = arg.trim_prefix("--build=")
		elif arg.begins_with("--result="):
			_result = arg.trim_prefix("--result=")
		elif arg == "--deploy":
			_deploy = true
		elif arg == "--drop":
			_drop = true
		elif arg == "--reveal":
			_reveal = true
		elif arg.begins_with("--zoom="):
			_zoom = arg.trim_prefix("--zoom=").to_float()
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 3:
		_main.progress = Progress.new("user://screenshot_progress.json")
		if not _locale.is_empty():
			TranslationServer.set_locale(_locale)
			if _level < 0:
				_main.show_menu()
		if _level >= 0:
			_main.progress.record(_level - 1, 3, 0, 0)
			_main.start_level(_level)
	if _frames == 8 and _level >= 0:
		_prepare(_main.screen as BattleScreen)
	if _frames == _capture_frame():
		var image := root.get_texture().get_image()
		image.save_png(_out)
		print("saved ", ProjectSettings.globalize_path(_out))
		return true
	return false


func _prepare(screen: BattleScreen) -> void:
	var battle := screen.battle
	var state := battle.state
	state.scout.drop_left = GameConfig.DROP_TIME * 0.6 if _drop else 0.0
	if _reveal:
		state.fog.cells.fill(FogOfWar.VISIBLE)
		state.fog.version += 1
	if _deploy or _rich or not _select.is_empty() or not _build.is_empty() or not _result.is_empty():
		state.fog.reveal(state.map.drop, 900.0)
		if _rich:
			BattleFixtures.open_terrain(state)
		battle.deploy_core(state.map.drop)
		for event in battle.events.drain():
			screen._on_event(event)
	if _rich:
		state.money = 5000
		var core := state.core()
		var spots := {
			"solar_a": [GameConfig.SOLAR, Vector2(-150, 40)],
			"solar_b": [GameConfig.SOLAR, Vector2(150, 40)],
			"solar_c": [GameConfig.SOLAR, Vector2(-150, -70)],
			"battery": [GameConfig.BATTERY, Vector2(140, -110)],
			"exporter": [GameConfig.EXPORTER, Vector2(-10, -135)],
			"relay": [GameConfig.RELAY, Vector2(0, -250)],
			"zap_a": [GameConfig.ZAPPER, Vector2(-170, -300)],
			"zap_b": [GameConfig.ZAPPER, Vector2(170, -300)],
			"relay_b": [GameConfig.RELAY, Vector2(0, -560)],
			"tower": [GameConfig.available_kinds(_level).back(), Vector2(-130, -620)],
			"healer": [GameConfig.HEALER, Vector2(150, -430)],
			"bulwark": [GameConfig.BULWARK, Vector2(110, -660)],
		}
		var ids := {"core": core.id}
		for key: String in spots:
			var entry: Array = spots[key]
			if battle.place(entry[0], core.position + entry[1]) == BuildRules.OK:
				ids[key] = state.player_buildings().back().id
		for pair in [["solar_a", "core"], ["solar_b", "battery"], ["solar_c", "core"], ["core", "relay"], ["core", "exporter"], ["battery", "relay"], ["relay", "zap_a"], ["relay", "zap_b"], ["relay", "relay_b"], ["relay_b", "tower"], ["relay_b", "healer"], ["relay_b", "bulwark"]]:
			if ids.has(pair[0]) and ids.has(pair[1]):
				battle.connect_buildings(ids[pair[0]], ids[pair[1]])
		var origin := core.origin
		for x in range(-6, 8):
			for y in [-14, 5]:
				battle.place(GameConfig.BULWARK, state.map.center_of(origin + Vector2i(x, y)))
		for y in range(-13, 5):
			for x in [-6, 7]:
				battle.place(GameConfig.BULWARK, state.map.center_of(origin + Vector2i(x, y)))
		for building in state.player_buildings():
			building.energy = Formulas.capacity(building) * 0.7
		battle.skip_prep()
	var steps := int(_seconds / GameConfig.TICK)
	for i in steps:
		battle.tick(GameConfig.TICK)
	var events := battle.events.drain()
	for event in events:
		screen._on_event(event)
	screen.rewards.handle(events)
	if _rich:
		screen.view.focus(state.core().position + Vector2(0, -380))
	if _connect:
		screen.view.set_mode(BattleView.Mode.CONNECT)
	if _zoom > 0.0:
		screen.view.zoom = _zoom
		screen.view.focus(state.map.drop + Vector2(0, -400))
	if not _build.is_empty():
		screen.choose_kind(_build)
		screen.view.begin(state.core().position + Vector2(0, -180))
	if not _select.is_empty():
		for building in state.player_buildings():
			if building.kind == _select:
				screen.view.select(building.id)
				break
	if _result == "win":
		for building in state.enemy_buildings():
			battle.combat.destroy(building)
		battle.tick(GameConfig.TICK)
	elif _result == "lose":
		battle.combat.destroy(state.core())
		battle.tick(GameConfig.TICK)


func _capture_frame() -> int:
	return 220 if not _result.is_empty() else 40
