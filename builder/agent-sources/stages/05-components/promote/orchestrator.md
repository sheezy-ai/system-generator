# Component Spec Promote Orchestrator

---

## Purpose

The per-component freeze. Runs **after a Review round completes for this component**; promotes the reviewed spec — splitting it into the published `specs/[component-name].md` / `future/[component-name].md` / `decisions/[component-name].md` — and records the promotion as a versioned `round-N-promote` round.

Because the Spec Promoter is the **sole producer of `specs/[component-name].md`** and Promote is the only workflow that runs it, this workflow sits on the **only road** to a published component spec (create finalises to a draft; review finalises to a reviewed draft; neither writes `specs/`). Create → Review → **Promote** [guard → split → record] → frozen.

**Structural note (05P-3):** this workflow *guards* its input, runs a **blocking Conformance Gate** (Step 2), then *runs the Spec Promoter* and records the freeze. The gate seeds the contract status ladder — it transitions **this component's sole-producer** contracts `MATERIALIZED → DEFINED` on a clean body-check (the gate's teeth: a `contract-verifier` re-run is a no-op on a first freeze, so the body-check itself is the gate), runs the absent-from-freeze detector **BLOCKING** (non-gating in Review, gating here), and on a re-freeze re-runs the `contract-verifier` for regression. **Producer-cardinality split:** multi-producer / ownerless / interface-only contracts are **not** touched here — they stay `MATERIALIZED` for the whole-stage gate / coherence Phase 4 (the only altitudes that see all producer bodies).

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
- [ ] Step 2: Conformance Gate (body-check → MATERIALIZED → DEFINED; absent-from-freeze BLOCKING; re-freeze regression)
- [ ] Step 3: Promote (split)
- [ ] Step 4: Finalise (verify + record + mark COMPLETE)

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

