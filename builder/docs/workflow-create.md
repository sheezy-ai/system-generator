# Create Workflow

The Create workflow generates a draft document from upstream inputs. Each stage declares which creation pattern it follows. The human exits the loop by choosing to promote, then runs the Review workflow to refine the promoted draft.

For the standard review workflow (used after creation), see `workflow-review.md`.

---

## Creation Patterns

Two patterns define how create workflows approach draft production, listed from lightest to heaviest pre-generation investment.

---

### Pattern: Select

```
Setup → Assess → [Human checkpoint] → Generate → Gap Resolution Pipeline → Promote
```

**When to use**: Technology and convention selection problems where options are bounded and the input (PRD) implies constraints but doesn't prescribe specific choices. Assessment surfaces trade-offs and collects human direction before generation.

**Stages using this pattern**: Foundations (03)

#### Characteristics

- **Pre-generation**: Assessor evaluates 2-3 options per category against upstream constraints, identifies coupled decisions, presents structured assessment with `>> HUMAN:` inline response placeholders
- **Human preferences**: Persisted in the assessment file via inline markers — survive workflow resume
- **Gap resolution**: Full pipeline (fewer gaps expected because assessment settles most decisions before generation)
- **Rounds**: Single round (assessment + generation, no multi-round loop)

#### Standard Steps

| Step | Name | Agent | Auto/Human |
|------|------|-------|------------|
| 1-3b | Setup, deferred items, brief check | Orchestrator | Auto |
| 3c | Assessment | Assessor | Auto → Human checkpoint |
| 4 | Generate | Generator (uses assessment) | Auto |
| 5 | Format gaps | Gap Formatter | Auto |
| 5 (cont) | Analyse gaps | Gap Analyst | Auto |
| 6 | Discussion | Discussion Facilitator | Human checkpoint |
| 7 | Apply decisions | Author | Auto |
| 8 | Promote | Orchestrator | Auto |

#### State File Template

```markdown
**Current Round**: 0
**Status**: IN_PROGRESS | WAITING_FOR_HUMAN | COMPLETE
**Gaps Exist**: unknown | true | false

## Progress

### Round 0 (Creation)
- [ ] Step 1-3b: Validate & Setup
- [ ] Step 3c: Run Assessor
- [ ] Step 4: Run Generator
- [ ] Step 5: Format & Analyse Gaps
- [ ] Step 6: Discussion Loop
- [ ] Step 7: Apply Decisions
- [ ] Step 8: Promote & Report
```

---

### Pattern: Explore

```
Setup → [Explore → Generate/Apply → Gap Resolution]* → Promote
```

**When to use**: Design problems where multiple viable alternatives need structured exploration before generation. The input needs decomposition into areas worth investigating, parallel deep-dives, and human review of proposed enrichments before the draft is produced.

**Stages using this pattern**: Blueprint (01), PRD (02), Architecture (04), Components (05)

#### Characteristics

- **Pre-generation**: Identify areas → parallel explorers → consolidate → scope filter → human enrichment review → summarize. This is the heaviest pre-generation investment.
- **Generation**: Round 1 uses Generator (from scratch). Round 2+ uses Enrichment Applicator (targeted edits to previous draft, not regeneration).
- **Gap resolution**: Varies by stage — Blueprint/PRD use lightweight resolution (human answers directly or edits draft), Architecture/Components use full gap pipeline
- **Rounds**: Multi-round with human exit choice at gap resolution
- **Area terminology**: Varies by stage — "dimensions" (Blueprint), "capabilities" (PRD), "concerns" (Architecture), "design concerns" (Components)

#### Standard Steps

| Step | Phase | Name | Agent | Auto/Human |
|------|-------|------|-------|------------|
| 1 | Explore | Setup | Orchestrator | Auto |
| 2 | Explore | Identify areas | Area Identifier | Auto |
| 3 | Explore | Review areas | — | Human checkpoint |
| 4 | Explore | Explore areas | Area Explorers (parallel) | Auto |
| 5 | Explore | Consolidate | Exploration Consolidator | Auto |
| 6 | Explore | Filter | Enrichment Scope Filter | Auto |
| 7 | Explore | Review enrichments | Discussion Facilitator | Human checkpoint |
| 8 | Explore | Summarize | Enrichment Author | Auto |
| 9 | Generate | Generate or apply enrichments | Generator (R1) / Applicator (R2+) | Auto |
| 9b | Generate | Coverage verification (if applicable) | Requirements Extractor + Coverage Checker | Auto |
| 9c | Generate | Depth verification (if applicable) | Depth Checker | Auto |
| 10 | Generate | Gap resolution | Varies by stage | Human checkpoint |
| 11 | Promote | Promote | Orchestrator | Auto |

#### Stage Variations

