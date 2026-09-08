---
name: update-docs
description: >-
  Use after engineer-review (or when the human asks to update product docs) to
  ask where documentation should land — skip, docs/ markdown in the current
  repo, a separate docs repository, or Confluence — then write dual-audience
  product docs (user + engineer). Prefer this over dumping the tech spec into
  README or inventing a docs destination.
---

# Update Docs

Post-review HITL gate for **product / internal documentation** that a human can read — not the kit's tech-spec or plan files. Destination is always a human choice.

## When to Use

- End of `/start-task` after engineer-review (or multi-repo-supervisor) finishes
- Human asks to document what just shipped
- Not a substitute for `tech-spec`, `clean-decision-docs`, or `ce-compound` (solutions/learnings) — those stay separate

## Related skills (composition)

| Skill | Role here |
|-------|-----------|
| **`hitl-choice`** | Destination picker (buttons / typed tokens) |
| **`english-humanizer`** | Prose pass on engineer-facing sections |
| **`ce-compound`** (optional, third-party) | Durable *solved-problem* write-ups in `docs/solutions/` — offer only when the session produced a reusable learning, not for ordinary feature docs |
| **`ce-explain`** (optional, third-party) | Visual teaching artifact for the human's own learning — **not** a product-docs destination |
| **`ce-promote`** (optional, third-party) | Launch/announcement copy — different job; do not mix into the product doc body |

Load **`references/writing-guide.md`** before drafting.

## Steps (mandatory order)

1. **Resolve plan path.** Argument, plan referenced in this session, or ask. Required — do not write a bare `pending` line.

2. **Write marker** in the **current project** (not the kit):

   ```bash
   # Prefer (consumer project):
   #   source scripts/pipeline-gates.sh
   #   pg_write_gate "$(pwd)" docs-gate "<plan-path>"
   # Line 1 = plan path (not the word pending)
   ```

3. **Stop.** Ask the HITL gate via skill **`hitl-choice`** (AskQuestion required; text only after failed/missing tool). Preset: **Docs update destination**. Prompt/text fallback:

   > Update product docs for what shipped?
   > - `skip` — no docs this run
   > - `docs_md` — Markdown under `docs/` in the **current** repo
   > - `docs_repo` — separate documentation repository (path/URL next)
   > - `confluence` — Confluence page (space/parent or URL next)

4. Do **not** invent a destination. On picker cancel/skip-without-token, re-ask.

5. **On `skip`:**
   - `pg_clear_gate "$(pwd)" docs-gate "<plan-path>"`
   - Report that docs were skipped; end this skill (pipeline may finish).

6. **On `docs_md` | `docs_repo` | `confluence`:**
   - Keep this plan's docs-gate until the write (or explicit human abort) completes. Never delete another slug's docs-gate; HITL **Force-clear foreign gate** first if the human explicitly asks.
   - Collect free-text follow-ups in chat when needed:
     - `docs_repo` → wait for local path or clone URL (+ optional branch / folder)
     - `confluence` → wait for space key + parent page title/id, or a full page URL
     - Optional for any choice: language override, page title, "update existing page X", or a **custom style** for user docs, engineer docs, or both (path/link/paste)
   - **Style resolution (required, especially for `docs_repo` / `confluence`):** before drafting, follow `references/writing-guide.md` → Style resolution. Sample existing sibling docs / Confluence parent pages; prefer (1) human custom style for user and/or engineer, else (2) destination house style, else (3) project style files, else (4) kit default dual-audience skeleton. Never overwrite an established house template with the kit default.
   - Ground content in the shipped change: plan path, tech spec, diff/`gh pr view`, and review outcome already in context. Do not invent user-facing capabilities.
   - Draft to the resolved style (kit default only when nothing stronger applies).
   - Run an `english-humanizer` pass on engineer-facing prose (and on user-facing prose if it drifted into AI filler), without fighting the house voice (terminology and section shape stay as resolved).
   - **Publish** to the chosen destination:
     - `docs_md` — write/update the Markdown file under `docs/` (never under `docs/superpowers/` for product docs). Leave uncommitted for `propose-commit`; do not bypass the gate. Report the path.
     - `docs_repo` — work in the named docs repo; follow its existing doc style. Write/update files on disk only — **leave uncommitted**. Do **not** `git commit`, do **not** open or update a pull request from this skill. Include that docs repo (and its branch) in the handoff `repo_branch_map` so the caller runs residual skill **`propose-commit`** before `create-pr`.
     - `confluence` — use Atlassian/Confluence MCP tools when authenticated; otherwise present the final Markdown for paste and optionally stage a local draft under `docs/` marked as Confluence staging. Match space/sibling page style. Never overwrite an unrelated page.
   - `pg_clear_gate "$(pwd)" docs-gate "<plan-path>"` when the publish step finishes or the human aborts after seeing the draft.

7. **Optional compound learning:** If the run produced a durable debugging/architecture learning worth `docs/solutions/`, briefly offer `ce-compound` as a *separate* follow-up — do not block the product-docs handoff on it.

## Notes

- After publish on the **full** `/start-task` path: if intentional files remain uncommitted in **any** repo touched (product repo and/or separate docs repo), the caller must run skill **`propose-commit`** again before `create-pr`. This skill must not `git commit` in any repo to bypass the gate (leave files on disk; report paths and extend `repo_branch_map`).
- Manual `/update-docs` may run without a preceding review; still use the same HITL destination gate.
- This skill never auto-selects Confluence vs repo from heuristics — wrong destination is worse than `skip`.
- Markers live in the consumer project `.cursor/gates/<kind>/<slug>`, same as other kit gates.
- Append session ledger per skill `trajectory-score` (stage `update-docs`, gate `docs-update`).
