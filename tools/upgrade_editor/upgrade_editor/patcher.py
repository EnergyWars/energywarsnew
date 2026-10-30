import re

from .gdliteral import find_span, parse_dict

TRACK_ORDER = ("max", "step", "price", "growth", "energy")
CURVE_ORDER = ("max", "gain", "gain_growth", "price", "growth")
INTEGER_KEYS = ("max",)
WALL_CURVE = ("bulwark", "hull")
NUMBER_LITERAL = re.compile(r"-?\d+(\.\d+)?(e[+-]?\d+)?")
IDENTIFIER = re.compile(r"[a-z][a-z0-9_]*")


class UnsafeValue(ValueError):
    pass


def _literal(text):
    if NUMBER_LITERAL.fullmatch(text) is None:
        raise UnsafeValue(f"not a number literal: {text[:40]!r}")
    return text


def _value(value):
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise UnsafeValue(f"not a number: {type(value).__name__}")
    return value


def _integer(value):
    value = _value(value)
    if isinstance(value, float) and not value.is_integer():
        raise UnsafeValue("not an integer")
    return _literal(str(int(value)))


def _float(value):
    return _literal(repr(float(_value(value))))


def _name(value):
    if not isinstance(value, str) or IDENTIFIER.fullmatch(value) is None:
        raise UnsafeValue(f"not an identifier: {str(value)[:40]!r}")
    return value


def _number(key, value):
    if key in INTEGER_KEYS:
        return _integer(value)
    return _float(value)


def _dict_literal(config, order):
    parts = [f'"{key}": {_number(key, config[key])}' for key in order if key in config]
    return "{" + ", ".join(parts) + "}"


def _const(prefix, name):
    return f"{prefix}{_name(name).upper()}"


def _block_start(text, kind):
    return re.search(rf"^\t{re.escape(_name(kind).upper())}: \{{", text, flags=re.MULTILINE)


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
    growth = _float(document["system"]["track_growth"])
    text = _replace_line(text, r"^const TRACK_GROWTH := .*$", f"const TRACK_GROWTH := {growth}")
    wall = next(entry for entry in document["buildings"] if entry["id"] == WALL_CURVE[0])
    literal = _dict_literal(wall["curves"][WALL_CURVE[1]], CURVE_ORDER)
    return _replace_line(text, r"^const WALL_HULL := .*$", f"const WALL_HULL := {literal}")


def _block_bounds(text, kind):
    start = _block_start(text, kind)
    if start is None:
        raise ValueError(f"building not found: {kind}")
    following = re.search(r"^\t[A-Z_]+: \{|^\}", text[start.end():], flags=re.MULTILINE)
    end = start.end() + following.start() if following else len(text)
    return start.start(), end


def _like(old, value):
    value = _value(value)
    if float(old) == float(value):
        return old
    if "." not in old and float(value).is_integer():
        return _integer(value)
    return _float(value)


def _flat_stats(stats, prefix=()):
    for key, value in stats.items():
        if isinstance(value, dict):
            yield from _flat_stats(value, prefix + (key,))
        else:
            yield prefix + (key,), value


def _patch_stats(text, entry):
    for path, value in _flat_stats(entry.get("stats", {})):
        start = _block_start(text, entry["id"])
        entries = parse_dict(text, start.end() - 1)
        try:
            begin, end = find_span(entries, path)
        except KeyError as error:
            raise UnsafeValue(f"unknown stat: {'.'.join(path)[:40]}") from error
        text = text[:begin] + _like(text[begin:end], value) + text[end:]
    return text


def _patch_building(text, entry):
    start, end = _block_bounds(text, entry["id"])
    block = text[start:end]
    cost = _integer(entry["cost"])
    block = re.sub(r'"cost": -?\d+', lambda _: f'"cost": {cost}', block, count=1)
    hp = _number("hp", entry["hp"])
    block = re.sub(r'"hp": [\d.]+', lambda _: f'"hp": {hp}', block, count=1)
    base = _integer(entry["upgrade_base"])
    if '"upgrade_base"' in block:
        block = re.sub(r'"upgrade_base": \d+', lambda _: f'"upgrade_base": {base}', block, count=1)
    elif base != cost:
        block = re.sub(r'("cost": \d+,)', rf'\1 "upgrade_base": {base},', block, count=1)
    listed = ", ".join(_const("TRACK_", track) for track in entry["tracks"])
    block = re.sub(r'"tracks": \[[^\]]*\]', lambda _: f'"tracks": [{listed}]', block, count=1)
    return _patch_armor(_patch_stats(text[:start] + block + text[end:], entry), entry)


def _patch_armor(text, entry):
    if "armor" not in entry:
        return text
    start = _block_start(text, entry["id"])
    entries = parse_dict(text, start.end() - 1)
    if "armor" not in entries:
        return text
    begin, end = find_span(entries, ("armor",))
    return text[:begin] + _like(text[begin:end], entry["armor"]) + text[end:]


def patch_config(text, document):
    text = _patch_tracks(text, document)
    for entry in document["buildings"]:
        text = _patch_building(text, entry)
    return text
