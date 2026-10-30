def _flatten(value, prefix, out):
    if isinstance(value, dict):
        for key in value:
            _flatten(value[key], f"{prefix}.{key}" if prefix else key, out)
    else:
        out[prefix] = value


def _indexed(document):
    flat = {}
    _flatten(document.get("system", {}), "system", flat)
    _flatten(document.get("tracks", {}), "tracks", flat)
    _flatten(document.get("armor", {}), "armor", flat)
    _flatten(document.get("enemies", {}), "enemies", flat)
    levels = document.get("levels", [])
    for index, level in enumerate(levels):
        _flatten(level, f"levels.{level.get('id', index)}", flat)
    if levels:
        flat["levels.order"] = [level.get("id") for level in levels]
    if document.get("routes") is not None:
        flat["routes"] = sorted(sorted(route) for route in document["routes"])
    for entry in document.get("buildings", []):
        base = f"buildings.{entry['id']}"
        for key, value in entry.items():
            if key != "id":
                _flatten(value, f"{base}.{key}", flat)
    _index_groups(document.get("groups"), flat)
    return flat


def _index_groups(groups, flat):
    if not isinstance(groups, list):
        return
    areas = [area for area in groups if isinstance(area, dict)]
    if not areas:
        return
    flat["groups.order"] = [area.get("name") for area in areas]
    for area in areas:
        base = f"groups.{area.get('name')}"
        flat[f"{base}.items"] = list(area.get("items") or [])
        sections = [section for section in area.get("sections") or [] if isinstance(section, dict)]
        flat[f"{base}.sections"] = [section.get("name") for section in sections]
        for section in sections:
            flat[f"{base}.section.{section.get('name')}"] = list(section.get("items") or [])


def diff(original, edited):
    before = _indexed(original)
    after = _indexed(edited)
    changes = []
    for path in sorted(before.keys() | after.keys()):
        old = before.get(path)
        new = after.get(path)
        if old != new:
            changes.append({"path": path, "before": old, "after": new})
    return changes
