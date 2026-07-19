# Foundations Promote Orchestrator

---

## Purpose

The split. Runs **after a Review round completes**; snapshots the reviewed Foundations, then promotes it — splitting into `foundations.md` / `decisions.md` / `future.md` — and records the promotion as a versioned `round-N-promote` round.

Because the promoter is the **sole producer of `foundations.md`** and Promote is the only workflow that runs it, this sits on the **only road** to a promoted Foundations. Promote is a plain split-and-record — Foundations has no downstream contract registry, so there is no freeze gate, materialization, or fidelity check (those are 04-only).

**Flow:** Review (completes) → **Promote** [guard → split → record] → done.

---

## Workflow State Management

**State file**: `system-design/03-foundations/versions/workflow-state.md`

### On Start/Resume

1. **Check if state file exists**:
   - **If NO**: Error — "No state file found. Promote requires a completed Review round; run Create → Review first."
   - **If YES**: Read the state file. The action depends on `Status` and `Current Workflow`:
     - **`Status: COMPLETE`** (a workflow just finished — regardless of `Current Workflow`): Set `Current Workflow: Promote`, initialize the next sequential round number (globally numbered — see unified `versions/` folder convention), preserve history. Then apply the **review-mandatory guard** (Step 1).
     - **`Status: not COMPLETE`** and **`Current Workflow: Promote`**: Resume from the current step.
     - **`Status: not COMPLETE`** and **`Current Workflow`** is anything else: Error — `Cannot start Promote: {Current Workflow} workflow still in progress`.

2. **Update state file** at each step transition.

### State File Format

```markdown
# Foundations Workflow State

**Foundations**: 03-foundations/foundations.md
**PRD**: 02-prd/prd.md
**Current Workflow**: Promote
**Current Round**: [N]
**Status**: IN_PROGRESS | COMPLETE

## Progress

### Round [N] (Promote)
- [ ] Step 1: Guard & Snapshot
- [ ] Step 2: Promote (split)
- [ ] Step 3: Finalise

## History
- YYYY-MM-DD HH:MM: Round [N] (Promote) started — splitting round-[R]-review
```

---

## Fixed Paths

**Output directory**: `system-design/03-foundations/versions`
**State file**: `system-design/03-foundations/versions/workflow-state.md`
**Working record**: `system-design/03-foundations/versions/round-[N]-promote/`

**Published outputs** (created by the promoter — the parent folder, unchanged from today):
- `system-design/03-foundations/foundations.md` — Clean current-scope Foundations
- `system-design/03-foundations/decisions.md` — Design rationale and trade-offs
- `system-design/03-foundations/future.md` — Deferred items and future considerations

**Output-location principle:** the `round-[N]-promote/` record is the working history — **nothing reads it cross-stage**. Downstream stages read only the stable published copies (`foundations.md` / `decisions.md` / `future.md`).

---

## Prompt Locations

```
agents/03-foundations/promote/
├── orchestrator.md                     # This file
└── promoter.md                         # Splits the reviewed Foundations into foundations/decisions/future
```

---

## Output Directory Structure

```
system-design/03-foundations/
├── foundations.md                 # Clean current-scope (created by the promoter here)
├── decisions.md                   # Design rationale (created by the promoter here)
├── future.md                      # Deferred items (created by the promoter here)
└── versions/
    ├── workflow-state.md
    ├── round-[R]-review/              # The review round being split (input source)
    │   └── 05-updated-foundations.md      # (or 00-foundations.md on the zero-issues path)
    ├── round-[N]-promote/             # This promote round's working record
    │   ├── 00-foundations.md              # Input snapshot = the reviewed doc being split
    │   ├── foundations.md                 # Copy of the promoted spec
    │   ├── decisions.md                   # Copy of the promoted decisions
    │   ├── future.md                      # Copy of the promoted future
    │   └── promote-metadata.md            # date, source review round, input file used
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
- You SPAWN agents to do work (the promoter)
- You UPDATE the state file with status changes
- You WRITE the round-record metadata directly via Edit (these are orchestrator records, not authored content)
- You DO NOT author the promoted documents (the promoter does)
- Spawn agents in FOREGROUND (not background) — agents need interactive approval for file writes

**Context management**: Keep your context lean — use Grep for targeted extraction from the state file, `ls` for existence checks. The reviewed document is read by the promoter, not by the orchestrator.

**Agent Invocation Pattern**

```
Follow the instructions in: [agent-prompt-path]

