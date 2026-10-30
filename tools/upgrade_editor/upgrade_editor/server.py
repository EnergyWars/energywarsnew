import ipaddress
import json
import mimetypes
import socket
import threading
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from .store import DocumentStore, MissingFile, ValidationFailed

MAX_BODY = 8 * 1024 * 1024
GUARD_HEADER = "X-Upgrade-Editor"
LOCAL_NAMES = ("localhost",)


def is_private_address(value):
    try:
        address = ipaddress.ip_address(value.split("%", 1)[0])
    except ValueError:
        return False
    if address.version == 6 and address.ipv4_mapped:
        address = address.ipv4_mapped
    return address.is_loopback or address.is_private or address.is_link_local


def host_name_allowed(name):
    name = name.strip("[]").lower()
    if name in LOCAL_NAMES:
        return True
    try:
        ipaddress.ip_address(name)
        return True
    except ValueError:
        pass
    own = socket.gethostname().lower()
    return name in (own, f"{own}.local", f"{own}.lan", f"{own}.fritz.box")


def lan_addresses():
    found = []
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
            probe.connect(("10.255.255.255", 1))
            found.append(probe.getsockname()[0])
    except OSError:
        pass
    return [address for address in found if is_private_address(address) and not address.startswith("127.")]


def create_server(store, web_dir, port=0, host="127.0.0.1"):
    server = ThreadingHTTPServer((host, port), EditorHandler)
    server.store = store
    server.web_dir = Path(web_dir).resolve()
    server.write_lock = threading.Lock()
    return server


class EditorHandler(BaseHTTPRequestHandler):
    server_version = "UpgradeEditor"

    def log_message(self, format, *args):
        pass

    def _host_allowed(self):
        if not is_private_address(self.client_address[0]):
            return False
        host = self.headers.get("Host", "")
        name, _, port = host.rpartition(":")
        return host_name_allowed(name) and port == str(self.server.server_address[1])

    def _send_json(self, payload, status=HTTPStatus.OK):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _send_error_code(self, status, code):
        self._send_json({"error": code}, status)

    def _read_body(self):
        length = int(self.headers.get("Content-Length", "0") or 0)
        if length <= 0 or length > MAX_BODY:
            return None
        try:
            return json.loads(self.rfile.read(length).decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError):
            return None

    def do_GET(self):
        if not self._host_allowed():
            return self._send_error_code(HTTPStatus.FORBIDDEN, "HOST")
        path = self.path.split("?", 1)[0]
        if path.startswith("/api/"):
            return self._get_api(path)
        self._get_static(path)

    def do_PUT(self):
        self._mutate()

    def do_POST(self):
        self._mutate()

    def _mutate(self):
        if not self._host_allowed():
            return self._send_error_code(HTTPStatus.FORBIDDEN, "HOST")
        if self.headers.get(GUARD_HEADER) != "1":
            return self._send_error_code(HTTPStatus.FORBIDDEN, "GUARD")
        path = self.path.split("?", 1)[0]
        store = self.server.store
        try:
            self._route_mutation(store, path)
        except ValidationFailed as failure:
            self._send_json({"error": "VALIDATION", "errors": failure.errors}, HTTPStatus.UNPROCESSABLE_ENTITY)
        except MissingFile:
            self._send_error_code(HTTPStatus.NOT_FOUND, "MISSING_FILE")

    def _route_mutation(self, store, path):
        if path == "/api/document" and self.command == "PUT":
            body = self._read_body()
            if not isinstance(body, dict) or "document" not in body:
                return self._send_error_code(HTTPStatus.BAD_REQUEST, "BODY")
            with self.server.write_lock:
                saved = store.save_edited(body["document"])
            return self._send_json({"source": "edited", "document": saved})
        if path == "/api/validate" and self.command == "POST":
            body = self._read_body()
            if not isinstance(body, dict) or "document" not in body:
                return self._send_error_code(HTTPStatus.BAD_REQUEST, "BODY")
            return self._send_json({"errors": store.validate(body["document"])})
        if path == "/api/diff" and self.command == "POST":
            body = self._read_body()
            if not isinstance(body, dict) or "document" not in body:
                return self._send_error_code(HTTPStatus.BAD_REQUEST, "BODY")
            errors = store.validate(body["document"])
            if errors:
                return self._send_json({"error": "VALIDATION", "errors": errors}, HTTPStatus.UNPROCESSABLE_ENTITY)
            return self._send_json({"changes": store.changes_for(body["document"])})
        if path == "/api/reset" and self.command == "POST":
            with self.server.write_lock:
                archived = store.reset_edited()
            return self._send_json({"source": store.source(), "archived": str(archived) if archived else None})
        self._send_error_code(HTTPStatus.NOT_FOUND, "ROUTE")

    def _get_api(self, path):
        store = self.server.store
        try:
            if path == "/api/document":
                return self._send_json({"source": store.source(), "document": store.load_active(), "original": store.load_original()})
            if path == "/api/changes":
                return self._send_json({"changes": store.changes()})
        except MissingFile:
            return self._send_error_code(HTTPStatus.NOT_FOUND, "MISSING_FILE")
        self._send_error_code(HTTPStatus.NOT_FOUND, "ROUTE")

    def _get_static(self, path):
        relative = "index.html" if path in ("", "/") else path.lstrip("/")
        target = (self.server.web_dir / relative).resolve()
        if self.server.web_dir not in target.parents or not target.is_file():
            return self._send_error_code(HTTPStatus.NOT_FOUND, "FILE")
        content = target.read_bytes()
        content_type = mimetypes.guess_type(target.name)[0] or "application/octet-stream"
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", content_type + ("; charset=utf-8" if content_type.startswith("text/") or content_type.endswith("javascript") or content_type.endswith("json") else ""))
        self.send_header("Content-Length", str(len(content)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(content)
