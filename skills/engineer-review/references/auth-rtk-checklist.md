# Auth / session / RTK race checklist

Shared reference for `review-logic`, `review-architecture`, and `review-security` when the diff touches session writers, scope listeners, `resetApiState`, `prepareHeaders`, or membership/org token endpoints. Linked from those agents — keep this file short.

## Session writers vs probes

| Kind | Examples | May write auth slice? |
|------|----------|------------------------|
| **Session writers** | `login`, `refreshMembershipTokenTrigger` (mutation), `getOrganizationToken` | Yes — full `AuthenticationResponse` into auth |
| **Probes** | Admin NONE `refreshMembershipToken` **query**, `hasRoles`, permission probes | **No** — must not write token/user/org into auth; must not be wired into scope-reset listeners |

List every matcher/listener that writes token/user/org into auth. Separate writers from probes explicitly.

## Sync `resetApiState` on scope change

When a listener runs **sync** `api.util.resetApiState()` on scope/token change:

1. Name which hooks stay subscribed on the **route where the mutation fires** (e.g. still on `/admin` during view-as before navigate).
2. Ask: after reset, which queries refetch immediately?
3. Do any of those fulfillments hit auth writers?
4. Cross-route shells (e.g. `AppNavigation` on `/admin`) may keep subscriptions across logical scope changes — treat as coupling.

## Token source of truth

- Does `prepareHeaders` read Redux, localStorage, or both?
- Does that match what the UI / portal assumes after a scope switch?
- A probe refetch that writes auth will clobber view-as / membership switches when headers read Redux.

## Required flow walks

When membership/org token changes, walk at least:

- View-as organization
- Membership switch
- Logout / soft-401

## Tests

If `resetApiState`, a scope listener, or an auth `*matchFulfilled` changed: require a regression with an **active competing subscription** (e.g. admin NONE refresh query still subscribed across `getOrganizationToken`), not only unwrap-vs-reset ordering.

## Interaction replay (post-clarify)

When a HITL answer changes reset timing, listener effects, or auth matchers, re-sim with:

`route_at_fire → active_subscriptions → session_writers → post_navigate_scope`

Do not treat the clarify answer as applied until that replay is in phase notes **or** a matching regression test exists.
