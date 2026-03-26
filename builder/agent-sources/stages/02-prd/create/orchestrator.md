# PRD Creation Orchestrator

---

## Purpose

Initialize the PRD stage by setting up structure, exploring capability areas from the Blueprint that need product-level decomposition, generating a draft PRD enriched by exploration findings, resolving gaps with the human, and iterating through additional explore→generate rounds as needed. When the human is satisfied, promote the final draft.

**Flow:** Setup → [Explore → Generate → Gap Resolution]* → Promote

The explore→generate cycle can repeat for as many rounds as the human wants. Round 1 explores from the Blueprint. Round 2+ explores from the previous round's draft, finding capability areas and enrichments that the earlier round missed or underexplored. The human exits the loop by choosing to promote at Gap Resolution.

---

## When to Run

Run this orchestrator at the start of the PRD stage, after the Blueprint is complete. Safe to re-invoke — the orchestrator reads its state file and resumes from the last completed step.

---

## Fixed Paths

**State file**: `system-design/02-prd/versions/workflow-state.md`

**Primary source** (determined by current round — see Path Resolution below):
- Round 1: `system-design/01-blueprint/blueprint.md`
- Round N (N≥2): Latest draft from round N-1

**Explore phase outputs**: `system-design/02-prd/versions/create/round-{N}/explore/`

Files within the explore directory:
- `00-capabilities.md`
- `01-explorer-{cap-name}.md`
- `02-enrichment-discussion.md`
- `02a-filtered-enrichment-discussion.md`
- `03-exploration-summary.md`

**Generate phase outputs** (in `versions/create/round-{N}/`):
- `00-draft-prd.md`
- `00-enrichment-applicator-output.md` (round 2+ only)
- `01-gap-resolutions.md`
- `02-author-output.md`
- `03-updated-prd.md`

**Brief** (optional): `system-design/02-prd/brief.md`

**Promoted output**: `system-design/02-prd/prd.md`

---

## Prompt Locations

```
agents/02-prd/create/
├── orchestrator.md                    # This file
├── capability-identifier.md           # Identifies capability areas to explore
├── capability-explorer.md             # Decomposes one capability area into requirements
├── exploration-consolidator.md        # Merges explorer outputs
├── enrichment-scope-filter.md         # Filters enrichments by level/depth
├── enrichment-author.md               # Produces exploration summary
├── generator.md                       # Creates draft from Blueprint + enrichments (round 1)
├── enrichment-applicator.md          # Applies enrichments to existing draft (round 2+)
└── author.md                          # Applies gap resolutions to draft

agents/universal-agents/
└── discussion-facilitator.md          # Facilitates enrichment discussions
```

---

## Output Directory Structure

```
system-design/02-prd/
├── prd.md                         # Promoted from create (then overwritten by Review)
├── brief.md                       # Optional human-provided brief
└── versions/
    ├── deferred-items.md           # Upstream deferred items for this stage
    ├── pending-issues.md           # Issues logged against this stage
    ├── workflow-state.md           # Unified workflow state (shared with Review)
    ├── create/                     # All creation round outputs
    │   ├── round-1/
    │   │   ├── explore/
    │   │   │   ├── 00-capabilities.md
    │   │   │   ├── 01-explorer-*.md
    │   │   │   ├── 02-enrichment-discussion.md
    │   │   │   ├── 02a-filtered-enrichment-discussion.md
    │   │   │   └── 03-exploration-summary.md
    │   │   ├── 00-draft-prd.md
    │   │   ├── 00-enrichment-applicator-output.md  # Round 2+ only
    │   │   ├── 01-gap-resolutions.md
    │   │   ├── 02-author-output.md
    │   │   └── 03-updated-prd.md
    │   └── round-{N}/                 # Additional create rounds (if "another round")
    │       ├── explore/
    │       │   └── [same explore files]
    │       └── [same generate files]
    └── review/                        # All review round outputs
        ├── round-1/
        │   └── [review workflow files]
        └── round-{N}/
            └── ...
```

