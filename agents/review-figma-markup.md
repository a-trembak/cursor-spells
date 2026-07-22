---
name: review-figma-markup
description: >-
  Frontend markup-vs-design phase for engineer-review. Ask the user for Figma
  node URLs first; use Figma MCP/skills to compare implementation to design.
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

## Output

`phase`: `"figma"`. Unambiguous class/style mismatches → apply; design intent unclear → clarify.
