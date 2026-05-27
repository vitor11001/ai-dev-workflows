#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  echo "Uso: install-copy.sh <codex|claude>" >&2
  exit 1
fi

case "$TARGET" in
  codex)
    SOURCE_DIR_NAME=".codex"
    INSTRUCTIONS_FILENAME="AGENTS.md"
    USER_BASE="$HOME/.codex"
    ;;
  claude)
    SOURCE_DIR_NAME=".claude"
    INSTRUCTIONS_FILENAME="CLAUDE.md"
    USER_BASE="$HOME/.claude"
    ;;
  *)
    echo "Target invalido: $TARGET (use codex ou claude)" >&2
    exit 1
    ;;
esac

SKILLS_DIR="$REPO_DIR/$SOURCE_DIR_NAME/skills"
TARGET_DIR="$USER_BASE/skills"
BACKUP_ROOT="$USER_BASE/skills-backup"
BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
PROJECT_CONFIG_DIR="$USER_BASE/ai-dev-workflows"
PROJECT_INSTRUCTIONS_SOURCE="$REPO_DIR/$SOURCE_DIR_NAME/$INSTRUCTIONS_FILENAME"
PROJECT_INSTRUCTIONS_TARGET="$PROJECT_CONFIG_DIR/$INSTRUCTIONS_FILENAME"
USER_INSTRUCTIONS_FILE="$USER_BASE/$INSTRUCTIONS_FILENAME"
INCLUDE_LINE="@${PROJECT_INSTRUCTIONS_TARGET}"

chmod_repo_scripts() {
  while IFS= read -r script_file; do
    chmod +x "$script_file"
  done < <(find "$REPO_DIR" -path "$REPO_DIR/.git" -prune -o -type f -name '*.sh' -print)
}

chmod_skill_scripts() {
  local skill_dir="$1"

  if [[ ! -d "$skill_dir/scripts" ]]; then
    return
  fi

  while IFS= read -r script_file; do
    chmod +x "$script_file"
  done < <(find "$skill_dir/scripts" -type f -name '*.sh' -print)
}

ensure_user_instructions_include() {
  if [[ -f "$USER_INSTRUCTIONS_FILE" ]]; then
    if ! grep -Fqx "$INCLUDE_LINE" "$USER_INSTRUCTIONS_FILE"; then
      cp "$USER_INSTRUCTIONS_FILE" "$USER_INSTRUCTIONS_FILE.bak.$(date +%Y%m%d-%H%M%S)"
      {
        printf '\n'
        printf '%s\n' "$INCLUDE_LINE"
      } >> "$USER_INSTRUCTIONS_FILE"
    fi
  else
    printf '%s\n' "$INCLUDE_LINE" > "$USER_INSTRUCTIONS_FILE"
  fi
}

install_project_instructions_copy() {
  if [[ -e "$PROJECT_INSTRUCTIONS_TARGET" || -L "$PROJECT_INSTRUCTIONS_TARGET" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp -a "$PROJECT_INSTRUCTIONS_TARGET" "$BACKUP_DIR/$INSTRUCTIONS_FILENAME"
    rm -rf "$PROJECT_INSTRUCTIONS_TARGET"
  fi

  cp "$PROJECT_INSTRUCTIONS_SOURCE" "$PROJECT_INSTRUCTIONS_TARGET"
}

mkdir -p "$TARGET_DIR"
mkdir -p "$BACKUP_ROOT"
mkdir -p "$PROJECT_CONFIG_DIR"

chmod_repo_scripts

echo "Instalando skills de $TARGET por copia..."

for skill_path in "$SKILLS_DIR"/*; do
  if [[ ! -d "$skill_path" ]]; then
    continue
  fi

  skill_name="$(basename "$skill_path")"
  target_path="$TARGET_DIR/$skill_name"
  echo "- $skill_name"

  if [[ -e "$target_path" || -L "$target_path" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp -a "$target_path" "$BACKUP_DIR/$skill_name"
    rm -rf "$target_path"
  fi

  cp -a "$skill_path" "$target_path"
  chmod_skill_scripts "$target_path"
done

install_project_instructions_copy
ensure_user_instructions_include

echo "Skills instaladas em:"
echo "$TARGET_DIR"
echo
echo "Projeto instalado em:"
echo "$PROJECT_CONFIG_DIR"
echo
echo "Arquivo de instrucoes instalado em:"
echo "$PROJECT_INSTRUCTIONS_TARGET"
echo
echo "Diretiva garantida em:"
echo "$USER_INSTRUCTIONS_FILE"

if [[ -d "$BACKUP_DIR" ]]; then
  echo "Backup das skills anteriores em:"
  echo "$BACKUP_DIR"
fi
