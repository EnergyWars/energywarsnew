class_name GameConfig
extends RefCounted

const TICK := 1.0 / 30.0
const MAX_STEPS_PER_FRAME := 12
const SPEEDS: Array[float] = [1.0, 2.0, 3.0]

const TEAM_PLAYER := 0
const TEAM_ENEMY := 1

const CORE := "core"
const SOLAR := "solar"
const RELAY := "relay"
const BATTERY := "battery"
const ZAPPER := "zapper"
const LASER := "laser"
const TESLA := "tesla"
const PLASMA := "plasma"
const SHIELD := "shield"
const EXPORTER := "exporter"
const HEALER := "healer"
const BULWARK := "bulwark"
const NEST := "nest"
const CAMP := "camp"
const TURRET := "turret"

const BUILD_ORDER: Array[String] = [BULWARK, SOLAR, RELAY, BATTERY, EXPORTER, ZAPPER, LASER, HEALER, TESLA, PLASMA, SHIELD]

const MODE_BOLT := "bolt"
const MODE_LASER := "laser"
const MODE_CHAIN := "chain"
const MODE_PLASMA := "plasma"

const TRACK_RATE := "rate"
const TRACK_RANGE := "range"
const TRACK_LINKS := "links"
const TRACK_OUTPUT := "output"
const TRACK_CAPACITY := "capacity"
const TRACK_POWER := "power"
const TRACK_SPEED := "speed"
const TRACK_HULL := "hull"

const TRACKS := {
	TRACK_RATE: {"max": 5, "step": 0.5, "price": 0.55},
	TRACK_RANGE: {"max": 5, "step": 0.15, "price": 0.5},
	TRACK_LINKS: {"max": 3, "step": 1.0, "price": 0.9},
	TRACK_OUTPUT: {"max": 5, "step": 0.4, "price": 0.7},
	TRACK_CAPACITY: {"max": 5, "step": 0.6, "price": 0.6},
	TRACK_POWER: {"max": 5, "step": 0.3, "price": 0.7},
	TRACK_SPEED: {"max": 5, "step": 0.15, "price": 0.6},
	TRACK_HULL: {"max": 5, "step": 0.5, "price": 0.8},
}
const TRACK_GROWTH := 1.7

