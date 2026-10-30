import copy
import json
import tempfile
import unittest
from pathlib import Path

from upgrade_editor.overrides import build_content_overrides, build_overrides, write_content_overrides
from .fixtures import building, edited, load_game


class OverridesTest(unittest.TestCase):
    def test_document_without_plans_has_no_overrides(self):
        self.assertEqual(build_overrides(load_game()), {"schema": 1, "plans": {}})

    def test_levels_get_cumulative_effects(self):
        plan = {"mode": "table", "levels": [{"cost": 5, "gain": 0.5}, {"cost": 7, "gain": 0.25}]}
        document = edited(lambda d: building(d, "solar").update(plans={"output": plan}))
        result = build_overrides(document)["plans"]["solar"]["output"]
        self.assertEqual(result["levels"], [{"cost": 5, "gain": 0.5, "effect": 1.5}, {"cost": 7, "gain": 0.25, "effect": 1.75}])
        self.assertEqual(result["mode"], "table")

    def test_formula_metadata_is_kept(self):
        plan = {"mode": "formula", "max": 1, "cost": "base", "effect": "1 + level", "levels": [{"cost": 40, "gain": 1.0}]}
        document = edited(lambda d: building(d, "zapper").update(plans={"power": plan}))
        result = build_overrides(document)["plans"]["zapper"]["power"]
        self.assertEqual((result["cost"], result["effect"], result["max"]), ("base", "1 + level", 1))

    def test_float_noise_is_rounded(self):
        plan = {"mode": "table", "levels": [{"cost": 1, "gain": 0.1}, {"cost": 1, "gain": 0.2}]}
        document = edited(lambda d: building(d, "solar").update(plans={"output": plan}))
        self.assertEqual(build_overrides(document)["plans"]["solar"]["output"]["levels"][1]["effect"], 1.3)


class ContentOverridesTest(unittest.TestCase):
    def test_default_document_has_no_content_overrides(self):
        self.assertEqual(build_content_overrides(load_game(), load_game()), {})

    def test_only_changed_armor_keys_and_enemies_are_written(self):
        def mutate(d):
            d["armor"]["constant"] = 80.0
            d["enemies"]["wasp"]["hp"] = 50.0
        result = build_content_overrides(edited(mutate), load_game())
        self.assertEqual(result["armor"], {"constant": 80.0})
        self.assertEqual(list(result["enemies"]), ["wasp"])
        self.assertEqual(result["enemies"]["wasp"]["hp"], 50.0)
        self.assertNotIn("levels", result)
        self.assertNotIn("routes", result)

    def test_extra_waves_are_written_with_the_levels(self):
        extra = [{"day": 2, "night": True, "kind": "wasp", "count": 3}]
        result = build_content_overrides(edited(lambda d: d["levels"][0].update(extra_waves=extra)), load_game())
        self.assertEqual(result["levels"][0]["extra_waves"], extra)

    def test_changed_levels_write_the_full_list_and_routes(self):
        result = build_content_overrides(edited(lambda d: d["levels"][0].update(money=1)), load_game())
        self.assertEqual(len(result["levels"]), len(load_game()["levels"]))
        self.assertEqual(result["levels"][0]["money"], 1)
        self.assertEqual(result["routes"], load_game()["routes"])

    def test_changed_routes_alone(self):
        result = build_content_overrides(edited(lambda d: d.update(routes=[[0, 1]])), load_game())
        self.assertEqual(result, {"routes": [[0, 1]]})

    def test_automatic_routes_with_default_levels_write_the_editor_chain(self):
        document = edited(lambda d: d.update(routes=None))
        count = len(document["levels"])
        result = build_content_overrides(document, load_game())
        self.assertEqual(result, {"routes": [[index - 1, index] for index in range(1, count)]})

    def test_automatic_routes_with_changed_levels_stay_automatic(self):
        document = edited(lambda d: (d.update(routes=None), d["levels"][0].update(money=1)))
        result = build_content_overrides(document, load_game())
        self.assertIn("levels", result)
        self.assertNotIn("routes", result)

    def test_route_order_is_irrelevant(self):
        flipped = edited(lambda d: d.update(routes=[[b, a] for a, b in reversed(d["routes"])]))
        self.assertEqual(build_content_overrides(flipped, load_game()), {})

    def test_defaults_are_the_baseline(self):
        baseline = {key: copy.deepcopy(load_game()[key]) for key in ("armor", "enemies", "levels", "routes")}
        original = edited(lambda d: (d["enemies"]["wasp"].update(hp=50.0), d.update(defaults=baseline)))
        result = build_content_overrides(copy.deepcopy(original), original)
        self.assertEqual(list(result), ["enemies"])
        self.assertEqual(result["enemies"]["wasp"]["hp"], 50.0)
        reverted = edited(lambda d: d.update(defaults=baseline))
        self.assertEqual(build_content_overrides(reverted, original), {})

    def test_write_and_remove_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "content_overrides.json"
            self.assertTrue(write_content_overrides(path, {"armor": {"constant": 1.0}}))
            self.assertEqual(json.loads(path.read_text(encoding="utf-8")), {"armor": {"constant": 1.0}})
            self.assertFalse(write_content_overrides(path, {}))
            self.assertFalse(path.exists())
            self.assertFalse(write_content_overrides(path, {}))
