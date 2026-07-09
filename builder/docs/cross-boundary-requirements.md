# Cross-Boundary Requirements

This rule governs what a spec does when it discovers a requirement it **cannot satisfy within its own boundary** — one that belongs to a *peer* component or to a *cross-cutting concern*. It is generator-wide methodology and applies across stages.

It replaces the retired forward-commitment **ratification** model — specifically the part that assumed a separate step-0 cross-cutting-spec *author* would later "ratify" downstream commitments. That ratifying party was never built and is the fiction being retired. The **step-0 cross-cutting interfaces themselves are real** — Architecture §6/§7 order them before component specs — and their **authority is Architecture §7**. So a component **may** forward-commit to a step-0 cross-cutting interface: it records the commitment as *adopt-by-reference to §7* (e.g. "adopts a step-0 cross-cutting interface convention by reference"), which **resolves by reference to §7**, not by a phantom ratifier. What does not exist is the separate ratifying author. `cross-cutting.md` is **materialized up-front from Architecture §7/§8** at stage init — a projection of the already-frozen contracts, authoritative only *by reference* to §7/§8, consumed by component creation as a resolved contract layer. It is still **not** an independent authority and no party ratifies it; the post-promotion cross-cutting population workflow reconciles the realized bodies against it.

## Authority Direction (unchanged)

The system-generator holds **architecture → downstream** as the binding authority direction. Architecture and Foundations decisions bind component specs. Component specs do **not** bind architecture, and one component does not bind a peer's internal design.

The reverse direction — **downstream → architecture/foundations** — and the lateral direction — **component → peer** — are **proposal-only**. A spec may *surface* a concrete requirement it needs another party to uphold, but the receiving authority (the upstream stage author, or the peer's own review) is the one that ratifies it.

Data *contracts* between components are the exception handled elsewhere: they are materialized into `cross-cutting.md` up-front from Architecture §7/§8, and reconciled/enforced by the contract verifier against the bodies that realize them. This document is about **non-contract** design / behavioural / invariant requirements.

## Three exits

When a spec finds a requirement it cannot satisfy inside its own boundary, classify it into exactly one of three exits:

| Kind | What it is | Destination | Consumer |
|------|-----------|-------------|----------|
| **Data contract** | A produces/consumes B's data, or calls B's API | Inline in the spec now; extracted to `cross-cutting.md` later (CTR-*) | Contract verifier (review) |
| **Peer requirement (P1)** | "Component X must uphold behaviour Y" that affects **only X's own spec** | X's `pending-issues.md`, `Kind: CROSS-BOUNDARY-PEER` | X's **review** (consolidator) + Coherence |
| **Cross-cutting invariant / cross-cutting design (P2)** | A cross-component invariant or shared design decision **no single component owns and that §7 does not already settle** (retention coordination between two components; a shared posture/type/format not yet pinned). *If §7 already governs it — e.g. a shared cross-cutting-interface convention §7 already pins — it is **adopted by reference to §7**, not escalated (see below).* | Architecture (or Foundations) `pending-issues.md`, `Kind: CROSS-BOUNDARY-UPSTREAM`, `Status: AWAITS_UPSTREAM_REVISION` | The upstream stage's own review/create/expand (on its next revision round) |

### P1 vs P2 — the triage

Ask: **does this bind a peer's own internal design (P1), or is it a system invariant / shared design decision that no single component can own (P2)?**

- If X could satisfy it entirely within X's own spec once X knows about it → **P1** (route to X's `pending-issues.md`).
- If it coordinates two or more components, or fixes a shared posture/type/format that must be pinned once and centrally → **P2** (escalate upstream). A component must **not** bind a peer to a system invariant; that inverts the authority direction.

When unsure, prefer **P2** (escalate upstream): a cross-component invariant wrongly filed as a peer request is harder to reconcile than an upstream escalation the author declines.

**Adopt-by-reference vs escalate.** A cross-cutting-interface convention that Architecture §7 **already governs** (e.g. a shared cap/retention convention, a failure-posture obligation, a shared identifier/type shape) is **adopted by reference to §7** in the component's own §12 — a forward commitment to the real step-0 interface, resolved by reference. That is **not** a P2 escalation. Escalate as P2 (`AWAITS_UPSTREAM_REVISION`) only a genuinely *unsettled* cross-component invariant that §7 does not yet answer and that needs an upstream position (e.g. a residual failure-posture sub-question a cross-cutting interface leaves open, if it is to be pinned centrally).

## The `AWAITS_UPSTREAM_REVISION` marker (P2)

A P2 escalation is an **open obligation on an already-completed upstream stage**. It must never be silently assumed resolved. So it is made *loud on both ends*:

- **Upstream end** — the entry in the upstream `pending-issues.md` carries `Status: AWAITS_UPSTREAM_REVISION`, distinct from a normal `UNRESOLVED` in-stage discrepancy. It is actioned when a human runs the next revision round of that stage (that stage's existing review/create/expand workflow is the consumer — no new machinery).
- **Originating end** — the originating spec records the requirement as an open cross-reference (e.g. in §12 / its own pending-issues) noting it *awaits an upstream revision*, so the dependency is visible and not read as settled.

There is **no automatic consumer** for P2 escalations by design: a human triggers the upstream revision round when escalations accumulate. This is deliberate — an auto-actioning loop across completed stages is a non-convergence risk.

## Non-Ratification Fallback (unchanged)

If the receiving authority declines a requirement (an upstream author rejects a P2, or a peer's review rejects a P1), the **originating spec rewrites to match** the ratified position. The architecture, Foundations, and the peer spec are **not** silently amended to honour an unratified downstream/lateral requirement. This preserves the authority direction.

## Where each stage emits these

- **Component create** — the Enrichment Scope Filter (exploration path) and the create Author (gap-resolution path) route P1/P2 requirements. Create *emits* cross-boundary requirements but does not *consume* them: a component authors inside-out from upstream documents, and cross-component reconciliation happens at **review** (create does not read `pending-issues.md`).
- **Component review** — the Issue Router and the review Author route P1/P2 requirements; the Consolidator *consumes* this component's `pending-issues.md`.

## Cross-References

- `guides/pending-issues-format.md` — the `pending-issues.md` format, including the `Kind` field, the lateral cross-component PI shape, and the `AWAITS_UPSTREAM_REVISION` status.
- `agents/universal-agents/alignment-verifier.md` — SYNC_UPSTREAM / FIX_DOCUMENT classification for discrepancies between *existing* documents (a separate concern).
