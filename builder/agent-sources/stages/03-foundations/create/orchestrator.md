# Foundations Creation Orchestrator

---

## Purpose

Initialize the Foundations stage by setting up structure, generating a draft Foundations document from the PRD, resolving any gaps through structured discussion, and promoting the final draft to `foundations.md` for the Review workflow.

**Flow:** Orchestrator (this) → Generator → Gap Discussion (if gaps) → Author (if gaps) → Promote → Review workflow

---

## When to Run

Run this orchestrator at the start of the Foundations stage, after the PRD is complete. Safe to re-invoke — the orchestrator reads its state file and resumes from the last completed step.

---

## Fixed Paths

**PRD**: `system-design/02-prd/prd.md`
**State file**: `system-design/03-foundations/versions/workflow-state.md`
**Output directory**: `system-design/03-foundations/versions/round-0`
**Draft output**: `system-design/03-foundations/versions/round-0/00-draft-foundations.md`
**Gap discussion**: `system-design/03-foundations/versions/round-0/01-gap-discussion.md`
**Author output**: `system-design/03-foundations/versions/round-0/02-author-output.md`
**Updated draft**: `system-design/03-foundations/versions/round-0/03-updated-foundations.md`
**Brief (optional)**: `system-design/03-foundations/brief.md`
**Promoted output**: `system-design/03-foundations/foundations.md`
**Final outputs** (created by Review workflow promoter — overwrites promoted output):
- `system-design/03-foundations/foundations.md` — Clean current-scope Foundations
- `system-design/03-foundations/decisions.md` — Design rationale and trade-offs
- `system-design/03-foundations/future.md` — Deferred items and future considerations

---

## Prompt Locations

```
agents/03-foundations/create/
├── orchestrator.md                    # This file
├── generator.md                       # Creates draft from PRD
└── author.md                          # Applies resolved gap discussions

agents/universal-agents/
├── gap-formatter.md                   # Extracts gaps into discussion format
├── gap-analyst.md                     # Proposes solutions for each gap
└── discussion-facilitator.md          # Facilitates gap discussions

agents/03-foundations/review/
├── orchestrator.md                    # Review workflow (run after create completes)
├── experts/
└── workflow/
```

---

## Output Directory Structure

```
system-design/03-foundations/
├── foundations.md                 # Promoted from create (then overwritten by Review promoter)
├── decisions.md                   # Design rationale (created by Review promoter)
├── future.md                      # Deferred items (created by Review promoter)
└── versions/
    ├── deferred-items.md           # Upstream gaps for this stage
    ├── pending-issues.md          # Issues logged against this stage
    ├── workflow-state.md              # Unified workflow state (shared with Review)
    └── round-0/
        ├── 00-draft-foundations.md             # Generator output
        ├── 01-gap-discussion.md               # Gap formatter output (if gaps exist)
        ├── 02-author-output.md                # Author changelog (if gaps exist)
        └── 03-updated-foundations.md          # Author output (if gaps exist)
```

---

## Workflow State Management

**State file**: `system-design/03-foundations/versions/workflow-state.md`

### On Start/Resume

1. **Check if state file exists**:
   - **If NO**: Fresh start — create state file, begin at Step 1
   - **If YES**: Read it, resume from the first incomplete step

2. **Resume logic**:
   - Steps 1-3b (Validate & Setup) are idempotent — always re-run on resume for validation
   - Step 4 (Generator) is non-idempotent — if marked complete, verify draft exists and skip
   - Steps 5-7 conditional on `Gaps Exist` flag — if `false`, skip to Step 8
   - Step 6 can resume at WAITING_FOR_HUMAN — re-read discussion file and continue loop
   - Step 8 (Promote) — if marked complete, workflow is done

3. **Update state file** at each step transition (instructions inline below)

### State File Format

```markdown
# Foundations Workflow State

**Foundations**: 03-foundations/foundations.md
**Current Round**: 0
**Status**: IN_PROGRESS | WAITING_FOR_HUMAN | COMPLETE
**Gaps Exist**: unknown | true | false

## Progress

### Round 0 (Creation)
- [ ] Step 1-3b: Validate & Setup
- [ ] Step 4: Run Generator
- [ ] Step 5: Format & Analyse Gaps
- [ ] Step 6: Discussion Loop
- [ ] Step 7: Apply Decisions
- [ ] Step 8: Promote & Report

## History
- YYYY-MM-DD HH:MM: Creation workflow started
```

---

