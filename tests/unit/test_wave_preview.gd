extends GutTest

const PROGRESS := "user://test_wave_preview_progress.json"
const SETTINGS := "user://test_wave_preview_settings.cfg"

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


func _level(extra: Array = []) -> Dictionary:
	return {"day": 60.0, "night": 40.0, "extra_waves": extra, "waves": {"interval": 9.0, "base": 1.0, "ramp": 1.0, "night": 1.2, "growth": 0.4,
		"roster": [["crawler", 0, 1.0], ["spitter", 1, 0.5], ["soldier", 0, 1.0]],
		"night_roster": [["stalker", 0, 1.0], ["raider", 2, 1.0], ["behemoth", 3, 0.1]]}}


func _kinds(preview: Dictionary, part: String, list: String = WavePreview.KINDS) -> Array:
	return preview[part][list]


func test_first_day_shows_only_starters_of_the_spawner_faction() -> void:
	var preview := WavePreview.for_round(_level(), 1, [GameConfig.NEST] as Array[String])
	assert_eq(_kinds(preview, WavePreview.DAY), ["crawler"])
	assert_eq(_kinds(preview, WavePreview.NIGHT), ["stalker"])
	assert_true(_kinds(preview, WavePreview.DAY, WavePreview.RAID).is_empty())
	assert_true(_kinds(preview, WavePreview.NIGHT, WavePreview.RAID).is_empty())


func test_later_days_unlock_stronger_monsters_and_mix_factions() -> void:
	var second := WavePreview.for_round(_level(), 2, [GameConfig.NEST] as Array[String])
	assert_eq(_kinds(second, WavePreview.DAY), ["crawler", "spitter"])
	var mixed := WavePreview.for_round(_level(), 3, [GameConfig.NEST, GameConfig.CAMP] as Array[String])
	assert_eq(_kinds(mixed, WavePreview.DAY), ["crawler", "spitter", "soldier"])
	assert_eq(_kinds(mixed, WavePreview.NIGHT), ["stalker", "raider"])
	var boss := WavePreview.for_round(_level(), 4, [GameConfig.NEST] as Array[String])
	assert_eq(_kinds(boss, WavePreview.NIGHT), ["stalker", "behemoth"])


func test_air_raids_appear_from_their_first_round() -> void:
	var before := WavePreview.for_round(_level(), GameConfig.AIR_RAID_FIRST_ROUND - 1, [GameConfig.NEST] as Array[String])
	assert_true(_kinds(before, WavePreview.DAY, WavePreview.RAID).is_empty())
	assert_false(WavePreview.raids_possible(GameConfig.AIR_RAID_FIRST_ROUND - 1))
	assert_true(WavePreview.raids_possible(GameConfig.AIR_RAID_FIRST_ROUND))
	var preview := WavePreview.for_round(_level(), GameConfig.AIR_RAID_FIRST_ROUND, [GameConfig.NEST] as Array[String])
	var day_raid := _kinds(preview, WavePreview.DAY, WavePreview.RAID)
	var night_raid := _kinds(preview, WavePreview.NIGHT, WavePreview.RAID)
	assert_eq(day_raid, SpawnDirector.air_kinds([GameConfig.NEST], false))
	assert_eq(night_raid, SpawnDirector.air_kinds([GameConfig.NEST], true))
	assert_false(day_raid.is_empty())
	for kind: String in day_raid + night_raid:
		assert_eq(GameConfig.enemy(kind).class, GameConfig.CLASS_AIR)
		assert_false(bool(GameConfig.enemy(kind).get("boss", false)), kind)


func test_extra_monsters_join_their_day_and_time_of_day() -> void:
	var extra := [{"day": 2, "night": true, "kind": "juggernaut", "count": 1}, {"day": 2, "night": false, "kind": "no_such_monster", "count": 3}]
	var preview := WavePreview.for_round(_level(extra), 2, [GameConfig.NEST] as Array[String])
	assert_has(_kinds(preview, WavePreview.NIGHT), "juggernaut")
	assert_does_not_have(_kinds(preview, WavePreview.DAY), "no_such_monster")
	var later := WavePreview.for_round(_level(extra), 3, [GameConfig.NEST] as Array[String])
	assert_does_not_have(_kinds(later, WavePreview.NIGHT), "juggernaut")


