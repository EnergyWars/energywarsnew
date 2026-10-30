import re

ARMOR_KEYS = ("constant", "max_reduction", "min_damage")
ENEMY_CLASSES = ("air", "ranged", "melee")
FACTIONS = ("nest", "camp")
ENEMY_REQUIRED = ("class", "hp", "speed", "damage", "cooldown", "reach", "radius", "bounty", "armor", "faction", "look")
ENEMY_OPTIONAL = ("boss", "nocturnal", "sabotage", "buffs")
ENEMY_FLAGS = ("boss", "nocturnal", "sabotage")
ENEMY_POSITIVE = ("hp", "speed", "radius", "cooldown")
ENEMY_NON_NEGATIVE = ("damage", "reach", "armor")
BUFF_SCOPES = ("night", "level")
BUFF_STATS = ("hp", "damage", "speed", "armor")
STRUCTURE_KINDS = ("nest", "camp", "turret")
CHALLENGE_KINDS = ("core", "lost", "days", "combo", "survive")
LEVEL_REQUIRED = ("id", "cells", "money", "day", "night", "seed", "drop", "structures", "terrain", "waves", "world", "challenges")
LEVEL_OPTIONAL = ("extra_waves",)
EXTRA_WAVE_KEYS = ("day", "night", "kind", "count")
MAX_EXTRA_COUNT = 200
TERRAIN_COUNTS = ("plateaus", "chasms", "ponds", "groves", "forests", "rocks")
WAVE_NUMBERS = ("interval", "base", "ramp", "night", "growth")
MIN_CELLS = 20
MAX_CELLS = 400
MAX_LEVELS = 200
MAX_NUMBER = 1e9
MAX_ITEMS = 64
MAX_ROUTES = 2000
MAX_TERRAIN = 100
MAX_SECONDS = 3600
MAX_WAVE_FACTOR = 1000
MAX_DAY = 10000
IDENTIFIER = re.compile(r"[A-Za-z0-9_-]{1,48}")


def _number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and abs(value) <= MAX_NUMBER


def _integer(value):
    return _number(value) and float(value).is_integer()


def _error(code, path):
    return {"code": code, "path": path}


def _pair(value, check):
    return isinstance(value, list) and len(value) == 2 and all(check(item) for item in value)


def _offset(value):
    return _integer(value) and abs(value) <= MAX_CELLS


def _unit(value):
    return _number(value) and 0 <= value <= 1


def _identifier(value):
    return isinstance(value, str) and IDENTIFIER.fullmatch(value) is not None


def _within(items, limit, path, errors):
    if len(items) > limit:
        errors.append(_error("LIMIT", path))
        return False
    return True


def check_armor(armor, errors):
    if not isinstance(armor, dict) or set(armor) != set(ARMOR_KEYS) or not all(_number(v) for v in armor.values()):
        errors.append(_error("ARMOR", "armor"))
        return
    if armor["constant"] <= 0:
        errors.append(_error("ARMOR_CONSTANT", "armor.constant"))
    if not 0 <= armor["max_reduction"] < 1:
        errors.append(_error("ARMOR_REDUCTION", "armor.max_reduction"))
    if armor["min_damage"] < 0:
        errors.append(_error("ARMOR", "armor.min_damage"))


def check_building_armor(entry, errors):
    if "armor" in entry and (not _number(entry["armor"]) or entry["armor"] < 0):
        errors.append(_error("ARMOR", f"buildings.{entry['id']}.armor"))


def _check_buffs(buffs, path, errors):
    if not isinstance(buffs, dict) or set(buffs) - set(BUFF_SCOPES):
        errors.append(_error("ENEMY_BUFFS", path))
        return
    for scope, values in buffs.items():
        valid = isinstance(values, dict) and not set(values) - set(BUFF_STATS) and all(_number(v) and v > -1 for v in values.values())
        if not valid:
            errors.append(_error("ENEMY_BUFFS", f"{path}.{scope}"))


def _check_enemy(enemy, path, errors):
    if not isinstance(enemy, dict):
        errors.append(_error("TYPE", path))
        return
    for key in enemy:
        if key not in ENEMY_REQUIRED + ENEMY_OPTIONAL:
            errors.append(_error("UNKNOWN_KEY", f"{path}.{key}"))
    for key in ENEMY_REQUIRED:
        if key not in enemy:
            errors.append(_error("MISSING", f"{path}.{key}"))
    if "class" in enemy and enemy["class"] not in ENEMY_CLASSES:
        errors.append(_error("ENEMY_CLASS", f"{path}.class"))
    if "faction" in enemy and enemy["faction"] not in FACTIONS:
        errors.append(_error("ENEMY_FACTION", f"{path}.faction"))
    if "look" in enemy and not _identifier(enemy["look"]):
        errors.append(_error("ENEMY_LOOK", f"{path}.look"))
    for key in ENEMY_POSITIVE:
        if key in enemy and (not _number(enemy[key]) or enemy[key] <= 0):
            errors.append(_error("ENEMY_NUMBER", f"{path}.{key}"))
    for key in ENEMY_NON_NEGATIVE:
        if key in enemy and (not _number(enemy[key]) or enemy[key] < 0):
            errors.append(_error("ENEMY_NUMBER", f"{path}.{key}"))
    if "bounty" in enemy and (not _integer(enemy["bounty"]) or enemy["bounty"] < 0):
        errors.append(_error("ENEMY_NUMBER", f"{path}.bounty"))
    for key in ENEMY_FLAGS:
        if key in enemy and not isinstance(enemy[key], bool):
            errors.append(_error("ENEMY_FLAG", f"{path}.{key}"))
    if "buffs" in enemy:
        _check_buffs(enemy["buffs"], f"{path}.buffs", errors)


