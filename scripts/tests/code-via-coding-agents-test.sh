#!/usr/bin/env bash
# Contract: parent chat must dispatch software-developer / bug-fixer for product code.
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

assert_file "rules/code-via-coding-agents.mdc"
assert_file "AGENTS.md"

assert_grep rule_always_apply "rules/code-via-coding-agents.mdc" "alwaysApply: true"
assert_grep rule_software_developer "rules/code-via-coding-agents.mdc" "csp-software-developer"
assert_grep rule_bug_fixer "rules/code-via-coding-agents.mdc" "csp-bug-fixer"
assert_grep rule_no_parent_product "rules/code-via-coding-agents.mdc" "protocol bug|never write|must not"
assert_grep agents_section "AGENTS.md" "csp-software-developer"
assert_grep agents_bug_fixer "AGENTS.md" "csp-bug-fixer"
assert_grep installer_project_rules "scripts/install-to-project.sh" "code-via-coding-agents[.]mdc"
assert_grep installer_user_rules "scripts/install-to-project.sh" "[.]cursor/rules/code-via-coding-agents"
assert_grep readme_user_rule "README.md" "~/[.]cursor/rules/code-via-coding-agents"
assert_grep readme_project_rule "README.md" "<project>/[.]cursor/rules/code-via-coding-agents"

# Installer must drop the always-on rule into user-global and project rules.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAKE_HOME="$TMP/home"
PROJECT="$TMP/app"
mkdir -p "$FAKE_HOME" "$PROJECT"
git -C "$PROJECT" init -q

if ! HOME="$FAKE_HOME" "$ROOT/scripts/install-to-project.sh" --user-only --skip-third-party-skills >/dev/null; then
  echo "FAIL user-only install exited non-zero" >&2
  fail=1
elif [[ -f "$FAKE_HOME/.cursor/rules/code-via-coding-agents.mdc" ]]; then
  echo "OK   user-global rule installed"
else
  echo "FAIL user-global rule missing at $FAKE_HOME/.cursor/rules/code-via-coding-agents.mdc" >&2
  fail=1
fi

if ! HOME="$FAKE_HOME" "$ROOT/scripts/install-to-project.sh" "$PROJECT" --skip-third-party-skills >/dev/null; then
  echo "FAIL project install exited non-zero" >&2
  fail=1
elif [[ -f "$PROJECT/.cursor/rules/code-via-coding-agents.mdc" ]]; then
  echo "OK   project rule installed"
else
  echo "FAIL project rule missing at $PROJECT/.cursor/rules/code-via-coding-agents.mdc" >&2
  fail=1
fi

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
