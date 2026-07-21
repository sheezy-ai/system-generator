# Component Specs Stage Orchestrator

---

## Purpose

One-time stage-level setup before creating any component specs. Run this once at the start of the Component Specs stage to:
- Create folder structure for all components
- Split the monolithic deferred items into component-specific files
- Verify the frozen contract registry (materialized + fidelity-checked by the Promote stage) is present before fan-out — 05-init consumes it, it no longer produces it
- Author step-0 schema-specs for §7 cross-cutting interfaces whose schema layer is deferred (a shared schema components may adopt by reference — not a gate)
- Initialize pending-issues files for each component
- Initialize the workflow state file

**Flow:** Stage Orchestrator (this) → Per-component: Component Orchestrator → Human augments → Review workflow

---

## When to Run

Run this orchestrator **once** at the start of the Component Specs stage, after the Architecture is complete.

**Invocation:**
```
Read the Component Specs stage orchestrator at:
{{AGENTS_PATH}}/05-components/initialize/orchestrator.md

Initialize Component Specs for:
- Architecture Overview: system-design/04-architecture/architecture.md

Run the initialization.
```

---

## Process

**Immediate execution**: The user invoking this orchestrator IS the instruction to execute. Do not ask for confirmation before starting. Proceed immediately with Step 1.

### Step 1: Read Component List and Compute Priority

**Precondition — the frozen contract registry must already exist (produced by Promote).** Before any component work, assert `system-design/05-components/specs/cross-cutting.md` exists with a materialized `Population` status (`MATERIALIZED`). If it is **absent**, or its `Population` is `MATERIALIZING` (an interrupted freeze) or any non-materialized value → **Error**: "The frozen contract registry is not present. Run the Promote stage (which materializes it) before initializing Component Specs." 05-init **consumes** the frozen registry — as of Slice 4 it no longer produces it (materialization + fidelity were relocated to the Promote stage).

**Precondition — freeze-identity check (the registry must not be stale relative to the current architecture).** Read the `**Frozen-At**` value from the registry `Status` block (`system-design/05-components/specs/cross-cutting.md`) and the `**Frozen-At**` value from the current `architecture.md` header (`system-design/04-architecture/architecture.md`), then:
- **Both present and equal** → the registry was frozen from the current architecture. **Proceed.**
- **Both present but they differ** → **Error (stale)**: "The contract registry (`Frozen-At: [X]`) is stale relative to the current architecture (`Frozen-At: [Y]`) — re-run the Promote stage to re-freeze before initializing Component Specs." (Catches the promote-HALT case: `architecture.md` is round-N but the still-published registry at 05-specs is round-(N-1).)
- **Either token absent** (a pre-Slice-6 artifact produced before freeze identity was stamped) → this is **not** a staleness error. **Require re-promote**, worded as identity-stamping: "Freeze identity not established (pre-Slice-6 artifact) — re-run the Promote stage to stamp `Frozen-At` before initializing Component Specs." Do **not** report a missing token as stale (no false-positive). This guarantees the token is always present going forward.

Comparison is **equality of the `round-[N]-promote` id strings only** — no ordering, recency, or comparison beyond equality (that would be ledger machinery, deferred).

1. **Read Architecture Overview** to find the Component Spec List section (§6)

2. **Extract components**:
   - Component name
   - Dependencies (from the Dependencies column of the §6 table)

3. **Validate** the component list is not empty

4. **Classify each dependency** as cross-cutting or component:
   - **Cross-cutting**: dependencies containing "(cross-cutting)" in their description — e.g., `audit-trail (cross-cutting interface)`, `source-attribution (cross-cutting interface)`, `compliance-gate (cross-cutting utility)`. These are pre-satisfied (step 0) and do not block component creation.
   - **Partial/scoped**: dependencies containing "scoped to" or "only" — e.g., `events (scoped to find_entities_by_source only)`. These are non-blocking for priority computation. The component can be fully specced except for the scoped capability. Record the partial dependency in the table but do not count it as blocking.
   - **Full component**: all other dependencies — e.g., `entities`, `events`, `pipeline`. These are blocking.

5. **Compute priority tiers** via topological sort on blocking dependencies. **Priority is advisory, not a blocking gate.** This stage runs against the **frozen contract registry** (the precondition asserted above): every cross-component dependency in the §6 table is already discharged by a frozen contract, and each component spec is authored against the Architecture + the registry — **never against a sibling component spec**. Components are therefore all authorable **in parallel**; the tier is only a soft convenience ordering (foundational data-owners first), not a constraint on when a spec can be written.
   - **Tier 1**: components with no blocking component dependencies (only cross-cutting and/or partial)
   - **Tier 2**: components whose blocking dependencies are all in tier 1
   - **Tier 3**: components whose blocking dependencies are all in tiers 1-2
   - Continue until all components are assigned a tier
   - **If a cycle is detected** (two or more components that depend on each other): this is **not** an error. Under the frozen contract registry a mutual dependency is discharged by the frozen contracts on both edges (a producer and consumer that each read the other via a frozen CTR is expected and fine), so it does not block authoring. Collapse the cycle: assign every component in it the **same tier** — the highest tier among their *non-cycle* blocking dependencies, or Tier 1 if they have none — and continue.

