# Architecture Overview Stage

The Architecture Overview decomposes PRD capabilities into components, defines data flows between them, and produces the list of component specs to create. It bridges the gap between "what" (PRD) and "how" (Component Specs).

For general workflow mechanics, see `workflow-create.md` and `workflow-review.md`.

---

## What It Contains

- **System Context**: System boundaries, external actors, key inputs/outputs
- **Component Decomposition**: Major components with responsibilities and rationale
- **Data Flows**: How data moves between components, key entities
- **Integration Points**: Component communication patterns, external integrations
- **Key Technical Decisions**: Architecture-level choices and patterns
- **Component Spec List**: Which specs to write, with scope and data ownership
- **Cross-Cutting Concerns**: Auth approach, logging, monitoring, shared infrastructure
- **Open Questions**: Deferred decisions, assumptions to validate

---

## What It Doesn't Contain

| Out of Scope | Where It Belongs |
|--------------|------------------|
| API contracts and schemas | Component Specs |
| Database table designs | Component Specs |
| Implementation algorithms | Component Specs |
| Deployment configuration | Ops/Infrastructure docs |
| User stories | PRD |
| Business logic details | Component Specs |
| Technology-specific setup | Foundations |

**The test:** If the content is specific to one component's implementation, it belongs in that component's spec, not the overview.

---

## Expert Panel

Architecture Overview uses five experts for the Review workflow:

| Expert | Code | Focus |
|--------|------|-------|
| **System Architect** | SYSARCH | Component decomposition, boundaries, responsibilities, coupling |
| **Data Architect** | DATA | Data flows, ownership, consistency concerns |
| **Integration Architect** | INT | Component interactions, contracts, integration patterns |
| **Technical Reviewer** | TECH | Feasibility, Foundations alignment, complexity |
| **FinOps** | FINOPS | Cost implications, budget alignment, scaling cost characteristics |

**Note:** Security is not an expert at this stage. Security decisions are made in Foundations and reviewed by the Security Engineer during Foundations Review. Architecture-level security concerns (trust boundaries, auth flows between components) are addressed during Architecture Overview Review by the Technical Reviewer. See DEC-038 for rationale.

---

## Consolidation Themes

The Consolidator groups issues by these Architecture-specific themes:

- Component Decomposition
- Data Flows
- Integration Points
- Technical Decisions
- Cross-Cutting Concerns
- Alignment

---

## File Paths

**Stage guide:** `guides/04-architecture-guide.md`

**Agent prompts:**
```
agents/04-architecture/
├── create/
│   ├── orchestrator.md
│   ├── concern-identifier.md          # Identifies architectural concerns to explore
│   ├── concern-explorer.md            # Explores one concern deeply
│   ├── exploration-consolidator.md    # Merges explorer outputs
│   ├── enrichment-scope-filter.md     # Filters enrichments by level/depth
│   ├── enrichment-author.md           # Produces exploration summary
│   ├── generator.md                   # Creates draft from PRD + Foundations + enrichments
│   └── author.md                      # Applies resolved gap discussions
└── review/
    ├── orchestrator.md
    ├── promoter.md                  # Splits Architecture into spec/decisions/future at exit
    ├── author.md
    ├── consolidator.md
    ├── change-verifier.md
    └── experts/
        ├── system-architect.md
        ├── data-architect.md
        ├── integration-architect.md
        ├── technical-reviewer.md
        └── finops.md
```

---

## Output Structure

```
system/04-architecture/
├── architecture.md                  # Clean current-scope Architecture (created by promoter)
├── decisions.md                     # Design rationale and trade-offs (created by promoter)
├── future.md                        # Deferred items and future considerations (created by promoter)
└── versions/
    ├── deferred-items.md             # Content deferred from upstream stages
    ├── pending-issues.md            # Issues flagged for upstream review
    ├── workflow-state.md
    ├── create/
    │   └── round-{N}/               # Create workflow output (round 1, 2, etc.)
    │       ├── explore/
    │       │   ├── 00-concerns.md
    │       │   ├── 01-explorer-*.md
    │       │   ├── 02-enrichment-discussion.md
    │       │   ├── 02a-filtered-enrichment-discussion.md
    │       │   └── 03-exploration-summary.md
    │       ├── 00-draft-architecture.md
    │       ├── 01-gap-discussion.md
    │       ├── 02-author-output.md
    │       └── 03-updated-architecture.md
    └── review/
        └── round-N/                 # Review workflow output
        ├── 01-system-architect.md
        ├── 01-data-architect.md
        ├── 01-integration-architect.md
        ├── 01-technical-reviewer.md
        ├── 01-finops.md
        ├── 02-consolidated-issues.md
        ├── 03-issues-discussion.md   # Inline discussions happen here
        ├── 04-author-output.md
        ├── 05-updated-architecture.md
        ├── 06-alignment-report.md
        └── 07-change-verification-report.md
```

