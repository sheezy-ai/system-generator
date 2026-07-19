# Stage Coherence Review Orchestrator

Verifies cross-component coherence before stage sign-off. Run after component specs are individually complete (or at checkpoints) to ensure specs work together as a coherent system.

---

## Purpose

Individual component reviews catch issues within a spec. This orchestrator catches issues *between* specs:
- Pending issues accumulated from other component reviews
- Contract alignment between producers and consumers
- Naming/schema consistency across components
- Dependencies declared but not compatible

---

## When to Run

- **Gate**: Before closing component specs stage (all components COMPLETE)
- **Checkpoint**: Periodically after several components complete (recommended every 3-4)
- **Ad-hoc**: When cross-component issues are suspected

**Invocation:**
```
Read the Stage Coherence Review Orchestrator at:
{{AGENTS_PATH}}/05-components/coherence/orchestrator.md

Run stage coherence review.
```

---

## Fixed Paths

**Stage state**: `system-design/05-components/versions/workflow-state.md`
**Component specs**: `system-design/05-components/specs/`
**Component versions**: `system-design/05-components/versions/`
**Cross-cutting spec**: `system-design/05-components/specs/cross-cutting.md`
**Coherence reports**: `system-design/05-components/versions/coherence/`

---

## Prerequisites

Before running:
1. At least 2 component specs should be COMPLETE
2. Stage workflow-state.md should exist

---

## Orchestration Flow

**Immediate execution**: The user invoking this orchestrator IS the instruction to execute. Proceed immediately with Phase 1 (state gathering). Present findings before applying changes.

### Phase 1: Gather State

1. **Read stage workflow-state.md** to identify component statuses
2. **Count components by status** — recognise the **full stage-index ladder** (`NOT_STARTED → CREATED → IN_PROGRESS → REVIEWED → COMPLETE`; 05P-1 added `CREATED`, 05P-2 added `REVIEWED`). Do **not** miscount `CREATED`/`REVIEWED` as `IN_PROGRESS` or `COMPLETE`:
   - COMPLETE (promoted — the only "ready" state)
   - REVIEWED (reviewed-but-not-promoted — **NOT ready**; a component here has passed Review but has not been frozen by its per-component Promote)
   - IN_PROGRESS
   - CREATED (create-terminal draft, not yet reviewed)
   - NOT_STARTED
   - **The "all COMPLETE" stage gate (Phase 6/7 freeze) requires every component at `COMPLETE`.** A component at `REVIEWED` (or `CREATED`/`IN_PROGRESS`/`NOT_STARTED`) means the stage is **not** ready to freeze.
3. **For each component with pending-issues.md**, count unresolved issues
4. **Read cross-cutting.md** to check population status (`MATERIALIZED`, or `COMPLETE`/reconciled)

**Present to human:**
```
Stage Coherence Review

Component Status:
- COMPLETE: [N] (list)
- REVIEWED: [N] (list)      # reviewed-but-not-promoted — NOT ready for stage freeze
- IN_PROGRESS: [N] (list)
- CREATED: [N] (list)
- NOT_STARTED: [N] (list)

Pending Issues: [N] unresolved across [M] components
Cross-Cutting Contracts: [MATERIALIZED with N contracts | reconciled (COMPLETE) with N contracts]

Phases to run:
1. Pending Issues Resolution - [N] issues to triage
2. Contract Conformance & Verification - body-check multi-producer/ownerless/interface-only MATERIALIZED contracts (→ DEFINED; single-real-component ones transition at their per-component promote) and verify producer/consumer alignment for all DEFINED contracts (DEFINED → VERIFIED)
3. Consistency Check - Scan for naming/schema drift
4. Cross-Boundary Routing Reconciliation - verify each spec's routing claims landed in the target's pending-issues

Proceed? (y/n)
```

---

### Phase 2: Pending Issues Resolution

1. **Aggregate all unresolved pending issues** from `versions/[component]/pending-issues.md`

2. **Group by target component**:
   ```
   ## Pending Issues by Target

   ### event-directory (8 issues)
   | ID | Source | Severity | Summary |
   |----|--------|----------|---------|
   | PI-001 | email-ingestion | MEDIUM | status enum missing 'rejected' |
   | PI-008 | quality-gate-module | MEDIUM | overall_confidence missing |
   ...

   ### [other-component] (N issues)
   ...
   ```

3. **For each issue, collect decision**:
   - **APPLY**: Resolve now (edit target spec)
   - **DEFER**: Leave for later (document reason)
   - **REJECT**: Won't fix (document reason)

