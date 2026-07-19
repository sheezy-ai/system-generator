# Component Spec Promote Orchestrator

---

## Purpose

The per-component freeze. Runs **after a Review round completes for this component**; promotes the reviewed spec — splitting it into the published `specs/[component-name].md` / `future/[component-name].md` / `decisions/[component-name].md` — and records the promotion as a versioned `round-N-promote` round.

Because the Spec Promoter is the **sole producer of `specs/[component-name].md`** and Promote is the only workflow that runs it, this workflow sits on the **only road** to a published component spec (create finalises to a draft; review finalises to a reviewed draft; neither writes `specs/`). Create → Review → **Promote** [guard → split → record] → frozen.

**Structural note (05P-2):** this workflow currently *guards* its input and *runs the existing Spec Promoter*, then records the freeze. It does **not** yet run a blocking conformance gate, and it does **not** seed the contract status ladder (`MATERIALIZED → DEFINED`) — those are added in 05P-3, on this same only-road. The per-round verifiers (contract-verifier, absent-from-freeze detector) stay in Review for now.

---

## Workflow State Management

**State file**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/workflow-state.md`

The per-component state file is shared across the component's Create → Review → Promote lifecycle. `Current Workflow` (Create | Review | Promote) and `Status` (IN_PROGRESS | WAITING_FOR_HUMAN | COMPLETE) together drive the state machine.

### On Start/Resume

Invoked for one component: `[component-name]`.

1. **Check if the per-component state file exists**:
   - **If NO**: Error — "No state file found for [component]. Promote requires a completed Review round; run Create → Review first."
   - **If YES**: Read the state file. The action depends on `Status` and `Current Workflow`:
     - **`Status: COMPLETE`** (a workflow just finished — regardless of `Current Workflow`): a Promote round is starting. **Apply the review-mandatory guard first, before mutating state** (this avoids stranding the component on a guard failure):
       - Read the state file history to identify the **last completed round** — its number (`R`) and type (`create` | `review-build` | `review-ops` | `promote`).
       - **If the last completed round was a Review round** (`review-build` or `review-ops`): Set `Current Workflow: Promote`, initialize the next sequential round number (`N` = highest existing `round-*` on the filesystem + 1; filesystem is source of truth for round numbering), set `Status: IN_PROGRESS`, preserve history. Then proceed to **Step 1 (Guard & Snapshot)**.
       - **If the last completed round was anything else** (`create`, `promote`, …): **Error and stop, WITHOUT mutating the state file** — `Promote requires a completed Review round; last round was {type}. Run a Review round before promoting.` Leaving `Status: COMPLETE` and `Current Workflow` untouched means the component is not stranded: the human can run Review (which starts a fresh round from `Status: COMPLETE`).
     - **`Status: not COMPLETE`** and **`Current Workflow: Promote`**: Resume from the current step.
     - **`Status: not COMPLETE`** and **`Current Workflow`** is anything else (Create, Review): Error — `Cannot start Promote: {Current Workflow} workflow still in progress`.

2. **Update the state file** at each step transition.

### State File Format (Promote round)

```markdown
# [Component Name] Workflow State

**Component**: [component-name]
**Spec**: 05-components/specs/[component-name].md
**Current Workflow**: Promote
**Current Round**: [N]
**Status**: IN_PROGRESS | COMPLETE

## Progress

### Round [N] (Promote)
- [ ] Step 1: Guard & Snapshot
- [ ] Step 2: Promote (split)
- [ ] Step 3: Finalise (verify + record + mark COMPLETE)

## History
- YYYY-MM-DD HH:MM: Round [N] (Promote) started — freezing round-[R]-review-[build|ops]
```

---

## Fixed Paths

**Output directory**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]`
**State file**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/workflow-state.md`
**Working record**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-promote/`

**Published outputs** (created by the Spec Promoter — the sole writer of these paths):
- `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/[component-name].md` — Implementation spec
- `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/future/[component-name].md` — Future planning
- `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/decisions/[component-name].md` — Design decisions

**Output-location principle:** the `round-[N]-promote/` record is this workflow's working history — nothing reads it cross-stage. Downstream (06-tasks, coherence) reads only the stable published `specs/[component-name].md`.

---

## Prompt Locations

```
agents/05-components/promote/
├── orchestrator.md    # This file
└── spec-promoter.md   # Splits the reviewed spec into specs/future/decisions (moved here from review in 05P-2; unchanged)
```

---

## Orchestration Workflow

**Immediate execution**: The user invoking this orchestrator IS the instruction to execute. Do not ask for confirmation before starting. Proceed immediately with the On Start/Resume check, then Step 1.

**File-First Principle**: Do NOT pass file contents or summaries to agents — pass only file PATHS; agents read files themselves.

**Orchestrator Boundaries**
- You READ the state file and workflow outputs.
- You SPAWN the Spec Promoter to do the split (in FOREGROUND, not background — it needs interactive approval for file writes).
- You UPDATE the state file with status changes.
- You WRITE the round-record metadata directly via Edit (an orchestrator record, not authored content).
- You DO NOT author the promoted documents — the Spec Promoter does.

