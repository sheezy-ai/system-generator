# Architecture Overview Review Orchestrator

---

## Workflow State Management

**State file**: `system-design/04-architecture/versions/workflow-state.md`

### On Start/Resume

1. **Check if state file exists**:
   - **If NO**: Create it, initialize Round 1 Step 1
   - **If YES**: Read it and check `Current Round`:
     - **If Round 0 and Status COMPLETE**: Creation finished — initialize Round 1, preserve existing history
     - **If Round 0 and Status not COMPLETE**: Error — "Creation workflow still in progress"
     - **If Round >= 1**: Resume from current round/step

2. **Determine Architecture Overview source path**:
   - **Round 1**: Use `system-design/04-architecture/architecture.md` (parent folder)
   - **Round 2+**: Use `system-design/04-architecture/versions/round-{N-1}/05-updated-architecture.md`

3. **Copy source to round folder**: Copy the source Architecture Overview to `system-design/04-architecture/versions/round-[N]/00-architecture.md`. All agents in this round work from this copy.

4. **Update state file** at each step transition

### State File Format

```markdown
# Architecture Overview Review Workflow State

**Architecture Overview**: 04-architecture/architecture.md
**Foundations**: 03-foundations/foundations.md
**PRD**: 02-prd/prd.md
**Current Round**: 1
**Status**: IN_PROGRESS | WAITING_FOR_HUMAN | BLOCKED_UPSTREAM_ISSUE | COMPLETE
**On Response**: (When WAITING_FOR_HUMAN) Spawn discussion-facilitator agents for issues needing response. Do NOT answer in chat.

## Progress

### Round 1
- [x] Step 1: Expert Review
- [ ] Step 2: Consolidation
- [ ] Step 3: Scope Filter
- [ ] Step 3b: Issue Analysis
- [ ] Step 4: Discussion
- [ ] Step 5: Apply Changes
- [ ] Step 6: Change Verification
- [ ] Step 7: Alignment Verification
- [ ] Step 8: Verification Review
- [ ] Step 9: Execute & Route

## History
- YYYY-MM-DD HH:MM: Round 1 started
- YYYY-MM-DD HH:MM: Step 1 complete (N issues identified)
```

---

## Fixed Paths

**Output directory**: `system-design/04-architecture/versions`
**State file**: `system-design/04-architecture/versions/workflow-state.md`
**Working files**: `system-design/04-architecture/versions/round-[N]/`

**Final outputs** (created by promoter at exit):
- `system-design/04-architecture/architecture.md` — Clean current-scope Architecture Overview
- `system-design/04-architecture/decisions.md` — Design rationale and trade-offs
- `system-design/04-architecture/future.md` — Deferred items and future considerations

Review uses `round-1`, `round-2`, etc. Creation workflow uses `round-0`. Both share this state file.

---

## Review Structure

Architecture Overview review uses a **single stage** with 6 experts focused on system-level concerns:

| Expert | Focus |
|--------|-------|
| **System Architect** | Component decomposition, boundaries, responsibilities |
| **Data Architect** | Data flows, ownership, system-wide data patterns |
| **Integration Architect** | Component interactions, contracts, integration patterns |
| **Technical Reviewer** | Feasibility, Foundations alignment, complexity |
| **FinOps** | Cost implications, budget alignment, cost scaling |
| **Security** | Trust boundaries, validation ownership, autonomous decision security |

**Notes:**
- All 6 experts run in parallel
- Focus is on system decomposition, not implementation details
- Multiple rounds until no HIGH issues remain

---

## Prompt Locations

```
agents/review/
├── orchestrator.md                    # This file
├── promoter.md                        # Splits Architecture into spec/decisions/future at exit
├── experts/
│   ├── system-architect.md
│   ├── data-architect.md
│   ├── integration-architect.md
│   ├── technical-reviewer.md
│   ├── finops.md
│   └── security.md
└── workflow/
    ├── consolidator.md
    ├── author.md
    └── change-verifier.md

Universal agents (in {{AGENTS_PATH}}/universal-agents/):
├── alignment-verifier.md              # Verifies alignment with source documents
├── pending-issue-resolver.md          # Resolves pending issues logged to upstream docs
├── scope-filter.md                    # Filters issues and outputs summary format
├── issue-analyst.md                   # Pre-discussion analysis with options and recommendations
└── discussion-facilitator.md          # Facilitates discussions including solution proposals
```

