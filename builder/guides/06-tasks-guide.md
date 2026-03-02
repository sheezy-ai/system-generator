# Task Guide

## Purpose

A task is a discrete, implementable unit of work. Each task should be:
- **Specific**: Clear what needs to be built
- **Testable**: Has acceptance criteria that can be verified
- **Independent**: Can be completed without waiting for unrelated work (though may have explicit dependencies)
- **Traceable**: Links back to the spec section it implements

---

## Scope Principles

Tasks follow two scope principles:

1. **What, not how** — Tasks describe what to build and acceptance criteria for verifying it. Implementation details (code snippets, algorithm choices, framework-specific patterns) belong to the implementer. The test: if a developer could reasonably implement it a different way and still pass the acceptance criteria, the task is at the right level.

2. **Derive, not invent** — Every task traces to a spec section or source document. Where sources are silent, mark defaults clearly. Design decisions belong in Component Specs; system-wide conventions belong in Foundations.

---

## Task File Structure

Each task file is a single markdown file containing all tasks for one component (or infrastructure). Tasks are grouped by the spec section they implement.

```markdown
# [Component Name] Tasks

**Spec**: [path to component spec]
**Generated**: YYYY-MM-DD
**Status**: DRAFT | APPROVED

---

## Summary

- **Total Tasks**: [N]
- **By Section**:
  - Interfaces: [N]
  - Data Model: [N]
  - Behaviour: [N]
  - ...

---

## Section: [Spec Section Name]

### TASK-001: [Brief descriptive title]

**Spec Reference**: §[section number]
**Status**: PENDING | IN_PROGRESS | DONE
**Depends On**: [TASK-NNN, Component/TASK-NNN, or None]

#### Description

[1-3 sentences describing what needs to be built]

#### Acceptance Criteria

- [ ] [Specific, verifiable criterion]
- [ ] [Another criterion]
- [ ] [...]

#### Notes

[Optional: implementation hints, decisions, or context]

---

### TASK-002: [Next task]
...
```

---

## Task Granularity

### Right-sized tasks

| Too Big | Right Size | Too Small |
|---------|------------|-----------|
| "Implement Event API" | "Implement POST /events endpoint" | "Add title field validation" |
| "Set up database" | "Create events table migration" | "Add id column to events" |
| "Handle errors" | "Implement validation error responses for Event API" | "Return 400 for missing title" |

**Rule of thumb**: A task should take 1-4 hours to implement. If much larger, break it down. If much smaller, combine with related work.

### Grouping related work

Small related items can be combined into one task:

```markdown
### TASK-005: Implement event validation

**Spec Reference**: §3.1.4

#### Acceptance Criteria

- [ ] Validate title is present and ≤255 characters
- [ ] Validate start_date is valid ISO8601 and in future
- [ ] Validate organizer_id exists in users table
- [ ] Return 400 with field-level errors for validation failures
```

### Prerequisite coherence

All acceptance criteria items within a task must share the same prerequisites. If some items can be verified immediately while others require the entire system running, they belong in separate tasks.

**Split when**:
- Some items need only local resources, others need a deployed system
- Some items are first-run verifiable, others require external services to be live
- The task's `Depends On` only covers some items' prerequisites

**Combine when**:
- All items can be verified under the same conditions
- All items share the same dependencies

---

## Writing Acceptance Criteria

Good acceptance criteria are:
- **Observable**: Can be verified without reading code
- **Specific**: No ambiguity about what "done" means
- **Complete**: Cover happy path AND error cases where relevant

### Examples

**Vague** (avoid):
- [ ] Endpoint works correctly
- [ ] Errors are handled

**Specific** (prefer):
- [ ] POST /events returns 201 with created event including generated UUID
- [ ] POST /events returns 400 with `{"errors": [...]}` when title missing
- [ ] POST /events returns 401 when Authorization header missing

---

## Dependencies

### Within a component

Reference by task ID:

```markdown
**Depends On**: TASK-003
```

### Across components

Reference with component prefix:

```markdown
**Depends On**: EventManagement/TASK-001, UserService/TASK-005
```

### On infrastructure

Reference infrastructure tasks:

```markdown
**Depends On**: Infrastructure/TASK-002 (Database setup)
```

### Dependency types

| Type | Meaning | Example |
|------|---------|---------|
| **Hard** | Cannot start until dependency complete | API endpoint depends on database table |
| **Soft** | Can develop in parallel, integrate later | Two endpoints that don't share data |

Only list hard dependencies. Soft dependencies are implicit from the spec.

### Direct vs transitive dependencies

`Depends On` lists only **direct** dependencies — tasks whose output this task's code directly calls, imports, or reads. If Task A calls the quality gate module, and the quality gate module internally calls the geocoding module, Task A depends on quality-gate-module but NOT on geocoding-module.

