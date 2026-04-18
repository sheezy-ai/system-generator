# Component Spec Creation Orchestrator

---

## Purpose

Create a single component spec by exploring design concerns, generating a draft enriched by exploration findings, resolving gaps with the human, and iterating through additional explore→generate rounds as needed. When the human is satisfied, promote the final draft to `specs/[component-name].md` for the Review workflow.

**Flow:** Setup → [Explore → Generate → Gap Resolution]* → Promote

The explore→generate cycle can repeat for as many rounds as the human wants. Round 1 explores from the Architecture and Foundations. Round 2+ explores from the previous round's draft, finding concerns and enrichments that the earlier round missed or underexplored. The human exits the loop by choosing to promote at Gap Resolution.

---

## When to Run

Run this orchestrator for each component, after the initialize orchestrator has completed. Components should be initialized in priority order, respecting dependencies. Safe to re-invoke — the orchestrator reads its state file and resumes from the last completed step.

**Invocation:**
```
Read the Component Create Orchestrator at:
{{AGENTS_PATH}}/05-components/create/orchestrator.md

Initialize component: [component-name]
```

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

**Primary source** (determined by current round — see Path Resolution below):
- Round 1: Architecture + Foundations (two documents)
- Round N (N≥2): Latest draft from round N-1

**Explore phase outputs**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/round-{N}-create/explore/`

Files within the explore directory:
- `00-concerns.md`
- `01-explorer-{concern-name}.md`
- `02-enrichment-discussion.md`
- `02a-filtered-enrichment-discussion.md`
- `03-exploration-summary.md`

**Generate phase outputs** (in `versions/[component-name]/round-{N}-create/`):
- `00-draft-spec.md`
- `00-enrichment-applicator-output.md` (Round 2+ only)
- `00-requirements-checklist.md`
- `00-coverage-report.md`
- `00-depth-report.md`
- `01-gap-discussion.md`
- `02-author-output.md`
- `03-updated-spec.md`

**Promoted output**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/[component-name].md`

---

## Prompt Locations

```
agents/05-components/create/
├── orchestrator.md                    # This file (per-component)
├── concern-identifier.md              # Identifies design concerns to explore
├── concern-explorer.md                # Explores one concern deeply
├── exploration-consolidator.md        # Merges explorer outputs
├── enrichment-scope-filter.md         # Filters enrichments by level/depth
├── enrichment-author.md               # Produces exploration summary
├── enrichment-applicator.md           # Applies enrichments to existing draft (round 2+)
├── generator.md                       # Creates draft from Architecture + Foundations + enrichments (round 1)
├── requirements-extractor.md          # Extracts Architecture requirements checklist
├── coverage-checker.md                # Verifies draft covers all checklist items
├── depth-checker.md                   # Verifies draft meets minimum specification depth
└── author.md                          # Applies resolved gap discussions

agents/universal-agents/
├── gap-formatter.md                   # Extracts gaps into discussion format
├── gap-analyst.md                     # Proposes solutions for each gap
├── discussion-facilitator.md          # Facilitates enrichment and gap discussions
├── alignment-verifier.md              # Verifies alignment with upstream documents
└── internal-coherence-checker.md      # Verifies internal consistency

agents/05-components/review/
├── orchestrator-router.md             # Review workflow (run after create completes)
├── experts/
└── ...
```

---

## Output Directory Structure

```
system-design/05-components/
├── specs/
│   └── [component-name].md            # Promoted from create (then overwritten by Review promoter)
└── versions/
    ├── workflow-state.md              # Stage-level state
    └── [component-name]/
        ├── deferred-items.md          # Upstream gaps for this component
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
            └── 03-updated-spec.md
```

---

## Workflow State Management

**Per-component state file**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/workflow-state.md`

### On Start/Resume

1. **Check if per-component state file exists**:
   - **If NO**: Fresh start — create state file (with `Current Workflow: Create`), begin at Step 1
   - **If YES**: Read it, check `Current Workflow`:
     - **If `Review`**: Error — "Review workflow is active. Cannot re-run creation."
     - **If `Create`**: Resume from the first incomplete step

2. **Resume logic**:
   - Step 1 (Setup) is idempotent — always re-run on resume for validation
   - Step 2 (Concern Identifier) — if marked complete, verify `{explore-dir}/00-concerns.md` exists and skip
   - Step 3 resumes at WAITING_FOR_HUMAN — re-read concerns file and present to human
   - Steps 2–8 (Explore phase) — if all marked SKIPPED, jump to Step 9
   - Step 7 resumes at WAITING_FOR_HUMAN — re-read filtered enrichment discussion file and continue loop
   - Step 9 (Generator) is non-idempotent — if marked complete, verify draft exists and skip
   - Step 10 (Gap Resolution) — if marked complete, skip to Step 11
   - Step 11 resumes at WAITING_FOR_HUMAN — present promote/another-round choice to human

3. **Update state file** at each step transition (instructions inline below)

4. **Resolve paths** using Path Resolution (below) before executing any step

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
- [ ] Step 10: Gap Resolution
- [ ] Step 11: Promote or Continue
- [ ] Step 11b: Creation Verification

### Phase 3: Promote
- [ ] Step 12: Promote & Report

## Explore Details

Concerns: [CON-1, CON-2, ...] or [none]
Enrichments Accepted: [N]
Enrichments Rejected: [N]

## History
- YYYY-MM-DD: Creation workflow started
```