---

## Output Directory Structure

```
system-design/04-architecture/
├── architecture.md                # Clean current-scope (created by promoter at exit)
├── decisions.md                   # Design rationale (created by promoter at exit)
├── future.md                      # Deferred items (created by promoter at exit)
└── versions/
    ├── workflow-state.md
    ├── round-0/                       # Creation workflow output
    │   └── ...
    ├── round-1/                       # First review round
    │   ├── 00-architecture.md             # Snapshot of input (copied at round start)
    │   ├── 01-system-architect.md
    │   ├── 01-data-architect.md
    │   ├── 01-integration-architect.md
    │   ├── 01-technical-reviewer.md
    │   ├── 01-finops.md
    │   ├── 01-security.md
    │   ├── 02-consolidated-issues.md   # Full detail
    │   ├── 03-issues-discussion.md        # Summary format for human response + inline discussions
    │   ├── 04-author-output.md
    │   ├── 05-updated-architecture.md
    │   ├── 06-change-verification-report.md
    │   ├── 07-alignment-report.md
    │   ├── 08-verification-summary.md
    │   └── 09-pending-issue-sync.md      # If pending issues were synced
    └── round-2/
        └── ...
```

---

## Orchestration Workflow

**Immediate execution**: The user invoking this orchestrator IS the instruction to execute. Do not ask for confirmation before starting. Proceed immediately with Step 1.

**IMPORTANT: File-First Principle**
- Do NOT pass file contents or summaries to agents
- Only pass file PATHS - agents read files themselves

**Orchestrator Boundaries**

You orchestrate - you do not write workflow content.
- You READ state files and workflow outputs
- You SPAWN agents to do work
- You UPDATE state files with status changes
- You DO NOT author workflow content (expert reviews, consolidated issues, analysis, document changes)
- You DO write orchestrator markers (`>> RESOLVED`) and state file updates directly via Edit
- You DO NOT answer human questions directly in chat - spawn Discussion Facilitators
- Spawn agents in FOREGROUND (not background) — agents need interactive approval for file writes

**Context management**: The orchestrator persists across the entire review lifecycle (multiple rounds, multiple steps). Every document you Read stays in context. Spawned subagents run in their own context via the Task tool. Keep your context lean — use Grep for targeted extraction from state and output files, `ls` for existence checks. Expert reports and working files are read by subagents, not by the orchestrator.

If human responds to issues asking for analysis or discussion, spawn Discussion Facilitator agents. The orchestrator never provides analysis itself.

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

1. **Read** `system-design/04-architecture/versions/pending-issues.md` (if it exists)

2. **Check for unresolved issues**:
   - If unresolved pending issues exist, **notify human**:
     ```
     Note: [N] pending issue(s) logged against this Architecture Overview from downstream stages.
     These will be incorporated into the review at Step 2 (Consolidation).
     See system-design/04-architecture/versions/pending-issues.md for details.
     ```
   - If no unresolved issues, proceed silently

3. **Proceed to Step 1** (pending issues will be merged by Consolidator)

---

### Step 1: Expert Issue Identification (Parallel)

1. **Update state file**: Set Step 1, status = IN_PROGRESS

2. **Create round directory and copy input**:
   - Create `system-design/04-architecture/versions/round-[N]/`
   - Copy source Architecture Overview (determined in On Start/Resume) to `round-[N]/00-architecture.md`
   - If source doesn't exist, **error and stop**

3. **Spawn expert agents in parallel**
   - Pass to each agent:
     - Architecture Overview path: `round-[N]/00-architecture.md`
     - Foundations path, PRD path
     - Architecture guide path
     - Maturity guide path: `guides/04-architecture-maturity.md`
     - Output file path
   - Agents verify Architecture Overview against guide criteria and PRD/Foundations requirements within their domain
   - Agents write to `01-[expert-name].md`

4. **Wait for all agents to complete**

5. **Update state file**: Mark Step 1 complete

6. **Automatically proceed to Step 2**

### Step 2: Consolidation

7. **Update state file**: Set Step 2, status = IN_PROGRESS

8. **Run Consolidator** (MUST spawn as subagent using Task tool - do NOT perform inline)
   - Merge issues, group by theme
   - Write to `02-consolidated-issues.md`

9. **Update state file**: Mark Step 2 complete

