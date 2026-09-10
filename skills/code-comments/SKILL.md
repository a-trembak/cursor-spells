---
name: code-comments
description: >-
  Use when writing or reviewing code comments: what to keep, what to remove,
  and when a comment is a crutch for an unclear name. Shared by developer
  agents (prevention) and engineer-review's deadcode phase (enforcement). Use
  when the user asks about comment style, when a comment names a chart,
  screen, widget, or Figma node, or when review-deadcode or a developer
  agent (including backend) needs the keep/remove taxonomy. Services forbid
  user-interface citations; React frontend may reference the user interface.
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
| In **service / backend / Java / Spring and other non-UI layers**: comments that justify a query, filter, merge, or transform by naming a screen, chart, widget, Figma node, dashboard, or other presentation detail — including a user-interface link or a user-interface example | Presentation names and links rot when the layout changes. Service-comment readers are Java, Service BI, and manager-developer audiences; they need the domain or data invariant, not "same as the chart". Restate the invariant or omit |

## Presentation vs domain

**Audience (service comments):** Java, Service BI, and manager-developer. Write domain, data, and invariants only — never screens, charts, widgets, Figma, dashboards, user-interface links, or user-interface examples.

**Services forbid:** Do not write comments in service / backend / Java / Spring (or other non-UI) code that point at a user-interface element, link, or example to explain a query, filter, merge, or transform. Backend must not say "same call as the chart" or "rows the chart already merged."

**React allow:** In React / frontend user-interface sources (`react-web` / `react-native` UI files), comments may name screens, widgets, Figma nodes, or layout when that helps the frontend reader.

If there is a real invariant in **service** code, keep that part and drop the presentation noun:

```
// Bad — tied to a chart (service example)
// Same unfiltered by-device call as the chart. Mongo exact code+ALARM misses
// suffixed codes (C61-1) and ERROR rows that the chart already merged.

// Good — data invariant only
// Unfiltered by-device fetch, then keep rows whose normalized code matches.
// Exact store match on code+ALARM misses suffixed codes (C61-1) and
// ERROR-category rows already merged into this series.
```

If the only reason in service code is how a screen looks, omit the comment.

## Preference order

Rename or simplify the code before reaching for a comment to compensate for an unclear name. A comment explaining what a poorly-named variable does is a signal to rename the variable, not evidence the comment is earning its place.

## Who uses this

- **Developer agents** (`csp-software-developer`, `csp-bug-fixer`): apply this taxonomy while writing new code — don't introduce what "Remove" lists in the first place. Services forbid presentation citations; React UI sources may reference the user interface.
- **`csp-review-deadcode`** (engineer-review phase): apply this taxonomy to classify comment findings in a diff; see `skills/engineer-review/references/auto-fix-eligibility.md` for which of these are safe to auto-apply vs. must go to `clarify`. Enforce the presentation Remove rule on service / backend / non-UI paths only.