---

## Orchestration Steps

**Immediate execution**: The user invoking this orchestrator IS the instruction to execute. Do not ask for confirmation before starting. Proceed immediately with Step 1.

**State file updates**: Update the per-component state file before and after each step as instructed below. These updates enable workflow resume and provide audit trail.

**IMPORTANT: File-First Principle**
- Do NOT pass file contents or summaries to agents
- Only pass file PATHS — agents read files themselves

**Orchestrator Boundaries**
- You READ input files to validate they exist
- You SPAWN agents to do work
- You UPDATE stage state (component index) and per-component state
- You COPY the final draft to `specs/[component-name].md` (promotion)
- You DO NOT write draft spec content, exploration content, or author output — agents do that
- You DO NOT answer, analyse, or respond to human discussion points — discussion facilitator agents do that
- Spawn agents in FOREGROUND (not background) — agents need interactive approval for file writes

**Context management**: The orchestrator persists across the entire creation lifecycle. Every document you Read stays in context. Spawned subagents run in their own context via the Task tool. Keep your context lean — use Grep for targeted extraction from state and output files, `ls` for existence checks. Working files are read by subagents, not by the orchestrator.

**What You Read:**
- Workflow state file (to determine current step and status)
- Agent output files (to verify completion and extract counts for handoff messages)
- Architecture and Foundations in Step 1 (deferred items validation) — this is structural validation (topic addressed yes/no), not content generation

**What You Do NOT Read:**
- Agent prompt files — agents read their own instructions
- Input documents being passed to agents (Architecture, Foundations, guide, brief, etc.)
- Any file where you're passing the path to an agent for content processing

Rule: If a file path appears in your agent invocation, don't read it yourself. Exception: deferred items validation requires checking whether upstream documents address specific topics.

**Agent Invocation Pattern**

When spawning subagents via Task tool:
- Point to the agent prompt file as the sole instruction source
- Provide only runtime-specific paths (input files, output files)
- Do NOT add instructions that duplicate the prompt file content

```
Follow the instructions in: [agent-prompt-path]

Input: [resolved file paths]
Output: [resolved file path]
```

### Path Resolution

Before executing any step, resolve these paths based on the current round number (read `Current Round` from the state file):

**Primary source** (`{primary-source}`):
- Round 1: Two documents — `{{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md` and `{{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md`
- Round N (N≥2): Determine from round N-1 outputs:
  - If `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/round-{N-1}-create/03-updated-spec.md` exists → use it
  - Otherwise → use `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/round-{N-1}-create/00-draft-spec.md`

**Explore directory** (`{explore-dir}`): `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/round-{N}-create/explore/`

**Round directory** (`{round-dir}`): `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/round-{N}-create/`

All steps below use `{primary-source}`, `{explore-dir}`, and `{round-dir}` to refer to these resolved paths. **Resolve them once at startup and again after any round increment.**

---

## Phase 1: Explore

### Step 1: Setup

0. **Update per-component state file**: Set status = IN_PROGRESS, phase = Explore (create state file if fresh start)

1. **Check stage state exists** at `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/workflow-state.md`
   - **If NO**: Error — "Run the Component Specs initialize orchestrator first"

2. **Read stage state** and validate:
   - Component exists in Component Specs table
   - Component status is `NOT_STARTED` (not already initialized or complete)

3. **Check dependencies** (from Component Dependencies table in stage state):
   - If component has dependencies listed, verify all have status `COMPLETE` in Component Specs table
   - **If any dependency not COMPLETE**: Error — "Cannot initialize [component]. Blocked by: [list incomplete dependencies]"

4. **Validate deferred-items state** (Round 1 only):
   - Read stage state and confirm `Stage Initialization: Status: COMPLETE`
   - If COMPLETE, verify both of the following:
     - The monolithic `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/deferred-items.md` does NOT exist, or if it exists, contains only the archived-header stub (no COMP-D items)
     - The per-component file `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/deferred-items.md` exists (empty content is fine; absent file is not)
   - **If either check fails**: Error — see Error Handling table (Deferred-items state inconsistent)

5. **Create directories** (if not exist):
   ```
   {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/
   └── round-{N}-create/
       └── explore/
   ```

6. **Deferred Items Intake** (Round 1 only):

   a. **Check if deferred items file exists** at `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/deferred-items.md`

   b. **If file doesn't exist or no PENDING items**: Continue

   c. **If has PENDING items**:
      - Read final upstream documents (Architecture, Foundations)
      - For each PENDING item, validate relevance:
        - `RESOLVED_UPSTREAM`: Fully addressed — mark closed
        - `PARTIALLY_ADDRESSED`: Touched but not resolved — keep for exploration/generation
        - `STILL_RELEVANT`: Not addressed — keep for exploration/generation
      - Update deferred items with validation results

