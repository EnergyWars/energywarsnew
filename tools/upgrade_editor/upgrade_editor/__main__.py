import argparse
import json
import sys
import webbrowser
from pathlib import Path

from .server import create_server, is_loopback_host, lan_addresses
from .store import DocumentStore, MissingFile, ValidationFailed

DEFAULT_PORT = 48731
DEFAULT_HOST = "127.0.0.1"
PACKAGE_DIR = Path(__file__).resolve().parent
TOOL_DIR = PACKAGE_DIR.parent
ROOT = TOOL_DIR.parent.parent


def default_store():
    return DocumentStore(TOOL_DIR / "data", ROOT / "src" / "core" / "game_config.gd", ROOT / "data" / "upgrade_overrides.json")


def serve(arguments):
    try:
        server = create_server(default_store(), TOOL_DIR / "web", arguments.port, arguments.host)
    except OSError as error:
        print(f"port {arguments.port} unavailable: {error}", file=sys.stderr)
        return 3
    port = server.server_address[1]
    url = f"http://127.0.0.1:{port}/"
    print(url, flush=True)
    if not is_loopback_host(arguments.host):
        for address in lan_addresses():
            print(f"http://{address}:{port}/", flush=True)
    if not arguments.no_browser:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


def print_changes(store):
    for change in store.changes():
        print(json.dumps(change, ensure_ascii=False))
    return 0


def validate(store):
    errors = store.validate(store.load_active())
    for error in errors:
        print(json.dumps(error, ensure_ascii=False))
    return 1 if errors else 0


def apply(store):
    print(json.dumps(store.promote(), ensure_ascii=False, indent=2))
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(prog="upgrade_editor")
    commands = parser.add_subparsers(dest="command")
    serve_parser = commands.add_parser("serve")
    serve_parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    serve_parser.add_argument("--host", default=DEFAULT_HOST)
    serve_parser.add_argument("--no-browser", action="store_true")
    for name in ("changes", "validate", "apply"):
        commands.add_parser(name)
    arguments = parser.parse_args(argv)
    command = arguments.command or "serve"
    if arguments.command is None:
        arguments = parser.parse_args(["serve"])
    store = default_store()
    try:
        if command == "serve":
            return serve(arguments)
        return {"changes": print_changes, "validate": validate, "apply": apply}[command](store)
    except MissingFile as error:
        print(f"missing file: {error}", file=sys.stderr)
        return 2
    except ValidationFailed as failure:
        for error in failure.errors:
            print(json.dumps(error, ensure_ascii=False), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
