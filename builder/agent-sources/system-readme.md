# System Design

This folder contains the design documentation for your project.

## Quick Start

Run `./init-project.sh` from the repo root to set up the folder structure.

## Prompts

### Blueprint

**Create:**
```
Execute the Blueprint creation workflow using the orchestrator at:
{{AGENTS_PATH}}/01-blueprint/create/orchestrator.md

Input:
- Concept: {{PROJECT_PATH}}/system-design/01-blueprint/concept.md
```

The create workflow iterates through **Explore** (identifies strategic dimensions, explores each in parallel, human reviews enrichments) and **Generate** (produces draft Blueprint from concept + accepted enrichments, resolves gaps) rounds — round 0 works from the concept, round 1+ works from the previous round's draft. The human exits the loop by choosing to promote, which triggers **Extract** (promotes to `blueprint.md` and extracts `scope-brief.md` for downstream stages). Strategic decisions identified during enrichment review or flagged by the Generator are registered and handled by a separate Decision Orchestrator.

**Decision Orchestrator** (run in a separate conversation, before promoting):
```
Execute the Decision workflow using the orchestrator at:
{{AGENTS_PATH}}/01-blueprint/create/decision-orchestrator.md

Decision name: {decision-name}
```

The Decision Orchestrator handles a single strategic decision end-to-end: defining an evaluation framework with the human, then analysing options against that framework. Run once per pending decision. Decisions can originate from enrichment review (`>> RESOLVED [DECISION NEEDED]`) or from Generator gap markers (`[DECISION NEEDED]` in the draft). Both are registered in the workflow state by the create orchestrator.

**Review:**
```
Execute the Blueprint review workflow using the orchestrator at:
{{AGENTS_PATH}}/01-blueprint/review/orchestrator.md
```

**Expand:**
```
Execute the Blueprint expand workflow using the orchestrator at:
{{AGENTS_PATH}}/01-blueprint/expand/orchestrator.md

Trigger: [description of what needs expanding, or path to a pending issue]
```

The expand workflow adds new capability areas or scope changes to an existing, promoted document. It runs **Scope** (analyst produces an Expansion Brief from the trigger, human reviews), **Explore** (one explorer per capability area investigates implications across all sections), **Integrate** (applies approved changes seamlessly), and **Verify** (coherence + enumeration checks — no alignment for Blueprint since it has no upstream). Expand never promotes — always follow with a Review round.

### PRD

**Create:**
```
Execute the PRD creation workflow using the orchestrator at:
{{AGENTS_PATH}}/02-prd/create/orchestrator.md
```

The create workflow iterates through **Explore** (identifies capability areas from the Blueprint that need product-level decomposition, explores each in parallel, human reviews enrichments) and **Generate** (produces draft PRD from Blueprint + accepted enrichments, resolves gaps) rounds — round 1 works from the Blueprint, round 2+ works from the previous round's draft. The human exits the loop by choosing to promote. Unlike Blueprint, PRD does not use a separate Decision Orchestrator — product-level decisions are resolved inline during enrichment review or gap resolution.

**Review:**
```
Execute the PRD review workflow using the orchestrator at:
{{AGENTS_PATH}}/02-prd/review/orchestrator.md
```

**Expand:**
```
Execute the PRD expand workflow using the orchestrator at:
{{AGENTS_PATH}}/02-prd/expand/orchestrator.md

Trigger: [description of what needs expanding, or path to a pending issue]
```

The expand workflow adds new capability areas or scope changes to the PRD. Same phases as Blueprint expand but includes alignment verification against Blueprint. Use when downstream stages (Foundations, Architecture) discover the PRD needs new capabilities that weren't in the original scope. Expand never promotes — always follow with a Review round.

### Foundations

**Create:**
```
Execute the Foundations creation workflow using the orchestrator at:
{{AGENTS_PATH}}/03-foundations/create/orchestrator.md
```

The create workflow runs **Assess** (evaluates technology options per category against PRD constraints, human provides directional preferences inline) then **Generate** (produces draft Foundations informed by assessment), followed by a structured gap analysis pipeline (Gap Formatter → Gap Analyst → human discussion → Author). Optional: place a brief at `{{PROJECT_PATH}}/system-design/03-foundations/brief.md` before running Create — the generator incorporates settled decisions from the brief directly, reducing gap markers.

