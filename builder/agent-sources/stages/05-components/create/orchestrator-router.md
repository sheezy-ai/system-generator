# Component Spec Creation Router

Central orchestrator that dispatches to phase orchestrators and handles all human communication.

---

## Purpose

Create a single component spec by exploring design concerns, generating a draft enriched by exploration findings, resolving gaps with the human, and iterating through additional explore→generate rounds as needed. When the human is satisfied, finalise the draft (`round-{N}-create/03-updated-spec.md`, else `00-draft-spec.md`) and hand off to the Review workflow. Create does **not** write `specs/[component-name].md` — the **Promote** workflow's spec-promoter is that path's sole writer.

**Flow:** Setup → [Explore → Generate → Gap Resolution]* → Promote

The explore→generate cycle can repeat for as many rounds as the human wants. Round 1 explores from the Architecture and Foundations. Round 2+ explores from the previous round's draft, finding concerns and enrichments that the earlier round missed or underexplored. The human exits the loop by choosing to promote at the promote/continue checkpoint.

**Phase orchestrators do work. Router talks to human.**

---

## Role

**Immediate execution**: The user invoking this orchestrator IS the instruction to execute. Do not ask for confirmation before starting. Proceed immediately.

- Dispatch to phase orchestrators (explore, generate, promote)
- Receive structured returns from phase orchestrators
- Present status and questions to human
- Collect human responses and decisions
- Update state file (and the stage index) and loop

**Invocation:**
```
Read the Component Create Router at:
{{AGENTS_PATH}}/05-components/create/orchestrator-router.md

Initialize component: [component-name]
```

Safe to re-invoke — the router reads the per-component state file and resumes from the last completed step.

---

## When to Run

Run this router for each component, after the initialize orchestrator has completed. Components should be initialized in priority order, respecting dependencies.

---

## Fixed Paths

**Architecture**: `{{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md`
**Foundations**: `{{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md`
**PRD**: `{{SYSTEM_DESIGN_PATH}}/system-design/02-prd/prd.md`
**Stage state**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/workflow-state.md`
**Component directory**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/`
**Per-component state**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/workflow-state.md`
**Brief (optional)**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/brief.md`
**Cross-cutting spec**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/cross-cutting.md`
**Re-raise ledger**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/create-decisions.md`

**Primary source** (determined by current round — see Path Resolution below):
- Round 1: Architecture + Foundations (two documents)
- Round N (N≥2): Latest draft from round N-1

