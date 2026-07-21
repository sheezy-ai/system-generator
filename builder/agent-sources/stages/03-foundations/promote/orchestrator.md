# Foundations Promote Orchestrator

---

## Purpose

The split. Runs **after a Review round completes**; snapshots the reviewed Foundations, then promotes it — splitting into `foundations.md` / `decisions.md` / `future.md` — and records the promotion as a versioned `round-N-promote` round.

Because the promoter is the **sole producer of `foundations.md`** and Promote is the only workflow that runs it, this sits on the **only road** to a promoted Foundations. Promote splits the reviewed Foundations, then runs a **blocking document-conservation gate** that can **HALT** before the split documents are published — so the split is no longer an unconditional split-and-record. Foundations has no downstream contract registry, so there is still **no freeze gate, materialization, or fidelity check (those are 04-only)**; the conservation gate is a verbatim-conservation check on the split, **not** a freeze/materialization gate.

**Flow:** Review (completes) → **Promote** [guard → split → conservation-gate → publish → record] → done.

---

## Workflow State Management

**State file**: `system-design/03-foundations/versions/workflow-state.md`

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
# Foundations Workflow State

**Foundations**: 03-foundations/foundations.md
**PRD**: 02-prd/prd.md
**Current Workflow**: Promote
**Current Round**: [N]
**Status**: IN_PROGRESS | WAITING_FOR_HUMAN | COMPLETE

## Progress

### Round [N] (Promote)
- [ ] Step 1: Guard & Snapshot
- [ ] Step 1b: Upstream Freshness Gate (equality clause on the direct 02 edge)
- [ ] Step 2: Promote (split)
- [ ] Step 2a: Document-conservation gate
- [ ] Step 3: Finalise

<!-- written by Review at round completion — Promote READS it (Step 1b), never writes it; do not overwrite these values on a template regen -->
## Upstream Freshness (reconciled-against)
- 02-prd:          round-[N]-promote

## History
- YYYY-MM-DD HH:MM: Round [N] (Promote) started — splitting round-[R]-review
```

---

## Fixed Paths

**Output directory**: `system-design/03-foundations/versions`
**State file**: `system-design/03-foundations/versions/workflow-state.md`
**Working record**: `system-design/03-foundations/versions/round-[N]-promote/`

**Published outputs** (the promoter writes the round-folder originals at Step 2; the orchestrator PUBLISHES them to these live parent paths at Step 2a, only after the conservation gate returns CLEAN):
- `system-design/03-foundations/foundations.md` — Clean current-scope Foundations
- `system-design/03-foundations/decisions.md` — Design rationale and trade-offs
- `system-design/03-foundations/future.md` — Deferred items and future considerations

**Output-location principle:** the `round-[N]-promote/` record is the working history — **nothing reads it cross-stage**. Downstream stages read only the stable published copies (`foundations.md` / `decisions.md` / `future.md`).

---

## Prompt Locations

```
agents/03-foundations/promote/
├── orchestrator.md                     # This file
└── promoter.md                         # Splits the reviewed Foundations into foundations/decisions/future round-folder originals

Universal agents (in {{AGENTS_PATH}}/universal-agents/):
├── realign-check.md                    # Step 1b: freshness re-align callable unit (runs the AV on the stale 02 edge, advances an ALIGNED edge, HALTs on a discrepancy)
└── document-conservation-checker.md    # Step 2a: document split conservation gate (verbatim §1–10 + cross-refs gate; prose/decisions/future advisory) — invoked with 03's Verbatim-critical sections list
```

---

## Output Directory Structure

```
system-design/03-foundations/
├── foundations.md                 # Clean current-scope (PUBLISHED here at Step 2a, after conservation CLEAN)
├── decisions.md                   # Design rationale (published here at Step 2a)
├── future.md                      # Deferred items (published here at Step 2a)
└── versions/
    ├── workflow-state.md
    ├── round-[R]-review/              # The review round being split (input source)
    │   └── 05-updated-foundations.md      # (or 00-foundations.md on the zero-issues path)
    ├── round-[N]-promote/             # This promote round's working record
    │   ├── 00-foundations.md              # Input snapshot = the reviewed doc being split
    │   ├── foundations.md                 # Promoted Foundations original (published to parent after CLEAN)
    │   ├── decisions.md                   # Promoted decisions original (published after CLEAN)
    │   ├── future.md                      # Promoted future original (published after CLEAN)
    │   ├── conservation.md                # Step 2a document-conservation report + verdict
    │   └── promote-metadata.md            # date, source review round, input file used, gate verdict
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
- You SPAWN the Document-Conservation Checker (Step 2a, FOREGROUND) and — only after its verdict is CLEAN — PUBLISH the round-folder originals to the live `foundations.md`/`decisions.md`/`future.md` paths via `cp`. This publish is the single writer of those live paths.
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
   - `system-design/03-foundations/versions/round-[R]-review/05-updated-foundations.md` (the Author ran that round), **else**
   - `system-design/03-foundations/versions/round-[R]-review/00-foundations.md` (the zero-issues path — no Author ran).
   - If neither exists → **Error and stop**: "Review round [R] completed but no reviewed document found."

