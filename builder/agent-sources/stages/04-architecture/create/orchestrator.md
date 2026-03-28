# Architecture Overview Creation Orchestrator

---

## Purpose

Initialize the Architecture stage by setting up structure, exploring architectural concerns from the PRD and Foundations that need structured analysis, generating a draft Architecture Overview enriched by exploration findings, resolving gaps with the human, and iterating through additional explore→generate rounds as needed. When the human is satisfied, promote the final draft.

**Flow:** Setup → [Explore → Generate → Gap Resolution]* → Promote

The explore→generate cycle can repeat for as many rounds as the human wants. Round 1 explores from the PRD and Foundations. Round 2+ explores from the previous round's draft, finding concerns and enrichments that the earlier round missed or underexplored. The human exits the loop by choosing to promote at Gap Resolution.

---

## When to Run

Run this orchestrator at the start of the Architecture stage, after the PRD and Foundations are complete. Safe to re-invoke — the orchestrator reads its state file and resumes from the last completed step.

---

## Fixed Paths

**PRD**: `system-design/02-prd/prd.md`
**Foundations**: `system-design/03-foundations/foundations.md`
**State file**: `system-design/04-architecture/versions/workflow-state.md`

**Primary source** (determined by current round — see Path Resolution below):
- Round 1: PRD + Foundations (two documents)
- Round N (N≥2): Latest draft from round N-1

**Explore phase outputs**: `system-design/04-architecture/versions/create/round-{N}/explore/`

Files within the explore directory:
- `00-concerns.md`
- `01-explorer-{concern-name}.md`
- `02-enrichment-discussion.md`
- `02a-filtered-enrichment-discussion.md`
- `03-exploration-summary.md`

**Generate phase outputs** (in `versions/create/round-{N}/`):
- `00-draft-architecture.md`
- `01-gap-discussion.md`
- `02-author-output.md`
- `03-updated-architecture.md`

**Brief (optional)**: `system-design/04-architecture/brief.md`
**Promoted output**: `system-design/04-architecture/architecture.md`
**Final outputs** (created by Review workflow promoter — overwrites promoted output):
- `system-design/04-architecture/architecture.md` — Clean current-scope Architecture Overview
- `system-design/04-architecture/decisions.md` — Design rationale and trade-offs
- `system-design/04-architecture/future.md` — Deferred items and future considerations

---

## Prompt Locations

```
agents/04-architecture/create/
├── orchestrator.md                    # This file
├── concern-identifier.md              # Identifies architectural concerns to explore
├── concern-explorer.md                # Explores one concern deeply
├── exploration-consolidator.md        # Merges explorer outputs
├── enrichment-scope-filter.md         # Filters enrichments by level/depth
├── enrichment-author.md               # Produces exploration summary
├── generator.md                       # Creates draft from PRD + Foundations + enrichments (round 1)
├── enrichment-applicator.md           # Applies enrichments to existing draft (round 2+)
└── author.md                          # Applies resolved gap discussions

agents/universal-agents/
├── gap-formatter.md                   # Extracts gaps into discussion format
├── gap-analyst.md                     # Proposes solutions for each gap
└── discussion-facilitator.md          # Facilitates enrichment and gap discussions

agents/04-architecture/review/
├── orchestrator.md                    # Review workflow (run after create completes)
├── experts/
└── workflow/
```

---

## Output Directory Structure

```
system-design/04-architecture/
├── architecture.md                # Promoted from create (then overwritten by Review promoter)
├── decisions.md                   # Design rationale (created by Review promoter)
├── future.md                      # Deferred items (created by Review promoter)
└── versions/
    ├── deferred-items.md           # Upstream gaps for this stage
    ├── pending-issues.md          # Issues logged against this stage
    ├── workflow-state.md              # Unified workflow state (shared with Review)
    └── create/
        ├── round-1/
        │   ├── explore/
        │   │   ├── 00-concerns.md
        │   │   ├── 01-explorer-*.md
        │   │   ├── 02-enrichment-discussion.md
        │   │   ├── 02a-filtered-enrichment-discussion.md
        │   │   └── 03-exploration-summary.md
        │   ├── 00-draft-architecture.md
        │   ├── 00-enrichment-applicator-output.md  # Round 2+ only
        │   ├── 01-gap-discussion.md
        │   ├── 02-author-output.md
        │   └── 03-updated-architecture.md
        └── round-{N}/
            ├── explore/
            │   └── [same explore files]
            └── [same generate files]
```