6. **Do NOT read or use the Architecture's "Spec creation order" narrative** for priority. The narrative is advisory documentation. Priority is derived from the dependency graph — this prevents drift between stated priority and actual dependencies.

**Note on the Architecture's "Spec creation order"**: The Architecture §6 contains a prose section describing spec creation order. This section may conflate product-phase ordering with technical dependencies (e.g., grouping components by "Phase 1b" rather than by actual dependency). The orchestrator ignores this narrative and computes priority mechanically from the Dependencies column.

### Step 2: Create Folder Structure

1. **Create directories**:
   ```
   system-design/05-components/
   ├── specs/                          # Final output (create if not exists)
   └── versions/
       ├── cross-cutting/              # Cross-cutting deferred items
       ├── [component-1]/              # One folder per component
       ├── [component-2]/
       └── ...
   ```

2. **For each component** from the Component Spec List:
   - Create `versions/[component-name]/`
   - Create `versions/[component-name]/pending-issues.md`:
     ```markdown
     # Pending Issues: [component-name]

     Issues discovered that need resolution before or during spec work.

     ---

     <!-- No issues logged yet -->
     ```
   - Create `versions/[component-name]/workflow-state.md`:
     ```markdown
     # [component-name] Workflow State

     **Component**: [component-name]
     **Spec**: 05-components/specs/[component-name].md
     **Architecture Overview**: 04-architecture/architecture.md
     **Foundations**: 03-foundations/foundations.md
     **PRD**: 02-prd/prd.md
     **Current Round**: -
     **Current Part**: -
     **Current Step**: -
     **Status**: NOT_STARTED

     ## Progress

     *No review rounds yet.*

     ## Upstream Freshness (reconciled-against)

     Per-edge reconciled-against `Frozen-At` for this component's direct alignment sources (02/03/04). Populated at the first Review completion (from the AV-read token); read + gated at this component's Promote guard (Step 1b) and blocking at the coherence stage sign-off. Absent until the first Review round whose Alignment Verifier ran.

     - 02-prd:          (not yet reconciled)
     - 03-foundations:  (not yet reconciled)
     - 04-architecture: (not yet reconciled)

     ## History

     - YYYY-MM-DD: Initialized
     ```

3. **Create** `versions/cross-cutting/`

### Step 3: Process Deferred Items

1. **Check if monolithic deferred items file exists** at `system-design/05-components/versions/deferred-items.md`

2. **If empty or doesn't exist**: Skip to Step 4

3. **If has content**: Use the **Task tool** to spawn a sub-agent:
   - **subagent_type**: `general-purpose`
   - **prompt**:
     ```
     Follow the instructions in: {{AGENTS_PATH}}/05-components/initialize/deferred-items-processor.md

     Input:
     - Monolithic deferred items: system-design/05-components/versions/deferred-items.md
     - Architecture Overview: system-design/04-architecture/architecture.md

     Output directory: system-design/05-components/versions/
     ```

4. **After agent completes**: Verify component-specific deferred items files were created and original was archived

5. **Backfill empty deferred-items stubs**: The processor writes a `deferred-items.md` only for components that received items. For every component from the Component Spec List whose `versions/[component-name]/deferred-items.md` does NOT exist, create an empty stub so the post-init invariant holds (every component folder contains `deferred-items.md`):
   ```markdown
   # Deferred Items: [component-name]

   Items deferred from upstream stages, relevant to this component.

   ---

   <!-- No deferred items for this component -->
   ```
   Components that already have a `deferred-items.md` (processor wrote items) are left unchanged.

### Step 3a: Author Step-0 Cross-Cutting Interface Schema-Specs

For each §7 cross-cutting **interface** whose schema layer Architecture leaves unpinned (schema / write-signature / posture / reason-taxonomy / retention deferred to component level), author a **step-0 schema-spec** up-front so the several components that write/read it realize **one shared schema** instead of each improvising a divergent one. This is the schema-layer complement to the **frozen CTR registry** (`specs/cross-cutting.md`, materialized + fidelity-checked upstream by the Promote stage) — it authors interface schema-specs, a separate artifact from the CTR registry, and does not read or write that registry.

**No gate.** The schema-specs are **step-0 artifacts nothing is forced to consume** — a component that writes/reads an interface **may** adopt one by reference, but component creation does **not** block on them. Do not treat a schema-spec as a prerequisite for any component.

