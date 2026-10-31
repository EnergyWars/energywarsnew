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
const BASTION := "bastion"
const WATER := "water"
const FIRE := "fire"
const LAMP := "lamp"
const ROVER := "rover"
const NEST := "nest"
const CAMP := "camp"
const TURRET := "turret"

const BUILD_ORDER: Array[String] = [BULWARK, SOLAR, WATER, FIRE, RELAY, BATTERY, EXPORTER, LAMP, ZAPPER, LASER, HEALER, BASTION, ROVER, TESLA, PLASMA, SHIELD]
const STARTER_KINDS: Array[String] = [BULWARK, SOLAR, RELAY, BATTERY, EXPORTER, LAMP, ZAPPER]

const BUILD_CATEGORIES := [
	{"key": "energy", "kinds": [SOLAR, WATER, FIRE, RELAY, BATTERY, EXPORTER]},
	{"key": "towers", "kinds": [ZAPPER, LASER, TESLA, PLASMA]},
	{"key": "defense", "kinds": [BULWARK, BASTION, SHIELD, HEALER]},
	{"key": "utility", "kinds": [LAMP, ROVER]},
]

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
const TRACK_ARMOR := "armor"
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
	TRACK_ARMOR: {"max": 20, "step": 0.15, "price": 0.15},
	TRACK_EFFICIENCY: {"max": 20, "step": 0.05, "price": 0.2},
	TRACK_CRIT: {"max": 20, "step": 0.01, "price": 0.25},
	TRACK_CHAIN: {"max": 5, "step": 1.0, "price": 0.7, "growth": 1.5},
	TRACK_SPLASH: {"max": 15, "step": 0.05, "price": 0.25},
	TRACK_OVERCLOCK: {"max": 12, "step": 0.2, "price": 0.15, "energy": 1.25},
	TRACK_TRANSFER: {"max": 10, "step": 0.1, "price": 0.2},
}
const TRACK_GROWTH := 1.18
const WALL_HULL := {"max": 8, "gain": 2.0, "gain_growth": 1.85, "price": 0.125, "growth": 1.75}