const BUILDINGS := {
	CORE: {"team": TEAM_PLAYER, "cost": 0, "upgrade_base": 120, "hp": 1500.0, "radius": 50.0, "cells": 2, "capacity": 300.0, "output": 3.0,
		"links": 3, "range": 280.0, "rate": 40.0, "build_radius": 420.0, "vision": 460.0,
		"attack": {"mode": MODE_BOLT, "damage": 12.0, "cooldown": 0.7, "energy": 3.0, "range": 220.0, "ground": true, "air": true},
		"tracks": [TRACK_RATE, TRACK_RANGE, TRACK_LINKS, TRACK_POWER]},
	SOLAR: {"team": TEAM_PLAYER, "cost": 40, "hp": 70.0, "radius": 26.0, "capacity": 30.0, "output": 8.0, "solar": true,
		"links": 1, "range": 240.0, "rate": 10.0, "build_radius": 240.0, "receives": false,
		"tracks": [TRACK_OUTPUT, TRACK_RATE, TRACK_RANGE, TRACK_LINKS]},
	RELAY: {"team": TEAM_PLAYER, "cost": 30, "hp": 90.0, "radius": 24.0, "capacity": 20.0,
		"links": 3, "range": 330.0, "rate": 30.0, "build_radius": 320.0, "vision": 320.0,
		"tracks": [TRACK_RATE, TRACK_RANGE, TRACK_LINKS]},
	BATTERY: {"team": TEAM_PLAYER, "cost": 80, "hp": 140.0, "radius": 26.0, "capacity": 400.0,
		"links": 2, "range": 220.0, "rate": 30.0, "build_radius": 220.0,
		"tracks": [TRACK_CAPACITY, TRACK_RATE, TRACK_RANGE, TRACK_LINKS]},
	EXPORTER: {"team": TEAM_PLAYER, "cost": 120, "hp": 80.0, "radius": 26.0, "capacity": 80.0, "links": 0, "build_radius": 160.0, "export": 8.0,
		"tracks": [TRACK_RATE, TRACK_CAPACITY]},
	ZAPPER: {"team": TEAM_PLAYER, "cost": 70, "hp": 90.0, "radius": 26.0, "capacity": 40.0, "links": 0, "build_radius": 160.0,
		"attack": {"mode": MODE_BOLT, "damage": 26.0, "cooldown": 0.45, "energy": 4.0, "range": 230.0, "ground": true, "air": true},
		"tracks": [TRACK_POWER, TRACK_SPEED, TRACK_RANGE]},
	LASER: {"team": TEAM_PLAYER, "cost": 120, "hp": 110.0, "radius": 26.0, "capacity": 60.0, "links": 0, "build_radius": 160.0,
		"attack": {"mode": MODE_LASER, "damage": 30.0, "cooldown": 0.0, "energy": 10.0, "range": 270.0, "ground": true, "air": true},
		"tracks": [TRACK_POWER, TRACK_RANGE]},
	TESLA: {"team": TEAM_PLAYER, "cost": 160, "hp": 120.0, "radius": 26.0, "capacity": 80.0, "links": 0, "build_radius": 160.0,
		"attack": {"mode": MODE_CHAIN, "damage": 30.0, "cooldown": 1.0, "energy": 14.0, "range": 220.0, "chain": 5, "ground": true, "air": true},
		"tracks": [TRACK_POWER, TRACK_SPEED, TRACK_RANGE]},
	PLASMA: {"team": TEAM_PLAYER, "cost": 200, "hp": 110.0, "radius": 26.0, "capacity": 100.0, "links": 0, "build_radius": 160.0,
		"attack": {"mode": MODE_PLASMA, "damage": 65.0, "cooldown": 2.5, "energy": 28.0, "range": 430.0, "min_range": 90.0, "splash": 85.0, "ground": true, "air": false},
		"tracks": [TRACK_POWER, TRACK_SPEED, TRACK_RANGE]},
	SHIELD: {"team": TEAM_PLAYER, "cost": 140, "hp": 100.0, "radius": 26.0, "capacity": 140.0, "links": 0, "build_radius": 160.0,
		"shield": {"radius": 210.0},
		"tracks": [TRACK_POWER, TRACK_RANGE]},
	HEALER: {"team": TEAM_PLAYER, "cost": 110, "hp": 90.0, "radius": 26.0, "capacity": 80.0, "links": 0, "build_radius": 160.0,
		"heal": {"amount": 20.0, "cooldown": 0.9, "energy": 6.0, "range": 230.0},
		"tracks": [TRACK_POWER, TRACK_SPEED, TRACK_RANGE]},
	BULWARK: {"team": TEAM_PLAYER, "cost": 4, "cost_every": 6, "upgrade_base": 40, "hp": 2000.0, "radius": 27.0, "capacity": 0.0, "links": 0,
		"build_radius": 0.0, "vision": 120.0, "wall": true,
		"tracks": [TRACK_HULL]},
	NEST: {"team": TEAM_ENEMY, "hp": 1200.0, "radius": 52.0, "cells": 2, "bounty": 250, "spawns": true},
	CAMP: {"team": TEAM_ENEMY, "hp": 1500.0, "radius": 52.0, "cells": 2, "bounty": 320, "spawns": true},
	TURRET: {"team": TEAM_ENEMY, "hp": 500.0, "radius": 26.0, "bounty": 140,
		"attack": {"damage": 16.0, "cooldown": 1.2, "range": 215.0}},
}

const CLASS_AIR := "air"
const CLASS_RANGED := "ranged"
const CLASS_MELEE := "melee"
const CLASSES: Array[String] = [CLASS_AIR, CLASS_RANGED, CLASS_MELEE]

