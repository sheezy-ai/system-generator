# Provisioning Stage

Provisioning takes the infrastructure-as-code from stage 08 and produces a **structured runbook** for deploying it to real infrastructure. This is the first stage with real-world side effects — cloud resources, costs, and permissions.

---

## Purpose

| Aspect | Description |
|--------|-------------|
| **Input** | Infrastructure tasks, built IaC code, build conventions |
| **Output** | Provisioning runbook + execution logs |
| **Abstraction Level** | Operational: real infrastructure commands against real environments |
| **Key Question** | "Is the infrastructure provisioned and verified?" |

---

## What Belongs Here

- Provisioning runbook (structured, with executable commands)
- Execution logs per batch
- Human triage decisions
- Verification results per item

---

## What Does NOT Belong Here

- Application code deployment (Stage 11 packaging covers deployment docs)
- Infrastructure-as-code generation (Stage 08)
- Design documentation
- Integration testing

---

## Pre-condition

The verification stage (09) must have completed with COMPLETE status. All code built, verified, and tests passing.

---

## Workflow

Three phases: generate the runbook, human triage, then execute in dependency-ordered batches.

```
Phase 1 (automated):  Generate runbook from infrastructure tasks + built IaC
Phase 2 (human):      Triage items — skip / auto / manual
Phase 3 (mixed):      Execute auto items, human handles manual items
```

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    PHASE 1: RUNBOOK GENERATION                           │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────┐                                                    │
│  │ Runbook Generator │──▶  runbook.md                                    │
│  └──────────────────┘                                                    │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                    PHASE 2: HUMAN TRIAGE                                 │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Coordinator presents runbook → Human marks each item:                   │
│    • auto  — agent executes                                              │
│    • skip  — already done / not needed                                   │
│    • manual — human handles                                              │
│  Semi-automated items: human provides required input values              │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│               PHASE 3: EXECUTION (dependency-ordered)                    │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐               │
│  │  Determine   │───▶│ Provisioning │───▶│   Report     │               │
│  │   batch      │    │    Agent     │    │  results     │               │
│  └──────────────┘    └──────────────┘    └──────┬───────┘               │
│        ▲                                        │                       │
│        └────────────────────────────────────────┘                       │
│                    (next batch or manual items)                          │
│                                                                          │
│  ALL RESOLVED ──▶ COMPLETE                                              │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Orchestration Model

Single coordinator with two subagents. Human is in the triage loop between generation and execution.

- **Coordinator** (`coordinator.md`): Spawns generator, presents runbook for triage, spawns provisioning agent for approved batches, tracks state. Does not execute commands.

- **Runbook Generator** (`runbook-generator.md`): One-shot agent. Reads infrastructure tasks + built IaC + conventions, produces the structured runbook. Read-only — no execution, no Bash.

- **Provisioning Agent** (`provisioning-agent.md`): Executes approved runbook items via Bash (broad access — second agent in the system with this, after stage 09 verifier). Captures output, verifies results, writes execution log. Does not triage or decide what to run.

---

## Runbook Items

Each runbook item maps 1:1 to an infrastructure task and includes:

- **ID**: PROV-NNN (maps to infrastructure/TASK-NNN)
- **Dependencies**: Other PROV items that must complete first
- **Type**: automated, value-injection, decision-point, external-action, or verification
- **Recommended mode**: auto, semi, or manual
- **Command**: Executable command (copy-pasteable)
- **Required inputs**: Human-provided values (for semi-automated items)
- **Verification criteria**: From the infrastructure task's acceptance criteria

---

## File Paths

**Stage documentation:** `docs/10-provisioning.md`

**Agent prompts:**
```
agents/10-provisioning/
├── coordinator.md           # Orchestrates triage and execution
├── runbook-generator.md     # Produces the runbook
└── provisioning-agent.md    # Executes approved items (broad Bash)
```

**Output locations:**
```
system-design/10-provisioning/
├── runbook.md
└── versions/
    ├── workflow-state.md
    └── batch-N/
        └── execution-log.md
```

---

## Invocation

**Run provisioning:**
```
Read the Provisioning coordinator at:
agents/10-provisioning/coordinator.md

Provision.
```

The coordinator verifies prerequisites, generates the runbook, presents it for human triage, then executes approved items in dependency-ordered batches. Re-invoke to continue execution after manual items are complete.

---

## State Management

Track state in `versions/workflow-state.md`:

```markdown
# Provisioning Workflow State

**Status**: GENERATING | TRIAGE | EXECUTING | COMPLETE
**Started**: YYYY-MM-DD
**Items Total**: [N]
**Items Resolved**: [N]

## Item Status

| ID | Title | Mode | Status | Batch | Notes |
|----|-------|------|--------|-------|-------|
| PROV-001 | [title] | auto | succeeded | 1 | |
| PROV-002 | [title] | skip | skipped | - | Already exists |
| PROV-003 | [title] | manual | pending | - | |

## History

- YYYY-MM-DD: Provisioning started
```

---

## Key Principles

- **Human-in-the-loop**: No provisioning without human triage. Every item is approved before execution.
- **Real-world side effects**: This stage creates cloud resources that cost money and can't be undone with `git checkout`. The human decides what runs.
- **Runbook as artifact**: The runbook is a durable document — useful beyond the pipeline for operational reference.
- **Idempotency by design**: Items should be safe to re-run. State tracking prevents accidental re-runs; idempotent commands are the safety net.
- **Dependency-ordered execution**: Items run only when their dependencies are satisfied.
- **Executable artifacts**: Every item has a command that can be run by either the agent or the human.
