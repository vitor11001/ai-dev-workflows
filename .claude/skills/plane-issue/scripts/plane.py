#!/usr/bin/env python3
"""Cliente mínimo da API do Plane Cloud para publicar, atualizar e buscar issues (work items).

Configuração em ~/.config/ai-dev-workflows/plane.env (ou no caminho de PLANE_CONFIG):

    PLANE_WORKSPACE=meu-workspace
    PLANE_API_TOKEN_FILE=~/.secrets/plane-token
    PLANE_API_URL=https://api.plane.so      # opcional
    PLANE_APP_URL=https://app.plane.so      # opcional, usado só para montar o link

O token é lido do arquivo indicado e enviado apenas no header `X-API-Key`; nunca é
impresso nem passado em argumento de linha de comando.

Uso:
    plane.py check
    plane.py publish <arquivo.md> --project <IDENT> --name "<título>"
    plane.py update <IDENT-N> <arquivo.md> [--name "<título>"]
    plane.py get <IDENT-N>
"""

from __future__ import annotations

import argparse
import html
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from html.parser import HTMLParser
from pathlib import Path

DEFAULT_CONFIG_PATH = "~/.config/ai-dev-workflows/plane.env"
DEFAULT_API_URL = "https://api.plane.so"
DEFAULT_APP_URL = "https://app.plane.so"
ISSUE_ID_PATTERN = re.compile(r"^([A-Za-z0-9]+)-(\d+)$")

TASK_ITEM_HTML = (
    '<li data-type="taskItem" data-checked="{checked}">'
    '<label contenteditable="false"><input type="checkbox"{checked_attr}><span></span></label>'
    "<div><p>{text}</p></div></li>"
)


class PlaneError(Exception):
    """Falha de configuração ou de chamada à API, com mensagem pronta para o usuário."""


def load_config() -> dict[str, str]:
    """Lê o arquivo de configuração `CHAVE=valor` e valida as chaves obrigatórias."""
    config_path = Path(os.environ.get("PLANE_CONFIG", DEFAULT_CONFIG_PATH)).expanduser()
    if not config_path.is_file():
        raise PlaneError(
            f"Configuração não encontrada em {config_path}. Crie o arquivo com "
            "PLANE_WORKSPACE e PLANE_API_TOKEN_FILE (ver o topo deste script)."
        )

    config: dict[str, str] = {}
    for raw_line in config_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.split("#", 1)[0].strip()
        if "=" in line:
            key, value = line.split("=", 1)
            config[key.strip()] = value.strip().strip("'\"")

    missing = [key for key in ("PLANE_WORKSPACE", "PLANE_API_TOKEN_FILE") if not config.get(key)]
    if missing:
        raise PlaneError(f"Chaves ausentes em {config_path}: {', '.join(missing)}.")

    token_path = Path(config["PLANE_API_TOKEN_FILE"]).expanduser()
    if not token_path.is_file():
        raise PlaneError(f"Arquivo do token não encontrado: {token_path}.")
    config["token"] = token_path.read_text(encoding="utf-8").strip()
    if not config["token"]:
        raise PlaneError(f"Arquivo do token está vazio: {token_path}.")

    config.setdefault("PLANE_API_URL", DEFAULT_API_URL)
    config.setdefault("PLANE_APP_URL", DEFAULT_APP_URL)
    return config


