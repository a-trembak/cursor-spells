# Fix: service comments must not cite the user interface

**Goal:** Stop developer and review agents from writing or keeping comments in **service / backend** code that name, link, or exemplify user-interface surfaces. Allow presentation-oriented comments in **React / frontend** UI code. Readers of service comments are Java, Service BI, and manager-developer audiences who need domain and data invariants — not screens or charts.

**Bug source:** Pasted chat description (no Jira key). Agents keep tying service comments to the user interface despite `skills/code-comments/SKILL.md`.

## Reported failure

- Service / Java / backend comments still mention charts, screens, widgets, Figma, user-interface links, or user-interface examples.
- The intended split is ignored: **React frontend** may reference the user interface in comments; **services** must not.

## Reproduction

1. Read `skills/code-comments/SKILL.md` Remove row and «Presentation vs domain» — wording forbids presentation-tied comments and says the ban **applies on every stack**, including backend.
2. Read `skills/software-developer/SKILL.md` Hard rules / Comments and `agents/csp-software-developer.md` — both say **every stack** must never name chart/screen/widget/Figma.
3. Read `scripts/tests/code-comments-test.sh` — asserts keywords exist, but does **not** assert a React-allowed / services-forbidden split, audience (Java / Service BI / manager-developer), or ban on user-interface links and examples in services.
4. Observed agent behavior: service diffs still get comments justified by presentation nouns or links; contract tests stay green because they only check that forbid keywords exist somewhere in the skill text.

## Hypothesized root cause

Two distinct faults:

1. **Service compliance miss** — the existing backend forbid is soft and incomplete: no named service-comment audience (Java / Service BI / manager-developer), no explicit ban on user-interface **links** or **examples**, and contract tests only grep for `chart` / `screen|widget|Figma` / `backend`. Agents ignore the forbid and the suite stays green.
2. **Missing React exception** — the same text scopes the ban as **every stack**, so React / frontend UI code is incorrectly covered. The human requires presentation comments to be **allowed** in React UI sources and **forbidden** only in services / backend / non-UI layers.

## Proposed minimal fix

1. **Canonical policy** — edit `skills/code-comments/SKILL.md`:
   - State audience for service comments: Java, Service BI, manager-developer; domain / data / invariants only.
   - **Forbid** in service / backend / Java / Spring and other non-UI layers: user-interface links, user-interface examples, screen / chart / widget / Figma / dashboard names used as the reason for a query, filter, merge, or transform. Restate the data invariant or omit.
   - **Allow** in React / frontend user-interface sources (`react-web` / `react-native` UI files): comments that name screens, widgets, Figma nodes, or layout when that helps the frontend reader.
   - Replace «applies on every stack» / «not a frontend-only rule» with this stack split. Keep the bad/good invariant rewrite example as a **service** example.
2. **Prevention mirrors** — one-line stack split in `skills/software-developer/SKILL.md`, `agents/csp-software-developer.md`, `skills/bug-fix/SKILL.md`, `agents/csp-bug-fixer.md` (load `code-comments`; services forbid presentation; React UI may reference it).
3. **Enforcement** — `agents/csp-review-deadcode.md`: classify presentation-tied comments as Remove (or clarify when mixed with an invariant) only on **service / backend / java-spring / non-UI** paths. Do **not** flag presentation nouns as this-policy violations under `react-web` / `react-native` UI sources solely for naming the user interface. State that gate in the agent text (stack labels + UI vs non-UI), not an invented path-glob table.
4. **Regression contract** — extend `scripts/tests/code-comments-test.sh` so green requires: service ban language (including links/examples), React/frontend allow language, audience tokens (`Java`, `Service BI`, `manager-developer`), developer skill+agent mirrors, **bug-fix skill + bug-fixer agent** mirrors, and deadcode stack-scoped enforcement phrasing.
5. **Eligibility** — edit `skills/engineer-review/references/auto-fix-eligibility.md` so the Yes row for presentation-only screen/chart/Figma comments applies to **service / backend** comments; frontend presentation comments are out of scope for that auto-remove.
6. **README** — update the `code-comments` Skills-table row to state services-forbid / React-allow (not «including backend» alone).

## Regression / blast radius

| Surface | Risk | Safeguard |
|---------|------|-----------|
| React UI comments that name screens/Figma | False-positive remove in review | deadcode gated to service/backend/java-spring/non-UI; React UI sources excluded |
| Service comments that still say «same as the chart» | Policy miss | stronger taxonomy + contract greps including bug-fix mirrors |
| Mixed invariant + chart in a service comment | Silent delete loses invariant | existing clarify path stays |
| README / eligibility drift | Stale «every stack» or unscoped Yes row | mandatory edits in Tasks 3–4 |

## Test plan (must fail before fix, pass after)

1. Extend `bash scripts/tests/code-comments-test.sh` with asserts for:
   - service/backend forbid of user-interface links/examples/presentation nouns;
   - React/frontend allow of presentation references;
   - audience phrasing (`Java`, `Service BI`, `manager-developer`);
   - developer skill + agent stack-split mirrors;
   - bug-fix skill + bug-fixer agent stack-split mirrors;
   - deadcode enforcement scoped to service/backend/non-UI (and not treating React UI presentation nouns as this remove target);
   - eligibility row scoped to service comments;
   - README row carrying the services-forbid / React-allow split.
2. Before editing policy files, those new asserts must fail; after the wording changes, the script must print `ALL PASS`.

## Rejected alternatives

- Ban presentation comments on every stack, including React — rejected: human clarified React frontend may cite the user interface.
- Rely on chat reminders only — rejected: agents already ignore soft wording; need canonical skill + contract test.
- Auto-delete any comment containing «chart» in any file — rejected: false positives on React UI and mixed invariant comments; clarify path must remain for mixed service comments.
- Path-glob-only deadcode gate without stack labels — rejected: kit already routes via `react-web` / `react-native` / `java-spring`; state stack + UI vs non-UI in the agent text.

## Implementation tasks

### Task 1: RED — extend `code-comments-test.sh`

Add failing asserts for the stack split, audience, service link/example ban, developer mirrors, bug-fix/bug-fixer mirrors, deadcode scope, eligibility service scope, and README split.

### Task 2: GREEN — update `skills/code-comments/SKILL.md`

Rewrite Remove row + Presentation section for services-forbid / React-allow + audience.

### Task 3: GREEN — mirror prevention, review, eligibility, README

Update software-developer skill + agent, bug-fix skill + agent, `csp-review-deadcode.md`, `auto-fix-eligibility.md` (mandatory service scope on the presentation Yes row), and the README `code-comments` row.

### Task 4: Verify

Re-run `bash scripts/tests/code-comments-test.sh` → `ALL PASS`. Spot-check greps for leftover unscoped «every stack» ban language that contradicts the React exception.
