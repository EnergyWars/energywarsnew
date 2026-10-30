import unittest

from upgrade_editor import model
from .fixtures import building, edited, load_game


def codes(document):
    return {error["code"] for error in model.validate(document, load_game())}


class ModelTest(unittest.TestCase):
    def test_game_document_is_valid(self):
        self.assertEqual(model.validate(load_game(), load_game()), [])

    def test_schema_must_match(self):
        self.assertEqual(codes(edited(lambda d: d.update(schema=2))), {"SCHEMA"})
        self.assertEqual(model.validate([], load_game())[0]["code"], "SCHEMA")

    def test_track_growth_must_exceed_one(self):
        self.assertIn("GROWTH", codes(edited(lambda d: d["system"].update(track_growth=1.0))))

    def test_track_set_is_fixed(self):
        self.assertEqual(codes(edited(lambda d: d["tracks"].pop("rate"))), {"TRACK_SET"})

    def test_track_values(self):
        cases = {
            "MAX": lambda d: d["tracks"]["rate"].update(max=0),
            "PRICE": lambda d: d["tracks"]["rate"].update(price=0),
            "POSITIVE": lambda d: d["tracks"]["rate"].update(step=-1),
            "GROWTH": lambda d: d["tracks"]["links"].update(growth=1),
            "UNKNOWN_KEY": lambda d: d["tracks"]["rate"].update(bogus=1),
            "MISSING": lambda d: d["tracks"]["rate"].pop("step"),
            "TYPE": lambda d: d["tracks"].update(rate=3),
        }
        for code, mutator in cases.items():
            with self.subTest(code=code):
                self.assertIn(code, codes(edited(mutator)))

    def test_max_must_be_integer(self):
        self.assertIn("MAX", codes(edited(lambda d: d["tracks"]["rate"].update(max=2.5))))
        self.assertIn("MAX", codes(edited(lambda d: d["tracks"]["rate"].update(max=True))))

    def test_building_set_is_fixed(self):
        self.assertEqual(codes(edited(lambda d: d["buildings"].pop())), {"BUILDING_SET"})

    def test_building_values(self):
        cases = {
            "COST": lambda d: building(d, "solar").update(cost=-1),
            "UPGRADE_BASE": lambda d: building(d, "solar").update(upgrade_base=0),
            "HP": lambda d: building(d, "solar").update(hp=0),
            "TRACKS": lambda d: building(d, "solar").update(tracks=["output", "output"]),
        }
        for code, mutator in cases.items():
            with self.subTest(code=code):
                self.assertIn(code, codes(edited(mutator)))

    def test_unknown_track_in_building_is_rejected(self):
        self.assertIn("TRACKS", codes(edited(lambda d: building(d, "solar").update(tracks=["nope"]))))

    def test_curves(self):
        self.assertIn("CURVE_SET", codes(edited(lambda d: building(d, "bulwark").update(curves={}))))
        self.assertIn("CURVE_TRACK", codes(edited(lambda d: building(d, "bulwark").update(tracks=[]))))
        self.assertIn("MISSING", codes(edited(lambda d: building(d, "bulwark")["curves"]["hull"].pop("gain_growth"))))


class StatsTest(unittest.TestCase):
    def test_stat_set_is_fixed(self):
        self.assertIn("STAT_SET", codes(edited(lambda d: building(d, "solar")["stats"].pop("radius"))))
        self.assertIn("STAT_SET", codes(edited(lambda d: building(d, "zapper")["stats"]["attack"].pop("damage"))))
        self.assertIn("STAT_SET", codes(edited(lambda d: building(d, "solar").pop("stats"))))

    def test_stat_values(self):
        self.assertIn("STAT", codes(edited(lambda d: building(d, "solar")["stats"].update(radius=-1))))
        self.assertIn("STAT", codes(edited(lambda d: building(d, "solar")["stats"].update(links=1.5))))
        self.assertIn("STAT", codes(edited(lambda d: building(d, "zapper")["stats"]["attack"].update(damage="x"))))
        self.assertEqual(codes(edited(lambda d: building(d, "solar")["stats"].update(radius=30))), set())


class HistoryTest(unittest.TestCase):
    def test_valid_history(self):
        self.assertEqual(codes(edited(lambda d: d.update(formula_history={"cost": ["base * level"], "effect": []}))), set())
        self.assertEqual(codes(edited(lambda d: None)), set())

    def test_invalid_history(self):
        for history in ([], {"other": []}, {"cost": "x"}, {"cost": [""]}, {"cost": [1]}, {"cost": ["a", "a"]}, {"cost": ["a"] * 2}, {"cost": [str(i) for i in range(31)]}, {"effect": ["x" * 501]}):
            self.assertIn("HISTORY", codes(edited(lambda d, h=history: d.update(formula_history=h))), str(history))


def formula_plan(**changes):
    plan = {"mode": "formula", "max": 2, "cost": "base * level", "effect": "1 + 0.1 * level", "levels": [{"cost": 1, "gain": 0.1}, {"cost": 2, "gain": 0.1}]}
    plan.update(changes)
    return plan


def with_plan(plan, kind="solar", track="output"):
    return edited(lambda d: building(d, kind).update(plans={track: plan}))


class PlansTest(unittest.TestCase):
    def test_valid_formula_and_table_plans(self):
        self.assertEqual(codes(with_plan(formula_plan())), set())
        table = {"mode": "table", "levels": [{"cost": 5, "gain": 0.5}]}
        self.assertEqual(codes(with_plan(table)), set())

    def test_plan_needs_a_listed_track(self):
        self.assertIn("PLAN_TRACK", codes(with_plan(formula_plan(), track="crit")))

    def test_plan_shape(self):
        self.assertIn("PLAN", codes(with_plan({"mode": "magic", "levels": []})))
        self.assertIn("PLAN", codes(with_plan("x")))
        self.assertIn("PLAN", codes(edited(lambda d: building(d, "solar").update(plans=[]))))

    def test_levels_must_be_valid(self):
        self.assertIn("PLAN_LEVELS", codes(with_plan(formula_plan(levels=[], max=0))))
        self.assertIn("PLAN_LEVELS", codes(with_plan(formula_plan(levels=[{"cost": 0, "gain": 1}, {"cost": 1, "gain": 1}]))))
        self.assertIn("PLAN_LEVELS", codes(with_plan(formula_plan(levels=[{"cost": 1.5, "gain": 1}, {"cost": 1, "gain": 1}]))))
        self.assertIn("PLAN_LEVELS", codes(with_plan(formula_plan(levels=[{"cost": 1}, {"cost": 1, "gain": 1}]))))
        self.assertIn("PLAN_LEVELS", codes(with_plan(formula_plan(levels=[{"cost": 1, "gain": 0.1}] * 201, max=201))))

    def test_formula_fields(self):
        self.assertIn("PLAN_FORMULA", codes(with_plan(formula_plan(cost=" "))))
        self.assertIn("PLAN_FORMULA", codes(with_plan(formula_plan(effect=3))))
        self.assertIn("PLAN_FORMULA", codes(with_plan(formula_plan(max=5))))
