# Security hardening checklist (S1–S10)

Canonical gates for `csp-review-security`, and for code writers (`csp-software-developer`, `csp-bug-fixer`) when the task touches the same surfaces. Catch popular attack classes (injection, broken access control, secret leaks, and related trust-boundary mistakes) with the **same** rules on both write and review.

Do **not** hardcode product names, ticket ids, or endpoint labels. Apply the rules; examples are illustration only.

Optional enrichment: third-party skill `security-review` if installed. This kit checklist is the source of truth — do not skip S1–S10 because that skill is missing.

---

## Trigger surfaces

**Trigger:** the diff, plan, or task adds or changes any of:

- authentication, sessions, cookies, tokens, or authorization checks
- crypto / password hashing / signing
- personal data (PII) handling or retention
- SQL / NoSQL / ORM queries, raw/native SQL, Criteria, search filters built from input
- network trust boundaries (outbound fetch/proxy, webhooks, redirects)
- file upload, download, or filesystem path from input
- secret handling (env, vault, API keys) or logging near secrets
- HTML / template / markdown rendering sinks (XSS)
- deserialization of untrusted payloads

If none of these are in scope, the security phase returns `skipped: true` with `skip_reason: no_sensitive_surface`. Writers skip loading this body when the task has no matching surface.

When a trigger fires, open this full checklist and run every applicable gate below — one-line phase bullets are not enough.

---

## S1 — SQL / NoSQL injection

**When:** queries, repositories, search filters, or dynamic persistence from user/tenant input.

**Required check:**

1. No string concatenation or format-string assembly of SQL / JPQL / Cypher / Mongo filter documents from untrusted input.
2. Prefer parameterized queries, bound parameters, or safe ORM APIs (`PreparedStatement`, named params, Criteria typed paths). Flag raw/native SQL that interpolates request fields.
3. Dynamic `ORDER BY` / column names must use an allowlist, not raw client strings.
4. NoSQL: reject operator injection (`$gt`, `$where`, and similar) from parsed JSON bodies unless explicitly sanitized/allowlisted.

**Anti-pattern:** `"SELECT … WHERE id = '" + id + "'"` or building a Mongo filter by merging the request body wholesale.

---

## S2 — Command / OS / template injection

**When:** process spawn, shell, or server-side template rendering uses request or file content.

**Required check:**

1. No shell invocation with unsanitized input (`Runtime.exec`, `ProcessBuilder` with `sh -c`, backticks).
2. Prefer argument arrays without a shell; allowlist commands and paths.
3. Server-side templates must not evaluate user content as code (SSTI). Escape or disable expression evaluation for untrusted strings.

**Anti-pattern:** `sh -c "convert " + userFilename` or rendering user text in a template engine with expressions enabled.

---

## S3 — Cross-site scripting (XSS)

**When:** HTML, markdown, rich text, or DOM sinks render data that may include user or third-party content.

**Required check:**

1. Escape or sanitize untrusted content before HTML sinks (`dangerouslySetInnerHTML`, `innerHTML`, unescaped templates).
2. Prefer framework default escaping; document any intentional raw HTML and the sanitizer used.
3. Reflecting request params into pages/headers without encoding is a finding.
4. Cookie / session tokens: `HttpOnly` / secure flags where the stack owns cookie setup in the diff.

**Anti-pattern:** Rendering search query or profile bio as raw HTML with no sanitizer.

---

## S4 — Cross-site request forgery and unsafe state changes

**When:** cookie-based session mutations, form posts, or browser-initiated state-changing endpoints.

**Required check:**

1. State-changing routes (POST/PUT/PATCH/DELETE) require the project's CSRF defense or equivalent (SameSite, synchronizer token, custom header pattern already used in-repo).
2. Do not introduce cookie-auth mutations that skip the existing CSRF pattern.
3. Prefer same-origin assumptions documented by the project's auth layer; flag new cross-origin credentialed endpoints without review.

**Anti-pattern:** New cookie-session POST that changes email/password with no CSRF token and no SameSite rationale.

