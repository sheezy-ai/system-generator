# Blueprint Review Orchestrator

---

## Workflow State Management

**State file**: `system-design/01-blueprint/versions/workflow-state.md`

### On Start/Resume

1. **Check if state file exists**:
   - **If NO**: Create it, initialize Round 1 Step 1, use original Blueprint path
   - **If YES**: Read it and check `Current Round`:
     - **If Round 0 and Status COMPLETE**: Creation finished — initialize Round 1, preserve existing history, use original Blueprint path
     - **If Round 0 and Status not COMPLETE**: Error — "Creation workflow still in progress"
     - **If Round >= 1**: Resume from current round/step

2. **Determine Blueprint source path**:
   - **Round 1**: Use `system-design/01-blueprint/blueprint.md` (parent folder)
   - **Round 2+**: Use `system-design/01-blueprint/versions/round-{N-1}/05-updated-blueprint.md`

3. **Copy source to round folder**: Copy the source Blueprint to `system-design/01-blueprint/versions/round-[N]/00-blueprint.md`. All agents in this round work from this copy.

4. **Update state file** at each step transition

### State File Format

```markdown
# Blueprint Review Workflow State

**Blueprint**: 01-blueprint/blueprint.md
**Current Round**: 1
**Status**: IN_PROGRESS | WAITING_FOR_HUMAN | COMPLETE
**On Response**: (When WAITING_FOR_HUMAN) Spawn discussion-facilitator agents for issues needing response. Do NOT answer in chat.

## Progress

### Round 1
- [x] Step 1: Expert Review
- [ ] Step 2: Consolidation
- [ ] Step 3: Scope Filter
- [ ] Step 3b: Issue Analysis
- [ ] Step 4: Discussion
- [ ] Step 5: Apply Changes
- [ ] Step 6: Verification

## History
- YYYY-MM-DD HH:MM: Round 1 started
- YYYY-MM-DD HH:MM: Step 1 complete (28 issues identified)
```

### State Transitions

Update the state file:
- **Before starting each step**: Set status = IN_PROGRESS
- **After completing each step**: Mark checkbox, add history entry
- **When waiting for human**: Set status = WAITING_FOR_HUMAN
- **When round complete**: Increment round, reset to Step 1 or set COMPLETE

---

## Fixed Paths

**Output directory**: `system-design/01-blueprint/versions`
**State file**: `system-design/01-blueprint/versions/workflow-state.md`

Review uses `round-1`, `round-2`, etc. Creation workflow uses `round-0`. This allows both workflows to share the same `versions/` folder with a unified state file, preserving the original Blueprint and maintaining full version history.

---

## Prompt Locations

```
agents/review/
├── orchestrator.md                    # This file (trigger prompt)
│
├── experts/                           # Parallel expert reviewers
│   ├── strategist.md
│   ├── commercial.md
│   ├── customer-advocate.md
│   └── operator.md
│
└── workflow/                          # Sequential processing steps
    ├── consolidator.md
    ├── author.md
    └── change-verifier.md

Create agents (in {{AGENTS_PATH}}/01-blueprint/create/):
└── scope-extractor.md                 # Re-extracts scope brief during promote

Universal agents (in {{AGENTS_PATH}}/universal-agents/):
├── scope-filter.md                    # Filters issues and outputs summary format
├── issue-analyst.md                   # Pre-analyzes issues with options and trade-offs
└── discussion-facilitator.md          # Facilitates discussions including solution proposals
```

---

## Output Directory Structure

```
versions/
├── workflow-state.md          # Tracks current round/step for resume (shared)
├── round-0/                   # Creation workflow output (if used)
│   └── ...
├── round-1/                   # First review round
│   ├── 00-blueprint.md            # Snapshot of input (copied at round start)
│   ├── 01-strategist.md
│   ├── 01-commercial.md
│   ├── 01-customer-advocate.md
│   ├── 01-operator.md
│   ├── 02-consolidated-issues.md   # Full detail
│   ├── 03-issues-discussion.md        # Summary format for human response + inline discussions
│   ├── 04-author-output.md
│   ├── 05-updated-blueprint.md
│   └── 06-change-verification-report.md
└── round-2/
    └── ...
```

---

## Orchestration Workflow

**Immediate execution**: The user invoking this orchestrator IS the instruction to execute. Do not ask for confirmation before starting. Proceed immediately with Step 1.

**IMPORTANT: File-First Principle**
- Do NOT pass file contents or summaries to agents
- Only pass file PATHS - agents read files themselves
- This reduces context usage and prevents information loss

**Orchestrator Boundaries**