---

## Workflow State Management

**State file**: `system-design/02-prd/versions/workflow-state.md`

### On Start/Resume

1. **Check if state file exists**:
   - **If NO**: Fresh start — create state file (with `Current Workflow: Create`), begin at Step 1
   - **If YES**: Read it, check `Current Workflow`:
     - **If `Review`**: Error — "Review workflow is active. Cannot re-run creation."
     - **If `Create`**: Resume from the first incomplete step

2. **Resume logic**:
   - Step 1 (Setup) is idempotent — always re-run on resume for validation
   - Step 2 (Capability Identifier) — if marked complete, verify `{explore-dir}/00-capabilities.md` exists and skip
   - Step 3 resumes at WAITING_FOR_HUMAN — re-read capabilities file and present to human
   - Steps 2–8 (Explore phase) — if all marked SKIPPED, jump to Step 9
   - Step 7 resumes at WAITING_FOR_HUMAN — re-read filtered enrichment discussion file and continue loop
   - Step 9 (Generator) is non-idempotent — if marked complete, verify draft exists and skip
   - Step 10 resumes at WAITING_FOR_HUMAN — re-read draft and present gap summary to human

3. **Update state file** at each step transition (instructions inline below)

4. **Resolve paths** using Path Resolution (below) before executing any step

### State File Format

```markdown
# PRD Workflow State

**Blueprint**: 01-blueprint/blueprint.md
**PRD**: 02-prd/prd.md
**Current Workflow**: Create
**Current Phase**: Explore | Generate
**Current Round**: 1
**Status**: IN_PROGRESS | WAITING_FOR_HUMAN | COMPLETE
**Gaps Exist**: unknown | true | false
**Explore Phase**: active | skipped | complete

## Progress

### Phase 1: Explore
- [ ] Step 1: Setup
- [ ] Step 2: Capability Identifier
- [ ] Step 3: Capability Review
- [ ] Step 4: Capability Explorers
- [ ] Step 5: Exploration Consolidator
- [ ] Step 6: Enrichment Scope Filter
- [ ] Step 7: Enrichment Review
- [ ] Step 8: Enrichment Author

### Phase 2: Generate
- [ ] Step 9: Generate or Apply Enrichments
- [ ] Step 10: Gap Resolution

### Phase 3: Promote
- [ ] Step 11: Promote

## Explore Details

Capabilities: [CAP-1, CAP-2, ...] or [none]
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
- You COPY the final draft to `prd.md` (promotion)
- You DO NOT write draft content, exploration content, or author output — agents do that
- You DO NOT answer, analyse, or respond to human discussion points — discussion facilitator agents do that
- Spawn agents in FOREGROUND (not background) — agents need interactive approval for file writes

### Path Resolution

Before executing any step, resolve these paths based on the current round number (read `Current Round` from the state file):

**Primary source** (`{primary-source}`):
- Round 1: `system-design/01-blueprint/blueprint.md`
- Round N (N≥2): Determine from round N-1 outputs:
  - If `system-design/02-prd/versions/create/round-{N-1}/03-updated-prd.md` exists → use it
  - Otherwise → use `system-design/02-prd/versions/create/round-{N-1}/00-draft-prd.md`

**Explore directory** (`{explore-dir}`): `system-design/02-prd/versions/create/round-{N}/explore/`

**Round directory** (`{round-dir}`): `system-design/02-prd/versions/create/round-{N}/`

All steps below use `{primary-source}`, `{explore-dir}`, and `{round-dir}` to refer to these resolved paths. **Resolve them once at startup and again after any round increment.**

---

## Phase 1: Explore

### Step 1: Setup

0. **Update state file**: Set status = IN_PROGRESS, phase = Explore (create state file if fresh start)

1. **Check Blueprint exists** at `system-design/01-blueprint/blueprint.md`
   - **If NO**: Error — "Cannot initialize PRD — Blueprint not found"
   - **If YES**: Continue

2. **Create directories** (if not exist):

   **Round 1 (first run):**
   ```
   system-design/02-prd/
   └── versions/
       └── create/
           └── round-1/
               └── explore/
   ```

   **Round N (N≥2, "another round"):**
   ```
   system-design/02-prd/versions/create/
   └── round-{N}/
       └── explore/
   ```

3. **Create deferred-items.md** (if not exists) at `system-design/02-prd/versions/deferred-items.md`:
   ```markdown
   # PRD Deferred Items

   Items deferred for later consideration or downstream stages.

   ---

   <!-- No deferred items yet -->
   ```

4. **Create pending-issues.md** (if not exists) at `system-design/02-prd/versions/pending-issues.md`:
   ```markdown
   # Pending Issues: PRD

   Issues discovered that need resolution.

   ---

   <!-- No issues logged yet -->
   ```

5. **Ensure downstream deferred items files exist** (Generator may append to these):
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

6. **Deferred items intake** — Read `system-design/02-prd/versions/deferred-items.md`:
   - If empty or no PENDING items: Note "no upstream deferred items" and continue
   - If has PENDING items:
     a. Read final Blueprint: `system-design/01-blueprint/blueprint.md`
     b. For each PENDING item, validate relevance:
        - Check if topic is addressed in final Blueprint
        - Update validation status:
          - `RESOLVED_UPSTREAM`: Fully addressed in Blueprint — mark closed
          - `PARTIALLY_ADDRESSED`: Touched but not resolved — keep for Generator
          - `STILL_RELEVANT`: Not addressed — keep for Generator
     c. Update deferred items with validation results

7. **Check for brief** — Check if `system-design/02-prd/brief.md` exists:
   - If brief exists: Will be passed to Generator as additional input
   - If no brief: Continue without (standard generation)

8. **Update state file**: Mark "Step 1: Setup" complete `[x]`, add history entry

### Step 2: Capability Identifier

**On resume**: If Step 2 already marked complete, verify `{explore-dir}/00-capabilities.md` exists and skip to Step 3.

1. **Verify primary source exists** — Read `{primary-source}` to confirm it's present

2. **Spawn Capability Identifier agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/02-prd/create/capability-identifier.md

   Input:
   - Blueprint: {primary-source}
   - PRD guide: {{GUIDES_PATH}}/02-prd-guide.md
   - Workflow state: system-design/02-prd/versions/workflow-state.md

   Output: {explore-dir}/00-capabilities.md
   ```

