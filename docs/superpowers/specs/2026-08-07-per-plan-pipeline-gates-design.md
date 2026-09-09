# Per-plan pipeline gates

## Status

`approved` — implementation target for cursor-spells kit (brainstorm validated).

## Goal

Allow multiple chats / tickets in the same consumer project to run approve-plan, critic, build, finish-plan, and update-docs in parallel without fighting over a single global marker file (e.g. `.cursor/critique-gate.pending` owned by ACP-2665 blocking ACP-2656).

## Problem

Today each gate kind is one flat file under `.cursor/`:

| Legacy file | Meaning |
|-------------|---------|
| `plan-gate.pending` | Plan HITL open |
| `critique-gate.pending` | Critic blocked / accept-risk open |
| `plan-critique.clear` | Critic clear for that plan path |
| `review-gate.pending` | Finish-plan → engineer-review HITL |
| `docs-gate.pending` | Update-docs destination HITL |

Content is typically one line: the plan path. Hooks such as `pre-build-gate.sh` treat **any** pending file as blocking Task 1 for the whole repo. Two chats on different plans therefore collide; the correct agent behavior today is to refuse to touch a foreign marker, which leaves the second chat stuck.

## Decisions

| Decision | Choice |
|----------|--------|
| Layout | Per-kind directories under `.cursor/gates/<kind>/<slug>` (approach 1) |
| Scope | All five pipeline markers in one change |
| Legacy | Migrate-on-read: copy legacy → per-plan file for that path, then delete legacy |
| Slug | Ticket id from plan path/basename (`ACP-\d+`, case-insensitive); else first 12 hex of SHA-256 of normalized relative plan path; ticket collision → `TICKET-<hash12>` |
| Foreign gates | Never delete/overwrite another slug without explicit HITL `force-clear <slug\|path>` |
| Hook semantics | Block / nudge only for the **current** plan's slug when the plan path is known. If the plan path is unknown, stay silent (`{}`) — do not list other slugs. |

## Layout

Root (consumer project only, never the kit checkout):

```text
.cursor/gates/
  plan-gate/<slug>
  critique-gate/<slug>
  plan-critique-clear/<slug>
  review-gate/<slug>
  docs-gate/<slug>
```

| Kind dir | Replaces |
|----------|----------|
| `plan-gate/` | `.cursor/plan-gate.pending` |
| `critique-gate/` | `.cursor/critique-gate.pending` |
| `plan-critique-clear/` | `.cursor/plan-critique.clear` |
| `review-gate/` | `.cursor/review-gate.pending` |
| `docs-gate/` | `.cursor/docs-gate.pending` |

### File contents

- Line 1: plan path (same contract as today — path string the skills already write).
- Line 2 (optional): `ticket: ACP-2656` when the slug was derived from a ticket id.

### Slug algorithm

Input: plan path as resolved by the calling skill.

