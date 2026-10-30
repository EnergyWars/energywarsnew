extends GutTest

const PRESETS := "res://export_presets.cfg"
const DEBUG_PRESET := "Android"
const PLAY_PRESET := "Android Play"
const MIN_TARGET_SDK := 36
const SAVE_PATH := "user://test_release_safe.json"
const PROGRESS_PATH := "user://test_release_progress.json"
const SETTINGS_PATH := "user://test_release_settings.cfg"
const STORE := "res://docs/store/"
const PRIVACY_URL := "https://example.com/privacy"
const LAUNCHER_ICONS := {
	"launcher_icons/main_192x192": 192,
	"launcher_icons/adaptive_foreground_432x432": 432,
	"launcher_icons/adaptive_background_432x432": 432,
	"launcher_icons/adaptive_monochrome_432x432": 432,
}
const LISTING_LIMITS := {"Titel": 30, "Kurzbeschreibung": 80, "Vollständige Beschreibung": 4000}
const STORE_DOCS: Array[String] = ["privacy-policy-de.md", "privacy-policy-en.md", "data-safety.md", "content-rating.md",
	"listing-de.md", "listing-en.md", "release-checklist.md"]

var settings: AppSettings
var progress: Progress
var sfx: SfxPlayer


func before_each() -> void:
	settings = AppSettings.new(SETTINGS_PATH)
	settings.sound = false
	settings.haptics = false
	progress = Progress.new(PROGRESS_PATH)
	sfx = SfxPlayer.new().setup(settings)
	add_child_autofree(sfx)


func after_each() -> void:
	for path in [SAVE_PATH, PROGRESS_PATH, SETTINGS_PATH]:
		SafeFile.remove(path)
	TranslationServer.set_locale("en")


func _presets() -> Dictionary:
	var config := ConfigFile.new()
	assert_eq(config.load(PRESETS), OK)
	var found := {}
	for section in config.get_sections():
		if section.ends_with(".options"):
			continue
		var options := {}
		for key in config.get_section_keys(section + ".options"):
			options[key] = config.get_value(section + ".options", key)
		var preset := {"options": options}
		for key in config.get_section_keys(section):
			preset[key] = config.get_value(section, key)
		found[str(preset.name)] = preset
	return found


func _image(path: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(path))


func _listing_sections(text: String) -> Dictionary:
	var sections := {}
	var current := ""
	for line in text.split("\n"):
		if line.begins_with("## "):
			current = line.trim_prefix("## ").strip_edges()
			sections[current] = []
		elif not current.is_empty() and not line.begins_with("<!--"):
			(sections[current] as Array).append(line)
	var result := {}
	for key: String in sections:
		result[key] = "\n".join(PackedStringArray(sections[key])).strip_edges()
	return result


func test_safe_file_writes_and_replaces_atomically() -> void:
	assert_true(SafeFile.write_text(SAVE_PATH, "first"))
	assert_true(SafeFile.write_text(SAVE_PATH, "second"))
	assert_eq(FileAccess.get_file_as_string(SAVE_PATH), "second")
	assert_false(FileAccess.file_exists(SafeFile.temp_path(SAVE_PATH)))


func test_safe_file_keeps_the_old_file_when_writing_fails() -> void:
	assert_true(SafeFile.write_text(SAVE_PATH, "kept"))
	DirAccess.make_dir_absolute(SafeFile.temp_path(SAVE_PATH))
	assert_false(SafeFile.write_text(SAVE_PATH, "lost"))
	assert_eq(FileAccess.get_file_as_string(SAVE_PATH), "kept")
	DirAccess.remove_absolute(SafeFile.temp_path(SAVE_PATH))


func test_safe_file_fails_for_missing_directories_without_leftovers() -> void:
	var path := "user://missing_release_dir/save.json"
	assert_false(SafeFile.write_text(path, "x"))
	assert_false(FileAccess.file_exists(path))
	assert_false(FileAccess.file_exists(SafeFile.temp_path(path)))


