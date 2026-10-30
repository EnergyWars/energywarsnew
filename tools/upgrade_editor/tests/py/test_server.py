import json
import shutil
import tempfile
import threading
import unittest
import urllib.error
import urllib.request
from pathlib import Path

from upgrade_editor.server import create_server, host_name_allowed, is_private_address, lan_addresses
from upgrade_editor.store import DocumentStore
from .fixtures import CONFIG, TOOL_DIR, building, edited, load_game


class ServerTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        data = self.tmp / "data"
        data.mkdir()
        shutil.copy(TOOL_DIR / "data" / "game.json", data / "game.json")
        shutil.copy(CONFIG, self.tmp / "game_config.gd")
        self.server = create_server(DocumentStore(data, self.tmp / "game_config.gd", self.tmp / "overrides.json"), TOOL_DIR / "web")
        thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        thread.start()
        self.addCleanup(thread.join, 2)
        self.addCleanup(self.server.server_close)
        self.addCleanup(self.server.shutdown)
        self.base = f"http://127.0.0.1:{self.server.server_address[1]}"

    def call(self, path, method="GET", body=None, headers=None):
        request = urllib.request.Request(self.base + path, method=method, headers=headers or {}, data=json.dumps(body).encode() if body is not None else None)
        try:
            with urllib.request.urlopen(request) as response:
                return response.status, response.read()
        except urllib.error.HTTPError as error:
            return error.code, error.read()

    def mutate(self, path, body, method="POST"):
        return self.call(path, method, body, {"X-Upgrade-Editor": "1", "Content-Type": "application/json"})

    def test_document_endpoint(self):
        status, body = self.call("/api/document")
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body)["source"], "original")

    def test_static_index_and_traversal(self):
        self.assertEqual(self.call("/")[0], 200)
        self.assertEqual(self.call("/../upgrade_editor/store.py")[0], 404)
        self.assertEqual(self.call("/nope.js")[0], 404)

    def test_unknown_route(self):
        self.assertEqual(self.call("/api/nope")[0], 404)
        self.assertEqual(self.mutate("/api/nope", {})[0], 404)

    def test_mutations_need_guard_header(self):
        self.assertEqual(self.call("/api/validate", "POST", {"document": load_game()})[0], 403)

    def test_foreign_host_is_rejected(self):
        request = urllib.request.Request(self.base + "/api/document", headers={"Host": "evil.example"})
        with self.assertRaises(urllib.error.HTTPError) as caught:
            urllib.request.urlopen(request)
        self.assertEqual(caught.exception.code, 403)

    def test_validate_and_diff(self):
        document = edited(lambda d: building(d, "solar").update(cost=50))
        self.assertEqual(json.loads(self.mutate("/api/validate", {"document": document})[1])["errors"], [])
        self.assertEqual(len(json.loads(self.mutate("/api/diff", {"document": document})[1])["changes"]), 1)
        bad = edited(lambda d: building(d, "solar").update(hp=0))
        self.assertEqual(self.mutate("/api/diff", {"document": bad})[0], 422)
        self.assertEqual(self.mutate("/api/validate", {})[0], 400)
        self.assertEqual(self.mutate("/api/diff", {})[0], 400)

    def test_save_reset_cycle(self):
        document = edited(lambda d: building(d, "solar").update(cost=50))
        self.assertEqual(self.mutate("/api/document", {"document": document}, "PUT")[0], 200)
        self.assertEqual(json.loads(self.call("/api/document")[1])["source"], "edited")
        self.assertEqual(len(json.loads(self.call("/api/changes")[1])["changes"]), 1)
        self.assertEqual(self.mutate("/api/reset", {})[0], 200)
        self.assertEqual(json.loads(self.call("/api/document")[1])["source"], "original")

    def test_save_rejects_invalid_and_bad_body(self):
        bad = edited(lambda d: building(d, "solar").update(hp=0))
        self.assertEqual(self.mutate("/api/document", {"document": bad}, "PUT")[0], 422)
        self.assertEqual(self.mutate("/api/document", {}, "PUT")[0], 400)

    def test_missing_file(self):
        (self.tmp / "data" / "game.json").unlink()
        self.assertEqual(self.call("/api/document")[0], 404)


class MainTest(unittest.TestCase):
    def test_default_port_is_fixed_and_busy_port_is_reported(self):
        import socket
        from upgrade_editor import __main__ as entry
        self.assertEqual(entry.DEFAULT_PORT, 48731)
        with socket.socket() as blocker:
            blocker.bind(("127.0.0.1", 0))
            blocker.listen()
            port = blocker.getsockname()[1]
            self.assertEqual(entry.main(["serve", "--no-browser", "--port", str(port)]), 3)


class NetworkTest(unittest.TestCase):
    def test_private_addresses(self):
        for value in ("127.0.0.1", "192.168.1.20", "10.0.0.5", "172.16.3.4", "169.254.1.1", "::1", "::ffff:192.168.0.2", "fe80::1%eth0"):
            self.assertTrue(is_private_address(value), value)
        for value in ("8.8.8.8", "2001:4860:4860::8888", "nonsense", "::ffff:8.8.8.8"):
            self.assertFalse(is_private_address(value), value)

    def test_host_names(self):
        import socket
        own = socket.gethostname().lower()
        for value in ("localhost", "127.0.0.1", "192.168.1.20", "[::1]", own, f"{own}.local"):
            self.assertTrue(host_name_allowed(value), value)
        for value in ("evil.example", "rebind.attacker.com", ""):
            self.assertFalse(host_name_allowed(value), value)

    def test_lan_addresses_are_private(self):
        for address in lan_addresses():
            self.assertTrue(is_private_address(address))
            self.assertFalse(address.startswith("127."))

    def test_server_can_bind_all_interfaces(self):
        import tempfile
        tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, tmp)
        (tmp / "data").mkdir()
        shutil.copy(TOOL_DIR / "data" / "game.json", tmp / "data" / "game.json")
        server = create_server(DocumentStore(tmp / "data", tmp / "c.gd", tmp / "o.json"), TOOL_DIR / "web", 0, "0.0.0.0")
        self.addCleanup(server.server_close)
        self.assertEqual(server.server_address[0], "0.0.0.0")
