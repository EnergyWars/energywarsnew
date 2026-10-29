class_name RewardDirector
extends RefCounted

const MAX_HIT_FLOATERS := 6
const KILL_PITCH_STEP := 0.04
const KILL_PITCH_CAP := 25
const SLOWMO_TIME := 0.7
const SLOWMO_SCALE := 0.3
const BOSS_SHAKE := 12.0
const STRUCTURE_SHAKE := 24.0
const PLASMA_SHAKE := 4.0
const LOST_SHAKE := 9.0
const UPGRADE_PITCH_CAP := 10

var view: BattleView
var hud: BattleHud
var celebrations: CelebrationLayer
var sfx: SfxPlayer
var slowmo := 0.0
var _hit_budget := 0
var _guards_announced := false


func _init(p_view: BattleView, p_hud: BattleHud, p_celebrations: CelebrationLayer, p_sfx: SfxPlayer) -> void:
	view = p_view
	hud = p_hud
	celebrations = p_celebrations
	sfx = p_sfx


func time_scale() -> float:
	return SLOWMO_SCALE if slowmo > 0.0 else 1.0


func update(delta: float) -> void:
	slowmo = maxf(slowmo - delta, 0.0)


func handle(events: Array[Dictionary]) -> void:
	_hit_budget = MAX_HIT_FLOATERS
	for event in events:
		var handler := "_on_" + str(event.type)
		if has_method(handler):
			call(handler, event)


func _play(id: String, pitch: float = 1.0) -> void:
	if sfx != null:
		sfx.play(id, pitch)


func _vibrate(ms: int) -> void:
	if sfx != null:
		sfx.vibrate(ms)


func _on_kill(event: Dictionary) -> void:
	var position: Vector2 = event.position
	var color := AppTheme.enemy_color(str(event.kind))
	var combo := int(event.combo)
	var fx := view.fx
	fx.burst(position, color, 14, 260.0, 6.0, 0.5)
	fx.burst(position, AppTheme.ENERGY_CORE, 6, 160.0, 3.0, 0.3)
	fx.ring(position, 4.0, 34.0, color, 0.3, 3.0)
	fx.floater("+%d" % int(event.bounty), position + Vector2(0, -16), AppTheme.GOLD, 0.9)
	_play(SoundBank.POP, 1.0 + mini(combo, KILL_PITCH_CAP) * KILL_PITCH_STEP)
	if combo >= 2:
		hud.show_combo(combo, Formulas.combo_tier(combo))
	if bool(event.boss):
		fx.burst(position, AppTheme.PLASMA_ORANGE, 40, 420.0, 9.0, 0.9)
		fx.ring(position, 10.0, 140.0, AppTheme.GOLD, 0.6, 8.0)
		fx.add_shake(BOSS_SHAKE)
		_play(SoundBank.BOOM_BIG)
		_vibrate(80)
		hud.banner(Texts.t("BANNER_BOSS_DOWN"), Texts.enemy_name(str(event.kind)), AppTheme.GOLD, 1.4)


func _on_purge(event: Dictionary) -> void:
	var position: Vector2 = event.position
	view.fx.burst(position, AppTheme.enemy_color(str(event.kind)), 10, 220.0, 6.0, 0.5)
	view.fx.floater("+%d" % int(event.bounty), position, AppTheme.GOLD)


func _on_combo(event: Dictionary) -> void:
	var tier := int(event.tier)
	var color := AppTheme.combo_color(tier)
	hud.banner("×%d" % int(event.count), "%s  +%d" % [Texts.combo_title(tier), int(event.bonus)], color, 1.2)
	_play(SoundBank.COMBO, 1.0 + 0.08 * tier)
	_vibrate(20 + 10 * tier)
	if tier >= 3:
		celebrations.burst_confetti(Vector2(hud.size.x * 0.5, hud.size.y * 0.45), 30 + 15 * tier)


func _on_combo_end(_event: Dictionary) -> void:
	hud.hide_combo()


func _on_hit(event: Dictionary) -> void:
	var position: Vector2 = event.position
	var crit := bool(event.crit)
	view.fx.burst(position, AppTheme.ENERGY_CORE if not crit else AppTheme.GOLD, 3 if not crit else 8, 140.0, 3.0, 0.2)
	if crit:
		view.fx.floater(Texts.format("FLOAT_CRIT", [int(round(float(event.amount)))]), position + Vector2(0, -24), AppTheme.GOLD, 1.3)
		return
	if _hit_budget <= 0:
		return
	_hit_budget -= 1
	view.fx.floater(str(int(round(float(event.amount)))), position + Vector2(0, -10), Color(1, 1, 1, 0.9), 0.7, 0.6)