func test_safe_file_remove_deletes_file_and_leftover_temp() -> void:
	assert_true(SafeFile.write_text(SAVE_PATH, "x"))
	var leftover := FileAccess.open(SafeFile.temp_path(SAVE_PATH), FileAccess.WRITE)
	leftover.store_string("partial")
	leftover.close()
	SafeFile.remove(SAVE_PATH)
	assert_false(FileAccess.file_exists(SAVE_PATH))
	assert_false(FileAccess.file_exists(SafeFile.temp_path(SAVE_PATH)))
	SafeFile.remove(SAVE_PATH)


func test_progress_and_settings_are_saved_atomically() -> void:
	progress.location = 0
	progress.total_kills = 12
	assert_true(progress.save())
	assert_false(FileAccess.file_exists(SafeFile.temp_path(PROGRESS_PATH)))
	assert_eq(Progress.new(PROGRESS_PATH).load_progress().total_kills, 12)
	settings.set_haptics(true)
	settings.set_sound(true)
	assert_false(FileAccess.file_exists(SafeFile.temp_path(SETTINGS_PATH)))
	var loaded := AppSettings.new(SETTINGS_PATH).load_settings()
	assert_true(loaded.haptics)
	assert_true(loaded.sound)
	var leftover := FileAccess.open(SafeFile.temp_path(PROGRESS_PATH), FileAccess.WRITE)
	leftover.store_string("{broken")
	leftover.close()
	progress.reset_all()
	assert_false(FileAccess.file_exists(PROGRESS_PATH))
	assert_false(FileAccess.file_exists(SafeFile.temp_path(PROGRESS_PATH)))


func test_version_code_scheme() -> void:
	assert_eq(AppInfo.version_code("1.0.0"), 10000)
	assert_eq(AppInfo.version_code("1.2.3"), 10203)
	assert_eq(AppInfo.version_code("12.34.56"), 123456)
	for invalid in ["", "1.0", "1.0.0.0", "1.x.0", "1.100.0", "1.0.100", "-1.0.0", "a.b.c"]:
		assert_eq(AppInfo.version_code(invalid), 0, invalid)


func test_privacy_url_only_accepts_https() -> void:
	assert_eq(AppInfo.privacy_url(""), "")
	assert_eq(AppInfo.privacy_url("http://example.com"), "")
	assert_eq(AppInfo.privacy_url("https://"), "")
	assert_eq(AppInfo.privacy_url("javascript:alert(1)"), "")
	assert_eq(AppInfo.privacy_url("https://exa mple.com"), "")
	assert_eq(AppInfo.privacy_url("  %s " % PRIVACY_URL), PRIVACY_URL)
	assert_eq(AppInfo.privacy_url(), AppInfo.privacy_url(AppInfo.PRIVACY_POLICY_URL))


func test_presets_share_version_package_and_scheme() -> void:
	var presets := _presets()
	assert_true(presets.has(DEBUG_PRESET))
	assert_true(presets.has(PLAY_PRESET))
	assert_ne(AppInfo.version(), "")
	for name: String in [DEBUG_PRESET, PLAY_PRESET]:
		var options: Dictionary = presets[name].options
		assert_eq(options["version/name"], AppInfo.version(), name)
		assert_eq(int(options["version/code"]), AppInfo.version_code(AppInfo.version()), name)
		assert_gt(int(options["version/code"]), 0, name)
		assert_eq(options["package/unique_name"], "com.wafflehq.energywars", name)
		assert_eq(int(options["package/app_category"]), 2, name)


func test_play_preset_builds_a_signed_aab_for_current_play_requirements() -> void:
	var preset: Dictionary = _presets()[PLAY_PRESET]
	var options: Dictionary = preset.options
	assert_true(options["gradle_build/use_gradle_build"])
	assert_eq(int(options["gradle_build/export_format"]), 1)
	assert_true(str(preset.export_path).ends_with(".aab"))
	assert_gte(int(options["gradle_build/target_sdk"]), MIN_TARGET_SDK)
	assert_gte(int(options["gradle_build/min_sdk"]), 24)
	assert_true(options["architectures/arm64-v8a"])
	assert_true(options["package/signed"])
	assert_false(options.get("gradle_build/compress_native_libraries", false))