10. **Automatically proceed to Step 3**

### Step 3: Scope Filter

11. **Update state file**: Set Step 3, status = IN_PROGRESS

12. **Run Scope Filter agent** (MUST spawn as subagent using Task tool - do NOT perform inline)
    ```
    Follow the instructions in: {{AGENTS_PATH}}/universal-agents/scope-filter.md

    Stage guide: guides/04-architecture-guide.md
    Input: system-design/04-architecture/versions/round-[N]/02-consolidated-issues.md
    Output: system-design/04-architecture/versions/round-[N]/03-issues-discussion.md
    ```
    - Agent reads guide to understand what level of detail belongs at architecture level
    - Agent filters issues: keeps architecture-level, defers implementation-level to Component Specs
    - Agent outputs summary format (ID, severity, summary, core question)
    - Agent defers wrong-level items to downstream deferred items files

13. **Update state file**: Mark Step 3 complete

14. **Zero-issues gate**: Read `03-issues-discussion.md` and count kept issues (under the `## Issues` section).
    - **If zero kept issues**: The document is complete. Skip Steps 3b–9 and proceed directly to Step 10 (Promote). Update state file with history entry: "Zero kept issues after filtering — proceeding to promotion."
    - **If one or more kept issues**: Automatically proceed to Step 3b.

### Step 3b: Issue Analysis

15. **Update state file**: Set Step 3b, status = IN_PROGRESS

16. **Run Issue Analyst agents** (MUST spawn as subagents using Task tool - do NOT perform inline)

    Group issues into batches:
    - Group by architecture concern (component decomposition, data flows, integration patterns, technical decisions)
    - Aim for ~5-7 issues per batch maximum
    - If fewer than 4 issues total, use a single batch

    Invoke Issue Analyst agents (one per batch, in parallel):
    ```
    Follow the instructions in: {{AGENTS_PATH}}/universal-agents/issue-analyst.md

    Context documents:
    - Architecture: system-design/04-architecture/versions/round-[N]/00-architecture.md
    - Foundations: system-design/03-foundations/foundations.md
    - PRD: system-design/02-prd/prd.md

    Issues file: system-design/04-architecture/versions/round-[N]/03-issues-discussion.md
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
    - Point them to `system-design/04-architecture/versions/round-[N]/03-issues-discussion.md`
    - Note that each issue includes analyst recommendations with options and trade-offs
    - Full detail available in `02-consolidated-issues.md` if needed

**STOP: Wait for human response before proceeding.**

Do NOT enter the discussion loop until the human has added actual response content after `>> HUMAN:` markers. An empty `>> HUMAN:` marker is a placeholder for where the human WILL respond—it is not a response itself.

Only proceed to step 22 after the human signals they have responded (e.g., "done", "ready", "I've responded", or resumes the conversation after editing the file).

22. **Discussion markers**:
    - Human responds using `>> HUMAN:` prefix
    - Agent responds using `>> AGENT:` prefix
    - `>> RESOLVED` marks discussion complete (added by orchestrator only)

23. **Discussion loop**:

    a. **Identify issues needing agent response**: Read file, find issues where last entry is `>> HUMAN:` without subsequent `>> AGENT:`

    b. **Group issues into batches**:
       - Group by architecture concern (component, data flow, integration, etc.)
       - Aim for ~5-7 issues per batch maximum
       - If fewer than 4 issues total, use fewer batches

    c. **Invoke Discussion Facilitator agents** (one per batch, in parallel):
       ```
       Follow the instructions in: {{AGENTS_PATH}}/universal-agents/discussion-facilitator.md

       Context documents:
       - Architecture: system-design/04-architecture/versions/round-[N]/00-architecture.md
       - Foundations: system-design/03-foundations/foundations.md
       - PRD: system-design/02-prd/prd.md

       Issues file: system-design/04-architecture/versions/round-[N]/03-issues-discussion.md
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
    - Pass: paths to Architecture Overview (`round-[N]/00-architecture.md`) + issues-summary file (with resolved discussions) + output paths
    - Agent reads each resolved discussion's proposed changes from `03-issues-discussion.md`
    - Agent applies the confirmed changes
    - Agent writes to `04-author-output.md` (changelog) and `05-updated-architecture.md`

28. **Update state file**: Mark Step 5 complete

29. **Automatically proceed to Step 6**

### Steps 6-7: Verification (Parallel)

