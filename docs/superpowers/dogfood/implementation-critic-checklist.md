# Implementation-critic dogfood fixture

Manual checklist to verify the critic behaves. Do not require CI to execute agents.

## Setup

Create a deliberately flawed plan file at `docs/superpowers/plans/2099-01-01-fixture-notification-plugin.md`:

````markdown
# Notification Plugin System Implementation Plan

**Goal:** Add an email notification when a user completes onboarding.

**Architecture:** Build a generic, pluggable notification-channel registry (email, SMS, push, webhook) with a strategy pattern, a config-driven channel loader, and a queue-backed dispatcher, so any future channel can be added without code changes.

**Tech Stack:** Node.js, MySQL

## Global Constraints
- None specified.

---

### Task 1: Add `notifications` and `notification_channels` tables

**Files:**
- Create: `db/migration/20990101_add_notifications.sql`

- [ ] **Step 1: Write migration**

```sql
CREATE TABLE notification_channels (id INT PRIMARY KEY, type VARCHAR(50));
CREATE TABLE notifications (id INT PRIMARY KEY, channel_id INT, payload JSON);
```

- [ ] **Step 2: Run migration against dev DB**

### Task 2: Build the channel registry and strategy interface

**Files:**
- Create: `src/notifications/ChannelRegistry.ts`
- Create: `src/notifications/EmailChannel.ts`

- [ ] **Step 1: Implement `ChannelRegistry` with dynamic strategy loading**
- [ ] **Step 2: Implement `EmailChannel` sending the onboarding email**
````

This fixture deliberately has:
- A generic multi-channel plugin architecture for a single, immediate requirement (email only) — Pass A YAGNI / simpler-alternative violation.
- A new-table migration with no rollback/down-migration step and no mention of how it relates to the existing `users`/`onboarding` tables it must join against — Pass B risk-coverage and soundness violation.
- No test tasks anywhere in the plan — Pass B should-fix.

## Expected critic behavior

| Check | Expect |
|-------|--------|
| Pass A | `must-fix` — plan builds a generic multi-channel registry for a single required channel (email); a simpler alternative (a single `sendOnboardingEmail` function/service) satisfies the same goal |
| Pass B | `must-fix` — migration has no rollback/down-migration step and doesn't name how `notification_channels`/`notifications` relate to the existing `users`/`onboarding` tables |
| Pass B | `should-fix` — no test tasks anywhere in the plan |
| Coverage | Notes `skill_missing` for `pass_a`/`pass_b` if `plan-reviewer`/`project-verify-plan` are not installed, and still produces the findings above via the built-in fallback checklist from `references/lenses.md` |
| Verdict | `blocked` (at least one must-fix open) |
| Report format | Matches `skills/implementation-critic/references/output-schema.md` exactly — Coverage, Must-fix, Should-fix, Accept-risk candidates, Verdict |
| No plan edits | `docs/superpowers/plans/2099-01-01-fixture-notification-plugin.md` is byte-identical before and after the run |

## Cleanup

Delete the fixture plan file after the dogfood run:

```bash
rm docs/superpowers/plans/2099-01-01-fixture-notification-plugin.md
```
