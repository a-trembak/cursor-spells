# Teach-review pipeline handoff Fix Plan

**Goal:** After Teach-review miss is handled on a kit pipeline review (full / `--fast` / issue), the agent must continue into `propose-commit` (with orientation strip + `approve-commit` / `revise`) instead of ending the turn on the teach-review land report.

**Architecture:** Instruction-only kit fix. `teach-review` is never a pipeline terminal: it always returns to the caller after the land (or failure) report. Skill `hitl-choice` preset **Teach-review miss** and agent `engineer-reviewer` restate the existing engineer-review spine step 15 so the in-chat orchestrator invokes `propose-commit` once. Bare `/teach-review` and Capture-escape do not start `propose-commit`. Prove the wire with positive and negative contract greps.

**Tech Stack:** Kit skill/agent Markdown, bash contract tests (`teach-review-contract-test.sh`, optionally `propose-commit-test.sh`), dogfood checklist row.

## Reported failure

After a validated engineer-review report, human chooses `miss`, paste description, `teach-review` lands kit instructions — then chat goes silent: no “what next”, no orientation strip, no `propose-commit` question.

## Reproduction

1. Run a pipeline review path (`/start-task`, `finish-plan`, `/start-task --fast`, or `/start-issue-task`) through a settled engineer-review report.
2. Answer Teach-review miss with `miss` + a generalizable description.
3. Observe: teach-review success message appears; agent stop; no `propose-commit` HITL and no `pipeline-status` strip in that turn.

Evidence already in-kit (instruction gap, not runtime exception):

| File | Gap |
|------|-----|
| `skills/teach-review/SKILL.md` step 7 | Ends after telling the human about land — reads as turn-complete |
| `skills/hitl-choice/SKILL.md` **Teach-review miss** | Invokes `teach-review` / capture; never says “then continue pipeline to `propose-commit`” |
| `agents/engineer-reviewer.md` hard rules | Documents Teach-review miss only; omits spine step 15 (`propose-commit`) |
| `scripts/tests/teach-review-contract-test.sh` | Asserts miss gate tokens; does not assert post-miss continue or negative auto-commit wires |

Normative continue already exists in `skills/engineer-review/SKILL.md` step 15 and `docs/superpowers/pipeline-flow.md` — agents still stop because leaf instructions are stronger/local.

## Hypothesized root cause

Agents treat `teach-review` as a complete task. The pipeline continue rule lives only on the long engineer-review spine; the agent file and miss preset that the model follows after the miss loop do not restate it. Orientation strip only appears when `hitl-choice` asks the next gate — if `propose-commit` never starts, status never shows.

## Proposed minimal fix

### Continue owner (single)

After miss settles on a **pipeline** review, **only** the in-chat engineer-review orchestrator (skill `engineer-review` step 15 / agent `engineer-reviewer`) invokes skill `propose-commit` once. Parent command steps (`start-task` 7b / `start-issue-task` 6b) remain the same outer wiring; they must not be taught as a second fresh Propose-commit ask in the same turn. `hitl-choice` tells the **calling skill** to continue to that owner — it does not itself open Propose commit. `teach-review` never opens Propose commit.

### File edits

