# Blueprint Creation Orchestrator

---

## Purpose

Initialize the Blueprint stage by setting up structure, exploring strategic dimensions of the concept, generating a draft Blueprint enriched by exploration findings and any completed decision analyses, resolving any gaps through structured discussion, promoting the final draft, and extracting a scope brief for downstream stages.

**Flow:** Setup → Explore (dimensions → enrichments) → Generate (draft → gaps → author) → Extract (promote + scope brief)

Strategic decisions identified during enrichment review are handled by the separate Decision Orchestrator, not this workflow. The Blueprint proceeds with pending decisions marked as gaps.

---

## When to Run

Run this orchestrator at the start of a new project, with a concept document. Safe to re-invoke — the orchestrator reads its state file and resumes from the last completed step.

---

## Fixed Paths

**State file**: `system-design/01-blueprint/versions/workflow-state.md`

**Explore phase outputs**:
- `system-design/01-blueprint/versions/explore/00-dimensions.md`
- `system-design/01-blueprint/versions/explore/01-explorer-{dim-name}.md`
- `system-design/01-blueprint/versions/explore/02-enrichment-discussion.md`
- `system-design/01-blueprint/versions/explore/03-exploration-summary.md`

**Decision outputs** (managed by Decision Orchestrator):
- `system-design/01-blueprint/decisions/{decision-name}/framework.md`
- `system-design/01-blueprint/decisions/{decision-name}/analysis.md`

**Generate phase outputs**:
- `system-design/01-blueprint/versions/round-0/00-draft-blueprint.md`
- `system-design/01-blueprint/versions/round-0/01-gap-discussion.md`
- `system-design/01-blueprint/versions/round-0/02-author-output.md`
- `system-design/01-blueprint/versions/round-0/03-updated-blueprint.md`

**Extract phase outputs**:
- `system-design/01-blueprint/blueprint.md`
- `system-design/01-blueprint/scope-brief.md`

---

## Prompt Locations

```
agents/01-blueprint/create/
├── orchestrator.md                    # This file
├── dimension-identifier.md            # Identifies strategic dimensions
├── dimension-explorer.md              # Explores one dimension deeply
├── exploration-consolidator.md        # Merges explorer outputs
├── enrichment-author.md               # Produces exploration summary
├── decision-orchestrator.md           # Handles one decision (framework + analysis) — separate workflow
├── decision-framework.md              # Defines decision criteria with human (used by decision orchestrator)
├── decision-analyst.md                # Evaluates options against framework (used by decision orchestrator)
├── generator.md                       # Creates draft from concept + enrichments + decisions
├── author.md                          # Applies resolved gap discussions
└── scope-extractor.md                 # Extracts scope brief from blueprint

agents/universal-agents/
├── gap-formatter.md                   # Extracts gaps into discussion format
├── gap-analyst.md                     # Proposes solutions for each gap
└── discussion-facilitator.md          # Facilitates discussions
```

---

## Output Directory Structure

```
system-design/01-blueprint/
├── concept.md                         # Input (user provides)
├── blueprint.md                       # Promoted from create (then overwritten by Review)
├── scope-brief.md                     # Extracted scope for downstream stages
├── decisions/                         # Decision analysis (one folder per decision)
│   └── {decision-name}/
│       ├── framework.md               # Evaluation criteria (human-approved)
│       └── analysis.md                # Options evaluated, final decision
└── versions/
    ├── deferred-items.md              # Items deferred from concept
    ├── pending-issues.md              # Issues logged against this stage
    ├── out-of-scope.md                # Non-documentation content from concept
    ├── workflow-state.md              # Unified workflow state (shared with Review)
    ├── explore/
    │   ├── 00-dimensions.md           # Dimension Identifier output
    │   ├── 01-explorer-*.md           # One per dimension
    │   ├── 02-enrichment-discussion.md # Consolidator output → human review
    │   └── 03-exploration-summary.md  # Enrichment Author output
    └── round-0/
        ├── 00-draft-blueprint.md      # Generator output
        ├── 01-gap-discussion.md       # Gap Formatter output (if gaps exist)
        ├── 02-author-output.md        # Author changelog (if gaps exist)
        └── 03-updated-blueprint.md    # Author output (if gaps exist)
```

