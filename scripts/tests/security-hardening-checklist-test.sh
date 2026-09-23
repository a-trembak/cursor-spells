#!/usr/bin/env bash
# Contract: security phase and code writers share one kit hardening checklist
# (S1–S11). Third-party security-review is enrichment only — never a skip.
# Part of the kit harness bench (scripts/harness-bench.sh → scripts/tests/*.sh).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0

assert_file() {
  local path="$1"
  if [[ ! -f "$ROOT/$path" ]]; then
    echo "FAIL missing file: $path" >&2
    fail=1
  else
    echo "OK   file $path"
  fi
}

assert_grep() {
  local name="$1" path="$2" pattern="$3"
  if grep -E -q "$pattern" "$ROOT/$path"; then
    echo "OK   $name"
  else
    echo "FAIL $name: /$pattern/ not in $path" >&2
    fail=1
  fi
}

assert_absent() {
  local name="$1" path="$2" pattern="$3"
  if grep -E -q "$pattern" "$ROOT/$path"; then
    echo "FAIL $name: /$pattern/ still in $path" >&2
    fail=1
  else
    echo "OK   $name"
  fi
}

CHECKLIST="skills/engineer-review/references/security-hardening-checklist.md"
AGENT="agents/csp-review-security.md"
DEV_SKILL="skills/software-developer/SKILL.md"
DEV_AGENT="agents/csp-software-developer.md"
BUG_SKILL="skills/bug-fix/SKILL.md"
BUG_AGENT="agents/csp-bug-fixer.md"
SKILLMAP="skills/engineer-review/references/skill-map.md"
ER_SKILL="skills/engineer-review/SKILL.md"
LEARN="skills/engineer-review/references/learned-misses.md"
LEARN_PROTO="skills/engineer-review/references/review-learn-protocol.md"
PATTERNS="skills/engineer-review/references/patterns-template.md"
DOGFOOD="docs/superpowers/dogfood/engineer-review-checklist.md"
HARNESS_README="evals/harness/README.md"
CTX_BUDGET="scripts/tests/engineer-review-context-budget-test.sh"

assert_file "$CHECKLIST"
assert_file "$AGENT"
assert_file "$DEV_SKILL"
assert_file "$DEV_AGENT"
assert_file "$BUG_SKILL"
assert_file "$BUG_AGENT"

# Gates S1–S11 live in the shared checklist (anchor so S1 does not match S10/S11)
assert_grep s1_sql "$CHECKLIST" "^## S1[^0-9]"
assert_grep s2_cmd "$CHECKLIST" "^## S2[^0-9]"
assert_grep s3_xss "$CHECKLIST" "^## S3[^0-9]"
assert_grep s4_csrf "$CHECKLIST" "^## S4[^0-9]"
assert_grep s5_access "$CHECKLIST" "^## S5[^0-9]"
assert_grep s6_ssrf "$CHECKLIST" "^## S6[^0-9]"
assert_grep s7_path "$CHECKLIST" "^## S7[^0-9]"
assert_grep s8_secret "$CHECKLIST" "^## S8[^0-9]"
assert_grep s9_deser "$CHECKLIST" "^## S9[^0-9]"
assert_grep s10_session "$CHECKLIST" "^## S10([^0-9]|$)"
assert_grep s11_secure_storage "$CHECKLIST" "^## S11([^0-9]|$)"
assert_grep s11_nested_strip "$CHECKLIST" "inbound persist transform|nested auth secrets"
assert_grep s11_separate_stores "$CHECKLIST" "Remember-Me"
assert_grep s11_fail_safe "$CHECKLIST" "Fail-safe logout|stuck splash"
assert_grep trigger_heading "$CHECKLIST" "## Trigger surfaces"
assert_grep trigger_secure_storage "$CHECKLIST" "platform secure storage"
assert_grep writer_vs_reviewer "$CHECKLIST" "## Writer vs reviewer"
assert_grep kit_source_of_truth "$CHECKLIST" "source of truth"
assert_grep no_skip_missing_skill "$CHECKLIST" "do not skip S1–S11 because that skill is missing|source of truth"
assert_grep injection_antipattern "$CHECKLIST" "SELECT"
assert_grep s10_points_replay "$CHECKLIST" "interaction-replay-checklist"
assert_grep s10_points_auth "$CHECKLIST" "auth-rtk-checklist"

