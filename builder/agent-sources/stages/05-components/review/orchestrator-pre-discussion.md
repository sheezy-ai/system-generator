# Component Spec Review: Pre-Discussion Phase

Handles Steps 0-4: Pending Issue Check, Expert Review, Consolidation, Filter Issues, and Issue Analysis.

---

## Orchestrator Boundaries

These are instructions for the router to follow directly. The router:
- Spawns expert/workflow agents using the Task tool (in FOREGROUND, not background)
- Passes file PATHS to agents, not file contents
- Does NOT read agent prompt files — agents read their own instructions

**Context management**: The router accumulates context across phases within a round. Spawned subagents (experts, consolidator, issue router, issue analyst) run in their own context via the Task tool. To keep the router's context lean:
- Use `ls` for existence checks, not Read
- Use Grep for targeted extraction from state files, not full reads
- Do NOT Read expert reports or consolidated issues into the router's context — subagents read their own inputs

---

## Workflow State Management

### State Files

**Stage state**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/workflow-state.md`
- Contains stage initialization status (cross-cutting.md, guide.md created)
- Contains component index (high-level status of all components)

**Per-component state**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/workflow-state.md`
- Detailed tracking for one component's review
- Current round, step, history, pending decisions

### On Start/Resume

1. **Check if per-component state file exists**:
   - **If NO**: Create it, initialize Round 1 (build) Step 1, add component to stage state's Component Specs table
   - **If YES**: Read it, resume from current round/part/step