**Context management**: Keep context lean — use Grep for targeted extraction from the state file, `ls` for existence checks. The reviewed spec is read by the Spec Promoter, not by the orchestrator.

---

### Step 1: Guard & Snapshot

1. **Update state file**: Set Step 1, `Status: IN_PROGRESS`.

2. **Determine the input document** (the reviewed spec to freeze — from the last completed Review round `R`, identified in On Start):
   - `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[R]-review-[build|ops]/05-updated-spec.md` if it exists (the Author ran that round), **else**
   - `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[R]-review-[build|ops]/00-spec.md` (the zero-issues path — no Author ran).
   - If neither exists → **Error and stop**: "Review round [R] completed but no reviewed spec found for [component]."

3. **Create the promote round record and snapshot the input**:
   - Create `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-promote/`.
   - Copy the input document to `round-[N]-promote/00-spec.md` (the input snapshot = the reviewed spec being frozen). **The split below works from this snapshot.**

4. **Update state file**: Mark Step 1 complete.

5. **Automatically proceed to Step 2.**

---

### Step 2: Promote (split)

6. **Update state file**: Set Step 2, `Status: IN_PROGRESS`.

7. **Spawn the Spec Promoter** (FOREGROUND) on the snapshot:
    ```
    Follow the instructions in: {{AGENTS_PATH}}/05-components/promote/spec-promoter.md

    Input:
    - Reviewed spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-promote/00-spec.md
    - Component name: [component-name]
    - Guide: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/guide.md

    Output:
    - Implementation spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/[component-name].md
    - Future planning: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/future/[component-name].md
    - Decisions: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/decisions/[component-name].md
    ```

8. **Copy the promoted set into the round record**: copy `specs/[component-name].md`, `future/[component-name].md`, `decisions/[component-name].md` into `round-[N]-promote/` (the frozen snapshot for this round). The `specs/`/`future/`/`decisions/` copies are the published authority; these are the round's working record.

9. **Update state file**: Mark Step 2 complete.

10. **Automatically proceed to Step 3.**

---

### Step 3: Finalise

11. **Update state file**: Set Step 3, `Status: IN_PROGRESS`.

12. **Verify the freeze outputs exist** (before marking COMPLETE):
    - The three published documents: `specs/[component-name].md`, `future/[component-name].md`, `decisions/[component-name].md`.
    - If any is missing → **Error**: "Spec Promoter completed but output not found at [path]" — do **not** mark COMPLETE.

13. **Write `round-[N]-promote/promote-metadata.md`** (the freeze record):
    ```markdown
    # Promote Round [N] — [component-name]

    **Date**: [date]
    **Component**: [component-name]
    **Source Review Round**: round-[R]-review-[build|ops] (input: [05-updated-spec.md | 00-spec.md])
    **Sole writer**: this Promote round is the only writer of specs/[component-name].md.

    ## Published Outputs
    - specs/[component-name].md
    - future/[component-name].md
    - decisions/[component-name].md
    ```
    (05P-3 adds the gate verdict, HIGH-gap dispositions, and contract-status transitions to this record.)

14. **Update state file**: `Status: COMPLETE`; mark Step 3 complete. Record in history: `Round [N] (Promote) complete — froze round-[R]-review-[build|ops]; specs/[component-name].md published`.

15. **Update the stage index** (`{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/workflow-state.md`): set the component's row in the Component Specs table to `COMPLETE`, Last Updated to today's date; add a history entry `[date]: [component-name] promoted (specs/ published)`. Keep the table sorted alphabetically.

16. **Report** to the user: the component freeze is complete; `specs/[component-name].md` / `future/[component-name].md` / `decisions/[component-name].md` are published, and `round-[N]-promote/` holds the record.

---

## Stopping Points

**Automatic flow (do NOT pause for human confirmation):** Step 1 → 2 → 3 proceed automatically. There is no human checkpoint in this workflow (05P-3 adds a gate that can HALT on HIGH findings).

Do NOT ask "Should I proceed?" between steps.

---

## Exit Criteria

Promote exits by **freezing**: the Spec Promoter produces the three published documents, and the `round-[N]-promote` record captures the freeze. The review-mandatory guard (On Start) is the only stop condition — it errors (without stranding) if the last completed round was not a Review round.

---

## Error Handling

| Condition | Action |
|-----------|--------|
| No state file for the component | Error: "No state file found for [component]. Promote requires a completed Review round; run Create → Review first." |
| Last completed round was not a Review round | Error (no state mutation): "Promote requires a completed Review round; last round was {type}." |
| `Status: not COMPLETE` + other workflow in progress | Error: "Cannot start Promote: {Current Workflow} workflow still in progress" |
| Reviewed spec not found | Error: "Review round [R] completed but no reviewed spec found for [component]." |
| Spec Promoter fails | Error: Report failure details; do not mark COMPLETE |
| Published output missing after split | Error: "Spec Promoter completed but output not found at [path]" — do not mark COMPLETE |

---

<!-- INJECT: tool-restrictions -->