func test_presets_request_only_needed_permissions_and_allow_backup() -> void:
	for preset: Dictionary in _presets().values():
		var options: Dictionary = preset.options
		for key: String in options:
			if key.begins_with("permissions/") and key != "permissions/custom_permissions" and options[key] is bool:
				assert_eq(options[key], key == "permissions/vibrate", key)
		assert_eq((options["permissions/custom_permissions"] as PackedStringArray).size(), 0)
		assert_true(options["user_data_backup/allow"])
		assert_true(options["screen/immersive_mode"])


func test_presets_store_no_signing_secrets() -> void:
	for preset: Dictionary in _presets().values():
		for key: String in preset.options:
			if key.begins_with("keystore/"):
				assert_eq(str(preset.options[key]), "", key)
	var ignored := FileAccess.get_file_as_string("res://.gitignore").split("\n")
	for pattern in ["*.keystore", "*.jks", "*.p12", "export_credentials.cfg", "*.aab", "*.apk", "build/"]:
		assert_true(ignored.has(pattern), pattern)


func test_presets_ship_only_game_files() -> void:
	for preset: Dictionary in _presets().values():
		var excluded := str(preset.exclude_filter)
		for folder in ["addons/gut/*", "tests/*", "docs/*", "tools/*", "build/*"]:
			assert_true(excluded.contains(folder), folder)
		var included := str(preset.include_filter)
		assert_true(included.contains("data/*.json"))
		assert_true(included.contains("assets/fonts/*.txt"))
		for path: String in LicenseCatalog.FILES.values():
			assert_true(path.get_file().match("*.txt") and path.begins_with("res://assets/fonts/"), path)


func test_launcher_icons_exist_with_android_sizes() -> void:
	for preset: Dictionary in _presets().values():
		for key: String in LAUNCHER_ICONS:
			var path := str(preset.options[key])
			assert_true(FileAccess.file_exists(path), path)
			var image := _image(path)
			assert_eq(image.get_size(), Vector2i(LAUNCHER_ICONS[key], LAUNCHER_ICONS[key]), path)
	var foreground := _image("res://assets/android/launcher_foreground_432.png")
	assert_eq(foreground.get_pixel(0, 0).a, 0.0)
	assert_eq(foreground.get_pixel(151, 280).a, 1.0)
	var background := _image("res://assets/android/launcher_background_432.png")
	assert_eq(background.get_pixel(0, 0).a, 1.0)
	var monochrome := _image("res://assets/android/launcher_monochrome_432.png")
	assert_eq(monochrome.get_pixel(0, 0).a, 0.0)


func test_store_graphics_match_play_specs() -> void:
	var icon := _image(STORE + "icon-512.png")
	assert_eq(icon.get_size(), Vector2i(512, 512))
	assert_eq(icon.get_pixel(0, 0).a, 1.0)
	for locale in ["de", "en"]:
		var feature := _image(STORE + "feature-graphic-%s.png" % locale)
		assert_eq(feature.get_size(), Vector2i(1024, 500), locale)
		assert_eq(feature.detect_alpha(), Image.ALPHA_NONE, locale)


func test_store_documents_exist_and_listings_fit_play_limits() -> void:
	for name in STORE_DOCS:
		assert_true(FileAccess.file_exists(STORE + name), name)
		assert_gt(FileAccess.get_file_as_string(STORE + name).length(), 200, name)
	for locale in ["de", "en"]:
		var sections := _listing_sections(FileAccess.get_file_as_string(STORE + "listing-%s.md" % locale))
		for heading: String in LISTING_LIMITS:
			assert_true(sections.has(heading), "%s %s" % [locale, heading])
			var text: String = sections.get(heading, "")
			assert_gt(text.length(), 0, "%s %s" % [locale, heading])
			assert_lte(text.length(), LISTING_LIMITS[heading], "%s %s" % [locale, heading])


func test_every_translation_row_has_english_and_german() -> void:
	var file := FileAccess.open("res://i18n/translations.csv", FileAccess.READ)
	var header := file.get_csv_line()
	assert_eq(Array(header), ["keys", "en", "de"])
	var keys := {}
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() == 1 and row[0].is_empty():
			continue
		assert_eq(row.size(), 3, row[0])
		assert_false(keys.has(row[0]), "duplicate %s" % row[0])
		keys[row[0]] = true
		assert_ne(row[1].strip_edges(), "", "en %s" % row[0])
		assert_ne(row[2].strip_edges(), "", "de %s" % row[0])