def check_enemies(enemies, original, errors):
    if not isinstance(enemies, dict) or set(enemies) != set(original):
        errors.append(_error("ENEMY_SET", "enemies"))
        return
    for kind, enemy in enemies.items():
        _check_enemy(enemy, f"enemies.{kind}", errors)


def _check_roster(roster, kinds, path, errors):
    if not isinstance(roster, list):
        errors.append(_error("WAVE_ROSTER", path))
        return
    if not _within(roster, MAX_ITEMS, path, errors):
        return
    for index, entry in enumerate(roster):
        valid = (
            isinstance(entry, list)
            and len(entry) == 3
            and isinstance(entry[0], str)
            and entry[0] in kinds
            and _integer(entry[1])
            and 0 <= entry[1] <= MAX_ITEMS
            and _number(entry[2])
            and 0 < entry[2] <= MAX_WAVE_FACTOR
        )
        if not valid:
            errors.append(_error("WAVE_ROSTER", f"{path}.{index}"))


def _check_waves(waves, kinds, path, errors):
    if not isinstance(waves, dict) or set(waves) != set(WAVE_NUMBERS) | {"roster", "night_roster"}:
        errors.append(_error("WAVES", path))
        return
    if not _number(waves["interval"]) or not 0 < waves["interval"] <= MAX_SECONDS:
        errors.append(_error("WAVES", f"{path}.interval"))
    for key in WAVE_NUMBERS[1:]:
        if not _number(waves[key]) or not 0 <= waves[key] <= MAX_WAVE_FACTOR:
            errors.append(_error("WAVES", f"{path}.{key}"))
    _check_roster(waves["roster"], kinds, f"{path}.roster", errors)
    _check_roster(waves["night_roster"], kinds, f"{path}.night_roster", errors)
    if isinstance(waves["roster"], list) and not waves["roster"]:
        errors.append(_error("WAVE_ROSTER", f"{path}.roster"))


def _check_extra_waves(entries, kinds, path, errors):
    if not isinstance(entries, list):
        errors.append(_error("EXTRA_WAVE", path))
        return
    if not _within(entries, MAX_ITEMS, path, errors):
        return
    for index, entry in enumerate(entries):
        valid = (
            isinstance(entry, dict)
            and set(entry) == set(EXTRA_WAVE_KEYS)
            and _integer(entry["day"])
            and 1 <= entry["day"] <= MAX_DAY
            and isinstance(entry["night"], bool)
            and isinstance(entry["kind"], str)
            and entry["kind"] in kinds
            and _integer(entry["count"])
            and 1 <= entry["count"] <= MAX_EXTRA_COUNT
        )
        if not valid:
            errors.append(_error("EXTRA_WAVE", f"{path}.{index}"))


def _check_terrain(terrain, path, errors):
    if not isinstance(terrain, dict) or set(terrain) != set(TERRAIN_COUNTS) | {"spots"}:
        errors.append(_error("LEVEL_TERRAIN", path))
        return
    for key in TERRAIN_COUNTS:
        if not _integer(terrain[key]) or not 0 <= terrain[key] <= MAX_TERRAIN:
            errors.append(_error("LEVEL_TERRAIN", f"{path}.{key}"))
    spots = terrain["spots"]
    if not isinstance(spots, list):
        errors.append(_error("LEVEL_TERRAIN", f"{path}.spots"))
        return
    if not _within(spots, MAX_ITEMS, f"{path}.spots", errors):
        return
    for index, spot in enumerate(spots):
        valid = (
            isinstance(spot, list)
            and len(spot) == 3
            and _pair(spot[0], _unit)
            and _integer(spot[1])
            and 0 < spot[1] <= MAX_CELLS
            and isinstance(spot[2], list)
            and len(spot[2]) <= MAX_ITEMS
            and all(_pair(offset, _offset) for offset in spot[2])
        )
        if not valid:
            errors.append(_error("LEVEL_TERRAIN", f"{path}.spots.{index}"))


