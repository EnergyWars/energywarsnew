extends GutTest

const PROGRESS := "user://test_build_info_progress.json"
const SETTINGS := "user://test_build_info_settings.cfg"


func after_each() -> void:
	DirAccess.remove_absolute(PROGRESS)
	DirAccess.remove_absolute(SETTINGS)


func _bar() -> BuildBar:
	var bar := BuildBar.new().setup([GameConfig.SOLAR, GameConfig.ZAPPER, GameConfig.LASER] as Array[String])
	add_child_autofree(bar)
	bar.expand()
	return bar


func _hold(bar: BuildBar, kind: String, seconds: float) -> void:
	bar.button_for(kind).button_down.emit()
	bar._process(seconds)


func test_long_press_shows_the_description_without_building() -> void:
	var bar := _bar()
	watch_signals(bar)
	_hold(bar, GameConfig.ZAPPER, BuildBar.INFO_HOLD * 0.5)
	assert_false(bar.info_visible())
	bar._process(BuildBar.INFO_HOLD)
	assert_true(bar.info_visible())
	assert_eq(bar.info_kind, GameConfig.ZAPPER)
	assert_eq(bar._info_title.text, Texts.building_name(GameConfig.ZAPPER))
	assert_eq(bar._info_short.text, Texts.building_info(GameConfig.ZAPPER))
	assert_eq(bar._info_desc.text, Texts.building_desc(GameConfig.ZAPPER))
	assert_true(bar._info_desc.visible)
	assert_eq(bar._info_cost.text, str(int(GameConfig.building(GameConfig.ZAPPER).cost)))
	bar.button_for(GameConfig.ZAPPER).pressed.emit()
	bar.button_for(GameConfig.ZAPPER).button_up.emit()
	assert_signal_not_emitted(bar, "kind_pressed")
	assert_true(bar.info_visible())


func test_short_tap_still_selects_the_building() -> void:
	var bar := _bar()
	watch_signals(bar)
	var button := bar.button_for(GameConfig.SOLAR)
	button.button_down.emit()
	bar._process(0.1)
	button.pressed.emit()
	button.button_up.emit()
	assert_signal_emitted_with_parameters(bar, "kind_pressed", [GameConfig.SOLAR])
	assert_false(bar.info_visible())
	bar._process(1.0)
	assert_false(bar.info_visible())


func test_releasing_outside_after_a_long_press_does_not_block_the_next_tap() -> void:
	var bar := _bar()
	watch_signals(bar)
	_hold(bar, GameConfig.LASER, BuildBar.INFO_HOLD + 0.1)
	bar.button_for(GameConfig.LASER).button_up.emit()
	assert_true(bar.info_visible())
	var button := bar.button_for(GameConfig.LASER)
	button.button_down.emit()
	button.pressed.emit()
	button.button_up.emit()
	assert_signal_emitted_with_parameters(bar, "kind_pressed", [GameConfig.LASER])


func test_place_button_in_the_info_selects_the_building() -> void:
	var bar := _bar()
	watch_signals(bar)
	bar.show_info(GameConfig.LASER)
	assert_true(bar.info_build_button.text.contains(Texts.t("BUILD_INFO_PLACE")))
	bar.info_build_button.pressed.emit()
	assert_signal_emitted_with_parameters(bar, "kind_pressed", [GameConfig.LASER])
	assert_false(bar.info_visible())


func test_info_button_switches_taps_to_descriptions() -> void:
	var bar := _bar()
	watch_signals(bar)
	assert_eq(bar.info_button.theme_type_variation, "Button")
	bar.info_button.pressed.emit()
	assert_true(bar.info_mode)
	assert_eq(bar.info_button.theme_type_variation, "PrimaryButton")
	bar.button_for(GameConfig.SOLAR).pressed.emit()
	assert_signal_not_emitted(bar, "kind_pressed")
	assert_eq(bar.info_kind, GameConfig.SOLAR)
	bar.toggle_info_mode()
	assert_false(bar.info_mode)
	assert_false(bar.info_visible())
	bar.button_for(GameConfig.SOLAR).pressed.emit()
	assert_signal_emitted_with_parameters(bar, "kind_pressed", [GameConfig.SOLAR])


func test_info_closes_with_its_button_collapse_and_selection() -> void:
	var bar := _bar()
	bar.show_info("no_such_building")
	assert_false(bar.info_visible())
	bar.show_info(GameConfig.SOLAR)
	bar.hide_info()
	assert_false(bar.info_visible())
	bar.hide_info()
	bar.show_info(GameConfig.SOLAR)
	bar.collapse()
	assert_false(bar.info_visible())
	assert_eq(bar.info_kind, "")
	bar.expand()
	bar.show_info(GameConfig.ZAPPER)
	var battle := BattleFixtures.battle(0)
	bar.refresh(battle.state, "")
	assert_eq(bar._info_cost.text, str(Formulas.build_cost(battle.state, GameConfig.ZAPPER)))
	bar.refresh(battle.state, GameConfig.ZAPPER)
	assert_false(bar.info_visible())


func test_back_button_closes_the_building_info_first() -> void:
	var settings := AppSettings.new(SETTINGS)
	settings.sound = false
	settings.haptics = false
	var progress := Progress.new(PROGRESS)
	var sfx := SfxPlayer.new().setup(settings)
	add_child_autofree(sfx)
	var screen := BattleScreen.new().setup(0, progress, settings, sfx)
	add_child_autofree(screen)
	BattleFixtures.open_terrain(screen.battle.state)
	screen.battle.deploy_core(screen.battle.state.map.drop)
	screen._process(1.0 / 30.0)
	var bar := screen.build_bar
	bar.expand()
	bar.show_info(bar.kinds[0])
	assert_true(bar.info_visible())
	screen.handle_back()
	assert_false(bar.info_visible())
	assert_true(bar.expanded)
	screen.handle_back()
	assert_false(bar.expanded)


func test_info_icons_exist_in_the_icon_font() -> void:
	for glyph in [Icons.DETAILS, Icons.FLIGHT]:
		assert_true(AppTheme.FONT_ICONS.has_char(glyph.unicode_at(0)), glyph)