func _on_bolt(event: Dictionary) -> void:
	var color := AppTheme.GOLD if bool(event.crit) else AppTheme.building_color(GameConfig.ZAPPER)
	view.fx.bolt(event.from, event.to, color, 3.0, 0.14, 16.0)
	_play(SoundBank.ZAP, randf_range(0.9, 1.2))


func _on_chain(event: Dictionary) -> void:
	view.fx.bolt_path(event.points, AppTheme.building_color(GameConfig.TESLA), 3.5, 0.22, 14.0)
	for point: Vector2 in event.points:
		view.fx.burst(point, AppTheme.VIOLET, 4, 120.0, 3.0, 0.25)
	_play(SoundBank.TESLA, randf_range(0.95, 1.1))


func _on_plasma_launch(event: Dictionary) -> void:
	view.fx.burst(event.from, AppTheme.PLASMA_ORANGE, 8, 160.0, 5.0, 0.3)
	_play(SoundBank.THUMP)


func _on_plasma_hit(event: Dictionary) -> void:
	var position: Vector2 = event.position
	var splash := float(event.splash)
	view.fx.ring(position, 8.0, splash, AppTheme.PLASMA_ORANGE, 0.4, 6.0)
	view.fx.burst(position, AppTheme.PLASMA_ORANGE, 26, 300.0, 7.0, 0.55)
	view.fx.burst(position, AppTheme.GOLD, 10, 200.0, 4.0, 0.4)
	view.fx.add_shake(PLASMA_SHAKE)
	_play(SoundBank.BOOM, randf_range(0.9, 1.1))


func _on_enemy_attack(event: Dictionary) -> void:
	if bool(event.ranged):
		view.fx.tracer(event.from, event.to, AppTheme.DANGER, 3.0 if str(event.kind) != "tank" else 6.0, 0.1)
		_play(SoundBank.ENEMY_SHOT, randf_range(0.9, 1.15))
	else:
		view.fx.burst(event.to.lerp(event.from, 0.5), AppTheme.DANGER, 3, 90.0, 3.0, 0.2)


func _on_enemy_shot(event: Dictionary) -> void:
	view.fx.tracer(event.from, event.to, AppTheme.DANGER, 5.0, 0.12)
	view.fx.burst(event.to, AppTheme.WARNING, 5, 120.0, 4.0, 0.25)
	_play(SoundBank.ENEMY_SHOT, 0.8)


func _on_building_hit(event: Dictionary) -> void:
	if not bool(event.player):
		view.fx.burst(event.position, AppTheme.WARNING, 3, 120.0, 4.0, 0.25)
		return
	view.fx.ring(event.position, 20.0, 40.0, AppTheme.DANGER, 0.2, 3.0)
	_play(SoundBank.HURT)


func _on_shielded(event: Dictionary) -> void:
	view.fx.ring(event.position, 30.0, 50.0, AppTheme.SHIELD_BLUE, 0.25, 4.0)
	_play(SoundBank.SHIELD)


func _on_building_destroyed(event: Dictionary) -> void:
	var position: Vector2 = event.position
	view.fx.burst(position, AppTheme.PLASMA_ORANGE, 40, 380.0, 8.0, 0.8)
	view.fx.burst(position, AppTheme.METAL, 16, 260.0, 5.0, 0.9, 300.0)
	view.fx.ring(position, 10.0, 120.0, AppTheme.DANGER, 0.5, 6.0)
	view.fx.add_shake(LOST_SHAKE)
	_play(SoundBank.BOOM_BIG, 1.15)
	_vibrate(120)
	if not bool(event.core):
		hud.toast(Texts.format("TOAST_LOST", [Texts.building_name(str(event.kind))]), AppTheme.DANGER)


