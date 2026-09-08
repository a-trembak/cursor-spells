# Pipeline orientation — Technical Spec

**Status:** approved  
**AC:** Closes the agreed orientation criteria from the 2026-09-08 investigation: chat status strip at every human-gate stop; `/pipeline-status` showing current layer/stage and legal returns; live highlight on `pipeline-flow.html` via URL parameters; tests and pipeline-flow docs updated for the new behavior.

## 1. AC references

- AC-1: At every closed-set human-in-the-loop gate, the orchestrator shows a short status strip (route, layer, current stage, next stages, legal returns, canvas link).
- AC-2: Slash command `/pipeline-status` reports the same orientation from disk state without advancing the pipeline.
- AC-3: `pipeline-flow.html` highlights done / current / waiting nodes when opened with orientation query parameters produced by the status tool.
- AC-4: Contract tests cover the status resolver and the HTML query-parameter contract; `pipeline-flow.md` / README mention the orientation surfaces.

## 2. Changes by layer

Order of touch (kit only — no consumer application services):

1. **Resolver library** — new `scripts/pipeline-status.sh` (sourceable + CLI). Reads consumer-project `.cursor/gates/<kind>/<slug>` and optional `.cursor/gates/trajectory-run/session-{full,fast,issue}.json`. Emits a stable orientation record (stdout: human text; optional `--json`; optional `--canvas-url`).
2. **Chat strip contract** — new skill `skills/pipeline-status/` (thin): documents the strip template and when to call the resolver; used by orchestrators before `hitl-choice` asks. Extend `skills/hitl-choice/SKILL.md` with a required “orientation strip before the question” step (call resolver or fall back to the known stage name when the script is missing).
3. **Slash command** — new `commands/pipeline-status.md` that runs the resolver in the consumer project root and prints the strip + legal returns + canvas link.
4. **Canvas** — update `docs/superpowers/pipeline-flow.html` to parse query parameters and apply CSS classes (`done` / `here` / `waiting`) on overview layer nodes and the `seq-strip`; keep hash navigation for detail views (`#review-gate` etc.).
5. **Docs twin** — update `docs/superpowers/pipeline-flow.md` (orientation section + legend) and README canvas blurb.
6. **Installer** — `scripts/install-to-project.sh` already walks `commands/*.md`; new command installs via existing symlink/copy walk. No new always-on rule file required for v1 (strip is skill protocol, not a Cursor rule).
7. **Tests** — `scripts/tests/pipeline-status-test.sh` (resolver fixtures) and extend `scripts/tests/pipeline-flow-graph-test.sh` (HTML query-param / class contract). Dogfood checklist row for `/pipeline-status`.

## 3. Data model / contracts

### Orientation record (JSON shape from `--json`)

| Field | Type | Meaning |
|-------|------|---------|
| `route` | `full` \| `fast` \| `issue` \| `unknown` | From session ledger filename / stages, else `unknown` |
| `layer` | `fetch` \| `plan` \| `build` \| `review` \| `ship` \| `idle` | Derived layer |
| `stage` | string | Canonical stage id aligned with trajectory `STAGES` + human-gate names where helpful (`review-gate`, `tech-spec`, …) |
| `pending_gates` | array of `{kind, slug, plan_path}` | Open `.cursor/gates/{plan-gate,critique-gate,review-gate,docs-gate}/*` |
| `critique_clear` | boolean | Whether any `plan-critique-clear/<slug>` exists for the active plan path when known |
| `ledger_path` | string \| null | Session ledger used, if any |
| `stages_entered` | string[] | From ledger `stages_entered` when present |
| `legal_returns` | array of `{from, to, how}` | Closed set from the cycle table in `pipeline-flow.md` for the current stage |
| `canvas` | object | `{ path, hash, query }` for building a `file://` or relative link |

### URL query parameters (canvas)