---

## Workflow State Management

**State file**: `system-design/01-blueprint/versions/workflow-state.md`

### On Start/Resume

1. **Check if state file exists**:
   - **If NO**: Fresh start — create state file, begin at Step 1
   - **If YES**: Read it, resume from the first incomplete step

2. **Resume logic**:
   - Step 1 (Setup) is idempotent — always re-run on resume for validation
   - Step 2 (Dimension Identifier) — if marked complete, verify `00-dimensions.md` exists and skip
   - Step 3 resumes at WAITING_FOR_HUMAN — re-read dimensions file and present to human
   - Steps 2–7 (Explore phase) — if all marked SKIPPED, jump to Step 8
   - Step 6 resumes at WAITING_FOR_HUMAN — re-read enrichment discussion file and continue loop
   - Step 8 (Generator) is non-idempotent — if marked complete, verify draft exists and skip
   - Steps 9–11 conditional on `Gaps Exist` flag — if `false`, skip to Step 12
   - Step 10 resumes at WAITING_FOR_HUMAN — re-read discussion file and continue loop

3. **Update state file** at each step transition (instructions inline below)

### State File Format

```markdown
# Blueprint Workflow State

**Blueprint**: 01-blueprint/blueprint.md
**Current Phase**: Explore | Generate | Extract
**Current Round**: 0
**Status**: IN_PROGRESS | WAITING_FOR_HUMAN | COMPLETE
**Gaps Exist**: unknown | true | false
**Explore Phase**: active | skipped | complete

## Progress

### Phase 1: Explore
- [ ] Step 1: Setup
- [ ] Step 2: Dimension Identifier
- [ ] Step 3: Dimension Review
- [ ] Step 4: Dimension Explorers
- [ ] Step 5: Exploration Consolidator
- [ ] Step 6: Enrichment Review
- [ ] Step 7: Enrichment Author

### Phase 2: Generate
- [ ] Step 8: Run Generator
- [ ] Step 9: Format & Analyse Gaps
- [ ] Step 10: Gap Discussion
- [ ] Step 11: Apply Decisions

### Phase 3: Extract
- [ ] Step 12: Promote
- [ ] Step 13: Scope Extract

## Explore Details

Dimensions: [DIM-1, DIM-2, ...] or [none]
Enrichments Accepted: [N]
Enrichments Rejected: [N]
Enrichments Decision Needed: [N]

## Decision Analysis

Decisions are handled by the Decision Orchestrator (separate workflow).
Status is tracked here so the Generator knows which decisions are resolved.

Decisions:
  - {decision-name} (ENR-NNN): PENDING | FRAMEWORK_IN_PROGRESS | FRAMEWORK_APPROVED | ANALYSIS_IN_PROGRESS | COMPLETE

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
- You CREATE structure files (deferred-items.md, pending-issues.md)
- You COPY the final draft to `blueprint.md` (promotion)
- You DO NOT write draft content, exploration content, decision content, gap discussion content, or author output — agents do that
- Spawn agents in FOREGROUND (not background) — agents need interactive approval for file writes

---

## Phase 1: Explore

### Step 1: Setup

0. **Update state file**: Set status = IN_PROGRESS, phase = Explore (create state file if fresh start)

1. **Create directories** (if not exist):
   ```
   system-design/01-blueprint/
   ├── decisions/
   └── versions/
       ├── explore/
       └── round-0/
   ```

2. **Create deferred-items.md** (if not exists) at `system-design/01-blueprint/versions/deferred-items.md`:
   ```markdown
   # Blueprint Deferred Items

   Items deferred for later consideration or downstream stages.

   ---

   <!-- No deferred items yet -->
   ```

3. **Create pending-issues.md** (if not exists) at `system-design/01-blueprint/versions/pending-issues.md`:
   ```markdown
   # Pending Issues: Blueprint

   Issues discovered that need resolution.

   ---

   <!-- No issues logged yet -->
   ```

4. **Ensure downstream deferred items files exist** (Generator may append to these):
   - `system-design/02-prd/versions/deferred-items.md`
   - `system-design/03-foundations/versions/deferred-items.md`
   - `system-design/04-architecture/versions/deferred-items.md`
   - `system-design/05-components/versions/deferred-items.md`

   Create parent directories and stub files as needed, using the template:
   ```markdown
   # [Stage] Deferred Items

   Items deferred here from upstream stages. Review when starting this stage's workflows.

   ---

   ## Deferred Items

   ---
   ```

5. **Update state file**: Mark "Step 1: Setup" complete `[x]`, add history entry

### Step 2: Dimension Identifier

**On resume**: If Step 2 already marked complete, verify `00-dimensions.md` exists and skip to Step 3.

1. **Verify concept exists** — Read `system-design/01-blueprint/concept.md` to confirm it's present

2. **Spawn Dimension Identifier agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/01-blueprint/create/dimension-identifier.md

   Input:
   - Concept: system-design/01-blueprint/concept.md

   Output: system-design/01-blueprint/versions/explore/00-dimensions.md
   ```