You orchestrate - you do not write workflow content.
- You READ state files and workflow outputs
- You SPAWN agents to do work
- You UPDATE state files with status changes
- You DO NOT author workflow content (expert reviews, consolidated issues, analysis, document changes)
- You DO write orchestrator markers (`>> RESOLVED`) and state file updates directly via Edit
- You DO NOT answer human questions directly in chat - spawn Discussion Facilitators
- Spawn agents in FOREGROUND (not background) — agents need interactive approval for file writes

If human responds to issues asking for analysis or discussion, spawn Discussion Facilitator agents. The orchestrator never provides analysis itself.

**Context management**: The orchestrator persists across the entire review lifecycle (multiple rounds, multiple steps). Every document you Read stays in context. Spawned subagents run in their own context via the Task tool. Keep your context lean — use Grep for targeted extraction from state and output files, `ls` for existence checks. Expert reports and working files are read by subagents, not by the orchestrator.

**What You Read:**
- Workflow state file (to determine current step and status)
- Agent output files (to verify completion before proceeding)

**What You Do NOT Read:**
- Agent prompt files - agents read their own instructions
- Input documents being passed to agents
- Any file where you're passing the path to an agent

Rule: If a file path appears in your agent invocation, don't read it yourself.

**Agent Invocation Pattern**

When spawning subagents via Task tool:
- Point to the agent prompt file as the sole instruction source
- Provide only runtime-specific paths (input files, output files)
- Do NOT add instructions that duplicate the prompt file content

```
Follow the instructions in: [agent-prompt-path]

Input: [resolved file paths]
Output: [resolved file path]
```

**State file updates**: Update the state file before and after each step as instructed below. These updates enable workflow resume and provide audit trail.

### Step 0: Pending Issue Check

**On workflow start**, check for pending issues logged against this document:

1. **Read** `system-design/01-blueprint/versions/pending-issues.md` (if it exists)

2. **Check for unresolved issues**:
   - If unresolved pending issues exist, **notify human**:
     ```
     Note: [N] pending issue(s) logged against this Blueprint from downstream stages.
     These will be incorporated into the review at Step 2 (Consolidation).
     See system-design/01-blueprint/versions/pending-issues.md for details.
     ```
   - If no unresolved issues, proceed silently

3. **Proceed to Step 1** (pending issues will be merged by Consolidator)

---

### Step 1: Expert Issue Identification (Parallel)

1. **Update state file**: Set Step 1, status = IN_PROGRESS

2. **Create round directory and copy input**:
   - Create `system-design/01-blueprint/versions/round-[N]/`
   - Copy source Blueprint (determined in On Start/Resume) to `round-[N]/00-blueprint.md`
   - If source doesn't exist, **error and stop**

3. **Spawn expert agents in parallel** using Task tool
   - Pass to each agent:
     - Blueprint file path: `system-design/01-blueprint/versions/round-[N]/00-blueprint.md`
     - Output file path (agent writes to it)
     - Round number
   - Agents identify **issues only** (no solutions)
   - Agents include clarifying questions where needed
   - Agents write directly to `system-design/01-blueprint/versions/round-[N]/01-[expert-name].md`

4. **Wait for all agents to complete**

5. **Update state file**: Mark Step 1 complete, add history entry

6. **Automatically proceed to Step 2** (no human checkpoint needed here)

### Step 2: Consolidation

7. **Update state file**: Set Step 2, status = IN_PROGRESS

8. **Run Consolidator** (MUST spawn as subagent using Task tool - do NOT perform inline)
   - Pass: paths to all expert output files + output path
   - Agent reads expert files, merges issues, groups by theme
   - Agent writes to `system-design/01-blueprint/versions/round-[N]/02-consolidated-issues.md`

9. **Update state file**: Mark Step 2 complete, add history entry

10. **Automatically proceed to Step 3** (no human checkpoint needed here)

### Step 3: Scope Filter

11. **Update state file**: Set Step 3, status = IN_PROGRESS

12. **Run Scope Filter agent** (MUST spawn as subagent using Task tool - do NOT perform inline)
    ```
    Follow the instructions in: {{AGENTS_PATH}}/universal-agents/scope-filter.md

    Stage guide: guides/01-blueprint-guide.md
    Input: system-design/01-blueprint/versions/round-[N]/02-consolidated-issues.md
    Output: system-design/01-blueprint/versions/round-[N]/03-issues-discussion.md
    ```
    - Agent filters issues to appropriate level
    - Agent outputs summary format (ID, severity, summary, core question)
    - Agent defers wrong-level items to downstream deferred items files

13. **Update state file**: Mark Step 3 complete, add history entry

