# Output schema

Emit user-facing markdown per [feedback-format.md](feedback-format.md) — **not** a bare path:summary bullet list.

Every Fixed / Clarify / Residual item must include:

- **What / Where / Why / Ask-or-fix**
- A **code snippet** (3–15 lines)
- A clickable `` [`path:line`](path) `` (and GitHub blob link when `HEAD_SHA` + remote are known)
- Prose run through **`english-humanizer`** (or its engineer-voice rules if the skill is missing)

See [feedback-format.md](feedback-format.md) for the full template, phase-JSON mapping, and anti-patterns.

If **Needs clarification** is non-empty, end with:

> Reply with answers like `C1: A` (or free text). I will re-run the affected phases and apply agreed fixes.

After the follow-up apply round, re-emit the same format with an updated Fixed now section and cleared/remaining clarifications.
