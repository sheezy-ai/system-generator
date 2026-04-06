# Deferred Items File Format

This document defines the format for `deferred-items.md` files, which hold content that was identified at one stage but belongs at a downstream stage.

## File Location

Stages 02-05 each have a deferred-items.md file in versions/:
- `system/02-prd/versions/deferred-items.md`
- `system/03-foundations/versions/deferred-items.md`
- `system/04-architecture/versions/deferred-items.md`
- `system/05-components/versions/deferred-items.md`

Note: Blueprint has no deferred items file (nothing upstream to defer from). Stages 06-12 are automated pipelines and don't use deferred items.

## Who Writes

- **Generator** defers content from concept/upstream documents during Step 0 (pre-processing)
- **Scope Filter** defers content from expert gaps/issues that belong downstream
- **Scope Filter** (classify_discussions mode) defers DOWNSTREAM discussions

## Who Reads

- **Orchestrator** (Step 0) validates deferred items when downstream stage starts
- **Generator** (downstream stage) reads validated items as input
- **Human** resolves deferred discussions before workflow proceeds

---

## Item Types

| Type | Source | Description |
|------|--------|-------------|
| GAP | Create workflow Scope Filter | Missing information that belongs at this stage |
| ISSUE | Review workflow Scope Filter | Problem identified that belongs at this stage |
| DISCUSSION | Scope Filter (classify_discussions) | Topic requiring back-and-forth before resolution |

Gaps and issues are addressed by the Generator. Discussions require human resolution.

---

## Validation Status

When a downstream stage starts (Step 0: Deferred Items Intake), deferred items are validated against the final upstream document to check if they're still relevant.

| Status | Meaning | Action |
|--------|---------|--------|
| PENDING | Not yet validated (default when deferred) | Will be validated at Step 0 |
| STILL_RELEVANT | Topic not addressed in final upstream output | Process at this stage |
| PARTIALLY_ADDRESSED | Topic touched but not fully resolved upstream | Process with context |
| RESOLVED_UPSTREAM | Topic fully addressed in final upstream output | Close, don't surface |

---

## File Format

```markdown
# Deferred Items: [Stage Name]

Content deferred here from upstream stages for consideration when creating this stage's document.

---

## Summary

| Source Stage | Gaps | Issues | Discussions |
|--------------|------|--------|-------------|
| Blueprint | [N] | [N] | [N] |
| PRD | [N] | [N] | [N] |
| ... | ... | ... | ... |

---

## Gaps

### From [Source Stage] Create - [Date]

**Source**: [original file path]
**Deferred by**: Scope Filter
**Validation**: PENDING | STILL_RELEVANT | PARTIALLY_ADDRESSED | RESOLVED_UPSTREAM

#### [GAP-ID]: [Summary]

**Original Context**: [Which expert raised this and why]

[Full item content]

**Why Deferred**: [Brief explanation]

---

## Issues

### From [Source Stage] Review - [Date]

**Source**: [original file path]
**Deferred by**: Scope Filter
**Validation**: PENDING | STILL_RELEVANT | PARTIALLY_ADDRESSED | RESOLVED_UPSTREAM

#### [ISS-ID]: [Summary]

**Original Context**: [Which expert raised this and why]

[Full item content]

**Why Deferred**: [Brief explanation]

---

## Discussions

### From [Source Stage] [Create/Review] - [Date]

**Source**: [original file path]
**Deferred by**: Scope Filter
**Validation**: PENDING | STILL_RELEVANT | PARTIALLY_ADDRESSED | RESOLVED_UPSTREAM

#### [DISC-ID]: [Topic]

**Original Context**: [Which gap raised this]

[Discussion topic description]

**Why Deferred**: [Brief explanation]

---
```

---

## Field Definitions

| Field | Description |
|-------|-------------|
| **Source** | File path where this content originated |
| **Deferred by** | Which agent deferred this (Generator or Scope Filter) |
| **Validation** | Current validation status (PENDING, STILL_RELEVANT, PARTIALLY_ADDRESSED, RESOLVED_UPSTREAM) |
| **ITEM-ID** | GAP-XXX, ISS-XXX, or DISC-XXX depending on type |
| **Summary/Topic** | Brief description of the content |
| **Original Context** | Why this was raised and by whom |
| **Why Deferred** | Explanation of why it belongs at this stage, not the source stage |