const ENEMIES := {
	"crawler": {"class": CLASS_MELEE, "hp": 26.0, "speed": 70.0, "damage": 6.0, "cooldown": 0.8, "reach": 0.0, "radius": 10.0, "bounty": 7},
	"beetle": {"class": CLASS_MELEE, "hp": 180.0, "speed": 40.0, "damage": 18.0, "cooldown": 1.0, "reach": 0.0, "radius": 16.0, "bounty": 22},
	"spitter": {"class": CLASS_RANGED, "hp": 40.0, "speed": 55.0, "damage": 7.0, "cooldown": 1.2, "reach": 110.0, "radius": 12.0, "bounty": 10},
	"wasp": {"class": CLASS_AIR, "hp": 22.0, "speed": 95.0, "damage": 5.0, "cooldown": 0.6, "reach": 0.0, "radius": 9.0, "bounty": 8},
	"behemoth": {"class": CLASS_MELEE, "hp": 900.0, "speed": 26.0, "damage": 80.0, "cooldown": 1.6, "reach": 0.0, "radius": 26.0, "bounty": 150, "boss": true},
	"soldier": {"class": CLASS_RANGED, "hp": 50.0, "speed": 52.0, "damage": 8.0, "cooldown": 1.1, "reach": 120.0, "radius": 11.0, "bounty": 12},
	"drone": {"class": CLASS_AIR, "hp": 36.0, "speed": 85.0, "damage": 7.0, "cooldown": 0.9, "reach": 70.0, "radius": 11.0, "bounty": 11},
	"saboteur": {"class": CLASS_MELEE, "hp": 45.0, "speed": 80.0, "damage": 5.0, "cooldown": 1.5, "reach": 0.0, "radius": 10.0, "bounty": 24, "sabotage": true},
	"tank": {"class": CLASS_RANGED, "hp": 340.0, "speed": 30.0, "damage": 30.0, "cooldown": 2.2, "reach": 210.0, "radius": 22.0, "bounty": 70, "boss": true},
}

const HP_GROWTH := 0.12
const HP_GROWTH_CYCLES := 8
const MAX_CYCLE_COUNT := 45.0
const BOUNTY_GROWTH := 0.15
const SPAWN_CALM := 0.35
const SURGE_PHASE := 0.75
const PACK_BASE := 3
const PACK_EVERY := 2
const PACK_MAX := 10
const PACK_SPREAD := 0.5
const HEAL_RECENT := 2.5
const HEAL_UNDER_FIRE := 0.5
const HEAL_CORE_BONUS := 0.3
const HEAL_JITTER := 0.1
const PICKUP_DELAY := 0.9
const COMBO_WINDOW := 2.2
const COMBO_TIERS: Array[int] = [5, 10, 20, 35, 50, 75, 100]
const CRIT_CHANCE := 0.12
const CRIT_FACTOR := 2.0
const SELL_REFUND := 0.5
const ENEMY_NO_BUILD := 150.0
const RETARGET_TIME := 0.5
const RETARGET_JITTER := 0.25
const PATHS_PER_TICK := 8
const SPAWN_RING := 1.6
const PLASMA_SPEED := 520.0
const CHAIN_JUMP := 140.0
const CHAIN_DECAY := 0.8
const SHIELD_RATIO := 2.0
const LASER_REPORT := 0.3
const TARGET_SCAN := 0.2
const SABOTAGE_REACH := 16.0
const SABOTAGE_CUT := 0.75
const MELEE_GAP := 4.0
const SPREAD := 0.28
const DAWN_RAMP := 20.0
const SKIP_PREP_BONUS := 1
const ENERGY_PER_COIN := 4.0
const EXPORT_BATCH := 5
const STAR_CORE_GOOD := 0.8
const STAR_CORE_OK := 0.4
const STAR_MAX_LOST := 2

const CELL := 56.0
const HIGH_GROUND_BONUS := 0.2
const VISION_DEFAULT := 260.0
const VISION_MARGIN := 40.0
const FOG_INTERVAL := 0.2
const SCOUT_SPEED := 150.0
const SCOUT_VISION := 380.0
const SCOUT_RADIUS := 16.0
const DROP_TIME := 2.6
const CORE_DEPLOY_RANGE := 420.0
const CORE_ENEMY_CLEAR := 900.0
const CLEAR_TIME := {"tree": 1.6, "rock": 3.2}
const CLEAR_REACH := 1.5

