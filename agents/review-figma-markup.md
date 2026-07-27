---
name: review-figma-markup
description: >-
  Frontend markup-vs-design phase for engineer-review. Ask the user for Figma
  node URLs first; use Figma MCP/skills to compare implementation to design.
  On react-web, also run ce-test-browser to verify the rendered UI against Figma.
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

## Web browser review (`react-web` only)

When stack is **`react-web`** (browser UI — not React Native / non-web):

1. After the Figma/MCP markup pass (or once URLs exist), load and follow **`ce-test-browser`** (`everyinc/compound-engineering-plugin@ce-test-browser` — often already available via the Cursor Compound Engineering plugin).
2. Open the affected routes in a real browser; capture screenshots / inspect rendered and interactive state.
3. Compare the **rendered** result to the same Figma nodes (layout, spacing, typography, color, missing states) — not only source markup.
4. If `ce-test-browser` is missing: continue with Figma/MCP markup check only; note `skill_missing: ce-test-browser` in Coverage. Do not block the phase.
5. If the app cannot be served or no browser driver is available: keep markup findings; add residual note `browser_review_unavailable` — do not invent pixel diffs.

## Output

`phase`: `"figma"`. Include `severity`. Unambiguous `P0|P1` mismatches → apply; design intent unclear → clarify.


## Evidence (mandatory)

Every `fixed` / `clarify` item **must** include `path`, `start_line`, `end_line`, and `snippet` (exact lines of the problem). Follow `skills/engineer-review/references/phase-protocol.md` and `evidence-gate.md`. Do **not** return path-only findings.

