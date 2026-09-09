# Teach-review Kit Instructions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** After a review miss, generalize the human’s remark into kit instructions and land a `learn/…` branch on the `cursor-spells` remote (`draft_merge` by default).

**Architecture:** A sourceable bash library owns config resolve, kit-path checks, and branch naming. `csp install` copies a commented JSONC template create-once. Skill `teach-review` (plus `/csp-teach-review`) edits the kit checkout and lands git. Orchestrators only ask `miss` / `no_miss` and invoke the skill — they never edit kit git.

**Tech Stack:** Bash helpers + Cursor skill/command/agent markdown in the cursor-spells kit; `gh` for draft pull requests; consumer install via `scripts/install-to-project.sh`.

## Global Constraints

- Spec: `docs/superpowers/specs/2026-08-21-teach-review-kit-instructions-design.md`.
- v1 config key is only `land`: `draft_merge` (default) or `auto_push`.
- Project config wins when `land` is valid; invalid project `land` → `draft_merge` (no fallthrough); missing project `land` falls through to user file then default.
- Install copies the template only when the destination is missing; never overwrite.
- `auto_push`: `git push` of `learn/…` only. `draft_merge`: same plus `gh pr create --draft` into kit `main`. Neither merges. Neither updates the local kit checkout.
- Orchestrators must not edit kit git. One miss class per `teach-review` invocation.
- Do not replace `csp-review-learn` or consumer `.cursor/review-learnings.md`.
- Frequent small commits — one per task.
- Nested fences: use 4-backtick outer fences when embedding ``` inside plan steps.
- User-facing chat in this kit still goes through `plain-language-chat` (full words). Skill/spec/plan English is unchanged.

---

## File Structure

| Path | Responsibility |
|------|----------------|
| `scripts/teach-review.sh` | JSONC strip, `land` resolve, kit path/dirty, `learn/` branch names, create-once install copy |
| `scripts/tests/teach-review-test.sh` | Shell tests for the helper (temp dirs / temp git) |
| `skills/teach-review/references/cursor-spells-learn.json` | Install template with `//` catalog above `land` |
| `scripts/install-to-project.sh` | Create-once copy to `~/.cursor/` and project `.cursor/` |
| `skills/teach-review/SKILL.md` | Generalize, route, edit kit, commit, land |
| `commands/csp-teach-review.md` | Slash entry |
| `skills/hitl-choice/SKILL.md` | Preset **Teach-review miss** (`miss` / `no_miss`) |
| `agents/csp-engineer-reviewer.md`, `skills/engineer-review/SKILL.md` | After validated report: miss gate, then invoke skill |
| `agents/csp-pr-reviewer.md`, `skills/pr-review/SKILL.md` | Same miss gate |
| `scripts/tests/teach-review-contract-test.sh` | Grep contracts (tokens, wiring, install, README) |
| `README.md`, `docs/superpowers/pipeline-flow.md` | Document command + gate |
| `docs/superpowers/dogfood/engineer-review-checklist.md` | Post-report miss gate row |

Do **not** copy `teach-review.sh` into consumer `scripts/` (only the kit checkout uses it). `csp install` still links `skills/teach-review` and `commands/csp-teach-review.md` via the existing skills/commands walk.

---

### Task 1: `teach-review.sh` helper + shell tests (TDD)

**Files:**
- Create: `scripts/teach-review.sh`
- Create: `scripts/tests/teach-review-test.sh`

**Interfaces:**
- `tr_strip_jsonc` — filter stdin; drop lines matching `^[[:space:]]*//`
- `tr_land_from_file <path>` — stdout `auto_push` \| `draft_merge` \| `invalid` \| empty (missing file or missing `land` key)
- `tr_resolve_land <project_root>` — uses `TR_HOME` if set, else `$HOME`; stdout always `auto_push` or `draft_merge`; stderr one-line warn when project `land` is `invalid`
- `tr_kit_path <project_root>` — first existing `cursor-spells-kit-path` under `<project>/.cursor/` then `$TR_HOME/.cursor/`; stdout path or empty
- `tr_is_kit_checkout <path>` — exit 0 if git work tree and `skills/engineer-review` + `agents/csp-engineer-reviewer.md` exist
- `tr_kit_is_dirty <kit>` — exit 0 if `git -C <kit> status --porcelain` is non-empty
- `tr_learn_branch_base <miss_class> [YYYYMMDD]` — stdout `learn/<miss_class>-<date>` (date default: `date +%Y%m%d`)
- `tr_unique_learn_branch <kit> <base>` — append `-2`, `-3`, … while `refs/heads/<name>` or `refs/remotes/origin/<name>` exists
- `tr_install_learn_config <dest> <template>` — `mkdir -p` dest dir; `cp` only if dest missing; exit 0 if dest already exists
- `tr_land_opens_pr <land>` — exit 0 for `draft_merge`, exit 1 for `auto_push`

