import shutil
import time
from pathlib import Path

from . import model
from .safejson import atomic_write, dumps, loads
from .changes import diff
from .overrides import build_content_overrides, build_overrides, write_content_overrides
from .patcher import patch_config


CONTENT_KEYS = ("armor", "enemies", "levels", "routes")
EDITOR_KEYS = ("groups", "saved_formulas")
ARCHIVE_ATTEMPTS = 1000


def keep_editor_data(document, original):
    if isinstance(document, dict) and isinstance(original, dict):
        document.pop("formula_history", None)
        for key in EDITOR_KEYS:
            if key not in document and key in original:
                document[key] = original[key]
    return document


class MissingFile(Exception):
    pass


class ValidationFailed(Exception):
    def __init__(self, errors):
        super().__init__("validation failed")
        self.errors = errors


class DocumentStore:
    def __init__(self, data_dir, config_path, overrides_path, content_path=None):
        self.data_dir = Path(data_dir)
        self.config_path = Path(config_path)
        self.overrides_path = Path(overrides_path)
        self.content_path = Path(content_path) if content_path else self.overrides_path.with_name("content_overrides.json")
        self.original_path = self.data_dir / "game.json"
        self.edited_path = self.data_dir / "game.edited.json"
        self.archive_dir = self.data_dir / "archive"

    @staticmethod
    def _read(path):
        try:
            return loads(Path(path).read_text(encoding="utf-8"))
        except FileNotFoundError as error:
            raise MissingFile(str(path)) from error

    def load_original(self):
        return self._read(self.original_path)

    def load_active(self):
        if not self.edited_path.exists():
            return self.load_original()
        return keep_editor_data(self._read(self.edited_path), self.load_original())

    def source(self):
        return "edited" if self.edited_path.exists() else "original"

    def validate(self, document):
        return model.safe_validate(document, self.load_original())

    def changes_for(self, document):
        return diff(self.load_original(), document)

    def changes(self):
        return self.changes_for(self.load_active())

    def save_edited(self, document):
        errors = self.validate(document)
        if errors:
            raise ValidationFailed(errors)
        atomic_write(self.edited_path, dumps(document))
        return document

    def _archive_target(self, prefix):
        self.archive_dir.mkdir(parents=True, exist_ok=True)
        stamp = time.strftime("%Y%m%d-%H%M%S")
        for counter in range(ARCHIVE_ATTEMPTS):
            target = self.archive_dir / (f"{prefix}-{stamp}.json" if counter == 0 else f"{prefix}-{stamp}-{counter}.json")
            try:
                target.open("x").close()
            except FileExistsError:
                continue
            return target
        raise FileExistsError(prefix)

    def reset_edited(self):
        if not self.edited_path.exists():
            return None
        target = self._archive_target("edited")
        shutil.move(str(self.edited_path), target)
        return target

    def promote(self):
        if not self.edited_path.exists():
            return {"applied": 0, "archived": None}
        document = self.load_active()
        errors = self.validate(document)
        if errors:
            raise ValidationFailed(errors)
        changes = self.changes_for(document)
        original = self.load_original()
        patched = patch_config(self.config_path.read_text(encoding="utf-8"), document)
        overrides = dumps(build_overrides(document)) + "\n"
        content = build_content_overrides(document, original)
        document["check"] = original.get("check", {})
        for key in ("names", "categories", "starters"):
            document[key] = original.get(key, {})
        document["defaults"] = original.get("defaults") or {key: original[key] for key in CONTENT_KEYS if key in original}
        promoted = dumps(document)
        atomic_write(self.config_path, patched)
        atomic_write(self.overrides_path, overrides)
        write_content_overrides(self.content_path, content)
        archived = self._archive_target("game")
        shutil.copy(self.original_path, archived)
        atomic_write(self.original_path, promoted)
        self.edited_path.unlink()
        return {"applied": len(changes), "archived": str(archived)}
