import copy
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


def saved(name="A", formula="base * level", description="", **extra):
    return {"name": name, "formula": formula, "description": description, **extra}


class VariablesTest(unittest.TestCase):
    def variables(self, items):
        return codes(edited(lambda d: building(d, "solar").update(variables=items)))

    def test_valid_variables(self):
        self.assertEqual(self.variables([]), set())
        self.assertEqual(self.variables([{"name": "bonus_2", "value": 1.5, "description": ""}, {"name": "_x", "value": -3, "description": "d" * 200}]), set())
        self.assertEqual(self.variables([{"name": f"v{i}", "value": i, "description": ""} for i in range(50)]), set())

    def test_invalid_variables(self):
        def item(**changes):
            return {"name": "ok", "value": 1, "description": "", **changes}
        cases = ("x", {}, [item(name="")], [item(name="Bonus")], [item(name="1a")], [item(name="a b")], [item(name="n" * 41)], [item(name="level")],
                 [item(name="min")], [item(name="pi")], [item(), item()], [item(value="1")], [item(value=True)], [item(value=1e16)], [item(description=1)],
                 [item(description="d" * 201)], [{"name": "ok", "value": 1}], [item(extra=1)], [item(name=1)],
                 [{"name": f"v{i}", "value": i, "description": ""} for i in range(51)])
        for value in cases:
            self.assertIn("VARIABLES", self.variables(value), str(value)[:60])


class SavedFormulasTest(unittest.TestCase):
    def test_any_number_of_saved_formulas_is_valid(self):
        many = {"cost": [saved(f"n{i}") for i in range(200)]}
        self.assertEqual(codes(edited(lambda d: d.update(saved_formulas=many))), set())

    def test_saved_formulas_may_use_any_variable_name(self):
        value = {"cost": [saved("A", "base * bonus")]}
        self.assertEqual(codes(edited(lambda d: d.update(saved_formulas=value))), set())

    def test_valid_saved_formulas(self):
        value = {"cost": [saved(description="lang")], "metric": [saved("B", "level", target="efficiency")]}
        self.assertEqual(codes(edited(lambda d: d.update(saved_formulas=value))), set())
        self.assertEqual(codes(edited(lambda d: None)), set())

    def test_invalid_saved_formulas(self):
        cases = ([], {"other": []}, {"cost": "x"}, {"cost": ["x"]}, {"cost": [saved(name="  ")]}, {"cost": [saved(name="n" * 61)]},
                 {"cost": [saved(formula="")]}, {"cost": [saved(formula="please read the keys")]}, {"cost": [saved(formula="1" * 501)]},
                 {"cost": [saved(description="d" * 1001)]}, {"cost": [saved("a"), saved(" A ")]},
                 {"cost": [saved(target="value")]}, {"metric": [saved()]}, {"metric": [saved(target="other")]}, {"cost": [{"name": "a", "formula": "1"}]},
                 {"cost": [saved(name=1)]})
        for value in cases:
            self.assertIn("SAVED_FORMULAS", codes(edited(lambda d, v=value: d.update(saved_formulas=v))), str(value))


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

    def test_plan_source_is_validated(self):
        source = {"max": 2, "cost": "base * level", "target": "efficiency", "formula": "1.2"}
        table = {"mode": "table", "levels": [{"cost": 5, "gain": 0.5}], "source": source}
        self.assertEqual(codes(with_plan(table)), set())
        for broken in ("x", {**source, "max": 0}, {**source, "max": 201}, {**source, "target": "other"}, {**source, "cost": ""},
                       {**source, "formula": "read the keys"}, {**source, "extra": 1}, {k: v for k, v in source.items() if k != "cost"}, {**source, "max": 1.5}):
            self.assertIn("PLAN_FORMULA", codes(with_plan({**table, "source": broken})), str(broken))

    def test_own_variables_are_accepted_in_plan_formulas(self):
        def mutate(d):
            building(d, "solar").update(variables=[{"name": "bonus", "value": 2, "description": "x"}], plans={"output": formula_plan(cost="base * bonus", effect="bonus + level")})
        self.assertEqual(codes(edited(mutate)), set())
        self.assertIn("PLAN_FORMULA", codes(with_plan(formula_plan(cost="base * bonus"))))
        source = {"max": 1, "cost": "bonus", "target": "value", "formula": "bonus"}
        table = {"mode": "table", "levels": [{"cost": 5, "gain": 0.5}], "source": source}
        def with_source(d):
            building(d, "solar").update(variables=[{"name": "bonus", "value": 2, "description": ""}], plans={"output": table})
        self.assertEqual(codes(edited(with_source)), set())

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


class LayoutValidationTest(unittest.TestCase):
    def setUp(self):
        self.original = load_game()
        self.document = copy.deepcopy(self.original)
        self.entry = next(item for item in self.document["buildings"] if item["id"] == "solar")

    def codes(self):
        return [error["code"] for error in model.safe_validate(self.document, self.original)]

    def test_default_layout_is_valid(self):
        self.assertEqual(self.codes(), [])

    def test_custom_order_and_titles_are_valid(self):
        self.entry["layout"] = [{"title": "Eigene", "tracks": list(reversed(self.entry["tracks"]))}, {"title": "", "tracks": []}]
        self.assertEqual(self.codes(), [])

    def test_layout_must_match_tracks(self):
        self.entry["layout"] = [{"title": "x", "tracks": self.entry["tracks"][:-1]}]
        self.assertIn("LAYOUT", self.codes())
        self.entry["layout"] = [{"title": "x", "tracks": self.entry["tracks"] + self.entry["tracks"][:1]}]
        self.assertIn("LAYOUT", self.codes())

    def test_layout_shape_is_checked(self):
        tracks = self.entry["tracks"]
        for bad in ([], "x", [{"title": "x" * 61, "tracks": tracks}], [{"title": 1, "tracks": tracks}], [{"title": "x", "tracks": tracks, "extra": 1}], [{"title": "x", "tracks": [1]}], ["x"], [{"title": "g", "tracks": tracks}] + [{"title": "g", "tracks": []}] * 20):
            with self.subTest(bad=bad):
                self.entry["layout"] = bad
                self.assertIn("LAYOUT", self.codes())


class DoneValidationTest(unittest.TestCase):
    def codes(self, done):
        document = copy.deepcopy(load_game())
        if done is not None:
            document["done"] = done
        return [error["code"] for error in model.safe_validate(document, load_game())]

    def test_valid_marks(self):
        track = building(load_game(), "solar")["tracks"][0]
        self.assertEqual(self.codes(None), [])
        self.assertEqual(self.codes([]), [])
        self.assertEqual(self.codes([f"solar:{track}"]), [])

    def test_invalid_marks(self):
        track = building(load_game(), "solar")["tracks"][0]
        for bad in ("x", [1], ["solar:nope"], ["ghost:hull"], [f"solar:{track}", f"solar:{track}"], ["a:b"] * 2, [f"x{i}" for i in range(1001)]):
            with self.subTest(bad=bad):
                self.assertIn("DONE", self.codes(bad))

