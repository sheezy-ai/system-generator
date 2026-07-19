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

Architecture Overview uses eight experts for the Review workflow:

| Expert | Code | Focus |
|--------|------|-------|
| **System Architect** | SYSARCH | Component decomposition, boundaries, responsibilities, coupling |
| **Data Architect** | DATA | Data flows, ownership, consistency concerns |
| **Integration Architect** | INT | Component interactions, contracts, integration patterns |
| **Technical Reviewer** | TECH | Feasibility, Foundations alignment, complexity |
| **FinOps** | FINOPS | Cost implications, budget alignment, scaling cost characteristics |
| **Security** | SEC | Architecture-level trust boundaries, auth flows between components |
| **Contract Completeness** | CONTRACT | Every cross-component read (incl. §5 decisions) resolves to a §8 data contract, or its ownership is flagged — closes the silent-uncontracted-read class |
| **Contract Freezability** | FREEZE | Each §8 contract is pinnable/freezable (the materializer's Frozen / Freezable-but-delegated / Under-pinned classification, run in-round before the freeze) |

**Contract Completeness + Contract Freezability** are the review half of the promote-stage freeze gate: they surface uncontracted or un-freezable cross-component reads *in-round*, where discussion already lives, so they can be resolved before promotion. The same two checks re-run as the hard, unavoidable gate in the **Promote workflow** (see "Promotion", below). *(Security became a review expert via a separate change, superseding the earlier "security is out of scope at Architecture" position.)*

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
│   ├── generator.md                   # Creates draft from PRD + Foundations + enrichments (round 1)
│   ├── enrichment-applicator.md       # Applies enrichments to existing draft (round 2+)
│   ├── requirements-extractor.md      # Extracts PRD requirements checklist
│   ├── coverage-checker.md            # Verifies draft covers all checklist items
│   └── author.md                      # Applies resolved gap discussions
├── review/
│   ├── orchestrator.md              # Exits mature → hands off to the Promote workflow (no longer runs the promoter)
│   ├── author.md
│   ├── consolidator.md
│   ├── change-verifier.md
│   └── experts/
│       ├── system-architect.md
│       ├── data-architect.md
│       ├── integration-architect.md
│       ├── technical-reviewer.md
│       ├── finops.md
│       ├── security.md
│       ├── contract-completeness.md    # Freeze gate (review half): uncontracted cross-component reads
│       └── contract-freezability.md    # Freeze gate (review half): un-freezable/under-pinned contracts
└── promote/                        # The single freeze — its own workflow (Slice 3), after Review
    ├── orchestrator.md              # Guard → gate → split → materialize → fidelity → publish → re-verify flag → record
    ├── promoter.md                  # Splits the reviewed Architecture into architecture.md/decisions.md/future.md (moved here from review/)
    ├── contract-materializer.md     # Projects §7/§8 → the frozen cross-cutting registry (FIRST_FREEZE | status-preserving MERGE)
    └── materialization-fidelity-checker.md  # Re-derives §7/§8 and diffs the registry (gate: MISMATCH halts the freeze)
```
The Promote orchestrator re-runs the two contract experts (`review/experts/contract-completeness.md`, `…/contract-freezability.md`) as the hard gate — they live in `review/` and are cross-referenced, not duplicated.

---

## Output Structure

```
system/04-architecture/
├── architecture.md                  # Clean current-scope Architecture (created by the Promote workflow)
├── decisions.md                     # Design rationale and trade-offs (created by the Promote workflow)
├── future.md                        # Deferred items and future considerations (created by the Promote workflow)
└── versions/
    ├── deferred-items.md             # Content deferred from upstream stages
    ├── pending-issues.md            # Issues flagged for upstream review
    ├── workflow-state.md
    ├── round-N-create/               # Create workflow output (round 1, 2, etc.)
    │   ├── explore/
    │   │   ├── 00-concerns.md
    │   │   ├── 01-explorer-*.md
    │   │   ├── 02-enrichment-discussion.md
    │   │   ├── 02a-filtered-enrichment-discussion.md
    │   │   └── 03-exploration-summary.md
    │   ├── 00-draft-architecture.md
    │   ├── 01-gap-discussion.md
    │   ├── 02-author-output.md
    │   └── 03-updated-architecture.md
    ├── round-N-review/              # Review workflow output
    │   ├── 01-system-architect.md   # (one 01-[expert].md per expert — 8 experts incl. security + the two contract experts)
    │   ├── 01-data-architect.md
    │   ├── 01-integration-architect.md
    │   ├── 01-technical-reviewer.md
    │   ├── 01-finops.md
    │   ├── 02-consolidated-issues.md
    │   ├── 03-issues-discussion.md   # Inline discussions happen here
    │   ├── 04-author-output.md
    │   ├── 05-updated-architecture.md
    │   ├── 06-alignment-report.md
    │   └── 07-change-verification-report.md
    └── round-N-promote/             # Promote workflow: the freeze record (Slice 3)
        ├── 00-architecture.md               # Input snapshot (the reviewed doc being frozen)
        ├── 00-prior-published-architecture.md # Prior architecture.md — MERGE re-freeze baseline
        ├── 11-contract-completeness-gate.md  # Gate re-run (completeness)
        ├── 12-contract-freezability-gate.md  # Gate re-run (freezability)
        ├── cross-cutting.md                  # Materialized registry original (published to 05-specs after fidelity CLEAN)
        ├── materialization.md                # Materialization report
        ├── materialization-fidelity.md       # Fidelity report
        └── promote-metadata.md               # Freeze record (date, source review round, gate verdict, mode, Frozen-At token)
```

**Promotion**: Promotion is a separate **Promote** workflow (not a step of Review) — the single freeze. After a Review round completes, Promote guards that the last completed round was Review, re-runs the contract completeness/freezability gate, then the Architecture Promoter splits the final reviewed document into three files, materializes the frozen contract registry (`05-components/specs/cross-cutting.md`) and fidelity-checks it — all recorded under `round-N-promote/`. Promote stamps a `Frozen-At` freeze-identity token into both `architecture.md`'s header and the registry Status block, so 05-init can reject a registry stale versus the current architecture (the stale-registry guard); a MERGE re-freeze additionally flags every producer of a changed write-direction contract for re-verification at its next review. `architecture.md` is the clean current-scope spec consumed by downstream stages. `decisions.md` captures architectural rationale and trade-offs. `future.md` captures deferred items, future components, and open questions. This matches the Components stage split pattern (see DEC-072, DEC-081, DEC-082).

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

**Flow:** Setup → [Explore → Generate → Gap Resolution]* → finalise draft → **hand to Review** (Create no longer promotes — the Promote workflow runs after Review; see "Promotion")

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
- Gap resolution / finalise-or-another-round decision (Create finalises the draft and hands to Review; it does not promote)

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

