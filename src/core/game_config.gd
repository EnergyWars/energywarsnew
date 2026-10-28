class_name GameConfig
extends RefCounted

const TICK := 1.0 / 30.0
const MAX_STEPS_PER_FRAME := 12
const SPEEDS: Array[float] = [1.0, 2.0, 3.0]

const EMPTY := {}
const EMPTY_LIST := []

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
const ROVER := "rover"
const NEST := "nest"
const CAMP := "camp"
const TURRET := "turret"

const BUILD_ORDER: Array[String] = [BULWARK, SOLAR, RELAY, BATTERY, EXPORTER, ZAPPER, LASER, HEALER, ROVER, TESLA, PLASMA, SHIELD]
const STARTER_KINDS: Array[String] = [BULWARK, SOLAR, RELAY, BATTERY, EXPORTER, ZAPPER]

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
const TRACK_EFFICIENCY := "efficiency"
const TRACK_CRIT := "crit"
const TRACK_CHAIN := "chain"
const TRACK_SPLASH := "splash"
const TRACK_OVERCLOCK := "overclock"
const TRACK_TRANSFER := "transfer"

const TRACKS := {
	TRACK_RATE: {"max": 25, "step": 0.12, "price": 0.22},
	TRACK_RANGE: {"max": 15, "step": 0.04, "price": 0.3},
	TRACK_LINKS: {"max": 5, "step": 1.0, "price": 0.8, "growth": 1.6},
	TRACK_OUTPUT: {"max": 30, "step": 0.1, "price": 0.25},
	TRACK_CAPACITY: {"max": 25, "step": 0.2, "price": 0.18},
	TRACK_POWER: {"max": 40, "step": 0.1, "price": 0.22},
	TRACK_SPEED: {"max": 25, "step": 0.06, "price": 0.25},
	TRACK_HULL: {"max": 30, "step": 0.15, "price": 0.18},
	TRACK_EFFICIENCY: {"max": 20, "step": 0.05, "price": 0.2},
	TRACK_CRIT: {"max": 20, "step": 0.01, "price": 0.25},
	TRACK_CHAIN: {"max": 5, "step": 1.0, "price": 0.7, "growth": 1.5},
	TRACK_SPLASH: {"max": 15, "step": 0.05, "price": 0.25},
	TRACK_OVERCLOCK: {"max": 12, "step": 0.2, "price": 0.15, "energy": 1.25},
	TRACK_TRANSFER: {"max": 10, "step": 0.15, "price": 0.2},
}
const TRACK_GROWTH := 1.12

