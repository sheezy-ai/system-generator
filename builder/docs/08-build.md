# Build Stage

Build takes the task files from stage 06 and **produces working code** in the project source tree. This is fundamentally different from stages 01–07, which produce design documentation and conventions within `system-design/`.

---

## Purpose

| Aspect | Description |
|--------|-------------|
| **Input** | Task files (per component + infrastructure), Component Specs, Foundations, Architecture, build conventions |
| **Output** | Working code in the project source tree |
| **Abstraction Level** | Executable code: modules, tests, configs, IaC |
| **Key Question** | "Does the code satisfy every task's acceptance criteria?" |

---

## What Belongs Here

- Application code implementing component tasks
- Tests for all implemented functionality
- Infrastructure-as-code (Terraform, Docker, CI/CD configs)
- Build logs and review reports

---

## What Does NOT Belong Here

- Design decisions (Component Specs)
- Task definitions (Tasks stage)
- Build conventions (Conventions stage)
- Design documentation

---

## Pre-condition

The conventions stage (07) must have completed with APPROVED status. The build coordinator verifies this before proceeding.

---

## Workflow

Build uses a **two-step pipeline** per task tier within each component, followed by a **cross-component spec-fidelity check** after all component tiers complete:

```
Per tier:       Build → Review → Route (max 3 rounds)
Per component:  Tier 1 → Tier 2 → ... → Tier T
Post-build:     Cross-Component Spec-Fidelity Check
```

The pipeline runner computes task dependency tiers from the task file's `Depends On` fields (same tier grouping algorithm the coordinator uses for components). Each tier is processed independently through build → review → route.

```
┌──────────────────────────────────────────────────────────────────────────┐
│                     BUILD PIPELINE (per component)                       │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │  TIER LOOP (per task tier)                                         │  │
│  │                                                                    │  │
│  │  ┌──────────────┐    ┌──────────────┐                             │  │
│  │  │    Build     │───▶│   Review     │                             │  │
│  │  │ (tier code)  │    │(tier crit.)  │                             │  │
│  │  └──────────────┘    └──────┬───────┘                             │  │
│  │        │                    │                                      │  │
│  │        │                    ▼                                      │  │
│  │        │             ┌──────────────┐                             │  │
│  │        │             │    Route     │                             │  │
│  │        │             │  PASS/FAIL   │                             │  │
│  │        │             └──────┬───────┘                             │  │
│  │        │               ┌────┴────┐                                │  │
│  │        ▲               ▼         ▼                                │  │
│  │        │          ┌────────┐ ┌────────┐                           │  │
│  │        └──(FAIL)──│  FAIL  │ │  PASS  │──▶ next tier              │  │
│  │         max 3     └────────┘ └────────┘                           │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  After all tiers pass:  ┌────────────┐                                  │
│                         │  COMPLETE  │                                  │
│                         └────────────┘                                  │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│              CROSS-COMPONENT SPEC-FIDELITY CHECK (post-tier)             │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐               │
│  │   Check      │───▶│    Route     │───▶│  Apply Fixes │               │
│  │ (all specs)  │    │  PASS/FAIL   │    │  (Edit code) │               │
│  └──────────────┘    └──────────────┘    └──────┬───────┘               │
│        ▲                                        │                       │
│        └────────────────────────────────────────┘                       │
│                    (re-check, max 3 rounds)                             │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Orchestration Model

Build uses a **coordinator + pipeline runner** split:

- **Coordinator** (`coordinator.md`): Verifies conventions are approved, derives dependency tiers from Architecture, spawns pipeline runners as parallel subagents, tracks progress, presents final summary. Does not build code directly.

- **Pipeline Runner** (`pipeline-runner.md`): Runs the full pipeline for a single component as a subagent. Computes task dependency tiers, creates tier task files, and runs each tier through build → review → route. Spawns worker agents (builder/infrastructure-builder, reviewer) per tier.

- **Spec-Fidelity Checker** (`spec-fidelity-checker.md`): Read-only agent that validates built code against reviewed component specs at integration boundaries. Runs after all per-component pipelines complete.

Components within the same dependency tier are spawned as parallel subagents. The coordinator groups components into tiers and processes them sequentially, spawning all runners within each tier in parallel.

---

## Pipeline Steps

The pipeline runner first computes task dependency tiers from the task file, then processes each tier independently through build → review → route.

### Step 0: Compute Task Tiers

The pipeline runner reads the task file, parses each task's `Depends On` field, and groups tasks into tiers using the same algorithm the coordinator uses for components. Cross-component dependencies are treated as already satisfied (guaranteed by component-level tiers). Each tier gets its own tier task file.

### Step 1: Build (per tier)

**Agent:** `builder.md` (components) or `infrastructure-builder.md` (infrastructure)

**Input:** Tier task file path, conventions path, spec path, foundations path, round directory

**Process:**
1. Read tier task file and build dependency-ordered task list
2. Read conventions for project structure and patterns
3. Glob existing code (from earlier-tier components and prior tiers)
4. Implement each task in the tier
5. Write build log

**Output:** Code in project source tree + `versions/[component]/tier-T/round-N/01-build-log.md`

---

### Step 2: Review (per tier)

**Agent:** `reviewer.md`

**Input:** Tier task file path, conventions path, round directory

**Process:**
1. Read tier task file's acceptance criteria
2. Read built code (from build log's file list)
3. Assess each acceptance criterion: PASS/FAIL/PARTIAL
4. Check conventions compliance
5. Report overall PASS or FAIL

**Output:** `versions/[component]/tier-T/round-N/02-review-report.md`

---

### Step 3: Route (per tier)

Based on review status:

| Status | Action |
|--------|--------|
| **FAIL** | Return to Build with review feedback. Increment round within this tier. |
| **PASS** | Proceed to next tier. |

**Max rounds**: 3 per tier. If exceeded, component is marked FAILED.

---

### Step 4: Cross-Component Spec-Fidelity Check

**Agent:** `spec-fidelity-checker.md` (spawned by coordinator after all tiers complete)

After all per-component pipelines complete, the coordinator runs a cross-component spec-fidelity check. This catches integration issues that per-component reviewers cannot detect — two components can pass individually but break when integrated.

**Checks:**
1. **Contract Implementation Fidelity** (CON-N): Both sides of each integration point match the spec
2. **Cross-Component Import Resolution** (IMP-N): Cross-component imports reference real modules and exports
3. **Shared Model Consistency** (MOD-N): Shared data structures used consistently across components
4. **Missing Integration Code** (MIS-N): Every spec-defined integration point has code on both sides

**Ground truth**: Reviewed component specs, not other components' code.

**Pre-check**: If fewer than 2 components are COMPLETE, the cross-component check is skipped (no integration to validate). If any components are FAILED/BLOCKED, the checker is told to skip their (possibly partial) code.

**On FAIL**: Coordinator delegates fixes to the spec-fidelity fixer agent (targeted code edits from the report), then re-runs the checker. Max 3 rounds.

**Output:** `versions/cross-component/round-N/01-spec-fidelity-report.md` and `02-fix-log.md`

---

## File Paths

**Stage documentation:** `docs/08-build.md`

**Agent prompts:**
```
agents/08-build/
├── coordinator.md              # Workflow coordination (tiers, status, cross-component check)
├── pipeline-runner.md          # Per-component pipeline (build → review)
├── builder.md                  # Component code builder
├── infrastructure-builder.md   # Infrastructure code builder
├── spec-fidelity-checker.md    # Cross-component integration validation
├── spec-fidelity-fixer.md     # Applies fixes from checker report
└── reviewer.md                 # Reviews code against acceptance criteria
```

**Output locations:**
```
system-design/08-build/
└── versions/
    ├── workflow-state.md                 # Processing order and progress
    ├── infrastructure/
    │   └── tier-T/
    │       ├── 00-tier-tasks.md          # Tasks for this tier
    │       └── round-N/
    │           ├── 01-build-log.md        # What was built
    │           └── 02-review-report.md    # Acceptance criteria review
    ├── [component-name]/
    │   └── tier-T/
    │       ├── 00-tier-tasks.md
    │       └── round-N/
    │           ├── 01-build-log.md
    │           └── 02-review-report.md
    └── cross-component/
        └── round-N/
            ├── 01-spec-fidelity-report.md  # Cross-component integration check
            └── 02-fix-log.md               # Fixes applied (FAIL rounds only)
