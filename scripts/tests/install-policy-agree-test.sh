#!/usr/bin/env bash
# Policy agreement gate for lgt install / update.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FAIL=0

assert_eq() {
  local name="$1" want="$2" got="$3"
  if [[ "$want" == "$got" ]]; then
    echo "OK   $name"
  else
    echo "FAIL $name: want='$want' got='$got'" >&2
    FAIL=1
  fi
}

assert_grep() {
  local name="$1" file="$2" pat="$3"
  if grep -qE "$pat" "$ROOT/$file"; then
    echo "OK   $name"
  else
    echo "FAIL $name: /$pat/ not in $file" >&2
    FAIL=1
  fi
}

assert_file() {
  local name="$1" path="$2"
  if [[ -f "$path" ]]; then
    echo "OK   $name"
  else
    echo "FAIL $name: missing $path" >&2
    FAIL=1
  fi
}

assert_grep help_agree "scripts/install-to-project.sh" "agree-policy"
assert_grep help_i_agree "scripts/install-to-project.sh" "i-agree"
assert_grep help_env "scripts/install-to-project.sh" "LGT_AGREE_POLICY|CSP_AGREE_POLICY"
assert_grep cli_help "bin/lgt" "agree-policy"
assert_grep hasher "scripts/csp-policy-hash.sh" "PRIVACY.md"
assert_grep name_opts "docs/legal/NAME-OPTIONS.md" "gh repo rename"
assert_grep readme_agree "README.md" "agree-policy"

HASH="$("$ROOT/scripts/csp-policy-hash.sh" --kit-root "$ROOT")"
assert_eq hash_len "64" "${#HASH}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAKE_HOME="$TMP/home"
PROJECT="$TMP/proj"
mkdir -p "$FAKE_HOME" "$PROJECT/.git"
git -C "$PROJECT" init -q

# Non-interactive without flag → abort
set +e
OUT="$(HOME="$FAKE_HOME" "$ROOT/scripts/install-to-project.sh" "$PROJECT" --skip-third-party-skills 2>&1)"
RC=$?
set -e
if [[ "$RC" -ne 0 ]] && echo "$OUT" | grep -q "agree-policy"; then
  echo "OK   refuse_without_agree"
else
  echo "FAIL refuse_without_agree rc=$RC out=$OUT" >&2
  FAIL=1
fi
if [[ -f "$PROJECT/.cursor/lgt-policy-accepted" || -f "$FAKE_HOME/.cursor/lgt-policy-accepted" ]]; then
  echo "FAIL marker_should_not_exist_yet" >&2
  FAIL=1
else
  echo "OK   no_marker_before_agree"
fi

# --agree-policy writes project + user markers
if HOME="$FAKE_HOME" "$ROOT/scripts/install-to-project.sh" "$PROJECT" --agree-policy --skip-third-party-skills >/dev/null; then
  echo "OK   install_with_agree"
else
  echo "FAIL install_with_agree" >&2
  FAIL=1
fi
assert_file project_marker "$PROJECT/.cursor/lgt-policy-accepted"
assert_file user_marker_from_project "$FAKE_HOME/.cursor/lgt-policy-accepted"
GOT_HASH="$(awk -F= '/^policy_hash=/{print $2; exit}' "$PROJECT/.cursor/lgt-policy-accepted")"
assert_eq marker_hash "$HASH" "$GOT_HASH"
grep -q '^accepted_at=' "$PROJECT/.cursor/lgt-policy-accepted" && echo "OK   marker_accepted_at" || {
  echo "FAIL marker_accepted_at" >&2
  FAIL=1
}
grep -q '^agree_via=flag$' "$PROJECT/.cursor/lgt-policy-accepted" && echo "OK   marker_agree_via" || {
  echo "FAIL marker_agree_via" >&2
  FAIL=1
}
grep -q '^policy_docs=PRIVACY.md,TERMS.md,DISCLAIMER.md,NOTICE.md' "$PROJECT/.cursor/lgt-policy-accepted" && echo "OK   marker_docs" || {
  echo "FAIL marker_docs" >&2
  FAIL=1
}
grep -q '^kit_commit=' "$PROJECT/.cursor/lgt-policy-accepted" && echo "OK   marker_kit_commit" || {
  echo "FAIL marker_kit_commit" >&2
  FAIL=1
}

# Second install without flag succeeds (hash match)
if HOME="$FAKE_HOME" "$ROOT/scripts/install-to-project.sh" "$PROJECT" --skip-third-party-skills >/dev/null; then
  echo "OK   reinstall_skips_prompt"
else
  echo "FAIL reinstall_skips_prompt" >&2
  FAIL=1
fi

# Stale project + valid user → refresh project from prior-user
echo "policy_hash=deadbeef" >"$PROJECT/.cursor/lgt-policy-accepted"
echo "policy_hash=deadbeef" >"$PROJECT/.cursor/csp-policy-accepted"
if HOME="$FAKE_HOME" "$ROOT/scripts/install-to-project.sh" "$PROJECT" --skip-third-party-skills >/dev/null; then
  echo "OK   prior_user_seeds_project"
