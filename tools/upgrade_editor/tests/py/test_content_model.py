import copy
import unittest

from upgrade_editor import model
from .fixtures import building, edited, enemy, level, load_game


def codes(document):
    return {error["code"] for error in model.validate(document, load_game())}


def new_level(document, identifier="fresh"):
    created = copy.deepcopy(level(document))
    created["id"] = identifier
    created["world"] = None
    return created


class ArmorTest(unittest.TestCase):
    def test_exported_content_is_valid(self):
        self.assertEqual(model.validate(load_game(), load_game()), [])

    def test_armor_rules(self):
        cases = {
            "ARMOR_CONSTANT": lambda d: d["armor"].update(constant=0),
            "ARMOR_REDUCTION": lambda d: d["armor"].update(max_reduction=1),
            "ARMOR": lambda d: d["armor"].update(min_damage=-1),
        }
        for code, mutator in cases.items():
            with self.subTest(code=code):
                self.assertIn(code, codes(edited(mutator)))

    def test_armor_edge_values(self):
        self.assertEqual(codes(edited(lambda d: d["armor"].update(max_reduction=0, min_damage=0))), set())
        self.assertIn("ARMOR_REDUCTION", codes(edited(lambda d: d["armor"].update(max_reduction=-0.1))))

    def test_armor_shape(self):
        self.assertIn("ARMOR", codes(edited(lambda d: d["armor"].pop("constant"))))
        self.assertIn("ARMOR", codes(edited(lambda d: d["armor"].update(extra=1))))
        self.assertIn("ARMOR", codes(edited(lambda d: d.update(armor=3))))
        self.assertIn("ARMOR", codes(edited(lambda d: d["armor"].update(constant="a"))))

    def test_building_armor(self):
        self.assertEqual(codes(edited(lambda d: building(d, "solar").update(armor=0))), set())
        self.assertIn("ARMOR", codes(edited(lambda d: building(d, "solar").update(armor=-1))))
        self.assertIn("ARMOR", codes(edited(lambda d: building(d, "solar").update(armor="x"))))

    def test_missing_sections_are_reported(self):
        self.assertIn("MISSING", codes(edited(lambda d: d.pop("enemies"))))

    def test_documents_without_content_sections_stay_valid(self):
        legacy = {key: value for key, value in load_game().items() if key not in ("armor", "enemies", "levels", "routes", "defaults")}
        self.assertEqual(model.validate(legacy, legacy), [])


class EnemyTest(unittest.TestCase):
    def test_enemy_set_is_fixed(self):
        self.assertIn("ENEMY_SET", codes(edited(lambda d: d["enemies"].pop("wasp"))))
        self.assertIn("ENEMY_SET", codes(edited(lambda d: d["enemies"].update(ghost=copy.deepcopy(d["enemies"]["wasp"])))))

    def test_enemy_rules(self):
        cases = {
            "ENEMY_CLASS": lambda d: enemy(d, "wasp").update({"class": "boat"}),
            "ENEMY_FACTION": lambda d: enemy(d, "wasp").update(faction="river"),
            "ENEMY_LOOK": lambda d: enemy(d, "wasp").update(look=""),
            "ENEMY_NUMBER": lambda d: enemy(d, "wasp").update(hp=0),
            "ENEMY_FLAG": lambda d: enemy(d, "wasp").update(boss="yes"),
            "ENEMY_BUFFS": lambda d: enemy(d, "wasp").update(buffs={"dawn": {}}),
            "MISSING": lambda d: enemy(d, "wasp").pop("speed"),
            "UNKNOWN_KEY": lambda d: enemy(d, "wasp").update(wings=2),
            "TYPE": lambda d: d["enemies"].update(wasp=5),
        }
        for code, mutator in cases.items():
            with self.subTest(code=code):
                self.assertIn(code, codes(edited(mutator)))

    def test_number_ranges(self):
        for key in ("hp", "speed", "radius", "cooldown"):
            with self.subTest(key=key):
                self.assertIn("ENEMY_NUMBER", codes(edited(lambda d: enemy(d, "wasp").update({key: 0}))))
        for key in ("damage", "reach", "armor", "bounty"):
            with self.subTest(key=key):
                self.assertIn("ENEMY_NUMBER", codes(edited(lambda d: enemy(d, "wasp").update({key: -1}))))
                self.assertEqual(codes(edited(lambda d: enemy(d, "wasp").update({key: 0}))), set())
        self.assertIn("ENEMY_NUMBER", codes(edited(lambda d: enemy(d, "wasp").update(bounty=1.5))))

    def test_buffs_structure(self):
        self.assertEqual(codes(edited(lambda d: enemy(d, "wasp").update(buffs={"night": {"hp": 0.2}}))), set())
        self.assertEqual(codes(edited(lambda d: enemy(d, "wasp").update(buffs={}))), set())
        self.assertIn("ENEMY_BUFFS", codes(edited(lambda d: enemy(d, "wasp").update(buffs={"night": {"luck": 1}}))))
        self.assertIn("ENEMY_BUFFS", codes(edited(lambda d: enemy(d, "wasp").update(buffs={"night": {"hp": -1}}))))
        self.assertIn("ENEMY_BUFFS", codes(edited(lambda d: enemy(d, "wasp").update(buffs={"level": []}))))
        self.assertIn("ENEMY_BUFFS", codes(edited(lambda d: enemy(d, "wasp").update(buffs=[]))))

    def test_all_classes_and_factions_are_allowed(self):
        for value in ("air", "ranged", "melee"):
            self.assertEqual(codes(edited(lambda d: enemy(d, "wasp").update({"class": value}))), set())
        for value in ("nest", "camp"):
            self.assertEqual(codes(edited(lambda d: enemy(d, "wasp").update(faction=value))), set())