3. **Wait for agent to complete**

4. **Verify output exists** at `system-design/01-blueprint/versions/explore/00-dimensions.md`

5. **Read the dimensions file** — Count dimensions. If fewer than 2 dimensions identified:
   - **Update state file**: Set `Explore Phase` = `skipped`, mark Steps 2–7 as `[x] SKIPPED`, add history entry "Fewer than 2 dimensions — skipping exploration"
   - **Skip to Step 8**

6. **Update state file**: Mark "Step 2: Dimension Identifier" complete `[x]`, record dimension list, add history entry

### Step 3: Dimension Review (`WAITING_FOR_HUMAN`)

**On resume**: If status = WAITING_FOR_HUMAN for Step 3, re-read dimensions file and present to human.

1. **Update state file**: Set status = WAITING_FOR_HUMAN

2. **Notify user** that dimensions are ready for review:
   ```
   Strategic dimensions identified for exploration.

   Dimensions file: system-design/01-blueprint/versions/explore/00-dimensions.md

   [N] dimensions identified:
   - DIM-1: [Name] — [Focus]
   - DIM-2: [Name] — [Focus]
   - ...

   Please review the dimensions file:
   - Accept as-is: "looks good" / "continue"
   - Add a dimension: Edit the file to add a new DIM entry
   - Remove a dimension: Edit the file to remove the DIM entry
   - Modify focus: Edit the file to adjust the focus/questions
   - Skip exploration entirely: "skip exploration"

   When ready, let me know.
   ```

**STOP: Wait for human response before proceeding.**

3. **After human responds**:
   - If human says "skip exploration" → Set `Explore Phase` = `skipped`, mark Steps 3–7 as `[x] SKIPPED`, skip to Step 8
   - Otherwise → Re-read dimensions file (human may have edited it), update dimension list in state file

4. **Update state file**: Mark "Step 3: Dimension Review" complete `[x]`, set status = IN_PROGRESS, add history entry

### Step 4: Dimension Explorers (parallel)

1. **Read the dimensions file** to get the final list of accepted dimensions

2. **Spawn Dimension Explorer agents** using Task tool (one per dimension, in parallel):
   ```
   Follow the instructions in: {{AGENTS_PATH}}/01-blueprint/create/dimension-explorer.md

   Input:
   - Concept: system-design/01-blueprint/concept.md
   - Dimensions file: system-design/01-blueprint/versions/explore/00-dimensions.md
   - Assigned dimension: DIM-[N]

   Output: system-design/01-blueprint/versions/explore/01-explorer-{dim-name}.md
   ```

   Replace `{dim-name}` with a kebab-case version of the dimension name.

3. **Wait for all explorers to complete**

4. **Verify outputs exist** — Check each expected `01-explorer-*.md` file exists

5. **Update state file**: Mark "Step 4: Dimension Explorers" complete `[x]`, add history entry with explorer count

### Step 5: Exploration Consolidator

