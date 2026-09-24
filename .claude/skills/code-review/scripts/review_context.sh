#!/usr/bin/env bash
set -euo pipefail

base_ref="${1:-}"

git rev-parse --is-inside-work-tree >/dev/null

printf 'branch: %s\n' "$(git branch --show-current)"
printf 'head: %s\n' "$(git rev-parse --short HEAD)"
printf 'upstream: %s\n' "$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || printf '<none>')"

if [[ -z "$base_ref" ]]; then
  printf 'base: <not provided; determine from PR, docs or branch chain>\n'
  printf '\nworktree:\n'
  git status --short
  exit 0
fi

git rev-parse --verify "${base_ref}^{commit}" >/dev/null
merge_base="$(git merge-base "$base_ref" HEAD)"

printf 'base: %s\n' "$base_ref"
printf 'merge-base: %s\n' "$(git rev-parse --short "$merge_base")"
printf '\nworktree:\n'
git status --short
printf '\nexclusive commits:\n'
git log --oneline "${merge_base}..HEAD"
printf '\ndiff stat:\n'
git diff --stat "${merge_base}...HEAD"
printf '\nchanged files:\n'
git diff --name-status "${merge_base}...HEAD"

# Gate verde em branch atrasada vale para a base antiga: mostrar quanto a base andou e se o
# merge com ela conflita, antes de confiar no CI local.
printf '\nbase drift:\n'
printf 'behind base: %s commits\n' "$(git rev-list --count "HEAD..${base_ref}")"
merge_status=0
merge_output="$(git merge-tree --write-tree --name-only --no-messages "$base_ref" HEAD 2>/dev/null)" ||
  merge_status=$?
case "$merge_status" in
  0) printf 'merge simulation: clean\n' ;;
  1)
    printf 'merge simulation: conflicts\n'
    tail -n +2 <<<"$merge_output"
    ;;
  *) printf 'merge simulation: <unavailable; git merge-tree --write-tree requires git >= 2.38>\n' ;;
esac

# PRs abertos que mexem nos mesmos arquivos conflitam com quem entrar depois.
printf '\nopen PRs touching the same files:\n'
if ! command -v gh >/dev/null 2>&1; then
  printf '<gh unavailable>\n'
  exit 0
fi
current_branch="$(git branch --show-current)"
changed_files="$(git diff --name-only "${merge_base}...HEAD")"
pr_files="$(timeout 30 gh pr list --state open --limit 50 --json number,headRefName,files \
  --jq '.[] | . as $pr | .files[] | "\($pr.number)\t\($pr.headRefName)\t\(.path)"' \
  2>/dev/null)" || {
  printf '<gh query failed>\n'
  exit 0
}
overlap="$(awk -F '\t' -v current="$current_branch" '
  NR == FNR { changed[$0] = 1; next }
  $2 != current && ($3 in changed) { count[$1 "\t" $2]++ }
  END { for (pr in count) printf "#%s (%d shared files)\n", pr, count[pr] }
' <(printf '%s\n' "$changed_files") <(printf '%s\n' "$pr_files") | sort)"
printf '%s\n' "${overlap:-<none>}"