func test_about_texts_are_translated() -> void:
	var keys := ["ABOUT_TITLE", "ABOUT_VERSION", "ABOUT_CREDITS", "ABOUT_PRIVACY_TITLE", "ABOUT_PRIVACY_TEXT", "ABOUT_PRIVACY_OPEN",
		"ABOUT_LICENSES_TITLE", "ABOUT_LICENSES_HINT", "ABOUT_LIB_GEIST", "ABOUT_LIB_GEIST_INFO", "ABOUT_LIB_ICONS", "ABOUT_LIB_ICONS_INFO",
		"ABOUT_LIB_GODOT", "ABOUT_LIB_GODOT_INFO", "ABOUT_LIB_GODOT_PARTS", "ABOUT_LIB_GODOT_PARTS_INFO", "ABOUT_LIB_ANDROID",
		"ABOUT_LIB_ANDROID_INFO", "ABOUT_LICENSE_TEXT_INFO", "ABOUT_COMPONENT_COPYRIGHT", "ABOUT_COMPONENT_LICENSE"]
	for locale in ["en", "de"]:
		TranslationServer.set_locale(locale)
		for key: String in keys:
			assert_ne(Texts.t(key), key, "%s %s" % [locale, key])
	TranslationServer.set_locale("de")
	assert_eq(Texts.t("ABOUT_TITLE"), "Über Energy Wars")
	assert_eq(Texts.format("ABOUT_COMPONENT_LICENSE", ["MIT"]), "Lizenz: MIT")


func test_license_catalog_lists_every_third_party_text() -> void:
	var entries := LicenseCatalog.entries()
	var ids: Array[String] = []
	for entry in entries:
		ids.append(str(entry.id))
		assert_ne(str(entry.title), "", str(entry.id))
		assert_ne(str(entry.info), "", str(entry.id))
		assert_ne(LicenseCatalog.text(str(entry.id)), "", str(entry.id))
	for id in [LicenseCatalog.GEIST, LicenseCatalog.MATERIAL_ICONS, LicenseCatalog.GODOT, LicenseCatalog.GODOT_PARTS, LicenseCatalog.ANDROID_LIBRARIES]:
		assert_true(ids.has(id), id)
	for name in LicenseCatalog.license_names():
		assert_true(ids.has(LicenseCatalog.LICENSE_PREFIX + name), name)
	assert_eq(entries.size(), 5 + Engine.get_license_info().size())
	assert_string_contains(LicenseCatalog.text(LicenseCatalog.GEIST), "SIL OPEN FONT LICENSE")
	assert_string_contains(LicenseCatalog.text(LicenseCatalog.MATERIAL_ICONS), "Apache License")
	assert_eq(LicenseCatalog.text(LicenseCatalog.GODOT), Engine.get_license_text().strip_edges())
	assert_string_contains(LicenseCatalog.text(LicenseCatalog.ANDROID_LIBRARIES), "Apache License")
	assert_eq(LicenseCatalog.text("unknown"), "")
	assert_eq(LicenseCatalog.text(LicenseCatalog.LICENSE_PREFIX + "unknown"), "")


func test_license_catalog_lists_engine_components() -> void:
	TranslationServer.set_locale("en")
	var text := LicenseCatalog.components()
	assert_true(text.begins_with("Godot Engine"))
	assert_string_contains(text, "© 2014-present, Godot Engine contributors")
	assert_string_contains(text, "License: Expat")
	assert_eq(text.split("\n\n").size(), Engine.get_copyright_info().size())


