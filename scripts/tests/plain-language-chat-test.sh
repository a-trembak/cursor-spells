#!/usr/bin/env bash
# Contract checks: user-facing chat must use full words (no abbreviations).
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

assert_file "skills/plain-language-chat/SKILL.md"
assert_file "rules/plain-language-chat.mdc"

assert_grep rule_always_apply "rules/plain-language-chat.mdc" "alwaysApply: true"
assert_grep rule_full_words "rules/plain-language-chat.mdc" "full words"
assert_grep rule_loads_skill "rules/plain-language-chat.mdc" "plain-language-chat"
assert_grep skill_no_abbrev "skills/plain-language-chat/SKILL.md" "No abbreviations"
assert_grep skill_pull_request "skills/plain-language-chat/SKILL.md" "pull request"
assert_grep skill_human_in_the_loop "skills/plain-language-chat/SKILL.md" "human-in-the-loop"
assert_grep installer_copies_rule "scripts/install-to-project.sh" "plain-language-chat.mdc"
assert_grep installer_user_rules "scripts/install-to-project.sh" "[.]cursor/rules/plain-language-chat"
assert_grep humanizer_points_to_skill "skills/english-humanizer/SKILL.md" "plain-language-chat"
assert_grep reviewer_loads_skill "agents/engineer-reviewer.md" "plain-language-chat"
assert_grep pr_reviewer_loads_skill "agents/pr-reviewer.md" "plain-language-chat"
assert_grep readme_lists_skill "README.md" "plain-language-chat"

# Installer must drop the always-on rule into user-global and project rules.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAKE_HOME="$TMP/home"
PROJECT="$TMP/app"
mkdir -p "$FAKE_HOME" "$PROJECT"
git -C "$PROJECT" init -q

HOME="$FAKE_HOME" "$ROOT/scripts/install-to-project.sh" --user-only >/dev/null
if [[ -f "$FAKE_HOME/.cursor/rules/plain-language-chat.mdc" ]]; then
  echo "OK   user-global rule installed"
else
  echo "FAIL user-global rule missing at $FAKE_HOME/.cursor/rules/plain-language-chat.mdc" >&2
  fail=1
fi
if [[ -d "$FAKE_HOME/.cursor/skills/plain-language-chat" || -L "$FAKE_HOME/.cursor/skills/plain-language-chat" ]]; then
  echo "OK   user-global skill installed"
else
  echo "FAIL user-global skill missing" >&2
  fail=1
fi

HOME="$FAKE_HOME" "$ROOT/scripts/install-to-project.sh" "$PROJECT" >/dev/null
if [[ -f "$PROJECT/.cursor/rules/plain-language-chat.mdc" ]]; then
  echo "OK   project rule installed"
else
  echo "FAIL project rule missing at $PROJECT/.cursor/rules/plain-language-chat.mdc" >&2
  fail=1
fi

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
