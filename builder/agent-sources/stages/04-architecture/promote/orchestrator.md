# Architecture Overview Promote Orchestrator

---

## Purpose

The single freeze. Runs **after a Review round completes**; gate-checks the reviewed Architecture Overview (contract completeness + freezability) as the hard, unavoidable backstop, then promotes it — splitting into `architecture.md` / `decisions.md` / `future.md` — and records the promotion as a versioned `round-N-promote` round.

Because the promoter is the **sole producer of `architecture.md`** and Promote is the only workflow that runs it, this gate sits on the **only road** to a promoted Architecture Overview. It is a single gate enforcing both freeze axes — §8 is **complete** AND **freezable** — before §8 becomes the authority.

**Flow:** Review (completes) → **Promote** [guard → gate → split → record] → frozen.

**Not in Promote:** materialization / fidelity (those live in 05-init until Slice 4); the experts themselves (per-round detection stays in Review). Promote only **re-runs** the two review experts as the unavoidable final verification, then promotes.

---

## Workflow State Management

**State file**: `system-design/04-architecture/versions/workflow-state.md`

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
# Architecture Overview Workflow State

**Architecture Overview**: 04-architecture/architecture.md
**Foundations**: 03-foundations/foundations.md
**PRD**: 02-prd/prd.md
**Current Workflow**: Promote
**Current Round**: [N]
**Status**: IN_PROGRESS | WAITING_FOR_HUMAN | COMPLETE

## Progress

### Round [N] (Promote)
- [ ] Step 1: Guard & Snapshot
- [ ] Step 2: Contract Completeness & Freezability Gate
- [ ] Step 3: Promote (split)
- [ ] Step 4: Finalise

## History
- YYYY-MM-DD HH:MM: Round [N] (Promote) started — freezing round-[R]-review
```

---

## Fixed Paths

**Output directory**: `system-design/04-architecture/versions`
**State file**: `system-design/04-architecture/versions/workflow-state.md`
**Working record**: `system-design/04-architecture/versions/round-[N]-promote/`

**Published outputs** (created by the promoter — the parent folder, unchanged from today):
- `system-design/04-architecture/architecture.md` — Clean current-scope Architecture Overview
- `system-design/04-architecture/decisions.md` — Design rationale and trade-offs
- `system-design/04-architecture/future.md` — Deferred items and future considerations

**Output-location principle:** the `round-[N]-promote/` record is the working history — **nothing reads it cross-stage**. Downstream stages read only the stable published copies (`architecture.md` / `decisions.md` / `future.md`).

---

## Prompt Locations

```
agents/04-architecture/promote/
├── orchestrator.md                    # This file
└── promoter.md                        # Splits the reviewed Architecture into spec/decisions/future

Gate reviewers (re-run — they LIVE in review, not moved):
├── {{AGENTS_PATH}}/04-architecture/review/experts/contract-completeness.md
└── {{AGENTS_PATH}}/04-architecture/review/experts/contract-freezability.md

Backward-edge machinery (existing):
└── system-design/04-architecture/versions/pending-issues.md   # consumed by Review Step 0
```

---

## Output Directory Structure

```
system-design/04-architecture/
├── architecture.md                # Clean current-scope (created by the promoter here)
├── decisions.md                   # Design rationale (created by the promoter here)
├── future.md                      # Deferred items (created by the promoter here)
└── versions/
    ├── workflow-state.md
    ├── round-[R]-review/              # The review round being frozen (input source)
    │   └── 05-updated-architecture.md
    ├── round-[N]-promote/             # This promote round's working record
    │   ├── 00-architecture.md             # Input snapshot = the reviewed doc being frozen
    │   ├── 11-contract-completeness-gate.md   # Gate re-run (completeness)
    │   ├── 12-contract-freezability-gate.md   # Gate re-run (freezability)
    │   ├── architecture.md                # Copy of the promoted spec
    │   ├── decisions.md                   # Copy of the promoted decisions
    │   ├── future.md                      # Copy of the promoted future
    │   └── promote-metadata.md            # date, source review round, gate verdict, HIGH gaps promoted past
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
- You SPAWN agents to do work (the two gate reviewers, the promoter)
- You UPDATE the state file with status changes
- You WRITE the round-record metadata and dispositions directly via Edit (these are orchestrator records, not authored content)
- You DO NOT author the promoted documents (the promoter does) or the gate reports (the reviewers do)
- Spawn agents in FOREGROUND (not background) — agents need interactive approval for file writes

**Context management**: Keep your context lean — use Grep for targeted extraction from the state file and gate reports, `ls` for existence checks. Gate reports and the reviewed document are read by the reviewers/promoter, not by the orchestrator.

**Agent Invocation Pattern**

```
Follow the instructions in: [agent-prompt-path]

Input: [resolved file paths]
Output: [resolved file path]
```

---

### Step 1: Guard & Snapshot

**Review-mandatory guard (structural — this makes "Review before a usable `architecture.md`" structural, not convention):**

1. **Update state file**: Set Step 1, status = IN_PROGRESS.

2. **Identify the last completed round** from the state file history: its number (`R`) and type.

