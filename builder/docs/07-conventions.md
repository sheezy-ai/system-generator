# Conventions Stage

The conventions stage generates the build conventions document — a single, human-approved reference covering repository structure, language/runtime, dependencies, module structure, imports, configuration, error handling, logging, testing, database patterns, API patterns, and build commands. All derived from the design documents produced in stages 01–06.

---

## Purpose

| Aspect | Description |
|--------|-------------|
| **Input** | Foundations, Architecture, Component Specs, Task Files |
| **Output** | `build-conventions.md` — human-approved build standards |
| **Abstraction Level** | Concrete conventions: file paths, commands, config values, patterns |
| **Key Question** | "Do the conventions accurately reflect the design documents?" |

---

## What Belongs Here

- Build conventions document (13 sections, assembled)
- Individual convention section files
- Section version history (generation rounds, review reports)
- Cross-reference review reports
- Source item extractions

---

## What Does NOT Belong Here

- Application code (Build stage)
- Design decisions (Component Specs)
- Task definitions (Tasks stage)

---

## Workflow

### Section-by-Section Generation

The conventions document is composed of 13 sections, each generated and reviewed individually against a focused set of source documents:

1. Repository Structure
2. Language & Runtime
3. Dependency Management
4. Module Structure
5. Import Conventions
6. Configuration
7. Error Handling
8. Logging
9. Testing
10. Database
11. API Patterns
12. Build & Run Commands
13. Code Style

Each section uses 1–4 designated source sections (not the full corpus), preventing context overload and enabling accurate source tracing.

### Batched Per-Section Pipeline

Sections are processed in batches of up to 4 in parallel. Each section runs through the same pipeline autonomously via a dedicated pipeline runner:

```
Round 1:  Extract + Generate (parallel) → Review Items → Correct Items → Review → Route
Round 2+: Generate (with feedback) → Review → Route
```

Per-section pipeline steps:
1. **Extract source items** (round 1 only) — pre-compute explicit items from designated sources
2. **Review source items** (round 1 only) — check for missing, over-extracted, and granularity issues
3. **Correct source items** (round 1 only) — mechanically apply reviewer findings
4. **Generate** — produce the section from source documents
5. **Review** — structured review checking source fidelity and completeness against corrected source items
6. **Route** — PASS marks section COMPLETE, FAIL loops back to generate with feedback

Max 4 rounds per section. Accept 2–3 rounds as normal convergence.

**Batch assignments:**
- Batch 1: Sections 01–04 (Repository Structure, Language & Runtime, Dependency Management, Module Structure)
- Batch 2: Sections 05–08 (Import Conventions, Configuration, Error Handling, Logging)
- Batch 3: Sections 09–11 + 13 (Testing, Database, API Patterns, Code Style)
- Batch 4: Section 12 (Build & Run Commands — depends on sections 01–11)

### Cross-Reference Review

After all 13 sections pass individual review:
1. Assemble the full conventions document
2. Run cross-reference review (internal consistency + contradictions across sections)
3. On FAIL: copy affected sections to version directories, apply fixes to copies (Edit), re-review copies for source fidelity, promote validated copies back to live location (DEC-056)
4. Re-assemble after fixes

### Human Approval

Present the final document for human review. This is the **only human checkpoint** — all generation and review is automated.

---

## Orchestration Model

Conventions uses a **coordinator + pipeline runner** split:

### Coordinator (`coordinator.md`)

Manages the full conventions workflow:
- Verifies prerequisites
- Initializes workflow state with Processing Order table
- Spawns pipeline runners in batches (up to 4 sections per batch, parallel via Task tool)
- Tracks batch completion in History
- Assembles the document after all sections pass
- Runs cross-reference review with post-fix source fidelity checks
- Presents for human approval

Does not process sections directly — delegates to pipeline runners.

### Section Pipeline Runner (`section-pipeline-runner.md`)

Runs the full pipeline for a single section as a subagent. Spawns worker agents (generator, extractor, reviewers, corrector) and handles the generate → review → route loop. Updates only its own section's row in the Processing Order table.

### Source Item Extractor (`source-item-extractor.md`)

Pre-computes explicit items from each section's designated source documents. Produces a structured list that is reviewed and corrected before use — mechanical, not model-dependent.

