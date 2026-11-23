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

# Permissões de .claude/permissions.json entram no settings.json criado do zero.
settings_file="$fake_home/.claude/settings.json"
expected_rules="$(python3 -I -c 'import json,sys; print("\n".join(json.load(open(sys.argv[1]))["allow"]))' "$repo_dir/.claude/permissions.json")"
while IFS= read -r rule; do
  python3 -I -c 'import json,sys; sys.exit(sys.argv[2] not in json.load(open(sys.argv[1]))["permissions"]["allow"])' \
    "$settings_file" "$rule" || fail "permissão ausente no settings.json: $rule"
done <<<"$expected_rules"

# Reexecução sem mudança: --quiet não imprime nada.
output="$(run_install --quiet)"
[[ -z "$output" ]] || fail "--quiet imprimiu sem haver mudança: $output"

# settings.json existente: chaves e regras do usuário são preservadas, sem duplicar as do
# repositório, com backup e mudança reportada.
cat >"$settings_file" <<'JSON'
{
  "model": "opus",
  "permissions": {"allow": ["Bash(ls:*)", "Bash(codex exec:*)"], "deny": ["Bash(rm:*)"]}
}
JSON
output="$(run_install --quiet)"
python3 -I - "$settings_file" "$repo_dir/.claude/permissions.json" <<'PY' || fail "merge do settings.json incorreto"
import json, sys
settings = json.load(open(sys.argv[1]))
wanted = json.load(open(sys.argv[2]))["allow"]
allow = settings["permissions"]["allow"]
assert settings["model"] == "opus"
assert settings["permissions"]["deny"] == ["Bash(rm:*)"]
assert allow[0] == "Bash(ls:*)"
assert all(allow.count(rule) == 1 for rule in wanted)
PY
grep -Fq 'permissao adicionada' <<<"$output" || fail "permissão adicionada não foi reportada em --quiet"
compgen -G "$settings_file.bak.*" >/dev/null || fail "backup do settings.json não foi criado"

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
