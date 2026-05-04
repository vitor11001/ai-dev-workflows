#!/usr/bin/env bash
set -euo pipefail

# Garante que não haverá travamento de tela (pager)
export GIT_PAGER=cat

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Erro: este diretório não está dentro de um repositório Git." >&2
  exit 1
fi

CURRENT_BRANCH="$(git branch --show-current)"

# Detecta a base branch (priorizando origin)
if git rev-parse --verify origin/master >/dev/null 2>&1; then
  BASE_BRANCH="origin/master"
elif git rev-parse --verify origin/main >/dev/null 2>&1; then
  BASE_BRANCH="origin/main"
elif git rev-parse --verify master >/dev/null 2>&1; then
  BASE_BRANCH="master"
elif git rev-parse --verify main >/dev/null 2>&1; then
  BASE_BRANCH="main"
else
  echo "Erro: Não foi possível encontrar master ou main." >&2
  exit 1
fi

# Converte a branch detectada em um Hash de commit para garantir 
# que o rtk e o git funcionem sem ambiguidade.
BASE_HASH=$(git rev-parse "$BASE_BRANCH")

echo "# Contexto para descrição de PR"
echo ""
echo "## Branch atual: $CURRENT_BRANCH"
echo "## Branch base: $BASE_BRANCH ($BASE_HASH)"

echo ""
echo "## Arquivos alterados"
git --no-pager diff --name-status "$BASE_HASH"..HEAD

echo ""
echo "## Diff stat"
git --no-pager diff --stat "$BASE_HASH"..HEAD

echo ""
echo "## Diff completo"
# Usando o Hash aqui para que o rtk não se perca com referências remotas
rtk git --no-pager diff "$BASE_HASH"..HEAD