5. **Create the promote round record and snapshot the input**:
   - Create `system-design/03-foundations/versions/round-[N]-promote/`
   - Copy the input document to `round-[N]-promote/00-foundations.md` (the input snapshot = the reviewed doc being split). **All promote steps below work from this snapshot.**

6. **Update state file**: Mark Step 1 complete.

7. **Automatically proceed to Step 1b.**

---

### Step 1b: Upstream Freshness Gate (equality clause on the direct alignment-source edges)

**The freshness clause (generalises the 05-init check):** *A stage may not promote while, for any of its direct alignment-source edges, the consumer's recorded `Frozen-At` ≠ that source's current `Frozen-At`.* Foundations' sole direct source is the **PRD** (`alignment-verifier.md` source table), so this gate has **one live edge: 03←02**.

- **Update state file**: Set Step 1b, status = IN_PROGRESS.

- **Detect (per direct edge — automatic, metadata-only):** for the **02-prd** edge, compare:
  - **Recorded** — `- 02-prd:` in the `## Upstream Freshness (reconciled-against)` block of `system-design/03-foundations/versions/workflow-state.md`.
  - **Source current** — the `**Frozen-At**` value in the current `system-design/02-prd/prd.md` header.
  - **Two absent cases, kept distinct:**
    - **Source's `Frozen-At` absent** (the PRD never stamped — pre-adoption) → **inert no-op**, not a staleness error (the exact 05-init rule): record "02 edge inert (source token absent)" and proceed. Do not HALT.
    - **Consumer's recorded value absent** (never recorded this edge) → **stale**: cleared **only by an actual AV re-check** (below), never by a bare stamp.
  - **Fresh** (recorded == source current) → edge clean.

- **If every edge is fresh or inert** → mark Step 1b complete; **automatically proceed to Step 2.**

