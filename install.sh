#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$REPO_DIR/codex/skills"
TARGET_DIR="$HOME/.codex/skills"
BACKUP_ROOT="$HOME/.codex/skills-backup"
BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"

mkdir -p "$TARGET_DIR"
mkdir -p "$BACKUP_ROOT"

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

echo "Skills instaladas em:"
echo "$TARGET_DIR"

if [[ -d "$BACKUP_DIR" ]]; then
  echo "Backup das skills anteriores em:"
  echo "$BACKUP_DIR"
fi
