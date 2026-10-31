from .content_model import check_building_armor, validate_content
from .expr import is_formula

SCHEMA = 1
MAX_LEVELS = 200
PLAN_MODES = ("formula", "table")
SAVED_KINDS = ("cost", "metric")
SAVED_LIMIT = 50
SAVED_NAME_LIMIT = 60
SAVED_DESCRIPTION_LIMIT = 1000
FORMULA_TEXT_LIMIT = 500
FORMULA_TARGETS = ("value", "efficiency", "totalEfficiency", "factor")
TRACK_KEYS = ("max", "step", "price", "growth", "energy")
CURVE_KEYS = ("max", "gain", "gain_growth", "price", "growth")
PLAN_KEYS = ("mode", "levels", "max", "cost", "effect")
BUILDING_EXTRA_KEYS = ("plans", "curves", "armor")
READONLY_BUILDING_KEYS = ("description_key", "cost_every")
MAX_NUMBER = 1e15
GROUP_NAME_LIMIT = 60
GROUP_AREA_LIMIT = 50
GROUP_SECTION_LIMIT = 50
GROUP_ITEM_LIMIT = 500
GROUP_AREA_KEYS = ("name", "items", "sections")
GROUP_SECTION_KEYS = ("name", "items")


def _is_number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and abs(value) <= MAX_NUMBER


def _is_integer(value):
    return _is_number(value) and float(value).is_integer()


def _error(code, path):
    return {"code": code, "path": path}


def _check_config(config, path, keys, errors):
    if not isinstance(config, dict):
        errors.append(_error("TYPE", path))
        return
    for key in config:
        if key not in keys:
            errors.append(_error("UNKNOWN_KEY", f"{path}.{key}"))
    if not _is_integer(config.get("max")) or config["max"] < 1:
        errors.append(_error("MAX", f"{path}.max"))
    if not _is_number(config.get("price")) or config["price"] <= 0:
        errors.append(_error("PRICE", f"{path}.price"))
    for key in ("step", "gain"):
        if key in keys and key in config and (not _is_number(config[key]) or config[key] <= 0):
            errors.append(_error("POSITIVE", f"{path}.{key}"))
    for key in ("growth", "gain_growth", "energy"):
        if key in config and (not _is_number(config[key]) or config[key] <= 1):
            errors.append(_error("GROWTH", f"{path}.{key}"))
    if "gain" in config and "gain_growth" not in config:
        errors.append(_error("MISSING", f"{path}.gain_growth"))
    if "gain" not in config and "step" not in config:
        errors.append(_error("MISSING", f"{path}.step"))


def validate(document, original):
    errors = []
    if not isinstance(document, dict) or document.get("schema") != SCHEMA:
        return [_error("SCHEMA", "schema")]
    growth = document.get("system", {}).get("track_growth")
    if not _is_number(growth) or growth <= 1:
        errors.append(_error("GROWTH", "system.track_growth"))
    _check_saved_formulas(document.get("saved_formulas", {}), errors)
    tracks = document.get("tracks")
    if not isinstance(tracks, dict) or set(tracks) != set(original["tracks"]):
        errors.append(_error("TRACK_SET", "tracks"))
        return errors
    for track_id, config in tracks.items():
        _check_config(config, f"tracks.{track_id}", TRACK_KEYS, errors)
    buildings = document.get("buildings")
    expected = [entry["id"] for entry in original["buildings"]]
    if not isinstance(buildings, list) or [entry.get("id") for entry in buildings] != expected:
        errors.append(_error("BUILDING_SET", "buildings"))
        return errors
    originals = {entry["id"]: entry for entry in original["buildings"]}
    for entry in buildings:
        _check_building(entry, originals[entry["id"]], tracks, errors)
        check_building_armor(entry, errors)
    _check_groups(document.get("groups"), _known_items(buildings), errors)
    errors.extend(validate_content(document, original))
    return errors


