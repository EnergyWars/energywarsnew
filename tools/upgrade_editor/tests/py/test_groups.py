import json
import shutil
import tempfile
import unittest
from pathlib import Path

from upgrade_editor import model
from upgrade_editor.changes import diff
from upgrade_editor.overrides import build_content_overrides, build_overrides
from upgrade_editor.patcher import patch_config
from upgrade_editor.store import EDITOR_KEYS, DocumentStore, ValidationFailed, keep_editor_data
from .fixtures import CONFIG, TOOL_DIR, building, edited, load_game

ZAP = "zapper:power"
LASER = "laser:power"
SOLAR = "solar:output"


def sample_groups():
    return [
        {"name": "Offensive", "items": [ZAP], "sections": [{"name": "Schaden", "items": [ZAP, LASER]}, {"name": "Reichweite", "items": ["zapper:range"]}]},
        {"name": "Wirtschaft", "items": [], "sections": [{"name": "Energie", "items": [SOLAR, ZAP]}]},
    ]


def with_groups(groups):
    return edited(lambda d: d.update(groups=groups))


def errors(document):
    return [error for error in model.validate(document, load_game()) if error["code"].startswith("GROUP")]


def pairs(document):
    return {(error["code"], error["path"]) for error in errors(document)}


class GroupModelTest(unittest.TestCase):
    def test_documents_without_or_with_valid_groups_pass(self):
        self.assertEqual(model.validate(load_game(), load_game()), [])
        self.assertEqual(model.validate(with_groups(sample_groups()), load_game()), [])
        self.assertEqual(model.validate(with_groups([]), load_game()), [])
        self.assertEqual(model.validate(with_groups(None), load_game()), [])
        self.assertEqual(model.validate(with_groups([{"name": "Leer"}]), load_game()), [])

    def test_one_upgrade_may_be_in_many_areas_and_subheadings(self):
        groups = [{"name": f"Bereich {index}", "items": [ZAP], "sections": [{"name": "A", "items": [ZAP]}, {"name": "B", "items": [ZAP]}]} for index in range(5)]
        self.assertEqual(errors(with_groups(groups)), [])

    def test_structure_errors(self):
        cases = {
            ("GROUPS", "groups"): {"Offensive": []},
            ("GROUPS", "groups.0"): ["Offensive"],
            ("GROUPS", "groups.0.items"): [{"name": "A", "items": "zapper:power"}],
            ("GROUPS", "groups.0.sections"): [{"name": "A", "sections": {"name": "B"}}],
            ("GROUPS", "groups.0.sections.0"): [{"name": "A", "sections": [{"name": "B", "colour": "red"}]}],
        }
        for expected, groups in cases.items():
            with self.subTest(expected=expected):
                self.assertIn(expected, pairs(with_groups(groups)))
        self.assertIn(("GROUPS", "groups.0"), pairs(with_groups([{"name": "A", "extra": 1}])))

    def test_limits(self):
        self.assertIn(("GROUPS", "groups"), pairs(with_groups([{"name": f"A{index}"} for index in range(model.GROUP_AREA_LIMIT + 1)])))
        self.assertIn(("GROUPS", "groups.0.sections"), pairs(with_groups([{"name": "A", "sections": [{"name": f"S{index}"} for index in range(model.GROUP_SECTION_LIMIT + 1)]}])))
        self.assertIn(("GROUPS", "groups.0.items"), pairs(with_groups([{"name": "A", "items": [ZAP] * (model.GROUP_ITEM_LIMIT + 1)}])))
        self.assertEqual(errors(with_groups([{"name": f"A{index}"} for index in range(model.GROUP_AREA_LIMIT)])), [])

    def test_names(self):
        for name in (None, "", "   ", 7, "x" * (model.GROUP_NAME_LIMIT + 1)):
            with self.subTest(name=name):
                self.assertIn(("GROUP_NAME", "groups.0.name"), pairs(with_groups([{"name": name}])))
        self.assertIn(("GROUP_NAME", "groups.0.sections.0.name"), pairs(with_groups([{"name": "A", "sections": [{"items": []}]}])))
        self.assertIn(("GROUP_NAME", "groups.0.name"), pairs(with_groups([{"items": []}])))
        self.assertEqual(errors(with_groups([{"name": "x" * model.GROUP_NAME_LIMIT}])), [])

    def test_duplicates(self):
        self.assertIn(("GROUP_DUPLICATE", "groups.1.name"), pairs(with_groups([{"name": "Offensive"}, {"name": " offensive "}])))
        self.assertIn(("GROUP_DUPLICATE", "groups.0.sections.1.name"), pairs(with_groups([{"name": "A", "sections": [{"name": "B"}, {"name": "b"}]}])))
        self.assertIn(("GROUP_DUPLICATE", "groups.0.items.1"), pairs(with_groups([{"name": "A", "items": [ZAP, ZAP]}])))
        self.assertIn(("GROUP_DUPLICATE", "groups.0.sections.0.items.1"), pairs(with_groups([{"name": "A", "sections": [{"name": "B", "items": [LASER, LASER]}]}])))
        self.assertEqual(errors(with_groups([{"name": "A", "sections": [{"name": "B"}]}, {"name": "C", "sections": [{"name": "B"}]}])), [])

    def test_unknown_upgrades(self):
        for item in ("ghost:power", "solar:power", "zapper:", "zapper", 3, None, {"id": ZAP}):
            with self.subTest(item=item):
                self.assertIn(("GROUP_ITEM", "groups.0.items.0"), pairs(with_groups([{"name": "A", "items": [item]}])))
        self.assertIn(("GROUP_ITEM", "groups.0.sections.0.items.0"), pairs(with_groups([{"name": "A", "sections": [{"name": "B", "items": ["laser:chain"]}]}])))

    def test_items_follow_the_track_list_of_the_document(self):
        def drop_power(document):
            building(document, "zapper")["tracks"].remove("power")
            document["groups"] = [{"name": "A", "items": [ZAP]}]

        self.assertIn(("GROUP_ITEM", "groups.0.items.0"), pairs(edited(drop_power)))

        def add_chain(document):
            building(document, "solar")["tracks"].append("chain")
            document["groups"] = [{"name": "A", "items": ["solar:chain"]}]

        self.assertEqual(errors(edited(add_chain)), [])


