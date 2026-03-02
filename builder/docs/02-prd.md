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
│   ├── orchestrator.md
│   └── generator.md
└── review/
    ├── orchestrator.md
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
system/02-prd/
├── prd.md                           # Final PRD
└── versions/
    ├── deferred-items.md             # Content deferred from upstream stages
    ├── pending-issues.md            # Issues flagged for upstream review
    ├── workflow-state.md            # Current workflow state
    ├── round-0/                     # Create workflow output
    │   └── 00-draft-prd.md          # Generator output (human augments this)
    └── round-N/                     # Review workflow output
        ├── 01-[expert].md
        ├── 02-consolidated-issues.md
        ├── 03-issues-discussion.md   # Inline discussions happen here
        ├── 04-author-output.md
        ├── 05-updated-prd.md
        ├── 06-alignment-report.md
        └── 07-change-verification-report.md
```

**Downstream deferred items (for PRD content that's too detailed):**
- `system/03-foundations/versions/deferred-items.md` - Technology choices
- `system/04-architecture/versions/deferred-items.md` - System decomposition
- `system/05-components/versions/deferred-items.md` - Data models, APIs

---

## Invocation

**Create a PRD:**
```
Read the PRD creation orchestrator at:
agents/02-prd/create/orchestrator.md

Then create a PRD from:
- Blueprint: system/01-blueprint/blueprint.md

Start the creation workflow.
```

**Review a PRD:**
```
Read the PRD review orchestrator at:
agents/02-prd/review/orchestrator.md

Then run the PRD review workflow for:
- PRD: system/02-prd/prd.md
- Blueprint: system/01-blueprint/blueprint.md

Start or resume the review.
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

