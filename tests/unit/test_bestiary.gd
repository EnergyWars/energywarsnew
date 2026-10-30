extends GutTest

const PROGRESS := "user://test_bestiary_progress.json"
const SETTINGS := "user://test_bestiary_settings.cfg"

var settings: AppSettings
var progress: Progress
var sfx: SfxPlayer


func before_each() -> void:
	settings = AppSettings.new(SETTINGS)
	settings.sound = false
	settings.haptics = false
	progress = Progress.new(PROGRESS)
	sfx = SfxPlayer.new().setup(settings)
	add_child_autofree(sfx)


func after_each() -> void:
	DirAccess.remove_absolute(PROGRESS)
	DirAccess.remove_absolute(SETTINGS)


func _deployed(rules: BattleSetup = null) -> BattleScreen:
	var screen := BattleScreen.new().setup(0, progress, settings, sfx, 0.0, rules)
	add_child_autofree(screen)
	BattleFixtures.open_terrain(screen.battle.state)
	screen.battle.deploy_core(screen.battle.state.map.drop)
	screen._process(1.0 / 30.0)
	return screen


func _labels(node: Node) -> Array[String]:
	var texts: Array[String] = []
	for child in node.find_children("*", "Label", true, false):
		texts.append((child as Label).text)
	return texts


func _enemy_icons(node: Node) -> Array[EnemyIcon]:
	var icons: Array[EnemyIcon] = []
	for child in node.find_children("*", "", true, false):
		if child is EnemyIcon:
			icons.append(child)
	return icons


func test_marking_monsters_as_seen() -> void:
	assert_eq(progress.seen_count(), 0)
	assert_false(progress.has_seen("crawler"))
	assert_true(progress.mark_seen("crawler"))
	assert_false(progress.mark_seen("crawler"))
	assert_false(progress.mark_seen("no_such_monster"))
	assert_true(progress.has_seen("crawler"))
	assert_eq(progress.seen_count(), 1)
	assert_eq(progress.to_dict().seen, ["crawler"])


func test_seen_monsters_survive_save_and_load() -> void:
	progress.mark_seen("crawler")
	progress.mark_seen("behemoth")
	assert_true(progress.save())
	var loaded := Progress.new(PROGRESS).load_progress()
	assert_eq(loaded.seen, ["crawler", "behemoth"] as Array[String])
	assert_eq(loaded.seen_count(), 2)


func test_old_saves_without_seen_monsters_still_load() -> void:
	var old := {"version": Progress.VERSION, "regions": {"dawn": {"conquered": true, "stars": 2, "best_days": 6, "done": ["conquer"]}},
		"techs": [], "location": 0, "total_kills": 42, "best_combo": 7}
	progress.apply(old)
	assert_true(progress.is_conquered(0))
	assert_eq(progress.stars_for(0), 2)
	assert_eq(progress.total_kills, 42)
	assert_true(progress.seen.is_empty())
	assert_eq(progress.seen_count(), 0)


func test_broken_seen_lists_are_sanitized() -> void:
	progress.apply({"version": Progress.VERSION, "seen": ["crawler", "crawler", "ghost", 5, "wasp"]})
	assert_eq(progress.seen, ["crawler", "wasp"] as Array[String])
	progress.apply({"version": Progress.VERSION, "seen": "crawler"})
	assert_true(progress.seen.is_empty())
	progress.apply({"version": Progress.LEGACY_VERSION, "stars": {"dawn": 1}, "seen": ["crawler"]})
	assert_true(progress.seen.is_empty())
	progress.apply({"version": 99, "seen": ["crawler"]})
	assert_true(progress.seen.is_empty())


func test_reset_all_forgets_seen_monsters() -> void:
	progress.mark_seen("crawler")
	progress.save()
	progress.reset_all()
	assert_true(progress.seen.is_empty())
	assert_false(Progress.new(PROGRESS).load_progress().has_seen("crawler"))


func test_sightings_report_each_visible_kind_once() -> void:
	var battle := BattleFixtures.battle(0)
	var core := battle.state.core()
	BattleFixtures.enemy(battle, "crawler", core.position + Vector2(200, 0))
	BattleFixtures.enemy(battle, "crawler", core.position + Vector2(-200, 0))
	BattleFixtures.enemy(battle, "spitter", core.position + Vector2(0, 200))
	assert_eq(battle.sightings.scan(), 2)
	var sighted := BattleFixtures.of_type(battle.events.drain(), "enemy_sighted")
	assert_eq(sighted.size(), 2)
	assert_eq(str(sighted[0].kind), "crawler")
	assert_eq(str(sighted[1].kind), "spitter")
	assert_false(bool(sighted[0].boss))
	assert_eq(battle.sightings.scan(), 0)