1. **`skills/teach-review/SKILL.md`** — After land or failure report: always return to the caller; this skill is never a pipeline terminal and never invokes `propose-commit` / `update-docs` / `create-pr`. Do **not** add a `source` / pipeline detection flag (Inputs stay description + cwd + kit path). Bare `/teach-review` and Capture-escape still stop meaningfully when the **caller** has nothing further — teach-review itself just returns.
2. **`skills/hitl-choice/SKILL.md`** — Under **Teach-review miss**: after `no_miss`, after `teach-review` returns (success or failure), or after `project_secret` capture settles: the **calling** pipeline review skill must continue to skill `propose-commit` per engineer-review step 15. Manual `/engineer-review` / `/pr-review` do **not** auto-start `propose-commit` unless the human asks. Do not ask Propose commit from inside this miss preset.
3. **`agents/engineer-reviewer.md`** — Hard rule mirroring step 15: after miss handled on pipeline runs → invoke `propose-commit` once, then full-path `update-docs` / residual propose / `create-pr` (or fast/issue `create-pr`) as already documented on the skill spine. Explicit: do not end the turn on the teach land report.
4. **`agents/pr-reviewer.md`** — No change to invent `propose-commit` (PR review stays report-oriented after miss). Optional one line: after miss handling, stop unless the human asks for more (unchanged behavior).
5. **Contract tests** — Extend `scripts/tests/teach-review-contract-test.sh` (and `propose-commit-test.sh` only if a single shared assert fits):
   - **Positive:** hitl-choice Teach-review miss mentions continue → `propose-commit`; engineer-reviewer mentions `propose-commit` after miss / pipeline; teach-review states return-to-caller / never pipeline terminal (or equivalent).
   - **Negative:** `commands/teach-review.md` must not instruct auto-start `propose-commit`; teach-review skill must not contain unconditional `next_skill: propose-commit`; Capture-escape command must not auto-start `propose-commit`.
6. **`docs/superpowers/dogfood/engineer-review-checklist.md`** — One row: after pipeline miss → teach (or `no_miss` / `project_secret`), next user-visible gate is Propose commit with orientation strip (not a silent end).

## Out of scope

- Changing teach-review land/git/worktree behavior
- Adding `source:` caller flags to teach-review Inputs
- Teach-review-miss gate on `multi-repo-supervisor` (supervisor currently has no miss ask; leaving step 9 alone — separate defect if desired later)
- Auto-starting `propose-commit` after bare `/teach-review` or `/capture-escape`
- Changing Pipeline finale or commit gate tokens
- Product-app code
- Live chat trajectory automation beyond dogfood checklist + greps (accept residual: greps can pass while a weak model still stops — mitigated by leaf restatement + dogfood row)

## Regression / blast radius

- **Risk:** Bare `/teach-review` accidentally starts product `propose-commit` → mitigated by negative contracts + single continue owner on engineer-reviewer only.
- **Risk:** Manual `/engineer-review` starts commit gate unwanted → keep “manual does not auto-start” in hitl + agent.
- **Low risk** otherwise: Markdown + grep contracts only.

## Test plan

1. RED: add contract assertions (positive + negative); run `bash scripts/tests/teach-review-contract-test.sh` → fail before edits.
2. Apply instruction edits + dogfood row.
3. GREEN: same script passes; `bash scripts/tests/propose-commit-test.sh` still passes.
4. Dogfood: checklist row documents expected live continue.

## Rejected alternatives

- Conditional `next_skill: propose-commit` inside teach-review based on inferred “pipeline” — needs a detection flag the skill does not have; rejected (critic F1).
- Putting `propose-commit` inside teach-review always — wrong for `/teach-review` and Capture-escape.
- Relying only on engineer-review spine step 15 — already present; still fails without leaf restatement.
- Naming “miss handled” on multi-repo without adding the miss gate — unsafe; out of scope instead.
- Disk gate “teach-handled” — heavier than needed for an instruction dead-end.

## Critic resolutions (this revision)

- **F1 / F3:** Dropped conditional propose-commit from teach-review; always return-to-caller; continue owner = engineer-reviewer + hitl calling-skill text.
- **F2:** Multi-repo miss wiring moved to Out of scope; do not edit multi-repo-supervisor for this fix.
- **F4:** Negative contract asserts added to Test plan / File edits.
- **F5:** Single continue owner section added.
- **F6:** Accept residual live-chat gap; dogfood checklist row is the human-visible lock.

## Tasks

### Task 1: Contract RED

- Extend `scripts/tests/teach-review-contract-test.sh` with positive + negative continue-wire greps.
- Run → expect FAIL.

### Task 2: Instruction wire

- Edit `skills/teach-review/SKILL.md`, `skills/hitl-choice/SKILL.md`, `agents/engineer-reviewer.md`, dogfood checklist.
- Do not edit multi-repo-supervisor; do not change teach-review.sh.

### Task 3: Contract GREEN + verify

- Re-run contract tests; keep evidence.
- Handoff `next_skill: engineer-reviewer`.
