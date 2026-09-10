# Designer ↔ critic consensus protocol

Used only on tech-spec **full** path. The human is not asked to break designer↔critic ties.

## Roles

- **Designer** (`csp-system-design-designer`): writes/revises `…-system-design.md`
- **Critic** (`system-design-critic`): read-only audit; emits findings + Verdict
- **Orchestrator** (`tech-spec` skill/agent): runs the loop, merges, owns HITL

## Loop

1. Designer writes or updates the system-design draft (`Status: draft`).
2. Critic runs against that file path (barrier: never start critic before the draft file exists).
3. If Verdict is `clear`: exit loop; proceed to merge.
4. If open **must-fix** findings exist: designer revises the draft to address each Must-fix (or documents an explicit trade-off the critic can clear on re-check). Do **not** ask the human.
   - In `format-human-plan` mode, a Must-fix against the human's stated approach is resolved by documenting the trade-off and residual risk in the draft (so the critic can clear or Accept-risk it) — never by silently re-architecting away from the human's intent. The human decides at `approve-spec`.
5. Critic re-checks the updated file.
6. Repeat until Verdict `clear` or `MAX_ROUNDS` (3) is reached.

## After MAX_ROUNDS

- Remaining **must-fix**: designer must fold each into Trade-offs / Assumptions with a concrete choice and rationale so the draft is mergeable; orchestrator then merges and surfaces residual risk in tech-spec Assumptions for `approve-spec`. Still no designer↔critic tie-break HITL.
- **should-fix**: may become Rejected alternatives one-liners or Assumptions after merge; never block merge.
- **accept-risk**: must appear in tech-spec Assumptions (claim, why, how to revoke) after merge; human reviews at `approve-spec`.

## Forbidden

- Asking the human which agent is "right"
- Separate `approve-design` gate
- Inventing AC business facts to clear a Must-fix
- Starting a second competing full designer by default

## Blocker exception (orchestrator)

If either agent surfaces a missing business fact with no happy path, orchestrator stops the loop and asks one Blocker question via `hitl-choice`. After the human answers, resume from step 1 with updated brief.
