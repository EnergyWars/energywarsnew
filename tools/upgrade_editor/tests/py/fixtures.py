import copy
import json
from pathlib import Path

TOOL_DIR = Path(__file__).resolve().parents[2]
CONFIG = TOOL_DIR.parent.parent / "src" / "core" / "game_config.gd"


def load_game():
    return json.loads((TOOL_DIR / "data" / "game.json").read_text(encoding="utf-8"))


def edited(mutator):
    document = copy.deepcopy(load_game())
    mutator(document)
    return document


def building(document, kind):
    return next(entry for entry in document["buildings"] if entry["id"] == kind)


def enemy(document, kind):
    return document["enemies"][kind]


def level(document, index=0):
    return document["levels"][index]
