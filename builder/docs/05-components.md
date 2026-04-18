# Component Specs Stage

Component Specs define **how to build each component** identified in the Architecture Overview. Each spec is implementation-ready: a developer should be able to build the component from the spec alone.

For general workflow mechanics, see `workflow-create.md` and `workflow-review.md`.

---

## What a Component Spec Contains

1. **Overview** - Component purpose, responsibilities, boundaries
2. **Scope** - What's in, what's out, what's deferred
3. **Interfaces** - API endpoints, message contracts, CLI commands
4. **Data Model** - Tables, schemas, relationships, constraints
5. **Behaviour** - Business logic, state machines, algorithms, edge cases
6. **Dependencies** - Other components, external services, libraries
7. **Integration** - How this component connects to others
8. **Error Handling** - Error types, recovery strategies, user feedback
9. **Observability** - Logging, metrics, alerts, health checks
10. **Security** - Auth requirements, data protection, input validation
11. **Testing** - Test strategy, key test cases, coverage requirements
12. **Open Questions** - Unresolved items, assumptions to validate
13. **Related Decisions** - Decisions that shaped this component, with source references

See `guides/05-components-guide.md` for full detail on each section.

---

## What Does NOT Belong in Component Specs

| Out of Scope | Where It Belongs |
|--------------|------------------|
| System-wide conventions | Foundations |
| Cross-component data flows | Architecture Overview |
| Business requirements | PRD |
| Strategic rationale | Blueprint |
| Actual code | Implementation |
| Deployment procedures | Ops Docs |
| Other components' internals | Their own specs |

**The test:** If the content applies to multiple components or isn't needed for implementation, it probably doesn't belong in the spec.

---

## Expert Panel

Component Specs uses seven experts for the Review workflow, split into two stages:

### Build Stage (4 experts)

| Expert | Code | Domain Focus |
|--------|------|--------------|
| **Technical Lead** | TECH | Implementation feasibility, Foundations compliance, complexity |
| **API Designer** | API | Interface design, contracts, versioning, developer experience |
| **Data Modeller** | DATA | Schema design, relationships, constraints, migrations |
| **Integration Reviewer** | INT | Cross-component consistency, contract alignment |

### Ops Stage (3 experts)

| Expert | Code | Domain Focus |
|--------|------|--------------|
| **Security Reviewer** | SEC | Security implementation, vulnerability assessment |
| **Test Engineer** | TEST | Test coverage, edge cases, error scenarios |
| **Operations Reviewer** | OPS | Observability, error handling, operational readiness |

See DEC-040 for expert panel rationale.

---

## Consolidation Themes

The Consolidator groups issues by these Component Spec-specific themes:

- Technical Feasibility
- Interface Design
- Data Model
- Behaviour & Logic
- Integration
- Security
- Testing & Quality
- Coherence

---

## Extended Review Workflow

Component Specs uses an extended 12-step review process (vs the standard 7-step workflow in `workflow-review.md`). Key additions: build/ops phase splitting, issue routing, contract verification, pending issue sync, and spec promotion.

### Steps

| Steps | Phase | Description |
|-------|-------|-------------|
| 0 | Pre-discussion | Initialize round (copy spec, set up round folder) |
| 1 | Pre-discussion | Expert review (4 build OR 3 ops experts, in parallel) |
| 2 | Pre-discussion | Consolidate issues |
| 3 | Pre-discussion | Issue Router (filter + route upstream/lateral issues) |
| 4 | Pre-discussion | Issue analysis (Issue Analyst provides options/recommendations) |
| 5 | Discussion | Human reviews and discusses issues inline |
| 6 | Post-discussion | Author applies approved changes |
| 7 | Post-discussion | Change Verification |
| 8 | Post-discussion | Alignment Verification (checks upstream consistency) |
| 9 | Post-discussion | Contract Verification (cross-component contract alignment) |
| 10 | Post-discussion | Evaluate results (NEEDS_REWORK / NEEDS_DECISIONS / VERIFICATION_CLEAN) |
| 11 | Post-discussion | Execute & Route (apply decisions, sync pending issues, choose next action) |
| 12 | Post-discussion | Promote spec (on exit only) |

