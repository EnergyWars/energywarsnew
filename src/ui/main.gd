extends Node

var settings: AppSettings
var progress: Progress
var sfx: SfxPlayer
var screen: Node


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
	var menu := LevelSelect.new().setup(progress, settings, safe_top())
	menu.level_chosen.connect(start_level)
	menu.locale_changed.connect(show_menu)
	layer.add_child(menu)
	_replace(layer)


func start_level(index: int) -> void:
	if not progress.is_unlocked(index):
		return
	var battle := BattleScreen.new().setup(index, progress, settings, sfx, safe_top())
	battle.menu_requested.connect(show_menu)
	battle.level_requested.connect(start_level)
	_replace(battle)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if screen is BattleScreen:
			(screen as BattleScreen).handle_back()
		else:
			get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		if screen is BattleScreen and not (screen as BattleScreen).paused:
			(screen as BattleScreen).toggle_pause()