- [ ] **Step 1: Write the failing test**

Create `scripts/tests/teach-review-test.sh`:

````bash
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
printf '%s\n' '{}' > "$KIT/agents/csp-engineer-reviewer.md"
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

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
````

chmod +x that file.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash scripts/tests/teach-review-test.sh`

Expected: FAIL because `scripts/teach-review.sh` is missing (`source` error) or functions are undefined.

- [ ] **Step 3: Write minimal implementation**

Create `scripts/teach-review.sh`:

````bash
#!/usr/bin/env bash
# Teach-review helpers (sourceable library).
# Usage: source scripts/teach-review.sh

tr__home() {
  printf '%s' "${TR_HOME:-$HOME}"
}

tr_strip_jsonc() {
  sed -E '/^[[:space:]]*\/\//d'
}

tr_land_from_file() {
  local f="$1" json="" land=""
  if [[ ! -f "$f" ]]; then
    printf ''
    return 0
  fi
  json="$(tr_strip_jsonc < "$f")"
  land="$(printf '%s\n' "$json" | sed -nE 's/.*"land"[[:space:]]*:[[:space:]]*"(auto_push|draft_merge)".*/\1/p' | head -n 1)"
  if [[ -n "$land" ]]; then
    printf '%s' "$land"
    return 0
  fi
  if printf '%s\n' "$json" | grep -Eq '"land"[[:space:]]*:'; then
    printf 'invalid'
    return 0
  fi
  printf ''
}

tr_resolve_land() {
  local project_root="${1%/}" home dest land
  home="$(tr__home)"
  dest="$project_root/.cursor/cursor-spells-learn.json"
  land="$(tr_land_from_file "$dest")"
  if [[ "$land" == "auto_push" || "$land" == "draft_merge" ]]; then
    printf '%s' "$land"
    return 0
  fi
  if [[ "$land" == "invalid" ]]; then
    echo "teach-review: invalid land in $dest — using draft_merge" >&2
    printf '%s' "draft_merge"
    return 0
  fi
  dest="$home/.cursor/cursor-spells-learn.json"
  land="$(tr_land_from_file "$dest")"
  if [[ "$land" == "auto_push" || "$land" == "draft_merge" ]]; then
    printf '%s' "$land"
    return 0
  fi
  if [[ "$land" == "invalid" ]]; then
    echo "teach-review: invalid land in $dest — using draft_merge" >&2
  fi
  printf '%s' "draft_merge"
}

tr_kit_path() {
  local project_root="${1%/}" home f
  home="$(tr__home)"
  f="$project_root/.cursor/cursor-spells-kit-path"
  if [[ -f "$f" ]]; then
    tr -d '\n' < "$f"
    return 0
  fi
  f="$home/.cursor/cursor-spells-kit-path"
  if [[ -f "$f" ]]; then
    tr -d '\n' < "$f"
    return 0
  fi
  printf ''
}

tr_is_kit_checkout() {
  local path="${1%/}"
  [[ -d "$path/.git" || -f "$path/.git" ]] || return 1
  git -C "$path" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
  [[ -e "$path/skills/engineer-review" && -f "$path/agents/csp-engineer-reviewer.md" ]]
}

tr_kit_is_dirty() {
  local kit="$1" out
  out="$(git -C "$kit" status --porcelain 2>/dev/null || true)"
  [[ -n "$out" ]]
}

tr_learn_branch_base() {
  local miss_class="$1" day="${2:-}"
  if [[ -z "$day" ]]; then
    day="$(date +%Y%m%d)"
  fi
  printf 'learn/%s-%s' "$miss_class" "$day"
}

tr_unique_learn_branch() {
  local kit="$1" base="$2" name="$2" n=2
  while git -C "$kit" show-ref --verify --quiet "refs/heads/$name" \
     || git -C "$kit" show-ref --verify --quiet "refs/remotes/origin/$name"; do
    name="${base}-${n}"
    n=$((n + 1))
  done
  printf '%s' "$name"
}

tr_install_learn_config() {
  local dest="$1" template="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -f "$dest" ]]; then
    return 0
  fi
  cp "$template" "$dest"
}

tr_land_opens_pr() {
  [[ "$1" == "draft_merge" ]]
}
````

- [ ] **Step 4: Run the tests and make sure they pass**

Run: `bash scripts/tests/teach-review-test.sh`

Expected: `ALL PASS`.

- [ ] **Step 5: Commit**

````bash
git add scripts/teach-review.sh scripts/tests/teach-review-test.sh
git commit -m "feat(review): add teach-review config and branch helpers"
````

---

### Task 2: Config template + create-once install

**Files:**
- Create: `skills/teach-review/references/cursor-spells-learn.json`
- Modify: `scripts/install-to-project.sh` (`install_user_bits` after kit-path write / plain-language copy; `install_project_bits` after `.cursor/` mkdir)
- Modify: `scripts/tests/teach-review-test.sh` (install copies the real template)
- Modify: `README.md` install tables (user + project rows)

**Interfaces:**
- Consumes: `tr_install_learn_config`
- Template body is the spec JSONC (comments above `land`, value `draft_merge`)

- [ ] **Step 1: Write the failing test**

Append to `scripts/tests/teach-review-test.sh` before `ALL PASS`:

````bash
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
````

- [ ] **Step 2: Run test to verify it fails**

Run: `bash scripts/tests/teach-review-test.sh`

Expected: FAIL `missing template` and/or `install missing tr_install_learn_config`.

- [ ] **Step 3: Write template + install wiring**

Create `skills/teach-review/references/cursor-spells-learn.json` with **this exact body**:

````jsonc
{
  // land — how teach-review sends the new kit instructions to GitHub.
  // Does not merge to main. Does not switch or update this machine's kit checkout.
  //
  // Variants (pick exactly one string):
  //   "draft_merge"  (default) Push branch learn/<class>-<date> and open a draft
  //                  pull request into main. You merge when you want the rule live.
  //   "auto_push"    Push the same learn/ branch only. No pull request.
  "land": "draft_merge"
}
````

In `scripts/install-to-project.sh`, after `KIT_ROOT=...` is set, the script already can source helpers. Near the top after `KIT_ROOT` (after `set -euo pipefail` block is fine at first use), source once inside the install functions:

At the start of `install_user_bits`, add:

````bash
  # shellcheck source=teach-review.sh
  source "$KIT_ROOT/scripts/teach-review.sh"
  tr_install_learn_config "$HOME/.cursor/cursor-spells-learn.json" \
    "$KIT_ROOT/skills/teach-review/references/cursor-spells-learn.json"
  echo "learn-config: $HOME/.cursor/cursor-spells-learn.json"
````

At the start of `install_project_bits` (after `mkdir -p "$PROJECT/.cursor/..."`):

````bash
  # shellcheck source=teach-review.sh
  source "$KIT_ROOT/scripts/teach-review.sh"
  tr_install_learn_config "$PROJECT/.cursor/cursor-spells-learn.json" \
    "$KIT_ROOT/skills/teach-review/references/cursor-spells-learn.json"
  echo "learn-config: $PROJECT/.cursor/cursor-spells-learn.json"
````

`--user-only` already calls only `install_user_bits` — user file is still created.

README table A (`~/.cursor/`), add row after kit-path:

````markdown
| `~/.cursor/cursor-spells-learn.json` | Created if missing — `land` (`draft_merge` default / `auto_push`); never overwritten on update |
````

README table B (`<project>/`), add row after kit-path:

````markdown
| `<project>/.cursor/cursor-spells-learn.json` | Created if missing — same template; never overwritten on update. Project `land` wins over the user file |
````

- [ ] **Step 4: Run the tests and make sure they pass**

Run: `bash scripts/tests/teach-review-test.sh`

Expected: `ALL PASS`.

- [ ] **Step 5: Commit**

````bash
git add skills/teach-review/references/cursor-spells-learn.json scripts/install-to-project.sh scripts/tests/teach-review-test.sh README.md
git commit -m "feat(review): install teach-review land config create-once"
````

---

### Task 3: Skill `teach-review` + slash command

**Files:**
- Create: `skills/teach-review/SKILL.md`
- Create: `commands/csp-teach-review.md`

**Interfaces:**
- Consumes: `tr_resolve_land`, `tr_kit_path`, `tr_is_kit_checkout`, `tr_kit_is_dirty`, `tr_learn_branch_base`, `tr_unique_learn_branch`, `tr_land_opens_pr`
- Produces: kit edits + `learn/…` commit; push; optional draft pull request
- Callers: `/csp-teach-review`, `csp-engineer-reviewer`, `csp-pr-reviewer`

- [ ] **Step 1: Write the failing contract assertions** (file missing)

Create `scripts/tests/teach-review-contract-test.sh` with only the files this task owns; later tasks append. Start with:

````bash
#!/usr/bin/env bash
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
assert_file "skills/teach-review/SKILL.md"
assert_file "commands/csp-teach-review.md"
assert_grep skill_source "skills/teach-review/SKILL.md" "teach-review.sh"
assert_grep skill_one_class "skills/teach-review/SKILL.md" "One miss class"
assert_grep skill_no_local_merge "skills/teach-review/SKILL.md" "Do not merge"
assert_grep skill_draft "skills/teach-review/SKILL.md" "gh pr create --draft"
assert_grep skill_auto_push "skills/teach-review/SKILL.md" "auto_push"
assert_grep skill_refuse "skills/teach-review/SKILL.md" "not generalizable"
assert_grep cmd_invoke "commands/csp-teach-review.md" "teach-review"
if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
````

chmod +x.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash scripts/tests/teach-review-contract-test.sh`

