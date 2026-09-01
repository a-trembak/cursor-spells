# Debug evidence gate (no assumption fixes)

Mandatory gate for `bug-fix` / `bug-fixer` **before any production code change**.

A hypothesis is **not** a root cause. A plausible story is **not** verification.

---

## E1 — Reproduce with the failing context

**Required before coding:**

1. Reproduce using the **same context as the reporter** (auth claims, query params, env, data shape) — not a convenient substitute (e.g. admin token without membership when the bug is membership-scoped).
2. Record: HTTP status / test failure / stack trace / log line with **file and line** when available.
3. If reproduction fails locally but succeeds in another context, **stop** — document the context delta; do not patch.

**Anti-pattern:** curl with fleet token while the browser uses membership JWT; declaring "cannot reproduce" without explaining the context mismatch.

---

## E2 — Root cause must be evidenced, not inferred

**A fix is allowed only when at least one of these is true:**

| Evidence type | Acceptable proof |
|---------------|------------------|
| Stack trace | Points to specific method/line in the failing request |
| Failing regression test | Real stack (integration / JPA / HTTP), not Mockito-only, that fails **before** the fix |
| Debug run | Breakpoint/log at the failing line during reproduced failure |
| Deploy proof | Bug disappears **only after** a verified deploy of a change that targets the evidenced line — still document the causal link |

**Not sufficient alone:**

- "This pattern often causes NPE"
- "Review suggested hardening"
- "Similar bug was fixed elsewhere"
- Mockito spec test that stubs a different path than Hibernate/runtime
- QA still 500 but git main has a plausible fix (deploy may lag — verify deploy **or** get stack trace)

---

## E3 — One hypothesis → one verification → then fix

Workflow:

1. State **one** hypothesis (single causal chain).
2. Design the **smallest check** to confirm or falsify it (test, log, curl with correct token, DB query).
3. Run the check. **If falsified:** new hypothesis — do **not** commit a fix for the old one.
4. Only after confirmation: minimal diff + regression test that would have failed pre-fix.

**Anti-pattern:** stacking multiple defensive null-checks or query rewrites across commits without any run proving which line threw.

---

## E4 — When evidence is blocked

If you cannot obtain stack trace, deploy SHA, or reproduction:

1. **Stop** — do not open a "likely fix" PR.
2. Return a **blockers list** (exactly what is missing: log access, request-id, deploy time, Docker for integration test, etc.).
3. Optional: add **diagnostic-only** change (logging, test skeleton) in a separate commit/PR — never masked as the fix.

---

## E5 — After a fix that did not work

If a prior fix was merged and the bug remains:

1. Treat prior hypothesis as **falsified** — do not extend it with more guesses.
2. Re-run E1 with fresh evidence; compare deploy SHA vs git main.
3. Do not amend/revert blindly; prove what still throws.

**Lesson (illustration only):** multiple dashboard PRs changed Criteria correlation and null-guards while QA still returned `NullPointerException` without a stack trace — each was an assumption until deploy + trace confirmed the throwing line.
