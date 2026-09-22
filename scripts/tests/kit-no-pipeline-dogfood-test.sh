#!/usr/bin/env bash
# Contract: kit checkout forbids shipping-pipeline dogfood; rule stays kit-only.
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
  if grep -E -q "$pattern" "$ROOT/$path" 2>/dev/null; then
    echo "OK   $name"
  else
    echo "FAIL $name: /$pattern/ not in $path" >&2
    fail=1
  fi
}

assert_no_grep() {
  local name="$1" path="$2" pattern="$3"
  if grep -E -q "$pattern" "$ROOT/$path" 2>/dev/null; then
    echo "FAIL $name: /$pattern/ must not appear in $path" >&2
    fail=1
  else
    echo "OK   $name"
  fi
}

assert_file "rules/kit-no-pipeline-dogfood.mdc"
assert_file "AGENTS.md"

assert_grep rule_always_apply "rules/kit-no-pipeline-dogfood.mdc" "alwaysApply: true"
assert_grep rule_forbid_start "rules/kit-no-pipeline-dogfood.mdc" "csp-start-task"
assert_grep rule_forbid_route "rules/kit-no-pipeline-dogfood.mdc" "Pipeline route"
assert_grep rule_allow_checklists "rules/kit-no-pipeline-dogfood.mdc" "dogfood checklists"
assert_grep rule_not_for_consumers "rules/kit-no-pipeline-dogfood.mdc" "copied into consumer"

assert_grep agents_kit_section "AGENTS.md" "no pipeline dogfood"
assert_grep agents_forbid_start "AGENTS.md" "csp-start-task"
assert_grep agents_direct_edit "AGENTS.md" "Edit kit files directly"
assert_grep agents_points_rule "AGENTS.md" "kit-no-pipeline-dogfood"

assert_grep coding_agents_exception "rules/code-via-coding-agents.mdc" "kit-no-pipeline-dogfood"
assert_grep patterns_note ".cursor/project-patterns.md" "kit-no-pipeline-dogfood"

# Installer must never ship this kit-only rule to user-global or consumer projects.
assert_no_grep installer_no_user "scripts/install-to-project.sh" "kit-no-pipeline-dogfood"
assert_grep readme_kit_note "README.md" "kit-no-pipeline-dogfood"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAKE_HOME="$TMP/home"
PROJECT="$TMP/app"
mkdir -p "$FAKE_HOME" "$PROJECT"
git -C "$PROJECT" init -q

if ! HOME="$FAKE_HOME" "$ROOT/scripts/install-to-project.sh" --user-only --skip-third-party-skills >/dev/null; then
  echo "FAIL user-only install exited non-zero" >&2
  fail=1
elif [[ -f "$FAKE_HOME/.cursor/rules/kit-no-pipeline-dogfood.mdc" ]]; then
  echo "FAIL kit-only rule leaked to user-global rules" >&2
  fail=1
else
  echo "OK   user-global install omits kit-no-pipeline-dogfood"
fi

if ! HOME="$FAKE_HOME" "$ROOT/scripts/install-to-project.sh" "$PROJECT" --skip-third-party-skills >/dev/null; then
  echo "FAIL project install exited non-zero" >&2
  fail=1
elif [[ -f "$PROJECT/.cursor/rules/kit-no-pipeline-dogfood.mdc" ]]; then
  echo "FAIL kit-only rule leaked to consumer project rules" >&2
  fail=1
else
  echo "OK   project install omits kit-no-pipeline-dogfood"
fi

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