Expected: FAIL missing `skills/teach-review/SKILL.md`.

- [ ] **Step 3: Write skill + command**

Create `skills/teach-review/SKILL.md`:

````markdown
---
name: teach-review
description: >-
  Turn a human remark about an engineer-review miss into generalized kit
  instructions (checklist, skill, or agent), commit on learn/…, and land on
  the cursor-spells remote. Use after Teach-review miss (miss) or /csp-teach-review.
---

# Teach-review

You write **kit instructions**, not a consumer ledger. Do not edit the application repository. Do not invoke `csp-review-learn` `mode:capture` as a substitute.

## When to Use

- Human chose `miss` after a validated `csp-engineer-reviewer` / `csp-pr-reviewer` report and pasted a description
- Slash command `/csp-teach-review` (argument is the description)

## Inputs

- Miss description (required). Empty → stop; do not invent a class.
- Current consumer project root (cwd) for config + kit-path files
- Kit checkout from `tr_kit_path`

## Steps

1. If the description is empty, ask open-ended for the miss (not a closed-set). Still empty → stop.
2. **Generalize** (one miss class per run). Strip product names, ticket ids, widgets. Produce:
   - `miss_class` kebab (example: `vague-function-names`)
   - `rule` — imperative check
   - `anti_pattern`
   - `target_kind`: `checklist` | `phase_agent` | `skill` | `new_skill_agent`
   - `target_path` kit-relative
   - `spine_wiring` if new agent
   Refuse when the only content is a ticket, a widget name, or a path with no transferable rule. Ask for a check-shaped class. Do not commit.
   If two classes are described, take the primary; tell the human to run `/csp-teach-review` again for the rest.
