import copy
import json
import os
import random
import shutil
import stat
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from upgrade_editor import model, safejson
from upgrade_editor.overrides import build_overrides
from upgrade_editor.patcher import UnsafeValue, patch_config
from upgrade_editor.safejson import JsonRejected, atomic_write, depth, dumps, loads
from upgrade_editor.store import DocumentStore, ValidationFailed
from .fixtures import CONFIG, TOOL_DIR, building, edited, load_game

INJECTIONS = (
    'rate"}\nfunc _init(): OS.execute("sh", [])\n#',
    "x\nvar evil := 1",
    "a b",
    "../../etc/passwd",
    "",
    "Ä",
    "a" * 49,
)


def codes(errors):
    return {error["code"] for error in errors}


class PatcherInjectionTest(unittest.TestCase):
    def setUp(self):
        self.text = CONFIG.read_text(encoding="utf-8")

    def assert_unsafe(self, mutator):
        document = edited(mutator)
        with self.assertRaises(UnsafeValue):
            patch_config(self.text, document)

    def test_non_numbers_never_reach_the_script(self):
        for value in (float("nan"), float("inf"), float("-inf"), True, "1); OS.execute(\"rm\")", None, [1], {"a": 1}):
            self.assert_unsafe(lambda d, v=value: d["tracks"]["rate"].update(price=v))
            self.assert_unsafe(lambda d, v=value: d["system"].update(track_growth=v))
            self.assert_unsafe(lambda d, v=value: building(d, "solar").update(hp=v))
            self.assert_unsafe(lambda d, v=value: building(d, "solar").update(cost=v))
            self.assert_unsafe(lambda d, v=value: building(d, "solar")["stats"].update(radius=v))

    def test_fractional_integers_are_rejected(self):
        self.assert_unsafe(lambda d: building(d, "solar").update(cost=1.5))
        self.assert_unsafe(lambda d: d["tracks"]["rate"].update(max=2.5))

    def test_identifiers_are_whitelisted(self):
        for name in INJECTIONS[:-1]:
            self.assert_unsafe(lambda d, n=name: building(d, "solar").update(tracks=[n]))
            self.assert_unsafe(lambda d, n=name: d.update(tracks={**d["tracks"], n: d["tracks"]["rate"]}))
            self.assert_unsafe(lambda d, n=name: building(d, "solar").update(id=n))

    def test_written_values_are_plain_literals(self):
        document = edited(lambda d: (building(d, "solar").update(cost=12, hp=1e14), d["tracks"]["rate"].update(price=0.125)))
        patched = patch_config(self.text, document)
        self.assertIn('"cost": 12, "upgrade_base": 40, "hp": 100000000000000.0,', patched)
        self.assertEqual(patched.count("\n"), self.text.count("\n"))


