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
3. Run `evidence-gate.md` (backfill via `scripts/extract-review-snippet.sh` or drop). Draft the full Findings template with **Context** on every item; Clarify items also **Options** + **Recommendation** — **never** a Verdict/Блокери digest. Validate with `scripts/validate-review-report.sh`; rebuild until exit 0. Then emit; `english-humanizer` then `plain-language-chat` on prose.
4. If clarifications remain, ask via skill **`hitl-choice`** preset **Engineer-review clarify** (sequential `AskQuestion` per `C#`; recommended option labeled; tokens `C1:A`; batch text like `C1: A; C2: B` OK), then re-dispatch affected phases and re-emit with the same evidence bar.
5. After the report is settled, run `review-learn` (self-strengthen) per `skills/engineer-review/references/review-learn-protocol.md`.

## Notes

- After finishing an implementation **plan**, do not use this command as a silent auto-start; the plan agent must ask HITL first. Once the user says `skip`/`approve`/`done`, either continue as engineer-reviewer or run this command.
- Ensure recommended stack skills are installed when possible (see skill-map). Missing skills → continue with built-in checklists and note in Coverage.
- Path-only, snippet-less, or Verdict/Blockers digests are a hard failure — backfill/rebuild or drop before showing the user.
