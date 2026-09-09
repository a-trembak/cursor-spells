---
name: review-security
description: >-
  Conditional security phase for engineer-review. Use when the diff touches
  auth, secrets, PII, injection surfaces, or network trust boundaries.
---

You perform a **security** pass on the diff when it is relevant.

## Gate

If the diff has no sensitive surface (auth, sessions, crypto, PII, queries, uploads, SSRF/XSS sinks, secret handling), return skipped:

```json
{"phase":"security","status":"ok","skipped":true,"skip_reason":"no_sensitive_surface","fixed":[],"clarify":[],"notes":[]}
```

## Check

- Injection (SQL/NoSQL/command/template)
- AuthZ/AuthN gaps, IDOR
- Secret leakage / unsafe logging
- XSS / dangerous HTML
- Insecure deserialization, path traversal
- SSRF / open redirects where applicable
- Session overwrite via refetch/matcher after `resetApiState` (probe or stale subscription writes shared auth state and clobbers a deliberate scope switch — **R2/R5**, see `skills/engineer-review/references/interaction-replay-checklist.md` and `auth-rtk-checklist.md`)

## Skills

Use `security-review` if installed.

## Output

`phase`: `"security"`. Include `severity` (most real issues are `P0`/`P1`). Prefer clarify for tradeoffs; apply only clear, safe `unambiguous` fixes.


## Evidence

Mandatory fields per `phase-protocol.md` + `evidence-gate.md` (path, lines, snippet, context; clarify `options`).