func test_sightings_ignore_hidden_dead_and_dark_enemies() -> void:
	var battle := BattleFixtures.battle(0)
	var state := battle.state
	var core := state.core()
	var hidden := BattleFixtures.enemy(battle, "crawler", core.position + Vector2(200, 0))
	state.fog.cells[state.map.index(state.map.cell_of(hidden.position))] = FogOfWar.HIDDEN
	var dead := BattleFixtures.enemy(battle, "spitter", core.position + Vector2(0, 200))
	dead.hp = 0.0
	assert_eq(battle.sightings.scan(), 0)
	assert_true(battle.start_round())
	state.round_time = float(state.level.day) + 5.0
	assert_true(state.is_night())
	var far := Vector2(state.map.size.x * 0.08, state.map.size.y * 0.08)
	assert_gt(far.distance_to(core.position), 600.0)
	var lurker := BattleFixtures.enemy(battle, "stalker", far)
	assert_false(battle.sightings.spots(lurker))
	var lit := BattleFixtures.enemy(battle, "raider", core.position + Vector2(core.radius() + 20.0, 0))
	assert_true(battle.sightings.spots(lit))
	assert_eq(battle.sightings.scan(), 1)
	assert_eq(str(BattleFixtures.of_type(battle.events.drain(), "enemy_sighted")[0].kind), "raider")


func test_sightings_scan_on_an_interval_during_the_fight() -> void:
	var battle := BattleFixtures.battle(0)
	var core := battle.state.core()
	assert_true(battle.start_round())
	BattleFixtures.enemy(battle, "crawler", core.position + Vector2(200, 0))
	battle.tick(GameConfig.TICK)
	assert_eq(BattleFixtures.of_type(battle.events.drain(), "enemy_sighted").size(), 1)
	BattleFixtures.enemy(battle, "spitter", core.position + Vector2(0, 200))
	assert_eq(battle.sightings.update(GameConfig.TICK), 0)
	assert_eq(battle.sightings.update(Sightings.SCAN), 1)


func test_bestiary_text_rows_and_badges() -> void:
	var crawler := BestiaryText.rows("crawler")
	assert_eq(crawler.size(), BestiaryText.ROW_KEYS.size())
	assert_eq(crawler[0], ["BESTIARY_HP", "42"])
	assert_eq(crawler[1], ["STAT_ARMOR", "0 (−0%)"])
	assert_eq(crawler[2], ["BESTIARY_SPEED", StatText.cells(70.0)])
	assert_eq(crawler[3], ["STAT_DAMAGE", "6"])
	assert_eq(crawler[4], ["STAT_RANGE", Texts.t("BESTIARY_MELEE")])
	var behemoth := GameConfig.enemy("behemoth")
	var armor := float(behemoth.armor)
	assert_eq(BestiaryText.rows("behemoth")[1][1], "%d (−%d%%)" % [int(armor), int(round(Formulas.armor_reduction(armor) * 100.0))])
	assert_eq(BestiaryText.rows("spitter")[4][1], StatText.cells(float(GameConfig.enemy("spitter").reach)))
	for row in BestiaryText.rows("crawler", false):
		assert_eq(row[1], BestiaryText.UNKNOWN_VALUE)
	var keys: Array[String] = []
	for badge in BestiaryText.badges("behemoth"):
		keys.append(str(badge[0]))
	assert_eq(keys, ["CLASS_MELEE", "BESTIARY_BOSS", "BESTIARY_NIGHT"] as Array[String])
	assert_eq(str(BestiaryText.badges("wasp")[0][0]), "CLASS_AIR")
	assert_eq(str(BestiaryText.badges("wasp").back()[0]), "BESTIARY_DAY")
	assert_eq(BestiaryText.name_of("crawler", true), Texts.enemy_name("crawler"))
	assert_eq(BestiaryText.name_of("crawler", false), Texts.t("BESTIARY_UNKNOWN"))
	assert_eq(BestiaryText.description_of("crawler", true), Texts.enemy_desc("crawler"))
	assert_eq(BestiaryText.description_of("crawler", false), Texts.t("BESTIARY_UNKNOWN_HINT"))


