# Architecture Expand Orchestrator

---

## Purpose

Expand the Architecture Overview by adding new capability areas or scope changes to an existing, promoted document. Unlike Create (which generates from scratch) or Review (which critiques and refines), Expand adds new content driven by a specific trigger — a downstream discovery, a scope decision, or a human-identified gap.

The expand workflow produces an updated Architecture Overview that reads as if the expanded capability was always in scope. It does not promote — the next step is always a Review round.

---

## Workflow State Management

**State file**: `system-design/04-architecture/versions/workflow-state.md`

### On Start/Resume

1. **Check if state file exists**:
   - **If NO**: Error — "No state file found. Run Create workflow first."
   - **If YES**: Read it and check `Current Workflow`:
     - **If `Create` and Status not COMPLETE**: Error — "Creation workflow still in progress"
     - **If any workflow and Status COMPLETE**: Initialize expand round, preserve existing history
     - **If `Expand`**: Resume from current round/step

2. **Determine Architecture Overview source path**:
   - Read the state file history to identify the last completed round number and type
   - **If no previous rounds exist** (first ever round): Use the upstream input documents: `system-design/02-prd/prd.md` and `system-design/03-foundations/foundations.md`
   - **If previous rounds exist**: Use the full updated document from the last completed round:
     - Last round was create: `versions/round-{N}-create/03-updated-architecture.md` (or `versions/round-{N}-create/00-draft-architecture.md` if only draft exists)
     - Last round was review: `versions/round-{N}-review/05-updated-architecture.md`
     - Last round was expand: `versions/round-{N}-expand/05-updated-architecture.md`
   - **Never use the promoted file** (`architecture.md` in the parent folder) as input — it may have been split by the review promoter, losing rationale and future content

3. **Copy source to round folder**: Copy the source Architecture Overview to `system-design/04-architecture/versions/round-[N]-expand/00-architecture.md`. All agents in this round work from this copy.

4. **Update state file** at each step transition

### State File Format

```markdown
# Architecture Overview Workflow State

**Architecture Overview**: 04-architecture/architecture.md
**Foundations**: 03-foundations/foundations.md
**PRD**: 02-prd/prd.md
**Current Workflow**: Expand
**Current Round**: [N]
**Status**: IN_PROGRESS | WAITING_FOR_HUMAN | COMPLETE

## Progress

### Round [N] (Expand)
- [ ] Step 1: Scope
- [ ] Step 2: Explore
- [ ] Step 3: Consolidation
- [ ] Step 4: Expansion Review
- [ ] Step 5: Integration
- [ ] Step 6: Change Verification
- [ ] Step 7: Alignment Verification
- [ ] Step 8: Internal Coherence
- [ ] Step 9: Enumeration Verification
- [ ] Step 10: Verification Review
- [ ] Step 11: Route

## History
- YYYY-MM-DD HH:MM: Round [N] (Expand) started — [trigger description]
```

---

## Fixed Paths

**Output directory**: `system-design/04-architecture/versions`
**State file**: `system-design/04-architecture/versions/workflow-state.md`
**Working files**: `system-design/04-architecture/versions/round-[N]-expand/`

Round directories follow the unified naming convention: `round-1-create`, `round-9-review`, `round-15-expand`, etc. The round number is globally sequential across all workflow types.

---

## Prompt Locations

```
agents/expand/
├── orchestrator.md                    # This file
├── scope-analyst.md                   # Produces Expansion Brief from trigger input
├── expansion-explorer.md              # Investigates capability areas, produces change sets
├── proposal-filter.md                 # Filters proposals by level, formats for human review
└── integration-author.md              # Applies approved changes to existing document

Universal agents (in {{AGENTS_PATH}}/universal-agents/):
├── exploration-consolidator.md        # Merges proposals across multiple explorers
├── alignment-verifier.md              # Verifies alignment with source documents
├── internal-coherence-checker.md      # Verifies cross-section consistency
├── enumeration-verifier.md            # Verifies enumeration section completeness
├── change-verifier.md                 # Verifies changes were applied correctly (see note)
└── discussion-facilitator.md          # Facilitates discussions including solution proposals
```

Note: Change verification for expand uses the review workflow's change-verifier agent (`{{AGENTS_PATH}}/04-architecture/review/workflow/change-verifier.md`) since the verification logic is the same.

---

## Output Directory Structure