## Orchestration Steps

**Immediate execution**: The user invoking this orchestrator IS the instruction to execute. Do not ask for confirmation before starting. Proceed immediately with Step 1.

**State file updates**: Update the state file before and after each step as instructed below. These updates enable workflow resume and provide audit trail.

**IMPORTANT: File-First Principle**
- Do NOT pass file contents or summaries to agents
- Only pass file PATHS - agents read files themselves

**Orchestrator Boundaries**
- You READ input files to validate they exist
- You SPAWN agents (Generator, Gap Formatter, Discussion Facilitator, Author) to do work
- You CREATE structure files (deferred-items.md, pending-issues.md)
- You COPY the final draft to `foundations.md` (promotion)
- You DO NOT write draft Foundations content, gap discussion content, or author output — agents do that

### Step 1: Validate Prerequisites

0. **Update state file**: Set status = IN_PROGRESS (create state file if fresh start)

1. **Check PRD exists** at `system-design/02-prd/prd.md`
   - **If NO**: Error - "Cannot initialize Foundations - PRD not found"
   - **If YES**: Continue

### Step 2: Setup Structure

1. **Create directories** (if not exist):
   ```
   system-design/03-foundations/
   └── versions/
       └── round-0/
   ```

2. **Create deferred-items.md** (if not exists) at `system-design/03-foundations/versions/deferred-items.md`:
   ```markdown
   # Foundations Deferred Items

   Items deferred for later consideration or downstream stages.

   ---

   <!-- No deferred items yet -->
   ```

3. **Create pending-issues.md** (if not exists) at `system-design/03-foundations/versions/pending-issues.md`:
   ```markdown
   # Pending Issues: Foundations

   Issues discovered that need resolution.

   ---

   <!-- No issues logged yet -->
   ```

4. **Ensure downstream deferred items files exist** (Generator may append to these):
   - `system-design/04-architecture/versions/deferred-items.md`
   - `system-design/05-components/versions/deferred-items.md`

### Step 3: Deferred Items Intake

1. **Read deferred items** at `system-design/03-foundations/versions/deferred-items.md`

2. **If empty or no PENDING items**: Skip to Step 4

3. **If has PENDING items**:

   a. **Read final PRD**: `system-design/02-prd/prd.md`

   b. **For each PENDING item, validate relevance**:
      - Check if topic is addressed in final PRD
      - Update validation status:
        - `RESOLVED_UPSTREAM`: Fully addressed in PRD - mark closed
        - `PARTIALLY_ADDRESSED`: Touched but not resolved - keep for Generator
        - `STILL_RELEVANT`: Not addressed - keep for Generator

   c. **Update deferred items** with validation results

### Step 3b: Check for Brief

1. **Check if brief document exists** at `system-design/03-foundations/brief.md`
   - If an explicit brief path was provided in the invocation, use that instead
2. **If brief exists**: Will be passed to Generator as additional input
3. **If no brief**: Continue without (standard generation)

4. **Update state file**: Mark "Step 1-3b: Validate & Setup" complete `[x]`, add history entry

### Step 4: Run Generator

**On resume**: If Step 4 already marked complete, verify `00-draft-foundations.md` exists and skip to Step 5. Do NOT re-run the Generator (it appends to downstream deferred items files and would create duplicates).

1. **Spawn Generator agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/03-foundations/create/generator.md

   Input:
   - PRD: system-design/02-prd/prd.md
   - Foundations guide: {{GUIDES_PATH}}/03-foundations-guide.md
   - Deferred items: system-design/03-foundations/versions/deferred-items.md
   - Brief: system-design/03-foundations/brief.md (if exists)

   Output: system-design/03-foundations/versions/round-0/00-draft-foundations.md

   Downstream deferred items (Generator may append):
   - Architecture: system-design/04-architecture/versions/deferred-items.md
   - Components: system-design/05-components/versions/deferred-items.md
   ```

2. **Wait for Generator to complete**

3. **Verify output exists** at `system-design/03-foundations/versions/round-0/00-draft-foundations.md`

4. **Update state file**: Mark "Step 4: Run Generator" complete `[x]`, add history entry

### Step 5: Format & Analyse Gaps

1. **Read the draft** at `system-design/03-foundations/versions/round-0/00-draft-foundations.md`

2. **Check for Gap Summary section** — Look for `## Gap Summary` heading

