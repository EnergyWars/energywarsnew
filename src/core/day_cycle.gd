class_name DayCycle
extends RefCounted


static func length(level: Dictionary) -> float:
	return float(level.day) + float(level.night)


static func phase_time(time: float, level: Dictionary) -> float:
	return fposmod(time + GameConfig.DAWN_RAMP, length(level))


static func light(time: float, level: Dictionary) -> float:
	var t := phase_time(time, level)
	var day := float(level.day)
	if t >= day:
		return 0.0
	var ramp := GameConfig.DAWN_RAMP
	return clampf(minf(t / ramp, (day - t) / ramp), 0.0, 1.0)


static func is_night(time: float, level: Dictionary) -> bool:
	return phase_time(time, level) >= float(level.day)


static func time_to_switch(time: float, level: Dictionary) -> float:
	var t := phase_time(time, level)
	var day := float(level.day)
	return day - t if t < day else length(level) - t


static func day_number(time: float, level: Dictionary) -> int:
	return int(floor((time + GameConfig.DAWN_RAMP) / length(level))) + 1
