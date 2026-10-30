SCHEMA = 1
MAX_LEVELS = 200
PLAN_MODES = ("formula", "table")
HISTORY_KINDS = ("cost", "effect")
HISTORY_LIMIT = 30
HISTORY_TEXT_LIMIT = 500
TRACK_KEYS = ("max", "step", "price", "growth", "energy")
CURVE_KEYS = ("max", "gain", "gain_growth", "price", "growth")


def _is_number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool)


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
    _check_history(document.get("formula_history", {}), errors)
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
    return errors


def _check_history(history, errors):
    if not isinstance(history, dict) or set(history) - set(HISTORY_KINDS):
        errors.append(_error("HISTORY", "formula_history"))
        return
    for kind, items in history.items():
        valid = (
            isinstance(items, list)
            and len(items) <= HISTORY_LIMIT
            and len(set(items)) == len(items)
            and all(isinstance(item, str) and item.strip() and len(item) <= HISTORY_TEXT_LIMIT for item in items)
        )
        if not valid:
            errors.append(_error("HISTORY", f"formula_history.{kind}"))


def _check_building(entry, source, tracks, errors):
    path = f"buildings.{entry['id']}"
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
                if not isinstance(plan.get(key), str) or not plan[key].strip():
                    errors.append(_error("PLAN_FORMULA", f"{where}.{key}"))
            if plan.get("max") != len(levels):
                errors.append(_error("PLAN_FORMULA", f"{where}.max"))
