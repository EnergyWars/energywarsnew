import re

from .gdliteral import find_span, parse_dict

TRACK_ORDER = ("max", "step", "price", "growth", "energy")
CURVE_ORDER = ("max", "gain", "gain_growth", "price", "growth")
INTEGER_KEYS = ("max",)
WALL_CURVE = ("bulwark", "hull")


def _number(key, value):
    if key in INTEGER_KEYS:
        return str(int(value))
    text = repr(float(value))
    return text[:-2] + ".0" if text.endswith("e") else text


def _dict_literal(config, order):
    parts = [f'"{key}": {_number(key, config[key])}' for key in order if key in config]
    return "{" + ", ".join(parts) + "}"


def _const(prefix, name):
    return f"{prefix}{name.upper()}"


def _replace_line(text, pattern, replacement):
    result, count = re.subn(pattern, lambda _: replacement, text, count=1, flags=re.MULTILINE)
    if count != 1:
        raise ValueError(f"pattern not found: {pattern}")
    return result


def _patch_tracks(text, document):
    for track_id, config in document["tracks"].items():
        constant = _const("TRACK_", track_id)
        pattern = rf"^\t{constant}: \{{.*\}},$"
        text = _replace_line(text, pattern, f"\t{constant}: {_dict_literal(config, TRACK_ORDER)},")
    growth = repr(float(document["system"]["track_growth"]))
    text = _replace_line(text, r"^const TRACK_GROWTH := .*$", f"const TRACK_GROWTH := {growth}")
    wall = next(entry for entry in document["buildings"] if entry["id"] == WALL_CURVE[0])
    literal = _dict_literal(wall["curves"][WALL_CURVE[1]], CURVE_ORDER)
    return _replace_line(text, r"^const WALL_HULL := .*$", f"const WALL_HULL := {literal}")


def _block_bounds(text, kind):
    start = re.search(rf"^\t{kind.upper()}: \{{", text, flags=re.MULTILINE)
    if start is None:
        raise ValueError(f"building not found: {kind}")
    following = re.search(r"^\t[A-Z_]+: \{|^\}", text[start.end():], flags=re.MULTILINE)
    end = start.end() + following.start() if following else len(text)
    return start.start(), end


def _like(old, value):
    if float(old) == float(value):
        return old
    if "." not in old and float(value).is_integer():
        return str(int(value))
    return repr(float(value))


def _flat_stats(stats, prefix=()):
    for key, value in stats.items():
        if isinstance(value, dict):
            yield from _flat_stats(value, prefix + (key,))
        else:
            yield prefix + (key,), value


def _patch_stats(text, entry):
    for path, value in _flat_stats(entry.get("stats", {})):
        start = re.search(rf"^\t{entry['id'].upper()}: \{{", text, flags=re.MULTILINE)
        entries = parse_dict(text, start.end() - 1)
        begin, end = find_span(entries, path)
        text = text[:begin] + _like(text[begin:end], value) + text[end:]
    return text


def _patch_building(text, entry):
    start, end = _block_bounds(text, entry["id"])
    block = text[start:end]
    block = re.sub(r'"cost": -?\d+', f'"cost": {int(entry["cost"])}', block, count=1)
    block = re.sub(r'"hp": [\d.]+', f'"hp": {_number("hp", entry["hp"])}', block, count=1)
    base = int(entry["upgrade_base"])
    if '"upgrade_base"' in block:
        block = re.sub(r'"upgrade_base": \d+', f'"upgrade_base": {base}', block, count=1)
    elif base != int(entry["cost"]):
        block = re.sub(r'("cost": \d+,)', rf'\1 "upgrade_base": {base},', block, count=1)
    listed = ", ".join(_const("TRACK_", track) for track in entry["tracks"])
    block = re.sub(r'"tracks": \[[^\]]*\]', f'"tracks": [{listed}]', block, count=1)
    return _patch_stats(text[:start] + block + text[end:], entry)


def patch_config(text, document):
    text = _patch_tracks(text, document)
    for entry in document["buildings"]:
        text = _patch_building(text, entry)
    return text
