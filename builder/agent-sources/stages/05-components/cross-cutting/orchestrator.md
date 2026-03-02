# Cross-Cutting Population Orchestrator

---

## Purpose

Extract data contracts from completed component specs and populate the cross-cutting specification incrementally — one component at a time in dependency order. Each component goes through extraction, reconciliation, human review, and registration before proceeding to the next.

**Flow:** All specs promoted → Human invokes this orchestrator → Per-component: extract → reconcile → human review → register → Next component → Finalise

---

## When to Run

Run this orchestrator **manually** when:
- All application-layer component specs have been completed and promoted
- You want to establish a central contract registry for verification

**Invocation:**
```
Read the Cross-Cutting Population Orchestrator at:
{{AGENTS_PATH}}/05-components/cross-cutting/orchestrator.md

Populate cross-cutting specification from completed specs.
```

---

## Fixed Paths

**Cross-cutting spec**: `system-design/05-components/specs/cross-cutting.md`
**Component specs directory**: `system-design/05-components/specs/`
**Stage state**: `system-design/05-components/versions/workflow-state.md`
**Population state**: `system-design/05-components/versions/cross-cutting/population-state.md`
**Extraction output directory**: `system-design/05-components/versions/cross-cutting/extraction/`
**Reconciliation output directory**: `system-design/05-components/versions/cross-cutting/reconciliation/`
**Deferred items**: `system-design/05-components/versions/cross-cutting/deferred-items.md`

**Agent prompts**:
- `{{AGENTS_PATH}}/05-components/cross-cutting/contract-extractor.md`
- `{{AGENTS_PATH}}/05-components/cross-cutting/contract-reconciler.md`

---

## Processing Order

Components are processed in dependency order from the workflow-state.md Component Dependencies table:

| # | Component | Dependencies | Reconcile? |
|---|-----------|--------------|------------|
| 1 | event-directory | none | No |
| 2 | email-ingestion | event-directory | Yes |
| 3 | shared-llm-client | none | No |
| 4 | extraction-agent | event-directory, shared-llm-client | Yes |
| 5 | paraphrasing-agent | shared-llm-client | Yes |
| 6 | geocoding-module | event-directory, shared-llm-client | Yes |
| 7 | quality-gate-module | extraction-agent, paraphrasing-agent, geocoding-module | Yes |
| 8 | data-processing-job | email-ingestion, extraction-agent, paraphrasing-agent, geocoding-module, quality-gate-module | Yes |
| 9 | admin-api | event-directory, data-processing-job | Yes |
| 10 | consumer-api | event-directory | Yes |

These are build-order dependencies. The extractor discovers actual integration points from spec content.

---

## Orchestration Steps

**Immediate execution**: The user invoking this orchestrator IS the instruction to execute. Do not ask for confirmation before starting. Proceed immediately.

**IMPORTANT: File-First Principle**
- Do NOT pass file contents to agents
- Only pass file PATHS — agents read files themselves

**Orchestrator Boundaries**
- You READ state files and agent outputs
- You SPAWN agents to do work (via Task tool)
- You UPDATE state files with status changes
- You PRESENT findings to human and collect decisions
- You WRITE approved contracts to cross-cutting.md
- You DO NOT read agent prompt files — agents read their own instructions

Rule: If a file path appears in your agent invocation, don't read it yourself.

### Step 1: Validate Prerequisites

1. **Check cross-cutting.md exists** at `specs/cross-cutting.md`
   - **If NO**: Error — "Cross-cutting placeholder not found. Run the initialize orchestrator first."

2. **Read cross-cutting.md** and check status:
   - **If status is COMPLETE**: Warning — "Cross-cutting already populated. Re-running will replace existing contracts. Continue? (y/n)"
   - **If status is IN_PROGRESS**: Check for population state file and attempt resume (see Resume Support below)
   - **If status is DEFERRED**: Proceed with fresh population

3. **Find completed specs**:
   - List all `.md` files in `specs/` directory
   - Exclude `cross-cutting.md`
   - Verify against Processing Order table above
   - **If any required spec missing**: Error — "Missing spec(s): [list]. All 10 application-layer specs must be present."