3. **Assert the last completed round was Review**:
   - If the last completed round was **Review** → proceed.
   - If it was **create** or **expand** (or anything else) → **Error and stop**: `Promote requires a completed Review round; last round was {type}. Run a Review round before promoting.`
   - This guard is mandatory. A pattern-based state machine ("`Status: COMPLETE` → start next") does not by itself stop a human pointing Promote at an unreviewed create/expand draft — this guard does.

4. **Determine the input document** (the reviewed doc to freeze):
   - `system-design/04-architecture/versions/round-[R]-review/05-updated-architecture.md` (the Author ran that round), **else**
   - `system-design/04-architecture/versions/round-[R]-review/00-architecture.md` (the zero-issues path — no Author ran).
   - If neither exists → **Error and stop**: "Review round [R] completed but no reviewed document found."

5. **Create the promote round record and snapshot the input**:
   - Create `system-design/04-architecture/versions/round-[N]-promote/`
   - Copy the input document to `round-[N]-promote/00-architecture.md` (the input snapshot = the reviewed doc being frozen). **All gate and promote steps below work from this snapshot.**

6. **Update state file**: Mark Step 1 complete.

7. **Automatically proceed to Step 2.**

---

### Step 2: Contract Completeness & Freezability Gate

**This is the same gate that was Review's old Step 12 — verbatim logic, moved here. It is the hard backstop that a Step 11 maturity-override, or the zero-issues auto-gate, cannot bypass. Because the promoter runs only here, the gate sits on the only road to a promoted Architecture Overview. A single gate, both freeze axes — §8 complete AND freezable — before §8 becomes the authority.**

8. **Update state file**: Set Step 2, status = IN_PROGRESS.

9. **Contract completeness & freezability gate (blocking — do NOT spawn the promoter until this passes or every HIGH finding, from either reviewer, has a recorded disposition)**:
   - **Re-run both reviewers** on the snapshot about to be promoted (`round-[N]-promote/00-architecture.md`). Each writes its own gate report; both must clear (or have every HIGH disposed). Pass the same inputs to both.

     **(a) Contract Completeness reviewer** — is anything **missing** from §8?
     ```
     Follow the instructions in: {{AGENTS_PATH}}/04-architecture/review/experts/contract-completeness.md

     Input:
     - Architecture Overview: system-design/04-architecture/versions/round-[N]-promote/00-architecture.md
     - Foundations: system-design/03-foundations/foundations.md
     - PRD: system-design/02-prd/prd.md
     - Architecture guide: guides/04-architecture-guide.md
     - Maturity guide: guides/04-architecture-maturity.md

     Output: system-design/04-architecture/versions/round-[N]-promote/11-contract-completeness-gate.md
     ```

     **(b) Contract Freezability reviewer** — is what is **in** §8 actually **pinnable/freezable**?
     ```
     Follow the instructions in: {{AGENTS_PATH}}/04-architecture/review/experts/contract-freezability.md

     Input:
     - Architecture Overview: system-design/04-architecture/versions/round-[N]-promote/00-architecture.md
     - Foundations: system-design/03-foundations/foundations.md
     - PRD: system-design/02-prd/prd.md
     - Architecture guide: guides/04-architecture-guide.md
     - Maturity guide: guides/04-architecture-maturity.md

     Output: system-design/04-architecture/versions/round-[N]-promote/12-contract-freezability-gate.md
     ```
   - **If EITHER reviewer returns any HIGH finding** (an uncontracted cross-component read, or an under-pinned/un-freezable contract): **HALT — do NOT spawn the promoter.** Author now lives in the **previous stage (Review)**, not here — the promote gate cannot Author-fix in-stage. Set status = WAITING_FOR_HUMAN and give **every** HIGH finding from both reports one recorded disposition before the promoter runs:
     - **Resolved** — log the HIGH finding to `system-design/04-architecture/versions/pending-issues.md` (as an Unresolved entry, targeting the Architecture stage, with the reviewer, the concern, and the §8 gap it names) and **HALT** with: `Contract gate HIGH — re-run the Review workflow to add/pin the contract, then re-run Promote.` Review Step 0 already consumes `pending-issues.md` (the existing backward channel), so the next Review round picks it up; when that round completes, re-run Promote for a fresh `round-N-promote` freeze.
     - **Deferred** — recorded to `future.md` as a knowingly-deferred contract obligation (promote-local).
     - **Dismissed** — recorded to `decisions.md` with rationale (why it is not a cross-component read / not a contract, or why the residual is a fenced component realization rather than an un-freezable contract) (promote-local).
   - A human may knowingly **override** and proceed; the **Override** and its rationale are recorded in `decisions.md` (and captured in `promote-metadata.md` as a HIGH gap promoted past). The gate can be overridden, but it can **never be a silent pass** — every HIGH finding, from either reviewer, leaves a recorded disposition before the promoter runs.
   - **If both reviewers return no HIGH findings**: proceed to Step 3. (MEDIUM/LOW findings are carried, not chased — record them in `future.md` if a human wants them tracked.)
   - **Note (honest — do not overstate this):** both are the **same** reviewers re-run, not second independent detectors. This buys **unavoidability** — it catches a HIGH gap (a missing contract, or an un-freezable one) that a Step 11 maturity-override or the zero-issues auto-gate would otherwise carry straight into promotion. It does **not** add independent detection or defence-in-depth; the detection already happened (or was skipped) at Review Step 1. The freezability re-run also guarantees the un-freezable contract is caught **here, before freeze**, rather than escalating from the 05-init materializer after promotion.