def _check_structures(structures, path, errors):
    if not isinstance(structures, list):
        errors.append(_error("LEVEL_STRUCTURE", path))
        return
    if not _within(structures, MAX_ITEMS, path, errors):
        return
    for index, entry in enumerate(structures):
        valid = isinstance(entry, list) and len(entry) == 2 and entry[0] in STRUCTURE_KINDS and _pair(entry[1], _unit)
        if not valid:
            errors.append(_error("LEVEL_STRUCTURE", f"{path}.{index}"))


def _check_challenges(challenges, path, errors):
    if not isinstance(challenges, list):
        errors.append(_error("CHALLENGE", path))
        return
    if not _within(challenges, MAX_ITEMS, path, errors):
        return
    for index, entry in enumerate(challenges):
        valid = isinstance(entry, list) and len(entry) == 2 and entry[0] in CHALLENGE_KINDS and _integer(entry[1]) and entry[1] >= 0
        if not valid:
            errors.append(_error("CHALLENGE", f"{path}.{index}"))


def _check_level(level, kinds, path, errors):
    if not isinstance(level, dict):
        errors.append(_error("TYPE", path))
        return
    for key in level:
        if key not in LEVEL_REQUIRED + LEVEL_OPTIONAL:
            errors.append(_error("UNKNOWN_KEY", f"{path}.{key}"))
    missing = [key for key in LEVEL_REQUIRED if key not in level]
    for key in missing:
        errors.append(_error("MISSING", f"{path}.{key}"))
    if missing:
        return
    if not _identifier(level["id"]):
        errors.append(_error("LEVEL_ID", f"{path}.id"))
    cells = level["cells"]
    if not _pair(cells, _integer) or any(not MIN_CELLS <= value <= MAX_CELLS for value in cells):
        errors.append(_error("LEVEL_CELLS", f"{path}.cells"))
    if not _integer(level["money"]) or level["money"] < 0:
        errors.append(_error("LEVEL_MONEY", f"{path}.money"))
    for key in ("day", "night"):
        if not _number(level[key]) or not 0 < level[key] <= MAX_SECONDS:
            errors.append(_error("LEVEL_TIME", f"{path}.{key}"))
    if not _integer(level["seed"]):
        errors.append(_error("LEVEL_SEED", f"{path}.seed"))
    if not _pair(level["drop"], _unit):
        errors.append(_error("LEVEL_POSITION", f"{path}.drop"))
    if level["world"] is not None and not _pair(level["world"], _unit):
        errors.append(_error("LEVEL_POSITION", f"{path}.world"))
    _check_structures(level["structures"], f"{path}.structures", errors)
    _check_terrain(level["terrain"], f"{path}.terrain", errors)
    _check_waves(level["waves"], kinds, f"{path}.waves", errors)
    if "extra_waves" in level:
        _check_extra_waves(level["extra_waves"], kinds, f"{path}.extra_waves", errors)
    _check_challenges(level["challenges"], f"{path}.challenges", errors)


def check_levels(levels, kinds, errors):
    if not isinstance(levels, list) or not 1 <= len(levels) <= MAX_LEVELS:
        errors.append(_error("LEVEL_SET", "levels"))
        return False
    seen = set()
    for index, level in enumerate(levels):
        _check_level(level, kinds, f"levels.{index}", errors)
        identifier = level.get("id") if isinstance(level, dict) else None
        if isinstance(identifier, str) and identifier.strip():
            if identifier in seen:
                errors.append(_error("LEVEL_ID_DUPLICATE", f"levels.{index}.id"))
            seen.add(identifier)
    return True


def check_routes(routes, level_count, errors):
    if routes is None:
        return
    if not isinstance(routes, list):
        errors.append(_error("ROUTES", "routes"))
        return
    if not _within(routes, MAX_ROUTES, "routes", errors):
        return
    seen = set()
    for index, route in enumerate(routes):
        valid = _pair(route, _integer) and all(0 <= value < level_count for value in route) and route[0] != route[1]
        if not valid:
            errors.append(_error("ROUTES", f"routes.{index}"))
            continue
        key = tuple(sorted(route))
        if key in seen:
            errors.append(_error("ROUTES", f"routes.{index}"))
        seen.add(key)


def validate_content(document, original):
    errors = []
    sections = [key for key in ("armor", "enemies", "levels", "routes") if key in document or key in original]
    for key in sections:
        if key not in document:
            errors.append(_error("MISSING", key))
    if "armor" in sections and "armor" in document:
        check_armor(document["armor"], errors)
    enemies = document.get("enemies", original.get("enemies"))
    if "enemies" in sections and "enemies" in document:
        check_enemies(document["enemies"], original.get("enemies", document["enemies"]), errors)
    kinds = set(enemies) if isinstance(enemies, dict) else set()
    level_count = 0
    if "levels" in sections and "levels" in document:
        if check_levels(document["levels"], kinds, errors):
            level_count = len(document["levels"])
    if "routes" in sections and "routes" in document:
        check_routes(document["routes"], level_count, errors)
    return errors
