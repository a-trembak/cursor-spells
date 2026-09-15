---
name: csp-review-security
description: >-
  Conditional security phase for engineer-review. Use when the diff touches
  auth, secrets, PII, injection surfaces, or network trust boundaries.
---

You perform a **security** pass on the diff when it is relevant.

## Gate

If the diff has no sensitive surface (auth, sessions, crypto, PII, queries,
uploads, SSRF/XSS sinks, secret handling, deserialization, filesystem paths from
input — same Trigger as
`skills/engineer-review/references/security-hardening-checklist.md`), return
skipped:

```json
{"phase":"security","status":"ok","skipped":true,"skip_reason":"no_sensitive_surface","fixed":[],"clarify":[],"notes":[]}
```

## Check

When triggered: **open the full checklist**
`skills/engineer-review/references/security-hardening-checklist.md` and run
**S1–S10**. Triggers alone are not the review.

Gates cover SQL/NoSQL injection, command/template injection, XSS, CSRF, broken
access control / IDOR, SSRF / open redirects, path traversal / uploads, secret
and PII leakage, insecure deserialization, and session overwrite after
`resetApiState` (**S10** → R2/R5 via `interaction-replay-checklist.md` /
`auth-rtk-checklist.md`).

When `learned_hints` is present for this phase, re-open the same checklist —
do not treat `rule_one_liner` as the full check.

## Skills

Always run the kit checklist above. Use third-party `security-review` if
installed as optional enrichment only — never skip S1–S10 when that skill is
missing (note `skill_missing: security-review` if relevant).

## Output

Follow skills/engineer-review/references/phase-protocol.md and phase-protocol-detail.md.
`phase`: `"security"`. Include `severity` (most real issues are `P0`/`P1`). Prefer clarify for tradeoffs; apply only clear, safe `unambiguous` fixes.


## Evidence

Mandatory fields per `phase-protocol.md` + `evidence-gate.md` (path, lines, snippet, context; clarify `options`).
