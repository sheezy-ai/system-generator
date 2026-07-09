# Component Spec Creation: Promote Phase

Handles Steps 11c–12: Decomposition Evaluation, Split into Sub-Specs, and Promote & Report. Dispatched by the router only when the human chooses "promote". Runs straight through between checkpoints and returns structured data to the router. **Router handles all human communication.**

---

## Orchestrator Boundaries

These are instructions for the router to follow directly. The router:
- Spawns worker agents using the Task tool (in FOREGROUND, not background)
- Passes file PATHS to agents, not file contents — agents read files themselves
- Does NOT read agent prompt files — agents read their own instructions
- Does NOT present to the human or STOP — it returns to the router, which owns all human communication

You COPY the final draft to `specs/[component-name].md` (promotion). You UPDATE the stage index and per-component state. You DO NOT write spec content — agents do that.

**Paths, Path Resolution, and the State File Format are defined in the router** (`orchestrator-router.md`). Resolve `{round-dir}` from the current round.

---

## Agent Prompt Locations

- Decomposition Evaluator: `{{AGENTS_PATH}}/05-components/create/decomposition-evaluator.md`
- Spec Splitter: `{{AGENTS_PATH}}/05-components/create/spec-splitter.md`

---

## On Entry

Router dispatches with `Action: PROMOTE` after the human chose "promote". Resume from `Current Step` among {11c, 11d, 12}, acting on `## Pending Decision` where the router recorded a sub-checkpoint choice.

Mark "Step 11: Promote or Continue" complete `[x]` (if not already), add history entry "Promoting draft from round {N}". Creation Verification already ran this round at Step 10c, so promotion proceeds straight to Step 11c.

## Step 11c: Decomposition Evaluation

Assess whether the settled spec should be decomposed into sub-specs (core + auxiliaries) before promotion. Runs once at the promote checkpoint.

**Confirm-decomposition sub-checkpoint** (first entry to Step 11c): set status = WAITING_FOR_HUMAN and **return** `DECOMP_CONFIRM`. (Router presents proceed / skip / back.)

**On re-dispatch — `## Pending Decision: decomp: ...`:**
- **`back`** → add history entry "Stepped back from Step 11c to Step 11"; **return** `BACK_TO_PROMOTE_CHOICE` so the router re-presents the promote/continue choice (Step 11). Do nothing else.
- **`skip`** → mark "Step 11c" complete `[x]` with note `skipped — human opted out`; add history entry; proceed to Step 12.
- **`proceed`** → set status = IN_PROGRESS; continue with step 1 below.

1. **Determine draft path**: if `{round-dir}/03-updated-spec.md` exists (Author ran), use it; otherwise `{round-dir}/00-draft-spec.md`.

2. **Spawn Decomposition Evaluator**:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/decomposition-evaluator.md

   Input:
   - Draft spec: [draft path]
   - Component guide: {{GUIDES_PATH}}/05-components-guide.md

   Output: {round-dir}/00-decomposition-report.md
   ```

3. **Wait**; read the report summary — extract recommendation: NO_SPLIT, SPLIT_RECOMMENDED, or ARCHITECTURE_ESCALATION.

4. **If NO_SPLIT**: Update state — Mark "Step 11c" complete `[x]`, history entry "No decomposition recommended". Proceed to Step 12.

5. **If ARCHITECTURE_ESCALATION**: set status = WAITING_FOR_HUMAN and **return** `ARCHITECTURE_ESCALATION { report: {round-dir}/00-decomposition-report.md }`. (Router presents the escalation note; the human decides to promote as a single spec or pause to escalate. On the router's re-dispatch: if the human chose to proceed as single spec → proceed to Step 12; if to escalate → update state accordingly and stop per the router's decision.)

6. **If SPLIT_RECOMMENDED**: set status = WAITING_FOR_HUMAN and **return** `SPLIT_DECISION { proposed_split: { core: {scope, ops}, auxiliaries: [{name, scope, ops, separability}] }, report: {round-dir}/00-decomposition-report.md }`. (Router presents approve / skip / modify.)
   **On re-dispatch — `## Pending Decision: decomp: skip`** → mark "Step 11c" complete `[x]`, add history entry; proceed to Step 12 (single-spec promotion).
   **On re-dispatch — `## Pending Decision: decomp: approve`** (possibly after the human edited the report) → mark "Step 11c" complete `[x]`, add history entry; proceed to Step 11d.

