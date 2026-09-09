# Tech-spec full path (system-design pair)

## When

- Entry `human` → always this path (after human plan is available)
- Entry `agent` → only if depth HITL returns `full`

## Brief

Collect once: AC source, optional human plan path/text, `.cursor/project-patterns.md` if present, stack label from `/csp-start-task` bootstrap when available.

## Steps

1. Dispatch `csp-system-design-designer`:
   - `human` → mode `format-human-plan`
   - `agent`+`full` → mode `draft-from-ac`
   - In `format-human-plan`, Must-fix findings against the human's stated approach are resolved by documenting trade-off and residual risk in the draft (critic clears or Accept-risk) — never by silently re-architecting away from human intent; human decides at `approve-spec`.
2. Wait until `…-system-design.md` exists with `Status: draft`.
3. Run consensus loop per `skills/system-design/references/consensus-protocol.md` (dispatch `csp-system-design-critic`, revise via designer, max 3 rounds).
4. On Blocker from missing business fact: one `hitl-choice` ask; resume loop with updated brief.
5. Merge into tech-spec per map below; write `docs/superpowers/specs/YYYY-MM-DD-<topic>-tech-spec.md` with `Status: draft`.
6. Set system-design file `Status: merged` (keep file).
7. Present tech-spec gate: `approve-spec` / `revise` / `skip` via `hitl-choice`.

## Merge map

| From system-design | Into tech-spec section |
|--------------------|------------------------|
| High-level design + deep dive (components, APIs, storage, data model) | Changes by layer; Data model / contracts |
| Scale/reliability + trade-offs (losing alternatives) | Rejected alternatives; Assumptions |
| Rollout/migration notes if present; else derive minimal safe sequence from storage/API changes | Rollout sequence; Compatibility / migration / rollback |
| AC ids | AC references |
| Accept-risk + Assumptions | Open questions / Assumptions |

All seven tech-spec sections required. Use `clean-decision-docs`. Do not copy system-design headers wholesale — rewrite into the tech-spec template voice.

## Context budget

Full path may load: `tech-spec`, `full-path.md`, `template.md`, `question-discipline.md`, `system-design` (+ template + consensus), `system-design-critic` (+ refs), `hitl-choice`, `clean-decision-docs`.

Light path must **not** load system-design pair skills.
