# Pipeline run memory — Technical Spec

**Status:** approved  
**AC:** AC1, AC2, AC3, AC4, AC5

## 1. AC references

Closes AC1, AC2, AC3, AC4, AC5.

## 2. Changes by layer

Order of touch (kit → consumer runtime):

1. **Helper script (kit source)** — add `scripts/pipeline-run-log.sh` with subcommands `init`, `append`, `promote`, `read-tail`, `path`, optional `brief-upsert`. Source `pipeline-gates.sh` for slug helpers. Use `flock` on the journal file for append and promote writes; if `flock` is missing, **fail writes** (non-zero) and still allow `read-tail` / `path`.
2. **Installer** — `scripts/install-to-project.sh` copies `pipeline-run-log.sh` into `<project>/scripts/` (executable). Print a one-line recommendation to gitignore `.cursor/gates/run-log/` after copy.
3. **Orientation** — extend `scripts/pipeline-status.sh` with `--invocation <id>`, additive JSON fields `run_log_path` / `run_log_tail`, optional strip line `Recent: <last note>`. Stage/layer stays gates → session ledger → idle.
4. **Pipeline skills / commands** — bootstrap: mint `invocation_id`, `init` (writes journal + pointer). Dual-write `append` only at the **allowlisted** ledger stops below. When plan path first known: `promote` (refuse if slug journal already exists). Fast / tiny / issue runs without a full implementation plan: keep `inv-*.md` + optional short **brief**; do not invent a fake plan under `docs/`.
5. **Docs** — `pipeline-flow.md` + dogfood checklist: consumer paths, pointer, brief, refuse-on-conflict promote, no chat dumps in kit.
6. **Contract tests** — helper + status + wiring tests on temp `--root`.

## 3. Data model / contracts

### Paths (consumer project root)

| When | Path |
|------|------|
| Pre-plan / no promote yet | `.cursor/gates/run-log/inv-<invocation_id>.md` |
| After successful promote | `.cursor/gates/run-log/<slug>.md` |
| Pointer (written on every `init`) | `.cursor/gates/run-log/current-invocation` |
| Optional short brief (fast / tiny / no formal plan) | `.cursor/gates/run-log/briefs/inv-<invocation_id>.brief.md` |

`invocation_id`: `[A-Za-z0-9][A-Za-z0-9._-]{0,63}`. No shared `active.md`.

**Pointer file format** (UTF-8). Written on every `init` with `invocation` + `updated`. On **successful** `promote` only, refresh to also include resolved `plan` / `slug` / optional `journal` (filename relative under run-log). Do **not** rewrite the pointer on refuse-on-conflict.

```text
invocation: <id>
plan: <path>                 # after successful promote
slug: <slug>                 # after successful promote
journal: <slug>.md           # optional; relative under run-log
updated: <iso8601>
```

### File shape (journal)

```markdown
# Pipeline run-log
invocation: <id>
plan: <path>
slug: <slug>
route: full|fast|issue|unknown
started: <iso8601>

- <iso8601> | stage=<id> | note=<short>
```

### Brief (optional, not a plan)

Skeleton only — goal, constraints, closed-set decisions, next stage. **Forbidden:** chat transcripts, full ticket bodies, tool traces. Cap ~40 lines.

### CLI

```text
pipeline-run-log.sh init --root <project> --invocation <id> [--route <…>] [--reset]
pipeline-run-log.sh append --root <project> --invocation <id> [--plan <path>] \
  --stage <id> --note "<short text>"
pipeline-run-log.sh promote --root <project> --invocation <id> --plan <path> [--route <…>]
pipeline-run-log.sh read-tail --root <project> [--invocation <id>] [--plan <path>] [--lines N]
pipeline-run-log.sh path --root <project> [--invocation <id>] [--plan <path>]
pipeline-run-log.sh brief-upsert --root <project> --invocation <id> [--route <…>] \
  [--goal "<text>"] [--next "<stage>"]
```

