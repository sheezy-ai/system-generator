# Tasks Stage

Tasks are **discrete, implementable units of work** derived from Component Specs and Foundations. Each task is specific enough to be completed independently and verified against clear acceptance criteria.

---

## Purpose

| Aspect | Description |
|--------|-------------|
| **Input** | Component Specs (per component), Foundations + Architecture Overview (for infrastructure) |
| **Output** | Task files with implementable work items |
| **Abstraction Level** | Actionable work: specific endpoints, migrations, integrations |
| **Key Question** | "What exactly needs to be built, in what order?" |

---

## What Belongs Here

- Specific implementation tasks (1-4 hours each)
- Clear acceptance criteria per task
- Dependencies between tasks (within and across components)
- Traceability to spec sections
- Task status tracking (PENDING, IN_PROGRESS, DONE, BLOCKED)

---

## What Does NOT Belong Here

- Design decisions (Component Specs)
- How to implement (that's the implementer's job)
- Time estimates (not part of task definition)
- Code snippets or implementation details
- System-wide conventions (Foundations)

Tasks follow two Scope Principles (see `guides/06-tasks-guide.md`): **what, not how** (tasks describe what to build and acceptance criteria, not implementation details) and **derive, not invent** (every task traces to a spec section or source document).

---

## Two Task Types

Unlike other stages, Tasks has **two distinct task types** with different sources:

### Infrastructure Tasks

| Aspect | Description |
|--------|-------------|
| **Source** | Foundations + Architecture Overview |
| **Covers** | Database, messaging, CI/CD, monitoring, secrets, containers |
| **Output** | `tasks/infrastructure/infrastructure.md` |
| **Created** | Once per project, always first (Tier 0) |

### Component Tasks

| Aspect | Description |
|--------|-------------|
| **Source** | Component Spec + Foundations (for conventions) |
| **Covers** | Interfaces, data model, behaviour, integrations per component |
| **Output** | `tasks/components/[component-name].md` |
| **Created** | One per component, in dependency tiers for parallel processing |

See DEC-044 for rationale.

---

## Workflow

Tasks uses an **automated pipeline** with no human review step:

```
Per component:  Extract Spec Items + Generate (parallel) → Coverage + Coherence Check (parallel) → Consolidate → Route → Promote
After all tiers: Cross-Component Consistency Check → Route
```

This works because:
- Tasks derive from already-reviewed Component Specs
- Spec-item extraction pre-computes a definitive completeness baseline (DEC-054)
- Coverage validation checks every extracted item has corresponding tasks
- Coherence validation ensures tasks are internally consistent and implementable
- Cross-component check validates consistency across all promoted task files
- Fix rounds use targeted edits, not full regeneration (DEC-055)
- Auto-promote on PASS eliminates approval bottleneck

See DEC-043 for rationale.

---

## No Expert Panel

Tasks has no experts. Component Specs have already been reviewed; Spec-Item Extractor pre-computes completeness baselines; Coverage Checker validates against extracted items; Coherence Checker validates consistency; Cross-Component Checker validates inter-file consistency; automated promotion replaces human approval.

---

