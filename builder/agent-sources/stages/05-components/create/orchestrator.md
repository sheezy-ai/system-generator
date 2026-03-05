# Component Spec Creation Orchestrator

---

## Purpose

Create a single component spec by generating a draft from the Architecture and Foundations, resolving any gaps through structured discussion, and promoting the final draft to `specs/[component-name].md` for the Review workflow.

**Flow:** Orchestrator (this) → Generator → Gap Discussion (if gaps) → Author (if gaps) → Promote → Review workflow

---

## When to Run

Run this orchestrator for each component, after the initialize orchestrator has completed. Components should be initialized in priority order, respecting dependencies. Safe to re-invoke — the orchestrator reads the per-component state file and resumes from the last completed step.

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
**Output directory**: `system-design/05-components/versions/[component-name]/round-0`
**Draft output**: `system-design/05-components/versions/[component-name]/round-0/00-draft-spec.md`
**Gap discussion**: `system-design/05-components/versions/[component-name]/round-0/01-gap-discussion.md`
**Author output**: `system-design/05-components/versions/[component-name]/round-0/02-author-output.md`
**Updated draft**: `system-design/05-components/versions/[component-name]/round-0/03-updated-spec.md`
**Promoted output**: `system-design/05-components/specs/[component-name].md`

---

## Prompt Locations

```
agents/05-components/initialize/
└── orchestrator.md                    # Stage-level setup (run first)

agents/05-components/create/
├── orchestrator.md                    # This file (per-component)
├── generator.md                       # Creates draft from Architecture + Foundations
└── author.md                          # Applies resolved gap discussions

agents/universal-agents/
├── gap-formatter.md                   # Extracts gaps into discussion format
├── gap-analyst.md                     # Proposes solutions for each gap
└── discussion-facilitator.md          # Facilitates gap discussions

agents/05-components/review/
├── orchestrator-router.md             # Review workflow (run after create completes)
├── experts/
└── workflow/
```

---

## Output Directory Structure

```
system-design/05-components/
├── specs/
│   └── [component-name].md            # Promoted from create (then overwritten by Review promoter)
└── versions/
    ├── workflow-state.md              # Stage-level state
    └── [component-name]/
        ├── deferred-items.md          # Upstream gaps for this component
        ├── workflow-state.md          # Per-component state
        └── round-0/
            ├── 00-draft-spec.md                  # Generator output
            ├── 01-gap-discussion.md              # Gap formatter output (if gaps exist)
            ├── 02-author-output.md               # Author changelog (if gaps exist)
            └── 03-updated-spec.md                # Author output (if gaps exist)
```

---

## Workflow State Management

**Per-component state file**: `system-design/05-components/versions/[component-name]/workflow-state.md`

### On Start/Resume

1. **Check if per-component state file exists**:
   - **If NO**: Fresh start — create state file, begin at Step 1
   - **If YES**: Read it, resume from the first incomplete step

2. **Resume logic**:
   - Steps 1-2b (Validate & Setup) are idempotent — always re-run on resume for validation
   - Step 3 (Generator) is non-idempotent — if marked complete, verify draft exists and skip
   - Steps 4-6 conditional on `Gaps Exist` flag — if `false`, skip to Step 7
   - Step 5 can resume at WAITING_FOR_HUMAN — re-read discussion file and continue loop
   - Step 7 (Promote) — if marked complete, workflow is done

3. **Update state file** at each step transition (instructions inline below)

### Per-Component State File Format

```markdown
# [Component Name] Workflow State

**Current Round**: 0
**Status**: IN_PROGRESS | WAITING_FOR_HUMAN | COMPLETE
**Gaps Exist**: unknown | true | false

## Progress

### Round 0 (Creation)
- [ ] Step 1-2b: Validate & Setup
- [ ] Step 3: Run Generator
- [ ] Step 4: Format & Analyse Gaps
- [ ] Step 5: Discussion Loop
- [ ] Step 6: Apply Decisions
- [ ] Step 7: Promote & Report

## History
- YYYY-MM-DD HH:MM: Creation workflow started
```

---

## Orchestration Steps

**Immediate execution**: The user invoking this orchestrator IS the instruction to execute. Do not ask for confirmation before starting. Proceed immediately with Step 1.

**State file updates**: Update the per-component state file before and after each step as instructed below. These updates enable workflow resume and provide audit trail.

**IMPORTANT: File-First Principle**
- Do NOT pass file contents or summaries to agents
- Only pass file PATHS - agents read files themselves

