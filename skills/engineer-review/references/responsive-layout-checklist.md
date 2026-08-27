# Responsive layout checklist (V1–V4)

Canonical gates for `review-figma-markup` and `review-patterns`. Catch **desktop-only layout review**: a dense table, expandable card, or overlay looks fine at desktop width or on the desktop Figma frame, but collides, clips, or overflows from tablet down to phone.

Do **not** hardcode product widgets. Apply the rules; examples are illustration only.

`review-figma-markup` skipped (`no figma`, awaiting URLs, not frontend) does **not** waive these gates. `review-patterns` still runs V1–V4 on frontend diffs.

---

## V1 — Trigger surfaces

**Trigger:** the diff adds or changes any of:

- data tables, column sets, or hide-on-narrow / breakpoint column flags
- expandable / accordion cards with nested content
- dialogs, drawers, popovers, modals, or other overlays

If none of these are in the diff (and not a force-included overlay host for the same UI), skip: Coverage `narrow_viewport: n/a`.

A nested table inside an expander inside an overlay is a **force-include** for V2–V3 even if the overlay file is unchanged.

---

## V2 — Tablet and phone, not only desktop

Before closing the UI / markup pass:

1. Check **tablet** and **phone** widths — not only the desktop Figma frame or a maximized desktop browser.
2. If Figma includes tablet or phone nodes, compare those too. If it only has desktop, still verify rendered layout (or source breakpoints) at narrower widths. A missing Figma frame is not a skip.
3. **`react-web`:** resize or emulate tablet (~768–1024 CSS px) **and** phone (~375–430 CSS px), or the project's documented breakpoints. One desktop screenshot is not enough.
4. **`react-native` / compact UI:** check the compact (phone) width **and** tablet/large if the app supports it.
5. Browser or device pass unavailable → inspect breakpoint / media-query / hide-column / stack / row-expander code in the diff; Coverage `narrow_viewport: source-only`. Do not treat that as a full visual pass.

---

## V3 — Compact-table and overlay chrome

When V1 fired:

- Reuse existing project patterns for dense data at narrow widths: hide columns, stack cells, or row expanders. Do not keep a full desktop column set on tablet or phone.
- Flag: too many columns still visible at the narrow breakpoint; header or title colliding with the expand control; borders, shadows, or nested tables clipped by dialog / overlay overflow.

---

## V4 — Coverage gate

When V1 fired, engineer-review Coverage **must** include:

```text
narrow_viewport: tablet+phone | source-only | skipped | n/a
```

- `tablet+phone` — visual (browser or device) check at both widths, or native compact + tablet
- `source-only` — breakpoint / pattern inspection only (no browser or device)
- `skipped` — V1 in scope but neither visual nor source check (incomplete review; prefer clarify)
- `n/a` — V1 not in scope
