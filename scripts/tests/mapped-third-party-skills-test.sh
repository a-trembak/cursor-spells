#!/usr/bin/env bash
# Contract: curated (Tier-1 / already-mapped) third-party skills listed in
# skill-map Database skill routing (always-on + current-stack) must appear in
# recommended-install lists and be installable from `csp install` without
# agents running `npx skills add` mid-review.
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

assert_absent() {
  local name="$1" path="$2" pattern="$3"
  if grep -E -q "$pattern" "$ROOT/$path"; then
    echo "FAIL $name: /$pattern/ still in $path" >&2
    fail=1
  else
    echo "OK   $name"
  fi
}

# Extract owner/repo@skill ids from a markdown slice on stdin.
# Drop the placeholder shape used in the Skill resolution protocol quote.
extract_ids() {
  grep -oE '[A-Za-z0-9._-]+/[A-Za-z0-9._-]+@[A-Za-z0-9._-]+' \
    | grep -vE '^owner/repo@' \
    | sort -u
}

# Always-on + current-stack rows; stop before Conditional (manual / detect-only).
db_default_ids() {
  awk '
    /^## Database skill routing$/ {on=1}
    /^### Conditional/ {on=0}
    on {print}
  ' "$ROOT/skills/engineer-review/references/skill-map.md" | extract_ids
}

# README has earlier bash fences (clone/install). Prefer the Recommended section.
recommended_ids_from_file() {
  local file="$1"
  if grep -q '^## Recommended third-party skills$' "$ROOT/$file"; then
    awk '
      /^## Recommended third-party skills$/ {want=1}
      want && /^```bash$/ {on=1; next}
      on && /^```$/ {exit}
      on {print}
    ' "$ROOT/$file" | extract_ids
  else
    awk '
      /^```bash$/ {on=1; next}
      on && /^```$/ {exit}
      on {print}
    ' "$ROOT/$file" | extract_ids
  fi
}

SKILLMAP="skills/engineer-review/references/skill-map.md"
HELPER="scripts/mapped-third-party-skills.sh"

assert_file "$SKILLMAP"
assert_file "scripts/install-to-project.sh"
assert_file "README.md"
assert_file "agents/software-developer.md"
assert_file "agents/review-logic.md"
assert_file "agents/review-architecture.md"
assert_file "$HELPER"

# Named MySQL + always-on migration skills must be in both recommended lists.
for id in \
  planetscale/database-skills@mysql \
  affaan-m/everything-claude-code@mysql-patterns \
  github/awesome-copilot@sql-code-review \
  wshobson/agents@database-migration \
  affaan-m/everything-claude-code@database-migrations
do
  if grep -F -q "$id" "$ROOT/$SKILLMAP"; then
    echo "OK   skillmap_names $id"
  else
    echo "FAIL skillmap_names: $id not in $SKILLMAP" >&2
    fail=1
  fi
  if recommended_ids_from_file "$SKILLMAP" | grep -Fxq "$id"; then
    echo "OK   skillmap_recommended $id"
  else
    echo "FAIL skillmap_recommended: $id not in $SKILLMAP recommended bash block" >&2
    fail=1
  fi
  if recommended_ids_from_file "README.md" | grep -Fxq "$id"; then
    echo "OK   readme_recommended $id"
  else
    echo "FAIL readme_recommended: $id not in README.md recommended bash block" >&2
    fail=1
  fi
done

# Every current-stack + always-on owner/repo@skill id must be in recommended installs.
while IFS= read -r id; do
  [[ -n "$id" ]] || continue
  if recommended_ids_from_file "$SKILLMAP" | grep -Fxq "$id"; then
    echo "OK   skillmap_covers_db $id"
  else
    echo "FAIL skillmap_covers_db: $id in Database skill routing but not recommended installs" >&2
    fail=1
  fi
  if recommended_ids_from_file "README.md" | grep -Fxq "$id"; then
    echo "OK   readme_covers_db $id"
  else
    echo "FAIL readme_covers_db: $id in Database skill routing but not README recommended installs" >&2
    fail=1
  fi
  # Agents can find the body: GitHub / skills.sh link or an npx skills add line.
  if grep -E "\[$id\]\(https://[^)]+\)|npx skills add $id|https://(github\\.com|skills\\.sh)/" "$ROOT/$SKILLMAP" \
    | grep -F -q "$id"; then
    echo "OK   skillmap_link $id"
  else
    echo "FAIL skillmap_link: $id has no GitHub/skills.sh link or npx skills add line in $SKILLMAP" >&2
    fail=1
  fi