**Orchestrator Boundaries**
- You READ input files to validate prerequisites
- You SPAWN agents (Generator, Gap Formatter, Discussion Facilitator, Author) to do work
- You UPDATE stage state (component index) and per-component state
- You COPY the final draft to `specs/[component-name].md` (promotion)
- You DO NOT write draft spec content, gap discussion content, or author output — agents do that

### Step 1: Validate Prerequisites

0. **Update per-component state file**: Set status = IN_PROGRESS (create state file if fresh start)

1. **Check stage state exists** at `system-design/05-components/versions/workflow-state.md`
   - **If NO**: Error - "Run the Component Specs initialize orchestrator first"

2. **Read stage state** and validate:
   - Component exists in Component Specs table
   - Component status is `NOT_STARTED` (not already initialized or complete)

3. **Check dependencies** (from Component Dependencies table in stage state):
   - If component has dependencies listed, verify all have status `COMPLETE` in Component Specs table
   - **If any dependency not COMPLETE**: Error - "Cannot initialize [component]. Blocked by: [list incomplete dependencies]"

### Step 2: Deferred Items Intake

1. **Check if deferred items file exists** at `system-design/05-components/versions/[component-name]/deferred-items.md`
   - **If file doesn't exist**: Skip to Step 2b

2. **Read deferred items**

3. **If empty or no PENDING items**: Skip to Step 2b

4. **If has PENDING items**:

   a. **Read final upstream documents**:
      - `system-design/04-architecture/architecture.md`
      - `system-design/03-foundations/foundations.md`

   b. **For each PENDING item, validate relevance**:
      - Check if topic is addressed in final Architecture or Foundations
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

4. **Update per-component state file**: Mark "Step 1-2b: Validate & Setup" complete `[x]`, add history entry

### Step 3: Run Generator

**On resume**: If Step 3 already marked complete, verify `00-draft-spec.md` exists and skip to Step 4.

1. **Create round directory**: `system-design/05-components/versions/[component-name]/round-0/`

2. **Spawn Generator agent** using Task tool:
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

3. **Wait for Generator to complete**

4. **Verify output exists** at `system-design/05-components/versions/[component-name]/round-0/00-draft-spec.md`

5. **Update per-component state file**: Mark "Step 3: Run Generator" complete `[x]`, add history entry

### Step 4: Format & Analyse Gaps

1. **Read the draft** at `system-design/05-components/versions/[component-name]/round-0/00-draft-spec.md`

2. **Check for Gap Summary section** — Look for `## Gap Summary` heading

3. **If no Gap Summary, or all counts are 0**:
   - **Update per-component state file**: Set `Gaps Exist` = `false`, mark Steps 4-6 complete `[x]`, add history entry "No gaps found — skipping to promotion"
   - **Skip Steps 4-6, proceed to Step 7**