4. **For each target component with APPLY decisions**:
   - Read the target component's spec
   - Apply the required changes (surgical edits only)
   - Update the component's pending-issues.md (move to Resolved section)

5. **Write resolution report** to `versions/coherence/[date]-pending-issues-resolution.md`

**Output:**
- Updated component specs (for APPLY decisions)
- Updated pending-issues.md files
- Resolution report

---

### Phase 4: Contract Conformance & Verification

**Prerequisite:** Cross-cutting.md must contain contract definitions — `MATERIALIZED` (frozen projections from the Promote freeze) and/or `DEFINED`/`VERIFIED` (already body-backed from prior rounds). This phase is **self-sufficient** — it performs the routine conformance itself; there is no separate reconciliation phase to run first. Iterate over **every** contract in the registry (do **not** narrow the sweep to a subset — the wholesale iteration over all contracts is what re-verifies ownerless composed-query/invariant contracts that no single producer review reaches). Two rungs, with a **producer-cardinality split on the first rung (05P-3)**:

- **`MATERIALIZED → DEFINED` (body-check) — this phase owns ONLY the multi-producer / ownerless / interface-only contracts.** For a `MATERIALIZED` entry whose `Producer(s)` is **not** a single real component — two or more producers, the ownerless collective `all domain components …` (comma-free but no owning component), or an interface-only producer like `Source Attribution interface (§7)` / `audit trail (§7)` — check the producer bodies against the frozen obligation/`Binds:` set and, on a clean check, transition it `MATERIALIZED → DEFINED` (a real body now backs it). This is exactly the ownerless/multi-producer wholesale sweep no single producer review reaches. A `MATERIALIZED` entry whose **sole producer is one real component** is body-checked and transitioned to `DEFINED` at **that component's per-component Promote gate** (`promote/orchestrator.md` Step 2), **not here** — leave it untouched (it is not stranded: its producer's promote is its home).
- **`DEFINED → VERIFIED` (consumer alignment) — this phase owns ALL of them (any producer cardinality).** For a `DEFINED` entry, verify producer/consumer alignment and, on a pass, transition it `DEFINED → VERIFIED`. Nothing else checks consumer-side alignment, so this rung is never narrowed.

1. **Read cross-cutting.md** to get contract definitions

2. **Build contract matrix**:
   ```
   | Contract | Producer | Consumers | Status |
   |----------|----------|-----------|--------|
   | quality_metadata | quality-gate-module | event-directory | VERIFY |
   | ExtractionData | extraction-agent | quality-gate-module | VERIFY |
   ...
   ```

3. **For each contract**, verify alignment:
   - Read producer spec's output schema
   - Read consumer spec's input expectations
   - Compare field names, types, required/optional
   - Flag mismatches

4. **Present mismatches to human**:
   ```
   Contract Mismatches Found: [N]

   ### CTR-001: quality_metadata
   Producer: quality-gate-module
   Consumer: event-directory

   | Field | Producer | Consumer | Issue |
   |-------|----------|----------|-------|
   | overall_confidence | required, top-level | missing | Consumer schema doesn't include field |

   Resolution options:
   - UPDATE_CONSUMER: a pure consumer-side realization fix (the consumer spec misreads a correctly-frozen contract) — apply locally to the consumer spec
   - ESCALATE_UPSTREAM: the mismatch implies the **frozen contract itself** is wrong (its obligation / `Binds:` set needs changing) — an authority-level (04) decision, **not** a local edit. Write a `CROSS-BOUNDARY-UPSTREAM` entry to `system-design/04-architecture/versions/pending-issues.md` (`Status: AWAITS_UPSTREAM_REVISION`) → backward edge → the next Promote re-freeze projects the corrected contract from §7/§8. Never rewrite the producer to match the consumer locally (05 owns status, 04 owns obligations)
   - DEFER: Leave for manual resolution
   ```

5. **Apply resolutions** based on human decisions