## Step 11d: Split into Sub-Specs

Runs only if the human approved decomposition in Step 11c.

1. **Spawn Spec Splitter**:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/spec-splitter.md

   Input:
   - Draft spec: [draft path from Step 11c]
   - Decomposition report: {round-dir}/00-decomposition-report.md
   - Component guide: {{GUIDES_PATH}}/05-components-guide.md
   - Component name: [component-name]

   Output:
   - Sub-spec files: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/[component-name]/core.md, [auxiliary].md, ...
   - Split summary: {round-dir}/00-split-summary.md
   ```

2. **Wait**; **verify** sub-spec files exist in `specs/[component-name]/`.

3. **Create per-sub-spec version folders and state files**: for each sub-spec (core + each auxiliary), create `versions/[component-name]/[sub-spec-name]/` and a `workflow-state.md` (status = NOT_STARTED, ready for review).

4. **Update stage state** (`versions/workflow-state.md`):
   - Add sub-spec rows under the component row:
     ```
     | [component-name]                    | DRAFT_READY | -                  | [date] |
     |   [component-name]/core             | DRAFT_READY | -                  | [date] |
     |   [component-name]/[auxiliary-1]    | DRAFT_READY | -                  | [date] |
     |   [component-name]/[auxiliary-2]    | DRAFT_READY | -                  | [date] |
     ```
   - Component-level status is derived: DRAFT_READY when all sub-specs are DRAFT_READY, COMPLETE when all are COMPLETE, IN_PROGRESS otherwise.
   - Add history entry: "[date]: [component-name] decomposed into [N] sub-specs: core, [aux-1], [aux-2]".

5. **Update state**: Mark "Step 11d" complete `[x]`, add history entry.

6. **Skip Step 12** (sub-specs are already in specs/ — splitter wrote them directly). Set status = COMPLETE.

7. **Return** `DECOMPOSED { sub_specs: [core, aux-1, aux-2, ...], summary: {round-dir}/00-split-summary.md }`. (Router reports completion; each sub-spec is reviewed independently via the Review workflow.)

## Step 12: Promote & Report (Single-Spec)

Runs only when the human chose to promote AND decomposition was not applied.

1. **Determine final draft path** (current round): if `{round-dir}/03-updated-spec.md` exists (Author ran), use it; otherwise `{round-dir}/00-draft-spec.md`.

2. **Copy final draft to specs** (Bash cp): `cp [final draft path] {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/[component-name].md`.

3. **Verify promotion** — confirm `specs/[component-name].md` exists.

4. **Update stage state** (`versions/workflow-state.md`): Component Specs table — update the component row status `NOT_STARTED` → `DRAFT_READY`, set Last Updated to today's date; add history entry "[date]: [component-name] creation workflow complete".

5. **Update per-component state**: Mark "Step 12" complete `[x]`, set status = COMPLETE, add history entry.

6. **Return** `PROMOTED { spec_path: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/[component-name].md, total_rounds: [N], summary: {...} }`. (Router reports completion, including: concerns explored / enrichments accepted-rejected for the final round, whether exploration was skipped, final draft path, gap-resolution summary, and the next-steps pointer to the Review workflow.)

---

## Return to Router

| Return | When |
|--------|------|
| `DECOMP_CONFIRM` | Step 11c entry — router presents proceed/skip/back |
| `BACK_TO_PROMOTE_CHOICE` | Human chose "back" — router re-presents the promote/continue choice |
| `ARCHITECTURE_ESCALATION { report }` | Decomposition evaluator recommends Architecture-level decomposition |
| `SPLIT_DECISION { proposed_split, report }` | Split recommended — router presents approve/skip/modify |
| `PROMOTED { spec_path, total_rounds, summary }` | Single-spec promotion complete |
| `DECOMPOSED { sub_specs, summary }` | Decomposed into sub-specs |

Do NOT present anything to the human — the router handles all human communication.

---

<!-- INJECT: tool-restrictions -->