### Build/Ops Phases

Each component cycles through two review phases:

- **Build** (4 experts): Technical design, API contracts, data models, integration
- **Ops** (3 experts): Security, testing, operational readiness

### Routing Logic

After each round, the routing decision determines next action:

| Current Phase | Condition | Recommendation |
|---------------|-----------|----------------|
| Build | Mature (no HIGH issues) | TRANSITION_TO_OPS |
| Build | Not mature | CONTINUE_BUILD |
| Ops | Mature (no HIGH issues) | EXIT |
| Ops | Not mature | CONTINUE_OPS |
| Ops | Structural issues found | KICK_BACK_TO_BUILD |

### Additional Agents (vs Standard Workflow)

| Agent | Step | Role |
|-------|------|------|
| Issue Router | 3 | Routes upstream/lateral issues to pending-issues files |
| Issue Analyst | 4 | Proactive analysis with options/recommendations before human sees issues |
| Contract Verifier | 9 | Validates cross-component contract alignment |
| Pending Issue Resolver | 11 | Executes human-decided pending issue resolutions (APPLY/DEFER/REJECT) |
| Spec Promoter | 12 | Produces implementation spec, decisions doc, and future planning doc |

### Verification Pipeline

Steps 7-9 run sequentially, each checking a different dimension:

| Step | Agent | Checks |
|------|-------|--------|
| 7 | Change Verifier | Changes applied correctly at appropriate level |
| 8 | Alignment Verifier | Consistency with upstream (Architecture, Foundations) |
| 9 | Contract Verifier | API contracts, cross-component data consistency |

Step 10 evaluates combined results:
- **NEEDS_REWORK**: Unresolved changes → return to Author
- **NEEDS_DECISIONS**: Partial resolutions or pending issues needing human decisions
- **VERIFICATION_CLEAN**: All clear → present routing options

---

## One Spec Per Component

Unlike other stages which produce a single document, Component Specs produces **one spec file per component**. The Architecture Overview's Component Spec List defines which specs to create.

**Creation order matters:** Create specs in dependency order — upstream components (data owners) first, dependent components after.

---

## Initialization and Deferred Items Processing

Component Specs is unique: it produces multiple specs (one per component) rather than a single document. Before creating any specs, run the **initializer** once to set up the folder structure and process deferred items.

### Initialization (One-Time)

Run the initializer before creating any component specs. It:

1. Reads the Architecture Overview's Component Spec List
2. Creates folder structure for all components: `versions/[component-name]/`
3. Runs the **Deferred Items Processor** to split the monolithic deferred items by component
4. Creates the workflow state file with all components listed as PENDING
5. Reports summary of what was created

The orchestrator will error if you try to create a spec without initializing first.

### Per-Component Creation Workflow

Component Specs uses the **Explore** creation pattern (see `workflow-create.md`):

```
[Explore → Generate → Gap Resolution]* → Promote
```

**Phase 1 — Explore**: Design Concern Identifier reads Architecture + Foundations and identifies 3-5 design concerns for the component (operation contracts, data model trade-offs, error vocabulary, atomicity boundaries). Human reviews concerns. Concern Explorers investigate each in parallel, proposing enrichments. Consolidator merges, Scope Filter removes wrong-level items, human reviews enrichments. Enrichment Author produces exploration summary.

**Phase 2 — Generate**: Generator creates draft WITH enrichment context. Coverage Checker verifies Architecture requirements. Depth Checker verifies minimum specification depth (typed inputs/outputs, named error rules, index declarations, atomicity boundaries). Gap resolution via full pipeline. Author applies resolutions.

**Phase 3 — Promote or Continue**: Human chooses to promote the draft or run another explore→generate round. Creation verification (alignment + coherence) runs before promotion.

The explore→generate cycle can repeat. Round 1 explores from Architecture + Foundations. Round 2+ explores from the previous round's draft.