1. **Spawn Exploration Consolidator agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/01-blueprint/create/exploration-consolidator.md

   Input:
   - Concept: system-design/01-blueprint/concept.md
   - Explorer outputs: system-design/01-blueprint/versions/explore/01-explorer-*.md
     [List all explorer files explicitly]

   Output: system-design/01-blueprint/versions/explore/02-enrichment-discussion.md
   ```

2. **Wait for agent to complete**

3. **Verify output exists** at `system-design/01-blueprint/versions/explore/02-enrichment-discussion.md`

4. **Read output** — Count enrichments for the Step 6 handoff message

5. **Update state file**: Mark "Step 5: Exploration Consolidator" complete `[x]`, add history entry with enrichment count

### Step 6: Enrichment Review (`WAITING_FOR_HUMAN`)

**On resume**: If status = WAITING_FOR_HUMAN for Step 6, re-read `02-enrichment-discussion.md` and continue the review loop from step 6(a) below.

1. **Update state file**: Set status = WAITING_FOR_HUMAN

2. **Notify user** enrichments are ready for review:
   ```
   Exploration complete — [N] enrichment proposals ready for review.

   Discussion file: system-design/01-blueprint/versions/explore/02-enrichment-discussion.md

   [N] enrichments from [M] dimensions, grouped by Blueprint section impact.

   Each enrichment has analysis, trade-offs, and a recommendation.
   Please review each and respond using >> HUMAN: markers:
   - Accept: "accept"
   - Reject: "reject"
   - Accept with changes: "accept with modification: [your changes]"
   - Decision needed: "decision needed: [decision-name]" — for meaty strategic choices that need their own analysis
   - Question/discuss: Write your question

   When done, let me know and I'll process your responses.
   ```

**STOP: Wait for human response before proceeding.**

Do NOT process enrichments until the human has added actual response content after `>> HUMAN:` markers. An empty `>> HUMAN:` marker is a placeholder, not a response.

Only proceed to step 3 after the human signals they have responded.

3. **Enrichment review loop**:

    a. **Identify enrichments needing processing**: Read file, find enrichments where last entry is `>> HUMAN:` with content but no `>> RESOLVED`

    b. **For each enrichment with a human response**:
       - If response indicates acceptance (`accept`, `agreed`, `yes`) → Add `>> RESOLVED [ACCEPTED]` after the human response
       - If response indicates rejection (`reject`, `no`, `not needed`) → Add `>> RESOLVED [REJECTED]` after the human response
       - If response starts with `accept with modification:` → Add `>> RESOLVED [ACCEPTED]` after the human response (the modification is preserved in the human's text)
       - If response starts with `decision needed:` → Add `>> RESOLVED [DECISION NEEDED]: {decision-name}` after the human response (extract decision name from the human's text)
       - If response is a question or discussion point → Leave unresolved, spawn Discussion Facilitator

    c. **If any enrichments need discussion** (question/pushback from human):
       - **Spawn Discussion Facilitator agents** (batched by group):
         ```
         Follow the instructions in: {{AGENTS_PATH}}/universal-agents/discussion-facilitator.md

         Context documents:
         - Concept: system-design/01-blueprint/concept.md

         Issues file: system-design/01-blueprint/versions/explore/02-enrichment-discussion.md
         Issues: [ENR-001, ENR-002, ...]
         ```
       - Wait for agents to complete
       - Present to human: "Please review the agent responses and reply to each enrichment."
       - Wait for human response
       - Return to step (a)

    d. **If all enrichments resolved**: Continue to decision registration below

4. **Register decisions**: If any enrichments were marked `>> RESOLVED [DECISION NEEDED]`:
   - Read each `>> RESOLVED [DECISION NEEDED]: {decision-name}` marker
   - Extract the enrichment ID (ENR-NNN) and decision name for each
   - Create decision folders at `system-design/01-blueprint/decisions/{decision-name}/`
   - Add each decision to the Decision Analysis section of the state file with status PENDING

5. **Notify user about pending decisions** (if any):
   ```
   [N] enrichments require decision analysis:
   - {decision-1} (from ENR-NNN)
   - {decision-2} (from ENR-MMM)

   These will be marked as pending gaps in the Blueprint.
   Run the Decision Orchestrator for each when ready:

     agents/01-blueprint/create/decision-orchestrator.md
     Decision name: {decision-name}

   Continuing to generate Blueprint...
   ```

6. **Update state file**: Mark "Step 6: Enrichment Review" complete `[x]`, set status = IN_PROGRESS, record accepted/rejected/decision-needed counts, add history entry

### Step 7: Enrichment Author

1. **Check if any enrichments were accepted** — Read enrichment discussion file for `>> RESOLVED [ACCEPTED]` markers. If zero accepted:
   - No exploration summary needed — Step 8 Generator will run from concept + decisions only
   - Update state file: Mark "Step 7: Enrichment Author" complete `[x]`, set `Explore Phase` = `complete`, add history entry "No enrichments accepted — Generator will use concept and decisions only"
   - Proceed to Step 8

2. **Spawn Enrichment Author agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/01-blueprint/create/enrichment-author.md

   Input:
   - Concept: system-design/01-blueprint/concept.md
   - Enrichment discussion: system-design/01-blueprint/versions/explore/02-enrichment-discussion.md

   Output: system-design/01-blueprint/versions/explore/03-exploration-summary.md
   ```

