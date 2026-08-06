# Auth / session / RTK race checklist

Specialization of [`interaction-replay-checklist.md`](interaction-replay-checklist.md) (**R2**, **R3**, **R5**, **R6**) for session writers, scope listeners, `resetApiState`, `prepareHeaders`, and membership/org token endpoints. Prefer the parent R1–R7 rules; use this file for auth-shaped detail.

## Session writers vs probes (R2)

| Kind | Role | May write auth slice? |
|------|------|------------------------|
| **Session writers** | Intentional scope/session changes (login, membership trigger mutation, org-token mutation) | Yes — full auth / `AuthenticationResponse` |
| **Probes** | Capability / menu / “still valid?” queries that happen to use similar endpoints | **No** — must not write token/user/org; must not be wired into scope-reset listeners |

List every matcher/listener that writes token/user/org into auth. Separate writers from probes explicitly. Product-specific endpoint names belong in consumer `.cursor/project-patterns.md`, not in this kit rule.

## Sync `resetApiState` on scope change (R1 + R3)

When a listener runs **sync** (or otherwise immediate) `api.util.resetApiState()` on scope/token change:

1. Name which hooks stay subscribed on the **route/shell still mounted** where the mutation fires.
2. Ask: after reset, which queries refetch immediately?
3. Do any of those fulfillments hit auth writers?
4. Cross-route shells may keep subscriptions across logical scope changes — treat as coupling; force-include them in the impact set even if unchanged.

## Token source of truth (R5)

- Does `prepareHeaders` read Redux, localStorage, or both?
- Does that match what the UI / next screen assumes after a scope switch?
- A probe refetch that writes auth will clobber intentional scope switches when headers/selectors read Redux.

## Required flow walks

When membership/org (or equivalent) token changes, walk at least the project’s intentional scope switches (document names in project-patterns), typically including view-as / impersonation, membership switch, and logout / soft-401.

## Tests (R6)

If `resetApiState`, a scope listener, or an auth `*matchFulfilled` changed: require a regression with an **active competing subscription**, not only unwrap-vs-reset ordering.

## Interaction replay (R1 / post-clarify)

Re-sim with the parent brief:

`trigger → route/shell still mounted → active subscriptions / host widgets → shared writers (auth, focus, selection) → user-visible outcome`

Do not treat a clarify answer that changes reset timing as applied until that replay is in phase notes **or** a matching competing-actor regression exists. Coverage: **R7** (`interaction_replay: auth|…`).
