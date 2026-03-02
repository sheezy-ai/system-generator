# Architecture Overview Guide

## Purpose

The Architecture Overview is the bridge between PRD and Technical Specs. It answers **how** the system is decomposed into components, **what** data flows between them, and **which** technical specs need to be written.

A good Architecture Overview allows someone to understand the system structure, identify the major building blocks, and know what specs are needed - without diving into implementation detail of any single component.

---

## Scope Principles

The Architecture Overview follows two scope principles:

1. **Structure, not implementation** — Architecture defines what components exist, what they're responsible for, and how they relate. Internal behaviour (capability lists, algorithms, threshold values, database field names, entry point commands, SQL queries, specific backoff values) belongs in Component Specs. Each component gets a one-sentence responsibility description, not a feature list.

2. **Reference, don't restate** — When Foundations defines a convention (retry policies, secrets management, security headers, log format), reference it (e.g., "per Foundations §6"). When a detail will be defined in a Component Spec, note the deferral rather than pre-defining the content.

| Appropriate (Architecture) | Too Detailed (belongs in Component Specs) |
|----------------------------|------------------------------------------|
| "Admin Service: manages sources, curates events, monitors operations" | 15-item capability list with specific workflows |
| "Data Processing Job: batch pipeline for email ingestion and extraction" | Cloud Run Job timeout of 90 minutes |
| "Async event processing for reliability" | Specific backoff values (1s, 2s, 4s, max 30s) |
| "Quality gate with auto-publish threshold" | Matching algorithm threshold (Levenshtein > 0.85) |
| "Retry policies per Foundations §6" | Restated retry table from Foundations |
| "Secrets managed via GCP Secret Manager per Foundations §8" | Reproduced list of 6 specific secret names |

---

## What the Architecture Overview Should Contain

### 1. System Context

**Questions to answer:**
- What is the system boundary?
- What external systems/users does it interact with?
- What are the key inputs and outputs?

**Level of detail:** A simple context diagram description. Who/what is outside the system, and how do they interact with it at a high level.

---

### 2. Component Decomposition

**Questions to answer:**
- What are the major components/services?
- What is each component's primary responsibility?
- Why this decomposition? (rationale)

**Level of detail:** Name each component, one-sentence description of its responsibility. Not how it works internally — no capability lists, specific workflows, SQL queries, algorithm thresholds, or database field names. Those belong in Component Specs.

Example:
- **Event Ingestion Service**: Receives events from external sources, validates format, queues for processing
- **Event Store**: Persists event data, provides query interface for retrieval
- **Discovery API**: Exposes event search and filtering to clients

---

### 3. Data Flows

**Questions to answer:**
- How does data move between components?
- What are the key data entities?
- Where does data originate and terminate?

**Level of detail:** Describe the primary flows. "User submits event → Ingestion validates → Store persists → Discovery indexes". Not detailed schemas or API contracts.

---

### 4. Integration Points

**Questions to answer:**
- Which components communicate with each other?
- What style of integration? (sync API, async messaging, shared database, etc.)
- What external systems are integrated?

**Level of detail:** Identify the integration style and rationale. Not the specific protocols or message formats - those belong in component specs.

---

### 5. Key Technical Decisions

**Questions to answer:**
- What significant technical choices have been made at the architecture level?
- What patterns are being used? (event-driven, request-response, CQRS, etc.)
- What constraints from the PRD/Blueprint affect architecture?

**Level of detail:** State the decision and brief rationale. Not implementation detail — no specific commands, database flag names, backoff values, or log field structures. Those belong in Component Specs.

**Format for decisions:**
```markdown
**Decision: [Brief title]**
- Rationale: [Why this decision was made]
- Source: Round N: ISSUE-ID
```

The source reference enables tracing back to the originating discussion in `versions/round-N/03-issues-discussion.md`.

Example:
- **Async event processing**: Events queued for reliability; consumers process at their own pace (Source: Round 1: ARCH-003)
- **Read/write separation**: Separate store for writes vs search index for reads (Source: Round 1: ARCH-007)

---

### 6. Component Spec List

