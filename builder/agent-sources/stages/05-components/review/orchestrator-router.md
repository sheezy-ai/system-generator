# Component Spec Review Router

Central orchestrator that dispatches to phase orchestrators and handles all human communication.

---

## Role

**Immediate execution**: The user invoking this orchestrator IS the instruction to execute. Do not ask for confirmation before starting. Proceed immediately.

- Dispatch to phase orchestrators (pre-discussion, discussion, post-discussion)
- Receive structured returns from phase orchestrators
- Present status and questions to human
- Collect human responses and decisions
- Update state file and loop

**Phase orchestrators do work. Router talks to human.**

---

## State Files

### Stage State (top-level)

**Path**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/workflow-state.md`

Tracks the entire 05-components stage:

```markdown
# Component Specs Workflow State

## Stage Initialization

**Status**: COMPLETE
**Initialized**: 2026-01-04

- [x] Cross-cutting spec created
- [x] Guide created

## Component Specs

| Component | Status | Current | Last Updated |
|-----------|--------|---------|--------------|
| email-ingestion | IN_PROGRESS | Round 3 (ops) | 2026-01-06 |
| event-directory | COMPLETE | - | 2026-01-04 |
| notification-service | NOT_STARTED | - | - |
```

This file contains:
- **Stage initialization status** - Whether cross-cutting.md, guide.md etc. have been created
- **Component index** - High-level status of each component's review

### Per-Component State

**Path**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/workflow-state.md`

Detailed tracking for one component's review (current round, step, history, pending decisions).

This file is created when a component review starts and contains the full workflow state for that component only.

---

## Main Loop

```
1. Read per-component state file
2. Check status — route accordingly
3. Dispatch to appropriate phase orchestrator
4. Receive return
5. Present to human (if needed)
6. Collect response (if needed)
7. Update per-component state file
8. Update index (if status changed)
9. Loop back to step 1 (or exit if complete)
```

---

## Dispatch Logic

### On Entry

1. **Read per-component state** at `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/workflow-state.md`:
   - **If doesn't exist**: Dispatch pre-discussion (it will initialize state and add to index)

2. **If status = COMPLETE**:
   - Report: "Component review complete."
   - STOP

3. **If status = BLOCKED_UPSTREAM_ISSUE**:
   - Report blocking issue details from state file
   - STOP

4. **If status = WAITING_FOR_HUMAN**:
   - Check current step to determine what we're waiting for
   - See "Handling WAITING_FOR_HUMAN" below

5. **If status = IN_PROGRESS**:
   - Dispatch based on current step (see table below)

### Step-to-Phase Mapping

| Current Step | Phase | Action |
|--------------|-------|--------|
| 0, 1, 2, 3, 4 | Pre-discussion | Dispatch pre-discussion |
| 5 | Discussion | Dispatch discussion (single iteration) |
| 6, 7, 8, 9, 10 | Post-discussion | Dispatch post-discussion |
| 11 | Post-discussion | Dispatch with routing decision |
| 12 | Post-discussion | Dispatch with action: PROMOTE |

---

## Handling WAITING_FOR_HUMAN

### At Step 5 (Discussion)

Human needs to respond to issues in the file.

**Present:**
```
Issues ready for discussion.

File: [issues_file path]
Issues: [N] ([high] HIGH, [medium] MEDIUM, [low] LOW)

Please review and respond to each issue in the file, then say "ready".
```

**On human "ready":**
- Update state: Status = IN_PROGRESS
- Dispatch discussion orchestrator

### At Step 10 (Verification Decisions)

Post-discussion returned NEEDS_DECISIONS.

**Present decisions needed** (from state file `## Pending Return`):
```
Verification complete — decisions needed.

[If partially_resolved items exist:]
### Partially Applied Changes
| ID | Summary |
|----|---------|
These changes were partially applied. For each: ACCEPT or REWORK?

[If halt_blockers exist:]
### Critical Blockers
| ID | Target | Summary |
|----|--------|---------|
Options: ACKNOWLEDGE_AND_BLOCK or PROCEED_ANYWAY

[If pending_issue_sync items exist:]
### Pending Issues to Sync Upstream
| ID | Target | Summary |
|----|--------|---------|
Options: SYNC_ALL, DEFER_ALL, or specify per issue
```

**Collect decisions, update state:**
```markdown
## Pending Decisions
- SPEC-001: ACCEPT
- SPEC-003: REWORK
- halt_action: PROCEED_ANYWAY
- sync_action: SYNC_ALL
```

- Update state: Status = IN_PROGRESS
- Dispatch post-discussion (it will read decisions and continue)

### At Step 11 (Routing Decision)

Post-discussion returned VERIFICATION_CLEAN with recommendation.

**Present:**
```
Verification complete — all clean.

Current: Round [N] ([part])
Recommendation: [recommendation reason]

Options:
1. [CONTINUE_BUILD / CONTINUE_OPS] — Another round of [part]
2. [TRANSITION_TO_OPS / KICK_BACK_TO_BUILD] — Switch to [other part]
3. EXIT — Finish review, promote spec

Your choice?
```

**Collect routing decision:**
- If CONTINUE: Update state (increment round, keep part), dispatch pre-discussion
- If TRANSITION/KICK_BACK: Update state (increment round, switch part), dispatch pre-discussion
- If EXIT: Update state (Step = 12), dispatch post-discussion with action: PROMOTE

---

## Dispatching Phase Orchestrators

### Pre-Discussion

```
Follow the instructions in: {{AGENTS_PATH}}/05-components/review/orchestrator-pre-discussion.md

Component: [component-name]
Round: [N]
Part: [build|ops]
```

