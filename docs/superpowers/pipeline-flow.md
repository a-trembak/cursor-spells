# Quality pipeline flow (canvas)

Canonical flowchart of `/start-task` (full + `--fast`), `/start-issue-task`, and shared finale `create-pr` — every stage, HITL gate, condition, and branch as shipped in this kit.

**Interactive canvas (click stages → detail branches):** open [`pipeline-flow.html`](pipeline-flow.html) in a browser.

Static Mermaid diagrams below are the same graph for GitHub preview and diffs.

**Legend**

| Shape / style | Meaning |
|---------------|---------|
| Stadium `([…])` | Start / end |
| Rectangle `[…]` | Automatic stage |
| Diamond `{…}` | Decision / condition |
| Trapezoid `[/…/]` | HITL gate (human must answer) |
| Hexagon `{{…}}` | Artifact / marker handoff |
| Subgraph box | Layer in time (Plan → Build → Review → Docs) |
| Thick `==>` | Happy-path sequence |
| Cross `--x` | Stop / blocked |
| Dotted `-.->` | Cycle: stay in this layer, or go **one layer back** |

`review-gate` is the HITL **after code**. Skill `/finish-plan` writes `.cursor/gates/review-gate/<slug>` and asks `skip` / `approve` / `done` / `fixes`. It does **not** reopen `writing-plans`.

Source of truth: [`commands/start-task.md`](../../commands/start-task.md), [`commands/start-issue-task.md`](../../commands/start-issue-task.md), [`commands/capture-escape.md`](../../commands/capture-escape.md), plus `jira-fetch`, `jira-transition`, `tech-spec`, `approve-plan`, `start-build`, `finish-plan`, `update-docs`, `create-pr`, `bug-fix`, `hitl-choice`, `teach-review`.

Closed-set HITL: skill `hitl-choice` **must** call AskQuestion (or alias) first; typed tokens only after failed/missing tool (rule `hitl-askquestion`).

---

## 1. Layers, sequence, and cycles

Time flows **down**. Thick arrows are the happy path. Dotted arrows are the only legal loops.

```mermaid
flowchart TB
  fetch["0 Fetch + route"]

  subgraph planLayer [Plan layer — spec and plan, no code yet]
    direction TB
    spec["tech-spec"]
    plans["writing-plans"]
    critic["approve-plan + critic"]
    spec ==> plans ==> critic
    spec -.->|"revise"| spec
    critic -.->|"revise"| plans
    critic -.->|"blocked / accept F-id"| critic
  end

  subgraph buildLayer [Build layer — write the code]
    direction TB
    startB["start-build"]
    code["software-developer"]
    startB ==> code
  end

  subgraph reviewLayer [Review layer — the plan is already executed]
    direction TB
    gate[/"review-gate"/]
    review["engineer-review"]
    gate ==>|"skip / approve / done"| review
    review -.->|"Needs clarification"| review
  end

  subgraph shipLayer [Docs and PR]
    direction TB
    docs["update-docs"]
    pr["create-pr"]
    docs ==> pr
  end

  fetch ==> spec
  critic ==>|"Verdict: clear"| startB
  code ==>|"tasks verified"| gate
  gate -.->|"fixes — back to Build, not Plan"| code
  review ==> docs
```

| Cycle | Returns to | Does not return to |
|-------|------------|--------------------|
| `revise` on tech-spec | Plan / tech-spec | Build |
| `revise` / `accept F-id` on critic | Plan / writing-plans or the same critic HITL | Build |
| **`fixes` on review-gate** | **Build / `software-developer`, then the same review-gate** | **`writing-plans`** |
| Needs clarification | Review / engineer-review | Plan |
| Docs location follow-up | Docs | Review |

`--fast` skips the Plan layer and skips `review-gate`; it still runs engineer-review. `/start-issue-task` has its own fix-plan loop, not this full Plan layer.

---

## 2. Full pipeline (end-to-end)

