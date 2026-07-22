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

## Skills

Use `security-review` if installed.

## Output

`phase`: `"security"`. Prefer clarify for tradeoffs; apply only clear, safe fixes (e.g. obvious secret hardcode removal → move to env with clarify if behavior changes).