# Security phase opens the full checklist — trigger bullets alone are not enough
assert_grep agent_open_full "$AGENT" "open the full checklist"
assert_grep agent_path "$AGENT" "security-hardening-checklist\\.md"
assert_grep agent_s1_s11 "$AGENT" "S1–S11"
assert_grep agent_enrichment_only "$AGENT" "optional enrichment"
assert_grep agent_never_skip "$AGENT" "never skip S1–S11"
assert_absent agent_skill_only_path "$AGENT" "^Use \`security-review\` if installed\\.\$"

# Writers load the same path on Trigger surfaces
assert_grep dev_skill_path "$DEV_SKILL" "security-hardening-checklist\\.md"
assert_grep dev_skill_gates "$DEV_SKILL" "S1–S11"
assert_grep dev_agent_path "$DEV_AGENT" "security-hardening-checklist\\.md"
assert_grep bug_skill_path "$BUG_SKILL" "security-hardening-checklist\\.md"
assert_grep bug_skill_gates "$BUG_SKILL" "S1–S11"
assert_grep bug_agent_path "$BUG_AGENT" "security-hardening-checklist\\.md"

# Shared path string is identical across reviewer + both writers (one source of truth)
SHARED_PATH="skills/engineer-review/references/security-hardening-checklist.md"
for path in "$AGENT" "$DEV_SKILL" "$DEV_AGENT" "$BUG_SKILL" "$BUG_AGENT"; do
  if grep -F -q "security-hardening-checklist.md" "$ROOT/$path"; then
    echo "OK   shared_ref_${path##*/}"
  else
    echo "FAIL shared_ref_${path##*/}: missing security-hardening-checklist.md" >&2
    fail=1
  fi
done
# Relative vs absolute kit path both OK; basename must match SHARED basename
assert_grep shared_basename_check "$CHECKLIST" "S1–S11"

# skill-map + orchestrator phase-only inventory
assert_grep skillmap_kit_checklist "$SKILLMAP" "security-hardening-checklist\\.md"
assert_grep skillmap_s1_s11 "$SKILLMAP" "S1–S11"
assert_grep skillmap_optional_enrichment "$SKILLMAP" "optional enrichment"
assert_grep er_skill_phase_only "$ER_SKILL" "security-hardening-checklist\\.md"

# Learn / patterns / dogfood / harness docs
assert_grep miss_id "$LEARN" "miss_security-checklist-skip"
assert_grep miss_secure_storage "$LEARN" "miss_auth-token-secure-storage-migration"
assert_grep miss_checklist "$LEARN" "security-hardening-checklist\\.md"
assert_grep miss_phases "$LEARN" "security"
assert_grep learn_proto_open "$LEARN_PROTO" "security-hardening-checklist"
assert_grep patterns_security "$PATTERNS" "security-hardening-checklist\\.md"
assert_grep dogfood_row "$DOGFOOD" "security-hardening-checklist"
assert_grep dogfood_test_script "$DOGFOOD" "security-hardening-checklist-test\\.sh"
assert_grep readme_agents "README.md" "security-hardening-checklist\\.md"
assert_grep harness_readme_related "$HARNESS_README" "security-hardening-checklist-test\\.sh|trajectory corpus"
assert_grep ctx_budget_lists "$CTX_BUDGET" "security-hardening-checklist"

# Context-budget test still asserts security opens the full checklist
assert_grep ctx_security_open "$CTX_BUDGET" "security_open_checklist"
assert_grep ctx_security_path "$CTX_BUDGET" "security-hardening-checklist"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
