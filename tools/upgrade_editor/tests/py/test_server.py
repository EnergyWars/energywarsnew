import contextlib
import http.client
import io
import json
import os
import shutil
import socket
import tempfile
import threading
import unittest
from pathlib import Path
from unittest import mock

from upgrade_editor import server as server_module
from upgrade_editor.server import (
    CONTENT_SECURITY_POLICY,
    GUARD_HEADER,
    MAX_BODY,
    EditorServer,
    create_server,
    host_name_allowed,
    is_loopback_host,
    is_private_address,
    lan_addresses,
    static_target,
)
from upgrade_editor.store import DocumentStore
from .fixtures import CONFIG, TOOL_DIR, building, edited, load_game


def make_store(root):
    data = root / "data"
    data.mkdir()
    shutil.copy(TOOL_DIR / "data" / "game.json", data / "game.json")
    shutil.copy(CONFIG, root / "game_config.gd")
    return DocumentStore(data, root / "game_config.gd", root / "overrides.json")


class ServerCase(unittest.TestCase):
    web_dir = TOOL_DIR / "web"
    host = "127.0.0.1"

    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.store = make_store(self.tmp)
        self.server = create_server(self.store, self.web_dir, 0, self.host)
        thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        thread.start()
        self.addCleanup(thread.join, 2)
        self.addCleanup(self.server.server_close)
        self.addCleanup(self.server.shutdown)
        self.port = self.server.server_address[1]

    def raw(self, method, path, body=None, headers=None, host=None):
        connection = http.client.HTTPConnection("127.0.0.1", self.port, timeout=5)
        self.addCleanup(connection.close)
        connection.putrequest(method, path, skip_host=True, skip_accept_encoding=True)
        merged = {"Host": f"127.0.0.1:{self.port}" if host is None else host}
        merged.update(headers or {})
        payload = body if isinstance(body, bytes) or body is None else json.dumps(body).encode()
        if payload is not None and "Content-Length" not in merged:
            merged["Content-Length"] = str(len(payload))
        for name, value in merged.items():
            connection.putheader(name, value)
        connection.endheaders()
        if payload:
            connection.send(payload)
        response = connection.getresponse()
        return response.status, response.read(), response

    def call(self, path, method="GET", body=None, headers=None):
        merged = dict(headers or {})
        status, content, _ = self.raw(method, path, body, merged)
        return status, content

    def mutate(self, path, body, method="POST", headers=None):
        merged = {GUARD_HEADER: "1", "Content-Type": "application/json"}
        merged.update(headers or {})
        return self.call(path, method, body, merged)


class ServerTest(ServerCase):
    def test_document_endpoint(self):
        status, body = self.call("/api/document")
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body)["source"], "original")

    def test_static_index_and_traversal(self):
        self.assertEqual(self.call("/")[0], 200)
        self.assertEqual(self.call("/js/main.js")[0], 200)
        self.assertEqual(self.call("/../upgrade_editor/store.py")[0], 404)
        self.assertEqual(self.call("/nope.js")[0], 404)

    def test_unknown_route(self):
        self.assertEqual(self.call("/api/nope")[0], 404)
        self.assertEqual(self.mutate("/api/nope", {})[0], 404)

    def test_mutations_need_guard_header(self):
        self.assertEqual(self.call("/api/validate", "POST", {"document": load_game()}, {"Content-Type": "application/json"})[0], 403)

    def test_foreign_host_is_rejected(self):
        status, body, _ = self.raw("GET", "/api/document", headers={}, host=f"evil.example:{self.port}")
        self.assertEqual(status, 403)
        self.assertEqual(json.loads(body)["error"], "HOST")

    def test_loopback_server_rejects_lan_host_names(self):
        for host in (f"192.168.1.20:{self.port}", f"rebind.example:{self.port}", f"127.0.0.1:{self.port + 1}", "127.0.0.1", ""):
            self.assertEqual(self.raw("GET", "/", host=host)[0], 403, host)
        for host in (f"localhost:{self.port}", f"[::1]:{self.port}", f"127.0.0.1:{self.port}"):
            self.assertEqual(self.raw("GET", "/", host=host)[0], 200, host)

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
        status, body = self.mutate("/api/reset", {})
        self.assertEqual(status, 200)
        archived = json.loads(body)["archived"]
        self.assertNotIn("/", archived)
        self.assertTrue(archived.startswith("edited-"))
        self.assertEqual(json.loads(self.call("/api/document")[1])["source"], "original")

    def test_save_rejects_invalid_and_bad_body(self):
        bad = edited(lambda d: building(d, "solar").update(hp=0))
        self.assertEqual(self.mutate("/api/document", {"document": bad}, "PUT")[0], 422)
        self.assertEqual(self.mutate("/api/document", {}, "PUT")[0], 400)

    def test_missing_file(self):
        (self.tmp / "data" / "game.json").unlink()
        self.assertEqual(self.call("/api/document")[0], 404)


