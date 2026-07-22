---
description: Run engineer-review orchestrator on the current branch diff (manual entry)
argument-hint: "[base:main|sha] [skip-hitl]"
---

# /engineer-review

Run the portable **engineer-review** flow (orchestrator `engineer-reviewer`).

## Arguments

- Optional base ref: first token like `main`, `origin/main`, or a SHA. Default: merge-base with `main`/`master`/`origin/main`.
- This command is **manual** → skip the post-plan HITL gate (user already asked for review).

## Steps

1. Read and follow skill `engineer-review` (`skills/engineer-review/SKILL.md`).
2. Invoke agent `engineer-reviewer` with:
   - `BASE_SHA` / `HEAD_SHA` from git
   - `mode`: find then apply unambiguous fixes
3. Emit the standard report (Fixed now / Needs clarification).
4. If clarifications remain, wait for answers like `C1: A`, then re-dispatch affected phases.

## Notes

- After finishing an implementation **plan**, do not use this command as a silent auto-start; the plan agent must ask HITL first. Once the user says `skip`/`approve`/`done`, either continue as engineer-reviewer or run this command.
- Ensure recommended stack skills are installed when possible (see skill-map). Missing skills → continue with built-in checklists and note in Coverage.