class PlaneClient:
    """Chamadas HTTP autenticadas à API v1 do Plane."""

    def __init__(self, config: dict[str, str]) -> None:
        self._token = config["token"]
        self._api_url = config["PLANE_API_URL"].rstrip("/")
        self.workspace = config["PLANE_WORKSPACE"]
        self.app_url = config["PLANE_APP_URL"].rstrip("/")

    def request(self, method: str, path: str, payload: dict[str, object] | None = None) -> dict:
        """Executa a chamada e devolve o JSON da resposta; erros viram `PlaneError`."""
        url = f"{self._api_url}/api/v1/workspaces/{self.workspace}/{path.lstrip('/')}"
        data = json.dumps(payload).encode("utf-8") if payload is not None else None
        request = urllib.request.Request(url, data=data, method=method)
        request.add_header("X-API-Key", self._token)
        request.add_header("Content-Type", "application/json")
        request.add_header("Accept", "application/json")
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                body = response.read().decode("utf-8")
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")[:500]
            if exc.code == 429:
                reset = exc.headers.get("X-RateLimit-Reset", "desconhecido")
                raise PlaneError(f"Limite de 60 requisições/minuto atingido; reset em {reset} (epoch UTC).") from exc
            raise PlaneError(f"{method} {url} falhou com HTTP {exc.code}: {detail}") from exc
        except urllib.error.URLError as exc:
            raise PlaneError(f"Não foi possível acessar {url}: {exc.reason}") from exc
        return json.loads(body) if body else {}

    def list_projects(self) -> list[dict]:
        """Lista todos os projetos do workspace, seguindo a paginação por cursor."""
        projects: list[dict] = []
        cursor = ""
        while True:
            query = urllib.parse.urlencode({"per_page": 100, **({"cursor": cursor} if cursor else {})})
            page = self.request("GET", f"projects/?{query}")
            projects.extend(page.get("results", []))
            if not page.get("next_page_results"):
                return projects
            cursor = page["next_cursor"]

    def project_id(self, identifier: str) -> str:
        """Resolve o identificador legível (ex.: `PROJ`) para o id interno do projeto."""
        for project in self.list_projects():
            if project.get("identifier", "").upper() == identifier.upper():
                return project["id"]
        raise PlaneError(f"Projeto com identificador {identifier} não encontrado no workspace {self.workspace}.")

    def get_issue(self, issue_id: str) -> dict:
        """Busca a issue pelo identificador legível (`PROJ-123`)."""
        parse_issue_id(issue_id)
        return self.request("GET", f"work-items/{issue_id.upper()}/")

    def browse_link(self, identifier: str, sequence_id: object) -> str:
        """Monta o link da issue na interface web."""
        return f"{self.app_url}/{self.workspace}/browse/{identifier.upper()}-{sequence_id}/"


def parse_issue_id(issue_id: str) -> tuple[str, str]:
    """Valida `PROJ-123` e devolve (identificador do projeto, número)."""
    match = ISSUE_ID_PATTERN.match(issue_id)
    if not match:
        raise PlaneError(f"Identificador inválido: {issue_id}. Esperado <PROJETO>-<número>, ex.: PROJ-123.")
    return match.group(1), match.group(2)


def inline_markdown(text: str) -> str:
    """Converte a marcação inline usada nas issues: `código`, **negrito** e *itálico*."""
    parts = re.split(r"(`[^`]+`)", text)
    converted: list[str] = []
    for part in parts:
        if part.startswith("`") and part.endswith("`") and len(part) > 1:
            converted.append(f"<code>{html.escape(part[1:-1])}</code>")
            continue
        escaped = html.escape(part)
        escaped = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", escaped)
        escaped = re.sub(r"(?<![*\w])\*(?!\s)(.+?)(?<!\s)\*(?![*\w])", r"<em>\1</em>", escaped)
        converted.append(escaped)
    return "".join(converted)


def markdown_to_html(markdown: str) -> str:
    """Converte o Markdown do padrão de issue para o HTML do editor do Plane.

    Cobre o que o padrão usa: títulos, parágrafos, listas, checklist (`- [ ]`), blockquote e
    tabela simples. Checklist vira `taskList`, o formato que o editor do Plane persiste.
    """
    blocks: list[str] = []
    lines = markdown.splitlines()
    index = 0

    while index < len(lines):
        line = lines[index].rstrip()
        stripped = line.strip()

        if not stripped:
            index += 1
            continue

        heading = re.match(r"^(#{1,6})\s+(.*)$", stripped)
        if heading:
            level = len(heading.group(1))
            blocks.append(f"<h{level}>{inline_markdown(heading.group(2))}</h{level}>")
            index += 1
            continue

        if re.match(r"^- \[[ xX]\]\s+", stripped):
            items: list[str] = []
            while index < len(lines) and re.match(r"^\s*- \[[ xX]\]\s+", lines[index]):
                item = re.match(r"^\s*- \[([ xX])\]\s+(.*)$", lines[index])
                checked = item.group(1).lower() == "x"
                items.append(
                    TASK_ITEM_HTML.format(
                        checked="true" if checked else "false",
                        checked_attr=" checked" if checked else "",
                        text=inline_markdown(item.group(2).strip()),
                    )
                )
                index += 1
            blocks.append(f'<ul data-type="taskList">{"".join(items)}</ul>')
            continue

        if re.match(r"^[-*]\s+", stripped):
            items = []
            while index < len(lines) and re.match(r"^\s*[-*]\s+(?!\[[ xX]\])", lines[index]):
                text = re.sub(r"^\s*[-*]\s+", "", lines[index]).strip()
                items.append(f"<li><p>{inline_markdown(text)}</p></li>")
                index += 1
            blocks.append(f"<ul>{''.join(items)}</ul>")
            continue

        if re.match(r"^\d+\.\s+", stripped):
            items = []
            while index < len(lines) and re.match(r"^\s*\d+\.\s+", lines[index]):
                text = re.sub(r"^\s*\d+\.\s+", "", lines[index]).strip()
                items.append(f"<li><p>{inline_markdown(text)}</p></li>")
                index += 1
            blocks.append(f"<ol>{''.join(items)}</ol>")
            continue

        if stripped.startswith(">"):
            quoted: list[str] = []
            while index < len(lines) and lines[index].strip().startswith(">"):
                quoted.append(lines[index].strip().lstrip(">").strip())
                index += 1
            blocks.append(f"<blockquote><p>{inline_markdown(' '.join(quoted))}</p></blockquote>")
            continue

        if stripped.startswith("|"):
            rows: list[list[str]] = []
            while index < len(lines) and lines[index].strip().startswith("|"):
                cells = [cell.strip() for cell in lines[index].strip().strip("|").split("|")]
                if not all(re.fullmatch(r":?-{3,}:?", cell) for cell in cells):
                    rows.append(cells)
                index += 1
            header, *body = rows
            head_html = "".join(f"<th><p>{inline_markdown(cell)}</p></th>" for cell in header)
            body_html = "".join(
                "<tr>" + "".join(f"<td><p>{inline_markdown(cell)}</p></td>" for cell in row) + "</tr>"
                for row in body
            )
            blocks.append(f"<table><tbody><tr>{head_html}</tr>{body_html}</tbody></table>")
            continue

        paragraph: list[str] = []
        while index < len(lines) and lines[index].strip() and not re.match(
            r"^(#{1,6}\s|[-*]\s|\d+\.\s|>|\|)", lines[index].strip()
        ):
            paragraph.append(lines[index].strip())
            index += 1
        blocks.append(f"<p>{inline_markdown(' '.join(paragraph))}</p>")

    return "".join(blocks)