class StaticAccessTest(ServerCase):
    def test_static_files_and_api_need_no_token(self):
        for path in ("/", "/index.html", "/css/app.css", "/i18n/de.json", "/js/api.js", "/api/document"):
            self.assertEqual(self.call(path)[0], 200, path)


class CsrfTest(ServerCase):
    def test_cross_origin_mutations_are_rejected(self):
        document = load_game()
        for headers in ({"Origin": "http://evil.example"}, {"Origin": "null"}, {"Origin": f"http://127.0.0.1:{self.port + 1}"}, {"Sec-Fetch-Site": "cross-site"}, {"Sec-Fetch-Site": "same-site"}):
            status, body = self.mutate("/api/validate", {"document": document}, headers=headers)
            self.assertEqual(status, 403, headers)
            self.assertEqual(json.loads(body)["error"], "ORIGIN")

    def test_same_origin_mutations_are_accepted(self):
        headers = {"Origin": f"http://127.0.0.1:{self.port}", "Sec-Fetch-Site": "same-origin"}
        self.assertEqual(self.mutate("/api/validate", {"document": load_game()}, headers=headers)[0], 200)

    def test_mutations_require_json_content_type(self):
        for content_type in ("text/plain", "application/x-www-form-urlencoded", "multipart/form-data; boundary=x", ""):
            status, body = self.call("/api/validate", "POST", {"document": load_game()}, {GUARD_HEADER: "1", "Content-Type": content_type})
            self.assertEqual(status, 415, content_type)
        self.assertEqual(self.mutate("/api/validate", {"document": load_game()}, headers={"Content-Type": "application/json; charset=utf-8"})[0], 200)


class RequestLimitTest(ServerCase):
    def headers(self, **extra):
        merged = {GUARD_HEADER: "1", "Content-Type": "application/json"}
        merged.update(extra)
        return merged

    def test_oversized_body_is_rejected_without_reading_it(self):
        status, body, _ = self.raw("POST", "/api/validate", headers=self.headers(**{"Content-Length": str(MAX_BODY + 1)}))
        self.assertEqual(status, 413)
        self.assertEqual(json.loads(body)["error"], "TOO_LARGE")

    def test_invalid_or_missing_length_is_rejected(self):
        for length in ("abc", "-5", "1e3", "0x10"):
            self.assertEqual(self.raw("POST", "/api/validate", headers=self.headers(**{"Content-Length": length}))[0], 411, length)
        self.assertEqual(self.raw("POST", "/api/validate", headers=self.headers())[0], 411)
        self.assertEqual(self.raw("POST", "/api/validate", headers=self.headers(**{"Transfer-Encoding": "chunked"}))[0], 411)

    def test_non_standard_json_is_rejected(self):
        for payload in (b'{"document": NaN}', b'{"document": Infinity}', b'{"document": -Infinity}', b"\xff\xfe", b"{", b"1" * 5000):
            self.assertEqual(self.raw("POST", "/api/validate", payload, self.headers())[0], 400, payload[:20])

    def test_deeply_nested_json_is_rejected(self):
        for depth in (100, 100000):
            payload = ('{"document": ' + "[" * depth + "]" * depth + "}").encode()
            self.assertEqual(self.raw("POST", "/api/validate", payload, self.headers())[0], 400, depth)

    def test_malformed_documents_fail_validation_instead_of_crashing(self):
        variants = [
            {"schema": 1, "system": []},
            {"schema": 1, "system": {"track_growth": 1.5}, "tracks": []},
            edited(lambda d: d.update(buildings=[1, 2, 3])),
            edited(lambda d: building(d, "solar").update(tracks=[{}])),
            edited(lambda d: building(d, "solar").update(stats=[])),
            edited(lambda d: d.update(levels=[{"id": []}])),
            edited(lambda d: d["levels"][0].update(waves=[])),
        ]
        for document in variants:
            status, body = self.mutate("/api/validate", {"document": document})
            self.assertEqual(status, 200)
            self.assertTrue(json.loads(body)["errors"])

    def test_huge_numbers_are_rejected(self):
        payload = b'{"document": {"schema": 1, "system": {"track_growth": 1' + b"0" * 400 + b"}}}"
        status, body, _ = self.raw("POST", "/api/validate", payload, self.headers())
        self.assertEqual(status, 200)
        self.assertTrue(json.loads(body)["errors"])

    def test_handler_has_a_socket_timeout(self):
        self.assertGreater(server_module.EditorHandler.timeout, 0)
        self.assertLessEqual(server_module.EditorHandler.timeout, 60)