else
  echo "FAIL prior_user_seeds_project" >&2
  FAIL=1
fi
GOT2="$(awk -F= '/^policy_hash=/{print $2; exit}' "$PROJECT/.cursor/lgt-policy-accepted")"
assert_eq prior_user_hash "$HASH" "$GOT2"
grep -q '^agree_via=prior-user$' "$PROJECT/.cursor/lgt-policy-accepted" && echo "OK   prior_user_via" || {
  echo "FAIL prior_user_via" >&2
  FAIL=1
}

# --i-agree alias + user-only marker
USER_HOME="$TMP/home2"
mkdir -p "$USER_HOME"
if HOME="$USER_HOME" "$ROOT/scripts/install-to-project.sh" --user-only --i-agree --skip-third-party-skills >/dev/null; then
  echo "OK   user_only_i_agree"
else
  echo "FAIL user_only_i_agree" >&2
  FAIL=1
fi
assert_file user_marker "$USER_HOME/.cursor/lgt-policy-accepted"

# Env var path
USER_HOME3="$TMP/home3"
mkdir -p "$USER_HOME3"
if HOME="$USER_HOME3" CSP_AGREE_POLICY=1 "$ROOT/scripts/install-to-project.sh" --user-only --skip-third-party-skills >/dev/null; then
  echo "OK   env_agree"
else
  echo "FAIL env_agree" >&2
  FAIL=1
fi

# Both markers stale → refuse
STALE_HOME="$TMP/home_stale"
STALE_PROJ="$TMP/proj_stale"
mkdir -p "$STALE_HOME/.cursor" "$STALE_PROJ/.git" "$STALE_PROJ/.cursor"
git -C "$STALE_PROJ" init -q
echo "policy_hash=deadbeef" >"$STALE_HOME/.cursor/lgt-policy-accepted"
echo "policy_hash=deadbeef" >"$STALE_HOME/.cursor/csp-policy-accepted"
echo "policy_hash=deadbeef" >"$STALE_PROJ/.cursor/lgt-policy-accepted"
echo "policy_hash=deadbeef" >"$STALE_PROJ/.cursor/csp-policy-accepted"
set +e
OUT2="$(HOME="$STALE_HOME" "$ROOT/scripts/install-to-project.sh" "$STALE_PROJ" --skip-third-party-skills 2>&1)"
RC2=$?
set -e
if [[ "$RC2" -ne 0 ]] && echo "$OUT2" | grep -q "agree-policy"; then
  echo "OK   stale_hash_refuses"
else
  echo "FAIL stale_hash_refuses rc=$RC2 out=$OUT2" >&2
  FAIL=1
fi

# --- update path (same gate; no sync without agree) ---

assert_grep cli_policy_before_pull "bin/lgt" 'policy-check-only'
assert_grep installer_policy_check_only "scripts/install-to-project.sh" 'POLICY_CHECK_ONLY'

UPD_HOME="$TMP/home_upd"
UPD_PROJ="$TMP/proj_upd"
mkdir -p "$UPD_HOME" "$UPD_PROJ/.git"
git -C "$UPD_PROJ" init -q
# Sentinel file: update must not create project install artifacts without agree
SENTINEL_BEFORE="$(find "$UPD_PROJ" -type f 2>/dev/null | sort | cksum)"

set +e
OUT_UPD="$(HOME="$UPD_HOME" "$ROOT/scripts/install-to-project.sh" --update "$UPD_PROJ" --skip-third-party-skills 2>&1)"
RC_UPD=$?
set -e
if [[ "$RC_UPD" -ne 0 ]] && echo "$OUT_UPD" | grep -q "agree-policy"; then
  echo "OK   update_refuse_without_agree"
else
  echo "FAIL update_refuse_without_agree rc=$RC_UPD out=$OUT_UPD" >&2
  FAIL=1
fi
if [[ -f "$UPD_PROJ/.cursor/lgt-policy-accepted" || -f "$UPD_HOME/.cursor/lgt-policy-accepted" ]]; then
  echo "FAIL update_marker_should_not_exist" >&2
  FAIL=1
else
  echo "OK   update_no_marker_without_agree"
fi
# No project hooks/rules/agents from a refused update
if [[ -d "$UPD_PROJ/.cursor/hooks" || -d "$UPD_PROJ/.cursor/agents" || -d "$UPD_HOME/.cursor/skills" ]]; then
  echo "FAIL update_mutated_without_agree" >&2
  FAIL=1
else
  echo "OK   update_no_file_changes_without_agree"
fi
SENTINEL_AFTER="$(find "$UPD_PROJ" -type f 2>/dev/null | sort | cksum)"
assert_eq update_project_unchanged "$SENTINEL_BEFORE" "$SENTINEL_AFTER"

