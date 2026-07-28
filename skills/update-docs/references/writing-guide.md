# Product documentation writing guide

Produce documentation a **product user** can follow and an **engineer** can trust. One file, two clear voices — never a dump of the PR or the tech spec.

## Audience split (required shape)

Every doc uses this skeleton unless the destination already has a stronger house template (honor that instead):

```markdown
# <Capability in user language>

## For users
What changed / what you can do now. Short how-to. Screens / steps if UI.
No service names, table names, or ticket ids unless the user sees them in the product.

## For engineers
Where it lives (services, APIs, events, flags). Contracts and edge cases.
How to verify. Rollback / compatibility notes when relevant.
Links to the tech spec / plan / PR — not a paste of them.
```

If the change is engineer-only (internal ops, no user-visible behavior), keep **For engineers** and replace **For users** with one line: "No user-facing change." Do not invent user copy.

If the change is purely user-facing with no new contracts, keep **For users** and a short **For engineers** pointer (paths, flag names) so support and on-call still find the source of truth.

## Voice

| Do | Don't |
|----|-------|
| Lead with the outcome | Open with "This document aims to…" / "In today's landscape…" |
| Concrete steps a person can do | Abstract capability lists with no action |
| Short sentences; one idea each | Nested clauses and throat-clearing |
| Name the product surface the user sees | Leak internal module names into the user section |
| Link to specs/PRs for depth | Paste the whole tech spec into product docs |
| State limits and edge cases honestly | Marketing adjectives (seamless, robust, unlock, leverage) |

Reuse skill **`english-humanizer`** patterns for the engineer section: direct, neutral, concrete. User section may be slightly warmer but still plain — no hype.

## Content rules

1. **Ground in what shipped.** Derive claims from the diff, plan, tech spec, and review outcome — never invent capabilities.
2. **One capability per page** when possible. Large launches may be a short hub page + linked pages.
3. **Current truth only.** No "previously / now / after the refactor" archaeology (same spirit as `clean-decision-docs`).
4. **Verification is part of the doc.** Engineer section must say how to confirm the change (command, UI path, or log signal).
5. **Images optional.** Prefer a clear step list over a collage of screenshots. If you attach screenshots, caption them with the step they illustrate.
6. **Language.** Match the destination's existing language when updating an existing page. New pages in this kit's pipeline default to **English** unless the human asked otherwise in the HITL follow-up.

## Destination-specific notes

### `docs/` markdown (current repo)

- Prefer `docs/<area>/<slug>.md` or the project's existing docs layout if one is obvious.
- Update an index / README TOC only when the project already maintains one.
- Do not place product docs under `docs/superpowers/` (that tree is kit/process, not product).

### Separate documentation repository

- After HITL `docs_repo`, wait for the human to name the repo path or clone URL (and optional branch / folder).
- Check out or open that repo, follow **its** contribution conventions (folder layout, PR required, etc.).
- Open or update a PR there when the human expects it; otherwise leave a committed branch and report the path.

### Confluence

- After HITL `confluence`, wait for space key + parent page (or full page URL) if not already known.
- Prefer Atlassian MCP / Confluence tools when authenticated; otherwise draft the Markdown body in chat (and optionally a local `docs/` staging file) for the human to paste.
- Never invent space permissions or overwrite unrelated pages. Update the named page or create a child under the named parent.

## Quality bar (self-check before handoff)

- [ ] A new teammate who never saw the PR can follow **For users** without asking chat.
- [ ] An on-call engineer can find the seam and verify from **For engineers** alone.
- [ ] No AI filler, no pasted tech-spec sections, no duplicate changelog archaeology.
- [ ] Destination matches the HITL choice; links resolve or are clearly placeholders the human must fill.
