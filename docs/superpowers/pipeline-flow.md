# Quality pipeline flow (canvas)

Canonical flowchart of `/start-task` — every stage, HITL gate, condition, and branch as shipped in this kit.

**Legend**

| Shape / style | Meaning |
|---------------|---------|
| Stadium `([…])` | Start / end |
| Rectangle `[…]` | Automatic stage |
| Diamond `{…}` | Decision / condition |
| Trapezoid `[/…/]` | HITL gate (human must answer) |
| Hexagon `{{…}}` | Artifact / marker handoff |
| Thick `==>` | Happy path |
| Cross `--x` | Stop / blocked |
| Dotted `-.->` | Loop / re-entry |

Source of truth: [`commands/start-task.md`](../../commands/start-task.md), plus `tech-spec`, `approve-plan`, `start-build`, `finish-plan`, `hitl-choice`.

---

## 1. Full pipeline (end-to-end)

```mermaid
flowchart TD
  startNode(["/start-task ac-source"])
  noAc{AC exist?}
  stopNoAc[/"Stop: writing AC out of scope"/]
  bootstrap["Bootstrap: patterns + stack detect"]
  techSpec[["tech-spec"]]
  planWrite["writing-plans"]
  approvePlan[["approve-plan + critic"]]
  startBuild[["start-build"]]
  softwareDev[["software-developer"]]
  finishPlan[["finish-plan"]]
  engReview[["engineer-reviewer or multi-repo-supervisor"]]
  doneNode(["Reviewed PR path"])

  startNode ==> noAc
  noAc -->|"no"| stopNoAc
  noAc -->|"yes"| bootstrap
  bootstrap ==> techSpec
  techSpec ==>|"Status approved or skip"| planWrite
  planWrite ==> approvePlan
  approvePlan ==>|"Verdict: clear"| startBuild
  startBuild ==> softwareDev
  softwareDev ==>|"all tasks verified"| finishPlan
  finishPlan ==>|"skip / approve / done"| engReview
  engReview ==> doneNode
```

---

## 2. Tech spec — modes, tiers, gate

```mermaid
flowchart TD
  entry([tech-spec start])
  entryHitl[/"HITL: human or agent"/]
  humanMode["Human provides file; agent structures gaps"]
  agentMode["Agent interview + draft"]
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
  entryHitl -->|"human"| humanMode
  entryHitl -->|"agent"| agentMode
  humanMode --> writeFile
  agentMode --> uncertainty
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

## 3. Approve plan → critic → build

```mermaid
flowchart TD
  planReady(["Plan exists"])
  writeGate{{".cursor/plan-gate.pending"}}
  clearStale["rm plan-critique.clear"]
  hitlApprove[/"HITL: approve-plan / revise"/]
  revisePlan["clean-decision-docs rewrite plan"]
  delGate["Delete plan-gate.pending"]
  writeCritique{{".cursor/critique-gate.pending"}}
  critic[["implementation-critic Pass A + Pass B"]]
  verdict{Verdict?}
  writeClear{{".cursor/plan-critique.clear"}}
  delCritique["Delete critique-gate.pending"]
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

## 4. Start-build → software-developer

```mermaid
flowchart TD
  startBuildCmd(["start-build"])
  checkClear{".cursor/plan-critique.clear matches plan?"}
  checkPending{"plan-gate or critique-gate pending?"}
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
  toFinish(["finish-plan"])

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
  verify ==> toFinish
```

---

## 5. Finish-plan → review routing

```mermaid
flowchart TD
  planDone(["Plan tasks complete"])
  writeReview{{".cursor/review-gate.pending"}}
  hitlFinish[/"HITL: skip / approve / done / fixes"/]
  doFixes["Implement fixes; re-ask gate"]
  delReview["Delete review-gate.pending"]
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
  writeReview ==> hitlFinish
  hitlFinish -->|"fixes"| doFixes
  doFixes --> hitlFinish
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
  clarify ==> reviewed
```

---

## 6. Engineer-review internals (phase graph)

```mermaid
flowchart TD
  orch(["engineer-reviewer"])
  lint[["review-lint"]]
  logic[["review-logic"]]
  patterns[["review-patterns"]]
  deadcode[["review-deadcode"]]
  arch[["review-architecture"]]
  perf[["review-performance"]]
  security[["review-security conditional"]]
  figma[["review-figma-markup if URLs"]]
  autofix{Auto-fix eligible?}
  apply["Apply fix"]
  clarifyItem[/"clarify — never silent apply"/]
  merge["Merge phase JSON + evidence gate"]
  report(["User-facing report"])

  orch ==> lint
  lint --> logic
  logic --> patterns
  patterns --> deadcode
  deadcode --> arch
  arch --> perf
  perf --> security
  security --> figma
  figma --> autofix
  autofix -->|"all 4 tests pass"| apply
  autofix -->|"any test fails"| clarifyItem
  apply --> merge
  clarifyItem --> merge
  merge ==> report
```

Auto-fix requires all four: deterministic check, single correct answer, no information loss, zero blast radius on data/UX. Traceability drift and migrations are always `clarify`.

---

## 7. Marker state machine

Runtime markers live in the **consumer project** `.cursor/` (never the kit).

```mermaid
stateDiagram-v2
  [*] --> Idle

  Idle --> PlanGate: approve-plan writes plan-gate.pending
  PlanGate --> CritiqueGate: approve-plan + critic starts
  PlanGate --> PlanGate: revise clears plan-critique.clear
  CritiqueGate --> CritiqueClear: Verdict clear
  CritiqueGate --> CritiqueGate: blocked / pending accept
  CritiqueClear --> Building: start-build + software-developer
  Building --> ReviewGate: finish-plan writes review-gate.pending
  ReviewGate --> Reviewing: skip / approve / done
  ReviewGate --> ReviewGate: fixes then re-ask
  Reviewing --> [*]

  note right of CritiqueClear
    plan-critique.clear must match plan path
  end note
```

| Marker | Written by | Cleared when |
|--------|------------|--------------|
| `.cursor/plan-gate.pending` | `approve-plan` | Human replies `approve-plan` |
| `.cursor/critique-gate.pending` | after plan approval | `Verdict: clear` |
| `.cursor/plan-critique.clear` | on `Verdict: clear` | invalidated on `revise` / re-approve |
| `.cursor/review-gate.pending` | `finish-plan` | `skip` / `approve` / `done` |

---

## 8. Standalone entry points (bypass full orchestrator)

```mermaid
flowchart LR
  writeSpec["/write-tech-spec"] --> techOnly[["tech-spec only"]]
  critique["/critique-plan"] --> criticOnly[["implementation-critic ad-hoc"]]
  approve["/approve-plan"] --> approveFlow[["approve + critic + start-build"]]
  build["/start-build"] --> buildOnly[["requires plan-critique.clear"]]
  finish["/finish-plan"] --> finishFlow[["HITL then review"]]
  eng["/engineer-review"] --> reviewDirect[["skip finish-plan HITL"]]
  pr["/pr-review"] --> prWrap[["PR wrapper report-only default"]]
  multi["/multi-review"] --> multiDirect[["multi-repo-supervisor"]]
```

`/critique-plan` alone does **not** write `plan-critique.clear` for build — prefer `/approve-plan` so plan HITL is not skipped.
