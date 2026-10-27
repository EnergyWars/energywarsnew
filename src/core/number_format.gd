class_name NumberFormat
extends RefCounted


static func grouped(value: int) -> String:
	var digits := str(absi(value))
	var parts: Array[String] = []
	while digits.length() > 3:
		parts.push_front(digits.substr(digits.length() - 3))
		digits = digits.substr(0, digits.length() - 3)
	parts.push_front(digits)
	return ("-" if value < 0 else "") + ",".join(parts)


static func clock(seconds: float) -> String:
	var total := maxi(int(ceil(seconds)), 0)
	return "%d:%02d" % [total / 60, total % 60]