def _known_items(buildings):
    known = set()
    for entry in buildings:
        listed = entry.get("tracks")
        if isinstance(listed, list):
            known.update(f"{entry['id']}:{track}" for track in listed if isinstance(track, str))
    return known


def _group_name_valid(name):
    return isinstance(name, str) and bool(name.strip()) and len(name.strip()) <= GROUP_NAME_LIMIT


def _check_group_shape(value, keys, path, errors):
    if not isinstance(value, dict) or set(value) - set(keys):
        errors.append(_error("GROUPS", path))
        return False
    if not _group_name_valid(value.get("name")):
        errors.append(_error("GROUP_NAME", f"{path}.name"))
    return True


def _check_group_items(items, known, path, errors):
    if items is None:
        return
    if not isinstance(items, list) or len(items) > GROUP_ITEM_LIMIT:
        errors.append(_error("GROUPS", path))
        return
    seen = set()
    for index, item in enumerate(items):
        if not isinstance(item, str) or item not in known:
            errors.append(_error("GROUP_ITEM", f"{path}.{index}"))
            continue
        if item in seen:
            errors.append(_error("GROUP_DUPLICATE", f"{path}.{index}"))
        seen.add(item)


def _check_group_names(entries, path, errors):
    seen = set()
    for index, entry in enumerate(entries):
        if not isinstance(entry, dict) or not isinstance(entry.get("name"), str):
            continue
        name = entry["name"].strip().lower()
        if name and name in seen:
            errors.append(_error("GROUP_DUPLICATE", f"{path}.{index}.name"))
        seen.add(name)


def _check_groups(groups, known, errors):
    if groups is None:
        return
    if not isinstance(groups, list) or len(groups) > GROUP_AREA_LIMIT:
        errors.append(_error("GROUPS", "groups"))
        return
    for area_index, area in enumerate(groups):
        path = f"groups.{area_index}"
        if not _check_group_shape(area, GROUP_AREA_KEYS, path, errors):
            continue
        _check_group_items(area.get("items"), known, f"{path}.items", errors)
        sections = area.get("sections")
        if sections is None:
            continue
        if not isinstance(sections, list) or len(sections) > GROUP_SECTION_LIMIT:
            errors.append(_error("GROUPS", f"{path}.sections"))
            continue
        for section_index, section in enumerate(sections):
            where = f"{path}.sections.{section_index}"
            if _check_group_shape(section, GROUP_SECTION_KEYS, where, errors):
                _check_group_items(section.get("items"), known, f"{where}.items", errors)
        _check_group_names(sections, f"{path}.sections", errors)
    _check_group_names(groups, "groups", errors)


def _check_saved_formulas(saved, errors):
    if not isinstance(saved, dict) or set(saved) - set(SAVED_KINDS):
        errors.append(_error("SAVED_FORMULAS", "saved_formulas"))
        return
    for kind, items in saved.items():
        if not _valid_saved_list(kind, items):
            errors.append(_error("SAVED_FORMULAS", f"saved_formulas.{kind}"))


def _valid_saved_list(kind, items):
    if not isinstance(items, list) or len(items) > SAVED_LIMIT:
        return False
    names = set()
    for item in items:
        if not _valid_saved_formula(kind, item):
            return False
        key = item["name"].strip().lower()
        if key in names:
            return False
        names.add(key)
    return True


def _valid_saved_formula(kind, item):
    keys = {"name", "formula", "description"} | ({"target"} if kind == "metric" else set())
    if not isinstance(item, dict) or set(item) != keys:
        return False
    name, formula, description = item["name"], item["formula"], item["description"]
    texts = isinstance(name, str) and isinstance(formula, str) and isinstance(description, str)
    return (
        texts
        and 0 < len(name.strip()) and len(name) <= SAVED_NAME_LIMIT
        and 0 < len(formula) <= FORMULA_TEXT_LIMIT and is_formula(formula)
        and len(description) <= SAVED_DESCRIPTION_LIMIT
        and (kind == "cost" or item["target"] in FORMULA_TARGETS)
    )


