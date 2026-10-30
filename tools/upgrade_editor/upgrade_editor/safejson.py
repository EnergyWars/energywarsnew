import json
import os
import tempfile
from pathlib import Path

MAX_DEPTH = 64


class JsonRejected(ValueError):
    pass


def _reject_constant(name):
    raise JsonRejected(f"constant {name}")


def depth(value):
    deepest = 0
    pending = [(value, 1)]
    while pending:
        node, level = pending.pop()
        if isinstance(node, dict):
            children = node.values()
        elif isinstance(node, list):
            children = node
        else:
            continue
        deepest = max(deepest, level)
        if deepest > MAX_DEPTH:
            return deepest
        pending.extend((child, level + 1) for child in children)
    return deepest


def loads(data):
    try:
        text = data.decode("utf-8") if isinstance(data, (bytes, bytearray)) else data
        value = json.loads(text, parse_constant=_reject_constant)
    except (UnicodeDecodeError, ValueError, RecursionError) as error:
        raise JsonRejected(str(error)) from error
    if depth(value) > MAX_DEPTH:
        raise JsonRejected("too deep")
    return value


def dumps(value, indent="\t"):
    return json.dumps(value, ensure_ascii=False, indent=indent, allow_nan=False)


def atomic_write(path, text):
    path = Path(path)
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o644
    handle, temporary = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(handle, "w", encoding="utf-8", newline="") as stream:
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    except BaseException:
        Path(temporary).unlink(missing_ok=True)
        raise