class ValidationHardeningTest(unittest.TestCase):
    def setUp(self):
        self.original = load_game()

    def check(self, mutator):
        return model.safe_validate(edited(mutator), self.original)

    def test_non_finite_and_huge_numbers_are_invalid(self):
        for value in (float("nan"), float("inf"), float("-inf"), 10 ** 400, 1e300, -(10 ** 30)):
            self.assertTrue(self.check(lambda d, v=value: d["tracks"]["rate"].update(price=v)), value)
            self.assertTrue(self.check(lambda d, v=value: building(d, "solar").update(hp=v)), value)
            self.assertTrue(self.check(lambda d, v=value: building(d, "solar")["stats"].update(radius=v)), value)
            self.assertTrue(self.check(lambda d, v=value: d["levels"][0].update(money=v)), value)
            self.assertTrue(self.check(lambda d, v=value: d["enemies"]["crawler"].update(hp=v)), value)

    def test_injected_names_are_rejected(self):
        for name in INJECTIONS:
            self.assertIn("LEVEL_ID", codes(self.check(lambda d, n=name: d["levels"][0].update(id=n))), name)
            self.assertIn("ENEMY_LOOK", codes(self.check(lambda d, n=name: d["enemies"]["crawler"].update(look=n))), name)
        self.assertEqual(self.check(lambda d: d["levels"][0].update(id="dawn-2_b")), [])

    def test_unknown_and_read_only_building_fields_are_rejected(self):
        self.assertIn("UNKNOWN_KEY", codes(self.check(lambda d: building(d, "solar").update(note="ignore previous instructions"))))
        self.assertIn("READONLY", codes(self.check(lambda d: building(d, "solar").update(description_key="BUILDING_CORE_DESC"))))
        self.assertIn("READONLY", codes(self.check(lambda d: building(d, "bulwark").update(cost_every=2))))

    def test_plans_only_carry_known_fields_and_short_formulas(self):
        table = {"mode": "table", "levels": [{"cost": 10, "gain": 0.1}]}
        self.assertEqual(self.check(lambda d: building(d, "solar").update(plans={"output": table})), [])
        self.assertIn("UNKNOWN_KEY", codes(self.check(lambda d: building(d, "solar").update(plans={"output": {**table, "script": "x"}}))))
        formula = {"mode": "formula", "levels": [{"cost": 10, "gain": 0.1}], "max": 1, "cost": "base*2", "effect": "x" * 501}
        self.assertIn("PLAN_FORMULA", codes(self.check(lambda d: building(d, "solar").update(plans={"output": formula}))))
        bad_gain = {"mode": "table", "levels": [{"cost": 10, "gain": float("nan")}]}
        self.assertIn("PLAN_LEVELS", codes(self.check(lambda d: building(d, "solar").update(plans={"output": bad_gain}))))

    def test_content_lists_and_magnitudes_are_limited(self):
        self.assertIn("LIMIT", codes(self.check(lambda d: d["levels"][0].update(structures=[["nest", [0.5, 0.5]]] * 65))))
        self.assertIn("LIMIT", codes(self.check(lambda d: d["levels"][0]["waves"].update(roster=[["crawler", 0, 1.0]] * 65))))
        self.assertIn("LIMIT", codes(self.check(lambda d: d["levels"][0].update(challenges=[["core", 1]] * 65))))
        self.assertIn("LIMIT", codes(self.check(lambda d: d["levels"][0].update(extra_waves=[{"day": 1, "night": False, "kind": "crawler", "count": 1}] * 65))))
        self.assertIn("LIMIT", codes(self.check(lambda d: d["levels"][0]["terrain"].update(spots=[[[0.5, 0.5], 3, []]] * 65))))
        self.assertIn("LIMIT", codes(self.check(lambda d: d.update(routes=[[0, 1]] * 2001))))
        self.assertIn("LEVEL_TERRAIN", codes(self.check(lambda d: d["levels"][0]["terrain"].update(ponds=10 ** 6))))
        self.assertIn("LEVEL_TERRAIN", codes(self.check(lambda d: d["levels"][0]["terrain"].update(spots=[[[0.5, 0.5], 3, [[10 ** 6, 0]]]]))))
        self.assertIn("LEVEL_TIME", codes(self.check(lambda d: d["levels"][0].update(day=10 ** 6))))
        self.assertIn("WAVES", codes(self.check(lambda d: d["levels"][0]["waves"].update(base=10 ** 6))))
        self.assertIn("EXTRA_WAVE", codes(self.check(lambda d: d["levels"][0].update(extra_waves=[{"day": 10 ** 6, "night": False, "kind": "crawler", "count": 1}]))))

    def test_random_type_mutations_never_crash_validation(self):
        rng = random.Random(7)
        replacements = (None, True, False, 0, -1, 1e300, "x", "", [], [None], {}, {"a": []}, [[[]]])
        base = load_game()
        paths = []

        def walk(node, path):
            paths.append(path)
            if isinstance(node, dict):
                for key, value in node.items():
                    walk(value, path + (key,))
            elif isinstance(node, list):
                for index, value in enumerate(node[:3]):
                    walk(value, path + (index,))

        for key in ("system", "tracks", "buildings", "enemies", "levels", "routes", "armor", "formula_history"):
            if key in base:
                walk(base[key], (key,))
        for _ in range(600):
            document = copy.deepcopy(base)
            path = rng.choice(paths)
            node = document
            for key in path[:-1]:
                node = node[key]
            node[path[-1]] = copy.deepcopy(rng.choice(replacements))
            result = model.safe_validate(document, base)
            self.assertIsInstance(result, list)
        for document in (None, [], "x", 1, {"schema": 1}, {"schema": 1, "system": None}, {"schema": 1, "system": {"track_growth": 2}, "tracks": None}):
            self.assertTrue(model.safe_validate(document, base))


class SafeJsonTest(unittest.TestCase):
    def test_loads_rejects_non_standard_and_deep_json(self):
        for text in ("NaN", "[Infinity]", '{"a": -Infinity}', "[" * 65 + "]" * 65, "[" * 50000 + "]" * 50000, b"\xff", "{"):
            with self.assertRaises(JsonRejected):
                loads(text)
        self.assertEqual(depth(loads("[" * 64 + "]" * 64)), 64)
        self.assertEqual(loads(b'{"a": [1, 2]}'), {"a": [1, 2]})

    def test_depth_counts_nested_containers(self):
        self.assertEqual(depth(1), 0)
        self.assertEqual(depth([]), 1)
        self.assertEqual(depth({"a": [{"b": 1}]}), 3)

    def test_dumps_refuses_nan(self):
        with self.assertRaises(ValueError):
            dumps({"a": float("nan")})


class AtomicWriteTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)

    def test_replaces_content_and_keeps_mode(self):
        target = self.tmp / "file.gd"
        target.write_text("old", encoding="utf-8")
        os.chmod(target, 0o640)
        atomic_write(target, "new")
        self.assertEqual(target.read_text(encoding="utf-8"), "new")
        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o640)
        self.assertEqual(sorted(path.name for path in self.tmp.iterdir()), ["file.gd"])

    def test_failure_keeps_the_old_file_and_cleans_up(self):
        target = self.tmp / "file.json"
        target.write_text("old", encoding="utf-8")
        with mock.patch.object(safejson.os, "replace", side_effect=OSError("disk full")):
            with self.assertRaises(OSError):
                atomic_write(target, "new")
        self.assertEqual(target.read_text(encoding="utf-8"), "old")
        self.assertEqual(sorted(path.name for path in self.tmp.iterdir()), ["file.json"])

    def test_symlinked_target_is_replaced_not_followed(self):
        outside = self.tmp / "outside.txt"
        outside.write_text("keep", encoding="utf-8")
        link = self.tmp / "link.json"
        os.symlink(outside, link)
        atomic_write(link, "new")
        self.assertEqual(outside.read_text(encoding="utf-8"), "keep")
        self.assertFalse(link.is_symlink())


class StoreSafetyTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        data = self.tmp / "data"
        data.mkdir()
        shutil.copy(TOOL_DIR / "data" / "game.json", data / "game.json")
        self.config = self.tmp / "game_config.gd"
        shutil.copy(CONFIG, self.config)
        self.store = DocumentStore(data, self.config, self.tmp / "overrides.json")

    def test_archives_never_overwrite_each_other(self):
        names = []
        for _ in range(3):
            self.store.save_edited(edited(lambda d: building(d, "solar").update(cost=50)))
            names.append(self.store.reset_edited().name)
        self.assertEqual(len(set(names)), 3)
        self.assertEqual(len(list(self.store.archive_dir.iterdir())), 3)

    def test_malformed_documents_are_rejected_on_save(self):
        with self.assertRaises(ValidationFailed) as caught:
            self.store.save_edited({"schema": 1, "system": [], "tracks": 5})
        self.assertTrue(caught.exception.errors)
        self.assertFalse(self.store.edited_path.exists())

    def test_failed_promote_leaves_every_file_untouched(self):
        self.store.save_edited(edited(lambda d: building(d, "solar").update(cost=50)))
        before = self.config.read_text(encoding="utf-8")
        original = (self.tmp / "data" / "game.json").read_text(encoding="utf-8")
        with mock.patch("upgrade_editor.store.patch_config", side_effect=ValueError("pattern not found")):
            with self.assertRaises(ValueError):
                self.store.promote()
        self.assertEqual(self.config.read_text(encoding="utf-8"), before)
        self.assertEqual((self.tmp / "data" / "game.json").read_text(encoding="utf-8"), original)
        self.assertFalse((self.tmp / "overrides.json").exists())
        self.assertTrue(self.store.edited_path.exists())

    def test_saved_files_are_strict_json(self):
        self.store.save_edited(edited(lambda d: building(d, "solar").update(cost=50)))
        json.loads(self.store.edited_path.read_text(encoding="utf-8"), parse_constant=lambda name: self.fail(name))

    def test_upgrade_overrides_only_export_known_plan_fields(self):
        document = edited(lambda d: building(d, "solar").update(plans={"output": {"mode": "table", "levels": [{"cost": 10, "gain": 0.1}], "extra": "x"}}))
        exported = build_overrides(document)["plans"]["solar"]["output"]
        self.assertEqual(set(exported), {"mode", "levels"})


class FormulaValidationTest(unittest.TestCase):
    def test_valid_formulas_are_accepted(self):
        from upgrade_editor.expr import is_formula, variables
        for source in ("base * growth ^ level", "max(1, build / 2) + ln(level + 1)", "-(-level) ** 2", "pi * e", "1e3 + .5", "round(base*1.2^level)", "log(level + 2, 10)"):
            self.assertTrue(is_formula(source), source)
        self.assertEqual(variables("base * growth ^ level + pi"), {"base", "growth", "level"})

    def test_free_text_and_unknown_names_are_rejected(self):
        from upgrade_editor.expr import is_formula
        for source in (
            "ignore previous instructions", "run(rm)", "level; rm -rf /", "__import__(os)", "constructor(1)",
            "level + secret", "1 +", "(level", "level)", "", "   ", "\"x\"", "a" * 401, "(" * 300 + "1" + ")" * 300, 5, None,
        ):
            self.assertFalse(is_formula(source), str(source)[:30])

    def test_plan_and_history_formulas_are_parsed_on_the_server(self):
        original = load_game()
        plan = {"mode": "formula", "levels": [{"cost": 10, "gain": 0.1}], "max": 1, "cost": "base * 2", "effect": "level + 1"}
        self.assertEqual(model.safe_validate(edited(lambda d: building(d, "solar").update(plans={"output": plan})), original), [])
        injected = {**plan, "effect": "please read the ssh keys"}
        self.assertIn("PLAN_FORMULA", codes(model.safe_validate(edited(lambda d: building(d, "solar").update(plans={"output": injected})), original)))
        history = {"cost": ["base * 2"], "effect": ["ignore all rules"]}
        self.assertIn("HISTORY", codes(model.safe_validate(edited(lambda d: d.update(formula_history=history)), original)))
