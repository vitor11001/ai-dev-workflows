#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fake_home="$(mktemp -d)"
trap 'rm -rf "$fake_home"' EXIT

run_install() {
  HOME="$fake_home" "$repo_dir/scripts/install-symlink.sh" claude "$@"
}

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

skills_dir="$fake_home/.claude/skills"

# Primeira instalação: um link por skill do repositório.
run_install --quiet >/dev/null
for skill_path in "$repo_dir/.claude/skills"/*/; do
  skill_name="$(basename "$skill_path")"
  [[ -L "$skills_dir/$skill_name" ]] || fail "link ausente: $skill_name"
done

# Reexecução sem mudança: --quiet não imprime nada.
output="$(run_install --quiet)"
[[ -z "$output" ]] || fail "--quiet imprimiu sem haver mudança: $output"

# Link de skill do repositório que deixou de existir é removido; link de outra origem
# (também quebrado) e diretório comum são preservados.
ln -s "$repo_dir/.claude/skills/removed-skill" "$skills_dir/removed-skill"
ln -s "/nowhere/foreign-skill" "$skills_dir/foreign-skill"
mkdir "$skills_dir/synced"

output="$(run_install --quiet)"
[[ ! -L "$skills_dir/removed-skill" ]] || fail "link quebrado do repositório não foi removido"
[[ -L "$skills_dir/foreign-skill" ]] || fail "link de outra origem foi removido"
[[ -d "$skills_dir/synced" ]] || fail "diretório comum foi removido"
grep -Fq 'link quebrado removido' <<<"$output" || fail "remoção não foi reportada em --quiet"

# O sync dos hooks age só quando a ferramenta já está instalada por symlink: sem instalação
# do Codex, ~/.codex/skills não é criado.
HOME="$fake_home" "$repo_dir/scripts/sync-skill-links.sh"
[[ ! -e "$fake_home/.codex/skills" ]] || fail "sync instalou ferramenta que não estava instalada"

# post-checkout ignora checkout de arquivo (flag 0).
rm "$skills_dir/onboarding"
(cd "$repo_dir" && HOME="$fake_home" .githooks/post-checkout HEAD HEAD 0)
[[ ! -e "$skills_dir/onboarding" ]] || fail "post-checkout sincronizou em checkout de arquivo"
(cd "$repo_dir" && HOME="$fake_home" .githooks/post-checkout HEAD HEAD 1 >/dev/null)
[[ -L "$skills_dir/onboarding" ]] || fail "post-checkout não sincronizou na troca de branch"

for hook_path in "$repo_dir"/.githooks/*; do
  bash -n "$hook_path"
  [[ -x "$hook_path" ]] || fail "hook sem permissão de execução: $hook_path"
done

printf 'install-symlink and git hooks are valid\n'
