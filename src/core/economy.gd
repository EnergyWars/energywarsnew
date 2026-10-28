class_name Economy
extends RefCounted

const KILL_COINS_PER := 4
const MAX_KILL_COINS := 6
const STRUCTURE_COINS := 12
const COIN_SPEED := 120.0
const COIN_DRAG := 4.0
const EXPORT_EPSILON := 0.0001

var state: BattleState
var events: BattleEvents
var combo := 0
var combo_timer := 0.0


func _init(p_state: BattleState, p_events: BattleEvents) -> void:
	state = p_state
	events = p_events


func enemy_killed(enemy: Enemy, cause: String = "kill") -> void:
	state.kills += 1
	combo += 1
	combo_timer = GameConfig.COMBO_WINDOW
	state.best_combo = maxi(state.best_combo, combo)
	var coins := clampi(enemy.bounty / KILL_COINS_PER, 1, MAX_KILL_COINS)
	drop(enemy.position, enemy.bounty, coins)
	events.emit(cause, {"position": enemy.position, "kind": enemy.kind, "bounty": enemy.bounty, "combo": combo, "boss": enemy.is_boss()})
	var bonus := Formulas.combo_bonus(combo)
	if bonus > 0:
		credit(bonus)
		events.emit("combo", {"count": combo, "tier": Formulas.combo_tier(combo), "bonus": bonus, "position": enemy.position})


func structure_destroyed(building: Building) -> void:
	var bounty := int(building.definition().get("bounty", 0))
	state.structures_destroyed += 1
	drop(building.position, bounty, STRUCTURE_COINS)


func drop(position: Vector2, value: int, coins: int) -> void:
	if value <= 0:
		return
	var count := clampi(coins, 1, value)
	var base := value / count
	var rest := value - base * count
	for i in count:
		var angle := state.rng.randf() * TAU
		var velocity := Vector2.from_angle(angle) * COIN_SPEED * state.rng.randf_range(0.4, 1.0)
		state.pickups.append(Pickup.new(position, base + (1 if i < rest else 0), velocity))


func credit(amount: int) -> void:
	state.money += amount
	state.earned += amount


func update(delta: float) -> void:
	_export(delta)
	update_pickups(delta)


func update_pickups(delta: float) -> void:
	if combo > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			if combo >= GameConfig.COMBO_TIERS[0]:
				events.emit("combo_end", {"count": combo})
			combo = 0
	if state.pickups.is_empty():
		return
	for pickup: Pickup in state.pickups.duplicate():
		pickup.age += delta
		pickup.position += pickup.velocity * delta
		pickup.velocity = pickup.velocity.lerp(Vector2.ZERO, clampf(COIN_DRAG * delta, 0.0, 1.0))
		if pickup.age >= GameConfig.PICKUP_DELAY:
			collect(pickup)


func reset_combo() -> void:
	if combo >= GameConfig.COMBO_TIERS[0]:
		events.emit("combo_end", {"count": combo})
	combo = 0
	combo_timer = 0.0


func _export(delta: float) -> void:
	for building in state.of_kind(GameConfig.EXPORTER):
		var batch := Formulas.export_batch(building)
		if batch <= 0.0:
			continue
		var amount := minf(building.energy, Formulas.export_rate(building) * delta)
		building.energy -= amount
		building.export_buffer += amount
		if building.export_buffer + EXPORT_EPSILON < batch:
			continue
		building.export_buffer = maxf(building.export_buffer - batch, 0.0)
		var coins := Formulas.export_income(batch) + building.export_carry
		var value := int(floor(coins + EXPORT_EPSILON))
		building.export_carry = maxf(coins - value, 0.0)
		if value > 0:
			credit(value)
			events.emit("export", {"position": building.position, "value": value, "id": building.id})


func collect(pickup: Pickup) -> void:
	var index := state.pickups.find(pickup)
	if index < 0:
		return
	state.pickups.remove_at(index)
	credit(pickup.value)
	events.emit("collect", {"position": pickup.position, "value": pickup.value})


func collect_all() -> void:
	for pickup: Pickup in state.pickups.duplicate():
		collect(pickup)
