# Review Workflow

The Review workflow refines an existing document through iterative cycles of expert analysis, solution proposal, and human-approved changes. This document covers the standard 7-step workflow used by stages 01-04.

**Note:** Stage 05 (Component Specs) uses an extended 12-step variant with build/ops phase splitting, issue routing, contract verification, pending issue sync, and spec promotion. See `05-components.md` for details.

For a high-level overview, see `overview.md`.

---

## Flow Diagram

```
    ┌─────────────────────────────────────────────────────────────────────────┐
    │                                                                         │
    │         ┌─────────────────┐                                             │
    │         │    Document     │                                             │
    │         └────────┬────────┘                                             │
    │                  │                                                      │
    │  ┌───────────────┼───────────────┬───────────────┐                      │
    │  ▼               ▼               ▼               ▼                      │
    │ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐                         │
    │ │ Expert  │ │ Expert  │ │ Expert  │ │ Expert  │                         │
    │ │    1    │ │    2    │ │    3    │ │    4    │                         │
    │ └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘                         │
    │      │           │           │           │                              │
    │      └───────────┴─────┬─────┴───────────┘                              │
    │                        │                                                │
    │                        ▼                                                │
    │               ┌─────────────────┐                                       │
    │               │   Consolidator  │                                       │
    │               └────────┬────────┘                                       │
    │                        │                                                │
    │                        ▼                                                │
    │               ┌─────────────────┐                                       │
    │               │  Scope Filter   │                                       │
    │               └────────┬────────┘                                       │
    │                        │                                                │
    │                        ▼                                                │
    │               ┌─────────────────┐                                       │
    │               │ Issue Analyst   │                                       │
    │               │ (pre-analysis)  │                                       │
    │               └────────┬────────┘                                       │
    │                        │                                                │
    │                        ▼                                                │
    │               ┌─────────────────┐                                       │
    │               │  Human Review   │◄───────────── Stop point 1            │
    │               │ (mark issues)   │                                       │
    │               └────────┬────────┘                                       │
    │                        │                                                │
    │                        ▼                                                │
    │               ┌─────────────────┐                                       │
    │               │ Issue Resolution│◄───────────── Stop point 2            │
    │               │(inline discuss) │               (iterative)             │
    │               └────────┬────────┘                                       │
    │                        │                                                │
    │                        ▼                                                │
    │               ┌─────────────────┐                                       │
    │               │     Author      │                                       │
    │               └────────┬────────┘                                       │
    │                        │                                                │
    │                        ▼                                                │
    │               ┌─────────────────┐                                       │
    │               │ Align. Verifier │                                       │
    │               └────────┬────────┘                                       │
    │                        │                                                │
    │             ┌──────────┴──────────┐                                     │
    │             ▼                     ▼                                     │
    │          PROCEED                HALT ◄───────── Stop point 3 (if HALT)  │
    │             │                     │                                     │
    │             ▼                     ▼                                     │
    │               ┌─────────────────┐                                       │
    │               │ Change Verifier │  Log upstream issue                   │
    │               └────────┬────────┘                                       │
    │                        │                                                │
    │             ┌──────────┴──────────┐                                     │
    │             ▼                     ▼                                     │
    │      All resolved           Issues remain                               │
    │             │                     │                                     │
    │             ▼                     │                                     │
    │    ┌─────────────────┐            │                                     │
    │    │  Human decides  │◄───────────┼───────────── Stop point 4           │
    │    │ (next round?)   │            │                                     │
    │    └────────┬────────┘            │                                     │
    │             │                     │                                     │
    │        EXIT │                     │                                     │
    │             ▼                     │                                     │
    │      Updated Document ◀───────────┘                                     │
    │             │                                                           │
    │             └───────────────────────────────────────────────────────────┘
                  (next round if needed)
```

---

## Step-by-Step Walkthrough

### Step 1: Expert Issue Identification (Parallel)

**Agents:** Domain-specific Experts (run in parallel)

Each expert reviews the document within their domain and identifies issues.

**Process:**
1. Read the document to review
2. Identify issues within assigned domain
3. Include clarifying questions where needed
4. Write output file