class HtmlToMarkdown(HTMLParser):
    """Converte o HTML do Plane de volta para Markdown, no mesmo subconjunto da ida."""

    def __init__(self) -> None:
        super().__init__()
        self.parts: list[str] = []
        self._list_stack: list[str] = []
        self._task_checked: str | None = None
        self._in_label = False
        self._in_blockquote = False
        self._table_row = -1
        self._table_cells = 0
        self._ol_counters: list[int] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attributes = dict(attrs)
        if tag in {"h1", "h2", "h3", "h4", "h5", "h6"}:
            self.parts.append("\n\n" + "#" * int(tag[1]) + " ")
        elif tag in {"ul", "ol"}:
            if not self._list_stack:
                self.parts.append("\n")
            if tag == "ol":
                self._list_stack.append("ol")
                self._ol_counters.append(0)
            else:
                self._list_stack.append("task" if attributes.get("data-type") == "taskList" else "ul")
        elif tag == "li":
            kind = self._list_stack[-1] if self._list_stack else "ul"
            if kind == "task" or attributes.get("data-type") == "taskItem":
                checked = attributes.get("data-checked") == "true"
                self.parts.append("\n- [x] " if checked else "\n- [ ] ")
            elif kind == "ol":
                self._ol_counters[-1] += 1
                self.parts.append(f"\n{self._ol_counters[-1]}. ")
            else:
                self.parts.append("\n- ")
        elif tag == "label":
            self._in_label = True
        elif tag == "p" and not self._list_stack and not self._in_blockquote and self._table_row < 0:
            self.parts.append("\n\n")
        elif tag == "blockquote":
            self._in_blockquote = True
            self.parts.append("\n\n> ")
        elif tag == "strong":
            self.parts.append("**")
        elif tag == "em":
            self.parts.append("*")
        elif tag == "code":
            self.parts.append("`")
        elif tag == "table":
            self._table_row = 0
            self.parts.append("\n")
        elif tag == "tr":
            self._table_cells = 0
            self.parts.append("\n|")
        elif tag in {"td", "th"}:
            self._table_cells += 1
            self.parts.append(" ")
        elif tag == "br":
            self.parts.append("\n")

    def handle_endtag(self, tag: str) -> None:
        if tag in {"ul", "ol"} and self._list_stack:
            if self._list_stack.pop() == "ol":
                self._ol_counters.pop()
            if not self._list_stack:
                self.parts.append("\n")
        elif tag == "label":
            self._in_label = False
        elif tag == "blockquote":
            self._in_blockquote = False
        elif tag == "strong":
            self.parts.append("**")
        elif tag == "em":
            self.parts.append("*")
        elif tag == "code":
            self.parts.append("`")
        elif tag in {"td", "th"}:
            self.parts.append(" |")
        elif tag == "tr" and self._table_row >= 0:
            if self._table_row == 0:
                self.parts.append("\n|" + "---|" * self._table_cells)
            self._table_row += 1
        elif tag == "table":
            self._table_row = -1
            self.parts.append("\n")

    def handle_data(self, data: str) -> None:
        if not self._in_label:
            self.parts.append(data)

    def markdown(self) -> str:
        """Devolve o Markdown acumulado, sem linhas em branco em excesso."""
        text = "".join(self.parts)
        return re.sub(r"\n{3,}", "\n\n", text).strip() + "\n"