```mermaid
flowchart TD
  startNode(["/start-task ac-source"])
  looksJira{Looks like Jira?}
  fetch[["jira-fetch MCP"]]
  fetchFail{MCP ok?}
  stopPaste[/"Stop: paste ticket text"/]
  inProgress[["jira-transition in_progress"]]
  route{"Route"}
  hitlRoute[/"HITL Pipeline route: full / fast / issue"/]
  noAc{AC exist?}
  stopNoAc[/"Stop: writing AC out of scope"/]
  bootstrap["Bootstrap: patterns + stack detect"]
  techSpec[["tech-spec"]]
  planWrite["writing-plans"]
  approvePlan[["approve-plan + critic"]]
  startBuild[["start-build"]]
  softwareDev[["software-developer"]]
  reviewGate[/"review-gate"/]
  engReview[["engineer-reviewer or multi-repo-supervisor"]]
  updateDocs[["update-docs"]]
  createPr[["create-pr draft then HITL finale"]]
  doneNode(["PR URL + docs path"])

  startNode ==> looksJira
  looksJira -->|"yes"| fetch
  looksJira -->|"no"| noAc
  fetch ==> fetchFail
  fetchFail -->|"no"| stopPaste
  fetchFail -->|"yes"| inProgress
  inProgress ==> route
  route -->|"bug, no --fast"| issuePipe[["issue pipeline"]]
  route -->|"unknown, no --fast"| hitlRoute
  hitlRoute -->|"full"| noAc
  hitlRoute -->|"fast"| fastPipe[["fast pipeline"]]
  hitlRoute -->|"issue"| issuePipe
  route -->|"feature or --fast not-bug"| noAc
  noAc -->|"no"| stopNoAc
  noAc -->|"yes"| bootstrap
  bootstrap ==> techSpec
  techSpec ==>|"Status approved or skip"| planWrite
  techSpec -.->|"revise"| techSpec
  planWrite ==> approvePlan
  approvePlan -.->|"revise"| planWrite
  approvePlan ==>|"Verdict: clear"| startBuild
  startBuild ==> softwareDev
  softwareDev ==>|"all tasks verified"| reviewGate
  reviewGate -.->|"fixes"| softwareDev
  reviewGate ==>|"skip / approve / done"| engReview
  engReview -.->|"Needs clarification"| engReview
  engReview ==> updateDocs
  updateDocs ==>|"skip / docs_md / docs_repo / confluence"| createPr
  createPr ==>|"keep_draft / ready / *_jira"| doneNode
```

`--fast` is never auto-selected. `--fast` + classified bug → HITL **Fast vs issue** (`issue` / `stay_fast`) before the fast pipeline. Explicit `/start-issue-task` always stays on the issue path. Skill `/finish-plan` is how the orchestrator enters `review-gate` after `software-developer` returns.

---

## 3. Tech spec — modes, tiers, gate

```mermaid
flowchart TD
  entry([tech-spec start])
  entryHitl[/"HITL: human or agent"/]
  requirePlan["Require plan path or paste"]
  depthHitl[/"HITL: light or full"/]
  fullPath[["system-design pair"]]
  uncertainty{Uncertainty tier?}
  blocker[/"HITL Blocker: stop ask"/]
  decision[/"HITL Decision: options A/B/C"/]
  assumption["Log Assumption in spec"]
  writeFile{{"Write English tech-spec file"}}
  gate[/"HITL: approve-spec / revise / skip"/]
  approved["Status: approved"]
  skipped["Status: skip + reason logged"]
  reviseLoop["clean-decision-docs rewrite"]
  toPlan(["Hand off to writing-plans"])

  entry ==> entryHitl
  entryHitl -->|"human"| requirePlan
  requirePlan --> fullPath
  entryHitl -->|"agent"| depthHitl
  depthHitl -->|"light"| uncertainty
  depthHitl -->|"full"| fullPath
  fullPath --> writeFile
  uncertainty -->|"Blocker"| blocker
  blocker --> uncertainty
  uncertainty -->|"Decision"| decision
  decision --> uncertainty
  uncertainty -->|"Assumption"| assumption
  assumption --> uncertainty
  uncertainty -->|"none left"| writeFile
  writeFile ==> gate
  gate -->|"approve-spec"| approved
  gate -->|"skip reason"| skipped
  gate -->|"revise"| reviseLoop
  reviseLoop --> writeFile
  approved ==> toPlan
  skipped ==> toPlan
```