3. **If no Gap Summary, or all subsections empty** (Must Answer, Should Answer, and Assumptions all show "None" or similar):
   - **Update state file**: Set `Gaps Exist` = `false`, mark Steps 5-7 complete `[x]`, add history entry "No gaps found — skipping to promotion"
   - **Skip Steps 5-7, proceed to Step 8**

4. **Spawn Gap Formatter agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/universal-agents/gap-formatter.md

   Input:
   - Draft: system-design/03-foundations/versions/round-0/00-draft-foundations.md

   Output: system-design/03-foundations/versions/round-0/01-gap-discussion.md
   ```

5. **Wait for Gap Formatter to complete**

6. **Verify output exists** at `system-design/03-foundations/versions/round-0/01-gap-discussion.md`

7. **Read output** — count gaps by severity for the Step 6 handoff message

8. **Spawn Gap Analyst agents** using Task tool (batch by section, same grouping as Discussion Facilitator):
   ```
   Follow the instructions in: {{AGENTS_PATH}}/universal-agents/gap-analyst.md

   Context documents:
   - Draft Foundations: system-design/03-foundations/versions/round-0/00-draft-foundations.md
   - PRD: system-design/02-prd/prd.md
   - Brief: system-design/03-foundations/brief.md (if exists)

   Gap discussion file: system-design/03-foundations/versions/round-0/01-gap-discussion.md
   Gaps: [GAP-001, GAP-002, ...]
   ```

9. **Wait for all Gap Analyst agents to complete**

10. **Verify analyst responses were written** (MANDATORY):
    - Count `>> AGENT:` markers in the gap discussion file
    - Compare to total number of gaps
    - If counts don't match: identify missing gaps and re-invoke Gap Analyst for those only

11. **Update state file**: Set `Gaps Exist` = `true`, mark "Step 5: Format & Analyse Gaps" complete `[x]`, add history entry with gap counts

### Step 6: Discussion Loop

**On resume**: If status = WAITING_FOR_HUMAN for Step 6, re-read `01-gap-discussion.md` and continue the discussion loop from step 11(a) below — identify which gaps still need responses.

8. **Update state file**: Set status = WAITING_FOR_HUMAN, add history entry

9. **Notify user** gap analysis is ready for review:
   ```
   Gap analysis complete.

   Discussion file: system-design/03-foundations/versions/round-0/01-gap-discussion.md

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
       - Group by Foundations section number (gaps contain `**Section**: §N`)
       - Batch 1: Sections 1-4 (Technology, Architecture, Auth, Data)
       - Batch 2: Sections 5-8 (API, Error Handling, Logging, Security)
       - Batch 3: Sections 9-11 (Testing, Deployment, Open Questions)
       - If fewer than 4 gaps total, use fewer batches

    c. **Invoke Discussion Facilitator agents** (one per batch, in parallel):
       ```
       Follow the instructions in: {{AGENTS_PATH}}/universal-agents/discussion-facilitator.md

       Context documents:
       - Draft Foundations: system-design/03-foundations/versions/round-0/00-draft-foundations.md
       - PRD: system-design/02-prd/prd.md

       Issues file: system-design/03-foundations/versions/round-0/01-gap-discussion.md
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

    j. **If all gaps resolved**: Proceed to Step 7

12. **Resolution indicators** (human response after `>> AGENT:` that signals done):
    - Agreement: "Yes", "Agreed", "That works", "Fine", "OK"
    - Dismissal: "Not a concern", "Not relevant", "Ignore", "Skip"
    - Acceptance: "Makes sense", "Fair enough", "Understood"

13. **Continue discussion indicators** (do NOT mark resolved):
    - Questions: "?", "What about", "How would", "Can you"
    - Requests: "Please", "Can you", "I'd like", "Show me"
    - Pushback: "I disagree", "That's not right", "But what about"

### Step 6→7 Gate

**Before invoking Author:**
1. Read `01-gap-discussion.md`
2. Verify EVERY gap has `>> RESOLVED` marker
3. If any gap lacks `>> RESOLVED`: Do NOT proceed. Continue discussion loop.
4. Only proceed to Step 7 when all gaps show `>> RESOLVED`

This gate is mandatory. Do not skip it.

5. **Update state file**: Mark "Step 6: Discussion Loop" complete `[x]`, set status = IN_PROGRESS, add history entry "All gaps resolved"

### Step 7: Apply Decisions

14. **Spawn Author agent** using Task tool:
    ```
    Follow the instructions in: {{AGENTS_PATH}}/03-foundations/create/author.md

    Input:
    - Draft Foundations: system-design/03-foundations/versions/round-0/00-draft-foundations.md
    - Gap discussion: system-design/03-foundations/versions/round-0/01-gap-discussion.md
    - Foundations guide: {{GUIDES_PATH}}/03-foundations-guide.md

    Output:
    - Change log: system-design/03-foundations/versions/round-0/02-author-output.md
    - Updated Foundations: system-design/03-foundations/versions/round-0/03-updated-foundations.md
    ```

15. **Wait for Author to complete**

16. **Verify outputs exist**:
    - `system-design/03-foundations/versions/round-0/02-author-output.md`
    - `system-design/03-foundations/versions/round-0/03-updated-foundations.md`

17. **Update state file**: Mark "Step 7: Apply Decisions" complete `[x]`, add history entry

### Step 8: Promote & Report

18. **Determine final draft path**:
    - If Steps 5-7 ran (gaps existed): Use `system-design/03-foundations/versions/round-0/03-updated-foundations.md`
    - If Steps 5-7 were skipped (no gaps): Use `system-design/03-foundations/versions/round-0/00-draft-foundations.md`

19. **Copy final draft to `foundations.md`** using Bash cp:
    ```
    cp [final draft path] system-design/03-foundations/foundations.md
    ```

20. **Verify promotion** — Confirm `system-design/03-foundations/foundations.md` exists

21. **Update state file**: Mark "Step 8: Promote & Report" complete `[x]`, set status = COMPLETE, add history entry

22. **Check downstream deferred items** for items the Generator deferred

23. **Present summary**:
    ```
    Foundations creation complete.

    Draft: system-design/03-foundations/versions/round-0/00-draft-foundations.md
    [If gaps resolved:]
    Updated: system-design/03-foundations/versions/round-0/03-updated-foundations.md
    Promoted to: system-design/03-foundations/foundations.md

    Brief: [Used / Not provided]

    [If gaps were resolved:]
    Gap resolution:
    - [N] gaps discussed
    - [M] changes applied by author
    - [K] flagged for attention (see 02-author-output.md)

    [If no gaps:]
    No gaps found — brief was fully specified.

    Deferred to downstream:
    - [X] items to Architecture deferred items
    - [Y] items to Components deferred items

    Next steps:
    1. Review foundations.md — verify promoted content looks correct
    2. When ready, run the Foundations Review workflow
       (Review reads from: system-design/03-foundations/foundations.md)
    ```

---

## Stopping Points

**Automatic flow (do NOT pause for human confirmation):**
- Steps 1 → 2 → 3 → 3b → 4 → 5: Proceed automatically through to gap analysis
- Step 7 → 8: Execute after all gaps resolved

**Human checkpoints:**
- **Step 6** — WAITING FOR HUMAN for gap discussion until all gaps resolved
- **Step 5 → 8 skip** — If no gaps, proceed automatically from Step 5 check to Step 8

---

## Error Handling

| Condition | Action |
|-----------|--------|
| PRD not found | Error: "Cannot initialize Foundations - PRD not found at system-design/02-prd/prd.md" |
| Generator fails | Error: Report failure details |
| Draft not created | Error: "Generator completed but draft not found at expected path" |
| Gap Formatter fails | Error: Report failure details |
| Gap discussion file not created | Error: "Gap Formatter completed but output not found at expected path" |
| Author fails | Error: Report failure details |
| Author output files not created | Error: "Author completed but outputs not found at expected paths" |
| Promotion copy fails | Error: "Failed to copy final draft to foundations.md" |
| State file corrupted/unreadable | Warning: Report issue, re-create state from file existence checks |
| Resume: draft missing but Step 4 marked complete | Error: "State says Generator complete but draft not found — re-run Generator or fix state file" |

---

## What Happens Next

After this orchestrator completes:

1. **Human reviews promoted Foundations** — Opens `system-design/03-foundations/foundations.md`
2. **Human optionally makes manual edits** — Can refine directly
3. **Human runs Review workflow** — Invokes the Foundations Review orchestrator

**IMPORTANT**: The Review workflow reads from `system-design/03-foundations/foundations.md` for Round 1. This file is created by the promotion step (Step 8). It MUST exist before starting the Review workflow.

The Review workflow will:
- Run expert reviewers on the Foundations
- Facilitate discussion on issues found
- Author changes and verify alignment with PRD
- Promote final version (overwriting `foundations.md` with reviewed version)

---

<!-- INJECT: tool-restrictions -->