def html_to_markdown(content: str) -> str:
    """Converte `description_html` para Markdown."""
    parser = HtmlToMarkdown()
    parser.feed(content)
    return parser.markdown()


def description_html_of(issue: dict) -> str | None:
    """Extrai o HTML da descrição, que a API pode devolver em campos diferentes."""
    for field in ("description_html", "description"):
        value = issue.get(field)
        if isinstance(value, str) and value.strip().startswith("<"):
            return value
    return None


def verify_task_items(issue: dict, expected: int) -> str:
    """Confere se os checkboxes persistiram como `taskItem` não marcados."""
    stored = description_html_of(issue)
    if stored is None:
        return "não conferido: a resposta da API não trouxe o HTML da descrição"
    found = len(re.findall(r'data-type="taskItem"', stored))
    if found != expected:
        raise PlaneError(f"Checklist não persistiu: esperado {expected} taskItem, gravado {found}.")
    return f"{found} checkboxes conferidos"


def command_check(client: PlaneClient) -> None:
    projects = client.list_projects()
    print(f"Configuração válida. Workspace {client.workspace}, {len(projects)} projetos:")
    for project in projects:
        print(f"- {project.get('identifier')}: {project.get('name')}")


def command_publish(client: PlaneClient, markdown_path: Path, project: str, name: str) -> None:
    markdown = markdown_path.read_text(encoding="utf-8")
    description = markdown_to_html(markdown)
    expected = description.count('data-type="taskItem"')
    project_id = client.project_id(project)
    created = client.request(
        "POST", f"projects/{project_id}/work-items/", {"name": name, "description_html": description}
    )
    stored = client.request("GET", f"projects/{project_id}/work-items/{created['id']}/")
    check = verify_task_items(stored, expected)
    issue_id = f"{project.upper()}-{created['sequence_id']}"
    print(f"Publicada: {issue_id}")
    print(f"Link: {client.browse_link(project, created['sequence_id'])}")
    print(f"Checklist: {check}")


def command_update(client: PlaneClient, issue_id: str, markdown_path: Path, name: str | None) -> None:
    project, number = parse_issue_id(issue_id)
    current = client.get_issue(issue_id)
    project_id = client.project_id(project)
    description = markdown_to_html(markdown_path.read_text(encoding="utf-8"))
    payload: dict[str, object] = {"description_html": description}
    if name:
        payload["name"] = name
    client.request("PATCH", f"projects/{project_id}/work-items/{current['id']}/", payload)
    stored = client.request("GET", f"projects/{project_id}/work-items/{current['id']}/")
    check = verify_task_items(stored, description.count('data-type="taskItem"'))
    print(f"Atualizada: {issue_id.upper()}")
    print(f"Link: {client.browse_link(project, current.get('sequence_id', number))}")
    print(f"Checklist: {check}")


def command_get(client: PlaneClient, issue_id: str) -> None:
    issue = client.get_issue(issue_id)
    stored = description_html_of(issue)
    body = html_to_markdown(stored) if stored else str(issue.get("description_stripped") or "")
    project, number = parse_issue_id(issue_id)
    print(f"<!-- {issue_id.upper()} — {client.browse_link(project, number)} -->")
    print(f"# {issue.get('name', '')}\n")
    print(body)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Cliente da API do Plane Cloud.")
    subcommands = parser.add_subparsers(dest="command", required=True)
    subcommands.add_parser("check", help="valida a configuração e lista os projetos")
    publish = subcommands.add_parser("publish", help="cria a issue a partir de um Markdown")
    publish.add_argument("markdown", type=Path)
    publish.add_argument("--project", required=True, help="identificador do projeto, ex.: PROJ")
    publish.add_argument("--name", required=True, help="título da issue")
    update = subcommands.add_parser("update", help="atualiza a descrição de uma issue existente")
    update.add_argument("issue_id")
    update.add_argument("markdown", type=Path)
    update.add_argument("--name")
    get = subcommands.add_parser("get", help="imprime a issue em Markdown")
    get.add_argument("issue_id")
    args = parser.parse_args(argv)

    try:
        client = PlaneClient(load_config())
        if args.command == "check":
            command_check(client)
        elif args.command == "publish":
            command_publish(client, args.markdown, args.project, args.name)
        elif args.command == "update":
            command_update(client, args.issue_id, args.markdown, args.name)
        else:
            command_get(client, args.issue_id)
    except PlaneError as exc:
        print(f"Erro: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
