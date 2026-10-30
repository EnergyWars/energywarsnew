SCHEMA = 1
DIGITS = 6


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
            exported = {key: value for key, value in plan.items() if key != "levels"}
            exported["levels"] = _levels(plan)
            entry_plans[track] = exported
        if entry_plans:
            plans[entry["id"]] = entry_plans
    return {"schema": SCHEMA, "plans": plans}
