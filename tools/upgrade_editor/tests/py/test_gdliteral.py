import unittest

from upgrade_editor.gdliteral import find_span, parse_dict

SAMPLE = '{"a": 1, "b": {"c": [1, 2], "d": "x,y"}, K: Vector2(1, 2), "e": 3.5}'


class GdLiteralTest(unittest.TestCase):
    def setUp(self):
        self.entries = parse_dict(SAMPLE, 0)

    def span(self, *path):
        start, end = find_span(self.entries, path)
        return SAMPLE[start:end]

    def test_scalars_and_nested(self):
        self.assertEqual(self.span("a"), "1")
        self.assertEqual(self.span("e"), "3.5")
        self.assertEqual(self.span("b", "c"), "[1, 2]")
        self.assertEqual(self.span("b", "d"), '"x,y"')

    def test_identifier_keys_and_calls(self):
        self.assertEqual(self.span("K"), "Vector2(1, 2)")

    def test_unknown_path_raises(self):
        with self.assertRaises(KeyError):
            find_span(self.entries, ("a", "z"))
        with self.assertRaises(KeyError):
            find_span(self.entries, ("nope",))
