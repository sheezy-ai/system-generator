# Cross-Boundary Requirements

This rule governs what a spec does when it discovers a requirement it **cannot satisfy within its own boundary** — one that belongs to a *peer* component or to a *cross-cutting concern*. It is generator-wide methodology and applies across stages.

It replaces the retired "forward commitments to cross-cutting specs" model. That model assumed a **step-0 cross-cutting-spec authoring/ratification** pass that is not built and was never intended: cross-cutting *design* is authored upstream in Architecture / Foundations, and `cross-cutting.md` is a **downstream contract registry only** (populated post-hoc by the cross-cutting population workflow). A downstream spec therefore does **not** "forward-commit" content to a future cross-cutting spec, and nothing ratifies such commitments. See the Defect note `DEFECT-cross-boundary-requirements.md` for the full history.

## Authority Direction (unchanged)

The system-generator holds **architecture → downstream** as the binding authority direction. Architecture and Foundations decisions bind component specs. Component specs do **not** bind architecture, and one component does not bind a peer's internal design.

The reverse direction — **downstream → architecture/foundations** — and the lateral direction — **component → peer** — are **proposal-only**. A spec may *surface* a concrete requirement it needs another party to uphold, but the receiving authority (the upstream stage author, or the peer's own review) is the one that ratifies it.

Data *contracts* between components are the exception handled elsewhere: they are extracted into `cross-cutting.md` and enforced by the contract verifier. This document is about **non-contract** design / behavioural / invariant requirements.

## Three exits

When a spec finds a requirement it cannot satisfy inside its own boundary, classify it into exactly one of three exits:

| Kind | What it is | Destination | Consumer |
|------|-----------|-------------|----------|
| **Data contract** | A produces/consumes B's data, or calls B's API | Inline in the spec now; extracted to `cross-cutting.md` later (CTR-*) | Contract verifier (review) |
| **Peer requirement (P1)** | "Component X must uphold behaviour Y" that affects **only X's own spec** | X's `pending-issues.md`, `Kind: CROSS-BOUNDARY-PEER` | X's **review** (consolidator) + Coherence |
| **Cross-cutting invariant / cross-cutting design (P2)** | A cross-component invariant, or a shared design decision **no single component owns** (audit-trail failure posture, retention coordination, a shared type/format) | Architecture (or Foundations) `pending-issues.md`, `Kind: CROSS-BOUNDARY-UPSTREAM`, `Status: AWAITS_UPSTREAM_REVISION` | The upstream stage's own review/create/expand (on its next revision round) |

### P1 vs P2 — the triage

Ask: **does this bind a peer's own internal design (P1), or is it a system invariant / shared design decision that no single component can own (P2)?**

- If X could satisfy it entirely within X's own spec once X knows about it → **P1** (route to X's `pending-issues.md`).
- If it coordinates two or more components, or fixes a shared posture/type/format that must be pinned once and centrally → **P2** (escalate upstream). A component must **not** bind a peer to a system invariant; that inverts the authority direction.

When unsure, prefer **P2** (escalate upstream): a cross-component invariant wrongly filed as a peer request is harder to reconcile than an upstream escalation the author declines.

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
- `DEFECT-cross-boundary-requirements.md` — the defect this methodology resolves.
