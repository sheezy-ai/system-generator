# Product Requirements (PRD) Stage

The PRD (Product Requirements Document) defines **what** we're building in a specific phase. It translates the Blueprint's strategic vision into concrete capabilities, success criteria, and scope boundaries.

For general workflow mechanics, see `workflow-create.md` and `workflow-review.md`.

---

## What a PRD Contains

1. **Phase Goal** - What this phase achieves, how it advances the Blueprint
2. **Success Criteria** - Measurable outcomes we're targeting
3. **Capabilities** - What users can do when this phase is complete
4. **Scope: In and Out** - Explicit boundaries
5. **Conceptual Data Model** - Key entities and relationships (not schema)
6. **Key Decisions** - Product decisions and trade-offs
7. **User Workflows** - Primary user journeys
8. **Integration Points** - External systems and data flows
9. **Compliance and Constraints** - Regulatory and security requirements
10. **Risks and Dependencies** - What could prevent success
11. **Definition of Done** - Completion criteria

See `guides/02-prd-guide.md` for full detail on each section.

---

## What Does NOT Belong in a PRD

| Out of Scope | Where It Belongs |
|--------------|------------------|
| Technical architecture | Foundations |
| Database schemas | Component Specs |
| API contracts | Component Specs |
| Implementation approach | Component Specs |
| UI/UX designs | Design Docs |
| Detailed user journeys with screens | Design Docs |
| Operational procedures | Ops Docs |
| Timelines and estimates | Project planning |
| Story breakdowns | Tasks |

**The test:** If content specifies *how* something is built rather than *what* is delivered, it probably doesn't belong in the PRD.

---

## Expert Panel

PRD uses five domain experts for the Review workflow:

| Expert | Code | Domain Focus |
|--------|------|--------------|
| **Product Manager** | PROD | Scope, prioritisation, Blueprint alignment |
| **Commercial** | COMM | Business model, resource efficiency |
| **Customer Advocate** | CUST | User value, adoption barriers |
| **Operator** | OPS | Delivery feasibility, launch readiness |
| **Compliance/Legal** | COMPL | GDPR, CCPA, SOC2, PCI-DSS, HIPAA, accessibility |

**Why no technical feasibility expert:** PRD defines *what* to build at requirements level. Technical feasibility (can we build this with available technology) is answered in downstream stages: Foundations, Architecture Overview, and Component Specs. The Operator expert covers *operational* feasibility (can we deliver and sustain this). See DEC-036.

---

## Consolidation Themes

The Consolidator groups issues by these PRD-specific themes:

- Scope & Prioritisation
- Success Criteria
- Capabilities
- Blueprint Alignment
- User Value
- Commercial
- Operational
- Coherence

---

## Create Workflow

PRD has a custom create workflow, unlike the generic Setup → Generate → Report pattern used by stages 03-05 (see `workflow-create.md`).

**Flow:** Setup → [Explore → Generate → Gap Resolution]* → Promote

The explore→generate cycle iterates for as many rounds as the human wants:
- **Round 1** explores from `blueprint.md`
- **Round 2+** explores from the previous round's draft
- The human exits the loop by choosing to promote at Gap Resolution

### Explore Phase (Steps 1-8)

Identifies capability areas from the Blueprint that need product-level decomposition, spawns parallel explorers for each area, consolidates enrichment proposals, filters by scope, and facilitates human review. Unlike Blueprint, PRD does not route enrichments to a separate Decision Orchestrator — product-level decisions are resolved inline during enrichment review or gap resolution.

### Generate Phase (Steps 9-10)

Generates a draft PRD from the Blueprint + accepted enrichments + brief (if provided). The human then reviews gaps and chooses to promote, answer gaps, or do another round.

### Promote Phase (Step 11)

Copies the final draft to `prd.md`.

---

## Scope Determination

PRD scope comes from the Blueprint's **MVP Definition** section. The Generator extracts:
- What's in scope for MVP
- What's explicitly out of scope
- Phase boundaries

No separate phase number is needed in the trigger prompt.

---

## File Paths

**Stage guide:** `guides/02-prd-guide.md`