---

## Workflow State Management

**State file**: `system-design/04-architecture/versions/workflow-state.md`

### On Start/Resume

1. **Check if state file exists**:
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
   - Step 10 resumes at WAITING_FOR_HUMAN — re-read draft and present gap summary to human

3. **Update state file** at each step transition (instructions inline below)

4. **Resolve paths** using Path Resolution (below) before executing any step

### State File Format

```markdown
# Architecture Workflow State

**Architecture**: 04-architecture/architecture.md
**Current Workflow**: Create
**Current Phase**: Explore | Generate | Promote
**Current Round**: 1
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
- [ ] Step 10: Gap Resolution

### Phase 3: Promote
- [ ] Step 11: Promote & Report

## Explore Details

Concerns: [CON-1, CON-2, ...] or [none]
Enrichments Accepted: [N]
Enrichments Rejected: [N]

## History
- YYYY-MM-DD HH:MM: Creation workflow started
```

---

## Orchestration Steps

**Immediate execution**: The user invoking this orchestrator IS the instruction to execute. Do not ask for confirmation before starting. Proceed immediately with Step 1.

**State file updates**: Update the state file before and after each step as instructed below. These updates enable workflow resume and provide audit trail.

**IMPORTANT: File-First Principle**
- Do NOT pass file contents or summaries to agents
- Only pass file PATHS — agents read files themselves

**Orchestrator Boundaries**
- You READ input files to validate they exist
- You SPAWN agents to do work
- You CREATE structure files (deferred-items.md, pending-issues.md, gap-resolutions.md)
- You COPY the final draft to `architecture.md` (promotion)
- You DO NOT write draft content, exploration content, or author output — agents do that
- You DO NOT answer, analyse, or respond to human discussion points — discussion facilitator agents do that
- Spawn agents in FOREGROUND (not background) — agents need interactive approval for file writes

**Context management**: The orchestrator persists across the entire creation lifecycle. Every document you Read stays in context. Spawned subagents run in their own context via the Task tool. Keep your context lean — use Grep for targeted extraction from state and output files, `ls` for existence checks. Working files are read by subagents, not by the orchestrator.

**What You Read:**
- Workflow state file (to determine current step and status)
- Agent output files (to verify completion and extract counts for handoff messages)
- PRD and Foundations in Step 1 (deferred items validation) — this is structural validation (topic addressed yes/no), not content generation

**What You Do NOT Read:**
- Agent prompt files — agents read their own instructions
- Input documents being passed to agents (PRD for generation, Foundations, guide, brief, etc.)
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
- Round 1: Two documents — `system-design/02-prd/prd.md` and `system-design/03-foundations/foundations.md`
- Round N (N≥2): Determine from round N-1 outputs:
  - If `system-design/04-architecture/versions/create/round-{N-1}/03-updated-architecture.md` exists → use it
  - Otherwise → use `system-design/04-architecture/versions/create/round-{N-1}/00-draft-architecture.md`

**Explore directory** (`{explore-dir}`): `system-design/04-architecture/versions/create/round-{N}/explore/`

**Round directory** (`{round-dir}`): `system-design/04-architecture/versions/create/round-{N}/`

All steps below use `{primary-source}`, `{explore-dir}`, and `{round-dir}` to refer to these resolved paths. **Resolve them once at startup and again after any round increment.**

---

## Phase 1: Explore

### Step 1: Setup

0. **Update state file**: Set status = IN_PROGRESS, phase = Explore (create state file if fresh start)

1. **Create directories** (if not exist):

   **Round 1 (first run):**
   ```
   system-design/04-architecture/
   └── versions/
       └── create/
           └── round-1/
               └── explore/
   ```

   **Round N (N≥2, "another round"):**
   ```
   system-design/04-architecture/versions/create/
   └── round-{N}/
       └── explore/
   ```

2. **Create deferred-items.md** (if not exists) at `system-design/04-architecture/versions/deferred-items.md`:
   ```markdown
   # Architecture Deferred Items

   Items deferred for later consideration or downstream stages.

   ---

   <!-- No deferred items yet -->
   ```

3. **Create pending-issues.md** (if not exists) at `system-design/04-architecture/versions/pending-issues.md`:
   ```markdown
   # Pending Issues: Architecture

   Issues discovered that need resolution.

   ---

   <!-- No issues logged yet -->
   ```