7. **Check for Brief**: Check if brief document exists at `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/brief.md`
   - If an explicit brief path was provided in the invocation, use that instead
   - If brief exists: Will be passed to Generator as additional input
   - If no brief: Continue without (standard generation)

8. **Update state file**: Mark "Step 1: Setup" complete `[x]`, add history entry

### Step 2: Concern Identifier

**On resume**: If Step 2 already marked complete, verify `{explore-dir}/00-concerns.md` exists and skip to Step 3.

1. **Spawn Concern Identifier agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/concern-identifier.md

   Input:
   - Component: [component-name]
   - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
   - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md
   - Component guide: {{GUIDES_PATH}}/05-components-guide.md
   - Cross-cutting spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/cross-cutting.md
   - Deferred items: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/deferred-items.md
   - Cross-cutting deferred items: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/cross-cutting/deferred-items.md
   - Workflow state: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/workflow-state.md

   Output: {explore-dir}/00-concerns.md
   ```

2. **Wait for agent to complete**

3. **Verify output exists** at `{explore-dir}/00-concerns.md`

4. **Read the concerns file** — Count concerns. If fewer than 2 concerns identified:
   - **Update state file**: Set `Explore Phase` = `skipped`, mark Steps 2–8 as `[x] SKIPPED`, add history entry "Fewer than 2 concerns — skipping exploration"
   - **Skip to Step 9**

5. **Update state file**: Mark "Step 2: Concern Identifier" complete `[x]`, record concern list, add history entry

### Step 3: Concern Review (`WAITING_FOR_HUMAN`)

**On resume**: If status = WAITING_FOR_HUMAN for Step 3, re-read concerns file and present to human.

1. **Update state file**: Set status = WAITING_FOR_HUMAN

2. **Notify user** that concerns are ready for review:
   ```
   Design concerns identified for exploration.

   Concerns file: {explore-dir}/00-concerns.md

   [N] concerns identified:
   - CON-1: [Name] — [Focus]
   - CON-2: [Name] — [Focus]
   - ...

   Please review the concerns file:
   - Accept as-is: "looks good" / "continue"
   - Add a concern: Edit the file to add a new CON entry
   - Remove a concern: Edit the file to remove the CON entry
   - Modify focus: Edit the file to adjust the focus/questions
   - Skip exploration entirely: "skip exploration"

   When ready, let me know.
   ```

**STOP: Wait for human response before proceeding.**

3. **After human responds**:
   - If human says "skip exploration" → Set `Explore Phase` = `skipped`, mark Steps 3–8 as `[x] SKIPPED`, skip to Step 9
   - Otherwise → Re-read concerns file (human may have edited it), update concern list in state file

4. **Update state file**: Mark "Step 3: Concern Review" complete `[x]`, set status = IN_PROGRESS, add history entry

### Step 4: Concern Explorers (parallel)

1. **Read the concerns file** to get the final list of accepted concerns

2. **Spawn Concern Explorer agents** using Task tool (one per concern, in parallel):
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/concern-explorer.md

   Input:
   - Component: [component-name]
   - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
   - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md
   - Cross-cutting spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/cross-cutting.md
   - Concerns file: {explore-dir}/00-concerns.md
   - Deferred items: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/deferred-items.md
   - Cross-cutting deferred items: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/cross-cutting/deferred-items.md
   - Assigned concern: CON-[N]

   Output: {explore-dir}/01-explorer-{concern-name}.md
   ```

   Replace `{concern-name}` with a kebab-case version of the concern name.

3. **Wait for all explorers to complete**

4. **Verify outputs exist** — Check each expected `01-explorer-*.md` file exists in `{explore-dir}/`

5. **Update state file**: Mark "Step 4: Concern Explorers" complete `[x]`, add history entry with explorer count

### Step 5: Exploration Consolidator

1. **Spawn Exploration Consolidator agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/exploration-consolidator.md

   Input:
   - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
   - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md
   - Explorer outputs: {explore-dir}/01-explorer-*.md
     [List all explorer files explicitly]

   Output: {explore-dir}/02-enrichment-discussion.md
   ```

2. **Wait for agent to complete**

3. **Verify output exists** at `{explore-dir}/02-enrichment-discussion.md`

4. **Read output** — Count enrichments for the Step 7 handoff message

5. **Update state file**: Mark "Step 5: Exploration Consolidator" complete `[x]`, add history entry with enrichment count

### Step 6: Enrichment Scope Filter

1. **Spawn Enrichment Scope Filter agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/enrichment-scope-filter.md

   Input:
   - Component guide: {{GUIDES_PATH}}/05-components-guide.md
   - Enrichment discussion: {explore-dir}/02-enrichment-discussion.md

   Output: {explore-dir}/02a-filtered-enrichment-discussion.md
   ```

2. **Wait for agent to complete**

3. **Verify output exists** at `{explore-dir}/02a-filtered-enrichment-discussion.md`

4. **Read filtering summary** from the output file — extract kept/deferred/filtered counts for the handoff message

5. **Update state file**: Mark "Step 6: Enrichment Scope Filter" complete `[x]`, add history entry with filtering counts

