# Figma markup checklist (F1–F7)

Canonical gates for `review-figma-markup`. Catch **eyeball skip**: the rendered screen (or JSX) looks “close enough” to Figma, so the phase never checks tokens, auto-layout numbers, DOM vs frame hierarchy, or empty/placeholder treatment.

Do **not** hardcode product widgets. Apply the rules; examples are illustration only.

Load this file **every** figma-phase run once node URLs exist. A `learned_hints` one-liner is not a substitute.

---

## F1 — Extract design facts first

**Trigger:** user pasted Figma node URLs (or they arrived in clarifications).

Before judging the diff, pull from the node (Figma MCP / `get_design_context` / plugin API — not memory):

- Frame hierarchy (tabs, group headers, tables/lists, footers)
- Auto-layout: padding, gap / item spacing, alignment, fill vs hug
- Text styles and color / radius / effect variables
- Component instances (tabs, badges, buttons, empty placeholders)

Closing on a vibe screenshot without this extract is an incomplete review. Ambiguous detached frames → `clarify`, not a silent pass.

---

## F2 — Tokens over hex closeness

Map each visible color, type size/weight, radius, and space to a **named** project token / theme variable / spacing scale.

- A placeholder or empty value (`--`, `—`, `N/A`, muted dashes) using brand / link / accent color instead of muted / secondary is a **P1** token miss — **not a nit**.
- “Hex is close” or inherited `color` from a parent link/button is not a pass.
- Spacing that disagrees with the extracted auto-layout gap/padding (stacked groups, row padding, header-to-meta) is in scope when the number is readable from Figma.

1px / hairline diffs with **no** token and **no** auto-layout number → drop or `P2` residual only if evidence still exists. Do not use that exception to skip F2 token misses.

---

## F3 — Structure / hierarchy

Figma frames vs DOM:

- Tab strip vs tab panels
- Accordion / group header vs nested table or list
- Column count; header label vs cell alignment (especially numeric columns)
- Stacked group spacing from itemSpacing — extra outer margin between groups is a structure miss when Figma has a single gap

Extra wrappers that change spacing, missing columns, or a grid implemented as unaligned flex are **P1**. Layer-name similarity (`Installation name` text in JSX) is not structure evidence.

---

## F4 — States in the node

Empty, loading, error, overflow / wrap, expanded vs collapsed: if the node or its variants show them, markup must match.

Wrong empty-cell treatment is in scope even when the happy path looks fine. A two-line name that blows row height vs the Figma wrap rule is F4, not “content data”.

---

## F5 — Design-system components

If the project already has tab, badge, button, accordion, or table primitives that match the Figma component, custom markup is a figma/patterns miss → `clarify` unless the primitive is a drop-in with the same tokens.

Do not accept a one-off pill/tab that only resembles the library control.

---

## F6 — Rendered evidence (`react-web`)

Source-only review is incomplete on web.

1. After F1, follow `ce-test-browser` (or equivalent) on the affected route.
2. Compare the **rendered** screenshot to the same Figma node for F2–F5 — not only class names in JSX.
3. If the skill or browser is missing: keep F1–F5 on source + Figma MCP; set coverage `source-only`; note `skill_missing: ce-test-browser` or `browser_review_unavailable`. Do not invent pixel diffs.
4. React Native / no browser: screenshot or simulator capture if available; otherwise F1–F5 on source + Figma, coverage `source-only`.

---

## F7 — Coverage gate

When the figma phase is in scope (frontend + URLs, not `user_said_no_figma`), engineer-review Coverage **must** include:

```text
figma_markup: compared | source-only | skipped | n/a
```

- `compared` — F1–F6 walked against Figma nodes and rendered UI
- `source-only` — F1–F5 on source + Figma; browser unavailable (incomplete; still flag readable token/structure misses)
- `skipped` — URLs were given but the checklist was not walked (treat as incomplete review)
- `n/a` — not frontend, or the user said `no figma`

Optional detail: `figma_nodes: <node-id list>` for the nodes actually opened.

---

## Severity

| Signal | Typical severity |
|--------|------------------|
| Named token / auto-layout number / hierarchy / empty-state / wrong library component, with Figma evidence | `P1` clarify (user-facing; auto-fix eligibility usually fails unless one obvious token class) |
| Figma itself is detached / has no variables / two plausible layouts | `clarify`, `recommended: null` if intent is unknown |
| 1px without token or auto-layout number | drop or `P2` residual only |

Do not silent-apply visual CSS.

---

## Anti-patterns

- Closing with **looks close enough** or “pixel-perfect bikeshed” while F1 was not extracted
- Passing empty `--` / muted labels that inherited a link or accent color
- Comparing only JSX class names to Figma layer names without auto-layout numbers
- Skipping accordion / table spacing because “layout is fine”
- Treating F2–F4 as nits so they vanish into Residual notes
