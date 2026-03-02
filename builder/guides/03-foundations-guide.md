# Foundations Guide

## Purpose

Foundations captures the shared technical decisions and conventions that apply across all components. These are decisions that:

- Are expensive to change once implementation starts
- Affect multiple components
- Need consistency across the system
- Aren't specific to any single component

A good Foundations document prevents every Tech Spec from re-asking the same questions and ensures consistency across the system.

---

## Scope Boundary

Foundations answers **"what tools and patterns"** not **"how they're configured"**.

| Belongs in Foundations | Belongs Elsewhere |
|------------------------|-------------------|
| "We use PostgreSQL" | Connection pool sizes (Component Specs) |
| "We use IAP for authentication" | Session timeout values (Architecture) |
| "We use Cloud Logging" | Log retention periods (Architecture) |
| "We use pytest for testing" | Coverage percentage targets (Component Specs) |

**The test:** If you're specifying a number, duration, or size, it's probably configuration, not a foundational decision.

### Scope Principles

Foundations follows two scope principles:

1. **Selections, not configuration** — Foundations names technologies and defines approaches. Specific values (timeouts, retention periods, instance counts, coverage targets, header values) belong in Architecture Overview or Component Specs. The scope boundary test above applies: numbers, durations, and sizes are configuration.

2. **Cross-cutting, not component-specific** — Every Foundations decision must apply to multiple components. If a decision affects only one component (or describes a data flow between specific named components), it belongs in that component's spec or in Architecture Overview. Test: would a developer of a *different* component need this information?

| Appropriate (Foundations) | Too Specific (belongs downstream) |
|--------------------------|----------------------------------|
| "We use structured JSON logging" | Log retention period of 90 days (Architecture) |
| "OAuth for email access" | Token lifecycle, monitoring baselines, revocation procedures (Component Specs) |
| "Soft delete for audit trail" | Cascade semantics between specific entities (Architecture) |
| "Security headers required on all responses" | Exact CSP/HSTS header values (Architecture or Component Specs) |
| "Exponential backoff for transient failures" | Per-agent timeout values of 60s/30s (Component Specs) |

---

## What Foundations Should Contain

### 1. Technology Choices

**Questions to answer:**
- What programming language(s) and frameworks?
- What database(s) and why?
- What cloud provider and services?
- What message broker or event system (if any)?

**Level of detail:** Named technologies with brief rationale. "PostgreSQL for relational data because [reason]" not just "a database".

---

### 2. Architecture Patterns

**Questions to answer:**
- Monolith, microservices, or modular monolith?
- Synchronous vs asynchronous communication patterns?
- Event-driven, request/response, or hybrid?
- How are components deployed (containers, serverless, VMs)?

**Level of detail:** Pattern choices with rationale. Not implementation details.

---

### 3. Authentication & Authorization

**Questions to answer:**
- What authentication approach and provider?
- What authorization model (RBAC, ABAC, etc.)?

**Level of detail:** Technology selection and approach only. Session timeout values, token lifetimes, rotation schedules, and provider-specific configuration belong in Architecture Overview or Component Specs.

---

### 4. Data Conventions

**Questions to answer:**
- Naming conventions (snake_case, camelCase)?
- Standard field types (UUIDs vs integers for IDs, timestamp formats)?
- Soft delete vs hard delete?
- Audit fields (created_at, updated_at, created_by)?

**Level of detail:** Concrete conventions that all components follow.

---

### 5. API Conventions

**Questions to answer:**
- REST, GraphQL, gRPC, or mix?
- Versioning strategy?
- Standard error response format?
- Pagination approach?
- Rate limiting approach?

**Level of detail:** Patterns and formats that all APIs follow.

---

### 6. Error Handling

**Questions to answer:**
- How are errors categorized?
- What information is exposed to clients vs logged internally?
- How are errors propagated across component boundaries?
- Retry policies for transient failures?

**Level of detail:** Patterns and conventions, not component-specific handling. Specific timeout values and retry counts belong in Component Specs.

---

### 7. Logging & Observability

**Questions to answer:**
- What logging and metrics stack?
- What correlation/trace ID approach?

**Level of detail:** Tool selection and cross-cutting patterns (structured format, correlation ID approach). Log levels, retention periods, metrics definitions, and alerting thresholds belong in Architecture Overview.

---

### 8. Security Baseline

**Questions to answer:**
- How are secrets managed?
- Encryption at rest and in transit?
- Input validation approach?
- Security headers and CORS policy?
- Dependency vulnerability scanning?

**Level of detail:** Non-negotiable security requirements that apply to all components. Specific header values, provider-specific configuration (token lifecycles, monitoring baselines), and component-specific security controls belong in Architecture Overview or Component Specs.

---

### 9. Testing Conventions

**Questions to answer:**
- What test frameworks (unit, integration, contract)?
- What test data management approach?

**Level of detail:** Framework selection and cross-cutting patterns. Coverage targets and component-specific test strategies belong in Component Specs.

---

### 10. Deployment & Infrastructure

**Questions to answer:**
- What CI/CD platform?
- What infrastructure-as-code tooling?
- What feature flag system (if any)?

**Level of detail:** Platform and tooling selection. Environment configuration, resource sizing, backup retention periods, and deployment specifics belong in Architecture Overview.

---

### 11. Open Questions

**Questions to answer:**
- What foundational decisions are deferred?
- What depends on learning from implementation?
- What needs more research?

**Level of detail:** Explicit acknowledgment of unknowns.

---

## What Should NOT Be in Foundations

| Out of Scope | Where It Belongs |
|--------------|------------------|
| Component-specific decisions | Component Specs |
| Business requirements | PRD |
| Strategic direction | Blueprint |
| Detailed schemas | Component Specs |
| Operational runbooks | Operational docs |
| One-off exceptions | Component Specs (with rationale) |

**The test:** If the decision only affects one component, it probably belongs in that component's spec, not Foundations.

---

## Relationship to Other Documents

| Document | Relationship |
|----------|-------------|
| PRD | Foundations implements PRD constraints (e.g., "GDPR compliance" in PRD → "soft delete for audit trail" in Foundations) |
| Architecture Overview | Consumes Foundations to inform component decomposition |
| Component Specs | References Foundations for conventions, only documents deviations |
| Decisions Log | Major Foundations decisions should be recorded in Decisions Log with rationale |

---

## Foundations is a Living Document

Unlike PRD and Blueprint which stabilize, Foundations grows:

1. **Initial version** created after PRD, before Architecture Overview
2. **Updated during Architecture Overview** as system-wide decisions emerge
3. **Updated during Component Specs** as patterns are refined
4. **Updated during implementation** as reality informs decisions

When updating Foundations:
- Add the new decision to the appropriate section
- Note the date and context
- If changing an existing decision, explain why

---

## Decision Source References

Decisions in Foundations (technology choices, patterns, conventions) should include source references when they originate from review discussions:

**Format:**
```markdown
**Decision: [Brief title]**
- Rationale: [Why this decision was made]
- Source: Round N: ISSUE-ID
```

The source reference enables tracing back to the originating discussion in `versions/round-N/03-issues-discussion.md`.

---

## Tone and Style

- **Prescriptive**: "We use X" not "consider using X"
- **Brief rationale**: One sentence on why, not a full analysis
- **Concrete**: Specific technologies and patterns, not abstract principles
- **Consistent**: Same format for each section