1. **Create** the output directory `system-design/05-components/specs/cross-cutting-interfaces/` (empty target; the author writes into it).

2. **Spawn Cross-Cutting Interface Schema-Author** using the Task tool:
   - **subagent_type**: `general-purpose`
   - **prompt**:
     ```
     Follow the instructions in: {{AGENTS_PATH}}/05-components/initialize/interface-schema-author.md

     Input:
     - Architecture Overview: system-design/04-architecture/architecture.md
     - PRD: system-design/02-prd/prd.md
     - Interface-schemas output directory: system-design/05-components/specs/cross-cutting-interfaces/

     Output:
     - Schema-specs (one per qualifying interface): system-design/05-components/specs/cross-cutting-interfaces/[interface-name].md
     - Authoring report: system-design/05-components/versions/cross-cutting/interface-schemas.md
     ```

3. **After agent completes**: Verify the authoring report was written. Read its authored/skipped counts. **Zero interfaces authored is a valid outcome** (none qualified under the selection rule) — not an error. Surface the counts in the Step 5 summary.

### Step 3b: Generate Project Scale Reference

1. **Check if `system-design/project-scale.md` already exists**:
   - **If yes**: Skip this step. The file may be a retrofit or a manually-revised instance — preserve it.
   - **If no**: Continue.

2. **Spawn Project Scale Generator** using the Task tool:
   - **subagent_type**: `general-purpose`
   - **prompt**:
     ```
     Follow the instructions in: {{AGENTS_PATH}}/05-components/initialize/project-scale-generator.md

     Input:
     - Project Scale Guide: {{GUIDES_PATH}}/project-scale-guide.md
     - PRD: system-design/02-prd/prd.md
     - Foundations: system-design/03-foundations/foundations.md
     - Architecture Overview: system-design/04-architecture/architecture.md

     Output: system-design/project-scale.md
     ```

3. **After agent completes**: Verify `system-design/project-scale.md` was created at the expected path.

4. **Human review gate** — present the generated file to the user and halt:

   ```
   Project scale reference generated at system-design/project-scale.md.

   Review gate: confirm extracted values, component classifications, and taxonomy mapping before initialization continues.

   Respond with:
   - "approved" — initialization continues with Step 4
   - Specific edits — describe the changes; I'll apply them and re-present
   - Redraft — I'll re-run the generator with any tightened prompt guidance

   Initialization waits here.
   ```

   Do not proceed to Step 4 without explicit human approval.

5. **Rationale**: `project-scale.md` is the canonical scale-context reference consumed by the Stage-Appropriateness Verifier and producer prompts. The generator produces a first draft from PRD + Architecture extraction; the human gate validates before downstream agents consume it.

### Step 4: Create Stage State File

1. **Create** `system-design/05-components/versions/workflow-state.md` (stage-level state):

```markdown
# Component Specs Workflow State

## Stage Initialization

**Status**: COMPLETE
**Initialized**: YYYY-MM-DD

- [x] Frozen contract registry verified present (materialized by Promote)
- [x] Component folders created
- [x] Per-component state files created

**Decomposition-membership edge (no recorded watermark needed).** The Tier-2 decomposition-membership detector (fired from Architecture Promote on a §6 roster change) is **history-independent**: it diffs the **instantiated component set** (the Component Specs table rows below) against the **current** Architecture §6 directly, so it needs no recorded "decomposed-from" token here. The stage-index rows themselves ARE the realized-membership record the detector reads.

## Component Specs

| Component | Status | Current | Last Updated |
|-----------|--------|---------|--------------|
| [component-1] | NOT_STARTED | - | - |
| [component-2] | NOT_STARTED | - | - |
| ... | NOT_STARTED | - | - |

## Component Dependencies

| Component | Priority | Dependencies |
|-----------|----------|--------------|
| [component-1] | 1 | - |
| [component-2] | 2 | [component-1] |
| ... | N | ... |

## Retired Components

Audit record of components removed from the stage after Architecture §6 dropped them (written by the **retire** orchestrator — `05-components/retire/orchestrator.md`). **Status-less by design** — a retired component is NOT in the live component set (`## Component Specs` above); no status-keyed reader (the decomposition-membership detector's instantiated-set read, the coherence status count, the all-COMPLETE freeze gate) counts these rows, so a retired component can never re-flag as ORPHANED or block the freeze. Archives are reversible (see the archive locations). Empty at initialization — a component is added here only when it is retired.

| Component | Retired | Reason | Archived (versions) | Archived (spec) | Rename hint |
|-----------|---------|--------|---------------------|-----------------|-------------|
| *(none retired yet)* | | | | | |

## History

