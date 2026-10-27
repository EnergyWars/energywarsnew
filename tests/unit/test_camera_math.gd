extends GutTest

const VIEW := Vector2(720, 1280)
const MAP := Vector2(1400, 2000)


func test_min_zoom_fits_map() -> void:
	var zoom := CameraMath.min_zoom(VIEW, MAP)
	assert_almost_eq(zoom, 720.0 / (1400.0 + CameraMath.MARGIN * 2.0), 0.001)
	assert_eq(CameraMath.min_zoom(VIEW, Vector2.ZERO), CameraMath.MIN_ZOOM)
	assert_eq(CameraMath.min_zoom(VIEW, Vector2(10, 10)), 1.0)


func test_clamp_zoom() -> void:
	assert_eq(CameraMath.clamp_zoom(10.0, VIEW, MAP), CameraMath.MAX_ZOOM)
	assert_eq(CameraMath.clamp_zoom(0.01, VIEW, MAP), CameraMath.min_zoom(VIEW, MAP))
	assert_eq(CameraMath.clamp_zoom(1.0, VIEW, MAP), 1.0)


func test_clamp_center_inside_map() -> void:
	var clamped := CameraMath.clamp_center(Vector2(-500, 5000), 1.0, VIEW, MAP)
	assert_eq(clamped, Vector2(360 - CameraMath.MARGIN, 2000 - 640 + CameraMath.MARGIN))
	assert_eq(CameraMath.clamp_center(Vector2(700, 1000), 1.0, VIEW, MAP), Vector2(700, 1000))


func test_clamp_center_centers_small_maps() -> void:
	assert_eq(CameraMath.clamp_center(Vector2(10, 10), 0.3, VIEW, Vector2(400, 400)), Vector2(200, 200))


func test_screen_world_roundtrip() -> void:
	var center := Vector2(500, 900)
	var world := CameraMath.screen_to_world(Vector2(100, 200), center, 0.8, VIEW)
	assert_almost_eq(CameraMath.world_to_screen(world, center, 0.8, VIEW).x, 100.0, 0.001)
	assert_eq(CameraMath.screen_to_world(VIEW * 0.5, center, 2.0, VIEW), center)


func test_zoom_at_keeps_focus_point() -> void:
	var center := Vector2(500, 900)
	var focus := Vector2(100, 300)
	var before := CameraMath.screen_to_world(focus, center, 1.0, VIEW)
	var moved := CameraMath.zoom_at(center, 1.0, 1.5, focus, VIEW)
	var after := CameraMath.screen_to_world(focus, moved, 1.5, VIEW)
	assert_almost_eq(after.x, before.x, 0.001)
	assert_almost_eq(after.y, before.y, 0.001)