---

## 4. Approve plan → critic → build

```mermaid
flowchart TD
  planReady(["Plan exists"])
  writeGate{{".cursor/gates/plan-gate/slug"}}
  clearStale["clear this slug plan-critique-clear"]
  hitlApprove[/"HITL: approve-plan / revise"/]
  revisePlan["clean-decision-docs rewrite plan"]
  delGate["Clear this slug plan-gate"]
  writeCritique{{".cursor/gates/critique-gate/slug"}}
  critic[["implementation-critic Pass A + Pass B"]]
  verdict{Verdict?}
  writeClear{{".cursor/gates/plan-critique-clear/slug"}}
  delCritique["Clear this slug critique-gate"]
  toBuild(["start-build"])
  blockedHitl[/"HITL: revise / accept F-id"/]
  acceptIds["Accept findings; recompute Verdict"]
  stopBlocked[/"Stop: no Task 1"/]

  planReady ==> writeGate
  writeGate --> clearStale
  clearStale ==> hitlApprove
  hitlApprove -->|"revise"| revisePlan
  revisePlan --> writeGate
  hitlApprove -->|"approve-plan"| delGate
  delGate --> writeCritique
  writeCritique ==> critic
  critic ==> verdict
  verdict -->|"clear"| delCritique
  delCritique --> writeClear
  writeClear ==> toBuild
  verdict -->|"blocked or clear pending accept"| blockedHitl
  blockedHitl -->|"revise"| revisePlan
  blockedHitl -->|"accept F-id"| acceptIds
  acceptIds --> verdict
  verdict -.->|"still not clear"| stopBlocked
```

### Critic verdict rules

| Verdict | Condition | Build? |
|---------|-----------|--------|
| `clear` | No open Must-fix; no un-accepted Accept-risk | Yes → `start-build` |
| `clear pending accept` | Must-fix resolved/accepted; Accept-risk still open | No — HITL `accept F<id>` or revise |
| `blocked` | Open Must-fix remains | No — revise or `accept F<id>` |

Should-fix findings are visible but never block.

---

## 5. Start-build → software-developer

```mermaid
flowchart TD
  startBuildCmd(["start-build"])
  checkClear{".cursor/gates/plan-critique-clear/slug matches this plan?"}
  checkPending{"this slug plan-gate or critique-gate pending?"}
  stopApprove[/"Stop: run approve-plan first"/]
  stopPending[/"Stop: approval or critique still open"/]
  entryOk{Entry: spec + plan + critic clear?}
  stopEntry[/"Stop: missing gate"/]
  branchSetup["Create feature branch in every target repo"]
  skillRoute["skill-map: stack + DB + code-comments"]
  execMode{User asked executing-plans?}
  sdd[["subagent-driven-development"]]
  ep[["executing-plans separate session"]]
  verify["verification-before-completion"]
  toReviewGate(["review-gate"])

  startBuildCmd ==> checkClear
  checkClear -->|"no"| stopApprove
  checkClear -->|"yes"| checkPending
  checkPending -->|"yes"| stopPending
  checkPending -->|"no"| entryOk
  entryOk -->|"no"| stopEntry
  entryOk -->|"yes"| branchSetup
  branchSetup ==> skillRoute
  skillRoute ==> execMode
  execMode -->|"no default"| sdd
  execMode -->|"yes"| ep
  sdd ==> verify
  ep ==> verify
  verify ==> toReviewGate
```

`start-build` **must Wait for** the `software-developer` Task to return, then invoke `/finish-plan` in the parent chat. That skill **is** the `review-gate` HITL; after `skip` / `approve` / `done` it starts `engineer-reviewer`. **Fire-and-forget** dispatch is a pipeline bug: the nested Task cannot run `AskQuestion`, so review never launches.

---

## 6. review-gate → review routing

Coding is done. This gate is **not** another Plan-layer step and **not** the pipeline end. Skill `/finish-plan` writes the marker, applies `review-surface` (checkout + `SetActiveBranch` + a **draft** pull request URL to open in Cursor), asks HITL, then routes to engineer-review. `fixes` returns to `software-developer` (Build), then re-runs `review-surface` and re-asks this same gate. Later `create-pr` `mode:pipeline` (after `update-docs`) **reuses** that draft and asks Pipeline finale.