| Param | Example | Effect |
|-------|---------|--------|
| `route` | `full` | Shown in header / strip |
| `layer` | `review` | Marks that layer box as `here`; earlier layers `done` |
| `stage` | `review-gate` | Marks matching overview node / seq item as `here`; maps to detail hash when opening |
| `pending` | `review-gate` | Optional; styles waiting human-gate nodes |

Example link printed by the resolver:

`docs/superpowers/pipeline-flow.html?route=full&layer=review&stage=review-gate#review-gate`

### Pending-gate precedence (when several open)

Highest wins for `stage` / `layer`: `docs-gate` → `review-gate` → `critique-gate` → `plan-gate`. If none pending: use last `stages_entered` entry from the session ledger; else `idle`.

### Chat status strip (template)

One short block before each human-gate ask (user language per `plain-language-chat`):

- Route label · layer · current stage  
- Next stages (1–3 names)  
- Legal returns (or “none — happy path only”)  
- Canvas link with query parameters  

### Legal returns (v1, informational only)

| Current context | Legal return | How (prose for humans) |
|-----------------|--------------|------------------------|
| `review-gate` | Build / `software-developer` | Answer `fixes` at the gate |
| Critic blocked / pending accept | Plan / rewrite or same critic ask | Answer `revise` or `accept F<id>` |
| Engineer-review needs clarification | Stay in Review | Answer clarify tokens |
| Docs location follow-up | Stay in Docs | Provide path/URL |
| Tech-spec / approve-plan revise loops | Stay in Plan | Answer `revise` |

No slash command rewinds the pipeline automatically in v1.

## 4. Rollout sequence

1. Land resolver script + unit/contract tests with fixture gate dirs (no skill wiring yet).
2. Land HTML query-parameter highlighting + graph contract asserts.
3. Land skill `pipeline-status` + command `/pipeline-status`.
4. Wire `hitl-choice` (and start-task notes) to require the strip before closed-set asks.
5. Update `pipeline-flow.md` / README; dogfood checklist.
6. Installer walk picks up the new command on next `csp update` / install — no schema migration.

## 5. Compatibility / migration / rollback

- **Compatibility:** Additive. Existing gates and ledgers unchanged. Old `pipeline-flow.html` without params still works (no highlight).
- **Migration:** None. No rename of gate kinds.
- **Rollback:** Remove the new command/skill/script and revert HTML/hitl-choice strips; markers keep working as today.

## 6. Rejected alternatives

- **Dedicated `pipeline-orientation/<slug>.json` marker written every stage** — rejected: duplicates session ledger + gates; extra write failures mid-pipeline.
- **Generated snapshot HTML per status** — rejected for v1 (Decision `url_params`): more moving parts; `file://` query params suffice.
- **Defer live HTML entirely** — rejected (human chose `url_params`).
- **Actionable `/pipeline-back` that mutates gates** — rejected for v1: high risk of desync with orchestrator; strip + legal-returns prose only.
- **Cursor Canvas plugin as the primary surface** — rejected for v1: heavier than extending the existing HTML map.

## 7. Open questions / Assumptions

**Open questions:** none.

**Assumptions:**

| Claim | Why safe | How to revoke |
|-------|----------|---------------|
| Resolver prefers consumer project `.cursor/gates` (cwd), not the kit repo, when cwd is a consumer install | Matches existing gate helpers | Document a `--root` flag; default remains cwd |
| When no ledger and no pending gates, report `idle` rather than inventing a stage | Avoids false confidence | Later: optional chat-hint file if humans want sticky stage |
| Status strip language follows the human’s chat language (`plain-language-chat`) | Existing kit chat rule | Force English-only strip if dogfood complains |
| Kit self-changes for this feature are implemented on a feature branch per cloud branch rules | Cloud agent policy | N/A |
| `pipeline-status.sh` may call into `pipeline-gates.sh` helpers for slug/path normalize | Same ownership | Inline copies only if sourcing proves fragile in tests |
