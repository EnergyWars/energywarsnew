extends GutTest

var tracker: GestureTracker


func before_each() -> void:
	tracker = GestureTracker.new()


func test_tap() -> void:
	assert_true(tracker.press(0, Vector2(100, 100)))
	assert_true(tracker.is_active())
	var moved := tracker.move(0, Vector2(105, 100))
	assert_eq(moved.kind, GestureTracker.DRAG)
	assert_false(moved.moved)
	var result := tracker.release(0, Vector2(105, 100))
	assert_eq(result.kind, GestureTracker.TAP)
	assert_false(tracker.is_active())


func test_drag() -> void:
	tracker.press(0, Vector2(100, 100))
	var moved := tracker.move(0, Vector2(160, 100))
	assert_true(moved.moved)
	assert_true(tracker.move(0, Vector2(105, 100)).moved)
	assert_eq(tracker.release(0, Vector2(105, 100)).kind, GestureTracker.DRAG_END)


func test_pinch_reports_zoom_and_pan() -> void:
	tracker.press(0, Vector2(100, 100))
	assert_false(tracker.press(1, Vector2(200, 100)))
	assert_true(tracker.multi)
	var result := tracker.move(1, Vector2(300, 100))
	assert_eq(result.kind, GestureTracker.PINCH)
	assert_almost_eq(float(result.zoom), 2.0, 0.001)
	assert_eq(result.pan, Vector2(50, 0))
	assert_eq(tracker.release(1, Vector2(300, 100)), {})
	var pan := tracker.move(0, Vector2(120, 100))
	assert_eq(pan.zoom, 1.0)
	assert_eq(pan.pan, Vector2(20, 0))
	assert_eq(tracker.release(0, Vector2(120, 100)).kind, GestureTracker.MULTI_END)
	assert_false(tracker.multi)


func test_unknown_fingers_are_ignored() -> void:
	assert_eq(tracker.move(5, Vector2.ZERO), {})
	assert_eq(tracker.release(5, Vector2.ZERO), {})


func test_cancel_and_center() -> void:
	assert_eq(tracker.center(), Vector2.ZERO)
	assert_eq(tracker.span(), 0.0)
	tracker.press(0, Vector2(0, 0))
	tracker.press(1, Vector2(10, 0))
	assert_eq(tracker.center(), Vector2(5, 0))
	assert_eq(tracker.span(), 10.0)
	tracker.cancel()
	assert_false(tracker.is_active())
	assert_eq(tracker.primary, -1)


func test_double_tap_and_hold_is_flagged() -> void:
	tracker.press(0, Vector2(100, 100), 1.0)
	assert_false(tracker.double)
	var first := tracker.release(0, Vector2(100, 100), 1.1)
	assert_eq(first.kind, GestureTracker.TAP)
	assert_false(first.double)
	tracker.press(0, Vector2(110, 105), 1.3)
	assert_true(tracker.double)
	tracker.move(0, Vector2(200, 105))
	var second := tracker.release(0, Vector2(200, 105), 1.8)
	assert_eq(second.kind, GestureTracker.DRAG_END)
	assert_true(second.double)
	assert_false(tracker.double)


func test_double_tap_needs_time_and_proximity() -> void:
	tracker.press(0, Vector2(100, 100), 1.0)
	tracker.release(0, Vector2(100, 100), 1.0)
	tracker.press(0, Vector2(100, 100), 1.0 + GestureTracker.DOUBLE_TAP_TIME + 0.1)
	assert_false(tracker.double)
	tracker.release(0, Vector2(100, 100), 2.0)
	tracker.press(0, Vector2(300, 100), 2.1)
	assert_false(tracker.double)


func test_drag_does_not_arm_double_tap() -> void:
	tracker.press(0, Vector2(100, 100), 1.0)
	tracker.move(0, Vector2(200, 100))
	tracker.release(0, Vector2(200, 100), 1.1)
	tracker.press(0, Vector2(200, 100), 1.2)
	assert_false(tracker.double)


func test_second_finger_cancels_double() -> void:
	tracker.press(0, Vector2(100, 100), 1.0)
	tracker.release(0, Vector2(100, 100), 1.1)
	tracker.press(0, Vector2(100, 100), 1.2)
	assert_true(tracker.double)
	tracker.press(1, Vector2(200, 100), 1.25)
	assert_false(tracker.double)
	assert_true(tracker.multi)


func test_now_uses_engine_clock() -> void:
	assert_almost_eq(GestureTracker.now(), Time.get_ticks_msec() / 1000.0, 0.05)
