# Defect: No clean mechanism for cross-boundary (non-contract) component requirements

**Status**: RESOLVED — 2026-07-08 (builder fix applied; see Resolution below)
**Found**: 2026-07-08, during `participants` component-spec creation (round 2)
**Affects**: system-generator/builder (prompts + methodology docs). Does **not** affect the correctness of already-authored component specs.

## Resolution (2026-07-08; refined 2026-07-09)

Fixed by clarifying the model (refined 2026-07-09 during email-sources / participants promotion): the **step-0 cross-cutting interfaces are real** — Architecture §6/§7 order them before components and their authority is §7 — so components **forward-commit to them by reference to §7** (as email-sources / participants do). The only fiction is a separate ratifying *author* pass that would "ratify" those commitments; that is retired. Cross-component *invariants* that §7 does not settle are reached by upward escalation; `cross-cutting.md` stays a downstream contract registry.

- **Model documented**: `docs/cross-boundary-requirements.md` (replaces the retired `docs/cross-cutting-forward.md`, now a redirect stub). Three exits — data contract (CTR registry), peer requirement (P1, lateral `pending-issues.md`), cross-cutting invariant/design (P2, upstream `pending-issues.md` with `AWAITS_UPSTREAM_REVISION`).
- **Disposition made first-class**: `guides/pending-issues-format.md` gains `Kind` + `AWAITS_UPSTREAM_REVISION` + the lateral shape; `review/issue-router.md` and `review/author.md` carry the P1/P2 disposition; **create gains a push channel it never had** via `create/enrichment-scope-filter.md` and `create/author.md`.
- **Fiction retired**: "pending cross-cutting spec ratification" language removed from `create/generator.md`, `create/concern-explorer.md`, and `create/concern-identifier.md`.

**Corrections to this note's original diagnosis** (verified during the fix): (a) the fiction lived in **three** create prompts, not one; (b) a lateral peer channel already existed in *review* — the real gap was that *create* had none; (c) `cross-cutting-forward.md` is builder-orphaned but was **not** project-data-orphaned — it was built, used, then abandoned at the 2026-06-30 re-init, leaving a live citation in `04-architecture/versions/pending-issues.md`; (d) XC-003 is **not** closed by a bare §7-line-513 reference — its immutable-record failure-posture sub-question needs an explicit upstream position; (e) "step-0" is **not** a fiction — the step-0 cross-cutting *interfaces* are real (§6/§7); only the separate ratifying-*author* pass was fictional. Components adopt cross-cutting-interface conventions by reference to §7 (verified in email-sources / participants). The initial "collapsed model / component-owned" framing overstated this and was corrected in the XC-* backlog and `cross-boundary-requirements.md`.

**Project-data follow-up (Group D — done 2026-07-09, commits `d350cf0` + `3967e1f`)**: reframed the XC-* items in `05-components/versions/cross-cutting/deferred-items.md` and annotated the legacy citation in `04-architecture/versions/pending-issues.md`.

**Known deferred (not addressed by this fix)**: the builder has **no workflow that authors the step-0 cross-cutting interface schema** (audit-trail / source-attribution). This mirrors an unresolved tension in Architecture §7 itself — the interface is "defined as a cross-cutting dependency **before** domain component specs begin" yet its "schema detail … is defined in the cross-cutting specification at component level" (the post-hoc CTR registry). Components currently bridge this with adopt-by-reference + XC-* flags; **XC-003's immutable-record failure-posture stays genuinely open**. Resolving it — build a step-0 authoring step, or amend §7 — is a separate decision deliberately not taken here.

---

## Summary

The builder has **no clean, documented pathway** for a component spec to place a **non-contract requirement across a boundary** — either onto a **peer component** or onto a **cross-cutting concern**. Data-*contract* requirements are well-supported; non-contract **design / behavioural / invariant** requirements are not. Instead, several prompts instruct component specs to record "pending cross-cutting ratification" flags that point at a **step-0 authoring/ratification workflow that does not exist**, producing dangling obligations nothing downstream ever consumes.

The effort it took to discover this — multiple dead-end remedies, and reading docs that contradict the implementation — is itself the symptom: following the documented builder leads into a step that was never built.

## What works (for contrast)

Data-contract requirements between components (A produces/consumes B's data, or calls B's API) are handled: CTR-* contracts + `cross-cutting/contract-extractor` + `contract-reconciler` + contract-verification-in-review. Producer/consumer mismatches are flagged and enforced.

