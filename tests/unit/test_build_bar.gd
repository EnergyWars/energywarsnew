extends GutTest


func _bar(kinds: Array[String], collapsible: bool = false) -> BuildBar:
	var bar := BuildBar.new().setup(kinds, collapsible)
	add_child_autofree(bar)
	return bar


func test_groups_follow_category_order_and_skip_empty() -> void:
	var kinds: Array[String] = [GameConfig.ZAPPER, GameConfig.SOLAR, GameConfig.BULWARK]
	var groups := BuildBar.groups(kinds)
	assert_eq(groups.size(), 3)
	assert_eq(groups[0].key, "energy")
	assert_eq(groups[1].key, "towers")
	assert_eq(groups[2].key, "defense")
	assert_eq(groups[2].kinds, [GameConfig.BULWARK] as Array[String])


func test_unknown_kinds_land_in_other() -> void:
	var groups := BuildBar.groups([GameConfig.CORE] as Array[String])
	assert_eq(groups.size(), 1)
	assert_eq(groups[0].key, "other")


func test_every_build_kind_has_a_category() -> void:
	var groups := BuildBar.groups(GameConfig.BUILD_ORDER)
	var seen := 0
	for group: Dictionary in groups:
		assert_ne(group.key, "other")
		seen += group.kinds.size()
	assert_eq(seen, GameConfig.BUILD_ORDER.size())


func test_tabs_start_with_all_kinds_in_category_order() -> void:
	var kinds: Array[String] = [GameConfig.ZAPPER, GameConfig.SOLAR, GameConfig.BULWARK]
	var tabs := BuildBar.tabs(kinds)
	assert_eq(tabs.size(), 4)
	assert_eq(tabs[0].key, BuildBar.ALL)
	assert_eq(tabs[0].kinds, [GameConfig.SOLAR, GameConfig.ZAPPER, GameConfig.BULWARK] as Array[String])
	assert_eq(tabs[1].key, "energy")
	assert_eq(tabs[3].key, "defense")


func test_tabs_skip_all_for_a_single_category() -> void:
	var tabs := BuildBar.tabs([GameConfig.SOLAR, GameConfig.RELAY] as Array[String])
	assert_eq(tabs.size(), 1)
	assert_eq(tabs[0].key, "energy")
	assert_true(BuildBar.tabs([] as Array[String]).is_empty())


func test_single_group_hides_tabs() -> void:
	var bar := _bar([GameConfig.CORE] as Array[String])
	assert_false(bar._tabs.visible)
	assert_false(bar._tab_buttons.has(BuildBar.ALL))
	assert_not_null(bar.button_for(GameConfig.CORE))


func test_all_tab_comes_first_and_shows_every_kind() -> void:
	var bar := _bar(GameConfig.STARTER_KINDS)
	assert_true(bar._tabs.visible)
	assert_eq(bar.category, BuildBar.ALL)
	assert_eq(bar._tabs.get_child(0), bar._tab_buttons[BuildBar.ALL])
	assert_eq(bar._tab_buttons[BuildBar.ALL].text, Texts.t("BUILD_CATEGORY_ALL"))
	assert_eq(bar._grid.get_child_count(), GameConfig.STARTER_KINDS.size())
	for kind in GameConfig.STARTER_KINDS:
		assert_not_null(bar.button_for(kind), kind)
	assert_eq(bar._grid.get_child(0), bar.button_for(GameConfig.SOLAR))


func test_only_selected_category_is_shown() -> void:
	var bar := _bar(GameConfig.STARTER_KINDS)
	bar.select_category("energy")
	assert_eq(bar.category, "energy")
	assert_not_null(bar.button_for(GameConfig.SOLAR))
	assert_null(bar.button_for(GameConfig.ZAPPER))
	bar.select_category("towers")
	assert_eq(bar.category, "towers")
	assert_not_null(bar.button_for(GameConfig.ZAPPER))
	assert_null(bar.button_for(GameConfig.SOLAR))
	bar.select_category(BuildBar.ALL)
	assert_not_null(bar.button_for(GameConfig.ZAPPER))
	assert_not_null(bar.button_for(GameConfig.SOLAR))


func test_selecting_unknown_or_same_category_changes_nothing() -> void:
	var bar := _bar(GameConfig.STARTER_KINDS)
	bar.select_category("nope")
	assert_eq(bar.category, BuildBar.ALL)
	bar.select_category(BuildBar.ALL)
	assert_eq(bar.category, BuildBar.ALL)


func test_tab_highlights_current_category() -> void:
	var bar := _bar(GameConfig.STARTER_KINDS)
	assert_eq(bar._tab_buttons[BuildBar.ALL].theme_type_variation, &"PrimaryButton")
	assert_eq(bar._tab_buttons["energy"].theme_type_variation, &"Button")
	bar.select_category("towers")
	assert_eq(bar._tab_buttons[BuildBar.ALL].theme_type_variation, &"Button")
	assert_eq(bar._tab_buttons["towers"].theme_type_variation, &"PrimaryButton")


func test_category_falls_back_when_kinds_change() -> void:
	var bar := _bar(GameConfig.STARTER_KINDS)
	bar.select_category("towers")
	bar.set_kinds([GameConfig.SOLAR] as Array[String])
	assert_eq(bar.category, "energy")
	bar.set_kinds([] as Array[String])
	assert_eq(bar.category, "")


func test_category_survives_new_kinds() -> void:
	var bar := _bar(GameConfig.STARTER_KINDS)
	bar.select_category("towers")
	bar.set_kinds(GameConfig.BUILD_ORDER)
	assert_eq(bar.category, "towers")
	assert_not_null(bar.button_for(GameConfig.LASER))
	bar.select_category(BuildBar.ALL)
	bar.set_kinds(GameConfig.BUILD_ORDER)
	assert_eq(bar.category, BuildBar.ALL)
	assert_eq(bar._grid.get_child_count(), GameConfig.BUILD_ORDER.size())


func test_cards_hidden_while_collapsed() -> void:
	var bar := _bar(GameConfig.STARTER_KINDS, true)
	assert_false(bar._grid.visible)
	assert_false(bar._tabs.visible)
	bar.expand()
	assert_true(bar._grid.visible)
	assert_true(bar._tabs.visible)
