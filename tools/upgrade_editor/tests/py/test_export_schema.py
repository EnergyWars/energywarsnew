import json
import unittest

from .fixtures import TOOL_DIR, load_game

ENEMY_KEYS = {"class", "hp", "speed", "damage", "cooldown", "reach", "radius", "bounty", "armor", "faction", "look", "buffs"}
LEVEL_KEYS = {"id", "cells", "money", "day", "night", "seed", "drop", "structures", "terrain", "waves", "world", "challenges"}


class ExportSchemaTest(unittest.TestCase):
    def setUp(self):
        self.game = load_game()

    def test_document_is_json_round_trippable(self):
        self.assertEqual(json.loads(json.dumps(self.game)), self.game)

    def test_top_level_keys(self):
        for key in ("armor", "enemies", "levels", "routes", "names", "buildings", "defaults"):
            self.assertIn(key, self.game)
        self.assertEqual(set(self.game["armor"]), {"constant", "max_reduction", "min_damage"})

    def test_enemies_are_complete(self):
        for kind, entry in self.game["enemies"].items():
            with self.subTest(kind=kind):
                self.assertTrue(ENEMY_KEYS <= set(entry))
                self.assertEqual(set(entry["buffs"]), {"night", "level"})
                self.assertEqual(set(entry["buffs"]["night"]), {"hp", "damage", "speed", "armor"})

    def test_levels_use_arrays_not_vectors(self):
        for entry in self.game["levels"]:
            self.assertEqual(set(entry), LEVEL_KEYS)
            self.assertIsInstance(entry["cells"], list)
            self.assertIsInstance(entry["drop"], list)
            for kind, position in entry["structures"]:
                self.assertIsInstance(position, list)

    def test_routes_reference_levels(self):
        count = len(self.game["levels"])
        for first, second in self.game["routes"]:
            self.assertTrue(0 <= first < count and 0 <= second < count)

    def test_buildings_carry_armor_and_description_key(self):
        for entry in self.game["buildings"]:
            self.assertIsInstance(entry["armor"], float)
            self.assertEqual(entry["description_key"], f"BUILDING_{entry['id'].upper()}_DESC")
            self.assertIn(entry["description_key"], self.game["names"])
            self.assertNotIn("armor", entry["stats"])

    def test_names_include_enemy_texts(self):
        self.assertTrue([key for key in self.game["names"] if key.startswith("ENEMY_")])

    def test_defaults_mirror_content_sections(self):
        self.assertEqual(set(self.game["defaults"]), {"armor", "enemies", "levels", "routes"})

    def test_export_script_writes_all_new_keys(self):
        script = (TOOL_DIR / "export_game.gd").read_text(encoding="utf-8")
        for key in ('"armor"', '"enemies"', '"levels"', '"routes"', '"description_key"', '"defaults"', "ENEMY_"):
            self.assertIn(key, script)