**Key difference from Create workflow:** Experts identify *issues* (problems with existing content), not *gaps* (missing information).

**Expert principles:**
- **Clarify Before Assuming**: If something is ambiguous, note it as a clarifying question
- **Raise What's Missing**: Flag concerns proactively, including future-phase risks
- **Be Direct**: State clearly why something is a problem
- **Be Specific**: Every issue must specify what's weak/missing/wrong, exactly where, and what could go wrong
- **Calibrate Severity Honestly**: Reserve HIGH for genuine blockers
- **Stay in Lane**: Focus only on assigned domain
- **Respect Stage Level**: Don't flag missing implementation details
- **Flag Over-Specification**: If document contains detail that belongs downstream, flag it

**Issue structure:**
```markdown
## [CODE]-001: [One-line summary]

**Severity**: HIGH | MEDIUM | LOW
**Risk Type**: Immediate | Future Phase | Theoretical
**Category**: [Category from expert's domain]
**Section**: [Document section reference]

### Issue

[Detailed description: what's weak/missing/wrong, exactly where, what could go wrong]

[Why this is a problem from this expert's perspective]

### Clarifying Questions

[Questions that would materially affect how this issue should be addressed. If none, write "None".]
```

**Severity definitions:**
- **HIGH**: Fundamental flaw that undermines viability
- **MEDIUM**: Significant gap that should be addressed
- **LOW**: Would strengthen but not critical

**Risk Type definitions:**
- **Immediate**: Affects Phase 1 / MVP viability
- **Future Phase**: Will become a problem in Phase 2+
- **Theoretical**: Could be a problem under certain conditions

**Constraints:**
- Maximum 12 issues per expert (see DEC-010)
- No solutions—issues and questions only
- Each expert has a code prefix (e.g., STRAT, COMM, CUST, OPS)

**Output location:** `system/[stage]/versions/round-N-review/01-[expert-name].md`

---

### Step 2: Consolidate Issues

**Agent:** Consolidator

The Consolidator merges all expert outputs into a single document.

**Process:**
1. Read all expert issue files
2. Group issues by theme (themes are stage-specific, hardcoded)
3. Handle duplicates (same issue from multiple experts)
4. Assign consolidated IDs (BLU-001, BLU-002, etc.)
5. Note original expert sources
6. Create clarifying questions summary
7. Write consolidated output

**Grouping example (Blueprint):**
- Vision & Problem
- Users & Value
- Business Model
- Market & Positioning
- Strategy & Phasing
- Risks & Assumptions
- Principles & Constraints
- Coherence

**Handling duplicates:**
- Group together, note all sources
- Use most detailed description
- Note "independently identified by multiple experts"

**Clarifying questions summary:**
The output includes a summary table at the top listing all questions that need answers before solutions can be proposed.

**Does NOT:**
- Filter issues (Scope Filter does this)
- Propose solutions
- Modify issue descriptions

**Output location:** `system/[stage]/versions/round-N-review/02-consolidated-issues.md`

---

### Step 3: Filter Issues (Scope Filter)

**Agent:** Scope Filter (universal)

The Scope Filter filters content to ensure only stage-appropriate issues proceed.

**Process:**
1. Read the stage guide
2. Read consolidated issues
3. For each issue, determine: keep or defer?
4. Write filtered output
5. Append deferred items to downstream deferred items files

**Filtering logic:**
- **Keep**: Issues appropriate for this stage
- **Defer**: Issues that belong in a downstream stage
- **When uncertain**: Keep (human can mark N/A)

**Output location:** `system/[stage]/versions/round-N-review/03-issues-discussion.md`

---

### Step 3b: Issue Analysis

**Agent:** Issue Analyst (universal)

The Issue Analyst pre-analyzes each issue with options, trade-offs, and a recommendation before the human sees it. This gives the human everything they need to make a decision without follow-up questions.

**Process:**
1. Read the document being reviewed and any upstream documents
2. Read the filtered issues file
3. For each assigned issue: assess validity, analyze options, provide recommendation
4. Edit the issues file inline, adding `>> AGENT:` analysis blocks