---

## Deferral Destinations

Content flows downstream only:

| From | Can Defer To |
|------|-------------|
| Blueprint | PRD, Foundations, Architecture, Specs |
| PRD | Foundations, Architecture, Specs |
| Foundations | Architecture, Specs |
| Architecture | Specs |
| Specs | (none - lowest level) |

---

## Content Types by Destination

**PRD deferred items receives:**
- Feature details, user stories
- UI/UX specifics
- Detailed user journeys

**Foundations deferred items receives:**
- Technology choices
- Architectural principles
- Infrastructure decisions

**Architecture deferred items receives:**
- System decomposition details
- Component boundaries
- Integration patterns

**Specs deferred items receives:**
- Data models, schemas
- API contracts
- Implementation details

---

## Workflow Consumption

### Step 0: Deferred Items Intake (Orchestrator)

Before Step 1 begins, the orchestrator:

1. Read the deferred items for this stage
2. Read final upstream document(s)
3. For each PENDING item, validate against upstream output
4. Update validation status (STILL_RELEVANT, PARTIALLY_ADDRESSED, or RESOLVED_UPSTREAM)
5. Route validated items:
   - STILL_RELEVANT/PARTIALLY_ADDRESSED gaps/issues -> pass to Generator
   - STILL_RELEVANT/PARTIALLY_ADDRESSED discussions -> create discussion docs, pause for human
   - RESOLVED_UPSTREAM -> mark closed, don't surface

### Generator Consumption

When Generator creates a new stage's document, it receives validated gaps/issues and should:

1. Review each validated item
2. Ensure draft addresses these topics (they were explicitly identified as belonging here)
3. Mark as gaps if full information isn't available
4. Items incorporated are marked as addressed in deferred items file

---

## Example

```markdown
# Deferred Items: Foundations

Content deferred here from upstream stages for consideration when creating this stage's document.

---

## Summary

| Source Stage | Gaps | Issues | Discussions |
|--------------|------|--------|-------------|
| Blueprint | 2 | 0 | 0 |
| PRD | 0 | 1 | 1 |

---

## Gaps

### From Blueprint Create - 2025-12-10

**Source**: system/01-blueprint/versions/round-1-create/02-consolidated-issues.md
**Deferred by**: Scope Filter
**Validation**: STILL_RELEVANT

#### GAP-OPS-003: Database scalability concerns

**Original Context**: Operator expert raised concern about data volume handling

The concept mentions "millions of events" but doesn't specify database approach. What database technology will handle this scale?

**Why Deferred**: Database technology choice is a Foundations decision, not Blueprint-level strategy.

---

### From Blueprint Create - 2025-12-10

**Source**: system/01-blueprint/versions/round-1-create/02-consolidated-issues.md
**Deferred by**: Scope Filter
**Validation**: RESOLVED_UPSTREAM

#### GAP-STRAT-004: API versioning approach

**Original Context**: Strategist noted need for API stability for partners

How will API versions be managed for partner integrations?

**Why Deferred**: API versioning is a technical convention belonging in Foundations.

**Resolution**: Addressed in final Blueprint under Technical Principles section.

---

## Issues

### From PRD Review - 2025-12-11

**Source**: system/02-prd/versions/round-1/03-issues-discussion.md
**Deferred by**: Scope Filter
**Validation**: STILL_RELEVANT

#### ISS-TECH-002: Authentication token lifetime

**Original Context**: Technical feasibility concern from Operator

PRD requires "secure authentication" but doesn't specify token handling. What's the session/token lifetime policy?

**Why Deferred**: Token lifetime is a security baseline decision for Foundations.

---

## Discussions

### From PRD Create - 2025-12-10

**Source**: system/02-prd/versions/round-1-create/03-issues-discussion.md
**Deferred by**: Scope Filter
**Validation**: PARTIALLY_ADDRESSED

#### DISC-001: Authentication approach - OAuth vs sessions

**Original Context**: GAP-012 response marked for discussion

PRD requires user authentication but technology choice belongs in Foundations. Need to decide OAuth, session-based, or JWT approach.

**Why Deferred**: Authentication mechanism is a Foundations technology decision.

**Note**: PRD now specifies "token-based auth required" but specific mechanism still needs resolution.

---
```
