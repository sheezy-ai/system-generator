# Foundations Stage

Foundations captures **shared technical decisions** that apply across all components. It answers the cross-cutting technical questions once, so component specs don't have to re-ask them.

For general workflow mechanics, see `workflow-create.md` and `workflow-review.md`.

---

## What Foundations Contains

1. **Technology Choices** - Languages, frameworks, databases, cloud provider
2. **Architecture Patterns** - Monolith/microservices, sync/async, deployment model
3. **Authentication & Authorization** - Auth approach, session management, RBAC/ABAC
4. **Data Conventions** - Naming, ID formats, timestamps, audit fields, soft delete
5. **API Conventions** - REST/GraphQL, versioning, error format, pagination
6. **Error Handling** - Error categories, client vs internal info, retry policies
7. **Logging & Observability** - Log format, levels, correlation IDs, metrics, alerting
8. **Security Baseline** - Secrets management, encryption, input validation, headers
9. **Testing Conventions** - Frameworks, coverage expectations, test data
10. **Deployment & Infrastructure** - CI/CD, environments, feature flags
11. **Open Questions** - Deferred decisions, unknowns

See `guides/03-foundations-guide.md` for full detail on each section.

---

## What Does NOT Belong in Foundations

| Out of Scope | Where It Belongs |
|--------------|------------------|
| Component-specific decisions | Component Specs |
| Business requirements | PRD |
| Strategic direction | Blueprint |
| Detailed schemas | Component Specs |
| Operational runbooks | Ops Docs |
| One-off exceptions | Component Specs (with rationale) |
| System decomposition | Architecture Overview |
| Component boundaries | Architecture Overview |

**The test:** If the decision only affects one component, it probably belongs in that component's spec, not Foundations.

---

## Expert Panel

Foundations uses four technical experts for the Review workflow:

| Expert | Code | Domain Focus |
|--------|------|--------------|
| **Infrastructure Architect** | INFRA | Cloud, deployment, environments, scaling, CI/CD |
| **Data Engineer** | DATA | Databases, data conventions, lifecycle, backup |
| **Security Engineer** | SEC | Auth, encryption, secrets, input validation |
| **Platform Engineer** | PLAT | APIs, observability, logging, testing |

**Why these four experts?** A Foundations document must answer:
- How do we deploy and scale? (Infrastructure Architect)
- How do we store and manage data consistently? (Data Engineer)
- How do we keep the system secure? (Security Engineer)
- How do we build consistent APIs and observe the system? (Platform Engineer)

See DEC-037 for full rationale.

---

## Consolidation Themes

The Consolidator groups issues by these Foundations-specific themes (aligned with guide sections):

- Technology Choices
- Architecture Patterns
- Authentication & Authorization
- Data Conventions
- API Conventions
- Error Handling
- Logging & Observability
- Security Baseline
- Testing Conventions
- Deployment & Infrastructure

---

## File Paths

**Stage guide:** `guides/03-foundations-guide.md`

**Agent prompts:**
```
agents/03-foundations/
├── create/
│   ├── orchestrator.md
│   ├── assessor.md                  # Lightweight technology assessment before generation
│   ├── generator.md
│   └── author.md                    # Applies resolved gap discussions
└── review/
    ├── orchestrator.md
    ├── promoter.md                  # Splits Foundations into spec/decisions/future at exit
    ├── author.md
    ├── consolidator.md
    ├── change-verifier.md
    └── experts/
        ├── infrastructure-architect.md
        ├── data-engineer.md
        ├── security-engineer.md
        └── platform-engineer.md
```

---

## Output Structure

```
system/03-foundations/
├── foundations.md               # Clean current-scope Foundations (created by promoter)
├── decisions.md                 # Design rationale and trade-offs (created by promoter)
├── future.md                    # Deferred items and future considerations (created by promoter)
└── versions/
    ├── deferred-items.md         # Content deferred from upstream stages
    ├── pending-issues.md        # Issues flagged for upstream review
    ├── workflow-state.md        # Current workflow state
    ├── round-0/                 # Create workflow output
    │   ├── 00-assessment.md         # Assessor output (technology assessment)
    │   └── 00-draft-foundations.md  # Generator output (human augments this)
    └── round-N/                 # Review workflow output (round 1, 2, etc.)
        ├── 01-infrastructure-architect.md
        ├── 01-data-engineer.md
        ├── 01-security-engineer.md
        ├── 01-platform-engineer.md
        ├── 02-consolidated-issues.md
        ├── 03-issues-discussion.md   # Inline discussions happen here
        ├── 04-author-output.md
        ├── 05-updated-foundations.md
        └── 06-alignment-report.md
```

