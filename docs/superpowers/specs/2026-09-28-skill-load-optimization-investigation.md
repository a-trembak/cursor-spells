# Skill load optimization — investigation

## Status

`investigation` — recommendations only. No pipeline behavior change in this document.

## Question

As models improve unevenly, the harness can over-constrain stronger runs by loading third-party skills the model already “knows,” while rules (author process) must stay constant. When should the kit load skills, and is a model-aware optimization worth building?

## Method

Four isolated agents debated with no shared prior chat:

| Role | Stance | Verdict |
|------|--------|---------|
| Skill-gating advocate | Gate third-party stack skills by capability / proven need | Act on design + experiment (**7 / 10**) |
| Keep-skills advocate | Mandatory curated loads are the product; do not trust model IQ | Do **not** build model-aware gating (**9 / 10**) |
| Hybrid architecture analyst | Inventory current progressive-load mechanisms; propose hybrids | Ship load levels + writer-lean / reviewer-strict (**8 / 10**) |
| Return-on-investment skeptic | Third-party bodies are not the hot path | **No-Go** on a full model-profile skill router now (**7 / 10**) |

Repo grounding: `skill-map.md`, slim engineer-review context design, phase agents, `learned-misses.md`, install skip flags, harness size proxies.

---

## Settled preferences (from the human)

1. **Rules are constants.** Always-on and globbed rules stay. They encode author process, not generic textbook knowledge.
2. **Third-party / external skills** are the main suspect for irrelevance and context bloat when a strong model already covers that domain.
3. First-party **process** skills (human-in-the-loop choice, engineer-review spine, trajectory scoring, and similar) are a different class from “how to write React” skills.

---

## What the kit already does

The debate found the kit is **not** “always dump every skill into every context.” Progressive loading already exists:

| Mechanism | Behavior |
|-----------|----------|
| Always-on rules | Process constants every turn |
| Mechanical `skill-map` routing | Stack / database table lookup — zero “am I smart?” judgement |
| Trigger-gated kit checklists | Open full R / S / F / J / N / … bodies only when triggers fire |
| Orchestrator slim context | Phase-owned checklist and third-party bodies; merge pack only at report time |
| `skill_missing` → built-in fallback | Missing install never blocks; Coverage notes the gap |
| Optional enrichment | Kit security checklist is source of truth; third-party `security-review` is enrichment |
| Human-gated Tier 2 | Unmapped stacks: cheap-model search, human decides, never silent install |
| Install skip | `--skip-third-party-skills` / `CSP_SKIP_THIRD_PARTY_SKILLS=1` |

What is **missing**: an explicit taxonomy of skill *kinds*, explicit load *depth* (index → kit checklist → third-party body), and a human-owned profile that can demote third-party enrichment without touching kit miss gates. What must **not** be invented: auto-detect model capability → skip kit checklists.

---

## Debate points of agreement

All four voices converge here:

1. **Do not auto-skip kit miss-class checklists** (interaction replay, security S1–S11, JPA gates, and similar) based on model self-assessment. That replays `miss_security-checklist-skip` and related production escapes in `learned-misses.md`.
2. **Rules stay always-on.** Progressive loading belongs to skills and checklists, not to collapsing rules into optional skills.
3. **A full model-profile skill router is premature** without token attribution and quality A/B. The keep-skills advocate and the return-on-investment skeptic reject it; the hybrid analyst lists auto capability-skip as an anti-pattern; even the gating advocate wants experiment-first, not a rip-out.
4. **Context work already shipped for the orchestrator** (`2026-09-09-slim-engineer-review-context-design.md`). Further wins are elsewhere: phase fan-out, human-in-the-loop skill size, third-party load *depth*, install set size.
5. **Third-party stack skills ≠ kit process skills.** Treat them differently. Security already models the preferred pattern (kit mandatory, third-party optional enrichment).

## Debate points of tension

| Tension | Gating advocate | Keep-skills / skeptic |
|---------|-----------------|------------------------|
| Are Tier-1 stack skills (Vercel, Spring, Warden, …) still worth always-on for strong models? | Often no — attention tax + house-style constraint | Yes until map is curated down with evidence; never via model IQ |
| Where is the real cost? | Phase / writer third-party bodies (especially database skill stacks × logic + architecture) | Phase fan-out, human-in-the-loop chain, first-party process prose |
| Smallest next step | Load profile + A/B without third-party bodies | Measure tokens; lazy human-in-the-loop presets; phase skip on tiny diffs; prune install set |

**Resolution used below:** optimize **depth and install surface** for third-party knowledge skills; keep **mechanical triggers** for kit miss checklists; **measure** before any model-conditioned router; prefer **human profile** over **auto model detection**.

---

## Cost picture (structural)

Approximate harness-health style inventory (kit tree, not live token traces):

- Always-on rules: on the order of ~6–13 KB total — real but small.
- First-party process skills dominate kit bytes (`hitl-choice` alone ~20 KB; `engineer-review` tree ~164 KB mostly references).
- Third-party bodies are **not vendored**; they enter only when installed and a phase / writer loads them.
- Engineer-review cost multiplies as **phases × chunks × clarify re-dispatch**, each with its own context.

Therefore: “harness hurts strong models” is more likely **too many process steps and parallel review workers** (plus occasional heavy third-party enrichment) than “the wrong React skill markdown for this model card.”

