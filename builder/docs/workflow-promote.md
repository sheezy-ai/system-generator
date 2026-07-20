# Promote Workflow

The Promote workflow **freezes** a reviewed document by splitting it into three published files — the clean current-scope spec, its design rationale, and its deferred items — and recording the promotion as its own version round. It is a separately-triggered workflow: Review no longer promotes at exit (it completes and *recommends* running Promote). Available for stages **02 (PRD)**, **03 (Foundations)**, and **04 (Architecture)**.

> Stage 01 (Blueprint) is not split — it copies the reviewed document to its canonical path. Stage 05 (Component Specs) keeps its own `spec-promoter`. See DEC-072 (the split) and DEC-081 (the decoupling).

For general workflow mechanics, see `workflow-create.md` and `workflow-review.md`.

---

## When It Runs

Promote runs **after a Review round completes**. It is the only workflow that runs the stage promoter, so it sits on the only road to a promoted (published) spec.

A **review-mandatory guard** enforces this structurally: Promote asserts that the last completed round was Review and errors otherwise (`Promote requires a completed Review round; last round was {type}`). A human cannot point Promote at an unreviewed create/expand draft.

---

## Flow

```
Reviewed document ──▶ Guard & Snapshot ──▶ [04: Contract Gate] ──▶ Promoter (split → round-folder) ──▶ Document-Conservation Gate ──▶ Publish ──▶ [04: Materialize + Fidelity] ──▶ Record ──▶ Done
```

- **All splitting stages (02/03/04/05):** the promoter writes the three docs to the `round-N-promote/` folder, a **document-conservation gate** (universal checker) verifies the split preserved the stage's verbatim-critical sections + cross-refs, and the orchestrator **publishes to the live paths only after the gate is CLEAN** (round-first). A conservation `MISMATCH` HALTs before publish. See DEC-085.
- **02 / 03:** `Guard & Snapshot → Split → Conservation Gate → Publish → Record` — no longer a plain split-and-record (the gate can HALT), but **no** contract freeze/materialization (that is 04-only).
- **04:** additionally runs the contract completeness/freezability **gate** (re-running the two review experts as the hard, unavoidable backstop), then after the split+conservation-publish **materializes** the frozen contract registry (`05-components/specs/cross-cutting.md`) and **fidelity-checks** it — closing the 04/05 seam. See `04-architecture.md`.

---

## Steps (02 / 03)

| Step | Name | Actor | Human? |
|------|------|-------|--------|
| 1 | Guard & Snapshot | Orchestrator | Auto (guard runs at On Start, before any state mutation) |
| 2 | Promote (split → round-folder) | Promoter | Auto |
| 2a | Document-conservation gate → publish | Checker + Orchestrator | Auto, unless MISMATCH |
| 3 | Finalise | Orchestrator | Auto |

Promote runs automatically **except** that the Step-2a conservation gate **HALTs for a human on a MISMATCH** (a verbatim-critical section was not preserved across the split). On CLEAN it publishes and continues; a placement smell (current-scope content routed to decisions/future) is surfaced as a passive, non-blocking note in the completion report. (04 additionally inserts the contract gate at Step 2 and materialize/fidelity at Steps 3b/3c; a HIGH gate finding or a fidelity `MISMATCH` there also halts for human disposition.) See DEC-085.

### Step 1 — Guard & Snapshot

- Assert the last completed round was Review (else error and stop).
- Resolve the input document: `round-[R]-review/05-updated-[document].md` **ELSE** `round-[R]-review/00-[document].md` (the zero-issues review path skips the Author, so only the `00` snapshot exists).
- Create `round-[N]-promote/` and snapshot the input to `round-[N]-promote/00-[document].md`. All later steps work from this snapshot.

### Step 2 — Promote (split)

- Spawn the stage promoter (the sole producer of the published spec) with the `00-[document].md` snapshot as input.
- The promoter writes the three published files and the orchestrator copies them into the round record.

### Step 3 — Finalise

- Verify the three published files exist; write `promote-metadata.md` (date, source review round, input file used); set state `COMPLETE`; report.

---

## Input Resolution (and the round type)

When a later Create/Review/Expand round starts after a Promote round, it must **not** read the published (split) file — that has lost rationale and future content. Source-selection resolves a `promote` last-round to `round-[N]-promote/00-[document].md` (the pre-split snapshot the promote round froze). This, plus the `05-updated … ELSE 00` fallback for a zero-issues review round, is the source-selection fix recorded in DEC-081.

---

## Output File Structure

```
system/[stage]/
├── [document].md               # Clean current-scope spec (published by Promote)
├── decisions.md                # Design rationale and trade-offs (published by Promote)
├── future.md                   # Deferred items and open questions (published by Promote)
└── versions/
    └── round-N-promote/            # This promote round's record
        ├── 00-[document].md            # Input snapshot = the reviewed doc being split
        ├── [document].md               # Copy of the promoted spec
        ├── decisions.md                # Copy of the promoted decisions
        ├── future.md                   # Copy of the promoted future
        └── promote-metadata.md         # date, source review round, input file used
```

The published files (parent folder) are the authority downstream stages read; the `round-N-promote/` record is working history that nothing reads cross-stage. (Stage 04's record additionally holds the materialized registry and the two freeze reports; the registry is published to `05-components/specs/cross-cutting.md` only after the fidelity check is CLEAN.)

---

## State Management

State file: `system/[stage]/versions/workflow-state.md` (shared with Create/Review/Expand; the `Current Workflow` field distinguishes the active workflow).

```markdown
# [Stage] Workflow State

**Current Workflow**: Promote
**Current Round**: [N]
**Status**: IN_PROGRESS | COMPLETE

## Progress
### Round [N] (Promote)
- [ ] Step 1: Guard & Snapshot
- [ ] Step 2: Promote (split)
- [ ] Step 3: Finalise
```

On start: a `COMPLETE` state advances to `Current Workflow: Promote` and initialises the next globally-numbered round, then applies the review-mandatory guard. Create refuses to re-run over a `Review` or `Promote` state.

---

## Exit Criteria

Promote exits by **freezing**: the guard passes, the promoter produces the three published documents, and the `round-N-promote` record captures the promotion. If the last completed round was not Review, Promote errors at Step 1 and does not split. (For 04, a HIGH contract-gate finding halts for disposition, and a materialization-fidelity `MISMATCH` halts promote-local — see `04-architecture.md`.)

---

## Differences by Stage

| | 02 PRD | 03 Foundations | 04 Architecture |
|---|--------|----------------|-----------------|
| **Splits into 3** | Yes | Yes | Yes |
| **Contract gate** | No | No | Yes (re-runs two review experts) |
| **Materialize + fidelity** | No | No | Yes (freezes the registry for 05) |
| **Backward-edge / pending-issues** | No | No | Yes |

01 copies (no split); 05 uses its own `spec-promoter`.
