import json
import shutil
import time
from pathlib import Path

from . import model
from .changes import diff
from .overrides import build_overrides
from .patcher import patch_config


class MissingFile(Exception):
    pass


class ValidationFailed(Exception):
    def __init__(self, errors):
        super().__init__("validation failed")
        self.errors = errors


class DocumentStore:
    def __init__(self, data_dir, config_path, overrides_path):
        self.data_dir = Path(data_dir)
        self.config_path = Path(config_path)
        self.overrides_path = Path(overrides_path)
        self.original_path = self.data_dir / "game.json"
        self.edited_path = self.data_dir / "game.edited.json"
        self.archive_dir = self.data_dir / "archive"

    @staticmethod
    def _read(path):
        try:
            return json.loads(Path(path).read_text(encoding="utf-8"))
        except FileNotFoundError as error:
            raise MissingFile(str(path)) from error

    def load_original(self):
        return self._read(self.original_path)

    def load_active(self):
        return self._read(self.edited_path) if self.edited_path.exists() else self.load_original()

    def source(self):
        return "edited" if self.edited_path.exists() else "original"

    def validate(self, document):
        return model.validate(document, self.load_original())

    def changes_for(self, document):
        return diff(self.load_original(), document)

    def changes(self):
        return self.changes_for(self.load_active())

    def save_edited(self, document):
        errors = self.validate(document)
        if errors:
            raise ValidationFailed(errors)
        self.edited_path.write_text(json.dumps(document, ensure_ascii=False, indent="\t"), encoding="utf-8")
        return document

    def reset_edited(self):
        if not self.edited_path.exists():
            return None
        self.archive_dir.mkdir(parents=True, exist_ok=True)
        target = self.archive_dir / f"edited-{time.strftime('%Y%m%d-%H%M%S')}.json"
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
        patched = patch_config(self.config_path.read_text(encoding="utf-8"), document)
        self.config_path.write_text(patched, encoding="utf-8")
        self.overrides_path.write_text(json.dumps(build_overrides(document), ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")
        self.archive_dir.mkdir(parents=True, exist_ok=True)
        archived = self.archive_dir / f"game-{time.strftime('%Y%m%d-%H%M%S')}.json"
        shutil.copy(self.original_path, archived)
        original = self.load_original()
        document["check"] = original.get("check", {})
        for key in ("names", "categories", "starters"):
            document[key] = original.get(key, {})
        self.original_path.write_text(json.dumps(document, ensure_ascii=False, indent="\t"), encoding="utf-8")
        self.edited_path.unlink()
        return {"applied": len(changes), "archived": str(archived)}