3. **Route** (you choose the file). Preference:
   1. Existing checklist under `skills/engineer-review/references/` or the phase skill body — append a gate that phase already loads every run.
   2. Existing phase agent (`csp-review-patterns`, `csp-review-logic`, `csp-review-deadcode`, `csp-review-simplify`, `code-comments`, …).
   3. New checklist in `references/` plus an always-on load line in the owning phase.
   4. Last resort: new `skills/<name>/SKILL.md` + `agents/<name>.md`, always-on dispatch in **both** `csp-engineer-reviewer` and `csp-pr-reviewer`, plus `skills/engineer-review/SKILL.md`, `skill-map.md`, and README tables.
   If a checklist already covers the class but the miss still happened, **strengthen that file** — do not no-op and do not clone a parallel skill.
   Never write a path outside the kit checkout.
4. Source helpers (`scripts/teach-review.sh` in the kit). Resolve:
   - `KIT="$(tr_kit_path "$PWD")"` then `tr_is_kit_checkout "$KIT"` — fail → stop with `csp install` / clone hint
   - `tr_kit_is_dirty "$KIT"` — dirty → stop; do not stash-mix
   - `land="$(tr_resolve_land "$PWD")"`
5. In the kit checkout only:
   - `git fetch origin main`
   - `base="$(tr_learn_branch_base "$miss_class")"`
   - `branch="$(tr_unique_learn_branch "$KIT" "$base")"`
   - `git -C "$KIT" checkout -b "$branch" origin/main`
   - Apply instruction edits; `git add` only those kit files
   - Commit: `feat(review): teach <miss_class>` (English; no secrets)
