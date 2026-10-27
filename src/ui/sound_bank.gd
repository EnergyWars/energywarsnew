class_name SoundBank
extends RefCounted

const CLICK := "click"
const PLACE := "place"
const LINK := "link"
const CUT := "cut"
const ZAP := "zap"
const TESLA := "tesla"
const THUMP := "thump"
const BOOM := "boom"
const BOOM_BIG := "boom_big"
const POP := "pop"
const COIN := "coin"
const CASH := "cash"
const COMBO := "combo"
const UPGRADE := "upgrade"
const ALARM := "alarm"
const NIGHT := "night"
const DAY := "day"
const FANFARE := "fanfare"
const DEFEAT := "defeat"
const STAR := "star"
const HURT := "hurt"
const ENEMY_SHOT := "enemy_shot"
const ERROR := "error"
const SHIELD := "shield"
const WHOOSH := "whoosh"
const HEAL := "heal"
const RUMBLE := "rumble"
const DEFAULT_GAP := 0.05

const SOUNDS := {
	CLICK: {"volume_db": -18.0, "gap": 0.03, "notes": [
		{"at": 0.0, "len": 0.035, "freq": 1900.0, "to": 1300.0, "vol": 0.6, "decay": 60.0},
	]},
	PLACE: {"volume_db": -8.0, "gap": 0.08, "notes": [
		{"at": 0.0, "len": 0.09, "wave": "noise", "smooth": 0.2, "vol": 0.7, "decay": 30.0},
		{"at": 0.0, "len": 0.16, "freq": 180.0, "to": 80.0, "vol": 0.9, "decay": 14.0},
		{"at": 0.05, "len": 0.14, "freq": 660.0, "wave": "triangle", "vol": 0.4, "decay": 14.0},
		{"at": 0.1, "len": 0.18, "freq": 990.0, "wave": "triangle", "vol": 0.35, "decay": 12.0},
	]},
	LINK: {"volume_db": -10.0, "gap": 0.08, "notes": [
		{"at": 0.0, "len": 0.2, "freq": 300.0, "to": 1600.0, "wave": "square", "vol": 0.25, "decay": 4.0},
		{"at": 0.0, "len": 0.16, "wave": "noise", "smooth": 0.6, "vol": 0.3, "decay": 12.0},
		{"at": 0.16, "len": 0.25, "freq": 1600.0, "vol": 0.5, "decay": 10.0},
		{"at": 0.16, "len": 0.25, "freq": 2400.0, "vol": 0.2, "decay": 14.0},
	]},
	CUT: {"volume_db": -9.0, "gap": 0.06, "notes": [
		{"at": 0.0, "len": 0.14, "wave": "noise", "smooth": 0.85, "vol": 0.7, "decay": 18.0},
		{"at": 0.0, "len": 0.14, "freq": 2600.0, "to": 500.0, "vol": 0.4, "decay": 12.0},
	]},
	ZAP: {"volume_db": -16.0, "gap": 0.04, "notes": [
		{"at": 0.0, "len": 0.08, "freq": 1100.0, "to": 300.0, "wave": "square", "vol": 0.35, "decay": 28.0},
		{"at": 0.0, "len": 0.06, "wave": "noise", "smooth": 0.9, "vol": 0.5, "decay": 40.0},
	]},
	TESLA: {"volume_db": -13.0, "gap": 0.08, "notes": [
		{"at": 0.0, "len": 0.28, "wave": "noise", "smooth": 0.7, "vol": 0.6, "decay": 9.0},
		{"at": 0.0, "len": 0.28, "freq": 120.0, "wave": "square", "vol": 0.3, "decay": 8.0},
		{"at": 0.02, "len": 0.2, "freq": 400.0, "to": 1400.0, "wave": "square", "vol": 0.15, "decay": 10.0},
	]},
	THUMP: {"volume_db": -10.0, "gap": 0.08, "notes": [
		{"at": 0.0, "len": 0.22, "freq": 150.0, "to": 55.0, "vol": 1.0, "decay": 11.0},
		{"at": 0.0, "len": 0.12, "wave": "noise", "smooth": 0.15, "vol": 0.4, "decay": 25.0},
	]},
	BOOM: {"volume_db": -9.0, "gap": 0.07, "notes": [
		{"at": 0.0, "len": 0.5, "wave": "noise", "smooth": 0.08, "vol": 1.0, "decay": 7.0},
		{"at": 0.0, "len": 0.4, "freq": 95.0, "to": 38.0, "vol": 0.8, "decay": 6.0},
	]},
	BOOM_BIG: {"volume_db": -5.0, "gap": 0.2, "notes": [
		{"at": 0.0, "len": 1.3, "wave": "noise", "smooth": 0.05, "vol": 1.0, "decay": 2.8},
		{"at": 0.0, "len": 1.1, "freq": 70.0, "to": 28.0, "vol": 0.9, "decay": 2.6},
		{"at": 0.0, "len": 0.25, "wave": "noise", "smooth": 0.45, "vol": 0.5, "decay": 14.0},
		{"at": 0.15, "len": 0.6, "wave": "noise", "smooth": 0.1, "vol": 0.6, "decay": 5.0},
	]},
	POP: {"volume_db": -10.0, "gap": 0.035, "notes": [
		{"at": 0.0, "len": 0.1, "freq": 380.0, "to": 1100.0, "vol": 1.0, "decay": 22.0},
		{"at": 0.0, "len": 0.06, "freq": 760.0, "to": 2200.0, "vol": 0.25, "decay": 40.0},
		{"at": 0.0, "len": 0.05, "wave": "noise", "smooth": 0.5, "vol": 0.3, "decay": 50.0},
	]},
	COIN: {"volume_db": -15.0, "gap": 0.045, "notes": [
		{"at": 0.0, "len": 0.06, "freq": 987.8, "wave": "square", "vol": 0.35, "decay": 6.0},
		{"at": 0.06, "len": 0.24, "freq": 1318.5, "wave": "square", "vol": 0.35, "decay": 11.0},
		{"at": 0.06, "len": 0.24, "freq": 2637.0, "vol": 0.15, "decay": 16.0},
	]},
	CASH: {"volume_db": -9.0, "gap": 0.06, "notes": [
		{"at": 0.0, "len": 0.06, "wave": "noise", "smooth": 0.5, "vol": 0.45, "decay": 50.0},
		{"at": 0.03, "len": 0.5, "freq": 1568.0, "vol": 0.6, "decay": 7.0},
		{"at": 0.03, "len": 0.5, "freq": 2093.0, "vol": 0.45, "decay": 8.0},
		{"at": 0.03, "len": 0.25, "freq": 4327.7, "vol": 0.18, "decay": 18.0},
	]},
	COMBO: {"volume_db": -8.0, "gap": 0.12, "notes": [
		{"at": 0.0, "len": 0.14, "freq": 523.3, "wave": "triangle", "vol": 0.6, "decay": 6.0},
		{"at": 0.06, "len": 0.14, "freq": 659.3, "wave": "triangle", "vol": 0.6, "decay": 6.0},
		{"at": 0.12, "len": 0.14, "freq": 784.0, "wave": "triangle", "vol": 0.6, "decay": 6.0},
		{"at": 0.18, "len": 0.4, "freq": 1046.5, "wave": "square", "vol": 0.3, "decay": 5.0},
		{"at": 0.18, "len": 0.4, "freq": 2093.0, "vol": 0.25, "decay": 7.0},
	]},
	UPGRADE: {"volume_db": -9.0, "gap": 0.1, "notes": [
		{"at": 0.0, "len": 0.16, "freq": 523.3, "wave": "triangle", "vol": 0.6, "decay": 6.0},
		{"at": 0.07, "len": 0.16, "freq": 659.3, "wave": "triangle", "vol": 0.6, "decay": 6.0},
		{"at": 0.14, "len": 0.16, "freq": 784.0, "wave": "triangle", "vol": 0.6, "decay": 6.0},
		{"at": 0.21, "len": 0.45, "freq": 1046.5, "wave": "triangle", "vol": 0.7, "decay": 4.0},
		{"at": 0.21, "len": 0.45, "freq": 2093.0, "vol": 0.2, "decay": 7.0},
	]},
	ALARM: {"volume_db": -12.0, "gap": 0.5, "notes": [
		{"at": 0.0, "len": 0.16, "freq": 880.0, "wave": "square", "vol": 0.35, "decay": 2.0},
		{"at": 0.18, "len": 0.16, "freq": 660.0, "wave": "square", "vol": 0.35, "decay": 2.0},
		{"at": 0.36, "len": 0.16, "freq": 880.0, "wave": "square", "vol": 0.35, "decay": 2.0},
		{"at": 0.54, "len": 0.22, "freq": 660.0, "wave": "square", "vol": 0.35, "decay": 3.0},
	]},
	NIGHT: {"volume_db": -7.0, "gap": 1.0, "notes": [
		{"at": 0.0, "len": 1.0, "freq": 392.0, "to": 196.0, "wave": "triangle", "vol": 0.6, "attack": 0.05, "decay": 1.8},
		{"at": 0.0, "len": 1.2, "freq": 98.0, "vol": 0.6, "attack": 0.1, "decay": 1.6},
		{"at": 0.4, "len": 0.9, "freq": 233.1, "wave": "triangle", "vol": 0.4, "attack": 0.05, "decay": 2.5},
	]},
	DAY: {"volume_db": -9.0, "gap": 1.0, "notes": [
		{"at": 0.0, "len": 0.5, "freq": 1046.5, "vol": 0.7, "decay": 6.0},
		{"at": 0.0, "len": 0.25, "freq": 2888.3, "vol": 0.18, "decay": 16.0},
		{"at": 0.11, "len": 0.65, "freq": 1568.0, "vol": 0.7, "decay": 5.0},
		{"at": 0.22, "len": 0.8, "freq": 2093.0, "vol": 0.5, "decay": 4.0},
	]},
	FANFARE: {"volume_db": -7.0, "gap": 0.6, "notes": [
		{"at": 0.0, "len": 0.13, "freq": 392.0, "wave": "triangle", "vol": 0.6, "decay": 3.0},
		{"at": 0.12, "len": 0.13, "freq": 523.3, "wave": "triangle", "vol": 0.6, "decay": 3.0},
		{"at": 0.24, "len": 0.13, "freq": 659.3, "wave": "triangle", "vol": 0.6, "decay": 3.0},
		{"at": 0.36, "len": 0.9, "freq": 784.0, "wave": "triangle", "vol": 0.7, "attack": 0.01, "decay": 2.2},
		{"at": 0.36, "len": 0.9, "freq": 523.3, "wave": "triangle", "vol": 0.4, "attack": 0.01, "decay": 2.2},
		{"at": 0.36, "len": 0.9, "freq": 659.3, "wave": "triangle", "vol": 0.35, "attack": 0.01, "decay": 2.2},
		{"at": 0.36, "len": 0.9, "freq": 1568.0, "vol": 0.15, "attack": 0.01, "decay": 4.0},
		{"at": 0.36, "len": 0.5, "freq": 784.0, "wave": "square", "vol": 0.08, "attack": 0.01, "decay": 5.0},
	]},
	DEFEAT: {"volume_db": -8.0, "gap": 1.0, "notes": [
		{"at": 0.0, "len": 0.32, "freq": 392.0, "wave": "triangle", "vol": 0.6, "decay": 3.0},
		{"at": 0.3, "len": 0.32, "freq": 311.1, "wave": "triangle", "vol": 0.6, "decay": 3.0},
		{"at": 0.6, "len": 1.0, "freq": 261.6, "wave": "triangle", "vol": 0.6, "decay": 1.8},
		{"at": 0.6, "len": 1.0, "freq": 130.8, "vol": 0.5, "decay": 1.8},
	]},
	STAR: {"volume_db": -9.0, "gap": 0.1, "notes": [
		{"at": 0.0, "len": 0.22, "freq": 2093.0, "vol": 0.45, "decay": 14.0},
		{"at": 0.05, "len": 0.22, "freq": 2637.0, "vol": 0.45, "decay": 14.0},
		{"at": 0.1, "len": 0.22, "freq": 3136.0, "vol": 0.45, "decay": 14.0},
		{"at": 0.15, "len": 0.3, "freq": 4186.0, "vol": 0.4, "decay": 12.0},
	]},
	HURT: {"volume_db": -17.0, "gap": 0.15, "notes": [
		{"at": 0.0, "len": 0.09, "freq": 210.0, "to": 110.0, "wave": "square", "vol": 0.4, "decay": 18.0},
	]},
	ENEMY_SHOT: {"volume_db": -18.0, "gap": 0.08, "notes": [
		{"at": 0.0, "len": 0.07, "wave": "noise", "smooth": 0.5, "vol": 0.5, "decay": 35.0},
		{"at": 0.0, "len": 0.06, "freq": 420.0, "to": 200.0, "wave": "square", "vol": 0.2, "decay": 30.0},
	]},
	ERROR: {"volume_db": -13.0, "gap": 0.2, "notes": [
		{"at": 0.0, "len": 0.08, "freq": 220.0, "wave": "square", "vol": 0.3, "decay": 6.0},
		{"at": 0.1, "len": 0.12, "freq": 175.0, "wave": "square", "vol": 0.3, "decay": 6.0},
	]},
	SHIELD: {"volume_db": -16.0, "gap": 0.15, "notes": [
		{"at": 0.0, "len": 0.16, "freq": 500.0, "to": 950.0, "vol": 0.5, "decay": 9.0},
		{"at": 0.0, "len": 0.16, "freq": 1000.0, "to": 1900.0, "vol": 0.15, "decay": 12.0},
	]},
	HEAL: {"volume_db": -17.0, "gap": 0.12, "notes": [
		{"at": 0.0, "len": 0.18, "freq": 660.0, "to": 990.0, "wave": "triangle", "vol": 0.5, "attack": 0.02, "decay": 9.0},
		{"at": 0.06, "len": 0.2, "freq": 1320.0, "wave": "triangle", "vol": 0.25, "attack": 0.02, "decay": 10.0},
	]},
	RUMBLE: {"volume_db": -9.0, "gap": 1.0, "notes": [
		{"at": 0.0, "len": 1.1, "wave": "noise", "smooth": 0.04, "vol": 0.9, "attack": 0.3, "decay": 2.5},
		{"at": 0.0, "len": 1.1, "freq": 70.0, "to": 50.0, "wave": "square", "vol": 0.18, "attack": 0.3, "decay": 2.5},
	]},
	WHOOSH: {"volume_db": -12.0, "gap": 0.2, "notes": [
		{"at": 0.0, "len": 0.45, "wave": "noise", "smooth": 0.12, "vol": 0.8, "attack": 0.18, "decay": 3.0},
		{"at": 0.0, "len": 0.45, "freq": 220.0, "to": 880.0, "vol": 0.3, "attack": 0.15, "decay": 3.0},
	]},
}

var _streams := {}


static func ids() -> Array[String]:
	var result: Array[String] = []
	for id: String in SOUNDS:
		result.append(id)
	return result


static func has(id: String) -> bool:
	return SOUNDS.has(id)


static func volume_db(id: String) -> float:
	return float(SOUNDS.get(id, {}).get("volume_db", 0.0))


static func gap(id: String) -> float:
	return float(SOUNDS.get(id, {}).get("gap", DEFAULT_GAP))


static func samples(id: String) -> PackedFloat32Array:
	return SoundSynth.render(SOUNDS[id].notes) if has(id) else PackedFloat32Array()


func is_cached(id: String) -> bool:
	return _streams.has(id)


func stream(id: String) -> AudioStreamWAV:
	if not has(id):
		return null
	if not _streams.has(id):
		_streams[id] = SoundSynth.to_stream(samples(id))
	return _streams[id]