const BUILDINGS := {
	CORE: {"team": TEAM_PLAYER, "cost": 0, "upgrade_base": 120, "hp": 1500.0, "radius": 50.0, "cells": 2, "capacity": 300.0, "output": 3.0,
		"links": 3, "range": 280.0, "rate": 40.0, "build_radius": 420.0, "vision": 460.0,
		"attack": {"mode": MODE_BOLT, "damage": 12.0, "cooldown": 0.7, "energy": 3.0, "range": 220.0, "ground": true, "air": true},
		"tracks": [TRACK_RATE, TRACK_RANGE, TRACK_LINKS, TRACK_TRANSFER, TRACK_POWER, TRACK_SPEED, TRACK_OUTPUT, TRACK_CAPACITY, TRACK_HULL]},
	SOLAR: {"team": TEAM_PLAYER, "cost": 40, "hp": 70.0, "radius": 26.0, "capacity": 30.0, "output": 8.0, "solar": true,
		"links": 1, "range": 240.0, "rate_from_output": true, "build_radius": 240.0, "receives": false,
		"tracks": [TRACK_OUTPUT, TRACK_RANGE, TRACK_LINKS, TRACK_TRANSFER, TRACK_CAPACITY, TRACK_HULL]},
	RELAY: {"team": TEAM_PLAYER, "cost": 30, "hp": 90.0, "radius": 24.0, "capacity": 20.0,
		"links": 3, "range": 330.0, "rate": 30.0, "build_radius": 320.0, "vision": 320.0,
		"tracks": [TRACK_RATE, TRACK_RANGE, TRACK_LINKS, TRACK_TRANSFER, TRACK_CAPACITY, TRACK_HULL]},
	BATTERY: {"team": TEAM_PLAYER, "cost": 80, "hp": 140.0, "radius": 26.0, "capacity": 400.0,
		"links": 2, "range": 220.0, "rate": 30.0, "build_radius": 220.0,
		"tracks": [TRACK_CAPACITY, TRACK_RATE, TRACK_RANGE, TRACK_LINKS, TRACK_TRANSFER, TRACK_HULL]},
	EXPORTER: {"team": TEAM_PLAYER, "cost": 120, "hp": 80.0, "radius": 26.0, "capacity": 80.0, "links": 0, "build_radius": 160.0, "export": 8.0,
		"tracks": [TRACK_RATE, TRACK_CAPACITY, TRACK_HULL]},
	ZAPPER: {"team": TEAM_PLAYER, "cost": 70, "hp": 90.0, "radius": 26.0, "capacity": 40.0, "links": 0, "build_radius": 160.0,
		"attack": {"mode": MODE_BOLT, "damage": 26.0, "cooldown": 0.45, "energy": 4.0, "range": 230.0, "ground": true, "air": true},
		"tracks": [TRACK_POWER, TRACK_SPEED, TRACK_OVERCLOCK, TRACK_RANGE, TRACK_CRIT, TRACK_EFFICIENCY, TRACK_CAPACITY, TRACK_HULL]},
	LASER: {"team": TEAM_PLAYER, "cost": 120, "hp": 110.0, "radius": 26.0, "capacity": 60.0, "links": 0, "build_radius": 160.0,
		"attack": {"mode": MODE_LASER, "damage": 30.0, "cooldown": 0.0, "energy": 10.0, "range": 270.0, "ground": true, "air": true},
		"tracks": [TRACK_POWER, TRACK_RANGE, TRACK_EFFICIENCY, TRACK_CAPACITY, TRACK_HULL]},
	TESLA: {"team": TEAM_PLAYER, "cost": 160, "hp": 120.0, "radius": 26.0, "capacity": 80.0, "links": 0, "build_radius": 160.0,
		"attack": {"mode": MODE_CHAIN, "damage": 30.0, "cooldown": 1.0, "energy": 14.0, "range": 220.0, "chain": 5, "ground": true, "air": true},
		"tracks": [TRACK_POWER, TRACK_SPEED, TRACK_OVERCLOCK, TRACK_RANGE, TRACK_CHAIN, TRACK_CRIT, TRACK_EFFICIENCY, TRACK_CAPACITY, TRACK_HULL]},
	PLASMA: {"team": TEAM_PLAYER, "cost": 200, "hp": 110.0, "radius": 26.0, "capacity": 100.0, "links": 0, "build_radius": 160.0,
		"attack": {"mode": MODE_PLASMA, "damage": 65.0, "cooldown": 2.5, "energy": 28.0, "range": 430.0, "min_range": 90.0, "splash": 85.0, "ground": true, "air": false},
		"tracks": [TRACK_POWER, TRACK_SPEED, TRACK_OVERCLOCK, TRACK_RANGE, TRACK_SPLASH, TRACK_CRIT, TRACK_EFFICIENCY, TRACK_CAPACITY, TRACK_HULL]},
	SHIELD: {"team": TEAM_PLAYER, "cost": 140, "hp": 100.0, "radius": 26.0, "capacity": 140.0, "links": 0, "build_radius": 160.0,
		"shield": {"radius": 210.0},
		"tracks": [TRACK_POWER, TRACK_RANGE, TRACK_CAPACITY, TRACK_HULL]},
	HEALER: {"team": TEAM_PLAYER, "cost": 110, "hp": 90.0, "radius": 26.0, "capacity": 80.0, "links": 0, "build_radius": 160.0,
		"heal": {"amount": 20.0, "cooldown": 0.9, "energy": 6.0, "range": 230.0},
		"tracks": [TRACK_POWER, TRACK_SPEED, TRACK_RANGE, TRACK_EFFICIENCY, TRACK_CAPACITY, TRACK_HULL]},
	ROVER: {"team": TEAM_PLAYER, "cost": 150, "hp": 160.0, "radius": 22.0, "capacity": 120.0, "links": 0, "build_radius": 0.0,
		"mobile": {"speed": 85.0, "energy": 0.12},
		"attack": {"mode": MODE_BOLT, "damage": 20.0, "cooldown": 0.5, "energy": 3.0, "range": 210.0, "ground": true, "air": true},
		"tracks": [TRACK_POWER, TRACK_SPEED, TRACK_OVERCLOCK, TRACK_RANGE, TRACK_CRIT, TRACK_EFFICIENCY, TRACK_CAPACITY, TRACK_HULL]},
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
	"behemoth": {"class": CLASS_MELEE, "hp": 900.0, "speed": 26.0, "damage": 80.0, "cooldown": 1.6, "reach": 0.0, "radius": 26.0, "bounty": 150, "boss": true, "nocturnal": true},
	"stalker": {"class": CLASS_MELEE, "hp": 60.0, "speed": 88.0, "damage": 10.0, "cooldown": 0.8, "reach": 0.0, "radius": 13.0, "bounty": 14, "nocturnal": true},
	"nightwing": {"class": CLASS_AIR, "hp": 60.0, "speed": 105.0, "damage": 8.0, "cooldown": 0.7, "reach": 0.0, "radius": 12.0, "bounty": 13, "nocturnal": true},
	"soldier": {"class": CLASS_RANGED, "hp": 50.0, "speed": 52.0, "damage": 8.0, "cooldown": 1.1, "reach": 120.0, "radius": 11.0, "bounty": 12},
	"drone": {"class": CLASS_AIR, "hp": 36.0, "speed": 85.0, "damage": 7.0, "cooldown": 0.9, "reach": 70.0, "radius": 11.0, "bounty": 11},
	"saboteur": {"class": CLASS_MELEE, "hp": 60.0, "speed": 80.0, "damage": 5.0, "cooldown": 1.5, "reach": 0.0, "radius": 10.0, "bounty": 24, "sabotage": true, "nocturnal": true},
	"tank": {"class": CLASS_RANGED, "hp": 340.0, "speed": 30.0, "damage": 30.0, "cooldown": 2.2, "reach": 210.0, "radius": 22.0, "bounty": 70, "boss": true, "nocturnal": true},
	"raider": {"class": CLASS_RANGED, "hp": 85.0, "speed": 58.0, "damage": 12.0, "cooldown": 1.1, "reach": 125.0, "radius": 12.0, "bounty": 16, "nocturnal": true},
	"phantom": {"class": CLASS_AIR, "hp": 60.0, "speed": 92.0, "damage": 10.0, "cooldown": 0.8, "reach": 80.0, "radius": 12.0, "bounty": 15, "nocturnal": true},
}

