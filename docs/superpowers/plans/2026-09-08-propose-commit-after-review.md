# Propose-commit after engineer-review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Defer every product `git commit` until a settled engineer-review report exists and the human answers `approve-commit` on skill `propose-commit`, then let `create-pr` only push and open the draft pull request.

**Architecture:** Add skill `propose-commit` plus HITL preset `approve-commit` / `revise`, gate kind `commit-approved` in `pipeline-gates.sh`, hard no-commit rules in `software-developer` and `bug-fix`, uncommitted diff visibility in `review-surface`, strip quiet product commits from `create-pr`, and wire full / fast / issue command spines plus pipeline-flow docs. Contract tests lock the phrases and gate kind.

**Tech Stack:** Kit Markdown skills/commands, bash `pipeline-gates.sh`, bash contract tests under `scripts/tests/`.

**Spec:** `docs/superpowers/specs/2026-09-08-propose-commit-after-review-design.md`

## Global Constraints

- Zero product `git commit` until settled engineer-review **and** human `approve-commit`.
- Applies to full, `--fast`, and `/start-issue-task` pipelines.
- No separate engineer-reviewer commit token (`human_only_after_both`).
- `propose-commit` never pushes and never opens a GitHub pull request.
- Full path: `propose-commit` → `update-docs` → optional second `propose-commit` for residual docs → `create-pr`.
- Fast / issue: `propose-commit` after engineer-review → `create-pr`.
- Do not change finish-plan HITL tokens or Pipeline finale tokens.
- Do not create placeholder commits to feed the merge-base tab; show `git status` / `git diff` in chat when ahead-of-base is empty.
- User-facing chat still follows `plain-language-chat` (full words).

## File map

| Path | Responsibility |
|------|----------------|
| `scripts/tests/propose-commit-test.sh` | Contract: skill, tokens, no-commit phrases, create-pr guard, command wiring, flow mentions |
| `scripts/pipeline-gates.sh` | Gate kind `commit-approved` (legacy migrate no-op) |
| `scripts/tests/pipeline-gates-test.sh` | Assert `pg_write_gate` / find / clear for `commit-approved` |
| `skills/propose-commit/SKILL.md` | Propose message+files, HITL, commit, write marker |
| `skills/hitl-choice/SKILL.md` | Preset **Propose commit** |
| `skills/software-developer/SKILL.md` | Forbid `git commit` in pipeline implement |
| `skills/bug-fix/SKILL.md` | Forbid `git commit` in pipeline fix |
| `skills/finish-plan/references/review-surface.md` | Uncommitted diff visibility |
| `scripts/tests/review-surface-test.sh` | Assert uncommitted diff phrases |
| `skills/create-pr/SKILL.md` | No quiet product commit; require clean tree or stop to `propose-commit` |
| `skills/engineer-review/SKILL.md` | After settled pipeline review → `propose-commit` before docs/PR |
| `skills/update-docs/SKILL.md` | After publish, if dirty → residual `propose-commit` |
| `commands/start-task.md` | Full + fast spines insert `propose-commit` |
| `commands/start-issue-task.md` | Insert `propose-commit` before `create-pr` |
| `docs/superpowers/pipeline-flow.md` | Document the new stage |
| `docs/superpowers/pipeline-flow.html` | Mirror the new stage (enough for contract greps) |
| `scripts/tests/pipeline-flow-graph-test.sh` | Assert `propose-commit` appears in flow docs |
| `README.md` | One-line mention of commit gate if skills table lists peers |

---

### Task 1: Contract test (RED)

**Files:**
- Create: `scripts/tests/propose-commit-test.sh`
- Modify: `scripts/tests/pipeline-flow-graph-test.sh`
- Test: `scripts/tests/propose-commit-test.sh`, `scripts/tests/pipeline-flow-graph-test.sh`

**Interfaces:**
- Consumes: paths listed in File map (must exist with greppable phrases after later tasks)
- Produces: failing contract until Tasks 2–8 land

- [ ] **Step 1: Write the failing contract test**

