---
name: review-figma-markup
description: >-
  Frontend markup-vs-design phase for engineer-review. Ask the user for Figma
  node URLs first; use Figma MCP/skills to compare implementation to design.
  On react-web, also run ce-test-browser at tablet and phone widths, not
  only the desktop Figma frame.
---

You compare **frontend markup/UI** to **Figma**.

## Gate

1. If stack is not frontend (`react-web` / `react-native` / UI TS), skip: `not_frontend`.
2. If the user has not provided Figma node URLs / links, **do not guess**. Return skip `awaiting_figma_urls` and tell the orchestrator to ask the user.
3. When URLs arrive (clarifications or prompt), load Figma skills/MCP (`figma-use`, `figma-design-to-code` as available) and compare changed UI to nodes.

## Check

- Structure / hierarchy vs design
- Spacing, typography, color tokens when evident
- Missing/extra states (empty, loading, error) if present in Figma
- Do not bikeshed pixel-perfect without tokens/evidence — clarify when ambiguous
- **Narrow viewports (always-on when frontend):** load and run `skills/engineer-review/references/responsive-layout-checklist.md` (**V1–V4**) before closing. A desktop Figma frame is not sufficient. If this phase is skipped (`no figma`, awaiting URLs), `review-patterns` still owns V1–V4 — do not drop the gate.

## Web browser review (`react-web` only)

When stack is **`react-web`** (browser UI — not React Native / non-web):

1. After the Figma/MCP markup pass (or once URLs exist), load and follow **`ce-test-browser`** (`everyinc/compound-engineering-plugin@ce-test-browser` — often already available via the Cursor Compound Engineering plugin).
2. Open the affected routes in a real browser; capture screenshots / inspect rendered and interactive state.
3. Compare the **rendered** result to the same Figma nodes (layout, spacing, typography, color, missing states) — not only source markup.
4. When **V1** fired (tables, expandable cards, dialogs, overlays): resize or emulate **tablet and phone** (checklist **V2**), not only the desktop frame. Look for tablet/phone Figma nodes when they exist; if they do not, still check the rendered layout at those widths.
5. If `ce-test-browser` is missing: continue with Figma/MCP markup check plus **V2/V3 source** inspection; note `skill_missing: ce-test-browser` and Coverage `narrow_viewport: source-only` when V1 fired. Do not block the phase.
6. If the app cannot be served or no browser driver is available: keep markup findings; add residual note `browser_review_unavailable`; Coverage `narrow_viewport: source-only` when V1 fired — do not invent pixel diffs.

## Output

`phase`: `"figma"`. Include `severity`. Unambiguous `P0|P1` mismatches → apply; design intent unclear → clarify.


## Evidence (mandatory)

Every `fixed` / `clarify` item **must** include `path`, `start_line`, `end_line`, `snippet`, and `context`. Clarify items **must** include structured `options` and prefer `recommended` + `recommendation_why`. Follow `skills/engineer-review/references/phase-protocol.md` and `evidence-gate.md`. Do **not** return path-only findings.