Gate agents (re-run at Step 2 — they LIVE in review/create, not moved):
├── {{AGENTS_PATH}}/05-components/create/absent-from-freeze-detector.md   # BLOCKING here (non-gating in review)
└── {{AGENTS_PATH}}/05-components/review/contract-verifier.md             # re-freeze regression only (no-op on a first freeze)
```

---

## Orchestration Workflow

**Immediate execution**: The user invoking this orchestrator IS the instruction to execute. Do not ask for confirmation before starting. Proceed immediately with the On Start/Resume check, then Step 1.

**File-First Principle**: Do NOT pass file contents or summaries to agents — pass only file PATHS; agents read files themselves.

**Orchestrator Boundaries**
- You READ the state file, `specs/cross-cutting.md` (contract statuses + `Producer(s)`), and workflow outputs.
- You RUN the Conformance Gate (Step 2): apply the producer-cardinality classifier and the body-check yourself; **SPAWN** the Absent-From-Freeze Detector (always, BLOCKING) and — on a re-freeze only — the `contract-verifier` (both in FOREGROUND).
- You SPAWN the Spec Promoter to do the split (in FOREGROUND, not background — it needs interactive approval for file writes).
- You EDIT `specs/cross-cutting.md` to transition **this component's sole-producer** contracts `MATERIALIZED → DEFINED` on a clean body-check — a gate status action (05 owns contract *status*), not authored obligation content. You do **not** touch multi-producer / ownerless / interface-only contracts.
- You UPDATE the state file with status changes.
- You WRITE the round-record metadata (incl. the gate verdict + dispositions + transitions) directly via Edit (an orchestrator record, not authored content).
- You DO NOT author the promoted documents — the Spec Promoter does. You do **not** author contract *obligations* (that is 04's) — the absent-from-freeze detector escalates absences upstream; you do not register them locally.

**Context management**: Keep context lean — use Grep for targeted extraction from the state file and `cross-cutting.md`, `ls` for existence checks. The reviewed spec is read by the gate agents / Spec Promoter; the orchestrator reads only what it needs for the classifier and the body-check.

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

### Step 2: Conformance Gate (blocking — the per-component freeze teeth)

**This gate sits on the only road to `specs/[component-name].md`. It runs against the snapshot (`round-[N]-promote/00-spec.md` = this component's realized spec) BEFORE the split. Three checks: (a) a conformance body-check that transitions this component's sole-producer contracts `MATERIALIZED → DEFINED` on a first freeze (the gate's real teeth — a `contract-verifier` re-run is a no-op on a first freeze, so the body-check itself IS the gate); (b) on a re-freeze, a `contract-verifier` re-run for regression only; (c) a BLOCKING absent-from-freeze detection. Any HIGH must have a recorded disposition before the promoter runs.**

6. **Update state file**: Set Step 2, `Status: IN_PROGRESS`.

7. **Identify this component's sole-producer contracts (the producer-cardinality classifier — load-bearing; this is NOT a comma-count).** Read `specs/cross-cutting.md`. For each contract, read its `Producer(s)` field and classify:
   - Split the `Producer(s)` value on commas into producer entries; **strip any parenthetical/qualifier suffix** from each entry (`pipeline (Pipeline Orchestrator)` → `pipeline`; `email-sources (sole writer / owner)` → `email-sources`).
   - A contract is **THIS-COMPONENT-SOLE-PRODUCER** iff, after the split, there is **exactly ONE** producer entry, that entry names a **real 05 component** (a component that owns a `specs/[component].md` — **not** an interface phrase such as `Source Attribution interface (§7)` or `audit trail (§7)`, and **not** the ownerless collective `all domain components …`), **and** that component is **`[component-name]`** (this component).
   - **Everything else is OUT of this gate's scope — do NOT touch its status** (it stays `MATERIALIZED` for the whole-stage gate / coherence's wholesale sweep): (i) two or more producer entries; (ii) a single entry that is the ownerless collective `all domain components …` (**comma-free, but no owning component** — a comma-count would wrongly call it single-producer); (iii) a single entry that is an interface-only producer (`… interface (§7)`, `audit trail (§7)` — **one entry, but no owning component**); (iv) a single real component that is **not** this one. Worked examples against the live registry: CTR-011 `Producer(s): all domain components (via audit-trail interface, §7)` → **whole-stage** (ownerless); CTR-023 `Producer(s): Source Attribution interface (§7) — …` → **whole-stage** (interface-only); CTR-002 `Producer(s): events, entities, email-sources` → **whole-stage** (multi); CTR-001 `Producer(s): pipeline` → per-component at pipeline's promote.

8. **Conformance body-check (the teeth) — for each THIS-COMPONENT-SOLE-PRODUCER contract, keyed on its current `Status`:**
   - **`MATERIALIZED` (first freeze):** check the component's realized interface (the emitting operation / §4 Data Model in the snapshot) against the frozen **Obligation** and, for a `Binds:` contract, against the **bound field list as the required-field set** (a dropped or blob-collapsed bound field is a **FAIL** — same rule as `review/contract-verifier.md` Step 3).
     - **Clean** → transition the contract `MATERIALIZED → DEFINED` in `specs/cross-cutting.md`: update **both** the §8 entry's `- **Status**: MATERIALIZED` line **and** its Appendix "Contract Status Summary" row to `DEFINED`, and add `- **Body-checked**: [date], [component-name] Promote round [N]` to the entry. **This is the per-component gate's conformance teeth.**
     - **FAIL** → **HALT** — do NOT transition, do NOT spawn the promoter → disposition (sub-step 11).
   - **`DEFINED` / `VERIFIED` (re-freeze):** already body-backed — do **not** re-transition to `DEFINED`. Regression is handled by the `contract-verifier` re-run in sub-step 9. **Preserve the `DEFINED` rung** — never demote below `DEFINED`.

9. **Re-freeze regression check (`contract-verifier` — meaningful only when contracts are already `DEFINED`/`VERIFIED`).** If **any** contract this component produces is already `DEFINED` or `VERIFIED` (this is a re-freeze), spawn the `contract-verifier` (FOREGROUND) on the snapshot; it re-checks this producer's `DEFINED`/`VERIFIED` contracts and, on a regression, demotes `VERIFIED → DEFINED` and raises a CRITICAL pending-issue (its existing behaviour — `VERIFIED → FAIL → DEFINED`). On a **first freeze** (every contract `MATERIALIZED`) the verifier is a **no-op by construction** (it includes only `DEFINED`/`VERIFIED`, `contract-verifier.md` Step 1) — **skip the spawn**; the body-check in sub-step 8 is the gate.
    ```
    Follow the instructions in: {{AGENTS_PATH}}/05-components/review/contract-verifier.md

    Input:
    - Producer spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-promote/00-spec.md
    - Cross-cutting specification: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/cross-cutting.md
    - Pending issues: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/pending-issues.md

    Output: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-promote/08-contract-verification.md
    ```
    A regression demotion is a HIGH-equivalent finding → disposition (sub-step 11); the demote target is `DEFINED` (never below).

10. **Absent-from-freeze detection — BLOCKING (the promote-altitude change: this detector is non-gating in Review, `orchestrator-post-discussion.md` "do not gate the round on them"; here it is a hard gate).** Spawn the Absent-From-Freeze Detector (FOREGROUND) on the snapshot:
    ```
    Follow the instructions in: {{AGENTS_PATH}}/05-components/create/absent-from-freeze-detector.md

    Input:
    - Component body (spec being frozen): {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-promote/00-spec.md
    - Frozen cross-cutting registry: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/cross-cutting.md
    - Architecture pending-issues (escalation target): {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/versions/pending-issues.md

    Output: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-promote/10-absent-from-freeze-report.md
    ```
    Read the verdict (`COVERED` | `ABSENCES_ESCALATED`). On **`ABSENCES_ESCALATED`**: **HALT — do NOT spawn the promoter.** The freeze would publish a component spec realizing a cross-component contract no frozen CTR covers; the detector has already escalated it `CROSS-BOUNDARY-UPSTREAM` to Architecture (a backward edge). Disposition = Resolved-style backward edge (sub-step 11). On **`COVERED`**: proceed.

11. **Dispositions for HIGH before the split** — a body-check FAIL (sub-step 8), a regression demotion (sub-step 9), or an absent-from-freeze escalation (sub-step 10). Set `Status: WAITING_FOR_HUMAN`; **every** HIGH gets one recorded disposition before the promoter runs, and the gate is **never a silent pass**:
    - **Resolved** — the fix lives in a prior stage. For a body-check FAIL / regression: log the finding to this component's `pending-issues.md` (targeting this component) and **HALT** with `Conformance gate HIGH — re-run the Review workflow to fix the producer body, then re-run Promote.` For an absent-from-freeze escalation (already written to Architecture's `pending-issues.md` by the detector): **HALT** with `Absent-from-freeze — a cross-component contract is absent from the frozen registry; re-run Architecture Promote (re-freeze) then this component's Review before re-running Promote.` A **Resolved** disposition HALTs here — it does **not** proceed to the split.
    - **Deferred** — a knowingly-deferred obligation → recorded to `future/[component-name].md` (promote-local) and captured in `promote-metadata`.
    - **Dismissed / Override** — a human knowingly proceeds → recorded to `decisions/[component-name].md` with rationale (promote-local) and captured in `promote-metadata` as a HIGH gap promoted past.

12. **Update state file**: Mark Step 2 complete; record the **gate verdict** (`CLEAN` or the per-finding dispositions) and the contract-status transitions applied in the history.

13. **Automatically proceed to Step 3** — only after the gate passes clean, or every HIGH finding has a recorded disposition/override. (A **Resolved** disposition HALTs at Step 2 and does not reach Step 3.)

---

### Step 3: Promote (split)

14. **Update state file**: Set Step 3, `Status: IN_PROGRESS`.

15. **Spawn the Spec Promoter** (FOREGROUND) on the snapshot:
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

16. **Copy the promoted set into the round record**: copy `specs/[component-name].md`, `future/[component-name].md`, `decisions/[component-name].md` into `round-[N]-promote/` (the frozen snapshot for this round). The `specs/`/`future/`/`decisions/` copies are the published authority; these are the round's working record.

17. **Update state file**: Mark Step 3 complete.

18. **Automatically proceed to Step 4.**

---

### Step 4: Finalise

19. **Update state file**: Set Step 4, `Status: IN_PROGRESS`.

20. **Verify the freeze outputs exist** (before marking COMPLETE):
    - The three published documents: `specs/[component-name].md`, `future/[component-name].md`, `decisions/[component-name].md`.
    - If any is missing → **Error**: "Spec Promoter completed but output not found at [path]" — do **not** mark COMPLETE.

21. **Write `round-[N]-promote/promote-metadata.md`** (the freeze record — now includes the gate verdict, HIGH-gap dispositions, and contract-status transitions):
    ```markdown
    # Promote Round [N] — [component-name]

    **Date**: [date]
    **Component**: [component-name]
    **Source Review Round**: round-[R]-review-[build|ops] (input: [05-updated-spec.md | 00-spec.md])
    **Freeze Mode**: [FIRST_FREEZE (contracts were MATERIALIZED) | RE-FREEZE (contracts already DEFINED/VERIFIED)]
    **Gate Verdict**: [CLEAN | DISPOSED]
    **Sole writer**: this Promote round is the only writer of specs/[component-name].md.

    ## Conformance Gate
    | Contract | Producer cardinality | Prior status | Body-check | New status |
    |----------|---------------------|--------------|------------|------------|
    | CTR-NNN | this-component-sole-producer | MATERIALIZED | clean | DEFINED |
    (Only this-component-sole-producer contracts appear here. Multi-producer / ownerless / interface-only contracts are NOT transitioned at per-component promote — they stay MATERIALIZED for the whole-stage gate / coherence.)

    **Absent-from-freeze**: [COVERED | ABSENCES_ESCALATED (HALTed)]
    **Re-freeze regression check**: [N/A (FIRST_FREEZE) | contract-verifier run — R regressions, demoted VERIFIED → DEFINED]

    ## Gate Findings & Dispositions
    | Source | Finding | Severity | Disposition | Recorded In |
    |--------|---------|----------|-------------|-------------|
    | (body-check / regression / absent-detector) | [gap] | HIGH | Resolved/Deferred/Dismissed/Override | pending-issues.md / future/ / decisions/ |

    ## HIGH gaps promoted past (knowing overrides)
    [list, or "none"]

    ## Published Outputs
    - specs/[component-name].md
    - future/[component-name].md
    - decisions/[component-name].md
    ```

22. **Update state file**: `Status: COMPLETE`; mark Step 4 complete. Record in history: `Round [N] (Promote) complete — froze round-[R]-review-[build|ops]; gate [CLEAN | disposed]; [K] contracts MATERIALIZED → DEFINED; specs/[component-name].md published`.

23. **Update the stage index** (`{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/workflow-state.md`): set the component's row in the Component Specs table to `COMPLETE`, Last Updated to today's date; add a history entry `[date]: [component-name] promoted (specs/ published)`. Keep the table sorted alphabetically.

24. **Report** to the user: the component freeze is complete; `specs/[component-name].md` / `future/[component-name].md` / `decisions/[component-name].md` are published, and `round-[N]-promote/` holds the record. Name any contracts transitioned `MATERIALIZED → DEFINED`, and any HIGH gap promoted past and where it was recorded.

---

## Stopping Points

**Automatic flow (do NOT pause for human confirmation):** Step 1 → 2 → 3 → 4 proceed automatically **unless the Conformance Gate (Step 2) HALTs** on a HIGH finding.

**Human checkpoint (orchestrator handles it directly):**
- **Step 2 (Conformance Gate)** — a body-check FAIL, a `contract-verifier` regression demotion, or an absent-from-freeze `ABSENCES_ESCALATED` verdict: set `Status: WAITING_FOR_HUMAN`. Every HIGH gets a recorded disposition before the promoter runs (Resolved → log + HALT for a Review / Architecture re-freeze; Deferred → `future/`; Dismissed / Override → `decisions/`). A **Resolved** disposition HALTs the workflow here — it does not reach the split.

Do NOT ask "Should I proceed?" between automatic steps. Only stop at the checkpoint above.

---

## Exit Criteria

Promote exits by **freezing**: the Conformance Gate passes clean (or every HIGH is disposed/overridden), the Spec Promoter produces the three published documents, and the `round-[N]-promote` record captures the freeze (gate verdict + contract-status transitions). On a **Resolved** gate disposition the workflow instead HALTs and routes back to Review (or Architecture re-freeze then Review) via `pending-issues.md` — the freeze happens on a subsequent Promote round. The review-mandatory guard (On Start) errors (without stranding) if the last completed round was not a Review round.

**Contract-status ladder (reconciliation):** this gate transitions **only** `MATERIALIZED → DEFINED` for **this-component-sole-producer** contracts. `DEFINED → VERIFIED` (consumer alignment) and the `MATERIALIZED → DEFINED` of **multi-producer / ownerless / interface-only** contracts stay with coherence Phase 4 / the whole-stage gate (the only altitudes that see all producer bodies). So **every contract has a home** and none is stranded `MATERIALIZED` forever: single-real-component → per-component promote; everything else → whole-stage. The `DEFINED` rung is preserved (the `contract-verifier`'s regression-demote target, `VERIFIED → FAIL → DEFINED`).

---

## Error Handling

| Condition | Action |
|-----------|--------|
| No state file for the component | Error: "No state file found for [component]. Promote requires a completed Review round; run Create → Review first." |
| Last completed round was not a Review round | Error (no state mutation): "Promote requires a completed Review round; last round was {type}." |
| `Status: not COMPLETE` + other workflow in progress | Error: "Cannot start Promote: {Current Workflow} workflow still in progress" |
| Reviewed spec not found | Error: "Review round [R] completed but no reviewed spec found for [component]." |
| Conformance body-check FAIL (sole-producer contract) | HALT — WAITING_FOR_HUMAN: log to this component's `pending-issues.md`; "Conformance gate HIGH — re-run Review to fix the producer body, then re-run Promote." Do not transition, do not spawn the promoter |
| Absent-from-freeze returns `ABSENCES_ESCALATED` | HALT — WAITING_FOR_HUMAN: detector already escalated to Architecture `pending-issues.md`; "re-run Architecture Promote (re-freeze) then this component's Review before re-running Promote." Do not spawn the promoter |
| `contract-verifier` regression demotion (re-freeze) | Demote `VERIFIED → DEFINED` (never below); HIGH-equivalent → disposition; the `DEFINED` rung is the floor |
| Gate agent (absent-detector / contract-verifier) fails | Error: report which agent failed; do not proceed to the promoter |
| Spec Promoter fails | Error: Report failure details; do not mark COMPLETE |
| Published output missing after split | Error: "Spec Promoter completed but output not found at [path]" — do not mark COMPLETE |

---

<!-- INJECT: tool-restrictions -->
