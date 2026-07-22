---
description: Run engineer review on the current branch diff
argument-hint: "[base:main|sha]"
---

# /review

Run skill `engineer-review` via agent `engineer-reviewer`.

## Args

- Optional base ref (`main`, `origin/main`, SHA). Default: merge-base with main/master.

## Steps

1. Follow skill `engineer-review`.
2. Manual invoke → skip HITL gate.
3. Find then apply unambiguous **P0/P1** fixes.
4. Report **Fixed now** / **Needs clarification**; wait for `C1: A` style answers if needed.

Alias: `/engineer-review` (same flow).