4. **Spawn Gap Formatter agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/universal-agents/gap-formatter.md

   Input:
   - Draft: system-design/05-components/versions/[component-name]/round-0/00-draft-spec.md

   Output: system-design/05-components/versions/[component-name]/round-0/01-gap-discussion.md
   ```

5. **Wait for Gap Formatter to complete**

6. **Verify output exists** at `system-design/05-components/versions/[component-name]/round-0/01-gap-discussion.md`

7. **Read output** — count gaps by severity for the Step 5 handoff message

8. **Spawn Gap Analyst agents** using Task tool (batch by section):
   ```
   Follow the instructions in: {{AGENTS_PATH}}/universal-agents/gap-analyst.md

   Context documents:
   - Draft Spec: system-design/05-components/versions/[component-name]/round-0/00-draft-spec.md
   - Architecture: system-design/04-architecture/architecture.md
   - Foundations: system-design/03-foundations/foundations.md
   - Brief: system-design/05-components/versions/[component-name]/brief.md (if exists)

   Gap discussion file: system-design/05-components/versions/[component-name]/round-0/01-gap-discussion.md
   Gaps: [GAP-001, GAP-002, ...]
   ```

9. **Wait for all Gap Analyst agents to complete**

10. **Verify analyst responses were written** (MANDATORY):
    - Count `>> AGENT:` markers in the gap discussion file
    - Compare to total number of gaps
    - If counts don't match: identify missing gaps and re-invoke Gap Analyst for those only

11. **Update per-component state file**: Set `Gaps Exist` = `true`, mark "Step 4: Format & Analyse Gaps" complete `[x]`, add history entry with gap counts

### Step 5: Discussion Loop

**On resume**: If status = WAITING_FOR_HUMAN for Step 5, re-read `01-gap-discussion.md` and continue the discussion loop from step 11(a) below — identify which gaps still need responses.

8. **Update per-component state file**: Set status = WAITING_FOR_HUMAN, add history entry

9. **Notify user** gap analysis is ready for review:
   ```
   Gap analysis complete for [component-name].

   Discussion file: system-design/05-components/versions/[component-name]/round-0/01-gap-discussion.md

   - [N] HIGH (Must Answer) gaps
   - [M] MEDIUM (Should Answer) gaps
   - [K] LOW (Assumptions to Validate) gaps

   Each gap has a proposed solution with options, trade-offs, and recommendation.
   Please review each proposal and respond using >> HUMAN: markers:
   - Accept: "Agreed", "Yes", "That works"
   - Modify: State what you'd change
   - Reject/Discuss: Explain your concern

   When done, let me know and I'll process your responses.
   ```

**STOP: Wait for human response before proceeding.**

Do NOT enter the discussion loop until the human has added actual response content after `>> HUMAN:` markers. An empty `>> HUMAN:` marker (as generated by Gap Formatter) is a placeholder for where the human WILL respond — it is not a response itself.

Only proceed to step 10 after the human signals they have responded (e.g., "done", "ready", "I've responded", or resumes the conversation after editing the file).

10. **Discussion markers**:
   - Human responds using `>> HUMAN:` prefix
   - Agent responds using `>> AGENT:` prefix
   - `>> RESOLVED` marks discussion complete (added by orchestrator only)

11. **Discussion loop**:

    a. **Identify gaps needing agent response**: Read file, find gaps where last entry is `>> HUMAN:` without subsequent `>> AGENT:`

    b. **Group gaps into batches** (2-3 batches recommended):
       - Group by spec section number (gaps contain `**Section**: §N`)
       - Batch 1: Sections 1-4 (Overview, Scope, Interfaces, Data Model)
       - Batch 2: Sections 5-8 (Behaviour, Dependencies, Integration, Error Handling)
       - Batch 3: Sections 9-12 (Observability, Security, Testing, Open Questions)
       - If fewer than 4 gaps total, use fewer batches

    c. **Invoke Discussion Facilitator agents** (one per batch, in parallel):
       ```
       Follow the instructions in: {{AGENTS_PATH}}/universal-agents/discussion-facilitator.md

       Context documents:
       - Draft Spec: system-design/05-components/versions/[component-name]/round-0/00-draft-spec.md
       - Architecture: system-design/04-architecture/architecture.md
       - Foundations: system-design/03-foundations/foundations.md

       Issues file: system-design/05-components/versions/[component-name]/round-0/01-gap-discussion.md
       Issues: [GAP-001, GAP-002, ...]
       ```

    d. **Wait for all agents to complete**

    e. **Verify agent responses were written** (MANDATORY):
       - Count `>> AGENT:` markers in the gap discussion file
       - Compare to number of gaps that were assigned to Discussion Facilitators
       - If counts match: Proceed to step (f)
       - If counts don't match:
         - Identify which gaps are missing `>> AGENT:` responses
         - Re-invoke Discussion Facilitators for ONLY the missing gaps
         - Repeat verification until all assigned gaps have responses

    f. **Present to human**: "Please review the agent responses and reply to each gap."

    g. **Wait for human responses**

    h. **After human responds**, read file and for each gap:
       - If last entry is `>> HUMAN:` after `>> AGENT:` AND response indicates closure → add `>> RESOLVED`
       - If last entry is `>> HUMAN:` with question, pushback, or request → leave open

    i. **If any gaps unresolved**: Go to step (a)

    j. **If all gaps resolved**: Proceed to Step 6

12. **Resolution indicators** (human response after `>> AGENT:` that signals done):
    - Agreement: "Yes", "Agreed", "That works", "Fine", "OK"
    - Dismissal: "Not a concern", "Not relevant", "Ignore", "Skip"
    - Acceptance: "Makes sense", "Fair enough", "Understood"

13. **Continue discussion indicators** (do NOT mark resolved):
    - Questions: "?", "What about", "How would", "Can you"
    - Requests: "Please", "Can you", "I'd like", "Show me"
    - Pushback: "I disagree", "That's not right", "But what about"

### Step 5→6 Gate

**Before invoking Author:**
1. Read `01-gap-discussion.md`
2. Verify EVERY gap has `>> RESOLVED` marker
3. If any gap lacks `>> RESOLVED`: Do NOT proceed. Continue discussion loop.
4. Only proceed to Step 6 when all gaps show `>> RESOLVED`

This gate is mandatory. Do not skip it.

5. **Update per-component state file**: Mark "Step 5: Discussion Loop" complete `[x]`, set status = IN_PROGRESS, add history entry "All gaps resolved"

### Step 6: Apply Decisions

14. **Spawn Author agent** using Task tool:
    ```
    Follow the instructions in: {{AGENTS_PATH}}/05-components/create/author.md

    Input:
    - Draft Spec: system-design/05-components/versions/[component-name]/round-0/00-draft-spec.md
    - Gap discussion: system-design/05-components/versions/[component-name]/round-0/01-gap-discussion.md
    - Component guide: {{GUIDES_PATH}}/05-components-guide.md

    Output:
    - Change log: system-design/05-components/versions/[component-name]/round-0/02-author-output.md
    - Updated Spec: system-design/05-components/versions/[component-name]/round-0/03-updated-spec.md
    ```

15. **Wait for Author to complete**

16. **Verify outputs exist**:
    - `system-design/05-components/versions/[component-name]/round-0/02-author-output.md`
    - `system-design/05-components/versions/[component-name]/round-0/03-updated-spec.md`

17. **Update per-component state file**: Mark "Step 6: Apply Decisions" complete `[x]`, add history entry

### Step 7: Promote & Report

18. **Determine final draft path**:
    - If Steps 4-6 ran (gaps existed): Use `system-design/05-components/versions/[component-name]/round-0/03-updated-spec.md`
    - If Steps 4-6 were skipped (no gaps): Use `system-design/05-components/versions/[component-name]/round-0/00-draft-spec.md`

19. **Copy final draft to specs** using Bash cp:
    ```
    cp [final draft path] system-design/05-components/specs/[component-name].md
    ```

20. **Verify promotion** — Confirm `system-design/05-components/specs/[component-name].md` exists

21. **Update stage state** (`versions/workflow-state.md`):
    - Component Specs table: Update component row status `NOT_STARTED` → `DRAFT_READY`, set Last Updated to today's date
    - Add history entry: "[date]: [component-name] creation workflow complete"

22. **Update per-component state file**: Mark "Step 7: Promote & Report" complete `[x]`, set status = COMPLETE, add history entry

23. **Present summary**:
    ```
    Component [component-name] creation complete.

    Draft: system-design/05-components/versions/[component-name]/round-0/00-draft-spec.md
    [If gaps resolved:]
    Updated: system-design/05-components/versions/[component-name]/round-0/03-updated-spec.md
    Promoted to: system-design/05-components/specs/[component-name].md

    Brief: [Used / Not provided]

    [If gaps were resolved:]
    Gap resolution:
    - [N] gaps discussed
    - [M] changes applied by author
    - [K] flagged for attention (see 02-author-output.md)

    [If no gaps:]
    No gaps found — brief was fully specified.

    Next steps:
    1. Review specs/[component-name].md — verify promoted content looks correct
    2. When ready, run the Component Review workflow for [component-name]
       (Review reads from: system-design/05-components/specs/[component-name].md)
    ```

---

## Stopping Points

**Automatic flow (do NOT pause for human confirmation):**
- Steps 1 → 2 → 2b → 3 → 4: Proceed automatically through to gap analysis
- Step 6 → 7: Execute after all gaps resolved

**Human checkpoints:**
- **Step 5** — WAITING FOR HUMAN for gap discussion until all gaps resolved
- **Step 4 → 7 skip** — If no gaps, proceed automatically from Step 4 check to Step 7

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
| Gap Formatter fails | Error: Report failure details |
| Gap discussion file not created | Error: "Gap Formatter completed but output not found at expected path" |
| Author fails | Error: Report failure details |
| Author output files not created | Error: "Author completed but outputs not found at expected paths" |
| Promotion copy fails | Error: "Failed to copy final draft to specs/[component-name].md" |
| State file corrupted/unreadable | Warning: Report issue, re-create state from file existence checks |
| Resume: draft missing but Step 3 marked complete | Error: "State says Generator complete but draft not found — re-run Generator or fix state file" |

---

## What Happens Next

After this orchestrator completes:

1. **Human reviews promoted spec** — Opens `system-design/05-components/specs/[component-name].md`
2. **Human optionally makes manual edits** — Can refine directly
3. **Human runs Review workflow** — Invokes the Component Review orchestrator for this component

**IMPORTANT**: The Review workflow reads from `system-design/05-components/specs/[component-name].md` for Round 1. This file is created by the promotion step (Step 7). It MUST exist before starting the Review workflow.

The Review workflow will:
- Run expert reviewers on the spec (Build part, then Ops part)
- Facilitate discussion on issues found
- Author the updated spec
- Verify alignment with Architecture and Foundations
- Verify contract conformance

---

<!-- INJECT: tool-restrictions -->