Create `scripts/tests/propose-commit-test.sh`:

```bash
#!/usr/bin/env bash
# Contract: product commits only after propose-commit + approve-commit.
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
  if grep -E -q "$pattern" "$ROOT/$path" 2>/dev/null; then
    echo "OK   $name"
  else
    echo "FAIL $name: /$pattern/ not in $path" >&2
    fail=1
  fi
}

assert_no_grep() {
  local name="$1" path="$2" pattern="$3"
  if grep -E -q "$pattern" "$ROOT/$path" 2>/dev/null; then
    echo "FAIL $name: /$pattern/ unexpectedly in $path" >&2
    fail=1
  else
    echo "OK   $name"
  fi
}

assert_file "skills/propose-commit/SKILL.md"
assert_file "skills/hitl-choice/SKILL.md"
assert_file "skills/software-developer/SKILL.md"
assert_file "skills/bug-fix/SKILL.md"
assert_file "skills/create-pr/SKILL.md"
assert_file "skills/engineer-review/SKILL.md"
assert_file "skills/update-docs/SKILL.md"
assert_file "commands/start-task.md"
assert_file "commands/start-issue-task.md"
assert_file "skills/finish-plan/references/review-surface.md"
assert_file "scripts/pipeline-gates.sh"

assert_grep skill_name "skills/propose-commit/SKILL.md" "^name: propose-commit$"
assert_grep skill_approve "skills/propose-commit/SKILL.md" "approve-commit"
assert_grep skill_revise "skills/propose-commit/SKILL.md" "revise"
assert_grep skill_marker "skills/propose-commit/SKILL.md" "commit-approved"
assert_grep skill_no_push "skills/propose-commit/SKILL.md" "Do not.*git push|never.*git push|Do \\*\\*not\\*\\* \`git push\`"
assert_grep skill_no_pr "skills/propose-commit/SKILL.md" "pull request"
assert_grep skill_review_pre "skills/propose-commit/SKILL.md" "engineer-review"
assert_grep skill_no_add_all "skills/propose-commit/SKILL.md" "git add -A|git add \\."

assert_grep hitl_preset "skills/hitl-choice/SKILL.md" "Propose commit"
assert_grep hitl_token "skills/hitl-choice/SKILL.md" "approve-commit"

assert_grep sd_no_commit "skills/software-developer/SKILL.md" "Never.*git commit|do not.*git commit|no product commit|forbid.*git commit"
assert_grep bf_no_commit "skills/bug-fix/SKILL.md" "Never.*git commit|do not.*git commit|no product commit|forbid.*git commit"

assert_grep create_pr_guard "skills/create-pr/SKILL.md" "propose-commit|commit-approved"
assert_grep create_pr_no_quiet "skills/create-pr/SKILL.md" "must not silently commit|do not silently commit|Never silently commit|quiet product commit"

assert_grep er_handoff "skills/engineer-review/SKILL.md" "propose-commit"
assert_grep docs_residual "skills/update-docs/SKILL.md" "propose-commit"
assert_grep start_full "commands/start-task.md" "propose-commit"
assert_grep start_fast "commands/start-task.md" "propose-commit"
assert_grep start_issue "commands/start-issue-task.md" "propose-commit"

assert_grep surface_uncommitted "skills/finish-plan/references/review-surface.md" "git status|git diff|uncommitted"
assert_grep gates_kind "scripts/pipeline-gates.sh" "commit-approved"

assert_grep flow_md "docs/superpowers/pipeline-flow.md" "propose-commit"
assert_grep flow_html "docs/superpowers/pipeline-flow.html" "propose-commit"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
```

Make executable: `chmod +x scripts/tests/propose-commit-test.sh`

Append to `scripts/tests/pipeline-flow-graph-test.sh` before the final `fail` check:

```bash
assert_contains md_propose_commit "$MD" "propose-commit"
assert_contains html_propose_commit "$HTML" "propose-commit"
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
bash scripts/tests/propose-commit-test.sh
bash scripts/tests/pipeline-flow-graph-test.sh
```