```
system-design/04-architecture/versions/
├── workflow-state.md
├── round-[N]-expand/
│   ├── 00-architecture.md              # Snapshot of input (copied at round start)
│   ├── 00-trigger.md                   # Trigger input (copied or created at round start)
│   ├── 01-expansion-brief.md           # Scope Analyst output
│   ├── 02-explorer-{cap-name}.md       # One per capability area
│   ├── 03-consolidated-proposals.md    # Merged proposals (if multiple capability areas)
│   ├── 03-expansion-review.md          # Proposals in discussion format for human review
│   ├── 04-integration-output.md        # Change log
│   ├── 05-updated-architecture.md      # Updated Architecture Overview with expansion applied
│   ├── 06-change-verification.md
│   ├── 07-alignment-report.md
│   ├── 08-coherence-report.md
│   ├── 09-enumeration-report.md
│   └── 10-verification-summary.md
└── pending-issues.md
```

---

## Orchestration Workflow

**Immediate execution**: The user invoking this orchestrator IS the instruction to execute. Do not ask for confirmation before starting. Proceed immediately with Step 1.

**IMPORTANT: File-First Principle**
- Do NOT pass file contents or summaries to agents
- Only pass file PATHS — agents read files themselves

**Orchestrator Boundaries**

You orchestrate — you do not write workflow content.
- You READ state files and workflow outputs
- You SPAWN agents to do work
- You UPDATE state files with status changes
- You DO NOT author workflow content (expansion briefs, proposals, document changes)
- You DO write orchestrator markers (`>> RESOLVED`) and state file updates directly via Edit
- You DO NOT answer human questions directly in chat — spawn Discussion Facilitators
- Spawn agents in FOREGROUND (not background) — agents need interactive approval for file writes

**Context management**: Keep your context lean — use Grep for targeted extraction from state and output files, `ls` for existence checks. Agent reports and working files are read by subagents, not by the orchestrator.

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

**State file updates**: Update the state file before and after each step as instructed below.

---

### Step 1: Scope

1. **Update state file**: Set Step 1, status = IN_PROGRESS

2. **Determine trigger input**:
   - If a pending issues file exists with unresolved issues: use `system-design/04-architecture/versions/pending-issues.md`
   - If the human provided a trigger description in the invocation: create `round-[N]-expand/00-trigger.md` with the description
   - If neither: ask the human what the expansion is about — **STOP** until they provide input