- YYYY-MM-DD: Initialization complete. N components ready for spec creation.
```

2. **Populate tables** using Step 1 results:
   - Component Specs table: all components, alphabetically sorted, all NOT_STARTED
   - Component Dependencies table: ordered by computed priority tier, with dependencies from the Architecture §6 table. The Priority column contains the computed tier (from Step 1), not a value copied from the Architecture's narrative. Cross-cutting dependencies are listed in the Dependencies column but do not affect priority. Partial/scoped dependencies are listed with their scope note.

### Step 5: Report Summary

Present to user:

```
Component Specs initialization complete.

Components ready for spec creation (in priority order):
1. [component-1] - [scope summary]
2. [component-2] - [scope summary]
...

Deferred items status:
- [N] items split across component deferred items files
- [M] cross-cutting items
- Original archived to: deferred-items-archived-YYYY-MM-DD.md

Cross-cutting contract registry:
- Consuming the frozen registry produced by Promote: specs/cross-cutting.md ([N] contracts) — materialized and fidelity-verified at the freeze (Promote stage); this stage only reads it
- Step-0 cross-cutting interface schema-specs authored: [N] (of [M] §7 interfaces evaluated; the rest skipped per the selection rule) — components may adopt by reference, not required
- Pending-issues.md initialized for each component

Project scale reference:
- [Generated project-scale.md (approved by human) | Preserved existing project-scale.md]

Next step: Initialize first component:
  Run the Component Create Router for [component-1]

Invocation:
  {{AGENTS_PATH}}/05-components/create/orchestrator-router.md
  Component: [component-1]
```

---

## Output

After initialization:

```
system-design/
├── project-scale.md                          # Project scale reference (generated in Step 3b)
└── 05-components/
    ├── specs/
    │   ├── cross-cutting.md                  # Frozen registry — PRODUCED BY PROMOTE (materialized projection of §7/§8), consumed here
    │   └── cross-cutting-interfaces/         # Step-0 interface schema-specs (one per qualifying §7 interface; may be empty)
    │       └── [interface-name].md
    └── versions/
        ├── deferred-items-archived-YYYY-MM-DD.md # Original backup (if had content)
        ├── workflow-state.md                 # Stage state: initialization + component index
        ├── cross-cutting/
        │   ├── deferred-items.md             # Cross-cutting items (if any)
        │   ├── materialization.md            # Contract materialization report — PRODUCED BY PROMOTE (consumed here)
        │   ├── materialization-fidelity.md   # Fidelity-check report — PRODUCED BY PROMOTE (consumed here)
        │   └── interface-schemas.md          # Interface schema-authoring report (rule evaluation + authored)
        ├── event-store/
        │   ├── deferred-items.md             # Component-specific items
        │   ├── pending-issues.md             # Pending issues for this component
        │   └── workflow-state.md             # Per-component review state
        ├── email-ingestion/
        │   ├── deferred-items.md
        │   ├── pending-issues.md
        │   └── workflow-state.md
        └── ...
```

**Two-level state model:**
- `versions/workflow-state.md` — Stage-level: initialization status, component index
- `versions/[component]/workflow-state.md` — Per-component: detailed review tracking

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Architecture Overview not found | Error: "Cannot initialize - Architecture Overview not found at [path]" |
| No Component Spec List in Architecture | Error: "Cannot initialize - Architecture Overview missing Component Spec List section" |
| State file already exists | Warning: "Already initialized. Re-running will reset state. Continue? (y/n)" |
| Deferred Items Processor fails | Error: Report failure, do not create state file |
| Interface Schema-Author fails (no report written) | Error: Report failure. (Zero interfaces authored is NOT a failure — a written report with 0 authored is a valid outcome.) |
| Frozen registry missing / not materialized (`specs/cross-cutting.md` absent or `Population` not `MATERIALIZED`) | Error: "The frozen contract registry is not present. Run the Promote stage (which materializes it) before initializing Component Specs." (materialization + fidelity moved to Promote in Slice 4) |
| Registry stale vs architecture (both `Frozen-At` present but differ) | Error: "The contract registry (`Frozen-At: [X]`) is stale relative to the current architecture (`Frozen-At: [Y]`) — re-run the Promote stage to re-freeze before initializing Component Specs." (equality check only — catches the promote-HALT round-mismatch case) |
| Freeze identity not stamped (either `Frozen-At` absent — pre-Slice-6 artifact) | Error: "Freeze identity not established (pre-Slice-6 artifact) — re-run the Promote stage to stamp `Frozen-At` before initializing Component Specs." (NOT a staleness error — require re-promote to stamp identity; do not false-positive a missing token as stale) |

---

**Tool Restrictions:**
- Use **Read**, **Write**, **Edit**, **Glob**, **Grep**, and **Task** tools
- Use **Bash** only for `mkdir -p` to create directories
- Do NOT use Bash for any other shell commands
- Do NOT use WebFetch or WebSearch
