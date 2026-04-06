# Blueprint Stage

The Blueprint is the foundational strategic document for a product or platform. It answers **why** we're building this, **who** it's for, and **what** we need to build first to validate the opportunity.

For general workflow mechanics, see `workflow-create.md` and `workflow-review.md`.

---

## What a Blueprint Contains

1. **Vision and Problem Statement** - What problem, why it matters, who experiences it
2. **Target Users** - Primary and secondary user segments
3. **Value Proposition** - What value we provide, why us over alternatives
4. **Business Model** - How this becomes sustainable, revenue streams
5. **Core Principles and Constraints** - What guides us, what we won't do
6. **Market Context** - Landscape, competitors, positioning
7. **MVP Definition** - Minimum viable scope, what's in/out
8. **Success Criteria** - How we know if MVP succeeded
9. **Key Risks and Assumptions** - Biggest risks, critical assumptions
10. **Why Now** - Why this is the right time

Optional: **Future Vision** - Post-MVP direction (kept separate from MVP scope)

See `guides/01-blueprint-guide.md` for full detail on each section.

---

## What Does NOT Belong in a Blueprint

| Out of Scope | Where It Belongs |
|--------------|------------------|
| Feature lists | PRD |
| Technical architecture | Foundations / Specs |
| Data models | PRD / Specs |
| Implementation approach | Specs |
| Timelines and deadlines | Project planning |
| Detailed financial projections | Business plan |
| Specific technology choices | Foundations |
| User stories or acceptance criteria | Tasks |
| API contracts, schemas | Specs |

**The test:** If content constrains *how* something is built rather than *what* or *why*, it probably doesn't belong in the Blueprint.

---

## Expert Panel

Blueprint uses four domain experts for the Review workflow:

| Expert | Code | Domain Focus |
|--------|------|--------------|
| **Strategist** | STRAT | Vision, positioning, strategic coherence, phasing, "why now" |
| **Commercial** | COMM | Business model, revenue, unit economics, pricing, sustainability |
| **Customer Advocate** | CUST | User needs, value proposition, user experience, adoption barriers |
| **Operator** | OPS | Feasibility, dependencies, risks, operational complexity, over-specification (operational/procedural detail) |

---

## Consolidation Themes

The Consolidator groups issues by these Blueprint-specific themes:

- Vision & Problem
- Users & Value
- Business Model
- Market & Positioning
- Strategy & Phasing
- Risks & Assumptions
- Principles & Constraints
- Coherence

---

## Create Workflow

Blueprint has a custom create workflow, unlike the generic Setup → Generate → Report pattern used by stages 02-05 (see `workflow-create.md`).

**Flow:** Setup → [Explore → Generate → Gap Resolution]* → Extract (promote + scope brief)

The explore→generate cycle iterates for as many rounds as the human wants:
- **Round 1** explores from `concept.md`
- **Round 2+** explores from the previous round's draft
- The human exits the loop by choosing to promote at Gap Resolution

### Explore Phase (Steps 1-8)

Identifies strategic dimensions of the concept, spawns parallel explorers for each dimension, consolidates enrichment proposals, filters by scope and depth, and facilitates human review. Enrichments marked as simple are accepted into the Blueprint; meaty strategic choices are routed to the Decision Orchestrator. The Enrichment Scope Filter applies three-tier depth handling: clear depth violations are auto-deferred to downstream, borderline cases are flagged for informed human review, and appropriate content passes through.

### Generate Phase (Steps 9-10)

Generates a draft Blueprint from the primary source + accepted enrichments + any resolved decisions. Pending decisions are marked as gap markers. The human then reviews gaps and chooses to promote, answer gaps, or do another round.

### Extract Phase (Steps 11-12)

Promotes the final draft to `blueprint.md` and extracts `scope-brief.md` for downstream stages.

### Decision Orchestrator (separate workflow)

Strategic decisions identified during enrichment review are handled by a separate Decision Orchestrator — not inline in the create workflow. Each decision gets its own framework (evaluation criteria, approved by human) and analysis (options evaluated against criteria, human approves final decision). The Blueprint proceeds with pending decisions marked as gaps; resolved decisions are incorporated as settled content.

---

## File Paths

**Stage guide:** `guides/01-blueprint-guide.md`

**Agent prompts:**
```
agents/01-blueprint/
├── create/
│   ├── orchestrator.md              # Coordinates explore→generate loop
│   ├── dimension-identifier.md      # Identifies strategic dimensions
│   ├── dimension-explorer.md        # Explores one dimension deeply
│   ├── exploration-consolidator.md  # Merges explorer outputs
│   ├── enrichment-scope-filter.md   # Filters enrichments by level/depth (three-tier)
│   ├── enrichment-author.md         # Produces exploration summary
│   ├── decision-orchestrator.md     # Handles one decision (separate workflow)
│   ├── decision-framework.md        # Defines decision criteria with human
│   ├── decision-analyst.md          # Evaluates options against framework
│   ├── generator.md                 # Creates draft from inputs
│   ├── author.md                    # Applies gap resolutions to draft
│   └── scope-extractor.md          # Extracts scope brief from blueprint
└── review/
    ├── orchestrator.md
    ├── author.md
    ├── consolidator.md
    ├── change-verifier.md
    └── experts/
        ├── strategist.md
        ├── commercial.md
        ├── customer-advocate.md
        └── operator.md
```