### Step 7: Enrichment Review (`WAITING_FOR_HUMAN`)

**On resume**: If status = WAITING_FOR_HUMAN for Step 7, re-read `{explore-dir}/02a-filtered-enrichment-discussion.md` and continue the review loop from step 7(a) below.

1. **Update state file**: Set status = WAITING_FOR_HUMAN

2. **Notify user** enrichments are ready for review:
   ```
   Exploration complete — [N] enrichment proposals ready for review (after scope filtering).

   Discussion file: {explore-dir}/02a-filtered-enrichment-discussion.md

   [If items were deferred or filtered, include:]
   Scope filtering: [D] deferred upstream, [F] filtered (too detailed for spec)

   [N] enrichments from [M] concerns, grouped by spec section impact.

   Each enrichment has analysis, trade-offs, and a recommendation.
   Please review each and respond after the >> HUMAN: markers.

   Respond naturally — say what you think. Examples:
   - Accept: "Happy with this", "Accept", "Agree", "Yes"
   - Reject: "Disagree — [reason]", "Not needed", "Reject"
   - Accept with changes: State what to change
   - Question/discuss: Ask your question or raise a concern

   When done, let me know and I'll process your responses.
   ```

**STOP: Wait for human response before proceeding.**

Do NOT process enrichments until the human has added actual response content after `>> HUMAN:` markers. An empty `>> HUMAN:` marker is a placeholder, not a response.

Only proceed to step 3 after the human signals they have responded.

3. **Enrichment review loop** (operates on `{explore-dir}/02a-filtered-enrichment-discussion.md`):

    a. **Identify enrichments needing processing**: Read file, find enrichments where last entry is `>> HUMAN:` with content but no `>> RESOLVED`

    b. **Interpret and confirm** — For each enrichment with a human response:

       **Phase 1 — Interpret intent**: Read the human's response and classify:

       **Prerequisite — Verify explicit positive signal**: Before classifying as ACCEPT, verify the response contains explicit positive words ("happy", "agree", "accept", "yes", "good"). Substantive engagement (questions, challenges) is not an implicit acceptance.

       - **ACCEPT**: Clear agreement with the enrichment as proposed
       - **REJECT**: Clear disagreement
       - **ACCEPT WITH MODIFICATION**: Agreement with changes
       - **ACCEPT WITH DISCUSSION**: Agreement combined with a question or concern
       - **QUESTION/DISCUSSION**: Question or concern without clear accept/reject

       **Phase 2 — Confirm**: Present ALL interpretations to the human at once:
       ```
       Here's how I interpret your responses:

       ENR-001: **Accept** — agreed with the proposed approach
       ENR-002: **Reject** — you disagree with this direction
       ENR-003: **Accept with modification** — keep but adjust per your note
       [... all enrichments with responses ...]

       Is that correct? (Clarify any I got wrong and I'll re-interpret.)
       ```

       **STOP: Wait for human to confirm or correct before proceeding.**

       After confirmation, apply the confirmed classifications:
       - ACCEPT → Add `>> RESOLVED [ACCEPTED]` after the human response
       - REJECT → Add `>> RESOLVED [REJECTED]` after the human response
       - ACCEPT WITH MODIFICATION → Add `>> RESOLVED [ACCEPTED]` after the human response
       - ACCEPT WITH DISCUSSION → Leave unresolved for discussion facilitator
       - QUESTION/DISCUSSION → Leave unresolved for discussion facilitator

    c. **If any enrichments need discussion** (ACCEPT WITH DISCUSSION or QUESTION/DISCUSSION):
       - **Spawn Discussion Facilitator agents** (batched by group):
         ```
         Follow the instructions in: {{AGENTS_PATH}}/universal-agents/discussion-facilitator.md

         Context documents:
         - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
         - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md

         Issues file: {explore-dir}/02a-filtered-enrichment-discussion.md
         Issues: [ENR-001, ENR-002, ...]
         ```
       - Wait for agents to complete
       - Present to human: "Please review the agent responses and reply to each enrichment."
       - Wait for human response
       - **After human responds**, read file and for each discussed enrichment:
         - If last entry is `>> HUMAN:` after `>> AGENT:` AND response indicates closure → add `>> RESOLVED [ACCEPTED]` or `>> RESOLVED [REJECTED]`
         - If last entry is `>> HUMAN:` with question, pushback, or request → leave open
       - **If any enrichments still unresolved**: Return to step (a)

    c2. **Resolution indicators** (human response after `>> AGENT:` that signals done):
        - Agreement: "Yes", "Agreed", "That works", "Fine", "OK"
        - Dismissal: "Not a concern", "Not relevant", "Ignore", "Skip"
        - Acceptance: "Makes sense", "Fair enough", "Understood"

    c3. **Continue discussion indicators** (do NOT mark resolved):
        - Questions: "?", "What about", "How would", "Can you"
        - Requests: "Please", "Can you", "I'd like", "Show me"
        - Pushback: "I disagree", "That's not right", "But what about"

    d. **If all enrichments resolved**: Continue to Step 8

4. **Update state file**: Mark "Step 7: Enrichment Review" complete `[x]`, set status = IN_PROGRESS, record accepted/rejected counts, add history entry

