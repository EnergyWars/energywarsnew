extends Node

var settings: AppSettings
var progress: Progress
var sfx: SfxPlayer
var screen: Node
var menu: WorldMapScreen
var last_index := 0
var last_rules: BattleSetup


func _ready() -> void:
	settings = AppSettings.new().load_settings()
	settings.apply()
	progress = Progress.new().load_progress()
	sfx = SfxPlayer.new().setup(settings)
	add_child(sfx)
	RenderingServer.set_default_clear_color(AppTheme.BACKGROUND)
	show_menu()


func safe_top() -> float:
	var safe := DisplayServer.get_display_safe_area()
	var screen_size := DisplayServer.screen_get_size()
	if screen_size.y <= 0:
		return 0.0
	return safe.position.y * get_viewport().get_visible_rect().size.y / screen_size.y


func _replace(next: Node) -> void:
	if is_instance_valid(screen):
		screen.queue_free()
	screen = next
	add_child(next)


func show_menu() -> void:
	var layer := CanvasLayer.new()
	menu = WorldMapScreen.new().setup(progress, settings, safe_top())
	menu.campaign_chosen.connect(start_campaign)
	menu.survival_chosen.connect(start_survival)
	menu.locale_changed.connect(show_menu)
	menu.progress_reset.connect(show_menu)
	layer.add_child(menu)
	_replace(layer)


func start_campaign(index: int) -> void:
	if Campaign.is_unlocked(progress, index):
		_start(index, BattleSetup.campaign(progress.arsenal()))


func start_survival(index: int, days: int) -> void:
	if progress.is_conquered(index):
		_start(index, BattleSetup.survival(days, progress.arsenal()))


func retry() -> void:
	if last_rules != null:
		_start(last_index, BattleSetup.new(last_rules.mode, last_rules.days, progress.arsenal()))


func resume(checkpoint: BattleCheckpoint) -> void:
	if checkpoint != null:
		_start(checkpoint.level_index, checkpoint.setup, checkpoint)


func _start(index: int, rules: BattleSetup, checkpoint: BattleCheckpoint = null) -> void:
	last_index = index
	last_rules = rules
	var battle := BattleScreen.new().setup(index, progress, settings, sfx, safe_top(), rules, checkpoint)
	battle.menu_requested.connect(show_menu)
	battle.retry_requested.connect(retry)
	battle.checkpoint_requested.connect(resume)
	menu = null
	_replace(battle)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if screen is BattleScreen:
			(screen as BattleScreen).handle_back()
		elif is_instance_valid(menu) and menu.handle_back():
			return
		else:
			get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		if screen is BattleScreen and not (screen as BattleScreen).paused:
			(screen as BattleScreen).toggle_pause()