3. **Wait for agent to complete**

4. **Verify output exists** at `system-design/01-blueprint/versions/explore/03-exploration-summary.md`

5. **Update state file**: Mark "Step 7: Enrichment Author" complete `[x]`, set `Explore Phase` = `complete`, set phase = Generate, add history entry

---

## Phase 2: Generate

### Step 8: Run Generator

**On resume**: If Step 8 already marked complete, verify `00-draft-blueprint.md` exists and skip to Step 9. Do NOT re-run the Generator (it appends to downstream deferred items files and would create duplicates).

1. **Determine exploration summary path**: Check if `system-design/01-blueprint/versions/explore/03-exploration-summary.md` exists. If yes, include it as input. If no (exploration was skipped or no enrichments accepted), omit it.

2. **Determine decision status**: Read the Decision Analysis section of the workflow state file.
   - For each decision with status COMPLETE: check that `decisions/{decision-name}/analysis.md` exists. Add to the resolved decisions list.
   - For each decision with status other than COMPLETE: add to the pending decisions list with the enrichment title (read from the enrichment discussion file).

3. **Spawn Generator agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/01-blueprint/create/generator.md

   Input:
   - Concept: system-design/01-blueprint/concept.md
   - Blueprint guide: {{GUIDES_PATH}}/01-blueprint-guide.md
   [If exploration summary exists:]
   - Exploration summary: system-design/01-blueprint/versions/explore/03-exploration-summary.md
   [If resolved decisions exist:]
   - Decision analyses (resolved — incorporate as settled decisions):
     - system-design/01-blueprint/decisions/{decision-1}/analysis.md
     [List all resolved decision analysis files]
   [If pending decisions exist:]
   - Pending decisions (mark as gaps in the relevant Blueprint sections):
     - {decision-name}: "[enrichment title / decision question summary]"
     [List all pending decisions with their descriptions]

   Output: system-design/01-blueprint/versions/round-0/00-draft-blueprint.md

   Downstream deferred items (Generator may append):
   - PRD: system-design/02-prd/versions/deferred-items.md
   - Foundations: system-design/03-foundations/versions/deferred-items.md
   - Architecture: system-design/04-architecture/versions/deferred-items.md
   - Components: system-design/05-components/versions/deferred-items.md
   ```

4. **Wait for Generator to complete**

5. **Verify output exists** at `system-design/01-blueprint/versions/round-0/00-draft-blueprint.md`

6. **Update state file**: Mark "Step 8: Run Generator" complete `[x]`, add history entry

### Step 9: Format & Analyse Gaps

1. **Read the draft** at `system-design/01-blueprint/versions/round-0/00-draft-blueprint.md`

2. **Check for Gap Summary section** — Look for `## Gap Summary` heading

3. **If no Gap Summary, or all subsections empty** (Must Answer, Should Answer, and Assumptions all show "None" or similar):
   - **Update state file**: Set `Gaps Exist` = `false`, mark Steps 9-11 complete `[x]`, add history entry "No gaps found — skipping to promotion"
   - **Skip Steps 9-11, proceed to Step 12**

