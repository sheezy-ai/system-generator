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

- [x] Frozen contract registry verified present (materialized by Promote)
- [x] Guide created

## Component Specs

| Component | Status | Current | Last Updated |
|-----------|--------|---------|--------------|
| email-ingestion | IN_PROGRESS | Round 3 (ops) | 2026-01-06 |
| event-directory | COMPLETE | - | 2026-01-04 |
| notification-service | NOT_STARTED | - | - |
```

This file contains:
- **Stage initialization status** - Whether guide.md etc. have been created and the frozen cross-cutting.md registry is present
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
   - **If doesn't exist**: Fresh start — dispatch pre-discussion (it initializes state with `Current Workflow: Review`, Round 1 (build) Step 1, and adds the component to the stage index).

2. **State-machine guard (symmetric — mirrors create/promote; reads `Current Workflow` + `Status`)**. This is the load-bearing type-guard: it starts Review after Create completes, resumes an in-progress Review, and refuses to run while another workflow owns the component.
   - **`Status: COMPLETE`** (a workflow just finished — regardless of `Current Workflow`: Create, Review, or Promote): a **new Review round is starting**. This is how Review begins after Create finalises (`Current Workflow: Create`, `Status: COMPLETE`), and how a backward-edge re-review begins after a prior Review or Promote round. Dispatch pre-discussion to begin the new round — its On Start sets `Current Workflow: Review`, initializes the next sequential round (build), and moves the stage index to IN_PROGRESS. **(After a Review EXIT the intended next step is the Promote workflow; re-running Review here instead just starts another review round — safe, but usually not what you want.)**
   - **`Status: not COMPLETE`** and **`Current Workflow`** is anything other than `Review` (i.e. `Create` or `Promote`): **Error** — "Cannot start Review: {Current Workflow} workflow still in progress." (A missed guard here would let Review run over an in-flight Create/Promote and strand the component.)
   - **`Status: not COMPLETE`** and **`Current Workflow: Review`**: resume the in-progress round — route by `Status` (items 3–5 below).

3. **If status = BLOCKED_UPSTREAM_ISSUE** (Current Workflow: Review):
   - Report blocking issue details from state file
   - STOP

4. **If status = WAITING_FOR_HUMAN** (Current Workflow: Review):
   - Check current step to determine what we're waiting for
   - See "Handling WAITING_FOR_HUMAN" below

5. **If status = IN_PROGRESS** (Current Workflow: Review):
   - Dispatch based on current step (see table below)

### Step-to-Phase Mapping

| Current Step | Phase | Action |
|--------------|-------|--------|
| 0, 1, 2, 3, 4 | Pre-discussion | Dispatch pre-discussion |
| 5 | Discussion | Dispatch discussion (single iteration) |
| 6, 7, 8, 9, 10 | Post-discussion | Dispatch post-discussion |
| 11 | Post-discussion | Dispatch with routing decision |
| 12 | (router only) | Mark COMPLETE & Hand to Promote — no dispatch (see below) |

---

## Handling WAITING_FOR_HUMAN

### At Step 5 (Discussion)

Human needs to respond to issues in the file.

**Present** — lead with the decision-triage must-engage list so the human knows where their attention is actually required (read the must-engage shortlist from `triage_file` / `03b-decision-triage.md`):
```
Issues ready for discussion.

File: [issues_file path]
Issues: [N] ([high] HIGH, [medium] MEDIUM, [low] LOW)

