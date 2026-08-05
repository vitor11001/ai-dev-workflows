#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
codex_skill="$repo_dir/.codex/skills/code-review"
claude_skill="$repo_dir/.claude/skills/code-review"

required_files=(
  "SKILL.md"
  "references/api-contract-rollout.md"
  "references/concurrency-transactions.md"
  "references/finding-quality.md"
  "references/review-surfaces.md"
  "scripts/review_context.sh"
)

for relative_path in "${required_files[@]}"; do
  cmp "$codex_skill/$relative_path" "$claude_skill/$relative_path"
done

grep -Fq "fronteira em que o impacto foi alegado" "$codex_skill/SKILL.md"
grep -Fq "handlers globais" "$codex_skill/references/finding-quality.md"
grep -Fq "Teste de controller não confirma status HTTP" \
  "$codex_skill/references/finding-quality.md"

for script_path in \
  "$codex_skill/scripts/review_context.sh" \
  "$claude_skill/scripts/review_context.sh"; do
  bash -n "$script_path"
  context="$(cd "$repo_dir" && "$script_path" origin/master)"
  grep -Fq "branch:" <<<"$context"
  grep -Fq "base: origin/master" <<<"$context"
  grep -Fq "merge-base:" <<<"$context"
  grep -Fq "exclusive commits:" <<<"$context"
  grep -Fq "diff stat:" <<<"$context"
  grep -Fq "changed files:" <<<"$context"
done

printf 'code-review skill pairs and context scripts are valid\n'
