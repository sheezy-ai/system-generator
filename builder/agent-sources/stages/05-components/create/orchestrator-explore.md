# Component Spec Creation: Explore Phase

Handles Steps 1–8: Setup, Concern Identification, Concern Exploration, Consolidation, Scope Filtering, and Enrichment Authoring. Runs straight through between checkpoints and returns structured data to the router. **Router handles all human communication.**

---

## Orchestrator Boundaries

These are instructions for the router to follow directly. The router:
- Spawns worker agents using the Task tool (in FOREGROUND, not background)
- Passes file PATHS to agents, not file contents — agents read files themselves
- Does NOT read agent prompt files — agents read their own instructions
- Does NOT present to the human or STOP — it returns to the router, which owns all human communication

You READ input files only to validate they exist and to extract counts for the router's hand-off. You UPDATE the per-component state file at each step. You DO NOT write draft/exploration/author content — agents do that.

**Paths, Path Resolution, State File Format, and the Output Directory Structure are defined in the router** (`orchestrator-router.md`). Resolve `{primary-source}`, `{explore-dir}`, `{round-dir}` from the current round per the router's Path Resolution.

**Context management**: Keep context lean — `ls` for existence checks, Grep for targeted extraction from state/output files. Do not Read working files that you are passing to agents.

---

## Agent Prompt Locations

- Concern Identifier: `{{AGENTS_PATH}}/05-components/create/concern-identifier.md`
- Concern Explorer: `{{AGENTS_PATH}}/05-components/create/concern-explorer.md`
- Exploration Consolidator: `{{AGENTS_PATH}}/05-components/create/exploration-consolidator.md`
- Enrichment Scope Filter: `{{AGENTS_PATH}}/05-components/create/enrichment-scope-filter.md`
- Enrichment Author: `{{AGENTS_PATH}}/05-components/create/enrichment-author.md`
- Discussion Facilitator: `{{AGENTS_PATH}}/universal-agents/discussion-facilitator.md`

---

## On Entry / Resume

Read the per-component state file. Resolve paths for `Current Round`. Read `## Pending Decision` (the human choice the router recorded). Resume from the first incomplete step:

- **Fresh start** (no state file): create it (`Current Workflow: Create`, phase = Explore), add the component to the stage index, begin at Step 1.
- **Step 1** is idempotent — always re-run on resume for validation.
- **Step 2**: if complete, verify `{explore-dir}/00-concerns.md` exists and skip.
- **Step 3**: this is a router checkpoint. On re-dispatch, act on `## Pending Decision` (`concerns-accepted` or `skip-exploration`) as in Step 3 below.
- **Steps 4–8**: if all marked SKIPPED (human chose "skip exploration"), this phase is already complete — return `EXPLORE_COMPLETE {enrichments_accepted: 0}`.
- **Step 7**: this is a router checkpoint (multi-iteration). On re-dispatch, run one enrichment-review iteration (see Step 7) based on the discussion-file marker state and `## Pending Decision`.

---

## Step 1: Setup

0. **Update state**: Set status = IN_PROGRESS, phase = Explore (create state file if fresh start).

1. **Check stage state exists** at `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/workflow-state.md`. If NO → Error (Error Handling table in router).

2. **Read stage state** and validate: component exists in the Component Specs table; status is `NOT_STARTED`.

3. **Check the contract layer is frozen** (not dependency review status): component creation authors **inside-out** — against the frozen cross-cutting contract layer, not against peer component bodies — so the gate is that the layer is *materialized*, **not** that dependencies are *reviewed*. Read the `**Population**` status from `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/cross-cutting.md`:
   - **`MATERIALIZED`** (or a later post-hoc `COMPLETE`) → the contract layer is frozen. **Proceed** — dependencies need **not** be `COMPLETE`. Bodies are created in parallel against the frozen contracts; full review sequences later, once consumers exist.
   - **`DEFERRED`** (legacy projects whose contract layer was never materialized) → fall back to the pre-materialization gate: if the component has dependencies, verify all have status `COMPLETE`; if any is not → Error "Cannot create [component]: contract layer not materialized and dependency not COMPLETE. Blocked by: [list]".
   - **`MATERIALIZING`** (materializer interrupted mid-run) → Error "Contract layer materialization incomplete. Re-run the Promote stage (which materializes the registry) before creating components."

