# Review findings

### F1 — Null user before id read

- **Context:** Session loader returns the authenticated user id for downstream checks.
- **Where:**
  - File: [`src/auth/session.ts`](src/auth/session.ts)
  - Lines: **10–14**
  - Jump: [`src/auth/session.ts:10`](src/auth/session.ts#L10)
- **What:** `user` may be null before `.id` is read.
- **Why:** Throws on logged-out refresh and breaks the shell.
- **Fix:** Return early when `loadUser()` yields null.

```ts
10|  const user = await loadUser();
11|  return user.id;
```

### C1 — Expired session UX

- **Context:** Token refresh failure currently clears state with no user-facing path.
- **Where:**
  - File: [`src/auth/session.ts`](src/auth/session.ts)
  - Lines: **40–46**
  - Jump: [`src/auth/session.ts:40`](src/auth/session.ts#L40)
- **Ask:** Should expired sessions redirect to login or show a modal?
- **Options:**
  - A — Redirect to /login (recommended)
  - B — Show re-auth modal
- **Recommendation:** A — Matches existing deep-link resume pattern.

```ts
40|  if (!token) {
41|    clearSession();
42|    return;
43|  }
```
