# Contract-First Component Specs — Design

**Status:** PROPOSAL (not yet implemented)
**Scope:** the 04-architecture ↔ 05-components seam — how inter-component contracts get frozen, consumed, and escalated.
**Relationship to existing docs:** extends `cross-boundary-requirements.md` (which defines P1/P2 routing and `AWAITS_UPSTREAM_REVISION`). This doc is about *where contracts are frozen and why*, and the narrow reinforcements needed; that doc is about *how a discovered cross-boundary requirement is routed*.

---

## 1. Problem

Component-spec creation authors **inside-out** — the generator reads Architecture + Foundations + the cross-cutting registry, not peer component specs (`cross-boundary-requirements.md`: "a component authors inside-out from upstream documents"). So the only way a component gets a peer's contract *right* is if that contract is **stable and complete** in the upstream documents before the body is written.

When it isn't, the contract detail is discovered late — inline, during body work — and can silently diverge. The motivating failure: **CTR-015** (`decision_point_reads`). Architecture froze the read's *topology* (participants supplies "feedback entries and usage logs") but delegated the field-shape to PRD §5. The delegation was implicit and unenforced, so the `participants` body modelled Feedback Entry as an opaque `body`, silently dropping the PRD §5 fields (success dimension, signal type, relationship proximity, cohort marker) that the Phase-1b go/no-go assessment depends on — and coverage still reported PASS. Caught only at Round-2 alignment verification.

This is one instance of a general question: **when should inter-component contracts be frozen, and where does that work belong?**

---

## 2. Core principle

> **Freeze contract *obligations* upstream (architecture); keep constrained *realizations* in components; escalate *unmade decisions* back to architecture rather than resolving them inline.**

Two supporting claims, both tested (§3):

- **At the spec stage, contracts are freezable ahead of the bodies that consume them.** A component spec and a contract are the *same kind of artifact* — both design-level. "Emergent from the body" only has force when the body is a *different* kind of artifact (running code) that reveals *empirical* facts (performance, data distributions, framework limits). Specs reveal none of that; everything in a spec is a *decision*, and a decision can be made in the contract layer. So contract-first is not merely feasible at this stage — it is theoretically sound *because* it is pre-implementation.
- **"Obligations up, realizations down" is the altitude rule the architecture reviewers already enforce.** Architecture pins the obligation/invariant; components own the concrete realization (encodings, table names, literal values), constrained by the frozen obligation so they cannot break a consumer. Architecture must *not* freeze realizations — doing so turns it into a component spec and forfeits the stability that makes it authoritative.

---

## 3. Evidence: the three-bucket model

Seven cross-component edges were pressure-tested, deliberately biased toward where genuine emergence would most likely hide (explicitly-delegated architectural decisions, known-open questions, decoupling contracts). Each was asked: *could this contract be frozen before either body, purely from Architecture + PRD — or does resolving it genuinely require working a body?*

Every edge classified into one of three buckets — and one bucket was **never populated**:

| Bucket | Meaning | Design home |
|--------|---------|-------------|
| **Frozen obligation + constrained realization** | Obligation pinnable upstream; only a fenced realization is component-owned | Architecture (obligation) + Component (realization) |
| **Unmade-upstream-decision (D)** | A real decision, not yet made, that belongs at architecture/foundations — *not* discovered in a body | Escalate to architecture (Expand round) |
| **Genuine emergence (C)** | Some part of the contract can *only* be determined by working a body | **Not found in any of 7 edges** |

Edges tested:

