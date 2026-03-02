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

**Immediate execution**: The user invoking this orchestrator IS the instruction to execute. Do not ask for confirmation before starting. Proceed immediately.

### Phase 1: Gather State

1. **Read stage workflow-state.md** to identify component statuses
2. **Count components by status**:
   - COMPLETE
   - IN_PROGRESS
   - NOT_STARTED
3. **For each component with pending-issues.md**, count unresolved issues
4. **Read cross-cutting.md** to check population status (DEFERRED or POPULATED)

**Present to human:**
```
Stage Coherence Review

Component Status:
- COMPLETE: [N] (list)
- IN_PROGRESS: [N] (list)
- NOT_STARTED: [N] (list)

Pending Issues: [N] unresolved across [M] components
Cross-Cutting Contracts: [DEFERRED | POPULATED with N contracts]

Phases to run:
1. Pending Issues Resolution - [N] issues to triage
2. Cross-Cutting Population - [Required | Already populated | Skip]
3. Contract Verification - [Available | Requires cross-cutting population first]
4. Consistency Check - Scan for naming/schema drift

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

### Phase 3: Cross-Cutting Population

1. **Check cross-cutting.md status**:
   - **If DEFERRED**: Ask human whether to populate now
   - **If POPULATED**: Ask human whether to refresh (re-extract from current specs)
   - **If human declines**: Skip to Phase 4

2. **If populating**, invoke the Cross-Cutting Population Orchestrator:
   ```
   Read the Cross-Cutting Population Orchestrator at:
   {{AGENTS_PATH}}/05-components/cross-cutting/orchestrator.md

   Populate cross-cutting specification from completed specs.
   ```

3. **Wait for completion** before proceeding

**Note:** This phase delegates to the existing cross-cutting orchestrator rather than duplicating its logic.

---

### Phase 4: Contract Verification

**Prerequisite:** Cross-cutting.md must be POPULATED. If DEFERRED, skip this phase with warning.

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
[ ] Cross-cutting contracts populated and verified
[ ] Consistency issues addressed
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
| No COMPLETE components | Error: "Need at least 1 complete component to review coherence" |
| No pending issues and cross-cutting DEFERRED | Warning: "No issues to resolve and contracts not populated - consider running cross-cutting population" |
| Human aborts mid-phase | Save progress, report partial completion |

---

## Agents/Orchestrators Referenced

| Agent | Purpose | Invocation |
|-------|---------|------------|
| Cross-Cutting Population Orchestrator | Extract and populate contracts | Phase 3 (delegation) |

**Note:** This orchestrator handles pending issue resolution and consistency checking directly rather than delegating to separate agents, as the logic is straightforward and context-dependent.

---

## Tool Restrictions

- Use **Read**, **Write**, **Edit**, **Glob**, and **Grep** tools
- Do NOT use Bash (except `mkdir` for creating coherence folder)
- Do NOT use WebFetch or WebSearch