```mermaid
flowchart TD
  planDone(["Build complete — plan already executed"])
  writeReview{{".cursor/gates/review-gate/slug"}}
  surface["review-surface: checkout + SetActiveBranch + draft URL"]
  hitlFinish[/"HITL: skip / approve / done / fixes"/]
  doFixes["software-developer implements fixes"]
  delReview["Clear this slug review-gate"]
  probe["Non-mutating multi-repo probe"]
  repoCount{Changed repo count?}
  stopZero[/"Stop: no changed repos"/]
  multi[["multi-repo-supervisor"]]
  singleFrontend{Frontend stack?}
  figmaHitl[/"HITL: no_figma / have_urls"/]
  single[["engineer-reviewer"]]
  clarify[/"HITL: Needs clarification only"/]
  reviewed(["Review complete"])

  planDone ==> writeReview
  writeReview ==> surface
  surface ==> hitlFinish
  hitlFinish -->|"fixes"| doFixes
  doFixes -->|"re-run review-surface"| surface
  hitlFinish -->|"skip or approve or done"| delReview
  delReview ==> probe
  probe ==> repoCount
  repoCount -->|"0"| stopZero
  repoCount -->|">= 2"| multi
  repoCount -->|"1"| singleFrontend
  singleFrontend -->|"react-web / react-native"| figmaHitl
  singleFrontend -->|"other"| single
  figmaHitl --> single
  multi --> clarify
  single --> clarify
  clarify -.->|"C-id answers"| clarify
  clarify ==> reviewed
```

---

## 7. Update-docs destination

```mermaid
flowchart TD
  reviewDone(["Review complete"])
  writeDocs{{".cursor/gates/docs-gate/slug"}}
  hitlDocs[/"HITL: skip / docs_md / docs_repo / confluence"/]
  skipDocs["Clear this slug; no docs"]
  needLoc{Location follow-up?}
  waitLoc[/"Chat: path, URL, or Confluence space"/]
  draft["Dual-audience draft + english-humanizer"]
  publish["Publish to chosen destination"]
  clearDocs["Clear this slug docs-gate"]
  doneDocs(["Pipeline done"])

  reviewDone ==> writeDocs
  writeDocs ==> hitlDocs
  hitlDocs -->|"skip"| skipDocs
  skipDocs ==> doneDocs
  hitlDocs -->|"docs_md"| draft
  hitlDocs -->|"docs_repo or confluence"| needLoc
  needLoc -->|"yes"| waitLoc
  waitLoc --> draft
  draft ==> publish
  publish ==> clearDocs
  clearDocs ==> doneDocs
```

| Token | Meaning |
|-------|---------|
| `skip` | No product docs this run |
| `docs_md` | Markdown under `docs/` in the current repo (not `docs/superpowers/`) |
| `docs_repo` | Separate documentation repository — path/URL in chat next |
| `confluence` | Confluence page — space/parent or URL in chat next |

Writing shape: skill `update-docs` + `references/writing-guide.md`. For `docs_repo` / `confluence`, **style resolution** first (custom user/engineer style → house siblings → kit default dual-audience). Optional follow-ups: `ce-compound` for durable learnings, `ce-explain` for personal teaching artifacts — neither replaces this gate.

---

## 8. Engineer-review internals (phase graph)

```mermaid
flowchart TD
  orch(["engineer-reviewer"])
  lint[["review-lint first"]]
  parallelFind["Parallel find: logic / patterns / deadcode / simplify / architecture / performance / security? / figma?"]
  autofix{Auto-fix eligible?}
  apply["Serialize apply: lint then patterns deadcode logic arch perf security figma"]
  clarifyItem[/"clarify — never silent apply"/]
  verifyLint["Verify: re-run review-lint once"]
  merge["Merge JSON + evidence gate + validate report"]
  needsClarify{Needs clarification?}
  waitHitl[/"HITL wait for C-id answers"/]
  redispatch["Re-dispatch affected phases"]
  report(["User-facing report"])

  orch ==> lint
  lint ==> parallelFind
  parallelFind ==> autofix
  autofix -->|"all 4 tests pass + P0/P1 unambiguous"| apply
  autofix -->|"any test fails or P2"| clarifyItem
  apply --> verifyLint
  clarifyItem --> verifyLint
  verifyLint --> merge
  merge --> needsClarify
  needsClarify -->|"yes"| waitHitl
  waitHitl --> redispatch
  redispatch --> merge
  needsClarify -->|"no"| report
```