10. **Update state file**: Mark Step 2 complete (record the gate verdict — CLEAN or the per-finding dispositions — in the history).

11. **Automatically proceed to Step 3** (only after the gate passes clean, or every HIGH finding has a recorded disposition/override; a **Resolved** disposition HALTs the workflow here — it does not proceed to Step 3).

---

### Step 3: Promote (split)

12. **Update state file**: Set Step 3, status = IN_PROGRESS.

13. **Spawn Architecture Promoter** (only after the gate passes clean, or every HIGH finding has a recorded disposition/override):
    ```
    Follow the instructions in: {{AGENTS_PATH}}/04-architecture/promote/promoter.md

    Input:
    - Reviewed Architecture Overview: system-design/04-architecture/versions/round-[N]-promote/00-architecture.md
    - Architecture guide: {{GUIDES_PATH}}/04-architecture-guide.md

    Output:
    - system-design/04-architecture/architecture.md
    - system-design/04-architecture/decisions.md
    - system-design/04-architecture/future.md
    ```

14. **Copy the promoted set into the round record**: copy `architecture.md`, `decisions.md`, `future.md` into `round-[N]-promote/` (the working record). The parent copies are the published authority; these are the frozen snapshot for this round.

15. **Update state file**: Mark Step 3 complete.

16. **Automatically proceed to Step 4.**

---

### Step 4: Finalise

17. **Update state file**: Set Step 4, status = IN_PROGRESS.

18. **Verify all three published output files exist**:
    - `system-design/04-architecture/architecture.md`
    - `system-design/04-architecture/decisions.md`
    - `system-design/04-architecture/future.md`
    - If any is missing → **Error**: "Promoter completed but output not found at [path]" — do not mark COMPLETE.

19. **Write `round-[N]-promote/promote-metadata.md`** (the freeze record):
    ```markdown
    # Promote Round [N]

    **Date**: [date]
    **Source Review Round**: round-[R]-review (input: [05-updated-architecture.md | 00-architecture.md])
    **Gate Verdict**: [CLEAN | DISPOSED]

    ## Gate Findings & Dispositions
    | Reviewer | Finding | Severity | Disposition | Recorded In |
    |----------|---------|----------|-------------|-------------|
    | contract-completeness | [gap] | HIGH | Deferred/Dismissed/Override | future.md / decisions.md |
    | contract-freezability | [gap] | HIGH | ... | ... |

    ## HIGH gaps promoted past (knowing overrides)
    [list, or "none"]
    ```

20. **Update state file**: status = COMPLETE; record the promotion in the round record + state history (`Round [N] (Promote) complete — froze round-[R]-review; gate [CLEAN | disposed]`).

21. **Report** to the user: the freeze is complete; the three published documents are current; `round-[N]-promote/` holds the record. If any HIGH was promoted past, name it and where it was recorded.

---

## Stopping Points

**Automatic flow (do NOT pause for human confirmation):**
- Step 1 → 2 → 3 → 4: proceed automatically **unless** the gate (Step 2) HALTs.

**Human checkpoints (orchestrator handles these directly):**
- **Step 2 (gate)** — if EITHER reviewer returns a HIGH finding: WAITING_FOR_HUMAN. Every HIGH gets a recorded disposition (Resolved → log to `pending-issues.md` + HALT for a Review round; Deferred → `future.md`; Dismissed / Override → `decisions.md`) before the promoter runs.

Do NOT ask "Should I proceed?" between automatic steps. Only stop at the gate checkpoint above.

---

## Exit Criteria

Promote exits by **freezing**: the gate passes clean (or every HIGH is disposed/overridden), the promoter produces the three published documents, and the `round-[N]-promote` record captures the freeze. On a **Resolved** disposition the workflow instead HALTs and routes back to Review via `pending-issues.md` — the freeze happens on a subsequent Promote round after Review re-runs.

---

## Error Handling

| Condition | Action |
|-----------|--------|
| No state file | Error: "No state file found. Promote requires a completed Review round; run Create → Review first." |
| Last completed round was not Review | Error: "Promote requires a completed Review round; last round was {type}." |
| `Status: not COMPLETE` + other workflow in progress | Error: "Cannot start Promote: {Current Workflow} workflow still in progress" |
| Reviewed document not found | Error: "Review round [R] completed but no reviewed document found." |
| Gate reviewer fails | Error: Report which reviewer failed; do not proceed to the promoter |
| Promoter fails | Error: Report failure details; do not mark COMPLETE |
| Published output file missing after promote | Error: "Promoter completed but output not found at [path]" |

---

<!-- INJECT: tool-restrictions -->
