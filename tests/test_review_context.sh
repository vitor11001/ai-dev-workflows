#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script_path="${1:-$repo_dir/.codex/skills/code-review/scripts/review_context.sh}"
fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/review-context-test.XXXXXX")"
trap 'rm -rf -- "$fixture_root"' EXIT

# Usar somente repositório descartável e identidade local; nunca acessar o remoto real.
mkdir "$fixture_root/bin" "$fixture_root/repo"
cp "$repo_dir/tests/fixtures/review-context-bin/gh" "$fixture_root/bin/gh"
cp "$repo_dir/tests/fixtures/review-context-bin/timeout" "$fixture_root/bin/timeout"
chmod +x "$fixture_root/bin/gh" "$fixture_root/bin/timeout"
export PATH="$fixture_root/bin:$PATH"
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL=/dev/null
cd "$fixture_root/repo"
git init -q -b main
git config user.name 'Review Context Test'
git config user.email 'review-context@example.invalid'
git config commit.gpgsign false
printf 'original\n' > shared.txt
printf 'original\n' > staged.txt
printf 'original\n' > unstaged.txt
git add .
git commit -qm baseline
baseline="$(git rev-parse HEAD)"
git switch -qc feature
printf 'feature\n' > shared.txt
git commit -qam feature
git switch -q main
printf 'base-only\n' > base-only.txt
git add base-only.txt
git commit -qm advance-base
integration="$(git rev-parse HEAD)"
git switch -q feature

printf 'staged-value\n' > staged.txt
git add staged.txt
printf 'unstaged-value\n' > unstaged.txt
printf 'new-value\n' > 'new file.txt'
before_status="$(git status --porcelain)"
before_diff="$(git diff HEAD)"

context="$(bash "$script_path" main)"
grep -Fqx "attribution base: $baseline" <<<"$context"
grep -Fqx "integration base: $integration" <<<"$context"
grep -Fqx 'behind base: 1 commits' <<<"$context"
grep -Fqx 'merge simulation: clean' <<<"$context"
# O avanço exclusivo da base não deve entrar nos arquivos alterados pela feature.
branch_files="$(sed -n '/^changed files:$/,/^base drift:$/p' <<<"$context")"
grep -Fq 'shared.txt' <<<"$branch_files"
if grep -Eq 'base-only.txt|staged.txt|unstaged.txt|new file.txt' <<<"$branch_files"; then
  printf 'branch diff includes changes outside committed feature\n' >&2
  exit 1
fi
staged_section="$(sed -n '/^staged diff /,/^unstaged diff /p' <<<"$context")"
unstaged_section="$(sed -n '/^unstaged diff /,/^untracked files /p' <<<"$context")"
grep -Fqx '+staged-value' <<<"$staged_section"
grep -Fqx '+unstaged-value' <<<"$unstaged_section"
grep -Fqx 'new file.txt' <<<"$context"
grep -Fqx $'#17\tother-feature (1 shared files)' <<<"$context"
if grep -Fq '#18' <<<"$context"; then exit 1; fi
grep -Fqx 'shared files alone do not prove a conflict' <<<"$context"

# Sem base e sem remoto, o contexto local continua disponível.
local_context="$(bash "$script_path")"
grep -Fqx '+staged-value' <<<"$local_context"
grep -Fqx '+unstaged-value' <<<"$local_context"
grep -Fqx 'new file.txt' <<<"$local_context"
test "$before_status" = "$(git status --porcelain)"
test "$before_diff" = "$(git diff HEAD)"
printf 'review context: divergent base, local changes and overlap passed\n'
