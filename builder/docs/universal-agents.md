# Universal Agents

Universal agents work across multiple stages and workflows. They provide consistent behavior regardless of which stage invokes them.

---

## In Standard Workflows

These agents are part of the standard Create and Review workflows:

### Alignment Verifier

**Purpose:** Verifies a document aligns with its source documents after changes are applied.

**Used in:** Review workflow (stages 02-05)

**Trigger:** Automatic - runs after Author completes

**Design decisions:** DEC-035, DEC-045

**Prompt:** `agents/universal-agents/alignment-verifier.md`

---

### Scope Filter

**Purpose:** Filters content to ensure it's at the appropriate level of abstraction. Content that belongs downstream gets deferred; appropriate content passes through.

**Used in:** Create and Review workflows (all stages)

**Trigger:** Automatic - runs after Consolidator

**Design decisions:** DEC-022, DEC-026, DEC-027

**Prompt:** `agents/universal-agents/scope-filter.md`

---

### Discussion Facilitator

**Purpose:** Facilitates iterative back-and-forth discussions with the human to resolve open issues. Discussions happen inline in the issues-discussion file.

**Used in:** Create and Review workflows (all stages)

**Trigger:** Manual - invoked when issues need a response (after human responds with `>> HUMAN:`)

**How it works:**
- Reads context documents first (the document being reviewed + upstream documents)
- Handles multiple issues per invocation (batched for efficiency)
- One response per issue per invocation (iterative back-and-forth)
- Uses `>> HUMAN:`, `>> AGENT:`, `>> RESOLVED` markers
- Proposes solutions with `**Proposed [Document] change**:` blocks
- Human confirms resolution naturally; orchestrator adds `>> RESOLVED` marker

**Invocation pattern:**
```
Context documents:
- [Document being reviewed]: [path]
- [Upstream document(s)]: [path(s)]

Issues file: [path to issues-discussion.md]
Issues: [ID1, ID2, ID3, ...]
```

**Prompt:** `agents/universal-agents/discussion-facilitator.md`

---

### Issue Analyst

**Purpose:** Proactive analysis of consolidated issues before human review. Provides options, trade-offs, and recommendations so the human has a head start on each issue.

**Used in:** Review workflow (stages 03-05, after issue filtering, before human discussion)

**Trigger:** Automatic - runs after Scope Filter (03/04) or Issue Router (05), before presenting issues to human

**How it works:**
- Reads consolidated issues and the spec under review
- For each issue, analyses options with pros/cons
- Writes inline `>> AGENT:` blocks in the issues-discussion file
- Provides recommendations, not prescriptive answers

**Prompt:** `agents/universal-agents/issue-analyst.md`

---

### Pending Issue Resolver

**Purpose:** Executes human-decided resolutions to pending issues logged during alignment verification. Applies changes to upstream documents (Architecture, Foundations) or component specs.

**Used in:** Review workflow (05-components extended workflow, Step 11)

**Trigger:** Automatic - runs when human approves pending issue sync

**How it works:**
- Reads pending issues with human decisions (APPLY/DEFER/REJECT)
- For APPLY decisions, applies surgical edits to the target document
- Produces a sync report documenting all changes
- Updates pending-issues.md to mark resolved items

**Prompt:** `agents/universal-agents/pending-issue-resolver.md`

---

## Specialist Agents

These agents are not part of standard workflows. Invoke them manually when needed.

### Technical Writer Session

**Purpose:** Interactive session for reviewing and improving document clarity. Reviews for readability and communication quality, discusses findings with human, applies agreed changes, and updates workflow state. Does not check technical correctness - that's handled by domain experts.

**When to use:** After all review rounds are complete, before promoting final version.

**Applicable stages:** All stages (01-05)

**Design decisions:** DEC-009

**Prompt:** `agents/specialist-agents/technical-writer.md`

**Trigger:**
```
Read the Technical Writer Session prompt at:
agents/specialist-agents/technical-writer.md

Then start a Technical Writer Session with:
- Document: [path to document]
- Workflow state: [path to workflow-state.md]
- Output folder: [path to versions/round-N-technical-writer/]
```

**Session flow:**
1. Updates workflow state (new round started)
2. Reviews document for clarity issues
3. Discusses findings with human
4. Applies agreed changes
5. Asks: another pass or done?
6. Updates workflow state (round complete)

---

## Why Universal?

These agents are universal because their logic is stage-agnostic:

- **Alignment Verifier** - Same verification process, different source documents per stage
- **Scope Filter** - Same filtering logic, reads stage guide for abstraction level
- **Discussion Facilitator** - Same inline discussion mechanics across all stages
- **Issue Analyst** - Same analytical approach, provides options/recommendations for any domain
- **Pending Issue Resolver** - Same sync mechanics, resolves upstream issues regardless of stage
- **Gap Formatter** - Same gap extraction mechanics across all stages

Stage-specific agents (experts, consolidators) require domain knowledge. Universal agents provide consistent cross-cutting functionality.