3. **Wait for agent to complete**

4. **Verify output exists** at `{explore-dir}/00-capabilities.md`

5. **Read the capabilities file** — Count capability areas. If fewer than 2 capability areas identified:
   - **Update state file**: Set `Explore Phase` = `skipped`, mark Steps 2–8 as `[x] SKIPPED`, add history entry "Fewer than 2 capability areas — skipping exploration"
   - **Skip to Step 9**

6. **Update state file**: Mark "Step 2: Capability Identifier" complete `[x]`, record capability list, add history entry

### Step 3: Capability Review (`WAITING_FOR_HUMAN`)

**On resume**: If status = WAITING_FOR_HUMAN for Step 3, re-read capabilities file and present to human.

1. **Update state file**: Set status = WAITING_FOR_HUMAN

2. **Notify user** that capability areas are ready for review:
   ```
   Capability areas identified for exploration.

   Capabilities file: {explore-dir}/00-capabilities.md

   [N] capability areas identified:
   - CAP-1: [Name] — [Focus]
   - CAP-2: [Name] — [Focus]
   - ...

   Please review the capabilities file:
   - Accept as-is: "looks good" / "continue"
   - Add a capability area: Edit the file to add a new CAP entry
   - Remove a capability area: Edit the file to remove the CAP entry
   - Modify focus: Edit the file to adjust the focus/questions
   - Skip exploration entirely: "skip exploration"

   When ready, let me know.
   ```

**STOP: Wait for human response before proceeding.**