**Create-terminal draft** (create's final output — NOT `specs/`): `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/round-{N}-create/03-updated-spec.md` (else `00-draft-spec.md`). The published `specs/[component-name].md` is written later, only by the Promote workflow's spec-promoter.

### Path Resolution

Resolve these paths based on the current round number (read `Current Round` from the state file), and pass the resolved values to phase orchestrators (they also re-resolve as needed):

**Primary source** (`{primary-source}`):
- Round 1: Two documents — `{{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md` and `{{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md`
- Round N (N≥2): Determine from round N-1 outputs:
  - If `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/round-{N-1}-create/03-updated-spec.md` exists → use it
  - Otherwise → use `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/round-{N-1}-create/00-draft-spec.md`

**Explore directory** (`{explore-dir}`): `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/round-{N}-create/explore/`

**Round directory** (`{round-dir}`): `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/round-{N}-create/`

**Resolve once at startup and again after any round increment.**

---

## State Files

### Stage State (top-level)

**Path**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/workflow-state.md`

Tracks the entire 05-components stage: stage initialization status and the component index (high-level status of each component). The router updates the component index when a component's status changes; the Stage Initialization section is managed by the initialize orchestrator, not this router.

### Per-Component State

**Path**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/workflow-state.md`

Detailed tracking for one component's creation (current round, phase, step, status, history, pending decisions). Created when creation starts.

### State File Format

```markdown
# [Component Name] Workflow State

**Component**: [component-name]
**Spec**: 05-components/specs/[component-name].md
**Architecture Overview**: 04-architecture/architecture.md
**Foundations**: 03-foundations/foundations.md
**PRD**: 02-prd/prd.md
**Current Round**: 1
**Current Workflow**: Create
**Current Phase**: Explore | Generate | Promote
**Status**: IN_PROGRESS | WAITING_FOR_HUMAN | COMPLETE
**Gaps Exist**: unknown | true | false
**Explore Phase**: active | skipped | complete

## Progress

### Phase 1: Explore
- [ ] Step 1: Setup
- [ ] Step 2: Concern Identifier
- [ ] Step 3: Concern Review
- [ ] Step 4: Concern Explorers
- [ ] Step 5: Exploration Consolidator
- [ ] Step 6: Enrichment Scope Filter
- [ ] Step 7: Enrichment Review
- [ ] Step 8: Enrichment Author

### Phase 2: Generate
- [ ] Step 9: Generate or Apply Enrichments
- [ ] Step 9b: Coverage Verification
- [ ] Step 9c: Depth Verification
- [ ] Step 9d: Excess Verification (binding)
- [ ] Step 10: Gap Resolution
- [ ] Step 10c: Creation Verification (alignment + coherence — per-round gate)
- [ ] Step 11: Promote or Continue

### Phase 3: Promote
- [ ] Step 12: Promote & Report

## Explore Details

Concerns: [CON-1, CON-2, ...] or [none]
Rigour-Gap Exit Predicate: MET | not-met   (set by explore Step 2 each round: MET iff the Concern Identifier surfaced zero rigour-gap-qualifying concerns; carried to the Step 11 promote checkpoint)
Enrichments Accepted: [N]
Enrichments Rejected: [N]

## Pending Decision
(Router writes the human's decision here before re-dispatching a phase orchestrator; the phase orchestrator reads it. E.g. `skip-exploration`, `concerns-accepted`, `promote`, `another-round`, `10c: FIX` / `10c: ACCEPT`.)

## History
- YYYY-MM-DD: Creation workflow started
```

**Step numbering is stable** (1–12, including 9b/9c/9d/10c). The split changes *where the logic lives*, not the step numbers — in-flight state files resume without migration.

---

## Output Directory Structure

```
system-design/05-components/
├── specs/
│   └── [component-name].md            # Written only by Promote's spec-promoter (create finalises to round-{N}-create/ drafts, not here)
└── versions/
    ├── workflow-state.md              # Stage-level state (component index)
    └── [component-name]/
        ├── deferred-items.md          # Upstream gaps for this component
        ├── create-decisions.md        # Re-raise ledger (no-spec-change waivers/KEEPs)
        ├── workflow-state.md          # Per-component state
        └── round-{N}-create/
            ├── explore/
            │   ├── 00-concerns.md
            │   ├── 01-explorer-*.md
            │   ├── 02-enrichment-discussion.md
            │   ├── 02a-filtered-enrichment-discussion.md
            │   └── 03-exploration-summary.md
            ├── 00-draft-spec.md
            ├── 00-enrichment-applicator-output.md  # Round 2+ only
            ├── 00-requirements-checklist.md
            ├── 00-coverage-report.md
            ├── 00-depth-report.md
            ├── 01-gap-discussion.md
            ├── 02-author-output.md
            ├── 03-updated-spec.md
            ├── 04-alignment-report.md
            ├── 05-coherence-report.md
            └── 06-stage-appropriateness-report.md
```

---

## Main Loop

```
1. Read per-component state file
2. Check status — route accordingly
3. Dispatch to appropriate phase orchestrator
4. Receive return
5. Present to human (if needed)
6. Collect response (if needed), record in ## Pending Decision
7. Update per-component state file
8. Update stage index (if status changed)
9. Loop back to step 1 (or exit if complete)
```

---

## Dispatch Logic

### On Entry

1. **Read per-component state** at `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/workflow-state.md`:
   - **If doesn't exist**: Fresh start — dispatch **explore** (it creates the state file at Step 1 and adds the component to the stage index).

2. **If `Current Workflow` = Review or Promote**: Error — "{Current Workflow} workflow is active. Cannot re-run creation." (Create is a bootstrap-only workflow; once the component has moved on to Review or Promote, it is not re-run. This is the symmetric type-guard — Create refuses to run while Review *or* Promote owns the component.)

3. **If status = COMPLETE**: Report "Component creation complete." and STOP.

4. **If status = WAITING_FOR_HUMAN**: Determine the checkpoint from `Current Step` and handle it — see "Handling WAITING_FOR_HUMAN" below.

5. **If status = IN_PROGRESS**: Dispatch based on `Current Step` (see mapping below).

### Step-to-Phase Mapping

| Current Step | Phase | Action |
|--------------|-------|--------|
| 1, 2 | Explore | Dispatch explore (resumes from current step) |
| 3 | Explore (checkpoint) | Present concerns; on response dispatch explore |
| 4, 5, 6 | Explore | Dispatch explore |
| 7 | Explore (checkpoint) | Present enrichments; dispatch explore per iteration |
| 8 | Explore | Dispatch explore |
| 9, 9b, 9c, 9d | Generate | Dispatch generate (Action: RUN) |
| 10 | Generate (checkpoint) | Present gaps; dispatch generate per iteration |
| 10c | Generate | Dispatch generate (Action: RUN); checkpoint only if it returns VERIFY_DECISION |
| 11 | Generate (checkpoint) | Present promote/continue |
| 12 | Promote | Dispatch promote (Action: PROMOTE) |

---

## Handling WAITING_FOR_HUMAN

For every checkpoint: the router presents, the human responds, the router records the decision under `## Pending Decision`, sets status = IN_PROGRESS, and re-dispatches the owning phase orchestrator. Phase orchestrators never present to the human.

### At Step 3 (Concern Review)

Explore returned `CONCERNS_READY`. **Present** (use the return's `concern_count` and `convergence_note`):
```
Design concerns identified for exploration.

Concerns file: [concerns_file]

[Convergence note — include per the return's convergence_note:
 - 0 concerns: "No rigour gaps found this round — strong convergence signal. I recommend skipping exploration (→ re-verify at generate) or promoting; explore only to push further."
 - 1 concern: "Only one concern surfaced — thin, likely-converging round. Worth weighing explore-this-concern vs. promote."]

[N] concerns identified:
- CON-1: [Name] — [Focus]
- CON-2: [Name] — [Focus]
- ...
[If 0 concerns: write "No concerns identified." in place of the list.]

Please review the concerns file:
- Accept as-is: "looks good" / "continue"
- Add a concern: Edit the file to add a new CON entry
- Remove a concern: Edit the file to remove the CON entry
- Modify focus: Edit the file to adjust the focus/questions
- Skip exploration entirely: "skip exploration"

When ready, let me know.
```

**STOP: Wait for human response.**

**On response:**
- "skip exploration" → record `## Pending Decision: skip-exploration`, dispatch explore.
- Otherwise (accept / edited file) → record `## Pending Decision: concerns-accepted`, dispatch explore (it re-reads the possibly-edited concerns file).

### At Step 7 (Enrichment Review)

Explore returned `ENRICHMENTS_READY` (first entry) or `ENRICHMENTS_NEED_HUMAN` (subsequent iterations). This is a **multi-iteration loop** — the router presents, the human writes responses into the discussion file, and the router re-dispatches explore for each iteration until it returns `EXPLORE_COMPLETE`.

**First presentation** (`ENRICHMENTS_READY`) — offer the review mode (use the return's counts):
```
Exploration complete — [N] enrichment proposals ready for review (after scope filtering).

Discussion file: [filtered_file]

[If items were deferred or filtered, include:]
Scope filtering: [D] deferred upstream, [F] filtered (too detailed for spec)

[N] enrichments: [A] recommended Accept, [C] conditional Consider,
[U] unconditional Consider, [X] Cautious, [D] depth-flagged.

Review mode:
- "auto-resolve" — accept all Accept items, resolve conditional items
  from their dependencies, present only Cautious/flagged/unconditional
  Consider items for your input
- "review all" — present all [N] items for individual response
```
**STOP: Wait for human to choose review mode.** Record it as `## Pending Decision: enrichment-mode: auto-resolve|review-all` and dispatch explore.

**Subsequent presentations** (`ENRICHMENTS_NEED_HUMAN`) — the return says which of these to present:
- *review-all prompt*:
  ```
  Please review each enrichment and respond after the >> HUMAN: markers.

  Respond naturally — say what you think. Examples:
  - Accept: "Happy with this", "Accept", "Agree", "Yes"
  - Reject: "Disagree — [reason]", "Not needed", "Reject"
  - Accept with changes: State what to change
  - Question/discuss: Ask your question or raise a concern

  When done, let me know and I'll process your responses.
  ```
- *auto-resolution summary + remaining* (the return supplies the auto-resolved list and the items needing input):
  ```
  Auto-resolved ([N]):
  - [A] accepted (recommendation: Accept)
  - [C] conditionally resolved ([details per item])
  [If any items rejected by condition resolution:]
  - [R] rejected (conditional — dependency accepted)

  Need your input ([M]):
  [For each unresolved item:]
  - ENR-XXX ([Cautious/Consider/Depth-flagged]): [summary]

  Options:
  - "looks good" — confirm auto-resolutions, then respond to items
    needing input (or "looks good, accept remaining" to accept all)
  - Per-item overrides if any auto-resolution is wrong
  ```
- *interpretation confirmation* (the return supplies the interpreted classifications):
  ```
  Here's how I interpret your responses:

  ENR-001: **Accept** — agreed with the proposed approach
  ENR-002: **Reject** — you disagree with this direction
  ENR-003: **Accept with modification** — keep but adjust per your note
  [... all enrichments with responses ...]

  Is that correct? (Clarify any I got wrong and I'll re-interpret.)
  ```
- *facilitator responses ready*: "Please review the agent responses and reply to each enrichment."

**STOP after each** for the human. Do NOT re-dispatch explore until the human has added actual response content after `>> HUMAN:` markers (an empty `>> HUMAN:` marker is a placeholder, not a response). Record the human's confirmation/overrides in the discussion file / `## Pending Decision` as the return directs, then dispatch explore for the next iteration.

**Resolution vs continue indicators** (for the human's post-`>> AGENT:` replies): closure = "Yes / Agreed / That works / Fine / OK / Makes sense / Fair enough / Not a concern / Ignore / Skip"; continue = "? / What about / How would / Can you / Please / I'd like / I disagree / But what about".

### At Step 10 (Gap Resolution)

Generate returned `GAPS_READY` (first) or `GAPS_NEED_HUMAN` (subsequent). Multi-iteration loop, same shape as Step 7.

**First presentation** (`GAPS_READY`, use the return's counts):
```
Gap analysis complete (round {N}).

Discussion file: [gap_discussion_file]

- [N] HIGH (Must Answer) gaps
- [M] MEDIUM (Should Answer) gaps
- [K] LOW (Assumptions to Validate) gaps

Each gap has a proposed solution with options, trade-offs, and recommendation.
Please review each proposal and respond using >> HUMAN: markers:
- Accept: "Agreed", "Yes", "That works"
- Modify: State what you'd change
- Reject/Discuss: Explain your concern

When done, let me know and I'll process your responses.
```
**STOP.** Do NOT re-dispatch generate until the human has added actual content after `>> HUMAN:` markers.

**Subsequent presentations** (`GAPS_NEED_HUMAN`): "Please review the agent responses and reply to each gap." **STOP.** Same resolution/continue indicators as above. Re-dispatch generate (Action: RUN) for the next iteration; it processes the file and, when all gaps resolve, runs the Author and proceeds to Step 10c.

### At Step 10c (Creation Verification decision)

Generate returned `VERIFY_DECISION` (alignment/coherence found HIGH/MEDIUM or an alignment HALT). **Present** (use the return's issue lists and `rework_pass`):
```
[If rework pass 2+, include at top:]
> **Rework pass [N]**: verification after rework pass [N]. Diminishing returns are expected — each fix may surface progressively more peripheral cross-section implications. Exit discipline: gate on **no HIGH/MEDIUM**, not zero issues.

Creation verification (round {N}) found issues:

[If alignment issues:]
### Alignment Issues
[List discrepancies with classification and severity]

[If coherence gaps:]
### Coherence Gaps
[List HIGH/MEDIUM gaps with source section, target section, and summary]

[If rework pass 2+:]
> HIGH gaps: **FIX** recommended.
> MEDIUM gaps: **ACCEPT** recommended — on rework pass [N], these are likely diminishing-returns implications. FIX only if build-affecting.

[If first pass:]
For each: **FIX** (return to Author) or **ACCEPT** (carry to the promote/continue decision as-is)?
```
**STOP.** Record `## Pending Decision: 10c: FIX [findings]` or `10c: ACCEPT`, dispatch generate (Action: RUN). On FIX it re-authors and re-verifies (looping back here if issues persist); on ACCEPT it computes the convergence signal and returns `ROUND_COMPLETE`.

### At Step 11 (Promote or Continue)

Generate returned `ROUND_COMPLETE` (use the return's `convergence_signal`, `rigour_gap_exit`, gap summary, and report paths). **Present** — the human sees **two independent convergence signals** and decides; neither auto-exits the loop:
```
[If gaps were resolved:]
All gaps resolved and applied (round {N}).
[If no gaps:]
Draft spec generated (round {N}) — no gaps found.

Draft: {round-dir}/00-draft-spec.md
[If Author ran:]
Updated: {round-dir}/03-updated-spec.md

The spec passed this round's full gate: no missing requirements (coverage/depth), no unresolved over-build (excess), AND clean alignment + internal coherence (Step 10c — no HIGH/MEDIUM). Reports: {round-dir}/06-stage-appropriateness-report.md, {round-dir}/04-alignment-report.md, {round-dir}/05-coherence-report.md.

Convergence — two signals:

1. Rigour-gap exit predicate (round {N}): [MET | not met]
[If MET:] → **CONVERGED — promote warranted.** This round's concern identification surfaced **zero rigour-gap-qualifying concerns** — the workflow's explicit exit predicate. Another round is unlikely to surface load-bearing concerns. (This is the decisive convergence signal; you still decide — it informs, it does not auto-promote.)
[If not met:] → Concerns were surfaced this round, so the rigour-gap exit predicate does not hold; weigh the severity signal below.

2. Severity signal (round {N}): [substantive | diminishing-returns]
- Gaps resolved this round: [X HIGH, Y MEDIUM, Z LOW] (or "none")
- Over-build (Step 9d): [all KEEP'd/confirmed | drove edits]
- Creation Verification (Step 10c): [clean first pass | required rework]
[If diminishing-returns:] → **Recommend promote.** This round resolved no HIGH/MEDIUM concerns and made only low-value/polish refinement; another round would likely surface more of the same. Exit on "no HIGH/MEDIUM", not "zero possible refinements".
[If substantive:] → This round made substantive (HIGH/MEDIUM) change; another round may still surface load-bearing concerns worth resolving before promotion.

You can:
- Say "promote" — promote the current draft
- Say "another round" — run another explore→generate cycle

When ready, let me know.
```
**STOP.** The rigour-gap exit predicate and the severity signal are **inputs the human acts on**, not gates that fire automatically — the promote decision stays human-gated regardless of either signal.

**On response:**
- **"another round"** → record `## Pending Decision: another-round`, dispatch generate (Action: ANOTHER_ROUND). Generate writes the re-raise ledger, increments the round, resets Steps 1–11, and returns `NEW_ROUND_READY`. Then re-resolve paths for the new round and dispatch explore.
- **"promote"** → record `## Pending Decision: promote`, dispatch promote (Action: PROMOTE).

---

## Dispatching Phase Orchestrators

Read the phase orchestrator prompt and follow its instructions directly (phase files are instruction documents, not agents to dispatch). Spawn the *worker* agents they name via the Task tool in FOREGROUND.

### Explore

```
Follow the instructions in: {{AGENTS_PATH}}/05-components/create/orchestrator-explore.md

Component: [component-name]
Round: [N]
```
**Returns:** `CONCERNS_READY {concerns_file, concern_count, convergence_note}` · `ENRICHMENTS_READY {filtered_file, counts}` · `ENRICHMENTS_NEED_HUMAN {present: <which prompt>, data}` · `EXPLORE_COMPLETE {enrichments_accepted}`.

On `EXPLORE_COMPLETE`, dispatch generate (Action: RUN).

### Generate

```
Follow the instructions in: {{AGENTS_PATH}}/05-components/create/orchestrator-generate.md

Component: [component-name]
Round: [N]
Action: [RUN | ANOTHER_ROUND]
```
**Returns:** `GAPS_READY {gap_discussion_file, counts}` · `GAPS_NEED_HUMAN {...}` · `VERIFY_DECISION {alignment_issues, coherence_gaps, rework_pass}` · `ROUND_COMPLETE {convergence_signal, rigour_gap_exit, gap_summary, report_paths}` · `NEW_ROUND_READY {new_round}`.

### Promote

```
Follow the instructions in: {{AGENTS_PATH}}/05-components/create/orchestrator-promote.md

Component: [component-name]
Round: [N]
Action: PROMOTE
```
**Returns:** `PROMOTED {draft_path, summary}` (create finalised to its draft; `specs/[component-name].md` is NOT written here).

On `PROMOTED`, update state to COMPLETE, update the stage index, report to human, STOP.

---

## State File Updates

- **After a phase orchestrator runs a step**: the phase orchestrator marks its own step `[x]` and adds history entries. The router does not duplicate those.
- **Before re-dispatching after a checkpoint**: router sets `Status` = IN_PROGRESS and writes `## Pending Decision`.
- **At a checkpoint**: the phase orchestrator sets `Status` = WAITING_FOR_HUMAN before returning; the router presents.

## Stage State Updates

Update the stage state (`{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/workflow-state.md`) Component Specs table when component status changes:

| Event | Update |
|-------|--------|
| Creation starts | Component row exists (from initialize) — leave `NOT_STARTED` until create finalises |
| Create finalises | `NOT_STARTED` → `CREATED`, set Last Updated |

Keep the table sorted alphabetically by component name. The Stage Initialization section is managed by the initialize orchestrator, not this router.

---

## Orchestrator Boundaries

- You READ phase orchestrator prompts and follow their instructions directly
- You SPAWN worker agents (via the phase orchestrators' instructions) using the Task tool in FOREGROUND, not background
- You PRESENT status and questions to the human, and COLLECT responses
- You UPDATE the per-component state file and the stage index
- You DO NOT answer, analyse, or respond to human discussion points — discussion-facilitator agents do that
- Phase orchestrator files are instruction documents, not agents to dispatch

**File-First Principle**: Do NOT pass file contents or summaries to agents — only pass file PATHS; agents read files themselves.

**Context management**: The router persists across the entire creation lifecycle (multiple rounds, multiple phases). Every document you Read stays in context. Minimise reads — use Grep for targeted extraction from state and output files, `ls` for existence checks. Working files are read by subagents, not by the router.

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Stage state not found | Error: "Run the Component Specs initialize orchestrator first" |
| Component not in stage state | Error: "Component [name] not found in Component Specs table" |
| Component not NOT_STARTED | Error: "Component [name] status is [status], expected NOT_STARTED" |
| Contract layer materializing (`Population: MATERIALIZING`) | Error: "Contract layer materialization incomplete. Re-run the Promote stage (which materializes the registry) before creating components." |
| Deferred-items state inconsistent | Error: "Stage state says initialization is COMPLETE, but deferred-items state is inconsistent: monolithic file still present with content: [yes/no]; per-component file missing: [yes/no]. This suggests the initialize orchestrator's Step 3 (deferred-items processor) did not complete cleanly. Fix: re-run the initialize workflow's deferred-items split/archive step, or manually reconcile, before re-running Create." |
| Generator fails | Error: Report failure details |
| Draft not created | Error: "Generator completed but draft not found at expected path" |
| Concern Identifier fails | Error: Report failure details |
| Concerns file not created | Error: "Concern Identifier completed but output not found" |
| Explorer fails | Error: Report which concern's explorer failed |
| Consolidator fails | Error: Report failure details |
| Enrichment Scope Filter fails | Error: Report failure details |
| Enrichment Author fails | Error: Report failure details |
| Gap Formatter fails | Error: Report failure details |
| Gap discussion file not created | Error: "Gap Formatter completed but output not found at expected path" |
| Author fails | Error: Report failure details |
| Author output files not created | Error: "Author completed but outputs not found at expected paths" |
| Final draft missing at finalise | Error: "Create reached Step 12 but the final draft was not found at the expected round-{N}-create path" |
| State file corrupted/unreadable | Warning: Report issue, re-create state from file existence checks |
| Resume: draft missing but Step 9 marked complete | Error: "State says Generator complete but draft not found — re-run Generator or fix state file" |
| Round N primary source missing | Error: "Round {N} requires draft from round {N-1} but no draft found" |
| Current Workflow = Review or Promote | Error: "{Current Workflow} workflow is active. Cannot re-run creation." |

---

## What Happens Next

After create finalises:

1. **Human reviews the create-terminal draft** — Opens the final draft (`{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/round-{N}-create/03-updated-spec.md`, or `00-draft-spec.md` if the Author did not run)
2. **Human optionally makes manual edits** to that draft
3. **Human runs Review workflow** — Invokes the Component Review Router for this component

**IMPORTANT**: Create does **not** write `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/[component-name].md`. That published path is written only by the **Promote** workflow's spec-promoter (its sole writer). The Review workflow reads the **create-terminal draft** (`versions/[component-name]/round-{N}-create/03-updated-spec.md`, else `00-draft-spec.md`) for its Round 1 — that draft MUST exist before starting Review.

---

<!-- INJECT: tool-restrictions -->