class LevelTest(unittest.TestCase):
    def test_level_rules(self):
        cases = {
            "LEVEL_ID": lambda d: level(d).update(id=" "),
            "LEVEL_CELLS": lambda d: level(d).update(cells=[5, 5]),
            "LEVEL_MONEY": lambda d: level(d).update(money=-1),
            "LEVEL_TIME": lambda d: level(d).update(day=0),
            "LEVEL_SEED": lambda d: level(d).update(seed=1.5),
            "LEVEL_POSITION": lambda d: level(d).update(drop=[2, 0.5]),
            "LEVEL_STRUCTURE": lambda d: level(d).update(structures=[["tower", [0.5, 0.5]]]),
            "LEVEL_TERRAIN": lambda d: level(d)["terrain"].update(rocks=-1),
            "WAVES": lambda d: level(d)["waves"].update(interval=0),
            "WAVE_ROSTER": lambda d: level(d)["waves"].update(roster=[["ghost", 0, 1.0]]),
            "CHALLENGE": lambda d: level(d).update(challenges=[["nonsense", 1]]),
            "MISSING": lambda d: level(d).pop("money"),
            "UNKNOWN_KEY": lambda d: level(d).update(extra=1),
        }
        for code, mutator in cases.items():
            with self.subTest(code=code):
                self.assertIn(code, codes(edited(mutator)))

    def test_extra_waves(self):
        good = [{"day": 2, "night": True, "kind": "wasp", "count": 3}]
        self.assertEqual(codes(edited(lambda d: level(d).update(extra_waves=good))), set())
        self.assertEqual(codes(edited(lambda d: level(d).update(extra_waves=[]))), set())
        bad = {
            "kind": {"day": 2, "night": True, "kind": "ghost", "count": 3},
            "day": {"day": 0, "night": True, "kind": "wasp", "count": 3},
            "count": {"day": 1, "night": False, "kind": "wasp", "count": 0},
            "huge": {"day": 1, "night": False, "kind": "wasp", "count": 201},
            "flag": {"day": 1, "night": 1, "kind": "wasp", "count": 1},
            "keys": {"day": 1, "night": False, "kind": "wasp"},
            "extra": {"day": 1, "night": False, "kind": "wasp", "count": 1, "x": 1},
            "type": [1, 2],
        }
        for name, entry in bad.items():
            with self.subTest(name=name):
                self.assertIn("EXTRA_WAVE", codes(edited(lambda d: level(d).update(extra_waves=[entry]))))
        self.assertIn("EXTRA_WAVE", codes(edited(lambda d: level(d).update(extra_waves="x"))))

    def test_night_time_must_be_positive(self):
        self.assertIn("LEVEL_TIME", codes(edited(lambda d: level(d).update(night=-5))))
        self.assertEqual(codes(edited(lambda d: level(d).update(night=0.5))), set())

    def test_minimum_cells(self):
        self.assertIn("LEVEL_CELLS", codes(edited(lambda d: level(d).update(cells=[19, 40]))))
        self.assertEqual(codes(edited(lambda d: level(d).update(cells=[20, 20]))), set())
        self.assertIn("LEVEL_CELLS", codes(edited(lambda d: level(d).update(cells=[30.5, 40]))))
        self.assertIn("LEVEL_CELLS", codes(edited(lambda d: level(d).update(cells=[30]))))

    def test_wave_roster_entries(self):
        bad = {"tier": ["wasp", -1, 1.0], "weight": ["wasp", 0, 0], "shape": ["wasp", 0], "tier_float": ["wasp", 0.5, 1.0]}
        for name, entry in bad.items():
            with self.subTest(name=name):
                self.assertIn("WAVE_ROSTER", codes(edited(lambda d: level(d)["waves"].update(roster=[entry]))))
        self.assertIn("WAVE_ROSTER", codes(edited(lambda d: level(d)["waves"].update(roster=[]))))
        self.assertEqual(codes(edited(lambda d: level(d)["waves"].update(night_roster=[]))), set())
        self.assertIn("WAVE_ROSTER", codes(edited(lambda d: level(d)["waves"].update(night_roster=[["ghost", 0, 1]]))))

    def test_wave_numbers(self):
        for key in ("base", "ramp", "night", "growth"):
            with self.subTest(key=key):
                self.assertIn("WAVES", codes(edited(lambda d: level(d)["waves"].update({key: -1}))))
        self.assertIn("WAVES", codes(edited(lambda d: level(d)["waves"].pop("roster"))))

    def test_terrain_spots(self):
        self.assertIn("LEVEL_TERRAIN", codes(edited(lambda d: level(d, 0)["terrain"].update(spots=[[[2, 0], 5, []]]))))
        self.assertIn("LEVEL_TERRAIN", codes(edited(lambda d: level(d, 0)["terrain"].update(spots=[[[0.5, 0.5], 0, []]]))))
        self.assertIn("LEVEL_TERRAIN", codes(edited(lambda d: level(d, 0)["terrain"].update(spots=[[[0.5, 0.5], 5, [[1]]]]))))

    def test_challenges(self):
        self.assertEqual(codes(edited(lambda d: level(d).update(challenges=[]))), set())
        self.assertIn("CHALLENGE", codes(edited(lambda d: level(d).update(challenges=[["core", -1]]))))
        self.assertIn("CHALLENGE", codes(edited(lambda d: level(d).update(challenges=[["core"]]))))

    def test_world_may_be_null_or_unit_pair(self):
        self.assertEqual(codes(edited(lambda d: level(d).update(world=None))), set())
        self.assertEqual(codes(edited(lambda d: level(d).update(world=[0, 1]))), set())
        self.assertIn("LEVEL_POSITION", codes(edited(lambda d: level(d).update(world=[1.1, 0.5]))))
        self.assertIn("LEVEL_POSITION", codes(edited(lambda d: level(d).update(world=[0.5]))))

    def test_levels_may_be_added(self):
        self.assertEqual(codes(edited(lambda d: d["levels"].append(new_level(d)))), set())

    def test_duplicate_ids_are_rejected(self):
        self.assertIn("LEVEL_ID_DUPLICATE", codes(edited(lambda d: d["levels"].append(new_level(d, level(d)["id"])))))

    def test_levels_may_be_deleted_down_to_one(self):
        def shrink(d):
            del d["levels"][1:]
            d["routes"] = []
        self.assertEqual(codes(edited(shrink)), set())
        self.assertIn("LEVEL_SET", codes(edited(lambda d: d.update(levels=[]))))
        self.assertIn("LEVEL_SET", codes(edited(lambda d: d.update(levels="x"))))

    def test_deleting_a_level_invalidates_routes_to_it(self):
        self.assertIn("ROUTES", codes(edited(lambda d: d["levels"].pop())))


class RouteTest(unittest.TestCase):
    def test_route_rules(self):
        self.assertIn("ROUTES", codes(edited(lambda d: d.update(routes=[[0, 99]]))))
        self.assertIn("ROUTES", codes(edited(lambda d: d.update(routes=[[-1, 1]]))))
        self.assertIn("ROUTES", codes(edited(lambda d: d.update(routes=[[1, 1]]))))
        self.assertIn("ROUTES", codes(edited(lambda d: d.update(routes=[[0, 1], [1, 0]]))))
        self.assertIn("ROUTES", codes(edited(lambda d: d.update(routes=[[0]]))))
        self.assertIn("ROUTES", codes(edited(lambda d: d.update(routes="x"))))

    def test_null_and_empty_routes_are_allowed(self):
        self.assertEqual(codes(edited(lambda d: d.update(routes=None))), set())
        self.assertEqual(codes(edited(lambda d: d.update(routes=[]))), set())

    def test_new_level_can_be_routed(self):
        def grow(d):
            d["levels"].append(new_level(d))
            d["routes"].append([len(d["levels"]) - 2, len(d["levels"]) - 1])
        self.assertEqual(codes(edited(grow)), set())