- **If the 02 edge is stale** → run the **Re-Align Check** callable unit (the gate-step; the AV re-checks, the wrapper advances/routes/logs — §3.4):
  ```
  Follow the instructions in: {{AGENTS_PATH}}/universal-agents/realign-check.md

  Inputs:
  - Consumer document: system-design/03-foundations/versions/round-[N]-promote/00-foundations.md
  - Consumer freshness record: system-design/03-foundations/versions/workflow-state.md (## Upstream Freshness)
  - Stale-edge list: { 02-prd, system-design/02-prd/prd.md, [recorded 02-prd value or absent] }
  - Stage guide: {{GUIDES_PATH}}/03-foundations-guide.md
  - Output report: system-design/03-foundations/versions/round-[N]-promote/01-realign-report.md
  ```
  - **`ALL_ADVANCED`** (the AV read zero discrepancies for 02, or the edge is inert) → the wrapper advanced the recorded `Frozen-At` to the AV-read token. Mark Step 1b complete; **proceed to Step 2.**
  - **`HALT_DISPOSITION_NEEDED`** (the AV found a discrepancy against 02 — even a non-SHOWSTOPPER one) → **HALT (freshness):** set `Status: WAITING_FOR_HUMAN`; present the re-align report. The human **resolves** (conform-down / sync-up a PI to `02-prd/versions/pending-issues.md`, then re-run Promote after the PRD's next Review) **or records a dismiss/override** that advances the edge with a rationale (to `decisions.md`). Do **NOT** run the promoter until the edge is advanced. Advance on the AV **`ALIGNED`-for-source** verdict (per-source zero discrepancies) — **never** on the AV's global `PROCEED`.

- **Update state file**: record the freshness verdict (fresh / advanced / disposed) in the history.

---

### Step 2: Promote (split)

8. **Update state file**: Set Step 2, status = IN_PROGRESS.

9. **Spawn Foundations Promoter** (FOREGROUND):
    ```
    Follow the instructions in: {{AGENTS_PATH}}/03-foundations/promote/promoter.md

    Input:
    - Reviewed Foundations: system-design/03-foundations/versions/round-[N]-promote/00-foundations.md
    - Foundations guide: {{GUIDES_PATH}}/03-foundations-guide.md
    - Freeze token: round-[N]-promote   (stamp into foundations.md's header as **Frozen-At** — the Foundations freeze identity downstream stages reconcile against; foundations.md has a Version/Last Updated block, so the promoter inserts the line there)

    Output:
    - system-design/03-foundations/versions/round-[N]-promote/foundations.md
    - system-design/03-foundations/versions/round-[N]-promote/decisions.md
    - system-design/03-foundations/versions/round-[N]-promote/future.md
    ```
    The promoter writes these round-folder originals; the live `foundations.md`/`decisions.md`/`future.md` paths are published by Step 2a after the conservation gate returns CLEAN.

10. **Update state file**: Mark Step 2 complete.

11. **Automatically proceed to Step 2a.**

---

### Step 2a: Document-conservation gate (new)

**Ordering invariant:** the Step-2a publish (below) is the single writer of the live `foundations.md`/`decisions.md`/`future.md` paths; nothing between Step 2 (split to the round folder) and this publish reads them. The published Foundations is what downstream stages consume, so it must be conservation-verified before it becomes that authority.

- **Update state file**: Set Step 2a, status = IN_PROGRESS.

- **Spawn the Document-Conservation Checker** (universal agent, FOREGROUND):
  ```
  Follow the instructions in: {{AGENTS_PATH}}/universal-agents/document-conservation-checker.md

  Input:
  - Reviewed source (pre-split): system-design/03-foundations/versions/round-[N]-promote/00-foundations.md
  - Split outputs (round-folder originals): system-design/03-foundations/versions/round-[N]-promote/foundations.md, decisions.md, future.md
  - Stage guide: {{GUIDES_PATH}}/03-foundations-guide.md
  - Promoter separation criteria (the split rulebook — used only by the advisory checks to recognise legitimate transformations): {{AGENTS_PATH}}/03-foundations/promote/promoter.md
  - Verbatim-critical sections: §1 Technology Choices, §2 Architecture Patterns, §3 Authentication & Authorization, §4 Data Conventions, §5 API Conventions, §6 Error Handling, §7 Logging & Observability, §8 Security Baseline, §9 Testing Conventions, §10 Deployment & Infrastructure

  Output: system-design/03-foundations/versions/round-[N]-promote/conservation.md
  ```

- **Gate on the verdict:**
  - **`MISMATCH`** → **HALT (promote-local):** `Status: WAITING_FOR_HUMAN`; present the conservation report. Disposition: a genuine content drop/distortion in §1–10 (or a dangling cross-reference) → re-run the promoter (Step 2); or an explicit human accept/override recorded to `decisions.md`. Do **NOT** publish the docs.
  - **`CLEAN`** → proceed to publish (below). Advisory findings are recorded (non-gating). **Also read the checker's `placement_smells` count** (from its return JSON / `round-[N]-promote/conservation.md`) and carry it forward to the Step-3 Finalise report. This is informational only — it never gates, HALTs, or changes the CLEAN publish path.
  - **missing / no verdict** → **treat as blocking** (never clean): `Document-conservation check produced no verdict — re-run Step 2a.`

- **Publish the documents** (single doc-publish point — ONLY after CLEAN), via `cp`:
  - `system-design/03-foundations/versions/round-[N]-promote/foundations.md` → `system-design/03-foundations/foundations.md`
  - `system-design/03-foundations/versions/round-[N]-promote/decisions.md` → `system-design/03-foundations/decisions.md`
  - `system-design/03-foundations/versions/round-[N]-promote/future.md` → `system-design/03-foundations/future.md`
  - Verify all three published files now exist; if any copy failed → **Error**, do not proceed.

- **Update state file**: Mark Step 2a complete; **automatically proceed to Step 3.**

---

### Step 3: Finalise

12. **Update state file**: Set Step 3, status = IN_PROGRESS.

13. **Verify the three published documents exist** (before finalising — published at Step 2a and conservation-verified: §1–10 byte-identical to the reviewed Foundations):
    - `system-design/03-foundations/foundations.md`
    - `system-design/03-foundations/decisions.md`
    - `system-design/03-foundations/future.md`
    - If any is missing → **Error**: "Promoter completed but output not found at [path]" — do **not** mark COMPLETE.

14. **Write `round-[N]-promote/promote-metadata.md`** (the promote record):
    ```markdown
    # Promote Round [N]

    **Date**: [date]
    **Source Review Round**: round-[R]-review
    **Input File Used**: [05-updated-foundations.md | 00-foundations.md]
    **Conservation Gate Verdict**: [CLEAN | MISMATCH-disposed]
    ```

15. **Update state file**: status = COMPLETE; record the promotion in the round record + state history (`Round [N] (Promote) complete — split round-[R]-review; conservation gate [CLEAN | disposed]`).

16. **Report** to the user: the split is complete; the three published documents (`foundations.md`, `decisions.md`, `future.md`) are current (conservation-verified) and `round-[N]-promote/` holds the record (incl. the conservation report).
    - **Eager-detect line (advisory — static direct-consumer list):** append: *This re-promote advanced Foundations' `Frozen-At`, so it staled the direct downstream consumers of Foundations — **04-architecture, 05-components**. Each re-aligns lazily at its own next Promote (its freshness gate auto-re-checks and either auto-clears or surfaces a discrepancy); nothing is auto-fired across completed stages.*
    - **Placement-smell notice (informational only — from the Step-2a `placement_smells` count):** **if `placement_smells > 0`**, append exactly ONE non-blocking line to this report: *Note: [N] placement smell(s) flagged — current-scope content routed to `decisions`/`future` that may belong in the clean spec. Non-blocking (the split published); review `round-[N]-promote/conservation.md` if you want to correct placement in a follow-up.* **If `placement_smells` is 0, say nothing.** This is informational only — **never HALT, wait, or ask a decision** on it, and it does not add a step.

---

## Stopping Points

**Automatic flow (do NOT pause for human confirmation):** Step 1 → 1b → 2 → 2a → 3 proceed automatically **unless** the freshness gate (Step 1b) HALTs on a live upstream discrepancy, or the document-conservation gate (Step 2a) returns `MISMATCH`.

**Human checkpoints (orchestrator handles them directly):**
- **Step 1b (freshness)** — if the 02 edge is stale and the re-align check returns `HALT_DISPOSITION_NEEDED` (the AV found a discrepancy against the current PRD): set `Status: WAITING_FOR_HUMAN`. The human resolves (conform-down / sync-up a PI to PRD, re-run after PRD Review) or records a dismiss/override that advances the edge. The promoter does not run until the edge is advanced.
- **Step 2a (conservation)** — if the conservation check returns `MISMATCH`: set `Status: WAITING_FOR_HUMAN`, **HALT promote-local** (re-run the promoter at Step 2, or an explicit human accept/override recorded to `decisions.md`). The docs are **not** published until the check is CLEAN.

Otherwise Promote guards, splits, conservation-checks, publishes, and records without pausing. Do NOT ask "Should I proceed?" between the automatic steps.

---

## Exit Criteria

Promote exits by **splitting**: the review-mandatory guard passes, the promoter writes the three documents to the round folder, the document-conservation gate (Step 2a) returns `CLEAN`, the orchestrator publishes the three documents to the live `foundations.md`/`decisions.md`/`future.md` paths, and the `round-[N]-promote` record captures the promotion (incl. the gate verdict). On a Step-2a `MISMATCH` the workflow HALTs promote-local (re-run the promoter, or human-accept) — the docs are not published until conservation is CLEAN. If the last completed round was not Review, the workflow errors at Step 1 and does not split.

---

## Error Handling

| Condition | Action |
|-----------|--------|
| No state file | Error: "No state file found. Promote requires a completed Review round; run Create → Review first." |
| Last completed round was not Review | Error: "Promote requires a completed Review round; last round was {type}." |
| `Status: not COMPLETE` + other workflow in progress | Error: "Cannot start Promote: {Current Workflow} workflow still in progress" |
| Reviewed document not found | Error: "Review round [R] completed but no reviewed document found." |
| Freshness gate: 02 edge stale, re-align returns `HALT_DISPOSITION_NEEDED` (Step 1b) | HALT (freshness): WAITING_FOR_HUMAN — human resolves (conform-down / sync-up PI to PRD) or records a dismiss/override that advances the edge. Do NOT run the promoter until the edge is advanced. Advance on `ALIGNED`-for-source, never on `PROCEED` |
| Promoter fails | Error: Report failure details; do not mark COMPLETE |
| Document-conservation check returns `MISMATCH` (Step 2a) | HALT promote-local: WAITING_FOR_HUMAN — re-run the promoter (Step 2) or human-accept; do NOT publish the docs |
| Document-conservation check produces no verdict | Error: treat as blocking, re-run Step 2a |
| Published doc missing after Step-2a publish | Error: do not proceed; do not mark COMPLETE |
| Published output file missing after promote | Error: "Promoter completed but output not found at [path]" |

---

<!-- INJECT: tool-restrictions -->