6. **Update contract status** in cross-cutting.md: a **multi-producer / ownerless / interface-only** `MATERIALIZED` entry with a clean producer body-check → `DEFINED` (a **single-real-component** `MATERIALIZED` entry transitions at its producer's per-component Promote gate, **not here** — per the split above; leave it untouched); a `DEFINED` entry (any producer cardinality) that passes producer/consumer alignment → `VERIFIED`. **Preserve the `DEFINED` rung** — it is the `contract-verifier`'s regression-demote target and the Slice-4 re-freeze reset state; never collapse `MATERIALIZED → VERIFIED` directly (a materialized contract must be body-backed as `DEFINED` before it can be consumer-verified as `VERIFIED`)

**Output:**
- Contract verification report
- Updated specs (if mismatches resolved)
- Updated cross-cutting.md (contract statuses)

---

### Phase 5: Consistency Check

1. **Scan all COMPLETE specs for common patterns**:

   **Enums to check:**
   - FlagReason values
   - Disposition types
   - Status enums

   **Naming conventions:**
   - Field naming (snake_case consistency)
   - Timestamp field names (created_at vs createdAt)
   - Boolean field prefixes (is_, has_)

   **Schema patterns:**
   - Confidence score ranges (0.0-1.0)
   - Timestamp formats (ISO8601)
   - Optional field handling

2. **Flag inconsistencies**:
   ```
   Consistency Issues Found: [N]

   ### CONS-001: Enum value mismatch
   Pattern: FlagReason enum
   - event-directory: LOW_CONFIDENCE, SIMILARITY_FLAGGED, ...
   - quality-gate-module: LOW_CONFIDENCE, SIMILARITY_FLAGGED, ...
   Status: CONSISTENT

   ### CONS-002: Field naming inconsistency
   Pattern: structure similarity field
   - paraphrasing-agent: structure_similar
   - event-directory: structure_mirrored
   Status: INCONSISTENT - should align
   ```

3. **Collect decisions** for inconsistencies (which spec is authoritative?)

4. **Apply fixes** based on decisions

**Output:**
- Consistency report
- Updated specs (if inconsistencies resolved)

---

### Phase 5b: Cross-Boundary Routing Reconciliation

Verify that every cross-boundary requirement a component spec *claims* to have routed actually exists in the target's `pending-issues.md`. Component specs author **inside-out** (a component reads only its own `pending-issues.md`, not peer specs), so a routing claim that never landed in the target is a **silently-lost obligation** the moment that target is authored.

1. **Invoke the Cross-Boundary Routing Reconciler** (stage-wide mode):
   ```
   Read the Cross-Boundary Routing Reconciler at:
   {{AGENTS_PATH}}/05-components/coherence/cross-boundary-routing-reconciler.md

   Reconcile cross-boundary routing claims against target pending-issues (stage-wide).
   ```

2. **Read the reconciler's verdict** (`RECONCILED` | `GAPS`).

3. **On `GAPS`**: present the routing worklist to the human — each claimed-but-unlanded obligation must be written into its named target's `pending-issues.md` (a `CROSS-BOUNDARY-PEER` / `CROSS-BOUNDARY-UPSTREAM` entry per `guides/pending-issues-format.md`) before that target is authored, or it is lost at inside-out authoring. This phase **reports**, it does not auto-route; writing the entries is a human/orchestrator action. (The same reconciler runs as a **hard gate at create Step 1** before a `NOT_STARTED` component is authored — so a miss targeting a not-yet-authored component is caught there too.)

**Output:** the routing-reconciliation report (`versions/coherence/[date]-routing-reconciliation.md`); any GAPS surfaced as the routing worklist.

---

### Phase 6: Coherence Report

Compile all findings into `versions/coherence/[date]-coherence-report.md`:

```markdown
# Stage Coherence Report

**Date**: YYYY-MM-DD
**Components Reviewed**: [N] COMPLETE, [M] IN_PROGRESS
**Status**: [COHERENT | ISSUES_REMAINING]

## Summary

| Phase | Issues Found | Resolved | Remaining |
|-------|--------------|----------|-----------|
| Pending Issues | 12 | 10 | 2 (deferred) |
| Contract Verification | 3 | 3 | 0 |
| Consistency Check | 2 | 2 | 0 |
| Routing Reconciliation | [claims] | [routed] | [gaps] |
| **Total** | 17 | 15 | 2 |

## Blocking Issues

[Any issues that must be resolved before stage sign-off]

## Deferred Issues

| Issue | Reason | Owner |
|-------|--------|-------|
| PI-003 | Waiting for DPJ spec | - |

## Documents Updated

| Document | Changes |
|----------|---------|
| specs/event-directory.md | PI-001, PI-008 applied |
| specs/cross-cutting.md | Contracts verified |

## Recommendations

- [Any follow-up actions recommended]

## Sign-Off

[ ] All blocking issues resolved
[ ] Cross-cutting contracts materialized/reconciled and verified
[ ] Consistency issues addressed
[ ] Cross-boundary routing claims reconciled (no stranded obligations)
[ ] Ready for implementation phase
```

**This sign-off is the whole-stage 05 freeze (05P-5).** When this coherence run is the **all-COMPLETE gate run** (every component at stage-index `COMPLETE`, per the "When to Run" Gate) **and** the `## Blocking Issues` list above is empty, the sign-off is clean and Phase 7 **freezes the stage** (stamps the `Stage-Frozen-At` token + `## Frozen Components` manifest that gates 06). If there are blocking issues, the freeze does **not** happen — the `## Blocking Issues` verdict is the stage HALT.

---

### Phase 7: Update Stage State — and, on a clean all-COMPLETE sign-off, FREEZE the stage

1. **Add history entry** to `versions/workflow-state.md`:
   ```
   - YYYY-MM-DD: Coherence review completed ([N] issues resolved, [M] deferred)
   ```

2. **Determine whether this run freezes the stage.** This coherence run is the whole-stage 05 freeze (the 05→06 gate) **only if BOTH hold**:
   - **Every component is at stage-index `COMPLETE`** in the Component Specs table (all promoted). A component at `REVIEWED` (reviewed-but-not-promoted), `IN_PROGRESS`, `CREATED`, or `NOT_STARTED` means the stage is **not** ready — do not freeze. AND
   - **No blocking issues** remain in the Phase 6 sign-off (`## Blocking Issues` empty / all resolved).

   A **checkpoint** run (some components not yet `COMPLETE`) is **non-freezing**: record the history entry (sub-step 1), report the coherence results, and stop — do **not** stamp.

3. **All-COMPLETE but blocking issues remain → do NOT stamp; HALT.** Report the blockers as the reason the stage cannot be frozen:
   ```
   Stage cannot be frozen — [N] blocking issue(s) must be resolved before stage sign-off:
   - [blocking issue 1]
   - ...
   Resolve them (route each back to the relevant component's Review/Promote), then re-run the coherence stage sign-off.
   ```
   This is the whole-stage HALT (coherence's own `## Blocking Issues` verdict is the gate).

4. **Clean all-COMPLETE sign-off → STAMP the freeze** into `versions/workflow-state.md`:
   - Add a **`**Stage-Frozen-At**: [date] — coherence sign-off`** marker to the `## Stage Initialization` block (so it lives beside the stage status).
   - Write a **`## Frozen Components`** manifest — every component and the Promote round that froze it. Determine each component's promote round from its per-component record: the highest `round-N-promote/` directory under `versions/[component]/` (the filesystem is the source of truth for round numbering, matching `promote/orchestrator.md`). Use Glob to enumerate them.
     ```markdown
     ## Frozen Components

     Stage frozen at coherence sign-off — every component below is promoted (`specs/[component].md` published). 06-tasks gates its start on this manifest (the `Stage-Frozen-At` marker + coverage of its processing order).

     | Component | Promote Round | Frozen |
     |-----------|---------------|--------|
     | [component-1] | round-[N]-promote | YYYY-MM-DD |
     | [component-2] | round-[N]-promote | YYYY-MM-DD |
     | ... | ... | ... |
     ```

5. **Report completion** to human. On a freeze: state that the stage is frozen (`Stage-Frozen-At` stamped, [N] components in the manifest) and 06-tasks may now start. Otherwise: report the coherence results only (checkpoint) or the blockers (HALT).

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Fewer than 2 COMPLETE components | Error: "Need at least 2 complete components to review coherence" |
| All components COMPLETE but blocking issues remain (Phase 7 freeze) | Do NOT stamp `Stage-Frozen-At`. HALT: "Stage cannot be frozen — [N] blocking issue(s) must be resolved before stage sign-off. Resolve and re-run coherence." |
| Not all components COMPLETE (Phase 7 freeze) | Non-freezing checkpoint run — record history, report results, do not stamp |
| Human aborts mid-phase | Save progress, report partial completion |

---

## Agents/Orchestrators Referenced

| Agent | Purpose | Invocation |
|-------|---------|------------|
| Cross-Boundary Routing Reconciler | Verify routing claims landed in target pending-issues | Phase 5b (stage-wide); also the create Step 1 authoring gate |

**Note:** This orchestrator handles pending issue resolution and consistency checking directly rather than delegating to separate agents, as the logic is straightforward and context-dependent.

---

## Tool Restrictions

- Use **Read**, **Write**, **Edit**, **Glob**, and **Grep** tools
- Do NOT use Bash (except `mkdir` for creating coherence folder)
- Do NOT use WebFetch or WebSearch
