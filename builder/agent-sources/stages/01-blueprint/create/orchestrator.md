# Blueprint Creation Orchestrator

---

## Purpose

Initialize the Blueprint stage by setting up structure, exploring strategic dimensions, generating a draft Blueprint enriched by exploration findings and any completed decision analyses, resolving gaps with the human, and iterating through additional explore→generate rounds as needed. When the human is satisfied, promote the final draft and extract a scope brief for downstream stages.

**Flow:** Setup → [Explore → Generate → Gap Resolution]* → Extract (promote + scope brief)

The explore→generate cycle can repeat for as many rounds as the human wants. Round 1 explores from the concept document. Round 2+ explores from the previous round's draft, finding dimensions and enrichments that the earlier round missed or underexplored. The human exits the loop by choosing to promote at Gap Resolution.

Strategic decisions identified during enrichment review are handled by the separate Decision Orchestrator, not this workflow. The Blueprint proceeds with pending decisions marked as gaps.

---

## When to Run

Run this orchestrator at the start of a new project, with a concept document. Safe to re-invoke — the orchestrator reads its state file and resumes from the last completed step.

---

## Fixed Paths

**State file**: `system-design/01-blueprint/versions/workflow-state.md`

**Primary source** (determined by current round — see Path Resolution below):
- Round 1: `system-design/01-blueprint/concept.md`
- Round N (N≥2): Latest draft from round N-1

**Explore phase outputs**: `system-design/01-blueprint/versions/round-{N}-create/explore/`

Files within the explore directory:
- `00-dimensions.md`
- `01-explorer-{dim-name}.md`
- `02-enrichment-discussion.md`
- `02a-filtered-enrichment-discussion.md`
- `03-exploration-summary.md`

**Decision outputs** (managed by Decision Orchestrator):
- `system-design/01-blueprint/decisions/{decision-name}/framework.md`
- `system-design/01-blueprint/decisions/{decision-name}/analysis.md`
- `system-design/01-blueprint/decisions/{decision-name}/context.md` (originating context — written at registration)
- `system-design/01-blueprint/decisions/{decision-name}/additional-context.md` (optional — enrichments routed as supplementary context)

**Generate phase outputs** (in `versions/round-{N}-create/`):
- `00-draft-blueprint.md`
- `01-gap-resolutions.md`
- `02-author-output.md`
- `03-updated-blueprint.md`

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
├── enrichment-scope-filter.md         # Filters enrichments by level/depth
├── enrichment-author.md               # Produces exploration summary
├── decision-orchestrator.md           # Handles one decision (framework + analysis) — separate workflow
├── decision-framework.md              # Defines decision criteria with human (used by decision orchestrator)
├── decision-analyst.md                # Evaluates options against framework (used by decision orchestrator)
├── generator.md                       # Creates draft from concept + enrichments + decisions
├── author.md                          # Applies gap resolutions to draft
└── scope-extractor.md                 # Extracts scope brief from blueprint

agents/universal-agents/
└── discussion-facilitator.md          # Facilitates enrichment discussions
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
│       ├── context.md                 # Originating context (written at registration)
│       ├── framework.md               # Evaluation criteria (human-approved)
│       ├── analysis.md                # Options evaluated, final decision
│       └── additional-context.md      # Supplementary context routed later (optional)
└── versions/
    ├── deferred-items.md              # Items deferred from concept
    ├── pending-issues.md              # Issues logged against this stage
    ├── out-of-scope.md                # Non-documentation content from concept
    ├── workflow-state.md              # Unified workflow state (shared with Review)
    ├── round-1-create/                 # Creation round 1
    │   ├── explore/
    │   │   ├── 00-dimensions.md
    │   │   ├── 01-explorer-*.md
    │   │   ├── 02-enrichment-discussion.md
    │   │   ├── 02a-filtered-enrichment-discussion.md
    │   │   └── 03-exploration-summary.md
    │   ├── 00-draft-blueprint.md
    │   ├── 01-gap-resolutions.md
    │   ├── 02-author-output.md
    │   └── 03-updated-blueprint.md
    ├── round-{N}-create/              # Additional create rounds (if "another round")
    │   ├── explore/
    │   │   └── [same explore files]
    │   └── [same generate files]
    ├── round-1-review/                # Review round 1
    │   └── [review workflow files]
    └── round-{N}-review/
        └── ...