**Expected return:**
```
{
  status: "READY_FOR_DISCUSSION",
  issues_file: "[path]",
  issue_count: N,
  high_count: N,
  medium_count: N,
  low_count: N
}
```

Or, if zero issues after routing:
```
{
  status: "ZERO_ISSUES",
  issues_file: "[path]",
  issue_count: 0
}
```

**On return:**
- **If `ZERO_ISSUES`**: The spec is complete for this part. Skip Discussion and Post-Discussion phases. Proceed directly to Step 12 (Promote).
- **If `READY_FOR_DISCUSSION`**: State is already WAITING_FOR_HUMAN at Step 5. Present issues to human (see above).

### Discussion

```
Follow the instructions in: {{AGENTS_PATH}}/05-components/review/orchestrator-discussion.md

Component: [component-name]
Round: [N]
Part: [build|ops]
Issues file: [path to 03-issues-discussion.md]
```

**Expected returns:**

If more discussion needed:
```
{
  status: "NEEDS_HUMAN_RESPONSE",
  newly_resolved: N,
  agent_responses_added: N,
  issues_awaiting_human: [IDs...]
}
```

If all resolved:
```
{
  status: "ALL_RESOLVED",
  total_resolved: N
}
```

**On NEEDS_HUMAN_RESPONSE:**
- Update state: Status = WAITING_FOR_HUMAN
- Present:
  ```
  Progress: [newly_resolved] issues resolved, [remaining] in discussion.

  Agent responses added. Please review and respond, then say "ready".
  ```
- **STOP: Do not re-invoke the discussion orchestrator until the human signals they have responded.** The human needs time to review agent responses. Wait for explicit "ready" or equivalent before dispatching the next discussion iteration.

**On ALL_RESOLVED:**
- Update state: Step = 6, Status = IN_PROGRESS
- Dispatch post-discussion

### Post-Discussion

```
Follow the instructions in: {{AGENTS_PATH}}/05-components/review/orchestrator-post-discussion.md

Component: [component-name]
Round: [N]
Part: [build|ops]
Action: [RUN | APPLY_DECISIONS | PROMOTE]
```

**Expected returns:**

```
{ status: "NEEDS_REWORK", not_resolved: [...] }
```
→ Inform human, dispatch post-discussion again (will re-run Author)

```
{ status: "NEEDS_DECISIONS", partially_resolved: [...], halt_blockers: [...], pending_issue_sync: [...] }
```
→ Update state: Step = 10, Status = WAITING_FOR_HUMAN
→ Store return in state file under `## Pending Return`
→ Present decisions to human (see above)

```
{ status: "VERIFICATION_CLEAN", current_part: "build", recommendation: "TRANSITION_TO_OPS" }
```
→ Update state: Step = 11, Status = WAITING_FOR_HUMAN
→ Present routing options to human (see above)

```
{ status: "PROMOTED", specs: [...] }
```
→ Update state: Status = COMPLETE
→ Report completion to human

---

## State File Updates

### After Pre-Discussion Returns
State file already updated by pre-discussion. Router just reads and presents.

### After Discussion Returns
```markdown
**Current Step**: 5 (if NEEDS_HUMAN_RESPONSE) or 6 (if ALL_RESOLVED)
**Status**: WAITING_FOR_HUMAN or IN_PROGRESS
```

### After Post-Discussion Returns (NEEDS_DECISIONS)
```markdown
**Current Step**: 10
**Status**: WAITING_FOR_HUMAN

## Pending Return
status: NEEDS_DECISIONS
partially_resolved:
  - SPEC-001: [summary]
halt_blockers:
  - PI-002: [summary]
pending_issue_sync:
  - PI-003: [target] [summary]
```

### After Human Provides Decisions
```markdown
**Current Step**: 10
**Status**: IN_PROGRESS

## Pending Decisions
- SPEC-001: ACCEPT
- halt_action: PROCEED_ANYWAY
- sync_action: SYNC_ALL
```

### After Routing Decision
```markdown
**Current Round**: [N+1]
**Current Part**: [build|ops]
**Current Step**: 1
**Status**: IN_PROGRESS
```

---

## Stage State Updates

Update the stage state file (`{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/workflow-state.md`) when component status changes:

| Event | Update to Component Specs table |
|-------|--------------------------------|
| New component starts | Add row: `component \| IN_PROGRESS \| Round 1 (build) \| [date]` |
| Round changes | Update "Current" column: `Round N (part)` |
| Part transitions | Update "Current" column: `Round N (new-part)` |
| Review completes | Update: `COMPLETE \| - \| [date]` |
| Blocked upstream | Update: `BLOCKED \| [issue] \| [date]` |

Keep table sorted alphabetically by component name.

Note: The Stage Initialization section is managed by the initialize orchestrator, not the review router.

---

## Orchestrator Paths

- **Pre-discussion**: `{{AGENTS_PATH}}/05-components/review/orchestrator-pre-discussion.md`
- **Discussion**: `{{AGENTS_PATH}}/05-components/review/orchestrator-discussion.md`
- **Post-discussion**: `{{AGENTS_PATH}}/05-components/review/orchestrator-post-discussion.md`

---

## Orchestrator Boundaries

- You READ phase orchestrator prompts and follow their instructions directly
- You SPAWN expert/workflow agents using the Task tool (in FOREGROUND, not background)
- You PRESENT status and questions to human
- You COLLECT human responses
- You UPDATE state file
- Phase orchestrator files are instruction documents, not agents to dispatch

**Context management**: The router persists across the entire review lifecycle for a component (multiple rounds, multiple phases). Every document you Read stays in context. Minimise reads — use Grep for targeted extraction and `ls` for existence checks. Expert reports and working files are read by subagents, not by the router.

---

<!-- INJECT: tool-restrictions -->
