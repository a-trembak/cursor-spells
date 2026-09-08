#!/usr/bin/env bash
# Contract: before review-gate HITL, finish-plan must surface the work in the
# human's client (checkout open folders + SetActiveBranch) so they can look at
# the diff. This is an intermediate convenience step — not create-pr, not the
# pipeline end. After skip/approve/done, engineer-review continues.
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

assert_no_grep() {
  local name="$1" path="$2" pattern="$3"
  if grep -E -q "$pattern" "$ROOT/$path"; then
    echo "FAIL $name: /$pattern/ unexpectedly in $path" >&2
    fail=1
  else
    echo "OK   $name"
  fi
}

assert_file "skills/finish-plan/references/review-surface.md"
assert_file "skills/finish-plan/SKILL.md"
assert_file "commands/finish-plan.md"
assert_file "skills/create-pr/SKILL.md"
assert_file "skills/software-developer/references/branch-setup.md"

assert_grep finish_skill_ref "skills/finish-plan/SKILL.md" "review-surface.md"
assert_grep finish_skill_before_hitl "skills/finish-plan/SKILL.md" "Apply review-surface"
assert_grep finish_cmd_ref "commands/finish-plan.md" "review-surface.md"
assert_grep finish_reask "skills/finish-plan/SKILL.md" "re-run review-surface"
assert_grep finish_then_engineer "skills/finish-plan/SKILL.md" "engineer-reviewer"
assert_no_grep finish_no_surface_create "skills/finish-plan/SKILL.md" "mode:surface"

assert_grep surface_set_active "skills/finish-plan/references/review-surface.md" "SetActiveBranch"
assert_grep surface_checkout "skills/finish-plan/references/review-surface.md" "git( -C.*)? checkout"
assert_grep surface_open_folder "skills/finish-plan/references/review-surface.md" "open folder|workspace folder|human has open"
assert_grep surface_not_worktree "skills/finish-plan/references/review-surface.md" "worktree"
assert_grep surface_every_repo "skills/finish-plan/references/review-surface.md" "every.*repo|each.*repo"
assert_grep surface_intermediate "skills/finish-plan/references/review-surface.md" "intermediate|does not end the pipeline|not the pipeline finale"
assert_grep surface_then_engineer "skills/finish-plan/references/review-surface.md" "engineer-review"
assert_grep surface_create_pr_later "skills/finish-plan/references/review-surface.md" "create-pr"
assert_no_grep surface_no_mode "skills/finish-plan/references/review-surface.md" "mode:surface"
assert_grep surface_forbid_gh_create "skills/finish-plan/references/review-surface.md" "not.*gh pr create"
assert_grep surface_never_finale "skills/finish-plan/references/review-surface.md" "Do not ask Pipeline finale|do not ask Pipeline finale|Never ask Pipeline finale"
assert_grep surface_uncommitted "skills/finish-plan/references/review-surface.md" "git status|uncommitted|working tree"
assert_grep surface_no_placeholder "skills/finish-plan/references/review-surface.md" "placeholder commit|Do not.*placeholder"
assert_grep surface_propose "skills/finish-plan/references/review-surface.md" "propose-commit"

assert_no_grep create_pr_no_surface "skills/create-pr/SKILL.md" "mode:surface"

assert_grep branch_set_active "skills/software-developer/references/branch-setup.md" "SetActiveBranch"
assert_grep branch_open_folder "skills/software-developer/references/branch-setup.md" "human has open|open workspace folder"
assert_no_grep branch_no_draft_pr "skills/software-developer/references/branch-setup.md" "draft pull request"

assert_grep rule_surface "rules/after-plan-review-gate.mdc" "review-surface|SetActiveBranch"
assert_grep hook_surface "hooks/post-plan-review-gate.sh" "review-surface|SetActiveBranch"
assert_grep start_task_surface "commands/start-task.md" "review-surface|SetActiveBranch"
assert_grep readme_surface "README.md" "review-surface|SetActiveBranch"
assert_grep flow_md_surface "docs/superpowers/pipeline-flow.md" "SetActiveBranch|review-surface"
assert_grep flow_html_surface "docs/superpowers/pipeline-flow.html" "SetActiveBranch|review-surface"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
