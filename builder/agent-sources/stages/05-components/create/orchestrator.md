# Component Spec Creation Orchestrator

---

## Purpose

Initialize a single component spec by generating a draft from the Architecture and Foundations. The human then augments the draft before running the Review workflow.

**Flow:** Create Orchestrator (this) → Human augments → Review workflow

---

## When to Run

Run this orchestrator for each component, after the initialize orchestrator has completed. Components should be initialized in priority order, respecting dependencies.

**Invocation:**
```
Read the Component Create Orchestrator at:
{{AGENTS_PATH}}/05-components/create/orchestrator.md

Initialize component: [component-name]
```

---

## Fixed Paths

**Architecture**: `system-design/04-architecture/architecture.md`
**Foundations**: `system-design/03-foundations/foundations.md`
**Stage state**: `system-design/05-components/versions/workflow-state.md`
**Component directory**: `system-design/05-components/versions/[component-name]/`
**Per-component state**: `system-design/05-components/versions/[component-name]/workflow-state.md`
**Brief (optional)**: `system-design/05-components/versions/[component-name]/brief.md`
**Draft output**: `system-design/05-components/versions/[component-name]/round-0/00-draft-spec.md`

---

## Prompt Locations

```
agents/05-components/initialize/
└── orchestrator.md                    # Stage-level setup (run first)

agents/05-components/create/
├── orchestrator.md                    # This file (per-component)
└── generator.md                       # Creates draft from Architecture + Foundations

agents/05-components/review/
├── orchestrator.md                    # Review workflow (run after human augments)
├── experts/
└── workflow/
```

---

## Orchestration Steps

**Immediate execution**: The user invoking this orchestrator IS the instruction to execute. Do not ask for confirmation before starting. Proceed immediately with Step 1.

**IMPORTANT: File-First Principle**
- Do NOT pass file contents or summaries to agents
- Only pass file PATHS - agents read files themselves

**Orchestrator Boundaries**
- You READ input files to validate prerequisites
- You SPAWN the Generator agent to do work
- You UPDATE stage state (component index) and per-component state
- You DO NOT write the draft spec - the Generator does that

### Step 1: Validate Prerequisites

1. **Check stage state exists** at `system-design/05-components/versions/workflow-state.md`
   - **If NO**: Error - "Run the Component Specs initialize orchestrator first"

2. **Read stage state** and validate:
   - Component exists in Component Specs table
   - Component status is `NOT_STARTED` (not already initialized or complete)

3. **Check dependencies** (from Component Dependencies table in stage state):
   - If component has dependencies listed, verify all have status `COMPLETE` in Component Specs table
   - **If any dependency not COMPLETE**: Error - "Cannot initialize [component]. Blocked by: [list incomplete dependencies]"

### Step 2: Deferred Items Intake

1. **Read deferred items** at `system-design/05-components/versions/[component-name]/deferred-items.md`

2. **If empty or no PENDING items**: Skip to Step 3

3. **If has PENDING items**:

   a. **Read final Architecture**: `system-design/04-architecture/architecture.md`

   b. **For each PENDING item, validate relevance**:
      - Check if topic is addressed in final Architecture
      - Update validation status:
        - `RESOLVED_UPSTREAM`: Fully addressed - mark closed
        - `PARTIALLY_ADDRESSED`: Touched but not resolved - keep for Generator
        - `STILL_RELEVANT`: Not addressed - keep for Generator

   c. **Update deferred items** with validation results

### Step 2b: Check for Brief

1. **Check if brief document exists** at `system-design/05-components/versions/[component-name]/brief.md`
   - If an explicit brief path was provided in the invocation, use that instead
2. **If brief exists**: Will be passed to Generator as additional input
3. **If no brief**: Continue without (standard generation)

### Step 3: Create Round Directory

1. **Create directory**: `system-design/05-components/versions/[component-name]/round-0/`

### Step 4: Run Generator

1. **Spawn Generator agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/generator.md

   Input:
   - Component: [component-name]
   - Architecture: system-design/04-architecture/architecture.md
   - Foundations: system-design/03-foundations/foundations.md
   - Component guide: {{GUIDES_PATH}}/05-components-guide.md
   - Deferred items: system-design/05-components/versions/[component-name]/deferred-items.md
   - Cross-cutting spec: system-design/05-components/specs/cross-cutting.md
   - Brief: system-design/05-components/versions/[component-name]/brief.md (if exists)

   Output: system-design/05-components/versions/[component-name]/round-0/00-draft-spec.md
   ```

2. **Wait for Generator to complete**

3. **Verify output exists** at `system-design/05-components/versions/[component-name]/round-0/00-draft-spec.md`

### Step 5: Update Workflow State

1. **Update stage state** (`versions/workflow-state.md`):
   - Component Specs table: Update component row status `NOT_STARTED` → `DRAFT_READY`, set Last Updated to today's date
   - Add history entry: "[date]: [component-name] draft generated"

2. **Update per-component state** (`versions/[component-name]/workflow-state.md`):
   - Status: `NOT_STARTED` → `DRAFT_READY`
   - Add history entry: "[date]: Draft generated"

### Step 6: Report to Human

1. **Read the draft** to count gaps (look for markers: `[QUESTION`, `[DECISION NEEDED`, `[ASSUMPTION`, `[TODO`, `[CLARIFY`)

2. **Present summary**:
   ```
   Component [component-name] initialization complete.

   Draft spec: system-design/05-components/versions/[component-name]/round-0/00-draft-spec.md

   Brief: [Used / Not provided]

   Gap summary:
   - [N] QUESTION items
   - [M] DECISION NEEDED items
   - [K] Assumptions to validate

   Next steps:
   1. Review the draft - fill in interface details, data model, etc.
   2. Optionally ask Claude to tidy up the draft
   3. When ready, run the Component Review workflow for [component-name]
   ```

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Stage state not found | Error: "Run the Component Specs initialize orchestrator first" |
| Component not in stage state | Error: "Component [name] not found in Component Specs table" |
| Component not NOT_STARTED | Error: "Component [name] status is [status], expected NOT_STARTED" |
| Dependencies incomplete | Error: "Cannot initialize [component]. Blocked by: [list]" |
| Generator fails | Error: Report failure details |
| Draft not created | Error: "Generator completed but draft not found at expected path" |

---

## What Happens Next

After this orchestrator completes:

1. **Human reviews draft** - Opens `00-draft-spec.md`, fills in interface details, data model, etc.
2. **Human optionally tidies** - Can ask Claude to clean up the draft
3. **Human runs Review workflow** - Invokes the Component Review orchestrator for this component

The Review workflow will:
- Run expert reviewers on the draft (Build part, then Ops part)
- Facilitate discussion on issues found
- Author the updated spec
- Verify alignment with Architecture and Foundations
- Verify contract conformance

---

<!-- INJECT: tool-restrictions -->
