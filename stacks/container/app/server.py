"""Tiny echo server with a health endpoint.

Zero third-party dependencies on purpose: the point of this stack is the
Dockerfile and the hooks that lint it, not the application.
"""

from __future__ import annotations

import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

# S104: binding all interfaces is correct inside a container - the network
# boundary is the container's, not the process's.
LISTEN_HOST = os.environ.get("LISTEN_HOST", "0.0.0.0")  # noqa: S104
LISTEN_PORT = int(os.environ.get("LISTEN_PORT", "8080"))


class Handler(BaseHTTPRequestHandler):
    """Serves /healthz and echoes everything else back as JSON."""

    server_version = "precommit-showcase/0.1"

    # The mixed-case name is mandated by BaseHTTPRequestHandler's dispatch.
    def do_GET(self) -> None:
        """Handle a GET request."""
        if self.path == "/healthz":
            self._respond(200, {"status": "ok"})
            return
        self._respond(200, {"path": self.path, "method": "GET"})

    def log_message(self, format: str, *args: object) -> None:  # noqa: A002
        """Emit one structured log line per request instead of Apache-style text."""
        print(
            json.dumps(
                {
                    "client": self.address_string(),
                    "message": format % args,
                }
            ),
            flush=True,
        )

    def _respond(self, status: int, payload: dict[str, object]) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def main() -> None:
    """Run the server until interrupted."""
    server = ThreadingHTTPServer((LISTEN_HOST, LISTEN_PORT), Handler)
    print(f"listening on {LISTEN_HOST}:{LISTEN_PORT}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        server.shutdown()


if __name__ == "__main__":
    main()
