# PRD Promote Orchestrator

---

## Purpose

The split. Runs **after a Review round completes**; snapshots the reviewed PRD, then promotes it — splitting into `prd.md` / `decisions.md` / `future.md` — and records the promotion as a versioned `round-N-promote` round.

Because the promoter is the **sole producer of `prd.md`** and Promote is the only workflow that runs it, this sits on the **only road** to a promoted PRD. Promote splits the reviewed PRD, then runs a **blocking document-conservation gate** that can **HALT** before the split documents are published — so the split is no longer an unconditional split-and-record. The PRD has no downstream contract registry, so there is still **no freeze gate, materialization, or fidelity check (those are 04-only)**; the conservation gate is a verbatim-conservation check on the split, **not** a freeze/materialization gate.

**Flow:** Review (completes) → **Promote** [guard → split → conservation-gate → publish → record] → done.

---

## Workflow State Management

**State file**: `system-design/02-prd/versions/workflow-state.md`

### On Start/Resume

1. **Check if state file exists**:
   - **If NO**: Error — "No state file found. Promote requires a completed Review round; run Create → Review first."
   - **If YES**: Read the state file. The action depends on `Status` and `Current Workflow`:
     - **`Status: COMPLETE`** (a workflow just finished — regardless of `Current Workflow`): a Promote round is starting. **Apply the review-mandatory guard first, before mutating state** (this avoids stranding the stage in `Promote`/`IN_PROGRESS` on a guard failure):
       - Read the state file history to identify the **last completed round** — its number (`R`) and type.
       - **If the last completed round was Review** → Set `Current Workflow: Promote`, initialize the next sequential round number (globally numbered — see unified `versions/` folder convention), set `Status: IN_PROGRESS`, preserve history. Then proceed to **Step 1 (Guard & Snapshot)**.
       - **If the last completed round was anything else** (`create`, `expand`, …) → **Error and stop, WITHOUT mutating the state file** — `Promote requires a completed Review round; last round was {type}. Run a Review round before promoting.` Leaving `Status: COMPLETE` and `Current Workflow` untouched means the stage is not stranded: the human can run Review (which starts a fresh round from `Status: COMPLETE`).
     - **`Status: not COMPLETE`** and **`Current Workflow: Promote`**: Resume from the current step.
     - **`Status: not COMPLETE`** and **`Current Workflow`** is anything else: Error — `Cannot start Promote: {Current Workflow} workflow still in progress`.

2. **Update state file** at each step transition.

### State File Format

```markdown
# PRD Workflow State

**Blueprint**: 01-blueprint/blueprint.md
**PRD**: 02-prd/prd.md
**Current Workflow**: Promote
**Current Round**: [N]
**Status**: IN_PROGRESS | WAITING_FOR_HUMAN | COMPLETE

## Progress

### Round [N] (Promote)
- [ ] Step 1: Guard & Snapshot
- [ ] Step 2: Promote (split)
- [ ] Step 2a: Document-conservation gate
- [ ] Step 3: Finalise

## History
- YYYY-MM-DD HH:MM: Round [N] (Promote) started — splitting round-[R]-review
```

---

## Fixed Paths

**Output directory**: `system-design/02-prd/versions`
**State file**: `system-design/02-prd/versions/workflow-state.md`
**Working record**: `system-design/02-prd/versions/round-[N]-promote/`

**Published outputs** (the promoter writes the round-folder originals at Step 2; the orchestrator PUBLISHES them to these live parent paths at Step 2a, only after the conservation gate returns CLEAN):
- `system-design/02-prd/prd.md` — Clean current-scope PRD
- `system-design/02-prd/decisions.md` — Product decision rationale and trade-offs
- `system-design/02-prd/future.md` — Deferred features and future considerations

**Output-location principle:** the `round-[N]-promote/` record is the working history — **nothing reads it cross-stage**. Downstream stages read only the stable published copies (`prd.md` / `decisions.md` / `future.md`).

---

## Prompt Locations

```
agents/02-prd/promote/
├── orchestrator.md                     # This file
└── promoter.md                         # Splits the reviewed PRD into prd/decisions/future round-folder originals

Universal agents (in {{AGENTS_PATH}}/universal-agents/):
└── document-conservation-checker.md    # Step 2a: document split conservation gate (verbatim §5/§8/§9 + cross-refs gate; prose/decisions/future advisory) — invoked with 02's Verbatim-critical sections list
```

---

## Output Directory Structure

