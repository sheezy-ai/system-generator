# System-Builder Overview

System-builder is a framework for creating and refining product documentation through AI-assisted workflows. It guides a product from initial concept through to implementation-ready specifications.

## Start Here (New Developers)

If you're new to system-builder, read these docs in order:

1. **This file** (`overview.md`) - Understand stages, workflows, and structure
2. **`workflow-create.md`** - How documents are created (the primary workflow)
3. **`workflow-review.md`** - How documents are refined (iterative improvement)
4. **A stage doc** (e.g., `01-blueprint.md`) - See how a specific stage works

## Getting Started

### 1. Initialise the project

```bash
../init-project.sh
```

This creates the required `system/` directories, deferred items files, pending issues files, and shared files. Safe to run multiple times. The script lives at the system-generator root (one level above `builder/`).

### 2. Run a workflow

Each stage has an orchestrator that coordinates the workflow. To create a document:

```
Read the [Stage] creation orchestrator at:
agents/[stage]/create/orchestrator.md

Then create a [Document] from:
- Concept: [path to your concept document]

Start the creation workflow.
```

Example (creating a Blueprint):
```
Read the Blueprint creation orchestrator at:
agents/01-blueprint/create/orchestrator.md

Then create a Blueprint from:
- Concept: my-project/concept.md

Start the creation workflow.
```

The orchestrator will guide you through each step, pausing for human input where needed.

## Stage Progression

Documentation progresses through twelve stages, each building on the previous:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Blueprint  │ ──▶ │     PRD     │ ──▶ │ Foundations │
│   (why)     │     │   (what)    │     │  (shared)   │
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
       ┌───────────────────────────────────────┘
       ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Architecture│ ──▶ │  Component  │ ──▶ │    Tasks    │
│  Overview   │     │    Specs    │     │             │
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
       ┌───────────────────────────────────────┘
       ▼
┌─────────────┐     ┌─────────────┐     ┌──────────────┐
│ Conventions │ ──▶ │    Build    │ ──▶ │ Verification │
│  (standards)│     │   (code)    │     │  (execute)   │
└─────────────┘     └─────────────┘     └──────────────┘
                                               │
       ┌───────────────────────────────────────┘
       ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ Provisioning │ ──▶ │  Packaging   │ ──▶ │  Operations  │
│  (runbook)   │     │ (deliverable)│     │ (readiness)  │
└──────────────┘     └──────────────┘     └──────────────┘
```

| Stage | Purpose | Level of Detail |
|-------|---------|-----------------|
| **Blueprint** | Vision, problem, users, business model, MVP definition | Strategic. No implementation. |
| **PRD** | What a specific phase delivers, scope boundaries | Functional. What, not how. |
| **Foundations** | Shared conventions, technology choices, patterns | Technical but stable. |
| **Architecture Overview** | System decomposition, component boundaries, data flows | Structural. |
| **Component Specs** | How to build each component | Implementation-ready. |
| **Tasks** | Discrete implementable work units | Actionable. |
| **Conventions** | Build standards derived from design docs (human approval) | Concrete. File paths, commands, patterns. |
| **Build** | Working code from task files, spec-fidelity checked | Executable. Modules, tests, IaC. |
| **Verification** | Lint, type check, unit test execution on built code | Execution. Real tool output. |
| **Provisioning** | Provisioning runbook from infrastructure tasks + built IaC | Operational. Real infrastructure commands. |
| **Packaging** | Standalone deliverable with developer-facing documentation | Handoff. Self-sustaining project. |
| **Operations Readiness** | Maintenance and operations artefact extraction | Operational. SLOs, runbooks, traceability. |

Stages 01–05 have guides (in `guides/`) that define what belongs at each level of abstraction.

## Workflows

Each stage supports up to four workflows:

### Create Workflow

Creates a draft document from inputs (concept, upstream documents). The human augments the draft, then runs Review to refine it.

```
Concept/Upstream ──▶ Generator ──▶ Human augments ──▶ Review Workflow
```

- **Generator** produces an initial draft with gaps marked
- **Human** reviews and fills in answers to open questions
- **Review Workflow** refines the document through expert review cycles

**Blueprint exception:** Blueprint has a custom create workflow with an Explore phase (strategic dimension exploration, enrichment review with three-tier depth filtering), iterative rounds, and a separate Decision Orchestrator. See `01-blueprint.md` for details.

**PRD exception:** PRD has a custom create workflow with an Explore phase (capability area decomposition, parallel explorers, enrichment review), iterative rounds, and inline decision resolution (no separate Decision Orchestrator). See `02-prd.md` for details.

**Foundations exception:** Foundations has a custom create workflow with an Assess step (lightweight technology assessment against PRD constraints, human directional preferences) before generation. The assessment informs the Generator's proposals, reducing gaps. See `03-foundations.md` for details.

**Architecture exception:** Architecture has a custom create workflow with a full Explore phase (architectural concern identification, parallel concern explorers, enrichment review), iterative rounds (round 1 from PRD + Foundations, round 2+ from previous draft), and gap resolution. See `04-architecture.md` for details.

### Review Workflow

Refines an existing document through iterative review cycles.

```
Document ──▶ Experts ──▶ Consolidator ──▶ Scope Filter ──▶ Human marks ──▶ Inline Discussion ──▶ Author ──▶ Alignment Verifier ──▶ Change Verifier ──┐
    ▲                                                                                                                                                    │
    └────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

