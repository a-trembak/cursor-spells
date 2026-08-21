#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=../teach-review.sh
source "$ROOT/scripts/teach-review.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export TR_HOME="$TMP/home"
mkdir -p "$TR_HOME/.cursor" "$TMP/proj/.cursor"

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

# Missing files → default
got="$(tr_resolve_land "$TMP/proj")"
assert_eq missing_default "draft_merge" "$got"

# JSONC comments + user only
cat > "$TR_HOME/.cursor/cursor-spells-learn.json" <<'EOF'
{
  // land — catalog
  //   "draft_merge"
  //   "auto_push"
  "land": "auto_push"
}
EOF
got="$(tr_resolve_land "$TMP/proj")"
assert_eq user_auto_push "auto_push" "$got"

# Project wins
printf '%s\n' '{ "land": "draft_merge" }' > "$TMP/proj/.cursor/cursor-spells-learn.json"
got="$(tr_resolve_land "$TMP/proj")"
assert_eq project_wins "draft_merge" "$got"

# Invalid project land → draft_merge, no fallthrough to user auto_push
printf '%s\n' '{ "land": "banana" }' > "$TMP/proj/.cursor/cursor-spells-learn.json"
warn="$(tr_resolve_land "$TMP/proj" 2>"$TMP/err" || true)"
got="$(tr_resolve_land "$TMP/proj" 2>/dev/null)"
assert_eq invalid_project "draft_merge" "$got"
grep -q "draft_merge" "$TMP/err" || { echo "FAIL invalid_project_warn" >&2; fail=1; }
echo "OK   invalid_project_warn"

# Missing land key in project → fall through to user
printf '%s\n' '{ }' > "$TMP/proj/.cursor/cursor-spells-learn.json"
got="$(tr_resolve_land "$TMP/proj")"
assert_eq project_empty_falls_through "auto_push" "$got"

# Create-once install
tmpl="$TMP/template.json"
printf '%s\n' '{ "land": "draft_merge" }' > "$tmpl"
dest="$TMP/once/cursor-spells-learn.json"
tr_install_learn_config "$dest" "$tmpl"
assert_eq install_created "draft_merge" "$(tr_land_from_file "$dest")"
printf '%s\n' '{ "land": "auto_push" }' > "$dest"
tr_install_learn_config "$dest" "$tmpl"
assert_eq install_no_overwrite "auto_push" "$(tr_land_from_file "$dest")"

# Branch names
assert_eq branch_base "learn/vague-function-names-20260821" "$(tr_learn_branch_base "vague-function-names" "20260821")"

KIT="$TMP/kit"
git init -q "$KIT"
git -C "$KIT" config user.email "t@example.com"
git -C "$KIT" config user.name "t"
mkdir -p "$KIT/skills/engineer-review" "$KIT/agents"
printf '%s\n' '{}' > "$KIT/skills/engineer-review/SKILL.md"
printf '%s\n' '{}' > "$KIT/agents/engineer-reviewer.md"
git -C "$KIT" add skills agents
git -C "$KIT" commit -qm init
tr_is_kit_checkout "$KIT" || { echo "FAIL is_kit" >&2; fail=1; }
echo "OK   is_kit"
tr_kit_is_dirty "$KIT" && { echo "FAIL dirty_clean" >&2; fail=1; }
echo "OK   dirty_clean"
printf '%s\n' x > "$KIT/x"
tr_kit_is_dirty "$KIT" || { echo "FAIL dirty_dirty" >&2; fail=1; }
echo "OK   dirty_dirty"
rm "$KIT/x"

git -C "$KIT" checkout -qb "learn/vague-function-names-20260821"
uniq="$(tr_unique_learn_branch "$KIT" "learn/vague-function-names-20260821")"
assert_eq unique_suffix "learn/vague-function-names-20260821-2" "$uniq"

if tr_land_opens_pr draft_merge; then
  echo "OK   opens_pr_yes"
else
  echo "FAIL opens_pr_yes" >&2
  fail=1
fi
if tr_land_opens_pr auto_push; then
  echo "FAIL opens_pr_auto" >&2
  fail=1
else
  echo "OK   opens_pr_auto"
fi

# Real template is JSONC and resolves to draft_merge
tmpl="$ROOT/skills/teach-review/references/cursor-spells-learn.json"
test -f "$tmpl" || { echo "FAIL missing template" >&2; fail=1; }
assert_eq template_land "draft_merge" "$(tr_land_from_file "$tmpl")"
grep -q "auto_push" "$tmpl" || { echo "FAIL template missing auto_push comment" >&2; fail=1; }
grep -q "draft_merge" "$tmpl" || { echo "FAIL template missing draft_merge comment" >&2; fail=1; }
echo "OK   template_comments"

# install-to-project.sh sources helper and calls tr_install_learn_config
grep -q 'tr_install_learn_config' "$ROOT/scripts/install-to-project.sh" || {
  echo "FAIL install missing tr_install_learn_config" >&2
  fail=1
}
echo "OK   install_calls_helper"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
