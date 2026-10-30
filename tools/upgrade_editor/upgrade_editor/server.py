import ipaddress
import json
import socket
import sys
import threading
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlsplit

from .safejson import JsonRejected, loads
from .store import MissingFile, ValidationFailed

MAX_BODY = 8 * 1024 * 1024
MAX_CONNECTIONS = 32
REQUEST_TIMEOUT = 20
GUARD_HEADER = "X-Upgrade-Editor"
LOCAL_NAMES = ("localhost",)
SAFE_FETCH_SITES = ("same-origin", "none")
JSON_TYPE = "application/json"
STATIC_TYPES = {
    ".html": "text/html; charset=utf-8",
    ".js": "text/javascript; charset=utf-8",
    ".css": "text/css; charset=utf-8",
    ".json": "application/json; charset=utf-8",
    ".ttf": "font/ttf",
    ".otf": "font/otf",
    ".woff": "font/woff",
    ".woff2": "font/woff2",
    ".svg": "image/svg+xml",
    ".png": "image/png",
    ".txt": "text/plain; charset=utf-8",
}
CONTENT_SECURITY_POLICY = "; ".join((
    "default-src 'none'",
    "script-src 'self'",
    "style-src 'self'",
    "img-src 'self' data:",
    "font-src 'self'",
    "connect-src 'self'",
    "base-uri 'none'",
    "form-action 'none'",
    "frame-ancestors 'none'",
))
SECURITY_HEADERS = (
    ("Content-Security-Policy", CONTENT_SECURITY_POLICY),
    ("X-Content-Type-Options", "nosniff"),
    ("X-Frame-Options", "DENY"),
    ("Referrer-Policy", "no-referrer"),
    ("Cross-Origin-Opener-Policy", "same-origin"),
    ("Cross-Origin-Resource-Policy", "same-origin"),
    ("Permissions-Policy", "camera=(), microphone=(), geolocation=(), payment=(), usb=()"),
    ("Cache-Control", "no-store"),
)


class RequestRejected(Exception):
    def __init__(self, status, code):
        super().__init__(code)
        self.status = status
        self.code = code


def is_private_address(value):
    try:
        address = ipaddress.ip_address(value.split("%", 1)[0])
    except ValueError:
        return False
    if address.version == 6 and address.ipv4_mapped:
        address = address.ipv4_mapped
    return address.is_loopback or address.is_private or address.is_link_local


def is_loopback_host(value):
    try:
        return ipaddress.ip_address(value.strip("[]")).is_loopback
    except ValueError:
        return value.lower() in LOCAL_NAMES


def host_name_allowed(name, loopback_only=False):
    name = name.strip("[]").lower()
    if not name:
        return False
    if loopback_only:
        return is_loopback_host(name)
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


def static_target(web_dir, path):
    try:
        decoded = unquote(path, errors="strict")
    except UnicodeDecodeError:
        return None
    if "\x00" in decoded or "\\" in decoded:
        return None
    relative = "index.html" if decoded in ("", "/") else decoded[1:] if decoded.startswith("/") else decoded
    parts = relative.split("/")
    if any(not part or part.startswith(".") for part in parts):
        return None
    if Path(relative).suffix.lower() not in STATIC_TYPES:
        return None
    target = (web_dir / relative).resolve()
    if not target.is_relative_to(web_dir) or not target.is_file():
        return None
    return target


class EditorServer(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, address, handler):
        super().__init__(address, handler)
        self.slots = threading.BoundedSemaphore(MAX_CONNECTIONS)

    def process_request(self, request, client_address):
        if not self.slots.acquire(blocking=False):
            self.shutdown_request(request)
            return
        try:
            super().process_request(request, client_address)
        except Exception:
            self.slots.release()
            raise

    def process_request_thread(self, request, client_address):
        try:
            super().process_request_thread(request, client_address)
        finally:
            self.slots.release()

    def handle_error(self, request, client_address):
        sys.stderr.write(f"upgrade_editor: connection error ({sys.exc_info()[0].__name__})\n")


def create_server(store, web_dir, port=0, host="127.0.0.1"):
    server = EditorServer((host, port), EditorHandler)
    server.store = store
    server.web_dir = Path(web_dir).resolve()
    server.write_lock = threading.Lock()
    server.loopback_only = is_loopback_host(host)
    return server