Transitive (indirect) dependencies — things that must exist for your direct dependencies to work, but that your code never touches — do not belong in `Depends On`. If a transitive dependency is worth noting (e.g., to explain why a failure in a distant component could affect this task), document it in Notes.

---

## Infrastructure Tasks

Infrastructure tasks follow the same format but are grouped by concern rather than spec section:

```markdown
# Infrastructure Tasks

**Sources**:
- Foundations: 03-foundations/foundations.md
- Architecture: 04-architecture/architecture.md
**Generated**: YYYY-MM-DD
**Status**: DRAFT | APPROVED

---

## Database

### TASK-001: Provision PostgreSQL database
...

### TASK-002: Configure connection pooling
...

---

## Messaging

### TASK-003: Create SQS queues for event messaging
...

---

## CI/CD

### TASK-004: Set up GitHub Actions pipeline
...
```

### Infrastructure groupings

Typical sections for infrastructure tasks:
- Database
- Messaging / Event Bus
- CI/CD Pipeline
- Monitoring / Observability
- Secrets Management
- Container / Deployment

---

## Spec Section Coverage

Every spec section should map to at least one task:

| Spec Section | Task Coverage |
|--------------|---------------|
| §3 Interfaces | One task per endpoint (or grouped if simple) |
| §4 Data Model | Migration tasks, typically one per table |
| §5 Behaviour | Business logic tasks, grouped by flow |
| §6 Dependencies | Integration tasks for each dependency |
| §8 Error Handling | Often combined with interface tasks |
| §9 Observability | Logging/metrics tasks if not in infra |
| §10 Security | Auth integration tasks |
| §11 Testing | Test implementation tasks (optional, may be implicit) |

Sections like Overview, Scope, Open Questions don't need direct task coverage.

---

## Data Flow Between Tasks

When one task produces data that another task consumes (credentials, generated values, resource identifiers, configuration), both tasks should document the handoff:

- **Producing task**: State what it outputs and where/how (e.g., "stores database password in Secret Manager as `db-password`")
- **Consuming task**: State where it gets the data and the mechanism (e.g., "reads DSN from Secret Manager secret `db-dsn`")

The mechanism must be explicit — not just "from TASK-003" but how the value moves (Secret Manager, environment variable, Terraform output, etc.).

This is especially important for security-sensitive data (credentials, tokens, keys) where an undocumented flow risks values being written to disk or logs.

---

## Coherence Rules

These rules apply to all task files (infrastructure and component). Generators should verify these before output; the coherence checker will validate them.

### Runtime dependency awareness

Distinguish between task-ordering dependencies (`Depends On`) and runtime dependencies (resources that must exist when a task executes). If a task configures something that references a resource created by a later stage, document conditional execution or skip-with-log behaviour in the task's Notes.

### Cross-component dependencies

When a task references artifacts outside its own scope (health check endpoints, Dockerfiles, settings modules, API contracts, shared models), document these as cross-component dependencies in the task's Notes section. The implementer needs to know what must exist outside their task file's scope.

### Deduplication

Each resource should have one authoritative task. Avoid creating multiple tasks that configure the same resource; other tasks should reference it via `Depends On`.

---

## Shared Quality Checks

Every generator should verify before output, in addition to any generator-specific checks:

- [ ] Runtime dependencies documented where they differ from task-ordering dependencies
- [ ] Cross-component dependencies noted in task Notes sections
- [ ] Tasks that produce outputs consumed by other tasks document the handoff mechanism
- [ ] No duplicate tasks for the same resource
- [ ] Items within each task share the same prerequisites (see: Prerequisite coherence)
- [ ] Task IDs are sequential
- [ ] Summary counts match actual tasks

---

## Task Status

| Status | Meaning |
|--------|---------|
| PENDING | Not started |
| IN_PROGRESS | Currently being worked on |
| DONE | Completed and verified |
| BLOCKED | Cannot proceed (note blocker in Notes) |

---

## What NOT to Include

- **Design decisions**: These belong in the spec
- **Why questions**: The spec explains rationale
- **Code snippets**: Tasks describe what, not how
- **Time estimates**: Not part of task definition

See also: Scope Principles (above).

---

## Example: Complete Task

```markdown
### TASK-007: Implement event status transitions

**Spec Reference**: §5.2
**Status**: PENDING
**Depends On**: TASK-003 (events table), TASK-005 (event validation)

#### Description

Implement the state machine for event status transitions. Events move through draft → published → cancelled states with validation at each transition.

#### Acceptance Criteria

- [ ] Draft events can transition to published (requires all required fields)
- [ ] Published events can transition to cancelled (by organizer only)
- [ ] Cancelled events cannot transition to any other state
- [ ] Invalid transitions return 400 with explanation
- [ ] Status changes are logged with timestamp and actor

#### Notes

State transitions are enforced at the service layer, not database constraints.
See Foundations §Error Handling for error response format.
```