- **events↔entities (CTR-008, `update_entity_references`)** — *fully frozen ahead.* Architecture §8 pins signature, return type, ambient-transaction participation, entity-scoped transfer semantics, and a deterministic lock-ordering obligation, all marked "non-negotiable." Only concrete table names deferred (not on the cross-component surface).
- **pipeline↔extraction-review (staleness coordination)** — *invariant frozen, values deferred.* Architecture pins "staleness threshold ≥ worst-case interlock wait"; the literal values are component-owned but constrained by the frozen relationship, so they reconcile without breaking the contract.
- **participants↔admin-views (CTR-015)** — *the failure — and it inverts the concern.* The field-shape was **freezable-but-unpinned** (it was in PRD §5 all along), not emergent. Contract-first would have *prevented* it.
- **source-attribution O1 dispatch** — registry-vs-direct is quarantined as **contract-invisible** internal wiring (DD-027: "no contract modification required"); the write-fails/read-degrades asymmetry is "fixed regardless of the validation mechanism."
- **XC-003 audit failure posture** — the participants-facing obligation is frozen at Architecture §7 (state-transition transactional consistency); the residual immutable-record posture is a **(D)** — provably not emergent (architecture already pinned the identical decision for the transition case).
- **CTR-022 absence signal** — "distinguishable from success" is the frozen invariant; typed-not-found vs empty-projection is a fenced representation choice. Absence is a data-model fact (zero-or-one lookup), not a body discovery.
- **CTR-026/027 opaque participant reference** — opaqueness/minting/sole-joiner frozen; concrete token (UUID PK) is a realization both consumers are structurally blind to. Residual token-canonicalization is **(D)** (PI-010, a Foundations decision).

**Result: 0 of 7 genuine emergence.** The unpopulated (C) bucket, plus the theoretical reason for it (§2), is what licenses an aggressive contract-first posture: the `TBD-IN-COMPONENT` frontier is nearly empty, and the real work is (a) freezing obligations *completely* and (b) handling **(D)** cleanly.

*Caveat:* this is a well-architected system, so some "already frozen" is a property of *this* Architecture. But that does not weaken the conclusion — in a weaker architecture the gaps surface as **(D) unmade-upstream-decisions**, not **(C) emergence**, and (D) is handled by escalation, not by body-discovery.

---

## 4. What already exists (much of the seam already exists)

The machinery this design implies is largely already in the **architecture stage** — the product of prior investment made *after* early rounds saw contracts emerging at the component stage.