func _on_structure_destroyed(event: Dictionary) -> void:
	var position: Vector2 = event.position
	var fx := view.fx
	for i in 4:
		var offset := Vector2.from_angle(fx.rng.randf() * TAU) * fx.rng.randf_range(10.0, 50.0)
		fx.burst(position + offset, [AppTheme.PLASMA_ORANGE, AppTheme.GOLD, AppTheme.DANGER, AppTheme.ENERGY_CORE][i], 40, 520.0, 10.0, 1.1)
	fx.ring(position, 20.0, 320.0, AppTheme.GOLD, 0.8, 12.0)
	fx.ring(position, 10.0, 200.0, AppTheme.ENERGY_CORE, 0.5, 6.0)
	fx.add_shake(STRUCTURE_SHAKE)
	fx.floater("+%d" % int(event.bounty), position + Vector2(0, -40), AppTheme.GOLD, 2.4, 1.6)
	slowmo = SLOWMO_TIME
	_play(SoundBank.BOOM_BIG)
	_play(SoundBank.FANFARE)
	_vibrate(250)
	celebrations.burst_confetti(view.to_screen(position), 90)
	var left := int(event.left)
	var subtitle := Texts.format("BANNER_BASES_LEFT", [left]) if left > 0 else Texts.t("BANNER_ALL_DESTROYED")
	hud.banner(Texts.format("BANNER_STRUCTURE_DOWN", [Texts.building_name(str(event.kind)).to_upper()]), subtitle, AppTheme.GOLD, 2.2)


func _on_collect(event: Dictionary) -> void:
	celebrations.fly_coin(view.to_screen(event.position), hud.money_anchor(), int(event.value))


func _on_export(event: Dictionary) -> void:
	var position: Vector2 = event.position
	view.fx.burst(position, AppTheme.GOLD, 6, 120.0, 4.0, 0.4)
	view.fx.floater("+%d" % int(event.value), position + Vector2(0, -30), AppTheme.GOLD, 0.9)
	celebrations.fly_coin(view.to_screen(position), hud.money_anchor(), int(event.value))


func coin_arrived(_value: int) -> void:
	hud.pulse_money()
	_play(SoundBank.COIN, randf_range(0.95, 1.25))


func _on_wave(event: Dictionary) -> void:
	if not bool(event.night):
		return
	hud.toast(Texts.format("TOAST_NIGHT_WAVE", [int(event.index), int(event.total)]), AppTheme.WARNING)
	_play(SoundBank.RUMBLE)
	_vibrate(30)


func _on_heal(event: Dictionary) -> void:
	var color := AppTheme.HEAL
	view.fx.tracer(event.from, event.to, color, 4.0, 0.25)
	view.fx.burst(event.to, color, 6, 90.0, 4.0, 0.4, -60.0)
	if _hit_budget > 0:
		_hit_budget -= 1
		view.fx.floater("+%d" % int(round(float(event.amount))), event.to + Vector2(0, -20), color, 0.8)
	_play(SoundBank.HEAL, randf_range(0.95, 1.1))


func _on_landed(event: Dictionary) -> void:
	view.fx.burst(event.position, Color("#c8b48a"), 18, 160.0, 5.0, 0.5)
	view.fx.ring(event.position, 6.0, 46.0, AppTheme.CHUTE, 0.4, 3.0)
	hud.toast(Texts.t("TOAST_LANDED"), AppTheme.ENERGY)
	_play(SoundBank.THUMP, 0.8)
	_vibrate(20)


func _on_core_deployed(event: Dictionary) -> void:
	var position: Vector2 = event.position
	view.fx.ring(position, 20.0, 220.0, AppTheme.ENERGY, 0.7, 8.0)
	view.fx.burst(position, AppTheme.ENERGY, 40, 320.0, 6.0, 0.8)
	view.fx.burst(position, Color("#c8b48a"), 24, 220.0, 5.0, 0.6)
	view.fx.add_shake(8.0)
	hud.banner(Texts.t("BANNER_BASE"), Texts.t("BANNER_BASE_SUB"), AppTheme.ENERGY, 2.0)
	_play(SoundBank.BOOM_BIG, 0.9)
	_play(SoundBank.UPGRADE)
	_vibrate(120)


func _on_clear_order(event: Dictionary) -> void:
	view.fx.ring(event.position, 30.0, 6.0, AppTheme.GOLD, 0.35, 3.0)
	_play(SoundBank.CLICK, 1.2)


func _on_scout_boarded(event: Dictionary) -> void:
	view.fx.ring(event.position, 40.0, 8.0, AppTheme.SCOUT, 0.5, 4.0)
	hud.toast(Texts.t("TOAST_BOARDED"), AppTheme.ENERGY)


func _on_structures_spawned(event: Dictionary) -> void:
	hud.announce_structures(int(event.count))


func _on_rifle(event: Dictionary) -> void:
	view.fx.tracer(event.from, event.to, AppTheme.GOLD, 2.0, 0.08)
	view.fx.burst(event.to, AppTheme.GOLD, 2, 90.0, 2.0, 0.15)
	_play(SoundBank.ENEMY_SHOT, 1.6)