func test_missing_roster_entries_fall_back_like_the_spawner() -> void:
	var preview := WavePreview.for_round(_level(), 1, [GameConfig.CAMP] as Array[String])
	assert_eq(_kinds(preview, WavePreview.NIGHT), [SpawnDirector.fallback_for(GameConfig.CAMP, true)])
	assert_false(GameConfig.is_nocturnal(SpawnDirector.fallback_for(GameConfig.CAMP, false)))
	assert_true(GameConfig.is_nocturnal(SpawnDirector.fallback_for(GameConfig.CAMP, true)))


func test_no_spawners_means_no_enemies() -> void:
	var preview := WavePreview.for_round(_level([{"day": 1, "night": false, "kind": "crawler", "count": 1}]), 5, [] as Array[String])
	for part in [WavePreview.DAY, WavePreview.NIGHT]:
		assert_true(_kinds(preview, part).is_empty())
		assert_true(_kinds(preview, part, WavePreview.RAID).is_empty())
	assert_true(WavePreview.for_round({}, 1, [GameConfig.NEST] as Array[String])[WavePreview.DAY][WavePreview.KINDS].size() == 1)


func test_preview_reads_living_spawners_from_the_battle() -> void:
	var battle := BattleFixtures.battle(0)
	var state := battle.state
	var spawners := WavePreview.spawner_kinds(state)
	assert_false(spawners.is_empty())
	var preview := WavePreview.of(state)
	assert_eq(preview, WavePreview.for_round(state.level, state.round_number, spawners))
	for building in state.enemy_buildings():
		if building.spawner:
			building.hp = 0.0
	assert_true(WavePreview.spawner_kinds(state).is_empty())


func test_spawner_candidates_use_the_shared_rules() -> void:
	var battle := BattleFixtures.battle(0)
	var spawns := battle.spawns
	assert_eq(spawns.candidates(GameConfig.NEST), SpawnDirector.eligible(spawns.roster(), GameConfig.NEST, battle.state.round_number))
	assert_eq(SpawnDirector.eligible(_level().waves.roster, GameConfig.NEST, 1), [["crawler", 0, 1.0]])
	assert_eq(spawns.fallback_kind(GameConfig.NEST), SpawnDirector.fallback_for(GameConfig.NEST, false))
	assert_eq(spawns.raid_kinds(false), SpawnDirector.air_kinds(WavePreview.spawner_kinds(battle.state), false))


func _deployed() -> BattleScreen:
	var screen := BattleScreen.new().setup(0, progress, settings, sfx)
	add_child_autofree(screen)
	BattleFixtures.open_terrain(screen.battle.state)
	screen.battle.deploy_core(screen.battle.state.map.drop)
	screen._process(1.0 / 30.0)
	return screen


func test_planning_card_shows_the_coming_monsters() -> void:
	var screen := _deployed()
	var hud := screen.hud
	var state := screen.battle.state
	assert_true(state.is_planning())
	assert_true(hud.preview_visible())
	var expected := WavePreview.of(state)
	assert_eq(hud.preview, expected)
	var day: Array = expected[WavePreview.DAY][WavePreview.KINDS] + expected[WavePreview.DAY][WavePreview.RAID]
	var icons := hud.preview_icons(false)
	assert_eq(icons.size(), day.size())
	assert_false(icons.is_empty())
	assert_eq(icons[0].kind, day[0])
	assert_false(icons[0].known)
	assert_eq(hud.preview_icons(true).size(), expected[WavePreview.NIGHT][WavePreview.KINDS].size() + expected[WavePreview.NIGHT][WavePreview.RAID].size())


func test_preview_reveals_known_monsters_and_follows_the_day() -> void:
	var screen := _deployed()
	var hud := screen.hud
	var state := screen.battle.state
	var first: String = hud.preview_icons(false)[0].kind
	progress.mark_seen(first)
	state.round_number = GameConfig.AIR_RAID_FIRST_ROUND
	screen._process(1.0 / 30.0)
	assert_true(hud.preview_icons(false)[0].known)
	assert_eq(hud.preview, WavePreview.of(state))
	assert_false(hud.preview[WavePreview.DAY][WavePreview.RAID].is_empty())
	screen.start_round()
	screen._process(1.0 / 30.0)
	assert_false(hud.preview_visible())


func test_preview_without_known_callback_shows_everything() -> void:
	var hud := BattleHud.new().setup(0.0)
	add_child_autofree(hud)
	assert_true(hud.is_known("crawler"))
	hud.known = func(kind: String) -> bool: return kind == "wasp"
	assert_true(hud.is_known("wasp"))
	assert_false(hud.is_known("crawler"))
