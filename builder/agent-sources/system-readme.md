# System Design

This folder contains the design documentation for your project.

## Quick Start

Run `./init-project.sh` from the repo root to set up the folder structure.

## Prompts

### Blueprint

**Create:**
```
Read the Blueprint creation orchestrator at:
{{AGENTS_PATH}}/01-blueprint/create/orchestrator.md

Create a Blueprint from:
- Concept: {{PROJECT_PATH}}/system-design/01-blueprint/concept.md
```

The create workflow iterates through **Explore** (identifies strategic dimensions, explores each in parallel, human reviews enrichments) and **Generate** (produces draft Blueprint from concept + accepted enrichments, resolves gaps) rounds — round 0 works from the concept, round 1+ works from the previous round's draft. The human exits the loop by choosing to promote, which triggers **Extract** (promotes to `blueprint.md` and extracts `scope-brief.md` for downstream stages). Strategic decisions identified during enrichment review or flagged by the Generator are registered and handled by a separate Decision Orchestrator.

**Decision Orchestrator** (run in a separate conversation, before promoting):
```
Read the Decision Orchestrator at:
{{AGENTS_PATH}}/01-blueprint/create/decision-orchestrator.md

Decision name: {decision-name}
```

The Decision Orchestrator handles a single strategic decision end-to-end: defining an evaluation framework with the human, then analysing options against that framework. Run once per pending decision. Decisions can originate from enrichment review (`>> RESOLVED [DECISION NEEDED]`) or from Generator gap markers (`[DECISION NEEDED]` in the draft). Both are registered in the workflow state by the create orchestrator.

**Review:**
```
Read the Blueprint review orchestrator at:
{{AGENTS_PATH}}/01-blueprint/review/orchestrator.md

Review the Blueprint.
```

### PRD

**Create:**
```
Read the PRD creation orchestrator at:
{{AGENTS_PATH}}/02-prd/create/orchestrator.md

Create a PRD.
```

The create workflow iterates through **Explore** (identifies capability areas from the Blueprint that need product-level decomposition, explores each in parallel, human reviews enrichments) and **Generate** (produces draft PRD from Blueprint + accepted enrichments, resolves gaps) rounds — round 1 works from the Blueprint, round 2+ works from the previous round's draft. The human exits the loop by choosing to promote. Unlike Blueprint, PRD does not use a separate Decision Orchestrator — product-level decisions are resolved inline during enrichment review or gap resolution.

**Review:**
```
Read the PRD review orchestrator at:
{{AGENTS_PATH}}/02-prd/review/orchestrator.md

Review the PRD.
```

### Foundations

**Create:**
```
Read the Foundations creation orchestrator at:
{{AGENTS_PATH}}/03-foundations/create/orchestrator.md

Create Foundations.
```

Optional: place a brief at `{{PROJECT_PATH}}/system-design/03-foundations/brief.md` before running Create. The generator incorporates settled decisions from the brief directly, reducing gap markers.

**Review:**
```
Read the Foundations review orchestrator at:
{{AGENTS_PATH}}/03-foundations/review/orchestrator.md

Review Foundations.
```

### Architecture Overview

**Create:**
```
Read the Architecture Overview creation orchestrator at:
{{AGENTS_PATH}}/04-architecture/create/orchestrator.md

Create an Architecture Overview.
```

Optional: place a brief at `{{PROJECT_PATH}}/system-design/04-architecture/brief.md` before running Create.

**Review:**
```
Read the Architecture Overview review orchestrator at:
{{AGENTS_PATH}}/04-architecture/review/orchestrator.md

Review the Architecture Overview.
```

### Component Spec

**Initialize (once, before first component):**
```
Read the Component Specs initialize orchestrator at:
{{AGENTS_PATH}}/05-components/initialize/orchestrator.md

Initialize Component Specs.
```

**Create (per component):**
```
Read the Component Spec create orchestrator at:
{{AGENTS_PATH}}/05-components/create/orchestrator.md

Create component spec for: [component name]
```

Optional: place a per-component brief at `{{PROJECT_PATH}}/system-design/05-components/versions/[component-name]/brief.md` before running Create.

After the draft is generated, review and augment it, then run Review.

**Review (per component):**
```
Read the Component Spec review router at:
{{AGENTS_PATH}}/05-components/review/orchestrator-router.md

Review component: [component name]
```

### Tasks

**Create all tasks (fully automated):**
```
Read the Tasks coordinator at:
{{AGENTS_PATH}}/06-tasks/coordinator.md

Create tasks.
```

The coordinator initializes workflow state, computes dependency tiers, spawns pipeline runners as parallel subagents, and presents the final summary. A single invocation processes all components end-to-end.

**Manual alternative — run a single component:**
```
Read the Tasks pipeline runner at:
{{AGENTS_PATH}}/06-tasks/pipeline-runner.md

Create tasks for [component-name].
```

### Conventions

**Generate build conventions (stops for human approval):**

```
Read the Conventions coordinator at:
{{AGENTS_PATH}}/07-conventions/coordinator.md

Generate conventions.
```

The coordinator generates build conventions in batches (up to 4 sections in parallel), runs cross-reference review, and presents the assembled document for human approval. Re-invoke after reviewing to mark as approved.