## Workflow Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                      TASK PIPELINE (per component)                       │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────┐                                                       │
│  │  Spec-Item   │──┐                                                    │
│  │  Extractor   │  │  (round 1 only,    ┌──────────────┐               │
│  │  (round 1)   │  ├─▶│  Coverage    │───▶│ Consolidate  │               │
│  └──────────────┘  │  │   Checker    │    │   Reports    │               │
│  ┌──────────────┐  │  ├──────────────┤    │              │               │
│  │   Generate   │──┘  │  Coherence   │    │              │               │
│  │    Tasks     │     │   Checker    │    │              │               │
│  └──────────────┘     └──────────────┘    └──────┬───────┘               │
│        │               (run in parallel)          │                       │
│        │                                         ▼                       │
│        │                                  ┌──────────────┐               │
│        │                                  │    Route     │               │
│        │                                  │  PASS/FAIL   │               │
│        │                                  └──────┬───────┘               │
│        │                                    ┌────┴────┐                  │
│        │                                    │         │                  │
│        ▲                                    ▼         ▼                  │
│        │                               ┌────────┐ ┌────────┐            │
│        └──────────(FAIL)───────────────│  FAIL  │ │ PASS   │            │
│         (Edit, not regenerate)         └────────┘ └───┬────┘            │
│                                                       │                  │
│                                                       ▼                  │
│                                                ┌────────────┐           │
│                                                │  Promote   │           │
│                                                │ (auto)     │           │
│                                                └────────────┘           │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘

After all components promoted:

┌──────────────────────────────────────────────────────────────────────────┐
│                     CROSS-COMPONENT CHECK                                │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐               │
│  │ Cross-Comp.  │───▶│    Route     │───▶│   Copy +     │               │
│  │   Checker    │    │  PASS/FAIL   │    │  Fix Copies  │               │
│  └──────────────┘    └──────────────┘    └──────┬───────┘               │
│        ▲                                        │                       │
│        │              ┌──────────────┐          │                       │
│        └──────────────│ Re-validate  │◀─────────┘                       │
│                       │  + Promote   │                                  │
│                       └──────────────┘                                  │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Orchestration Model

Task creation uses a **coordinator + pipeline runner** split:

- **Coordinator** (`coordinator.md`): Initializes workflow state, computes dependency tiers, spawns pipeline runners as parallel subagents via Task tool, tracks progress, presents final summary. Does not process components directly.

- **Pipeline Runner** (`pipeline-runner.md`): Runs the full pipeline for a single component as a subagent. Spawns worker agents (generator, checkers, consolidator) and handles the generate → check → route → promote loop.

Components within the same dependency tier are spawned as parallel subagents. The coordinator groups components into tiers and processes them sequentially, spawning all runners within each tier in parallel.

---

## Pipeline Steps

### Step 1: Extract Spec Items + Generate Tasks

On round 1, the **spec-item extractor** and **generator** run in parallel. The extractor pre-computes a definitive list of implementable items from source documents (see DEC-054). On round 2+, only the generator runs (the extractor output from round 1 is reused).

**Spec-Item Extractor** (`spec-item-extractor.md`):
- For components: reads the component spec (§3–§11), extracts every implementable item
- For infrastructure: reads Foundations, Architecture, and infrastructure spec
- Output: `versions/[component-name]/round-1/00-spec-items.md` (numbered list of items with source locations)

**Generator** (`task-generator.md` or `infrastructure-generator.md`):

#### For Infrastructure Tasks

**Input:** Foundations path, Architecture Overview path, task guide path, output path

**Process:**
1. Read Foundations to identify infrastructure requirements (database, CI/CD, monitoring, secrets)
2. Read Architecture Overview for platform/integration infrastructure
3. Generate tasks grouped by concern (Database, CI/CD, Monitoring, Secrets, Containers, etc.)
4. Order tasks by dependency

**Round 1 output:** `versions/infrastructure/round-N/01-draft-tasks.md` (Write)
**Round 2+ output:** Edit the existing draft in place (targeted corrections from feedback only — DEC-055)

#### For Component Tasks

**Input:** Component Spec path, Foundations path, existing task files (cross-references), infrastructure task file, task guide path, output path

**Process:**
1. Read Component Spec to identify implementable items per section
2. Read Foundations for conventions reference
3. Read existing task files to understand cross-component task IDs
4. Generate tasks grouped by spec section (Interfaces, Data Model, Behaviour, etc.)
5. Identify dependencies within and across components

**Round 1 output:** `versions/[component-name]/round-N/01-draft-tasks.md` (Write)
**Round 2+ output:** Edit the existing draft in place (targeted corrections from feedback only — DEC-055)

---

### Step 2: Coverage and Coherence Check

Coverage Checker and Coherence Checker run **in parallel**.

#### Coverage Checker (`coverage-checker.md`)

**Input:** Spec-items file (from extractor), draft task file, other existing task files, infrastructure task file

**Checks:**
1. **Coverage**: Every item in the spec-items file has a corresponding task (validated against extractor output, not self-enumerated — DEC-054)
2. **Dependencies**: All `Depends On` references resolve correctly
3. **Circular dependencies**: No cycles in the task dependency graph

**Output:** `versions/[component-name]/round-N/02-coverage-report.md`

#### Coherence Checker (`coherence-checker.md`)

**Input:** Task file, source documents, other existing task files, infrastructure task file

**Checks:**
1. **Provisioning Sequence**: Runtime resource dependencies acknowledged
2. **Inter-Task Data Flow**: Handoff mechanisms documented between producer/consumer tasks
3. **Cross-Component Dependencies**: Application code dependencies noted
4. **Prerequisite Coherence**: Items within a task share the same prerequisites

**Output:** `versions/[component-name]/round-N/02-coherence-report.md`

**Severity levels:**
- **HIGH**: Task will fail at execution with no documented workaround — blocks PASS
- **MEDIUM**: Implicit assumptions that could cause confusion or incorrect implementation — blocks PASS
- **LOW**: Minor documentation improvements, clear from context — advisory only

---

### Step 3: Consolidate

**Agent:** `checker-consolidator.md`

Merges coverage and coherence reports into a single consolidated report with a unified status.

**Input:** Coverage report path, coherence report path

**Output:** `versions/[component-name]/round-N/03-consolidated-report.md`

**Status determination:**

| Coverage | Coherence | Consolidated |
|----------|-----------|-------------|
| PASS | PASS (no HIGH/MEDIUM) | **PASS** |
| PASS | ISSUES_FOUND (LOW only) | **PASS (with advisory)** |
| PASS | ISSUES_FOUND (HIGH or MEDIUM) | **FAIL** |
| FAIL | Any | **FAIL** |

---

### Step 4: Route

Based on consolidated status:

| Status | Action |
|--------|--------|
| **FAIL** | Return to Generate with all issues as feedback. Increment round. |
| **PASS (with advisory)** | Proceed to Promote. LOW items are genuinely advisory. |
| **PASS** | Proceed to Promote. |

**Max rounds**: 5. If exceeded, component is marked FAILED.

---

### Step 5: Promote

Auto-promote on PASS (or PASS with advisory):
- Copy draft task file to final location
- Update workflow state: component status = COMPLETE

---

### Step 6: Cross-Component Consistency Check

Runs **after all tiers complete** (all components promoted). Validates consistency across the full set of promoted task files using the copy-edit-validate-promote pattern (DEC-056).

**Agent:** `cross-component-checker.md` (read-only analysis)

**Checks:**
1. **DEP-N**: Cross-component dependency content alignment (referenced tasks exist and match)
2. **INT-N**: Bidirectional interface consistency (producer and consumer agree)
3. **RES-N**: Shared resource consistency (same resource described consistently)
4. **MIS-N**: Missing cross-references (implicit dependencies not documented)

**Process:**
1. Checker produces a report with exact fix instructions
2. On PASS → finalize
3. On FAIL → coordinator copies affected promoted files to version directories, applies fixes to copies (Edit), re-validates copies with coverage + coherence checkers, promotes validated copies back, re-runs cross-component check
4. Max 3 rounds before escalating to user

**Output:** `versions/cross-component/round-N/01-cross-component-report.md`

---

## Coverage Validation

### For Component Specs

| Spec Section | Required Coverage |
|--------------|-------------------|
| §3 Interfaces | At least one task per endpoint |
| §4 Data Model | Migration task per table |
| §5 Behaviour | Tasks covering all flows |
| §6 Dependencies | Integration task per dependency |
| §7 Integration | Tasks for each integration |
| §8 Error Handling | Combined with interface tasks OR separate |
| §9 Observability | May be infra OR component task |
| §10 Security | Auth integration tasks |
| §11 Testing | Optional (may be implicit) |

Sections that don't need direct coverage: §1 Overview, §2 Scope, §12 Open Questions, §13 Related Decisions

### For Infrastructure

| Area | Required Coverage |
|------|-------------------|
| Database | Provisioning, configuration, backups |
| Messaging | Queue/topic setup, dead letter queues |
| CI/CD | Pipeline setup, test/build/deploy stages |
| Monitoring | Logging infrastructure, metrics, alerting |
| Secrets | Secrets management setup, rotation |
| Containers | Base images, registry setup |

---

## Dependency Validation

### Dependency Formats

| Format | Example | Resolves To |
|--------|---------|-------------|
| Within component | `TASK-003` | Task in same file |
| Cross-component | `UserService/TASK-001` | Task in UserService task file |
| Infrastructure | `Infrastructure/TASK-002` | Task in infrastructure file |

### Validation Statuses

| Status | Meaning |
|--------|---------|
| VALID | Dependency resolves to existing task |
| INVALID | Referenced task does not exist |
| UNVERIFIED | Target task file not provided (cannot verify) |
| CIRCULAR | Part of a dependency cycle |
| MALFORMED | Dependency format is incorrect |

**Note:** UNVERIFIED is not a failure. If a component's task file hasn't been created yet, cross-references to it are marked UNVERIFIED and validated later.

---

## File Paths

**Stage guide:** `guides/06-tasks-guide.md`

**Agent prompts:**
```
agents/06-tasks/
├── coordinator.md              # Workflow coordination (initialization, tiers, cross-component check, finalization)
├── pipeline-runner.md          # Per-component pipeline (extract + generate → check → promote)
├── spec-item-extractor.md      # Pre-computes implementable items from source documents
├── task-generator.md           # Component task generation
├── infrastructure-generator.md # Infrastructure task generation
├── coverage-checker.md         # Coverage validation against extracted spec items
├── coherence-checker.md        # Coherence validation (provisioning, data flow, cross-component, prerequisites)
├── checker-consolidator.md     # Merges coverage + coherence reports
└── cross-component-checker.md  # Cross-component consistency validation (after all tiers)
```

**Output locations:**
```
system/06-tasks/
├── tasks/
│   ├── infrastructure/
│   │   └── infrastructure.md           # Infrastructure tasks
│   └── components/
│       ├── event-directory.md          # Component tasks
│       ├── email-ingestion.md
│       └── ...
└── versions/
    ├── workflow-state.md               # Processing order and progress
    ├── infrastructure/
    │   └── round-N/
    │       ├── 00-spec-items.md        # Extracted spec items (round 1 only)
    │       ├── 01-draft-tasks.md       # Generated tasks
    │       ├── 02-coverage-report.md   # Coverage check
    │       ├── 02-coherence-report.md  # Coherence check
    │       └── 03-consolidated-report.md  # Merged report
    ├── [component-name]/
    │   ├── round-N/
    │   │   ├── 00-spec-items.md
    │   │   ├── 01-draft-tasks.md
    │   │   ├── 02-coverage-report.md
    │   │   ├── 02-coherence-report.md
    │   │   └── 03-consolidated-report.md
    │   └── xref-round-N/              # Cross-component fix copies
    │       ├── 01-tasks.md            # Copy of promoted file
    │       ├── 02-coverage-report.md  # Re-validation
    │       ├── 02-coherence-report.md
    │       └── 03-consolidated-report.md
    └── cross-component/
        └── round-N/
            └── 01-cross-component-report.md  # Cross-component check
```

---

## Processing Order

The coordinator computes dependency tiers from the Architecture's Component Spec List:

- **Tier 0**: Infrastructure (always first — component generators need the infrastructure task file)
- **Tier 1+**: Components grouped by dependency — each tier contains components whose dependencies are all in earlier tiers

Components within a tier are spawned as parallel subagents. Tiers are processed sequentially.

---

## Invocation

**Create all tasks (fully automated):**
```
Read the Tasks coordinator at:
agents/06-tasks/coordinator.md

Create tasks.
```

The coordinator initializes workflow state, computes dependency tiers, spawns pipeline runners as parallel subagents, and presents the final summary. A single invocation processes all components end-to-end.

**Manual alternative — run a single component:**
```
Read the Tasks pipeline runner at:
agents/06-tasks/pipeline-runner.md

Create tasks for [component-name].
```

---

## State Management

Track workflow state in `versions/workflow-state.md`:

```markdown
# Task Creation Workflow State

**Status**: INITIALISING | IN_PROGRESS | CROSS_CHECKING | COMPLETE
**Started**: YYYY-MM-DD

## Processing Order

| # | Component | Type | Dependencies | Status | Round | Last Updated | Notes |
|---|-----------|------|-------------|--------|-------|--------------|-------|
| 0 | infrastructure | infra | - | PENDING | - | - | |
| 1 | event-directory | component | - | PENDING | - | - | |
| 2 | email-ingestion | component | event-directory | PENDING | - | - | |
| ... | | | | | | | |

## History

- YYYY-MM-DD: Task creation pipeline started
```

**Component statuses**: PENDING → GENERATING → CHECKING → PROMOTING → COMPLETE

Exception statuses: FAILED (exceeded max rounds or agent failure), BLOCKED (dependency is FAILED)

**Ownership**: The coordinator manages the overall workflow status and history. Each pipeline runner updates only its own component's row.

---

## After Task Completion

Once tasks are promoted:
1. Tasks are ready for implementation
2. Implementers can claim and work on tasks
3. Update task status as work progresses (PENDING → IN_PROGRESS → DONE)
4. Cross-component dependencies guide work order

---

## Tool Restrictions

All agents in this workflow:
- **Use:** Read, Write, Edit, Glob, Grep
- **Do NOT use:** Bash (except `cp` and `mkdir` for file orchestration), WebFetch, WebSearch

---

## Key Principles

- **Spec-derived**: Every task traces to a spec section
- **Right-sized**: 1-4 hours of work per task
- **Dependency-aware**: Cross-component and infrastructure dependencies explicit
- **Coverage-gated**: Every spec section must have corresponding tasks
- **Coherence-gated**: Tasks must be internally consistent and acknowledge runtime dependencies
- **Auto-promoted**: Tasks auto-promote on PASS — no manual approval step