func _on_focus(event: Dictionary) -> void:
	view.fx.ring(event.to, 34.0, 10.0, AppTheme.DANGER, 0.4, 4.0)
	_play(SoundBank.CLICK, 0.8)


func _on_relocated(event: Dictionary) -> void:
	view.fx.ring(event.from, 30.0, 6.0, AppTheme.ENERGY_CORE, 0.3, 3.0)
	view.fx.ring(event.position, 6.0, 60.0, AppTheme.ENERGY, 0.4, 5.0)
	view.fx.floater("-%d" % int(event.cost), event.position, AppTheme.GOLD, 1.0)
	_play(SoundBank.PLACE)
	_vibrate(15)


func _on_stalled(_event: Dictionary) -> void:
	hud.toast(Texts.t("TOAST_STALLED"), AppTheme.WARNING)


func _on_fuel_marked(event: Dictionary) -> void:
	view.fx.ring(event.position, 34.0, 8.0, AppTheme.FLAME, 0.35, 3.0)
	_play(SoundBank.CLICK, 1.3)


func _on_fuel_unmarked(event: Dictionary) -> void:
	view.fx.ring(event.position, 8.0, 30.0, AppTheme.ON_SURFACE_VARIANT, 0.3, 2.0)
	_play(SoundBank.CLICK, 0.9)


func _on_fuel_empty(event: Dictionary) -> void:
	view.fx.ring(event.position, 20.0, 60.0, AppTheme.FLAME, 0.5, 3.0)
	hud.toast(Texts.t("TOAST_FUEL_EMPTY"), AppTheme.WARNING)


func _on_scout_route(event: Dictionary) -> void:
	view.fx.ring(event.target, 30.0, 6.0, AppTheme.ENERGY_CORE, 0.35, 3.0)
	_play(SoundBank.CLICK, 1.1)


func _on_cleared(event: Dictionary) -> void:
	if event.has("fire"):
		view.fx.burst(event.position, AppTheme.FLAME, 24, 200.0, 6.0, 0.7, -160.0)
		view.fx.burst(event.position, AppTheme.TRUNK, 10, 120.0, 4.0, 0.6, -60.0)
		_play(SoundBank.WHOOSH, 0.9)
		return
	var tree := str(event.obstacle) == LevelMap.TREE
	var color := AppTheme.TREE_LIGHT if tree else AppTheme.ROCK
	view.fx.burst(event.position, color, 22, 220.0, 6.0, 0.6)
	view.fx.burst(event.position, AppTheme.TRUNK if tree else AppTheme.ROCK_DARK, 10, 160.0, 4.0, 0.5, 200.0)
	view.fx.add_shake(3.0)
	_play(SoundBank.CUT if tree else SoundBank.BOOM, 0.8)
	_vibrate(25)


func _on_fight_started(event: Dictionary) -> void:
	hud.banner(Texts.t("BANNER_FIGHT"), Texts.format("BANNER_ROUND_SUB", [int(event.round)]), AppTheme.DANGER, 1.6)
	_play(SoundBank.WHOOSH)


func _on_nightfall(_event: Dictionary) -> void:
	hud.banner(Texts.t("BANNER_NIGHT"), Texts.t("BANNER_NIGHT_SUB"), AppTheme.VIOLET, 2.2)
	_play(SoundBank.NIGHT)


func _on_night_over(event: Dictionary) -> void:
	var burning := int(event.get("burning", 0))
	var subtitle := Texts.format("BANNER_NIGHT_OVER_BURN", [burning]) if burning > 0 else Texts.t("BANNER_NIGHT_OVER_SUB")
	hud.banner(Texts.t("BANNER_NIGHT_OVER"), subtitle, AppTheme.GOLD, 2.0)
	_play(SoundBank.DAY)


func _on_burned(event: Dictionary) -> void:
	var position: Vector2 = event.position
	var fx := view.fx
	fx.burst(position, AppTheme.FLAME, 18, 200.0, 6.0, 0.7, -160.0)
	fx.burst(position, AppTheme.FLAME_CORE, 8, 120.0, 4.0, 0.5, -200.0)
	fx.burst(position, AppTheme.METAL_DARK, 6, 80.0, 5.0, 0.9, -60.0)
	fx.ring(position, 6.0, 40.0, AppTheme.FLAME, 0.35, 3.0)
	if _hit_budget > 0:
		_hit_budget -= 1
		_play(SoundBank.THUMP, randf_range(1.3, 1.6))
	if bool(event.boss):
		fx.add_shake(BOSS_SHAKE * 0.5)
		hud.toast(Texts.format("TOAST_BOSS_BURNED", [Texts.enemy_name(str(event.kind))]), AppTheme.GOLD)