Auto-fix requires all four: deterministic check, single correct answer, no information loss, zero blast radius on data/UX. Traceability drift and migrations are always `clarify`.

After a validated engineer-review report, HITL **Teach-review miss** (`miss` / `project_secret` / `no_miss`). `miss` invokes skill `teach-review` (kit `learn/…` branch; does not merge to `main`). `project_secret` writes this project's `.cursor/review-learnings.md` only.

---

## 9. Marker state machine

Runtime markers live in the **consumer project** `.cursor/gates/<kind>/<slug>` (never the kit). Parallel tickets use different slugs; a foreign slug never blocks this plan. Stop hooks emit `followup_message` only when the current plan path is known and that slug is pending. Unknown plan path stays silent — listing every open slug auto-continues unrelated chats and cannot be cleared there. Legacy flat files (`.cursor/*.pending`, `plan-critique.clear`) migrate-on-read then delete.

```mermaid
stateDiagram-v2
  [*] --> Idle

  Idle --> PlanGate: approve-plan writes plan-gate/slug
  PlanGate --> CritiqueGate: approve-plan + critic starts
  PlanGate --> PlanGate: revise clears this slug plan-critique-clear
  CritiqueGate --> CritiqueClear: Verdict clear
  CritiqueGate --> CritiqueGate: blocked / pending accept
  CritiqueClear --> Building: start-build + software-developer
  Building --> ReviewGate: /finish-plan writes review-gate/slug
  ReviewGate --> Reviewing: skip / approve / done
  ReviewGate --> Building: fixes then software-developer
  Building --> ReviewGate: re-ask review-gate
  Reviewing --> Reviewing: Needs clarification
  Reviewing --> DocsGate: update-docs writes docs-gate/slug
  DocsGate --> [*]: skip / publish complete
  DocsGate --> DocsGate: waiting location follow-up

  note right of CritiqueClear
    plan-critique-clear/slug must match this plan path
  end note
```

| Marker | Written by | Cleared when |
|--------|------------|--------------|
| `.cursor/gates/plan-gate/<slug>` | `approve-plan` | Human replies `approve-plan` |
| `.cursor/gates/critique-gate/<slug>` | after plan approval | `Verdict: clear` |
| `.cursor/gates/plan-critique-clear/<slug>` | on `Verdict: clear` | invalidated on `revise` / re-approve |
| `.cursor/gates/review-gate/<slug>` | `/finish-plan` (`review-gate` HITL) | `skip` / `approve` / `done` |
| `.cursor/gates/docs-gate/<slug>` | `update-docs` | `skip` or publish/abort complete |

---

## 10. Standalone entry points (bypass full orchestrator)

```mermaid
flowchart LR
  writeSpec["/write-tech-spec"] --> techOnly[["tech-spec only"]]
  critique["/critique-plan"] --> criticOnly[["implementation-critic ad-hoc"]]
  approve["/approve-plan"] --> approveFlow[["approve + critic + start-build"]]
  build["/start-build"] --> buildOnly[["requires this slug plan-critique-clear"]]
  finish["/finish-plan"] --> finishFlow[["review-gate HITL then review"]]
  eng["/engineer-review"] --> reviewDirect[["skip review-gate HITL"]]
  docs["/update-docs"] --> docsFlow[["HITL destination then write"]]
  pr["/pr-review"] --> prWrap[["PR wrapper: canvas + report-only Findings"]]
  multi["/multi-review"] --> multiDirect[["multi-repo-supervisor"]]
  issue["/start-issue-task"] --> issuePipe[["Jira MCP + bug-fixer + create-pr finale"]]
  fast["/start-task --fast"] --> fastPipe[["fetch + brief + mode:fast + review + create-pr finale"]]
  escape["/capture-escape"] --> dest[/"miss vs project_secret"/]
  dest -->|miss| teachEsc[["teach-review"]]
  dest -->|project_secret| learnPipe[["review-learn capture production-escape"]]
```

