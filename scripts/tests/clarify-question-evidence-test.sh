#!/usr/bin/env bash
# Contract: after engineer-review / pr-review, each sequential clarify
# question for a fixer must include the file location and the numbered
# code snippet. Title-only or Jump-only prompts are the miss this file
# guards.
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

assert_file "$HITL"
assert_file "agents/engineer-reviewer.md"
assert_file "agents/pr-reviewer.md"
assert_file "agents/multi-repo-supervisor.md"
assert_file "skills/engineer-review/references/feedback-format.md"
assert_file "skills/engineer-review/references/forbidden-formats.md"

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

# Orchestrators that ask the questions must restate the evidence bar
# (not only the report template).
assert_grep er_clarify_ask "agents/engineer-reviewer.md" "Never ask a clarify"
assert_grep er_clarify_no_title_only "agents/engineer-reviewer.md" "Jump path is not enough"
assert_grep pr_clarify_ask "agents/pr-reviewer.md" "Never ask a clarify"
assert_grep pr_clarify_no_title_only "agents/pr-reviewer.md" "Jump path is not enough"
assert_grep mr_clarify_ask "agents/multi-repo-supervisor.md" "Never ask a clarify"

# Report format + forbidden list must not let the question collapse to title-only.
assert_grep fmt_repeat_where "skills/engineer-review/references/feedback-format.md" "repeats that item"
assert_grep forbid_clarify_q "skills/engineer-review/references/forbidden-formats.md" "clarify question without file"
assert_grep dogfood_clarify "docs/superpowers/dogfood/engineer-review-checklist.md" "numbered fence"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