const ROUND_HP_GROWTH := 1.16
const ROUND_DAMAGE_GROWTH := 0.08
const ROUND_BOUNTY_GROWTH := 0.12
const BURN_MIN := 0.6
const BURN_MAX := 2.4
const WAVE_FIRST := 3.0
const WAVE_TRICKLE := 0.3
const WAVE_MAX := 30
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
const RELOCATE_SHARE := 0.2
const ENEMY_NO_BUILD := 150.0
const ENEMY_PLAN_CLEAR := 650.0
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
const DUSK_RAMP := 12.0
const DAWN_RAMP := 8.0
const ENERGY_PER_COIN := 4.0
const EXPORT_BATCH := 5
const SURVIVAL_TARGETS: Array[int] = [5, 10, 15]
const BEAM_LOSS_PER_CELL := 0.025
const BEAM_LOSS_MAX := 0.6
const GUARDS := {
	NEST: {"kind": "beetle", "hp": 4.0},
	CAMP: {"kind": "soldier", "hp": 12.0},
}
const GUARD_BASE := 2
const GUARD_EVERY := 2
const GUARD_MAX := 5
const GUARD_FIRST := 2.0
const GUARD_TRICKLE := 0.8
const GUARD_RESPAWN := 30.0
const GUARD_RING := 2.4
const GUARD_SPEED := 0.55
const GUARD_STEP := 0.7
const GUARD_PAUSE_MIN := 0.4
const GUARD_PAUSE_MAX := 1.6
const GUARD_BOUNTY := 1.5
const WORLD_WALK_SPEED := 0.32

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
const OBSTACLE_HP := {"tree": 140.0, "rock": 320.0}
const SCOUT_GUN := {"damage": 9.0, "cooldown": 0.55, "range": 250.0}

