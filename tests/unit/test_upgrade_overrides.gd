extends GutTest

const PLANS := {
	"solar": {
		"output": {"levels": [{"cost": 10, "effect": 1.5}, {"cost": 25, "effect": 1.6}, {"cost": 0, "effect": 3.0}]},
		"transfer": {"levels": [{"cost": 5, "effect": 1.25}]},
		"crit": {"levels": [{"cost": 5, "effect": 1.5}]},
		"range": {"levels": []},
		"hull": {"levels": [{"cost": 5}]},
	},
	"zapper": {"crit": {"levels": [{"cost": 5, "effect": 1.5}]}},
	"lamp": {"hull": {}},
}


func before_each() -> void:
	UpgradeOverrides.set_plans(PLANS)


func after_each() -> void:
	UpgradeOverrides.reset()


func _building(kind: String) -> Building:
	return Building.new(1, kind, Vector2.ZERO)


func test_table_is_built_from_valid_levels_only() -> void:
	var table := UpgradeOverrides.table("solar", GameConfig.TRACK_OUTPUT)
	assert_eq(table.max, 3)
	assert_eq(table.levels[2].cost, 1)
	assert_true(UpgradeOverrides.table("solar", GameConfig.TRACK_RANGE).is_empty())
	assert_true(UpgradeOverrides.table("solar", GameConfig.TRACK_HULL).is_empty())
	assert_true(UpgradeOverrides.table("lamp", GameConfig.TRACK_HULL).is_empty())
	assert_true(UpgradeOverrides.table("relay", GameConfig.TRACK_OUTPUT).is_empty())


func test_reset_removes_all_tables() -> void:
	UpgradeOverrides.reset()
	assert_true(UpgradeOverrides.table("solar", GameConfig.TRACK_OUTPUT).is_empty())


func test_multiplier_follows_the_table() -> void:
	var solar := _building(GameConfig.SOLAR)
	assert_eq(Formulas.multiplier(solar, GameConfig.TRACK_OUTPUT), 1.0)
	solar.set_level(GameConfig.TRACK_OUTPUT, 1)
	assert_eq(Formulas.multiplier(solar, GameConfig.TRACK_OUTPUT), 1.5)
	solar.set_level(GameConfig.TRACK_OUTPUT, 3)
	assert_eq(Formulas.multiplier(solar, GameConfig.TRACK_OUTPUT), 3.0)
	solar.set_level(GameConfig.TRACK_OUTPUT, 9)
	assert_eq(Formulas.multiplier(solar, GameConfig.TRACK_OUTPUT), 3.0)


func test_cost_and_max_level_follow_the_table() -> void:
	var solar := _building(GameConfig.SOLAR)
	assert_eq(Formulas.max_level(solar, GameConfig.TRACK_OUTPUT), 3)
	assert_eq(Formulas.upgrade_cost(solar, GameConfig.TRACK_OUTPUT), 10)
	solar.set_level(GameConfig.TRACK_OUTPUT, 1)
	assert_eq(Formulas.upgrade_cost(solar, GameConfig.TRACK_OUTPUT), 25)
	solar.set_level(GameConfig.TRACK_OUTPUT, 3)
	assert_true(Formulas.is_maxed(solar, GameConfig.TRACK_OUTPUT))


func test_other_buildings_keep_their_parametric_curves() -> void:
	var relay := _building(GameConfig.RELAY)
	assert_eq(Formulas.max_level(relay, GameConfig.TRACK_RANGE), int(GameConfig.TRACKS[GameConfig.TRACK_RANGE].max))
	relay.set_level(GameConfig.TRACK_RANGE, 2)
	assert_almost_eq(Formulas.multiplier(relay, GameConfig.TRACK_RANGE), 1.0 + float(GameConfig.TRACKS[GameConfig.TRACK_RANGE].step) * 2.0, 0.0001)


func test_transfer_and_crit_use_the_table_gain() -> void:
	var solar := _building(GameConfig.SOLAR)
	solar.set_level(GameConfig.TRACK_TRANSFER, 1)
	assert_almost_eq(Formulas.transfer_factor(solar), 0.75, 0.0001)
	var zapper := _building(GameConfig.ZAPPER)
	zapper.set_level(GameConfig.TRACK_CRIT, 1)
	assert_almost_eq(Formulas.crit_chance(zapper), GameConfig.CRIT_CHANCE + 0.5, 0.0001)


func test_parametric_transfer_and_crit_are_unchanged() -> void:
	var relay := _building(GameConfig.RELAY)
	relay.set_level(GameConfig.TRACK_TRANSFER, 3)
	assert_almost_eq(Formulas.transfer_factor(relay), 1.0 - float(GameConfig.TRACKS[GameConfig.TRACK_TRANSFER].step) * 3.0, 0.0001)
	var laser := _building(GameConfig.LASER)
	assert_almost_eq(Formulas.crit_chance(laser), GameConfig.CRIT_CHANCE, 0.0001)


func test_shipped_file_is_valid_json() -> void:
	UpgradeOverrides.reset()
	assert_true(FileAccess.file_exists(UpgradeOverrides.PATH))
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(UpgradeOverrides.PATH))
	assert_true(parsed is Dictionary)
	assert_eq(int(parsed.schema), 1)
