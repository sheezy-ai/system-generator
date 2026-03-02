# PRD Creation Orchestrator

---

## Purpose

Initialize the PRD stage by setting up structure and generating a draft PRD from the Blueprint. The human then augments the draft before running the Review workflow.

**Flow:** Orchestrator (this) → Human augments → Review workflow

---

## When to Run

Run this orchestrator once at the start of the PRD stage, after the Blueprint is complete.

---

## Fixed Paths

**Blueprint**: `system-design/01-blueprint/blueprint.md`
**Output directory**: `system-design/02-prd/versions/round-0`
**Draft output**: `system-design/02-prd/versions/round-0/00-draft-prd.md`
**State file**: `system-design/02-prd/versions/workflow-state.md`
**Final output**: `system-design/02-prd/prd.md` (created by Review workflow)

---

## Prompt Locations

```
agents/02-prd/create/
├── orchestrator.md                    # This file
└── generator.md                       # Creates draft from Blueprint

agents/02-prd/review/
├── orchestrator.md                    # Review workflow (run after human augments)
├── experts/
└── workflow/
```

---

## Output Directory Structure

```
system-design/02-prd/
├── versions/
│   ├── deferred-items.md           # Upstream gaps for this stage
│   ├── pending-issues.md          # Issues logged against this stage
│   └── round-0/
│       └── 00-draft-prd.md        # Generator output
└── prd.md                         # Final (created by Review workflow)
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
- You DO NOT write the draft PRD - the Generator does that

### Step 1: Validate Prerequisites

1. **Check Blueprint exists** at `system-design/01-blueprint/blueprint.md`
   - **If NO**: Error - "Cannot initialize PRD - Blueprint not found"
   - **If YES**: Continue

### Step 2: Setup Structure

1. **Create directories** (if not exist):
   ```
   system-design/02-prd/
   └── versions/
       └── round-0/
   ```

2. **Create deferred-items.md** (if not exists) at `system-design/02-prd/versions/deferred-items.md`:
   ```markdown
   # PRD Deferred Items

   Items deferred for later consideration or downstream stages.

   ---

   <!-- No deferred items yet -->
   ```

3. **Create pending-issues.md** (if not exists) at `system-design/02-prd/versions/pending-issues.md`:
   ```markdown
   # Pending Issues: PRD

   Issues discovered that need resolution.

   ---

   <!-- No issues logged yet -->
   ```

### Step 3: Deferred Items Intake

1. **Read deferred items** at `system-design/02-prd/versions/deferred-items.md`

2. **If empty or no PENDING items**: Skip to Step 4

3. **If has PENDING items**:

   a. **Read final Blueprint**: `system-design/01-blueprint/blueprint.md`

   b. **For each PENDING item, validate relevance**:
      - Check if topic is addressed in final Blueprint
      - Update validation status:
        - `RESOLVED_UPSTREAM`: Fully addressed in Blueprint - mark closed
        - `PARTIALLY_ADDRESSED`: Touched but not resolved - keep for Generator
        - `STILL_RELEVANT`: Not addressed - keep for Generator

   c. **Update deferred items** with validation results

### Step 4: Run Generator

1. **Spawn Generator agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/02-prd/create/generator.md

   Input:
   - Blueprint: system-design/01-blueprint/blueprint.md
   - PRD guide: {{GUIDES_PATH}}/02-prd-guide.md
   - Deferred items: system-design/02-prd/versions/deferred-items.md

   Output: system-design/02-prd/versions/round-0/00-draft-prd.md
   ```

2. **Wait for Generator to complete**

3. **Verify output exists** at `system-design/02-prd/versions/round-0/00-draft-prd.md`

### Step 5: Report to Human

1. **Read the draft** to count gaps (look for markers: `[QUESTION`, `[DECISION NEEDED`, `[ASSUMPTION`, `[TODO`, `[CLARIFY`)

2. **Present summary**:
   ```
   PRD initialization complete.

   Draft PRD: system-design/02-prd/versions/round-0/00-draft-prd.md

   Gap summary:
   - [N] MUST_ANSWER items
   - [M] SHOULD_ANSWER items
   - [K] Assumptions to validate

   Next steps:
   1. Review the draft and fill in answers to open questions
   2. Optionally ask Claude to tidy up the draft
   3. When ready, run the PRD Review workflow
   ```

### Step 6: Record Completion

1. **Write state file** at `system-design/02-prd/versions/workflow-state.md`:
   ```markdown
   # PRD Workflow State

   **Current Round**: 0
   **Status**: COMPLETE

   ## Progress

   ### Round 0 (Creation)
   - [x] Step 1: Generate PRD

   ## History
   - [date]: Creation workflow complete
   ```

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Blueprint not found | Error: "Cannot initialize PRD - Blueprint not found at system-design/01-blueprint/blueprint.md" |
| Generator fails | Error: Report failure details |
| Draft not created | Error: "Generator completed but draft not found at expected path" |

---

## What Happens Next

After this orchestrator completes:

1. **Human reviews draft** - Opens `00-draft-prd.md`, fills in answers to open questions inline
2. **Human optionally tidies** - Can ask Claude to clean up the draft
3. **Human runs Review workflow** - Invokes the PRD Review orchestrator

The Review workflow will:
- Run expert reviewers on the draft
- Facilitate discussion on issues found
- Author the final PRD
- Verify alignment with Blueprint

---

<!-- INJECT: tool-restrictions -->