**Manual alternative — run a single section:**
```
Read the section pipeline runner at:
{{AGENTS_PATH}}/07-conventions/section-pipeline-runner.md

Process section N (Section Name).
```

### Build

**Run the build pipeline (conventions must be approved first):**

```
Read the Build coordinator at:
{{AGENTS_PATH}}/08-build/coordinator.md

Build.
```

The coordinator verifies conventions are approved, derives dependency tiers from the Architecture, and processes all components tier-by-tier — fully automated.

**Manual alternative — run a single component:**
```
Read the Build pipeline runner at:
{{AGENTS_PATH}}/08-build/pipeline-runner.md

Build [component-name].
```

### Verification

**Run build verification (build must be complete first):**

```
Read the Verification coordinator at:
{{AGENTS_PATH}}/09-verification/coordinator.md

Verify.
```

The coordinator verifies build is complete, runs Phase 1 (mechanical — lint, types, imports) with an automated fix loop, then Phase 2 (unit tests) with a human checkpoint. Re-invoke after making changes to continue Phase 2.

### Provisioning

**Generate provisioning runbook and execute (verification must be complete first):**

```
Read the Provisioning coordinator at:
{{AGENTS_PATH}}/10-provisioning/coordinator.md

Provision.
```

The coordinator generates a provisioning runbook from infrastructure tasks and built IaC, presents it for human triage, then executes approved items in dependency-ordered batches. Re-invoke after completing manual items to continue.

### Packaging

**Package the deliverable (provisioning must be complete first):**

```
Read the Packaging coordinator at:
{{AGENTS_PATH}}/11-packaging/coordinator.md

Package.
```

The coordinator generates developer-facing documentation, presents it for human review, then verifies package completeness.

### Operations Readiness

**Generate maintenance and operations artefacts (packaging must be complete first):**

```
Read the Operations Readiness coordinator at:
{{AGENTS_PATH}}/12-operations-readiness/coordinator.md

Extract operations readiness artefacts.
```

The coordinator extracts 9 artefacts from the completed design docs and build output — component map, contracts, risk profile, traceability (for System-Maintainer) and SLOs, monitoring definitions, deployment topology, runbooks, security posture (for System-Operator). All 5 extractors run in parallel, followed by a cross-reference consistency check and human review. This is the system-builder's final stage.

### Technical Writer Session

Run **after all review rounds are complete** and before promoting the final version. There's no value reviewing clarity mid-cycle when content might still change.

This is an **interactive session** - you'll review the document, discuss with the human, apply agreed changes, and update workflow state. All in one conversation.

```
Read the Technical Writer Session prompt at:
{{AGENTS_PATH}}/specialist-agents/technical-writer.md

Then start a Technical Writer Session with:
- Document: {{PROJECT_PATH}}/system-design/[stage]/[document].md
- Workflow state: {{PROJECT_PATH}}/system-design/[stage]/versions/workflow-state.md
- Output folder: {{PROJECT_PATH}}/system-design/[stage]/versions/round-[N]-technical-writer/

Where [N] is the next round number after the last review round.
```

The session handles workflow state updates automatically - it will add a new round, update progress, and add history entries.

## After Review Completes

**Stages 03–05** (Foundations, Architecture, Components) have promoter agents that run automatically at review exit. The promoter splits the reviewed document into three files:
- `[document].md` — Clean current-scope spec
- `decisions.md` — Design rationale and trade-offs
- `future.md` — Deferred items and future considerations

No manual promotion is needed for these stages.

**Stage 01** (Blueprint) auto-promotes during both create and review. The review orchestrator also re-extracts `scope-brief.md` to keep it consistent with the reviewed Blueprint.

**Stage 02** (PRD) auto-promotes during creation. The create orchestrator promotes the final draft to `prd.md` when the human chooses to promote at Gap Resolution. The review orchestrator handles promotion separately.

## Stage Progression

Work through stages in order:

1. **Blueprint** - Vision, users, business model, MVP
2. **PRD** - Phase scope, capabilities, success criteria
3. **Foundations** - Tech stack, conventions, cross-cutting decisions
4. **Architecture** - Components, data flows, integration points
5. **Component Specs** - Implementation-ready specs (one per component)
6. **Tasks** - Discrete work units (infrastructure + one file per component)
7. **Conventions** - Build conventions from design docs (human approval checkpoint)
8. **Build** - Working code from task files (build → review per tier)
9. **Verification** - Lint, type check, unit test execution on built code
10. **Provisioning** - Runbook generation, human triage, infrastructure execution
11. **Packaging** - Developer-facing docs, package verification, standalone deliverable
12. **Operations Readiness** - Maintenance and operations artefacts for System-Maintainer and System-Operator

## Folder Contents

Each stage folder (01–05) contains:
- **[document].md** — The main output
- **scope-brief.md** — Focused scope brief for downstream stages (stage 01 only)
- **decisions.md** — Design rationale and trade-offs (stages 03–05)
- **future.md** — Deferred items and future considerations (stages 03–05)
- **versions/** — Workflow history and artifacts
  - **deferred-items.md** — Content deferred from upstream stages
  - **pending-issues.md** — Issues for upstream stages

Stages 06–12 use different structures defined by their coordinators. Deferred items and pending issues apply to stages 01–05 only.

## Learning More

See `system-generator/builder/docs/overview.md` for framework details.