Expected: `propose-commit-test.sh` exits non-zero (missing skill / greps). `pipeline-flow-graph-test.sh` fails on new `propose-commit` needles (unless already present — must fail until flow docs updated).

- [ ] **Step 3: Commit**

```bash
git add scripts/tests/propose-commit-test.sh scripts/tests/pipeline-flow-graph-test.sh
git commit -m "test: RED contract for propose-commit gate"
```

---

### Task 2: Gate kind `commit-approved`

**Files:**
- Modify: `scripts/pipeline-gates.sh` (`pg_legacy_path` case)
- Modify: `scripts/tests/pipeline-gates-test.sh`
- Test: `scripts/tests/pipeline-gates-test.sh`

**Interfaces:**
- Consumes: existing `pg_write_gate` / `pg_clear_gate` / `pg__find_gate_for_plan`
- Produces: `commit-approved` usable as `kind` without migrate error

- [ ] **Step 1: Extend the RED assertion in pipeline-gates-test**

At the end of `scripts/tests/pipeline-gates-test.sh` (before final success), add:

```bash
# commit-approved kind (no legacy file required)
pg_write_gate "$TMP" commit-approved "docs/plans/2026-propose-commit.md"
CA_FILE="$(pg__find_gate_for_plan "$TMP" commit-approved "docs/plans/2026-propose-commit.md")"
if [[ -f "$CA_FILE" ]]; then
  echo "OK   commit-approved gate written"
else
  echo "FAIL commit-approved gate missing" >&2
  exit 1
fi
pg_clear_gate "$TMP" commit-approved "docs/plans/2026-propose-commit.md"
if pg__find_gate_for_plan "$TMP" commit-approved "docs/plans/2026-propose-commit.md" >/dev/null; then
  echo "FAIL commit-approved gate still present after clear" >&2
  exit 1
fi
echo "OK   commit-approved gate cleared"
```

- [ ] **Step 2: Run to verify fail/error on unknown kind**

Run: `bash scripts/tests/pipeline-gates-test.sh`  
Expected: failure or stderr `unknown kind: commit-approved` until Step 3.

- [ ] **Step 3: Add kind to `pg_legacy_path`**

In `scripts/pipeline-gates.sh`, inside the `case "$kind" in` of `pg_legacy_path`, add (never created historically — migrate no-ops):

```bash
    commit-approved) printf '%s/.cursor/commit-approved.pending' "$root" ;;
```

Keep existing kinds unchanged. Place before the `*)` unknown branch.

- [ ] **Step 4: Run test to verify pass**

Run: `bash scripts/tests/pipeline-gates-test.sh`  
Expected: ends with success / existing `ALL PASS` or script’s success path; new commit-approved OK lines print.

- [ ] **Step 5: Commit**

```bash
git add scripts/pipeline-gates.sh scripts/tests/pipeline-gates-test.sh
git commit -m "feat(gates): add commit-approved gate kind"
```

---

### Task 3: Skill `propose-commit`

**Files:**
- Create: `skills/propose-commit/SKILL.md`
- Test: `scripts/tests/propose-commit-test.sh` (partial greps will still fail until later tasks)

**Interfaces:**
- Consumes: `hitl-choice` preset **Propose commit**; `pg_write_gate` kind `commit-approved`; handoff `repo_branch_map` + `plan_path`
- Produces: commits on feature branches; `.cursor/gates/commit-approved/<slug>`

- [ ] **Step 1: Create `skills/propose-commit/SKILL.md`**

