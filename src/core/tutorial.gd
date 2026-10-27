class_name Tutorial
extends RefCounted

const MOVE_SCOUT := "move_scout"
const DEPLOY_CORE := "deploy_core"
const BUILD_SOLAR := "build_solar"
const CONNECT := "connect"
const BUILD_TOWER := "build_tower"
const POWER_TOWER := "power_tower"
const BUILD_WALL := "build_wall"
const CAMERA := "camera"
const STORAGE := "storage"
const CUT := "cut"
const DONE := ""

const ORDER: Array[String] = [MOVE_SCOUT, DEPLOY_CORE, BUILD_SOLAR, CONNECT, BUILD_TOWER, POWER_TOWER, BUILD_WALL, CAMERA, STORAGE, CUT]

var step := DONE
var _index := -1


func _init(active: bool) -> void:
	if active:
		_index = 0
		step = ORDER[0]


func is_active() -> bool:
	return step != DONE


func handle(event: Dictionary) -> bool:
	var advanced := false
	while is_active() and matches(step, event):
		next()
		advanced = true
	return advanced


static func matches(current: String, event: Dictionary) -> bool:
	var type := str(event.get("type", ""))
	var kind := str(event.get("kind", ""))
	match current:
		MOVE_SCOUT:
			return type == "scout_order" or type == "core_deployed"
		DEPLOY_CORE:
			return type == "core_deployed"
		BUILD_SOLAR:
			return type == "placed" and kind == GameConfig.SOLAR
		CONNECT:
			return type == "link"
		BUILD_TOWER:
			return type == "placed" and GameConfig.is_tower(kind)
		POWER_TOWER:
			return type == "link" and bool(event.get("tower", false))
		BUILD_WALL:
			return (type == "placed" and kind == GameConfig.BULWARK) or type == "fight_started"
		CAMERA:
			return type == "camera" or type == "fight_started"
		STORAGE:
			return (type == "placed" and kind == GameConfig.BATTERY) or type == "nightfall"
		CUT:
			return type == "unlink" or type == "nightfall" or type == "victory"
	return false


func next() -> void:
	_index += 1
	step = ORDER[_index] if _index < ORDER.size() else DONE


func skip() -> void:
	_index = ORDER.size()
	step = DONE