4. **Spawn Gap Formatter agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/universal-agents/gap-formatter.md

   Input:
   - Draft: system-design/01-blueprint/versions/round-0/00-draft-blueprint.md

   Output: system-design/01-blueprint/versions/round-0/01-gap-discussion.md
   ```

5. **Wait for Gap Formatter to complete**

6. **Verify output exists** at `system-design/01-blueprint/versions/round-0/01-gap-discussion.md`

7. **Read output** — count gaps by severity for the Step 10 handoff message

8. **Spawn Gap Analyst agents** using Task tool (batch by section, same grouping as Discussion Facilitator):
   ```
   Follow the instructions in: {{AGENTS_PATH}}/universal-agents/gap-analyst.md

   Context documents:
   - Draft Blueprint: system-design/01-blueprint/versions/round-0/00-draft-blueprint.md
   [If exploration summary exists:]
   - Exploration summary: system-design/01-blueprint/versions/explore/03-exploration-summary.md

   Gap discussion file: system-design/01-blueprint/versions/round-0/01-gap-discussion.md
   Gaps: [GAP-001, GAP-002, ...]
   ```

9. **Wait for all Gap Analyst agents to complete**

10. **Verify analyst responses were written** (MANDATORY):
    - Count `>> AGENT:` markers in the gap discussion file
    - Compare to total number of gaps
    - If counts don't match: identify missing gaps and re-invoke Gap Analyst for those only

11. **Update state file**: Set `Gaps Exist` = `true`, mark "Step 9: Format & Analyse Gaps" complete `[x]`, add history entry with gap counts

### Step 10: Gap Discussion (`WAITING_FOR_HUMAN`)

**On resume**: If status = WAITING_FOR_HUMAN for Step 10, re-read `01-gap-discussion.md` and continue the discussion loop from step 10(a) below — identify which gaps still need responses.

1. **Update state file**: Set status = WAITING_FOR_HUMAN

2. **Notify user** gap analysis is ready for review:
   ```
   Gap analysis complete.

   Discussion file: system-design/01-blueprint/versions/round-0/01-gap-discussion.md

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

Do NOT enter the discussion loop until the human has added actual response content after `>> HUMAN:` markers. An empty `>> HUMAN:` marker is a placeholder, not a response.

Only proceed to step 3 after the human signals they have responded.

3. **Discussion markers**:
   - Human responds using `>> HUMAN:` prefix
   - Agent responds using `>> AGENT:` prefix
   - `>> RESOLVED` marks discussion complete (added by orchestrator only)

4. **Discussion loop**:

    a. **Identify gaps needing agent response**: Read file, find gaps where last entry is `>> HUMAN:` without subsequent `>> AGENT:`

    b. **Group gaps into batches** (2-3 batches recommended):
       - Group by Blueprint section number (gaps contain `**Section**: §N`)
       - Batch 1: Sections 1-4 (Vision, Target Users, Value Proposition, Business Model)
       - Batch 2: Sections 5-8 (Principles, Maturity Target, Market Context, MVP Definition)
       - Batch 3: Sections 9-11 (Success Criteria, Risks, Why Now, Future Vision)
       - If fewer than 4 gaps total, use fewer batches

    c. **Invoke Discussion Facilitator agents** (one per batch, in parallel):
       ```
       Follow the instructions in: {{AGENTS_PATH}}/universal-agents/discussion-facilitator.md

       Context documents:
       - Draft Blueprint: system-design/01-blueprint/versions/round-0/00-draft-blueprint.md

       Issues file: system-design/01-blueprint/versions/round-0/01-gap-discussion.md
       Issues: [GAP-001, GAP-002, ...]
       ```

    d. **Wait for all agents to complete**

    e. **Verify agent responses were written** (MANDATORY):
       - Count `>> AGENT:` markers in the gap discussion file
       - Compare to number of gaps that were assigned to Discussion Facilitators
       - If counts don't match:
         - Identify which gaps are missing `>> AGENT:` responses
         - Re-invoke Discussion Facilitators for ONLY the missing gaps
         - Repeat verification until all assigned gaps have responses

    f. **Present to human**: "Please review the agent responses and reply to each gap."

    g. **Wait for human responses**

    h. **After human responds**, read file and for each gap:
       - If last entry is `>> HUMAN:` after `>> AGENT:` AND response indicates closure → add `>> RESOLVED`
       - If last entry is `>> HUMAN:` with question, pushback, or request → leave open

    i. **If any gaps unresolved**: Go to step (a)

    j. **If all gaps resolved**: Proceed to Step 11

