#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$REPO_DIR/codex/skills"
TARGET_DIR="$HOME/.codex/skills"
BACKUP_ROOT="$HOME/.codex/skills-backup"
BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
PROJECT_CONFIG_DIR="$HOME/.codex/ai-dev-workflows"
PROJECT_AGENTS_SOURCE="$REPO_DIR/codex/AGENTS.md"
PROJECT_AGENTS_TARGET="$PROJECT_CONFIG_DIR/AGENTS.md"
USER_AGENTS_FILE="$HOME/.codex/AGENTS.md"
INCLUDE_LINE="@${PROJECT_AGENTS_TARGET}"

mkdir -p "$TARGET_DIR"
mkdir -p "$BACKUP_ROOT"
mkdir -p "$PROJECT_CONFIG_DIR"

echo "Instalando skills do repositório..."

for skill_path in "$SKILLS_DIR"/*; do
  if [[ ! -d "$skill_path" ]]; then
    continue
  fi

  skill_name="$(basename "$skill_path")"
  echo "- $skill_name"

  if [[ -e "$TARGET_DIR/$skill_name" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp -R "$TARGET_DIR/$skill_name" "$BACKUP_DIR/$skill_name"
  fi

  rm -rf "$TARGET_DIR/$skill_name"
  cp -R "$skill_path" "$TARGET_DIR/$skill_name"

  if [[ -d "$TARGET_DIR/$skill_name/scripts" ]]; then
    while IFS= read -r script_file; do
      chmod +x "$script_file"
    done < <(find "$TARGET_DIR/$skill_name/scripts" -type f -name '*.sh')
  fi
done

cp "$PROJECT_AGENTS_SOURCE" "$PROJECT_AGENTS_TARGET"

if [[ -f "$USER_AGENTS_FILE" ]]; then
  if ! grep -Fqx "$INCLUDE_LINE" "$USER_AGENTS_FILE"; then
    cp "$USER_AGENTS_FILE" "$USER_AGENTS_FILE.bak.$(date +%Y%m%d-%H%M%S)"
    {
      printf '\n'
      printf '%s\n' "$INCLUDE_LINE"
    } >> "$USER_AGENTS_FILE"
  fi
else
  printf '%s\n' "$INCLUDE_LINE" > "$USER_AGENTS_FILE"
fi

echo "Skills instaladas em:"
echo "$TARGET_DIR"
echo
echo "Projeto instalado em:"
echo "$PROJECT_CONFIG_DIR"
echo
echo "Arquivo de instrucoes instalado em:"
echo "$PROJECT_AGENTS_TARGET"
echo
echo "Diretiva garantida em:"
echo "$USER_AGENTS_FILE"

if [[ -d "$BACKUP_DIR" ]]; then
  echo "Backup das skills anteriores em:"
  echo "$BACKUP_DIR"
fi