const LEVELS := [
	{"id": "dawn", "cells": Vector2i(52, 64), "money": 320, "day": 80.0, "night": 60.0, "seed": 11,
		"drop": Vector2(0.5, 0.84), "structures": [[NEST, Vector2(0.5, 0.1)]],
		"terrain": {"plateaus": 3, "chasms": 1, "forests": 8, "rocks": 9,
			"spots": [[Vector2(0.36, 0.72), 6, [Vector2i(1, 0)]], [Vector2(0.72, 0.62), 5, [Vector2i(0, 1), Vector2i(-1, 0)]]]},
		"waves": {"interval": 9.0, "base": 0.8, "ramp": 1.5, "night": 1.2, "growth": 0.35,
			"roster": [["crawler", 0, 1.0], ["spitter", 1, 0.3], ["wasp", 2, 0.3]],
			"night_roster": [["stalker", 0, 1.0], ["nightwing", 1, 0.4]]},
		"world": Vector2(0.5, 0.9), "challenges": [["core", 80], ["survive", 5]]},
	{"id": "beetle_hill", "cells": Vector2i(56, 70), "money": 360, "day": 80.0, "night": 60.0, "seed": 23,
		"drop": Vector2(0.5, 0.86), "structures": [[NEST, Vector2(0.25, 0.1)], [NEST, Vector2(0.75, 0.18)]],
		"terrain": {"plateaus": 5, "chasms": 1, "forests": 10, "rocks": 10, "spots": [[Vector2(0.5, 0.66), 6, [Vector2i(0, -1), Vector2i(1, 0)]]]},
		"waves": {"interval": 9.0, "base": 0.6, "ramp": 1.5, "night": 1.2, "growth": 0.35,
			"roster": [["crawler", 0, 1.0], ["beetle", 1, 0.5], ["spitter", 1, 0.4], ["wasp", 2, 0.3]],
			"night_roster": [["stalker", 0, 1.0], ["nightwing", 0, 0.4], ["behemoth", 3, 0.05]]},
		"world": Vector2(0.24, 0.74), "challenges": [["lost", 3], ["survive", 5]]},
	{"id": "swarm_night", "cells": Vector2i(58, 74), "money": 400, "day": 75.0, "night": 70.0, "seed": 37,
		"drop": Vector2(0.5, 0.86), "structures": [[NEST, Vector2(0.2, 0.12)], [NEST, Vector2(0.8, 0.1)]],
		"terrain": {"plateaus": 5, "chasms": 2, "forests": 11, "rocks": 10, "spots": []},
		"waves": {"interval": 9.0, "base": 0.6, "ramp": 1.5, "night": 1.2, "growth": 0.35,
			"roster": [["crawler", 0, 1.0], ["wasp", 0, 0.6], ["spitter", 1, 0.4]],
			"night_roster": [["nightwing", 0, 1.0], ["stalker", 0, 0.6], ["behemoth", 3, 0.05]]},
		"world": Vector2(0.76, 0.72), "challenges": [["combo", 20], ["survive", 5]]},
	{"id": "outpost", "cells": Vector2i(60, 76), "money": 420, "day": 80.0, "night": 60.0, "seed": 41,
		"drop": Vector2(0.5, 0.86), "structures": [[CAMP, Vector2(0.5, 0.08)], [TURRET, Vector2(0.38, 0.2)], [TURRET, Vector2(0.62, 0.2)]],
		"terrain": {"plateaus": 6, "chasms": 2, "forests": 10, "rocks": 12, "spots": []},
		"waves": {"interval": 9.0, "base": 0.9, "ramp": 1.5, "night": 1.2, "growth": 0.35,
			"roster": [["soldier", 0, 1.0], ["drone", 1, 0.4]],
			"night_roster": [["raider", 0, 1.0], ["phantom", 1, 0.4]]},
		"world": Vector2(0.42, 0.56), "challenges": [["core", 70], ["survive", 6]]},
	{"id": "sabotage", "cells": Vector2i(64, 80), "money": 440, "day": 80.0, "night": 65.0, "seed": 53,
		"drop": Vector2(0.5, 0.87), "structures": [[CAMP, Vector2(0.25, 0.08)], [CAMP, Vector2(0.75, 0.12)], [TURRET, Vector2(0.5, 0.22)]],
		"terrain": {"plateaus": 6, "chasms": 3, "forests": 12, "rocks": 12, "spots": []},
		"waves": {"interval": 9.0, "base": 0.6, "ramp": 1.5, "night": 1.2, "growth": 0.35,
			"roster": [["soldier", 0, 1.0], ["drone", 1, 0.4]],
			"night_roster": [["raider", 0, 1.0], ["saboteur", 0, 0.8], ["phantom", 1, 0.4]]},
		"world": Vector2(0.8, 0.47), "challenges": [["lost", 4], ["survive", 6]]},
	{"id": "tank_front", "cells": Vector2i(66, 84), "money": 580, "day": 85.0, "night": 65.0, "seed": 67,
		"drop": Vector2(0.5, 0.88), "structures": [[CAMP, Vector2(0.3, 0.08)], [CAMP, Vector2(0.7, 0.08)], [TURRET, Vector2(0.2, 0.22)], [TURRET, Vector2(0.8, 0.22)], [TURRET, Vector2(0.5, 0.16)]],
		"terrain": {"plateaus": 7, "chasms": 3, "forests": 12, "rocks": 14, "spots": []},
		"waves": {"interval": 9.0, "base": 0.6, "ramp": 1.5, "night": 1.2, "growth": 0.35,
			"roster": [["soldier", 0, 1.0], ["drone", 0, 0.4]],
			"night_roster": [["raider", 0, 1.0], ["saboteur", 1, 0.4], ["phantom", 1, 0.4], ["tank", 1, 0.2]]},
		"world": Vector2(0.28, 0.36), "challenges": [["days", 8], ["survive", 7]]},
	{"id": "colossus", "cells": Vector2i(70, 88), "money": 620, "day": 85.0, "night": 70.0, "seed": 79,
		"drop": Vector2(0.5, 0.88), "structures": [[NEST, Vector2(0.2, 0.08)], [NEST, Vector2(0.5, 0.14)], [NEST, Vector2(0.8, 0.08)]],
		"terrain": {"plateaus": 7, "chasms": 3, "forests": 14, "rocks": 14, "spots": []},
		"waves": {"interval": 9.0, "base": 0.35, "ramp": 1.5, "night": 1.2, "growth": 0.35,
			"roster": [["crawler", 0, 1.0], ["wasp", 0, 0.6], ["spitter", 0, 0.4], ["beetle", 1, 0.4]],
			"night_roster": [["stalker", 0, 1.0], ["nightwing", 0, 0.5], ["behemoth", 1, 0.1]]},
		"world": Vector2(0.72, 0.25), "challenges": [["combo", 35], ["survive", 7]]},
	{"id": "final_war", "cells": Vector2i(76, 96), "money": 720, "day": 90.0, "night": 75.0, "seed": 97,
		"drop": Vector2(0.5, 0.9), "structures": [[NEST, Vector2(0.15, 0.08)], [CAMP, Vector2(0.5, 0.06)], [NEST, Vector2(0.85, 0.08)], [TURRET, Vector2(0.3, 0.2)], [TURRET, Vector2(0.7, 0.2)], [CAMP, Vector2(0.5, 0.24)]],
		"terrain": {"plateaus": 8, "chasms": 4, "forests": 16, "rocks": 16, "spots": []},
		"waves": {"interval": 9.0, "base": 0.3, "ramp": 1.5, "night": 1.2, "growth": 0.35,
			"roster": [["crawler", 0, 1.0], ["soldier", 0, 0.8], ["wasp", 1, 0.5], ["drone", 1, 0.4], ["spitter", 1, 0.4], ["beetle", 1, 0.5]],
			"night_roster": [["stalker", 0, 1.0], ["raider", 0, 0.8], ["nightwing", 1, 0.4], ["phantom", 1, 0.4], ["saboteur", 1, 0.4], ["tank", 2, 0.2], ["behemoth", 2, 0.1]]},
		"world": Vector2(0.48, 0.1), "challenges": [["core", 60], ["survive", 8]]},
]

