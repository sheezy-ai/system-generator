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
2. **Count components by status**:
   - COMPLETE
   - IN_PROGRESS
   - NOT_STARTED
3. **For each component with pending-issues.md**, count unresolved issues
4. **Read cross-cutting.md** to check population status (`MATERIALIZED`, or `COMPLETE`/reconciled)

**Present to human:**
```
Stage Coherence Review

Component Status:
- COMPLETE: [N] (list)
- IN_PROGRESS: [N] (list)
- NOT_STARTED: [N] (list)

Pending Issues: [N] unresolved across [M] components
Cross-Cutting Contracts: [MATERIALIZED with N contracts | reconciled (COMPLETE) with N contracts]

Phases to run:
1. Pending Issues Resolution - [N] issues to triage
2. Cross-Cutting Reconciliation - [Reconcile bodies vs materialized registry | Already reconciled | Skip]
3. Contract Verification - [Available (contracts present) | Requires materialization/population first]
4. Consistency Check - Scan for naming/schema drift
5. Cross-Boundary Routing Reconciliation - verify each spec's routing claims landed in the target's pending-issues

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

### Phase 3: Cross-Cutting Conformance

1. **Check cross-cutting.md status**:
   - **If MATERIALIZED**: Ask human whether to run **conformance reconciliation** now — reconcile the realized bodies against the up-front materialized registry (the populate orchestrator handles this mode)
   - **If COMPLETE** (already reconciled): Ask human whether to refresh (re-reconcile from current specs)
   - **If human declines**: Skip to Phase 4

2. **If reconciling**, invoke the Cross-Cutting Population Orchestrator:
   ```
   Read the Cross-Cutting Population Orchestrator at:
   {{AGENTS_PATH}}/05-components/cross-cutting/orchestrator.md

   Populate cross-cutting specification from completed specs.
   ```

3. **Wait for completion** before proceeding

**Note:** This phase delegates to the existing cross-cutting orchestrator rather than duplicating its logic.

---

### Phase 4: Contract Verification

**Prerequisite:** Cross-cutting.md must contain contract definitions — `MATERIALIZED` (frozen projections) or `COMPLETE`/reconciled (body-backed). Against a purely `MATERIALIZED` registry not yet reconciled (Phase 3), verification checks each realized spec against the frozen obligation/`Binds:` set; running Phase 3 reconciliation first is preferable so entries are body-backed (`DEFINED`).

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
   - UPDATE_CONSUMER: Add field to consumer spec
   - UPDATE_PRODUCER: Change producer to match consumer
   - DEFER: Leave for manual resolution
   ```

5. **Apply resolutions** based on human decisions

6. **Update contract status** in cross-cutting.md (DEFINED → VERIFIED)

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

---

### Phase 7: Update Stage State

1. **Add history entry** to `versions/workflow-state.md`:
   ```
   - YYYY-MM-DD: Coherence review completed ([N] issues resolved, [M] deferred)
   ```

2. **Report completion** to human

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Fewer than 2 COMPLETE components | Error: "Need at least 2 complete components to review coherence" |
| Human aborts mid-phase | Save progress, report partial completion |

---

## Agents/Orchestrators Referenced

| Agent | Purpose | Invocation |
|-------|---------|------------|
| Cross-Cutting Population Orchestrator | Extract and populate contracts | Phase 3 (delegation) |
| Cross-Boundary Routing Reconciler | Verify routing claims landed in target pending-issues | Phase 5b (stage-wide); also the create Step 1 authoring gate |

**Note:** This orchestrator handles pending issue resolution and consistency checking directly rather than delegating to separate agents, as the logic is straightforward and context-dependent.

---

## Tool Restrictions

- Use **Read**, **Write**, **Edit**, **Glob**, and **Grep** tools
- Do NOT use Bash (except `mkdir` for creating coherence folder)
- Do NOT use WebFetch or WebSearch
