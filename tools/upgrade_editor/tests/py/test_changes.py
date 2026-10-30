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