3. **Run Scope Analyst**:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/04-architecture/expand/scope-analyst.md

   Trigger: system-design/04-architecture/versions/round-[N]-expand/00-trigger.md
   Architecture: system-design/04-architecture/versions/round-[N]-expand/00-architecture.md
   PRD: system-design/02-prd/prd.md
   Foundations: system-design/03-foundations/foundations.md
   Stage guide: {{GUIDES_PATH}}/04-architecture-guide.md
   Output: system-design/04-architecture/versions/round-[N]-expand/01-expansion-brief.md
   ```

4. **Update state file**: Add history entry

5. **Present Expansion Brief to human**:
   - Point them to `round-[N]-expand/01-expansion-brief.md`
   - Ask them to review: expansion thesis, capability areas, affected sections, scope boundaries

6. **Update state file**: Set status = WAITING_FOR_HUMAN

**STOP: Wait for human response before proceeding.**

7. **After human responds**:
   - If human approves: Mark Step 1 complete, proceed to Step 2
   - If human requests changes: Spawn Discussion Facilitator for discussion, then re-run Scope Analyst with updated input after resolution
   - If human rejects the expansion entirely: Mark workflow COMPLETE with history "Expansion cancelled by human"

---

### Step 2: Explore

8. **Update state file**: Set Step 2, status = IN_PROGRESS

9. **Read the Expansion Brief** to determine capability areas

10. **Spawn Expansion Explorers** (one per capability area, in parallel):
    ```
    Follow the instructions in: {{AGENTS_PATH}}/04-architecture/expand/expansion-explorer.md

    Expansion Brief: system-design/04-architecture/versions/round-[N]-expand/01-expansion-brief.md
    Capability area: [CAP-ID]
    Architecture: system-design/04-architecture/versions/round-[N]-expand/00-architecture.md
    PRD: system-design/02-prd/prd.md
    Foundations: system-design/03-foundations/foundations.md
    Stage guide: {{GUIDES_PATH}}/04-architecture-guide.md
    Output: system-design/04-architecture/versions/round-[N]-expand/02-explorer-{cap-name}.md
    ```

11. **Wait for all explorers to complete**

12. **If multiple capability areas** (2+), run Exploration Consolidator:
    ```
    Follow the instructions in: {{AGENTS_PATH}}/universal-agents/exploration-consolidator.md

    Explorer files: [list of 02-explorer-*.md paths]
    Architecture: system-design/04-architecture/versions/round-[N]-expand/00-architecture.md
    Output: system-design/04-architecture/versions/round-[N]-expand/03-consolidated-proposals.md
    ```
    **IMPORTANT**: The consolidated proposals file must contain raw proposal content only — no discussion markers (`>> HUMAN:`, `>> AGENT:`, `>> RESOLVED`). These are added by the Proposal Filter in Step 3.

13. **If single capability area**: Copy the explorer output to `03-consolidated-proposals.md` using `cp`. Do NOT add discussion markers, headers, or any formatting — copy the file as-is.

14. **Update state file**: Mark Step 2 complete

15. **Automatically proceed to Step 3**

---

### Step 3: Proposal Filter

16. **Update state file**: Set Step 3, status = IN_PROGRESS

17. **Run Proposal Filter** to check level-appropriateness and format for human review:
    ```
    Follow the instructions in: {{AGENTS_PATH}}/04-architecture/expand/proposal-filter.md

    Stage guide: {{GUIDES_PATH}}/04-architecture-guide.md
    Input: system-design/04-architecture/versions/round-[N]-expand/03-consolidated-proposals.md
    Output: system-design/04-architecture/versions/round-[N]-expand/03-expansion-review.md
    ```

18. **Update state file**: Mark Step 3 complete

19. **Zero-proposals gate**: Read `03-expansion-review.md` and count kept proposals.
    - **If zero kept**: All proposals were filtered. Notify human, set status = COMPLETE with history "All proposals filtered — no expansion applied."
    - **If one or more kept**: Automatically proceed to Step 4.

---

### Step 4: Expansion Review

20. **Update state file**: Set Step 4, status = WAITING_FOR_HUMAN

21. **Notify user** proposals are ready for review:
    - Point them to `system-design/04-architecture/versions/round-[N]-expand/03-expansion-review.md`
    - Each proposal includes: new content, modified content, cross-section implications, rationale
    - Full detail available in the explorer files if needed

**STOP: Wait for human response before proceeding.**

Do NOT proceed until the human has added actual response content after `>> HUMAN:` markers.

22. **Discussion markers**:
    - Human responds using `>> HUMAN:` prefix
    - Agent responds using `>> AGENT:` prefix
    - `>> RESOLVED` marks discussion complete (added by orchestrator only)

23. **Discussion loop**:

    a. **Identify proposals needing agent response**: Read file, find proposals where last entry is `>> HUMAN:` without subsequent `>> AGENT:`

    b. **Invoke Discussion Facilitator agents** (batched by capability area):
       ```
       Follow the instructions in: {{AGENTS_PATH}}/universal-agents/discussion-facilitator.md

       Context documents:
       - Architecture: system-design/04-architecture/versions/round-[N]-expand/00-architecture.md
       - PRD: system-design/02-prd/prd.md
       - Foundations: system-design/03-foundations/foundations.md

       Issues file: system-design/04-architecture/versions/round-[N]-expand/03-expansion-review.md
       Issues: [ID1, ID2, ...]
       ```

    c. **Wait for all agents to complete**

    d. **Verify agent responses were written** (MANDATORY):
       - Count `>> AGENT:` markers
       - If counts don't match: re-invoke for missing proposals
       - Repeat until all assigned proposals have responses

    e. **Present to human**: "Please review the agent responses and reply to each proposal."

    f. **Update state file**: Set status = WAITING_FOR_HUMAN

    **STOP: Wait for human response.**

    g. **After human responds**, read file and for each proposal:
       - If response indicates acceptance → add `>> RESOLVED [ACCEPTED]`
       - If response indicates rejection → add `>> RESOLVED [REJECTED]`
       - If response has question, pushback, or modification request → leave open

    h. **If any proposals unresolved**: Go to step (a)

    i. **If all proposals resolved**: Proceed to Step 4→5 Gate

24. **Resolution indicators** (human response after `>> AGENT:` that signals done):
    - Acceptance: "Yes", "Agreed", "That works", "Fine", "OK", "Happy with that"
    - Rejection: "No", "Remove", "Don't include", "Skip", "Reject"
    - Modification: "Yes but change...", "Accept with modification..."

25. **Continue discussion indicators** (do NOT mark resolved):
    - Questions: "?", "What about", "How would", "Can you"
    - Requests: "Please", "Can you", "I'd like", "Show me"
    - Pushback: "I disagree", "That's not right", "But what about"

### Step 4→5 Gate

**Before invoking Integration Author:**
1. Read `03-expansion-review.md`
2. Verify EVERY proposal has `>> RESOLVED` marker (either `[ACCEPTED]` or `[REJECTED]`)
3. If any proposal lacks `>> RESOLVED`: Do NOT proceed. Continue discussion loop.
4. If ALL proposals are `[REJECTED]`: Set status = COMPLETE with history "All proposals rejected — no expansion applied."
5. Only proceed to Step 5 when at least one proposal is `[ACCEPTED]`

This gate is mandatory. Do not skip it.

---

### Step 5: Integration

26. **Update state file**: Set Step 5, status = IN_PROGRESS

27. **Run Integration Author**:
    ```
    Follow the instructions in: {{AGENTS_PATH}}/04-architecture/expand/integration-author.md

    Architecture: system-design/04-architecture/versions/round-[N]-expand/00-architecture.md
    Approved proposals: system-design/04-architecture/versions/round-[N]-expand/03-expansion-review.md
    Stage guide: {{GUIDES_PATH}}/04-architecture-guide.md
    Change log output: system-design/04-architecture/versions/round-[N]-expand/04-integration-output.md
    Updated Architecture output: system-design/04-architecture/versions/round-[N]-expand/05-updated-architecture.md
    ```

28. **Update state file**: Mark Step 5 complete

29. **Automatically proceed to Steps 6-9**

---

### Steps 6-9: Verification (Parallel)

**IMPORTANT**: Run Steps 6, 7, 8, and 9 in parallel — they have no dependencies on each other. Aggregate all results, then present to human at Step 10.

30. **Update state file**: Set Steps 6-9, status = IN_PROGRESS

31. **Spawn all four verification agents in parallel**:

    **Change Verifier** (Step 6):
    ```
    Follow the instructions in: {{AGENTS_PATH}}/04-architecture/review/workflow/change-verifier.md

    Issues summary with resolutions: system-design/04-architecture/versions/round-[N]-expand/03-expansion-review.md
    Author output: system-design/04-architecture/versions/round-[N]-expand/04-integration-output.md
    Updated Architecture: system-design/04-architecture/versions/round-[N]-expand/05-updated-architecture.md
    Output: system-design/04-architecture/versions/round-[N]-expand/06-change-verification.md
    ```

    **Alignment Verifier** (Step 7):
    ```
    Follow the instructions in: {{AGENTS_PATH}}/universal-agents/alignment-verifier.md

    Updated Architecture: system-design/04-architecture/versions/round-[N]-expand/05-updated-architecture.md
    PRD: system-design/02-prd/prd.md
    Foundations: system-design/03-foundations/foundations.md
    Output: system-design/04-architecture/versions/round-[N]-expand/07-alignment-report.md
    ```

    **Internal Coherence Checker** (Step 8):
    ```
    Follow the instructions in: {{AGENTS_PATH}}/universal-agents/internal-coherence-checker.md

    Document: system-design/04-architecture/versions/round-[N]-expand/05-updated-architecture.md
    Stage guide: {{GUIDES_PATH}}/04-architecture-guide.md
    Output: system-design/04-architecture/versions/round-[N]-expand/08-coherence-report.md
    ```

    **Enumeration Verifier** (Step 9):
    ```
    Follow the instructions in: {{AGENTS_PATH}}/universal-agents/enumeration-verifier.md

    Document: system-design/04-architecture/versions/round-[N]-expand/05-updated-architecture.md
    Stage guide: {{GUIDES_PATH}}/04-architecture-guide.md
    Output: system-design/04-architecture/versions/round-[N]-expand/09-enumeration-report.md
    ```

32. **Wait for all four agents to complete**

33. **Update state file**: Mark Steps 6, 7, 8, and 9 complete

34. **Automatically proceed to Step 10**

---

### Step 10: Verification Review

35. **Update state file**: Set Step 10, status = IN_PROGRESS

36. **Read all verification reports** and aggregate findings:
    - `06-change-verification.md` — check for PARTIALLY_APPLIED, NOT_APPLIED
    - `07-alignment-report.md` — check for HALT recommendation, SYNC_UPSTREAM
    - `08-coherence-report.md` — check for HIGH or MEDIUM coherence gaps
    - `09-enumeration-report.md` — check for HIGH or MEDIUM missing items

37. **Write verification summary** to `10-verification-summary.md`:
    ```markdown
    # Verification Summary

    **Round**: [N] (Expand)
    **Date**: [date]

    ## Change Verification

    **Result**: [ALL_APPLIED / NEEDS_ATTENTION]
    - APPLIED: [N]
    - PARTIALLY_APPLIED: [N]
    - NOT_APPLIED: [N]
    - REJECTED (correctly skipped): [N]

    ## Alignment Verification

    **Recommendation**: [PROCEED / HALT]

    ### Pending Issues for Sync (if any)

    | ID | Target | Summary | Certainty | Classification |
    |----|--------|---------|-----------|----------------|

    ## Internal Coherence

    **Status**: [COHERENT / GAPS_FOUND]
    - HIGH: [N]
    - MEDIUM: [N]
    - LOW: [N]

    ## Enumeration Completeness

    **Status**: [COMPLETE / GAPS_FOUND]
    - HIGH: [N]
    - MEDIUM: [N]
    - LOW: [N]

    ## Overall Status

    **[CLEAN / NEEDS_DECISIONS / NEEDS_REWORK]**
    ```

38. **Track rework pass count**: Count how many times Steps 5→6-9→10 have executed. Record in state file history.

39. **Determine next action based on Overall Status**:

    a. **If CLEAN**: Mark Step 10 complete, proceed to Step 11

    b. **If NEEDS_REWORK** (NOT_APPLIED items): Return to Step 5 (Integration Author)

    c. **If NEEDS_DECISIONS**: Present to human (see step 40)

40. **If NEEDS_DECISIONS, present to human** (same format as review orchestrator):

    Include rework context framing if pass 2+:
    ```
    > **Rework pass [N]**: Verification after rework pass [N]. Diminishing returns expected.
    ```

    Present relevant sections (change issues, alignment issues, coherence gaps, enumeration gaps) with FIX/ACCEPT options per item.

**STOP: Wait for human response before proceeding.**

41. **Collect decisions from human response**

42. **If FIX requested**: Return to Step 5 with specific feedback

43. **Update state file**: Mark Step 10 complete, proceed to Step 11

---

### Step 11: Route

44. **Update state file**: Set Step 11, status = IN_PROGRESS

45. **Handle pending issue sync** (if alignment verification found SYNC_UPSTREAM items):
    - Same pending issue resolver pattern as review workflow
    - Sync to Foundations at `system-design/03-foundations/versions/pending-issues.md` and/or PRD at `system-design/02-prd/versions/pending-issues.md` if applicable

46. **Update state file**: Mark Step 11 complete

47. **Notify human**: Expand round complete.
    ```
    Expand round [N] complete.

    Next steps:
    - Run a Review round to verify the expanded document with expert reviewers
    - Run another Expand round if additional capability areas need expansion

    The expand workflow does not promote. A Review round should follow to validate
    the expansion before promotion.
    ```

48. **Update state file**: Set status = COMPLETE

---

## Stopping Points

**Automatic flow (do NOT pause for human confirmation):**
- Steps 2 → 3: Explore and scope filter proceed automatically
- Steps 5 → 6+7+8+9 (parallel) → 10: Integration through verification without pausing
- Step 10 → 11: Execute after human decisions collected (if needed)

**Human checkpoints (orchestrator handles these directly):**
- **Step 1** — WAITING_FOR_HUMAN for Expansion Brief review
- **Step 4** — WAITING_FOR_HUMAN for proposal review and discussion
- **Step 10** (if NEEDS_DECISIONS) — Present verification results, collect decisions

Do NOT ask "Should I proceed?" between automatic steps. Only stop at the human checkpoints listed above.

---

## Exit Criteria

The expand workflow completes when:
1. All accepted proposals have been integrated and verified, OR
2. All proposals were rejected or filtered (no changes applied), OR
3. The human cancels the expansion at Step 1

The expand workflow does NOT promote. After completion, the human should run a Review round to validate the expansion with expert reviewers.

---

<!-- INJECT: tool-restrictions -->
