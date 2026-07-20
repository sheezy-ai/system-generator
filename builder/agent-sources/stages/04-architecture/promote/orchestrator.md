# Architecture Overview Promote Orchestrator

---

## Purpose

The single freeze. Runs **after a Review round completes**; gate-checks the reviewed Architecture Overview (contract completeness + freezability) as the hard, unavoidable backstop, then promotes it — splitting into `architecture.md` / `decisions.md` / `future.md` — **materializes the frozen contract registry (`05-components/specs/cross-cutting.md`) from §7/§8 + PRD §5 and fidelity-checks it**, and records the promotion as a versioned `round-N-promote` round. **Promote produces the complete + freezable + materialized + fidelity-verified contract authority in one act** — closing the 04/05 seam. 05-init then only *consumes* the frozen registry.

Because the promoter is the **sole producer of `architecture.md`** and Promote is the only workflow that runs it, this gate sits on the **only road** to a promoted Architecture Overview. It is a single gate enforcing both freeze axes — §8 is **complete** AND **freezable** — before §8 becomes the authority.

**Flow:** Review (completes) → **Promote** [guard → gate → split → materialize → fidelity → record] → frozen.

**Materialization + fidelity now run here** (relocated from 05-init in Slice 4), so the freeze is complete in one act. Because Promote runs on **every** promote — including re-promotes (backward-edge fixes, `expand → review → promote`) — materialization is a **status-preserving MERGE** on a re-freeze (it never clobbers the 05-owned conformance status on the co-owned registry). **Still not in Promote:** the review experts themselves (per-round detection stays in Review). Promote only **re-runs** the two review experts as the unavoidable final verification, then promotes, materializes, and fidelity-checks.

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
- [ ] Step 3a: Document-conservation gate
- [ ] Step 3b: Materialize the contract registry
- [ ] Step 3c: Materialization-fidelity check
- [ ] Step 4: Finalise (publish registry)
- [ ] Step 4b: Write-direction re-verify flag (MERGE only)
- [ ] Step 4c: Record the freeze & mark complete

## History
- YYYY-MM-DD HH:MM: Round [N] (Promote) started — freezing round-[R]-review
```

---

## Fixed Paths

**Output directory**: `system-design/04-architecture/versions`
**State file**: `system-design/04-architecture/versions/workflow-state.md`
**Working record**: `system-design/04-architecture/versions/round-[N]-promote/`

**Published outputs** (the promoter writes the round-folder originals at Step 3; the orchestrator PUBLISHES them to the parent folder at Step 3a, only after the conservation gate returns CLEAN):
- `system-design/04-architecture/architecture.md` — Clean current-scope Architecture Overview
- `system-design/04-architecture/decisions.md` — Design rationale and trade-offs
- `system-design/04-architecture/future.md` — Deferred items and future considerations

**Output-location principle:** the `round-[N]-promote/` record is the working history — **nothing reads it cross-stage**. Downstream stages read only the stable published copies (`architecture.md` / `decisions.md` / `future.md`).

---

## Prompt Locations

```
agents/04-architecture/promote/
├── orchestrator.md                     # This file
├── promoter.md                         # Splits the reviewed Architecture into spec/decisions/future
├── document-conservation-checker.md    # Step 3a: document split conservation gate (verbatim §6/§8/§7 + cross-refs gate; prose/decisions/future advisory)
├── contract-materializer.md            # Step 3b: materialize the registry (FIRST_FREEZE | MERGE) — relocated here in Slice 5
└── materialization-fidelity-checker.md # Step 3c: fidelity gate — relocated here in Slice 5

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
├── architecture.md                # Clean current-scope (PUBLISHED here from the round folder at Step 3a, after conservation CLEAN)
├── decisions.md                   # Design rationale (PUBLISHED here from the round folder at Step 3a, after conservation CLEAN)
├── future.md                      # Deferred items (PUBLISHED here from the round folder at Step 3a, after conservation CLEAN)
└── versions/
    ├── workflow-state.md
    ├── round-[R]-review/              # The review round being frozen (input source)
    │   └── 05-updated-architecture.md
    ├── round-[N]-promote/             # This promote round's working record
    │   ├── 00-architecture.md             # Input snapshot = the reviewed doc being frozen
    │   ├── 00-prior-published-architecture.md # Prior published architecture.md, captured in Step 1 BEFORE Step 3a publishes over it (MERGE baseline; absent on the very first freeze)
    │   ├── 11-contract-completeness-gate.md   # Gate re-run (completeness)
    │   ├── 12-contract-freezability-gate.md   # Gate re-run (freezability)
    │   ├── architecture.md                # The promoted spec ORIGINAL (Step 3 writes here first; published to the parent at Step 3a after conservation CLEAN)
    │   ├── decisions.md                   # The promoted decisions ORIGINAL (Step 3 writes here first; published to the parent at Step 3a after conservation CLEAN)
    │   ├── future.md                      # The promoted future ORIGINAL (Step 3 writes here first; published to the parent at Step 3a after conservation CLEAN)
    │   ├── conservation.md                # Step 3a conservation report (round-folder record) — verdict gates the doc-publish
    │   ├── cross-cutting.md               # The materialized registry ORIGINAL (Step 3b writes here; published to 05-specs at Step 4 after fidelity CLEAN)
    │   ├── materialization.md             # The materialization report ORIGINAL (Step 3b) — round-folder record only
    │   ├── materialization-fidelity.md    # The fidelity report ORIGINAL (Step 3c) — round-folder record only
    │   └── promote-metadata.md            # date, source review round, gate verdict, HIGH gaps promoted past, contracts/bindings/escalations, fidelity verdict, MERGE changed/reset/preserved counts
    └── pending-issues.md