5. **Resolution indicators** (human response after `>> AGENT:` that signals done):
    - Agreement: "Yes", "Agreed", "That works", "Fine", "OK"
    - Dismissal: "Not a concern", "Not relevant", "Ignore", "Skip"
    - Acceptance: "Makes sense", "Fair enough", "Understood"

6. **Continue discussion indicators** (do NOT mark resolved):
    - Questions: "?", "What about", "How would", "Can you"
    - Requests: "Please", "Can you", "I'd like", "Show me"
    - Pushback: "I disagree", "That's not right", "But what about"

### Step 10→11 Gate

**Before invoking Author:**
1. Read `01-gap-discussion.md`
2. Verify EVERY gap has `>> RESOLVED` marker
3. If any gap lacks `>> RESOLVED`: Do NOT proceed. Continue discussion loop.
4. Only proceed to Step 11 when all gaps show `>> RESOLVED`

This gate is mandatory. Do not skip it.

5. **Update state file**: Mark "Step 10: Gap Discussion" complete `[x]`, set status = IN_PROGRESS, add history entry "All gaps resolved"

### Step 11: Apply Decisions

1. **Spawn Author agent** using Task tool:
    ```
    Follow the instructions in: {{AGENTS_PATH}}/01-blueprint/create/author.md

    Input:
    - Draft Blueprint: system-design/01-blueprint/versions/round-0/00-draft-blueprint.md
    - Gap discussion: system-design/01-blueprint/versions/round-0/01-gap-discussion.md
    - Blueprint guide: {{GUIDES_PATH}}/01-blueprint-guide.md

    Output:
    - Change log: system-design/01-blueprint/versions/round-0/02-author-output.md
    - Updated Blueprint: system-design/01-blueprint/versions/round-0/03-updated-blueprint.md
    ```

2. **Wait for Author to complete**

3. **Verify outputs exist**:
    - `system-design/01-blueprint/versions/round-0/02-author-output.md`
    - `system-design/01-blueprint/versions/round-0/03-updated-blueprint.md`

4. **Update state file**: Mark "Step 11: Apply Decisions" complete `[x]`, set phase = Extract, add history entry

---

## Phase 3: Extract

### Step 12: Promote

1. **Determine final draft path**:
    - If Steps 9-11 ran (gaps existed): Use `system-design/01-blueprint/versions/round-0/03-updated-blueprint.md`
    - If Steps 9-11 were skipped (no gaps): Use `system-design/01-blueprint/versions/round-0/00-draft-blueprint.md`

2. **Copy final draft to `blueprint.md`** using Bash cp:
    ```
    cp [final draft path] system-design/01-blueprint/blueprint.md
    ```

3. **Verify promotion** — Confirm `system-design/01-blueprint/blueprint.md` exists

4. **Update state file**: Mark "Step 12: Promote" complete `[x]`, add history entry

### Step 13: Scope Extract

1. **Spawn Scope Extractor agent** using Task tool:
    ```
    Follow the instructions in: {{AGENTS_PATH}}/01-blueprint/create/scope-extractor.md

    Input:
    - Blueprint: system-design/01-blueprint/blueprint.md

    Output: system-design/01-blueprint/scope-brief.md
    ```

2. **Wait for agent to complete**

3. **Verify output exists** at `system-design/01-blueprint/scope-brief.md`

4. **Update state file**: Mark "Step 13: Scope Extract" complete `[x]`, set status = COMPLETE, add history entry

5. **Check downstream deferred items** for items the Generator deferred