- Journal path resolution: while `inv-<id>.md` still exists, `append` / `path` / `read-tail` for that id always use it — even if `--plan` is also passed (avoids writing onto a foreign slug after refuse-on-conflict). After a successful promote removes `inv-<id>.md`, resolve via `--plan` when passed, else via the pointer’s `journal` / `slug` / `plan` when the pointer’s `invocation` matches the same id. Status enrichment follows the same inv-first then pointer-slug/journal rule for `--invocation`.
- Once the plan path is known, allowlisted writers should pass `--plan` on `append` (belt and suspenders with pointer resolution).
- `--note`: collapse newlines to spaces, trim, hard max **120 Unicode characters** (truncate with a Unicode-aware helper, not raw bytes).
- Duplicate append: if last body line’s `stage=` and `note=` match, skip write, exit `0` (check must run inside the same `flock` critical section as the append write).
- `init`: create `inv-<id>.md` + write pointer. If `inv-<id>.md` already exists → **refuse** (exit non-zero) unless `--reset` (rewrite that path only). Never touch other invocations’ files.
- Exit `2` on unknown args / invalid invocation id; missing journal on `read-tail` → empty stdout, exit `0`. Status with an invalid `--invocation` (or invalid pointer id) **omits** run-log enrichment and still prints the orientation strip (does not hard-exit).
- **Promote:**
  - Target absent → `mv` then refresh header (`plan` / `slug` / `route`); refresh pointer with `plan` / `slug` / `journal`; exit `0`.
  - Target **exists** → **refuse-on-conflict**: exit non-zero; leave `inv-<id>.md` intact; do **not** rewrite the pointer; do not merge or truncate. Caller skips promote (one sentence); continues appending with `--invocation` (may record `plan`/`slug` in the inv header via append metadata if implemented, without deleting the foreign slug journal).
  - I/O failure mid-promote → leave source intact; exit non-zero; no retry loop. Contract tests must exercise a **real** mid-promote failure (for example target directory not writable), not “missing `--plan`”.

### Status resolution for enrichment

Order: `--invocation` flag → pending-gate plan’s slug journal → `current-invocation` pointer → omit. Never newest-`inv-*`-by-mtime.

### Dual-write allowlist (append + ledger)

Only these stops dual-write run-log when they already record the session ledger:

- `commands/csp-start-task.md`, `commands/csp-start-issue-task.md` (`init`, append, promote when plan known, optional `brief-upsert` on fast/tiny)
- `skills/tech-spec/SKILL.md`
- `skills/approve-plan/SKILL.md`
- `skills/finish-plan/SKILL.md`
- `skills/hitl-choice/SKILL.md` (append after closed-set token; orientation may pass `--invocation`)
- `skills/propose-commit/SKILL.md`
- `skills/create-pr/SKILL.md`

### Authority

| Store | Authority |
|-------|-----------|
| `.cursor/gates/<kind>/<slug>` | Pending / clear human gates |
| `.cursor/gates/trajectory-run/session-*.json` | Trajectory scoring stages |
| `.cursor/gates/run-log/…` | Orientation journal / brief / pointer only |

### Forbidden content

No chat transcripts, full ticket bodies, secrets, or kit-global conversation / vector memory (AC4).

## 4. Rollout sequence

1. Land helper + contract tests (isolation, refuse-on-conflict, real promote failure, Unicode note, re-init refuse, pointer write).
2. Installer copy + gitignore recommendation.
3. Status `--invocation` + enrichment + pointer fallback.
4. Allowlisted skill/command wire-ups; fast path brief optional.
5. Docs + dogfood checklist.
6. Consumer `csp update` / install — no ledger migration.

## 5. Compatibility / migration / rollback

| Step | Rollback |
|------|----------|
| Helper / installer | Remove consumer copy; skills skip when missing |
| Status fields / `--invocation` | Additive; old callers ignore |
| Pointer / briefs | Delete `.cursor/gates/run-log/` locally |
| Skill wire-ups | Revert markdown |

## 6. Rejected alternatives

- Kit-global conversation memory / vector dump of chat — violates AC4.
- Shared `active.md` truncated on every start — wipes concurrent pre-plan chats.
- **Merge-on-promote when slug journal exists** — interleaves two chats’ notes; orientation can quietly lie after context loss.
- Fake implementation plans under `docs/` for tiny / fast fixes — bloated; use inv journal + optional brief instead.
- Mandatory newest-`inv-*`-by-mtime guessing — can pick the wrong journal.
- Soft truncate of oldest body lines in v1.
- Promote by truncating an existing slug journal.
- Replacing session ledgers with the run-log.

## 7. Open questions / Assumptions

### Open questions

None.

### Assumptions

| Claim | Why | How to revoke |
|-------|-----|---------------|
| Pointer is always written on `init` but missing pointer never bricks the pipeline | Cheap recovery after context loss; omit enrichment if absent | Per-session pointer filenames if hosts expose a stable session key |
| Refuse-on-conflict promote is correct default | Keeps each journal attributable to one invocation | Add explicit `promote --force-merge` only after dogfood demands it |
| Fast / tiny runs need no formal plan file | Human: small fixes should not require writing-plans | Require brief-upsert when route is `fast` if dogfood loses goals |
| Notes reuse closed-set tokens / stage ids | Same vocabulary as the ledger | Fixed note-verb enum if free text drifts |
| Status JSON enrichment is additive | Optional keys | Gate behind a flag if a parser is strict |
| v1 relies on contract tests; write fails closed without `flock` | Avoids torn orientation lines | Soften to best-effort skip if a host cannot ship `flock` |
| Dual-write allowlist is complete for v1 | Wiring test greps the allowlist | Extend allowlist when new ledger stops appear |