4. **Create working directories** (use Bash with mkdir):
   - `versions/cross-cutting/`
   - `versions/cross-cutting/extraction/`
   - `versions/cross-cutting/reconciliation/`

5. **Initialise population state file** at `versions/cross-cutting/population-state.md` (see State File Format below)

6. **Update cross-cutting.md** status section:
   - Change `**Population**: DEFERRED` to `**Population**: IN_PROGRESS`
   - Add `**Started**: [date]`

7. **Report to human**:
   ```
   Cross-cutting population starting.

   Found 10 completed component specs.
   Processing in dependency order — will pause for review after each component.

   Starting with: event-directory (1/10)
   ```

8. **Proceed to Step 2**

### Step 2: Per-Component Loop

For each component in Processing Order (or resume from current component):

#### Step 2a: Extract

1. **Update population state**: Set current component status to EXTRACTING

2. **Determine next contract ID**: Read from population state `Next Contract ID` field

3. **Spawn Contract Extractor agent** (MUST spawn as subagent using Task tool — do NOT perform inline):
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/cross-cutting/contract-extractor.md

   Input:
   - Component spec: system-design/05-components/specs/[component-name].md
   - Cross-cutting spec: system-design/05-components/specs/cross-cutting.md
   - Next contract ID: CTR-[NNN]

   Output:
   - Extraction report: system-design/05-components/versions/cross-cutting/extraction/[component-name].md
   ```

4. **Read extraction report** — verify it was written and extract summary counts

5. **Update population state**: Mark extraction complete, record produced/consumed counts

6. **Proceed to Step 2b**

#### Step 2b: Reconcile

1. **Check if reconciliation needed**:
   - Read the extraction report's consumed interfaces section
   - **If no consumed interfaces** (component has no dependencies per Processing Order): Skip to Step 2c (Register). Do NOT mention reconciliation or PENDING_REGISTRATION — this component is a pure producer.
   - **If consumed interfaces exist and at least one producer has been processed**: Proceed to reconciliation (step 2)
   - **If consumed interfaces exist but NO producers have been processed yet**: Skip reconciliation, proceed to Step 2c. Note which producers are pending — these will be reconciled when those producers are processed later.

2. **Update population state**: Set current component status to RECONCILING

3. **Spawn Contract Reconciler agent** (MUST spawn as subagent using Task tool — do NOT perform inline):
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/cross-cutting/contract-reconciler.md

   Input:
   - Extraction report: system-design/05-components/versions/cross-cutting/extraction/[component-name].md
   - Cross-cutting spec: system-design/05-components/specs/cross-cutting.md
   - Component spec: system-design/05-components/specs/[component-name].md

   Output:
   - Reconciliation report: system-design/05-components/versions/cross-cutting/reconciliation/[component-name].md
   ```

4. **Read reconciliation report** — verify it was written and extract summary

5. **Update population state**: Mark reconciliation complete

6. **Proceed to Step 2c**

#### Step 2c: Register

All produced contracts are registered automatically. All mismatches are documented as NOTE.

1. **Update population state**: Set current component status to REGISTERING

2. **For each produced contract**, append to cross-cutting.md under `## 1. Data Contracts`:

   Group contracts by producer component. If this is the first contract for this producer, add a subsection header:

   ```markdown
   ### [producer-component]

   #### CTR-NNN: [contract_name]

   - **Producer**: [producer-component]
   - **Consumer(s)**: [consumer-1], [consumer-2]
   - **Status**: DEFINED
   - **Source**: [producer-component] spec, Section [N]

   ##### Schema

   [Schema verbatim from spec — dataclass definition, JSONB structure, function signature, etc.]

   ##### Consumer Expectations

   | Consumer | Required Fields | Notes |
   |----------|-----------------|-------|
   | [consumer-1] | [fields used] | [how they use it] |
   | [consumer-2] | [fields used] | [how they use it] |

   ##### Verification Notes

   *Registered [date] during cross-cutting population.*
   ```

3. **Handle mismatches**: For each mismatch found during reconciliation, append to the affected contract's Verification Notes: "Divergence noted: [consumer] expects [detail], producer provides [detail]. To be resolved during verification."