const LEVELS := [
	{"id": "dawn", "cells": Vector2i(52, 64), "money": 320, "prep": 75.0, "day": 220.0, "night": 120.0, "seed": 11,
		"drop": Vector2(0.5, 0.84), "structures": [[NEST, Vector2(0.5, 0.1)]],
		"terrain": {"plateaus": 3, "chasms": 1, "forests": 8, "rocks": 9,
			"spots": [[Vector2(0.36, 0.72), 6, [Vector2i(1, 0)]], [Vector2(0.72, 0.62), 5, [Vector2i(0, 1), Vector2i(-1, 0)]]]},
		"spawns": {"cycle": 120.0, "base": 8.0, "growth": 3.0, "night": 1.4, "roster": [["crawler", 0, 1.0], ["spitter", 2, 0.3], ["wasp", 3, 0.3]]},
		"new": [SOLAR, RELAY, BATTERY, EXPORTER, ZAPPER, BULWARK]},
	{"id": "beetle_hill", "cells": Vector2i(56, 70), "money": 360, "prep": 75.0, "day": 210.0, "night": 130.0, "seed": 23,
		"drop": Vector2(0.5, 0.86), "structures": [[NEST, Vector2(0.25, 0.1)], [NEST, Vector2(0.75, 0.18)]],
		"terrain": {"plateaus": 5, "chasms": 1, "forests": 10, "rocks": 10, "spots": [[Vector2(0.5, 0.66), 6, [Vector2i(0, -1), Vector2i(1, 0)]]]},
		"spawns": {"cycle": 120.0, "base": 6.0, "growth": 2.5, "night": 1.4, "roster": [["crawler", 0, 1.0], ["beetle", 1, 0.5], ["spitter", 1, 0.4], ["wasp", 2, 0.3]]},
		"new": [LASER, HEALER]},
	{"id": "swarm_night", "cells": Vector2i(58, 74), "money": 400, "prep": 75.0, "day": 190.0, "night": 160.0, "seed": 37,
		"drop": Vector2(0.5, 0.86), "structures": [[NEST, Vector2(0.2, 0.12)], [NEST, Vector2(0.8, 0.1)]],
		"terrain": {"plateaus": 5, "chasms": 2, "forests": 11, "rocks": 10, "spots": []},
		"spawns": {"cycle": 115.0, "base": 6.0, "growth": 2.8, "night": 1.6, "roster": [["crawler", 0, 1.0], ["wasp", 1, 0.8], ["spitter", 1, 0.4], ["beetle", 1, 0.4]]},
		"new": [SHIELD]},
	{"id": "outpost", "cells": Vector2i(60, 76), "money": 420, "prep": 80.0, "day": 210.0, "night": 130.0, "seed": 41,
		"drop": Vector2(0.5, 0.86), "structures": [[CAMP, Vector2(0.5, 0.08)], [TURRET, Vector2(0.38, 0.2)], [TURRET, Vector2(0.62, 0.2)]],
		"terrain": {"plateaus": 6, "chasms": 2, "forests": 10, "rocks": 12, "spots": []},
		"spawns": {"cycle": 120.0, "base": 9.0, "growth": 4.0, "night": 1.4, "roster": [["soldier", 0, 1.0], ["drone", 1, 0.4]]},
		"new": [TESLA]},
	{"id": "sabotage", "cells": Vector2i(64, 80), "money": 440, "prep": 80.0, "day": 200.0, "night": 140.0, "seed": 53,
		"drop": Vector2(0.5, 0.87), "structures": [[CAMP, Vector2(0.25, 0.08)], [CAMP, Vector2(0.75, 0.12)], [TURRET, Vector2(0.5, 0.22)]],
		"terrain": {"plateaus": 6, "chasms": 3, "forests": 12, "rocks": 12, "spots": []},
		"spawns": {"cycle": 120.0, "base": 6.0, "growth": 2.8, "night": 1.4, "roster": [["soldier", 0, 1.0], ["saboteur", 1, 0.6], ["drone", 1, 0.4]]},
		"new": [PLASMA]},
	{"id": "tank_front", "cells": Vector2i(66, 84), "money": 580, "prep": 85.0, "day": 200.0, "night": 140.0, "seed": 67,
		"drop": Vector2(0.5, 0.88), "structures": [[CAMP, Vector2(0.3, 0.08)], [CAMP, Vector2(0.7, 0.08)], [TURRET, Vector2(0.2, 0.22)], [TURRET, Vector2(0.8, 0.22)], [TURRET, Vector2(0.5, 0.16)]],
		"terrain": {"plateaus": 7, "chasms": 3, "forests": 12, "rocks": 14, "spots": []},
		"spawns": {"cycle": 130.0, "base": 6.0, "growth": 2.2, "night": 1.4, "roster": [["soldier", 0, 1.0], ["saboteur", 1, 0.4], ["drone", 1, 0.4], ["tank", 1, 0.2]]},
		"new": []},
	{"id": "colossus", "cells": Vector2i(70, 88), "money": 620, "prep": 85.0, "day": 190.0, "night": 160.0, "seed": 79,
		"drop": Vector2(0.5, 0.88), "structures": [[NEST, Vector2(0.2, 0.08)], [NEST, Vector2(0.5, 0.14)], [NEST, Vector2(0.8, 0.08)]],
		"terrain": {"plateaus": 7, "chasms": 3, "forests": 14, "rocks": 14, "spots": []},
		"spawns": {"cycle": 125.0, "base": 3.5, "growth": 1.6, "night": 1.5, "roster": [["crawler", 0, 1.0], ["wasp", 0, 0.6], ["spitter", 0, 0.4], ["beetle", 1, 0.4], ["behemoth", 2, 0.08]]},
		"new": []},
	{"id": "final_war", "cells": Vector2i(76, 96), "money": 720, "prep": 90.0, "day": 200.0, "night": 160.0, "seed": 97,
		"drop": Vector2(0.5, 0.9), "structures": [[NEST, Vector2(0.15, 0.08)], [CAMP, Vector2(0.5, 0.06)], [NEST, Vector2(0.85, 0.08)], [TURRET, Vector2(0.3, 0.2)], [TURRET, Vector2(0.7, 0.2)], [CAMP, Vector2(0.5, 0.24)]],
		"terrain": {"plateaus": 8, "chasms": 4, "forests": 16, "rocks": 16, "spots": []},
		"spawns": {"cycle": 125.0, "base": 3.0, "growth": 1.3, "night": 1.5, "roster": [["crawler", 0, 1.0], ["soldier", 0, 0.8], ["wasp", 1, 0.5], ["drone", 1, 0.4], ["spitter", 1, 0.4], ["saboteur", 1, 0.4], ["beetle", 1, 0.5], ["tank", 2, 0.2], ["behemoth", 2, 0.1]]},
		"new": []},
]