---

## File Paths

**Stage guide:** `guides/05-components-guide.md`

**Agent prompts:**
```
agents/05-components/
├── initialize/
│   ├── orchestrator.md             # One-time setup (run before first spec)
│   └── deferred-items-processor.md  # Splits deferred items by component
├── create/
│   ├── orchestrator.md             # Per-component workflow ([Explore → Generate → Gap Resolution]* → Promote)
│   ├── concern-identifier.md       # Identifies design concerns for exploration
│   ├── concern-explorer.md         # Explores one concern deeply (parallel)
│   ├── exploration-consolidator.md # Merges explorer outputs by spec section
│   ├── enrichment-scope-filter.md  # Filters enrichments by level (defers up, filters code)
│   ├── enrichment-author.md        # Produces exploration summary
│   ├── enrichment-applicator.md    # Applies enrichments to existing draft (round 2+)
│   ├── generator.md                # Creates draft from Architecture + Foundations + enrichments
│   ├── requirements-extractor.md   # Extracts Architecture requirements checklist
│   ├── coverage-checker.md         # Verifies draft covers all checklist items
│   ├── depth-checker.md            # Verifies draft meets minimum specification depth
│   └── author.md                   # Applies resolved gap discussions
├── cross-cutting/
│   ├── orchestrator.md             # Populate cross-cutting contracts
│   ├── contract-extractor.md       # Extract contracts from one component spec
│   └── contract-reconciler.md      # Reconcile consumed interfaces against registered contracts
├── coherence/
│   └── orchestrator.md             # Stage coherence review
└── review/
    ├── orchestrator-router.md        # Main entry point, routes to phases
    ├── orchestrator-pre-discussion.md  # Steps 1-5: Expert review through discussion
    ├── orchestrator-discussion.md    # Discussion facilitation
    ├── orchestrator-post-discussion.md # Steps 6-12: Apply, verify, promote
    ├── author.md
    ├── consolidator.md
    ├── issue-router.md               # Routes issues upstream/lateral
    ├── change-verifier.md
    ├── contract-verifier.md
    ├── spec-promoter.md
    └── experts/
        ├── build/
        │   ├── api-designer.md
        │   ├── data-modeller.md
        │   ├── integration-reviewer.md
        │   └── technical-lead.md
        └── ops/
            ├── operations-reviewer.md
            ├── security-reviewer.md
            └── test-engineer.md
```

---

## Output Structure

```
system/05-components/
├── specs/
│   ├── [component-a].md             # Promoted implementation spec (v1.0)
│   ├── [component-b].md
│   ├── cross-cutting.md             # Cross-component contract registry
│   └── ...
├── decisions/
│   ├── [component-a].md             # Design decisions extracted during promotion
│   └── ...
├── future/
│   ├── [component-a].md             # Growth paths and deferred items
│   └── ...
└── versions/
    ├── deferred-items.md             # Monolithic deferred items (archived after processing)
    ├── deferred-items-archived-YYYY-MM-DD.md  # Archived original
    ├── pending-issues.md            # Issues flagged for upstream review
    ├── workflow-state.md            # Stage-level state (all components)
    ├── cross-cutting/
    │   ├── deferred-items.md        # Items spanning multiple components
    │   ├── population-state.md      # Cross-cutting population progress tracker
    │   ├── extraction/              # Per-component extraction reports
    │   │   └── [component-name].md
    │   └── reconciliation/          # Per-component reconciliation reports
    │       └── [component-name].md
    ├── coherence/                   # Stage coherence review reports
    │   └── [date]-coherence-report.md
    ├── [component-a]/
    │   ├── deferred-items.md        # Component-specific deferred items
    │   ├── workflow-state.md        # Per-component state (steps, rounds, parts)
    │   ├── pending-issues.md        # Cross-component issues targeting this component
    │   ├── round-{N}-create/        # Create workflow (may have multiple rounds)
    │   │   ├── explore/
    │   │   │   ├── 00-concerns.md
    │   │   │   ├── 01-explorer-*.md
    │   │   │   ├── 02-enrichment-discussion.md
    │   │   │   ├── 02a-filtered-enrichment-discussion.md
    │   │   │   └── 03-exploration-summary.md
    │   │   ├── 00-draft-spec.md
    │   │   ├── 00-enrichment-applicator-output.md  # Round 2+ only
    │   │   ├── 00-requirements-checklist.md
    │   │   ├── 00-coverage-report.md
    │   │   ├── 00-depth-report.md
    │   │   ├── 01-gap-discussion.md
    │   │   ├── 02-author-output.md
    │   │   └── 03-updated-spec.md
    │   └── round-{N}-review-[build|ops]/  # Review workflow (build or ops phase)
    │       ├── 00-spec.md           # Input spec snapshot
    │       ├── 01-[expert].md       # Expert outputs (3-4 per round)
    │       ├── 02-consolidated-issues.md
    │       ├── 03-issues-discussion.md  # Inline discussions + issue analysis
    │       ├── 04-author-output.md
    │       ├── 05-updated-spec.md
    │       ├── 06-change-verification-report.md
    │       ├── 07-alignment-report.md
    │       ├── 08-contract-verification-report.md
    │       └── 09-verification-summary.md  # Combined results + recommendation
    └── [component-b]/
        ├── deferred-items.md
        ├── workflow-state.md
        └── ...
```

