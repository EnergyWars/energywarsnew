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
    for entry in document.get("buildings", []):
        base = f"buildings.{entry['id']}"
        for key, value in entry.items():
            if key != "id":
                _flatten(value, f"{base}.{key}", flat)
    return flat


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