const SPAWNER_FACTIONS := {
	NEST: ["crawler", "beetle", "spitter", "wasp", "behemoth"],
	CAMP: ["soldier", "saboteur", "drone", "tank"],
}


static func level_count() -> int:
	return LEVELS.size()


static func level(index: int) -> Dictionary:
	return LEVELS[clampi(index, 0, LEVELS.size() - 1)]


static func available_kinds(index: int) -> Array[String]:
	var result: Array[String] = []
	for i in clampi(index, 0, LEVELS.size() - 1) + 1:
		for kind: String in LEVELS[i].new:
			result.append(kind)
	var ordered: Array[String] = []
	for kind in BUILD_ORDER:
		if result.has(kind):
			ordered.append(kind)
	return ordered


static func building(kind: String) -> Dictionary:
	return BUILDINGS.get(kind, {})


static func enemy(kind: String) -> Dictionary:
	return ENEMIES.get(kind, {})


static func has_attack(kind: String) -> bool:
	return building(kind).has("attack") and building(kind).get("team", TEAM_PLAYER) == TEAM_PLAYER


static func is_tower(kind: String) -> bool:
	return has_attack(kind) and kind != CORE


static func uses_energy_actively(kind: String) -> bool:
	var definition := building(kind)
	return has_attack(kind) or definition.has("heal") or definition.has("shield")


static func cells(kind: String) -> int:
	return int(building(kind).get("cells", 1))


static func is_wall(kind: String) -> bool:
	return bool(building(kind).get("wall", false))
