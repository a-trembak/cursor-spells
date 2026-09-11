# Output schema

Emit user-facing markdown per [feedback-format.md](feedback-format.md) and [evidence-gate.md](evidence-gate.md). Reject [forbidden-formats.md](forbidden-formats.md).

Every Fixed / Clarify / Findings item must include **Context**, the full **Where** block (File + Lines + Jump links), a **numbered code fence**, and What/Why/Ask-or-fix prose through **`english-humanizer`** then **`plain-language-chat`**.

Every Clarify item must include **Options** (each choice labeled; recommended marked with `(recommended)` when set) and a **Recommendation:** line (`A — why` or `none — pick based on product intent`).

If evidence is incomplete after backfill with `$KIT/scripts/extract-review-snippet.sh`, **drop** that item — do not show a path-only finding. Do not invent `recommended` when the phase left it null.

**Never** emit a Verdict / Blockers / Блокери executive digest. Run `$KIT/scripts/validate-review-report.sh` on the draft; only show the user when it exits 0.

If **Needs clarification** is non-empty, after the validated report ask via skill **`hitl-choice`** preset **Engineer-review clarify** (sequential AskQuestion per `C#` required; recommended option labeled). Each sequential `C#` question repeats that item’s **Where** block and numbered code fence. Text only after failed/missing tool:

> Prefer the buttons for each `C#` (one question at a time). Or reply in one message like `C1: A; C2: B` (or free text). I will re-run the affected phases and apply agreed fixes.