```

---

## Workflow State Management

**State file**: `system-design/01-blueprint/versions/workflow-state.md`

### On Start/Resume

1. **Check if state file exists**:
   - **If NO**: Fresh start — create state file (with `Current Workflow: Create`), begin at Step 1
   - **If YES**: Read it, check `Current Workflow`:
     - **If `Review`**: Error — "Review workflow is active. Cannot re-run creation."
     - **If `Create`**: Resume from the first incomplete step

2. **Resume logic**:
   - Step 1 (Setup) is idempotent — always re-run on resume for validation
   - Step 2 (Dimension Identifier) — if marked complete, verify `{explore-dir}/00-dimensions.md` exists and skip
   - Step 3 resumes at WAITING_FOR_HUMAN — re-read dimensions file and present to human
   - Steps 2–8 (Explore phase) — if all marked SKIPPED, jump to Step 9
   - Step 7 resumes at WAITING_FOR_HUMAN — re-read filtered enrichment discussion file and continue loop
   - Step 9 (Generator) is non-idempotent — if marked complete, verify draft exists and skip
   - Step 10 resumes at WAITING_FOR_HUMAN — re-read draft and present gap summary to human

3. **Update state file** at each step transition (instructions inline below)

4. **Resolve paths** using Path Resolution (below) before executing any step

### State File Format

```markdown
# Blueprint Workflow State

**Blueprint**: 01-blueprint/blueprint.md
**Current Workflow**: Create
**Current Phase**: Explore | Generate | Extract
**Current Round**: 1
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
- [ ] Step 6: Enrichment Scope Filter
- [ ] Step 7: Enrichment Review
- [ ] Step 8: Enrichment Author

### Phase 2: Generate
- [ ] Step 9: Run Generator
- [ ] Step 10: Gap Resolution
- [ ] Step 10b: Creation Verification

### Phase 3: Extract
- [ ] Step 11: Promote
- [ ] Step 12: Scope Extract

## Explore Details

Dimensions: [DIM-1, DIM-2, ...] or [none]
Enrichments Accepted: [N]
Enrichments Rejected: [N]
Enrichments Decision Needed: [N]
Enrichments Decision Context: [N]

## Decision Analysis

Decisions are handled by the Decision Orchestrator (separate workflow).
Status is tracked here so the Generator knows which decisions are resolved.

Decisions:
  - {decision-name} (round-{N}): PENDING | FRAMEWORK_IN_PROGRESS | FRAMEWORK_APPROVED | ANALYSIS_IN_PROGRESS | COMPLETE

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
- You COPY the final draft to `blueprint.md` (promotion)
- You DO NOT write draft content, exploration content, decision content, or author output — agents do that
- Spawn agents in FOREGROUND (not background) — agents need interactive approval for file writes

**Context management**: The orchestrator persists across the entire creation lifecycle. Every document you Read stays in context. Spawned subagents run in their own context via the Task tool. Keep your context lean — use Grep for targeted extraction from state and output files, `ls` for existence checks. Working files are read by subagents, not by the orchestrator.

**What You Read:**
- Workflow state file (to determine current step and status)
- Agent output files (to verify completion and extract counts for handoff messages)

**What You Do NOT Read:**
- Agent prompt files — agents read their own instructions
- Input documents being passed to agents (PRD, Foundations, guide, etc.)
- Any file where you're passing the path to an agent

Rule: If a file path appears in your agent invocation, don't read it yourself.

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
- Round 1: `system-design/01-blueprint/concept.md`
- Round N (N≥2): Determine from round N-1 outputs:
  - If `system-design/01-blueprint/versions/round-{N-1}-create/03-updated-blueprint.md` exists → use it
  - Otherwise → use `system-design/01-blueprint/versions/round-{N-1}-create/00-draft-blueprint.md`

**Explore directory** (`{explore-dir}`): `system-design/01-blueprint/versions/round-{N}-create/explore/`

**Round directory** (`{round-dir}`): `system-design/01-blueprint/versions/round-{N}-create/`

All steps below use `{primary-source}`, `{explore-dir}`, and `{round-dir}` to refer to these resolved paths. **Resolve them once at startup and again after any round increment.**