class EditorHandler(BaseHTTPRequestHandler):
    server_version = "UpgradeEditor"
    sys_version = ""
    timeout = REQUEST_TIMEOUT
    error_content_type = "application/json; charset=utf-8"
    error_message_format = '{"error": "HTTP_%(code)d"}'

    def version_string(self):
        return self.server_version

    def log_message(self, format, *args):
        pass

    def end_headers(self):
        for name, value in SECURITY_HEADERS:
            self.send_header(name, value)
        super().end_headers()

    def _host_allowed(self):
        if not is_private_address(self.client_address[0]):
            return False
        host = self.headers.get("Host", "")
        name, _, port = host.rpartition(":")
        return host_name_allowed(name, self.server.loopback_only) and port == str(self.server.server_address[1])

    def _send_json(self, payload, status=HTTPStatus.OK):
        body = json.dumps(payload, ensure_ascii=False, allow_nan=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _send_error_code(self, status, code):
        self._send_json({"error": code}, status)

    def _request_path(self):
        return urlsplit(self.path).path

    def _check_mutation(self):
        if self.headers.get(GUARD_HEADER) != "1":
            raise RequestRejected(HTTPStatus.FORBIDDEN, "GUARD")
        site = self.headers.get("Sec-Fetch-Site")
        if site is not None and site not in SAFE_FETCH_SITES:
            raise RequestRejected(HTTPStatus.FORBIDDEN, "ORIGIN")
        origin = self.headers.get("Origin")
        if origin is not None and origin != f"http://{self.headers.get('Host', '')}":
            raise RequestRejected(HTTPStatus.FORBIDDEN, "ORIGIN")
        content_type = self.headers.get("Content-Type", "").split(";", 1)[0].strip().lower()
        if content_type != JSON_TYPE:
            raise RequestRejected(HTTPStatus.UNSUPPORTED_MEDIA_TYPE, "CONTENT_TYPE")

    def _read_body(self):
        if self.headers.get("Transfer-Encoding"):
            raise RequestRejected(HTTPStatus.LENGTH_REQUIRED, "LENGTH")
        raw = self.headers.get("Content-Length", "")
        if not raw.isdigit():
            raise RequestRejected(HTTPStatus.LENGTH_REQUIRED, "LENGTH")
        length = int(raw)
        if length > MAX_BODY:
            self.close_connection = True
            raise RequestRejected(HTTPStatus.REQUEST_ENTITY_TOO_LARGE, "TOO_LARGE")
        if length == 0:
            return None
        data = self.rfile.read(length)
        if len(data) != length:
            self.close_connection = True
            raise RequestRejected(HTTPStatus.BAD_REQUEST, "BODY")
        try:
            return loads(data)
        except JsonRejected:
            return None

    def _guarded(self, action):
        try:
            if not self._host_allowed():
                raise RequestRejected(HTTPStatus.FORBIDDEN, "HOST")
            action()
        except RequestRejected as rejection:
            self._send_error_code(rejection.status, rejection.code)
        except ValidationFailed as failure:
            self._send_json({"error": "VALIDATION", "errors": failure.errors}, HTTPStatus.UNPROCESSABLE_ENTITY)
        except MissingFile:
            self._send_error_code(HTTPStatus.NOT_FOUND, "MISSING_FILE")
        except (ConnectionError, TimeoutError):
            self.close_connection = True
        except Exception as error:
            sys.stderr.write(f"upgrade_editor: internal error ({type(error).__name__})\n")
            self.close_connection = True
            try:
                self._send_error_code(HTTPStatus.INTERNAL_SERVER_ERROR, "INTERNAL")
            except OSError:
                pass

    def do_GET(self):
        self._guarded(self._get)

    def do_PUT(self):
        self._guarded(self._mutate)

    def do_POST(self):
        self._guarded(self._mutate)

    def _get(self):
        path = self._request_path()
        if path.startswith("/api/"):
            return self._get_api(path)
        self._get_static(path)

    def _mutate(self):
        self._check_mutation()
        self._route_mutation(self.server.store, self._request_path())

    def _document_body(self):
        body = self._read_body()
        if not isinstance(body, dict) or "document" not in body:
            raise RequestRejected(HTTPStatus.BAD_REQUEST, "BODY")
        return body["document"]

    def _route_mutation(self, store, path):
        if path == "/api/document" and self.command == "PUT":
            document = self._document_body()
            with self.server.write_lock:
                saved = store.save_edited(document)
            return self._send_json({"source": "edited", "document": saved})
        if path == "/api/validate" and self.command == "POST":
            return self._send_json({"errors": store.validate(self._document_body())})
        if path == "/api/diff" and self.command == "POST":
            document = self._document_body()
            errors = store.validate(document)
            if errors:
                return self._send_json({"error": "VALIDATION", "errors": errors}, HTTPStatus.UNPROCESSABLE_ENTITY)
            return self._send_json({"changes": store.changes_for(document)})
        if path == "/api/reset" and self.command == "POST":
            self._read_body()
            with self.server.write_lock:
                archived = store.reset_edited()
            return self._send_json({"source": store.source(), "archived": archived.name if archived else None})
        self._send_error_code(HTTPStatus.NOT_FOUND, "ROUTE")

    def _get_api(self, path):
        store = self.server.store
        if path == "/api/document":
            return self._send_json({"source": store.source(), "document": store.load_active(), "original": store.load_original()})
        if path == "/api/changes":
            return self._send_json({"changes": store.changes()})
        self._send_error_code(HTTPStatus.NOT_FOUND, "ROUTE")

    def _get_static(self, path):
        target = static_target(self.server.web_dir, path)
        if target is None:
            return self._send_error_code(HTTPStatus.NOT_FOUND, "FILE")
        content = target.read_bytes()
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", STATIC_TYPES[target.suffix.lower()])
        self.send_header("Content-Length", str(len(content)))
        self.end_headers()
        self.wfile.write(content)
