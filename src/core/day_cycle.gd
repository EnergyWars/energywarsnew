class_name DayCycle
extends RefCounted


static func length(level: Dictionary) -> float:
	return float(level.day) + float(level.night)


static func light(round_time: float, level: Dictionary) -> float:
	var day := float(level.day)
	if round_time < day:
		return clampf((day - round_time) / GameConfig.DUSK_RAMP, 0.0, 1.0)
	if round_time < length(level):
		return 0.0
	return clampf((round_time - length(level)) / GameConfig.DAWN_RAMP, 0.0, 1.0)


static func is_night(round_time: float, level: Dictionary) -> bool:
	return round_time >= float(level.day) and round_time < length(level)


static func is_finished(round_time: float, level: Dictionary) -> bool:
	return round_time >= length(level)


static func time_to_switch(round_time: float, level: Dictionary) -> float:
	var day := float(level.day)
	if round_time < day:
		return day - round_time
	return maxf(length(level) - round_time, 0.0)
