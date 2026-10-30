import unittest

from upgrade_editor.patcher import patch_config
from .fixtures import CONFIG, building, edited, load_game


class PatcherTest(unittest.TestCase):
    def setUp(self):
        self.text = CONFIG.read_text(encoding="utf-8")

    def test_original_document_reproduces_the_source(self):
        self.assertEqual(patch_config(self.text, load_game()), self.text)

    def test_track_values_are_written(self):
        document = edited(lambda d: d["tracks"]["rate"].update(max=30, step=0.2, price=0.5, growth=1.3))
        patched = patch_config(self.text, document)
        self.assertIn('TRACK_RATE: {"max": 30, "step": 0.2, "price": 0.5, "growth": 1.3},', patched)

    def test_energy_and_growth_constants(self):
        document = edited(lambda d: (d["tracks"]["overclock"].update(energy=1.5), d["system"].update(track_growth=1.2)))
        patched = patch_config(self.text, document)
        self.assertIn('"energy": 1.5}', patched)
        self.assertIn("const TRACK_GROWTH := 1.2\n", patched)

    def test_wall_curve(self):
        document = edited(lambda d: building(d, "bulwark")["curves"]["hull"].update(max=9, gain=2.5))
        patched = patch_config(self.text, document)
        self.assertIn('const WALL_HULL := {"max": 9, "gain": 2.5, "gain_growth": 1.85, "price": 0.125, "growth": 1.75}', patched)

    def test_building_scalars_are_written(self):
        document = edited(lambda d: building(d, "solar").update(cost=45, hp=75.5))
        patched = patch_config(self.text, document)
        self.assertIn('SOLAR: {"team": TEAM_PLAYER, "cost": 45, "upgrade_base": 40, "hp": 75.5,', patched)
        self.assertEqual(patched.count('"cost": 45'), 1)

    def test_upgrade_base_is_updated_or_inserted(self):
        document = edited(lambda d: (building(d, "core").update(upgrade_base=200), building(d, "solar").update(upgrade_base=99)))
        patched = patch_config(self.text, document)
        self.assertIn('CORE: {"team": TEAM_PLAYER, "cost": 0, "upgrade_base": 200,', patched)
        self.assertIn('SOLAR: {"team": TEAM_PLAYER, "cost": 40, "upgrade_base": 99, "hp": 70.0,', patched)

    def test_upgrade_base_equal_to_cost_stays_implicit(self):
        document = edited(lambda d: building(d, "solar").update(cost=60, upgrade_base=60))
        self.assertNotIn('"upgrade_base": 60', patch_config(self.text, document))

    def test_track_list_is_written(self):
        document = edited(lambda d: building(d, "solar").update(tracks=["range", "output"]))
        self.assertIn('"tracks": [TRACK_RANGE, TRACK_OUTPUT]', patch_config(self.text, document))

    def test_last_building_before_enemies_is_isolated(self):
        document = edited(lambda d: building(d, "bulwark").update(hp=1700.0))
        patched = patch_config(self.text, document)
        self.assertIn('"hp": 1700.0', patched)
        self.assertIn('NEST: {"team": TEAM_ENEMY, "hp": 1200.0', patched)

    def test_flat_and_nested_stats_are_written(self):
        def mutate(d):
            building(d, "zapper")["stats"]["attack"]["damage"] = 31
            building(d, "core")["stats"].update(radius=51.5, links=4)
            building(d, "bulwark")["stats"]["repair"]["rate"] = 6.5
        patched = patch_config(self.text, edited(mutate))
        self.assertIn('"damage": 31.0, "cooldown": 0.45', patched)
        self.assertIn('"radius": 51.5, "cells": 2', patched)
        self.assertIn('"links": 4, "range": 280.0', patched)
        self.assertIn('"repair": {"rate": 6.5, "energy": 0.4}', patched)

    def test_integer_stat_stays_integer_and_unchanged_text_is_kept(self):
        patched = patch_config(self.text, edited(lambda d: building(d, "tesla")["stats"]["attack"].update(chain=6)))
        self.assertIn('"chain": 6, "ground"', patched)

    def test_missing_target_raises(self):
        with self.assertRaises(ValueError):
            patch_config("const TRACKS := {}\n", load_game())
