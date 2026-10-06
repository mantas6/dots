#!/usr/bin/env python3
"""Run with python3 tests/code-to-html.py; requires nvim on PATH.

Use Neovim's real Ex parser with a deterministic TOhtml stand-in, without
loading user configuration or plugins. All fixtures stay inside this repo.
"""

import os
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "bin/code-to-html"


class CodeToHtmlTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(
            prefix=".code-to-html-", dir=ROOT / "tests"
        )
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.tools = self.directory / "tools"
        self.tools.mkdir()
        nvim = shutil.which("nvim")
        if nvim is None:
            self.fail("nvim is required")
        self.env = dict(os.environ, TEST_NVIM=nvim, TMPDIR=str(self.directory))
        self.env["HOME"] = str(self.directory)
        for variable in [
            "XDG_CONFIG_HOME",
            "XDG_DATA_HOME",
            "XDG_STATE_HOME",
            "XDG_CACHE_HOME",
        ]:
            self.env[variable] = str(self.directory / variable)
        self.env["PATH"] = str(self.tools) + os.pathsep + self.env["PATH"]
        self.env["TITLE_LOG"] = str(self.directory / "title-log")
        self.tool(
            "nvim",
            "#!/usr/bin/env sh\n"
            'exec "$TEST_NVIM" --headless -u NONE -i NONE '
            '--cmd \'command -bar TOhtml enew | call setline(1, "<html><body>fixture</body></html>")\' "$@"\n',
        )
        self.tool(
            "add-html-title",
            "#!/usr/bin/env sh\n"
            '[ -f "$1" ] || exit 1\n'
            'printf "%s\\n%s\\n" "$1" "$2" >> "$TITLE_LOG"\n',
        )

    def tool(self, name, content):
        path = self.tools / name
        path.write_text(content)
        path.chmod(0o755)

    def run_export(self, *paths):
        command = ["sh", str(SCRIPT), *paths]
        with subprocess.Popen(
            command,
            cwd=self.directory,
            env=self.env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            start_new_session=True,
        ) as process:
            try:
                stdout, stderr = process.communicate(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                stdout, stderr = process.communicate()
                self.fail(f"Export timed out: {stderr}")
            return subprocess.CompletedProcess(
                command, process.returncode, stdout, stderr
            )

    def test_literal_output_paths(self):
        names = [
            "plain.js",
            "two words.js",
            "percent%.js",
            "hash#.js",
            "pipe|name.js",
            "quote'name.js",
            "back\\slash.js",
            "-leading.js",
        ]
        for name in names:
            (self.directory / name).write_text("const value = 42;\n")
        for name in names:
            with self.subTest(name=name):
                result = self.run_export(name)
                self.assertEqual(result.returncode, 0, result.stderr)
                output = self.directory / (name + ".html")
                self.assertTrue(output.is_file(), result.stderr)
                self.assertEqual(
                    output.read_text(), "<html><body>fixture</body></html>\n"
                )
                self.assertEqual(
                    (self.directory / name).read_text(), "const value = 42;\n"
                )
        expected = "".join(f"{name}.html\n{name}\n" for name in names)
        self.assertEqual(Path(self.env["TITLE_LOG"]).read_text(), expected)

    def test_existing_output_is_skipped_and_batch_continues(self):
        for name in ["existing.js", "next.js"]:
            (self.directory / name).write_text("source\n")
        existing = self.directory / "existing.js.html"
        existing.write_text("keep this output\n")
        result = self.run_export("existing.js", "next.js")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(existing.read_text(), "keep this output\n")
        self.assertIn("File exists existing.js.html", result.stderr)
        self.assertTrue((self.directory / "next.js.html").is_file())
        self.assertEqual(
            Path(self.env["TITLE_LOG"]).read_text(), "next.js.html\nnext.js\n"
        )


if __name__ == "__main__":
    unittest.main()
