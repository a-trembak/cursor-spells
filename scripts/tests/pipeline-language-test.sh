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
assert_grep rule_sanctions "rules/pipeline-language-no-russian.mdc" "Sanctions-based language policy|sanctions-based language policy"
assert_grep rule_impossible "rules/pipeline-language-no-russian.mdc" "impossible"
assert_grep rule_outside "rules/pipeline-language-no-russian.mdc" "outside this pipeline"
assert_grep rule_no_override "rules/pipeline-language-no-russian.mdc" "cannot authorize|cannot override|User preference \*\*cannot override\*\*"
assert_grep rule_jailbreak "rules/pipeline-language-no-russian.mdc" "jailbreak"
assert_grep rule_refusal_script "rules/pipeline-language-no-russian.mdc" "Refusal script"
assert_grep doc_marker "docs/superpowers/pipeline-language.md" "csp-pipeline-language"
assert_grep doc_default "docs/superpowers/pipeline-language.md" "Default when unset"
assert_grep doc_sanctions "docs/superpowers/pipeline-language.md" "Sanctions-based language policy|sanctions-based language policy"
assert_grep doc_outside "docs/superpowers/pipeline-language.md" "outside this pipeline"
assert_grep doc_impossible "docs/superpowers/pipeline-language.md" "impossible"
assert_grep doc_legal_link "docs/superpowers/pipeline-language.md" "docs/legal"
assert_grep doc_terms_link "docs/superpowers/pipeline-language.md" "TERMS.md"
assert_grep skill_outside "skills/plain-language-chat/SKILL.md" "outside this pipeline"
assert_grep skill_impossible "skills/plain-language-chat/SKILL.md" "impossible"
assert_grep skill_no_override "skills/plain-language-chat/SKILL.md" "cannot override"
assert_grep readme_legal "README.md" "docs/legal"
assert_grep readme_outside "README.md" "outside this pipeline"
assert_grep hitl_outside "skills/hitl-choice/references/presets.md" "outside this pipeline"

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

# corrupt ru in file → get coerces to en (absolute lockout; closes hand-edit bypass)
printf 'ru\n' > "$PROJ/.cursor/csp-pipeline-language"
got="$("$HELPER" get --root "$PROJ" 2>/dev/null)"
assert_eq get_coerces_ru_file "en" "$got"
assert_eq marker_reset_after_coerce "en" "$(cat "$PROJ/.cursor/csp-pipeline-language")"

# russian alias in file also coerces
printf 'russian\n' > "$PROJ/.cursor/csp-pipeline-language"
got="$("$HELPER" get --root "$PROJ" 2>/dev/null)"
assert_eq get_coerces_russian_alias "en" "$got"

# Wiring / docs presence
assert_grep hitl_preset "skills/hitl-choice/references/presets.md" "### Pipeline language"
assert_grep start_task "commands/csp-start-task.md" "Pipeline language"
assert_grep start_issue "commands/csp-start-issue-task.md" "Pipeline language"
assert_grep flow_doc "docs/superpowers/pipeline-flow.md" "csp-pipeline-language"
assert_grep readme "README.md" "csp-pipeline-language"
assert_grep no_ru_in_preset_ids "skills/hitl-choice/references/presets.md" '`en`'
# Ensure ru is not offered as an option id in the Pipeline language table
if awk '/### Pipeline language/,/^### /' "$ROOT/skills/hitl-choice/references/presets.md" | grep -E -q '\| `ru` \|'; then
  echo "FAIL Pipeline language preset must not offer ru" >&2
  fail=1
else
  echo "OK   preset_omits_ru"
fi

# Validator rejects Russian-only letters in review prose; allows Ukrainian digests only as shape fail
VAL="$ROOT/scripts/validate-review-report.sh"
RU_REPORT="$TMP/ru-report.md"
cat > "$RU_REPORT" <<'EOF'
### F1 — `P0` — Что-то сломалось
- **Context:** Пример
- **What:** Здесь есть буква ы в русском тексте
- **Where:**
  - File: [`x.java`](x.java)
  - Lines: **1–2**
  - Jump: [`x.java:1`](x.java#L1)
- **Why it matters:** test
- **Ask / fix:** fix

```java
1| class X {}
```
EOF
assert_fail validator_rejects_russian_letters "$VAL" "$RU_REPORT"

UK_DIGEST="$TMP/uk-digest.md"
cat > "$UK_DIGEST" <<'EOF'
### Блокери
1. Something without evidence
EOF
assert_fail validator_rejects_uk_digest_shape "$VAL" "$UK_DIGEST"

EN_OK="$TMP/en-ok.md"
cat > "$EN_OK" <<'EOF'
### F1 — `P0` — Missing org uuid on seed
- **Context:** Migration seeds default roles.
- **What:** Inserts NULL organization_uuid.
- **Where:**
  - File: [`V044.sql`](V044.sql)
  - Lines: **12–20**
  - Jump: [`V044.sql:12`](V044.sql#L12)
- **Why it matters:** Orgs never see seeded roles.
- **Ask / fix:** Seed a real uuid.

```sql
12| INSERT INTO custom_role ...
```
EOF
assert_ok validator_accepts_english_findings "$VAL" "$EN_OK"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