const WORLD_ROUTES: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(2, 4), Vector2i(3, 5), Vector2i(4, 5), Vector2i(4, 6), Vector2i(5, 7), Vector2i(6, 7)]

const BRANCH_OFFENSE := "offense"
const BRANCH_DEFENSE := "defense"
const BRANCH_ECONOMY := "economy"
const BRANCHES: Array[String] = [BRANCH_OFFENSE, BRANCH_DEFENSE, BRANCH_ECONOMY]
const ALL_TOWERS := "towers"
const ALL_BUILDINGS := "all"

const BOOST_DAMAGE := "damage"
const BOOST_HP := "hp"
const BOOST_RANGE := "range"
const BOOST_OUTPUT := "output"
const BOOST_CAPACITY := "capacity"
const BOOST_EXPORT := "export"
const BOOST_HEAL := "heal"
const BOOST_CHAIN := "chain"
const BOOST_SPLASH := "splash"
const BOOST_TRANSFER := "transfer"

const TECHS := {
	"zapper_power": {"branch": BRANCH_OFFENSE, "cost": 1, "requires": [], "kind": ZAPPER, "boost": BOOST_DAMAGE, "value": 0.2},
	"laser": {"branch": BRANCH_OFFENSE, "cost": 2, "requires": [], "unlock": LASER},
	"rover": {"branch": BRANCH_OFFENSE, "cost": 2, "requires": ["zapper_power"], "unlock": ROVER},
	"tesla": {"branch": BRANCH_OFFENSE, "cost": 3, "requires": ["zapper_power"], "unlock": TESLA},
	"plasma": {"branch": BRANCH_OFFENSE, "cost": 3, "requires": ["laser"], "unlock": PLASMA},
	"laser_focus": {"branch": BRANCH_OFFENSE, "cost": 2, "requires": ["laser"], "kind": LASER, "boost": BOOST_DAMAGE, "value": 0.2},
	"tesla_arc": {"branch": BRANCH_OFFENSE, "cost": 2, "requires": ["tesla"], "kind": TESLA, "boost": BOOST_CHAIN, "value": 0.2},
	"plasma_blast": {"branch": BRANCH_OFFENSE, "cost": 2, "requires": ["plasma"], "kind": PLASMA, "boost": BOOST_SPLASH, "value": 0.25},
	"weapons_1": {"branch": BRANCH_OFFENSE, "cost": 2, "requires": ["laser"], "kind": ALL_TOWERS, "boost": BOOST_DAMAGE, "value": 0.1},
	"weapons_2": {"branch": BRANCH_OFFENSE, "cost": 3, "requires": ["weapons_1"], "kind": ALL_TOWERS, "boost": BOOST_DAMAGE, "value": 0.1},
	"optics": {"branch": BRANCH_OFFENSE, "cost": 2, "requires": ["weapons_1"], "kind": ALL_TOWERS, "boost": BOOST_RANGE, "value": 0.08},
	"bulwark_hull": {"branch": BRANCH_DEFENSE, "cost": 1, "requires": [], "kind": BULWARK, "boost": BOOST_HP, "value": 0.25},
	"healer": {"branch": BRANCH_DEFENSE, "cost": 2, "requires": [], "unlock": HEALER},
	"healer_power": {"branch": BRANCH_DEFENSE, "cost": 2, "requires": ["healer"], "kind": HEALER, "boost": BOOST_HEAL, "value": 0.25},
	"shield": {"branch": BRANCH_DEFENSE, "cost": 3, "requires": ["healer"], "unlock": SHIELD},
	"plating_1": {"branch": BRANCH_DEFENSE, "cost": 2, "requires": ["bulwark_hull"], "kind": ALL_BUILDINGS, "boost": BOOST_HP, "value": 0.15},
	"plating_2": {"branch": BRANCH_DEFENSE, "cost": 3, "requires": ["plating_1"], "kind": ALL_BUILDINGS, "boost": BOOST_HP, "value": 0.15},
	"solar_output": {"branch": BRANCH_ECONOMY, "cost": 1, "requires": [], "kind": SOLAR, "boost": BOOST_OUTPUT, "value": 0.15},
	"solar_output_2": {"branch": BRANCH_ECONOMY, "cost": 2, "requires": ["solar_output"], "kind": SOLAR, "boost": BOOST_OUTPUT, "value": 0.15},
	"battery_capacity": {"branch": BRANCH_ECONOMY, "cost": 1, "requires": [], "kind": BATTERY, "boost": BOOST_CAPACITY, "value": 0.3},
	"exporter_rate": {"branch": BRANCH_ECONOMY, "cost": 2, "requires": ["battery_capacity"], "kind": EXPORTER, "boost": BOOST_EXPORT, "value": 0.25},
	"superconductor": {"branch": BRANCH_ECONOMY, "cost": 2, "requires": ["solar_output"], "kind": ALL_BUILDINGS, "boost": BOOST_TRANSFER, "value": 0.25},
	"funding_1": {"branch": BRANCH_ECONOMY, "cost": 1, "requires": [], "money": 60},
	"funding_2": {"branch": BRANCH_ECONOMY, "cost": 2, "requires": ["funding_1"], "money": 120},
}