3b. **Check inbound cross-boundary obligations are landed** (Round 1 only — the authoring gate): a component authors **inside-out** from its own `pending-issues.md`, so any peer requirement a producer *claims* to have routed here but never actually wrote is **lost the moment this component is authored**. Invoke the **Cross-Boundary Routing Reconciler** in **scoped mode** for this component:
   ```
   Read the Cross-Boundary Routing Reconciler at:
   {{AGENTS_PATH}}/05-components/coherence/cross-boundary-routing-reconciler.md

   Reconcile routing claims scoped to target component: [component-name].
   ```
   - **`RECONCILED`** → every inbound obligation producers claim to have routed here is present in this component's `pending-issues.md`. **Proceed.**
   - **`GAPS`** → **Error / halt**: "Cannot create [component]: inbound cross-boundary obligations claimed by producer specs are absent from `versions/[component]/pending-issues.md` and would be lost at authoring. Route each into the component's pending-issues.md (`CROSS-BOUNDARY-PEER` per `guides/pending-issues-format.md`), then re-run. Missing: [list from the reconciler's GAPS worklist]." Do **not** proceed until the missing entries are routed and the scoped reconciler returns `RECONCILED`. This is a halt-for-human gate (it never auto-routes). **Rounds 2+ skip this gate** — the component is already authored; its inbound obligations were gated at Round 1.

4. **Validate deferred-items state** (Round 1 only):
   - Read stage state and confirm `Stage Initialization: Status: COMPLETE`.
   - If COMPLETE, verify the monolithic `versions/deferred-items.md` does NOT exist, or contains only the archived-header stub (no COMP-D items). If this fails → Error (Deferred-items state inconsistent).
   - The per-component `versions/[component-name]/deferred-items.md` may be absent — NOT an error (means zero deferred items). Step 5a creates an empty stub.

5. **Create directories** (if not exist): `versions/[component-name]/round-{N}-create/explore/`.

5a. **Ensure per-component deferred-items.md exists** (Round 1 only): if `versions/[component-name]/deferred-items.md` is absent, create an empty stub:
   ```markdown
   # Deferred Items: [component-name]

   Items deferred from upstream stages, relevant to this component.

   ---

   <!-- No deferred items for this component -->
   ```
   If it already exists, leave it unchanged.

6. **Deferred Items Intake** (Round 1 only):
   a. Check `versions/[component-name]/deferred-items.md`.
   b. If absent or no PENDING items → continue.
   c. If PENDING items: read final upstream documents (Architecture, Foundations); for each PENDING item validate relevance (`RESOLVED_UPSTREAM` → mark closed; `PARTIALLY_ADDRESSED` / `STILL_RELEVANT` → keep for exploration/generation); update the file with validation results.

7. **Check for Brief** at `versions/[component-name]/brief.md` (or an explicit brief path from the invocation). If it exists, it will be passed to the Generator later.

8. **Update state**: Mark "Step 1: Setup" complete `[x]`, add history entry.

Automatically proceed to Step 2.

## Step 2: Concern Identifier

**On resume**: if complete, verify `{explore-dir}/00-concerns.md` exists and skip to Step 3.