Input: [resolved file paths]
Output: [resolved file path]
```

---

### Step 1: Guard & Snapshot

**Review-mandatory guard (structural — this makes "Review before a usable `foundations.md`" structural, not convention):**

1. **Update state file**: Set Step 1, status = IN_PROGRESS.

2. **Identify the last completed round** from the state file history: its number (`R`) and type.

3. **Assert the last completed round was Review**:
   - If the last completed round was **Review** → proceed.
   - If it was **create** or **expand** (or anything else) → **Error and stop**: `Promote requires a completed Review round; last round was {type}. Run a Review round before promoting.`
   - This guard is mandatory. A pattern-based state machine ("`Status: COMPLETE` → start next") does not by itself stop a human pointing Promote at an unreviewed create/expand draft — this guard does.

4. **Determine the input document** (the reviewed doc to split):
   - `system-design/03-foundations/versions/round-[R]-review/05-updated-foundations.md` (the Author ran that round), **else**
   - `system-design/03-foundations/versions/round-[R]-review/00-foundations.md` (the zero-issues path — no Author ran).
   - If neither exists → **Error and stop**: "Review round [R] completed but no reviewed document found."

5. **Create the promote round record and snapshot the input**:
   - Create `system-design/03-foundations/versions/round-[N]-promote/`
   - Copy the input document to `round-[N]-promote/00-foundations.md` (the input snapshot = the reviewed doc being split). **All promote steps below work from this snapshot.**

6. **Update state file**: Mark Step 1 complete.

7. **Automatically proceed to Step 2.**

---

### Step 2: Promote (split)

8. **Update state file**: Set Step 2, status = IN_PROGRESS.

9. **Spawn Foundations Promoter** (FOREGROUND):
    ```
    Follow the instructions in: {{AGENTS_PATH}}/03-foundations/promote/promoter.md

    Input:
    - Reviewed Foundations: system-design/03-foundations/versions/round-[N]-promote/00-foundations.md
    - Foundations guide: {{GUIDES_PATH}}/03-foundations-guide.md

    Output:
    - system-design/03-foundations/foundations.md
    - system-design/03-foundations/decisions.md
    - system-design/03-foundations/future.md
    ```

10. **Copy the promoted set into the round record**: copy `foundations.md`, `decisions.md`, `future.md` into `round-[N]-promote/` (the working record). The parent copies are the published authority; these are the frozen snapshot for this round.

11. **Update state file**: Mark Step 2 complete.

12. **Automatically proceed to Step 3.**

---

### Step 3: Finalise

13. **Update state file**: Set Step 3, status = IN_PROGRESS.

14. **Verify the three published documents exist** (before finalising):
    - `system-design/03-foundations/foundations.md`
    - `system-design/03-foundations/decisions.md`
    - `system-design/03-foundations/future.md`
    - If any is missing → **Error**: "Promoter completed but output not found at [path]" — do **not** mark COMPLETE.

15. **Write `round-[N]-promote/promote-metadata.md`** (the promote record):
    ```markdown
    # Promote Round [N]

    **Date**: [date]
    **Source Review Round**: round-[R]-review
    **Input File Used**: [05-updated-foundations.md | 00-foundations.md]
    ```

16. **Update state file**: status = COMPLETE; record the promotion in the round record + state history (`Round [N] (Promote) complete — split round-[R]-review`).

17. **Report** to the user: the split is complete; the three published documents (`foundations.md`, `decisions.md`, `future.md`) are current, and `round-[N]-promote/` holds the record.

---

## Stopping Points

**Automatic flow (do NOT pause for human confirmation):**
- Step 1 → 2 → 3: proceed automatically through the split and record.

There are no human checkpoints in Promote — it guards, splits, and records. Do NOT ask "Should I proceed?" between steps.

---

## Exit Criteria

Promote exits by **splitting**: the review-mandatory guard passes, the promoter produces the three published documents, and the `round-[N]-promote` record captures the promotion. If the last completed round was not Review, the workflow errors at Step 1 and does not split.

---

## Error Handling

| Condition | Action |
|-----------|--------|
| No state file | Error: "No state file found. Promote requires a completed Review round; run Create → Review first." |
| Last completed round was not Review | Error: "Promote requires a completed Review round; last round was {type}." |
| `Status: not COMPLETE` + other workflow in progress | Error: "Cannot start Promote: {Current Workflow} workflow still in progress" |
| Reviewed document not found | Error: "Review round [R] completed but no reviewed document found." |
| Promoter fails | Error: Report failure details; do not mark COMPLETE |
| Published output file missing after promote | Error: "Promoter completed but output not found at [path]" |

---

<!-- INJECT: tool-restrictions -->