---

## Invocation

**Initialize (once, before first spec):**
```
Read the Component Specs initialize orchestrator at:
agents/05-components/initialize/orchestrator.md

Initialize Component Specs for:
- Architecture Overview: system/04-architecture/architecture.md

Run the initialization.
```

**Create a Component Spec (per component):**
```
Read the Component Spec creation orchestrator at:
agents/05-components/create/orchestrator.md

Then create a spec for:
- Component: [component-name]
- Architecture Overview: system/04-architecture/architecture.md
- Foundations: system/03-foundations/foundations.md

Start the creation workflow.
```

The generator accepts an optional per-component brief at `system/05-components/versions/[component-name]/brief.md`. If present, the brief's settled decisions are incorporated directly rather than being marked as gaps. The brief can be structured (matching guide sections), a flat list of decisions, or freeform prose. See DEC-073.

**Review a Component Spec:**
```
Read the Component Spec review orchestrator at:
agents/05-components/review/orchestrator.md

Then run the review workflow for:
- Spec: system/05-components/specs/[component-name].md
- Architecture Overview: system/04-architecture/architecture.md
- Foundations: system/03-foundations/foundations.md

Start or resume the review.
```

**Populate Cross-Cutting Contracts:**
```
Read the Cross-Cutting Population Orchestrator at:
agents/05-components/cross-cutting/orchestrator.md

Populate cross-cutting specification from completed specs.
```

**Run Stage Coherence Review:**
```
Read the Stage Coherence Review Orchestrator at:
agents/05-components/coherence/orchestrator.md

Run stage coherence review.
```

---

## Component Spec-Specific Considerations

### Level Calibration

Component Specs are implementation-ready. They should be detailed enough that a developer can build from them.

| Appropriate (Component Spec) | Too Abstract (belongs upstream) | Too Detailed (belongs in code) |
|-----------------------------|--------------------------------|-------------------------------|
| "POST /events accepts {title, date, venue_id}" | "Events can be created" | "Use Express.js router.post()" |
| "events table: id UUID PK, title VARCHAR(255)" | "Events are persisted" | "CREATE INDEX idx_events_date" |
| "Return 400 if title > 255 chars" | "Validate input" | "if (title.length > 255) throw..." |
| "Log event creation at INFO level" | "Operations are logged" | "logger.info({event: 'created'})" |

Component Specs follow three Scope Principles (see `guides/05-components-guide.md`): **contracts not code** (express interfaces as tables and behaviour as prose, not Python/SQL), **reference don't restate** (cite Foundations conventions rather than reproducing them), and **no Implementation Reference sections** (code belongs in the codebase).