# The registry is PUBLISHED (copied from the round-folder original above) to 05 — ONLY after fidelity returns CLEAN
# (produced by Promote, consumed by 05-init):
#   system-design/05-components/specs/cross-cutting.md
# The two freeze reports (materialization.md, materialization-fidelity.md) live ONLY in the round folder above —
# no live 05 agent reads them (the fidelity gate now lives at Promote).
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
   - **Capture the Track A merge baseline (new, load-bearing for the re-freeze MERGE):** **before** anything overwrites the published file, snapshot the **current published** `system-design/04-architecture/architecture.md` into `round-[N]-promote/00-prior-published-architecture.md` — **if it exists** (`cp` only when present; on the very first freeze there is no published `architecture.md` yet, and that is the FIRST_FREEZE case). This is the **prior-freeze §8/§7 source** the Step-3b MERGE diffs each contract against (Track A). It is guaranteed present whenever the 05 registry is status-bearing (05 ran against a published `architecture.md`). Using the **published `architecture.md`** — not a prior promote-stage snapshot (which an old project promoted under the pre-Slice-4 design does not have) — is what prevents a clock-reset clobber on the very first Slice-4 re-promote. **Do not** confuse this with `00-architecture.md`: that is the *incoming* reviewed doc about to be frozen; this is the *outgoing* prior authority being diffed against.

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
   - **Note (honest — do not overstate this):** both are the **same** reviewers re-run, not second independent detectors. This buys **unavoidability** — it catches a HIGH gap (a missing contract, or an un-freezable one) that a Step 11 maturity-override or the zero-issues auto-gate would otherwise carry straight into promotion. It does **not** add independent detection or defence-in-depth; the detection already happened (or was skipped) at Review Step 1. The freezability re-run also guarantees the un-freezable contract is caught **here, before freeze**, rather than escalating from the materializer at Promote Step 3b.

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
    - Freeze token: round-[N]-promote   (stamp into architecture.md's header as **Frozen-At** — the whole-registry freeze identity; must match the token passed to the materializer at Step 3b)

    Output:
    - system-design/04-architecture/versions/round-[N]-promote/architecture.md
    - system-design/04-architecture/versions/round-[N]-promote/decisions.md
    - system-design/04-architecture/versions/round-[N]-promote/future.md
    ```

14. **Update state file**: Mark Step 3 complete.

15. **Automatically proceed to Step 3a.**

---

### Step 3a: Document-conservation gate (new)

**Ordering invariant:** Step 3a's publish (below) MUST complete before Step 3b (materialize) runs, because the materializer reads the **live parent** `architecture.md`. The published `architecture.md` carries the promoter's `Frozen-At: round-[N]-promote`, which must still match the registry token the materializer stamps.

- **Update state file**: Set Step 3a, status = IN_PROGRESS.

- **Spawn the Document-Conservation Checker** (FOREGROUND):
  ```
  Follow the instructions in: {{AGENTS_PATH}}/04-architecture/promote/document-conservation-checker.md

  Input:
  - Reviewed source (pre-split): system-design/04-architecture/versions/round-[N]-promote/00-architecture.md
  - Split outputs (round-folder originals): system-design/04-architecture/versions/round-[N]-promote/architecture.md, decisions.md, future.md
  - Architecture guide: {{GUIDES_PATH}}/04-architecture-guide.md
  - Promoter separation criteria (the split rulebook — used only by the advisory checks to recognise legitimate transformations): {{AGENTS_PATH}}/04-architecture/promote/promoter.md

  Output: system-design/04-architecture/versions/round-[N]-promote/conservation.md
  ```

- **Gate on the verdict:**
  - **`MISMATCH`** → **HALT (promote-local):** status = WAITING_FOR_HUMAN; present the conservation report. Disposition: a genuine content drop/distortion → re-run the promoter (Step 3); or an explicit human accept/override recorded to `decisions.md`. Do **NOT** publish the docs.
  - **`CLEAN`** → proceed to publish (below). Advisory findings are recorded (non-gating).
  - **missing / no verdict** → **treat as blocking** (never clean): `Document-conservation check produced no verdict — re-run Step 3a.`

- **Publish the documents** (single doc-publish point — ONLY after CLEAN), via `cp`:
  - `round-[N]-promote/architecture.md` → `system-design/04-architecture/architecture.md`
  - `round-[N]-promote/decisions.md` → `system-design/04-architecture/decisions.md`
  - `round-[N]-promote/future.md` → `system-design/04-architecture/future.md`
  - Verify all three published files now exist; if any copy failed → **Error**, do not proceed.

- **Update state file**: Mark Step 3a complete; **automatically proceed to Step 3b.**

---

### Step 3b: Materialize the contract registry (new — the relocated freeze)

**Ordering (do not reorder):** materialize runs **after** the split (Step 3) and the document-conservation publish (Step 3a) because the materializer reads the live-parent `architecture.md` — now freshly published by Step 3a and **conservation-verified** (§6/§8/§7-interface confirmed byte-identical to the reviewed source), so it is a trusted authority for materialization. It is the **same input path 05-init read before Slice 4**, so first-freeze output is behaviourally equivalent to the old 05-init result (the materializer is an LLM agent — *semantic* equivalence: same contracts / Binds / obligations / verdict, not a byte-diff). A mid-freeze HALT corrupts nothing new: this promote round's `Status` only becomes `COMPLETE` at Step 4 (Finalise), and under the round-first write-order (§Step 3b/3c/4) the registry is **not published to `05-specs` until Step 4, after fidelity returns CLEAN** — so a HALT at 3b/3c leaves the **prior** `05-specs` registry intact and this round non-`COMPLETE`. **There is no mechanical guard** stopping 05-init from running against that prior (still-`MATERIALIZED`) registry during a HALT: 05-init is immediate-execution, gated only by its registry precondition, and never reads promote state. The protection is **human sequencing** — the human driving the stage sees the promote HALT and does not run 05-init until the freeze completes. Protocol, not a state-machine gate.

16. **Update state file**: Set Step 3b, status = IN_PROGRESS.

17. **Ensure the 05 registry target exists** (05-init no longer creates it). Using `Bash mkdir -p` and `Write`:
    - `mkdir -p system-design/05-components/specs/`
    - `mkdir -p system-design/05-components/versions/cross-cutting/`
    - **First-freeze only** (the file does not yet exist): create the placeholder `system-design/05-components/specs/cross-cutting.md` with:
      ```markdown
      # Cross-Cutting Specification

      ## Status

      **Population**: MATERIALIZING
      ```
    - If `specs/cross-cutting.md` already exists, **do not** overwrite it here — on MERGE the materializer reads its live status for the preserve-vs-reset decision, but writes the new registry to the **round folder** (Step 4 publishes it to `05-specs` after fidelity CLEAN).

18. **Select the materialize mode** by inspecting the live registry `system-design/05-components/specs/cross-cutting.md`:
    - **No status-bearing registry** — no registry file, the placeholder just created, or every contract entry carries `Status: MATERIALIZED` → **FIRST_FREEZE** (clean overwrite, all `MATERIALIZED` — the materializer's existing behaviour, behaviourally equivalent to old 05-init).
    - **Legacy `POPULATED` / `DEFERRED` registry** (pre-materialization, body-extracted obligations — possible on an old project until Slice 5) → **FIRST_FREEZE too:** legacy obligations were keyed on extracted bodies, not §8, so their status is not a valid baseline for the §8-materialized model — re-materialize clean.
    - **Registry carries any `DEFINED` / `VERIFIED`** under the materialized model → **MERGE** (status-preserving), passing the Step-1 prior-published snapshot as the Track A baseline. If that snapshot is absent (no prior published `architecture.md`), fall back to **FIRST_FREEZE** (there is nothing to diff against).

19. **Spawn the Contract Materializer** (FOREGROUND) reading the just-promoted parent `architecture.md`, passing the selected mode and (for MERGE) the baseline path:
    ```
    Follow the instructions in: {{AGENTS_PATH}}/04-architecture/promote/contract-materializer.md

    Input:
    - Architecture Overview (incoming, just promoted): system-design/04-architecture/architecture.md
    - PRD: system-design/02-prd/prd.md
    - Cross-cutting registry (live 05-specs — read for status only, on MERGE): system-design/05-components/specs/cross-cutting.md
    - Architecture pending-issues: system-design/04-architecture/versions/pending-issues.md
    - Mode: [FIRST_FREEZE | MERGE]
    - Prior-freeze baseline (MERGE only): system-design/04-architecture/versions/round-[N]-promote/00-prior-published-architecture.md
    - Freeze-Token: round-[N]-promote   (stamp into the registry Status block as **Frozen-At** — the whole-registry freeze identity; MUST be the same token passed to the promoter at Step 3, both modes)

    Output:
    - Registry ORIGINAL (round folder): system-design/04-architecture/versions/round-[N]-promote/cross-cutting.md
    - Materialization report: system-design/04-architecture/versions/round-[N]-promote/materialization.md
    ```

20. **After the materializer completes**: verify the round-folder registry original (`round-[N]-promote/cross-cutting.md`) `Status` block (`Population: MATERIALIZED`) and read the materialization report (`round-[N]-promote/materialization.md`). If the materializer escalated any under-pinned **(D)** contract (it appends to `04 pending-issues` itself): **HALT — route back via the backward edge** (same disposition as the Step 2 gate's "Resolved": log/confirm the escalation in `pending-issues.md`, set status = WAITING_FOR_HUMAN, and HALT with `Materializer escalated an under-pinned (D) contract — re-run the Review workflow to pin it, then re-run Promote.`). Note the anomaly — the Step-2 freezability reviewer should already have caught it; this is rare by construction. Otherwise mark Step 3b complete and **automatically proceed to Step 3c.**

---

### Step 3c: Materialization-fidelity check (new — the relocated gate)

21. **Update state file**: Set Step 3c, status = IN_PROGRESS.

22. **Spawn the Materialization-Fidelity Checker** (FOREGROUND). **Do NOT** pass the materialization report — independence requires re-deriving from authority:
    ```
    Follow the instructions in: {{AGENTS_PATH}}/04-architecture/promote/materialization-fidelity-checker.md

    Input:
    - Architecture Overview: system-design/04-architecture/architecture.md
    - PRD: system-design/02-prd/prd.md
    - Materialized registry (round-folder original — not yet published): system-design/04-architecture/versions/round-[N]-promote/cross-cutting.md

    Output:
    - Fidelity report: system-design/04-architecture/versions/round-[N]-promote/materialization-fidelity.md
    ```
    **Gate on the verdict** (semantics identical to the old 05-init gate):
    - **`MISMATCH`** → **HALT (promote-local).** A load-bearing discrepancy between the registry and Architecture §7/§8 would poison every consumer. Set status = WAITING_FOR_HUMAN; present the fidelity report; the fix is **re-materialize (re-run Step 3b) or an explicit human accept** — **not** a backward-to-Review round (this is a projection fault, not an architecture gap).
    - **`CLEAN`** → proceed to Step 4.
    - **missing / no verdict** → **treat as blocking** (never as clean): `Materialization-fidelity check did not produce a verdict — re-run Step 3c.`

23. **Update state file**: Mark Step 3c complete; **automatically proceed to Step 4.**

---

### Step 4: Finalise

24. **Update state file**: Set Step 4, status = IN_PROGRESS.

25. **Verify the freeze originals exist** (before publishing):
    - The three published documents: `system-design/04-architecture/architecture.md`, `decisions.md`, `future.md`.
    - The round-folder registry original: `round-[N]-promote/cross-cutting.md` exists with a valid `Population` status (`MATERIALIZED`).
    - The two round-folder freeze reports: `round-[N]-promote/materialization.md` and `round-[N]-promote/materialization-fidelity.md` (verdict `CLEAN` — a `MISMATCH` would have HALTed at Step 3c).
    - If any is missing → **Error**: "Promoter/freeze completed but output not found at [path]" — do **not** publish, do **not** mark COMPLETE.

26. **Publish the registry to 05 — ONLY now, after fidelity CLEAN** (`cp`): copy `round-[N]-promote/cross-cutting.md` → `system-design/05-components/specs/cross-cutting.md`. This is the **single publish point** — the round-folder original is the source of truth; `05-specs` receives the fidelity-verified copy that 05-init consumes. A Step-3c `MISMATCH` HALTs *before* reaching here, so an unverified registry is **never** published and the prior `05-specs` registry (if any) stays intact. The two freeze reports (`materialization.md`, `materialization-fidelity.md`) remain **round-folder records only** — no live 05 agent reads them. Verify `system-design/05-components/specs/cross-cutting.md` now exists with `Population: MATERIALIZED` after the copy; if the copy failed → **Error**, do **not** mark COMPLETE.

---

### Step 4b: Write-direction re-verify flag (MERGE only)

**MERGE only — SKIP this entire step on FIRST_FREEZE** (nothing was previously verified on a first freeze, so there is nothing to re-verify — record "N/A (FIRST_FREEZE)" in the state history and go straight to Step 4c). Runs **after** the registry is published (item 26 above) so producers + patterns are read from the final registry.

This step keeps the materializer a **pure projector** — the **orchestrator** (not the materializer) writes the durable re-verify flags. It makes the write-direction re-verify need **prominent** in each producer's own `pending-issues.md`, rather than merely implicit in a reset-to-`DEFINED` status.

**Update state file**: Set Step 4b, status = IN_PROGRESS.

**Inputs (the published registry alone cannot substitute — a contract can be `DEFINED` without having *changed this freeze*):**
- **Changed-set** — from `round-[N]-promote/materialization.md`, the `## MERGE Status Decisions` table: the CTRs whose `Changed?` column is **CHANGED** (Track A §8/§7 or Track B PRD §5 fired). These are the only contracts that changed *this* round; the reset-to-`DEFINED` status is **not** the changed-set.
- **Pattern + Producer(s)** — for each changed CTR, read from the published registry (`system-design/05-components/specs/cross-cutting.md`).

**For each CHANGED contract whose Pattern is `write-direction`:**
- For **each** of its **Producer(s)** — a write-direction contract may carry 2+ producers in some projects, so **flag every one; do NOT assume a single producer**:
  - If `system-design/05-components/versions/[producer]/` does **not** exist (e.g. a component **newly added to §6 in this same re-freeze**), **`mkdir -p`** it and create an empty `pending-issues.md` stub first.
  - Append a durable re-verify entry to `system-design/05-components/versions/[producer]/pending-issues.md` using the **lateral shape** (`{{GUIDES_PATH}}/pending-issues-format.md`): `Kind: CROSS-BOUNDARY-PEER`, `Status: UNRESOLVED`, `Severity: HIGH`, `Target: [producer]`, `Source: Architecture Promote re-freeze, round-[N]-promote`. Body: *"CTR-NNN's write-direction obligation changed at re-freeze `round-[N]-promote` — re-verify the producer's conformance to the new obligation."* The producer's next **review** consumes it (`{{AGENTS_PATH}}/05-components/review/orchestrator-pre-discussion.md`, Step 0 pending-issues read), so the need is durable + prominent, not merely inferable from a `DEFINED` status.

**Composed-query / invariant contracts — NO flag.** Their re-verify rests **entirely on coherence being run as the stage-close gate**: `{{AGENTS_PATH}}/05-components/coherence/orchestrator.md` Phase 4 re-verifies *all* contracts wholesale when run, and it is **human-invoked**. This is a **known, deliberate reliance** stated here — not a silent gap. **Honest caveat:** coherence's producer-schema-vs-consumer-input method *iterates* every contract but verifies multi-/interface-producer composed-query contracts only **weakly** — "covered by coherence" means *iterated*, not rigorously verified (pre-existing, not a Slice-6 defect; rigorous ownerless verification is deferred-subsystem work).

**Known consumption gap (do NOT silently rely on create-time pickup):** the create workflow does **not** consume `pending-issues.md` (`{{GUIDES_PATH}}/pending-issues-format.md` states plainly: "create does not read `pending-issues.md`" — a component authors inside-out from upstream docs; cross-component reconciliation happens at **review**). So for a **newly-added producer** (created before its first review), the flag is consumed at that producer's **first review**, not at create. Because Create → Review always precedes stage sign-off, the flag is **durable and eventually consumed, not lost** — but there is no create-time consumption. (04→05 write ownership: promote writing a 05 producer pending-issue is accepted and named — consistent with promote already publishing the 05 registry; this is a lightweight flag, not the full verifier, which is the deferred L2 piece.)

**Update state file**: Mark Step 4b complete (record the flagged producers + CTRs, or "N/A (FIRST_FREEZE)"). **Automatically proceed to Step 4c.**

---

### Step 4c: Record the freeze & mark complete

27. **Write `round-[N]-promote/promote-metadata.md`** (the freeze record):
    ```markdown
    # Promote Round [N]

    **Date**: [date]
    **Source Review Round**: round-[R]-review (input: [05-updated-architecture.md | 00-architecture.md])
    **Gate Verdict**: [CLEAN | DISPOSED]
    **Materialize Mode**: [FIRST_FREEZE | MERGE]
    **Fidelity Verdict**: [CLEAN | (a MISMATCH would have HALTed before here)]

    ## Gate Findings & Dispositions
    | Reviewer | Finding | Severity | Disposition | Recorded In |
    |----------|---------|----------|-------------|-------------|
    | contract-completeness | [gap] | HIGH | Deferred/Dismissed/Override | future.md / decisions.md |
    | contract-freezability | [gap] | HIGH | ... | ... |

    ## Materialization
    | Metric | Count |
    |--------|-------|
    | Contracts materialized | [N] |
    | Bindings resolved | [N] |
    | Under-pinned / escalated (D) | [N] |
    | (MERGE) Changed → reset to DEFINED | [N] |
    | (MERGE) Unchanged → status preserved | [N] |
    | (MERGE) Removed → archived | [N] |

    ## HIGH gaps promoted past (knowing overrides)
    [list, or "none"]
    ```

28. **Update state file**: status = COMPLETE; record the promotion in the round record + state history (`Round [N] (Promote) complete — froze round-[R]-review; gate [CLEAN | disposed]; materialize [FIRST_FREEZE | MERGE]; fidelity CLEAN`).

29. **Report** to the user: the freeze is complete; the three published documents are current, the contract registry is materialized + fidelity-verified, and `round-[N]-promote/` holds the record. If any HIGH was promoted past, name it and where it was recorded. If MERGE ran, note the changed/reset/preserved counts.

---

## Stopping Points

**Automatic flow (do NOT pause for human confirmation):**
- Step 1 → 2 → 3 → 3a → 3b → 3c → 4 → 4b → 4c: proceed automatically **unless** the gate (Step 2) HALTs, the conservation check returns `MISMATCH` (Step 3a), the materializer escalates a (D) contract (Step 3b), or the fidelity check returns `MISMATCH` (Step 3c). Step 4b (write-direction re-verify flag) is MERGE-only and never HALTs — it writes durable producer flags and proceeds.

**Human checkpoints (orchestrator handles these directly):**
- **Step 2 (gate)** — if EITHER reviewer returns a HIGH finding: WAITING_FOR_HUMAN. Every HIGH gets a recorded disposition (Resolved → log to `pending-issues.md` + HALT for a Review round; Deferred → `future.md`; Dismissed / Override → `decisions.md`) before the promoter runs.
- **Step 3a (conservation)** — if the conservation check returns `MISMATCH`: WAITING_FOR_HUMAN, **HALT promote-local** (re-run the promoter at Step 3, or an explicit human accept/override recorded to `decisions.md`). The docs are **not** published until the check is CLEAN.
- **Step 3b (materialize)** — if the materializer escalates an under-pinned **(D)** contract: WAITING_FOR_HUMAN, **HALT backward-to-Review** via `pending-issues.md` (re-run Review to pin it, then re-run Promote). Rare — the Step-2 freezability reviewer should already have caught it.
- **Step 3c (fidelity)** — if the checker returns `MISMATCH`: WAITING_FOR_HUMAN, **HALT promote-local** (re-materialize / re-run Step 3b, or an explicit human accept). This is a projection fault, **not** an architecture gap — do **not** route backward-to-Review.

Do NOT ask "Should I proceed?" between automatic steps. Only stop at the checkpoints above.

---

## Exit Criteria

Promote exits by **freezing**: the gate passes clean (or every HIGH is disposed/overridden), the promoter writes the three documents to the round folder, the document-conservation gate returns `CLEAN` and the orchestrator publishes the three documents to the parent, the materializer writes the frozen contract registry original to the round folder, the fidelity check returns `CLEAN`, Finalise publishes the registry to `05-components/specs/cross-cutting.md`, and the `round-[N]-promote` record captures the whole freeze. On a **Resolved** gate disposition or a Step-3b **(D)** escalation the workflow instead HALTs and routes back to Review via `pending-issues.md` — the freeze happens on a subsequent Promote round after Review re-runs. On a Step-3a or Step-3c `MISMATCH` the workflow HALTs promote-local (re-run the promoter / re-materialize, or human-accept) without routing back to Review.

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
| Document-conservation check returns `MISMATCH` | HALT promote-local: WAITING_FOR_HUMAN — re-run the promoter (Step 3) or human-accept; do NOT publish the docs |
| Document-conservation check produces no verdict | Error: treat as blocking, re-run Step 3a |
| Published doc missing after Step-3a publish | Error: do not proceed to materialize |
| Materializer fails (no registry / not MATERIALIZED) | Error: Report failure; do not mark COMPLETE; re-run Step 3b |
| Materializer escalates an under-pinned (D) contract | HALT backward-to-Review: log to `pending-issues.md`, WAITING_FOR_HUMAN — re-run Review to pin, then re-run Promote |
| Fidelity check returns `MISMATCH` | HALT promote-local: WAITING_FOR_HUMAN — re-materialize (Step 3b) or human-accept; do NOT route backward-to-Review |
| Fidelity check produces no verdict | Error: "Materialization-fidelity check did not produce a verdict — re-run Step 3c." Treat a missing verdict as blocking, never as clean |
| Registry `cross-cutting.md` missing after materialize | Error: "Freeze completed but registry not found at [path]" — do not mark COMPLETE |

---

<!-- INJECT: tool-restrictions -->
