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
  "references/test-adequacy.md"
  "scripts/review_context.sh"
)

for relative_path in "${required_files[@]}"; do
  cmp "$codex_skill/$relative_path" "$claude_skill/$relative_path"
done

# O par .codex/.claude só fica sincronizado se TODO reference entrar em required_files. Um
# arquivo fora da lista pode existir de um lado e faltar do outro sem o cmp acima notar —
# foi assim que o .claude ficou sem `test-adequacy.md`, e a skill do Claude rodou sem a
# verificação de adequação semântica que a do Codex já tinha.
for skill_dir in "$codex_skill" "$claude_skill"; do
  for reference_path in "$skill_dir"/references/*.md; do
    reference_name="references/$(basename "$reference_path")"
    printf '%s\n' "${required_files[@]}" | grep -Fqx "$reference_name" || {
      printf 'reference fora de required_files: %s\n' "$reference_name" >&2
      exit 1
    }
  done
done

grep -Fq "fronteira em que o impacto foi alegado" "$codex_skill/SKILL.md"
grep -Fq "handlers globais" "$codex_skill/references/finding-quality.md"
grep -Fq "Teste de controller não confirma status HTTP" \
  "$codex_skill/references/finding-quality.md"
grep -Fq 'Riscos preexistentes observados' "$codex_skill/SKILL.md"
grep -Fq 'não altera o veredito' \
  "$codex_skill/references/finding-quality.md"
grep -Fq 'não iniciar auditoria ampla' \
  "$codex_skill/references/finding-quality.md"
grep -Fq 'é hipótese, e é' "$codex_skill/SKILL.md"
grep -Fq 'Afirmação causal escrita é hipótese' \
  "$codex_skill/references/test-adequacy.md"
grep -Fq 'Racional invertido' "$codex_skill/references/test-adequacy.md"
grep -Fq 'Mutante sobrevivente' "$codex_skill/references/test-adequacy.md"

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