### Step 8: Enrichment Author

1. **Check if any enrichments were accepted** — Read `{explore-dir}/02a-filtered-enrichment-discussion.md` for `>> RESOLVED [ACCEPTED]` markers. If zero accepted:
   - No exploration summary needed — Step 9 Generator will run from primary source only
   - Update state file: Mark "Step 8: Enrichment Author" complete `[x]`, set `Explore Phase` = `complete`, add history entry "No enrichments accepted — Generator will use primary source only"
   - Proceed to Step 9

2. **Spawn Enrichment Author agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/enrichment-author.md

   Input:
   - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
   - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md
   - Component guide: {{GUIDES_PATH}}/05-components-guide.md
   - Filtered enrichment discussion: {explore-dir}/02a-filtered-enrichment-discussion.md

   Output: {explore-dir}/03-exploration-summary.md
   ```

3. **Wait for agent to complete**

4. **Verify output exists** at `{explore-dir}/03-exploration-summary.md`

5. **Update state file**: Mark "Step 8: Enrichment Author" complete `[x]`, set `Explore Phase` = `complete`, set phase = Generate, add history entry

---

## Phase 2: Generate

### Step 9: Generate or Apply Enrichments

**On resume**: If Step 9 already marked complete, verify `{round-dir}/00-draft-spec.md` exists and skip to Step 9b. For round 1: do NOT re-run the Generator (it appends to downstream deferred items files and would create duplicates).

**Round 1** and **Round 2+** use different approaches:
- **Round 1**: No prior draft exists — the Generator creates the spec from scratch
- **Round 2+**: A prior draft exists — the Enrichment Applicator applies accepted enrichments as targeted edits to the previous round's draft

#### Round 1: Run Generator

1. **Determine exploration summary path**: Check if `{explore-dir}/03-exploration-summary.md` exists. If yes, include it as input. If no (exploration was skipped or no enrichments accepted), omit it.

2. **Spawn Generator agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/generator.md

   Input:
   - Component: [component-name]
   - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
   - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md
   - Component guide: {{GUIDES_PATH}}/05-components-guide.md
   - Deferred items: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/deferred-items.md
   - Cross-cutting spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/cross-cutting.md
   - Cross-cutting deferred items: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/cross-cutting/deferred-items.md
   - Brief: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/brief.md (if exists)
   [If exploration summary exists:]
   - Exploration summary: {explore-dir}/03-exploration-summary.md

   Output: {round-dir}/00-draft-spec.md
   ```

3. **Wait for Generator to complete**

4. **Verify output exists** at `{round-dir}/00-draft-spec.md`

5. **Update state file**: Mark "Step 9: Generate or Apply Enrichments" complete `[x]`, add history entry

#### Round 2+: Apply Enrichments

1. **Copy previous round's draft** to `{round-dir}/00-draft-spec.md` using Bash cp:
   ```
   cp [previous round's latest draft per Path Resolution] {round-dir}/00-draft-spec.md
   ```

2. **Determine exploration summary path**: Check if `{explore-dir}/03-exploration-summary.md` exists.
   - **If NO** (exploration was skipped or no enrichments accepted): Draft is already copied with no changes needed. Skip to step 5.
   - **If YES**: Continue to step 3.

3. **Spawn Enrichment Applicator agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/enrichment-applicator.md

   Input:
   - Draft Spec: {round-dir}/00-draft-spec.md
   - Exploration summary: {explore-dir}/03-exploration-summary.md
   - Component guide: {{GUIDES_PATH}}/05-components-guide.md

   Output:
   - Updated Spec: {round-dir}/00-draft-spec.md (edit in place)
   - Change log: {round-dir}/00-enrichment-applicator-output.md
   ```

4. **Wait for Enrichment Applicator to complete**

5. **Verify output exists** at `{round-dir}/00-draft-spec.md`

6. **Update state file**: Mark "Step 9: Generate or Apply Enrichments" complete `[x]`, add history entry

### Step 9b: Coverage Verification

**Purpose**: Independently verify the draft addresses every requirement the Architecture assigns to this component. The Requirements Extractor reads the Architecture directly (not the draft) to produce a checklist, then the Coverage Checker verifies the draft against it.

**On resume**: If Step 9b already marked complete, skip to Step 9c.

1. **Spawn Requirements Extractor** (if checklist doesn't already exist):
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/requirements-extractor.md

   Input:
   - Component: [component-name]
   - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
   - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md
   - Component guide: {{GUIDES_PATH}}/05-components-guide.md
   - Deferred items: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/deferred-items.md
   - Cross-cutting spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/cross-cutting.md

   Output: {round-dir}/00-requirements-checklist.md
   ```

2. **Wait for extractor to complete** (and for Generator/Applicator if running in parallel)

3. **Verify checklist exists** at `{round-dir}/00-requirements-checklist.md`