done < <(db_default_ids)

# Clickable markdown links to the canonical map (and Database skill routing).
link_pat='\[[^]]+\]\([^)]*skill-map\.md[^)]*\)'
db_frag='skill-map.md#database-skill-routing'
assert_grep sd_agent_link "agents/software-developer.md" "$link_pat"
assert_grep sd_agent_db "agents/software-developer.md" "$db_frag"
assert_grep logic_agent_link "agents/review-logic.md" "$link_pat"
assert_grep logic_agent_db "agents/review-logic.md" "$db_frag"
assert_grep arch_agent_link "agents/review-architecture.md" "$link_pat"
assert_grep arch_agent_db "agents/review-architecture.md" "$db_frag"
assert_grep er_agent_link "agents/engineer-reviewer.md" "$link_pat"
assert_grep bug_agent_link "agents/bug-fixer.md" "$link_pat"
assert_grep sd_skill_link "skills/software-developer/SKILL.md" "$link_pat"
assert_grep sd_skill_db "skills/software-developer/SKILL.md" "$db_frag"
assert_grep bug_skill_link "skills/bug-fix/SKILL.md" "$link_pat"

# Agents must never silently install mid-run.
assert_absent sd_no_npx "agents/software-developer.md" "npx skills add"
assert_absent er_no_npx "agents/engineer-reviewer.md" "npx skills add"
assert_absent logic_no_npx "agents/review-logic.md" "npx skills add"
assert_grep sd_no_auto "agents/software-developer.md" "Never auto-install"
assert_grep er_tier2 "agents/engineer-reviewer.md" "Never install a third-party skill"

# Installer: skip flag, helper as source of truth (no hardcoded skill ids).
assert_grep install_skip_flag "scripts/install-to-project.sh" "skip-third-party-skills"
assert_grep install_skip_help "scripts/install-to-project.sh" "skip-third-party-skills"
assert_grep install_skip_env "scripts/install-to-project.sh" "CSP_SKIP_THIRD_PARTY_SKILLS"
assert_grep csp_skip_help "bin/cursor-spells" "skip-third-party-skills"
assert_grep install_sources_helper "scripts/install-to-project.sh" "mapped-third-party-skills.sh"
assert_grep install_calls_mtp "scripts/install-to-project.sh" "mtp_install_curated"
assert_absent install_no_hardcode_planetscale "scripts/install-to-project.sh" "planetscale/database-skills"
assert_grep readme_skip_flag "README.md" "skip-third-party-skills"
assert_grep skillmap_skip_manual "skills/engineer-review/references/skill-map.md" "Conditional"

# Existing installer-running tests must skip network so they stay fast.
assert_grep plc_skip_third "scripts/tests/plain-language-chat-test.sh" "skip-third-party-skills|CSP_SKIP_THIRD_PARTY_SKILLS"

# Helper runtime: parse skill-map; skip; non-fatal npx failure; no conditional by default.
if [[ -f "$ROOT/$HELPER" ]]; then
  # shellcheck source=../mapped-third-party-skills.sh
  source "$ROOT/$HELPER"

  helper_db="$(mtp_db_default_ids | sort -u)"
  map_db="$(db_default_ids)"
  if [[ "$helper_db" == "$map_db" ]]; then
    echo "OK   helper_db_matches_map"
  else
    echo "FAIL helper_db_matches_map: helper and skill-map Database default ids differ" >&2
    echo "helper:" >&2
    echo "$helper_db" >&2
    echo "map:" >&2
    echo "$map_db" >&2
    fail=1
  fi

  while IFS= read -r id; do
    [[ -n "$id" ]] || continue
    if mtp_install_ids "" | grep -Fxq "$id"; then
      echo "OK   helper_installs_db $id"
    else
      echo "FAIL helper_installs_db: $id not in mtp_install_ids default set" >&2
      fail=1
    fi
  done < <(db_default_ids)

  # Conditional Postgres ids must not install unless the project uses Postgres.
  if mtp_install_ids "" | grep -Fq "postgresql-table-design"; then
    echo "FAIL helper_skips_conditional: postgresql-table-design in default install set" >&2
    fail=1
  else
    echo "OK   helper_skips_conditional"
  fi

  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  mkdir -p "$TMP/bin" "$TMP/home" "$TMP/app"
  git -C "$TMP/app" init -q

  cat > "$TMP/bin/npx" <<'FAKE'