4. **Ensure downstream deferred items files exist** (Generator may append to these):
   - `system-design/05-components/versions/deferred-items.md`

5. **Deferred Items Intake** (Round 1 only):

   a. **Read deferred items** at `system-design/04-architecture/versions/deferred-items.md`
      - Note: May already contain items deferred by PRD or Foundations Generators

   b. **If empty or no PENDING items**: Continue

   c. **If has PENDING items**:
      - Read final upstream documents (PRD, Foundations)
      - For each PENDING item, validate relevance:
        - `RESOLVED_UPSTREAM`: Fully addressed — mark closed
        - `PARTIALLY_ADDRESSED`: Touched but not resolved — keep for exploration/generation
        - `STILL_RELEVANT`: Not addressed — keep for exploration/generation
      - Update deferred items with validation results

6. **Check for Brief**: Check if brief document exists at `system-design/04-architecture/brief.md`
   - If an explicit brief path was provided in the invocation, use that instead
   - If brief exists: Will be passed to Generator as additional input
   - If no brief: Continue without (standard generation)

7. **Update state file**: Mark "Step 1: Setup" complete `[x]`, add history entry

### Step 2: Concern Identifier

**On resume**: If Step 2 already marked complete, verify `{explore-dir}/00-concerns.md` exists and skip to Step 3.

1. **Verify primary source exists** — Read `{primary-source}` to confirm it's present

2. **Spawn Concern Identifier agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/04-architecture/create/concern-identifier.md

   Input:
   - PRD: system-design/02-prd/prd.md
   - Foundations: system-design/03-foundations/foundations.md
   - Architecture guide: {{GUIDES_PATH}}/04-architecture-guide.md
   - Deferred items: system-design/04-architecture/versions/deferred-items.md
   - Workflow state: system-design/04-architecture/versions/workflow-state.md

   Output: {explore-dir}/00-concerns.md
   ```

3. **Wait for agent to complete**

4. **Verify output exists** at `{explore-dir}/00-concerns.md`

5. **Read the concerns file** — Count concerns. If fewer than 2 concerns identified:
   - **Update state file**: Set `Explore Phase` = `skipped`, mark Steps 2–8 as `[x] SKIPPED`, add history entry "Fewer than 2 concerns — skipping exploration"
   - **Skip to Step 9**

6. **Update state file**: Mark "Step 2: Concern Identifier" complete `[x]`, record concern list, add history entry

### Step 3: Concern Review (`WAITING_FOR_HUMAN`)

**On resume**: If status = WAITING_FOR_HUMAN for Step 3, re-read concerns file and present to human.

1. **Update state file**: Set status = WAITING_FOR_HUMAN

2. **Notify user** that concerns are ready for review:
   ```
   Architectural concerns identified for exploration.

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
   Follow the instructions in: {{AGENTS_PATH}}/04-architecture/create/concern-explorer.md

   Input:
   - PRD: system-design/02-prd/prd.md
   - Foundations: system-design/03-foundations/foundations.md
   - Concerns file: {explore-dir}/00-concerns.md
   - Deferred items: system-design/04-architecture/versions/deferred-items.md
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
   Follow the instructions in: {{AGENTS_PATH}}/04-architecture/create/exploration-consolidator.md

   Input:
   - PRD: system-design/02-prd/prd.md
   - Foundations: system-design/03-foundations/foundations.md
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
   Follow the instructions in: {{AGENTS_PATH}}/04-architecture/create/enrichment-scope-filter.md

   Input:
   - Architecture guide: {{GUIDES_PATH}}/04-architecture-guide.md
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
   Scope filtering: [D] deferred to downstream, [F] filtered (depth exceeded)

   [N] enrichments from [M] concerns, grouped by Architecture section impact.

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

       ENR-001: **Accept** — agreed with the proposed decomposition
       ENR-002: **Reject** — you disagree with separating these concerns
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
         - PRD: system-design/02-prd/prd.md
         - Foundations: system-design/03-foundations/foundations.md

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
   Follow the instructions in: {{AGENTS_PATH}}/04-architecture/create/enrichment-author.md

   Input:
   - PRD: system-design/02-prd/prd.md
   - Foundations: system-design/03-foundations/foundations.md
   - Architecture guide: {{GUIDES_PATH}}/04-architecture-guide.md
   - Filtered enrichment discussion: {explore-dir}/02a-filtered-enrichment-discussion.md

   Output: {explore-dir}/03-exploration-summary.md
   ```

3. **Wait for agent to complete**

4. **Verify output exists** at `{explore-dir}/03-exploration-summary.md`

5. **Update state file**: Mark "Step 8: Enrichment Author" complete `[x]`, set `Explore Phase` = `complete`, set phase = Generate, add history entry

---

## Phase 2: Generate

### Step 9: Generate or Apply Enrichments

**On resume**: If Step 9 already marked complete, verify `{round-dir}/00-draft-architecture.md` exists and skip to Step 10. For round 1: do NOT re-run the Generator (it appends to downstream deferred items files and would create duplicates).

**Round 1** and **Round 2+** use different approaches:
- **Round 1**: No prior draft exists — the Generator creates the Architecture from scratch
- **Round 2+**: A prior draft exists — the Enrichment Applicator applies accepted enrichments as targeted edits to the previous round's draft

#### Round 1: Run Generator

1. **Determine exploration summary path**: Check if `{explore-dir}/03-exploration-summary.md` exists. If yes, include it as input. If no (exploration was skipped or no enrichments accepted), omit it.

2. **Spawn Generator agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/04-architecture/create/generator.md

   Input:
   - PRD: system-design/02-prd/prd.md
   - Foundations: system-design/03-foundations/foundations.md
   - Architecture guide: {{GUIDES_PATH}}/04-architecture-guide.md
   - Deferred items: system-design/04-architecture/versions/deferred-items.md
   - Brief: system-design/04-architecture/brief.md (if exists)
   [If exploration summary exists:]
   - Exploration summary: {explore-dir}/03-exploration-summary.md

   Output: {round-dir}/00-draft-architecture.md

   Downstream deferred items (Generator may append):
   - Components: system-design/05-components/versions/deferred-items.md
   ```