| Aspect | Blueprint | PRD | Architecture | Components |
|--------|-----------|-----|-------------|------------|
| Area term | Dimensions | Capabilities | Concerns | Design Concerns |
| Upstream input | Concept | Blueprint | PRD + Foundations | Architecture + Foundations |
| Decision system | Separate Decision Orchestrator | Inline | None | None |
| Gap resolution | Lightweight (human answers/edits) | Lightweight | Full pipeline | Full pipeline |
| Coverage verification | No | No | Yes (Step 9b) | Yes (Step 9b) |
| Depth verification | No | No | No | Yes (Step 9c) |
| Enrichment applicator | No (regenerates) | Yes (round 2+) | Yes (round 2+) | Yes (round 2+) |

#### State File Template

```markdown
**Current Workflow**: Create
**Current Phase**: Explore | Generate | Promote
**Current Round**: 1
**Status**: IN_PROGRESS | WAITING_FOR_HUMAN | COMPLETE
**Gaps Exist**: unknown | true | false
**Explore Phase**: active | skipped | complete

## Progress

### Phase 1: Explore
- [ ] Step 1: Setup
- [ ] Step 2: Area Identifier
- [ ] Step 3: Area Review
- [ ] Step 4: Area Explorers
- [ ] Step 5: Consolidator
- [ ] Step 6: Scope Filter
- [ ] Step 7: Enrichment Review
- [ ] Step 8: Enrichment Author

### Phase 2: Generate
- [ ] Step 9: Generate or Apply Enrichments
- [ ] Step 9b: Coverage Verification (if applicable)
- [ ] Step 9c: Depth Verification (if applicable)
- [ ] Step 10: Gap Resolution

### Phase 3: Promote
- [ ] Step 11: Promote & Report
```

---

## Choosing a Pattern

| Question | Select | Explore |
|----------|--------|---------|
| Are options bounded and well-known? | Yes | No |
| Do multiple viable design alternatives exist? | No | Yes |
| Does the input need decomposition into areas? | No | Yes |
| Is multi-round iteration valuable? | No | Yes |

If a new stage doesn't fit cleanly, prefer the lighter pattern and add specific steps as deviations rather than using a heavier pattern and skipping steps.

---

## Component Specs: Two-Level Structure

Component Specs is unique: it produces multiple specs (one per component) rather than a single document.

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
- Explore design concerns (parallel concern explorers, enrichment review)
- Generate draft spec from Architecture + Foundations + exploration enrichments
- Verify coverage and depth
- Resolve gaps through structured discussion
- Iterate (human can request additional explore→generate rounds)
- Promote final draft

**Pattern:** Explore

**Orchestrator:** `agents/05-components/create/orchestrator.md`

### Component-Level: Review

**Run for each component** after creation promotes the draft.

**Orchestrator:** `agents/05-components/review/orchestrator-router.md`

---

## Shared Components

Both patterns share these universal agents and conventions:

**Gap Resolution Pipeline** (used by Select; used by Explore stages with full gap resolution):
- Gap Formatter → Gap Analyst → Discussion Facilitator → Author
- Universal agents, stage-agnostic behaviour
- Orchestrator passes stage-specific context documents

**Coverage Verification** (used by Architecture and Components):
- Requirements Extractor + Coverage Checker
- Stage-specific agents (different upstream documents per stage)
- Gaps injected as `[TODO: Coverage gap — ...]` markers

**Depth Verification** (used by Components only):
- Depth Checker
- Verifies minimum specification depth (typed inputs/outputs, named error rules, index declarations, atomicity boundaries)
- Shallow items injected as `[TODO: Depth gap — ...]` markers

**Enrichment Review Loop** (used by Explore only):
- Area Identifier → Area Explorers → Consolidator → Scope Filter → Human Review → Enrichment Author
- Stage-specific agents (different area terminology and scope boundaries)

**Author Features** (both patterns):
- Level check with stage-appropriate examples
- Design rationale documentation (inline + decisions section)
- Maturity calibration
- Copy-then-Edit approach

---

## Gap Markers

Generators and checkers mark gaps with these inline markers:

| Marker | When to Use |
|--------|-------------|
| `[QUESTION: ...]` | Information needed |
| `[DECISION NEEDED: ...]` | Choice required |
| `[ASSUMPTION: ...]` | Guess that needs validation |
| `[TODO: ...]` | Placeholder to fill |
| `[CLARIFY: ...]` | Source is ambiguous |

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
- **Stage level**: Keep content at appropriate abstraction level
- **Defer, don't drop**: Wrong-level content goes to deferred items, never discarded

---

## After Creation

Once the draft is promoted:

1. **Run the Review workflow** to refine the document (see `workflow-review.md`)
2. Review workflow iterates until document is satisfactory
3. Final document is promoted to `system-design/[stage]/[document].md`
