extends GutTest

const LEVEL := {"day": 100.0, "night": 50.0}


func test_round_starts_in_full_daylight() -> void:
	assert_eq(DayCycle.light(0.0, LEVEL), 1.0)
	assert_false(DayCycle.is_night(0.0, LEVEL))
	assert_false(DayCycle.is_finished(0.0, LEVEL))


func test_light_fades_at_dusk_and_is_zero_at_night() -> void:
	var dusk := 100.0 - GameConfig.DUSK_RAMP * 0.5
	assert_almost_eq(DayCycle.light(dusk, LEVEL), 0.5, 0.001)
	assert_eq(DayCycle.light(100.0, LEVEL), 0.0)
	assert_eq(DayCycle.light(149.0, LEVEL), 0.0)
	assert_true(DayCycle.is_night(100.0, LEVEL))
	assert_true(DayCycle.is_night(149.0, LEVEL))


func test_dawn_after_the_night() -> void:
	assert_false(DayCycle.is_night(150.0, LEVEL))
	assert_true(DayCycle.is_finished(150.0, LEVEL))
	assert_almost_eq(DayCycle.light(150.0 + GameConfig.DAWN_RAMP * 0.5, LEVEL), 0.5, 0.001)
	assert_eq(DayCycle.light(400.0, LEVEL), 1.0)


func test_time_to_switch() -> void:
	assert_almost_eq(DayCycle.time_to_switch(0.0, LEVEL), 100.0, 0.001)
	assert_almost_eq(DayCycle.time_to_switch(120.0, LEVEL), 30.0, 0.001)
	assert_eq(DayCycle.time_to_switch(200.0, LEVEL), 0.0)


func test_length() -> void:
	assert_eq(DayCycle.length(LEVEL), 150.0)
