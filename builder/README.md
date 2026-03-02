# System-Builder

A framework for creating product documentation through AI-assisted workflows. Guides a product from initial concept through to implementation-ready specifications.

## Quick Start

1. **Initialise** the project structure:
   ```bash
   ../init-project.sh
   ```

2. **Write your concept** in `system/01-blueprint/concept.md`

3. **Create a Blueprint**:
   ```
   Read the Blueprint creation orchestrator at:
   agents/01-blueprint/create/orchestrator.md

   Then create a Blueprint from:
   - Concept: system/01-blueprint/concept.md

   Start the creation workflow.
   ```

4. **Progress through stages** - See `system/README.md` for all workflow prompts

## Documentation Structure

| Folder | Purpose |
|--------|---------|
| `system/` | Your project's documentation outputs |
| `agents/` | Built agent prompts |
| `agent-sources/` | Source templates for agents (build system) |
| `docs/` | Framework documentation |
| `guides/` | Stage guides (what belongs at each abstraction level) |

## Stage Progression

```
Blueprint → PRD → Foundations → Architecture → Component Specs → Tasks →
  (why)    (what)   (shared)    (structure)       (how)         (do)

Conventions → Build → Verification → Provisioning → Packaging → Operations Readiness
 (standards)  (code)   (execute)      (runbook)    (deliverable)   (readiness)
```

Each stage produces documentation at a specific level of abstraction:

| Stage | Question Answered | Output |
|-------|-------------------|--------|
| Blueprint | Why build this? | Vision, users, business model, MVP scope |
| PRD | What does this phase deliver? | Capabilities, success criteria, scope |
| Foundations | What patterns do we use? | Tech stack, conventions, security baseline |
| Architecture | How is the system structured? | Components, data flows, boundaries |
| Component Specs | How do we build each part? | APIs, schemas, behaviour, tests |
| Tasks | What work items exist? | Implementable units of work |
| Conventions | What standards apply? | File paths, commands, build patterns |
| Build | What code is produced? | Modules, tests, IaC |
| Verification | Does the code pass checks? | Lint, type check, test execution |
| Provisioning | How is infrastructure set up? | Provisioning runbook, real commands |
| Packaging | What is the deliverable? | Standalone project with docs |
| Operations Readiness | Is the system operable? | SLOs, runbooks, traceability |

## Key Navigation

- **Using the framework**: `system/README.md` - Trigger prompts for all workflows
- **Understanding stages**: `guides/README.md` - What belongs at each level
- **Framework internals**: `docs/overview.md` - How it works
- **Design rationale**: `docs/design-decisions.md` - Why it's built this way

## Two Workflows

**Create** - Generate a new document from inputs (concept or upstream docs)

**Review** - Refine an existing document through iterative expert review

Both workflows use domain-expert agents, human checkpoints, and alignment verification.