4. **Spawn Coverage Checker**:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/coverage-checker.md

   Input:
   - Requirements checklist: {round-dir}/00-requirements-checklist.md
   - Draft Spec: {round-dir}/00-draft-spec.md
   - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md

   Output: {round-dir}/00-coverage-report.md
   ```

5. **Wait for checker to complete**

6. **Read coverage report summary** — extract GAPS_FOUND or PASS status

7. **If GAPS_FOUND**: Add any GAP items as `[TODO: Coverage gap — ...]` markers to the draft spec using targeted Edit operations, so the Gap Formatter can extract them alongside the Generator's own gap markers.

8. **Update state file**: Mark "Step 9b: Coverage Verification" complete `[x]`, add history entry with coverage counts

### Step 9c: Depth Verification

**Purpose**: Verify the draft meets minimum specification depth — every operation has typed inputs/outputs/errors, every data model element has appropriate constraints, every multi-step write has an atomicity declaration. Catches shallowness that coverage checking misses.

**On resume**: If Step 9c already marked complete, skip to Step 10.

1. **Spawn Depth Checker**:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/depth-checker.md

   Input:
   - Draft Spec: {round-dir}/00-draft-spec.md
   - Component guide: {{GUIDES_PATH}}/05-components-guide.md

   Output: {round-dir}/00-depth-report.md
   ```

2. **Wait for checker to complete**

3. **Read depth report summary** — extract SHALLOW count or PASS status

4. **If SHALLOW items found**: Add each as `[TODO: Depth gap — ...]` markers to the draft spec using targeted Edit operations, so the Gap Formatter can extract them alongside other gap markers.

5. **Update state file**: Mark "Step 9c: Depth Verification" complete `[x]`, add history entry with depth counts

### Step 10: Gap Resolution

**On resume**: If Step 10 already marked complete, skip to Step 11. If status = WAITING_FOR_HUMAN within Step 10's discussion loop, re-read `{round-dir}/01-gap-discussion.md` and continue the discussion loop from step 10.13(a).

1. **Read the draft** at `{round-dir}/00-draft-spec.md`

2. **Check for Gap Summary section** — Look for `## Gap Summary` heading

3. **If no Gap Summary, or all counts are 0**:
   - **Update state file**: Set `Gaps Exist` = `false`, mark "Step 10: Gap Resolution" complete `[x]`, add history entry "No gaps found"
   - Proceed to Step 11

4. **Spawn Gap Formatter agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/universal-agents/gap-formatter.md

   Input:
   - Draft: {round-dir}/00-draft-spec.md

   Output: {round-dir}/01-gap-discussion.md
   ```

5. **Wait for Gap Formatter to complete**

6. **Verify output exists** at `{round-dir}/01-gap-discussion.md`

7. **Read output** — count gaps by severity

8. **Spawn Gap Analyst agents** using Task tool (batch by section, 2-3 batches):
   ```
   Follow the instructions in: {{AGENTS_PATH}}/universal-agents/gap-analyst.md

   Context documents:
   - Draft Spec: {round-dir}/00-draft-spec.md
   - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
   - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md
   - Brief: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/brief.md (if exists)

   Gap discussion file: {round-dir}/01-gap-discussion.md
   Gaps: [GAP-001, GAP-002, ...]
   ```

   Batch by spec section:
   - Batch 1: Sections 1-4 (Overview, Scope, Interfaces, Data Model)
   - Batch 2: Sections 5-8 (Behaviour, Dependencies, Integration, Error Handling)
   - Batch 3: Sections 9-12 (Observability, Security, Testing, Open Questions)
   - If fewer than 4 gaps total, use fewer batches

9. **Wait for all Gap Analyst agents to complete**

10. **Verify analyst responses were written** (MANDATORY):
    - Count `>> AGENT:` markers in the gap discussion file
    - Compare to total number of gaps
    - If counts don't match: identify missing gaps and re-invoke Gap Analyst for those only

11. **Update state file**: Set `Gaps Exist` = `true`, set status = WAITING_FOR_HUMAN, add history entry with gap counts

12. **Notify user** gap analysis is ready for review:
   ```
   Gap analysis complete (round {N}).

   Discussion file: {round-dir}/01-gap-discussion.md

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

**STOP: Wait for human response before proceeding.**

Do NOT enter the discussion loop until the human has added actual response content after `>> HUMAN:` markers.