**Agent prompts:**
```
agents/02-prd/
├── create/
│   ├── orchestrator.md                # Coordinates explore→generate loop
│   ├── capability-identifier.md       # Identifies capability areas from Blueprint
│   ├── capability-explorer.md         # Decomposes one capability area into requirements
│   ├── exploration-consolidator.md    # Merges explorer outputs by PRD section
│   ├── enrichment-scope-filter.md     # Filters enrichments by level/depth
│   ├── enrichment-author.md           # Produces exploration summary
│   ├── generator.md                   # Creates draft from Blueprint + enrichments (round 1)
│   ├── enrichment-applicator.md       # Applies enrichments to existing draft (round 2+)
│   └── author.md                      # Applies gap resolutions to draft
└── review/
    ├── orchestrator.md
    ├── promoter.md                    # Splits PRD into spec/decisions/future at exit
    ├── author.md
    ├── consolidator.md
    ├── change-verifier.md
    └── experts/
        ├── product-manager.md
        ├── commercial.md
        ├── customer-advocate.md
        ├── operator.md
        └── compliance-legal.md
```

---

## Output Structure

```
system-design/02-prd/
├── prd.md                             # Promoted from create (then overwritten by Review)
├── brief.md                           # Optional human-provided brief
└── versions/
    ├── deferred-items.md              # Content deferred from upstream stages
    ├── pending-issues.md              # Issues flagged for upstream review
    ├── workflow-state.md              # Unified workflow state (shared with Review)
    ├── round-1-create/                # Round 1 (from blueprint)
    │   ├── explore/
    │   │   ├── 00-capabilities.md
    │   │   ├── 01-explorer-*.md
    │   │   ├── 02-enrichment-discussion.md
    │   │   ├── 02a-filtered-enrichment-discussion.md
    │   │   └── 03-exploration-summary.md
    │   ├── 00-draft-prd.md
    │   ├── 01-gap-resolutions.md
    │   ├── 02-author-output.md
    │   └── 03-updated-prd.md
    ├── round-{N}-create/              # Additional create rounds (if "another round")
    │   ├── explore/
    │   │   └── [same explore files]
    │   └── [same generate files]
    └── round-{N}-review/              # Review round outputs
        ├── 01-[expert].md
        ├── 02-consolidated-issues.md
        ├── 03-issues-discussion.md
        ├── 04-author-output.md
        ├── 05-updated-prd.md
        ├── 06-alignment-report.md
        └── 07-change-verification-report.md
```

**Downstream deferred items (for PRD content that's too detailed):**
- `system-design/03-foundations/versions/deferred-items.md` - Technology choices
- `system-design/04-architecture/versions/deferred-items.md` - System decomposition
- `system-design/05-components/versions/deferred-items.md` - Data models, APIs

---

## Invocation

**Create a PRD:**
```
Read the PRD creation orchestrator at:
agents/02-prd/create/orchestrator.md

Create a PRD.
```

**Review a PRD:**
```
Read the PRD review orchestrator at:
agents/02-prd/review/orchestrator.md

Review the PRD.
```

---

## PRD-Specific Considerations

### Level Calibration

PRD sits between Blueprint (strategic) and Foundations (technical). Common level violations:

| Appropriate (PRD) | Too Strategic (belongs in Blueprint) | Too Detailed (defer downstream) |
|-------------------|-------------------------------------|-------------------------------|
| "Users can filter events by date" | "We target event discovery" | "Date picker with calendar UI" |
| "Success: 50+ events published" | "Success: validated hypothesis" | "PostgreSQL range queries" |
| "Events have venue and categories" | "We solve event discovery" | "venue_id foreign key schema" |
| "GDPR data retention required" | "Regulatory compliance" | "30-day TTL on sessions table" |

### Blueprint Alignment

PRD must align with Blueprint. The Alignment Verifier (in Review workflow) checks for:
- **CONTRADICTION**: PRD conflicts with Blueprint
- **SCOPE_DRIFT**: PRD expands/contracts scope without justification
- **MISSING_ALIGNMENT**: Blueprint requirement not addressed
- **AMBIGUOUS**: Unclear whether PRD aligns

If discrepancies are found, they're resolved via:
- **FIX_NEW**: Update PRD to align
- **FIX_SOURCE**: Log issue to Blueprint's pending-issues.md
- **NOT_A_CONFLICT**: Document explanation
- **INTENTIONAL**: Document reasoning in the PRD with source reference

### Compliance/Legal Expert

PRD Review includes a Compliance/Legal expert (not in Create). This expert identifies:
- GDPR, CCPA, SOC2, PCI-DSS, HIPAA requirements
- Accessibility compliance (WCAG)
- Industry-specific regulations

Issues include a **Regulation/Standard** field (e.g., "GDPR Art. 17", "SOC2 CC6.1").