- **Experts** identify issues (problems with existing content)
- **Human** responds naturally to each issue (no special keywords needed)
- **Inline Discussion** proposes and refines solutions within the issues-discussion file
- **Alignment Verifier** verifies document still aligns with sources after changes
- **Change Verifier** confirms approved solutions were applied correctly

Review cycles repeat until the document is satisfactory.

### Expand Workflow

Adds new capability areas or scope changes to an existing document. Used when downstream work discovers that an upstream document needs new content that wasn't in the original scope.

```
Trigger ──▶ Scope Analyst ──▶ Human reviews brief ──▶ Explorers ──▶ Proposal Filter ──▶ Human reviews proposals ──▶ Integration Author ──▶ Verification ──┐
                                                                                                                                                          │
                                                                                                                                               CLEAN? ──▶ Done
```

- **Scope Analyst** turns the trigger (pending issue, conversation, human description) into a structured Expansion Brief with capability areas
- **Explorers** investigate each capability area and produce complete change sets (new content, modified content, cross-section implications)
- **Proposal Filter** checks level-appropriateness and formats proposals for human review with full content preserved
- **Integration Author** applies approved changes so the document reads as if the capability was always in scope
- **Verification** reuses the review workflow's verification agents (alignment, coherence, enumeration, change verification)

Expand never promotes — always follow with a Review round. Available for stages 01–04.

See `workflow-expand.md` for details.

### Promote Workflow

Freezes a reviewed document by splitting it into three published files — the clean current-scope spec (`[document].md`), `decisions.md` (rationale), and `future.md` (deferred items). Promote is a separately-triggered workflow (not a step of Review), recorded as its own `round-N-promote` round.

```
Reviewed document ──▶ Guard (last round was Review) ──▶ Promoter (split) ──▶ Record ──▶ Done
```

- **Review-mandatory guard** — Promote refuses to run unless the last completed round was Review, so an unreviewed draft can never become a published spec
- **Promoter** — the sole producer of the published spec; splits the reviewed document into spec / decisions / future
- **Record** — captured under `round-N-promote/` (input snapshot + copies + metadata)

At review exit (zero-issues gate or maturity), Review completes and *recommends* running Promote — it no longer promotes automatically. Available for stages 02–04. Architecture additionally runs a contract completeness/freezability gate and materializes the frozen contract registry for stage 05; stage 05 uses its own spec-promoter. See `workflow-promote.md` for details.

## Key Concepts

### Agents

Agents are AI prompts with specific roles. Each agent:
- Has a single responsibility (generate, review, merge, etc.)
- Reads from files, writes to files (file-first operation)
- Does not receive content passed inline—only file paths

Agents are either **universal** (apply to all stages) or **stage-specific** (tailored to a particular stage).

**Universal agents in standard workflows:**
- **Scope Filter** - Filters content to the appropriate abstraction level
- **Issue Analyst** - Analyses issues with options and recommendations before human review
- **Discussion Facilitator** - Facilitates iterative discussions to resolve issues (batched, with context)
- **Alignment Verifier** - Verifies document aligns with its source documents
- **Human Guidelines** - Guidance for human reviewers (reference, not an agent)

**Universal agents triggered manually (optional):**
- **Skeptic** - Cross-cutting expert that challenges assumptions and identifies weaknesses
- **Technical Writer** - Improves document clarity and consistency

See `workflow-create.md` and `workflow-review.md` for details on all agent types.

### Orchestrators

Orchestrators coordinate multi-step workflows. They:
- Manage workflow state (current step, status)
- Invoke agents in sequence
- Handle human interaction points
- Track progress in a state file

Each stage has a Create orchestrator and a Review orchestrator. Stages 01–04 also have an Expand orchestrator.

### Deferred Items

Content sometimes belongs at a different abstraction level than where it was raised. Deferred items files capture this content for the appropriate stage.

- Blueprint deferred items → holds PRD-level content found during Blueprint work
- PRD deferred items → holds Foundations-level content
- And so on

The Scope Filter agent filters content to deferred items files. This keeps each stage focused on its appropriate level of detail.

### Pending Issues

When working on a downstream document, you may discover that an upstream document has a problem (contradiction, missing requirement, etc.). Pending issues capture these for the upstream stage to address.

- PRD pending issues → problems in the PRD found during Foundations/Architecture work
- Blueprint pending issues → problems in the Blueprint found during PRD work
- And so on