13. **Discussion loop**:

    a. **Identify gaps needing agent response**: Read file, find gaps where last entry is `>> HUMAN:` without subsequent `>> AGENT:`

    b. **For gaps where human accepted** (clear agreement indicators): Add `>> RESOLVED`

    c. **For gaps needing discussion**: Spawn Discussion Facilitator agents (batched by section):
       ```
       Follow the instructions in: {{AGENTS_PATH}}/universal-agents/discussion-facilitator.md

       Context documents:
       - Draft Spec: {round-dir}/00-draft-spec.md
       - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
       - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md

       Issues file: {round-dir}/01-gap-discussion.md
       Issues: [GAP-001, GAP-002, ...]
       ```

    d. **Wait for all agents to complete**

    e. **Verify agent responses were written** (MANDATORY)

    f. **Present to human**: "Please review the agent responses and reply to each gap."

    g. **Wait for human responses**

    h. **After human responds**, read file and for each gap:
       - If last entry is `>> HUMAN:` after `>> AGENT:` AND response indicates closure → add `>> RESOLVED`
       - If last entry is `>> HUMAN:` with question, pushback, or request → leave open

    i. **Resolution indicators** (human response after `>> AGENT:` that signals done):
       - Agreement: "Yes", "Agreed", "That works", "Fine", "OK"
       - Dismissal: "Not a concern", "Not relevant", "Ignore", "Skip"
       - Acceptance: "Makes sense", "Fair enough", "Understood"

    j. **Continue discussion indicators** (do NOT mark resolved):
       - Questions: "?", "What about", "How would", "Can you"
       - Requests: "Please", "Can you", "I'd like", "Show me"
       - Pushback: "I disagree", "That's not right", "But what about"

    k. **If any gaps unresolved**: Go to step (a)

    l. **If all gaps resolved**:
       - **Spawn Author agent** using Task tool:
         ```
         Follow the instructions in: {{AGENTS_PATH}}/05-components/create/author.md

         Input:
         - Draft Spec: {round-dir}/00-draft-spec.md
         - Gap discussion: {round-dir}/01-gap-discussion.md
         - Component guide: {{GUIDES_PATH}}/05-components-guide.md

         Output:
         - Change log: {round-dir}/02-author-output.md
         - Updated Spec: {round-dir}/03-updated-spec.md
         ```
       - Wait for Author to complete
       - Verify outputs exist

14. **Update state file**: Mark "Step 10: Gap Resolution" complete `[x]`, add history entry

### Step 11: Promote or Continue (`WAITING_FOR_HUMAN`)

**On resume**: If status = WAITING_FOR_HUMAN for Step 11, present the promote/another-round choice to the human.

1. **Update state file**: Set status = WAITING_FOR_HUMAN

2. **Notify user**:
   ```
   [If gaps were resolved:]
   All gaps resolved and applied (round {N}).
   [If no gaps:]
   Draft spec generated (round {N}) — no gaps found.

   Draft: {round-dir}/00-draft-spec.md
   [If Author ran:]
   Updated: {round-dir}/03-updated-spec.md

   You can:
   - Say "promote" — promote the current draft
   - Say "another round" — run another explore→generate cycle

   When ready, let me know.
   ```

**STOP: Wait for human response.**

3. **After human responds**:

   **If "another round"**:
   - Determine the latest draft for this round:
     - If `{round-dir}/03-updated-spec.md` exists (Author ran): use it
     - Otherwise: use `{round-dir}/00-draft-spec.md`
   - Update state file:
     - Mark "Step 11: Promote or Continue" complete `[x]`
     - Increment `Current Round`
     - Reset Steps 1–11 to unchecked `[ ]`
     - Set phase = Explore, Explore Phase = active, Gaps Exist = unknown
     - Add history entry "Round {N} complete — starting round {N+1}"
   - **Re-resolve paths** using Path Resolution with the new round number
   - **Loop to Step 1**

   **If "promote"** or "promote as-is":
   - Update state file: Mark "Step 11: Promote or Continue" complete `[x]`, add history entry "Promoting draft from round {N}"
   - Proceed to Step 11b

### Step 11b: Creation Verification

**Purpose**: Verify alignment with source documents and internal coherence before promotion. Catches misalignment and cross-section consistency gaps introduced during creation.

1. **Determine draft path**:
    - If `{round-dir}/03-updated-spec.md` exists (Author ran): Use it
    - Otherwise: Use `{round-dir}/00-draft-spec.md`

2. **Spawn both verification agents in parallel**:

    **Alignment Verifier**:
    ```
    Follow the instructions in: {{AGENTS_PATH}}/universal-agents/alignment-verifier.md

    Input:
    - Updated spec: [draft path from step 1]
    - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
    - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md
    - PRD: {{SYSTEM_DESIGN_PATH}}/system-design/02-prd/prd.md

    Output: {round-dir}/04-alignment-report.md
    ```

    **Internal Coherence Checker**:
    ```
    Follow the instructions in: {{AGENTS_PATH}}/universal-agents/internal-coherence-checker.md

    Document: [draft path from step 1]
    Stage guide: {{GUIDES_PATH}}/05-components-guide.md
    Output: {round-dir}/05-coherence-report.md
    ```

3. **Wait for both agents to complete**

4. **Read both reports** and aggregate findings:
    - Alignment report: check for HALT recommendation, SYNC_UPSTREAM, REVIEW_NEEDED
    - Coherence report: check for HIGH or MEDIUM gaps

5. **If both CLEAN** (alignment PROCEED with no issues, coherence COHERENT or LOW only):
    - Update state file: Mark "Step 11b: Creation Verification" complete `[x]`, add history entry
    - Proceed to Step 12

6. **Track rework pass count**: Count how many times verification has been run in this round. The first verification is pass 1. Each FIX that returns to Author and re-runs verification increments the count.

7. **If issues found**: Present findings to human:
    ```
    [If rework pass 2+, include at top:]
    > **Rework pass [N]**: This is verification after rework pass [N]. Diminishing returns are expected — each fix may surface progressively more peripheral cross-section implications.

    Creation verification found issues:

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
    For each: **FIX** (return to Author) or **ACCEPT** (promote as-is)?
    ```
    - If FIX: Spawn Author to address issues, then re-run verification
    - If ACCEPT: Proceed to Step 12
    - Update state file: Mark "Step 11b: Creation Verification" complete `[x]`, add history entry