3. **After human responds**:
   - If human says "skip exploration" → Set `Explore Phase` = `skipped`, mark Steps 3–8 as `[x] SKIPPED`, skip to Step 9
   - Otherwise → Re-read capabilities file (human may have edited it), update capability list in state file

4. **Update state file**: Mark "Step 3: Capability Review" complete `[x]`, set status = IN_PROGRESS, add history entry

### Step 4: Capability Explorers (parallel)

1. **Read the capabilities file** to get the final list of accepted capability areas

2. **Spawn Capability Explorer agents** using Task tool (one per capability area, in parallel):
   ```
   Follow the instructions in: {{AGENTS_PATH}}/02-prd/create/capability-explorer.md

   Input:
   - Blueprint: {primary-source}
   - Capabilities file: {explore-dir}/00-capabilities.md
   - Assigned capability: CAP-[N]

   Output: {explore-dir}/01-explorer-{cap-name}.md
   ```

   Replace `{cap-name}` with a kebab-case version of the capability area name.

3. **Wait for all explorers to complete**

4. **Verify outputs exist** — Check each expected `01-explorer-*.md` file exists in `{explore-dir}/`

5. **Update state file**: Mark "Step 4: Capability Explorers" complete `[x]`, add history entry with explorer count

### Step 5: Exploration Consolidator

