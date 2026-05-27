#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$REPO_DIR/codex/skills"
TARGET_DIR="$HOME/.codex/skills"
BACKUP_ROOT="$HOME/.codex/skills-backup"
BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
PROJECT_CONFIG_DIR="$HOME/.codex/ai-dev-workflows"
PROJECT_AGENTS_SOURCE="$REPO_DIR/codex/AGENTS.md"
PROJECT_AGENTS_TARGET="$PROJECT_CONFIG_DIR/AGENTS.md"
USER_AGENTS_FILE="$HOME/.codex/AGENTS.md"
INCLUDE_LINE="@${PROJECT_AGENTS_TARGET}"

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

ensure_user_agents_include() {
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
}

install_project_agents_copy() {
  if [[ -e "$PROJECT_AGENTS_TARGET" || -L "$PROJECT_AGENTS_TARGET" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp -a "$PROJECT_AGENTS_TARGET" "$BACKUP_DIR/AGENTS.md"
    rm -rf "$PROJECT_AGENTS_TARGET"
  fi

  cp "$PROJECT_AGENTS_SOURCE" "$PROJECT_AGENTS_TARGET"
}

mkdir -p "$TARGET_DIR"
mkdir -p "$BACKUP_ROOT"
mkdir -p "$PROJECT_CONFIG_DIR"

chmod_repo_scripts

echo "Instalando skills do repositorio por copia..."

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

install_project_agents_copy
ensure_user_agents_include

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
