#!/usr/bin/env bash
# Extract a line-range snippet from a file at a given git revision (or worktree).
# Usage: extract-review-snippet.sh <rev|WORKTREE> <path> <start_line> [end_line]
# Prints "LINE|TEXT" per line (TEXT preserves indentation).
set -euo pipefail

REV="${1:?rev or WORKTREE}"
PATH_IN_REPO="${2:?path}"
START_RAW="${3:?start_line}"
END_RAW="${4:-$START_RAW}"

# Reject non-integers early (avoids bash treating words as variables under set -u).
if ! [[ "$START_RAW" =~ ^[0-9]+$ && "$END_RAW" =~ ^[0-9]+$ ]]; then
  echo "error: start_line/end_line must be positive integers (got start='$START_RAW' end='$END_RAW')" >&2
  echo "usage: extract-review-snippet.sh <rev|WORKTREE> <path> <start_line> [end_line]" >&2
  exit 2
fi

START="$START_RAW"
END="$END_RAW"

if (( START < 1 )); then START=1; fi
if (( END < START )); then END="$START"; fi
if (( END - START > 14 )); then END=$((START + 14)); fi

emit_range() {
  # stdin: file contents; print START..END as N|line
  awk -v s="$START" -v e="$END" 'NR>=s && NR<=e { printf "%d|%s\n", NR, $0 }'
}

if [[ "$REV" == "WORKTREE" ]]; then
  if [[ ! -f "$PATH_IN_REPO" ]]; then
    echo "error: file not found in worktree: $PATH_IN_REPO" >&2
    exit 1
  fi
  emit_range < "$PATH_IN_REPO"
else
  if ! git cat-file -e "${REV}:${PATH_IN_REPO}" 2>/dev/null; then
    echo "error: ${REV}:${PATH_IN_REPO} not found" >&2
    exit 1
  fi
  git show "${REV}:${PATH_IN_REPO}" | emit_range
fi
