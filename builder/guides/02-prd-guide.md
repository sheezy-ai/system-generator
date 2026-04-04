# PRD Guide

## Purpose

A PRD (Product Requirements Document) defines **what** we're building in a specific phase. It translates the Blueprint's strategic vision into concrete capabilities, success criteria, and scope boundaries for one phase of development.

A good PRD allows someone to understand what the phase delivers, how success will be measured, and what's explicitly in or out of scope - without prescribing how to build it.

---

## What the PRD Should Contain

### 1. Phase Goal

**Questions to answer:**
- What is the primary objective of this phase?
- How does this phase advance the Blueprint's vision?
- What hypothesis are we testing or validating?

**Level of detail:** One or two paragraphs. Clear connection to Blueprint. Should answer "why this phase matters."

---

### 2. Success Criteria

**Questions to answer:**
- How do we know if this phase succeeded?
- What are the measurable outcomes we're targeting?
- What quantitative and qualitative signals matter?

**Level of detail:** Specific, measurable criteria. Include targets where known (e.g., "50+ events published", "5 users report finding useful events"). Avoid vague criteria like "users are satisfied."

---

### 3. Capabilities

**Questions to answer:**
- What can users do when this phase is complete?
- What functionality is being delivered?
- What user workflows are enabled?

**Level of detail:** Describe capabilities from the user's perspective. "Users can filter events by date" not "implement date filtering with PostgreSQL range queries." Focus on *what*, not *how*.

---

### 4. Scope: In and Out

**Questions to answer:**
- What is explicitly included in this phase?
- What is explicitly excluded (deferred to later phases)?
- What's the boundary between this phase and the next?

**Level of detail:** Be explicit about boundaries. List what's out as clearly as what's in. This prevents scope creep and manages expectations.

---

### 5. Conceptual Data Model

**Questions to answer:**
- What are the key entities/concepts in this phase?
- How do they relate to each other at a conceptual level?
- What information needs to be captured?

**Level of detail:** Entity names and relationships only. "Events have a venue and categories" not "events table with venue_id foreign key and event_categories junction table." Schema design belongs in Tech Spec.

---

### 6. Key Decisions

**Questions to answer:**
- What product decisions have been made for this phase?
- What trade-offs were considered?
- What constraints apply?

**Level of detail:** Document decisions that affect scope or capabilities. Include rationale. This creates a record and prevents re-litigating settled questions.

**Format for decisions:**
```markdown
**Decision: [Brief title]**
- Rationale: [Why this decision was made]
- Source: Round N: ISSUE-ID
```

The source reference enables tracing back to the originating discussion in `versions/round-N/03-issues-discussion.md`.

---

### 7. User Workflows

**Questions to answer:**
- What are the primary user journeys in this phase?
- What steps do users take to accomplish their goals?
- What are the entry and exit points?

**Level of detail:** High-level workflow descriptions. "User searches for events → views results → selects event → sees details" not wireframes or UI specifications.

---

### 8. Integration Points

**Questions to answer:**
- What external systems does this phase interact with?
- What data sources are consumed?
- What outputs are produced for other systems?

**Level of detail:** Identify integration points and their purpose. "Consumes event data from email extraction pipeline" not "calls /api/events endpoint with OAuth2 bearer token."

---

### 9. Compliance and Constraints

**Questions to answer:**
- What regulatory or compliance requirements apply?
- What security requirements must be met?
- What operational constraints exist?

**Level of detail:** Requirements level. "Must comply with GDPR data retention" not "implement 30-day TTL on user_sessions table." Implementation details belong in Tech Spec.

---

### 10. Risks and Dependencies

**Questions to answer:**
- What could prevent this phase from succeeding?
- What dependencies exist on other work or external factors?
- What assumptions are we making?

**Level of detail:** Identify risks and dependencies relevant to this phase. Phase-level concerns, not implementation risks (those belong in Tech Spec).

---

### 11. Definition of Done

**Questions to answer:**
- What must be true for this phase to be considered complete?
- What quality bar must be met?
- What operational readiness is required?

**Level of detail:** Checklist of completion criteria. "Core user journeys functional", "Success metrics can be measured", "System handles expected load."

**Sufficient when:** Every consumer-facing capability, admin capability, and operational requirement defined in the Capabilities section (§3) has a corresponding checklist item in the Definition of Done. A single checklist item may cover a tightly related group, but must not bundle unrelated capabilities behind a generic section reference. The test: someone reading only the DoD can identify every capability that must be built and verified, without needing to read §3 to discover unlisted items.

---

## What Should NOT Be in the PRD

| Out of Scope | Where It Belongs |
|--------------|------------------|
| Technical architecture | Component Specs |
| Database schemas | Component Specs |
| API contracts | Component Specs |
| Implementation approach | Component Specs |
| UI/UX designs | Design Docs |
| Detailed user journeys with screens | Design Docs |
| Operational procedures | Ops Docs |
| Monitoring dashboards | Ops Docs |
| Timelines and estimates | Project Planning |
| Story breakdowns | Tasks |

**The test:** If the content specifies *how* something is built rather than *what* is delivered, it probably doesn't belong in the PRD.

---

## Relationship to Blueprint

The PRD should:
- **Implement** a phase from the Blueprint's roadmap
- **Align** with the Blueprint's vision and principles
- **Reference** the Blueprint for strategic context
- **Not contradict** the Blueprint's direction

If the PRD needs to deviate from the Blueprint, that deviation should be explicit and justified, and may indicate the Blueprint needs updating.

---

## Tone and Style

- **Clear and specific:** Unambiguous about what's being delivered
- **User-focused:** Describe capabilities from user perspective
- **Bounded:** Explicit about what's in and out of scope
- **Testable:** Success criteria that can actually be measured
- **Stable:** Should not change frequently during a phase; if it does, scope is unclear

---

## Common Mistakes

**Too detailed:** Including implementation specifics, database schemas, or technical approaches. This creates confusion about what's requirement vs design.

**Too vague:** Capabilities like "good event discovery" that can't be objectively evaluated. Be specific about what users can do.

**No boundaries:** Failing to explicitly state what's out of scope. This invites scope creep and unclear expectations.

**Unmeasurable success:** Success criteria that can't actually be measured or are purely subjective.

**Blueprint drift:** PRD that doesn't align with or contradicts the Blueprint without acknowledging the deviation.

**Implementation leakage:** Specifying how something should be built rather than what it should do.