### Source Item Reviewer (`source-item-reviewer.md`)

Reviews the extractor's output against designated source sections. Identifies missing items, over-extracted items, and granularity issues. Produces a findings report for the corrector.

### Source Item Corrector (`source-item-corrector.md`)

Mechanically applies the reviewer's findings to produce a corrected source items file. Adds missing items, removes over-extracted items, and resolves granularity issues. The corrected file is what the section reviewer uses for completeness checking.

### Section Generator (`conventions-generator.md`)

Generates a single conventions section from its designated source documents. Includes citation self-verification before output.

### Section Reviewer (`conventions-reviewer.md`)

Reviews a single section against its designated sources using a structured protocol:
- Enumerate claims (section → source direction)
- Read pre-computed source items (source → section direction)
- Verify claims (source fidelity)
- Check coverage (completeness)

### Cross-Reference Reviewer (`cross-reference-reviewer.md`)

Reviews the complete set of sections for internal consistency and contradictions. Catches cross-section issues that per-section reviewers cannot detect.

---

## File Paths

**Guide:**
```
guides/07-conventions-guide.md  # Section source mapping, content guide, shared quality checks
```

**Agent prompts:**
```
agents/07-conventions/
├── coordinator.md              # Workflow coordination (batches, assembly, cross-reference, approval)
├── section-pipeline-runner.md  # Per-section pipeline (extract + generate → review → route)
├── source-item-extractor.md    # Pre-computes source items per section
├── source-item-reviewer.md     # Reviews extractor output for accuracy
├── source-item-corrector.md    # Applies reviewer findings mechanically
├── conventions-generator.md    # Generates convention sections
├── conventions-reviewer.md     # Reviews sections against sources
├── cross-reference-reviewer.md # Reviews cross-section consistency
└── cross-reference-fixer.md    # Fixes cross-reference issues
```

**Output locations:**
```
system-design/07-conventions/
├── conventions/
│   ├── sections/                         # 13 individual section files
│   ├── build-conventions.md              # Assembled conventions document
│   └── versions/
│       ├── section-01/ through section-13/
│       │   ├── source-items.md           # Raw extractor output
│       │   ├── source-items-review.md    # Reviewer findings
│       │   ├── source-items-reviewed.md  # Corrected source items (used by section reviewer)
│       │   └── round-N/
│       │       ├── 01-section.md         # Section snapshot
│       │       └── 02-review-report.md   # Review report
│       └── cross-reference/
│           └── round-N/
│               └── 02-review-report.md   # Cross-reference report
└── versions/
    └── workflow-state.md                 # Conventions workflow state
```

---

## Invocation

**Generate conventions:**
```
Read the Conventions coordinator at:
agents/07-conventions/coordinator.md

Generate conventions.
```

This generates all sections, runs reviews, and stops for human approval.

**After approval, mark as approved:**
```
Read the Conventions coordinator at:
agents/07-conventions/coordinator.md

Generate conventions.
```

The coordinator detects AWAITING_APPROVAL status and marks conventions as APPROVED.

---

## State Management

Track workflow state in `versions/workflow-state.md`:

```markdown
# Conventions Workflow State

**Status**: GENERATING | CROSS_REFERENCING | AWAITING_APPROVAL | APPROVED
**Started**: YYYY-MM-DD

## Processing Order

| # | Section | File Name | Batch | Status | Round | Last Updated | Notes |
|---|---------|-----------|-------|--------|-------|--------------|-------|
| 01 | Repository Structure | 01-repository-structure | 1 | PENDING | - | - | |
| ... | | | | | | | |
| 12 | Build & Run Commands | 12-build-run-commands | 4 | PENDING | - | - | Depends on 01-11 |
| 13 | Code Style | 13-code-style | 3 | PENDING | - | - | |

## History

- YYYY-MM-DD: Conventions generation started
```

**Top-level Status values** (managed by coordinator): GENERATING, CROSS_REFERENCING, AWAITING_APPROVAL, APPROVED

**Per-section Status values** (managed by pipeline runners): PENDING → GENERATING → REVIEWING → COMPLETE (exception: FAILED)

**Ownership**: The coordinator manages the top-level Status and History. Each pipeline runner updates only its own section's row — avoiding write conflicts during parallel execution.