**Promotion**: At exit, the Foundations Promoter splits the final reviewed document into three files. `foundations.md` is the clean current-scope spec consumed by downstream stages. `decisions.md` captures design rationale and trade-offs for reference. `future.md` captures deferred items and open questions. This matches the Components stage split pattern (see DEC-072).

**Downstream deferred items (for Foundations content that's too detailed):**
- `system/04-architecture/versions/deferred-items.md` - System decomposition, component boundaries
- `system/05-components/versions/deferred-items.md` - Implementation details, specific configurations

---

## Invocation

**Create Foundations:**
```
Read the Foundations creation orchestrator at:
agents/03-foundations/create/orchestrator.md

Then create Foundations from:
- PRD: system/02-prd/prd.md

Start the creation workflow.
```

The generator accepts an optional brief at `system/03-foundations/brief.md`. If present, the brief's settled decisions are incorporated directly rather than being marked as gaps. The brief can be structured (matching guide sections), a flat list of decisions, or freeform prose. See DEC-073.

**Review Foundations:**
```
Read the Foundations review orchestrator at:
agents/03-foundations/review/orchestrator.md

Then run the review workflow for:
- Foundations: system/03-foundations/foundations.md
- PRD: system/02-prd/prd.md

Start or resume the review.
```

---

## Custom Create Workflow

Foundations uses a custom create workflow with an Assess step and a structured gap discussion loop, rather than the generic Setup → Generate → Report flow.

**Flow:** Setup → **Assess** → [Human checkpoint] → Generate → Gap Format → Gap Analyse → [Human checkpoint: gap discussion] → Author → Promote

**Assess step:** The Assessor reads the PRD, Foundations guide, deferred items, and brief (if any). For each technology category, it evaluates viable options against PRD constraints, identifies coupled decisions, and presents a structured assessment to the human for directional preferences. The human's preferences then guide the Generator, producing better first-draft proposals and fewer gaps.

**Gap discussion:** After generation, gaps are extracted, formatted, and analysed by Gap Analyst agents (with options, trade-offs, and recommendations). The human reviews proposals inline and discusses unresolved items with Discussion Facilitator agents. Once all gaps are resolved, the Author applies decisions to produce the final draft.

This is a single-round workflow (no multi-round exploration loop). The assessment step serves the same purpose as the exploration phase in Blueprint/PRD — surfacing trade-offs and collecting human direction before generation — but in a lighter-weight form appropriate for technology selection decisions.

---

## Foundations-Specific Considerations

### Level Calibration

Foundations sits between PRD (business requirements) and Architecture Overview (system decomposition). Common level violations:

| Appropriate (Foundations) | Too Strategic (belongs in PRD) | Too Detailed (defer downstream) |
|--------------------------|-------------------------------|-------------------------------|
| "PostgreSQL for relational data" | "GDPR compliance required" | "users table schema" |
| "IAP for authentication" | "Secure authentication needed" | "Session timeout: 24 hours" (Architecture) |
| "REST with JSON" | "API needed for mobile" | "GET /events endpoint contract" |
| "Structured JSON logging" | "Auditable operations" | "90-day log retention" (Architecture) |
| "UUIDs for IDs" | "Unique identifiers needed" | "UUID generation in UserService" |

Foundations follows two Scope Principles (see `guides/03-foundations-guide.md`): **selections, not configuration** (name technologies and approaches, not specific timeout values, retention periods, instance counts, or header values) and **cross-cutting, not component-specific** (every decision must apply to multiple components — if it affects only one component, it belongs in that component's spec).

### PRD Alignment

Foundations must implement PRD constraints without contradicting them. The Alignment Verifier (in Review workflow) checks for:
- **CONTRADICTION**: Foundations conflicts with PRD requirement
- **CONSTRAINT_VIOLATION**: Foundations violates PRD constraint
- **CAPABILITY_GAP**: Foundations choice can't support PRD capability
- **AMBIGUOUS**: Unclear if technical choice supports requirement

If discrepancies are found, they're resolved via:
- **FIX_NEW**: Update Foundations to support PRD
- **FIX_SOURCE**: Log issue to PRD's pending-issues.md
- **NOT_A_CONFLICT**: Document explanation
- **INTENTIONAL**: Document reasoning in Foundations with source reference

### Living Document

Unlike Blueprint and PRD which stabilize, Foundations grows:

1. **Initial version** created after PRD, before Architecture Overview
2. **Updated during Architecture Overview** as system-wide decisions emerge
3. **Updated during Component Specs** as patterns are refined
4. **Updated during implementation** as reality informs decisions

When updating Foundations:
- Add the new decision to the appropriate section
- Note the date and context
- If changing an existing decision, explain why and add source reference