**Promotion**: At exit, the Architecture Promoter splits the final reviewed document into three files. `architecture.md` is the clean current-scope spec consumed by downstream stages. `decisions.md` captures architectural rationale and trade-offs. `future.md` captures deferred items, future components, and open questions. This matches the Components stage split pattern (see DEC-072).

**Downstream deferred items:**
- `system/05-components/versions/deferred-items.md` - Implementation details

---

## Invocation

**Create Architecture Overview:**
```
Read the Architecture Overview creation orchestrator at:
agents/04-architecture/create/orchestrator.md

Then create an Architecture Overview from:
- PRD: system/02-prd/prd.md
- Foundations: system/03-foundations/foundations.md

Start the creation workflow.
```

The generator accepts an optional brief at `system/04-architecture/brief.md`. If present, the brief's settled decisions are incorporated directly rather than being marked as gaps. The brief can be structured (matching guide sections), a flat list of decisions, or freeform prose. See DEC-073.

**Review Architecture Overview:**
```
Read the Architecture Overview review orchestrator at:
agents/04-architecture/review/orchestrator.md

Then run the review workflow for:
- Architecture Overview: system/04-architecture/architecture.md
- Foundations: system/03-foundations/foundations.md
- PRD: system/02-prd/prd.md

Start or resume the review.
```

---

## Custom Create Workflow

Architecture uses a custom create workflow with a full exploration loop, similar to Blueprint and PRD creation.

**Flow:** Setup → [Explore → Generate → Gap Resolution]* → Promote

**Explore phase:**
1. **Concern Identifier** — reads PRD + Foundations and identifies 3-5 architectural concerns worth exploring (component decomposition alternatives, data flow patterns, integration approaches, pipeline orchestration)
2. **Human reviews** concern list (can add, remove, modify, or skip exploration)
3. **Concern Explorers** — one per concern, run in parallel, each proposes 2-5 enrichments with trade-offs
4. **Exploration Consolidator** — merges explorer outputs, groups by Architecture section, deduplicates
5. **Enrichment Scope Filter** — filters by Architecture level, defers Component Specs detail
6. **Human reviews** enrichments (accept, reject, modify, discuss)
7. **Enrichment Author** — produces exploration summary for the Generator

**Generate phase:** Generator produces draft using PRD + Foundations + exploration summary. Gaps are presented for human resolution (provide answers, edit directly, or run another round).

**Multi-round:** The human can say "another round" at gap resolution to run another explore→generate cycle. Round 2+ explores from the previous round's draft rather than from PRD + Foundations directly.

**Human checkpoints:**
- Concern review (Step 3)
- Enrichment review (Step 7)
- Gap resolution / promote decision (Step 10)

---

## Architecture-Specific Considerations

### Abstraction Level

The Architecture Overview is about **structure**, not **implementation**. Every section should answer "what components exist and how do they relate?" not "how does this component work internally?"

**Right level:**
- "Event Service receives events, validates them, and persists to Event Store"
- "Components communicate via async message queue"

**Too detailed (belongs in Component Specs):**
- "Event Service exposes POST /events endpoint accepting JSON payload"
- "Message queue uses RabbitMQ with durable queues"

The Architecture Overview follows two Scope Principles (see `guides/04-architecture-guide.md`): **structure, not implementation** (define components and relationships, not capability lists, algorithms, threshold values, entry point commands, or database field names) and **reference, don't restate** (reference Foundations for conventions rather than reproducing retry policies, secrets lists, or security headers).

### PRD Traceability

Every PRD capability should map to one or more components. If a capability can't be mapped, the decomposition is incomplete. The Component Spec List should trace back to PRD capabilities.

### Alignment Verification

The Review workflow verifies the Architecture Overview against source documents (PRD + Foundations). The Technical Reviewer also checks Foundations alignment as part of expert review.

### Component Spec List

The spec list is a critical output — it drives the entire next stage. Ensure:
- Every component has a clear scope
- Data ownership is assigned (who owns what data)
- Dependencies are identified (spec order matters)

### FinOps Expert Focus

The FinOps expert is particularly important in Architecture Review because architecture decisions have major cost implications:

- **Component count** — More components = more infrastructure overhead
- **Data flows** — Cross-region or high-volume flows can be expensive
- **Scaling patterns** — Some patterns scale cost linearly, others exponentially
- **Technology choices** — Managed services vs self-hosted trade-offs

Cost issues caught here prevent expensive refactoring later.

