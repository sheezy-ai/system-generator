# Architecture Overview Review Orchestrator

---

## Workflow State Management

**State file**: `system-design/04-architecture/versions/workflow-state.md`

### On Start/Resume

1. **Check if state file exists**:
   - **If NO**: Create it, initialize Round 1 Step 1, set `Current Workflow: Review`
   - **If YES**: Read the state file. The action depends on `Status` and `Current Workflow`:
     - **`Status: COMPLETE`** (regardless of `Current Workflow`): Set `Current Workflow: Review`, initialize the next sequential round number (globally numbered — see unified `versions/` folder convention), preserve history.
     - **`Status: not COMPLETE`** and **`Current Workflow: Review`**: Resume from current round/step.
     - **`Status: not COMPLETE`** and **`Current Workflow`** is anything else: Error — `Cannot start Review: {Current Workflow} workflow still in progress`.

2. **Determine Architecture Overview source path**:
   - Read the state file history to identify the last completed round number and type
   - **If no previous rounds exist** (first ever round): Use the upstream input documents: `system-design/02-prd/prd.md` and `system-design/03-foundations/foundations.md`
   - **If previous rounds exist**: Use the full updated document from the last completed round:
     - Last round was create: `versions/round-{N}-create/03-updated-architecture.md` (or `versions/round-{N}-create/00-draft-architecture.md` if only draft exists)
     - Last round was review: `versions/round-{N}-review/05-updated-architecture.md` **ELSE** `versions/round-{N}-review/00-architecture.md` (the zero-issues path skips the Author, so `05-updated-architecture.md` may not exist)
     - Last round was expand: `versions/round-{N}-expand/05-updated-architecture.md`
     - Last round was promote: `versions/round-{N}-promote/00-architecture.md` (the input snapshot the promote round froze — the pre-split full document)
   - **Never use the promoted file** (`architecture.md` in the parent folder) as input — it may have been split by the Promote stage, losing rationale and future content

3. **Copy source to round folder**: Copy the source Architecture Overview to `system-design/04-architecture/versions/round-[N]-review/00-architecture.md`. All agents in this round work from this copy.

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
- [ ] Step 8: Internal Coherence
- [ ] Step 9: Enumeration Verification
- [ ] Step 10: Verification Review
- [ ] Step 11: Execute & Route

## Upstream Freshness (reconciled-against)

