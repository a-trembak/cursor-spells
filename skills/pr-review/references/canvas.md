# PR Review Canvas (plugin)

Optional comprehension layer for `/pr-review`. **Do not vendor** the skill body into this kit.

## Source

Cursor plugin **PR Review Canvas** (`pr-review-canvas`) — skill id `pr-review-canvas`. Install via Cursor Plugins (Marketplace / `cursor/plugins` tree). Companion: Cursor Canvas skill (`~/.cursor/skills-cursor/canvas/SKILL.md`).

## When the orchestrator runs it

1. After PR resolve succeeds and a GitHub PR URL (or `gh`-resolvable number) exists.
2. Unless the user passed `no-canvas`.
3. **Before** phase dispatch — so the canvas orients the human while Findings stay the contractual review output.
4. Pass the **resolved PR URL** (or number) into the skill. Do not invent a local-only diff when PR resolve failed — skip canvas and note why in Coverage.

## How to run

1. Read and follow skill `pr-review-canvas` (and its canvas prerequisite).
2. Write the `.canvas.tsx` under the IDE canvases directory per the canvas skill (not into the repo).
3. Keep commentary on the canvas about **what changed and what is tricky in the diff** — do **not** replace Findings, and do not move evidence-gated What/Where/Why into the canvas alone.
4. After Findings emit, one short pointer to the canvas path/title is enough (no need to paste the whole walkthrough into chat).

## Missing plugin

If `pr-review-canvas` (or Canvas) is unavailable: continue the PR review spine unchanged; record `skill_missing: pr-review-canvas` in Coverage. Findings + validator remain mandatory.

## Out of scope

- `/engineer-review` / `/finish-plan` without a GitHub PR — no canvas step.
- `/multi-review` — per-repo PR canvas is not defined here; skip unless a single PR URL was the entry.
- Auto-posting canvas content as a GitHub PR comment.