```
system-design/02-prd/
├── prd.md                         # Clean current-scope (PUBLISHED here at Step 2a, after conservation CLEAN)
├── decisions.md                   # Product decision rationale (published here at Step 2a)
├── future.md                      # Deferred features (published here at Step 2a)
└── versions/
    ├── workflow-state.md
    ├── round-[R]-review/              # The review round being split (input source)
    │   └── 05-updated-prd.md              # (or 00-prd.md on the zero-issues path)
    ├── round-[N]-promote/             # This promote round's working record
    │   ├── 00-prd.md                     # Input snapshot = the reviewed doc being split
    │   ├── prd.md                        # Promoted PRD original (published to parent after CLEAN)
    │   ├── decisions.md                  # Promoted decisions original (published after CLEAN)
    │   ├── future.md                     # Promoted future original (published after CLEAN)
    │   ├── conservation.md               # Step 2a document-conservation report + verdict
    │   └── promote-metadata.md           # date, source review round, input file used, gate verdict
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
- You SPAWN agents to do work (the promoter; and the Document-Conservation Checker at Step 2a)
- You SPAWN the Document-Conservation Checker (Step 2a, FOREGROUND) and — only after its verdict is CLEAN — PUBLISH the round-folder originals to the live `prd.md`/`decisions.md`/`future.md` paths via `cp`. This publish is the single writer of those live paths.
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

The **review-mandatory guard runs at On Start** (guard-first — before any state mutation), so a Promote mis-pointed at an unreviewed create/expand draft **errors without mutating the state file** (no stranding in `Promote`/`IN_PROGRESS`). By Step 1 the last completed round is confirmed **Review**; Step 1 snapshots that reviewed input.

1. **Update state file**: Set Step 1, status = IN_PROGRESS.

2. **Identify the last completed round** from the state file history: its number (`R`) and type.

3. **Guard already applied at On Start** — the last completed round was confirmed **Review** there (guard-first), so no re-assertion or error path is needed here; proceed. (Running the guard at On Start *without mutating state on failure* is what keeps a mis-pointed Promote from stranding the stage in `Promote`/`IN_PROGRESS`.)

4. **Determine the input document** (the reviewed doc to split):
   - `system-design/02-prd/versions/round-[R]-review/05-updated-prd.md` (the Author ran that round), **else**
   - `system-design/02-prd/versions/round-[R]-review/00-prd.md` (the zero-issues path — no Author ran).
   - If neither exists → **Error and stop**: "Review round [R] completed but no reviewed document found."

5. **Create the promote round record and snapshot the input**:
   - Create `system-design/02-prd/versions/round-[N]-promote/`
   - Copy the input document to `round-[N]-promote/00-prd.md` (the input snapshot = the reviewed doc being split). **All promote steps below work from this snapshot.**

6. **Update state file**: Mark Step 1 complete.

7. **Automatically proceed to Step 2.**

---

### Step 2: Promote (split)

8. **Update state file**: Set Step 2, status = IN_PROGRESS.

9. **Spawn PRD Promoter** (FOREGROUND):
    ```
    Follow the instructions in: {{AGENTS_PATH}}/02-prd/promote/promoter.md

    Input:
    - Reviewed PRD: system-design/02-prd/versions/round-[N]-promote/00-prd.md
    - PRD guide: {{GUIDES_PATH}}/02-prd-guide.md

    Output:
    - system-design/02-prd/versions/round-[N]-promote/prd.md
    - system-design/02-prd/versions/round-[N]-promote/decisions.md
    - system-design/02-prd/versions/round-[N]-promote/future.md
    ```
    The promoter writes these round-folder originals; the live `prd.md`/`decisions.md`/`future.md` paths are published by Step 2a after the conservation gate returns CLEAN.

10. **Update state file**: Mark Step 2 complete.

11. **Automatically proceed to Step 2a.**

---

### Step 2a: Document-conservation gate (new)

**Ordering invariant:** the Step-2a publish (below) is the single writer of the live `prd.md`/`decisions.md`/`future.md` paths; nothing between Step 2 (split to the round folder) and this publish reads them. The published PRD is what downstream stages consume, so it must be conservation-verified before it becomes that authority.

- **Update state file**: Set Step 2a, status = IN_PROGRESS.

- **Spawn the Document-Conservation Checker** (universal agent, FOREGROUND):
  ```
  Follow the instructions in: {{AGENTS_PATH}}/universal-agents/document-conservation-checker.md

  Input:
  - Reviewed source (pre-split): system-design/02-prd/versions/round-[N]-promote/00-prd.md
  - Split outputs (round-folder originals): system-design/02-prd/versions/round-[N]-promote/prd.md, decisions.md, future.md
  - Stage guide: {{GUIDES_PATH}}/02-prd-guide.md
  - Promoter separation criteria (the split rulebook — used only by the advisory checks to recognise legitimate transformations): {{AGENTS_PATH}}/02-prd/promote/promoter.md
  - Verbatim-critical sections: §5 Conceptual Data Model, §8 Integration Points, §9 Compliance and Constraints

  Output: system-design/02-prd/versions/round-[N]-promote/conservation.md
  ```

- **Gate on the verdict:**
  - **`MISMATCH`** → **HALT (promote-local):** `Status: WAITING_FOR_HUMAN`; present the conservation report. Disposition: a genuine content drop/distortion in §5/§8/§9 (or a dangling cross-reference) → re-run the promoter (Step 2); or an explicit human accept/override recorded to `decisions.md`. Do **NOT** publish the docs.
  - **`CLEAN`** → proceed to publish (below). Advisory findings are recorded (non-gating). **Also read the checker's `placement_smells` count** (from its return JSON / `round-[N]-promote/conservation.md`) and carry it forward to the Step-3 Finalise report. This is informational only — it never gates, HALTs, or changes the CLEAN publish path.
  - **missing / no verdict** → **treat as blocking** (never clean): `Document-conservation check produced no verdict — re-run Step 2a.`

- **Publish the documents** (single doc-publish point — ONLY after CLEAN), via `cp`:
  - `system-design/02-prd/versions/round-[N]-promote/prd.md` → `system-design/02-prd/prd.md`
  - `system-design/02-prd/versions/round-[N]-promote/decisions.md` → `system-design/02-prd/decisions.md`
  - `system-design/02-prd/versions/round-[N]-promote/future.md` → `system-design/02-prd/future.md`
  - Verify all three published files now exist; if any copy failed → **Error**, do not proceed.

- **Update state file**: Mark Step 2a complete; **automatically proceed to Step 3.**

---

### Step 3: Finalise

12. **Update state file**: Set Step 3, status = IN_PROGRESS.

13. **Verify the three published documents exist** (before finalising — published at Step 2a and conservation-verified: §5/§8/§9 byte-identical to the reviewed PRD):
    - `system-design/02-prd/prd.md`
    - `system-design/02-prd/decisions.md`
    - `system-design/02-prd/future.md`
    - If any is missing → **Error**: "Promoter completed but output not found at [path]" — do **not** mark COMPLETE.

14. **Write `round-[N]-promote/promote-metadata.md`** (the promote record):
    ```markdown
    # Promote Round [N]

    **Date**: [date]
    **Source Review Round**: round-[R]-review
    **Input File Used**: [05-updated-prd.md | 00-prd.md]
    **Conservation Gate Verdict**: [CLEAN | MISMATCH-disposed]
    ```

15. **Update state file**: status = COMPLETE; record the promotion in the round record + state history (`Round [N] (Promote) complete — split round-[R]-review; conservation gate [CLEAN | disposed]`).

16. **Report** to the user: the split is complete; the three published documents (`prd.md`, `decisions.md`, `future.md`) are current (conservation-verified) and `round-[N]-promote/` holds the record (incl. the conservation report).
    - **Placement-smell notice (informational only — from the Step-2a `placement_smells` count):** **if `placement_smells > 0`**, append exactly ONE non-blocking line to this report: *Note: [N] placement smell(s) flagged — current-scope content routed to `decisions`/`future` that may belong in the clean spec. Non-blocking (the split published); review `round-[N]-promote/conservation.md` if you want to correct placement in a follow-up.* **If `placement_smells` is 0, say nothing.** This is informational only — **never HALT, wait, or ask a decision** on it, and it does not add a step.

---

## Stopping Points

**Automatic flow (do NOT pause for human confirmation):** Step 1 → 2 → 2a → 3 proceed automatically **unless** the document-conservation gate (Step 2a) returns `MISMATCH`.

**Human checkpoint (orchestrator handles it directly):**
- **Step 2a (conservation)** — if the conservation check returns `MISMATCH`: set `Status: WAITING_FOR_HUMAN`, **HALT promote-local** (re-run the promoter at Step 2, or an explicit human accept/override recorded to `decisions.md`). The docs are **not** published until the check is CLEAN.

Otherwise Promote guards, splits, conservation-checks, publishes, and records without pausing. Do NOT ask "Should I proceed?" between the automatic steps.

---

## Exit Criteria

Promote exits by **splitting**: the review-mandatory guard passes, the promoter writes the three documents to the round folder, the document-conservation gate (Step 2a) returns `CLEAN`, the orchestrator publishes the three documents to the live `prd.md`/`decisions.md`/`future.md` paths, and the `round-[N]-promote` record captures the promotion (incl. the gate verdict). On a Step-2a `MISMATCH` the workflow HALTs promote-local (re-run the promoter, or human-accept) — the docs are not published until conservation is CLEAN. If the last completed round was not Review, the workflow errors at Step 1 and does not split.

---

## Error Handling

| Condition | Action |
|-----------|--------|
| No state file | Error: "No state file found. Promote requires a completed Review round; run Create → Review first." |
| Last completed round was not Review | Error: "Promote requires a completed Review round; last round was {type}." |
| `Status: not COMPLETE` + other workflow in progress | Error: "Cannot start Promote: {Current Workflow} workflow still in progress" |
| Reviewed document not found | Error: "Review round [R] completed but no reviewed document found." |
| Promoter fails | Error: Report failure details; do not mark COMPLETE |
| Document-conservation check returns `MISMATCH` (Step 2a) | HALT promote-local: WAITING_FOR_HUMAN — re-run the promoter (Step 2) or human-accept; do NOT publish the docs |
| Document-conservation check produces no verdict | Error: treat as blocking, re-run Step 2a |
| Published doc missing after Step-2a publish | Error: do not proceed; do not mark COMPLETE |
| Published output file missing after promote | Error: "Promoter completed but output not found at [path]" |

---

<!-- INJECT: tool-restrictions -->