```markdown
---
name: propose-commit
description: >-
  Use after a settled engineer-review report in a kit pipeline (full, --fast,
  or issue) when product changes are still uncommitted. Proposes commit message
  and file list, HITL approve-commit / revise, then git commit only. Never push
  or open a pull request — create-pr owns that. Also use after update-docs when
  residual docs files remain uncommitted.
---

# Propose Commit

Human-gated product commit after engineer-review. Implements the design in
`docs/superpowers/specs/2026-09-08-propose-commit-after-review-design.md`.

## When to Use

- After engineer-review (or multi-repo-supervisor) has produced a **settled** report for this pipeline run
- Again on the full path after `update-docs` if intentional files remain uncommitted
- Not from `finish-plan` review-surface
- Not as a substitute for Pipeline finale
- Not for kit self-edits outside a consumer product pipeline unless the human is running this skill on purpose

## Preconditions

All required:

1. Each target repo is on the **feature branch** (not `main` / `master` / default).
2. An engineer-review report for **this run** is settled (no blocking open clarifications that the pipeline treats as not ready to continue).
3. `repo → branch` map from the handoff, or a resolvable current feature branch.
4. `plan_path` when known (implementation plan or issue fix plan). If the handoff has `plan_path: none` (fast brief only), use synthetic path `runs/<feature-branch-name>` as the plan path argument to gate helpers.

If any fail: **stop** and say which precondition is missing. Do not commit.

## Spine

1. For each `repo → branch` in the map (or the single current repo):
   - `git -C <repo> status` / `git diff` / `git diff --cached`
   - Build the intentional file list. **Never** `git add -A` or `git add .`.
2. Propose in chat (full words per `plain-language-chat`):
   - Commit message (match recent conventional style in that repo; default `fix:` when ambiguous for bug work, `feat:` only for new capability)
   - Per-repo file list to stage
3. HITL via skill **`hitl-choice`** (AskQuestion required; text only after failed/missing tool). Preset: **Propose commit**.
   - `revise` — wait for message and/or file-list changes; re-propose; do **not** commit.
   - `approve-commit` — continue.
4. On `approve-commit`, per repo with changes:
   - Stage only the listed paths
   - `git commit` with the approved message
   - Confirm not on default branch before committing
5. Write the gate in the **current project** (consumer root):

   ```bash
   source scripts/pipeline-gates.sh   # consumer copy or kit path
   pg_write_gate "$(pwd)" commit-approved "<plan-path-or-runs-branch>"
   ```

6. **Do not** `git push`. **Do not** open or update a GitHub pull request. Hand off to the caller (`update-docs` or `create-pr`).

## Multi-repo

One human gate may cover the whole proposal set for the run. Skip repos with a clean work tree. Do not push any repo.

## Hard rules

- Never commit without a settled engineer-review report for this run **and** `approve-commit`.
- Never push. Never `gh pr create` / `gh pr ready`. Never merge.
- Never commit on the default branch.
- Never `git add -A` / `git add .`.
- Nested implementers must not have already committed; if the branch is unexpectedly ahead with no `commit-approved` marker, stop and ask — do not invent history rewrites.

## Output

```
next_skill: update-docs | create-pr   # per caller wiring
plan_path: <path>
repo_branch_map:
  - <repo> → <branch>
commit_approved: true
```
```

- [ ] **Step 2: Sanity grep**

Run: `grep -E 'approve-commit|commit-approved|git push' skills/propose-commit/SKILL.md`  
Expected: matches present.

- [ ] **Step 3: Commit**

```bash
git add skills/propose-commit/SKILL.md
git commit -m "feat(skills): add propose-commit gate skill"
```

---

### Task 4: HITL preset + implementer forbids

**Files:**
- Modify: `skills/hitl-choice/SKILL.md`
- Modify: `skills/software-developer/SKILL.md`
- Modify: `skills/bug-fix/SKILL.md`
- Test: greps in `scripts/tests/propose-commit-test.sh`

**Interfaces:**
- Consumes: Task 3 skill tokens
- Produces: preset **Propose commit**; hard no-commit in implementers

- [ ] **Step 1: Add preset to `hitl-choice`**

In `skills/hitl-choice/SKILL.md`:

1. Add `approve-commit` to the When to Use / description list of gates (near Pipeline finale).
2. Insert a new subsection **before** `### Pipeline finale`:

```markdown
### Propose commit

Ask from skill `propose-commit` after a settled engineer-review report (and again after `update-docs` when residual files remain). Never ask before engineer-review. Never treat this as Pipeline finale.

| id | label |
|----|-------|
| `approve-commit` | Approve commit message and file list |
| `revise` | Revise message or files (describe next) |

On `revise`, wait for free-text changes, then re-propose. On `approve-commit`, the calling skill runs `git commit` only (no push).
```