func _on_guards_ignited(event: Dictionary) -> void:
	hud.toast(Texts.format("TOAST_GUARDS_BURN", [int(event.count)]), AppTheme.FLAME)
	_play(SoundBank.WHOOSH, 0.8)


func _on_round_cleared(event: Dictionary) -> void:
	hud.banner(Texts.format("BANNER_ROUND_CLEARED", [int(event.round)]), Texts.t("BANNER_ROUND_CLEARED_SUB"), AppTheme.SUCCESS, 2.4)
	_play(SoundBank.FANFARE)
	_vibrate(60)
	celebrations.burst_confetti(Vector2(hud.size.x * 0.5, hud.size.y * 0.4), 60)


func _on_spawn(event: Dictionary) -> void:
	if bool(event.get("guard", false)):
		view.fx.burst(event.position, AppTheme.WARNING, 8, 90.0, 5.0, 0.4)
		if not _guards_announced:
			_guards_announced = true
			hud.toast(Texts.t("TOAST_GUARDS"), AppTheme.WARNING)
		return
	view.fx.burst(event.position, AppTheme.NEST_SPOT, 6, 90.0, 5.0, 0.35)
	if bool(event.boss):
		hud.toast(Texts.t("TOAST_BOSS"), AppTheme.DANGER)
		_play(SoundBank.ALARM, 0.7)


func _on_placed(event: Dictionary) -> void:
	var position: Vector2 = event.position
	var radius := float(GameConfig.building(str(event.kind)).radius)
	view.fx.ring(position, radius, radius + 50.0, AppTheme.ENERGY, 0.35, 5.0)
	view.fx.burst(position, Color("#c8b48a"), 14, 180.0, 5.0, 0.45)
	view.fx.add_shake(2.0)
	_play(SoundBank.PLACE)
	_vibrate(15)


func _on_link(event: Dictionary) -> void:
	view.fx.bolt(event.from, event.to, AppTheme.ENERGY_CORE, 5.0, 0.25, 22.0)
	view.fx.burst(event.to, AppTheme.ENERGY, 12, 200.0, 4.0, 0.35)
	_play(SoundBank.LINK)
	_vibrate(12)


func _on_unlink(event: Dictionary) -> void:
	var cause := str(event.cause)
	var middle: Vector2 = (event.from as Vector2).lerp(event.to, 0.5)
	if cause == "cut":
		view.fx.burst(middle, AppTheme.ENERGY_CORE, 18, 260.0, 4.0, 0.4)
		view.fx.burst(event.from, AppTheme.ENERGY, 6, 120.0, 3.0, 0.3)
		_play(SoundBank.CUT)
		_vibrate(18)
	elif cause == "sabotage":
		view.fx.burst(middle, AppTheme.DANGER, 18, 220.0, 4.0, 0.45)
		hud.toast(Texts.t("TOAST_SABOTAGE"), AppTheme.DANGER)
		_play(SoundBank.CUT, 0.7)


func _on_upgraded(event: Dictionary) -> void:
	var position: Vector2 = event.position
	view.fx.burst(position, AppTheme.GOLD, 24, 240.0, 5.0, 0.6)
	view.fx.ring(position, 10.0, 80.0, AppTheme.GOLD, 0.45, 5.0)
	view.fx.floater(Texts.format("FLOAT_LEVEL", [int(event.level)]), position + Vector2(0, -40), AppTheme.GOLD, 1.3, 1.1)
	_play(SoundBank.UPGRADE, 1.0 + 0.05 * mini(int(event.level), UPGRADE_PITCH_CAP))
	_vibrate(25)
	if bool(event.get("overloaded", false)):
		hud.toast(Texts.t("TOAST_OVERLOADED"), AppTheme.DANGER)


func _on_sold(event: Dictionary) -> void:
	view.fx.burst(event.position, AppTheme.GOLD, 12, 160.0, 4.0, 0.4)
	view.fx.floater("+%d" % int(event.refund), event.position, AppTheme.GOLD, 1.1)
	_play(SoundBank.CASH)


func _on_victory(_event: Dictionary) -> void:
	_play(SoundBank.FANFARE)
	_vibrate(300)
	celebrations.burst_confetti(Vector2(hud.size.x * 0.5, hud.size.y * 0.6), 200, 1300.0)


func _on_defeat(_event: Dictionary) -> void:
	view.fx.add_shake(EffectPool.MAX_SHAKE)
	_play(SoundBank.DEFEAT)
	_vibrate(400)
