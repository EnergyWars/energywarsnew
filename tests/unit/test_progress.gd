extends GutTest

const PATH := "user://test_progress.json"


func after_each() -> void:
	DirAccess.remove_absolute(PATH)


func test_fresh_progress() -> void:
	var progress := Progress.new(PATH).load_progress()
	assert_true(progress.is_unlocked(0))
	assert_false(progress.is_unlocked(1))
	assert_false(progress.is_unlocked(-1))
	assert_false(progress.is_unlocked(99))
	assert_eq(progress.stars_for(0), 0)
	assert_eq(progress.stars_for(99), 0)
	assert_eq(progress.next_level(), 0)
	assert_eq(progress.total_stars(), 0)


func test_record_unlocks_next_level() -> void:
	var progress := Progress.new(PATH)
	assert_true(progress.record(0, 2, 40, 12))
	assert_true(progress.is_unlocked(1))
	assert_eq(progress.next_level(), 1)
	assert_false(progress.record(0, 1, 10, 3))
	assert_eq(progress.stars_for(0), 2)
	assert_eq(progress.total_kills, 50)
	assert_eq(progress.best_combo, 12)
	assert_true(progress.record(0, 3, 0, 0))
	assert_eq(progress.total_stars(), 3)
	assert_false(progress.record(99, 3, 5, 0))
	assert_eq(progress.total_kills, 55)


func test_next_level_when_all_done() -> void:
	var progress := Progress.new(PATH)
	for i in GameConfig.level_count():
		progress.record(i, 1, 0, 0)
	assert_eq(progress.next_level(), GameConfig.level_count() - 1)


func test_save_and_load_roundtrip() -> void:
	var progress := Progress.new(PATH)
	progress.record(0, 3, 12, 7)
	progress.record(1, 1, 3, 2)
	assert_true(progress.save())
	var loaded := Progress.new(PATH).load_progress()
	assert_eq(loaded.stars_for(0), 3)
	assert_eq(loaded.stars_for(1), 1)
	assert_eq(loaded.total_kills, 15)
	assert_eq(loaded.best_combo, 7)


func test_invalid_data_is_sanitized() -> void:
	var progress := Progress.new(PATH)
	progress.apply({"version": Progress.VERSION, "stars": {"dawn": 9, "nowhere": 2, "beetle_hill": -3}, "total_kills": -5, "best_combo": "4"})
	assert_eq(progress.stars_for(0), 3)
	assert_eq(progress.stars_for(1), 0)
	assert_false(progress.stars.has("nowhere"))
	assert_eq(progress.total_kills, 0)
	assert_eq(progress.best_combo, 4)
	progress.apply({"version": Progress.VERSION, "stars": "broken"})
	assert_true(progress.stars.is_empty())


func test_unknown_version_resets() -> void:
	var progress := Progress.new(PATH)
	progress.record(0, 3, 10, 10)
	progress.apply({"version": 999, "stars": {"dawn": 3}, "total_kills": 50})
	assert_eq(progress.stars_for(0), 0)
	assert_eq(progress.total_kills, 0)


func test_corrupt_file_is_ignored() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("{not json")
	file.close()
	var progress := Progress.new(PATH).load_progress()
	assert_eq(progress.total_stars(), 0)


func test_save_fails_for_invalid_path() -> void:
	assert_false(Progress.new("user://missing_dir/sub/progress.json").save())