**Analysis structure:**
- **Full analysis** (default): Options with pros/cons/risks, clear recommendation
- **Challenge** (if issue is invalid): Explain why, recommend closing
- **Question** (if human context needed): Ask specific question that would unlock the analysis

**Depth-flagged content:** When an issue concerns content flagged as potentially exceeding the document's abstraction level, the analyst defaults to recommending deferral to the appropriate downstream stage unless genuinely unsure, in which case they delegate the depth call to the human.

**Batching:** Issues are grouped by document section (~5-7 per batch) and analyst agents run in parallel, one per batch.

**Output:** Inline edits to `system/[stage]/versions/round-N-review/03-issues-discussion.md`

---

### Step 4: Human Response

**Stop point:** Workflow pauses here for human to mark each issue.

**What human sees:**
- File path to review: `system/[stage]/versions/round-N-review/03-issues-discussion.md`
- Issues sorted by severity (HIGH → MEDIUM → LOW)
- Each issue with ID, severity, summary, and core question

**Response format:**
For each issue, human marks the status:

```markdown
### BLU-001: Vision statement too vague

**Severity**: HIGH | **Section**: Vision

**Summary**: The vision lacks specificity about target market...

**Question**: What specific market segment are we targeting?

>> HUMAN: Good point - we should clarify this. We're targeting mid-market B2B.
```

**Discussion flow:**

Human responds naturally to each issue — no special keywords needed. The agent infers intent:
- If human agrees issue is valid → agent proposes solution
- If human wants to explore → agent clarifies first
- If human disagrees it's an issue → agent acknowledges and marks resolved (no change)

Discussion continues with `>> HUMAN:` / `>> AGENT:` turns until `>> RESOLVED`.

**Inline discussion example:**
```markdown
>> HUMAN: Good point - we should clarify this. We're targeting mid-market B2B.

>> AGENT: I propose resolving this as follows:

**Proposed [Document] change**:
> Update Vision section to specify "mid-size B2B companies (50-500 employees) in the tech sector"

**Rationale**: This makes the target market specific and measurable.

If this looks right, confirm and we can mark this resolved.

>> HUMAN: Yes, that works.

>> RESOLVED
```

**Discussion markers:**
| Marker | Used By | Purpose |
|--------|---------|---------|
| `>> HUMAN:` | Human | All human input (natural response, no keywords needed) |
| `>> AGENT:` | Facilitator | Responses and proposals |
| `>> RESOLVED` | Orchestrator | Added after human confirms resolution |

**When all discussions resolved:** Proceed to Step 5

---

### Step 5: Apply Changes (Author)

**Agent:** Author

The Author applies approved solutions to the document.

**Process:**
1. Read the document
2. Read issues-discussion file (`03-issues-discussion.md`)
3. Find resolved discussions—look for `>> RESOLVED` markers
4. Skip unresolved discussions
5. For each resolved discussion: apply the proposed change faithfully
6. Write change log
7. Write updated document

**Resolution handling:**
| Status | Action |
|--------|--------|
| `>> RESOLVED` or confirmed ("Agreed", "Yes, do it") | Apply proposed change from the discussion |
| No resolution marker | Skip (still in discussion) |
| Human disagreed it's an issue | Skip (no change needed) |

**Ambiguity handling:**
If a solution is unclear or conflicts with existing content, flag it instead of guessing:
```markdown
### Change N: BLU-007 - [Issue Summary]

- **Action**: FLAGGED
- **Section**: [Where it would be applied]
- **Issue**: [What's ambiguous]
- **Options**:
  - Option A: [Interpretation 1]
  - Option B: [Interpretation 2]
- **Needs**: Human clarification before applying
```

**Level check:**
While applying changes, verify each stays at appropriate level. If an approved solution would add too much detail, flag it for human confirmation.

**Output locations:**
- Change log: `system/[stage]/versions/round-N-review/04-author-output.md`
- Updated document: `system/[stage]/versions/round-N-review/05-updated-[document].md`

---

### Step 6: Alignment Verification

**Agent:** Alignment Verifier (`agents/universal-agents/alignment-verifier.md`)

The Alignment Verifier ensures the updated document still aligns with its source documents after changes were applied.

