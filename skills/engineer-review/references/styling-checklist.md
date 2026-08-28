# Styling checklist (inline layout vs styled)

Use when the **patterns** phase reviews a diff that touches UI components, especially React + MUI.

## When to run

Run on every touched `.tsx` / `.jsx` file when **either**:

- the file already defines one or more `styled(...)` layout wrappers (`Styled*`, `*Wrap`, etc.), or
- `.cursor/project-patterns.md` states that layout uses `styled()` instead of inline `sx`.

Skip generated files, Storybook-only fixtures, and test helpers unless they ship to production UI.

## S1 — No new inline layout in styled-first files

**Rule:** When a file uses `styled()` for layout, new layout in the same diff must be a named `styled()` component — not inline `sx` or Box layout props.

**Flag as `fixed` (auto-eligible pattern violation):**

- `<Box sx={{ display: …, flex…, gap…, minWidth… }}>` added or extended in a file with existing `styled()` wrappers
- `<Box display="flex" flexDirection="…" gap={…} minWidth={…}>` (or equivalent shorthand layout props) added in the same situation
- Extending an existing inline `sx` object with layout keys (`display`, `flex*`, `gap`, `minWidth`, `width`, `align*`) instead of extracting/updating a styled component

**Do not flag:**

- One-off `sx` on leaf elements when the file has no `styled()` convention and project patterns allow `sx`
- Theme/token props on Typography (`color`, `variant`, `ml` tied to conditional icon spacing) when not structural layout
- `sx` passed into a shared component prop when that component's contract requires it

**Fix shape:** Extract a `Styled*` (or file-consistent prefix) near other styled definitions; move layout keys there; replace the inline Box.

## S2 — Match existing styled naming and tokens

When S1 fires, the replacement should:

- Live alongside other styled definitions at the bottom of the file (or the file's established styled block)
- Reuse theme spacing tokens (`theme.spacing("spacingXl")`, `theme.spacing(1)`) when sibling styled components do
- Keep responsive rules in the styled block, not split across inline `sx` and styled

## Evidence

Every finding needs `path`, `start_line`, `end_line`, `snippet`, and `context` per `phase-protocol.md`.