3. **Wait for Generator to complete**

4. **Verify output exists** at `{round-dir}/00-draft-architecture.md`

5. **Update state file**: Mark "Step 9: Generate or Apply Enrichments" complete `[x]`, add history entry

#### Round 2+: Apply Enrichments

1. **Copy previous round's draft** to `{round-dir}/00-draft-architecture.md` using Bash cp:
   ```
   cp [previous round's latest draft per Path Resolution] {round-dir}/00-draft-architecture.md
   ```

2. **Determine exploration summary path**: Check if `{explore-dir}/03-exploration-summary.md` exists.
   - **If NO** (exploration was skipped or no enrichments accepted): Draft is already copied with no changes needed. Skip to step 5.
   - **If YES**: Continue to step 3.

3. **Spawn Enrichment Applicator agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/04-architecture/create/enrichment-applicator.md

   Input:
   - Draft Architecture: {round-dir}/00-draft-architecture.md
   - Exploration summary: {explore-dir}/03-exploration-summary.md
   - Architecture guide: {{GUIDES_PATH}}/04-architecture-guide.md

   Output:
   - Updated Architecture: {round-dir}/00-draft-architecture.md (edit in place)
   - Change log: {round-dir}/00-enrichment-applicator-output.md
   ```

4. **Wait for Enrichment Applicator to complete**

5. **Verify output exists** at `{round-dir}/00-draft-architecture.md`

6. **Update state file**: Mark "Step 9: Generate or Apply Enrichments" complete `[x]`, add history entry

### Step 10: Gap Resolution

**On resume**: If status = WAITING_FOR_HUMAN for Step 10, re-read `{round-dir}/01-gap-discussion.md` and continue the gap discussion loop. If no gap discussion file exists yet, re-read the draft and start from step 1.

1. **Read the draft** at `{round-dir}/00-draft-architecture.md`

2. **Check for Gap Summary section** — Look for `## Gap Summary` heading

3. **If no Gap Summary, or all subsections empty** (Must Answer, Should Answer, and Assumptions all show "None" or similar):
   - **Update state file**: Set `Gaps Exist` = `false`, add history entry "No gaps found"
   - **Notify user**:
     ```
     Draft Architecture generated (round {N}) — no gaps found.

     Draft: {round-dir}/00-draft-architecture.md

     You can:
     - Say "promote" — promote the draft
     - Say "another round" — run another explore→generate cycle

     When ready, let me know.
     ```
   - **STOP: Wait for human response.** Handle "promote" or "another round" per step 14 below.