## What's broken

**1. No lateral component→component requirement channel.**
Authority is Architecture → components (top-down) by design. A component that needs a **peer** to uphold a behavioural invariant has no direct channel. The intended substitute is upward escalation to Architecture, which authors the cross-component invariant (precedent: **Architecture §7 line 591** — the pipeline↔extraction-review retention-coordination invariant, authored at architecture level). But that path is **generic** ("wrong level, kick upstream" via the scope-filter `DEFER-UPWARD` / review Issue Router → Architecture pending-issues), not purpose-built, and requires **re-opening a completed Architecture stage** to action.

**2. Prompts invent a "pending ratification" fiction for cross-cutting.**
Three artifacts presuppose a step-0 cross-cutting-**spec authoring/ratification** workflow:
- `agent-sources/stages/05-components/create/generator.md` (~lines 52, 79): emit §12 "bilateral-ratification flags … **pending cross-cutting spec ratification**."
- `system-design/05-components/versions/cross-cutting/deferred-items.md`: frames XC-* items as "to be resolved during **cross-cutting interface spec work (step 0)**."
- `docs/cross-cutting-forward.md`: a full forward-commitment → ratification methodology (`forward-cross-cutting/[target].md` inventory; ratify/normalise/reject lifecycle).

**None of the ratifying step is implemented.** The only cross-cutting workflow is the **registry populate** (`agent-sources/stages/05-components/cross-cutting/orchestrator.md` → `specs/cross-cutting.md` = a CTR contract registry; explicitly "does not go through the review workflow"). The actual cross-cutting *design* is authored upstream in **Architecture §7 / Foundations**. So the flags/commitments have no consumer and nothing ratifies them.

## Evidence (how it surfaced)

- **participants round-2 ENR-010** ("provenance audit writes must be transaction-participating / abort on audit-write failure") was framed as a requirement on **XC-003** pending step-0 ratification. Tracing "how does that get actioned?" found: (a) no ratifying step exists, and (b) the substance was **already an Architecture §7 commitment** — line 513: the audit trail is in CloudSQL to "preserve transactional consistency between state transitions and audit entries." The forward-commitment framing was a category error; the correct move is to **reference §7**.
- **participants CON-4** (retention-coordination invariant on `admin-views`) is the **peer-component** instance of the same defect. Its correct home is **Architecture §7**, alongside the existing pipeline↔extraction-review invariant — not a participants enrichment reaching into admin-views.

## Corrective direction (for the fix pass — a direction, not a design)

1. **Document the real model.** Cross-cutting *design* decisions and cross-component *invariants* are Architecture / Foundations concerns. A component that discovers one **escalates upward**; it does not "flag pending cross-cutting ratification" or bind a peer directly. `cross-cutting.md` is a downstream **contract registry** only.
2. **Make the upward path first-class.** Give component-create an explicit **"cross-boundary requirement"** disposition (distinct from generic wrong-level defer) that routes the item to Architecture/Foundations pending-issues with enough context to be actioned, and states plainly it **awaits an Architecture revision** — so it is never silently assumed resolved.
3. **Retire or correct the fiction.** Retire `docs/cross-cutting-forward.md` (or rewrite its premise to "escalate upstream," dropping the non-existent ratification lifecycle); change the generator's §12 instruction from "pending cross-cutting spec ratification" to "**reference the governing Architecture/Foundations decision, or escalate upstream if undecided**"; reconcile the XC-* framing in `cross-cutting/deferred-items.md`.
4. **Resolve the XC-* backlog.** The XC-* items in `cross-cutting/deferred-items.md` are upstream design questions mis-filed as a cross-cutting-spec worklist. Route them to Architecture/Foundations, or close by reference where §7 already answers them (e.g., **XC-003 failure posture ← §7 line 513**).

## Open decision for the owner

Confirm the premise before implementing: were the step-0 cross-cutting interface *specs* (audit-trail, source-attribution, compliance-gate, admin-authz) **deliberately collapsed** into "design authored in Architecture §7 + a CTR registry," or was a thin step-0 authoring pass **intended and never built**? The corrective direction above assumes the former (it matches the evidence). If the latter, the fix is instead to build that authoring workflow.

## Scope note

Builder (system-generator) defect only. Already-authored component specs are correct — their requirements are recorded (in §12 / dependencies); they are simply **not routed**. This fix is independent of, and can follow, the in-flight participants run.