#!/usr/bin/env bash
echo "npx $*" >> "${MTP_NPX_LOG:?}"
if [[ -n "${MTP_NPX_FAIL:-}" ]]; then
  echo "fake npx failing" >&2
  exit 1
fi
exit 0
FAKE
  chmod +x "$TMP/bin/npx"

  export MTP_NPX_LOG="$TMP/npx.log"
  export PATH="$TMP/bin:$PATH"
  unset MTP_NPX_FAIL || true

  : > "$MTP_NPX_LOG"
  if CSP_SKIP_THIRD_PARTY_SKILLS=1 mtp_install_curated "$TMP/app" >/dev/null; then
    if [[ -s "$MTP_NPX_LOG" ]]; then
      echo "FAIL skip_env_no_npx: npx still ran under CSP_SKIP_THIRD_PARTY_SKILLS=1" >&2
      fail=1
    else
      echo "OK   skip_env_no_npx"
    fi
  else
    echo "FAIL skip_env_no_npx: mtp_install_curated exited non-zero" >&2
    fail=1
  fi

  : > "$MTP_NPX_LOG"
  export MTP_NPX_FAIL=1
  set +e
  out="$(mtp_install_curated "$TMP/app" 2>&1)"
  rc=$?
  set -e
  unset MTP_NPX_FAIL
  if [[ "$rc" -ne 0 ]]; then
    echo "FAIL npx_fail_nonfatal: expected exit 0, got $rc" >&2
    fail=1
  elif ! grep -E -q "skill_missing:" <<<"$out"; then
    echo "FAIL npx_fail_nonfatal: output lacked skill_missing" >&2
    echo "$out" >&2
    fail=1
  else
    echo "OK   npx_fail_nonfatal"
  fi

  # Detect Postgres in a consumer project → include conditional Postgres ids.
  mkdir -p "$TMP/pg"
  printf '%s\n' '{"dependencies":{"pg":"8.0.0"}}' > "$TMP/pg/package.json"
  if mtp_detect_conditional_ids "$TMP/pg" | grep -Fq "postgresql-table-design"; then
    echo "OK   detect_postgres"
  else
    echo "FAIL detect_postgres: expected postgresql-table-design for pg dependency" >&2
    fail=1
  fi

  # Full installer: skip flag still links kit bits; npx failure does not brick kit install.
  : > "$MTP_NPX_LOG"
  if ! HOME="$TMP/home" PATH="$TMP/bin:$PATH" \
    "$ROOT/scripts/install-to-project.sh" --user-only --skip-third-party-skills >/dev/null; then
    echo "FAIL installer_skip_still_works: kit install failed with skip flag" >&2
    fail=1
  elif [[ ! -f "$TMP/home/.cursor/rules/plain-language-chat.mdc" ]]; then
    echo "FAIL installer_skip_still_works: kit rule missing after skip install" >&2
    fail=1
  elif [[ -s "$MTP_NPX_LOG" ]]; then
    echo "FAIL installer_skip_still_works: npx ran despite --skip-third-party-skills" >&2
    fail=1
  else
    echo "OK   installer_skip_still_works"
  fi

  export MTP_NPX_FAIL=1
  : > "$MTP_NPX_LOG"
  set +e
  HOME="$TMP/home2" PATH="$TMP/bin:$PATH" \
    "$ROOT/scripts/install-to-project.sh" --user-only >/tmp/mtp-install-fail.log 2>&1
  inst_rc=$?
  set -e
  mkdir -p "$TMP/home2"
  if [[ "$inst_rc" -ne 0 ]]; then
    echo "FAIL installer_npx_fail_continues: kit install exited $inst_rc" >&2
    cat /tmp/mtp-install-fail.log >&2
    fail=1
  else
    echo "OK   installer_npx_fail_continues"
  fi
  unset MTP_NPX_FAIL
else
  echo "FAIL helper missing; runtime checks skipped" >&2
fi

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