---

## Output Structure

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
    ├── round-1-create/                # Round 1 (from concept)
    │   ├── explore/
    │   │   ├── 00-dimensions.md
    │   │   ├── 01-explorer-*.md
    │   │   ├── 02-enrichment-discussion.md
    │   │   ├── 02a-filtered-enrichment-discussion.md
    │   │   └── 03-exploration-summary.md
    │   ├── 00-draft-blueprint.md
    │   └── ...
    ├── round-{N}-create/              # Round N (N≥2) — from previous draft
    │   ├── explore/
    │   │   └── ...
    │   └── ...
    └── round-{N}-review/              # Review round outputs
        ├── 00-blueprint.md            # Snapshot of input
        ├── 01-[expert].md
        ├── 02-consolidated-issues.md
        ├── 03-issues-discussion.md
        ├── 04-author-output.md
        ├── 05-updated-blueprint.md
        └── 06-change-verification-report.md
```

**Downstream deferred items (for Blueprint content that's too detailed):**
- `system-design/02-prd/versions/deferred-items.md` - Features, UI/UX
- `system-design/03-foundations/versions/deferred-items.md` - Technology choices
- `system-design/04-architecture/versions/deferred-items.md` - System decomposition
- `system-design/05-components/versions/deferred-items.md` - Data models, APIs

---

## Invocation

**Create a Blueprint:**
```
Read the Blueprint creation orchestrator at:
agents/01-blueprint/create/orchestrator.md

Then create a Blueprint from:
- Concept: [path to your concept document]

Start the creation workflow.
```

**Review a Blueprint:**
```
Read the Blueprint review orchestrator at:
agents/01-blueprint/review/orchestrator.md

Then run the Blueprint review workflow for:
- Blueprint: system/01-blueprint/blueprint.md

Start or resume the review.
```

---

## Custom Create Workflow

Blueprint uses a custom create workflow with an exploration loop, iterative rounds, and a separate Decision Orchestrator.

**Flow:** Setup → [Explore → Generate → Gap Resolution]* → Extract (promote + scope brief)

**Explore phase:**
1. **Dimension Identifier** — reads concept and identifies 3-5 strategic dimensions worth exploring
2. **Human reviews** dimension list (can add, remove, modify, or skip exploration)
3. **Dimension Explorers** — one per dimension, run in parallel, each proposes 2-5 enrichments with trade-offs
4. **Exploration Consolidator** — merges explorer outputs, groups by Blueprint section, deduplicates
5. **Enrichment Scope Filter** — three-tier depth filtering (keep / defer-depth / flag)
6. **Human reviews** enrichments (accept, reject, modify, route to decision, discuss)
7. **Enrichment Author** — produces exploration summary for the Generator

**Decision Orchestrator** (separate workflow): For enrichments that require strategic decisions, a separate Decision Orchestrator handles framework definition and analysis. Decisions are registered as pending gaps in the Blueprint until resolved.

**Generate phase:** Generator produces draft using concept + exploration summary + resolved decisions. Gaps presented to human for resolution (provide answers, edit directly, or run another round).

**Multi-round:** Human can say "another round" at gap resolution to run another explore→generate cycle. Round 2+ explores from the previous round's draft.

**Extract phase:** Promoter copies final draft to `blueprint.md` and Scope Extractor produces `scope-brief.md` for downstream stages.

**Human checkpoints:**
- Dimension review (Step 3)
- Enrichment review (Step 7)
- Gap resolution / promote decision (Step 10)

---

## Blueprint-Specific Considerations

### No Alignment Verification

Blueprint is the only stage that skips Alignment Verification. Its source (concept document) is informal - "a rough idea or brief description" - so there's no formal source to verify against. The Blueprint *expands* the concept rather than *implements* it.

### Level Calibration

Blueprint is the most strategic level. Common level violations:

| Appropriate (Blueprint) | Too Detailed (defer downstream) |
|------------------------|-------------------------------|
| "We target mid-size event organisers" | "Organisers with 5-50 events/year" |
| "Subscription-based revenue model" | "£50/month with annual discount" |
| "Email extraction bootstraps supply" | "Using Claude 3.5 with structured output" |
| "Phase 1 validates core hypothesis" | "Phase 1 has 6 stages with exit criteria" |
| "Consumer-first design principle" | "Homepage has search bar and category grid" |
| "Pre-validation is a design research phase" | "Seven specific learning objectives with assessment framework" |
| "Completeness and accuracy are different problems" | "90%+ completeness target, below 70% unacceptable, diagnostic logic" |

Note: The last two examples illustrate **operational/procedural** over-specification — content that is Blueprint-level in topic but exceeds the guide's stated depth. The strategic insight belongs in the Blueprint; the procedural detail (specific process frameworks, metrics targets with thresholds, decision procedures) belongs in the PRD. The Enrichment Scope Filter auto-defers clear depth violations and flags borderline cases for human review.