2. **Verify round number against filesystem** (before starting a new round):
   - List existing directories: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-*-*/`
   - Parse highest round number from directory names (e.g., `round-8-review-build` → 8)
   - If state file says "Current Round: X" but highest directory is round-Y:
     - If Y > X: State is behind — update state to Round Y, log warning
     - If X > Y + 1: State is ahead — error and stop (manual intervention needed)
   - New round number = highest existing round + 1
   - **Filesystem is source of truth for round numbering**

3. **Determine spec source path** (used when starting a round):
   - **First Build round**: Use `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/[component-name].md`
   - **Subsequent Build round**: Use `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-{N-1}-review-build/05-updated-spec.md`
   - **First Ops round**: Use final Build round's output (`{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-{last-build}-review-build/05-updated-spec.md`)
   - **Subsequent Ops round**: Use `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-{N-1}-review-ops/05-updated-spec.md`
   - **Build after Ops kick-back**: Use previous Ops round's output (`{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-{N-1}-review-ops/05-updated-spec.md`)

4. **Copy source at round start**: Copy the source spec to `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/round-[N]-review-[build|ops]/00-spec.md`. All agents in this round work from this copy.

5. **Update state file** at each step transition

### State File Format

```markdown
# Component Spec Review Workflow State

**Component**: [component-name]
**Spec**: 05-components/specs/[component-name].md
**Architecture Overview**: 04-architecture/architecture.md
**Foundations**: 03-foundations/foundations.md
**PRD**: 02-prd/prd.md
**Current Round**: 3
**Current Part**: build
**Current Step**: 1
**Status**: IN_PROGRESS | WAITING_FOR_HUMAN | BLOCKED_UPSTREAM_ISSUE | COMPLETE
**On Response**: (When WAITING_FOR_HUMAN) Spawn discussion-facilitator agents for issues needing response. Do NOT answer in chat.

## Progress

### Round 1 (build)
- [x] Step 1: Expert Review
- [x] Step 2: Consolidation
- ... (completed)

### Round 2 (build)
- [x] Step 1: Expert Review
- ... (completed)

### Round 3 (build) <- current
- [x] Step 1: Expert Review
- [ ] Step 2: Consolidation
- [ ] Step 3: Route Issues (Issue Router)
- [ ] Step 4: Issue Analysis
- [ ] Step 5: Discussion
- [ ] Step 6: Apply Changes
- [ ] Step 7: Change Verification
- [ ] Step 8: Alignment Verification
- [ ] Step 9: Contract Verification
- [ ] Step 10: Verification Review
- [ ] Step 11: Execute & Route
- [ ] Step 12: Promote (on exit only)

## History
- YYYY-MM-DD HH:MM: Round 1 (build) started
- YYYY-MM-DD HH:MM: Round 1 (build) complete - continuing build
- YYYY-MM-DD HH:MM: Round 2 (build) started
```

---

## Fixed Paths

**Output directory**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions`
**Stage state**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/workflow-state.md`
**Per-component state**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/workflow-state.md`
**Working files**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/round-[N]-review-[build|ops]/`

Review uses `round-1-review-build`, `round-2-review-build`, `round-3-review-ops`, etc. Creation workflow uses `round-{N}-create`.

---

## Review Parts

Component Spec review uses **2 parts** with 7 experts total:

| Part | Focus | Experts |
|------|-------|---------|
| **Build** | Can we build this right? | Technical Lead, API Designer, Data Modeller, Integration Reviewer |
| **Ops** | Will it work in production? | Security Reviewer, Operations Reviewer, Test Engineer |

**Workflow:**
- **Build to maturity first**: Run Build rounds until no HIGH issues remain
- **Then Ops to maturity**: Run Ops rounds until no HIGH issues remain
- **Kick-back if needed**: If Ops finds structural issues requiring redesign, return to Build

Each round is one part only. Round numbers are global across the entire review.

---

## Agent Prompt Locations

**Expert agents** (spawn based on current part):

Build experts:
- `{{AGENTS_PATH}}/05-components/review/experts/build/technical-lead.md`
- `{{AGENTS_PATH}}/05-components/review/experts/build/api-designer.md`
- `{{AGENTS_PATH}}/05-components/review/experts/build/data-modeller.md`
- `{{AGENTS_PATH}}/05-components/review/experts/build/integration-reviewer.md`

Ops experts:
- `{{AGENTS_PATH}}/05-components/review/experts/ops/security-reviewer.md`
- `{{AGENTS_PATH}}/05-components/review/experts/ops/operations-reviewer.md`
- `{{AGENTS_PATH}}/05-components/review/experts/ops/test-engineer.md`

**Workflow agents**:
- Consolidator: `{{AGENTS_PATH}}/05-components/review/consolidator.md`
- Issue Router: `{{AGENTS_PATH}}/05-components/review/issue-router.md`
- Issue Analyst: `{{AGENTS_PATH}}/universal-agents/issue-analyst.md`

---

## Output Directory Structure

```
versions/
├── workflow-state.md              # Index: status of all components
├── [component-name]/
│   ├── workflow-state.md          # Per-component: detailed tracking
│   ├── round-{N}-create/           # Creation workflow output
│   │   └── ...
│   ├── round-1-review-build/      # First review round (build)
│   │   ├── 00-spec.md             # Snapshot of input spec
│   │   ├── 01-technical-lead.md
│   │   ├── 01-api-designer.md
│   │   ├── 01-data-modeller.md
│   │   ├── 01-integration-reviewer.md
│   │   ├── 02-consolidated-issues.md
│   │   ├── 03-issues-discussion.md
│   │   └── ...
│   ├── round-2-review-build/
│   │   └── ...
│   └── round-3-review-ops/
│       ├── 00-spec.md
│       ├── 01-security-reviewer.md
│       ├── 01-operations-reviewer.md
│       ├── 01-test-engineer.md
│       └── ...
```

---

## Step 0: Pending Issue Check

**On workflow start**, check for pending issues logged against this document:

1. **Read** `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/pending-issues.md` (if it exists)

2. **Check for unresolved issues** for this component:
   - If unresolved pending issues exist, **notify human**:
     ```
     Note: [N] pending issue(s) logged against this Component Spec from other component reviews.
     These will be incorporated into the review at Step 2 (Consolidation).
     See {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/pending-issues.md for details.
     ```
   - If no unresolved issues for this component, proceed silently

3. **Proceed to Step 1** (pending issues will be merged by Consolidator)

---

## Step 1: Expert Issue Identification (Parallel)

1. **Update state file**: Set Step 1, status = IN_PROGRESS

2. **Create round directory and copy input**:
   - Create `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/round-[N]-review-[build|ops]/`
   - Copy source spec (determined in On Start/Resume) to `round-[N]-review-[build|ops]/00-spec.md`
   - If source doesn't exist, **error and stop**

3. **Spec path for this round**: Use `round-[N]-review-[build|ops]/00-spec.md`

4. **Spawn expert agents in parallel** (based on current part):

   Use the Task tool to spawn each expert agent. All experts for a part run in parallel.

   **If Build part**, spawn 4 Task agents (technical-lead, api-designer, data-modeller, integration-reviewer):
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/review/experts/build/[expert].md

   Input:
   - Spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-build/00-spec.md
   - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
   - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md
   - Maturity guide: {{GUIDES_PATH}}/05-components-maturity.md

   Output: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-build/01-[expert-name].md
   ```

   **If Ops part**, spawn 3 Task agents (security-reviewer, operations-reviewer, test-engineer) with same pattern.

5. **Update state file**: Mark Step 1 complete

6. **Automatically proceed to Step 2**

---

## Step 2: Consolidation

7. **Update state file**: Set Step 2, status = IN_PROGRESS

8. **Run Consolidator** (spawn as Task agent):
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/review/consolidator.md

   Input:
   - Expert reports: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/01-*.md
   - Pending issues: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/pending-issues.md

   Output:
   - Consolidated issues: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/02-consolidated-issues.md
   ```

9. **Update state file**: Mark Step 2 complete

10. **Automatically proceed to Step 3**

---

## Step 3: Route Issues (Issue Router)

11. **Update state file**: Set Step 3, status = IN_PROGRESS

12. **Run Issue Router agent** (spawn as Task agent):
    ```
    Follow the instructions in: {{AGENTS_PATH}}/05-components/review/issue-router.md

    Stage guide: {{GUIDES_PATH}}/05-components-guide.md
    Input: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/02-consolidated-issues.md
    Output: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/03-issues-discussion.md
    Component: [component]
    ```
    - Agent reads guide to understand what level of detail belongs at spec level
    - Agent filters issues: keeps spec-level issues, escalates upstream issues
    - Agent outputs summary format (ID, severity, summary, core question)
    - Note: Component Specs is the lowest level; issues that don't belong here should be escalated upstream, not deferred downstream

13. **Update state file**: Mark Step 3 complete

14. **Zero-issues gate**: Read `03-issues-discussion.md` and count kept issues (under the `## Issues` section).
    - **If zero kept issues**: Skip Steps 4–5. Update state file with history entry: "Zero kept issues after routing — proceeding to promotion." Return `ZERO_ISSUES` status to router (see Return to Router below).
    - **If one or more kept issues**: Automatically proceed to Step 4.

---

## Step 4: Issue Analysis

15. **Update state file**: Set Step 4, status = IN_PROGRESS

16. **Count issues** in `03-issues-discussion.md` and group into batches:
    - Group by theme or spec section
    - Aim for ~5-7 issues per batch maximum
    - If fewer than 4 issues total, use a single batch

17. **Spawn Issue Analyst agents in parallel** (one per batch):
    ```
    Follow the instructions in: {{AGENTS_PATH}}/universal-agents/issue-analyst.md

    Context documents:
    - Spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/00-spec.md
    - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
    - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md
    - PRD: {{SYSTEM_DESIGN_PATH}}/system-design/02-prd/prd.md

    Issues file: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/03-issues-discussion.md
    Issues: [ID1, ID2, ID3, ...]
    ```

18. **Wait for all agents to complete**

19. **Verify responses written**:
    - Check that each issue now has a `>> AGENT:` block
    - If any missing, re-invoke Issue Analyst for missing issues only

20. **Update state file**: Mark Step 4 complete

21. **Update state file for discussion phase**:
    - Set Step 5, status = WAITING_FOR_HUMAN

22. **Count issues by severity** in `03-issues-discussion.md`

---

## Return to Router

After Step 4 completes, return structured data to router:

```
{
  status: "READY_FOR_DISCUSSION",
  issues_file: "{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/03-issues-discussion.md",
  issue_count: [total issues],
  high_count: [HIGH severity count],
  medium_count: [MEDIUM severity count],
  low_count: [LOW severity count]
}
```

If zero issues after Step 3 (zero-issues gate):

```
{
  status: "ZERO_ISSUES",
  issues_file: "{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/03-issues-discussion.md",
  issue_count: 0
}
```

Do NOT present anything to human — router handles all human communication.

---

<!-- INJECT: tool-restrictions -->