class ErrorPageTest(ServerCase):
    def test_internal_errors_hide_details(self):
        with mock.patch.object(DocumentStore, "load_active", side_effect=RuntimeError("secret /home/user/path")), contextlib.redirect_stderr(io.StringIO()) as log:
            status, body = self.call("/api/document")
        self.assertEqual(status, 500)
        self.assertEqual(json.loads(body), {"error": "INTERNAL"})
        self.assertNotIn("secret", log.getvalue())
        self.assertIn("RuntimeError", log.getvalue())

    def test_unsupported_methods_get_json_errors(self):
        for method in ("DELETE", "PATCH", "OPTIONS", "TRACE", "HEAD"):
            status, body, response = self.raw(method, "/api/document", headers={})
            self.assertEqual(status, 501, method)
            self.assertNotIn(b"<html", body.lower())
            self.assertIsNone(response.getheader("Access-Control-Allow-Origin"))

    def test_server_header_hides_runtime_version(self):
        _, _, response = self.raw("GET", "/")
        self.assertEqual(response.getheader("Server"), "UpgradeEditor")


class SecurityHeaderTest(ServerCase):
    def assert_headers(self, response):
        self.assertEqual(response.getheader("Content-Security-Policy"), CONTENT_SECURITY_POLICY)
        self.assertEqual(response.getheader("X-Content-Type-Options"), "nosniff")
        self.assertEqual(response.getheader("X-Frame-Options"), "DENY")
        self.assertEqual(response.getheader("Referrer-Policy"), "no-referrer")
        self.assertEqual(response.getheader("Cache-Control"), "no-store")
        self.assertEqual(response.getheader("Cross-Origin-Opener-Policy"), "same-origin")

    def test_every_response_carries_security_headers(self):
        requests = [
            ("GET", "/", {}),
            ("GET", "/js/main.js", {}),
            ("GET", "/api/document", {}),
            ("GET", "/api/document", {}),
            ("GET", "/missing.js", {}),
            ("DELETE", "/", {}),
        ]
        for method, path, headers in requests:
            _, _, response = self.raw(method, path, headers=headers)
            self.assert_headers(response)

    def test_policy_forbids_inline_and_eval_scripts(self):
        script = next(part for part in CONTENT_SECURITY_POLICY.split("; ") if part.startswith("script-src"))
        self.assertEqual(script, "script-src 'self'")
        self.assertNotIn("unsafe", CONTENT_SECURITY_POLICY)
        self.assertIn("frame-ancestors 'none'", CONTENT_SECURITY_POLICY)

    def test_static_content_types_are_explicit(self):
        _, _, response = self.raw("GET", "/js/main.js")
        self.assertEqual(response.getheader("Content-Type"), "text/javascript; charset=utf-8")
        _, _, response = self.raw("GET", "/")
        self.assertEqual(response.getheader("Content-Type"), "text/html; charset=utf-8")

    def test_index_has_no_inline_script_or_style(self):
        html = (TOOL_DIR / "web" / "index.html").read_text(encoding="utf-8")
        self.assertNotRegex(html, r"<script(?![^>]*\bsrc=)")
        self.assertNotIn("<style", html)
        self.assertNotIn(" style=", html)
        self.assertNotRegex(html, r"\son[a-z]+=")


class StaticPathTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.web = (self.tmp / "web").resolve()
        (self.web / "js").mkdir(parents=True)
        (self.web / "index.html").write_text("<!doctype html>", encoding="utf-8")
        (self.web / "js" / "app.js").write_text("export {};", encoding="utf-8")
        (self.web / ".secret.json").write_text("{}", encoding="utf-8")
        (self.web / "js" / "notes.py").write_text("x", encoding="utf-8")
        (self.tmp / "outside.js").write_text("leak", encoding="utf-8")
        os.symlink(self.tmp / "outside.js", self.web / "js" / "link.js")
        os.symlink(self.tmp, self.web / "up")

    def test_regular_files_resolve(self):
        self.assertEqual(static_target(self.web, "/"), self.web / "index.html")
        self.assertEqual(static_target(self.web, "/js/app.js"), self.web / "js" / "app.js")
        self.assertEqual(static_target(self.web, "/js/%61pp.js"), self.web / "js" / "app.js")

    def test_traversal_and_tricks_are_rejected(self):
        for path in (
            "/../outside.js", "/js/../../outside.js", "/%2e%2e/outside.js", "/js/%2e%2e%2f%2e%2e%2foutside.js",
            "/js/..%5c..%5coutside.js", "/js\\..\\..\\outside.js", "/js/app.js%00.js", "/%00", "//etc/passwd",
            "/.secret.json", "/js/.", "/js/notes.py", "/js/link.js", "/up/outside.js", "/js/", "/js", "/%ff.js",
            "/js//app.js", "/C:/windows/win.ini",
        ):
            self.assertIsNone(static_target(self.web, path), path)


