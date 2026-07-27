# Output schema

Emit user-facing markdown per [feedback-format.md](feedback-format.md) and [evidence-gate.md](evidence-gate.md) — **not** a bare path:summary bullet list.

Every Fixed / Clarify item must include the full **Where** block (File + Lines + Jump links), a **numbered code fence**, and What/Why/Ask-or-fix prose through **`english-humanizer`**.

If evidence is incomplete after backfill with `scripts/extract-review-snippet.sh`, **drop** that item — do not show a path-only finding.

If **Needs clarification** is non-empty, end with:

> Reply with answers like `C1: A` (or free text). I will re-run the affected phases and apply agreed fixes.
