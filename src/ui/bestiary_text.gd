class_name BestiaryText
extends RefCounted

const UNKNOWN_VALUE := "?"
const ROW_KEYS: Array[String] = ["BESTIARY_HP", "STAT_ARMOR", "BESTIARY_SPEED", "STAT_DAMAGE", "STAT_RANGE"]


static func rows(kind: String, known: bool = true) -> Array[Array]:
	var values: Array[String] = []
	if known:
		values = _values(kind)
	var result: Array[Array] = []
	for index in ROW_KEYS.size():
		result.append([ROW_KEYS[index], values[index] if known else UNKNOWN_VALUE])
	return result


static func _values(kind: String) -> Array[String]:
	var definition := GameConfig.enemy(kind)
	var reach := float(definition.get("reach", 0.0))
	return [
		NumberFormat.grouped(int(round(float(definition.get("hp", 0.0))))),
		StatText.armor_value(float(definition.get("armor", 0.0))),
		StatText.cells(float(definition.get("speed", 0.0))),
		NumberFormat.grouped(int(round(float(definition.get("damage", 0.0))))),
		StatText.cells(reach) if reach > 0.0 else Texts.t("BESTIARY_MELEE"),
	]


static func badges(kind: String) -> Array[Array]:
	var definition := GameConfig.enemy(kind)
	var result: Array[Array] = [["CLASS_%s" % str(definition.get("class", GameConfig.CLASS_MELEE)).to_upper(), AppTheme.ENERGY]]
	if bool(definition.get("boss", false)):
		result.append(["BESTIARY_BOSS", AppTheme.DANGER])
	if GameConfig.is_nocturnal(kind):
		result.append(["BESTIARY_NIGHT", AppTheme.VIOLET])
	else:
		result.append(["BESTIARY_DAY", AppTheme.GOLD])
	return result


static func name_of(kind: String, known: bool) -> String:
	return Texts.enemy_name(kind) if known else Texts.t("BESTIARY_UNKNOWN")


static func description_of(kind: String, known: bool) -> String:
	return Texts.enemy_desc(kind) if known else Texts.t("BESTIARY_UNKNOWN_HINT")