const BUILDINGS := {
	CORE: {"team": TEAM_PLAYER, "armor": 0.0, "cost": 0, "upgrade_base": 120, "hp": 1500.0, "radius": 50.0, "cells": 2, "capacity": 300.0, "output": 3.0,
		"links": 3, "range": 280.0, "rate": 40.0, "build_radius": 420.0, "vision": 460.0,
		"attack": {"mode": MODE_BOLT, "damage": 12.0, "cooldown": 0.7, "energy": 3.0, "range": 220.0, "ground": true, "air": true},
		"tracks": [TRACK_RATE, TRACK_RANGE, TRACK_LINKS, TRACK_TRANSFER, TRACK_POWER, TRACK_SPEED, TRACK_OUTPUT, TRACK_CAPACITY, TRACK_HULL, TRACK_ARMOR]},
	SOLAR: {"team": TEAM_PLAYER, "armor": 0.0, "cost": 40, "hp": 70.0, "radius": 26.0, "capacity": 30.0, "output": 8.0, "solar": true,
		"links": 1, "range": 240.0, "rate_from_output": true, "build_radius": 240.0, "receives": false,
		"tracks": [TRACK_OUTPUT, TRACK_RANGE, TRACK_LINKS, TRACK_TRANSFER, TRACK_CAPACITY, TRACK_HULL, TRACK_ARMOR]},
	WATER: {"team": TEAM_PLAYER, "armor": 0.0, "cost": 50, "hp": 90.0, "radius": 26.0, "capacity": 30.0, "output": 3.0, "water_only": true,
		"links": 1, "range": 240.0, "rate_from_output": true, "build_radius": 240.0, "receives": false,
		"tracks": [TRACK_OUTPUT, TRACK_RANGE, TRACK_LINKS, TRACK_TRANSFER, TRACK_CAPACITY, TRACK_HULL, TRACK_ARMOR]},
	FIRE: {"team": TEAM_PLAYER, "armor": 0.0, "cost": 15, "hp": 60.0, "radius": 24.0, "capacity": 40.0, "output": 30.0, "fuel": true,
		"links": 1, "range": 240.0, "rate_from_output": true, "build_radius": 200.0, "receives": false,
		"tracks": [TRACK_OUTPUT, TRACK_RANGE, TRACK_LINKS, TRACK_TRANSFER, TRACK_CAPACITY, TRACK_HULL, TRACK_ARMOR]},
	LAMP: {"team": TEAM_PLAYER, "armor": 0.0, "cost": 25, "hp": 60.0, "radius": 20.0, "capacity": 40.0, "links": 0, "build_radius": 160.0, "light": true,
		"tracks": [TRACK_EFFICIENCY, TRACK_CAPACITY, TRACK_TRANSFER, TRACK_HULL, TRACK_ARMOR]},
	RELAY: {"team": TEAM_PLAYER, "armor": 0.0, "cost": 30, "hp": 90.0, "radius": 24.0, "capacity": 20.0,
		"links": 3, "range": 330.0, "rate": 30.0, "build_radius": 320.0, "vision": 320.0,
		"tracks": [TRACK_RATE, TRACK_RANGE, TRACK_LINKS, TRACK_TRANSFER, TRACK_CAPACITY, TRACK_HULL, TRACK_ARMOR]},
	BATTERY: {"team": TEAM_PLAYER, "armor": 0.0, "cost": 80, "hp": 140.0, "radius": 26.0, "capacity": 400.0,
		"links": 2, "range": 220.0, "rate": 30.0, "build_radius": 220.0,
		"tracks": [TRACK_CAPACITY, TRACK_RATE, TRACK_RANGE, TRACK_LINKS, TRACK_TRANSFER, TRACK_HULL, TRACK_ARMOR]},
	EXPORTER: {"team": TEAM_PLAYER, "armor": 0.0, "cost": 120, "hp": 80.0, "radius": 26.0, "capacity": 80.0, "links": 0, "build_radius": 160.0, "export": 8.0,
		"tracks": [TRACK_RATE, TRACK_CAPACITY, TRACK_TRANSFER, TRACK_HULL, TRACK_ARMOR]},
	ZAPPER: {"team": TEAM_PLAYER, "armor": 0.0, "cost": 70, "hp": 90.0, "radius": 26.0, "capacity": 40.0, "links": 0, "build_radius": 160.0,
		"attack": {"mode": MODE_BOLT, "damage": 26.0, "cooldown": 0.45, "energy": 4.0, "range": 230.0, "ground": true, "air": true},
		"tracks": [TRACK_POWER, TRACK_SPEED, TRACK_OVERCLOCK, TRACK_RANGE, TRACK_CRIT, TRACK_EFFICIENCY, TRACK_CAPACITY, TRACK_TRANSFER, TRACK_HULL, TRACK_ARMOR]},
	LASER: {"team": TEAM_PLAYER, "armor": 0.0, "cost": 120, "hp": 110.0, "radius": 26.0, "capacity": 60.0, "links": 0, "build_radius": 160.0,
		"attack": {"mode": MODE_LASER, "damage": 30.0, "cooldown": 0.0, "energy": 10.0, "range": 270.0, "ground": true, "air": true},
		"tracks": [TRACK_POWER, TRACK_RANGE, TRACK_EFFICIENCY, TRACK_CAPACITY, TRACK_TRANSFER, TRACK_HULL, TRACK_ARMOR]},
	TESLA: {"team": TEAM_PLAYER, "armor": 0.0, "cost": 160, "hp": 120.0, "radius": 26.0, "capacity": 80.0, "links": 0, "build_radius": 160.0,
		"attack": {"mode": MODE_CHAIN, "damage": 30.0, "cooldown": 1.0, "energy": 14.0, "range": 220.0, "chain": 5, "ground": true, "air": true},
		"tracks": [TRACK_POWER, TRACK_SPEED, TRACK_OVERCLOCK, TRACK_RANGE, TRACK_CHAIN, TRACK_CRIT, TRACK_EFFICIENCY, TRACK_CAPACITY, TRACK_TRANSFER, TRACK_HULL, TRACK_ARMOR]},
	PLASMA: {"team": TEAM_PLAYER, "armor": 0.0, "cost": 200, "hp": 110.0, "radius": 26.0, "capacity": 100.0, "links": 0, "build_radius": 160.0,
		"attack": {"mode": MODE_PLASMA, "damage": 65.0, "cooldown": 2.5, "energy": 28.0, "range": 430.0, "min_range": 90.0, "splash": 85.0, "ground": true, "air": false},
		"tracks": [TRACK_POWER, TRACK_SPEED, TRACK_OVERCLOCK, TRACK_RANGE, TRACK_SPLASH, TRACK_CRIT, TRACK_EFFICIENCY, TRACK_CAPACITY, TRACK_TRANSFER, TRACK_HULL, TRACK_ARMOR]},
	SHIELD: {"team": TEAM_PLAYER, "armor": 0.0, "cost": 140, "hp": 100.0, "radius": 26.0, "capacity": 140.0, "links": 0, "build_radius": 160.0,
		"shield": {"radius": 210.0},
		"tracks": [TRACK_POWER, TRACK_RANGE, TRACK_CAPACITY, TRACK_TRANSFER, TRACK_HULL, TRACK_ARMOR]},
	HEALER: {"team": TEAM_PLAYER, "armor": 0.0, "cost": 110, "hp": 90.0, "radius": 26.0, "capacity": 80.0, "links": 0, "build_radius": 160.0,
		"heal": {"amount": 20.0, "cooldown": 0.9, "energy": 6.0, "range": 230.0},
		"tracks": [TRACK_POWER, TRACK_SPEED, TRACK_RANGE, TRACK_EFFICIENCY, TRACK_CAPACITY, TRACK_TRANSFER, TRACK_HULL, TRACK_ARMOR]},
	ROVER: {"team": TEAM_PLAYER, "armor": 0.0, "cost": 150, "hp": 160.0, "radius": 22.0, "capacity": 120.0, "links": 0, "build_radius": 0.0,
		"mobile": {"speed": 85.0, "energy": 0.12},
		"attack": {"mode": MODE_BOLT, "damage": 20.0, "cooldown": 0.5, "energy": 3.0, "range": 210.0, "ground": true, "air": true},
		"tracks": [TRACK_POWER, TRACK_SPEED, TRACK_OVERCLOCK, TRACK_RANGE, TRACK_CRIT, TRACK_EFFICIENCY, TRACK_CAPACITY, TRACK_TRANSFER, TRACK_HULL, TRACK_ARMOR]},
	BASTION: {"team": TEAM_PLAYER, "armor": 0.0, "cost": 130, "hp": 900.0, "radius": 28.0, "capacity": 60.0, "links": 0, "build_radius": 160.0, "lure": true,
		"attack": {"mode": MODE_BOLT, "damage": 14.0, "cooldown": 0.5, "energy": 3.0, "range": 240.0, "ground": false, "air": true},
		"tracks": [TRACK_POWER, TRACK_SPEED, TRACK_RANGE, TRACK_CRIT, TRACK_EFFICIENCY, TRACK_CAPACITY, TRACK_TRANSFER, TRACK_HULL, TRACK_ARMOR]},
	BULWARK: {"team": TEAM_PLAYER, "armor": 3.0, "cost": 4, "cost_every": 6, "upgrade_base": 40, "hp": 1600.0, "radius": 27.0, "capacity": 12.0, "links": 0,
		"build_radius": 0.0, "vision": 120.0, "wall": true, "repair": {"rate": 5.0, "energy": 0.4},
		"tracks": [TRACK_HULL, TRACK_ARMOR], "curves": {TRACK_HULL: WALL_HULL}},
	NEST: {"team": TEAM_ENEMY, "armor": 30.0, "hp": 1200.0, "radius": 52.0, "cells": 2, "bounty": 250, "spawns": true},
	CAMP: {"team": TEAM_ENEMY, "armor": 30.0, "hp": 1500.0, "radius": 52.0, "cells": 2, "bounty": 320, "spawns": true},
	TURRET: {"team": TEAM_ENEMY, "armor": 15.0, "hp": 500.0, "radius": 26.0, "bounty": 140,
		"attack": {"damage": 16.0, "cooldown": 1.2, "range": 215.0}},
}

