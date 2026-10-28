class_name PlanHistory
extends RefCounted

const MAX_STEPS := 100

var baseline: PlanSnapshot
var baseline_stats: EnergyStats
var _steps: Array[PlanSnapshot] = []
var _in_stroke := false
var _stroke_tag := ""


func begin(state: BattleState) -> void:
	baseline = PlanSnapshot.capture(state)
	baseline_stats = EnergyStats.measure(state)
	_steps.clear()
	close_stroke()


func end() -> void:
	baseline = null
	_steps.clear()
	close_stroke()


func is_active() -> bool:
	return baseline != null


func open_stroke() -> void:
	_in_stroke = true
	_stroke_tag = ""


func close_stroke() -> void:
	_in_stroke = false
	_stroke_tag = ""


func wants(tag: String = "") -> bool:
	return is_active() and not (_in_stroke and not tag.is_empty() and tag == _stroke_tag)


func record(snapshot: PlanSnapshot, tag: String = "") -> void:
	if snapshot == null or not wants(tag):
		return
	_steps.append(snapshot)
	_stroke_tag = tag if _in_stroke else ""
	if _steps.size() > MAX_STEPS:
		_steps.pop_front()


func size() -> int:
	return _steps.size()


func can_undo() -> bool:
	return is_active() and not _steps.is_empty()


func pop() -> PlanSnapshot:
	_stroke_tag = ""
	return _steps.pop_back() if can_undo() else null


func rewind() -> PlanSnapshot:
	_steps.clear()
	close_stroke()
	return baseline