**Process:**
1. Read the updated document
2. Read source documents (stage-specific: Blueprint for PRD, PRD for Foundations, etc.)
3. Identify any discrepancies between document and sources
4. Classify each discrepancy (FIX_NEW, PENDING_ISSUE, INTENTIONAL, NOT_A_CONFLICT)
5. Assess severity of pending issues
6. Output recommendation (PROCEED or HALT)
7. Write alignment report

**Discrepancy classifications:**
| Classification | Meaning | Action |
|----------------|---------|--------|
| FIX_NEW | This document is wrong | Return to Author to fix |
| PENDING_ISSUE | Source document is wrong | Log to upstream pending-issues.md |
| INTENTIONAL | Deliberate divergence | Document reasoning |
| NOT_A_CONFLICT | Appears to conflict but doesn't | Document explanation |

**Pending issue severity:**
| Severity | Workflow Impact |
|----------|-----------------|
| SHOWSTOPPER | HALT - cannot proceed until source fixed |
| HIGH | PROCEED with warning |
| MEDIUM/LOW | PROCEED |

**Routing:**
| Recommendation | Action |
|----------------|--------|
| PROCEED | Continue to Step 7 (Change Verification) |
| HALT | Stop workflow, log to upstream pending-issues.md, set BLOCKED_UPSTREAM_ISSUE |

**Output location:** `system/[stage]/versions/round-N-review/06-alignment-report.md`

**Note:** Blueprint skips this step — its source (concept document) is informal, so alignment verification is not applicable (see DEC-035). Blueprint goes directly from Author (Step 5) to Change Verification (Step 7), and uses `06-change-verification-report.md` for the verifier output.

---

### Step 7: Verify Changes

**Agent:** Change Verifier

The Change Verifier confirms changes were applied correctly and at appropriate level.

**Process:**
1. Read issues-summary file (to know what was resolved)
2. Read author output (to see what was done)
3. Read updated document (to verify application)
4. For each resolved issue: verify
5. Write verification report

**Verification per issue:**
1. Was the solution applied?
2. Was it applied correctly?
3. Does it address the root concern?
4. Does it stay at appropriate level?
5. Is it consistent with rest of document?

**Status definitions:**
| Status | Meaning |
|--------|---------|
| RESOLVED | Solution applied correctly, addresses issue, appropriate level |
| PARTIALLY_RESOLVED | Applied but doesn't fully address issue |
| NOT_RESOLVED | Not applied, or doesn't address issue |
| LEVEL_VIOLATION | Applied but introduced inappropriate detail |

**Level check criteria:**
| Appropriate (PASS) | Too Detailed (LEVEL_VIOLATION) |
|-------------------|-------------------------------|
| High-level capability descriptions | Feature lists or user stories |
| Business model type | Pricing tiers or specific amounts |
| Phase goals | Stage definitions with exit criteria |
| User segment descriptions | Personas with detailed attributes |
| Principle statements | Implementation rules |
| "Pre-validation is a design research phase" | "Seven specific learning objectives with assessment framework" |
| "Completeness and accuracy are different problems" | "90%+ target, below 70% unacceptable, diagnostic logic" |

**Routing based on results:**
| Result | Action |
|--------|--------|
| All RESOLVED | Proceed to next round (or exit) |
| Some NOT_RESOLVED | Return to Author with feedback |
| Some PARTIALLY_RESOLVED | Human decides: accept or rework |
| Some LEVEL_VIOLATION | Return to Author to simplify |

**Output location:** `system/[stage]/versions/round-N-review/07-change-verification-report.md`

**Human decision:**
After verification completes, human decides:
- **Next round**: Increment round number, go back to Step 1
- **Exit**: Mark workflow complete

**Exit criteria (guidance):**
1. No HIGH severity issues remaining
2. Consecutive rounds with no new significant issues
3. Maximum iterations reached (suggest 3 rounds)
4. Human judgment ("good enough")

**Promoting the document:**
After final round, manually copy the updated document to the stage's main location to promote it. The original is preserved in versions until explicitly overwritten.

---

## Output File Structure

