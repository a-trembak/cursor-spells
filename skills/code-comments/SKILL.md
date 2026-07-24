---
name: code-comments
description: >-
  Use when writing or reviewing code comments: what to keep, what to remove,
  and when a comment is a crutch for an unclear name. Shared by developer
  agents (prevention) and engineer-review's deadcode phase (enforcement). Use
  when the user asks about comment style, or when review-deadcode or a
  developer agent needs the keep/remove taxonomy.
---

# Code Comments

A comment is worth keeping only if it tells a reader something the code itself cannot.

## Keep

| What | Why |
|------|-----|
| `TODO` / `FIXME` (**never delete**, ideally with an owner/ticket ref) | Marks known follow-up work; deleting it hides the debt, it doesn't resolve it |
| Why / invariant / non-obvious constraint / security or perf trade-off | Explains intent the code can't state on its own |
| Non-obvious call-site parameter labels (`/* enabled= */ true`) when refactoring for clarity isn't feasible | Disambiguates an unclear call site without a full rename |
| Public API documentation | Communicates contract to callers who won't read the implementation |

## Remove / never write

| What | Why |
|------|-----|
| AI narrative ("Helper function that…", "Import dependencies") | Restates what the code already says; adds no information |
| Changelog-style ("previously used X, now Y") | Git history already carries this; it rots the moment the next change lands |
| Commented-out code | Dead weight; git history is the place for old versions |
| Comments that just restate the type/parameter name | Zero information beyond the signature itself |

## Preference order

Rename or simplify the code before reaching for a comment to compensate for an unclear name. A comment explaining what a poorly-named variable does is a signal to rename the variable, not evidence the comment is earning its place.

## Who uses this

- **Developer agents**: apply this taxonomy while writing new code — don't introduce what "Remove" lists in the first place.
- **`review-deadcode`** (engineer-review phase): apply this taxonomy to classify comment findings in a diff; see `skills/engineer-review/references/auto-fix-eligibility.md` for which of these are safe to auto-apply vs. must go to `clarify`.
