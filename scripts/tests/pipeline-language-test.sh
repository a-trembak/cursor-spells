#!/usr/bin/env bash
# Contract checks: pipeline language marker, Russian ban, defaults.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HELPER="$ROOT/scripts/csp-pipeline-language.sh"
fail=0

assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "OK   $name"
  else
    echo "FAIL $name: expected '$expected' got '$actual'" >&2
    fail=1
  fi
}

assert_ok() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "OK   $name"
  else
    echo "FAIL $name (expected success)" >&2
    fail=1
  fi
}

assert_fail() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "FAIL $name (expected failure)" >&2
    fail=1
  else
    echo "OK   $name"
  fi
}

assert_file() {
  local path="$1"
  if [[ -f "$ROOT/$path" ]]; then
    echo "OK   file $path"
  else
    echo "FAIL missing file: $path" >&2
    fail=1
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

assert_file "scripts/csp-pipeline-language.sh"
assert_file "rules/pipeline-language-no-russian.mdc"
assert_file "docs/superpowers/pipeline-language.md"

assert_grep rule_always "rules/pipeline-language-no-russian.mdc" "alwaysApply: true"
assert_grep rule_sanctions "rules/pipeline-language-no-russian.mdc" "Sanctions policy"
assert_grep rule_never_ru "rules/pipeline-language-no-russian.mdc" "never be used"
assert_grep doc_marker "docs/superpowers/pipeline-language.md" "csp-pipeline-language"
assert_grep doc_default "docs/superpowers/pipeline-language.md" "Default when unset"
assert_grep doc_sanctions "docs/superpowers/pipeline-language.md" "Sanctions policy"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PROJ="$TMP/app"
mkdir -p "$PROJ"

# Default when unset
got="$("$HELPER" get --root "$PROJ")"
assert_eq default_en "en" "$got"

# Accept common codes
assert_ok accept_uk "$HELPER" validate uk
assert_ok accept_de "$HELPER" validate de
assert_ok accept_other "$HELPER" validate "other:sw"
assert_eq normalize_english "en" "$("$HELPER" normalize English)"
assert_eq normalize_ua "uk" "$("$HELPER" normalize ua)"

# Reject Russian
assert_fail reject_ru "$HELPER" validate ru
assert_fail reject_RU "$HELPER" validate RU
assert_fail reject_russian "$HELPER" validate russian
assert_fail reject_ru_RU "$HELPER" validate ru-RU
assert_fail reject_other_ru "$HELPER" validate "other:ru"
assert_ok is_banned_ru "$HELPER" is-banned ru
assert_fail is_allowed_en bash -c "'$HELPER' is-banned en"

# set + get round-trip
"$HELPER" set --root "$PROJ" --lang uk >/dev/null
got="$("$HELPER" get --root "$PROJ")"
assert_eq set_get_uk "uk" "$got"
assert_eq marker_file_uk "uk" "$(cat "$PROJ/.cursor/csp-pipeline-language")"

# set russian must fail and not write
assert_fail set_ru "$HELPER" set --root "$PROJ" --lang ru
got="$("$HELPER" get --root "$PROJ")"
assert_eq still_uk_after_ru_set "uk" "$got"

# empty marker → en
: > "$PROJ/.cursor/csp-pipeline-language"
got="$("$HELPER" get --root "$PROJ")"
assert_eq empty_marker_en "en" "$got"

# corrupt ru in file → get fails
printf 'ru\n' > "$PROJ/.cursor/csp-pipeline-language"
assert_fail get_rejects_ru_file "$HELPER" get --root "$PROJ"

# Wiring / docs presence (may be added in later commits — soft-check files that must exist by end)
assert_grep hitl_preset_or_plan "docs/superpowers/plans/2026-09-29-pipeline-language-policy.md" "Pipeline language"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
