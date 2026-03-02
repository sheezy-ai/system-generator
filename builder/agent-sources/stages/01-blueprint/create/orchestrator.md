# Blueprint Creation Orchestrator

---

## Purpose

Initialize the Blueprint stage by setting up structure and generating a draft Blueprint from the concept. The human then augments the draft before running the Review workflow.

**Flow:** Orchestrator (this) → Human augments → Review workflow

---

## When to Run

Run this orchestrator once at the start of a new project, with a concept document or description.

---

## Fixed Paths

**Output directory**: `system-design/01-blueprint/versions/round-0`
**Draft output**: `system-design/01-blueprint/versions/round-0/00-draft-blueprint.md`
**State file**: `system-design/01-blueprint/versions/workflow-state.md`
**Final output**: `system-design/01-blueprint/blueprint.md` (created by Review workflow)

---

## Prompt Locations

```
agents/01-blueprint/create/
├── orchestrator.md                    # This file
└── generator.md                       # Creates draft from concept

agents/01-blueprint/review/
├── orchestrator.md                    # Review workflow (run after human augments)
├── experts/
└── workflow/
```

---

## Output Directory Structure

```
system-design/01-blueprint/
├── versions/
│   ├── deferred-items.md           # Upstream gaps for this stage
│   ├── pending-issues.md          # Issues logged against this stage
│   └── round-0/
│       └── 00-draft-blueprint.md  # Generator output
└── blueprint.md                   # Final (created by Review workflow)
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
- You DO NOT write the draft Blueprint - the Generator does that

### Step 1: Setup Structure

1. **Create directories** (if not exist):
   ```
   system-design/01-blueprint/
   └── versions/
       └── round-0/
   ```

2. **Create deferred-items.md** (if not exists) at `system-design/01-blueprint/versions/deferred-items.md`:
   ```markdown
   # Blueprint Deferred Items

   Items deferred for later consideration or downstream stages.

   ---

   <!-- No deferred items yet -->
   ```

3. **Create pending-issues.md** (if not exists) at `system-design/01-blueprint/versions/pending-issues.md`:
   ```markdown
   # Pending Issues: Blueprint

   Issues discovered that need resolution.

   ---

   <!-- No issues logged yet -->
   ```

### Step 2: Run Generator

1. **Spawn Generator agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/01-blueprint/create/generator.md

   Input:
   - Concept: [concept file path or inline description]
   - Blueprint guide: {{GUIDES_PATH}}/01-blueprint-guide.md

   Output: system-design/01-blueprint/versions/round-0/00-draft-blueprint.md
   ```

2. **Wait for Generator to complete**

3. **Verify output exists** at `system-design/01-blueprint/versions/round-0/00-draft-blueprint.md`

### Step 3: Report to Human

1. **Read the draft** to count gaps (look for markers: `[QUESTION`, `[DECISION NEEDED`, `[ASSUMPTION`, `[TODO`, `[CLARIFY`)

2. **Present summary**:
   ```
   Blueprint initialization complete.

   Draft Blueprint: system-design/01-blueprint/versions/round-0/00-draft-blueprint.md

   Gap summary:
   - [N] QUESTION items
   - [M] DECISION NEEDED items
   - [K] Assumptions to validate

   Next steps:
   1. Review the draft and fill in answers to open questions
   2. Optionally ask Claude to tidy up the draft
   3. When ready, run the Blueprint Review workflow
   ```

### Step 4: Record Completion

1. **Write state file** at `system-design/01-blueprint/versions/workflow-state.md`:
   ```markdown
   # Blueprint Workflow State

   **Current Round**: 0
   **Status**: COMPLETE

   ## Progress

   ### Round 0 (Creation)
   - [x] Step 1: Generate Blueprint

   ## History
   - [date]: Creation workflow complete
   ```

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Generator fails | Error: Report failure details |
| Draft not created | Error: "Generator completed but draft not found at expected path" |

---

## What Happens Next

After this orchestrator completes:

1. **Human reviews draft** - Opens `00-draft-blueprint.md`, fills in answers to open questions inline
2. **Human optionally tidies** - Can ask Claude to clean up the draft
3. **Human runs Review workflow** - Invokes the Blueprint Review orchestrator

The Review workflow will:
- Run expert reviewers on the draft
- Facilitate discussion on issues found
- Author the final Blueprint
- Iterate until ready for the next stage (PRD)

---

## Note: No Alignment Verification

Unlike other stages (PRD, Foundations, Architecture, Components), the Blueprint does **not** have upstream alignment verification.

**Reason**: The concept document is informal input—a rough idea or description—not a tracked source with specific requirements. The Blueprint *expands* the concept rather than *implementing* it.

---

<!-- INJECT: tool-restrictions -->
