import copy
import json
import shutil
import tempfile
import unittest
from pathlib import Path

from upgrade_editor.store import DocumentStore, MissingFile, ValidationFailed
from .fixtures import CONFIG, TOOL_DIR, building, edited, load_game


class StoreTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        data = self.tmp / "data"
        data.mkdir()
        shutil.copy(TOOL_DIR / "data" / "game.json", data / "game.json")
        self.config = self.tmp / "game_config.gd"
        shutil.copy(CONFIG, self.config)
        self.store = DocumentStore(data, self.config, self.tmp / "overrides.json")

    def test_active_is_original_until_saved(self):
        self.assertEqual(self.store.source(), "original")
        self.assertEqual(self.store.load_active(), load_game())

    def test_missing_original_raises(self):
        (self.tmp / "data" / "game.json").unlink()
        with self.assertRaises(MissingFile):
            self.store.load_original()

    def test_save_edited_switches_source(self):
        document = edited(lambda d: building(d, "solar").update(cost=50))
        self.store.save_edited(document)
        self.assertEqual(self.store.source(), "edited")
        self.assertEqual(building(self.store.load_active(), "solar")["cost"], 50)
        self.assertEqual(len(self.store.changes()), 1)

    def test_save_rejects_invalid(self):
        with self.assertRaises(ValidationFailed) as caught:
            self.store.save_edited(edited(lambda d: building(d, "solar").update(hp=0)))
        self.assertEqual(caught.exception.errors[0]["code"], "HP")
        self.assertFalse(self.store.edited_path.exists())

    def test_reset_archives_the_copy(self):
        self.assertIsNone(self.store.reset_edited())
        self.store.save_edited(edited(lambda d: building(d, "solar").update(cost=50)))
        archived = self.store.reset_edited()
        self.assertTrue(archived.exists())
        self.assertEqual(self.store.source(), "original")

    def test_promote_without_copy_does_nothing(self):
        self.assertEqual(self.store.promote()["applied"], 0)

    def test_promote_patches_config_and_replaces_original(self):
        self.store.save_edited(edited(lambda d: building(d, "solar").update(cost=50)))
        summary = self.store.promote()
        self.assertEqual(summary["applied"], 1)
        self.assertIn('"cost": 50', self.config.read_text(encoding="utf-8"))
        self.assertEqual(building(self.store.load_original(), "solar")["cost"], 50)
        self.assertIn("names", self.store.load_original())
        self.assertFalse(self.store.edited_path.exists())
        self.assertTrue(Path(summary["archived"]).exists())

    def test_promote_writes_the_overrides_file(self):
        plan = {"mode": "table", "levels": [{"cost": 5, "gain": 0.5}]}
        self.store.save_edited(edited(lambda d: building(d, "solar").update(plans={"output": plan})))
        self.store.promote()
        written = json.loads((self.tmp / "overrides.json").read_text(encoding="utf-8"))
        self.assertEqual(written["plans"]["solar"]["output"]["levels"][0]["effect"], 1.5)
        self.assertIn("plans", building(self.store.load_original(), "solar"))

    def test_promote_without_plans_writes_an_empty_overrides_file(self):
        self.store.save_edited(edited(lambda d: building(d, "solar").update(cost=50)))
        self.store.promote()
        self.assertEqual(json.loads((self.tmp / "overrides.json").read_text(encoding="utf-8"))["plans"], {})

    def test_promote_rejects_tampered_copy(self):
        broken = copy.deepcopy(load_game())
        building(broken, "solar")["hp"] = -1
        self.store.edited_path.write_text(json.dumps(broken), encoding="utf-8")
        with self.assertRaises(ValidationFailed):
            self.store.promote()
        self.assertEqual(self.config.read_text(encoding="utf-8"), CONFIG.read_text(encoding="utf-8"))


class ContentPromoteTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        data = self.tmp / "data"
        data.mkdir()
        shutil.copy(TOOL_DIR / "data" / "game.json", data / "game.json")
        self.config = self.tmp / "game_config.gd"
        shutil.copy(CONFIG, self.config)
        self.store = DocumentStore(data, self.config, self.tmp / "upgrade_overrides.json")
        self.content = self.tmp / "content_overrides.json"

    def test_default_edit_writes_no_content_file(self):
        self.store.save_edited(edited(lambda d: building(d, "solar").update(cost=50)))
        self.store.promote()
        self.assertFalse(self.content.exists())

    def test_content_edit_writes_file_and_keeps_defaults(self):
        self.store.save_edited(edited(lambda d: d["enemies"]["wasp"].update(hp=77.0)))
        self.store.promote()
        written = json.loads(self.content.read_text(encoding="utf-8"))
        self.assertEqual(written["enemies"]["wasp"]["hp"], 77.0)
        self.assertEqual(self.store.load_original()["defaults"]["enemies"]["wasp"]["hp"], load_game()["enemies"]["wasp"]["hp"])

    def test_second_apply_keeps_earlier_overrides_and_revert_removes_file(self):
        self.store.save_edited(edited(lambda d: d["enemies"]["wasp"].update(hp=77.0)))
        self.store.promote()
        self.store.save_edited(edited(lambda d: building(d, "solar").update(cost=50)) | {"enemies": self.store.load_original()["enemies"]})
        self.store.promote()
        self.assertEqual(json.loads(self.content.read_text(encoding="utf-8"))["enemies"]["wasp"]["hp"], 77.0)
        reverted = self.store.load_original()
        reverted["enemies"]["wasp"]["hp"] = load_game()["enemies"]["wasp"]["hp"]
        self.store.save_edited(reverted)
        self.store.promote()
        self.assertFalse(self.content.exists())

    def test_invalid_content_is_rejected(self):
        with self.assertRaises(ValidationFailed):
            self.store.save_edited(edited(lambda d: d["armor"].update(constant=0)))

    def test_building_armor_reaches_the_config(self):
        self.store.save_edited(edited(lambda d: building(d, "bastion").update(armor=61.0)))
        self.store.promote()
        self.assertIn('"armor": 61.0', self.config.read_text(encoding="utf-8"))
