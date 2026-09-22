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

# Clear must fail loudly when rm cannot remove the marker
FAKE_BIN="$(mktemp -d)"
cat >"$FAKE_BIN/rm" <<'EOF'
#!/bin/bash
echo "rm: Operation not permitted" >&2
exit 1
EOF
chmod +x "$FAKE_BIN/rm"
pg_write_gate "$TMP" docs-gate "docs/plans/2026-clear-fail.md"
if PATH="$FAKE_BIN:$PATH" pg_clear_gate "$TMP" docs-gate "docs/plans/2026-clear-fail.md" 2>/tmp/pg_clear_err.txt; then
  echo "FAIL clear_should_fail_when_rm_denied" >&2
  fail=1
else
  echo "OK   clear_fails_when_rm_denied"
fi
grep -q "clear failed" /tmp/pg_clear_err.txt || {
  echo "FAIL clear_stderr_missing" >&2
  fail=1
}
# Real clear still works
pg_clear_gate "$TMP" docs-gate "docs/plans/2026-clear-fail.md"
rm -rf "$FAKE_BIN"

# When project .cursor/gates is not writable, write uses home fallback
FB_PROJ="$(mktemp -d)"
FB_HOME="$(mktemp -d)"
mkdir -p "$FB_PROJ"
chmod a-w "$FB_PROJ"
if ! HOME="$FB_HOME" pg_write_gate "$FB_PROJ" docs-gate "docs/plans/fallback-docs.md" 2>/tmp/pg_fb_err.txt; then
  echo "FAIL fallback_write_should_succeed" >&2
  fail=1
else
  echo "OK   fallback_write_when_primary_unwritable"
fi
FB_BASE="$(HOME="$FB_HOME" pg__fallback_gates_base "$FB_PROJ")"
FB_FILE="$(HOME="$FB_HOME" pg__find_gate_for_plan "$FB_PROJ" docs-gate "docs/plans/fallback-docs.md" || true)"
if [[ -n "${FB_FILE:-}" && -f "$FB_FILE" ]]; then
  echo "OK   fallback_gate_file_present"
else
  echo "FAIL fallback_gate_file_missing under $FB_BASE (found=${FB_FILE:-})" >&2
  fail=1
fi
HOME="$FB_HOME" pg_clear_gate "$FB_PROJ" docs-gate "docs/plans/fallback-docs.md"
chmod a+w "$FB_PROJ"
rm -rf "$FB_PROJ" "$FB_HOME"

# Write fails when forced base is not writable
RO="$(mktemp -d)"
mkdir -p "$RO/gates"
chmod a-w "$RO/gates"
if PG_GATES_BASE="$RO/gates" pg_write_gate "$TMP" docs-gate "docs/plans/ro-base.md" 2>/tmp/pg_ro_err.txt; then
  echo "FAIL write_should_fail_on_ro_base" >&2
  fail=1
else
  echo "OK   write_fails_on_readonly_gates_base"
fi
grep -q "write failed\|mkdir failed" /tmp/pg_ro_err.txt || {
  echo "FAIL write_ro_stderr_missing" >&2
  fail=1
}
chmod a+w "$RO/gates"
rm -rf "$RO"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
