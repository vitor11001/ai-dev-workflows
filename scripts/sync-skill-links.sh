#!/usr/bin/env bash
set -euo pipefail

# Chamado pelos git hooks de .githooks/. Reaplica a instalação por symlink, em modo
# silencioso, para cada ferramenta já instalada por symlink a partir deste repositório.
# Instalação por cópia (ou ausente) não é tocada.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

installed_by_symlink() {
  local target="$1"
  local skills_source="$REPO_DIR/.$target/skills/"
  local target_path

  for target_path in "$HOME/.$target/skills"/*; do
    if [[ -L "$target_path" && "$(readlink "$target_path")" == "$skills_source"* ]]; then
      return 0
    fi
  done

  return 1
}

for target in claude codex; do
  if installed_by_symlink "$target"; then
    "$REPO_DIR/scripts/install-symlink.sh" "$target" --quiet
  fi
done
