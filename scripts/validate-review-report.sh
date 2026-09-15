#!/usr/bin/env bash
# Validate a user-facing engineer-review / pr-review markdown report.
# Usage: validate-review-report.sh <report.md>
# Exit 0 = ok to show user; non-zero = rebuild (forbidden digest or missing evidence).
set -euo pipefail

FILE="${1:?path to review report markdown}"
if [[ ! -f "$FILE" ]]; then
  echo "error: file not found: $FILE" >&2
  exit 2
fi

# Strip fenced code for structure checks that should ignore snippet bodies
BODY="$(awk '
  BEGIN { in_fence=0 }
  /^```/ { in_fence = !in_fence; next }
  !in_fence { print }
' "$FILE")"

FAIL=0
fail() { echo "FAIL: $*" >&2; FAIL=1; }

count_re() {
  # $1 = regex against BODY
  local re="$1"
  local n
  n="$(printf '%s\n' "$BODY" | grep -E -c -- "$re" || true)"
  # grep -c prints 0 on some systems even with exit 1; normalize empty
  [[ -n "$n" ]] || n=0
  echo "$n"
}

# Banned digest headings / patterns (EN + common UA labels from bad runs)
if printf '%s\n' "$BODY" | grep -E -iq -- '^#{1,3}[[:space:]]*(blockers|блокери|also \(p1\)|також \(p1\)|verdict)([[:space:]]|$)'; then
  fail "forbidden digest heading (Verdict/Blockers/Блокери) — use Findings with Where + snippet"
fi
if printf '%s\n' "$BODY" | grep -E -iq -- '^Verdict:'; then
  fail "leading Verdict: digest line is forbidden as the report body"
fi

# F1 / C1 / C_CR1 / api:C1 / C1@api
FINDING_RE='^#{2,3}[[:space:]]+([A-Za-z0-9_.-]+[:@])?(F|C)(_CR)?[0-9]+'
C_FINDING_RE='^#{2,3}[[:space:]]+([A-Za-z0-9_.-]+[:@])?C(_CR)?[0-9]+'

FINDINGS="$(count_re "$FINDING_RE")"
C_FINDINGS="$(count_re "$C_FINDING_RE")"
WHERE="$(count_re '\*\*Where:\*\*')"
JUMP="$(count_re 'Jump:')"
FILE_LINK="$(count_re 'File:')"
CONTEXT="$(count_re '\*\*Context:\*\*')"
RECOMMENDATION="$(count_re '\*\*Recommendation:\*\*')"
RECOMMENDED_MARK="$(count_re '\(recommended\)')"
FENCES="$(grep -E -c -- '^```' "$FILE" || true)"
[[ -n "$FENCES" ]] || FENCES=0
FENCE_BLOCKS=$((FENCES / 2))

if [[ "$FINDINGS" -eq 0 ]]; then
  if printf '%s\n' "$BODY" | grep -E -iq -- 'no findings|no issues|nothing to report|findings:[[:space:]]*none'; then
    if [[ "$FAIL" -ne 0 ]]; then
      echo "Rebuild per skills/engineer-review/references/feedback-format.md and forbidden-formats.md" >&2
      exit 1
    fi
    echo "OK: empty findings acknowledged"
    exit 0
  fi
  fail "no ### F#/C# findings and no explicit empty-findings note"
else
  if [[ "$WHERE" -lt "$FINDINGS" ]]; then
    fail "each finding needs **Where:** (found $WHERE Where for $FINDINGS findings)"
  fi
  if [[ "$JUMP" -lt "$FINDINGS" ]]; then
    fail "each finding needs Jump: link (found $JUMP Jump for $FINDINGS findings)"
  fi
  if [[ "$FILE_LINK" -lt "$FINDINGS" ]]; then
    fail "each finding needs File: link (found $FILE_LINK File for $FINDINGS findings)"
  fi
  if [[ "$CONTEXT" -lt "$FINDINGS" ]]; then
    fail "each finding needs **Context:** (found $CONTEXT Context for $FINDINGS findings)"
  fi
  if [[ "$FENCE_BLOCKS" -lt "$FINDINGS" ]]; then
    fail "each finding needs a code fence snippet (found $FENCE_BLOCKS fences for $FINDINGS findings)"
  fi
  if [[ "$C_FINDINGS" -gt 0 ]]; then
    if [[ "$RECOMMENDATION" -lt "$C_FINDINGS" ]] && [[ "$RECOMMENDED_MARK" -lt "$C_FINDINGS" ]]; then
      fail "each C# clarify needs **Recommendation:** or (recommended) (found $RECOMMENDATION Recommendation / $RECOMMENDED_MARK (recommended) for $C_FINDINGS C findings)"
    fi
  fi
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "Rebuild per skills/engineer-review/references/feedback-format.md and forbidden-formats.md" >&2
  exit 1
fi

# Narrow Coverage enum: if jpa_result_type appears outside fences, value must be allowed.
if printf '%s\n' "$BODY" | grep -E -q -- 'jpa_result_type'; then
  if ! printf '%s\n' "$BODY" | grep -E -q -- 'jpa_result_type:[[:space:]]*(matched|mismatched|skipped|n/a)\b'; then
    fail "jpa_result_type must be one of matched|mismatched|skipped|n/a when present"
    echo "Rebuild per skills/engineer-review/references/feedback-format.md and forbidden-formats.md" >&2
    exit 1
  fi
fi

echo "OK: $FINDINGS finding(s) with Context/Where/Jump/File + code fences"
if [[ "$C_FINDINGS" -gt 0 ]]; then
  echo "OK: $C_FINDINGS C finding(s) with Recommendation/(recommended)"
fi
exit 0
