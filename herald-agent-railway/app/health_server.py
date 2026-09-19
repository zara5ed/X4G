#!/usr/bin/env python3
"""Herald health endpoint.

A deliberately tiny, dependency-free HTTP server so that Railway (and any
uptime monitor you point at it) can check liveness without touching the
agent's own API surface.

Endpoints
    GET /healthz    → 200 while the process is alive          (liveness)
    GET /readyz     → 200 once the bootstrap finished, 503 otherwise
    GET /           → 200 service card, no secrets
    *               → 404

Notes
    • Standard library only — nothing to install, nothing to patch.
    • Binds 0.0.0.0 because Railway routes traffic from outside the container.
    • Never echoes environment variables or request headers.
"""

from __future__ import annotations

import json
import os
import signal
import sys
import threading
import time
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

READY_FILE = os.environ.get("HERALD_READY_FILE", "/tmp/herald-ready.json")
AGENT_NAME = os.environ.get("HERALD_AGENT_NAME", "Herald")
VERSION = os.environ.get("HERALD_VERSION", "1.0.0")
REPO_URL = os.environ.get("HERALD_REPO_URL", "https://github.com/NousResearch/hermes-agent")

STARTED_AT = time.time()


def _readiness() -> tuple[bool, dict]:
    """Return (ready, details) based on the file written by bootstrap.sh."""
    try:
        with open(READY_FILE, encoding="utf-8") as handle:
            details = json.load(handle)
        return bool(details.get("ready")), details
    except (OSError, ValueError):
        return False, {}


class Handler(BaseHTTPRequestHandler):
    server_version = f"Herald/{VERSION}"
    sys_version = ""            # keep the banner compact
    protocol_version = "HTTP/1.1"

    # ── internals ────────────────────────────────────────────────────────────
    def _send_json(self, status: HTTPStatus, payload: dict) -> None:
        body = json.dumps(payload, separators=(",", ":")).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)

    def _route(self) -> None:  # noqa: C901 - three branches, kept flat for clarity
        path = self.path.split("?", 1)[0].rstrip("/") or "/"

        if path == "/healthz":
            self._send_json(
                HTTPStatus.OK,
                {"status": "ok", "agent": AGENT_NAME, "uptime_s": int(time.time() - STARTED_AT)},
            )
            return

        if path == "/readyz":
            ready, details = _readiness()
            payload = {"status": "ready" if ready else "starting", "agent": AGENT_NAME}
            payload.update({k: v for k, v in details.items() if k not in {"ready", "agent"}})
            self._send_json(HTTPStatus.OK if ready else HTTPStatus.SERVICE_UNAVAILABLE, payload)
            return

        if path == "/":
            _, details = _readiness()
            self._send_json(
                HTTPStatus.OK,
                {
                    "service": f"{AGENT_NAME} — self-hosted AI agent gateway",
                    "version": VERSION,
                    "uptime_s": int(time.time() - STARTED_AT),
                    "channels": details.get("platforms", []),
                    "endpoints": ["/healthz", "/readyz"],
                    "runtime": {"engine": "Hermes Agent (MIT)", "source": REPO_URL},
                },
            )
            return

        self._send_json(HTTPStatus.NOT_FOUND, {"error": "not_found"})

    # ── HTTP verbs ───────────────────────────────────────────────────────────
    def do_GET(self) -> None:  # noqa: N802 - name required by BaseHTTPRequestHandler
        self._route()

    def do_HEAD(self) -> None:  # noqa: N802
        self._route()

    def log_message(self, fmt: str, *args) -> None:  # noqa: A002
        # Strip the query string and keep one short line per request.
        sys.stderr.write(f"[health] {self.command} {self.path.split('?', 1)[0]} {args[1] if len(args) > 1 else ''}\n")


def main() -> int:
    try:
        port = int(os.environ.get("HERALD_HEALTH_PORT") or os.environ.get("PORT") or 8080)
    except ValueError:
        port = 8080

    server = ThreadingHTTPServer(("0.0.0.0", port), Handler)
    server.daemon_threads = True

    def _stop(_signum, _frame):  # pragma: no cover - signal path
        # BaseServer.shutdown() blocks until serve_forever() returns, so calling
        # it directly from this handler (same thread) deadlocks and the process
        # ignores SIGTERM. Hand the stop over to a helper thread instead.
        threading.Thread(target=server.shutdown, daemon=True).start()

    signal.signal(signal.SIGTERM, _stop)
    signal.signal(signal.SIGINT, _stop)

    sys.stderr.write(f"[health] {AGENT_NAME} health endpoint on 0.0.0.0:{port} (/healthz, /readyz)\n")
    try:
        server.serve_forever()
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
