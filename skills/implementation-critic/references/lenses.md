# Critic lenses

Passes A and B run on every critic invocation — one alone misses a different class of plan defect (a plan can be simple but silently unsafe on migration, or safe but over-engineered).

**Pass C** runs whenever the plan is a **bug-fix plan** (path/topic contains `-fix`, caller is `/start-issue-task`, or the plan states it addresses a defect/regression). Skip Pass C for feature/implementation plans that are not bug fixes; note `pass_c: n/a (not a bug-fix plan)` in Coverage.

## Pass A — Design (skill: `plan-reviewer`, mblode/agent-skills)

Install: `npx skills add https://github.com/mblode/agent-skills --skill plan-reviewer`

### Checklist

Used verbatim when the skill is installed; used as the built-in fallback checklist when it is not.

- **KISS** — Is this the simplest thing that could work? Could a developer unfamiliar with this plan understand it in one read?
- **YAGNI** — Is every abstraction, config option, or generalization justified by a *current* requirement in the tech spec/AC, not a hypothetical future one?
- **Simpler alternative** — Is there a solution with fewer moving parts (fewer new files, fewer new abstractions, fewer new dependencies) that satisfies the same AC?
- **Existing abstractions** — Does the plan reuse existing helpers/services/patterns from `.cursor/project-patterns.md` and the codebase, or does it reinvent something that already exists?
- **Tracer bullet** — Does the plan deliver a minimal working slice across the full stack first, rather than building all of one layer before any of another?
- **Duplication over wrong abstraction** — Are new abstractions justified by actual repetition already present in the plan/codebase, not by speculation about future reuse?

## Pass B — Risk (skill: `project-verify-plan`, envoydev/agents-stack)

Install: `npx skills add https://github.com/envoydev/agents-stack --skill project-verify-plan`

### Checklist

Used verbatim when the skill is installed; used as the built-in fallback checklist when it is not.

- **Risk coverage** — Does the plan name the non-obvious failure modes this change will hit (data-access, lifecycle, concurrency, boundary traps for its stack)? A trap the plan doesn't name is a trap the build inherits.
- **Scope match** — Does the plan cover exactly what the tech spec / AC ask for — nothing missing, nothing speculative added?
- **Edges + safety** — Are boundary, empty, and error cases named (not assumed)? Is every auth / migration-order / data-loss / concurrency surface called out with its safeguard?
- **Soundness** — Does the approach match the repo's existing architecture (not introduce a second, competing one)? Are dependencies between tasks correctly ordered? Is this the smallest plan that meets the tech spec?

## Pass C — Bug fix (built-in; no third-party skill)

Run for bug-fix plans only (see above). Built-in checklist — always available.

### Checklist

- **Root cause vs symptom** — Does the plan name the causal chain and change the underlying fault, not only mask the symptom (extra null-check, swallow error, retry without fixing the producer)?
- **Regression / blast radius** — Are call sites, shared helpers, migrations, and user-visible flows that could break named with safeguards or explicit accept-risk?
- **Better alternative** — Is there a simpler or more correct fix (existing helper, smaller diff, fix at the source module) that still resolves the reported failure? If yes and the plan ignores it without rationale → finding.
- **Test catches the bug** — Does the verification/test plan include a case that fails before the fix and passes after for the reported failure mode?

## Anti-confabulation rule (applies to all passes)

Before recording any finding, quote the exact plan/spec line or the exact repo `file:line` it is judging, read fresh in this pass — never infer from the branch name, working directory, or memory of an earlier pass. If a finding cannot be backed by a fresh quote, do not record it.

## Skill-missing fallback

If `plan-reviewer` or `project-verify-plan` is not installed, run the corresponding checklist above directly (it is written to work standalone) and set that pass's Coverage line to `ran (built-in fallback)` plus `skill_missing: <skill-id>`. Do not skip the pass and do not block the run. Pass C has no external skill — always `ran (built-in)`.
