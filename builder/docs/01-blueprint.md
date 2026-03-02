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
| **Operator** | OPS | Feasibility, dependencies, risks, operational complexity |

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

## File Paths

**Stage guide:** `guides/01-blueprint-guide.md`

**Agent prompts:**
```
agents/01-blueprint/
├── create/
│   ├── orchestrator.md
│   └── generator.md
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
system/01-blueprint/
├── blueprint.md                    # Final Blueprint
└── versions/
    ├── out-of-scope.md             # Content that doesn't belong in docs
    ├── workflow-state.md           # Current workflow state
    ├── round-0/                    # Create workflow output
    │   └── 00-draft-blueprint.md   # Generator output (human augments this)
    └── round-N/                    # Review workflow output
        ├── 01-[expert].md
        ├── 02-consolidated-issues.md
        ├── 03-issues-discussion.md   # Inline discussions happen here
        ├── 04-author-output.md
        ├── 05-updated-blueprint.md
        └── 06-alignment-report.md
```

**Downstream deferred items (for Blueprint content that's too detailed):**
- `system/02-prd/versions/deferred-items.md` - Features, UI/UX
- `system/03-foundations/versions/deferred-items.md` - Technology choices
- `system/04-architecture/versions/deferred-items.md` - System decomposition
- `system/05-components/versions/deferred-items.md` - Data models, APIs

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

