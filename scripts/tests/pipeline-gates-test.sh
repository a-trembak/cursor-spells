#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=../pipeline-gates.sh
source "$ROOT/scripts/pipeline-gates.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP"

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

# Ticket from basename
slug="$(pg_slug_for_plan "$TMP" "docs/superpowers/plans/2026-08-07-acp-2656-foo-plan.md" plan-gate)"
assert_eq ticket_slug "ACP-2656" "$slug"

# Hash fallback (no ticket)
slug2="$(pg_slug_for_plan "$TMP" "docs/plans/feature-x.md" plan-gate)"
[[ "$slug2" =~ ^[0-9a-f]{12}$ ]] || { echo "FAIL hash_slug format: $slug2" >&2; fail=1; }
echo "OK   hash_slug"

# Write + read clear isolation
pg_write_gate "$TMP" critique-gate "docs/plans/2026-acp-2656-a.md"
pg_write_gate "$TMP" critique-gate "docs/plans/2026-acp-2665-b.md"
test -f "$TMP/.cursor/gates/critique-gate/ACP-2656"
test -f "$TMP/.cursor/gates/critique-gate/ACP-2665"
pg_clear_gate "$TMP" critique-gate "docs/plans/2026-acp-2656-a.md"
test ! -f "$TMP/.cursor/gates/critique-gate/ACP-2656"
test -f "$TMP/.cursor/gates/critique-gate/ACP-2665"
echo "OK   clear_does_not_touch_foreign"

# Legacy migrate-on-read
TMP2="$(mktemp -d)"
mkdir -p "$TMP2/.cursor"
printf '%s\n' "docs/plans/legacy-acp-100.md" > "$TMP2/.cursor/critique-gate.pending"
pg_migrate_legacy "$TMP2" critique-gate "docs/plans/legacy-acp-100.md"
test -f "$TMP2/.cursor/gates/critique-gate/ACP-100"
test ! -f "$TMP2/.cursor/critique-gate.pending"
echo "OK   legacy_migrate"
rm -rf "$TMP2"

# Collision: same ticket, different plans
pg_write_gate "$TMP" plan-gate "docs/plans/acp-1-one.md"
slug_b="$(pg_slug_for_plan "$TMP" "docs/plans/acp-1-two.md" plan-gate)"
[[ "$slug_b" == ACP-1-* && "$slug_b" != "ACP-1" ]] || { echo "FAIL collision slug: $slug_b" >&2; fail=1; }
echo "OK   ticket_collision"

# This-plan clear while a foreign critique-gate stays pending (start-build isolation)
pg_write_gate "$TMP" critique-gate "docs/plans/2026-acp-2665-b.md"
pg_write_gate "$TMP" plan-critique-clear "docs/plans/2026-acp-2656-a.md"
test -f "$TMP/.cursor/gates/critique-gate/ACP-2665"
test -f "$TMP/.cursor/gates/plan-critique-clear/ACP-2656"
test ! -f "$TMP/.cursor/gates/critique-gate/ACP-2656"
test ! -f "$TMP/.cursor/gates/plan-gate/ACP-2656"
echo "OK   this_plan_clear_ignores_foreign_critique"

# commit-approved kind (no legacy file required)
pg_write_gate "$TMP" commit-approved "docs/plans/2026-propose-commit.md"
CA_FILE="$(pg__find_gate_for_plan "$TMP" commit-approved "docs/plans/2026-propose-commit.md")"
if [[ -f "$CA_FILE" ]]; then
  echo "OK   commit-approved gate written"
else
  echo "FAIL commit-approved gate missing" >&2
  exit 1
fi
pg_clear_gate "$TMP" commit-approved "docs/plans/2026-propose-commit.md"
if pg__find_gate_for_plan "$TMP" commit-approved "docs/plans/2026-propose-commit.md" >/dev/null; then
  echo "FAIL commit-approved gate still present after clear" >&2
  exit 1
fi
echo "OK   commit-approved gate cleared"

# local-verify kind
pg_write_gate "$TMP" local-verify "docs/plans/2026-local-verify.md"
LV_FILE="$(pg__find_gate_for_plan "$TMP" local-verify "docs/plans/2026-local-verify.md")"
if [[ -f "$LV_FILE" ]]; then
  echo "OK   local-verify gate written"
else
  echo "FAIL local-verify gate missing" >&2
  exit 1
fi
pg_clear_gate "$TMP" local-verify "docs/plans/2026-local-verify.md"
if pg__find_gate_for_plan "$TMP" local-verify "docs/plans/2026-local-verify.md" >/dev/null; then
  echo "FAIL local-verify gate still present after clear" >&2
  exit 1
fi
echo "OK   local-verify gate cleared"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