6. **Land** (do not merge; do not checkout `main`; do not run `csp update`):
   - `git -C "$KIT" push -u origin "$branch"`
   - If `tr_land_opens_pr "$land"` (i.e. `draft_merge`):
     `gh pr create --draft --repo <kit-origin> --base main --head "$branch" --title "feat(review): teach <miss_class>" --body "<rule one-liner + file list>"`
   - `auto_push`: skip `gh pr create`
   - Push or `gh` failure: report error + local branch name; do not claim success
7. Tell the human (full words in chat): `miss_class`, rule one-liner, kit-relative paths, branch name, pull request URL if `draft_merge` succeeded, and that reviews keep old instructions until `learn/…` is merged to `main` and this machine’s kit checkout points at that `main`.

## Hard rules

- Never edit consumer app files (including `.cursor/review-learnings.md`) in this loop.
- Never merge to `main`. Never mark the pull request ready.
- Never auto-edit kit checklists from `csp-review-learn` promote; this skill is the kit-edit path.
- Failure after a review report must not retract the report; say `/csp-teach-review` can retry.
````

Create `commands/csp-teach-review.md`:

````markdown
---
description: Publish a review miss into cursor-spells kit instructions (learn/ branch + land config).
argument-hint: "[what the reviewer missed]"
---

# /csp-teach-review

Turn a human remark into generalized **kit** instructions. Does **not** write `.cursor/review-learnings.md`. Does **not** run `engineer-review`.

## Arguments

- Optional miss description (symptom + the check that should have caught it). If omitted, ask in chat (open-ended — not Teach-review miss).

## Steps

1. Read skill `teach-review` (`skills/teach-review/SKILL.md`).
2. If the argument is empty, ask for the description. Empty still → stop.
3. Follow `teach-review` verbatim (generalize → route → kit git → land).
4. Skip the closed-set `miss` / `no_miss` gate — invoking this command **is** the miss.

## Notes

- Do not start `csp-engineer-reviewer` or `/csp-capture-escape` unless the human asks.
- One miss class per invocation.
````

- [ ] **Step 4: Run the tests and make sure they pass**

Run: `bash scripts/tests/teach-review-contract-test.sh` and `bash scripts/tests/teach-review-test.sh`

Expected: `ALL PASS` on both.

- [ ] **Step 5: Commit**

````bash
git add skills/teach-review/SKILL.md commands/csp-teach-review.md scripts/tests/teach-review-contract-test.sh
git commit -m "feat(review): add teach-review skill and slash command"
````

---

### Task 4: Teach-review miss gate + orchestrator wiring

**Files:**
- Modify: `skills/hitl-choice/SKILL.md` (When to Use + new preset after Review-learn promote)
- Modify: `agents/csp-engineer-reviewer.md` (after capture learnings; before pipeline docs handoff)
- Modify: `skills/engineer-review/SKILL.md` (same spine point)
- Modify: `agents/csp-pr-reviewer.md` and `skills/pr-review/SKILL.md` (after settled report / `csp-review-learn`)
- Modify: `scripts/tests/teach-review-contract-test.sh`

