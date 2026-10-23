#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work_dir="$(mktemp -d)"
server_pid=""
cleanup() {
  if [[ -n "$server_pid" ]]; then
    kill "$server_pid" 2>/dev/null || true
  fi
  rm -rf "$work_dir"
}
trap cleanup EXIT

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

python3 -I -B "$repo_dir/tests/fixtures/plane_fake_server.py" "$work_dir" &
server_pid=$!
for _ in $(seq 50); do
  [[ -s "$work_dir/port" ]] && break
  sleep 0.1
done
[[ -s "$work_dir/port" ]] || fail "servidor falso do Plane não subiu"

printf 'token-de-teste\n' > "$work_dir/token"
cat > "$work_dir/plane.env" <<EOF
PLANE_WORKSPACE=ws-teste
PLANE_API_TOKEN_FILE=$work_dir/token
PLANE_API_URL=http://127.0.0.1:$(cat "$work_dir/port")
EOF

cat > "$work_dir/issue.md" <<'EOF'
## Contexto

O solicitante não é avisado quando o **gestor** rejeita o pedido de `reembolso`.

## Definição

**Cenário:** gestor rejeita uma solicitação.

- **Dado** que existe uma solicitação aguardando aprovação
- **Quando** o gestor confirma a rejeição
- **Então** o solicitante recebe uma notificação

## Definition of done

- [ ] O solicitante recebe notificação na rejeição
- [ ] O motivo aparece na notificação
EOF

for script_path in \
  "$repo_dir/.codex/skills/plane-issue/scripts/plane.py" \
  "$repo_dir/.claude/skills/plane-issue/scripts/plane.py"; do
  rm -f "$work_dir/requests.jsonl"
  plane() {
    PLANE_CONFIG="$work_dir/plane.env" python3 -I -B "$script_path" "$@"
  }

  # check lista os projetos do workspace.
  plane check | grep -Fq 'PROJ: Projeto de teste' || fail "check não listou o projeto"

  # publish converte o DoD em taskList, cria, relê e confere os checkboxes.
  output="$(plane publish "$work_dir/issue.md" --project PROJ --name 'Notificar rejeição')"
  grep -Fq 'Publicada: PROJ-' <<<"$output" || fail "publish não devolveu o ID"
  grep -Fq 'Checklist: 2 checkboxes conferidos' <<<"$output" || fail "publish não conferiu a checklist"
  grep -Fq '/ws-teste/browse/PROJ-' <<<"$output" || fail "publish não montou o link"
  sent="$(grep '"POST"' "$work_dir/requests.jsonl")"
  grep -Fq 'data-type=\"taskList\"' <<<"$sent" || fail "checklist não virou taskList"
  grep -Fq 'data-checked=\"false\"' <<<"$sent" || fail "checkbox não saiu desmarcado"
  grep -Fq '<strong>gestor</strong>' <<<"$sent" || fail "negrito não convertido"
  grep -Fq '<code>reembolso</code>' <<<"$sent" || fail "código inline não convertido"
  grep -Fq '<h2>Contexto</h2>' <<<"$sent" || fail "título de seção não convertido"

  # get devolve Markdown com o checklist de volta em `- [ ]`.
  issue_id="$(sed -n 's/^Publicada: //p' <<<"$output")"
  fetched="$(plane get "$issue_id")"
  grep -Fq '# Notificar rejeição' <<<"$fetched" || fail "get não trouxe o título"
  grep -Fq -- '- [ ] O solicitante recebe notificação na rejeição' <<<"$fetched" || fail "get não reconstruiu o checklist"
  grep -Fq -- '- **Dado** que existe uma solicitação' <<<"$fetched" || fail "get não reconstruiu o Gherkin"

  # update substitui a descrição e confere de novo.
  printf '## Contexto\n\nTexto novo.\n\n- [ ] Único item\n' > "$work_dir/issue-v2.md"
  output="$(plane update "$issue_id" "$work_dir/issue-v2.md")"
  grep -Fq 'Checklist: 1 checkboxes conferidos' <<<"$output" || fail "update não conferiu a checklist"
  grep -Fq '"PATCH"' "$work_dir/requests.jsonl" || fail "update não enviou PATCH"

  # O token só trafega no header: nunca na saída nem no corpo das requisições.
  if grep -Fq 'token-de-teste' "$work_dir/requests.jsonl" || grep -Fq 'token-de-teste' <<<"$output$fetched"; then
    fail "token vazou para a saída ou para o corpo"
  fi

  # Token errado vira erro legível, com código de saída 1.
  printf 'outro-token\n' > "$work_dir/wrong-token"
  sed "s#$work_dir/token#$work_dir/wrong-token#" "$work_dir/plane.env" > "$work_dir/wrong.env"
  if PLANE_CONFIG="$work_dir/wrong.env" python3 -I -B "$script_path" check 2>"$work_dir/err"; then
    fail "token inválido não falhou"
  fi
  grep -Fq 'HTTP 401' "$work_dir/err" || fail "erro de autenticação não foi reportado"

  # Configuração ausente explica o que criar.
  if PLANE_CONFIG="$work_dir/nao-existe.env" python3 -I -B "$script_path" check 2>"$work_dir/err"; then
    fail "configuração ausente não falhou"
  fi
  grep -Fq 'PLANE_WORKSPACE e PLANE_API_TOKEN_FILE' "$work_dir/err" || fail "erro de configuração sem orientação"

  # Markdown → HTML → Markdown preserva o padrão de issue (exemplo da skill, tabela, lista
  # numerada, blockquote e marcação inline): o `get` precisa devolver o que o `publish` enviou.
  python3 -I -B - "$script_path" "$repo_dir/.codex/skills/plane-issue/references/plane-test.md" <<'PY' || fail "ida e volta Markdown/HTML alterou o texto"
import importlib.util
import sys

spec = importlib.util.spec_from_file_location("plane", sys.argv[1])
plane = importlib.util.module_from_spec(spec)
spec.loader.exec_module(plane)

samples = [
    open(sys.argv[2], encoding="utf-8").read(),
    "Antes.\n\n| Campo | Valor |\n|---|---|\n| `status` | **aprovado** |\n\nDepois.\n",
    "## Passos\n\n1. Abrir\n2. Fechar\n",
    "Texto *opcional* e **forte**.\n\n> Restrição: só no fluxo de rejeição.\n",
]
for sample in samples:
    back = plane.html_to_markdown(plane.markdown_to_html(sample))
    if back.strip() != sample.strip():
        print(f"esperado:\n{sample}\nobtido:\n{back}", file=sys.stderr)
        sys.exit(1)
PY

  # ID fora do formato é recusado antes de chamar a API.
  if plane get 'proj123' 2>"$work_dir/err"; then
    fail "ID inválido não falhou"
  fi
  grep -Fq 'Esperado <PROJETO>-<número>' "$work_dir/err" || fail "ID inválido sem orientação"
done

printf 'plane script is valid\n'