- [ ] **Step 2: Forbid commits in `software-developer`**

In `skills/software-developer/SKILL.md` **Hard rules**, add:

```markdown
- **Never `git commit`** during pipeline implementation, verification, or handoff. Leave all product changes uncommitted for skill `propose-commit` after engineer-review. Nested task agents inherit this forbid. Branch creation/checkout only — no implementation commits on any branch until `approve-commit`
```

Keep the existing “Do not write implementation commits on `main` / `master` / the default branch” line (still true; broader forbid supersedes feature-branch commits too).

- [ ] **Step 3: Forbid commits in `bug-fix`**

In `skills/bug-fix/SKILL.md`, under hard rules or a clear **Hard rules** section, add:

```markdown
- **Never `git commit`** during pipeline fix work. Leave changes uncommitted for skill `propose-commit` after engineer-review. Nested `bug-fixer` / task agents inherit this forbid
```

Keep existing anti-pattern text about stacking likely fixes across commits (still valid as a debugging rule; pipeline simply never commits until the gate).

- [ ] **Step 4: Commit**

```bash
git add skills/hitl-choice/SKILL.md skills/software-developer/SKILL.md skills/bug-fix/SKILL.md
git commit -m "feat(pipeline): HITL approve-commit and no-commit implementers"
```

---

### Task 5: Review-surface uncommitted visibility

**Files:**
- Modify: `skills/finish-plan/references/review-surface.md`
- Modify: `scripts/tests/review-surface-test.sh`
- Test: `scripts/tests/review-surface-test.sh`

**Interfaces:**
- Consumes: spec rule “Diff visibility before any commit”
- Produces: chat `git status` / `git diff` when merge-base tab is empty

- [ ] **Step 1: Extend review-surface**

After section **2. Activate the pull request tab** (before **3. Then ask HITL**), add:

```markdown
## 2b. Uncommitted change set (mandatory when ahead is empty)

Product pipelines may have **zero commits** on the feature branch ahead of base until `propose-commit`. The merge-base pull request tab can be empty even when the work tree is full of changes.

For **each** repo in the map, after checkout:

1. Run `git -C <open-folder> status --porcelain` and `git -C <open-folder> diff` (and `git diff --cached` if needed).
2. If `git rev-list --count <base>..<branch>` is `0` **or** the porcelain output is non-empty, paste or summarize in chat: dirty paths + a concise diff summary (cap huge diffs; point to paths).
3. State clearly that the pull request tab may be empty until commits exist; the human is reviewing the **working tree**.
4. **Do not** create a placeholder commit to feed the tab.

Keep attempting `SetActiveBranch` (step 2) for checkout visibility.
```

Also update the intro paragraph that implies the human only looks at the merge-base diff — mention working-tree / chat diff when uncommitted.

Update the later pipeline sentence: after engineer-review comes `propose-commit`, then `update-docs`, then `create-pr` (not “then update-docs then create-pr” alone).

- [ ] **Step 2: Extend `review-surface-test.sh`**

Add:

```bash
assert_grep surface_uncommitted "skills/finish-plan/references/review-surface.md" "git status|uncommitted|working tree"
assert_grep surface_no_placeholder "skills/finish-plan/references/review-surface.md" "placeholder commit|Do not.*placeholder"
assert_grep surface_propose "skills/finish-plan/references/review-surface.md" "propose-commit"
```

- [ ] **Step 3: Run test**

Run: `bash scripts/tests/review-surface-test.sh`  
Expected: `ALL PASS`

- [ ] **Step 4: Commit**

```bash
git add skills/finish-plan/references/review-surface.md scripts/tests/review-surface-test.sh
git commit -m "feat(review-surface): show uncommitted diff before commit gate"
```

---

### Task 6: Guard `create-pr`

**Files:**
- Modify: `skills/create-pr/SKILL.md`
- Test: greps via `scripts/tests/propose-commit-test.sh`

