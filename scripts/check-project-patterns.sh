#!/usr/bin/env bash
# Warn (or fail) when source changes land without a project patterns cache.
# Intended for consumer repos. Exit 0 = ok, 1 = missing patterns with src changes.
#
# Usage (after install, from consumer repo root):
#   ./.cursor/scripts/check-project-patterns.sh
#   ./.cursor/scripts/check-project-patterns.sh --strict
#   BASE_REF=origin/main ./.cursor/scripts/check-project-patterns.sh --strict

set -euo pipefail

STRICT=0
if [[ "${1:-}" == "--strict" ]]; then
  STRICT=1
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

PATTERNS=".cursor/project-patterns.md"
BASE_REF="${BASE_REF:-origin/main}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "not a git repo; skip"
  exit 0
fi

# Resolve base; fall back to empty-tree if missing
if git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  RANGE="$BASE_REF...HEAD"
else
  RANGE="$(git hash-object -t tree /dev/null)...HEAD"
fi

changed="$(git diff --name-only "$RANGE" 2>/dev/null || git diff --name-only)"
src_hits="$(printf '%s\n' "$changed" | grep -E '^(src/|app/|apps/|packages/.+/src/|backend/|frontend/)' || true)"

if [[ -z "$src_hits" ]]; then
  echo "ok: no src-like paths in range"
  exit 0
fi

if [[ -f "$PATTERNS" ]]; then
  echo "ok: $PATTERNS present"
  exit 0
fi

msg="missing $PATTERNS while these paths changed:"
echo "$msg"
printf '%s\n' "$src_hits"
echo "Run engineer-review once (or create patterns manually from the kit template)."

if [[ "$STRICT" -eq 1 ]]; then
  exit 1
fi
exit 0
