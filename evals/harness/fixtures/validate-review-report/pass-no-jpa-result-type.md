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

## Coverage

- `graphify: absent`
