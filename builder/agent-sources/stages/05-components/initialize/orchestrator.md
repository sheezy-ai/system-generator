# Component Specs Stage Orchestrator

---

## Purpose

One-time stage-level setup before creating any component specs. Run this once at the start of the Component Specs stage to:
- Create folder structure for all components
- Split the monolithic deferred items into component-specific files
- Create cross-cutting specification placeholder
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

1. **Read Architecture Overview** to find the Component Spec List section (§6)

2. **Extract components**:
   - Component name
   - Dependencies (from the Dependencies column of the §6 table)

3. **Validate** the component list is not empty

4. **Classify each dependency** as cross-cutting or component:
   - **Cross-cutting**: dependencies containing "(cross-cutting)" in their description — e.g., `audit-trail (cross-cutting interface)`, `source-attribution (cross-cutting interface)`, `compliance-gate (cross-cutting utility)`. These are pre-satisfied (step 0) and do not block component creation.
   - **Partial/scoped**: dependencies containing "scoped to" or "only" — e.g., `events (scoped to find_entities_by_source only)`. These are non-blocking for priority computation. The component can be fully specced except for the scoped capability. Record the partial dependency in the table but do not count it as blocking.
   - **Full component**: all other dependencies — e.g., `entities`, `events`, `pipeline`. These are blocking.

5. **Compute priority tiers** via topological sort on blocking dependencies:
   - **Tier 1**: components with no blocking component dependencies (only cross-cutting and/or partial)
   - **Tier 2**: components whose blocking dependencies are all in tier 1
   - **Tier 3**: components whose blocking dependencies are all in tiers 1-2
   - Continue until all components are assigned a tier
   - **If a cycle is detected**: error — "Circular dependency detected: [cycle]. Cannot compute priority."

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
     # Component Spec Review Workflow State

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

### Step 3a: Create Cross-Cutting Specification Placeholder

1. **Create** `specs/cross-cutting.md` with placeholder content:

```markdown
# Cross-Cutting Specification

## Status

**Population**: DEFERRED

Contracts are defined inline in component specs during initial development. This registry will be populated by extracting established contracts once component specs stabilize.

See the populate cross-cutting orchestrator for the extraction process.

---

## 1. Data Contracts

*To be extracted from component specs*

---

## 2. Shared Types

*To be extracted from component specs*

---

## Appendix: Contract Status Summary

| Contract ID | Name | Consumer | Producer(s) | Status |
|-------------|------|----------|-------------|--------|
| *None yet* | | | | |
```

### Step 4: Create Stage State File

1. **Create** `system-design/05-components/versions/workflow-state.md` (stage-level state):

```markdown
# Component Specs Workflow State

## Stage Initialization

**Status**: COMPLETE
**Initialized**: YYYY-MM-DD

- [x] Cross-cutting placeholder created
- [x] Component folders created
- [x] Per-component state files created

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

Cross-cutting specification:
- Created specs/cross-cutting.md (placeholder - contracts extracted later)
- Pending-issues.md initialized for each component

Next step: Initialize first component:
  Run the Component Create Orchestrator for [component-1]

Invocation:
  {{AGENTS_PATH}}/05-components/create/orchestrator.md
  Component: [component-1]
```

---

## Output

After initialization:

```
system-design/05-components/
├── specs/
│   └── cross-cutting.md                   # Placeholder (contracts extracted later)
└── versions/
    ├── deferred-items-archived-YYYY-MM-DD.md # Original backup (if had content)
    ├── workflow-state.md                  # Stage state: initialization + component index
    ├── cross-cutting/
    │   └── deferred-items.md                 # Cross-cutting items (if any)
    ├── event-store/
    │   ├── deferred-items.md                 # Component-specific items
    │   ├── pending-issues.md              # Pending issues for this component
    │   └── workflow-state.md              # Per-component review state
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

---

**Tool Restrictions:**
- Use **Read**, **Write**, **Edit**, **Glob**, **Grep**, and **Task** tools
- Use **Bash** only for `mkdir -p` to create directories
- Do NOT use Bash for any other shell commands
- Do NOT use WebFetch or WebSearch