func test_about_overlay_shows_version_privacy_and_licenses() -> void:
	var overlay := AboutOverlay.new().setup(24.0)
	add_child_autofree(overlay)
	assert_eq(overlay.version_label.text, Texts.format("ABOUT_VERSION", [AppInfo.version()]))
	assert_eq(overlay.privacy_text.text, Texts.t("ABOUT_PRIVACY_TEXT"))
	assert_eq(overlay.privacy_button.visible, not AppInfo.privacy_url().is_empty())
	assert_eq(overlay.toggles.size(), LicenseCatalog.entries().size())
	assert_false(overlay.is_expanded(LicenseCatalog.GEIST))
	assert_eq(overlay.license_text(LicenseCatalog.GEIST), "")
	overlay.toggle_license(LicenseCatalog.GEIST)
	assert_true(overlay.is_expanded(LicenseCatalog.GEIST))
	assert_eq(overlay.license_text(LicenseCatalog.GEIST), LicenseCatalog.text(LicenseCatalog.GEIST))
	assert_true((overlay.toggles[LicenseCatalog.GEIST] as Button).text.begins_with(Icons.EXPAND_LESS))
	overlay.toggle_license(LicenseCatalog.GEIST)
	assert_false(overlay.is_expanded(LicenseCatalog.GEIST))
	assert_true((overlay.toggles[LicenseCatalog.GEIST] as Button).text.begins_with(Icons.EXPAND_MORE))
	overlay.toggle_license("unknown")
	assert_false(overlay.is_expanded("unknown"))
	assert_eq(overlay.license_text("unknown"), "")


func test_about_overlay_opens_only_a_configured_privacy_url() -> void:
	var opened: Array[String] = []
	var overlay := AboutOverlay.new().setup(0.0, PRIVACY_URL)
	overlay.opener = func(url: String) -> void: opened.append(url)
	add_child_autofree(overlay)
	assert_true(overlay.privacy_button.visible)
	overlay.privacy_button.pressed.emit()
	assert_eq(opened, [PRIVACY_URL] as Array[String])
	var offline := AboutOverlay.new().setup(0.0, "http://insecure.example.com")
	offline.opener = func(url: String) -> void: opened.append(url)
	add_child_autofree(offline)
	assert_false(offline.privacy_button.visible)
	offline.open_privacy()
	assert_eq(opened.size(), 1)


func test_about_overlay_closes_on_back() -> void:
	var overlay := AboutOverlay.new().setup()
	add_child(overlay)
	watch_signals(overlay)
	overlay.handle_back()
	assert_signal_emitted(overlay, "closed")
	assert_true(overlay.is_queued_for_deletion())
	await wait_process_frames(1)


func test_world_map_opens_and_closes_about_with_back() -> void:
	var screen := WorldMapScreen.new().setup(progress, settings, 12.0)
	add_child_autofree(screen)
	assert_false(screen.is_about_open())
	screen.about_button.pressed.emit()
	assert_true(screen.is_about_open())
	var first := screen.about
	screen.open_about()
	assert_eq(screen.about, first)
	assert_eq(screen.about.safe_top, 12.0)
	assert_true(screen.handle_back())
	assert_false(screen.is_about_open())
	assert_false(screen.handle_back())


func test_battle_screen_suspends_without_closing_open_overlays() -> void:
	var screen := BattleScreen.new().setup(0, progress, settings, sfx)
	add_child_autofree(screen)
	screen.suspend()
	assert_true(screen.paused)
	assert_true(screen.overlay is PauseOverlay)
	var pause := screen.overlay
	screen.suspend()
	assert_true(screen.paused)
	assert_eq(screen.overlay, pause)
	assert_false(pause.is_queued_for_deletion())
	screen.toggle_pause()
	assert_false(screen.paused)
	var dialog := ConfirmOverlay.new().setup("t", "m", "c")
	screen._open_overlay(dialog)
	screen.suspend()
	assert_eq(screen.overlay, dialog)
	assert_false(dialog.is_queued_for_deletion())
	assert_false(screen.paused)
	screen.battle.state.phase = BattleState.Phase.LOST
	dialog.queue_free()
	await wait_process_frames(1)
	screen.suspend()
	assert_false(screen.paused)


func test_main_pauses_the_battle_when_the_app_goes_to_background() -> void:
	var main: Node = load("res://src/ui/main.gd").new()
	add_child_autofree(main)
	main.progress = progress
	main.settings = settings
	main.show_menu()
	main._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_true(main.menu is WorldMapScreen)
	main.start_campaign(0)
	main._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_true((main.screen as BattleScreen).paused)
	main._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_true((main.screen as BattleScreen).paused)
	assert_true((main.screen as BattleScreen).is_overlay_open())
