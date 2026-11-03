"""Run with python3 -m unittest discover -s tests -p 'test_*.py'."""
import io
import json
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

import validate_dialogue as validator


class FlagReportTests(unittest.TestCase):
    def run_fixture(self, graph):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "example.json").write_text(json.dumps(graph))
            output = io.StringIO()
            with patch.object(validator, "ROOT", root), patch.object(validator, "DIALOGUE_DIR", root):
                with redirect_stdout(output):
                    status = validator.main()
            return status, output.getvalue()

    def test_lists_node_and_choice_assignments_including_repeated_names(self):
        graph = {"start": {
            "set_flag": {"seen": False, "count": 0},
            "choices": [
                {"text": "Yes", "next": None, "set_flag": {"seen": True}},
                {"text": "No", "next": None, "set_flag": {"seen": False}},
            ],
        }}
        status, output = self.run_fixture(graph)
        self.assertEqual(status, 0)
        self.assertEqual([line.strip() for line in output.splitlines() if " = " in line], [
            "example.json:start:node  seen = false",
            "example.json:start:node  count = 0",
            "example.json:start:choice[0]  seen = true",
            "example.json:start:choice[1]  seen = false",
        ])

    def test_orphan_warning_still_succeeds_and_lists_authored_write(self):
        status, output = self.run_fixture({"start": {"next": "start"},
            "orphan": {"next": None, "set_flag": {"unlisted_name": False}}})
        self.assertEqual(status, 0)
        self.assertIn("warning:", output)
        self.assertIn("example.json:orphan:node  unlisted_name = false", output)

    def test_structure_error_still_fails(self):
        status, output = self.run_fixture({"start": {"next": "missing", "set_flag": {"x": False}}})
        self.assertEqual(status, 1)
        self.assertIn("points to missing node", output)
        self.assertIn("example.json:start:node  x = false", output)

    def test_checked_in_graphs(self):
        def assignments(filename):
            graph = json.loads((validator.DIALOGUE_DIR / filename).read_text())
            return list(validator.flag_assignments(graph))

        self.assertEqual(assignments("keeper_intro.json"), [
            ("logbook_choice1", 0, "skeptic", True),
            ("logbook_choice1", 1, "believer", True),
            ("logbook_choice2", 0, "trusted_edith", True),
            ("logbook_choice2", 1, "trusted_edith", False),
            ("radio_2", 0, "radioed_tom", True),
            ("radio_2", 1, "radioed_tom", True),
        ])
        self.assertEqual(assignments("lamp_room.json"), [])
