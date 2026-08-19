# English Humanizer — Full pattern list

Patterns tuned for **bug reports, colleague messages, and PR comments**. SKILL.md has the voice and process; this file is the checklist.

## Contents

- [English / LLM tells (1–14)](#english--llm-tells)
- [Universal patterns in English (15–27)](#universal-patterns-in-english)
- [Style markers](#style-markers)
- [Full example (PR comment)](#full-example-pr-comment)
- [Full example (problem for colleagues)](#full-example-problem-for-colleagues)

---

## English / LLM tells

### 1. Throat-clearing openers

Filler that delays the point.

Markers: It's worth noting, It's important to mention, I'd like to highlight, At a high level, To put it simply, In today's…

Before: It's worth noting that the webhook handler ignores duplicate delivery IDs.
After: The webhook handler ignores duplicate delivery IDs.

### 2. Significance / marketing inflation

Everything is critical, robust, seamless, or transformative.

Markers: significant, critical role, robust, seamless, elevate, leverage synergies, game-changer, cutting-edge

Before: This is a critical enhancement that will significantly elevate our reliability posture.
After: This stops double-charging when Stripe retries the webhook.

### 3. Sycophancy / cheerleading

Praise instead of substance — especially awkward in PR review.

Markers: Great catch!, Excellent point!, Absolutely!, Really appreciate you flagging this!, Happy to help!

Before: Great catch! This is definitely an important edge case.
After: Good catch — empty `orgId` skips the authz check.

### 4. Hedge stacks

Multiple softeners that bury the claim.

Markers: might potentially, could possibly, it seems that it may, in some cases it might

Before: This might potentially cause issues in certain edge-case scenarios.
After: Concurrent refresh can overwrite the session row.

### 5. Synonym cycling / rule of three

Triplets and thesaurus spinning to avoid repetition.

Before: We should improve, enhance, and optimize the retry policy.
After: We should cap retries at 3 and add jitter.

Before: The change streamlines, simplifies, and modernizes the flow.
After: The change removes the extra round-trip to org-management.

### 6. Fake collaboration padding

Empty offer-to-help closers and emoji warmth.

Markers: Hope this helps!, Happy to dive deeper, Let me know if you want me to pair, 🙂 🚀

Before: Hope this helps! Happy to dig further if useful 🙂
After: (remove) — or one concrete offer: "I can add a repro test."

### 7. Vague authority

Appeals to unnamed research or "best practices."

Markers: studies show, industry best practice, experts agree, modern systems typically

Before: Best practices suggest we should always validate on the server.
After: Validate on the server — the mobile client can be patched.

### 8. Delve / tapestry / landscape vocabulary

Stock LLM lexicon that never appears in real eng chat.

Markers: delve into, dive deep, tapestry, landscape, realm, multifaceted, nuanced interplay, underscore

Before: Let's delve into the multifaceted landscape of our caching approach.
After: Cache invalidation races with the write path on deploy.

### 9. Nominalizations / corporate verbs

Weak verb + noun instead of a direct verb; "leverage/utilize/facilitate."

Before: We should perform an investigation into the utilization of the connection pool.
After: We should check why the pool exhausts under 50 concurrent users.

Before: This facilitates the ability to leverage existing authz headers.
After: This reuses the existing authz headers.

### 10. Not only… but also

Forced rhetorical contrast.

Before: This not only fixes the race, but also improves overall resilience.
After: This fixes the race. Side effect: fewer reconnect storms.

### 11. Copula avoidance / inflated verbs

Avoiding "is/are" with "serves as," "represents," "acts as a."

Before: This endpoint serves as a critical gateway component that facilitates…
After: This endpoint is the gateway's auth entry point.

### 12. Artificial from–to scope

Fake breadth: "from X to Y" without substance.

Before: This covers everything from strategic planning to operational execution.
After: This covers create, update, and delete for installations.

### 13. Knowledge cut-off / disclaimer padding

Unnecessary model disclaimers in peer communication.

Markers: as of my last knowledge, based on available information, I don't have access to…

Before: Based on available information, the timeout appears to be 30s.
After: Timeout is 30s in `application.yml`.

### 14. Over-polite softening (wrong register)

Customer-support politeness in peer PR/Slack.

Before: I humbly suggest we might perhaps consider revisiting this approach when you have a moment.
After: Can we revisit this? The current approach loses updates when two tabs save.

---

## Universal patterns in English

Same family as finnish-humanizer universals; English examples for eng context.

### 15. Empty optimistic ending

Before: Looking forward to unlocking exciting opportunities going forward!
After: (delete) — or a concrete next step: "I'll verify on staging after merge."

### 16. Despite challenges formula

Before: Despite these challenges, the system continues to evolve and deliver value.
After: The race remains under load; the retry patch only helps the single-instance case.

### 17. Adjective piles

Before: A modern, innovative, user-friendly, scalable solution.
After: Horizontally scalable; UI matches the existing settings screen.

### 18. Overlong sentences

Packing repro + impact + theory into one sentence.

Before: The new validator, which was introduced last week, has caused failures in production for users who have multiple orgs because the cache key omits orgId, which means stale permissions can be served, leading to 403s that are hard to debug.
After: Last week's validator causes prod 403s for multi-org users. Cache key omits `orgId`, so stale permissions get served.

### 19. Passive agency dodge (when actor matters)

Passive is fine in eng writing; fix only when it hides who/what acts and that matters for the bug.

Before: It was decided that tokens would be rotated more frequently.
After: We rotate tokens every 15 minutes (see `#security` thread).

### 20. Bullet theater

Bold labels and emoji bullets instead of sentences.

Before:
> **Impact:** high  
> **Root cause:** caching  
> **Next steps:** investigate further

After: High impact: stale cache serves old permissions. Next: confirm key format in `AuthzCache`.

### 21. Em-dash and colon sermon style

Before: The issue is clear: we must — without delay — address the underlying concerns.
After: Root cause looks like a stale cache key. Let's fix the key format first.

### 22. Rhetorical questions as filler

Before: So what does this mean for our users? It means we need to take action.
After: Users with two orgs can hit intermittent 403s.

### 23. Negative parallelism spam

Before: This isn't just a bug — it's a systemic reliability concern.
After: Same class of failure as the session overwrite on refresh.

### 24. Softening apology loops

Before: Sorry if I'm missing something obvious — feel free to ignore if this is intentional!
After: Is the missing `orgId` in the cache key intentional?

(Keep one polite hedge if the review might be wrong; drop the apology stack.)

### 25. Inflated uncertainty theater

Before: There is a non-zero chance this could conceivably surface under rare race conditions.
After: Race window is ~50ms when two saves overlap.

### 26. Template closing CTAs

Before: Please don't hesitate to reach out with any further questions or concerns.
After: (delete) — or "Ping me if the staging repro differs."

### 27. Unexplained abbreviations

Letter-clump jargon that a non-insider has to decode. Short sentences are fine; shortened terms are not.

Markers: PR, CI, HITL, AC, SHA, P0/P1, MCP, TTL, JWT, WIP, LGTM (when used as words in prose)

Before: CI failed on the PR after HITL; SHA abc is P0.
After: Continuous integration failed on the pull request after the human-in-the-loop step; commit hash abc is highest severity.

For Cursor chat with the kit owner, skill **`plain-language-chat`** is mandatory after this pass.

---

## Style markers

Not grammar errors — formatting habits common in AI output:

- **Bold overload** — Bold only what a skimming reviewer must see (symptom, file, ask).
- **Emoji** — Remove in PR comments unless the team's norm is casual.
- **Curly quotes** — Prefer straight `"quotes"` in code-adjacent text.
- **Horizontal rules / dense headings** — Fine in docs; rare in Slack/PR. Flatten if the message is short.
- **Title Case Headings** In Short Messages — usually unnecessary.

---

## Full example (PR comment)

### Before (AI-flavored)

> Great catch on this one! It's worth noting that this could potentially introduce a significant race condition in certain scenarios. At a high level, we might want to consider leveraging a more robust approach to ensure seamless consistency. Happy to dive deeper if helpful! 🚀

### After

> There's a race if two saves overlap — the second write can drop the first update. Can we key the upsert on `(installationId, updatedAt)` or add a version check? I can sketch a test if useful.

### Changes

| # | Pattern | Fix |
|---|---------|-----|
| 3 | Sycophancy | Removed "Great catch on this one!" |
| 1 | Throat-clearing | Removed "It's worth noting" / "At a high level" |
| 4 | Hedge stacks | "could potentially" → concrete race |
| 2 | Inflation | "significant" / "seamless" / "robust" removed |
| 9 | Corporate verbs | "leveraging" removed |
| 6 | Padding | Emoji + "Happy to dive deeper" → concrete offer |

---

## Full example (problem for colleagues)

### Before (AI-flavored)

> I'd like to highlight a potentially important issue in the authentication landscape. Based on available information, users may experience challenges refreshing sessions. Studies show that robust token handling is a best practice. Despite these challenges, I'm confident we can craft a seamless solution going forward. Let me know if you'd like me to delve deeper!

### After

> iOS clients get `401` on refresh after about 15 minutes even though refresh time-to-live is 24 hours. Android looks fine.  
> Suspect: gateway drops `Escloud-Authorization` on `POST /auth/refresh` (see gateway logs around 14:02 UTC).  
> Can someone on API gateway confirm? I can provide a failing Charles session.

### Changes

| # | Pattern | Fix |
|---|---------|-----|
| 1 | Throat-clearing | Removed "I'd like to highlight" |
| 8 | LLM lexicon | Removed "landscape" / "delve" |
| 13 | Disclaimer | Removed "Based on available information" |
| 7 | Vague authority | Removed "Studies show…" |
| 2 | Inflation | Removed "seamless" / "important" |
| 16 | Despite formula | Removed empty confidence close |
| — | Structure | What / evidence / ask |