4. **Update Appendix: Contract Status Summary** table — add rows for each registered contract

5. **Update population state**:
   - Mark current component COMPLETE
   - Update `Next Contract ID` to next sequential value
   - Record contracts registered count
   - Add history entry

6. **Proceed to next component in Processing Order** (return to Step 2a). Do NOT pause or report between components.

### Step 3: Finalise

After all 10 components are processed:

1. **Update cross-cutting.md status section**:
   ```markdown
   ## Status

   **Population**: COMPLETE
   **Started**: [start date]
   **Completed**: [today's date]
   **Source Specs**: 10 component specs

   Contracts extracted incrementally in dependency order with reconciliation.
   Use contract verification in reviews to detect regressions.
   ```

2. **Add Shared Types section** — if any types were referenced across 3+ contracts, list them under `## 2. Shared Types`. Otherwise: `*No shared types identified across 3+ contracts.*`

3. **Add Source Traceability appendix**:
   ```markdown
   ## Appendix: Source Traceability

   | Contract ID | Producer | Source Spec | Source Sections |
   |-------------|----------|-------------|-----------------|
   | CTR-001 | [producer] | [component].md | §3 Interfaces, §7 Integration |
   | CTR-002 | [producer] | [component].md | §4 Data Model |
   | ... | | | |
   ```

4. **Add Reconciliation Summary appendix**:
   ```markdown
   ## Appendix: Reconciliation Summary

   | Consumer | Clean | Minor | Field | Structural | Gaps | Pending |
   |----------|-------|-------|-------|------------|------|---------|
   | email-ingestion | [N] | [N] | [N] | [N] | [N] | [N] |
   | extraction-agent | [N] | [N] | [N] | [N] | [N] | [N] |
   | ... | | | | | | |
   ```

5. **Deferred items validation**:
   - Read `system-design/05-components/versions/cross-cutting/deferred-items.md`
   - Find all PKG-* items that contain "register this contract" or "Contract Registration" (these are explicit contract registration requests from spec reviews)
   - For each such item, search the registered contracts in cross-cutting.md for a match by contract name, producer, and consumer
   - Classify each deferred items contract item:
     - **MATCHED** — a registered contract covers this deferred items entry
     - **GAP** — no registered contract matches. The extractor may have missed it or the spec may not describe it in the sections the extractor reads
   - Skip resolved items (Status: RESOLVED) and non-contract items (ARCH-*, FND-*, INF-*)
   - Record results for the final summary

6. **Update population state**: Set workflow status to COMPLETE

7. **Update stage state** (`versions/workflow-state.md`):
   - Add history entry: "[date]: Cross-cutting populated with [N] contracts from 10 component specs"

8. **Present final summary to human**:

   ```
   ## Cross-Cutting Population Complete

   **Output**: specs/cross-cutting.md
   **Contracts**: [N] defined
   **Components processed**: 10/10
   **Status**: COMPLETE

   ### Per-Component Breakdown

   | # | Component | Contracts | Consumed | Clean | Mismatches |
   |---|-----------|-----------|----------|-------|------------|
   | 1 | event-directory | [N] | - | - | - |
   | 2 | email-ingestion | [N] | [N] | [N] | [N] |
   | ... | | | | | |

   [If any mismatches were found:]

   ### Mismatches Documented

   These divergences were noted during reconciliation. They will be enforced
   by the contract verifier during future review rounds.

   | Consumer | Interface | Producer Contract | Classification | Summary |
   |----------|-----------|-------------------|----------------|---------|
   | [component] | [interface] | CTR-NNN | MINOR/FIELD/STRUCTURAL | [brief description] |
   | ... | | | | |

   ### Deferred Items Validation

   Cross-referenced registered contracts against contract registration
   requests from the cross-cutting deferred items.

   | Deferred Item | Contract | Producer | Consumer | Status |
   |------------------|----------|----------|----------|--------|
   | PKG-006 | email_sources Lookup | event-directory | email-ingestion | MATCHED (CTR-NNN) / GAP |
   | PKG-007 | EmailForProcessing | email-ingestion | extraction-agent | MATCHED (CTR-NNN) / GAP |
   | ... | | | | |

   [If any GAPs:]

   **Gaps found**: [N] deferred items contract registrations were not matched
   to registered contracts. Review the deferred items entries and extraction
   reports to determine if these need manual registration.

   ### Status

   **Cross-cutting population is complete. No further action required.**

   Cross-cutting.md is a contract registry — it does not go through the
   review workflow.

   Any mismatches documented above will be caught automatically by the
   contract verifier the next time a component spec goes through a review
   round. No manual intervention needed.

   ### Reference Files

   Full extraction reports: versions/cross-cutting/extraction/
   Full reconciliation reports: versions/cross-cutting/reconciliation/
   Population state: versions/cross-cutting/population-state.md
   Deferred items: versions/cross-cutting/deferred-items.md
   ```

