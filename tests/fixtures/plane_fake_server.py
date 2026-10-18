"""Servidor falso da API v1 do Plane para os testes de `plane-issue/scripts/plane.py`.

Guarda os work items em memória, exige o header `X-API-Key` e registra cada requisição em
`<estado>/requests.jsonl` para o teste conferir o que foi enviado.
"""

from __future__ import annotations

import json
import re
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

EXPECTED_TOKEN = "token-de-teste"
WORKSPACE = "ws-teste"
PROJECT = {"id": "proj-uuid", "identifier": "PROJ", "name": "Projeto de teste"}


class FakePlane(BaseHTTPRequestHandler):
    """Implementa só as rotas usadas pelo script: projetos, criar, buscar e atualizar."""

    state_dir: Path
    work_items: dict[str, dict] = {}

    def log_message(self, *args: object) -> None:  # silencia o log padrão no stderr
        return

    def _record(self, body: dict | None) -> None:
        with (self.state_dir / "requests.jsonl").open("a", encoding="utf-8") as log:
            log.write(json.dumps({"method": self.command, "path": self.path, "body": body}) + "\n")

    def _reply(self, status: int, payload: dict) -> None:
        data = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _body(self) -> dict | None:
        length = int(self.headers.get("Content-Length") or 0)
        return json.loads(self.rfile.read(length)) if length else None

    def _handle(self) -> None:
        body = self._body()
        self._record(body)
        if self.headers.get("X-API-Key") != EXPECTED_TOKEN:
            self._reply(401, {"detail": "invalid token"})
            return

        base = f"/api/v1/workspaces/{WORKSPACE}/"
        path = self.path.split("?", 1)[0]
        if not path.startswith(base):
            self._reply(404, {"detail": "workspace"})
            return
        route = path[len(base):]

        if self.command == "GET" and route == "projects/":
            self._reply(200, {"results": [PROJECT], "next_page_results": False, "next_cursor": None})
            return

        if self.command == "POST" and route == f"projects/{PROJECT['id']}/work-items/":
            sequence_id = len(self.work_items) + 1
            item = {"id": f"wi-{sequence_id}", "sequence_id": sequence_id, **body}
            self.work_items[item["id"]] = item
            self._reply(201, item)
            return

        match = re.fullmatch(rf"projects/{PROJECT['id']}/work-items/(wi-\d+)/", route)
        if match and match.group(1) in self.work_items:
            item = self.work_items[match.group(1)]
            if self.command == "PATCH":
                item.update(body or {})
            self._reply(200, item)
            return

        match = re.fullmatch(r"work-items/PROJ-(\d+)/", route)
        if self.command == "GET" and match:
            for item in self.work_items.values():
                if str(item["sequence_id"]) == match.group(1):
                    self._reply(200, item)
                    return

        self._reply(404, {"detail": "not found"})

    do_GET = do_POST = do_PATCH = _handle


def main() -> None:
    state_dir = Path(sys.argv[1])
    FakePlane.state_dir = state_dir
    server = HTTPServer(("127.0.0.1", 0), FakePlane)
    (state_dir / "port").write_text(str(server.server_address[1]), encoding="utf-8")
    server.serve_forever()


if __name__ == "__main__":
    main()