1. **Spawn Exploration Consolidator agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/02-prd/create/exploration-consolidator.md

   Input:
   - Blueprint: {primary-source}
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
   Follow the instructions in: {{AGENTS_PATH}}/02-prd/create/enrichment-scope-filter.md

   Input:
   - PRD guide: {{GUIDES_PATH}}/02-prd-guide.md
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

   [N] enrichments from [M] capability areas, grouped by PRD section impact.

   Each enrichment has analysis, trade-offs, and a recommendation.
   Please review each and respond after the >> HUMAN: markers.

   Respond naturally — say what you think. Examples:
   - Accept: "Happy with this", "Accept", "Agree", "Yes"
   - Reject: "Disagree — [reason]", "Not needed", "Reject"
   - Accept with changes: State what to change — e.g., "Good, but this should be out of scope for Phase 1"
   - Question/discuss: Ask your question or raise a concern

   I'll interpret your intent and confirm before marking anything resolved.

   When done, let me know and I'll process your responses.
   ```

**STOP: Wait for human response before proceeding.**

Do NOT process enrichments until the human has added actual response content after `>> HUMAN:` markers. An empty `>> HUMAN:` marker is a placeholder, not a response.

Only proceed to step 3 after the human signals they have responded.

3. **Enrichment review loop** (operates on `{explore-dir}/02a-filtered-enrichment-discussion.md`):

    a. **Identify enrichments needing processing**: Read file, find enrichments where last entry is `>> HUMAN:` with content but no `>> RESOLVED`

    b. **Interpret and confirm** — For each enrichment with a human response, follow this two-phase process:

       **Phase 1 — Interpret intent**: Read the human's natural language response and classify into one of:

       **Prerequisite — Verify explicit positive signal**: Before classifying any response as an ACCEPT variant (ACCEPT, ACCEPT WITH MODIFICATION, ACCEPT WITH DISCUSSION), verify that the response contains an explicit positive signal — words like "happy", "agree", "accept", "yes", "good", "reasonable", or clear positive sentiment. Substantive engagement with an enrichment (questions, challenges, alternative proposals) is not an implicit positive signal. If no explicit positive signal is present, the response is QUESTION/DISCUSSION or REJECT — it cannot be any form of acceptance.

       - **ACCEPT**: Clear agreement with the enrichment as proposed, with no questions, observations, or concerns. Indicators: "happy with", "accept", "agree", "yes", clean positive sentiment only.
       - **REJECT**: Clear disagreement or statement that the enrichment should not be included. Indicators: "disagree", "reject", "not needed", "no", substantive disagreement with the enrichment's premise.
       - **ACCEPT WITH MODIFICATION**: Agreement with changes to scope, framing, priority, or content. Indicators: positive sentiment combined with "but change/make/adjust", partial agreement ("agree with X but not Y"), instructions that alter the proposed content while keeping the enrichment.
       - **ACCEPT WITH DISCUSSION**: Agreement with the enrichment, combined with a question, observation, or concern that warrants a response. The acceptance is not in doubt — the human agrees the enrichment should be included — but they have raised a point that should be engaged with before the enrichment is finalised. Indicators: positive sentiment combined with "?", an observation, or a concern.
       - **QUESTION/DISCUSSION**: Question, concern without clear accept/reject, or request for exploration before deciding. Indicators: questions, hedging without clear direction, requests for more information.

       **Compound responses** — A response may contain multiple signals. Apply this priority:
       - Accept with no additional content → ACCEPT.
       - Accept + any question, observation, or concern → ACCEPT WITH DISCUSSION. Do not judge whether the question is "informational" or "substantive" — if the human raised a point alongside acceptance, it warrants a response.
       - Agreement + disagreement on different aspects → ACCEPT WITH MODIFICATION.

       **Phase 2 — Confirm**: Present ALL interpretations to the human at once:
       ```
       Here's how I interpret your responses:

       ENR-001: **Accept with modification** — keep enrichment but adjust scope per your note
       ENR-002: **Reject** — you disagree with the premise
       ENR-003: **Accept** — agreed as proposed
       [... all enrichments with responses ...]

       Is that correct? (Clarify any I got wrong and I'll re-interpret.)
       ```

       **STOP: Wait for human to confirm or correct before proceeding.**

       After confirmation, apply the confirmed classifications:
       - ACCEPT → Add `>> RESOLVED [ACCEPTED]` after the human response
       - REJECT → Add `>> RESOLVED [REJECTED]` after the human response
       - ACCEPT WITH MODIFICATION → Add `>> RESOLVED [ACCEPTED]` after the human response (the modification is preserved in the human's text)
       - ACCEPT WITH DISCUSSION → Leave unresolved for discussion facilitator (acceptance is noted but the raised point needs a response first)
       - QUESTION/DISCUSSION → Leave unresolved for discussion facilitator

    c. **If any enrichments need discussion** (ACCEPT WITH DISCUSSION or QUESTION/DISCUSSION):
       - **Spawn Discussion Facilitator agents** (batched by group):
         ```
         Follow the instructions in: {{AGENTS_PATH}}/universal-agents/discussion-facilitator.md

         Context documents:
         - Blueprint: {primary-source}

         Issues file: {explore-dir}/02a-filtered-enrichment-discussion.md
         Issues: [ENR-001, ENR-002, ...]
         ```
       - Wait for agents to complete
       - Present to human: "Please review the agent responses and reply to each enrichment."
       - Wait for human response
       - **After human responds**, read file and for each discussed enrichment:
         - If last entry is `>> HUMAN:` after `>> AGENT:` AND response indicates closure → add `>> RESOLVED [ACCEPTED]` (for ACCEPT WITH DISCUSSION) or `>> RESOLVED` (for QUESTION/DISCUSSION, then re-classify)
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

    d. **If all enrichments resolved**: Continue to step 4

4. **Update state file**: Mark "Step 7: Enrichment Review" complete `[x]`, set status = IN_PROGRESS, record accepted/rejected counts, add history entry

### Step 8: Enrichment Author

1. **Check if any enrichments were accepted** — Read `{explore-dir}/02a-filtered-enrichment-discussion.md` for `>> RESOLVED [ACCEPTED]` markers. If zero accepted:
   - No exploration summary needed — Step 9 Generator will run from primary source only
   - Update state file: Mark "Step 8: Enrichment Author" complete `[x]`, set `Explore Phase` = `complete`, add history entry "No enrichments accepted — Generator will use primary source only"
   - Proceed to Step 9

2. **Spawn Enrichment Author agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/02-prd/create/enrichment-author.md

   Input:
   - Blueprint: {primary-source}
   - PRD guide: {{GUIDES_PATH}}/02-prd-guide.md
   - Filtered enrichment discussion: {explore-dir}/02a-filtered-enrichment-discussion.md

   Output: {explore-dir}/03-exploration-summary.md
   ```

3. **Wait for agent to complete**

4. **Verify output exists** at `{explore-dir}/03-exploration-summary.md`

5. **Update state file**: Mark "Step 8: Enrichment Author" complete `[x]`, set `Explore Phase` = `complete`, set phase = Generate, add history entry

---

## Phase 2: Generate

### Step 9: Generate or Apply Enrichments

**On resume**: If Step 9 already marked complete, verify `{round-dir}/00-draft-prd.md` exists and skip to Step 10. For round 1: do NOT re-run the Generator (it appends to downstream deferred items files and would create duplicates).

**Round 1** and **Round 2+** use different approaches:
- **Round 1**: No prior draft exists — the Generator creates the PRD from scratch using the Blueprint
- **Round 2+**: A prior draft exists — the Enrichment Applicator applies accepted enrichments as targeted edits to the previous round's draft

#### Round 1: Run Generator

1. **Determine exploration summary path**: Check if `{explore-dir}/03-exploration-summary.md` exists. If yes, include it as input. If no (exploration was skipped or no enrichments accepted), omit it.

2. **Spawn Generator agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/02-prd/create/generator.md

   Input:
   - Blueprint: system-design/01-blueprint/blueprint.md
   - PRD guide: {{GUIDES_PATH}}/02-prd-guide.md
   - Deferred items: system-design/02-prd/versions/deferred-items.md
   - Brief: system-design/02-prd/brief.md (if exists)
   [If exploration summary exists:]
   - Exploration summary: {explore-dir}/03-exploration-summary.md

   Output: {round-dir}/00-draft-prd.md

   Downstream deferred items (Generator may append):
   - Foundations: system-design/03-foundations/versions/deferred-items.md
   - Architecture: system-design/04-architecture/versions/deferred-items.md
   - Components: system-design/05-components/versions/deferred-items.md
   ```

3. **Wait for Generator to complete**

4. **Verify output exists** at `{round-dir}/00-draft-prd.md`

5. **Update state file**: Mark "Step 9: Generate or Apply Enrichments" complete `[x]`, add history entry

#### Round 2+: Apply Enrichments

1. **Copy previous round's draft** to `{round-dir}/00-draft-prd.md` using Bash cp:
   ```
   cp [previous round's latest draft per Path Resolution] {round-dir}/00-draft-prd.md
   ```

2. **Determine exploration summary path**: Check if `{explore-dir}/03-exploration-summary.md` exists.
   - **If NO** (exploration was skipped or no enrichments accepted): Draft is already copied with no changes needed. Skip to step 5.
   - **If YES**: Continue to step 3.

3. **Spawn Enrichment Applicator agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/02-prd/create/enrichment-applicator.md

   Input:
   - Draft PRD: {round-dir}/00-draft-prd.md
   - Exploration summary: {explore-dir}/03-exploration-summary.md
   - PRD guide: {{GUIDES_PATH}}/02-prd-guide.md

   Output:
   - Updated PRD: {round-dir}/00-draft-prd.md (edit in place)
   - Change log: {round-dir}/00-enrichment-applicator-output.md
   ```

4. **Wait for Enrichment Applicator to complete**

5. **Verify output exists** at `{round-dir}/00-draft-prd.md`

6. **Update state file**: Mark "Step 9: Generate or Apply Enrichments" complete `[x]`, add history entry

### Step 10: Gap Resolution (`WAITING_FOR_HUMAN`)

**On resume**: If status = WAITING_FOR_HUMAN for Step 10, re-read draft and present gap summary to human.

1. **Read the draft** at `{round-dir}/00-draft-prd.md`

2. **Check for Gap Summary section** — Look for `## Gap Summary` heading

3. **Determine gap status**:
   - If no Gap Summary, or all subsections empty (Must Answer, Should Answer, and Assumptions all show "None" or similar) → no gaps
   - Otherwise → gaps exist

4. **Update state file**: Set `Gaps Exist` = `true` or `false`, set status = WAITING_FOR_HUMAN

5. **Notify user** the draft is ready for review:

   **If gaps exist:**
   ```
   Draft PRD generated (round {N}).

   Draft: {round-dir}/00-draft-prd.md

   The draft has the following gaps:

   Must Answer:
   - [List each must-answer gap]

   Should Answer:
   - [List each should-answer gap]

   Assumptions to Validate:
   - [List each assumption]

   You can:
   - Edit the draft directly — replace gap markers with your answers
   - Provide answers here — I'll create a resolutions file and have the Author apply them
   - Say "another round" — run another explore→generate cycle using this draft as input
   - Say "promote" — promote the current draft as-is

   When ready, let me know how you'd like to proceed.
   ```

   **If no gaps:**
   ```
   Draft PRD generated (round {N}) — no gaps found.

   Draft: {round-dir}/00-draft-prd.md

   You can:
   - Say "promote" — promote the draft
   - Say "another round" — run another explore→generate cycle to deepen the PRD

   When ready, let me know.
   ```

**STOP: Wait for human response before proceeding.**

6. **After human responds**:

   **If "another round"**:
   - Determine the latest draft for this round:
     - If `{round-dir}/03-updated-prd.md` exists (Author ran): use it
     - Otherwise: use `{round-dir}/00-draft-prd.md`
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

   **If human edited the draft directly**:
   - After human confirms edits are done, ask: "Draft updated. Promote or another round?"
   - Wait for response, handle "promote" or "another round" as above

   **If human provides answers in conversation**:
   - **Create gap resolutions file** at `{round-dir}/01-gap-resolutions.md` recording the human's answers in gap discussion format:
     ```markdown
     # Gap Resolutions

     Answers provided by the human for gaps in the draft PRD.

     ---

     ## GAP-001
     **Gap**: [The gap marker text from the draft]
     **Section**: [Which PRD section contains this gap]
     **Severity**: [Must Answer | Should Answer | Assumption]

     >> HUMAN:
     [The human's answer]

     >> RESOLVED

     ---

     ## GAP-002
     [Same structure for each answered gap]
     ```
   - **Spawn Author agent** using Task tool:
     ```
     Follow the instructions in: {{AGENTS_PATH}}/02-prd/create/author.md

     Input:
     - Draft PRD: {round-dir}/00-draft-prd.md
     - Gap discussion: {round-dir}/01-gap-resolutions.md
     - PRD guide: {{GUIDES_PATH}}/02-prd-guide.md

     Output:
     - Change log: {round-dir}/02-author-output.md
     - Updated PRD: {round-dir}/03-updated-prd.md
     ```
   - Wait for Author to complete
   - Verify outputs exist
   - Ask: "Gaps resolved and applied. Promote or another round?"
   - Wait for response, handle "promote" or "another round" as above

---

## Phase 3: Promote

Phase 3 runs only when the human chooses to promote at Step 10, exiting the explore→generate loop.

### Step 11: Promote

1. **Determine final draft path** (from the current round):
    - If `{round-dir}/03-updated-prd.md` exists (Author ran): Use it
    - Otherwise: Use `{round-dir}/00-draft-prd.md`

2. **Copy final draft to `prd.md`** using Bash cp:
    ```
    cp [final draft path] system-design/02-prd/prd.md
    ```

3. **Verify promotion** — Confirm `system-design/02-prd/prd.md` exists

4. **Update state file**: Mark "Step 11: Promote" complete `[x]`, set status = COMPLETE, add history entry

5. **Check downstream deferred items** for items the Generator deferred

6. **Present summary**:
    ```
    PRD creation complete (after {total_rounds} round(s)).

    Final round ({N}):
    - [N] capability areas explored, [M] enrichments accepted, [K] rejected
    [If exploration was skipped in final round:]
    - Exploration skipped

    Final draft: {round-dir}/00-draft-prd.md
    [If Author ran in final round:]
    Updated: {round-dir}/03-updated-prd.md
    Promoted to: system-design/02-prd/prd.md

    Brief: [Used / Not provided]

    [If gaps existed in final round:]
    Gap resolution:
    - [N] gaps in final draft
    - [Resolved by: direct edit / Author / deferred to review]

    [If no gaps in final round:]
    No gaps found in final draft.

    Deferred to downstream:
    - [X] items to Foundations deferred items
    - [Y] items to Architecture deferred items
    - [Z] items to Components deferred items

    Next steps:
    1. Review prd.md — verify promoted content looks correct
    2. When ready, run the PRD Review workflow
       (Review reads from: system-design/02-prd/prd.md)
    ```

---

## Stopping Points

**Automatic flow (do NOT pause for human confirmation):**
- Steps 1 → 2: Setup then identifier
- Steps 4 → 5 → 6: Explorers then consolidator then scope filter
- Steps 8 → 9: Enrichment author then generator
- Step 11: Promote

**Automatic flow discipline**: Between automatic steps, the orchestrator updates state and spawns the next agent without pausing. Do not read files unless the step instructions explicitly direct you to. Each step already specifies what the orchestrator reads (e.g., "Read the capabilities file," "Check for Gap Summary"). If a read is not in the step instructions, do not perform it — agents read their own inputs.

**Human checkpoints:**
- **Step 3** — WAITING_FOR_HUMAN for capability review
- **Step 7** — WAITING_FOR_HUMAN for enrichment review until all enrichments resolved
- **Step 10** — WAITING_FOR_HUMAN for gap resolution (promote vs another round)

**Skip paths:**
- **Explore skip** — If fewer than 2 capability areas (Step 2) or human says "skip" (Step 3) → jump to Step 9
- **Gap skip** — If no gaps in draft (Step 10) → still present promote/another-round choice

**Loop path:**
- **Another round** — If human says "another round" at Step 10 → increment round, reset Steps 1–10, loop to Step 1

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Blueprint not found | Error: "Cannot initialize PRD — Blueprint not found at system-design/01-blueprint/blueprint.md" |
| Primary source not found | Error: "Primary source not found at {primary-source}" |
| Capability Identifier fails | Error: Report failure details |
| Capabilities file not created | Error: "Capability Identifier completed but output not found" |
| Explorer fails | Error: Report which capability area's explorer failed |
| Consolidator fails | Error: Report failure details |
| Enrichment Scope Filter fails | Error: Report failure details |
| Filtered enrichment file not created | Error: "Enrichment Scope Filter completed but output not found" |
| Enrichment Author fails | Error: Report failure details |
| Generator fails | Error: Report failure details |
| Draft not created | Error: "Generator completed but draft not found at expected path" |
| Author fails | Error: Report failure details |
| Author output files not created | Error: "Author completed but outputs not found" |
| Promotion copy fails | Error: "Failed to copy final draft to prd.md" |
| State file corrupted/unreadable | Warning: Report issue, re-create state from file existence checks |
| Resume: draft missing but Step 9 marked complete | Error: "State says Generator complete but draft not found — re-run Generator or fix state file" |
| Round N primary source missing | Error: "Round {N} requires draft from round {N-1} but no draft found" |
| Current Workflow = Review | Error: "Review workflow is active. Cannot re-run creation." |

---

## What Happens Next

After this orchestrator completes:

1. **Human reviews promoted PRD** — Opens `system-design/02-prd/prd.md`
2. **Human optionally makes manual edits** — Can refine directly
3. **Human runs Review workflow** — Invokes the PRD Review orchestrator

**IMPORTANT**: The Review workflow reads from `system-design/02-prd/prd.md` for Round 1. This file is created by the promotion step (Step 11). It MUST exist before starting the Review workflow.

The Review workflow will:
- Run expert reviewers on the PRD
- Facilitate discussion on issues found
- Author changes and verify alignment with Blueprint
- Promote final version (overwriting `prd.md` with reviewed version)

---

<!-- INJECT: tool-restrictions -->