func test_every_badge_and_row_key_is_translated() -> void:
	for locale in ["en", "de"]:
		TranslationServer.set_locale(locale)
		for key in BestiaryText.ROW_KEYS:
			assert_ne(Texts.t(key), key, "%s %s" % [locale, key])
		for kind: String in GameConfig.enemy_kinds():
			for badge in BestiaryText.badges(kind):
				assert_ne(Texts.t(str(badge[0])), str(badge[0]), "%s %s" % [locale, kind])
		for key in ["BESTIARY_TITLE", "BESTIARY_HINT", "BESTIARY_OPEN", "BESTIARY_UNKNOWN_HINT", "BESTIARY_NEW", "BESTIARY_NEW_HINT",
				"BESTIARY_LATER", "WAVE_PREVIEW_TITLE", "WAVE_PREVIEW_RAID", "BUILD_INFO_PLACE", "BESTIARY_MELEE"]:
			assert_ne(Texts.t(key), key, "%s %s" % [locale, key])
	TranslationServer.set_locale("de")
	assert_ne(Texts.t("BESTIARY_TITLE"), "Monster Lexicon")
	TranslationServer.set_locale("en")


func test_enemy_icon_draws_known_monsters_and_silhouettes() -> void:
	var icon := EnemyIcon.new().setup("behemoth", 64.0, false)
	assert_eq(icon.material, EnemyIcon.silhouette_material())
	assert_eq(EnemyIcon.silhouette_material().shader, EnemyIcon.SILHOUETTE_SHADER)
	assert_eq(EnemyIcon.silhouette_material().get_shader_parameter(&"tint"), EnemyIcon.SILHOUETTE)
	assert_eq(icon.custom_minimum_size, Vector2(64, 64))
	icon.set_known(true)
	assert_null(icon.material)
	var hidden := EnemyIcon.new().setup("wasp", 40.0, false)
	add_child_autofree(hidden)
	add_child_autofree(icon)
	icon.size = Vector2(64, 64)
	assert_almost_eq(icon.paint_radius(), 64.0 * EnemyIcon.FILL, 0.001)
	var larva := EnemyIcon.new().setup("larva", 50.0)
	add_child_autofree(larva)
	larva.size = Vector2(50, 50)
	assert_almost_eq(larva.paint_radius(), 50.0 * EnemyIcon.FILL / float(EnemyPainter.look_of("larva").scale), 0.001)
	var empty := EnemyIcon.new().setup("", 40.0)
	add_child_autofree(empty)
	icon._process(0.5)
	assert_almost_eq(icon.clock, 0.5, 0.001)
	await wait_process_frames(2)
	assert_true(is_instance_valid(icon))


func test_bestiary_lists_every_monster_and_hides_unknown_ones() -> void:
	progress.mark_seen("crawler")
	var overlay := BestiaryOverlay.new().setup(progress, 0.0, "crawler")
	add_child_autofree(overlay)
	assert_eq(overlay.cards.size(), GameConfig.enemy_kinds().size())
	var known_texts := _labels(overlay.cards["crawler"])
	assert_has(known_texts, Texts.enemy_name("crawler"))
	assert_has(known_texts, Texts.enemy_desc("crawler"))
	assert_has(known_texts, Texts.t("CLASS_MELEE"))
	assert_has(known_texts, "42")
	var unknown_texts := _labels(overlay.cards["behemoth"])
	assert_has(unknown_texts, Texts.t("BESTIARY_UNKNOWN"))
	assert_does_not_have(unknown_texts, Texts.enemy_name("behemoth"))
	assert_does_not_have(unknown_texts, Texts.t("BESTIARY_BOSS"))
	assert_true(_enemy_icons(overlay.cards["crawler"])[0].known)
	assert_false(_enemy_icons(overlay.cards["behemoth"])[0].known)
	assert_eq(BestiaryOverlay.count_text(progress), "1 / %d" % GameConfig.enemy_kinds().size())
	assert_has(_labels(overlay), BestiaryOverlay.count_text(progress))


func test_bestiary_scrolls_to_the_focused_monster_and_closes() -> void:
	progress.mark_seen("gunship")
	var overlay := BestiaryOverlay.new().setup(progress, 0.0, "gunship")
	add_child_autofree(overlay)
	assert_true(overlay._pending_focus)
	for i in 10:
		await wait_process_frames(1)
		if not overlay._pending_focus:
			break
	assert_false(overlay._pending_focus)
	var plain := BestiaryOverlay.new().setup(progress, 0.0, "no_such_monster")
	add_child_autofree(plain)
	assert_false(plain._pending_focus)
	plain._process(0.1)
	watch_signals(overlay)
	overlay.handle_back()
	assert_signal_emitted(overlay, "closed")
	assert_true(overlay.is_queued_for_deletion())