const CLASS_AIR := "air"
const CLASS_RANGED := "ranged"
const CLASS_MELEE := "melee"
const CLASSES: Array[String] = [CLASS_AIR, CLASS_RANGED, CLASS_MELEE]

const BUFFS_SWARM := {
	"night": {"hp": 0.1, "damage": 0.1, "speed": 0.05, "armor": 0.0},
	"level": {"hp": 0.05, "damage": 0.04, "speed": 0.01, "armor": 0.0},
}
const BUFFS_STANDARD := {
	"night": {"hp": 0.15, "damage": 0.12, "speed": 0.05, "armor": 0.1},
	"level": {"hp": 0.06, "damage": 0.05, "speed": 0.01, "armor": 0.04},
}
const BUFFS_HEAVY := {
	"night": {"hp": 0.2, "damage": 0.15, "speed": 0.03, "armor": 0.12},
	"level": {"hp": 0.08, "damage": 0.06, "speed": 0.0, "armor": 0.05},
}
const BUFFS_BOSS := {
	"night": {"hp": 0.25, "damage": 0.2, "speed": 0.02, "armor": 0.15},
	"level": {"hp": 0.1, "damage": 0.08, "speed": 0.0, "armor": 0.06},
}

const ENEMIES := {
	"crawler": {"class": CLASS_MELEE, "faction": NEST, "look": "crawler", "armor": 0.0, "hp": 42.0, "speed": 70.0, "damage": 6.0, "cooldown": 0.8, "reach": 0.0, "radius": 10.0, "bounty": 5, "buffs": BUFFS_SWARM},
	"larva": {"class": CLASS_MELEE, "faction": NEST, "look": "larva", "armor": 0.0, "hp": 24.0, "speed": 90.0, "damage": 3.0, "cooldown": 0.6, "reach": 0.0, "radius": 7.0, "bounty": 3, "buffs": BUFFS_SWARM},
	"mauler": {"class": CLASS_MELEE, "faction": NEST, "look": "mauler", "armor": 2.0, "hp": 90.0, "speed": 62.0, "damage": 14.0, "cooldown": 0.9, "reach": 0.0, "radius": 14.0, "bounty": 9, "buffs": BUFFS_STANDARD},
	"beetle": {"class": CLASS_MELEE, "faction": NEST, "look": "beetle", "armor": 12.0, "hp": 290.0, "speed": 40.0, "damage": 18.0, "cooldown": 1.0, "reach": 0.0, "radius": 16.0, "bounty": 15, "buffs": BUFFS_HEAVY},
	"stalker": {"class": CLASS_MELEE, "faction": NEST, "look": "stalker", "armor": 4.0, "hp": 96.0, "speed": 88.0, "damage": 10.0, "cooldown": 0.8, "reach": 0.0, "radius": 13.0, "bounty": 10, "nocturnal": true, "buffs": BUFFS_STANDARD},
	"ravager": {"class": CLASS_MELEE, "faction": NEST, "look": "ravager", "armor": 6.0, "hp": 180.0, "speed": 76.0, "damage": 22.0, "cooldown": 0.8, "reach": 0.0, "radius": 15.0, "bounty": 16, "nocturnal": true, "buffs": BUFFS_STANDARD},
	"spitter": {"class": CLASS_RANGED, "faction": NEST, "look": "spitter", "armor": 0.0, "hp": 64.0, "speed": 55.0, "damage": 7.0, "cooldown": 1.2, "reach": 110.0, "radius": 12.0, "bounty": 7, "buffs": BUFFS_STANDARD},
	"slinger": {"class": CLASS_RANGED, "faction": NEST, "look": "slinger", "armor": 2.0, "hp": 70.0, "speed": 50.0, "damage": 9.0, "cooldown": 1.4, "reach": 140.0, "radius": 12.0, "bounty": 8, "buffs": BUFFS_STANDARD},
	"wasp": {"class": CLASS_AIR, "faction": NEST, "look": "wasp", "armor": 0.0, "hp": 36.0, "speed": 95.0, "damage": 5.0, "cooldown": 0.6, "reach": 0.0, "radius": 9.0, "bounty": 6, "buffs": BUFFS_SWARM},
	"gnat": {"class": CLASS_AIR, "faction": NEST, "look": "gnat", "armor": 0.0, "hp": 20.0, "speed": 125.0, "damage": 2.0, "cooldown": 0.5, "reach": 0.0, "radius": 7.0, "bounty": 3, "buffs": BUFFS_SWARM},
	"nightwing": {"class": CLASS_AIR, "faction": NEST, "look": "nightwing", "armor": 2.0, "hp": 96.0, "speed": 105.0, "damage": 8.0, "cooldown": 0.7, "reach": 0.0, "radius": 12.0, "bounty": 9, "nocturnal": true, "buffs": BUFFS_STANDARD},
	"behemoth": {"class": CLASS_MELEE, "faction": NEST, "look": "behemoth", "armor": 60.0, "hp": 1440.0, "speed": 26.0, "damage": 80.0, "cooldown": 1.6, "reach": 0.0, "radius": 26.0, "bounty": 105, "boss": true, "nocturnal": true, "buffs": BUFFS_BOSS},
	"juggernaut": {"class": CLASS_MELEE, "faction": NEST, "look": "juggernaut", "armor": 40.0, "hp": 1900.0, "speed": 34.0, "damage": 70.0, "cooldown": 1.2, "reach": 0.0, "radius": 26.0, "bounty": 130, "boss": true, "nocturnal": true, "buffs": BUFFS_BOSS},
	"broodmother": {"class": CLASS_RANGED, "faction": NEST, "look": "broodmother", "armor": 25.0, "hp": 900.0, "speed": 28.0, "damage": 24.0, "cooldown": 1.6, "reach": 220.0, "radius": 24.0, "bounty": 100, "boss": true, "nocturnal": true, "buffs": BUFFS_BOSS},
	"dreadwing": {"class": CLASS_AIR, "faction": NEST, "look": "dreadwing", "armor": 15.0, "hp": 800.0, "speed": 70.0, "damage": 40.0, "cooldown": 1.0, "reach": 0.0, "radius": 22.0, "bounty": 110, "boss": true, "nocturnal": true, "buffs": BUFFS_BOSS},
	"soldier": {"class": CLASS_RANGED, "faction": CAMP, "look": "soldier", "armor": 6.0, "hp": 80.0, "speed": 52.0, "damage": 8.0, "cooldown": 1.1, "reach": 120.0, "radius": 11.0, "bounty": 8, "buffs": BUFFS_STANDARD},
	"raider": {"class": CLASS_RANGED, "faction": CAMP, "look": "raider", "armor": 10.0, "hp": 136.0, "speed": 58.0, "damage": 12.0, "cooldown": 1.1, "reach": 125.0, "radius": 12.0, "bounty": 11, "nocturnal": true, "buffs": BUFFS_STANDARD},
	"sniper": {"class": CLASS_RANGED, "faction": CAMP, "look": "sniper", "armor": 4.0, "hp": 100.0, "speed": 40.0, "damage": 26.0, "cooldown": 2.2, "reach": 230.0, "radius": 12.0, "bounty": 14, "nocturnal": true, "buffs": BUFFS_STANDARD},
	"sprinter": {"class": CLASS_MELEE, "faction": CAMP, "look": "sprinter", "armor": 0.0, "hp": 50.0, "speed": 120.0, "damage": 6.0, "cooldown": 0.5, "reach": 0.0, "radius": 9.0, "bounty": 6, "buffs": BUFFS_SWARM},
	"saboteur": {"class": CLASS_MELEE, "faction": CAMP, "look": "saboteur", "armor": 4.0, "hp": 96.0, "speed": 80.0, "damage": 5.0, "cooldown": 1.5, "reach": 0.0, "radius": 10.0, "bounty": 17, "sabotage": true, "nocturnal": true, "buffs": BUFFS_STANDARD},
	"breacher": {"class": CLASS_MELEE, "faction": CAMP, "look": "breacher", "armor": 8.0, "hp": 220.0, "speed": 56.0, "damage": 60.0, "cooldown": 2.0, "reach": 0.0, "radius": 14.0, "bounty": 20, "nocturnal": true, "buffs": BUFFS_STANDARD},
	"brute": {"class": CLASS_MELEE, "faction": CAMP, "look": "brute", "armor": 30.0, "hp": 420.0, "speed": 34.0, "damage": 40.0, "cooldown": 1.4, "reach": 0.0, "radius": 19.0, "bounty": 24, "nocturnal": true, "buffs": BUFFS_HEAVY},
	"drone": {"class": CLASS_AIR, "faction": CAMP, "look": "drone", "armor": 2.0, "hp": 58.0, "speed": 85.0, "damage": 7.0, "cooldown": 0.9, "reach": 70.0, "radius": 11.0, "bounty": 8, "buffs": BUFFS_STANDARD},
	"phantom": {"class": CLASS_AIR, "faction": CAMP, "look": "phantom", "armor": 4.0, "hp": 96.0, "speed": 92.0, "damage": 10.0, "cooldown": 0.8, "reach": 80.0, "radius": 12.0, "bounty": 10, "nocturnal": true, "buffs": BUFFS_STANDARD},
	"tank": {"class": CLASS_RANGED, "faction": CAMP, "look": "tank", "armor": 70.0, "hp": 540.0, "speed": 30.0, "damage": 30.0, "cooldown": 2.2, "reach": 210.0, "radius": 22.0, "bounty": 50, "boss": true, "nocturnal": true, "buffs": BUFFS_BOSS},
	"artillery": {"class": CLASS_RANGED, "faction": CAMP, "look": "artillery", "armor": 50.0, "hp": 700.0, "speed": 22.0, "damage": 70.0, "cooldown": 3.0, "reach": 320.0, "radius": 22.0, "bounty": 90, "boss": true, "nocturnal": true, "buffs": BUFFS_BOSS},
	"warlord": {"class": CLASS_RANGED, "faction": CAMP, "look": "warlord", "armor": 45.0, "hp": 1200.0, "speed": 36.0, "damage": 36.0, "cooldown": 1.4, "reach": 240.0, "radius": 22.0, "bounty": 110, "boss": true, "nocturnal": true, "buffs": BUFFS_BOSS},
	"colossus": {"class": CLASS_MELEE, "faction": CAMP, "look": "colossus", "armor": 90.0, "hp": 2600.0, "speed": 22.0, "damage": 120.0, "cooldown": 2.0, "reach": 0.0, "radius": 30.0, "bounty": 160, "boss": true, "nocturnal": true, "buffs": BUFFS_BOSS},
	"reaper": {"class": CLASS_MELEE, "faction": CAMP, "look": "reaper", "armor": 20.0, "hp": 1100.0, "speed": 70.0, "damage": 90.0, "cooldown": 1.0, "reach": 0.0, "radius": 22.0, "bounty": 120, "boss": true, "nocturnal": true, "buffs": BUFFS_BOSS},
	"gunship": {"class": CLASS_AIR, "faction": CAMP, "look": "gunship", "armor": 35.0, "hp": 1000.0, "speed": 50.0, "damage": 30.0, "cooldown": 1.0, "reach": 150.0, "radius": 24.0, "bounty": 120, "boss": true, "nocturnal": true, "buffs": BUFFS_BOSS},
}