```
system/[stage]/versions/round-N-review/
├── 00-[document].md            # Snapshot of input (copied at round start)
├── 01-[expert-1].md            # Expert outputs
├── 01-[expert-2].md
├── ...
├── 02-consolidated-issues.md   # Consolidator output (full detail)
├── 03-issues-discussion.md     # Scope Filter output + Issue Analyst analysis + inline discussions
├── 04-author-output.md         # Author change log
├── 05-updated-[document].md    # Updated document
├── 06-alignment-report.md      # Alignment Verifier output
└── 07-change-verification-report.md  # Change Verifier output
```

**Blueprint exception:** Blueprint skips Alignment Verification (Step 6), so uses `06-change-verification-report.md` instead. Output is under `versions/round-N-review/`.

---

## State Management

State file: `system/[stage]/versions/workflow-state.md`

```markdown
# [Stage] Review Workflow State

**Document**: [document path]
**Current Round**: 1
**Current Step**: 5
**Step Name**: Issue Resolution
**Status**: IN_PROGRESS | WAITING_FOR_HUMAN | BLOCKED_UPSTREAM_ISSUE | COMPLETE

## Progress

### Round 1
- [x] Step 1: Expert Review
- [x] Step 2: Consolidation
- [x] Step 3: Scope Filter
- [ ] Step 3b: Issue Analysis
- [ ] Step 4: Discussion
- [ ] Step 5: Apply Changes
- [ ] Step 6: Alignment Verification
- [ ] Step 7: Change Verification

## History
- YYYY-MM-DD HH:MM: Round 1 started
- YYYY-MM-DD HH:MM: 28 issues identified
```

State updates at each step transition. Workflow can be resumed from any step.

---

## Automatic vs Manual Steps

| Steps | Behaviour |
|-------|-----------|
| 1 → 2 → 3 → 3b | Automatic (no human stops) |
| Step 4 | **Stop**: Human participates in discussions until all resolved |
| After 6 (if HALT) | **Stop**: Upstream blocker found, human confirms |
| After 7 | **Stop**: Human decides next round or exit |

---

## Iteration

Review cycles repeat until exit criteria are met:

```
Round 1 → Round 2 → Round 3 → ... → Exit
```

Each round:
- Uses output from previous round as input
- Accumulates deferred items
- Builds on previous improvements

**Round input:**
- Round 1: Original document
- Round 2+: `system/[stage]/versions/round-{N-1}-review/05-updated-[document].md`

---

## Deferred Items Handling

Across rounds, deferred items accumulate at `system/[stage]/versions/deferred-items.md`.

After review is complete:
1. Review accumulated deferred items
2. Items tagged for downstream stages become input to those stages
3. The deferred items are valuable pre-work for downstream documents

---

## Tool Restrictions

All agents in the Review workflow:
- **Use:** Read, Write, Edit, Glob, Grep
- **Do NOT use:** Bash, WebFetch, WebSearch

---

## Key Principles

- **Issues, not gaps**: Experts identify problems with existing content
- **Inline discussions**: Issues are discussed and resolved inline in the issues-summary file
- **Human decisions**: All issues require human response (natural language, no keywords)
- **File-first**: Pass paths, not content
- **Stage level**: Keep content at appropriate abstraction level
- **Iterative refinement**: Multiple rounds until satisfactory
- **Defer, don't drop**: Wrong-level content goes to deferred items

---

## Guide Usage

Agents use guides differently depending on their role:

| Agent | Stage Guide | Maturity Guide |
|-------|-------------|----------------|
| Experts | No (guidance is in prompt) | Reads directly (except Blueprint) |
| Author | Reads directly (for structure) | N/A |
| Scope Filter | Reads directly (for filtering) | N/A |

**Why this design:**
- **Experts** have domain-specific abstraction guidance built into their prompts - they don't need the full stage guide
- **Experts** read maturity guides directly to calibrate severity (e.g., don't flag enterprise concerns for MVP)
- **Author** needs the full stage guide to ensure applied changes stay at appropriate level
- **Scope Filter** reads the stage guide to determine what belongs at this level vs downstream

See `guides/README.md` for more detail on guide files.
