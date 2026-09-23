#!/usr/bin/env bash
# Contract: after engineer-review / pr-review, each sequential clarify
# question for a fixer must include the file location and the numbered
# code snippet. Title-only or Jump-only prompts are the miss this file
# guards.
#
# Also guards the phase→orchestrator handoff miss: phases wrote a short
# internal note and never returned full context / snippet / question /
# when_shows upward, so the parent only asked "C1: A; C2: B".
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

assert_not_grep() {
  local name="$1" path="$2" pattern="$3"
  if grep -E -q "$pattern" "$ROOT/$path"; then
    echo "FAIL $name: /$pattern/ must not appear in $path" >&2
    fail=1
  else
    echo "OK   $name"
  fi
}

HITL="skills/hitl-choice/SKILL.md"
DETAIL="skills/engineer-review/references/phase-protocol-detail.md"
PROTO="skills/engineer-review/references/phase-protocol.md"
SKILL="skills/engineer-review/SKILL.md"
GATE="skills/engineer-review/references/evidence-gate.md"
FMT="skills/engineer-review/references/feedback-format.md"
FORBID="skills/engineer-review/references/forbidden-formats.md"

assert_file "$HITL"
assert_file "agents/csp-engineer-reviewer.md"
assert_file "agents/csp-pr-reviewer.md"
assert_file "agents/csp-multi-repo-supervisor.md"
assert_file "$FMT"
assert_file "$FORBID"
assert_file "$DETAIL"
assert_file "$PROTO"
assert_file "$SKILL"
assert_file "$GATE"

# The old short-prompt rule is the miss: it told agents to omit the fence.
assert_not_grep hitl_no_omit_fence "$HITL" "do not paste the full code fence"
assert_not_grep hitl_no_title_only "$HITL" "short title \\+ one-line Context \\+ Jump path"

# Positive recipe: each C# question is self-contained with file + snippet.
assert_grep hitl_heading "$HITL" "### Engineer-review clarify"
assert_grep hitl_self_contained "$HITL" "self-contained"
assert_grep hitl_prompt_file "$HITL" "File path"
assert_grep hitl_prompt_lines "$HITL" "Lines"
assert_grep hitl_prompt_jump "$HITL" "Jump"
assert_grep hitl_prompt_fence "$HITL" "numbered code fence"
assert_grep hitl_excuse_report "$HITL" "report already"
assert_grep hitl_fallback_not_see_report "$HITL" "not .see the report above"

# Batch letter list is a reply shape only — never the ask body.
assert_grep hitl_batch_reply_only "$HITL" "reply shape only"
assert_grep hitl_ban_batch_ask "$HITL" "batch letter list"
assert_grep hitl_when_shows "$HITL" "When it shows up"
assert_grep hitl_what_wrong "$HITL" "What is wrong"
assert_grep hitl_plain_language "$HITL" "plain-language-chat"

# Orchestrators that ask the questions must restate the evidence bar
# (not only the report template).
assert_grep er_clarify_ask "agents/csp-engineer-reviewer.md" "Never ask a clarify"
assert_grep er_clarify_no_title_only "agents/csp-engineer-reviewer.md" "Jump path is not enough"
assert_grep er_no_re_summarize "agents/csp-engineer-reviewer.md" "re-summarize"
assert_grep pr_clarify_ask "agents/csp-pr-reviewer.md" "Never ask a clarify"
assert_grep pr_clarify_no_title_only "agents/csp-pr-reviewer.md" "Jump path is not enough"
assert_grep mr_clarify_ask "agents/csp-multi-repo-supervisor.md" "Never ask a clarify"

# Report format + forbidden list must not let the question collapse to title-only.
assert_grep fmt_repeat_where "$FMT" "repeats that item"
assert_grep fmt_when_shows "$FMT" "When it shows up"
assert_grep forbid_clarify_q "$FORBID" "clarify question without file"
assert_grep forbid_batch_ask "$FORBID" "batch letter list"
assert_grep forbid_truncated_phase "$FORBID" "truncated phase"
assert_grep dogfood_clarify "docs/superpowers/dogfood/engineer-review-checklist.md" "numbered fence"
assert_grep dogfood_handoff "docs/superpowers/dogfood/engineer-review-checklist.md" "phase JSON"

# Phase handoff: compact JSON ≠ truncated evidence; full fields required upward.
assert_grep detail_no_truncate "$DETAIL" "Never truncate"
assert_grep detail_when_shows "$DETAIL" "when_shows"
assert_grep detail_full_upward "$DETAIL" "full evidence"
assert_grep proto_verbatim_merge "$PROTO" "verbatim"
assert_grep skill_compact_means "$SKILL" "not truncated evidence"
assert_grep gate_when_shows "$GATE" "when_shows"
assert_grep gate_question_full "$GATE" "question"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
