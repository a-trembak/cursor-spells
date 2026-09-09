#!/usr/bin/env bash
# Contract tests for scripts/code-quality-cases.py
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT=(python3 "$ROOT/scripts/code-quality-cases.py")
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

assert_grep_out() {
  local name="$1" pattern="$2"
  shift 2
  local out
  out="$("$@" 2>&1 || true)"
  if grep -E -q "$pattern" <<<"$out"; then
    echo "OK   $name"
  else
    echo "FAIL $name: /$pattern/ not in output:" >&2
    echo "$out" >&2
    fail=1
  fi
}

assert_exit() {
  local name="$1" expected="$2"
  shift 2
  local actual=0
  "$@" >/dev/null 2>&1 || actual=$?
  assert_eq "$name" "$expected" "$actual"
}

if ! "${SCRIPT[@]}" validate --help >/dev/null 2>&1; then
  echo "FAIL missing validate" >&2
  exit 1
fi
echo "OK   help_validate"

assert_exit committed_validate 0 "${SCRIPT[@]}" validate --kit-root "$ROOT"
assert_exit committed_pass_score 0 "${SCRIPT[@]}" score --kit-root "$ROOT" \
  --runs-dir "$ROOT/evals/code-quality/fixtures/pass"
assert_grep_out pass_line "PASS fix-off-by-one" "${SCRIPT[@]}" score --kit-root "$ROOT" \
  --run "$ROOT/evals/code-quality/fixtures/pass/fix-off-by-one.json"
assert_grep_out pass_fast "PASS fast-no-plan-files" "${SCRIPT[@]}" score --kit-root "$ROOT" \
  --run "$ROOT/evals/code-quality/fixtures/pass/fast-no-plan-files.json"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Invalid case: id/filename mismatch
mkdir -p "$TMP/cases" "$TMP/fix"
printf '%s\n' 'ok' >"$TMP/fix/source.md"
cat >"$TMP/cases/bad-id.json" <<EOF
{
  "id": "other-id",
  "title": "x",
  "source": "fix/source.md",
  "status": "active",
  "mode": "fast",
  "fixture": "fix",
  "expected_files": [],
  "forbidden_paths": [],
  "required_substrings": {},
  "forbidden_substrings": {},
  "test_commands": []
}
EOF
# Need fixture relative to kit-root override — use TMP as kit root
mkdir -p "$TMP/evals/code-quality/cases"
cp "$TMP/cases/bad-id.json" "$TMP/evals/code-quality/cases/bad-id.json"
# source path must exist under kit root
mkdir -p "$TMP/docs"
# Fix source to existing file under TMP kit
cat >"$TMP/evals/code-quality/cases/bad-id.json" <<'EOF'
{
  "id": "other-id",
  "title": "x",
  "source": "docs/source.md",
  "status": "active",
  "mode": "fast",
  "fixture": "evals/code-quality/fixtures/x",
  "expected_files": [],
  "forbidden_paths": [],
  "required_substrings": {},
  "forbidden_substrings": {},
  "test_commands": []
}
EOF
printf '%s\n' 's' >"$TMP/docs/source.md"
mkdir -p "$TMP/evals/code-quality/fixtures/x"
assert_exit invalid_id 1 "${SCRIPT[@]}" validate --kit-root "$TMP"

# Missing expected file fails score
BROKEN="$TMP/broken-clamp"
cp -a "$ROOT/evals/code-quality/fixtures/fix-off-by-one" "$BROKEN"
rm -f "$BROKEN/clamp.py"
assert_exit missing_file 1 "${SCRIPT[@]}" score --kit-root "$ROOT" \
  --case "$ROOT/evals/code-quality/cases/fix-off-by-one.json" \
  --workspace "$BROKEN"
assert_grep_out missing_file_msg "expected file missing" "${SCRIPT[@]}" score --kit-root "$ROOT" \
  --case "$ROOT/evals/code-quality/cases/fix-off-by-one.json" \
  --workspace "$BROKEN"

# Forbidden path present fails
BAD="$TMP/bad-paths"
cp -a "$ROOT/evals/code-quality/fixtures/fast-no-plan-files" "$BAD"
mkdir -p "$BAD/docs/superpowers/plans"
printf '%s\n' 'invented' >"$BAD/docs/superpowers/plans/echo-plan.md"
assert_exit forbidden_present 1 "${SCRIPT[@]}" score --kit-root "$ROOT" \
  --case "$ROOT/evals/code-quality/cases/fast-no-plan-files.json" \
  --workspace "$BAD"

# Failing unittest fails score
FAILTEST="$TMP/fail-test"
cp -a "$ROOT/evals/code-quality/fixtures/add-greet-with-test" "$FAILTEST"
cat >"$FAILTEST/greet.py" <<'EOF'
def greet(name: str) -> str:
    return f"Nope, {name}!"
EOF
assert_exit test_fail 1 "${SCRIPT[@]}" score --kit-root "$ROOT" \
  --case "$ROOT/evals/code-quality/cases/add-greet-with-test.json" \
  --workspace "$FAILTEST"

# Forbidden substring
SUB="$TMP/sub"
cp -a "$ROOT/evals/code-quality/fixtures/touch-only-target" "$SUB"
printf '%s\n' 'MODIFIED_BY_AGENT' >"$SUB/unrelated.txt"
assert_exit forbidden_sub 1 "${SCRIPT[@]}" score --kit-root "$ROOT" \
  --case "$ROOT/evals/code-quality/cases/touch-only-target.json" \
  --workspace "$SUB"

# Skill / README wiring
if grep -E -q 'code-quality-cases.py' "$ROOT/skills/code-quality-score/SKILL.md"; then
  echo "OK   skill_exists"
else
  echo "FAIL skill_exists" >&2
  fail=1
fi
if grep -E -q 'code-quality' "$ROOT/README.md"; then
  echo "OK   readme_line"
else
  echo "FAIL readme_line" >&2
  fail=1
fi
if grep -E -q 'code-quality-cases.py validate' "$ROOT/docs/superpowers/dogfood/code-quality-evals-checklist.md"; then
  echo "OK   dogfood"
else
  echo "FAIL dogfood" >&2
  fail=1
fi

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL TESTS PASSED"
exit 0
