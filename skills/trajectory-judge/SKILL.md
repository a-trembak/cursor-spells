---
name: trajectory-judge
description: >-
  Nested-Task judge for invented business facts and decision-doc archaeology.
  Use from tech-spec and clean-decision-docs after a spec or plan file is
  written or revised, before trajectory-score. Never implements code. Never
  replaces hard-sensor score.
---

# Trajectory judge

A **separate instance** from `csp-software-developer`. Reads named spec/plan files and reports whether forbidden trajectory actions occurred. Writes `actions_taken` on the ledger, then the caller **re-scores** with hard sensors. This judge never replaces `python3 scripts/trajectory-cases.py score`.

## When to Use

- Skill `tech-spec` after the spec file exists (especially case `tech-spec-no-invented-facts`)
- Skill `clean-decision-docs` after a revise rewrite (case `clean-revise-no-archaeology`)
- Not for diffs, tests, or engineer-review

## Dispatch

Invoke agent **`csp-trajectory-judge`** as a **nested Task**. Do **not** dispatch `csp-software-developer`, `csp-bug-fixer`, or `csp-engineer-reviewer` for this job. Wait for the Task to return.

Pass: absolute paths of the spec and/or plan files just written, plus the acceptance criteria text (or ticket `ac_text`) actually given this turn.

## What to detect

| Action | Fail when the file… |
|--------|---------------------|
| `invent-business-facts` | States product rules, formats, limits, or fields that are **not** in the given acceptance criteria / ticket / human answers this turn, and were **not** asked as Blocker/Decision questions |
| `archaeology-in-decision-docs` | Uses forbidden `clean-decision-docs` patterns: “changed to”, “was previously”, What-changed / Changelog sections, strikethrough of old draft text, “after F2”, dual old+new wording |

Quote the exact file line before recording a hit. If neither action is present, return `clean`.

## After the Task returns

1. Resolve kit and ledger per skill `trajectory-score`.
2. If the judge reported `invent-business-facts` and/or `archaeology-in-decision-docs`: `record action` each id on the current slice ledger (init that ledger first when scoring `tech-spec-no-invented-facts` or `clean-revise-no-archaeology`).
3. Run `score`. A hit must `FAIL` those cases (they forbid those actions). Follow Trajectory fail on `FAIL`.
4. If not scoring those slices (different AC / not a revise) but the judge still reported a hit: **stop**, print the quoted lines, ask **Trajectory fail**. Do not continue the pipeline with invented facts or archaeology in the file.
5. If the judge returned `clean`, continue. Hard sensors still run at the wired stop.

## Hard rules

- Never edit the spec/plan in this Task (the caller rewrites via `clean-decision-docs` if the human chooses `revise`).
- Never invent acceptance criteria to make the spec look complete.
- Never treat a `PASS` from this judge as a substitute for `trajectory-cases.py score`.
