#!/usr/bin/env bash
# Stop-hook followups must be per-plan. A foreign critique/review gate in the
# same consumer project must not auto-continue an unrelated chat.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=../pipeline-gates.sh
source "$ROOT/scripts/pipeline-gates.sh"

fail=0
assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$expected" != "$actual" ]]; then
    echo "FAIL $name: expected [$expected] got [$actual]" >&2
    fail=1
  else
    echo "OK   $name"
  fi
}

assert_contains() {
  local name="$1" needle="$2" haystack="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "FAIL $name: expected to contain [$needle] in [$haystack]" >&2
    fail=1
  else
    echo "OK   $name"
  fi
}

run_hook() {
  local hook="$1" cwd="$2" payload="${3:-{}}"
  printf '%s' "$payload" | env -i PATH="$PATH" HOME="$TMP/home" bash -c "cd $(printf '%q' "$cwd") && bash $(printf '%q' "$hook")"
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/.cursor/hooks" "$TMP/home"
printf '%s\n' "$ROOT" > "$TMP/.cursor/cursor-spells-kit-path"
cp "$ROOT/hooks/resolve-kit-path.sh" "$TMP/.cursor/hooks/"
cp "$ROOT/hooks/pre-build-gate.sh" "$TMP/.cursor/hooks/"
cp "$ROOT/hooks/post-plan-review-gate.sh" "$TMP/.cursor/hooks/"

pg_write_gate "$TMP" critique-gate "docs/superpowers/plans/2026-08-20-acp-2681-alert-occurrence-detail.md"
pg_write_gate "$TMP" review-gate "docs/superpowers/plans/2026-08-20-acp-2681-alert-occurrence-detail.md"

# Unknown plan path: foreign open gates must not emit followup_message.
# followup_message auto-continues every chat; the non-owning chat cannot clear
# the slug, so listing becomes an unresolvable stop-hook loop.
pre_unknown="$(run_hook "$TMP/.cursor/hooks/pre-build-gate.sh" "$TMP" '{}')"
assert_eq pre_unknown_plan_stays_silent '{}' "$pre_unknown"

review_unknown="$(run_hook "$TMP/.cursor/hooks/post-plan-review-gate.sh" "$TMP" '{}')"
assert_eq review_unknown_plan_stays_silent '{}' "$review_unknown"

# Known matching plan: still nudge this slug only.
pre_own="$(run_hook "$TMP/.cursor/hooks/pre-build-gate.sh" "$TMP" '{"plan_path":"docs/superpowers/plans/2026-08-20-acp-2681-alert-occurrence-detail.md"}')"
assert_contains pre_own_plan_nudges_this_slug 'acp-2681-alert-occurrence-detail' "$pre_own"
assert_contains pre_own_plan_is_followup 'followup_message' "$pre_own"

review_own="$(run_hook "$TMP/.cursor/hooks/post-plan-review-gate.sh" "$TMP" '{"plan_path":"docs/superpowers/plans/2026-08-20-acp-2681-alert-occurrence-detail.md"}')"
assert_contains review_own_plan_nudges_this_slug 'acp-2681-alert-occurrence-detail' "$review_own"
assert_contains review_own_plan_is_followup 'followup_message' "$review_own"

# Known other plan: foreign ACP-2681 must not block ACP-2657.
pre_other="$(run_hook "$TMP/.cursor/hooks/pre-build-gate.sh" "$TMP" '{"plan_path":"docs/superpowers/plans/2026-08-20-acp-2657-active-alerts.md"}')"
assert_eq pre_other_plan_ignores_foreign '{}' "$pre_other"

review_other="$(run_hook "$TMP/.cursor/hooks/post-plan-review-gate.sh" "$TMP" '{"plan_path":"docs/superpowers/plans/2026-08-20-acp-2657-active-alerts.md"}')"
assert_eq review_other_plan_ignores_foreign '{}' "$review_other"

# Missing kit-path must not fall back to a consumer scripts/ dump.
rm -f "$TMP/.cursor/cursor-spells-kit-path"
mkdir -p "$TMP/scripts"
printf '#!/bin/sh\necho should-not-source\n' > "$TMP/scripts/pipeline-gates.sh"
pre_no_kit="$(run_hook "$TMP/.cursor/hooks/pre-build-gate.sh" "$TMP" '{"plan_path":"docs/superpowers/plans/2026-08-20-acp-2681-alert-occurrence-detail.md"}')"
assert_contains pre_missing_kit_followup 'cursor-spells-kit-path' "$pre_no_kit"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
