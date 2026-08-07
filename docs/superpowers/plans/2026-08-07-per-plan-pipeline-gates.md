# Per-Plan Pipeline Gates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace global `.cursor/*-gate` marker files with per-plan `.cursor/gates/<kind>/<slug>` so parallel chats/tickets can run approve-plan, critic, build, finish-plan, and update-docs without foreign-marker clashes.

**Architecture:** A shared bash library (`scripts/pipeline-gates.sh`) owns slug derivation, migrate-on-read from legacy flat files, and write/clear/list. Hooks source the library; skills/commands/rules document equivalent steps and call the same paths. Foreign slugs are never deleted without explicit HITL `force-clear`.

**Tech Stack:** Bash helpers + Cursor skill/command/rule/hook markdown in the cursor-spells kit; consumer-project install via `scripts/install-to-project.sh`.

## Global Constraints

- Layout: `.cursor/gates/{plan-gate,critique-gate,plan-critique-clear,review-gate,docs-gate}/<slug>` only in the **consumer project**.
- Slug: ticket from path/basename (`ACP-\d+` or `[A-Z][A-Z0-9]+-\d+`, prefer basename); else first 12 hex of SHA-256 of normalized relative path; ticket collision → `TICKET-<hash12>`.
- Require `sha256sum` or `shasum`; never invent a weaker slug.
- File line 1 = plan path; optional line 2 = `ticket: <ID>` when slug came from a ticket.
- Legacy migrate-on-read then delete flat file when path matches; never steal another plan's legacy marker.
- Foreign slug: never delete/overwrite without HITL `force-clear <slug|path>`.
- `start-build` checks only **this** plan's slug gates — other slugs' pending must not block.
- Spec: `docs/superpowers/specs/2026-08-07-per-plan-pipeline-gates-design.md`.
- Frequent small commits — one per task.
- Nested fences: use 4-backtick outer fences when embedding ``` inside plan steps.

---

## File Structure

| Path | Responsibility |
|------|----------------|
| `scripts/pipeline-gates.sh` | Slug, migrate, write/clear/list API |
| `scripts/tests/pipeline-gates-test.sh` | Shell tests for the helper (temp dirs) |
| `scripts/install-to-project.sh` | Always refresh `pipeline-gates.sh` into consumer `scripts/` |
| `hooks/pre-build-gate.sh` | Per-slug plan/critique pending nudge |
| `hooks/post-plan-review-gate.sh` | Per-slug review-gate nudge |
| `skills/approve-plan/SKILL.md` | Write/clear per-slug plan + critique gates |
| `skills/start-build/SKILL.md` | Require clear for this slug only |
| `skills/finish-plan/SKILL.md` | `review-gate/<slug>` with plan path line 1 |
| `skills/update-docs/SKILL.md` | `docs-gate/<slug>` with plan path line 1 |
| `skills/hitl-choice/SKILL.md` | Preset `force-clear` |
| `commands/*.md`, `rules/*.mdc`, agents mentioning markers | Path wording |
| `docs/superpowers/pipeline-flow.md` (+ html), `README.md` | Docs |
| `docs/superpowers/dogfood/per-plan-pipeline-gates-checklist.md` | Parallel-chat fixture |

---

### Task 1: `pipeline-gates.sh` helper + shell tests (TDD)

**Files:**
- Create: `scripts/pipeline-gates.sh`
- Create: `scripts/tests/pipeline-gates-test.sh`

**Interfaces:**
- Produces (bash functions, all take project root via `PG_ROOT` env or first arg `$1` as root when documented):
  - `pg_normalize_plan_path <root> <plan_path>` → stdout relative path
  - `pg_slug_for_plan <root> <plan_path> [kind]` → stdout slug (collision-aware when `kind` given)
  - `pg_gate_path <root> <kind> <slug>` → stdout absolute path
  - `pg_migrate_legacy <root> <kind> [plan_path]` → migrates matching legacy; if `plan_path` omitted, migrate all discoverable legacy for that kind when listing
  - `pg_write_gate <root> <kind> <plan_path>` → creates gate file
  - `pg_clear_gate <root> <kind> <plan_path>` → removes only matching slug (exit 0 if already absent)
  - `pg_list_gates <root> <kind>` → lines `slug<TAB>plan_path`
  - `pg_legacy_path <root> <kind>` → stdout legacy flat path for kind
- Kinds: `plan-gate` | `critique-gate` | `plan-critique-clear` | `review-gate` | `docs-gate`
- Legacy map: `plan-gate`→`.cursor/plan-gate.pending`, `critique-gate`→`.cursor/critique-gate.pending`, `plan-critique-clear`→`.cursor/plan-critique.clear`, `review-gate`→`.cursor/review-gate.pending`, `docs-gate`→`.cursor/docs-gate.pending`

- [ ] **Step 1: Write failing tests**

Create `scripts/tests/pipeline-gates-test.sh`:

````bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=../pipeline-gates.sh
source "$ROOT/scripts/pipeline-gates.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP"

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

# Ticket from basename
slug="$(pg_slug_for_plan "$TMP" "docs/superpowers/plans/2026-08-07-acp-2656-foo-plan.md" plan-gate)"
assert_eq ticket_slug "ACP-2656" "$slug"

# Hash fallback (no ticket)
slug2="$(pg_slug_for_plan "$TMP" "docs/plans/feature-x.md" plan-gate)"
[[ "$slug2" =~ ^[0-9a-f]{12}$ ]] || { echo "FAIL hash_slug format: $slug2" >&2; fail=1; }
echo "OK   hash_slug"

# Write + read clear isolation
pg_write_gate "$TMP" critique-gate "docs/plans/2026-acp-2656-a.md"
pg_write_gate "$TMP" critique-gate "docs/plans/2026-acp-2665-b.md"
test -f "$TMP/.cursor/gates/critique-gate/ACP-2656"
test -f "$TMP/.cursor/gates/critique-gate/ACP-2665"
pg_clear_gate "$TMP" critique-gate "docs/plans/2026-acp-2656-a.md"
test ! -f "$TMP/.cursor/gates/critique-gate/ACP-2656"
test -f "$TMP/.cursor/gates/critique-gate/ACP-2665"
echo "OK   clear_does_not_touch_foreign"

# Legacy migrate-on-read
TMP2="$(mktemp -d)"
mkdir -p "$TMP2/.cursor"
printf '%s\n' "docs/plans/legacy-acp-100.md" > "$TMP2/.cursor/critique-gate.pending"
pg_migrate_legacy "$TMP2" critique-gate "docs/plans/legacy-acp-100.md"
test -f "$TMP2/.cursor/gates/critique-gate/ACP-100"
test ! -f "$TMP2/.cursor/critique-gate.pending"
echo "OK   legacy_migrate"
rm -rf "$TMP2"

# Collision: same ticket, different plans
pg_write_gate "$TMP" plan-gate "docs/plans/acp-1-one.md"
slug_b="$(pg_slug_for_plan "$TMP" "docs/plans/acp-1-two.md" plan-gate)"
[[ "$slug_b" == ACP-1-* && "$slug_b" != "ACP-1" ]] || { echo "FAIL collision slug: $slug_b" >&2; fail=1; }
echo "OK   ticket_collision"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
````

- [ ] **Step 2: Run tests — expect FAIL**

```bash
chmod +x scripts/tests/pipeline-gates-test.sh
bash scripts/tests/pipeline-gates-test.sh
```

Expected: FAIL (missing `pipeline-gates.sh` or undefined functions).

- [ ] **Step 3: Implement `scripts/pipeline-gates.sh`**

Implement the functions so the tests pass. Required behaviors:

- Normalize: if plan path starts with `$root/`, strip it; strip leading `./`; collapse duplicate slashes; strip trailing `/`.
- Ticket regex: prefer basename match of `[A-Za-z][A-Za-z0-9]*-[0-9]+` (case-insensitive find, slug uppercased); else search full normalized path; else SHA-256 via `sha256sum` else `shasum -a 256`, take first 12 hex of the hex digest.
- `pg_slug_for_plan` with kind: if candidate ticket slug file exists under that kind and line-1 (normalized) differs from this plan, return `TICKET-<hash12>`.
- `pg_write_gate`: migrate first; mkdir `-p` kind dir; write line-1 plan path (as provided/normalized consistently); if ticket-derived slug without hash suffix, append line-2 `ticket: ID`.
- `pg_clear_gate`: resolve slug for plan (find existing file whose line-1 matches if collision variants exist — scan kind dir); remove only that file; never remove others.
- `pg_migrate_legacy`: map kind→legacy filename; if legacy missing, return 0; if line-1 empty, print warning to stderr and return 0 without delete; if plan_path arg set and equals legacy path, migrate+delete; if plan_path omitted, migrate legacy into its own slug and delete (list-pass).
- `pg_list_gates`: after `pg_migrate_legacy "$root" "$kind"` with no plan_path, print `slug<TAB>line1` for each file in the kind dir.

Keep the script `set -euo pipefail` safe when sourced (use functions only; no exit on source). Executable bit optional for a sourced library; still `chmod +x` for consistency.

- [ ] **Step 4: Run tests — expect PASS**

```bash
bash scripts/tests/pipeline-gates-test.sh
```

Expected: `ALL PASS`.

- [ ] **Step 5: Commit**

```bash
git add scripts/pipeline-gates.sh scripts/tests/pipeline-gates-test.sh
git commit -m "feat(gates): add per-plan pipeline-gates helper and tests"
```

---

### Task 2: Install helper into consumer projects

**Files:**
- Modify: `scripts/install-to-project.sh` (project scripts section ~279–285)
- Modify: `README.md` (What install creates / Runtime markers — brief mention OK; full markers table can wait for Task 7)

- [ ] **Step 1: Always refresh `pipeline-gates.sh`**

After the `validate-review-report.sh` copy block, add:

```bash
  cp "$KIT_ROOT/scripts/pipeline-gates.sh" "$PROJECT/scripts/pipeline-gates.sh"
  chmod +x "$PROJECT/scripts/pipeline-gates.sh"
  echo "copied: $PROJECT/scripts/pipeline-gates.sh"
```

- [ ] **Step 2: README one-liner**

In the install table or scripts list, note that `scripts/pipeline-gates.sh` is always refreshed (per-plan gate helper).

- [ ] **Step 3: Commit**

```bash
git add scripts/install-to-project.sh README.md
git commit -m "feat(install): refresh pipeline-gates.sh into consumer projects"
```

---

### Task 3: Update `pre-build-gate.sh`

**Files:**
- Modify: `hooks/pre-build-gate.sh`

**Interfaces:**
- Consumes: `pipeline-gates.sh` from `$root/scripts/pipeline-gates.sh` if present, else from kit-relative path next to the hook when running inside the kit dogfood (prefer consumer path).
- Plan path discovery (best-effort): jq fields `.plan_path`, `.plan`, or first line of env `CURSOR_PLAN_PATH` if set; otherwise unknown.

- [ ] **Step 1: Rewrite hook logic**

Replace single-file checks with:

1. `root` detection unchanged.
2. `source "$root/scripts/pipeline-gates.sh"` when file exists; if missing, fall back to message telling user to `csp update` (still exit 0 with followup).
3. Call `pg_migrate_legacy` for `plan-gate` and `critique-gate` (no plan_path → list-pass migrate).
4. If plan path known: compute slug; if `pg_gate_path` file exists for `plan-gate` or `critique-gate`, emit followup naming that kind + plan path (same tone as today).
5. If plan path unknown: `pg_list_gates` both kinds; if any rows, followup listing them ("Open plan-gate: …; Open critique-gate: …. Resolve in the owning chat; do not delete foreign slugs.").
6. If none open: `{}` exit 0.
7. Keep aborted/error short-circuit.

- [ ] **Step 2: Smoke test with temp root**

```bash
TMP=$(mktemp -d)
mkdir -p "$TMP/scripts" "$TMP/.cursor/gates/critique-gate"
cp scripts/pipeline-gates.sh "$TMP/scripts/"
printf '%s\n' 'docs/plans/acp-9.md' > "$TMP/.cursor/gates/critique-gate/ACP-9"
# Simulate unknown plan path — should list ACP-9
printf '{}' | env -i PATH="$PATH" bash -c "cd '$TMP' && bash hooks/pre-build-gate.sh" 
# Expect followup_message containing ACP-9 or docs/plans/acp-9.md
rm -rf "$TMP"
```

(Adjust invocation if the hook must live under `$TMP/.cursor/hooks/` — copy hook into TMP and run from TMP as cwd.)

- [ ] **Step 3: Commit**

```bash
git add hooks/pre-build-gate.sh
git commit -m "feat(hooks): per-slug pre-build critique/plan gates"
```

---

### Task 4: Update `post-plan-review-gate.sh`

**Files:**
- Modify: `hooks/post-plan-review-gate.sh`

- [ ] **Step 1: Per-slug review-gate**

Mirror Task 3 patterns for kind `review-gate` only:

- Source helper; migrate legacy `review-gate.pending`.
- Known plan path → nudge only that slug.
- Unknown → list open `review-gate/*`.
- Preserve "honor skip/approve/done already in chat; do not re-ask forever" wording, updated to mention `.cursor/gates/review-gate/<slug>`.

- [ ] **Step 2: Commit**

```bash
git add hooks/post-plan-review-gate.sh
git commit -m "feat(hooks): per-slug post-plan review-gate"
```

---

### Task 5: Skills — approve-plan + start-build

**Files:**
- Modify: `skills/approve-plan/SKILL.md`
- Modify: `skills/start-build/SKILL.md`
- Modify: `commands/approve-plan.md`
- Modify: `commands/start-build.md`
- Modify: `commands/start-issue-task.md` (critique markers)
- Modify: `rules/before-build-critique-gate.mdc`

- [ ] **Step 1: Rewrite marker bash in `approve-plan`**

Replace flat paths with helper-equivalent steps:

```bash
# Prefer:
#   source scripts/pipeline-gates.sh   # consumer project
#   pg_write_gate "$(pwd)" plan-gate "<plan-path>"
# On approve-plan:
#   pg_clear_gate "$(pwd)" plan-gate "<plan-path>"
#   pg_write_gate "$(pwd)" critique-gate "<plan-path>"
# On Verdict clear:
#   pg_clear_gate "$(pwd)" critique-gate "<plan-path>"
#   pg_write_gate "$(pwd)" plan-critique-clear "<plan-path>"
# On revise: pg_write_gate plan-gate; pg_clear_gate plan-critique-clear
```

Document foreign-slug rule + `force-clear` HITL via `hitl-choice`.

- [ ] **Step 2: Rewrite `start-build`**

- Resolve plan path (argument, else from `pg_list_gates plan-critique-clear` if exactly one, else recent plans).
- Require `plan-critique-clear/<slug>` line-1 == plan.
- Stop only if **this slug** has `plan-gate` or `critique-gate`.
- Explicitly: other slugs' pending gates do **not** block.

- [ ] **Step 3: Align commands + before-build rule**

Same path vocabulary; rule item 4 becomes "Do not dispatch Task 1 while **this plan's** `plan-gate/<slug>` or `critique-gate/<slug>` exists."

- [ ] **Step 4: Commit**

```bash
git add skills/approve-plan/SKILL.md skills/start-build/SKILL.md \
  commands/approve-plan.md commands/start-build.md commands/start-issue-task.md \
  rules/before-build-critique-gate.mdc
git commit -m "feat(skills): approve-plan and start-build use per-plan gates"
```

---

### Task 6: Skills — finish-plan + update-docs + hitl force-clear

**Files:**
- Modify: `skills/finish-plan/SKILL.md`
- Modify: `skills/update-docs/SKILL.md`
- Modify: `skills/hitl-choice/SKILL.md`
- Modify: `commands/finish-plan.md`
- Modify: `commands/update-docs.md`
- Modify: `rules/after-plan-review-gate.mdc`
- Modify: agents that mention `review-gate.pending` / `docs-gate.pending` / `plan-critique.clear` (`agents/software-developer.md`, `agents/bug-fixer.md`, `agents/engineer-reviewer.md` as needed)

- [ ] **Step 1: finish-plan / update-docs write plan path**

Both currently write a bare `pending` line. Change to:

1. Resolve plan path (argument, plan referenced in session, or ask).
2. `pg_write_gate … review-gate|docs-gate "<plan-path>"` (line 1 = plan path, not the word `pending`).
3. Clear with `pg_clear_gate` for that plan only.

- [ ] **Step 2: hitl-choice preset Force-clear foreign gate**

```markdown
### Force-clear foreign gate

| id | label |
|----|-------|
| `force-clear` | Clear the named foreign gate slug/path |
| `leave` | Leave foreign gate untouched |

Ask only when the human explicitly wants to remove another chat's gate. Option prompt must include the slug and plan path. Ids: `force-clear` requires a follow-up slug or path if not already in the prompt context; `leave` aborts.
```

Also add `force-clear` to When to Use examples.

- [ ] **Step 3: Rules + agents wording**

Update legacy paths to `.cursor/gates/...` language.

- [ ] **Step 4: Commit**

```bash
git add skills/finish-plan/SKILL.md skills/update-docs/SKILL.md skills/hitl-choice/SKILL.md \
  commands/finish-plan.md commands/update-docs.md rules/after-plan-review-gate.mdc \
  agents/software-developer.md agents/bug-fixer.md agents/engineer-reviewer.md
git commit -m "feat(skills): per-plan review/docs gates and force-clear HITL"
```

---

### Task 7: Pipeline docs + README markers table

**Files:**
- Modify: `docs/superpowers/pipeline-flow.md` (marker state machine + tables)
- Modify: `docs/superpowers/pipeline-flow.html` (marker strings in relevant cards)
- Modify: `README.md` Runtime markers paragraph/table

- [ ] **Step 1: Replace flat marker paths** with `.cursor/gates/<kind>/<slug>` and note parallel tickets.

- [ ] **Step 2: Commit**

```bash
git add docs/superpowers/pipeline-flow.md docs/superpowers/pipeline-flow.html README.md
git commit -m "docs: document per-plan pipeline gate paths"
```

---

### Task 8: Dogfood checklist

**Files:**
- Create: `docs/superpowers/dogfood/per-plan-pipeline-gates-checklist.md`

- [ ] **Step 1: Write fixture**

Scenarios:

1. **Parallel critique:** Create two fake plan paths `…/acp-2656-….md` and `…/acp-2665-….md`; `pg_write_gate` critique for both; confirm `start-build` rules would allow clearing/building 2656 while 2665 pending remains.
2. **Legacy migrate:** Write legacy `.cursor/critique-gate.pending` with one plan; run migrate; legacy gone; per-plan present.
3. **Foreign clear refused:** Document that agent must HITL `force-clear` before removing the other slug.
4. Cleanup: `rm -rf .cursor/gates` and any leftover legacy files from the fixture.

- [ ] **Step 2: Commit**

```bash
git add docs/superpowers/dogfood/per-plan-pipeline-gates-checklist.md
git commit -m "test(dogfood): per-plan pipeline gates parallel-chat checklist"
```

---

### Task 9: Integration verification

**Files:** none new

- [ ] **Step 1: Re-run helper tests**

```bash
bash scripts/tests/pipeline-gates-test.sh
```

Expected: `ALL PASS`.

- [ ] **Step 2: Grep for stale flat-marker instructions in skills/hooks/rules**

```bash
rg -n '\.cursor/(plan-gate\.pending|critique-gate\.pending|plan-critique\.clear|review-gate\.pending|docs-gate\.pending)' \
  skills hooks rules commands agents README.md docs/superpowers/pipeline-flow.md \
  || true
```

Expected: only migrate/legacy mentions or historical design/plan docs — **no** "write this flat file" instructions in skills/hooks/rules/commands/agents. Fix stragglers if any and commit:

```bash
git add -u skills hooks rules commands agents
git commit -m "fix: remove remaining flat pipeline-gate write instructions"
```

(Skip commit if clean.)

---

## Spec coverage (self-review)

| Spec requirement | Task |
|------------------|------|
| Per-kind dirs under `.cursor/gates/` | Task 1 |
| All five kinds | Tasks 1, 5, 6 |
| Ticket / hash / collision slug | Task 1 |
| Migrate-on-read | Tasks 1, 3, 4 |
| Foreign slug hands-off + force-clear | Tasks 5, 6 |
| start-build this-slug only | Task 5 |
| Hooks per-slug / list fallback | Tasks 3, 4 |
| Install helper | Task 2 |
| Docs + dogfood | Tasks 7, 8 |

## Placeholder scan

No TBD steps; helper API, test cases, and file paths are concrete.