def _check_building(entry, source, tracks, errors):
    path = f"buildings.{entry['id']}"
    for key in entry:
        if key not in source and key not in BUILDING_EXTRA_KEYS:
            errors.append(_error("UNKNOWN_KEY", f"{path}.{key}"))
    for key in READONLY_BUILDING_KEYS:
        if entry.get(key) != source.get(key):
            errors.append(_error("READONLY", f"{path}.{key}"))
    if not _is_integer(entry.get("cost")) or entry["cost"] < 0:
        errors.append(_error("COST", f"{path}.cost"))
    if not _is_integer(entry.get("upgrade_base")) or entry["upgrade_base"] < 1:
        errors.append(_error("UPGRADE_BASE", f"{path}.upgrade_base"))
    if not _is_number(entry.get("hp")) or entry["hp"] <= 0:
        errors.append(_error("HP", f"{path}.hp"))
    listed = entry.get("tracks")
    if not isinstance(listed, list) or len(set(listed)) != len(listed) or any(track not in tracks for track in listed):
        errors.append(_error("TRACKS", f"{path}.tracks"))
        listed = []
    _check_stats(entry.get("stats"), source.get("stats", {}), f"{path}.stats", errors)
    _check_plans(entry.get("plans", {}), listed, f"{path}.plans", errors)
    curves = entry.get("curves", {})
    if not isinstance(curves, dict) or set(curves) != set(source.get("curves", {})):
        errors.append(_error("CURVE_SET", f"{path}.curves"))
        return
    for track_id, config in curves.items():
        if track_id not in listed:
            errors.append(_error("CURVE_TRACK", f"{path}.curves.{track_id}"))
        _check_config(config, f"{path}.curves.{track_id}", CURVE_KEYS, errors)


def _check_stats(stats, source, path, errors):
    if not isinstance(stats, dict) or set(stats) != set(source):
        errors.append(_error("STAT_SET", path))
        return
    for key, original in source.items():
        value = stats[key]
        if isinstance(original, dict):
            _check_stats(value, original, f"{path}.{key}", errors)
        elif not _is_number(value) or value < 0 or (isinstance(original, int) and not _is_integer(value)):
            errors.append(_error("STAT", f"{path}.{key}"))


def _check_plans(plans, listed, path, errors):
    if not isinstance(plans, dict):
        errors.append(_error("PLAN", path))
        return
    for track_id, plan in plans.items():
        where = f"{path}.{track_id}"
        if track_id not in listed:
            errors.append(_error("PLAN_TRACK", where))
            continue
        if not isinstance(plan, dict) or plan.get("mode") not in PLAN_MODES:
            errors.append(_error("PLAN", where))
            continue
        for key in plan:
            if key not in PLAN_KEYS:
                errors.append(_error("UNKNOWN_KEY", f"{where}.{key}"))
        levels = plan.get("levels")
        if not isinstance(levels, list) or not 1 <= len(levels) <= MAX_LEVELS:
            errors.append(_error("PLAN_LEVELS", f"{where}.levels"))
            continue
        for index, level in enumerate(levels):
            valid = isinstance(level, dict) and _is_integer(level.get("cost")) and level["cost"] >= 1 and _is_number(level.get("gain"))
            if not valid:
                errors.append(_error("PLAN_LEVELS", f"{where}.levels.{index}"))
        if plan["mode"] == "formula":
            for key in ("cost", "effect"):
                if not isinstance(plan.get(key), str) or len(plan[key]) > FORMULA_TEXT_LIMIT or not is_formula(plan[key]):
                    errors.append(_error("PLAN_FORMULA", f"{where}.{key}"))
            if plan.get("max") != len(levels):
                errors.append(_error("PLAN_FORMULA", f"{where}.max"))


MALFORMED = (AttributeError, TypeError, KeyError, IndexError, ValueError, OverflowError, RecursionError)


def safe_validate(document, original):
    try:
        return validate(document, original)
    except MALFORMED:
        return [_error("TYPE", "document")]