### Foundations Compliance

Every spec must apply Foundations conventions — but by **referencing** them, not restating them. Specs define what is specific to the component; system-wide conventions (error envelope format, security headers, retry policies, log format) are referenced with a pointer (e.g., "per Foundations §Error Handling") rather than reproduced inline.

The Alignment Verifier checks Foundations compliance.

### Cross-Component Consistency

When a spec references another component:
- Use the exact interface defined in that component's spec
- Don't invent contracts — reference the source spec
- If a needed interface doesn't exist, flag it as a gap

The Integration Reviewer specifically checks cross-component consistency.

### Architecture Overview Alignment

Every spec must trace back to the Architecture Overview:
- Component must be in the Component Spec List
- Responsibilities must match what Architecture Overview assigned
- Data ownership must be respected
- Integration points must align with defined data flows

### Spec Stability

Component Specs should stabilize before Tasks are generated. If a spec changes significantly after tasks are created, tasks may need regeneration.

---

## Stage-Wide Workflows

Beyond individual component creation and review, Component Specs has two stage-wide workflows:

### Cross-Cutting Population

Extracts data contracts from completed component specs and populates the cross-cutting specification. Processes one component at a time in dependency order using three agents: an orchestrator, a contract extractor, and a contract reconciler.

**When to run:**
- All application-layer component specs are complete and promoted
- You want to establish a central contract registry for verification

**What it does:**
1. Processes each component in dependency order (upstream producers first)
2. **Extracts** produced and consumed interfaces from each spec (contract-extractor agent)
3. **Reconciles** consumed interfaces against already-registered producer contracts (contract-reconciler agent)
4. **Registers** produced contracts to `specs/cross-cutting.md` with schema, consumer expectations, and verification notes
5. **Finalises** with source traceability, reconciliation summary, and deferred items validation
6. Runs fully automatically — presents a single summary at the end

Contracts are registered as DEFINED. The contract verifier in the review workflow transitions them to VERIFIED during subsequent reviews.

### Stage Coherence Review

Verifies cross-component coherence before stage sign-off. Addresses issues that span components:

- **Pending issues resolution** - Issues logged against components by other component reviews
- **Contract verification** - Producer/consumer alignment using cross-cutting contracts
- **Consistency check** - Naming/schema drift across components

**When to run:**
- Before closing the component specs stage (all components COMPLETE)
- At checkpoints (every 3-4 components complete)
- When cross-component issues are suspected

**Phases:**

| Phase | Name | Description |
|-------|------|-------------|
| 1 | Gather State | Read component statuses, count pending issues, check cross-cutting status |
| 2 | Pending Issues Resolution | Aggregate unresolved issues by target, triage (APPLY/DEFER/REJECT), apply resolutions |
| 3 | Cross-Cutting Population | Refresh cross-cutting contracts if needed (delegates to cross-cutting orchestrator) |
| 4 | Contract Verification | Build contract matrix, verify producer/consumer alignment, resolve mismatches |
| 5 | Consistency Check | Scan for naming/schema drift (enums, field naming, schema patterns) |
| 6 | Coherence Report | Compile findings into `versions/coherence/[date]-coherence-report.md` |
| 7 | Update Stage State | Add history entry to workflow-state.md |

**Output:** `versions/coherence/[date]-coherence-report.md` with status (COHERENT or ISSUES_REMAINING), summary table, blocking/deferred issues, and sign-off checklist.

### Promotion

After a component's review reaches EXIT (ops phase, no HIGH issues), the Spec Promoter produces three deliverables:

| Output | Location | Content |
|--------|----------|---------|
| Implementation spec | `specs/[component].md` | Clean v1.0 spec (review artifacts stripped, CHANGED markers removed) |
| Decisions doc | `decisions/[component].md` | Design decisions extracted from review history |
| Future planning | `future/[component].md` | Growth paths, deferred items, and future considerations |

The promoter reads the full review history to extract decisions and growth paths that accumulated during iterative review.

See invocation section for how to run these workflows.