The upstream `Frozen-At` this stage last reconciled against, **one line per direct alignment-source edge** (Architecture's direct sources are the PRD and Foundations — `alignment-verifier.md` source table). Written at Review completion (Step 12) from the AV-read tokens; read by the Promote guard's freshness clause (Step 1b). Absent until the first Review round whose Alignment Verifier ran (the zero-issues fast-path advances no edge — it runs no AV).

- 02-prd:          round-[N]-promote
- 03-foundations:  round-[N]-promote

## History
- YYYY-MM-DD HH:MM: Round 1 started
- YYYY-MM-DD HH:MM: Step 1 complete (N issues identified)
```

---

## Fixed Paths

**Output directory**: `system-design/04-architecture/versions`
**State file**: `system-design/04-architecture/versions/workflow-state.md`
**Working files**: `system-design/04-architecture/versions/round-[N]-review/`

**Final outputs** (created by the **Promote stage's** promoter, after review hands off — review no longer produces these):
- `system-design/04-architecture/architecture.md` — Clean current-scope Architecture Overview
- `system-design/04-architecture/decisions.md` — Design rationale and trade-offs
- `system-design/04-architecture/future.md` — Deferred items and future considerations

Review outputs go under `versions/round-1-review/`, `versions/round-2-review/`, etc. Creation outputs go under `versions/round-{N}-create/`. Both workflows share the `versions/` folder with a unified state file.

---

## Review Structure

Architecture Overview review uses a **single stage** with 8 experts focused on system-level concerns:

| Expert | Focus |
|--------|-------|
| **System Architect** | Component decomposition, boundaries, responsibilities |
| **Data Architect** | Data flows, ownership, system-wide data patterns |
| **Integration Architect** | Component interactions, contracts, integration patterns |
| **Technical Reviewer** | Feasibility, Foundations alignment, complexity |
| **FinOps** | Cost implications, budget alignment, cost scaling |
| **Security** | Trust boundaries, validation ownership, autonomous decision security |
| **Contract Completeness** | Every implied cross-component data read is a registered §8 contract |
| **Contract Freezability** | Every §8 contract is freezable — pinned by §7/§8 (+ PRD §5), or a resolvable delegation |

**Notes:**
- All 8 experts run in parallel
- Focus is on system decomposition, not implementation details
- Multiple rounds until a round is **mature** — no HIGH or MEDIUM issues surfaced (LOW carried, not chased); see Exit Criteria

---

## Prompt Locations

```
agents/review/
├── orchestrator.md                    # This file
├── consolidator.md                    # Step 2: merges expert issues by theme
├── author.md                          # Step 5: applies resolved changes
├── change-verifier.md                 # Step 6: verifies each resolution applied
└── experts/
    ├── system-architect.md
    ├── data-architect.md
    ├── integration-architect.md
    ├── technical-reviewer.md
    ├── finops.md
    ├── security.md
    ├── contract-completeness.md
    └── contract-freezability.md

Universal agents (in {{AGENTS_PATH}}/universal-agents/):
├── alignment-verifier.md              # Verifies alignment with source documents
├── internal-coherence-checker.md      # Verifies cross-section consistency within document
├── pending-issue-resolver.md          # Resolves pending issues logged to upstream docs
├── scope-filter.md                    # Filters issues and outputs summary format
├── issue-analyst.md                   # Pre-discussion analysis with options and recommendations
└── discussion-facilitator.md          # Facilitates discussions including solution proposals
```

---

## Output Directory Structure

```
system-design/04-architecture/
├── architecture.md                # Clean current-scope (created by the Promote stage, after review)
├── decisions.md                   # Design rationale (created by the Promote stage)
├── future.md                      # Deferred items (created by the Promote stage)
└── versions/
    ├── workflow-state.md
    ├── round-{N}-create/              # Creation workflow output
    │   └── ...
    ├── round-1-review/                # First review round
    │   ├── 00-architecture.md             # Snapshot of input (copied at round start)
    │   ├── 01-system-architect.md
    │   ├── 01-data-architect.md
    │   ├── 01-integration-architect.md
    │   ├── 01-technical-reviewer.md
    │   ├── 01-finops.md
    │   ├── 01-security.md
    │   ├── 01-contract-completeness.md
    │   ├── 01-contract-freezability.md
    │   ├── 02-consolidated-issues.md   # Full detail
    │   ├── 03-issues-discussion.md        # Summary format for human response + inline discussions
    │   ├── 04-author-output.md
    │   ├── 05-updated-architecture.md
    │   ├── 06-change-verification-report.md
    │   ├── 07-alignment-report.md
    │   ├── 08-coherence-report.md
    │   ├── 09-verification-summary.md
    │   └── 10-pending-issue-sync.md      # If pending issues were synced
    ├── round-2-review/
    │   └── ...
    ├── round-{N}-promote/             # Promote stage: gate reports + freeze record (11-/12- gate reports live here now)
    │   └── ...
    └── pending-issues.md
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
   - Create `system-design/04-architecture/versions/round-[N]-review/`
   - Copy source Architecture Overview (determined in On Start/Resume) to `round-[N]/00-architecture.md`
   - If source doesn't exist, **error and stop**

3. **Spawn expert agents in parallel**
   - Spawn **all 8 experts** from the Review Structure roster (System Architect, Data Architect, Integration Architect, Technical Reviewer, FinOps, Security, **Contract Completeness**, **Contract Freezability**). Each has a prompt in `agents/review/experts/`.
   - Pass to each agent:
     - Architecture Overview path: `round-[N]/00-architecture.md`
     - Foundations path, PRD path
     - Architecture guide path
     - Maturity guide path: `guides/04-architecture-maturity.md`
     - Output file path
   - Agents verify Architecture Overview against guide criteria and PRD/Foundations requirements within their domain
   - Agents write to `01-[expert-name].md` (the Contract Completeness expert writes `01-contract-completeness.md`; the Contract Freezability expert writes `01-contract-freezability.md`), all merged by the Consolidator at Step 2

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
    Input: system-design/04-architecture/versions/round-[N]-review/02-consolidated-issues.md
    Output: system-design/04-architecture/versions/round-[N]-review/03-issues-discussion.md
    ```
    - Agent reads guide to understand what level of detail belongs at architecture level
    - Agent filters issues: keeps architecture-level, defers implementation-level to Component Specs
    - Agent outputs summary format (ID, severity, summary, core question)
    - Agent defers wrong-level items to downstream deferred items files

13. **Update state file**: Mark Step 3 complete

14. **Zero-issues gate**: Read `03-issues-discussion.md` and count kept issues (under the `## Issues` section).
    - **If zero kept issues**: The document is complete. Skip Steps 3b–11 and proceed directly to Step 12 (Mark COMPLETE & Hand to Promote). **The contract completeness & freezability gate still runs — in the Promote stage, on the only road to `architecture.md`** — the zero-issues auto-gate does not bypass it; it just no longer runs inside review. Update state file with history entry: "Zero kept issues after filtering — marking complete and handing to Promote (the gate runs there)."
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
    - Architecture: system-design/04-architecture/versions/round-[N]-review/00-architecture.md
    - Foundations: system-design/03-foundations/foundations.md
    - PRD: system-design/02-prd/prd.md

    Issues file: system-design/04-architecture/versions/round-[N]-review/03-issues-discussion.md
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
    - Point them to `system-design/04-architecture/versions/round-[N]-review/03-issues-discussion.md`
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
       - Architecture: system-design/04-architecture/versions/round-[N]-review/00-architecture.md
       - Foundations: system-design/03-foundations/foundations.md
       - PRD: system-design/02-prd/prd.md

       Issues file: system-design/04-architecture/versions/round-[N]-review/03-issues-discussion.md
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

### Steps 6-8: Verification (Parallel)

**IMPORTANT**: Run Steps 6, 7, 8, and 9 in parallel — they have no dependencies on each other. Aggregate all results, then present to human at Step 10.

30. **Update state file**: Set Steps 6-8, status = IN_PROGRESS

31. **Spawn all four verification agents in parallel**:

    **Change Verifier** (Step 6) (`change-verifier.md`):
    - Pass: paths to issues-summary (with resolutions) + author output + updated architecture + output path
    - Agent verifies each resolution was applied correctly
    - Write to `06-change-verification-report.md`

    **Alignment Verifier** (Step 7) (`{{AGENTS_PATH}}/universal-agents/alignment-verifier.md`):
    - Pass: Updated architecture path, Foundations path, PRD path, output path
    - Agent verifies architecture still aligns with source documents after changes
    - Agent identifies any pending issues (problems in source documents)
    - Write to `07-alignment-report.md`

    **Internal Coherence Checker** (Step 8) (`{{AGENTS_PATH}}/universal-agents/internal-coherence-checker.md`):
    - Pass: Updated architecture path, stage guide path, output path
    - Agent verifies cross-section consistency within the Architecture Overview
    - Write to `08-coherence-report.md`
    ```
    Follow the instructions in: {{AGENTS_PATH}}/universal-agents/internal-coherence-checker.md

    Document: system-design/04-architecture/versions/round-[N]-review/05-updated-architecture.md
    Stage guide: guides/04-architecture-guide.md
    Output: system-design/04-architecture/versions/round-[N]-review/08-coherence-report.md
    ```

    **Enumeration Verifier** (Step 9) (`{{AGENTS_PATH}}/universal-agents/enumeration-verifier.md`):
    - Pass: Updated architecture path, stage guide path, output path
    - Agent verifies enumeration sections contain explicit items for every source concept
    - Write to `09-enumeration-report.md`
    ```
    Follow the instructions in: {{AGENTS_PATH}}/universal-agents/enumeration-verifier.md

    Document: system-design/04-architecture/versions/round-[N]-review/05-updated-architecture.md
    Stage guide: guides/04-architecture-guide.md
    Output: system-design/04-architecture/versions/round-[N]-review/09-enumeration-report.md
    ```

32. **Wait for all four agents to complete**

33. **Update state file**: Mark Steps 6, 7, 8, and 9 complete

34. **Automatically proceed to Step 10** (do NOT stop even if HALT recommended)

### Step 10: Verification Review

35. **Update state file**: Set Step 10, status = IN_PROGRESS

36. **Read all verification reports** and aggregate findings:
    - `06-change-verification-report.md` - check for PARTIALLY_RESOLVED, NOT_RESOLVED, or LEVEL_VIOLATION
    - `07-alignment-report.md` - check for HALT recommendation, SYNC_UPSTREAM, REVIEW_NEEDED
    - `08-coherence-report.md` - check for HIGH or MEDIUM coherence gaps
    - `09-enumeration-report.md` - check for GAPS_FOUND with HIGH or MEDIUM missing items

37. **Write verification summary** to `09-verification-summary.md`:
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

    ## Internal Coherence

    **Status**: [COHERENT / GAPS_FOUND]
    - HIGH: [N]
    - MEDIUM: [N]
    - LOW: [N]

    ### Coherence Gaps Needing Decision (if any HIGH/MEDIUM)

    | ID | Category | Severity | Source Section | Target Section | Summary |
    |----|----------|----------|---------------|----------------|---------|
    | COH-001 | MISSING_REFLECTION | HIGH | [source] | [target] | [summary] |

    ## Overall Status

    **[CLEAN / NEEDS_DECISIONS / NEEDS_REWORK]**

    ### Decisions Required (if any)

    1. PARTIALLY_RESOLVED: [list items needing accept/rework decision]
    2. HALT blockers: [list items needing acknowledgment]
    3. Pending issue sync: [list items needing sync decision]
    4. Coherence gaps: [list HIGH/MEDIUM items needing decision]
    5. Enumeration gaps: [list HIGH/MEDIUM missing items needing decision]
    ```

38. **Track rework pass count**: Count how many times Steps 5→6-9→10 have executed in this round. The first pass after Step 4 (Discussion) is pass 1. Each FIX decision that returns to Author increments the count. Record the count in the state file history.

39. **Determine next action based on Overall Status**:

    a. **If CLEAN** (no decisions needed, no failures):
       - Update state file: Mark Step 10 complete
       - Automatically proceed to Step 11

    b. **If NEEDS_REWORK** (NOT_RESOLVED or LEVEL_VIOLATION items exist):
       - Present to human: "Changes not applied correctly. Returning to Author."
       - Return to Step 5 (Author)

    c. **If NEEDS_DECISIONS**:
       - Update state file: Set status = WAITING_FOR_HUMAN
       - Present consolidated findings to human (see step 40)

40. **If NEEDS_DECISIONS, present to human** (orchestrator does this directly):
    ```
    ## Verification Complete - Decisions Needed

    [If rework pass 2+, include at top:]
    > **Rework pass [N]**: This is verification after rework pass [N]. [N-1] previous rework(s) resolved [X] issues.
    > Previous pass found [Y] coherence/enumeration gaps; [Z] were fixed, introducing [W] new gaps this pass.
    > Diminishing returns are expected — each fix may surface progressively more peripheral cross-section implications.

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
    (Before listing: cross-check each finding against its target `pending-issues.md` register with the shared matcher — `target-stage + section-anchor + concern-gist`, semantic not string-equality, staleness-gated. A finding matching an existing **WONT_FIX** is shown **inline, tagged** `[RE-RAISE — dismissed Round N: rationale]`, default-drop (never hidden). One matching an existing **UNRESOLVED** is annotated "already logged as PI-NNN, awaiting upstream". If the cited upstream section materially changed since the match, treat as not-matched and show normally. Uncertain ⇒ show.)
    **Pending issues to sync upstream:**
    | ID | Target | Summary | Certainty | Register status |
    |----|--------|---------|-----------|-----------------|

    Options:
    1. **Sync now** - Log all to their target stage's register (`pending-issues.md`), for that stage's next review to action. Does NOT edit any upstream document.
    2. **Defer all** - Do NOT route. Each finding stays only in this round's `07-alignment-report.md` — a working artifact of this review round that no other stage reads — so the target stage will not see it unless it is separately re-raised.
    3. **Select individually** - Choose per issue

    ### Coherence Gaps (if HIGH/MEDIUM items)

    | ID | Category | Source Section | Target Section | Summary |
    |----|----------|---------------|----------------|---------|
    | COH-001 | MISSING_REFLECTION | [source] | [target] | [summary] |

    [If rework pass 2+:]
    > HIGH gaps: **FIX** recommended — these indicate an implementer would miss a requirement.
    > MEDIUM gaps: **ACCEPT** recommended — on rework pass [N], these are likely diminishing-returns cross-section implications. The information exists in the document; the gap is in explicit cross-referencing. FIX only if you judge the gap is build-affecting.

    [If first pass:]
    For each: **FIX** (return to Author to address) or **ACCEPT** (proceed as-is)?

    ### Enumeration Gaps (if HIGH/MEDIUM items)

    | ID | Category | Source Section | Target Section | Summary |
    |----|----------|---------------|----------------|---------|
    | ENUM-001 | MISSING_ITEM | [source] | [target] | [summary] |

    [If rework pass 2+:]
    > HIGH gaps: **FIX** recommended — these indicate an implementer would miss a requirement.
    > MEDIUM gaps: **ACCEPT** recommended — on rework pass [N], these are likely diminishing-returns cross-section implications. The information exists in the document; the gap is in explicit cross-referencing. FIX only if you judge the gap is build-affecting.

    [If first pass:]
    For each: **FIX** (return to Author to address) or **ACCEPT** (proceed as-is)?
    ```

**STOP: Wait for human response before proceeding.**

41. **Collect decisions from human response**

42. **Update state file**: Mark Step 10 complete

43. **Automatically proceed to Step 11**

### Step 11: Execute & Route

44. **Update state file**: Set Step 11, status = IN_PROGRESS

45. **If REWORK or FIX was requested**: Return to Step 5 (Author) with specific feedback

46. **Handle pending issue sync based on decision**:

    a. **If "Defer all"**:
       - Skip sync entirely - no file to write, no agent to spawn
       - The findings are NOT routed anywhere. They remain only in this round's `07-alignment-report.md`, a working artifact of this review round that no downstream or upstream stage reads; the target stage will not encounter them unless they are separately re-raised. Choose Defer only when that dropped outcome is intended.
       - Proceed to step 47

    b. **If "Sync now" or "Select individually"**:
       - Run Pending Issue Resolver agent:
         ```
         Follow the instructions in: {{AGENTS_PATH}}/universal-agents/pending-issue-resolver.md

         Alignment report: system-design/04-architecture/versions/round-[N]-review/07-alignment-report.md

         Upstream pending-issues:
         - Foundations: system-design/03-foundations/versions/pending-issues.md
         - PRD: system-design/02-prd/versions/pending-issues.md

         Decisions:
         [If "Sync now": all issues get LOG]
         [If "Select individually": per-issue decisions from human]
         - PI-001: LOG | DEFER | REJECT
         - PI-002: LOG | DEFER | REJECT
         ...
         (LOG = append to the target register as UNRESOLVED; DEFER = do not route; REJECT = log WONT_FIX with a Concern key. The resolver never edits an upstream document.)

         Output: system-design/04-architecture/versions/round-[N]-review/10-pending-issue-sync.md
         ```

46b. **Close architecture-stage pending-issues for entries resolved this round**:

    This step closes entries in the **current stage's own** pending-issues file (`system-design/04-architecture/versions/pending-issues.md`). It is distinct from step 46's Pending Issue Resolver, which writes to **upstream** pending-issues files (Foundations / PRD).

    Procedure:
    - Read `system-design/04-architecture/versions/pending-issues.md`
    - Read this round's `02-consolidated-issues.md` to identify which Unresolved entries were merged into this round's issue stream by the Consolidator at Step 2 (these will be the entries with their original PI-NNN / SPEC-NNN IDs mapped to ARCH-NNN issue IDs in this round)
    - Read this round's `03-issues-discussion.md` to identify the resolution outcome for each merged entry (APPLIED inline, close-with-no-change, close-as-stale, or close-as-resolved-by-prior-round)
    - For each merged-and-resolved entry:
      - Move it from the `## Unresolved Issues` section to the `## Resolved Issues` section (insert at the top of Resolved, in reverse-chronological order with a new dated subsection header for this round)
      - Add resolution metadata to the entry:
        - `**Status:** RESOLVED`
        - `**Resolved:** [date]`
        - `**Resolution Round:** Architecture Round [N] Review (issue tracked as ARCH-NNN)`
        - `**Resolution:** [one-paragraph note explaining how the round closed the entry — APPLIED edits reference the architecture section/CTR; close-with-no-change references the human-approved recommendation; close-as-resolved-by-prior-round references the earlier round's ARCH-NNN that closed it]`
    - **Also record mainline dismissals (re-raise ledger)**: for each **expert-raised issue this round** (a round-local ARCH-NNN that was **not** already a pending-issue) whose resolution outcome in `03-issues-discussion.md` is **close-with-no-change** or **close-as-stale** (dismissed / won't-fix / working-as-intended — a resolution that leaves **no trace in the architecture text**), **add a new entry** to the `## Resolved Issues` section with:
      - `**Status:** RESOLVED (dismissed — no document change)`
      - `**Resolved:** [date]` · `**Resolution Round:** Architecture Round [N] Review`
      - `**Concern key:** [architecture section / CTR anchor] — [one-line concern summary]` — this is the **stable key the Consolidator matches against to suppress re-raises**; use the document section + concern gist, because round-local ARCH-NNN IDs do not persist across rounds
      - `**Resolution:** [why it was dismissed — the human-approved rationale]`
      APPLIED-inline resolutions do **not** need a ledger entry (the architecture text changed, so a future round sees the fix directly). It is specifically the **no-document-change dismissals** that must be recorded — otherwise the unchanged architecture text invites the identical concern to be re-raised next round, which is the review loop's non-convergence trap.
    - Update the Summary table counts (UNRESOLVED ↓, RESOLVED ↑)
    - **Do not touch entries that were not merged into this round's issue stream** (e.g., Unresolved entries logged after Step 2 but before Step 11) — those carry forward to the next round

    Rationale: this step ensures the architecture-stage pending-issues file reflects the truth of what each round closed. Without it, downstream stages reading this file see stale Unresolved entries that have actually been addressed. The orchestrator separates this from step 46's Pending Issue Resolver because the Resolver's semantic is "log findings to the **upstream** registers (Foundations / PRD)", whereas this step's semantic is "close entries in our **own** pending-issues register".

47. **If HALT was acknowledged**:
    - Write blocking issue to upstream pending-issues.md (same format as above)
    - Set status = BLOCKED_UPSTREAM_ISSUE
    - Workflow halts

48. **Update state file**: Mark Step 11 complete

49. **Route to completion**:
    - **Determine maturity**: from this round's `03-issues-discussion.md`, count the **HIGH and MEDIUM** issues this round surfaced and kept at document level. LOW issues do **not** count toward maturity. This round is **mature** if it surfaced **no HIGH or MEDIUM** issues — the convergence criterion: exit on "no HIGH/MEDIUM", **not** "zero issues" (aligning the human routing with the zero-issues auto-gate's intent and the create-stage exit).
    - **Present the routing choice to the user with the maturity signal**: state `Round [N] — maturity: [mature | not mature]; this round surfaced [N] HIGH, [M] MEDIUM ([K] LOW carried)`. If **mature**, tell the user the document has stabilised and **EXIT (promote) is the default** — remaining LOW items are carried, not chased, and another round is warranted only if they expect genuinely new HIGH/MEDIUM concerns. Then ask: **next round or exit?**
    - If user chooses next round: Update state file to increment round, reset to Step 1
    - If user chooses exit: Proceed to Step 12 (Mark COMPLETE & Hand to Promote)

### Step 12: Mark COMPLETE & Hand to Promote

**Review no longer runs the gate or the promoter — they moved to the Promote stage.** This step ends the review round and hands off. The gate is **not gone**: it runs in Promote, which is the sole producer of `architecture.md` — so the contract completeness & freezability gate still sits on the only road to a promoted Architecture Overview, just one stage later. A maturity-override at Step 11, or the zero-issues auto-gate, still cannot reach `architecture.md` without passing (or disposing) that gate in Promote.

50. **Determine the handoff input document** (the reviewed doc Promote will freeze):
    - `05-updated-architecture.md` if it exists (the Author ran this round), otherwise `00-architecture.md` (the zero-issues path where no Author ran).

50b. **Record upstream freshness (the reconciled-against watermark — TOCTOU-safe).** If this round ran the Alignment Verifier (Step 7 — i.e. **not** the zero-issues path), advance the per-edge freshness record to **the `Frozen-At` the AV actually read**:
    - Read this round's `07-alignment-report.md` `## Frozen-At Read (per source)` block; extract the token the AV read for the **02-prd** and **03-foundations** sources.
    - Write/update the `## Upstream Freshness (reconciled-against)` block in `system-design/04-architecture/versions/workflow-state.md`: set `- 02-prd: [AV-read token]` and `- 03-foundations: [AV-read token]`. These say "reconciled against *these* PRD/Foundations versions" — the versions the AV compared, not their current-at-completion values.
    - Record `ABSENT` for any source the AV read as `ABSENT` (a pre-adoption artifact carrying no `**Frozen-At**`); the Promote guard treats an absent-source token as inert (a no-op), not stale.
    - **Zero-issues fast-path caveat:** the zero-issues path (Step 3 → Step 12, no Author, no Step-7 AV) ran **no** Alignment Verifier — it advances **no** edge (leave the record unchanged). The Promote guard then correctly forces a real Review round before the stage can freeze.

51. **Update state file**: set `Status: COMPLETE` and mark Step 12 complete. Record in history: `Round [N] Review complete — handed to Promote`.

52. **Emit the explicit handoff** to the user:
    ```
    Review round [N] is COMPLETE and mature.
    NEXT: run the Promote workflow on
    system-design/04-architecture/versions/round-[N]-review/[05-updated-architecture.md | 00-architecture.md].

    Promote runs the contract completeness & freezability gate (the unavoidable freeze backstop)
    and then splits the reviewed Architecture Overview into architecture.md / decisions.md / future.md.
    Until Promote runs, no promoted architecture.md is produced.
    ```

---

## Stopping Points

**Automatic flow (do NOT pause for human confirmation):**
- Steps 1 → 2 → 3: Proceed automatically through expert review, consolidation, and filtering
- **Zero-issues gate** (after Step 3): If zero kept issues, skip directly to Step 12 (Mark COMPLETE & Hand to Promote) — the contract completeness & freezability gate still runs, in the Promote stage
- Steps 3b → 4: Proceed to issue analysis and discussion
- Steps 5 → 6+7+8+9 (parallel) → 10: Execute without pausing between verification steps
- Step 10 → 11: Execute after human decisions collected (if needed)

**Human checkpoints (orchestrator handles these directly):**
- **Step 4** — WAITING_FOR_HUMAN for discussion until all issues resolved
- **Step 10** (if NEEDS_DECISIONS) — Present consolidated verification results, collect all decisions at once
- **After Step 11** — User decides: next round or exit

Do NOT ask "Should I proceed?" between automatic steps. Only stop at the human checkpoints listed above.

---

## Exit Criteria

The review exits via one of two paths:

1. **Automatic exit (zero-issues gate)**: After Step 3 (scope filter), if zero issues remain in the kept list after consolidation, re-raise detection, and scope/depth filtering, the document is complete. The zero-issues gate triggers this automatically, proceeding directly to Step 12 (Mark COMPLETE & Hand to Promote). The contract completeness & freezability gate still runs before the promoter — it now runs in the **Promote stage**, which is the sole producer of `architecture.md` (its unavoidability is the point: a zero-issues auto-exit must not carry an uncontracted cross-component read, or an un-freezable contract, into promotion).

2. **Severity-gated exit (maturity)**: After Step 11, the user exits when the round is **mature** — it surfaced no HIGH or MEDIUM issues (Step 49). Remaining LOW items are carried, not chased. This is a first-class exit, not merely a fallback: the convergence criterion is "no HIGH/MEDIUM" — this is what "multiple rounds until no HIGH issues remain" (above) means, and it reconciles with the zero-issues gate, which is the stronger short-circuit when nothing at all remains. The user may still override and exit despite open HIGH/MEDIUM if the remaining issues are not worth another round.

**After final round**: review marks the round COMPLETE and hands to Promote. The **Promote stage** then runs the contract completeness & freezability gate (blocking on HIGH findings from either reviewer — an uncontracted cross-component read, or an un-freezable contract) and the Architecture Promoter, which splits the reviewed Architecture Overview into three documents: `architecture.md` (clean spec), `decisions.md` (rationale), and `future.md` (deferred items).

---

<!-- INJECT: tool-restrictions -->