---

## Taxonomy (recommended)

| Class | Examples | Load policy |
|-------|----------|-------------|
| **Constants (rules)** | `kit-no-pipeline-dogfood`, `code-via-coding-agents`, chat wording rules | Always |
| **Kit process spines** | `engineer-review`, `finish-plan`, `software-developer`, `hitl-choice` | Always for that stage |
| **Kit miss-class checklists** | R1–R7, S1–S11, J / N / RT / V / F gates | Trigger-gated full open; **never** model-skipped |
| **Mapped stack knowledge (third-party)** | Vercel React, Spring Boot, performance, architecture, dead-code | Mechanical route; load depth configurable |
| **Mapped weak-spot enrichment (third-party)** | Database migration packs, optional `security-review` | Diff / stack conditioned; prefer kit gate as floor |
| **Optional tooling** | `graphify`, `ce-test-browser`, `ce-simplify-code` | Prefer-if-present + documented fallback |
| **Tier 2 unmapped** | Unknown stack | Human-gated only |

### Load levels

| Level | Content | When |
|-------|---------|------|
| **L0** Index | Trigger sentence + path + Coverage token | Always in the phase / writer stub |
| **L1** Kit checklist | Full miss-class body | Trigger or learned-hint match |
| **L2** Third-party body | Mapped `SKILL.md` (+ personas) | Installed **and** profile / policy allows enrichment |

---

## Recommendations

### Do now (high leverage, low risk)

1. **Document the taxonomy and L0→L1→L2** in `skill-map.md` without changing runtime behavior. Makes the next edits discussable.
2. **Formalize “kit checklist = floor, third-party = enrichment”** for every mapped stack skill the way security already works — so `skill_missing` and “strong model / lean profile” share one contract.
3. **Measure before inventing a router.** On a handful of full-path reviews, attribute input cost to: phase fan-out, human-in-the-loop skill, kit checklists, third-party bodies, discovery list. Kill model-routing work if third-party share is clearly minor.
4. **Prefer process demotion over skill IQ gates:** lazy-load `hitl-choice` presets; skip low-value review phases on tiny non-risky diffs (with Coverage notes); prune default curated install ids that kit checklists already cover.

### Do next (conditional)

5. **Human-configured profile** (`strict` / `balanced` / `expert`) that only modulates **L2** third-party depth. Hard floor: rules + kit miss checklists never on the skip list.
6. **Writer lean / reviewer strict:** implementers may skip L2 stack enrichment under `expert` / `balanced`; review phases still run L1 on triggers (safety net).
7. **Collapse database third-party stacks** if measurement shows multiplicative load (logic + architecture × many migration skills) without extra catch rate — keep at least one migration-discipline skill as floor.

### Do not do (this cycle)

8. **Do not** auto-detect model capability and skip kit L1 checklists.
9. **Do not** build a full per-model skill router until measurement + quality A/B justify it (see kill criteria below).
10. **Do not** move checklist bodies back into the orchestrator (undoes slim-context).
11. **Do not** treat `learned_hints` one-liners as a substitute for opening the linked checklist.
12. **Do not** silently install or edit Tier-2 map entries.

---

## Is the optimization worth it?

| Scope | Worth it? | Why |
|-------|-----------|-----|
| Model-aware auto skill router | **No** (now) | Wrong layer; high maintenance; unstable across Cursor model swaps; no token proof |
| Taxonomy + enrichment vs floor clarification | **Yes** | Cheap; aligns security/simplify precedents; enables later profiles |
| Human L2 profile + writer-lean | **Maybe** | Only after measurement shows L2 cost matters and quality holds without it |
| Phase skip / human-in-the-loop slim / install prune | **Yes** | Higher expected return than skill routing; model-agnostic |

**Overall:** the *problem is real* (stronger models + mandatory third-party enrichment can waste context and over-steer). The *right optimization* is mostly **already half-built** (triggers, slim orch, `skill_missing`, optional enrichment). Push that pattern further. Do **not** invest in “this model is smart enough to skip the harness.”

---

## Minimum experiment (if insisting on evidence)

1. Instrument 10–20 full-path engineer-reviews: phase count, chunks, skill loaded vs `skill_missing`, rough token buckets.
2. Fixed fixture set: frontier vs mid model × skills installed vs `--skip-third-party-skills`.
3. Blind score against kit gates (R / S / J / RT / V) and known `learned-misses` classes — not vibe quality.
4. **No router code** in the experiment.

**Kill criteria (any one):** third-party bodies &lt; ~15% of review input tokens; frontier quality with skills skipped within noise of skills-on for must-fix classes; phase-skip / human-in-the-loop slim alone recovers more savings than a projected router; experiment exceeds one focused engineering pass without clear signal.

---

## Suggested follow-up artifacts (separate work)

- Short design addendum to `skill-map.md`: Skill classes + Load levels (behavior-preserving).
- Optional consumer config sketch: `.cursor/csp-skill-profile` or install flag for L2 depth (not model auto-detect).
- Measurement note under `docs/superpowers/dogfood/` once live token buckets exist.

## Non-goals of this investigation

- Changing review severity or apply eligibility.
- Deleting checklist content to fake a size win.
- Shipping profile or router code in the same change as this write-up.
