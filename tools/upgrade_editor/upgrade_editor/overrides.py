from pathlib import Path

from .safejson import atomic_write, dumps

SCHEMA = 1
DIGITS = 6
EXPORTED_PLAN_KEYS = ("mode", "max", "cost", "effect")


def _levels(plan):
    effect = 1.0
    result = []
    for level in plan["levels"]:
        effect += level["gain"]
        result.append({"cost": int(level["cost"]), "gain": level["gain"], "effect": round(effect, DIGITS)})
    return result


def build_overrides(document):
    plans = {}
    for entry in document["buildings"]:
        entry_plans = {}
        for track, plan in entry.get("plans", {}).items():
            exported = {key: plan[key] for key in EXPORTED_PLAN_KEYS if key in plan}
            exported["levels"] = _levels(plan)
            entry_plans[track] = exported
        if entry_plans:
            plans[entry["id"]] = entry_plans
    return {"schema": SCHEMA, "plans": plans}


def _different(document, baseline, key):
    return key in document and document[key] != baseline.get(key)


def build_content_overrides(document, original):
    baseline = original.get("defaults") or original
    result = {}
    armor = document.get("armor")
    if isinstance(armor, dict):
        changed = {key: value for key, value in armor.items() if value != baseline.get("armor", {}).get(key)}
        if changed:
            result["armor"] = changed
    enemies = {kind: enemy for kind, enemy in document.get("enemies", {}).items() if enemy != baseline.get("enemies", {}).get(kind)}
    if enemies:
        result["enemies"] = enemies
    levels_changed = _different(document, baseline, "levels")
    if levels_changed:
        result["levels"] = document["levels"]
    routes = document.get("routes")
    if routes is None and not levels_changed and isinstance(document.get("levels"), list) and "routes" in document:
        routes = [[index - 1, index] for index in range(1, len(document["levels"]))]
    if routes is not None and (levels_changed or _normalized(routes) != _normalized(baseline.get("routes", routes))):
        result["routes"] = routes
    return result


def _normalized(routes):
    return sorted(sorted(route) for route in routes)


def write_content_overrides(path, content):
    path = Path(path)
    if not content:
        path.unlink(missing_ok=True)
        return False
    atomic_write(path, dumps(content) + "\n")
    return True
