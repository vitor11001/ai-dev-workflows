#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.codex/skills"

echo "Instalando skill pr-description..."

rm -rf "$HOME/.codex/skills/pr-description"
cp -R "$REPO_DIR/codex/skills/pr-description" "$HOME/.codex/skills/pr-description"

chmod +x "$HOME/.codex/skills/pr-description/scripts/pr_context.sh"

echo "Skill instalada em:"
echo "$HOME/.codex/skills/pr-description"