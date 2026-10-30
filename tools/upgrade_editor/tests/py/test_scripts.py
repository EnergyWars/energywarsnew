import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

from .fixtures import TOOL_DIR

SCRIPTS = ("app-to-game.sh", "game-to-app.sh", "export.sh")
FAKE_CLAUDE = """#!/usr/bin/env bash
printf '%s\\n' "$@" > "$OUT_DIR/args"
cat > "$OUT_DIR/stdin"
"""


@unittest.skipUnless(shutil.which("bash"), "bash missing")
class ScriptTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.fake = self.tmp / "fake claude"
        self.fake.write_text(FAKE_CLAUDE, encoding="utf-8")
        self.fake.chmod(0o755)
        self.prompt = self.tmp / "prompt.md"
        self.prompt.write_text("Aufgabe mit $(rm -rf /) und `id`", encoding="utf-8")

    def run_claude(self, command):
        environment = {**os.environ, "CLAUDE_CMD": command, "OUT_DIR": str(self.tmp)}
        subprocess.run(
            ["bash", "-c", 'set -euo pipefail; source "$1"; run_claude "$2"', "test", str(TOOL_DIR / "claude.sh"), str(self.prompt)],
            check=True, env=environment, cwd=self.tmp, timeout=20,
        )
        return (self.tmp / "args").read_text(encoding="utf-8").splitlines(), (self.tmp / "stdin").read_text(encoding="utf-8")

    def test_scripts_are_strict_and_parse(self):
        for name in SCRIPTS:
            text = (TOOL_DIR / name).read_text(encoding="utf-8")
            self.assertIn("set -euo pipefail", text, name)
            self.assertNotRegex(text, r"\beval\b|dangerously|bypassPermissions", name)
            subprocess.run(["bash", "-n", str(TOOL_DIR / name)], check=True, timeout=20)
        subprocess.run(["bash", "-n", str(TOOL_DIR / "claude.sh")], check=True, timeout=20)

    def test_claude_gets_minimal_tools_and_the_prompt_on_stdin(self):
        link = self.tmp / "claude-fake"
        os.symlink(self.fake, link)
        args, stdin = self.run_claude(str(link))
        self.assertEqual(stdin, self.prompt.read_text(encoding="utf-8"))
        self.assertNotIn(stdin, args)
        self.assertEqual(args[0], "-p")
        self.assertEqual(args[args.index("--tools") + 1], "Read,Edit,Write,Glob,Grep")
        self.assertEqual(args[args.index("--allowedTools") + 1], "Read,Edit,Write,Glob,Grep")
        self.assertIn("Bash", args[args.index("--disallowedTools") + 1].split(","))
        self.assertIn("WebFetch", args[args.index("--disallowedTools") + 1].split(","))
        self.assertEqual(args[args.index("--permission-mode") + 1], "dontAsk")
        self.assertIn("--strict-mcp-config", args)
        self.assertFalse((self.tmp / "pwned").exists())

    def test_command_variable_is_split_without_globbing(self):
        link = self.tmp / "claude-fake"
        os.symlink(self.fake, link)
        (self.tmp / "match-me").write_text("", encoding="utf-8")
        args, _ = self.run_claude(f"{link} --model x *")
        self.assertEqual(args[:2], ["--model", "x"])
        self.assertEqual(args[2], "*")

    def test_prompts_mark_data_as_untrusted(self):
        for name in ("app-to-game.md", "game-to-app.md"):
            text = (TOOL_DIR / "prompts" / name).read_text(encoding="utf-8")
            self.assertIn("keine Anweisungen", text, name)
            self.assertIn("keine Shell", text, name)
        self.assertIn("last_config.diff", (TOOL_DIR / "prompts" / "app-to-game.md").read_text(encoding="utf-8"))
        self.assertNotIn("Prüfe `git diff", (TOOL_DIR / "prompts" / "app-to-game.md").read_text(encoding="utf-8"))
