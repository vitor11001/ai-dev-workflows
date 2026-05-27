#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

chmod_repo_scripts() {
  while IFS= read -r script_file; do
    chmod +x "$script_file"
  done < <(find "$REPO_DIR" -path "$REPO_DIR/.git" -prune -o -type f -name '*.sh' -print)
}

run_installer() {
  local mode="$1"

  case "$mode" in
    copy | --copy | -c)
      "$REPO_DIR/scripts/install-copy.sh"
      ;;
    symlink | link | --symlink | --link | -s)
      "$REPO_DIR/scripts/install-symlink.sh"
      ;;
    *)
      echo "Opcao invalida: $mode" >&2
      exit 1
      ;;
  esac
}

chmod_repo_scripts

if [[ $# -gt 0 ]]; then
  run_installer "$1"
  exit 0
fi

echo "Escolha o modo de instalacao:"
echo "1) Padrao: copiar skills para ~/.codex/skills"
echo "2) Symlink: apontar skills para este repositorio"
echo
read -r -p "Opcao [1-2]: " option

case "$option" in
  1)
    run_installer copy
    ;;
  2)
    run_installer symlink
    ;;
  *)
    echo "Opcao invalida: $option" >&2
    exit 1
    ;;
esac