4. **Spawn Gap Formatter agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/universal-agents/gap-formatter.md

   Input:
   - Draft: {round-dir}/00-draft-architecture.md

   Output: {round-dir}/01-gap-discussion.md
   ```

5. **Wait for Gap Formatter to complete**

6. **Verify output exists** at `{round-dir}/01-gap-discussion.md`

7. **Read output** — count gaps by severity

8. **Spawn Gap Analyst agents** using Task tool (batch by section, 2-3 batches):
   ```
   Follow the instructions in: {{AGENTS_PATH}}/universal-agents/gap-analyst.md

   Context documents:
   - Draft Architecture: {round-dir}/00-draft-architecture.md
   - PRD: system-design/02-prd/prd.md
   - Foundations: system-design/03-foundations/foundations.md
   - Brief: system-design/04-architecture/brief.md (if exists)

   Gap discussion file: {round-dir}/01-gap-discussion.md
   Gaps: [GAP-001, GAP-002, ...]
   ```

   Batch by Architecture section:
   - Batch 1: Sections 1-3 (System Context, Component Decomposition, Data Flows)
   - Batch 2: Sections 4-6 (Integration Points, Key Technical Decisions, Component Spec List)
   - Batch 3: Sections 7-9 (Cross-Cutting Concerns, Data Contracts, Open Questions)
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
       - Draft Architecture: {round-dir}/00-draft-architecture.md
       - PRD: system-design/02-prd/prd.md
       - Foundations: system-design/03-foundations/foundations.md

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
         Follow the instructions in: {{AGENTS_PATH}}/04-architecture/create/author.md

         Input:
         - Draft Architecture: {round-dir}/00-draft-architecture.md
         - Gap discussion: {round-dir}/01-gap-discussion.md
         - Architecture guide: {{GUIDES_PATH}}/04-architecture-guide.md

         Output:
         - Change log: {round-dir}/02-author-output.md
         - Updated Architecture: {round-dir}/03-updated-architecture.md
         ```
       - Wait for Author to complete
       - Verify outputs exist

14. **After gap resolution completes** (all gaps resolved and Author applied, or no gaps existed):

   **Notify user**:
   ```
   [If gaps were resolved:]
   All gaps resolved and applied.
   [If no gaps:]
   No gaps found.

   You can:
   - Say "promote" — promote the current draft
   - Say "another round" — run another explore→generate cycle

   When ready, let me know.
   ```

   **STOP: Wait for human response.**

   **If "another round"**:
   - Determine the latest draft for this round:
     - If `{round-dir}/03-updated-architecture.md` exists (Author ran): use it
     - Otherwise: use `{round-dir}/00-draft-architecture.md`
   - Update state file:
     - Increment `Current Round`
     - Reset Steps 1–10 to unchecked `[ ]`
     - Set phase = Explore, Explore Phase = active, Gaps Exist = unknown
     - Add history entry "Round {N} complete — starting round {N+1}"
   - **Re-resolve paths** using Path Resolution with the new round number
   - **Loop to Step 1**

   **If "promote"** or "promote as-is":
   - Update state file: Mark "Step 10: Gap Resolution" complete `[x]`, add history entry "Promoting draft from round {N}"
   - Proceed to Step 11

---

## Phase 3: Promote

Phase 3 runs only when the human chooses to promote at Step 10, exiting the explore→generate loop.

### Step 11: Promote & Report

1. **Determine final draft path** (from the current round):
    - If `{round-dir}/03-updated-architecture.md` exists (Author ran): Use it
    - Otherwise: Use `{round-dir}/00-draft-architecture.md`

2. **Copy final draft to `architecture.md`** using Bash cp:
    ```
    cp [final draft path] system-design/04-architecture/architecture.md
    ```

3. **Verify promotion** — Confirm `system-design/04-architecture/architecture.md` exists

4. **Update state file**: Mark "Step 11: Promote & Report" complete `[x]`, set status = COMPLETE, add history entry

5. **Check downstream deferred items** for items the Generator deferred

