class_name BattleReport
extends RefCounted

var level_index := 0
var survival := false
var target := 0
var won := false
var days := 0
var stars := 0
var kills := 0
var combo := 0
var completed: Array[String] = []
var new_challenges: Array[String] = []
var points := 0
var first_conquest := false
var improved := false


static func from_state(state: BattleState) -> BattleReport:
	var report := BattleReport.new()
	report.level_index = state.level_index
	report.survival = state.is_survival()
	report.target = state.setup.days
	report.won = state.phase == BattleState.Phase.WON
	report.days = state.days_survived
	report.stars = state.stars()
	report.kills = state.kills
	report.combo = state.best_combo
	report.completed = Challenges.completed(state)
	return report


func is_endless() -> bool:
	return survival and target == 0