9. **Return**: `{ status: "COMPLETE", contracts: [N], components: 10, mismatches: [M], deferred_items_gaps: [N] }`

---

## State File Format

`versions/cross-cutting/population-state.md`:

```markdown
# Cross-Cutting Population State

**Workflow Status**: INITIALISING | IN_PROGRESS | COMPLETE
**Started**: [date]
**Next Contract ID**: CTR-001

## Processing Order

| # | Component | Status | Contracts Registered |
|---|-----------|--------|---------------------|
| 1 | event-directory | PENDING | - |
| 2 | email-ingestion | PENDING | - |
| 3 | shared-llm-client | PENDING | - |
| 4 | extraction-agent | PENDING | - |
| 5 | paraphrasing-agent | PENDING | - |
| 6 | geocoding-module | PENDING | - |
| 7 | quality-gate-module | PENDING | - |
| 8 | data-processing-job | PENDING | - |
| 9 | admin-api | PENDING | - |
| 10 | consumer-api | PENDING | - |

## Current

**Component**: [component-name]
**Step**: EXTRACTING | RECONCILING | REGISTERING

## History

- [date]: Population workflow started
```

**Component statuses**: PENDING → EXTRACTING → RECONCILING → REGISTERING → COMPLETE

Update the state file at every step transition. This enables resume on interruption.

---

## Resume Support

On start, if population state file exists at `versions/cross-cutting/population-state.md`:

1. **Read population state**
2. **Check workflow status**:
   - **COMPLETE**: Report "Population already complete. Re-run? (y/n)" — if yes, start fresh
   - **IN_PROGRESS**: Resume from current component/step
3. **Resume logic**:
   - Check Processing Order table — if all 10 components show COMPLETE, skip directly to Step 3 (Finalise)
   - Otherwise, find current component and step from state:
     - **EXTRACTING**: Check if extraction report exists — if yes, proceed to RECONCILING; if no, re-run extraction
     - **RECONCILING**: Check if reconciliation report exists — if yes, proceed to REGISTERING; if no, re-run reconciliation
     - **REGISTERING**: Check what's already in cross-cutting.md — resume registration for unregistered contracts
4. **Report**: "Resuming cross-cutting population from [component-name], step [step]"

---

## Stopping Points

**The entire workflow runs automatically without human intervention.**

All contracts are registered and all mismatches are documented as NOTE. The only output to the human is the final summary at Step 3.

Do NOT pause between components. Do NOT ask "Should I proceed?" at any point. Process all 10 components, then present the summary.

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Cross-cutting.md not found | Error: "Run initialize orchestrator first" |
| Missing component spec | Error: "Missing spec(s): [list]" |
| Extraction agent fails | Error: report failure, retry once, then skip component and note in state |
| Reconciliation agent fails | Error: report failure, skip reconciliation for this component, register contracts without reconciliation |
| No contracts found for component | Register nothing, note in state, proceed to next |

---

## Compatibility

Contracts registered by this orchestrator are compatible with the existing contract verifier agents:
- CTR-NNN sequential IDs
- Producer/Consumer(s) fields
- Status: DEFINED (verifier transitions to VERIFIED on pass)
- Schema section with verbatim spec content
- Consumer Expectations table
- Verification Notes section

---

<!-- INJECT: tool-restrictions -->