**Review:**
```
Execute the Foundations review workflow using the orchestrator at:
{{AGENTS_PATH}}/03-foundations/review/orchestrator.md
```

**Expand:**
```
Execute the Foundations expand workflow using the orchestrator at:
{{AGENTS_PATH}}/03-foundations/expand/orchestrator.md

Trigger: [description of what needs expanding, or path to a pending issue]
```

The expand workflow adds new conventions or technology decisions to Foundations. Same phases as PRD expand with alignment verification against Blueprint. Use when downstream stages discover Foundations needs new conventions (e.g., a new external integration pattern, a new trust boundary requiring security conventions). Expand never promotes — always follow with a Review round.

### Architecture Overview

**Create:**
```
Execute the Architecture Overview creation workflow using the orchestrator at:
{{AGENTS_PATH}}/04-architecture/create/orchestrator.md
```

The create workflow iterates through **Explore** (identifies architectural concerns from PRD + Foundations, explores each in parallel, human reviews enrichments) and **Generate** (produces draft Architecture from PRD + Foundations + accepted enrichments, with independent coverage verification against PRD requirements, then structured gap analysis) rounds — round 1 works from the PRD + Foundations, round 2+ applies enrichments to the previous round's draft via the Enrichment Applicator. The human exits the loop by choosing to promote. Optional: place a brief at `{{PROJECT_PATH}}/system-design/04-architecture/brief.md` before running Create.

**Review:**
```
Execute the Architecture Overview review workflow using the orchestrator at:
{{AGENTS_PATH}}/04-architecture/review/orchestrator.md
```

**Expand:**
```
Execute the Architecture Overview expand workflow using the orchestrator at:
{{AGENTS_PATH}}/04-architecture/expand/orchestrator.md

Trigger: [description of what needs expanding, or path to a pending issue]
```

The expand workflow adds new architectural concerns to the Architecture Overview. Includes alignment verification against both PRD and Foundations. Use when scope changes require new components, data flows, or integration patterns that weren't in the original architecture. Expand never promotes — always follow with a Review round.

### Component Spec

**Initialize (once, before first component):**
```
Execute the Component Specs initialization workflow using the orchestrator at:
{{AGENTS_PATH}}/05-components/initialize/orchestrator.md
```

**Create (per component):**
```
Execute the Component Spec creation workflow using the orchestrator at:
{{AGENTS_PATH}}/05-components/create/orchestrator.md

Component: [component name]
```

Optional: place a per-component brief at `{{PROJECT_PATH}}/system-design/05-components/versions/[component-name]/brief.md` before running Create.

The create workflow iterates through **Explore** (identifies design concerns for the component — operation contracts, data model trade-offs, error vocabulary, atomicity boundaries — explores each in parallel, human reviews enrichments) and **Generate** (produces draft spec from Architecture + Foundations + accepted enrichments, with independent coverage verification against Architecture requirements, depth verification for minimum specification depth, then structured gap analysis) rounds — round 1 works from the Architecture + Foundations, round 2+ applies enrichments to the previous round's draft via the Enrichment Applicator. The human exits the loop by choosing to promote.

**Review (per component):**
```
Execute the Component Spec review workflow using the router at:
{{AGENTS_PATH}}/05-components/review/orchestrator-router.md

Component: [component name]
```

### Tasks

**Create all tasks (fully automated):**
```
Execute the Tasks workflow using the coordinator at:
{{AGENTS_PATH}}/06-tasks/coordinator.md
```

The coordinator initializes workflow state, computes dependency tiers, spawns pipeline runners as parallel subagents, and presents the final summary. A single invocation processes all components end-to-end.

**Manual alternative — run a single component:**
```
Execute the Tasks pipeline using:
{{AGENTS_PATH}}/06-tasks/pipeline-runner.md

Component: [component-name]
```

### Conventions

**Generate build conventions (stops for human approval):**

```
Execute the Conventions workflow using the coordinator at:
{{AGENTS_PATH}}/07-conventions/coordinator.md
```