⚠️ Must-engage — your input required ([must_engage_count]): these turn on product facts, scale, risk/regulatory appetite, scope intent, or an upstream-vs-spec direction call that the recommendations and verifiers cannot decide for you. Engaging these is the priority ("defer — need to check" is a valid answer):
[list each must-engage issue: ID — why it's yours — default-if-waved and its risk, from 03b-decision-triage.md]

Triage detail (incl. any "accept-with-scrutiny" recommendations): [triage_file path]

The remaining issues are implementation choices backstopped by the verifier suite — review at your discretion. Please respond to each issue in the file, then say "ready".
```

If `must_engage_count` is 0, say so explicitly ("Triage flagged no must-engage issues this round") rather than omitting the line.

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
Options: SYNC_ALL, DEFER_ALL, or specify per issue. (DEFER_ALL does NOT route: findings stay only in this round's alignment report, which no other stage reads — the target stage won't see them unless separately re-raised.)
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
Maturity: [mature | not mature] — this round surfaced [N] HIGH, [M] MEDIUM ([K] LOW carried)
Recommendation: [recommendation reason]

[If mature (no HIGH/MEDIUM surfaced this round): state that this part has stabilised and present EXIT / TRANSITION as the default. Any remaining LOW items are carried (recorded), not blocking. Another round of the same part is warranted only if you expect genuinely new HIGH/MEDIUM concerns — not to chase LOWs.]

Options:
1. [CONTINUE_BUILD / CONTINUE_OPS] — Another round of [part] (only if you expect new HIGH/MEDIUM concerns; LOW items alone do not warrant another round)
2. [TRANSITION_TO_OPS / KICK_BACK_TO_BUILD] — Switch to [other part]
3. EXIT — Finish review, promote spec

Your choice?
```

**Collect routing decision:**
- If CONTINUE: Update state (increment round, keep part), dispatch pre-discussion
- If TRANSITION/KICK_BACK: Update state (increment round, switch part), dispatch pre-discussion
- If EXIT: **Mark COMPLETE & Hand to Promote** (see below) — do NOT dispatch post-discussion for promotion; the split/freeze is the separate Promote workflow (05P-2).

---

## Mark COMPLETE & Hand to Promote

Reached when the human chooses **EXIT** at the routing decision, or when pre-discussion returns **ZERO_ISSUES** (nothing to review this part). This ends the Review workflow for the component and hands off to Promote. **Review no longer runs the promoter** — it moved to the Promote workflow, which is the sole writer of `specs/[component-name].md`. The freeze is not gone: it runs in Promote, on the only road to the published spec.

1. **Determine the handoff input document** (the reviewed spec Promote will freeze), from the last completed Review round `R` and part:
   - `round-[R]-review-[build|ops]/05-updated-spec.md` if it exists (the Author ran), otherwise `round-[R]-review-[build|ops]/00-spec.md` (the zero-issues path, no Author ran).
2. **Update per-component state**: set `Status: COMPLETE` (leave `Current Workflow: Review` — this is review-COMPLETE), mark Step 12 complete, add history entry `Round [R] Review complete — handed to Promote`.
3. **Update the stage index** (`{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/workflow-state.md`): set the component's row to `REVIEWED` (reviewed, promote pending — not yet `COMPLETE`; the Promote workflow sets `COMPLETE` once `specs/[component-name].md` is published), Last Updated to today. Keep the table sorted alphabetically.
4. **Emit the explicit handoff** to the human:
   ```
   Review for [component] is COMPLETE and mature.
   NEXT: run the Promote workflow (05-components/promote/orchestrator.md) for [component].
   It freezes the reviewed spec at
   {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[R]-review-[build|ops]/[05-updated-spec.md | 00-spec.md]
   into specs/[component].md / future/[component].md / decisions/[component].md.
   Until Promote runs, no published specs/[component].md is produced.
   ```
5. STOP.

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
- **If `ZERO_ISSUES`**: The spec is complete for this part. Skip Discussion and Post-Discussion phases. Proceed directly to **Mark COMPLETE & Hand to Promote** (see below) — the reviewed spec is this round's `00-spec.md` (no Author ran).
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
Action: [RUN | APPLY_DECISIONS]
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
→ Present routing options to human (see above). On the human's EXIT choice, the router runs **Mark COMPLETE & Hand to Promote** directly (no further post-discussion dispatch — promotion is the separate Promote workflow).

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
| New component starts | Update the existing row (created at `CREATED`): `IN_PROGRESS \| Round 1 (build) \| [date]` |
| Round changes | Update "Current" column: `Round N (part)` |
| Part transitions | Update "Current" column: `Round N (new-part)` |
| Review completes (EXIT / zero-issues) | Update: `REVIEWED \| - \| [date]` — reviewed, promote pending. The **Promote** workflow sets `COMPLETE` once `specs/[component].md` is published; Review no longer marks the component `COMPLETE`. |
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
