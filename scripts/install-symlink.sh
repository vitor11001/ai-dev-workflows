#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TARGET="${1:-}"
QUIET=false

if [[ "${2:-}" == "--quiet" ]]; then
  QUIET=true
fi

if [[ -z "$TARGET" ]]; then
  echo "Uso: install-symlink.sh <codex|claude> [--quiet]" >&2
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

# Mensagens de progresso; suprimidas em --quiet (execução pelos git hooks).
log() {
  if [[ "$QUIET" == false ]]; then
    echo "$@"
  fi
}

# Mudanças efetivas (link criado ou removido); impressas mesmo em --quiet.
report_change() {
  echo "[$TARGET] $1"
}

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
  report_change "link criado: $target_path"
}

# Remove links que apontam para uma skill deste repositório que deixou de existir (skill
# renomeada, removida ou ausente na branch atual). Links de outra origem nunca são tocados.
remove_stale_skill_links() {
  local target_path

  for target_path in "$TARGET_DIR"/*; do
    if [[ ! -L "$target_path" || -e "$target_path" ]]; then
      continue
    fi

    if [[ "$(readlink "$target_path")" == "$SKILLS_DIR/"* ]]; then
      rm "$target_path"
      report_change "link quebrado removido: $target_path"
    fi
  done
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

mkdir -p "$TARGET_DIR"
mkdir -p "$BACKUP_ROOT"
mkdir -p "$PROJECT_CONFIG_DIR"

chmod_repo_scripts

log "Instalando skills de $TARGET por symlink..."

for skill_path in "$SKILLS_DIR"/*; do
  if [[ ! -d "$skill_path" ]]; then
    continue
  fi

  skill_name="$(basename "$skill_path")"
  target_path="$TARGET_DIR/$skill_name"
  log "- $skill_name"

  ensure_symlink "$skill_path" "$target_path" "$skill_name"
done

remove_stale_skill_links

ensure_symlink "$PROJECT_INSTRUCTIONS_SOURCE" "$PROJECT_INSTRUCTIONS_TARGET" "$INSTRUCTIONS_FILENAME"
ensure_user_instructions_include

log "Skills instaladas como symlinks em:"
log "$TARGET_DIR"
log
log "Projeto instalado como symlink em:"
log "$PROJECT_INSTRUCTIONS_TARGET"
log
log "Diretiva garantida em:"
log "$USER_INSTRUCTIONS_FILE"
log
log "A partir de agora, git pull neste repositorio atualiza as skills linkadas."

if [[ -d "$BACKUP_DIR" ]]; then
  echo "Backup dos itens anteriores em:"
  echo "$BACKUP_DIR"
fi
