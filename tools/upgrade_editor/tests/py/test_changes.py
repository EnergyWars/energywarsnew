import copy
import unittest

from upgrade_editor.changes import diff
from .fixtures import building, edited, load_game


class ChangesTest(unittest.TestCase):
    def test_identical_documents_have_no_changes(self):
        self.assertEqual(diff(load_game(), load_game()), [])

    def test_scalar_changes_are_listed_with_paths(self):
        document = edited(lambda d: (d["tracks"]["rate"].update(price=0.5), building(d, "solar").update(cost=41)))
        paths = {change["path"]: change for change in diff(load_game(), document)}
        self.assertEqual(paths["tracks.rate.price"]["after"], 0.5)
        self.assertEqual(paths["buildings.solar.cost"]["before"], 40)

    def test_added_and_removed_keys(self):
        document = edited(lambda d: d["tracks"]["rate"].update(growth=1.3))
        change = diff(load_game(), document)[0]
        self.assertIsNone(change["before"])
        self.assertEqual(change["after"], 1.3)

    def test_track_list_and_curves(self):
        document = edited(lambda d: (building(d, "solar").update(tracks=["output"]), building(d, "bulwark")["curves"]["hull"].update(gain=3.0)))
        paths = {change["path"] for change in diff(load_game(), document)}
        self.assertIn("buildings.solar.tracks", paths)
        self.assertIn("buildings.bulwark.curves.hull.gain", paths)


class ContentChangesTest(unittest.TestCase):
    def paths(self, mutator):
        return {change["path"]: change for change in diff(load_game(), edited(mutator))}

    def test_armor_and_building_armor(self):
        paths = self.paths(lambda d: (d["armor"].update(constant=50.0), building(d, "solar").update(armor=9.0)))
        self.assertEqual(paths["armor.constant"]["before"], 100.0)
        self.assertEqual(paths["buildings.solar.armor"]["after"], 9.0)

    def test_enemy_fields_including_buffs(self):
        paths = self.paths(lambda d: (d["enemies"]["wasp"].update(hp=1.0), d["enemies"]["wasp"]["buffs"]["night"].update(hp=0.9)))
        self.assertEqual(paths["enemies.wasp.hp"]["after"], 1.0)
        self.assertEqual(paths["enemies.wasp.buffs.night.hp"]["after"], 0.9)

    def test_level_changes_are_keyed_by_id(self):
        first = load_game()["levels"][0]["id"]
        paths = self.paths(lambda d: d["levels"][0].update(money=7))
        self.assertEqual(paths[f"levels.{first}.money"]["after"], 7)

    def test_added_and_removed_levels(self):
        def grow(d):
            created = copy.deepcopy(d["levels"][0])
            created["id"] = "fresh"
            d["levels"].append(created)
        added = self.paths(grow)
        self.assertIsNone(added["levels.fresh.money"]["before"])
        self.assertIn("levels.order", added)
        removed = self.paths(lambda d: d["levels"].pop())
        last = load_game()["levels"][-1]["id"]
        self.assertIsNone(removed[f"levels.{last}.money"]["after"])

    def test_level_order_and_routes(self):
        paths = self.paths(lambda d: (d["levels"].reverse(), d.update(routes=[[0, 1]])))
        self.assertIn("levels.order", paths)
        self.assertIn("routes", paths)

    def test_route_direction_is_not_a_change(self):
        self.assertEqual(self.paths(lambda d: d.update(routes=[[b, a] for a, b in d["routes"]])), {})
