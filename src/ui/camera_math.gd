class_name CameraMath
extends RefCounted

const MIN_ZOOM := 0.3
const MAX_ZOOM := 1.8
const MARGIN := 160.0


static func min_zoom(view_size: Vector2, map_size: Vector2) -> float:
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		return MIN_ZOOM
	var fit := minf(view_size.x / (map_size.x + MARGIN * 2.0), view_size.y / (map_size.y + MARGIN * 2.0))
	return clampf(fit, MIN_ZOOM, 1.0)


static func clamp_zoom(zoom: float, view_size: Vector2, map_size: Vector2) -> float:
	return clampf(zoom, min_zoom(view_size, map_size), MAX_ZOOM)


static func clamp_center(center: Vector2, zoom: float, view_size: Vector2, map_size: Vector2) -> Vector2:
	var half := view_size / maxf(zoom, 0.001) * 0.5
	var result := center
	for axis in 2:
		var low := half[axis] - MARGIN
		var high := map_size[axis] - half[axis] + MARGIN
		result[axis] = map_size[axis] * 0.5 if low > high else clampf(center[axis], low, high)
	return result


static func screen_to_world(screen: Vector2, center: Vector2, zoom: float, view_size: Vector2) -> Vector2:
	return center + (screen - view_size * 0.5) / zoom


static func world_to_screen(world: Vector2, center: Vector2, zoom: float, view_size: Vector2) -> Vector2:
	return (world - center) * zoom + view_size * 0.5


static func zoom_at(center: Vector2, zoom: float, new_zoom: float, focus: Vector2, view_size: Vector2) -> Vector2:
	var anchor := screen_to_world(focus, center, zoom, view_size)
	return anchor - (focus - view_size * 0.5) / new_zoom