class GroupChangesTest(unittest.TestCase):
    def test_group_edits_are_listed(self):
        paths = {change["path"]: change for change in diff(load_game(), with_groups(sample_groups()))}
        self.assertEqual(paths["groups.order"]["after"], ["Offensive", "Wirtschaft"])
        self.assertEqual(paths["groups.Offensive.items"]["after"], [ZAP])
        self.assertEqual(paths["groups.Offensive.sections"]["after"], ["Schaden", "Reichweite"])
        self.assertEqual(paths["groups.Offensive.section.Schaden"]["after"], [ZAP, LASER])
        self.assertIsNone(paths["groups.order"]["before"])

    def test_empty_or_missing_groups_are_no_change(self):
        self.assertEqual(diff(load_game(), with_groups([])), [])
        self.assertEqual(diff(load_game(), with_groups(None)), [])
        self.assertEqual(diff(load_game(), with_groups(["kaputt"])), [])

    def test_reordering_is_a_change(self):
        reordered = sample_groups()
        reordered.reverse()
        self.assertEqual([change["path"] for change in diff(with_groups(sample_groups()), with_groups(reordered))], ["groups.order"])
        moved = sample_groups()
        moved[0]["sections"][0]["items"].reverse()
        self.assertEqual([change["path"] for change in diff(with_groups(sample_groups()), with_groups(moved))], ["groups.Offensive.section.Schaden"])


class GroupsStayInTheEditorTest(unittest.TestCase):
    def test_groups_never_reach_the_game_files(self):
        document = with_groups(sample_groups())
        self.assertNotIn("Offensive", json.dumps(build_overrides(document)))
        self.assertNotIn("Offensive", json.dumps(build_content_overrides(document, load_game())))
        source = CONFIG.read_text(encoding="utf-8")
        self.assertEqual(patch_config(source, document), patch_config(source, load_game()))

    def test_keep_editor_data_fills_only_missing_keys(self):
        self.assertEqual(EDITOR_KEYS, ("groups", "saved_formulas"))
        original = {"groups": sample_groups()}
        self.assertEqual(keep_editor_data({}, original)["groups"], sample_groups())
        self.assertEqual(keep_editor_data({"groups": []}, original)["groups"], [])
        self.assertEqual(keep_editor_data({}, {}), {})
        self.assertEqual(keep_editor_data([], original), [])


class GroupStoreTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.data = self.tmp / "data"
        self.data.mkdir()
        shutil.copy(TOOL_DIR / "data" / "game.json", self.data / "game.json")
        self.config = self.tmp / "game_config.gd"
        shutil.copy(CONFIG, self.config)
        self.store = DocumentStore(self.data, self.config, self.tmp / "upgrade_overrides.json")

    def test_saving_keeps_groups_in_the_copy(self):
        self.store.save_edited(with_groups(sample_groups()))
        self.assertEqual(self.store.load_active()["groups"], sample_groups())
        self.assertIn("groups.order", {change["path"] for change in self.store.changes()})

    def test_invalid_groups_are_rejected_on_save(self):
        with self.assertRaises(ValidationFailed) as caught:
            self.store.save_edited(with_groups([{"name": "A", "items": ["ghost:power"]}]))
        self.assertEqual(caught.exception.errors[0]["code"], "GROUP_ITEM")
        self.assertFalse(self.store.edited_path.exists())

    def test_promote_keeps_groups_in_the_new_original(self):
        self.store.save_edited(with_groups(sample_groups()))
        self.store.promote()
        self.assertEqual(self.store.load_original()["groups"], sample_groups())
        self.assertNotIn("Offensive", (self.tmp / "upgrade_overrides.json").read_text(encoding="utf-8"))
        self.assertEqual(self.config.read_text(encoding="utf-8"), CONFIG.read_text(encoding="utf-8"))

    def test_an_older_copy_without_groups_takes_them_from_the_original(self):
        original = load_game()
        original["groups"] = sample_groups()
        self.store.original_path.write_text(json.dumps(original), encoding="utf-8")
        copy = edited(lambda d: building(d, "solar").update(cost=50))
        self.store.edited_path.write_text(json.dumps(copy), encoding="utf-8")
        self.assertEqual(self.store.load_active()["groups"], sample_groups())
        self.store.promote()
        promoted = self.store.load_original()
        self.assertEqual(promoted["groups"], sample_groups())
        self.assertEqual(building(promoted, "solar")["cost"], 50)

    def test_deleting_all_groups_in_the_copy_wins(self):
        original = load_game()
        original["groups"] = sample_groups()
        self.store.original_path.write_text(json.dumps(original), encoding="utf-8")
        self.store.save_edited(with_groups([]))
        self.store.promote()
        self.assertEqual(self.store.load_original()["groups"], [])


class ExportKeepsGroupsTest(unittest.TestCase):
    def test_export_script_carries_groups_over(self):
        script = (TOOL_DIR / "export_game.gd").read_text(encoding="utf-8")
        self.assertIn("func _keep_groups(", script)
        self.assertIn('document["groups"] = kept', script)
        self.assertIn("var previous := _load_previous()", script)
        self.assertLess(script.index("_keep_groups(document, previous)"), script.index("FileAccess.open(OUTPUT, FileAccess.WRITE)"))
        self.assertIn("known.has(item)", script)


class SavedFormulasKeptTest(unittest.TestCase):
    def test_keep_editor_data_restores_missing_saved_formulas_and_drops_the_old_history(self):
        original = {"saved_formulas": {"cost": [{"name": "a", "formula": "base", "description": ""}]}}
        self.assertEqual(keep_editor_data({}, original)["saved_formulas"], original["saved_formulas"])
        self.assertEqual(keep_editor_data({"saved_formulas": {"cost": []}}, original)["saved_formulas"], {"cost": []})
        self.assertNotIn("formula_history", keep_editor_data({"formula_history": {"cost": ["x"]}}, original))

    def test_export_script_carries_the_saved_formulas_over(self):
        script = (TOOL_DIR / "export_game.gd").read_text(encoding="utf-8")
        self.assertIn("func _keep_saved_formulas(", script)
        self.assertIn('document["saved_formulas"] = kept', script)
        self.assertLess(script.index("_keep_saved_formulas(document, previous)"), script.index("FileAccess.open(OUTPUT, FileAccess.WRITE)"))
        self.assertNotIn("SAVED_LIMIT", script)
        self.assertIn("func _keep_plan_sources(", script)
        self.assertIn("func _keep_variables(", script)
        self.assertLess(script.index("_keep_plan_sources(document, previous)"), script.index("FileAccess.open(OUTPUT, FileAccess.WRITE)"))
        self.assertIn("SAVED_DESCRIPTION_LIMIT := 1000", script)