---

## S5 — Broken access control (AuthN / AuthZ / IDOR)

**When:** endpoints, queries, or UI actions load or mutate resources by id.

**Required check:**

1. Every resource access checks authentication **and** authorization (role/tenant/ownership) — not only "user is logged in".
2. IDs from the client (path, query, body) must be scoped to the caller's tenant/org/user before read or write (no IDOR).
3. Admin or elevated actions must not be reachable via parameter tampering alone.
4. Deny by default: missing check is a finding, not "probably fine".

**Anti-pattern:** `findById(requestId)` returning another tenant's row because only authentication was checked.

---

## S6 — Server-side request forgery and open redirects

**When:** server fetches a URL from input, proxies, webhooks, or redirects use a client-supplied location.

**Required check:**

1. Outbound HTTP from user URLs: allowlist schemes/hosts; block link-local, metadata, and internal ranges unless explicitly required and gated.
2. Redirect targets: allowlist or same-origin relative paths only — no open `?next=` to arbitrary hosts.
3. Webhook / callback URLs follow the same allowlist rules.

**Anti-pattern:** `fetch(req.query.url)` or `Redirect(request.getParameter("returnTo"))` with no allowlist.

---

## S7 — Path traversal and unsafe file upload

**When:** filesystem paths, downloads, or uploads derive from user input.

**Required check:**

1. Resolve paths under a fixed root; reject `..`, absolute paths, and null bytes.
2. Uploads: allowlist content types/extensions; do not trust client `Content-Type` alone for execution sinks; store outside the web root or with non-executable serving.
3. Download endpoints must not stream arbitrary server paths from a query parameter.

**Anti-pattern:** `new File(base, userPath)` without normalizing and verifying `startsWith(base)`.

---

## S8 — Secret and personal-data leakage

**When:** logging, errors, API responses, client bundles, or config near secrets / PII.

**Required check:**

1. No secrets (tokens, passwords, API keys, private keys) in logs, exception messages, or client-visible responses.
2. Do not commit secrets; prefer env/vault patterns already used in the repo.
3. PII in logs/errors minimized; avoid dumping full request bodies that may contain credentials.
4. Stack traces with sensitive context must not reach public clients.

**Anti-pattern:** `log.info("auth " + token)` or returning DB connection strings in an error JSON body.

---

## S9 — Insecure deserialization

**When:** binary/JSON/XML/pickle/Java serialization accepts untrusted payloads.

**Required check:**

1. Do not deserialize untrusted data with gadgets-prone serializers (Java `ObjectInputStream`, pickle, similar) without a strict allowlist.
2. Prefer data-only formats (JSON with schema validation) over executable object graphs.
3. Polymorphic type fields from the client (`@class`, `@type`) must be constrained.

**Anti-pattern:** Deserializing a request body with a general-purpose object deserializer and no type allowlist.

---

## S10 — Session overwrite after reset / probe writers

**When:** auth slice, session writers, `resetApiState`, matchers, or scope/token listeners change.

**Required check:**

1. Open [`interaction-replay-checklist.md`](interaction-replay-checklist.md) (**R2**, **R5**) and [`auth-rtk-checklist.md`](auth-rtk-checklist.md).
2. Probes / capability queries must not write shared auth state after a deliberate scope switch.
3. Walk competing subscriptions after sync `resetApiState` on scope change.

**Anti-pattern:** A menu/probe refetch that writes token/user/org and clobbers an intentional membership or view-as switch.

---

## Writer vs reviewer

| Role | Duty |
|------|------|
| `csp-software-developer` / `csp-bug-fixer` | When the task hits Trigger surfaces, load this file **before** coding and apply S1–S10 so the change does not introduce what the security phase will flag. |
| `csp-review-security` | When the diff hits Trigger surfaces, open this file and run S1–S10 independently — do not trust that writers already complied. |

Missing third-party `security-review` → proceed on this checklist; note `skill_missing: security-review` in Coverage when relevant. Never skip the phase solely because that skill is absent.
