---
name: clean-decision-docs
description: >-
  Use when drafting or revising tech specs, design docs, implementation plans,
  or other decision artifacts after critique, discussion, or human feedback —
  especially on revise / approve-spec / approve-plan loops. Use when tempted to
  write "fixed", "changed to", "was previously", or a what-changed section
  inside the document.
---

# Clean Decision Docs

A tech spec or plan is a **final-form decision**, not a diary of how you got there. Critique, revise, and discussion happen *outside* the artifact; the file itself must read as if the current decisions were always the decisions.

Same idea as banning changelog comments in code (`code-comments`): git history, chat, and critic reports already carry the revision trail.

## When to Use

- Writing or revising a tech spec, design doc, or implementation plan
- Applying critic findings (`must-fix` / `should-fix`) or human `revise` feedback
- Any time you are about to narrate a prior draft inside the document

## Hard rule

**Rewrite the document in place as the current truth.** Do not leave archaeology of discarded drafts.

| Put here | Not here |
|----------|----------|
| Chat reply summarizing what you changed (for the human's verify step) | Inside the spec/plan body |
| Critic report / review thread | "What changed", "Changelog", "Updates after critique" sections |
| Git history / PR diff | "was previously", strikethrough of old text, "fixed to…" |

## Forbidden in the artifact body

| Pattern | Why it fails |
|---------|--------------|
| Diff language: "changed to", "updated to", "now uses", "instead of the previous", "was previously", "fixed", "corrected" | Narrates process, not the decision |
| Critique breadcrumbs: "after F2", "per critic", "as discussed", "addressing feedback" | Couples the doc to a transient review cycle |
| Archaeology sections: `## What changed`, `## Changelog`, Before/After tables of draft revisions | Turns the doc into a patch log |
| Dual states: keeping old and new text, strikethrough of rejected draft wording | Leaves "old door handle next to the new hole" |
| Status theater: "Revised draft", "v2 after review" as content (Status header `draft`/`approved`/`skip` is fine) | Implies the reader must know prior versions |

## Allowed (do not confuse these)

| Pattern | Why it's fine |
|---------|----------------|
| Tech-spec **Rejected alternatives** — one line each: option considered + why it lost *as a current design choice* | Decision rationale for the critic, not a draft diary |
| Rollout / migration steps that name temporary intermediate states the *system* will pass through | Forward-looking ops sequence, not "we used to plan X" |
| Chat (or a separate review reply) that lists what you changed this turn | Human verification belongs in the conversation |
| Open questions / Assumptions still pending | Current unknowns, not past mistakes |

**Rejected alternatives vs archaeology:**  
✅ `Synchronous inline CSV — rejected: timeouts under load; async job + email link chosen instead.`  
❌ `~~Synchronous GET~~ — replaced after critique F2.`  
❌ `Changed from sync GET to async job.`

## Revise protocol

1. Read the feedback (human and/or critic ids).
2. Edit the affected sections so they state only the **chosen** design/tasks.
3. Delete wording that only made sense for the discarded approach.
4. If an alternative was seriously considered and lost, add/update a one-line **Rejected alternatives** entry (specs) — never a strikethrough of the old draft paragraph.
5. In **chat**, optionally list what changed so the human can verify. Keep that list out of the file.
6. Self-check before presenting: search the file for the forbidden patterns above. If any match, rewrite that sentence as present-tense current truth.
7. After a **forced revise**, invoke skill **`trajectory-judge`**. Score `clean-revise-no-archaeology` per skill `trajectory-score` (init invocation `skill clean-decision-docs on a forced revise`).

## Rationalizations (do not use these)

| Excuse | Reality |
|--------|---------|
| "Human asked to see what changed" | Answer in chat; the file stays clean |
| "Next reviewer needs the history" | Critic report + git diff are the history |
| "Just a small 'Updated:' note" | Small notes rot and teach the next agent to leave bigger ones |
| "Rejected alternatives is the same thing" | No — it records *current* rationale, not draft archaeology |
| "I'll leave old text struck through for clarity" | Clarity is one coherent document, not two overlapping ones |

## Who uses this

- **tech-spec** agent/skill — especially on `revise` after `approve-spec`
- **approve-plan** / plan author — especially on `revise` after critic or human feedback
- Any agent writing under `docs/**/specs/` or `docs/**/plans/`