**Interfaces:**
- Consumes: `commit-approved` marker and/or already-committed clean tree from `propose-commit`
- Produces: push + draft only; no quiet product commit

- [ ] **Step 1: Rewrite built-in commit step**

In `skills/create-pr/SKILL.md` **Spine** step 4 (built-in path), replace the bullet that says to commit if there are staged/uncommitted changes with:

```markdown
   - Inspect `git status` / `git diff`.
   - If the work tree is **dirty** with intentional product/docs changes: **stop**. Tell the human to run skill `propose-commit` (requires settled engineer-review + `approve-commit`). Do **not** silently commit. Do **not** invent a commit message here.
   - If the work tree is clean and the feature branch is ahead of base: continue to push (commits must already exist from `propose-commit`).
   - If `ce-commit-push-pr` is installed: it must **not** create product commits without `approve-commit` / `commit-approved` for this run. Prefer built-in push+PR when the third-party skill would quiet-commit; otherwise stop and report.
```

In **Hard rules**, add:

```markdown
- Never silently commit ungated product changes. Dirty tree → stop and point at `propose-commit` / `commit-approved`.
```

Update the skill description frontmatter similarly: commits happen only via `propose-commit`; this skill pushes and opens the draft.

Keep Pipeline finale and trajectory scoring unchanged.

- [ ] **Step 2: Commit**

```bash
git add skills/create-pr/SKILL.md
git commit -m "fix(create-pr): refuse quiet product commits without propose-commit"
```

---

### Task 7: Wire commands and review/docs handoffs

**Files:**
- Modify: `skills/engineer-review/SKILL.md`
- Modify: `skills/update-docs/SKILL.md`
- Modify: `commands/start-task.md`
- Modify: `commands/start-issue-task.md`
- Test: `scripts/tests/propose-commit-test.sh`

**Interfaces:**
- Consumes: Task 3 skill; full/fast/issue spines from spec
- Produces: correct call order

- [ ] **Step 1: `engineer-review` handoff**

In `skills/engineer-review/SKILL.md`, after the pipeline docs handoff bullet (step 15 / “Pipeline docs handoff via `update-docs`…”), change to:

```markdown
15. After a successful **pipeline** review (from `/start-task` / `finish-plan` / `/start-task --fast` / `/start-issue-task`), once the report is settled and teach-review-miss is handled: invoke skill **`propose-commit`** next. Then:
    - Full path: `update-docs` (existing destination HITL), then if the tree is still dirty invoke **`propose-commit`** again for residual docs, then `create-pr`.
    - Fast / issue: `create-pr` (no `update-docs` unless the human asked).
    Manual `/engineer-review` does **not** auto-start `propose-commit` or `update-docs` unless the human asks.
```

Adjust any earlier sentence that says update-docs runs immediately after review without `propose-commit`.

- [ ] **Step 2: `update-docs` residual**

In `skills/update-docs/SKILL.md` Notes or end of publish step, add:

```markdown
- After publish on the **full** `/start-task` path: if intentional files remain uncommitted in the product repo, the caller must run skill **`propose-commit`** again before `create-pr`. This skill must not `git commit` those files to bypass the gate (leave files on disk; report paths).
```

Remove or soften any line that says “Stage/commit only if the human's workflow…” into: leave uncommitted for `propose-commit`; do not bypass the gate.

- [ ] **Step 3: `commands/start-task.md` full mode**

Between step 7 (Engineer review) and step 8 (Update docs), insert:

```markdown
7b. **Propose commit** (automatic after review settles): invoke skill **`propose-commit`** (HITL `approve-commit` / `revise`). Zero product commits before this step.
```

Renumber or keep 8/9 but change Create PR text to: push + draft only (commits already done; if dirty after docs, run `propose-commit` again first).

Update step 8/9:

```markdown
8. **Update docs** …
9. **Propose commit (residual)** — if `update-docs` left uncommitted intentional files, invoke **`propose-commit`** again.
10. **Create PR** — invoke skill **`create-pr`** (push + draft + Pipeline finale). Do not expect `create-pr` to invent product commits.
```

