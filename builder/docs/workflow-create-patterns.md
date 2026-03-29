# Create Workflow Patterns

Three pre-generation intensity levels define how create workflows approach draft production. Each stage declares which pattern it follows. The patterns are listed from lightest to heaviest pre-generation investment.

For the standard review workflow (used after creation), see `workflow-review.md`.

---

## Pattern: Direct

```
Setup → Generate → Coverage Verify → Gap Resolution Pipeline → Promote
```

**When to use**: Implementation-level documents derived from explicit upstream requirements. The upstream documents enumerate specific items this stage must address — no exploration or assessment needed before generation.

**Stages using this pattern**: Components (05)

### Characteristics

- **Pre-generation**: None — upstream documents (Architecture, cross-cutting spec) are specific enough for direct generation
- **Post-generation**: Independent coverage verification catches silent omissions the Generator's self-review misses
- **Gap resolution**: Full pipeline (Gap Formatter → Gap Analyst → Discussion Facilitator → Author)
- **Rounds**: Single round (no multi-round loop)

### Standard Steps

| Step | Name | Agent | Auto/Human |
|------|------|-------|------------|
| 1-2b | Setup & deferred items intake | Orchestrator | Auto |
| 3 | Generate | Generator | Auto |
| 3b | Coverage verification | Requirements Extractor + Coverage Checker | Auto |
| 4 | Format gaps | Gap Formatter | Auto |
| 4 (cont) | Analyse gaps | Gap Analyst | Auto |
| 5 | Discussion | Discussion Facilitator | Human checkpoint |
| 6 | Apply decisions | Author | Auto |
| 7 | Promote | Orchestrator | Auto |

### State File Template

```markdown
**Current Round**: 0
**Status**: IN_PROGRESS | WAITING_FOR_HUMAN | COMPLETE
**Gaps Exist**: unknown | true | false

## Progress

### Round 0 (Creation)
- [ ] Step 1-2b: Validate & Setup
- [ ] Step 3: Run Generator
- [ ] Step 3b: Coverage Verification
- [ ] Step 4: Format & Analyse Gaps
- [ ] Step 5: Discussion Loop
- [ ] Step 6: Apply Decisions
- [ ] Step 7: Promote & Report
```

---

## Pattern: Select

```
Setup → Assess → [Human checkpoint] → Generate → Gap Resolution Pipeline → Promote
```

**When to use**: Technology and convention selection problems where options are bounded and the input (PRD) implies constraints but doesn't prescribe specific choices. Assessment surfaces trade-offs and collects human direction before generation.

**Stages using this pattern**: Foundations (03)

### Characteristics

- **Pre-generation**: Assessor evaluates 2-3 options per category against upstream constraints, identifies coupled decisions, presents structured assessment with `>> HUMAN:` inline response placeholders
- **Human preferences**: Persisted in the assessment file via inline markers — survive workflow resume
- **Gap resolution**: Full pipeline (fewer gaps expected because assessment settles most decisions before generation)
- **Rounds**: Single round (assessment + generation, no multi-round loop)

### Standard Steps

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

### State File Template

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

## Pattern: Explore

```
Setup → [Explore → Generate/Apply → Gap Resolution]* → Promote
```

**When to use**: Design problems where multiple viable alternatives need structured exploration before generation. The input needs decomposition into areas worth investigating, parallel deep-dives, and human review of proposed enrichments before the draft is produced.

**Stages using this pattern**: Blueprint (01), PRD (02), Architecture (04)

### Characteristics

- **Pre-generation**: Identify areas → parallel explorers → consolidate → scope filter → human enrichment review → summarize. This is the heaviest pre-generation investment.
- **Generation**: Round 1 uses Generator (from scratch). Round 2+ uses Enrichment Applicator (targeted edits to previous draft, not regeneration).
- **Gap resolution**: Varies by stage — Blueprint/PRD use lightweight resolution (human answers directly or edits draft), Architecture uses full gap pipeline
- **Rounds**: Multi-round with human exit choice at gap resolution
- **Area terminology**: Varies by stage — "dimensions" (Blueprint), "capabilities" (PRD), "concerns" (Architecture)

### Standard Steps

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
| 10 | Generate | Gap resolution | Varies by stage | Human checkpoint |
| 11 | Promote | Promote | Orchestrator | Auto |

### Stage Variations

| Aspect | Blueprint | PRD | Architecture |
|--------|-----------|-----|-------------|
| Area term | Dimensions | Capabilities | Concerns |
| Upstream input | Concept | Blueprint | PRD + Foundations |
| Decision system | Separate Decision Orchestrator | Inline | None |
| Gap resolution | Lightweight (human answers/edits) | Lightweight | Full pipeline |
| Coverage verification | No | No | Yes (Step 9b) |
| Enrichment applicator | No (regenerates) | Yes (round 2+) | Yes (round 2+) |

### State File Template

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
- [ ] Step 10: Gap Resolution

### Phase 3: Promote
- [ ] Step 11: Promote & Report
```

---

## Choosing a Pattern

| Question | Direct | Select | Explore |
|----------|--------|--------|---------|
| Does upstream enumerate specific items to implement? | Yes | No | No |
| Are options bounded and well-known? | N/A | Yes | No |
| Do multiple viable structural alternatives exist? | No | No | Yes |
| Does the input need decomposition into areas? | No | No | Yes |
| Is multi-round iteration valuable? | No | No | Yes |

If a new stage doesn't fit cleanly, prefer the lighter pattern and add specific steps as deviations rather than using a heavier pattern and skipping steps.

---

## Shared Components

All three patterns share these universal agents and conventions:

**Gap Resolution Pipeline** (used by Select and Direct; optionally by Explore):
- Gap Formatter → Gap Analyst → Discussion Facilitator → Author
- Universal agents, stage-agnostic behaviour
- Orchestrator passes stage-specific context documents

**Coverage Verification** (used by Direct; optionally by Explore):
- Requirements Extractor + Coverage Checker
- Stage-specific agents (different upstream documents per stage)
- Gaps injected as `[TODO: Coverage gap — ...]` markers

**Enrichment Review Loop** (used by Explore only):
- Area Identifier → Area Explorers → Consolidator → Scope Filter → Human Review → Enrichment Author
- Stage-specific agents (different area terminology and scope boundaries)

**Author Features** (all patterns):
- Level check with stage-appropriate examples
- Design rationale documentation (inline + decisions section)
- Maturity calibration
- Copy-then-Edit approach
