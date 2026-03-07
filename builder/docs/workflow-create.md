# Create Workflow

The Create workflow generates a draft document from upstream inputs (concept document, or output from a previous stage). The human augments the draft, then runs the Review workflow to refine it.

For a high-level overview, see `overview.md`.

---

## Flow Diagram

```
                    ┌─────────────────┐
                    │ Concept/Upstream│
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │     Setup       │◄──── Step 1
                    │ (structure,     │      (directories, deferred items)
                    │  deferred items)│
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │    Generator    │◄──── Step 2
                    │ (draft + gaps)  │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Report to Human │◄──── Step 3
                    │  (gap summary)  │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Human Augments  │◄──── Human fills in gaps
                    │   the Draft     │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Review Workflow │◄──── See workflow-review.md
                    └─────────────────┘
```

**Notes:**
- The Create workflow produces a draft; the Review workflow refines it
- **Blueprint has a custom create workflow** with an Explore phase (strategic dimension exploration, enrichment review), iterative rounds (round 0 from concept, round 1+ from previous draft), and a separate Decision Orchestrator. See `01-blueprint.md` for details. The generic flow above applies to stages 02-05.
- Component Specs has an additional Initialize step (stage-level setup before per-component creation)

---

## Step-by-Step Walkthrough

### Step 1: Setup

**Agent:** Orchestrator (performs this step directly)

The orchestrator creates the required directory structure and initialises tracking files.

**Process:**
1. Create stage directories (if not exist):
   ```
   system-design/[stage]/
   └── versions/
       └── round-0/
   ```
2. Create `deferred-items.md` (if not exists) - holds items deferred from upstream
3. Create `pending-issues.md` (if not exists) - holds issues logged against this stage

**Deferred Items Intake (for stages 02-05):**

If deferred items exist with PENDING items from upstream stages:
1. Read final upstream document(s)
2. For each PENDING item, check if addressed upstream
3. Update validation status:
   - `RESOLVED_UPSTREAM`: Fully addressed - mark closed
   - `PARTIALLY_ADDRESSED`: Touched but not resolved - pass to Generator
   - `STILL_RELEVANT`: Not addressed - pass to Generator

**Note:** Blueprint skips deferred items intake (no upstream stage).

---

### Step 2: Generate Draft

**Agent:** Generator

The Generator creates an initial draft from the concept/upstream document.

**Process:**
1. Read the stage guide to understand required structure and abstraction level
2. Read the concept/upstream document
3. Read validated deferred items (if any from Step 1)
4. Extract relevant information from concept
5. Incorporate validated gaps/issues from deferred items
6. Generate all required sections following the guide structure
7. Mark all gaps clearly with markers

**Gap markers:**
| Marker | When to Use |
|--------|-------------|
| `[QUESTION: ...]` | Information needed |
| `[DECISION NEEDED: ...]` | Choice required |
| `[ASSUMPTION: ...]` | Guess that needs validation |
| `[TODO: ...]` | Placeholder to fill |
| `[CLARIFY: ...]` | Source is ambiguous |

**Output:**
- Draft document with gaps marked
- Location: `system-design/[stage]/versions/round-0/00-draft-[document].md`

---

### Step 3: Report to Human

**Agent:** Orchestrator (performs this step directly)

The orchestrator summarises the draft for the human.

**Process:**
1. Read the draft and count gap markers
2. Present summary to human:
   ```
   [Stage] initialization complete.

   Draft: system-design/[stage]/versions/round-0/00-draft-[document].md

   Gap summary:
   - [N] QUESTION items
   - [M] DECISION NEEDED items
   - [K] Assumptions to validate

   Next steps:
   1. Review the draft and fill in answers to open questions
   2. Optionally ask Claude to tidy up the draft
   3. When ready, run the [Stage] Review workflow
   ```

---

### Human Augments the Draft

**Actor:** Human (not an agent)

The human reviews the draft and fills in answers to open questions directly in the document.

**Process:**
1. Open the draft document
2. Search for gap markers (`[QUESTION`, `[DECISION NEEDED`, etc.)
3. Replace markers with actual content
4. Add any additional content needed
5. Optionally ask Claude to help tidy up the draft

**Tips:**
- Be specific - "Enterprise companies" is less useful than "Mid-market SaaS (100-1000 employees)"
- State reasoning if helpful - it helps maintain context
- Flag uncertainty - if you're guessing, say so
- Don't worry about level - if you add detail that belongs downstream, Review will catch it

---

### Run Review Workflow

Once the draft is augmented, run the Review workflow to refine it. See `workflow-review.md`.

The Review workflow will:
- Run domain experts to identify issues
- Facilitate discussion on issues found
- Author approved changes
- Verify alignment with source documents
- Iterate until the document is satisfactory

---

## Component Specs: Two-Level Structure

Component Specs has a unique structure with stage-level and component-level workflows:

### Stage-Level: Initialize

**Run once** before creating any component specs.

**Purpose:**
- Generate cross-cutting spec from Architecture
- Create component folder structure
- Split monolithic deferred items into component-specific files
- Create workflow state file

**Orchestrator:** `agents/05-components/initialize/orchestrator.md`

### Component-Level: Create

**Run for each component** in priority order.

**Purpose:**
- Validate dependencies are complete
- Process component's deferred items
- Generate draft spec from Architecture + Foundations
- Report to human

**Orchestrator:** `agents/05-components/create/orchestrator.md`

### Component-Level: Review

**Run for each component** after human augments the draft.

**Orchestrator:** `agents/05-components/review/orchestrator.md`

---

## Output File Structure

```
system-design/[stage]/
├── versions/
│   ├── deferred-items.md           # Items deferred from upstream
│   ├── pending-issues.md          # Issues logged against this stage
│   └── round-0/
│       └── 00-draft-[document].md # Generator output
└── [document].md                  # Final (created by Review workflow)
```

---

## Tool Restrictions

All agents in the Create workflow:
- **Use:** Read, Write, Edit, Glob, Grep
- **Do NOT use:** Bash, WebFetch, WebSearch

This ensures agents operate only on files and don't execute arbitrary commands or fetch external content.

---

## Key Principles

- **Draft, not final**: Create produces a draft; Review refines it
- **Gaps, not issues**: Generator marks missing information for human to fill
- **File-first**: Pass paths, not content; agents read and write files
- **Human augments**: Human fills in gaps directly in the draft
- **Stage level**: Keep content at appropriate abstraction level
- **Defer, don't drop**: Wrong-level content goes to deferred items, never discarded

---

## After Creation

Once the draft is augmented:

1. **Run the Review workflow** to refine the document (see `workflow-review.md`)
2. Review workflow iterates until document is satisfactory
3. Final document is promoted to `system-design/[stage]/[document].md`