class ConnectionLimitTest(unittest.TestCase):
    def test_excess_connections_are_closed(self):
        tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, tmp)
        server = create_server(make_store(tmp), TOOL_DIR / "web")
        self.addCleanup(server.server_close)
        self.assertIsInstance(server, EditorServer)
        while server.slots.acquire(blocking=False):
            pass
        left, right = socket.socketpair()
        self.addCleanup(right.close)
        with mock.patch.object(server, "shutdown_request") as shutdown:
            server.process_request(left, ("127.0.0.1", 1))
        shutdown.assert_called_once_with(left)
        left.close()


class MainTest(unittest.TestCase):
    def test_default_port_is_fixed_and_busy_port_is_reported(self):
        from upgrade_editor import __main__ as entry
        self.assertEqual(entry.DEFAULT_PORT, 48731)
        with socket.socket() as blocker:
            blocker.bind(("127.0.0.1", 0))
            blocker.listen()
            port = blocker.getsockname()[1]
            with contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(entry.main(["serve", "--no-browser", "--port", str(port)]), 3)

    def test_default_host_is_loopback(self):
        from upgrade_editor import __main__ as entry
        self.assertEqual(entry.DEFAULT_HOST, "127.0.0.1")

    def run_serve(self, arguments):
        from upgrade_editor import __main__ as entry
        tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, tmp)
        store = make_store(tmp)
        output = io.StringIO()
        with mock.patch.object(entry, "default_store", return_value=store), \
                mock.patch.object(EditorServer, "serve_forever", side_effect=KeyboardInterrupt), \
                mock.patch.object(entry.webbrowser, "open") as browser, \
                mock.patch.object(entry, "lan_addresses", return_value=["192.168.1.20"]), \
                contextlib.redirect_stdout(output):
            self.assertEqual(entry.main(["serve", "--port", "0", *arguments]), 0)
        return output.getvalue(), browser

    def test_start_link_has_no_token(self):
        printed, browser = self.run_serve([])
        first = printed.splitlines()[0]
        self.assertRegex(first, r"^http://127\.0\.0\.1:\d+/$")
        browser.assert_called_once_with(first)
        self.assertNotIn("192.168.1.20", printed)

    def test_lan_mode_prints_lan_links(self):
        printed, _ = self.run_serve(["--host", "0.0.0.0"])
        lines = printed.splitlines()
        self.assertTrue(any(line.startswith("http://192.168.1.20:") and line.endswith("/") for line in lines))


class NetworkTest(unittest.TestCase):
    def test_private_addresses(self):
        for value in ("127.0.0.1", "192.168.1.20", "10.0.0.5", "172.16.3.4", "169.254.1.1", "::1", "::ffff:192.168.0.2", "fe80::1%eth0"):
            self.assertTrue(is_private_address(value), value)
        for value in ("8.8.8.8", "2001:4860:4860::8888", "nonsense", "::ffff:8.8.8.8"):
            self.assertFalse(is_private_address(value), value)

    def test_host_names(self):
        own = socket.gethostname().lower()
        for value in ("localhost", "127.0.0.1", "192.168.1.20", "[::1]", own, f"{own}.local"):
            self.assertTrue(host_name_allowed(value), value)
        for value in ("evil.example", "rebind.attacker.com", "", "[]"):
            self.assertFalse(host_name_allowed(value), value)

    def test_loopback_only_host_names(self):
        for value in ("localhost", "127.0.0.1", "127.0.0.2", "[::1]", "LOCALHOST"):
            self.assertTrue(host_name_allowed(value, loopback_only=True), value)
        for value in ("192.168.1.20", socket.gethostname(), "evil.example", "0.0.0.0", ""):
            self.assertFalse(host_name_allowed(value, loopback_only=True), value)
        self.assertTrue(is_loopback_host("127.0.0.1"))
        self.assertFalse(is_loopback_host("0.0.0.0"))

    def test_lan_addresses_are_private(self):
        for address in lan_addresses():
            self.assertTrue(is_private_address(address))
            self.assertFalse(address.startswith("127."))

    def test_server_can_bind_all_interfaces(self):
        tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, tmp)
        (tmp / "data").mkdir()
        shutil.copy(TOOL_DIR / "data" / "game.json", tmp / "data" / "game.json")
        server = create_server(DocumentStore(tmp / "data", tmp / "c.gd", tmp / "o.json"), TOOL_DIR / "web", 0, "0.0.0.0")
        self.addCleanup(server.server_close)
        self.assertEqual(server.server_address[0], "0.0.0.0")
        self.assertFalse(server.loopback_only)