**Interfaces:**
- HITL ids: `miss` | `no_miss` (canonical tokens)
- `no_miss` → do not invoke `teach-review`
- `miss` → free-text description if not already in the message, then skill `teach-review`
- Orchestrators never edit kit git

- [ ] **Step 1: Extend the contract test** (will fail until wiring exists)

Append greps to `scripts/tests/teach-review-contract-test.sh` before `ALL PASS`:

````bash
assert_grep hitl_heading "skills/hitl-choice/SKILL.md" "### Teach-review miss"
assert_grep token_miss "skills/hitl-choice/SKILL.md" '`miss`'
assert_grep token_no_miss "skills/hitl-choice/SKILL.md" '`no_miss`'
assert_grep er_agent_gate "agents/csp-engineer-reviewer.md" "Teach-review miss"
assert_grep er_skill_gate "skills/engineer-review/SKILL.md" "Teach-review miss"
assert_grep pr_agent_gate "agents/csp-pr-reviewer.md" "Teach-review miss"
assert_grep pr_skill_gate "skills/pr-review/SKILL.md" "Teach-review miss"
assert_grep er_no_kit_git "agents/csp-engineer-reviewer.md" "never edit kit git"
assert_grep pr_invoke "agents/csp-pr-reviewer.md" "teach-review"
````

- [ ] **Step 2: Run test to verify it fails**

Run: `bash scripts/tests/teach-review-contract-test.sh`

Expected: FAIL `Teach-review miss` not in `hitl-choice` / orchestrators.

- [ ] **Step 3: Wire the gate**

In `skills/hitl-choice/SKILL.md` frontmatter `description` When-to-use list, add **Teach-review miss**. In **When to Use** bullet, add `miss` / `no_miss`.

Insert this preset **immediately after** `### Review-learn promote` (before `### Pipeline route`):

````markdown
### Teach-review miss

Ask **after** a validated `csp-engineer-reviewer` or `csp-pr-reviewer` report is shown (pipeline and manual `/csp-engineer-review` / `/csp-pr-review`). Do not ask on `/csp-teach-review` (the command is already the miss).

| id | label |
|----|-------|
| `miss` | The review missed something I will describe |
| `no_miss` | Nothing to teach; stop |

`no_miss` → do not invoke `teach-review`. `miss` → if this message has no description, wait for free text (open-ended), then invoke skill `teach-review`. Failure of `teach-review` must not retract the report.
````

In `agents/csp-engineer-reviewer.md` spine, after capture learnings (current step 15), insert a new step **before** pipeline docs handoff. Renumber as needed so order is: capture `csp-review-learn` → **Teach-review miss** → `update-docs` when in pipeline.

Add this step text:

````markdown
16. **Teach-review miss:** after the validated report is shown, ask via skill `hitl-choice` preset **Teach-review miss** (`miss` / `no_miss`). `no_miss` → continue. `miss` → collect description (open-ended if needed), invoke skill `teach-review`. **Never edit kit git** in this orchestrator. If `teach-review` fails, keep the report; tell the human to retry with `/csp-teach-review`.
````

Shift the previous docs-handoff step to 17.

In **Hard rules**, keep “Never auto-edit kit checklists from a consumer review” (that still applies to this orchestrator). Add: `Never edit kit git; kit instruction publishes go through skill teach-review.`

In `skills/engineer-review/SKILL.md`, after Capture (`csp-review-learn`), add the same Teach-review miss step; docs handoff stays after it.

In `agents/csp-pr-reviewer.md` / `skills/pr-review/SKILL.md`, after “After the report is settled, run `csp-review-learn`…”, add:

````markdown
11. **Teach-review miss:** ask `hitl-choice` preset **Teach-review miss**. `no_miss` → stop. `miss` → description then skill `teach-review`. Never edit kit git here.
````

(Use the next unused step number in each file.)

- [ ] **Step 4: Run the tests and make sure they pass**

Run: `bash scripts/tests/teach-review-contract-test.sh`

Expected: `ALL PASS`.

- [ ] **Step 5: Commit**

