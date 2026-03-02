# Component Spec Guide

## Purpose

A Component Spec defines **how** a specific component is implemented. It provides enough detail for an engineer to build the component, understand its interfaces, and know how it integrates with the rest of the system.

A good Component Spec allows someone to implement the component without guessing, while remaining focused on the "what" and "how" rather than prescribing every line of code.

---

## Scope Principles

These principles govern the abstraction level of every section.

### Contracts, not code

Specs define **what** to build through contracts and constraints. They do not prescribe **how** to code it.

| Spec territory (yes) | Code territory (no) |
|----------------------|---------------------|
| Data model tables with columns, types, constraints | Python dataclass definitions |
| Interface descriptions: purpose, inputs, outputs, errors | Function signatures with imports and docstrings |
| Behaviour scenarios in prose | Algorithm implementations in pseudo-code or Python |
| Error categories and recovery approach | Exception class hierarchies or try/except blocks |

### Reference, don't restate

When Foundations defines a system-wide convention (error envelope format, security headers, retry policies, log format, correlation IDs), the spec should reference it, not reproduce it. Only add what is specific to this component.

- Good: "Error responses follow Foundations §Error Handling. Component-specific errors: ..."
- Bad: Copying the Foundations error envelope JSON example and HTTP status code table into the spec.

### No Implementation Reference sections

Code belongs in the codebase, not the spec. Do not include sections that provide complete or partial code implementations (e.g., "Implementation Reference", "Code Examples", "Sample Implementation").

---

## What the Component Spec Should Contain

### 1. Overview

**Questions to answer:**
- What is this component's purpose?
- What problem does it solve within the system?
- How does it fit into the overall architecture?

**Level of detail:** Brief context-setting. Reference the Architecture Overview for broader context.

---

### 2. Scope

**Questions to answer:**
- What is in scope for this component?
- What is explicitly out of scope?
- What are the boundaries with adjacent components?

**Level of detail:** Clear boundaries. "This component handles X. It does NOT handle Y - that's Component Z's responsibility."

---

### 3. Interfaces

**Questions to answer:**
- What APIs does this component expose?
- What events/messages does it produce or consume?
- What are the request/response formats?

**Level of detail:** Specific enough to implement against. Include endpoints, methods, payload schemas, error responses.

Example:
```
POST /events
Request: { title: string, date: ISO8601, location: { lat, lng } }
Response: { id: uuid, status: "pending" | "published" }
Errors: 400 (validation), 401 (unauthorized), 500 (internal)
```

---

### 4. Data Model

**Questions to answer:**
- What data does this component own? (This is the authoritative schema definition)
- What is the schema/structure?
- What are the key entities and relationships?
- Which other components may read this data?

**Level of detail:** Specific schemas, field types, constraints. This is implementation detail - be precise. Other components that depend on this data will reference this section as the source of truth.

Example:
```
## Data Model

### events table (Read by: Booking, Notification)
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK | Event identifier |
| title | VARCHAR(255) | NOT NULL | Event title |
| status | ENUM | NOT NULL | draft, published, cancelled |
...
```

---

### 5. Behaviour

**Questions to answer:**
- What does this component do in various scenarios?
- What is the happy path?
- How are edge cases and errors handled?

**Level of detail:** Describe the logic and flow. Use scenarios or pseudo-code where helpful. Not line-by-line code, but clear enough to implement.

---

### 6. Dependencies

**Questions to answer:**
- What other components does this depend on?
- What data from other components does this component read?
- What external services are required?
- What happens if dependencies are unavailable?

**Level of detail:** List dependencies with their purpose. For data dependencies, reference the owning component's Data Model section explicitly. Describe failure handling approach.

Example:
```
## Dependencies

### Component Dependencies
| Component | Purpose | Data Referenced |
|-----------|---------|-----------------|
| Event Management | Validate event exists for booking | events table (§4 Data Model) |
| User Service | Get organizer details | users table (§4 Data Model) |

### External Dependencies
| Service | Purpose | Failure Handling |
|---------|---------|------------------|
| Stripe API | Payment processing | Queue for retry, notify user of delay |
```

---

### 7. Integration

**Questions to answer:**
- How does this component integrate with others?
- What contracts must it honor?
- What data does it receive from / send to other components?

**Level of detail:** Specific integration points with reference to other specs where relevant.

---

### 8. Error Handling

**Questions to answer:**
- What errors can occur?
- How are they communicated to callers?
- What retry/recovery logic is needed?

**Level of detail:** Component-specific error scenarios, their severity, and recovery approach. Defer to Foundations for error envelope format, standard HTTP error categories, and retry policy mechanics. Focus on what is unique to this component.

---

### 9. Observability

**Questions to answer:**
- What are the key operational indicators for this component?
- What business-significant events should be logged?
- What component-specific data must be excluded from logs?

**Level of detail:** Key indicators (what healthy/unhealthy looks like), business-significant log events and their levels, and component-specific log sanitization rules. Defer to Foundations for log format, log levels, correlation IDs, metrics collection mechanism, and alerting thresholds.

