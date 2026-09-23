# Forbidden user-facing review formats

If the report looks like any example below, **do not send it**. Rebuild with [feedback-format.md](feedback-format.md) + [evidence-gate.md](evidence-gate.md), or drop findings that lack evidence.

## Banned: executive “Verdict / Blockers” digest

This shape (any language) is a hard failure — even when the technical claims are correct:

```markdown
Verdict: request changes — PR #94 …
Coverage: main <- feature/… · … · report-only

### Blockers (P0)
1. V044 inserts SWEGON_* with organization_uuid = NULL, while CustomRoleService.findByOrganizationUuid only looks up by UUID…
2. After dropping UNIQUE(name, organization_uuid), MySQL allows duplicate system roles because NULL ≠ NULL…
3. UserService.assignUserToRole resolves via findByName without org-scope…

### Also (P1)
Missing index on organization_uuid; COMMERCIAL_CLIENT_* regression risk; …

### Draft for PR comment
F1–F5 blockers… I can post this to GitHub if you want.
```

Why it fails: **no file path, no line range, no Jump/GitHub link, no code fence.** Mentions of class/method/migration names are not locations. A peer cannot open the problem in the editor from this text.

## Banned: path-only / symbol-only bullets

```markdown
- `P0` CustomRoleService: org filter missing
- `src/…/UserService.java`: role escalation via findByName
```

## Banned: leading with Verdict, then “full report later”

Never ship a short digest first and promise the real report. The **first** (and only) user-facing review message must be the full Findings / Fixed / Clarify sections with evidence. Optional one-line Coverage header is fine; optional PR comment draft goes **after** the full findings, never instead of them.

## Required shape (minimum one finding)

```markdown
### F1 — `P0` — System roles seeded with NULL org uuid never match org lookup
- **Context:** Migration seeds default system roles for new tenants; org-scoped lookup runs on every assign.
- **What:** Migration inserts `SWEGON_*` rows with `organization_uuid = NULL`, but lookup only queries by concrete org uuid.
- **Where:**
  - File: [`src/main/resources/db/migration/V044__….sql`](src/main/resources/db/migration/V044__….sql)
  - Lines: **12–20**
  - Jump: [`…/V044__….sql:12`](src/main/resources/db/migration/V044__….sql#L12)
  - GitHub: [V044…#L12-L20](https://github.com/<owner>/<repo>/blob/<HEAD_SHA>/src/main/resources/db/migration/V044__….sql#L12-L20)
- **Why it matters:** Orgs never see the seeded roles; assign/fallback paths then hit the wrong resolver.
- **Ask / fix:** Seed with a real org uuid, or change the query to include `organization_uuid IS NULL` for system roles.

```sql
12| INSERT INTO custom_role (name, organization_uuid, …)
13| VALUES ('SWEGON_ADMIN', NULL, …);
```
```

Repeat that block for every finding. Length is expected. Compressing into a digest is not allowed.

## Banned: clarify question without file + snippet

A sequential `C#` AskQuestion (or its text fallback) that is only a title and option buttons is a hard failure — even when the report above already had evidence:

```markdown
C1 — Use existing helper?
```

Why it fails: the person answering cannot see the code or the file. Repeat File, Lines, Jump, and the numbered fence in the question itself. Title + Jump path is not enough.

## Banned: batch letter list as the ask

Never open a clarify round with only:

```markdown
Waiting for confirmation: C1: A; C2: A; C3: B; C4: A
```

or a bare “reply `C1: A; C2: B`” with no per-item body. That batch letter list is a **reply shape only**. The ask must go **one `C#` at a time**, each message carrying Context, What is wrong, When it shows up, Where, the numbered fence, Ask, and option buttons (skill `hitl-choice` Engineer-review clarify). Full words — skill `plain-language-chat`.

## Banned: truncated phase clarify handoff

A phase Task that keeps a rich private note and returns only a short `summary` / title / letter options to the parent is a hard failure. Parent merge needs full `context`, `what`, `when_shows`, `question`, `snippet`, and option labels **verbatim**. “Compact JSON upward” means structured JSON without chat transcripts — **not** truncated evidence.