---

## Phase 3: Promote

Phase 3 runs only when the human chooses to promote at Step 11, exiting the explore→generate loop.

### Step 12: Promote & Report

1. **Determine final draft path** (from the current round):
    - If `{round-dir}/03-updated-spec.md` exists (Author ran): Use it
    - Otherwise: Use `{round-dir}/00-draft-spec.md`

2. **Copy final draft to specs** using Bash cp:
    ```
    cp [final draft path] {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/[component-name].md
    ```

3. **Verify promotion** — Confirm `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/[component-name].md` exists

4. **Update stage state** (`{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/workflow-state.md`):
    - Component Specs table: Update component row status `NOT_STARTED` → `DRAFT_READY`, set Last Updated to today's date
    - Add history entry: "[date]: [component-name] creation workflow complete"

5. **Update per-component state file**: Mark "Step 12: Promote & Report" complete `[x]`, set status = COMPLETE, add history entry

6. **Present summary**:
    ```
    Component [component-name] creation complete (after {total_rounds} round(s)).

    Final round ({N}):
    - [N] concerns explored, [M] enrichments accepted, [K] rejected
    [If exploration was skipped in final round:]
    - Exploration skipped

    Final draft: {round-dir}/00-draft-spec.md
    [If Author ran in final round:]
    Updated: {round-dir}/03-updated-spec.md
    Promoted to: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/[component-name].md

    [If gaps existed in final round:]
    Gap resolution:
    - [N] gaps in final draft
    - [Resolved by: direct edit / Author / deferred to review]

    [If no gaps in final round:]
    No gaps found in final draft.

    Next steps:
    1. Review specs/[component-name].md — verify promoted content looks correct
    2. When ready, run the Component Review workflow for [component-name]
       (Review reads from: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/[component-name].md)
    ```

---

## Stopping Points

**Automatic flow (do NOT pause for human confirmation):**
- Steps 1 → 2: Setup then identifier
- Steps 4 → 5 → 6: Explorers then consolidator then scope filter
- Steps 8 → 9 → 9b → 9c: Enrichment author then generator/applicator then coverage then depth
- Step 10: Gap resolution (Gap formatter → Gap analyst → discussion loop → Author)
- Steps 11b → 12: Verification then promote (unless issues found)

**Automatic flow discipline**: Between automatic steps, the orchestrator updates state and spawns the next agent without pausing. Do not read files unless the step instructions explicitly direct you to. Each step already specifies what the orchestrator reads. If a read is not in the step instructions, do not perform it — agents read their own inputs.

**Human checkpoints:**
- **Step 3** — WAITING_FOR_HUMAN for concern review
- **Step 7** — WAITING_FOR_HUMAN for enrichment review until all enrichments resolved
- **Step 10** — WAITING_FOR_HUMAN within gap discussion loop (sub-steps 12-13)
- **Step 11** — WAITING_FOR_HUMAN for promote vs another round

**Skip paths:**
- **Explore skip** — If fewer than 2 concerns (Step 2) or human says "skip" (Step 3) → jump to Step 9
- **Gap skip** — If no gaps in draft (Step 10) → Step 10 completes immediately, Step 11 still presents promote/another-round choice

**Loop path:**
- **Another round** — If human says "another round" at Step 11 → increment round, reset Steps 1–11, loop to Step 1

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Stage state not found | Error: "Run the Component Specs initialize orchestrator first" |
| Component not in stage state | Error: "Component [name] not found in Component Specs table" |
| Component not NOT_STARTED | Error: "Component [name] status is [status], expected NOT_STARTED" |
| Dependencies incomplete | Error: "Cannot initialize [component]. Blocked by: [list]" |
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
| Promotion copy fails | Error: "Failed to copy final draft to specs/[component-name].md" |
| State file corrupted/unreadable | Warning: Report issue, re-create state from file existence checks |
| Resume: draft missing but Step 9 marked complete | Error: "State says Generator complete but draft not found — re-run Generator or fix state file" |
| Round N primary source missing | Error: "Round {N} requires draft from round {N-1} but no draft found" |
| Current Workflow = Review | Error: "Review workflow is active. Cannot re-run creation." |

---

## What Happens Next

After this orchestrator completes:

1. **Human reviews promoted spec** — Opens `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/[component-name].md`
2. **Human optionally makes manual edits** — Can refine directly
3. **Human runs Review workflow** — Invokes the Component Review orchestrator for this component

**IMPORTANT**: The Review workflow reads from `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/[component-name].md` for Round 1. This file is created by the promotion step (Step 12). It MUST exist before starting the Review workflow.

The Review workflow will:
- Run expert reviewers on the spec (Build part, then Ops part)
- Facilitate discussion on issues found
- Author the updated spec
- Verify alignment with Architecture and Foundations
- Verify contract conformance

---

<!-- INJECT: tool-restrictions -->