---

### 10. Security Considerations

**Questions to answer:**
- What authentication/authorization is required?
- What sensitive data is handled?
- What security controls are needed?

**Level of detail:** Specific requirements. "API requires JWT with 'events:write' scope." Not generic "must be secure." Defer to Foundations for security headers, CSRF policy, and encryption standards. Focus on component-specific auth requirements, sensitive data classification, and authorization rules.

---

### 11. Testing Approach

**Questions to answer:**
- How will this component be tested?
- What are the key test scenarios?
- What test infrastructure is needed?

**Level of detail:** Testing strategy, not individual test cases. Unit, integration, contract testing approach.

---

### 12. Open Questions

**Questions to answer:**
- What decisions are deferred to implementation?
- What needs to be resolved during development?
- What assumptions are being made?

**Level of detail:** Explicit list of unknowns and assumptions.

---

### 13. Related Decisions

**Questions to answer:**
- What upstream decisions shaped this component's design?
- Where can someone find the rationale for non-obvious choices?

**Level of detail:** A table linking to decision log entries or review discussions. Brief enough to scan, with pointers for those who want context.

**Format for inline decisions:**
```markdown
**Decision: [Brief title]**
- Rationale: [Why this decision was made]
- Source: Round N: ISSUE-ID
```

The source reference enables tracing back to the originating discussion in `versions/round-N/03-issues-discussion.md`.

**Format for related decisions table:**
```markdown
## Related Decisions

| Decision | Summary | Source |
|----------|---------|--------|
| Email normalization | Lowercase at application layer | Round 2: CLU-003 |
| Async messaging | Queue between Ingestion and Store | Round 1: ARCH-034 |
```

**Why this section exists:**
- Engineers can validate that design choices are intentional, not errors
- Context is available on demand without cluttering the spec body
- Decisions are traceable from implementation back to rationale

**Promotion note:** At promotion, inline decisions and the Related Decisions table are extracted into a separate `decisions/[component].md` file. The promoted implementation spec retains a reference to this file but not the full decision content.

---

### Content That Gets Extracted at Promotion

During review, specs accumulate content that is valuable but not part of the final implementation spec. The Spec Promoter extracts this into separate files:

| Content Pattern | Extracted To | Example |
|----------------|--------------|---------|
| `**Decision: [title]**` blocks | `decisions/[component].md` | Design rationale from review discussions |
| `Phase 1b+` / growth path notes | `future/[component].md` | Deferred features, scaling considerations |
| Related Decisions table | `decisions/[component].md` | Decision index with source references |
| Open Questions (resolved) | Removed | Questions answered during review |

The promoted implementation spec (`specs/[component].md`) contains only what an engineer needs to build the component.

---

## What Should NOT Be in the Component Spec

| Out of Scope | Where It Belongs |
|--------------|------------------|
| Business requirements | PRD |
| System-wide architecture | Architecture Overview |
| Other components' details | Their own specs |
| Deployment/infrastructure | Ops docs or Foundations |
| User stories | PRD/Stories |
| Code | The codebase |

**The test:** If the content isn't about this specific component's implementation, it probably doesn't belong here.

**Note:** The Issue Router uses this table during review (Step 3) to decide whether issues should be escalated upstream or kept at spec level.

---

## Relationship to Architecture Overview

The Component Spec implements what the Architecture Overview describes:

| Architecture Overview Says | Component Spec Provides |
|---------------------------|-------------------|
| "Event Ingestion Service validates events" | Validation rules, error responses, endpoint spec |
| "Async messaging between components" | Message schemas, queue names, consumer behaviour |
| "Read/write separation" | Write path details in one spec, read path in another |

The Architecture Overview says "this component exists and does X." The Component Spec says "here's exactly how it does X."

---

## Tone and Style

- **Precise**: Specific enough to implement without guessing
- **Complete**: Cover all aspects of the component
- **Focused**: Only this component, not the whole system
- **Honest**: Acknowledge unknowns rather than pretending certainty

---

## Common Mistakes

**Too vague**: "The service processes events" doesn't tell an engineer what to build. Be specific.

**Too broad**: Including details about other components. Stay in scope.

**Missing interfaces**: Describing behaviour without specifying the actual API/contract.

**No error handling**: Only describing the happy path. Real systems have errors.

**Assumed context**: Not explaining how this component fits into the system. Reference the Architecture Overview.

**Over-specification**: Including implementation details that belong in the codebase, not the spec. Common forms:
- Python/SQL code blocks where tables or prose descriptions would suffice (dataclass definitions, function signatures with imports, ORM calls, algorithm implementations)
- Restating Foundations conventions (error envelope format, security headers, retry policies, correlation IDs) instead of referencing the relevant Foundations section
- "Implementation Reference" sections containing complete or partial code
- Framework-specific annotations (Django `on_delete`, DRF serializer details, Pydantic `Config` classes) instead of schema-level constraint descriptions

See [Scope Principles](#scope-principles) above.

