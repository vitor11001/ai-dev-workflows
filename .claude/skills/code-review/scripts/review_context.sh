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
