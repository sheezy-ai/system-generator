# Architecture Overview Creation Orchestrator

---

## Purpose

Initialize the Architecture stage by setting up structure and generating a draft Architecture Overview from the PRD and Foundations. The human then augments the draft before running the Review workflow.

**Flow:** Orchestrator (this) → Human augments → Review workflow

---

## When to Run

Run this orchestrator once at the start of the Architecture stage, after the PRD and Foundations are complete.

---

## Fixed Paths

**PRD**: `system-design/02-prd/prd.md`
**Foundations**: `system-design/03-foundations/foundations.md`
**Output directory**: `system-design/04-architecture/versions/round-0`
**Draft output**: `system-design/04-architecture/versions/round-0/00-draft-architecture.md`
**State file**: `system-design/04-architecture/versions/workflow-state.md`
**Brief (optional)**: `system-design/04-architecture/brief.md`
**Final outputs** (created by Review workflow promoter):
- `system-design/04-architecture/architecture.md` — Clean current-scope Architecture Overview
- `system-design/04-architecture/decisions.md` — Design rationale and trade-offs
- `system-design/04-architecture/future.md` — Deferred items and future considerations

---

## Prompt Locations

```
agents/04-architecture/create/
├── orchestrator.md                    # This file
└── generator.md                       # Creates draft from PRD + Foundations

agents/04-architecture/review/
├── orchestrator.md                    # Review workflow (run after human augments)
├── experts/
└── workflow/
```

---

## Output Directory Structure

```
system-design/04-architecture/
├── architecture.md                # Clean current-scope (created by Review promoter)
├── decisions.md                   # Design rationale (created by Review promoter)
├── future.md                      # Deferred items (created by Review promoter)
└── versions/
    ├── deferred-items.md           # Upstream gaps for this stage
    ├── pending-issues.md          # Issues logged against this stage
    └── round-0/
        └── 00-draft-architecture.md
```

---

## Orchestration Steps

**Immediate execution**: The user invoking this orchestrator IS the instruction to execute. Do not ask for confirmation before starting. Proceed immediately with Step 1.

**IMPORTANT: File-First Principle**
- Do NOT pass file contents or summaries to agents
- Only pass file PATHS - agents read files themselves

**Orchestrator Boundaries**
- You READ input files to validate they exist
- You SPAWN the Generator agent to do work
- You CREATE structure files (deferred-items.md, pending-issues.md)
- You DO NOT write the draft Architecture - the Generator does that

### Step 1: Validate Prerequisites

1. **Check PRD exists** at `system-design/02-prd/prd.md`
   - **If NO**: Error - "Cannot initialize Architecture - PRD not found"

2. **Check Foundations exists** at `system-design/03-foundations/foundations.md`
   - **If NO**: Error - "Cannot initialize Architecture - Foundations not found"

### Step 2: Setup Structure

1. **Create directories** (if not exist):
   ```
   system-design/04-architecture/
   └── versions/
       └── round-0/
   ```

2. **Create deferred-items.md** (if not exists) at `system-design/04-architecture/versions/deferred-items.md`:
   ```markdown
   # Architecture Deferred Items

   Items deferred for later consideration or downstream stages.

   ---

   <!-- No deferred items yet -->
   ```

3. **Create pending-issues.md** (if not exists) at `system-design/04-architecture/versions/pending-issues.md`:
   ```markdown
   # Pending Issues: Architecture

   Issues discovered that need resolution.

   ---

   <!-- No issues logged yet -->
   ```

### Step 3: Deferred Items Intake

1. **Read deferred items** at `system-design/04-architecture/versions/deferred-items.md`
   - Note: May already contain items deferred by Foundations Generator

2. **If empty or no PENDING items**: Skip to Step 4

3. **If has PENDING items**:

   a. **Read final upstream documents**:
      - `system-design/02-prd/prd.md`
      - `system-design/03-foundations/foundations.md`

   b. **For each PENDING item, validate relevance**:
      - Check if topic is addressed in final PRD or Foundations
      - Update validation status:
        - `RESOLVED_UPSTREAM`: Fully addressed - mark closed
        - `PARTIALLY_ADDRESSED`: Touched but not resolved - keep for Generator
        - `STILL_RELEVANT`: Not addressed - keep for Generator

   c. **Update deferred items** with validation results

### Step 3b: Check for Brief

1. **Check if brief document exists** at `system-design/04-architecture/brief.md`
   - If an explicit brief path was provided in the invocation, use that instead
2. **If brief exists**: Will be passed to Generator as additional input
3. **If no brief**: Continue without (standard generation)

### Step 4: Run Generator

1. **Spawn Generator agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/04-architecture/create/generator.md

   Input:
   - PRD: system-design/02-prd/prd.md
   - Foundations: system-design/03-foundations/foundations.md
   - Architecture guide: {{GUIDES_PATH}}/04-architecture-guide.md
   - Deferred items: system-design/04-architecture/versions/deferred-items.md
   - Brief: system-design/04-architecture/brief.md (if exists)

   Output: system-design/04-architecture/versions/round-0/00-draft-architecture.md
   ```

2. **Wait for Generator to complete**

3. **Verify output exists** at `system-design/04-architecture/versions/round-0/00-draft-architecture.md`

### Step 5: Report to Human

1. **Read the draft** to extract:
   - Gap count (markers: `[QUESTION`, `[DECISION NEEDED`, `[ASSUMPTION`, `[TODO`, `[CLARIFY`)
   - Component list (from Section 6: Component Spec List)
   - Data contracts (from Section 8: Data Contracts)

2. **Present summary**:
   ```
   Architecture initialization complete.

   Draft Architecture: system-design/04-architecture/versions/round-0/00-draft-architecture.md

   Brief: [Used / Not provided]

   Gap summary:
   - [N] MUST_ANSWER items
   - [M] SHOULD_ANSWER items
   - [K] Assumptions to validate

   Components identified:
   - [component-1]
   - [component-2]
   - ...

   Data contracts identified: [N] contracts

   Next steps:
   1. Review the draft - validate component boundaries, data flows
   2. Optionally ask Claude to tidy up the draft
   3. When ready, run the Architecture Review workflow
   ```

### Step 6: Record Completion

1. **Write state file** at `system-design/04-architecture/versions/workflow-state.md`:
   ```markdown
   # Architecture Workflow State

   **Current Round**: 0
   **Status**: COMPLETE

   ## Progress

   ### Round 0 (Creation)
   - [x] Step 1: Generate Architecture

   ## History
   - [date]: Creation workflow complete
   ```

---

## Error Handling

| Condition | Action |
|-----------|--------|
| PRD not found | Error: "Cannot initialize Architecture - PRD not found at system-design/02-prd/prd.md" |
| Foundations not found | Error: "Cannot initialize Architecture - Foundations not found at system-design/03-foundations/foundations.md" |
| Generator fails | Error: Report failure details |
| Draft not created | Error: "Generator completed but draft not found at expected path" |

---

## What Happens Next

After this orchestrator completes:

1. **Human reviews draft** - Opens `00-draft-architecture.md`, validates component decomposition, data flows
2. **Human optionally tidies** - Can ask Claude to clean up the draft
3. **Human runs Review workflow** - Invokes the Architecture Review orchestrator

The Review workflow will:
- Run expert reviewers on the draft
- Facilitate discussion on issues found
- Author the final Architecture
- Verify alignment with PRD and Foundations

---

<!-- INJECT: tool-restrictions -->
