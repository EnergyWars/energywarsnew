import unittest

from upgrade_editor.overrides import build_overrides
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