---

## Phase 1: Explore

### Step 1: Setup

0. **Update state file**: Set status = IN_PROGRESS, phase = Explore (create state file if fresh start)

1. **Create directories** (if not exist):

   **Round 1 (first run):**
   ```
   system-design/01-blueprint/
   ├── decisions/
   └── versions/
       └── round-1-create/
           └── explore/
   ```

   **Round N (N≥2, "another round"):**
   ```
   system-design/01-blueprint/versions/
   └── round-{N}-create/
       └── explore/
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

**On resume**: If Step 2 already marked complete, verify `{explore-dir}/00-dimensions.md` exists and skip to Step 3.

1. **Verify primary source exists** — Read `{primary-source}` to confirm it's present

2. **Spawn Dimension Identifier agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/01-blueprint/create/dimension-identifier.md

   Input:
   - Concept: {primary-source}
   - Blueprint guide: {{GUIDES_PATH}}/01-blueprint-guide.md
   - Workflow state: system-design/01-blueprint/versions/workflow-state.md

   Output: {explore-dir}/00-dimensions.md
   ```

3. **Wait for agent to complete**

4. **Verify output exists** at `{explore-dir}/00-dimensions.md`

5. **Read the dimensions file** — Count dimensions. If fewer than 2 dimensions identified:
   - **Update state file**: Set `Explore Phase` = `skipped`, mark Steps 2–8 as `[x] SKIPPED`, add history entry "Fewer than 2 dimensions — skipping exploration"
   - **Skip to Step 9**

6. **Update state file**: Mark "Step 2: Dimension Identifier" complete `[x]`, record dimension list, add history entry

### Step 3: Dimension Review (`WAITING_FOR_HUMAN`)

**On resume**: If status = WAITING_FOR_HUMAN for Step 3, re-read dimensions file and present to human.

1. **Update state file**: Set status = WAITING_FOR_HUMAN