14. **Zero-issues gate**: Read `03-issues-discussion.md` and count kept issues (under the `## Issues` section).
    - **If zero kept issues**: The document is complete. Skip Steps 3b–6 and proceed directly to Step 7 (Promote). Update state file with history entry: "Zero kept issues after filtering — proceeding to promotion."
    - **If one or more kept issues**: Automatically proceed to Step 3b.

### Step 3b: Issue Analysis

15. **Update state file**: Set Step 3b, status = IN_PROGRESS

16. **Run Issue Analyst agents** (MUST spawn as subagents using Task tool - do NOT perform inline)

    Group issues into batches:
    - Group by Blueprint section (issues contain `**Section**: Section N` or similar)
    - Aim for ~5-7 issues per batch maximum
    - If fewer than 4 issues total, use a single batch

    Invoke Issue Analyst agents (one per batch, in parallel):
    ```
    Follow the instructions in: {{AGENTS_PATH}}/universal-agents/issue-analyst.md

    Context documents:
    - Blueprint: system-design/01-blueprint/versions/round-[N]/00-blueprint.md

    Issues file: system-design/01-blueprint/versions/round-[N]/03-issues-discussion.md
    Issues: [ID1, ID2, ID3, ...]
    ```

17. **Verify analyst responses were written** (MANDATORY):
    - Count `>> AGENT:` markers in the issues file
    - Compare to total number of in-scope issues
    - If counts don't match: re-invoke for missing issues

18. **Update state file**: Mark Step 3b complete

19. **Automatically proceed to Step 4**

### Step 4: Discussion

20. **Update state file**: Set Step 4, status = WAITING_FOR_HUMAN

21. **Notify user** issues are ready for discussion
    - Point them to `system-design/01-blueprint/versions/round-[N]/03-issues-discussion.md`
    - Full detail available in `02-consolidated-issues.md` if needed

**STOP: Wait for human response before proceeding.**

Do NOT enter the discussion loop until the human has added actual response content after `>> HUMAN:` markers. An empty `>> HUMAN:` marker (as generated by Scope Filter) is a placeholder for where the human WILL respond—it is not a response itself.

Only proceed to step 22 after the human signals they have responded (e.g., "done", "ready", "I've responded", or resumes the conversation after editing the file).

22. **Discussion markers**:
    - Human responds using `>> HUMAN:` prefix
    - Agent responds using `>> AGENT:` prefix
    - `>> RESOLVED` marks discussion complete (added by orchestrator only)

23. **Discussion loop**:

    a. **Identify issues needing agent response**: Read file, find issues where last entry is `>> HUMAN:` without subsequent `>> AGENT:`

    b. **Group issues into batches**:
       - Group by Blueprint section (issues contain `**Section**: Section N` or similar)
       - Aim for ~5-7 issues per batch maximum
       - If fewer than 4 issues total, use fewer batches

    c. **Invoke Discussion Facilitator agents** (one per batch, in parallel):
       ```
       Follow the instructions in: {{AGENTS_PATH}}/universal-agents/discussion-facilitator.md

       Context documents:
       - Blueprint: system-design/01-blueprint/versions/round-[N]/00-blueprint.md

       Issues file: system-design/01-blueprint/versions/round-[N]/03-issues-discussion.md
       Issues: [ID1, ID2, ID3, ...]
       ```

    d. **Wait for all agents to complete**

    e. **Verify agent responses were written** (MANDATORY):
       - Count `>> AGENT:` markers in the issues file
       - Compare to number of issues that were assigned to Discussion Facilitators
       - If counts match: Proceed to step (f)
       - If counts don't match:
         - Identify which issues are missing `>> AGENT:` responses
         - Re-invoke Discussion Facilitators for ONLY the missing issues
         - Repeat verification until all assigned issues have responses

    f. **Present to human**: "Please review the agent responses and reply to each issue."

    g. **Update state file**: Set status = WAITING_FOR_HUMAN

    **STOP: Do not read the issues file or check for responses.** The human needs time to review agent responses. Resume only when the human signals they have responded (e.g., "done", "ready", "I've responded").

    h. **After human responds**, read file and for each issue:
       - If last entry is `>> HUMAN:` after `>> AGENT:` AND response indicates closure → add `>> RESOLVED`
       - If last entry is `>> HUMAN:` with question, pushback, or request → leave open

    i. **If any issues unresolved**: Go to step (a)

    j. **If all issues resolved**: Proceed to Step 4→5 Gate

24. **Resolution indicators** (human response after `>> AGENT:` that signals done):
    - Agreement: "Yes", "Agreed", "That works", "Fine", "OK"
    - Dismissal: "Not a concern", "Not relevant", "Ignore", "Skip"
    - Acceptance: "Makes sense", "Fair enough", "Understood"

