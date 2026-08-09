#!/usr/bin/env bash
#
# generate-changelog.sh — build a Markdown changelog for a release.
#
# Usage:
#   scripts/generate-changelog.sh <current-tag> [output-file]
#
# Collects commits between the previous tag (or the repo root if none) and the
# current tag, then groups them by Conventional Commit type. Falls back to a
# plain commit list for commits that don't follow the convention.
#
# Requires a full git history (checkout with fetch-depth: 0).

set -euo pipefail

CURRENT_TAG="${1:-}"
OUTPUT_FILE="${2:-CHANGELOG_RELEASE.md}"

if [[ -z "$CURRENT_TAG" ]]; then
  echo "usage: $0 <current-tag> [output-file]" >&2
  exit 1
fi

# Find the previous tag reachable before the current one. If the current tag
# isn't in the tag list yet (e.g. dispatched build), describe from HEAD.
if git rev-parse -q --verify "refs/tags/${CURRENT_TAG}" >/dev/null 2>&1; then
  PREV_TAG="$(git describe --tags --abbrev=0 "${CURRENT_TAG}^" 2>/dev/null || true)"
  RANGE_END="${CURRENT_TAG}"
else
  PREV_TAG="$(git describe --tags --abbrev=0 2>/dev/null || true)"
  RANGE_END="HEAD"
fi

if [[ -n "$PREV_TAG" ]]; then
  RANGE="${PREV_TAG}..${RANGE_END}"
  COMPARE_LINE="Changes since **${PREV_TAG}**."
else
  RANGE="${RANGE_END}"
  COMPARE_LINE="Initial release."
fi

# Pull commits as "hash<TAB>subject".
COMMITS="$(git log --no-merges --pretty=format:'%H%x09%s' "${RANGE}" 2>/dev/null || true)"

# Buckets for the grouped output.
FEATURES=""
FIXES=""
PERF=""
REFACTOR=""
DOCS=""
OTHER=""

short_link() {
  # Emit "- subject (`shorthash`)".
  local hash="$1" subject="$2"
  printf -- "- %s (\`%s\`)\n" "$subject" "${hash:0:7}"
}

if [[ -n "$COMMITS" ]]; then
  while IFS=$'\t' read -r hash subject; do
    [[ -z "$hash" ]] && continue
    line="$(short_link "$hash" "$subject")"
    case "$subject" in
      feat:*|feat\(*\):*)         FEATURES+="$(short_link "$hash" "${subject#*: }")"$'\n' ;;
      fix:*|fix\(*\):*)           FIXES+="$(short_link "$hash" "${subject#*: }")"$'\n' ;;
      perf:*|perf\(*\):*)         PERF+="$(short_link "$hash" "${subject#*: }")"$'\n' ;;
      refactor:*|refactor\(*\):*) REFACTOR+="$(short_link "$hash" "${subject#*: }")"$'\n' ;;
      docs:*|docs\(*\):*)         DOCS+="$(short_link "$hash" "${subject#*: }")"$'\n' ;;
      *)                          OTHER+="$line"$'\n' ;;
    esac
  done <<< "$COMMITS"
fi

{
  echo "## BetBook ${CURRENT_TAG}"
  echo
  echo "$COMPARE_LINE"
  echo

  [[ -n "$FEATURES" ]] && { echo "### New features"; echo; printf "%s\n" "$FEATURES"; }
  [[ -n "$FIXES"    ]] && { echo "### Bug fixes";    echo; printf "%s\n" "$FIXES"; }
  [[ -n "$PERF"     ]] && { echo "### Performance";  echo; printf "%s\n" "$PERF"; }
  [[ -n "$REFACTOR" ]] && { echo "### Refactoring";  echo; printf "%s\n" "$REFACTOR"; }
  [[ -n "$DOCS"     ]] && { echo "### Documentation"; echo; printf "%s\n" "$DOCS"; }
  [[ -n "$OTHER"    ]] && { echo "### Other changes"; echo; printf "%s\n" "$OTHER"; }

  if [[ -z "$COMMITS" ]]; then
    echo "_No commits found in range \`${RANGE}\`._"
    echo
  fi
} > "$OUTPUT_FILE"

echo "Wrote changelog to ${OUTPUT_FILE} (range: ${RANGE})" >&2
