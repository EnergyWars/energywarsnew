extends GutTest

const PATH := "user://test_progress.json"


func after_each() -> void:
	DirAccess.remove_absolute(PATH)


func _report(index: int, survival: bool, won: bool, completed: Array[String], days: int = 0, target: int = 0) -> BattleReport:
	var report := BattleReport.new()
	report.level_index = index
	report.survival = survival
	report.won = won
	report.completed = completed
	report.days = days
	report.target = target
	report.stars = Formulas.survival_stars(target) if survival and won else 0
	report.kills = 10
	report.combo = 4
	return report


func test_fresh_progress() -> void:
	var progress := Progress.new(PATH).load_progress()
	assert_false(progress.is_conquered(0))
	assert_false(progress.is_conquered(-1))
	assert_false(progress.is_conquered(99))
	assert_eq(progress.stars_for(0), 0)
	assert_eq(progress.stars_for(99), 0)
	assert_eq(progress.best_days(0), 0)
	assert_eq(progress.total_stars(), 0)
	assert_eq(progress.skill_points(), 0)
	assert_eq(progress.conquered_count(), 0)
	assert_eq(progress.location, 0)
	assert_true(progress.completed(0).is_empty())
	assert_eq(progress.arsenal().kinds(), GameConfig.STARTER_KINDS)


func test_campaign_win_conquers_and_awards_points() -> void:
	var progress := Progress.new(PATH)
	var report := progress.record(_report(1, false, true, [Challenges.CONQUER, Challenges.LOST] as Array[String]))
	assert_true(report.first_conquest)
	assert_true(progress.is_conquered(1))
	assert_eq(progress.location, 1)
	assert_eq(report.new_challenges, [Challenges.CONQUER, Challenges.LOST] as Array[String])
	assert_eq(report.points, Challenges.CONQUER_POINTS + Challenges.DEFAULT_POINTS)
	assert_eq(progress.skill_points(), report.points)
	assert_eq(progress.total_kills, 10)
	assert_eq(progress.best_combo, 4)
	var again := progress.record(_report(1, false, true, [Challenges.CONQUER] as Array[String]))
	assert_false(again.first_conquest)
	assert_true(again.new_challenges.is_empty())
	assert_eq(again.points, 0)
	assert_eq(progress.total_kills, 20)


func test_campaign_loss_changes_nothing_but_totals() -> void:
	var progress := Progress.new(PATH)
	var report := progress.record(_report(0, false, false, [] as Array[String]))
	assert_false(report.first_conquest)
	assert_false(progress.is_conquered(0))
	assert_eq(progress.skill_points(), 0)
	assert_eq(progress.total_kills, 10)


func test_survival_records_stars_and_days() -> void:
	var progress := Progress.new(PATH)
	progress.mark_conquered(0)
	var report := progress.record(_report(0, true, true, [Challenges.SURVIVE] as Array[String], 10, 10))
	assert_eq(progress.stars_for(0), 2)
	assert_true(report.improved)
	assert_eq(report.new_challenges, [Challenges.SURVIVE] as Array[String])
	assert_eq(progress.best_days(0), 10)
	var weaker := progress.record(_report(0, true, true, [] as Array[String], 5, 5))
	assert_false(weaker.improved)
	assert_eq(progress.stars_for(0), 2)
	assert_eq(progress.total_stars(), 2)
	var lost := progress.record(_report(0, true, false, [] as Array[String], 3, 15))
	assert_false(lost.improved)
	assert_eq(progress.stars_for(0), 2)


func test_endless_tracks_the_record() -> void:
	var progress := Progress.new(PATH)
	progress.mark_conquered(2)
	var report := _report(2, true, false, [] as Array[String], 12, 0)
	assert_true(report.is_endless())
	assert_true(progress.record(report).improved)
	assert_eq(progress.best_days(2), 12)
	assert_eq(progress.stars_for(2), 0)
	assert_false(progress.record(_report(2, true, false, [] as Array[String], 7, 0)).improved)
	assert_eq(progress.best_days(2), 12)


func test_record_ignores_invalid_level() -> void:
	var progress := Progress.new(PATH)
	var report := progress.record(_report(99, false, true, [Challenges.CONQUER] as Array[String]))
	assert_false(report.first_conquest)
	assert_eq(progress.total_kills, 10)
	progress.mark_conquered(-1)
	progress.mark_conquered(99)
	assert_eq(progress.conquered_count(), 0)


func test_techs_spend_and_refund_points() -> void:
	var progress := Progress.new(PATH)
	progress.mark_conquered(0)
	assert_eq(progress.skill_points(), Challenges.CONQUER_POINTS)
	progress.techs.append("laser")
	assert_true(progress.has_tech("laser"))
	assert_eq(progress.spent_points(), TechTree.cost("laser"))
	assert_true(progress.arsenal().has(GameConfig.LASER))
	assert_eq(progress.reset_techs(), TechTree.cost("laser"))
	assert_false(progress.has_tech("laser"))
	assert_eq(progress.skill_points(), Challenges.CONQUER_POINTS)