const SPAWNER_FACTIONS := {
	NEST: ["crawler", "beetle", "spitter", "wasp", "stalker", "nightwing", "behemoth"],
	CAMP: ["soldier", "drone", "raider", "phantom", "saboteur", "tank"],
}


static func level_count() -> int:
	return LEVELS.size()


static func level(index: int) -> Dictionary:
	return LEVELS[clampi(index, 0, LEVELS.size() - 1)]


static func level_index(id: String) -> int:
	for i in LEVELS.size():
		if LEVELS[i].id == id:
			return i
	return -1


static func tech(id: String) -> Dictionary:
	return TECHS.get(id, EMPTY)


static func building(kind: String) -> Dictionary:
	return BUILDINGS.get(kind, EMPTY)


static func enemy(kind: String) -> Dictionary:
	return ENEMIES.get(kind, EMPTY)


static func has_attack(kind: String) -> bool:
	var definition := building(kind)
	return definition.has("attack") and int(definition.get("team", TEAM_PLAYER)) == TEAM_PLAYER


static func is_tower(kind: String) -> bool:
	return has_attack(kind) and kind != CORE


static func uses_energy_actively(kind: String) -> bool:
	var definition := building(kind)
	return has_attack(kind) or definition.has("heal") or definition.has("shield")


static func cells(kind: String) -> int:
	return int(building(kind).get("cells", 1))


static func is_mobile(kind: String) -> bool:
	return building(kind).has("mobile")


static func is_wall(kind: String) -> bool:
	return bool(building(kind).get("wall", false))


static func is_nocturnal(kind: String) -> bool:
	return bool(enemy(kind).get("nocturnal", false))


static func guard(spawner_kind: String) -> Dictionary:
	return GUARDS.get(spawner_kind, EMPTY)
