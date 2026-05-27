#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

chmod_repo_scripts() {
  while IFS= read -r script_file; do
    chmod +x "$script_file"
  done < <(find "$REPO_DIR" -path "$REPO_DIR/.git" -prune -o -type f -name '*.sh' -print)
}

run_copy() {
  local target="$1"
  "$REPO_DIR/scripts/install-copy.sh" "$target"
}

run_symlink() {
  local target="$1"
  "$REPO_DIR/scripts/install-symlink.sh" "$target"
}

run_mode() {
  local mode="$1"
  local target="$2"

  case "$target" in
    codex)
      case "$mode" in
        copy) run_copy codex ;;
        symlink) run_symlink codex ;;
      esac
      ;;
    claude)
      case "$mode" in
        copy) run_copy claude ;;
        symlink) run_symlink claude ;;
      esac
      ;;
    all)
      case "$mode" in
        copy)
          run_copy codex
          echo
          run_copy claude
          ;;
        symlink)
          run_symlink codex
          echo
          run_symlink claude
          ;;
      esac
      ;;
  esac
}

handle_flag() {
  case "$1" in
    --copy-codex) run_mode copy codex ;;
    --copy-claude) run_mode copy claude ;;
    --copy-all) run_mode copy all ;;
    --symlink-codex) run_mode symlink codex ;;
    --symlink-claude) run_mode symlink claude ;;
    --symlink-all) run_mode symlink all ;;
    *)
      echo "Flag invalida: $1" >&2
      echo "Use uma das flags:" >&2
      echo "  --copy-codex     --copy-claude     --copy-all" >&2
      echo "  --symlink-codex  --symlink-claude  --symlink-all" >&2
      exit 1
      ;;
  esac
}

chmod_repo_scripts

if [[ $# -gt 0 ]]; then
  handle_flag "$1"
  exit 0
fi

echo "Escolha a ferramenta para instalar:"
echo "1) Codex"
echo "2) Claude"
echo "3) Ambos"
echo
read -r -p "Opcao [1-3]: " tool_option

case "$tool_option" in
  1) TARGET="codex" ;;
  2) TARGET="claude" ;;
  3) TARGET="all" ;;
  *)
    echo "Opcao invalida: $tool_option" >&2
    exit 1
    ;;
esac

echo
echo "Escolha o modo de instalacao:"
echo "1) Copia (copiar skills para o diretorio do usuario)"
echo "2) Symlink (apontar skills para este repositorio)"
echo
read -r -p "Opcao [1-2]: " mode_option

case "$mode_option" in
  1) MODE="copy" ;;
  2) MODE="symlink" ;;
  *)
    echo "Opcao invalida: $mode_option" >&2
    exit 1
    ;;
esac

run_mode "$MODE" "$TARGET"