2. **Notify user** that dimensions are ready for review:
   ```
   Strategic dimensions identified for exploration.

   Dimensions file: {explore-dir}/00-dimensions.md

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
   - If human says "skip exploration" → Set `Explore Phase` = `skipped`, mark Steps 3–8 as `[x] SKIPPED`, skip to Step 9
   - Otherwise → Re-read dimensions file (human may have edited it), update dimension list in state file

4. **Update state file**: Mark "Step 3: Dimension Review" complete `[x]`, set status = IN_PROGRESS, add history entry

### Step 4: Dimension Explorers (parallel)

1. **Read the dimensions file** to get the final list of accepted dimensions

2. **Check for decision overlaps**: For each dimension, check if it has a `**Decision overlap**:` field. If so, extract the decision name and check which decision files exist:
   - `system-design/01-blueprint/decisions/{decision-name}/framework.md`
   - `system-design/01-blueprint/decisions/{decision-name}/additional-context.md`

3. **Spawn Dimension Explorer agents** using Task tool (one per dimension, in parallel):
   ```
   Follow the instructions in: {{AGENTS_PATH}}/01-blueprint/create/dimension-explorer.md

   Input:
   - Concept: {primary-source}
   - Dimensions file: {explore-dir}/00-dimensions.md
   - Assigned dimension: DIM-[N]
   [If dimension has decision overlap and files exist:]
   - Decision framework: system-design/01-blueprint/decisions/{decision-name}/framework.md
   [If additional-context.md exists:]
   - Decision additional context: system-design/01-blueprint/decisions/{decision-name}/additional-context.md

   Output: {explore-dir}/01-explorer-{dim-name}.md
   ```

   Replace `{dim-name}` with a kebab-case version of the dimension name.

4. **Wait for all explorers to complete**

5. **Verify outputs exist** — Check each expected `01-explorer-*.md` file exists in `{explore-dir}/`

6. **Update state file**: Mark "Step 4: Dimension Explorers" complete `[x]`, add history entry with explorer count

### Step 5: Exploration Consolidator

1. **Spawn Exploration Consolidator agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/01-blueprint/create/exploration-consolidator.md

   Input:
   - Concept: {primary-source}
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
   Follow the instructions in: {{AGENTS_PATH}}/01-blueprint/create/enrichment-scope-filter.md

   Input:
   - Blueprint guide: {{GUIDES_PATH}}/01-blueprint-guide.md
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

   [N] enrichments from [M] dimensions, grouped by Blueprint section impact.

   Each enrichment has analysis, trade-offs, and a recommendation.
   Please review each and respond after the >> HUMAN: markers.

   Respond naturally — say what you think. Examples:
   - Accept: "Happy with this", "Accept", "Agree", "Yes"
   - Reject: "Disagree — [reason]", "Not needed", "Reject"
   - Accept with changes: State what to change — e.g., "Good, but make it a should-do rather than must-do"
   - Route to existing decision: "Add to [decision-name] framework" — routes as context for that pending decision
   - New decision needed: "Decision needed: [name]" — creates a new decision framework
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
       - **DECISION CONTEXT**: Enrichment should feed into an existing pending decision rather than the Blueprint directly. Indicators: "add to [decision-name]", "part of the [decision-name] framework", "should feed into [decision]", reference to a pending decision by name or topic. Cross-reference with the Decision Analysis section of the state file to identify which decision.
       - **DECISION NEEDED**: A new strategic decision should be created. Indicators: "decision needed", "needs its own framework", "this is a strategic choice that needs analysis". This creates a NEW decision, not a reference to an existing one.
       - **QUESTION/DISCUSSION**: Question, concern without clear accept/reject, or request for exploration before deciding. Indicators: questions, hedging without clear direction, requests for more information.

       **Compound responses** — A response may contain multiple signals. Apply this priority:
       - Accept with no additional content → ACCEPT.
       - Accept + any question, observation, or concern → ACCEPT WITH DISCUSSION. Do not judge whether the question is "informational" or "substantive" — if the human raised a point alongside acceptance, it warrants a response.
       - Agreement + disagreement on different aspects → ACCEPT WITH MODIFICATION.
       - Route to decision + accept → DECISION CONTEXT (enrichment feeds the decision, does not also go into the Blueprint).

       **Overlap check** — Before confirming, read the Decision Analysis section of the state file. For each enrichment being classified as ACCEPT or ACCEPT WITH MODIFICATION, check whether its topic overlaps with a registered pending decision (match by topic/content, not just name). If it does, flag it in the confirmation. Only flag genuine topical overlaps — not every enrichment needs this check.

       **Phase 2 — Confirm**: Present ALL interpretations to the human at once:
       ```
       Here's how I interpret your responses:

       ENR-001: **Accept with modification** — keep enrichment but adjust framing per your note
       ENR-002: **Reject** — you disagree with the premise
       ENR-003: **Accept with modification** — change from must-do to should-do
       ENR-007: **Accept** (Note: this overlaps with the pending `source-strategy` decision — route as decision context instead?)
       [... all enrichments with responses ...]

       Is that correct? (Clarify any I got wrong and I'll re-interpret.)
       ```

       **STOP: Wait for human to confirm or correct before proceeding.**

       After confirmation, apply the confirmed classifications:
       - ACCEPT → Add `>> RESOLVED [ACCEPTED]` after the human response
       - REJECT → Add `>> RESOLVED [REJECTED]` after the human response
       - ACCEPT WITH MODIFICATION → Add `>> RESOLVED [ACCEPTED]` after the human response (the modification is preserved in the human's text)
       - ACCEPT WITH DISCUSSION → Leave unresolved for discussion facilitator (acceptance is noted but the raised point needs a response first)
       - DECISION CONTEXT → Add `>> RESOLVED [DECISION CONTEXT]: {decision-name}` after the human response
       - DECISION NEEDED → Add `>> RESOLVED [DECISION NEEDED]: {decision-name}` after the human response
       - QUESTION/DISCUSSION → Leave unresolved for discussion facilitator

    c. **If any enrichments need discussion** (ACCEPT WITH DISCUSSION or QUESTION/DISCUSSION):
       - **Spawn Discussion Facilitator agents** (batched by group):
         ```
         Follow the instructions in: {{AGENTS_PATH}}/universal-agents/discussion-facilitator.md

         Context documents:
         - Concept: {primary-source}

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

    d. **If all enrichments resolved**: Continue to decision context routing below

    e. **Route decision context enrichments**: For each enrichment marked `>> RESOLVED [DECISION CONTEXT]: {decision-name}`:
       - Read the enrichment entry (proposal, trade-offs, agent analysis, human response)
       - If `system-design/01-blueprint/decisions/{decision-name}/additional-context.md` does not exist, create it:
         ```markdown
         # Additional Context: {decision-name}

         Supplementary enrichments routed to this decision as additional context.
         Read alongside `context.md` and `framework.md`.

         ---
         ```
       - Append the enrichment context:
         ```markdown
         ## {ENR-NNN}: {enrichment-title}

         **Source**: {explore-dir}/02a-filtered-enrichment-discussion.md
         **Round**: {current-round}

         **Proposal**: [copy from enrichment]

         **Human response**: [copy from >> HUMAN: block]

         ---
         ```

4. **Register new decisions**: If any enrichments were marked `>> RESOLVED [DECISION NEEDED]`:
   - Read each `>> RESOLVED [DECISION NEEDED]: {decision-name}` marker
   - Extract the enrichment ID (ENR-NNN) and decision name for each
   - Create decision folders at `system-design/01-blueprint/decisions/{decision-name}/`
   - **Write `context.md`** in the decision folder — extract the enrichment entry (proposal, trade-offs, agent analysis, human response) from the enrichment discussion file:
     ```markdown
     # Decision Context: {decision-name}

     Context extracted from enrichment review at registration.

     ---

     ## Source

     **Enrichment**: ENR-NNN
     **Round**: {current-round}
     **Source file**: {explore-dir}/02a-filtered-enrichment-discussion.md

     ## Enrichment Content

     [Copy the full enrichment entry: proposal, trade-offs, agent analysis, human response]

     ---
     ```
   - Add each decision to the Decision Analysis section of the state file with status PENDING and round number:
     ```
     - {decision-name} (round-{N}): PENDING
     ```

5. **Notify user about pending decisions** (if any new decisions or decision context routed):
   ```
   [If new decisions:]
   [N] enrichments require decision analysis:
   - {decision-1}
   - {decision-2}

   These will be marked as pending gaps in the Blueprint.
   Run the Decision Orchestrator for each when ready (in a separate conversation):

     Read the Decision Orchestrator at:
     agents/01-blueprint/create/decision-orchestrator.md

     Decision name: {decision-name}

   [If decision context routed:]
   [N] enrichments routed as additional context for existing decisions:
   - ENR-NNN → {decision-name}

   This context will be available when the Decision Orchestrator runs.

   Continuing to generate Blueprint...
   ```

6. **Update state file**: Mark "Step 7: Enrichment Review" complete `[x]`, set status = IN_PROGRESS, record accepted/rejected/decision-needed/decision-context counts, add history entry

### Step 8: Enrichment Author

1. **Check if any enrichments were accepted** — Read `{explore-dir}/02a-filtered-enrichment-discussion.md` for `>> RESOLVED [ACCEPTED]` markers. If zero accepted:
   - No exploration summary needed — Step 9 Generator will run from primary source + decisions only
   - Update state file: Mark "Step 8: Enrichment Author" complete `[x]`, set `Explore Phase` = `complete`, add history entry "No enrichments accepted — Generator will use primary source and decisions only"
   - Proceed to Step 9

2. **Spawn Enrichment Author agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/01-blueprint/create/enrichment-author.md

   Input:
   - Concept: {primary-source}
   - Blueprint guide: {{GUIDES_PATH}}/01-blueprint-guide.md
   - Filtered enrichment discussion: {explore-dir}/02a-filtered-enrichment-discussion.md

   Output: {explore-dir}/03-exploration-summary.md
   ```

3. **Wait for agent to complete**

4. **Verify output exists** at `{explore-dir}/03-exploration-summary.md`

5. **Update state file**: Mark "Step 8: Enrichment Author" complete `[x]`, set `Explore Phase` = `complete`, set phase = Generate, add history entry

---

## Phase 2: Generate

### Step 9: Run Generator

**On resume**: If Step 9 already marked complete, verify `{round-dir}/00-draft-blueprint.md` exists and skip to Step 10. Do NOT re-run the Generator (it appends to downstream deferred items files and would create duplicates).

1. **Determine exploration summary path**: Check if `{explore-dir}/03-exploration-summary.md` exists. If yes, include it as input. If no (exploration was skipped or no enrichments accepted), omit it.

2. **Determine decision status**: Read the Decision Analysis section of the workflow state file.
   - For each decision with status COMPLETE: check that `decisions/{decision-name}/analysis.md` exists. Add to the resolved decisions list.
   - For each decision with status other than COMPLETE: add to the pending decisions list with the decision question (read from `decisions/{decision-name}/context.md`).

3. **Spawn Generator agent** using Task tool:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/01-blueprint/create/generator.md

   Input:
   - Concept: {primary-source}
   - Blueprint guide: {{GUIDES_PATH}}/01-blueprint-guide.md
   [If exploration summary exists:]
   - Exploration summary: {explore-dir}/03-exploration-summary.md
   [If resolved decisions exist:]
   - Decision analyses (resolved — incorporate as settled decisions):
     - system-design/01-blueprint/decisions/{decision-1}/analysis.md
     [List all resolved decision analysis files]
   [If pending decisions exist:]
   - Pending decisions (mark as gaps in the relevant Blueprint sections):
     - {decision-name}: "[enrichment title / decision question summary]"
     [List all pending decisions with their descriptions]

   Output: {round-dir}/00-draft-blueprint.md

   Downstream deferred items (Generator may append):
   - PRD: system-design/02-prd/versions/deferred-items.md
   - Foundations: system-design/03-foundations/versions/deferred-items.md
   - Architecture: system-design/04-architecture/versions/deferred-items.md
   - Components: system-design/05-components/versions/deferred-items.md
   ```

4. **Wait for Generator to complete**

5. **Verify output exists** at `{round-dir}/00-draft-blueprint.md`

6. **Update state file**: Mark "Step 9: Run Generator" complete `[x]`, add history entry

### Step 10: Gap Resolution (`WAITING_FOR_HUMAN`)

**On resume**: If status = WAITING_FOR_HUMAN for Step 10, re-read draft and present gap summary to human.

1. **Read the draft** at `{round-dir}/00-draft-blueprint.md`

2. **Check for Gap Summary section** — Look for `## Gap Summary` heading

3. **Determine gap status**:
   - If no Gap Summary, or all subsections empty (Must Answer, Should Answer, and Assumptions all show "None" or similar) → no gaps
   - Otherwise → gaps exist

4. **Detect and register gap-sourced decisions**: Scan the Gap Summary for `[DECISION NEEDED]` entries. For each one found that is NOT already registered in the Decision Analysis section of the state file:
   - Derive a decision name in kebab-case from the gap text (e.g., "Which specific niches..." → `niche-selection`)
   - Create the decision folder at `system-design/01-blueprint/decisions/{decision-name}/`
   - **Write `context.md`** in the decision folder — extract the gap marker text and its surrounding Blueprint section from the draft:
     ```markdown
     # Decision Context: {decision-name}

     Context extracted from Generator gap markers at registration.

     ---

     ## Source

     **Gap marker**: [The full gap marker text from the draft]
     **Blueprint section**: [Which section of the draft contains this gap]
     **Round**: {current-round}
     **Source file**: {round-dir}/00-draft-blueprint.md

     ## Context

     [Copy the relevant surrounding content from the Blueprint section where the gap appears — enough for the Decision Framework agent to understand the full context without reading the draft]

     ---
     ```
   - Add to the Decision Analysis section of the state file:
     ```
     - {decision-name} (round-{N}): PENDING
     ```

5. **Update state file**: Set `Gaps Exist` = `true` or `false`, set status = WAITING_FOR_HUMAN

6. **Notify user** the draft is ready for review:

   **If gaps exist:**
   ```
   Draft Blueprint generated (round {N}).

   Draft: {round-dir}/00-draft-blueprint.md

   The draft has the following gaps:

   Must Answer:
   - [List each must-answer gap]

   Should Answer:
   - [List each should-answer gap]

   Assumptions to Validate:
   - [List each assumption]

   [If decisions were registered in step 4:]
   Decisions registered:
   - {decision-name}: [gap marker text summary]
   Run the Decision Orchestrator for each before promoting.

   You can:
   - Edit the draft directly — replace gap markers with your answers
   - Provide answers here — I'll create a resolutions file and have the Author apply them
   - Run the Decision Orchestrator for pending decisions (in a separate conversation)
   - Say "another round" — run another explore→generate cycle using this draft as input
   - Say "promote" — promote the current draft and extract scope brief

   When ready, let me know how you'd like to proceed.
   ```

   **If no gaps:**
   ```
   Draft Blueprint generated (round {N}) — no gaps found.

   Draft: {round-dir}/00-draft-blueprint.md

   You can:
   - Say "promote" — promote the draft and extract scope brief
   - Say "another round" — run another explore→generate cycle to deepen the Blueprint

   When ready, let me know.
   ```

**STOP: Wait for human response before proceeding.**

7. **After human responds**:

   **If "another round"**:
   - Determine the latest draft for this round:
     - If `{round-dir}/03-updated-blueprint.md` exists (Author ran): use it
     - Otherwise: use `{round-dir}/00-draft-blueprint.md`
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

     Answers provided by the human for gaps in the draft Blueprint.

     ---

     ## GAP-001
     **Gap**: [The gap marker text from the draft]
     **Section**: [Which Blueprint section contains this gap]
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
     Follow the instructions in: {{AGENTS_PATH}}/01-blueprint/create/author.md

     Input:
     - Draft Blueprint: {round-dir}/00-draft-blueprint.md
     - Gap discussion: {round-dir}/01-gap-resolutions.md
     - Blueprint guide: {{GUIDES_PATH}}/01-blueprint-guide.md

     Output:
     - Change log: {round-dir}/02-author-output.md
     - Updated Blueprint: {round-dir}/03-updated-blueprint.md
     ```
   - Wait for Author to complete
   - Verify outputs exist
   - Ask: "Gaps resolved and applied. Promote or another round?"
   - Wait for response, handle "promote" or "another round" as above

---

### Step 10b: Creation Verification

**Purpose**: Verify internal coherence of the draft before promotion. Catches cross-section consistency gaps introduced during creation.

1. **Determine draft path**:
    - If `{round-dir}/03-updated-blueprint.md` exists (Author ran): Use it
    - Otherwise: Use `{round-dir}/00-draft-blueprint.md`

2. **Spawn Internal Coherence Checker** using Task tool:
    ```
    Follow the instructions in: {{AGENTS_PATH}}/universal-agents/internal-coherence-checker.md

    Document: [draft path from step 1]
    Stage guide: {{GUIDES_PATH}}/01-blueprint-guide.md
    Output: {round-dir}/04-coherence-report.md
    ```

3. **Wait for agent to complete**

4. **Read coherence report** and check for HIGH or MEDIUM gaps

5. **If COHERENT or LOW only**: Update state file, mark "Step 10b: Creation Verification" complete `[x]`, add history entry. Proceed to promote.

6. **If HIGH or MEDIUM gaps found**: Present findings to human:
    ```
    Creation verification found cross-section consistency gaps:

    [List HIGH/MEDIUM gaps with source section, target section, and summary]

    For each: **FIX** (return to Author) or **ACCEPT** (promote as-is)?
    ```
    - If FIX: Spawn Author to address gaps, then re-run verification
    - If ACCEPT: Proceed to promote
    - Update state file: Mark "Step 10b: Creation Verification" complete `[x]`, add history entry

---

## Phase 3: Extract

Phase 3 runs only when the human chooses to promote at Step 10, exiting the explore→generate loop.

### Step 11: Promote

1. **Determine final draft path** (from the current round):
    - If `{round-dir}/03-updated-blueprint.md` exists (Author ran): Use it
    - Otherwise: Use `{round-dir}/00-draft-blueprint.md`

2. **Copy final draft to `blueprint.md`** using Bash cp:
    ```
    cp [final draft path] system-design/01-blueprint/blueprint.md
    ```

3. **Verify promotion** — Confirm `system-design/01-blueprint/blueprint.md` exists

4. **Update state file**: Mark "Step 11: Promote" complete `[x]`, add history entry

### Step 12: Scope Extract

1. **Spawn Scope Extractor agent** using Task tool:
    ```
    Follow the instructions in: {{AGENTS_PATH}}/01-blueprint/create/scope-extractor.md

    Input:
    - Blueprint: system-design/01-blueprint/blueprint.md

    Output: system-design/01-blueprint/scope-brief.md
    ```

2. **Wait for agent to complete**

3. **Verify output exists** at `system-design/01-blueprint/scope-brief.md`

4. **Update state file**: Mark "Step 12: Scope Extract" complete `[x]`, set status = COMPLETE, add history entry

5. **Check downstream deferred items** for items the Generator deferred

6. **Present summary**:
    ```
    Blueprint creation complete (after {total_rounds} round(s)).

    Final round ({N}):
    - [N] dimensions explored, [M] enrichments accepted, [K] rejected, [C] routed as decision context
    [If decisions registered across any round:]
    - [D] decisions ([R] resolved, [P] pending)
    [If exploration was skipped in final round:]
    - Exploration skipped

    Final draft: {round-dir}/00-draft-blueprint.md
    [If Author ran in final round:]
    Updated: {round-dir}/03-updated-blueprint.md
    Promoted to: system-design/01-blueprint/blueprint.md
    Scope brief: system-design/01-blueprint/scope-brief.md

    [If gaps existed in final round:]
    Gap resolution:
    - [N] gaps in final draft
    - [Resolved by: direct edit / Author / deferred to review]

    [If no gaps in final round:]
    No gaps found in final draft.

    [If pending decisions exist:]
    Pending decisions (run Decision Orchestrator when ready):
    - {decision-1} (from ENR-NNN) — PENDING
    - {decision-2} (from ENR-MMM) — FRAMEWORK_APPROVED

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
- Steps 4 → 5 → 6: Explorers then consolidator then scope filter
- Steps 8 → 9: Enrichment author then generator
- Steps 10b → 11 → 12: Verification then promote then scope extract (unless HIGH/MEDIUM gaps found)

**Human checkpoints:**
- **Step 3** — WAITING_FOR_HUMAN for dimension review
- **Step 7** — WAITING_FOR_HUMAN for enrichment review until all enrichments resolved
- **Step 10** — WAITING_FOR_HUMAN for gap resolution (promote vs another round)

**Skip paths:**
- **Explore skip** — If fewer than 2 dimensions (Step 2) or human says "skip" (Step 3) → jump to Step 9
- **Gap skip** — If no gaps in draft (Step 10) → still present promote/another-round choice

**Loop path:**
- **Another round** — If human says "another round" at Step 10 → increment round, reset Steps 1–10, loop to Step 1

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Primary source not found | Error: "Primary source not found at {primary-source}" |
| Dimension Identifier fails | Error: Report failure details |
| Dimensions file not created | Error: "Dimension Identifier completed but output not found" |
| Explorer fails | Error: Report which dimension's explorer failed |
| Consolidator fails | Error: Report failure details |
| Enrichment Scope Filter fails | Error: Report failure details |
| Filtered enrichment file not created | Error: "Enrichment Scope Filter completed but output not found" |
| Enrichment Author fails | Error: Report failure details |
| Generator fails | Error: Report failure details |
| Draft not created | Error: "Generator completed but draft not found at expected path" |
| Author fails | Error: Report failure details |
| Author output files not created | Error: "Author completed but outputs not found" |
| Scope Extractor fails | Error: Report failure details |
| Promotion copy fails | Error: "Failed to copy final draft to blueprint.md" |
| State file corrupted/unreadable | Warning: Report issue, re-create state from file existence checks |
| Resume: draft missing but Step 9 marked complete | Error: "State says Generator complete but draft not found — re-run Generator or fix state file" |
| Round N primary source missing | Error: "Round {N} requires draft from round {N-1} but no draft found" |
| Current Workflow = Review | Error: "Review workflow is active. Cannot re-run creation." |

---

## What Happens Next

After this orchestrator completes:

1. **Human reviews promoted Blueprint** — Opens `system-design/01-blueprint/blueprint.md`
2. **Human resolves pending decisions** — Runs Decision Orchestrator for each (if any)
3. **Human optionally makes manual edits** — Can refine directly
4. **Human runs Review workflow** — Invokes the Blueprint Review orchestrator

**IMPORTANT**: The Review workflow reads from `system-design/01-blueprint/blueprint.md` for Round 1. This file is created by the promotion step (Step 11). It MUST exist before starting the Review workflow.

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
