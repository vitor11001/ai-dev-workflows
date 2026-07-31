#!/usr/bin/env bash
set -euo pipefail

export GIT_PAGER=cat

DIFF_EXCLUDES=(
  ":(exclude).github/PULL_REQUEST_TEMPLATE"
  ":(exclude).github/PULL_REQUEST_TEMPLATE.md"
  ":(exclude).github/PULL_REQUEST_TEMPLATE/*"
  ":(exclude).github/pull_request_template.md"
  ":(exclude).github/pull_request_template/*"
  ":(exclude)PULL_REQUEST_TEMPLATE.md"
  ":(exclude)pull_request_template.md"
)

usage() {
  echo "Uso: pr_context.sh [--base <branch-ou-ref>]" >&2
}

fail() {
  echo "Erro: $1" >&2
  exit 1
}

ref_exists() {
  git rev-parse --verify --quiet "${1}^{commit}" >/dev/null
}

normalize_base_ref() {
  local candidate="$1"

  if [[ "$candidate" != origin/* ]] && ref_exists "origin/$candidate"; then
    printf '%s\n' "origin/$candidate"
    return
  fi

  if ref_exists "$candidate"; then
    printf '%s\n' "$candidate"
    return
  fi

  return 1
}

base_from_pull_request() {
  local base_name

  command -v gh >/dev/null 2>&1 || return 1
  base_name="$(
    GH_PROMPT_DISABLED=1 gh pr view "$CURRENT_BRANCH" \
      --json baseRefName \
      --jq '.baseRefName' 2>/dev/null
  )" || return 1
  [[ -n "$base_name" ]] || return 1
  normalize_base_ref "$base_name"
}

base_from_git_config() {
  local configured_base

  configured_base="$(git config --get "branch.${CURRENT_BRANCH}.gh-merge-base")" || return 1
  [[ -n "$configured_base" ]] || return 1
  normalize_base_ref "$configured_base"
}

closest_ancestor_base() {
  local best_distance=""
  local best_ref=""
  local best_sha=""
  local candidate_distance
  local candidate_ref
  local candidate_sha
  local -a ambiguous_refs=()

  while IFS= read -r candidate_ref; do
    case "$candidate_ref" in
      "$CURRENT_BRANCH"|"origin/$CURRENT_BRANCH"|origin/HEAD)
        continue
        ;;
    esac

    git merge-base --is-ancestor "$candidate_ref" HEAD 2>/dev/null || continue
    candidate_distance="$(git rev-list --count "$candidate_ref"..HEAD)"
    candidate_sha="$(git rev-parse "$candidate_ref")"

    if [[ -z "$best_distance" ]] || (( candidate_distance < best_distance )); then
      best_distance="$candidate_distance"
      best_ref="$candidate_ref"
      best_sha="$candidate_sha"
      ambiguous_refs=()
      continue
    fi

    if (( candidate_distance == best_distance )) && [[ "$candidate_sha" != "$best_sha" ]]; then
      ambiguous_refs+=("$candidate_ref")
    fi
  done < <(
    git for-each-ref \
      --format='%(refname:short)' \
      refs/remotes/origin \
      refs/heads
  )

  [[ -n "$best_ref" ]] || return 1

  if (( ${#ambiguous_refs[@]} > 0 )); then
    echo "Erro: bases ancestrais igualmente próximas: $best_ref ${ambiguous_refs[*]}." >&2
    echo "Informe a base desejada com --base <branch-ou-ref>." >&2
    return 2
  fi

  printf '%s\n' "$best_ref"
}

fallback_base() {
  local candidate

  for candidate in origin/main origin/master main master; do
    if ref_exists "$candidate"; then
      printf '%s\n' "$candidate"
      return
    fi
  done

  return 1
}

resolve_base() {
  local detected_base

  if [[ -n "$REQUESTED_BASE" ]]; then
    BASE_BRANCH="$(normalize_base_ref "$REQUESTED_BASE")" \
      || fail "base '$REQUESTED_BASE' não encontrada."
    BASE_SOURCE="argumento --base"
    return
  fi

  if detected_base="$(base_from_pull_request)"; then
    BASE_BRANCH="$detected_base"
    BASE_SOURCE="Pull Request existente"
    return
  fi

  if detected_base="$(base_from_git_config)"; then
    BASE_BRANCH="$detected_base"
    BASE_SOURCE="branch.${CURRENT_BRANCH}.gh-merge-base"
    return
  fi

  if detected_base="$(closest_ancestor_base)"; then
    BASE_BRANCH="$detected_base"
    BASE_SOURCE="branch ancestral mais próxima"
    return
  else
    local detection_status=$?
    (( detection_status == 1 )) || exit "$detection_status"
  fi

  BASE_BRANCH="$(fallback_base)" \
    || fail "não foi possível determinar a branch base."
  BASE_SOURCE="fallback main/master"
}

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  fail "este diretório não está dentro de um repositório Git."
fi

REQUESTED_BASE=""
while (( $# > 0 )); do
  case "$1" in
    --base)
      (( $# >= 2 )) || {
        usage
        fail "a opção --base exige uma branch ou ref."
      }
      REQUESTED_BASE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      fail "argumento desconhecido '$1'."
      ;;
  esac
done

CURRENT_BRANCH="$(git branch --show-current)"
[[ -n "$CURRENT_BRANCH" ]] || fail "HEAD destacado; não há branch atual."

BASE_BRANCH=""
BASE_SOURCE=""
resolve_base

BASE_HASH="$(git rev-parse "$BASE_BRANCH")"
MERGE_BASE_HASH="$(git merge-base "$BASE_BRANCH" HEAD)"
DIFF_RANGE="${BASE_BRANCH}...HEAD"
COMMIT_RANGE="${MERGE_BASE_HASH}..HEAD"

echo "# Contexto para descrição de PR"
echo
echo "## Branch atual: $CURRENT_BRANCH"
echo "## Branch base: $BASE_BRANCH ($BASE_HASH)"
echo "## Origem da base: $BASE_SOURCE"
echo "## Merge-base: $MERGE_BASE_HASH"

echo
echo "## Commits exclusivos da branch"
git --no-pager log \
  --reverse \
  --format='### %h %s%n%n%b' \
  "$COMMIT_RANGE"

echo
echo "## Arquivos alterados"
git --no-pager diff --name-status "$DIFF_RANGE" -- . "${DIFF_EXCLUDES[@]}"

echo
echo "## Diff stat"
git --no-pager diff --stat "$DIFF_RANGE" -- . "${DIFF_EXCLUDES[@]}"

echo
echo "## Diff completo"
git --no-pager diff "$DIFF_RANGE" -- . "${DIFF_EXCLUDES[@]}"