```

**Code output:** Written to the project source tree (outside `system-design/`), in the structure defined by `build-conventions.md`.

---

## Processing Order

The coordinator computes dependency tiers from the Architecture's Component Spec List:

- **Tier 0**: Infrastructure (always first — component builders need the infrastructure build as context)
- **Tier 1+**: Components grouped by dependency — each tier contains components whose dependencies are all in earlier tiers

Components within a tier are spawned as parallel subagents. Tiers are processed sequentially.

---

## Invocation

**Run the build pipeline:**
```
Read the Build coordinator at:
agents/08-build/coordinator.md

Build.
```

The coordinator verifies conventions are approved, derives tiers, and processes all components.

**Manual alternative — run a single component:**
```
Read the Build pipeline runner at:
agents/08-build/pipeline-runner.md

Build [component-name].
```

---

## State Management

Track workflow state in `versions/workflow-state.md`:

```markdown
# Build Workflow State

**Status**: IN_PROGRESS | CROSS_CHECKING | COMPLETE
**Started**: YYYY-MM-DD

## Processing Order

| # | Component | Type | Dependencies | Status | Round | Last Updated | Notes |
|---|-----------|------|-------------|--------|-------|--------------|-------|
| 0 | infrastructure | infra | - | PENDING | - | - | |
| 1 | event-directory | component | - | PENDING | - | - | |
| 2 | email-ingestion | component | event-directory | PENDING | - | - | |
| ... | | | | | | | |

## History

- YYYY-MM-DD: Build pipeline started
```

**Component statuses**: PENDING → BUILDING → REVIEWING → COMPLETE

Exception statuses: FAILED (exceeded max rounds or agent failure), BLOCKED (dependency is FAILED)

**Ownership**: The coordinator manages the overall workflow status and history. Each pipeline runner updates only its own component's row. The Notes column tracks tier progress during processing (`Tier T/N, round N`) and final summary on completion (`T tiers, N total rounds`).

---

## Key Principles

- **Tasks scope what, conventions govern how**: Tasks define the features, endpoints, and functionality to build. Build conventions (from Stage 07) define the implementation patterns — error handling, logging, API formats, module structure. Both are enforced: the reviewer checks acceptance criteria (tasks) and conventions compliance.
- **Tier-based task grouping**: Tasks within a component are grouped into dependency tiers and built sequentially
- **Review-gated**: Code must pass acceptance criteria review to complete
- **Spec-fidelity checked**: Cross-component integration validated against reviewed specs
- **Tier-based**: Infrastructure first, then components in dependency order
- **Auto-complete on PASS**: Components auto-complete on review PASS — no manual approval step
- **Fully automated**: No human checkpoint — conventions were approved in Stage 07