6. **Present summary**:
    ```
    Blueprint creation complete.

    Exploration:
    - [N] dimensions explored
    - [M] enrichments accepted, [K] rejected
    [If decisions registered:]
    - [D] decisions registered ([R] resolved, [P] pending)
    [If exploration was skipped:]
    - Exploration skipped

    Draft: system-design/01-blueprint/versions/round-0/00-draft-blueprint.md
    [If gaps resolved:]
    Updated: system-design/01-blueprint/versions/round-0/03-updated-blueprint.md
    Promoted to: system-design/01-blueprint/blueprint.md
    Scope brief: system-design/01-blueprint/scope-brief.md

    [If pending decisions exist:]
    Pending decisions (run Decision Orchestrator when ready):
    - {decision-1} (from ENR-NNN) — PENDING
    - {decision-2} (from ENR-MMM) — FRAMEWORK_APPROVED

    [If gaps were resolved:]
    Gap resolution:
    - [N] gaps discussed
    - [M] changes applied by author
    - [K] flagged for attention (see 02-author-output.md)

    [If no gaps:]
    No gaps found — concept was fully specified.

    Deferred to downstream:
    - [W] items to PRD deferred items
    - [X] items to Foundations deferred items
    - [Y] items to Architecture deferred items
    - [Z] items to Components deferred items

    Next steps:
    1. Review blueprint.md — verify promoted content looks correct
    [If pending decisions:]
    2. Run Decision Orchestrator for pending decisions
    3. When ready, run the Blueprint Review workflow
       (Review reads from: system-design/01-blueprint/blueprint.md)
    [If no pending decisions:]
    2. When ready, run the Blueprint Review workflow
       (Review reads from: system-design/01-blueprint/blueprint.md)
    ```

---

## Stopping Points

**Automatic flow (do NOT pause for human confirmation):**
- Steps 1 → 2: Setup then identifier
- Steps 4 → 5: Explorers then consolidator
- Steps 7 → 8 → 9: Enrichment author then generator then gap analysis
- Steps 11 → 12 → 13: Author then promote then scope extract

**Human checkpoints:**
- **Step 3** — WAITING_FOR_HUMAN for dimension review
- **Step 6** — WAITING_FOR_HUMAN for enrichment review until all enrichments resolved
- **Step 10** — WAITING_FOR_HUMAN for gap discussion until all gaps resolved

**Skip paths:**
- **Explore skip** — If fewer than 2 dimensions (Step 2) or human says "skip" (Step 3) → jump to Step 8
- **Gap skip** — If no gaps in draft (Step 9) → jump to Step 12

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Concept not found | Error: "Concept document not found at system-design/01-blueprint/concept.md" |
| Dimension Identifier fails | Error: Report failure details |
| Dimensions file not created | Error: "Dimension Identifier completed but output not found" |
| Explorer fails | Error: Report which dimension's explorer failed |
| Consolidator fails | Error: Report failure details |
| Enrichment Author fails | Error: Report failure details |
| Generator fails | Error: Report failure details |
| Draft not created | Error: "Generator completed but draft not found at expected path" |
| Gap Formatter fails | Error: Report failure details |
| Gap discussion file not created | Error: "Gap Formatter completed but output not found" |
| Author fails | Error: Report failure details |
| Author output files not created | Error: "Author completed but outputs not found" |
| Scope Extractor fails | Error: Report failure details |
| Promotion copy fails | Error: "Failed to copy final draft to blueprint.md" |
| State file corrupted/unreadable | Warning: Report issue, re-create state from file existence checks |
| Resume: draft missing but Step 8 marked complete | Error: "State says Generator complete but draft not found — re-run Generator or fix state file" |

---

## What Happens Next

After this orchestrator completes:

1. **Human reviews promoted Blueprint** — Opens `system-design/01-blueprint/blueprint.md`
2. **Human resolves pending decisions** — Runs Decision Orchestrator for each (if any)
3. **Human optionally makes manual edits** — Can refine directly
4. **Human runs Review workflow** — Invokes the Blueprint Review orchestrator

**IMPORTANT**: The Review workflow reads from `system-design/01-blueprint/blueprint.md` for Round 1. This file is created by the promotion step (Step 12). It MUST exist before starting the Review workflow.

The Review workflow will:
- Run expert reviewers on the Blueprint
- Facilitate discussion on issues found
- Author changes and verify consistency
- Promote final version (overwriting `blueprint.md` with reviewed version)
- Re-extract scope brief (updating `scope-brief.md` with reviewed content)

---

## Note: No Upstream Alignment

Unlike other stages (PRD, Foundations, Architecture, Components), the Blueprint does **not** have upstream alignment verification or deferred items intake.

**Reason**: The concept document is informal input — a rough idea or description — not a tracked source with specific requirements. The Blueprint *expands* the concept rather than *implementing* it.

---

<!-- INJECT: tool-restrictions -->
