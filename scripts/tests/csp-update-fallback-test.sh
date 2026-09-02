#!/usr/bin/env bash
# Regression: `csp update` / install --update with no project path must refresh
# ~/.cursor (user-only) when cwd is not a git repo or multi-repo workspace.
# Before a4c66ea this was the documented default; auto-detect must not remove it.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0

assert_grep() {
  local name="$1" path="$2" pattern="$3"
  if grep -E -q "$pattern" "$ROOT/$path"; then
    echo "OK   $name"
  else
    echo "FAIL $name: /$pattern/ not in $path" >&2
    fail=1
  fi
}

# Contract strings for the fallback (behavioral checks below are the source of truth)
assert_grep update_fallback_comment "scripts/install-to-project.sh" \
  'update.*no (resolvable )?project|refresh ~/.cursor only|USER_ONLY=1'
assert_grep readme_update_no_path "README.md" \
  'csp update[[:space:]]+#.*~/.cursor|refresh ~/.cursor only'

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAKE_HOME="$TMP/home"
EMPTY_DIR="$TMP/not-a-repo"
mkdir -p "$FAKE_HOME" "$EMPTY_DIR"

# --update from a non-repo cwd must succeed and install user bits (not dump usage + exit 1)
set +e
OUT="$(
  cd "$EMPTY_DIR"
  HOME="$FAKE_HOME" "$ROOT/scripts/install-to-project.sh" --update --skip-third-party-skills 2>&1
)"
RC=$?
set -e

if [[ "$RC" -eq 0 ]]; then
  echo "OK   update exit 0 from non-repo cwd"
else
  echo "FAIL update exited $RC from non-repo cwd" >&2
  echo "$OUT" >&2
  fail=1
fi

if echo "$OUT" | grep -q 'No project path given'; then
  echo "FAIL update still errors with 'No project path given'" >&2
  echo "$OUT" >&2
  fail=1
fi

if echo "$OUT" | grep -q 'refreshing ~/.cursor only'; then
  echo "OK   update announces ~/.cursor-only fallback"
else
  echo "FAIL update did not announce ~/.cursor-only fallback" >&2
  echo "$OUT" >&2
  fail=1
fi

if echo "$OUT" | grep -q 'Install or update cursor-spells'; then
  echo "FAIL update dumped usage help (should fallback, not usage 1)" >&2
  fail=1
else
  echo "OK   update did not dump usage help"
fi

if [[ -d "$FAKE_HOME/.cursor/skills" || -L "$FAKE_HOME/.cursor/skills/plain-language-chat" ]] \
  || [[ -f "$FAKE_HOME/.cursor/rules/plain-language-chat.mdc" ]]; then
  echo "OK   user-global bits installed after pathless update"
else
  echo "FAIL user-global bits missing after pathless update" >&2
  ls -laR "$FAKE_HOME" >&2 || true
  fail=1
fi

# install (not --update) from non-repo still requires a path or --user-only
set +e
INSTALL_OUT="$(
  cd "$EMPTY_DIR"
  HOME="$FAKE_HOME" "$ROOT/scripts/install-to-project.sh" --skip-third-party-skills 2>&1
)"
INSTALL_RC=$?
set -e
if [[ "$INSTALL_RC" -ne 0 ]]; then
  echo "OK   install without path still fails outside a repo"
else
  echo "FAIL install without path unexpectedly succeeded" >&2
  echo "$INSTALL_OUT" >&2
  fail=1
fi

# --update from inside the kit checkout itself → ~/.cursor only (not project bits into kit)
FAKE_HOME2="$TMP/home2"
mkdir -p "$FAKE_HOME2"
set +e
KIT_OUT="$(
  cd "$ROOT"
  HOME="$FAKE_HOME2" "$ROOT/scripts/install-to-project.sh" --update --skip-third-party-skills 2>&1
)"
KIT_RC=$?
set -e
if [[ "$KIT_RC" -eq 0 ]] && echo "$KIT_OUT" | grep -q 'refreshing ~/.cursor only'; then
  echo "OK   update from kit checkout falls back to ~/.cursor only"
else
  echo "FAIL update from kit checkout (rc=$KIT_RC)" >&2
  echo "$KIT_OUT" >&2
  fail=1
fi
if echo "$KIT_OUT" | grep -q "project: $ROOT"; then
  echo "FAIL update installed project bits into the kit" >&2
  fail=1
else
  echo "OK   update did not target kit as consumer project"
fi

# CLI: csp update wires --update into the installer
if [[ -x "$ROOT/bin/csp" ]]; then
  assert_grep cli_update_passes_flag "bin/cursor-spells" 'INSTALLER.*--update'
fi

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
