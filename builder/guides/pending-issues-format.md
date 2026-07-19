# Pending Issues File Format

This document defines the format for `pending-issues.md` files, which track issues identified in upstream documents during downstream work.

## File Location

Stages 01–05 each have a pending-issues.md file:
- `system/01-blueprint/pending-issues.md`
- `system/02-prd/pending-issues.md`
- `system/03-foundations/pending-issues.md`
- `system/04-architecture/pending-issues.md`
- `system/05-components/pending-issues.md`

Stages 06–12 are automated pipelines and don't use pending issues.

Component Specs also has **per-component** pending-issues files for lateral/cross-component issues:
- `system/05-components/versions/[component-name]/pending-issues.md`

## Who Writes

- **Orchestrator** writes new pending issues (after human confirms Alignment Verifier's HALT recommendation)
- **Issue Router** (05-components review) appends escalated upstream issues and lateral cross-component issues, classified by `Kind` (see Cross-Boundary Requirements below)
- **Enrichment Scope Filter** (05-components create) appends cross-boundary requirements surfaced during exploration — P1 lateral to a peer, P2 upstream to Architecture/Foundations
- **Author** (05-components create and review) appends cross-boundary requirements surfaced during gap/issue resolution, and marks issues as RESOLVED
- **Pending Issue Resolver** updates status for human-decided resolutions (APPLY → RESOLVED, DEFER → DEFERRED, REJECT → WONT_FIX)
- **Architecture Promote** (`04-architecture/promote`) — on a re-freeze (MERGE), appends a durable re-verify flag (`CROSS-BOUNDARY-PEER`, `HIGH`) to each affected write-direction producer's file when its contract obligation changed at the freeze; consumed at that producer's next review (Slice 6)

## Who Reads

- **Review Orchestrator** checks for unresolved issues at workflow start (Step 0)
- **Consolidator** reads unresolved issues and includes them in consolidated output
- **Contract Verifier** (05-components) reads pending issues when checking for regressions
- **Stage Coherence Orchestrator** (05-components) aggregates pending issues across all components during Phase 2
- **Upstream stage workflows** (create/expand/review for PRD, Foundations, Architecture) action their own `AWAITS_UPSTREAM_REVISION` (P2) items when that stage is next revised

Note: **create does not read `pending-issues.md`** — a component authors inside-out from upstream documents, and cross-component reconciliation happens at review. Create only *writes* cross-boundary requirements here; it does not consume them.

---

## File Format

```markdown
# Pending Issues: [Stage Name]

Issues identified in this stage's document during downstream work.

---

## Summary

| Status | Count |
|--------|-------|
| UNRESOLVED | [N] |
| RESOLVED | [N] |

---

## Unresolved Issues

### PI-001: [Brief title]

**Status:** UNRESOLVED
**Severity:** SHOWSTOPPER | HIGH | MEDIUM | LOW
**Logged:** YYYY-MM-DD
**Source:** [Downstream stage] [Create|Review] workflow, Round [N]

#### This Document States

> "[Exact quote from this document]"

**Section:** [Section reference in this document]

#### Downstream Document States

> "[Exact quote from downstream document that conflicts]"

**Section:** [Section reference in downstream document]

#### Issue

[Clear description of the discrepancy and why it's a problem]

#### Downstream Impact

[What happens if this isn't fixed - why does downstream care?]

#### Suggested Fix

[What the Alignment Verifier suggested, if any]

#### Clarifying Questions

[Questions that might help resolution, or "None"]

>> RESPONSE:

---

### PI-002: [Next issue...]

---

## Resolved Issues

### PI-003: [Brief title]

**Status:** RESOLVED
**Severity:** HIGH
**Logged:** YYYY-MM-DD
**Source:** PRD Review workflow, Round 2
**Resolved:** YYYY-MM-DD
**Resolution Round:** Blueprint Review Round 3
**Resolution:** [Brief description of how it was fixed]
**Concern key:** [*no-spec-change dismissals only* — spec-section anchor + one-line concern summary; the Consolidator matches incoming issues against this to suppress re-raises]

[Rest of original issue preserved for audit trail]

---
```

---

## Field Definitions

### Required Fields

| Field | Description |
|-------|-------------|
| **Status** | UNRESOLVED, AWAITS_UPSTREAM_REVISION, RESOLVED, DEFERRED, or WONT_FIX |
| **Kind** | `DISCREPANCY` (default — a conflict with an existing document), `CROSS-BOUNDARY-PEER` (a non-contract requirement on a peer component), or `CROSS-BOUNDARY-UPSTREAM` (a cross-cutting invariant / shared design decision escalated to Architecture/Foundations). See Cross-Boundary Requirements below. |
| **Severity** | SHOWSTOPPER, HIGH, MEDIUM, or LOW (from Alignment Verifier) |
| **Logged** | Date the issue was logged |
| **Source** | Which downstream workflow identified this. Standard format: `[Downstream stage] [Create\|Review] workflow, Round [N]`. Issue Router format: `Component Spec Review ([component]) - [Date]` with `Escalated by: Component Spec Issue Router` |
| **This Document States** | Exact quote from this (upstream) document |
| **Section** | Section reference for the quote |
| **Downstream Document States** | Exact quote from downstream document showing conflict |
| **Issue** | Clear description of the discrepancy |
| **Downstream Impact** | Why this matters to the downstream stage |

### Resolution Fields (when resolved)

| Field | Description |
|-------|-------------|
| **Resolved** | Date resolved |
| **Resolution Round** | Which Review round fixed it |
| **Resolution** | Brief description of the fix |
| **Concern key** | *(no-spec-change dismissals only)* Stable identifier — spec-section anchor + one-line concern summary — used by the Consolidator to suppress re-raises. Required when a mainline issue is closed **without** a spec edit (dismissed / won't-fix / working-as-intended), since the unchanged spec text would otherwise invite the same concern to be re-raised next round. Not needed for APPLIED-inline resolutions (the spec text changed). |

---

## Cross-Boundary Requirements

Two entry shapes share this file; the `Kind` field distinguishes them.

**DISCREPANCY** (default) — a conflict between this document and a downstream document, logged by the Alignment Verifier / Orchestrator. Uses the `This Document States` / `Downstream Document States` quote pair shown in the File Format above.

**CROSS-BOUNDARY-PEER (P1)** — a non-contract requirement one component needs a **peer** to uphold, where the peer can satisfy it entirely within its own spec. Written to the **target peer's** `pending-issues.md`; consumed at the peer's next **review** (Consolidator). This is how component-stage integration requirements are documented as components are developed.

**CROSS-BOUNDARY-UPSTREAM (P2)** — a cross-component invariant or shared design decision that **no single component owns** (audit-trail failure posture, retention coordination, a shared type/format). A component must not bind a peer to a system invariant, so it is escalated to **Architecture** (or Foundations) `pending-issues.md` with **`Status: AWAITS_UPSTREAM_REVISION`** — an open obligation on an already-completed stage, actioned when a human next runs that stage's revision workflow, never treated as silently resolved. The originating spec records the dependency as awaiting upstream revision so it stays visible on both ends.

Both cross-boundary kinds use the **lateral shape** (a `Target` component/stage, not a document-quote pair):

```markdown
### PI-[NNN]: [Brief summary]

**Status:** UNRESOLVED | AWAITS_UPSTREAM_REVISION
**Kind:** CROSS-BOUNDARY-PEER | CROSS-BOUNDARY-UPSTREAM
**Severity:** SHOWSTOPPER | HIGH | MEDIUM | LOW
**Logged:** [YYYY-MM-DD]
**Source:** [source-component] Spec [Create|Review], Round [N]
**Target:** [target-component | Architecture | Foundations]

#### Issue
[What the target needs to uphold, and why]

#### Suggested Change
[Specific recommendation for the target spec/stage]

#### Reference
See [source-component] spec Section [X].
```

See `docs/cross-boundary-requirements.md` for the full triage (P1 vs P2) and authority model.

---

## Consolidator Compatibility

The format is designed so Consolidator can read pending issues and merge them with expert-identified issues:

1. **ID format**: PI-001, PI-002, etc. (distinct from expert IDs like PROD-001)
2. **Severity**: Same scale as expert issues
3. **Section**: Same reference style
4. **Clarifying Questions + >> RESPONSE:**: Same pattern for human input
5. **Issue description**: Same level of detail expected

When Consolidator includes a pending issue, it adds:
- `**Source:** [PENDING ISSUE from: PRD Review]`
- `**Tag:** [BLOCKING DOWNSTREAM]`

---

## Staleness Detection

Consolidator should check if the quoted text still exists in the document:

1. Search for the exact quote in "This Document States"
2. If not found:
   - Flag as `[QUOTE NOT FOUND - document may have changed]`
   - Still include the issue (human decides if still relevant)
3. If section reference doesn't exist:
   - Flag as `[SECTION MOVED OR RENAMED]`

---

## Status Transitions

```
              Alignment Verifier / Issue Router
                    identifies issue
                           │
                           ▼
                    ┌─────────────┐
                    │ UNRESOLVED  │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
     Author applies   Human defers   Human rejects
      fix (APPLY)      (DEFER)        (REJECT)
              │            │            │
              ▼            ▼            ▼
       ┌──────────┐ ┌──────────┐ ┌──────────┐
       │ RESOLVED │ │ DEFERRED │ │ WONT_FIX │
       └──────────┘ └──────────┘ └──────────┘
```

DEFERRED and WONT_FIX are set by the Pending Issue Resolver based on human decisions during the review workflow (Step 11) or Stage Coherence Review (Phase 2).

**AWAITS_UPSTREAM_REVISION** is a variant of UNRESOLVED for `CROSS-BOUNDARY-UPSTREAM` (P2) escalations: the item is a live obligation on an already-completed upstream stage. It transitions to RESOLVED when that stage's next revision round actions it (and the change propagates downstream via the Alignment Verifier). It is never silently treated as resolved.

---

## Example

```markdown
# Pending Issues: Blueprint

Issues identified in this stage's document during downstream work.

---

## Summary

| Status | Count |
|--------|-------|
| UNRESOLVED | 1 |
| RESOLVED | 1 |

---

## Unresolved Issues

### PI-002: MVP scope contradicts phasing strategy

**Status:** UNRESOLVED
**Severity:** SHOWSTOPPER
**Logged:** 2025-12-10
**Source:** PRD Review workflow, Round 1

#### This Document States

> "MVP focuses on core discovery features only. Social features are Phase 2."

**Section:** MVP Definition

#### Downstream Document States

> "Users can share discoveries with friends and see friend activity in their feed."

**Section:** Capability 3.2 - Social Sharing

#### Issue

The PRD includes social sharing as an MVP capability, but the Blueprint explicitly defers social features to Phase 2. This is a direct contradiction about MVP scope.

#### Downstream Impact

PRD cannot proceed with social features in MVP without Blueprint alignment. Either Blueprint needs to include social in MVP, or PRD needs to remove it.

#### Suggested Fix

Clarify whether social sharing is MVP or Phase 2. If MVP, update Blueprint's MVP Definition. If Phase 2, PRD will remove from MVP capabilities.

#### Clarifying Questions

Was social sharing intentionally moved to MVP since Blueprint was written?

>> RESPONSE:

---

## Resolved Issues

### PI-001: Missing success metric for user retention

**Status:** RESOLVED
**Severity:** HIGH
**Logged:** 2025-12-08
**Source:** PRD Review workflow, Round 1
**Resolved:** 2025-12-09
**Resolution Round:** Blueprint Review Round 2
**Resolution:** Added 30-day retention target of 40% to Success Metrics section

[Original issue content preserved...]

---
```