const ARMOR_UNIT := 10.0
const ARMOR := {"constant": 100.0, "max_reduction": 0.9, "min_damage": 1.0}
const ROUND_HP_GROWTH := 1.22
const ROUND_DAMAGE_GROWTH := 0.08
const ROUND_BOUNTY_GROWTH := 0.12
const BURN_MIN := 0.6
const BURN_MAX := 2.4
const WAVE_FIRST := 3.0
const WAVE_TRICKLE := 0.3
const WAVE_MAX := 30
const GROUND_WAVE_BONUS := 1.35
const GROUND_DAMAGE_BONUS := 1.3
const AIR_RAID_FIRST_ROUND := 4
const AIR_RAID_CHANCE := 0.14
const AIR_RAID_GAP := 4
const AIR_RAID_MIN := 3
const AIR_RAID_MAX := 5
const AIR_RAID_CAP := 9
const AIR_RAID_SPREAD := 90.0
const AIR_RAID_MARGIN := 40.0
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
const SPREAD_CROWD := 3
const SPREAD_CHANCE := 0.5
const SPREAD_OPTIONS := 3
const SPREAD_REACH := 4.0
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
const ENERGY_PER_COIN := 8.0
const EXPORT_CYCLE := 5.0
const SURVIVAL_TARGETS: Array[int] = [5, 10, 15]
const CREATIVE_MAX_DAY := 99
const BEAM_LOSS_PER_CELL := 0.025
const BEAM_LOSS_MAX := 0.6
const BEAM_FREE_MARGIN := 1.0
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
const SCOUT_SPEED := 195.0
const SCOUT_VISION := 460.0
const SCOUT_RADIUS := 16.0
const DROP_TIME := 2.6
const CORE_DEPLOY_RANGE := 420.0
const CORE_ENEMY_CLEAR := 900.0
const CLEAR_TIME := {"tree": 0.0, "rock": 1.1}
const CLEAR_REACH := 2.9
const SCOUT_WAYPOINT := 8.0
const OBSTACLE_HP := {"tree": 140.0, "rock": 320.0}
const SCOUT_GUN := {"damage": 9.0, "cooldown": 0.55, "range": 250.0}
const STRUCTURE_FAR_SHARE := 0.6
const STRUCTURE_SPACING := 14.0
const STRUCTURE_MARGIN := 2
const TURRET_POST_RING := Vector2(5.0, 9.0)
const CORE_LIGHT := 3.0
const LAMP_RADIUS := 3.0
const LAMP_RADIUS_MIN := 1.5
const LAMP_RADIUS_MAX := 7.0
const LAMP_RADIUS_STEP := 0.5
const LAMP_BASE_RADIUS := 2.0
const LAMP_BASE_DRAW := 1.2
const LAMP_EXPONENT := 2.5
const GLOW_ENERGY := 0.5
const GLOW_REACH := 1.5
const CREEP_RIM := 6
const CREEP_RADIUS := 6.0
const CREEP_CORE_CLEAR := 16.0
const CREEP_FRINGE := 1.0
const CREEP_REACH := 2.5
const CREEP_RECEDE_TIME := 8.0
const CREEP_REFRESH := 0.1
const CREEP_SCAN := 0.25
const CREEP_STRIDE := 2
const FIRE_REACH := 3.5
const FIRE_BURN_TIME := 15.0

