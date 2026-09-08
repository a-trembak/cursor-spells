# Pipeline Orientation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give humans a live “where am I” orientation for the quality pipeline: chat status strip at every human gate, `/pipeline-status` from disk markers + session ledger, and `pipeline-flow.html` highlighting via URL query parameters.

**Architecture:** A bash resolver (`scripts/pipeline-status.sh`) derives an orientation record from `.cursor/gates/*` and optional trajectory session ledgers. Skill + slash command print a status strip and a canvas URL with `?route=&layer=&stage=`. The existing HTML canvas reads those params and applies `done` / `here` / `waiting` styles. No new gate kinds; back-navigation stays informational in v1.

**Tech Stack:** Bash (sourcing `pipeline-gates.sh`), Cursor skill/command markdown, static HTML/CSS/JS canvas, shell contract tests.

## Global Constraints

- Spec: `docs/superpowers/specs/2026-09-08-pipeline-orientation-tech-spec.md` (Status: approved).
- Live canvas binding: **URL query parameters only** (Decision `url_params`) — no generated snapshot HTML.
- Do not invent a new `.cursor/gates/...` kind for orientation; derive from existing pending gates + session ledger.
- Legal returns are **informational only** in v1 (no `/pipeline-back` that mutates gates).
- Pending-gate precedence for `stage`/`layer`: `docs-gate` → `review-gate` → `critique-gate` → `plan-gate`; else last `stages_entered`; else `idle`.
- User-facing chat strips follow skill `plain-language-chat` (full words; Ukrainian when the human writes Ukrainian).
- Kit self-edit: implement on feature branch `cursor/pipeline-orientation-7f76` (or current registered cloud branch template).
- Frequent small commits — one per task.
- Nested fences: use 4-backtick outer fences when embedding ``` inside plan steps.
- Parent may edit kit files for this change; still execute via `software-developer` nested Task after critique clear (harness protocol).

---

## File Structure

| Path | Responsibility |
|------|----------------|
| `scripts/pipeline-status.sh` | Resolve orientation; human text / JSON / canvas URL |
| `scripts/tests/pipeline-status-test.sh` | Fixture-based resolver tests |
| `docs/superpowers/pipeline-flow.html` | Parse query params; highlight layers/nodes |
| `scripts/tests/pipeline-flow-graph-test.sh` | Extend for query-param / class contract |
| `skills/pipeline-status/SKILL.md` | Strip template + when to run resolver |
| `commands/pipeline-status.md` | Slash command entry |
| `skills/hitl-choice/SKILL.md` | Require orientation strip before closed-set asks |
| `commands/start-task.md` | Brief note that orientation strip applies on full/fast/issue human gates |
| `docs/superpowers/pipeline-flow.md` | Orientation section + legend |
| `README.md` | Mention `/pipeline-status` next to canvas blurb |
| `docs/superpowers/dogfood/pipeline-orientation-checklist.md` | Manual dogfood steps |
| `scripts/install-to-project.sh` | Copy `pipeline-status.sh` into consumer `scripts/` like `pipeline-gates.sh` |

---

### Task 1: Resolver library + shell tests (TDD)

**Files:**
- Create: `scripts/pipeline-status.sh`
- Create: `scripts/tests/pipeline-status-test.sh`
- Modify: `scripts/install-to-project.sh` (copy `pipeline-status.sh` beside `pipeline-gates.sh`)

**Interfaces:**
- Consumes: `pg_*` helpers from `scripts/pipeline-gates.sh` (source it)
- Produces (CLI):
  - `pipeline-status.sh [--root <dir>]` → human-readable strip on stdout (exit 0)
  - `pipeline-status.sh --json [--root <dir>]` → JSON orientation record on stdout
  - `pipeline-status.sh --canvas-url [--root <dir>] [--kit-root <dir>]` → single URL/path line with query + hash
- JSON fields exactly as spec §3: `route`, `layer`, `stage`, `pending_gates`, `critique_clear`, `ledger_path`, `stages_entered`, `legal_returns`, `canvas`
- Layer map: fetch/plan/build/review/ship/idle per stage families in `pipeline-flow.md`
- Route detection: prefer `session-full.json` → `full`, `session-fast.json` → `fast`, `session-issue.json` → `issue`; else `unknown`
- `--root` defaults to cwd

- [ ] **Step 1: Write failing tests**

Create `scripts/tests/pipeline-status-test.sh` with temp project fixtures:

````bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# fixture: review-gate pending → layer=review stage=review-gate
# fixture: session-full.json only → last stage from ledger
# fixture: empty → idle / unknown
# assert --json fields with python3 -c or jq
# assert --canvas-url contains route= layer= stage= and #hash
````

Cover at least: pending review-gate wins; docs-gate beats review-gate; empty idle; legal_returns for review-gate includes Build/`fixes`; canvas URL shape.

- [ ] **Step 2: Run tests — expect FAIL**

Run: `bash scripts/tests/pipeline-status-test.sh`  
Expected: FAIL (script missing or incomplete).

- [ ] **Step 3: Implement `scripts/pipeline-status.sh`**

Minimal implementation: scan gate dirs, read session ledger if present, print text/JSON/URL. Source `pipeline-gates.sh` for list helpers when useful (`pg_list_gates`).

- [ ] **Step 4: Run tests — expect PASS**

Run: `bash scripts/tests/pipeline-status-test.sh`  
Expected: ALL PASS.

- [ ] **Step 5: Wire installer copy**

In `scripts/install-to-project.sh`, next to the `pipeline-gates.sh` copy block, also copy `pipeline-status.sh` and `chmod +x`.

- [ ] **Step 6: Commit**

```bash
git add scripts/pipeline-status.sh scripts/tests/pipeline-status-test.sh scripts/install-to-project.sh
git commit -m "Add pipeline-status resolver and contract tests"
```

---

### Task 2: Live highlight on `pipeline-flow.html`

**Files:**
- Modify: `docs/superpowers/pipeline-flow.html`
- Modify: `scripts/tests/pipeline-flow-graph-test.sh`

**Interfaces:**
- Consumes: query params `route`, `layer`, `stage`, optional `pending` from Task 1 `--canvas-url`
- Produces: CSS classes on overview `.layer` / `.node` / `.seq-strip li`: `done`, `here`, `waiting`; header shows route when present; on load, if `stage` maps to a detail view id, optionally `show(stage)` after applying overview highlight (keep overview visible first OR jump to detail — prefer: apply overview highlight, set hash to stage detail only when `detail=1` is absent; **default:** stay on overview with highlight, set `history.replaceState` query preserved)

Assumption locked in plan: **default open stays on overview with highlights**; hash from URL still works if user navigates. If `--canvas-url` includes `#review-gate`, open that detail view **and** keep query params so Back to overview retains highlight.