**Deferred items flow downstream** (content that's too detailed for current stage). **Pending issues flow upstream** (problems in source documents discovered during downstream work).

The Alignment Verifier identifies pending issues. See `workflow-create.md` and `workflow-review.md` for details.

### Human Review

Workflows pause for human input at defined points:
- **Create workflow**: After issues are consolidated and filtered
- **Review workflow**: After issues are consolidated, and again after solutions are proposed

Humans provide decisions, answer questions, and approve changes. Guidance is in `docs/human-review-guide.md`.

## Directory Structure

```
/                                  # Repository root
├── agents/                        # Built agent prompts (output of build)
│   ├── 01-blueprint/
│   │   ├── create/
│   │   │   ├── orchestrator.md
│   │   │   ├── dimension-identifier.md
│   │   │   ├── dimension-explorer.md
│   │   │   ├── exploration-consolidator.md
│   │   │   ├── enrichment-scope-filter.md
│   │   │   ├── enrichment-author.md
│   │   │   ├── decision-orchestrator.md
│   │   │   ├── decision-framework.md
│   │   │   ├── decision-analyst.md
│   │   │   ├── generator.md
│   │   │   ├── author.md
│   │   │   └── scope-extractor.md
│   │   ├── review/
│   │   │   ├── orchestrator.md
│   │   │   ├── author.md
│   │   │   ├── consolidator.md
│   │   │   ├── change-verifier.md
│   │   │   └── experts/
│   │   └── expand/
│   │       ├── orchestrator.md
│   │       ├── scope-analyst.md
│   │       ├── expansion-explorer.md
│   │       ├── proposal-filter.md
│   │       └── integration-author.md
│   ├── 02-prd/
│   │   ├── create/...
│   │   ├── review/...
│   │   └── expand/...            # Same structure as Blueprint expand
│   ├── 03-foundations/
│   │   ├── create/
│   │   │   ├── orchestrator.md
│   │   │   ├── assessor.md
│   │   │   ├── generator.md
│   │   │   └── author.md
│   │   └── review/...
│   ├── 04-architecture/
│   │   ├── create/
│   │   │   ├── orchestrator.md
│   │   │   ├── concern-identifier.md
│   │   │   ├── concern-explorer.md
│   │   │   ├── exploration-consolidator.md
│   │   │   ├── enrichment-scope-filter.md
│   │   │   ├── enrichment-author.md
│   │   │   ├── generator.md
│   │   │   ├── enrichment-applicator.md
│   │   │   ├── requirements-extractor.md
│   │   │   ├── coverage-checker.md
│   │   │   └── author.md
│   │   └── review/...
│   ├── 05-components/              # Component Specs
│   ├── 06-tasks/                  # Task pipeline agents
│   ├── 07-conventions/            # Conventions pipeline agents
│   ├── 08-build/                  # Build pipeline agents
│   ├── 09-verification/           # Build verification agents
│   ├── 10-provisioning/           # Infrastructure provisioning agents
│   ├── 11-packaging/              # Deliverable packaging agents
│   ├── 12-operations-readiness/   # Maintenance and operations artefact extraction
│   ├── universal-agents/
│   │   ├── alignment-verifier.md
│   │   ├── discussion-facilitator.md
│   │   ├── scope-filter.md
│   │   ├── issue-analyst.md
│   │   ├── pending-issue-resolver.md
│   │   ├── gap-formatter.md
│   │   └── gap-analyst.md
│   └── specialist-agents/
│       └── technical-writer.md
├── agent-sources/                 # Source templates for agents
│   ├── stage-config.sh            # Stage configuration
│   ├── common/                    # Shared content injected into prompts
│   ├── stages/                    # Stage-specific templates
│   └── universal-agents/          # Universal agent templates
├── docs/                          # Framework documentation
│   ├── overview.md                # This file
│   ├── workflow-create.md
│   ├── workflow-review.md
│   └── design-decisions.md
├── guides/                        # What belongs at each stage
│   ├── 01-blueprint-guide.md
│   ├── 02-prd-guide.md
│   └── ...
└── system/                        # Output (generated documents)
    ├── 01-blueprint/
    │   ├── blueprint.md
    │   └── versions/
    └── ...
```

Scripts `init-project.sh` and `build-prompts.sh` live at the system-generator root (one level above `builder/`).

## Round Numbering

Rounds use a **unified sequential numbering** with a workflow type suffix:

```
versions/
├── round-1-create/
├── round-2-create/
├── ...
├── round-8-create/
├── round-9-review/
├── round-10-review/
├── round-11-expand/
├── round-12-review/
└── workflow-state.md
```

The round number is globally sequential across all workflow types. The suffix (`-create`, `-review`, `-expand`) indicates which workflow produced the round. This provides a single chronological timeline of all work on a document.

All rounds for a stage share a `versions/` folder with a unified state file. The state file's `Current Round` is the global round number, and `Current Workflow` indicates the active workflow type.

**Source path resolution**: When starting a new round, the orchestrator always uses the last completed round's full output document — never the promoted file. Promoted files may have been split (rationale → `decisions.md`, future → `future.md`), so using them as input would lose content.

## Further Reading

- `workflow-create.md` - Create workflow mechanics and agent details
- `workflow-create.md` - Three pre-generation intensity levels (Direct, Select, Explore)
- `workflow-review.md` - Review workflow mechanics and agent details
- `workflow-expand.md` - Expand workflow mechanics and agent details
- `design-decisions.md` - Why the system is designed this way
- `01-blueprint.md` - Blueprint stage documentation
