#!/usr/bin/env bash
# csp install must not vendor pipeline helpers into consumer scripts/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
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

assert_absent() {
  local name="$1" path="$2"
  if [[ -e "$path" ]]; then
    echo "FAIL $name: unexpectedly present $path" >&2
    fail=1
  else
    echo "OK   $name"
  fi
}

assert_file() {
  local name="$1" path="$2"
  if [[ -f "$path" ]]; then
    echo "OK   $name"
  else
    echo "FAIL $name: missing $path" >&2
    fail=1
  fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAKE_HOME="$TMP/home"
PROJECT="$TMP/app"
mkdir -p "$FAKE_HOME" "$PROJECT/scripts"
git -C "$PROJECT" init -q

# Leftovers from an older install must be removed.
for leftover in \
  check-project-patterns.sh \
  extract-review-snippet.sh \
  validate-review-report.sh \
  pipeline-gates.sh \
  pipeline-status.sh \
  jira-issue.sh \
  pr-merge-ci.sh
do
  printf 'old dump\n' > "$PROJECT/scripts/$leftover"
done
printf 'product\n' > "$PROJECT/scripts/release-notes.sh"

if ! HOME="$FAKE_HOME" "$ROOT/scripts/install-to-project.sh" "$PROJECT" --skip-third-party-skills >/dev/null; then
  echo "FAIL install exited non-zero" >&2
  fail=1
fi

assert_file kit_path_written "$PROJECT/.cursor/cursor-spells-kit-path"
assert_file hook_resolver_copied "$PROJECT/.cursor/hooks/resolve-kit-path.sh"
assert_file product_script_kept "$PROJECT/scripts/release-notes.sh"

for leftover in \
  check-project-patterns.sh \
  extract-review-snippet.sh \
  validate-review-report.sh \
  pipeline-gates.sh \
  pipeline-status.sh \
  jira-issue.sh \
  pr-merge-ci.sh
do
  assert_absent "removed_$leftover" "$PROJECT/scripts/$leftover"
done

kit_written="$(tr -d '\n' < "$PROJECT/.cursor/cursor-spells-kit-path")"
assert_eq kit_path_points_at_root "$ROOT" "$kit_written"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