1. **Spawn Concern Identifier** (Task tool):
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/concern-identifier.md

   Input:
   - Component: [component-name]
   - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
   - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md
   - Component guide: {{GUIDES_PATH}}/05-components-guide.md
   - Cross-cutting spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/cross-cutting.md
   - Cross-cutting interface schema-specs (step-0; may be empty): {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/cross-cutting-interfaces/ — shared schema-specs for §7 cross-cutting interfaces; where this component writes/reads such an interface, adopt the frozen schema by reference (non-blocking — a component may adopt; it is not required)
   - Deferred items: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/deferred-items.md
   - Cross-cutting deferred items: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/cross-cutting/deferred-items.md
   - Workflow state: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/workflow-state.md
   [Round 2+ only — the artefact this round critiques:]
   - Previous-round draft (primary source): {primary-source}

   Output: {explore-dir}/00-concerns.md
   ```

2. **Wait**; **verify** `{explore-dir}/00-concerns.md` exists.

3. **Read the concerns file** — count concerns. The count does **not** drive control flow — it only sets the recommendation carried into the Step 3 checkpoint. Do **not** auto-skip on a low count. Set the `convergence_note` from the count:
   - **0 concerns**: identifier found no rigour gaps — strong convergence signal. `convergence_note = "0-concerns"`.
   - **1 concern**: thin, likely-converging round. `convergence_note = "1-concern"`.
   - **2+ concerns**: normal review. `convergence_note = "none"`.

   **Rigour-gap exit predicate (this round).** The `0-concerns` case is the workflow's explicit **convergence exit predicate** — *a round yields zero rigour-gap-qualifying concerns*. It is a first-class exit signal that is carried forward to the **promote/continue checkpoint** (Step 11), where the human acts on it — **not** merely the advisory Step 3 note, and **not** an auto-exit. Set `rigour_gap_exit = MET` iff `convergence_note == "0-concerns"`, else `rigour_gap_exit = not-met`.

4. **Update state**: Mark "Step 2" complete `[x]`, record concern list and count, and **persist the rigour-gap exit predicate** for this round into the `## Explore Details` section (`Rigour-Gap Exit Predicate: MET | not-met`) so it survives to the promote checkpoint (a later, separate generate dispatch reads it there). Add history entry.

5. **Set status = WAITING_FOR_HUMAN** and **return** `CONCERNS_READY { concerns_file: {explore-dir}/00-concerns.md, concern_count: [N], convergence_note: [0-concerns|1-concern|none] }`. (Router presents the concern review; the count never skips it.)

## Step 3: Concern Review (resolved by router decision)

On re-dispatch, read `## Pending Decision`:

- **`skip-exploration`** → Set `Explore Phase` = `skipped`, mark Steps 3–8 as `[x] SKIPPED`, add history entry, and jump to the end: **return** `EXPLORE_COMPLETE { enrichments_accepted: 0 }`.
- **`concerns-accepted`** → Re-read the concerns file (the human may have edited it), update the concern list in state, mark "Step 3" complete `[x]`, set status = IN_PROGRESS. Automatically proceed to Step 4.

## Step 4: Concern Explorers (parallel)

1. **Read the concerns file** for the final accepted list.

2. **Spawn Concern Explorer agents** (one per concern, in parallel):
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/concern-explorer.md

   Input:
   - Component: [component-name]
   - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
   - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md
   - Cross-cutting spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/cross-cutting.md
   - Cross-cutting interface schema-specs (step-0; may be empty): {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/cross-cutting-interfaces/ — shared schema-specs for §7 cross-cutting interfaces; where this component writes/reads such an interface, adopt the frozen schema by reference (non-blocking — a component may adopt; it is not required)
   - Concerns file: {explore-dir}/00-concerns.md
   - Deferred items: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/deferred-items.md
   - Cross-cutting deferred items: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/cross-cutting/deferred-items.md
   [Round 2+ only — the artefact this round critiques:]
   - Previous-round draft (primary source): {primary-source}
   - Assigned concern: CON-[N]

   Output: {explore-dir}/01-explorer-{concern-name}.md
   ```
   Replace `{concern-name}` with a kebab-case version of the concern name.

3. **Wait for all**; **verify** each expected `01-explorer-*.md` exists.

4. **Update state**: Mark "Step 4" complete `[x]`, add history entry with explorer count. Proceed to Step 5.

## Step 5: Exploration Consolidator

1. **Spawn Exploration Consolidator**:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/exploration-consolidator.md

   Input:
   - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
   - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md
   - Explorer outputs: {explore-dir}/01-explorer-*.md
     [List all explorer files explicitly]
   [Round 2+ only — the draft the enrichments must build on, not restate:]
   - Previous-round draft (primary source): {primary-source}

   Output: {explore-dir}/02-enrichment-discussion.md
   ```

2. **Wait**; **verify** `{explore-dir}/02-enrichment-discussion.md` exists. Read output — count enrichments for the handoff.

3. **Update state**: Mark "Step 5" complete `[x]`, add history entry with enrichment count. Proceed to Step 6.

## Step 6: Enrichment Scope Filter

1. **Spawn Enrichment Scope Filter**:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/enrichment-scope-filter.md

   Input:
   - Component guide: {{GUIDES_PATH}}/05-components-guide.md
   - Enrichment discussion: {explore-dir}/02-enrichment-discussion.md
   - Project scale reference: {{SYSTEM_DESIGN_PATH}}/system-design/project-scale.md

   Output: {explore-dir}/02a-filtered-enrichment-discussion.md
   ```

2. **Wait**; **verify** `{explore-dir}/02a-filtered-enrichment-discussion.md` exists. Read filtering summary — extract kept/deferred/filtered counts.

3. **Update state**: Mark "Step 6" complete `[x]`, add history entry with filtering counts. Proceed to Step 7.

## Step 7: Enrichment Review (multi-iteration checkpoint)

This is a router checkpoint operating on `{explore-dir}/02a-filtered-enrichment-discussion.md`. Each invocation runs **one iteration**: read the file's marker state and `## Pending Decision`, act, then either return a `ENRICHMENTS_*` status for the router to present, or (when all enrichments are resolved) proceed to Step 8.

Do NOT process enrichments until the human has added actual response content after `>> HUMAN:` markers — an empty `>> HUMAN:` marker is a placeholder, not a response.

**First entry (from Step 6):**
1. Set status = WAITING_FOR_HUMAN.
2. Parse each enrichment's recommendation field and count: **Accept**; **Conditional Consider** (recommendation "Consider" with conditional language referencing another ENR-ID, e.g. "accept if ENR-XXX rejected"); **Cautious**; **Depth-flagged** (`!! Depth flag`); **Unconditional Consider** ("Consider" without conditional language).
3. **Return** `ENRICHMENTS_READY { filtered_file, counts: {N,A,C,U,X,depth,deferred,filtered} }`. (Router offers the review mode.)

**Re-dispatch — `## Pending Decision: enrichment-mode: auto-resolve`:**
   a. **Auto-accept all Accept items**: for each enrichment recommendation "Accept", add `>> RESOLVED [ACCEPTED]` after the `>> HUMAN:` placeholder.
   b. **Resolve conditional Consider items**: parse each condition (e.g. "accept if ENR-XXX rejected"); look up the dependency's recommendation; if it resolves cleanly, add `>> RESOLVED [ACCEPTED|REJECTED]`; if ambiguous (mutual conditionals, or dependency itself Cautious), leave unresolved for the human.
   c. Determine items still needing input (Cautious / depth-flagged / unconditional Consider / ambiguous conditionals).
   d. If none remain → proceed to Step 8. If some remain → **return** `ENRICHMENTS_NEED_HUMAN { present: "auto-resolution-summary", data: { auto_resolved: [...], remaining: [...] } }`.

**Re-dispatch — `## Pending Decision: enrichment-mode: review-all`:** **return** `ENRICHMENTS_NEED_HUMAN { present: "review-all-prompt" }` (router asks the human to fill `>> HUMAN:` markers).

**Re-dispatch — human has filled `>> HUMAN:` markers (review-all, or auto-resolve remaining):**
   a. **Identify enrichments needing processing**: last entry is `>> HUMAN:` with content but no `>> RESOLVED`.
   b. **Interpret intent** for each. **Prerequisite — verify explicit positive signal**: before classifying as ACCEPT, verify the response contains explicit positive words ("happy", "agree", "accept", "yes", "good"); substantive engagement (questions, challenges) is not implicit acceptance. Classify: **ACCEPT** / **REJECT** / **ACCEPT WITH MODIFICATION** / **ACCEPT WITH DISCUSSION** / **QUESTION/DISCUSSION**.
   c. **Return** `ENRICHMENTS_NEED_HUMAN { present: "interpretation-confirmation", data: { classifications: [ENR-ID → label + reason] } }` for the human to confirm/correct.

**Re-dispatch — human confirmed interpretations (with any overrides applied to `## Pending Decision` / the file):**
   a. Apply confirmed classifications: ACCEPT / ACCEPT WITH MODIFICATION → `>> RESOLVED [ACCEPTED]`; REJECT → `>> RESOLVED [REJECTED]`; ACCEPT WITH DISCUSSION / QUESTION/DISCUSSION → leave unresolved for the facilitator.
   b. **If any need discussion**: spawn Discussion Facilitator agents (batched by group):
      ```
      Follow the instructions in: {{AGENTS_PATH}}/universal-agents/discussion-facilitator.md

      Context documents:
      - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
      - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md

      Issues file: {explore-dir}/02a-filtered-enrichment-discussion.md
      Issues: [ENR-001, ENR-002, ...]
      ```
      Wait for agents; **return** `ENRICHMENTS_NEED_HUMAN { present: "facilitator-responses-ready" }`.
   c. **If all enrichments resolved** → proceed to Step 8.

**Re-dispatch — human replied to facilitator responses:** for each discussed enrichment, if the last entry is `>> HUMAN:` after `>> AGENT:` and the response indicates closure → add `>> RESOLVED [ACCEPTED|REJECTED]`; if it is a question/pushback/request → leave open. If any remain unresolved → loop (return to "human has filled markers" processing, spawning facilitators again as needed). If all resolved → proceed to Step 8.

**Resolution indicators** (post-`>> AGENT:` closure): "Yes", "Agreed", "That works", "Fine", "OK", "Not a concern", "Not relevant", "Ignore", "Skip", "Makes sense", "Fair enough", "Understood".
**Continue indicators** (do NOT mark resolved): "?", "What about", "How would", "Can you", "Please", "I'd like", "Show me", "I disagree", "That's not right", "But what about".

**On proceeding to Step 8**: Mark "Step 7" complete `[x]`, set status = IN_PROGRESS, record accepted/rejected counts, add history entry.

## Step 8: Enrichment Author

1. **Check if any enrichments were accepted** — read `{explore-dir}/02a-filtered-enrichment-discussion.md` for `>> RESOLVED [ACCEPTED]` markers. If zero accepted:
   - No exploration summary needed (Step 9 Generator will run from primary source only).
   - Update state: Mark "Step 8" complete `[x]`, set `Explore Phase` = `complete`, set phase = Generate, add history entry "No enrichments accepted — Generator will use primary source only".
   - **Return** `EXPLORE_COMPLETE { enrichments_accepted: 0 }`.

2. **Spawn Enrichment Author**:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/enrichment-author.md

   Input:
   - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
   - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md
   - Component guide: {{GUIDES_PATH}}/05-components-guide.md
   - Filtered enrichment discussion: {explore-dir}/02a-filtered-enrichment-discussion.md

   Output: {explore-dir}/03-exploration-summary.md
   ```

3. **Wait**; **verify** `{explore-dir}/03-exploration-summary.md` exists.

4. **Update state**: Mark "Step 8" complete `[x]`, set `Explore Phase` = `complete`, set phase = Generate, add history entry.

5. **Return** `EXPLORE_COMPLETE { enrichments_accepted: [N] }`.

---

## Return to Router

| Return | When |
|--------|------|
| `CONCERNS_READY { concerns_file, concern_count, convergence_note }` | After Step 2 — concerns ready for review |
| `ENRICHMENTS_READY { filtered_file, counts }` | After Step 6 — enrichments ready, offer review mode |
| `ENRICHMENTS_NEED_HUMAN { present, data }` | Mid Step 7 — router presents the named prompt and collects the human response |
| `EXPLORE_COMPLETE { enrichments_accepted }` | After Step 8, or on skip-exploration — generate phase can start |

Do NOT present anything to the human — the router handles all human communication.

---

<!-- INJECT: tool-restrictions -->