- [ ] **Step 4: Fast mode in `start-task.md`**

After engineer review in fast mode, before Create PR:

```markdown
5b. **Propose commit** — invoke skill **`propose-commit`**.
6. **Create PR** — …
```

- [ ] **Step 5: `commands/start-issue-task.md`**

After step 6 engineer review, before create-pr:

```markdown
6b. **Propose commit** — invoke skill **`propose-commit`** (HITL `approve-commit` / `revise`).
7. **Create PR** — …
```

- [ ] **Step 6: Commit**

```bash
git add skills/engineer-review/SKILL.md skills/update-docs/SKILL.md commands/start-task.md commands/start-issue-task.md
git commit -m "feat(pipeline): wire propose-commit into full fast and issue"
```

---

### Task 8: Pipeline flow docs + GREEN contract

**Files:**
- Modify: `docs/superpowers/pipeline-flow.md`
- Modify: `docs/superpowers/pipeline-flow.html`
- Modify: `README.md` (only if it lists create-pr / finish-plan peers — add one `propose-commit` mention)
- Test: `scripts/tests/propose-commit-test.sh`, `scripts/tests/pipeline-flow-graph-test.sh`

**Interfaces:**
- Consumes: wiring from Task 7
- Produces: greppable `propose-commit` in flow docs; all contracts green

- [ ] **Step 1: Update `pipeline-flow.md`**

In the Review / Docs / PR sections:

1. Add `propose-commit` to the source-of-truth skill list.
2. In the full-path sequence diagram / Build→Review→Docs chain, insert `propose-commit` after engineer-review and before `update-docs`; note residual `propose-commit` after docs; then `create-pr`.
3. In fast and issue sections, insert `propose-commit` between engineer-review and `create-pr`.
4. Document gate `.cursor/gates/commit-approved/<slug>` in the markers table.
5. Note uncommitted review-surface chat diff when ahead-of-base is 0.

Keep existing review-gate behavior intact.

- [ ] **Step 2: Update `pipeline-flow.html`**

Add visible label or view text containing the exact string `propose-commit` in the review/finale area (mirror the markdown story enough for `pipeline-flow-graph-test.sh` and `propose-commit-test.sh` greps). Do not remove existing `review-gate` / `SetActiveBranch` strings the graph test requires.

- [ ] **Step 3: README**

If `README.md` documents pipeline skills in a table/list, add one row/line for `propose-commit` (commit only after engineer-review + `approve-commit`). If there is no such list, skip.

- [ ] **Step 4: Run all related contracts**

```bash
bash scripts/tests/propose-commit-test.sh
bash scripts/tests/pipeline-flow-graph-test.sh
bash scripts/tests/pipeline-gates-test.sh
bash scripts/tests/review-surface-test.sh
```

Expected: each prints `ALL PASS` (or pipeline-gates success equivalent).

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/pipeline-flow.md docs/superpowers/pipeline-flow.html README.md scripts/tests/propose-commit-test.sh
git commit -m "docs(pipeline): document propose-commit; GREEN contracts"
```

---

## Spec coverage (self-review)

| Spec requirement | Task |
|------------------|------|
| After engineer-review, before update-docs / create-pr | 7, 8 |
| Zero commits until gate | 4, 3 |
| All pipelines | 7 |
| `human_only_after_both` | 3, 4 |
| Skill `propose-commit` | 3 |
| HITL `approve-commit` / `revise` | 4 |
| Marker `commit-approved` | 2, 3 |
| No push in propose-commit | 3 |
| create-pr no quiet commit | 6 |
| Docs residual second propose-commit | 7 |
| Uncommitted diff visibility | 5 |
| Out of scope: finish-plan tokens / finale / merge | untouched |
| Contract tests | 1, 8 |

## Placeholder scan

No TBD / “implement later” / “similar to Task N” left in steps.

## Type consistency

Gate kind string is always `commit-approved`. HITL token always `approve-commit`. Skill name always `propose-commit`.