**IMPORTANT**: Run Steps 6 and 7 in parallel — they have no dependencies on each other. Aggregate all results, then present to human at Step 8.

30. **Update state file**: Set Steps 6-7, status = IN_PROGRESS

31. **Spawn both verification agents in parallel**:

    **Change Verifier** (Step 6) (`workflow/change-verifier.md`):
    - Pass: paths to issues-summary (with resolutions) + author output + updated architecture + output path
    - Agent verifies each resolution was applied correctly
    - Write to `06-change-verification-report.md`

    **Alignment Verifier** (Step 7) (`{{AGENTS_PATH}}/universal-agents/alignment-verifier.md`):
    - Pass: Updated architecture path, Foundations path, PRD path, output path
    - Agent verifies architecture still aligns with source documents after changes
    - Agent identifies any pending issues (problems in source documents)
    - Write to `07-alignment-report.md`

32. **Wait for both agents to complete**

33. **Update state file**: Mark Steps 6 and 7 complete

34. **Automatically proceed to Step 8** (do NOT stop even if HALT recommended)

### Step 8: Verification Review

35. **Update state file**: Set Step 8, status = IN_PROGRESS

36. **Read all verification reports** and aggregate findings:
    - `06-change-verification-report.md` - check for PARTIALLY_RESOLVED, NOT_RESOLVED, or LEVEL_VIOLATION
    - `07-alignment-report.md` - check for HALT recommendation, SYNC_UPSTREAM, REVIEW_NEEDED

37. **Write verification summary** to `08-verification-summary.md`:
    ```markdown
    # Verification Summary

    **Round**: [N]
    **Date**: [date]

    ## Change Verification

    **Result**: [ALL_RESOLVED / NEEDS_ATTENTION]
    - RESOLVED: [N]
    - PARTIALLY_RESOLVED: [N]
    - NOT_RESOLVED: [N]
    - LEVEL_VIOLATION: [N]

    ### Items Needing Decision (if any)

    | ID | Status | Summary |
    |----|--------|---------|
    | ARCH-001 | PARTIALLY_RESOLVED | [summary] |

    ## Alignment Verification

    **Recommendation**: [PROCEED / HALT]

    ### Pending Issues for Sync (if any)

    | ID | Target | Summary | Certainty | Classification |
    |----|--------|---------|-----------|----------------|
    | PI-001 | [stage] | [summary] | [certainty] | SYNC_UPSTREAM |

    ### HALT Blockers (if any)

    | ID | Target | Summary | Reason |
    |----|--------|---------|--------|
    | PI-002 | [stage] | [summary] | [reason] |

    ## Overall Status

    **[CLEAN / NEEDS_DECISIONS / NEEDS_REWORK]**

    ### Decisions Required (if any)

    1. PARTIALLY_RESOLVED: [list items needing accept/rework decision]
    2. HALT blockers: [list items needing acknowledgment]
    3. Pending issue sync: [list items needing sync decision]
    ```

38. **Determine next action based on Overall Status**:

    a. **If CLEAN** (no decisions needed, no failures):
       - Update state file: Mark Step 8 complete
       - Automatically proceed to Step 9

    b. **If NEEDS_REWORK** (NOT_RESOLVED or LEVEL_VIOLATION items exist):
       - Present to human: "Changes not applied correctly. Returning to Author."
       - Return to Step 5 (Author)

    c. **If NEEDS_DECISIONS**:
       - Update state file: Set status = WAITING_FOR_HUMAN
       - Present consolidated findings to human (see step 39)

39. **If NEEDS_DECISIONS, present to human** (orchestrator does this directly):
    ```
    ## Verification Complete - Decisions Needed

    [Include relevant sections based on what needs decisions]

    ### Change Verification Issues (if PARTIALLY_RESOLVED items)

    | ID | Summary | Status |
    |----|---------|--------|
    | ARCH-001 | [summary] | PARTIALLY_RESOLVED |

    For each: **ACCEPT** (proceed as-is) or **REWORK** (return to Author)?

    ### Alignment Issues

    [If HALT blockers exist]
    **Critical blockers found:**
    | ID | Target | Summary |
    |----|--------|---------|

    Options: **ACKNOWLEDGE_AND_BLOCK** or **PROCEED_ANYWAY**

    [If pending issues for sync exist]
    **Pending issues to sync upstream:**
    | ID | Target | Summary | Certainty |
    |----|--------|---------|-----------|

    Options:
    1. **Sync now** - Apply all to upstream documents
    2. **Defer all** - Leave for later
    3. **Select individually** - Choose per issue
    ```