**Questions to answer:**
- What technical specs need to be written?
- What is each spec's scope?
- What data does each component own? (authoritative schemas)
- Are there dependencies between specs?

**Level of detail:** A list of spec names with one-line scope description. Include data ownership to establish the order of spec creation - components that own data should be specified before components that depend on that data.

Example:
| Spec | Scope | Data Owned | Dependencies |
|------|-------|------------|--------------|
| Event Ingestion | Receiving, validating, queueing events | events (draft) | None |
| Event Store | Persistence, retrieval, data model | events (published) | Event Ingestion |
| Discovery API | Search, filtering, client interface | None (reads events) | Event Store |

**Why data ownership matters:** Component specs define authoritative schemas for the data they own. Dependent components reference these schemas rather than duplicating them. This means upstream components (data owners) must be specified before their dependents.

---

### 7. Cross-Cutting Concerns

**Questions to answer:**
- How are concerns like auth, logging, monitoring handled?
- Are there shared libraries or infrastructure components?
- What patterns apply across all components?

**Level of detail:** Identify the concerns and reference Foundations for conventions. Do not restate Foundations content (retry policies, secrets lists, security headers). Component-specific concerns (per-stage log fields, pipeline-specific retry behaviour) belong in Component Specs.

---

### 8. Data Contracts

**Questions to answer:**
- What data structures flow between components?
- Who produces each data structure? Who consumes it?
- What is the direction of the contract (consumer defines, producer conforms)?

**Level of detail:** Identify the contracts, producers, and consumers. Not the detailed schemas - those are defined in component specs and captured in the cross-cutting specification.

**Why this matters:** Data contracts establish the integration boundaries between components. The consumer (who stores/uses the data) defines the required schema; the producer (who creates the data) must conform. This drives the order of spec creation and enables contract verification.

Example:
| Contract ID | Name | Consumer | Producer(s) | Description |
|-------------|------|----------|-------------|-------------|
| CTR-001 | extraction_metadata | event-directory | extraction-agent | Extraction artifacts and metadata |
| CTR-002 | paraphrasing_metadata | event-directory | paraphrasing-agent | Paraphrasing output and metadata |
| CTR-003 | quality_metadata | event-directory | quality-gate-module | QG evaluation results |

**Derivation:** Contracts are inferred from component responsibilities and data flows. If Component A "owns" or "stores" data that Component B "produces", that's a contract with A as consumer and B as producer.

**Downstream flow:** These architecture-level contracts feed into the 05-components cross-cutting specification (`specs/cross-cutting.md`), where they are populated with detailed schemas extracted from component specs and verified by the Contract Verifier during each component review round.

---

### 9. Open Questions

**Questions to answer:**
- What architectural decisions are deferred?
- What needs to be resolved before or during spec writing?
- What assumptions are being made?

**Level of detail:** Explicit list of unknowns. Better to acknowledge gaps than pretend certainty.

---

## What Should NOT Be in the Architecture Overview

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

## Relationship to PRD

The Architecture Overview translates PRD capabilities into technical structure:

| PRD Says | Architecture Overview Says |
|----------|---------------------------|
| "Users can discover events" | Discovery API component, Event Store for data |
| "Organisers can create events" | Event Ingestion component, validation flow |
| "System shows recommendations" | Recommendation Service component, data flows from Event Store |

Every PRD capability should map to one or more components. If a capability can't be mapped, the decomposition is incomplete.

---

## Tone and Style

- **Structural, not detailed**: Describe the shape of the system, not the internals
- **Decision-focused**: Explain why this structure, not just what it is
- **Complete but concise**: Cover all major components without exhaustive detail
- **Actionable**: The spec list should be a clear work breakdown

---

## Common Mistakes

**Too detailed**: Including API specs, database schemas, or algorithm details. This belongs in component specs.

**Too vague**: "We'll have some services" isn't a decomposition. Name the components and their responsibilities.

**Missing rationale**: Stating the structure without explaining why. The "why" helps future decisions.

**Incomplete mapping**: PRD capabilities that don't appear in any component. Everything needs a home.

**No spec list**: Describing the architecture without identifying what specs to write. The spec list is a key output.