1. Normalize to a project-relative path when possible (strip consumer project root prefix; collapse `//`; no trailing slash).
2. Search the normalized path and its basename for the first match of `(?i)ACP-\d+` (or the project's existing ticket pattern if already documented elsewhere — default **`ACP-\d+`** plus a generic `[A-Z][A-Z0-9]+-\d+` Jira-style fallback). Prefer the basename match when both hit.
3. If a ticket id is found: slug = that id uppercased (e.g. `ACP-2656`).
4. Else: slug = first 12 lowercase hex chars of SHA-256 of the normalized relative path. Require `sha256sum` or `shasum`; if neither exists, **stop** with an error — do not invent a weaker slug.
5. Collision: if `.cursor/gates/<kind>/<ticket>` already exists and its line-1 plan path ≠ this plan path, use `<ticket>-<hash12>` for the new plan. Existing file for the matching path is reused as-is.

## Legacy migrate-on-read

When any skill or hook needs to read a gate for plan path P:

1. Compute slug S for P.
2. If `.cursor/gates/<kind>/<S>` (or collision variant whose line-1 equals P) exists → use it.
3. Else if legacy flat file exists:
   - Read its line-1 path L.
   - If L equals P (normalized): write per-plan file for S with the same contents, delete the legacy file, then use the per-plan file.
   - If L refers to another plan: leave legacy alone; for P create/use only the per-plan file (do not steal L's marker). Prefer migrating L into *its* per-plan file in the same pass when the caller is doing a repo-wide list (hooks), so legacy does not linger forever.
4. Empty/corrupt legacy (no usable path): do not migrate; emit a chat/hook warning; do not block writing a valid per-plan gate for P.

Writers always create the per-plan path. After a successful migrate of a legacy file that pointed at P, legacy must be gone so hooks stop seeing a second source of truth.

## Skill semantics

Applies to: `approve-plan`, `start-build`, `finish-plan`, `update-docs`, `start-issue-task`, and any command/agent that today reads or writes the five legacy markers (`software-developer` / `csp-bug-fixer` preconditions, engineer-review finish handoff, etc.).

1. Resolve plan path → slug.
2. Migrate-on-read for kinds about to be read.
3. Read/write/clear **only** `.cursor/gates/<kind>/<slug>` for that plan.
4. **Foreign slug:** never delete or overwrite. If the human explicitly requests clearing another chat's gate, ask HITL `force-clear <slug|path>` first.
5. `start-build` for plan P:
   - Require `plan-critique-clear/<slug>` with line-1 == P.
   - Stop if `plan-gate/<slug>` or `critique-gate/<slug>` exists for that slug.
   - Do **not** require other slugs' gates to be absent.

## Hook semantics

### `pre-build-gate.sh`

- Prefer plan path from hook payload / cwd context when available.
- If plan path known: followup only when `plan-gate/<slug>` or `critique-gate/<slug>` exists for that slug (after migrate-on-read for those kinds).
- If plan path unknown: emit `{}`. Do **not** list open gates. `followup_message` auto-continues every chat in the workspace; a foreign slug cannot be cleared there, so listing re-creates a repo-wide unresolvable loop (stop-hook `loop_limit`).
- Stop treating a single global pending file — or a list of all per-plan files — as a repo-wide hard block for unrelated plans. Skills (`start-build`, `approve-plan`, `finish-plan`) remain the per-plan gate when the hook has no plan path.

### `post-plan-review-gate.sh` (and docs-gate consumers)

- Same per-slug model under `review-gate/` and `docs-gate/`.
- Known plan path → nudge only that slug; honor existing skip/approve/done tokens in chat as today before re-asking.
- Unknown plan path → emit `{}` (same reason as `pre-build-gate.sh`).

## Shared helper

Add a small bash library used by hooks and documented for skills, e.g. `scripts/pipeline-gates.sh` (installed/refreshed into consumer projects like other kit scripts):

| Function | Role |
|----------|------|
| `pg_normalize_plan_path` | Project-relative normalize |
| `pg_slug_for_plan` | Ticket / hash / collision rule |
| `pg_gate_path kind slug` | Absolute path under `.cursor/gates/` |
| `pg_migrate_legacy kind` | Migrate-on-read / list-pass migrate |
| `pg_write_gate kind plan_path` | mkdir, write line-1 (+ optional ticket line), migrate first |
| `pg_clear_gate kind plan_path` | Remove only matching slug file |
| `pg_list_gates kind` | Paths + line-1 for open gates |

Skills keep a markdown contract ("call these steps / equivalent bash") so agents without sourcing the script still behave correctly.

## Components to change

| Artifact | Change |
|----------|--------|
| `scripts/pipeline-gates.sh` | New helper |
| `bin/csp` / install path | Install/refresh helper into consumer `scripts/` (same pattern as other kit scripts) |
| `hooks/pre-build-gate.sh` | Per-slug + migrate; silent when plan path unknown |
| `hooks/post-plan-review-gate.sh` | Per-slug `review-gate/` |
| `skills/approve-plan`, `start-build`, `finish-plan`, `update-docs` | Paths + foreign-slug rule |
| `commands/approve-plan`, `start-build`, `start-issue-task`, `finish-plan`, `update-docs` | Document new paths |
| `rules/before-build-critique-gate.mdc`, `after-plan-review-gate.mdc` | Per-slug wording |
| Agents that mention markers | Align preconditions |
| `docs/superpowers/pipeline-flow.md` (+ html) | Diagram marker paths |
| `README.md` | Runtime markers table |
| Dogfood checklist | Two plans, two critique pendings, build one without clearing the other |

## Success criteria

- Chat A (ACP-2665) can hold `critique-gate/ACP-2665` while chat B (ACP-2656) writes/clears `critique-gate/ACP-2656` without HITL between them.
- `start-build` for B succeeds when only B's clear marker matches B's plan, even if A's critique-gate is still pending.
- A stop hook in chat B with unknown plan path does **not** emit `followup_message` for A's pending gate.
- Opening a skill against a repo that still has legacy `.cursor/critique-gate.pending` migrates that plan's marker once and removes the legacy file.
- Agents refuse to delete another slug's gate unless the human passes `force-clear`.

## Out of scope

- Isolation by Cursor chat/session id (plan/ticket identity is enough)
- Cross-machine distributed locking
- Changing `implementation-critic` Verdict rules or accept-risk semantics
- Renaming HITL reply tokens (`approve-plan`, `accept F<id>`, etc.)