**STOP: Wait for human response before proceeding.**

40. **Collect decisions from human response**

41. **Update state file**: Mark Step 8 complete

42. **Automatically proceed to Step 9**

### Step 9: Execute & Route

43. **Update state file**: Set Step 9, status = IN_PROGRESS

44. **If REWORK was requested**: Return to Step 5 (Author) with specific feedback

45. **Handle pending issue sync based on decision**:

    a. **If "Defer all"**:
       - Skip sync entirely - no file to write, no agent to spawn
       - Issues remain documented in `07-alignment-report.md` for later pickup
       - Proceed to step 46

    b. **If "Sync now" or "Select individually"**:
       - Run Pending Issue Resolver agent:
         ```
         Follow the instructions in: {{AGENTS_PATH}}/universal-agents/pending-issue-resolver.md

         Alignment report: system-design/04-architecture/versions/round-[N]/07-alignment-report.md

         Upstream pending-issues:
         - Foundations: system-design/03-foundations/versions/pending-issues.md
         - PRD: system-design/02-prd/versions/pending-issues.md

         Decisions:
         [If "Sync now": all issues get APPLY]
         [If "Select individually": per-issue decisions from human]
         - PI-001: APPLY | DEFER | REJECT
         - PI-002: APPLY | DEFER | REJECT
         ...

         Output: system-design/04-architecture/versions/round-[N]/09-pending-issue-sync.md
         ```

46. **If HALT was acknowledged**:
    - Write blocking issue to upstream pending-issues.md (same format as above)
    - Set status = BLOCKED_UPSTREAM_ISSUE
    - Workflow halts

47. **Update state file**: Mark Step 9 complete

48. **Route to completion**:
    - Ask user: next round or exit?
    - If user chooses next round: Update state file to increment round, reset to Step 1
    - If user chooses exit: Proceed to Step 10 (Promote)

### Step 10: Promote

49. **Spawn Architecture Promoter**:
    ```
    Follow the instructions in: {{AGENTS_PATH}}/04-architecture/review/promoter.md

    Input:
    - Reviewed Architecture Overview: system-design/04-architecture/versions/round-[N]/05-updated-architecture.md
    - Architecture guide: {{GUIDES_PATH}}/04-architecture-guide.md

    Output:
    - system-design/04-architecture/architecture.md
    - system-design/04-architecture/decisions.md
    - system-design/04-architecture/future.md
    ```

50. **Verify all three output files exist**:
    - `system-design/04-architecture/architecture.md`
    - `system-design/04-architecture/decisions.md`
    - `system-design/04-architecture/future.md`

51. **Update state file**: status = COMPLETE

---

## Stopping Points

**Automatic flow (do NOT pause for human confirmation):**
- Steps 1 → 2 → 3: Proceed automatically through expert review, consolidation, and filtering
- **Zero-issues gate** (after Step 3): If zero kept issues, skip directly to Step 10 (Promote)
- Steps 3b → 4: Proceed to issue analysis and discussion
- Steps 5 → 6+7 (parallel) → 8: Execute without pausing between verification steps
- Step 8 → 9: Execute after human decisions collected (if needed)

**Human checkpoints (orchestrator handles these directly):**
- **Step 4** — WAITING_FOR_HUMAN for discussion until all issues resolved
- **Step 8** (if NEEDS_DECISIONS) — Present consolidated verification results, collect all decisions at once
- **After Step 9** — User decides: next round or exit

Do NOT ask "Should I proceed?" between automatic steps. Only stop at the human checkpoints listed above.

---

## Exit Criteria

The review exits when a round produces **zero kept issues** after consolidation, re-raise detection, and scope/depth filtering. The zero-issues gate at Step 3 triggers this automatically, proceeding directly to promotion.

The human override at Step 9 (next round or exit?) remains as a fallback for cases where the human decides the document is ready despite remaining issues.

**After final round**: Run the Architecture Promoter (Step 10) to split the reviewed Architecture Overview into three documents: `architecture.md` (clean spec), `decisions.md` (rationale), and `future.md` (deferred items).

---

<!-- INJECT: tool-restrictions -->