6. **Present summary**:
    ```
    Architecture creation complete (after {total_rounds} round(s)).

    Final round ({N}):
    - [N] concerns explored, [M] enrichments accepted, [K] rejected
    [If exploration was skipped in final round:]
    - Exploration skipped

    Final draft: {round-dir}/00-draft-architecture.md
    [If Author ran in final round:]
    Updated: {round-dir}/03-updated-architecture.md
    Promoted to: system-design/04-architecture/architecture.md

    [If gaps existed in final round:]
    Gap resolution:
    - [N] gaps in final draft
    - [Resolved by: direct edit / Author / deferred to review]

    [If no gaps in final round:]
    No gaps found in final draft.

    Deferred to downstream:
    - [X] items to Components deferred items

    Next steps:
    1. Review architecture.md — verify promoted content looks correct
    2. When ready, run the Architecture Review workflow
       (Review reads from: system-design/04-architecture/architecture.md)
    ```

---

## Stopping Points

**Automatic flow (do NOT pause for human confirmation):**
- Steps 1 → 2: Setup then identifier
- Steps 4 → 5 → 6: Explorers then consolidator then scope filter
- Steps 8 → 9: Enrichment author then generator/applicator
- Step 10 gap analysis (steps 4-10 within Step 10): Gap formatter → Gap analyst → present to human
- Step 11: Promote and report

**Automatic flow discipline**: Between automatic steps, the orchestrator updates state and spawns the next agent without pausing. Do not read files unless the step instructions explicitly direct you to. Each step already specifies what the orchestrator reads (e.g., "Read the concerns file," "Check for Gap Summary"). If a read is not in the step instructions, do not perform it — agents read their own inputs.

**Human checkpoints:**
- **Step 3** — WAITING_FOR_HUMAN for concern review
- **Step 7** — WAITING_FOR_HUMAN for enrichment review until all enrichments resolved
- **Step 10** — WAITING_FOR_HUMAN for gap resolution (promote vs another round)

**Skip paths:**
- **Explore skip** — If fewer than 2 concerns (Step 2) or human says "skip" (Step 3) → jump to Step 9
- **Gap skip** — If no gaps in draft (Step 10) → still present promote/another-round choice

**Loop path:**
- **Another round** — If human says "another round" at Step 10 → increment round, reset Steps 1–10, loop to Step 1

---

## Error Handling

| Condition | Action |
|-----------|--------|
| PRD not found | Error: "Cannot initialize Architecture - PRD not found at system-design/02-prd/prd.md" |
| Foundations not found | Error: "Cannot initialize Architecture - Foundations not found at system-design/03-foundations/foundations.md" |
| Concern Identifier fails | Error: Report failure details |
| Concerns file not created | Error: "Concern Identifier completed but output not found" |
| Explorer fails | Error: Report which concern's explorer failed |
| Consolidator fails | Error: Report failure details |
| Enrichment Scope Filter fails | Error: Report failure details |
| Filtered enrichment file not created | Error: "Enrichment Scope Filter completed but output not found" |
| Enrichment Author fails | Error: Report failure details |
| Generator fails | Error: Report failure details |
| Draft not created | Error: "Generator completed but draft not found at expected path" |
| Author fails | Error: Report failure details |
| Author output files not created | Error: "Author completed but outputs not found" |
| Promotion copy fails | Error: "Failed to copy final draft to architecture.md" |
| State file corrupted/unreadable | Warning: Report issue, re-create state from file existence checks |
| Resume: draft missing but Step 9 marked complete | Error: "State says Generator complete but draft not found — re-run Generator or fix state file" |
| Round N primary source missing | Error: "Round {N} requires draft from round {N-1} but no draft found" |
| Current Workflow = Review | Error: "Review workflow is active. Cannot re-run creation." |

---

## What Happens Next

After this orchestrator completes:

1. **Human reviews promoted Architecture** — Opens `system-design/04-architecture/architecture.md`
2. **Human optionally makes manual edits** — Can refine directly
3. **Human runs Review workflow** — Invokes the Architecture Review orchestrator

**IMPORTANT**: The Review workflow reads from `system-design/04-architecture/architecture.md` for Round 1. This file is created by the promotion step (Step 11). It MUST exist before starting the Review workflow.

The Review workflow will:
- Run expert reviewers on the Architecture
- Facilitate discussion on issues found
- Author changes and verify alignment with PRD and Foundations
- Promote final version (overwriting `architecture.md` with reviewed version)

---

<!-- INJECT: tool-restrictions -->