````bash
git add skills/hitl-choice/SKILL.md agents/csp-engineer-reviewer.md skills/engineer-review/SKILL.md agents/csp-pr-reviewer.md skills/pr-review/SKILL.md scripts/tests/teach-review-contract-test.sh
git commit -m "feat(review): always ask teach-review miss after reports"
````

---

### Task 5: Docs + dogfood + README skill row

**Files:**
- Modify: `README.md` (Skills table + capture-escape adjacent usage blurb)
- Modify: `docs/superpowers/pipeline-flow.md` (post-review note + source-of-truth list)
- Modify: `docs/superpowers/dogfood/engineer-review-checklist.md`
- Modify: `scripts/tests/teach-review-contract-test.sh`
- Modify: `docs/superpowers/pipeline-flow.html` only if it already lists post-review HITL nodes in prose/legend that would otherwise omit this gate — if the HTML is a canvas of the same mermaid, add a one-line note in the same place as `csp-review-learn` / capture-escape if present; otherwise skip HTML.

**Interfaces:**
- None (documentation)

- [ ] **Step 1: Extend contract greps**

````bash
assert_grep readme_skill "README.md" "teach-review"
assert_grep readme_cmd "README.md" "/csp-teach-review"
assert_grep flow_teach "docs/superpowers/pipeline-flow.md" "teach-review"
assert_grep dogfood_miss "docs/superpowers/dogfood/engineer-review-checklist.md" "Teach-review miss"
````

- [ ] **Step 2: Run test to verify it fails**

Run: `bash scripts/tests/teach-review-contract-test.sh`

Expected: FAIL README / pipeline-flow / dogfood greps.

- [ ] **Step 3: Write the docs**

README Skills table, add after `pr-review` (or near `engineer-review`):

````markdown
| [`teach-review`](skills/teach-review/) | After a review miss: generalize into kit instructions, `learn/…` branch, land via `cursor-spells-learn.json` (`draft_merge` / `auto_push`) |
````

README usage near `/csp-capture-escape`:

````markdown
`/csp-teach-review [what slipped]` writes generalized **kit** instructions (not `.cursor/review-learnings.md`). After every settled engineer/PR review the orchestrator asks `miss` / `no_miss`. Land config: `~/.cursor/cursor-spells-learn.json` and `<project>/.cursor/cursor-spells-learn.json` (created on `csp install` if missing).
````

In `docs/superpowers/pipeline-flow.md` legend/source-of-truth sentence that lists skills, add `teach-review`. After the review layer description, add:

````markdown
After a validated engineer-review report, HITL **Teach-review miss** (`miss` / `no_miss`). `miss` invokes skill `teach-review` (kit `learn/…` branch; does not merge to `main`).
````

Dogfood table row:

````markdown
| Validated report shown | HITL **Teach-review miss**; `no_miss` does not touch kit git; `miss` + description runs `teach-review` |
````

- [ ] **Step 4: Run the tests and make sure they pass**

Run:

````bash
bash scripts/tests/teach-review-test.sh
bash scripts/tests/teach-review-contract-test.sh
````

Expected: both `ALL PASS`.

- [ ] **Step 5: Commit**

````bash
git add README.md docs/superpowers/pipeline-flow.md docs/superpowers/dogfood/engineer-review-checklist.md scripts/tests/teach-review-contract-test.sh
git commit -m "docs(review): document teach-review miss gate and land config"
````

---

## Self-review (spec coverage)

| Spec requirement | Task |
|------------------|------|
| Config catalog + JSONC comments | 2 (template) |
| Resolve project wins / invalid project / default | 1 |
| Install create-once both layers | 2 |
| Skill generalize/route/git/land | 3 |
| Slash command | 3 |
| Always-ask miss gate on engineer + PR review | 4 |
| Orchestrators do not edit kit git | 4 |
| `auto_push` vs `draft_merge` (no local merge) | 1 + 3 |
| README / pipeline-flow / dogfood | 5 |
| Helper tests + contract tests | 1, 2, 4, 5 |
| Do not replace `csp-review-learn` | 3 notes + 4 order (capture still first) |

No third land mode. No consumer ledger writes in this loop. New phase files are **runtime** output of the skill (not this plan’s commits) except the skill/command themselves.