The coordinator generates build conventions in batches (up to 4 sections in parallel), runs cross-reference review, and presents the assembled document for human approval. Re-invoke after reviewing to mark as approved.

**Manual alternative — run a single section:**
```
Execute the Conventions section pipeline using:
{{AGENTS_PATH}}/07-conventions/section-pipeline-runner.md

Section: N (Section Name)
```

### Build

**Run the build pipeline (conventions must be approved first):**

```
Execute the Build workflow using the coordinator at:
{{AGENTS_PATH}}/08-build/coordinator.md
```

The coordinator verifies conventions are approved, derives dependency tiers from the Architecture, and processes all components tier-by-tier — fully automated.

**Manual alternative — run a single component:**
```
Execute the Build pipeline using:
{{AGENTS_PATH}}/08-build/pipeline-runner.md

Component: [component-name]
```

### Verification

**Run build verification (build must be complete first):**

```
Execute the Verification workflow using the coordinator at:
{{AGENTS_PATH}}/09-verification/coordinator.md
```

The coordinator verifies build is complete, runs Phase 1 (mechanical — lint, types, imports) with an automated fix loop, then Phase 2 (unit tests) with a human checkpoint. Re-invoke after making changes to continue Phase 2.

### Provisioning

**Generate provisioning runbook and execute (verification must be complete first):**

```
Execute the Provisioning workflow using the coordinator at:
{{AGENTS_PATH}}/10-provisioning/coordinator.md
```

The coordinator generates a provisioning runbook from infrastructure tasks and built IaC, presents it for human triage, then executes approved items in dependency-ordered batches. Re-invoke after completing manual items to continue.

### Packaging

**Package the deliverable (provisioning must be complete first):**

```
Execute the Packaging workflow using the coordinator at:
{{AGENTS_PATH}}/11-packaging/coordinator.md
```

The coordinator generates developer-facing documentation, presents it for human review, then verifies package completeness.

### Operations Readiness

**Generate maintenance and operations artefacts (packaging must be complete first):**

```
Execute the Operations Readiness workflow using the coordinator at:
{{AGENTS_PATH}}/12-operations-readiness/coordinator.md
```

The coordinator extracts 9 artefacts from the completed design docs and build output — component map, contracts, risk profile, traceability (for System-Maintainer) and SLOs, monitoring definitions, deployment topology, runbooks, security posture (for System-Operator). All 5 extractors run in parallel, followed by a cross-reference consistency check and human review. This is the system-builder's final stage.

### Technical Writer Session

Run **after all review rounds are complete** and before promoting the final version. There's no value reviewing clarity mid-cycle when content might still change.

This is an **interactive session** - you'll review the document, discuss with the human, apply agreed changes, and update workflow state. All in one conversation.

```
Execute a Technical Writer Session using:
{{AGENTS_PATH}}/specialist-agents/technical-writer.md

Input:
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

## When to Use Expand vs Review

**Review** answers: "Is what's here correct and complete?" Use when you want experts to examine the document for issues, inconsistencies, and gaps in existing content.

**Expand** answers: "What's missing and what should we add?" Use when:
- A downstream stage discovers the document needs new capability areas (e.g., architecture review reveals the PRD needs a new component)
- A scope decision adds something that wasn't in the original document
- You identify an area that's underdeveloped and needs structured exploration

Expand never promotes — it always hands off to a Review round. The typical cycle after a scope change is: Expand → Review → Promote.

Downstream stages use Review rounds (not Expand) to catch up after upstream expansions. The review experts will naturally surface misalignment with updated upstream documents.

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
  - **round-N-create/** — Creation workflow rounds
  - **round-N-review/** — Review workflow rounds
  - **round-N-expand/** — Expand workflow rounds
  - **workflow-state.md** — Tracks current round, workflow type, and status
  - **deferred-items.md** — Content deferred from upstream stages
  - **pending-issues.md** — Issues for upstream stages

Round numbers are globally sequential across all workflow types (e.g., rounds 1-8 create, round 9 review, round 10 expand, round 11 review).

Stages 06–12 use different structures defined by their coordinators. Deferred items and pending issues apply to stages 01–05 only.

## Learning More

See `system-generator/builder/docs/overview.md` for framework details.