func test_world_map_opens_the_bestiary() -> void:
	progress.mark_seen("crawler")
	var menu := WorldMapScreen.new().setup(progress, settings)
	add_child_autofree(menu)
	assert_true(menu.bestiary_button.text.contains(Texts.format("BESTIARY_OPEN", [1, GameConfig.enemy_kinds().size()])))
	assert_false(menu.handle_back())
	menu.bestiary_button.pressed.emit()
	assert_true(is_instance_valid(menu.bestiary))
	var first := menu.bestiary
	menu.open_bestiary("wasp")
	assert_eq(menu.bestiary, first)
	assert_true(menu.handle_back())
	assert_true(first.is_queued_for_deletion())
	menu.open_bestiary("wasp")
	assert_ne(menu.bestiary, first)
	assert_eq(menu.bestiary.focus_kind, "wasp")


func test_main_opens_the_requested_monster_after_the_battle() -> void:
	var main: Node = load("res://src/ui/main.gd").new()
	add_child_autofree(main)
	main.progress = progress
	main.start_campaign(0)
	assert_true(main.screen is BattleScreen)
	main.show_menu()
	assert_false(is_instance_valid(main.menu.bestiary))
	main.start_campaign(0)
	progress.mark_seen("crawler")
	(main.screen as BattleScreen).bestiary_request = "crawler"
	main.show_menu()
	assert_true(is_instance_valid(main.menu.bestiary))
	assert_eq(main.menu.bestiary.focus_kind, "crawler")


func test_new_monsters_are_announced_and_saved() -> void:
	var screen := _deployed()
	assert_true(screen.record_sighting("crawler"))
	assert_true(progress.has_seen("crawler"))
	assert_true(Progress.new(PROGRESS).load_progress().has_seen("crawler"))
	assert_eq(screen.discovered, ["crawler"] as Array[String])
	assert_true(screen.hud.discovery_visible())
	assert_eq(screen.hud.discovery_text(), Texts.format("BESTIARY_NEW", [Texts.enemy_name("crawler")]))
	assert_false(screen.record_sighting("crawler"))
	screen._on_event({"type": "enemy_sighted", "kind": "spitter"})
	assert_true(progress.has_seen("spitter"))
	assert_eq(screen.hud.discovery_kind, "crawler")
	screen.hud.press_discovery()
	assert_eq(screen.bestiary_request, "crawler")
	assert_eq(screen.hud.discovery_kind, "spitter")
	screen.hud._tick_discovery(BattleHud.DISCOVERY_TIME + 0.1)
	assert_false(screen.hud.discovery_visible())
	assert_eq(screen.hud.discovery_kind, "")
	screen.hud.press_discovery()
	assert_eq(screen.bestiary_request, "crawler")


func test_tapping_the_discovery_card_requests_the_bestiary() -> void:
	var screen := _deployed()
	screen.record_sighting("wasp")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	screen.hud._on_discovery_input(press)
	assert_eq(screen.bestiary_request, "")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	screen.hud._on_discovery_input(release)
	assert_eq(screen.bestiary_request, "wasp")
	screen.record_sighting("gnat")
	var touch := InputEventScreenTouch.new()
	touch.pressed = false
	screen.hud._on_discovery_input(touch)
	assert_eq(screen.bestiary_request, "gnat")


func test_discovery_card_fades_out_and_queues_monsters() -> void:
	var screen := _deployed()
	var hud := screen.hud
	hud.announce_discovery("crawler")
	hud.announce_discovery("crawler")
	hud.announce_discovery("larva")
	assert_eq(hud.discovery_kind, "crawler")
	hud._tick_discovery(BattleHud.DISCOVERY_TIME - BattleHud.DISCOVERY_FADE * 0.5)
	assert_lt(hud._discovery.modulate.a, 1.0)
	hud._tick_discovery(BattleHud.DISCOVERY_FADE)
	assert_eq(hud.discovery_kind, "larva")
	assert_eq(hud._discovery.modulate.a, 1.0)
	screen._process(1.0 / 30.0)
	assert_true(hud.discovery_visible())


func test_creative_battles_do_not_unlock_monsters() -> void:
	var screen := _deployed(BattleSetup.creative(3, progress.arsenal()))
	assert_false(screen.records_sightings())
	assert_false(screen.record_sighting("crawler"))
	assert_false(progress.has_seen("crawler"))
	assert_false(screen.hud.discovery_visible())


func test_a_fight_unlocks_monsters_in_the_lexicon() -> void:
	var screen := _deployed()
	var battle := screen.battle
	var core := battle.state.core()
	screen.start_round()
	BattleFixtures.enemy(battle, "mauler", core.position + Vector2(220, 0))
	for i in 3:
		screen._process(1.0 / 30.0)
	assert_true(progress.has_seen("mauler"))
	assert_eq(screen.hud.discovery_kind, "mauler")