- [ ] **Step 1: Extend graph contract tests (fail first)**

Add asserts to `scripts/tests/pipeline-flow-graph-test.sh`:

- HTML contains JS that reads `URLSearchParams` for `layer` and `stage`
- CSS defines `.layer.here`, `.node.here`, `.seq-strip li.here` (here may already exist — assert `.layer.done` / `.layer.here` / `.waiting` as needed)
- Comment or data attribute documenting param names `route`, `layer`, `stage`

- [ ] **Step 2: Run — expect FAIL** for new needles

- [ ] **Step 3: Implement HTML/CSS/JS**

Parse search params on load; map `layer` to `.layer.plan|build|review|…`; mark earlier layers done; mark stage node if `data-stage` attributes exist (add `data-stage` / `data-layer` on overview nodes as needed). Preserve existing click navigation.

- [ ] **Step 4: Run graph tests — PASS**

Run: `bash scripts/tests/pipeline-flow-graph-test.sh`

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/pipeline-flow.html scripts/tests/pipeline-flow-graph-test.sh
git commit -m "Highlight pipeline-flow canvas from URL query params"
```

---

### Task 3: Skill + slash command `/pipeline-status`

**Files:**
- Create: `skills/pipeline-status/SKILL.md`
- Create: `commands/pipeline-status.md`

**Interfaces:**
- Consumes: `scripts/pipeline-status.sh` from kit path (via `.cursor/cursor-spells-kit-path` or `$KIT`) or consumer `scripts/pipeline-status.sh` after install
- Produces: chat-facing strip + canvas link; agents must not invent stage when script fails — say orientation skipped in one sentence

- [ ] **Step 1: Write skill**

Skill body: when to use (before every `hitl-choice` closed-set ask; on `/pipeline-status`); run resolver; print strip; never advance gates.

- [ ] **Step 2: Write command**

`commands/pipeline-status.md`: resolve project root = cwd; run script; print output. Optional args: none required.

- [ ] **Step 3: Smoke**

Run from a temp fixture or kit with session ledger:  
`bash scripts/pipeline-status.sh --root /workspace`  
Expected: non-empty strip, valid `--json`.

- [ ] **Step 4: Commit**

```bash
git add skills/pipeline-status/SKILL.md commands/pipeline-status.md
git commit -m "Add pipeline-status skill and slash command"
```

---

### Task 4: Wire `hitl-choice` + start-task notes

**Files:**
- Modify: `skills/hitl-choice/SKILL.md`
- Modify: `commands/start-task.md` (one short orientation note under full-mode / shared notes)
- Optional one-liner in `skills/finish-plan/SKILL.md`, `skills/approve-plan/SKILL.md`, `skills/tech-spec/SKILL.md`: “before ask, skill `pipeline-status` strip” — prefer single choke point in `hitl-choice` to avoid drift

**Interfaces:**
- Consumes: skill `pipeline-status`
- Produces: protocol step 0 in `hitl-choice`: load/print orientation strip before calling AskQuestion / text fallback

- [ ] **Step 1: Edit `hitl-choice` protocol**

Insert mandatory step: before the interactive question tool, invoke skill `pipeline-status` (or run the script) and include the strip in the same user-visible turn as the question. Missing script → one-sentence skip, still ask the gate.

- [ ] **Step 2: Add start-task pointer**

In `commands/start-task.md` full-mode notes: human gates use `hitl-choice` orientation strip; humans may run `/pipeline-status` anytime.

- [ ] **Step 3: Grep contract (lightweight)**

Add asserts to `scripts/tests/pipeline-status-test.sh` or a tiny `scripts/tests/pipeline-status-wiring-test.sh`:

- `hitl-choice/SKILL.md` mentions `pipeline-status`
- `commands/pipeline-status.md` exists
- `commands/start-task.md` mentions `/pipeline-status` or orientation strip

- [ ] **Step 4: Run wiring tests — PASS**

- [ ] **Step 5: Commit**

```bash
git add skills/hitl-choice/SKILL.md commands/start-task.md scripts/tests/pipeline-status-wiring-test.sh
git commit -m "Require orientation strip before hitl-choice asks"
```

---

### Task 5: Docs + dogfood checklist

**Files:**
- Modify: `docs/superpowers/pipeline-flow.md`
- Modify: `README.md`
- Create: `docs/superpowers/dogfood/pipeline-orientation-checklist.md`

**Interfaces:**
- Documents AC-4 surfaces; links resolver + command + URL param legend

- [ ] **Step 1: Add orientation section to `pipeline-flow.md`**

After the legend: how to read `/pipeline-status`, URL params table, legal-returns note (informational).

- [ ] **Step 2: README blurb**

Extend the canvas sentence to mention `/pipeline-status` and query-param highlight.

- [ ] **Step 3: Dogfood checklist**

Steps: create fake `review-gate` marker → run script → open printed URL → confirm highlight; clear marker → idle.

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/pipeline-flow.md README.md docs/superpowers/dogfood/pipeline-orientation-checklist.md
git commit -m "Document pipeline orientation strip and canvas params"
```

---

## Verification (plan complete)

Run:

```bash
bash scripts/tests/pipeline-status-test.sh
bash scripts/tests/pipeline-status-wiring-test.sh
bash scripts/tests/pipeline-flow-graph-test.sh
```

All PASS. Manual: `/pipeline-status` (or script) against a fixture shows strip + openable canvas URL with highlight.

## Execution handoff

After `approve-plan` → `implementation-critic` → `Verdict: clear` → `start-build` dispatches nested Task `software-developer` for this plan path; wait; then `finish-plan`.