`/critique-plan` alone does **not** write `plan-critique-clear/<slug>` for build — prefer `/approve-plan` so plan HITL is not skipped.

`/pr-review` resolves a GitHub PR, optionally builds a **PR Review Canvas** (Cursor plugin `pr-review-canvas`; skip with `no-canvas`), then runs the same engineer-review phases. Canvas orients the diff; validated Findings remain the review contract.

---

## 11. Fast mode (`/start-task --fast`)

```mermaid
flowchart TD
  startFast(["/start-task --fast ac-source"])
  looksJira{Looks like Jira?}
  fetch[["jira-fetch"]]
  inProgress[["jira-transition in_progress"]]
  fastVsIssue[/"HITL Fast vs issue if class bug"/]
  boot["Bootstrap"]
  brief["Short AC brief in chat"]
  exec["software-developer mode:fast"]
  review["engineer-reviewer no review-gate HITL"]
  prNode[["create-pr draft then HITL finale"]]
  doneFast(["PR URL"])

  startFast ==> looksJira
  looksJira -->|"yes"| fetch --> inProgress --> fastVsIssue --> boot
  looksJira -->|"no"| boot
  boot ==> brief ==> exec ==> review ==> prNode ==> doneFast
```

No tech-spec, writing-plans, approve-plan, critic, review-gate, or update-docs. Clarify HITL only if engineer-review needs it. `--fast` is explicit only.

---

## 12. Issue mode (`/start-issue-task`)

```mermaid
flowchart TD
  startIssue(["/start-issue-task jira-key"])
  boot["Bootstrap"]
  jira[["jira-fetch getJiraIssue"]]
  jiraFail{MCP ok?}
  stopJira[/"Stop: paste ticket text"/]
  inProgress[["jira-transition in_progress"]]
  planFix["Write fix plan"]
  critic["implementation-critic Pass A B C"]
  verdict{Verdict clear?}
  hitlCrit[/"HITL: revise or accept F-id"/]
  fixer["bug-fixer"]
  review["engineer-reviewer"]
  prNode[["create-pr draft then HITL finale"]]
  doneIssue(["PR URL"])

  startIssue ==> boot ==> jira ==> jiraFail
  jiraFail -->|"no"| stopJira
  jiraFail -->|"yes"| inProgress ==> planFix ==> critic ==> verdict
  verdict -->|"blocked or pending accept"| hitlCrit
  hitlCrit --> planFix
  verdict -->|"clear"| fixer ==> review ==> prNode ==> doneIssue
```

Always this path when `/start-issue-task` is invoked explicitly (even if type is Story). After fetch, `jira-transition` target `in_progress`. Jira comment options appear on the Pipeline finale when `jira_key` is known. `ready` / `ready_jira` run `jira-transition` target `review` only after every opened pull request is merged and continuous integration succeeded. Never `gh pr merge`.

---

## 13. Create-pr Pipeline finale

```mermaid
flowchart TD
  startPr["create-pr"]
  draft["Always draft first"]
  hitl[/"HITL Pipeline finale"/]
  keep["keep_draft"]
  ready["gh pr ready"]
  jiraC["addCommentToJiraIssue PR URL"]
  waitMerge["all PRs merged + CI success"]
  jiraRev[["jira-transition review"]]
  done(["Report PR URL"])

  startPr ==> draft ==> hitl
  hitl -->|"keep_draft"| keep --> done
  hitl -->|"ready"| ready --> waitMerge --> jiraRev --> done
  hitl -->|"keep_draft_jira"| jiraC --> done
  hitl -->|"ready_jira"| ready --> jiraC --> waitMerge --> jiraRev --> done
```

`keep_draft_jira` / `ready_jira` only when a Jira key is known. Never merge. `ready` / `ready_jira` with a key → wait until `pr_merge_ci_verdict` is `all_merged_ci_success`, then `jira-transition` target `review` (skip if already Review; report and continue on failure). `keep_draft` / `keep_draft_jira` leave the ticket In Progress.
