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

backup_existing_path() {
  local source_path="$1"
  local backup_name="$2"

  mkdir -p "$BACKUP_DIR"
  cp -a "$source_path" "$BACKUP_DIR/$backup_name"
}

ensure_symlink() {
  local source_path="$1"
  local target_path="$2"
  local backup_name="$3"

  if [[ -L "$target_path" && "$(readlink "$target_path")" == "$source_path" ]]; then
    return
  fi

  if [[ -e "$target_path" || -L "$target_path" ]]; then
    backup_existing_path "$target_path" "$backup_name"
    rm -rf "$target_path"
  fi

  ln -s "$source_path" "$target_path"
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

mkdir -p "$TARGET_DIR"
mkdir -p "$BACKUP_ROOT"
mkdir -p "$PROJECT_CONFIG_DIR"

chmod_repo_scripts

echo "Instalando skills do repositorio por symlink..."

for skill_path in "$SKILLS_DIR"/*; do
  if [[ ! -d "$skill_path" ]]; then
    continue
  fi

  skill_name="$(basename "$skill_path")"
  target_path="$TARGET_DIR/$skill_name"
  echo "- $skill_name"

  ensure_symlink "$skill_path" "$target_path" "$skill_name"
done

ensure_symlink "$PROJECT_AGENTS_SOURCE" "$PROJECT_AGENTS_TARGET" "AGENTS.md"
ensure_user_agents_include

echo "Skills instaladas como symlinks em:"
echo "$TARGET_DIR"
echo
echo "Projeto instalado como symlink em:"
echo "$PROJECT_AGENTS_TARGET"
echo
echo "Diretiva garantida em:"
echo "$USER_AGENTS_FILE"
echo
echo "A partir de agora, git pull neste repositorio atualiza as skills linkadas."

if [[ -d "$BACKUP_DIR" ]]; then
  echo "Backup dos itens anteriores em:"
  echo "$BACKUP_DIR"
fi