func test_save_and_load_roundtrip() -> void:
	var progress := Progress.new(PATH)
	progress.record(_report(0, false, true, [Challenges.CONQUER, Challenges.CORE] as Array[String]))
	progress.record(_report(0, true, true, [Challenges.SURVIVE] as Array[String], 15, 15))
	progress.techs.append("laser")
	progress.location = 0
	assert_true(progress.save())
	var loaded := Progress.new(PATH).load_progress()
	assert_true(loaded.is_conquered(0))
	assert_eq(loaded.stars_for(0), 3)
	assert_eq(loaded.best_days(0), 15)
	assert_true(loaded.is_done(0, Challenges.CORE))
	assert_true(loaded.has_tech("laser"))
	assert_eq(loaded.skill_points(), progress.skill_points())
	assert_eq(loaded.total_kills, 20)
	assert_eq(loaded.best_combo, 4)
	assert_eq(loaded.location, 0)


func test_legacy_version_is_migrated() -> void:
	var progress := Progress.new(PATH)
	progress.apply({"version": Progress.LEGACY_VERSION, "stars": {"dawn": 3, "beetle_hill": 1, "swarm_night": 0, "nowhere": 2}, "total_kills": 40, "best_combo": 9})
	assert_true(progress.is_conquered(0))
	assert_true(progress.is_conquered(1))
	assert_false(progress.is_conquered(2))
	assert_true(progress.is_done(0, Challenges.CONQUER))
	assert_false(progress.is_done(0, Challenges.CORE))
	assert_eq(progress.stars_for(0), 0)
	assert_eq(progress.skill_points(), Challenges.CONQUER_POINTS * 2)
	assert_eq(progress.location, 1)
	assert_eq(progress.total_kills, 40)
	assert_eq(progress.best_combo, 9)
	assert_eq(int(progress.to_dict().version), Progress.VERSION)


func test_legacy_file_is_migrated_on_load() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "stars": {"dawn": 2}, "total_kills": 5, "best_combo": 1}))
	file.close()
	var progress := Progress.new(PATH).load_progress()
	assert_true(progress.is_conquered(0))
	assert_eq(progress.total_kills, 5)
	assert_true(progress.save())
	var reloaded := Progress.new(PATH).load_progress()
	assert_true(reloaded.is_conquered(0))
	assert_eq(reloaded.total_kills, 5)


func test_legacy_broken_stars_are_ignored() -> void:
	var progress := Progress.new(PATH)
	progress.apply({"version": Progress.LEGACY_VERSION, "stars": "broken", "total_kills": 3})
	assert_eq(progress.conquered_count(), 0)
	assert_eq(progress.total_kills, 3)


func test_invalid_data_is_sanitized() -> void:
	var progress := Progress.new(PATH)
	progress.apply({"version": Progress.VERSION, "regions": {
		"dawn": {"conquered": true, "stars": 9, "best_days": -4, "done": ["conquer", "conquer", "bogus", "survive"]},
		"beetle_hill": {"conquered": "yes", "stars": -3, "done": "broken"},
		"swarm_night": {"done": ["conquer"]},
		"nowhere": {"conquered": true},
		"outpost": "broken"},
		"techs": ["laser", "laser", "bogus"], "location": 42, "total_kills": -5, "best_combo": "4"})
	assert_eq(progress.stars_for(0), 3)
	assert_eq(progress.best_days(0), 0)
	assert_eq(progress.completed(0), [Challenges.CONQUER, Challenges.SURVIVE] as Array[String])
	assert_false(progress.is_conquered(1))
	assert_eq(progress.stars_for(1), 0)
	assert_true(progress.is_conquered(2))
	assert_false(progress.is_conquered(3))
	assert_false(progress.regions.has("nowhere"))
	assert_eq(progress.techs, ["laser"] as Array[String])
	assert_eq(progress.location, GameConfig.level_count() - 1)
	assert_eq(progress.total_kills, 0)
	assert_eq(progress.best_combo, 4)
	progress.apply({"version": Progress.VERSION, "regions": "broken", "techs": "broken"})
	assert_true(progress.regions.is_empty())
	assert_true(progress.techs.is_empty())


func test_overspent_techs_are_reset() -> void:
	var progress := Progress.new(PATH)
	progress.apply({"version": Progress.VERSION, "regions": {}, "techs": ["laser", "tesla"]})
	assert_true(progress.techs.is_empty())


func test_unknown_version_resets() -> void:
	var progress := Progress.new(PATH)
	progress.mark_conquered(0)
	progress.apply({"version": 999, "regions": {"dawn": {"conquered": true}}, "total_kills": 50})
	assert_false(progress.is_conquered(0))
	assert_eq(progress.total_kills, 0)
	progress.apply({"total_kills": 50})
	assert_eq(progress.total_kills, 0)


func test_corrupt_file_is_ignored() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("{not json")
	file.close()
	var progress := Progress.new(PATH).load_progress()
	assert_eq(progress.total_stars(), 0)


func test_save_fails_for_invalid_path() -> void:
	assert_false(Progress.new("user://missing_dir/sub/progress.json").save())