- **Contract-completeness checking** — `04-architecture/review/experts/integration-architect.md` does explicit absence-spotting: interface symmetry (each operation's read *and* write surface), producer/consumer pairing (every contract row names both), cross-component flow paths (every dependency has an integration row or explicit deferral). It enforces altitude ("don't flag missing endpoint specifications — those belong in Component Specs").
- **Data-contract review** — `04-architecture/review/experts/data-architect.md`, which also holds altitude ("don't flag missing field definitions — those belong in Component Specs").
- **Escalation consumption is wired, not aspirational** — `04-architecture/expand/orchestrator.md` takes as its trigger: "if a pending issues file exists with unresolved issues: use `04-architecture/versions/pending-issues.md`", explicitly "driven by a downstream discovery." That file exists and is actively used (~99 KB). So "push (D) back to architecture" is a running loop.
- **Component-side field-coverage** — `05-components/create/requirements-extractor.md` (Step 1b) + `coverage-checker.md` (CONFIRM-INTENTIONAL), added in `30e3ab0` after CTR-015, already check owned-entity PRD §5 fields at the component boundary.
- **Contract registry + conformance** — `05-components/cross-cutting/` (`contract-extractor`, `contract-reconciler`) and `review/contract-verifier.md` extract contracts into `cross-cutting.md` and reconcile consumer↔producer (currently `DEFERRED`). **Note:** these read *finished component bodies* (post-hoc) — their registry format + field-comparison logic are reusable, but the Gap-1 up-front materializer is a **new, upstream-reading agent**, not a re-run of these (see Gap 1).

The earlier idea of a *new* contract-first components workflow was largely reinventing this. The real work is four narrow reinforcements.

---

## 5. The four gaps and their fixes

### Gap 1 — Checked delegation, via a contract-materialization pass at the components initializer (closes the CTR-015 class)

**Problem:** Architecture may delegate a CTR's field-shape to an authoritative source (PRD §5, Foundations) — and *should*, to keep altitude. But the delegation falls in a seam: `integration-architect` works at operation granularity and `data-architect` explicitly excludes field definitions, so *no one checks the delegation is explicit and will be enforced.* Relatedly, the builder has **no pass that materializes the frozen inter-component contracts up-front** — `cross-cutting.md` is a post-hoc registry (currently a DEFERRED stub), so components author against Architecture §7/§8 with no resolved contract layer to consume.

**Fix — a contract-materialization ("define") pass at the components initializer:**
- **Materialize up-front — a NEW agent reading *upstream*, not the existing body-readers:** at stage init, a new agent reads Architecture §8 (the CTR table) + §7 (interfaces) + PRD §5 and populates `cross-cutting.md` with the frozen inter-component contracts, so component creation reads a *resolved* layer. **Direction correction:** the existing `cross-cutting/` `contract-extractor` / `contract-reconciler` **cannot** do this — they read a *finished component body* ("read only the ONE component spec you are given") and extract contracts *out* of it, post-hoc. What carries over is the **registry output format** and the **reconciler's field-comparison logic** (reusable for post-hoc conformance once bodies exist), *not* the direction. §8 is already a near-complete frozen table (30+ CTRs with consumer/producer/pattern/description), so this is mostly **transcription + resolving each delegated field-shape to an explicit binding pointer + flagging the under-pinned ones** — not heavy discovery.
- **The registry is a *projection*, not a new authority (reconcile the "downstream registry only" framing — carefully, ~6 prompts):** `cross-boundary-requirements.md` and ~5 create prompts (`generator` ×3, `concern-identifier`, `concern-explorer`, `requirements-extractor`) assert, deliberately and verbatim, that `cross-cutting.md` is a **downstream registry only / populated post-hoc** with **no cross-cutting-spec authoring step** — hardening that killed the retired "ratification" fiction. Materializing up-front collides with that framing, so it must be reconciled: **authority stays with Architecture §7/§8; the up-front registry is a materialized *projection* of §7/§8 (authoritative only by reference) — not a new authority and not a ratifier.** This preserves the authority-direction invariant and is genuinely *not* the fiction (no phantom author ratifies anything — §7/§8 already said it). It requires touching that framing in the ~6 prompts, carefully.
- **Bind + check the delegations:** where a CTR's payload is an owned entity, resolve the delegation as a **binding, conformance-checked pointer** — e.g. CTR-015 feedback payload **binds** PRD §5 Feedback Entry (participant, date, success dimension(s), signal type, period marker, transition marker, cohort marker, content). Component-side enforcement already exists (`30e3ab0`: owned-entity PRD §5 fields + CONFIRM-INTENTIONAL); wire it to the registry's binding annotation.
- **Escalate gaps:** when materialization reveals a contract the Architecture under-pinned, escalate upstream (the Expand loop), not inline.

**Why the initializer, not architecture review:** materialization is a component-stage consumption/setup step (lower blast-radius than modifying the mature architecture review), and it's the natural point to deliver contract-first *at the point of consumption*. This is the deliberate choice to **build the step-0 contract-authoring pass** rather than leave the step-0 interface schema collapsed into "§7 + a post-hoc registry" — a question the builder previously flagged as an open decision, now settled here. One residual stays genuinely open upstream: **XC-003's immutable-record audit-write failure posture** is a `(D)` unmade-upstream-decision to escalate (P2 / `AWAITS_UPSTREAM_REVISION`), not resolve at the initializer.

**Architecture side (small):** the architecture reviewers should confirm every entity-bearing CTR *names its authoritative field source* (a pointer-exists check, at altitude — not the fields). This folds naturally into Gap 2's `integration-architect` work.

**Lands in:** the components **initialize** + `cross-cutting/` workflow (materialize / bind / escalate); the `cross-cutting.md` registry (un-DEFERRED); component coverage (already `30e3ab0`); a light architecture-review pointer-exists check.

### Gap 2 — Subtle-obligation completeness (the incomplete-freezing risk)

**Problem:** The confirmed risk is *incomplete* freezing, not premature freezing. `integration-architect` absence-spotting is at interface/operation granularity, but the load-bearing obligations that bit us are *sub-operation*: CTR-008's deterministic lock-ordering, O1's write-fails/read-degrades asymmetry, CTR-026's token-canonicalization. These get pinned only when someone reasons hard about concurrency/consistency.

**Fix:** extend the `integration-architect` absence checklist with a named **cross-component obligation class**: concurrency/lock-ordering, transaction-participation, identifier canonicalization/equality, and failure-surfacing posture. Prompt it to walk each multi-writer or multi-reader edge for these specifically.

**Lands in:** architecture review (`integration-architect` prompt).

### Gap 3 — Components gate on *contract-frozen*, not *review-complete*

**Problem:** `create/orchestrator.md` Step 1.3 blocks creating a component until its dependencies are `COMPLETE` (fully reviewed). Since creation is inside-out and reads only contracts, this uses full review as a proxy for contract-stability — over-serializing, and forcing upstream components to be reviewed *before their consumers exist to weigh in* (which maximizes late upstream re-review).

**Fix:** add a **contract-frozen** milestone (a component's produced CTRs registered + agreed) between `DRAFT_READY` and `COMPLETE`, and change the create gate to require dependencies **contract-frozen**, not `COMPLETE`. Bodies can then be created in parallel against frozen contracts; full review sequences later, when consumers are known.

**Lands in:** `create/orchestrator.md` Step 1.3 + the stage-state status model (`versions/workflow-state.md`) + create resume logic. **Do not ship this before Gaps 1, 2, and 4** — relaxing the gate while contracts are still under-frozen just moves churn downstream.

### Gap 4 — Convergence discipline (two levels)

**Problem:** Review loops lack structural termination (existing known issue): fix-induced churn, no re-raise suppression, contradictory exit thresholds. Pushing (D) back to architecture adds a *second* level where this can thrash (cross-stage ping-pong).

**Fix:**
- **Within-component:** a **resolved-issue ledger** that verifiers read (so a settled item can't return as a "fresh" finding), re-raise suppression in the verifier prompts, and severity-gated exit (exit on no-HIGH, not zero-issues — Step 10c already does this; propagate it).
- **Cross-stage:** keep Expand human-triggered and **batched** — accumulate (D) escalations and run one Expand round, with re-raise suppression across stages, rather than an auto-loop. (`cross-boundary-requirements.md` already mandates human-triggered; make batching + suppression explicit.)

**Lands in:** the universal verifiers (`alignment-verifier`, `internal-coherence-checker`, `stage-appropriateness-verifier`, `contract-verifier`), the review phase orchestrators + create Step 10c, and the Expand orchestrator.

---

## 6. Adoption sequencing

- **Phase 0 (cheap, high-leverage, no re-architecture):** Gap 4 within-component convergence (ledger + suppression + severity-exit) **and** un-defer the existing `cross-cutting/` extract→reconcile against the specs you already have (email-sources). Fixes the acute pain and starts populating the registry with zero new machinery.
- **Phase 1 (the root fix):** Gap 1 (contract-materialization + binding-delegation pass at the components initializer) and Gap 2 (subtle-obligation checklist). These make component-stage (D) discoveries *rare* — the whole point.
- **Phase 2:** Gap 3 (contract-frozen milestone + gate change). Only after Phases 1 and the convergence half of 4, so the relaxed gate opens onto stable contracts.
- **Ongoing:** Gap 4 cross-stage batching as Expand rounds accumulate escalations.

## 7. Risks

1. **Incomplete freezing** (the confirmed real risk) — the architecture contract-completeness pass must have architect-grade rigor to catch subtle obligations. Mitigated by Gap 2; residuals surface as (D) and escalate.
2. **Cross-stage thrash** — a late (Tier-4) discovery forcing an architecture change that ripples to already-reviewed Tier-1s, at maximum blast radius. Mitigated by freezing *well* up front (Gaps 1–2 make late discovery rare) and by bounded/batched Expand (Gap 4).
3. **Over-freezing** — architecture drifting into field/realization detail and losing altitude. Guarded by the existing altitude discipline in both architecture experts; the binding-delegation convention (Gap 1) is the counter-pattern: *delegate and check*, don't duplicate.

## 8. Migration for in-flight work

- `email-sources` (`DRAFT_READY`) and `participants` (Round 3): do not disrupt. Extract their contracts into the registry now (Phase 0 seed). Apply the contract-frozen gate/status regime (Gap 3) only to not-yet-started components.
- The dependency/tier table in `versions/workflow-state.md` is unchanged; only the *gate predicate* over it changes.

---

## 9. Open items to confirm before implementing

- The exact form of the binding-delegation annotation on CTRs (a §8 column? an inline "binds PRD §5 …" clause?), and how the initializer / `cross-cutting/` define pass materializes + escalates (which agents, registry format).
- Whether `contract-frozen` is a distinct status or a separate column alongside the review status, and its resume semantics.
- The resolved-issue ledger format and where it lives (per-component vs per-round).

*(All agent-prompt edits are authored in `builder/agent-sources/` and built via `build-prompts.sh`, not edited in `builder/agents/` directly.)*