25. **Continue discussion indicators** (do NOT mark resolved):
    - Questions: "?", "What about", "How would", "Can you"
    - Requests: "Please", "Can you", "I'd like", "Show me"
    - Pushback: "I disagree", "That's not right", "But what about"

### Step 4→5 Gate

**Before invoking Author:**
1. Read `03-issues-discussion.md`
2. Verify EVERY issue has `>> RESOLVED` marker
3. If any issue lacks `>> RESOLVED`: Do NOT proceed. Continue discussion loop.
4. Only proceed to Step 5 when all issues show `>> RESOLVED`

This gate is mandatory. Do not skip it.

### Step 5: Apply Changes

26. **Update state file**: Set Step 5, status = IN_PROGRESS

27. **Run Author agent**
    - Pass: paths to Blueprint (`round-[N]/00-blueprint.md`) + issues-summary file (with resolved discussions) + output paths
    - Agent reads each resolved discussion's proposed changes from `03-issues-discussion.md`
    - Agent applies the confirmed changes
    - Agent writes to `system-design/01-blueprint/versions/round-[N]/04-author-output.md` (changelog) and `system-design/01-blueprint/versions/round-[N]/05-updated-blueprint.md`

28. **Update state file**: Mark Step 5 complete, add history entry

29. **Automatically proceed to Step 6** (no human checkpoint needed here)

### Step 6: Verify

30. **Update state file**: Set Step 6, status = IN_PROGRESS

31. **Run Verifier agent**
    - Pass: paths to issues-summary (with resolutions) + author output + updated Blueprint + output path
    - Agent verifies each resolution was applied correctly
    - Agent checks for level violations (scope creep)
    - Agent writes to `system-design/01-blueprint/versions/round-[N]/06-change-verification-report.md`

32. **Update state file**: Mark Step 6 complete, add history entry

33. **Route based on results**:
    - All RESOLVED → Update state: status = WAITING_FOR_HUMAN, ask user: next round or exit?
    - Some NOT_RESOLVED → Return to Author (Step 5)
    - Some LEVEL_VIOLATION → Return to Author to simplify (Step 5)
    - PARTIALLY_RESOLVED → Update state: status = WAITING_FOR_HUMAN, ask user to decide

34. **If user chooses next round**: Update state file to increment round, reset to Step 1
35. **If user chooses exit**: Proceed to Step 7 (Promote)

### Step 7: Promote

36. **Copy reviewed Blueprint to canonical path**:
    - Copy `system-design/01-blueprint/versions/round-[N]/05-updated-blueprint.md` to `system-design/01-blueprint/blueprint.md`

37. **Verify output file exists**: `system-design/01-blueprint/blueprint.md`

38. **Re-extract scope brief** — The reviewed Blueprint may have changed scoping sections. Re-run the Scope Extractor to keep the scope brief consistent:
    ```
    Follow the instructions in: {{AGENTS_PATH}}/01-blueprint/create/scope-extractor.md

    Input:
    - Blueprint: system-design/01-blueprint/blueprint.md

    Output: system-design/01-blueprint/scope-brief.md
    ```

39. **Update state file**: status = COMPLETE

---

## Stopping Points

**Automatic flow (do NOT pause for human confirmation):**
- Steps 1 → 2 → 3 → zero-issues gate: If zero kept issues → skip to Step 7 (Promote)
- Steps 3 → 3b → 4: If kept issues exist, proceed automatically until Step 4 Discussion
- Steps 5 → 6: Once all issues are RESOLVED, execute these steps without pausing

**Human checkpoints:**
- **Step 4** — WAITING_FOR_HUMAN for discussion until all issues resolved
- **After Step 6** — User decides: next round or exit

Do NOT ask "Should I proceed?" between automatic steps. Only stop at the human checkpoints listed above.

---

## Exit Criteria

The review exits via one of two paths:

1. **Automatic exit (zero-issues gate)**: After Step 3 (scope filter), if zero issues remain in the kept list after consolidation, re-raise detection, and scope/depth filtering, the document is complete. The orchestrator skips Steps 3b–6 and proceeds directly to Step 7 (Promote).

2. **Human override**: After Step 6, the user can choose to exit even if issues were found in the current round. This is a fallback for cases where remaining issues are not worth another round.

**After final round**: Run the Promote step (Step 7) to copy the reviewed Blueprint to its canonical path at `system-design/01-blueprint/blueprint.md`.

---

<!-- INJECT: tool-restrictions -->