const LEVELS := [
	{"id": "dawn", "cells": Vector2i(52, 64), "money": 320, "day": 80.0, "night": 60.0, "seed": 11,
		"drop": Vector2(0.5, 0.84), "structures": [[NEST, Vector2(0.5, 0.1)]],
		"terrain": {"plateaus": 3, "chasms": 1, "ponds": 3, "groves": 1, "forests": 11, "rocks": 12,
			"spots": [[Vector2(0.36, 0.72), 6, [Vector2i(1, 0)]], [Vector2(0.72, 0.62), 5, [Vector2i(0, 1), Vector2i(-1, 0)]]]},
		"waves": {"interval": 9.0, "base": 1.3, "ramp": 1.5, "night": 1.2, "growth": 0.4,
			"roster": [["crawler", 0, 1.0], ["larva", 0, 0.6], ["spitter", 1, 0.3]],
			"night_roster": [["stalker", 0, 1.0]]},
		"world": Vector2(0.5, 0.9), "challenges": [["core", 80], ["survive", 5]]},
	{"id": "beetle_hill", "cells": Vector2i(56, 70), "money": 360, "day": 80.0, "night": 60.0, "seed": 23,
		"drop": Vector2(0.5, 0.86), "structures": [[NEST, Vector2(0.25, 0.1)], [NEST, Vector2(0.75, 0.18)]],
		"terrain": {"plateaus": 5, "chasms": 1, "ponds": 4, "groves": 1, "forests": 13, "rocks": 13, "spots": [[Vector2(0.5, 0.66), 6, [Vector2i(0, -1), Vector2i(1, 0)]]]},
		"waves": {"interval": 9.0, "base": 1.0, "ramp": 1.5, "night": 1.2, "growth": 0.4,
			"roster": [["crawler", 0, 1.0], ["larva", 0, 0.5], ["beetle", 1, 0.5], ["spitter", 1, 0.4], ["mauler", 2, 0.3]],
			"night_roster": [["stalker", 0, 1.0], ["ravager", 3, 0.3], ["behemoth", 4, 0.04]]},
		"world": Vector2(0.24, 0.74), "challenges": [["lost", 3], ["survive", 5]]},
	{"id": "swarm_night", "cells": Vector2i(58, 74), "money": 400, "day": 75.0, "night": 70.0, "seed": 37,
		"drop": Vector2(0.5, 0.86), "structures": [[NEST, Vector2(0.2, 0.12)], [NEST, Vector2(0.8, 0.1)]],
		"terrain": {"plateaus": 5, "chasms": 2, "ponds": 4, "groves": 1, "forests": 14, "rocks": 13, "spots": []},
		"waves": {"interval": 9.0, "base": 1.0, "ramp": 1.5, "night": 1.2, "growth": 0.4,
			"roster": [["crawler", 0, 1.0], ["larva", 0, 0.8], ["spitter", 1, 0.4], ["slinger", 2, 0.3], ["mauler", 2, 0.3]],
			"night_roster": [["stalker", 0, 0.6], ["ravager", 2, 0.4], ["behemoth", 4, 0.05]]},
		"world": Vector2(0.76, 0.72), "challenges": [["combo", 20], ["survive", 5]]},
	{"id": "outpost", "cells": Vector2i(60, 76), "money": 420, "day": 80.0, "night": 60.0, "seed": 41,
		"drop": Vector2(0.5, 0.86), "structures": [[CAMP, Vector2(0.5, 0.08)], [TURRET, Vector2(0.38, 0.2)], [TURRET, Vector2(0.62, 0.2)]],
		"terrain": {"plateaus": 6, "chasms": 2, "ponds": 4, "groves": 2, "forests": 13, "rocks": 15, "spots": []},
		"waves": {"interval": 9.0, "base": 1.45, "ramp": 1.5, "night": 1.2, "growth": 0.4,
			"roster": [["soldier", 0, 1.0], ["sprinter", 0, 0.5]],
			"night_roster": [["raider", 0, 1.0], ["sniper", 2, 0.3], ["breacher", 3, 0.2]]},
		"world": Vector2(0.42, 0.56), "challenges": [["core", 70], ["survive", 6]]},
	{"id": "sabotage", "cells": Vector2i(64, 80), "money": 440, "day": 80.0, "night": 65.0, "seed": 53,
		"drop": Vector2(0.5, 0.87), "structures": [[CAMP, Vector2(0.25, 0.08)], [CAMP, Vector2(0.75, 0.12)], [TURRET, Vector2(0.5, 0.22)]],
		"terrain": {"plateaus": 6, "chasms": 3, "ponds": 5, "groves": 1, "forests": 15, "rocks": 16, "spots": []},
		"waves": {"interval": 9.0, "base": 1.0, "ramp": 1.5, "night": 1.2, "growth": 0.4,
			"roster": [["soldier", 0, 1.0], ["sprinter", 0, 0.6]],
			"night_roster": [["raider", 0, 1.0], ["saboteur", 0, 0.8], ["sniper", 2, 0.4], ["breacher", 3, 0.3], ["brute", 4, 0.15]]},
		"world": Vector2(0.8, 0.47), "challenges": [["lost", 4], ["survive", 6]]},
	{"id": "tank_front", "cells": Vector2i(66, 84), "money": 580, "day": 85.0, "night": 65.0, "seed": 67,
		"drop": Vector2(0.5, 0.88), "structures": [[CAMP, Vector2(0.3, 0.08)], [CAMP, Vector2(0.7, 0.08)], [TURRET, Vector2(0.2, 0.22)], [TURRET, Vector2(0.8, 0.22)], [TURRET, Vector2(0.5, 0.16)]],
		"terrain": {"plateaus": 7, "chasms": 3, "ponds": 5, "groves": 2, "forests": 16, "rocks": 18, "spots": []},
		"waves": {"interval": 9.0, "base": 1.0, "ramp": 1.5, "night": 1.2, "growth": 0.4,
			"roster": [["soldier", 0, 1.0], ["sprinter", 0, 0.5]],
			"night_roster": [["raider", 0, 1.0], ["saboteur", 1, 0.4], ["sniper", 1, 0.4], ["breacher", 2, 0.3], ["brute", 3, 0.25], ["tank", 4, 0.15], ["artillery", 6, 0.05]]},
		"world": Vector2(0.28, 0.36), "challenges": [["days", 8], ["survive", 7]]},
	{"id": "colossus", "cells": Vector2i(70, 88), "money": 620, "day": 85.0, "night": 70.0, "seed": 79,
		"drop": Vector2(0.5, 0.88), "structures": [[NEST, Vector2(0.2, 0.08)], [NEST, Vector2(0.5, 0.14)], [NEST, Vector2(0.8, 0.08)]],
		"terrain": {"plateaus": 7, "chasms": 3, "ponds": 6, "groves": 2, "forests": 18, "rocks": 18, "spots": []},
		"waves": {"interval": 9.0, "base": 0.55, "ramp": 1.5, "night": 1.2, "growth": 0.4,
			"roster": [["crawler", 0, 1.0], ["larva", 0, 0.6], ["spitter", 0, 0.4], ["mauler", 1, 0.5], ["slinger", 1, 0.4], ["beetle", 1, 0.5]],
			"night_roster": [["stalker", 0, 1.0], ["ravager", 2, 0.5], ["behemoth", 4, 0.08], ["juggernaut", 5, 0.05], ["broodmother", 6, 0.04]]},
		"world": Vector2(0.72, 0.25), "challenges": [["combo", 35], ["survive", 7]]},
	{"id": "final_war", "cells": Vector2i(76, 96), "money": 720, "day": 90.0, "night": 75.0, "seed": 97,
		"drop": Vector2(0.5, 0.9), "structures": [[NEST, Vector2(0.15, 0.08)], [CAMP, Vector2(0.5, 0.06)], [NEST, Vector2(0.85, 0.08)], [TURRET, Vector2(0.3, 0.2)], [TURRET, Vector2(0.7, 0.2)], [CAMP, Vector2(0.5, 0.24)]],
		"terrain": {"plateaus": 8, "chasms": 4, "ponds": 6, "groves": 2, "forests": 20, "rocks": 20, "spots": []},
		"waves": {"interval": 9.0, "base": 0.5, "ramp": 1.5, "night": 1.2, "growth": 0.4,
			"roster": [["crawler", 0, 1.0], ["soldier", 0, 0.8], ["sprinter", 0, 0.5], ["mauler", 1, 0.4], ["spitter", 1, 0.4], ["slinger", 1, 0.3], ["beetle", 1, 0.5]],
			"night_roster": [["stalker", 0, 1.0], ["raider", 0, 0.8], ["saboteur", 1, 0.4], ["ravager", 2, 0.5], ["sniper", 2, 0.4], ["breacher", 2, 0.3], ["brute", 3, 0.3], ["tank", 3, 0.15], ["behemoth", 4, 0.1], ["warlord", 5, 0.06], ["juggernaut", 5, 0.06], ["artillery", 5, 0.05], ["reaper", 6, 0.04], ["broodmother", 6, 0.04], ["colossus", 7, 0.04]]},
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
	"bastion": {"branch": BRANCH_DEFENSE, "cost": 2, "requires": ["bulwark_hull"], "unlock": BASTION},
	"plating_1": {"branch": BRANCH_DEFENSE, "cost": 2, "requires": ["bulwark_hull"], "kind": ALL_BUILDINGS, "boost": BOOST_HP, "value": 0.15},
	"plating_2": {"branch": BRANCH_DEFENSE, "cost": 3, "requires": ["plating_1"], "kind": ALL_BUILDINGS, "boost": BOOST_HP, "value": 0.15},
	"solar_output": {"branch": BRANCH_ECONOMY, "cost": 1, "requires": [], "kind": SOLAR, "boost": BOOST_OUTPUT, "value": 0.15},
	"solar_output_2": {"branch": BRANCH_ECONOMY, "cost": 2, "requires": ["solar_output"], "kind": SOLAR, "boost": BOOST_OUTPUT, "value": 0.15},
	"battery_capacity": {"branch": BRANCH_ECONOMY, "cost": 1, "requires": [], "kind": BATTERY, "boost": BOOST_CAPACITY, "value": 0.3},
	"exporter_rate": {"branch": BRANCH_ECONOMY, "cost": 2, "requires": ["battery_capacity"], "kind": EXPORTER, "boost": BOOST_EXPORT, "value": 0.25},
	"superconductor": {"branch": BRANCH_ECONOMY, "cost": 2, "requires": ["solar_output"], "kind": ALL_BUILDINGS, "boost": BOOST_TRANSFER, "value": 0.25},
	"water": {"branch": BRANCH_ECONOMY, "cost": 1, "requires": [], "unlock": WATER},
	"fire": {"branch": BRANCH_ECONOMY, "cost": 1, "requires": [], "unlock": FIRE},
	"funding_1": {"branch": BRANCH_ECONOMY, "cost": 1, "requires": [], "money": 60},
	"funding_2": {"branch": BRANCH_ECONOMY, "cost": 2, "requires": ["funding_1"], "money": 120},
}

const SPAWNER_FACTIONS := {
	NEST: ["crawler", "larva", "mauler", "beetle", "stalker", "ravager", "spitter", "slinger", "wasp", "gnat", "nightwing", "behemoth", "juggernaut", "broodmother", "dreadwing"],
	CAMP: ["soldier", "raider", "sniper", "sprinter", "saboteur", "breacher", "brute", "drone", "phantom", "tank", "artillery", "warlord", "colossus", "reaper", "gunship"],
}

static var _factions := {}
static var _faction_version := -1


static func levels() -> Array:
	var custom := ContentOverrides.levels()
	return custom if not custom.is_empty() else LEVELS


static func level_count() -> int:
	return levels().size()


static func level(index: int) -> Dictionary:
	var list := levels()
	return list[clampi(index, 0, list.size() - 1)]


static func level_index(id: String) -> int:
	var list := levels()
	for i in list.size():
		if list[i].id == id:
			return i
	return -1


static func tech(id: String) -> Dictionary:
	return TECHS.get(id, EMPTY)


static func building(kind: String) -> Dictionary:
	return BUILDINGS.get(kind, EMPTY)


static func enemy(kind: String) -> Dictionary:
	var custom := ContentOverrides.enemy(kind)
	return custom if not custom.is_empty() else ENEMIES.get(kind, EMPTY)


static func enemy_kinds() -> Array:
	var kinds: Array = ENEMIES.keys()
	for kind: String in ContentOverrides.enemy_kinds():
		if not kinds.has(kind):
			kinds.append(kind)
	return kinds


static func faction_kinds(spawner_kind: String) -> Array:
	var version := ContentOverrides.version()
	if version != _faction_version:
		var grouped := {}
		for kind: String in enemy_kinds():
			var faction := str(enemy(kind).get("faction", ""))
			if not grouped.has(faction):
				grouped[faction] = []
			grouped[faction].append(kind)
		for faction: String in grouped:
			grouped[faction].make_read_only()
		_factions = grouped
		_faction_version = version
	return _factions.get(spawner_kind, EMPTY_LIST)


static func armor_config() -> Dictionary:
	return ContentOverrides.armor()


static func has_attack(kind: String) -> bool:
	var definition := building(kind)
	return definition.has("attack") and int(definition.get("team", TEAM_PLAYER)) == TEAM_PLAYER


static func is_tower(kind: String) -> bool:
	return has_attack(kind) and kind != CORE


static func uses_energy_actively(kind: String) -> bool:
	var definition := building(kind)
	return has_attack(kind) or definition.has("heal") or definition.has("shield") or definition.has("light")


static func cells(kind: String) -> int:
	return int(building(kind).get("cells", 1))


static func is_mobile(kind: String) -> bool:
	return building(kind).has("mobile")


static func is_wall(kind: String) -> bool:
	return bool(building(kind).get("wall", false))


static func is_burner(kind: String) -> bool:
	return bool(building(kind).get("fuel", false))


static func is_lamp(kind: String) -> bool:
	return bool(building(kind).get("light", false))


static func is_nocturnal(kind: String) -> bool:
	return bool(enemy(kind).get("nocturnal", false))


static func guard(spawner_kind: String) -> Dictionary:
	return GUARDS.get(spawner_kind, EMPTY)
