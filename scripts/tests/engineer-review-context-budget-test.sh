#!/usr/bin/env bash
# Contract: engineer-review orchestrator context budget — always vs phase-only
# vs merge-only; never instruct loading checklist bodies into orch context;
# phases with triggers still open full checklists.
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

SKILL="skills/engineer-review/SKILL.md"
ORCH="agents/engineer-reviewer.md"
LOGIC="agents/review-logic.md"
ARCH="agents/review-architecture.md"

assert_file "$SKILL"
assert_file "$ORCH"
assert_file "skills/engineer-review/references/phase-protocol.md"
assert_file "skills/engineer-review/references/phase-protocol-detail.md"
assert_file "skills/engineer-review/references/skill-map-orch.md"
assert_file "skills/engineer-review/references/review-learn-capture.md"
assert_file "skills/engineer-review/references/graphify-r3-force-include.md"
assert_file "docs/superpowers/specs/2026-09-09-slim-engineer-review-context-design.md"
assert_file "docs/superpowers/dogfood/slim-engineer-review-context-checklist.md"

# Context budget section lists the three load classes
assert_grep budget_heading "$SKILL" "## Context budget"
assert_grep budget_always "$SKILL" "Always-on"
assert_grep budget_phase "$SKILL" "Phase-only"
assert_grep budget_merge "$SKILL" "Merge-only"

# Always-on files named in budget
assert_grep always_phase_proto "$SKILL" "phase-protocol\\.md"
assert_grep always_skill_map_orch "$SKILL" "skill-map-orch\\.md"
assert_grep always_graphify "$SKILL" "graphify-protocol\\.md"
assert_grep always_learn "$SKILL" "review-learn-protocol\\.md"

# Merge-only pack named
assert_grep merge_feedback "$SKILL" "feedback-format\\.md"
assert_grep merge_evidence "$SKILL" "evidence-gate\\.md"
assert_grep merge_forbidden "$SKILL" "forbidden-formats\\.md"
assert_grep merge_lazy "$SKILL" "merge/report|Merge-only|lazy"

# Orchestrator must NOT instruct loading checklist bodies into orch context
CHECKLISTS=(
  interaction-replay-checklist
  auth-rtk-checklist
  figma-markup-checklist
  responsive-layout-checklist
  null-safety-checklist
  jpa-criteria-checklist
  styling-checklist
  learned-misses
)

for base in "${CHECKLISTS[@]}"; do
  # Forbid "read/load/open <file> into orchestrator" style; allow "phases … open" / "do not load"
  if grep -E -i "(read|load|open|paste).{0,40}${base}" "$ROOT/$SKILL" "$ROOT/$ORCH" \
    | grep -E -iv "(do not|never|not|phase|phases|review-learn|point|owned|except)" \
    | grep -E -q "${base}"; then
    echo "FAIL orch_no_load_body_${base}: orchestrator still instructs loading ${base} body" >&2
    grep -E -i "(read|load|open|paste).{0,40}${base}" "$ROOT/$SKILL" "$ROOT/$ORCH" >&2 || true
    fail=1
  else
    echo "OK   orch_no_load_body_${base}"
  fi
done

# Agent lazy-loads feedback pack; does not require it in preconditions at start
assert_grep orch_lazy_merge "$ORCH" "Merge / report|lazy load|lazy"
assert_absent orch_precond_no_feedback_start "$ORCH" "Preconditions[\\s\\S]{0,800}feedback-format\\.md"
# Abort must not require merge pack
assert_grep abort_no_pack "$SKILL" "Abort does \\*\\*not\\*\\* load|abort.*not.*feedback|must not load this pack"

# Phase agents with triggers still require opening full checklist
assert_grep logic_open_replay "$LOGIC" "open the full checklist"
assert_grep logic_replay_path "$LOGIC" "interaction-replay-checklist\\.md"
assert_grep logic_open_null "$LOGIC" "null-safety-checklist\\.md"
assert_grep arch_open_replay "$ARCH" "open the full checklist"
assert_grep arch_replay_path "$ARCH" "interaction-replay-checklist\\.md"

# Canonical spine lives in skill; agent points at it
assert_grep skill_canonical "$SKILL" "canonical spine"
assert_grep agent_pointer "$ORCH" "Canonical spine|skill \\*\\*\`engineer-review\`\\*\\*"

# Checklist bodies still exist (do not delete)
for base in interaction-replay-checklist auth-rtk-checklist figma-markup-checklist \
  responsive-layout-checklist null-safety-checklist jpa-criteria-checklist styling-checklist; do
  assert_file "skills/engineer-review/references/${base}.md"
done
assert_file "skills/engineer-review/references/learned-misses.md"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
