#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$REPO_DIR/codex/skills"
TARGET_DIR="$HOME/.codex/skills"

mkdir -p "$TARGET_DIR"

echo "Instalando skills do repositório..."

for skill_path in "$SKILLS_DIR"/*; do
  if [[ ! -d "$skill_path" ]]; then
    continue
  fi

  skill_name="$(basename "$skill_path")"
  echo "- $skill_name"

  rm -rf "$TARGET_DIR/$skill_name"
  cp -R "$skill_path" "$TARGET_DIR/$skill_name"

  if [[ -d "$TARGET_DIR/$skill_name/scripts" ]]; then
    chmod +x "$TARGET_DIR/$skill_name"/scripts/* || true
  fi
done

echo "Skills instaladas em:"
echo "$TARGET_DIR"
