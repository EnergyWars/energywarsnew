extends GutTest

const PATH := "user://test_settings_locale.cfg"


func after_each() -> void:
	DirAccess.remove_absolute(PATH)
	TranslationServer.set_locale("en")


func test_locale_is_validated_and_persisted() -> void:
	var settings := AppSettings.new(PATH)
	settings.set_locale("de")
	assert_eq(TranslationServer.get_locale(), "de")
	assert_eq(AppSettings.new(PATH).load_settings().locale, "de")
	settings.set_locale("xx")
	assert_eq(settings.locale, "")
	assert_true(AppSettings.LOCALES.has(settings.resolved_locale().substr(0, 2)) or settings.resolved_locale() == AppSettings.FALLBACK_LOCALE)


func test_rolling_number_counts_up() -> void:
	var roll := RollingNumber.new()
	roll.set_target(100.0)
	assert_eq(roll.value, 100.0)
	roll.set_target(200.0)
	assert_true(roll.is_rolling())
	assert_true(roll.advance(RollingNumber.ROLL_TIME * 0.5))
	assert_between(roll.value, 101.0, 199.0)
	roll.advance(RollingNumber.ROLL_TIME)
	assert_eq(roll.value, 200.0)
	assert_false(roll.advance(0.1))
	roll.set_target(50.0)
	assert_eq(roll.value, 50.0)


func test_juice_float_scale() -> void:
	assert_eq(Juice.float_scale(0.0), 0.4)
	assert_gt(Juice.float_scale(0.12), 1.2)
	assert_eq(Juice.float_scale(1.0), 1.0)
