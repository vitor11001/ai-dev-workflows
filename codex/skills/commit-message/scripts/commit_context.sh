#!/usr/bin/env bash
set -euo pipefail

# Garante que não haverá travamento de tela (pager)
export GIT_PAGER=cat

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Erro: este diretório não está dentro de um repositório Git." >&2
  exit 1
fi

CURRENT_BRANCH="$(git branch --show-current)"
STAGED_DIFF_EMPTY="false"

if git diff --cached --quiet; then
  STAGED_DIFF_EMPTY="true"
fi

echo "# Contexto para mensagem de commit"
echo ""
echo "## Branch atual: $CURRENT_BRANCH"

if [[ "$STAGED_DIFF_EMPTY" == "false" ]]; then
  echo "## Escopo analisado: alterações staged"

  echo ""
  echo "## Arquivos staged"
  git --no-pager diff --cached --name-status

  echo ""
  echo "## Diff stat staged"
  git --no-pager diff --cached --stat
else
  echo "## Escopo analisado: alterações não staged e arquivos não rastreados"

  echo ""
  echo "## Arquivos modificados"
  git --no-pager diff --name-status

  echo ""
  echo "## Arquivos não rastreados"
  git --no-pager ls-files --others --exclude-standard

  echo ""
  echo "## Diff stat"
  git --no-pager diff --stat
fi