# policy-check-only alone also refuses without agree (CLI pre-pull gate)
set +e
OUT_CHK="$(HOME="$UPD_HOME" "$ROOT/scripts/install-to-project.sh" --update --policy-check-only "$UPD_PROJ" --skip-third-party-skills 2>&1)"
RC_CHK=$?
set -e
if [[ "$RC_CHK" -ne 0 ]] && echo "$OUT_CHK" | grep -q "agree-policy"; then
  echo "OK   policy_check_only_refuse"
else
  echo "FAIL policy_check_only_refuse rc=$RC_CHK out=$OUT_CHK" >&2
  FAIL=1
fi

# update with --agree-policy succeeds
if HOME="$UPD_HOME" "$ROOT/scripts/install-to-project.sh" --update "$UPD_PROJ" --agree-policy --skip-third-party-skills >/dev/null; then
  echo "OK   update_with_agree"
else
  echo "FAIL update_with_agree" >&2
  FAIL=1
fi
assert_file update_project_marker "$UPD_PROJ/.cursor/lgt-policy-accepted"
assert_file update_user_marker "$UPD_HOME/.cursor/lgt-policy-accepted"

# Matching marker: update without flag proceeds
if HOME="$UPD_HOME" "$ROOT/scripts/install-to-project.sh" --update "$UPD_PROJ" --skip-third-party-skills >/dev/null; then
  echo "OK   update_skips_prompt_with_marker"
else
  echo "FAIL update_skips_prompt_with_marker" >&2
  FAIL=1
fi

# Stale hash on update → refuse
echo "policy_hash=deadbeef" >"$UPD_PROJ/.cursor/lgt-policy-accepted"
echo "policy_hash=deadbeef" >"$UPD_PROJ/.cursor/csp-policy-accepted"
echo "policy_hash=deadbeef" >"$UPD_HOME/.cursor/lgt-policy-accepted"
echo "policy_hash=deadbeef" >"$UPD_HOME/.cursor/csp-policy-accepted"
set +e
OUT_STALE_UPD="$(HOME="$UPD_HOME" "$ROOT/scripts/install-to-project.sh" --update "$UPD_PROJ" --skip-third-party-skills 2>&1)"
RC_STALE_UPD=$?
set -e
if [[ "$RC_STALE_UPD" -ne 0 ]] && echo "$OUT_STALE_UPD" | grep -q "agree-policy"; then
  echo "OK   update_stale_hash_refuses"
else
  echo "FAIL update_stale_hash_refuses rc=$RC_STALE_UPD out=$OUT_STALE_UPD" >&2
  FAIL=1
fi

# CLI: bin/lgt update refuses without agree before pull (fake HOME, no upstream → skip pull after gate)
CLI_HOME="$TMP/home_cli"
CLI_PROJ="$TMP/proj_cli"
mkdir -p "$CLI_HOME" "$CLI_PROJ/.git"
git -C "$CLI_PROJ" init -q
set +e
OUT_CLI="$(HOME="$CLI_HOME" "$ROOT/bin/lgt" update "$CLI_PROJ" --skip-third-party-skills 2>&1)"
RC_CLI=$?
set -e
if [[ "$RC_CLI" -ne 0 ]] && echo "$OUT_CLI" | grep -q "agree-policy"; then
  echo "OK   lgt_update_refuse_without_agree"
else
  echo "FAIL lgt_update_refuse_without_agree rc=$RC_CLI out=$OUT_CLI" >&2
  FAIL=1
fi
# Must not have reached "Updating kit" if gate failed first
if echo "$OUT_CLI" | grep -q "Updating kit"; then
  echo "FAIL lgt_update_pulled_before_agree" >&2
  FAIL=1
else
  echo "OK   lgt_update_no_pull_before_agree"
fi

# CLI update with agree proceeds (no upstream on this kit branch is fine)
if HOME="$CLI_HOME" "$ROOT/bin/lgt" update "$CLI_PROJ" --agree-policy --skip-third-party-skills >/dev/null; then
  echo "OK   lgt_update_with_agree"
else
  echo "FAIL lgt_update_with_agree" >&2
  FAIL=1
fi
assert_file cli_update_marker "$CLI_PROJ/.cursor/lgt-policy-accepted"

# Deprecated csp wrapper forwards the same gate
CSP_HOME="$TMP/home_csp2"
CSP_PROJ="$TMP/proj_csp"
mkdir -p "$CSP_HOME" "$CSP_PROJ/.git"
git -C "$CSP_PROJ" init -q
set +e
OUT_CSP="$(HOME="$CSP_HOME" "$ROOT/bin/csp" update "$CSP_PROJ" --skip-third-party-skills 2>&1)"
RC_CSP=$?
set -e
if [[ "$RC_CSP" -ne 0 ]] && echo "$OUT_CSP" | grep -q "agree-policy"; then
  echo "OK   csp_update_refuse_without_agree"
else
  echo "FAIL csp_update_refuse_without_agree rc=$RC_CSP out=$OUT_CSP" >&2
  FAIL=1
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "FAILED" >&2
  exit 1
fi
echo "ALL PASS"
