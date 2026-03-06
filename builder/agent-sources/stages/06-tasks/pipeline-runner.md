# Task Creation Pipeline Runner

---

## Purpose

Runs the full task creation pipeline for a single component: generate → check → consolidate → route → promote. Self-contained — operates in its own session with no dependency on other active sessions.

**Invocation**: Given a component name (e.g., "event-directory"), the runner derives all paths, verifies dependencies, and runs the pipeline to completion.

---

## Fixed Paths

All project-relative paths below are relative to the system-design root directory (the directory containing `03-foundations/`, `04-architecture/`, `05-components/`, `06-tasks/`).

**Source documents:**
- Architecture: `04-architecture/architecture.md`
- Foundations: `03-foundations/foundations.md`
- Component specs: `05-components/specs/`
- Infrastructure spec: `05-components/specs/infrastructure.md`
- Cross-cutting spec: `05-components/specs/cross-cutting.md`

**Task output:**
- Infrastructure: `06-tasks/tasks/infrastructure/infrastructure.md`
- Components: `06-tasks/tasks/components/[component-name].md`

**Versions and state:**
- Workflow state: `06-tasks/versions/workflow-state.md`
- Per-component rounds: `06-tasks/versions/[component-name]/round-N/`

**Worker agent prompts:**
- `{{AGENTS_PATH}}/06-tasks/infrastructure-generator.md`
- `{{AGENTS_PATH}}/06-tasks/task-generator.md`
- `{{AGENTS_PATH}}/06-tasks/spec-item-extractor.md`
- `{{AGENTS_PATH}}/06-tasks/coverage-checker.md`
- `{{AGENTS_PATH}}/06-tasks/coherence-checker.md`
- `{{AGENTS_PATH}}/06-tasks/spec-item-reviewer.md`
- `{{AGENTS_PATH}}/06-tasks/spec-item-corrector.md`
- `{{AGENTS_PATH}}/06-tasks/checker-consolidator.md`
- `{{AGENTS_PATH}}/06-tasks/reference-verifier.md`

**Task guide:** `{{GUIDES_PATH}}/06-tasks-guide.md`

---

## Runner Boundaries

- You READ workflow state, source documents, and agent outputs
- You SPAWN worker agents to do work (via Task tool)
- You UPDATE your component's row in the workflow state file
- You DO NOT read worker agent prompt files — agents read their own instructions
- You DO NOT modify other components' rows or the History section in workflow state

Rule: If a file path appears in your agent invocation, don't read it yourself. Only pass file PATHS — agents read files themselves.

---

## Startup

### Step 1: Read workflow state

Read `06-tasks/versions/workflow-state.md`. Find the row for your component in the Processing Order table.

- **If component not found**: Error — "Component [name] not found in workflow state."
- **If component status is COMPLETE**: Report "Tasks for [name] already complete." Stop.
- **If component status is FAILED**: Report "Tasks for [name] previously FAILED. To retry, reset status to PENDING in workflow state." Stop.
- **If component status is BLOCKED**: Report "Tasks for [name] is BLOCKED by [dependency]. Resolve the dependency first." Stop.

### Step 2: Determine component type

Read the Type column from the component's row:
- **infra**: Use infrastructure pipeline (infrastructure-generator, foundations + architecture as sources)
- **component**: Use component pipeline (task-generator, component spec as source)

### Step 3: Verify dependencies

Read the Dependencies column. For each dependency, check its Status in the Processing Order table.

- **All COMPLETE**: Proceed.
- **Any PENDING, GENERATING, CHECKING, PROMOTING**: Report "Waiting for dependencies: [list with statuses]. Cannot proceed yet." Stop.
- **Any FAILED**: Report "Dependency [name] has FAILED. This component is blocked." Update own status to BLOCKED with note "Blocked by [name]". Stop.

### Step 4: Resolve paths

Derive all paths from the component name and type:

**For infrastructure (type = infra):**
- Generator: `infrastructure-generator.md`
- Generator inputs: Foundations path, Architecture path, Infrastructure Spec path
- Extractor: `spec-item-extractor.md`
- Extractor inputs: Foundations path, Architecture path, Infrastructure Spec path
- Extractor output: `round-1/00-spec-items.md` (always round 1, reused across rounds)
- Reviewer: `spec-item-reviewer.md`
- Reviewer inputs: Foundations path, Architecture path, Infrastructure Spec path, Extractor output
- Reviewer output (findings): `round-1/00-spec-items-review.md`
- Corrector: `spec-item-corrector.md`
- Corrector inputs: Extractor output, Reviewer findings
- Corrector output (corrected items): `round-1/00-spec-items-reviewed.md`
- Coverage Checker spec items: `round-1/00-spec-items-reviewed.md` (corrected items, not raw extractor output)
- Coverage Checker sources: Foundations path, Architecture path, Infrastructure Spec path
- Coherence Checker sources: Foundations path, Architecture path, Infrastructure Spec path
- Other task files: none
- Infrastructure file: none (this IS the infrastructure file)
- Version directory: `06-tasks/versions/infrastructure/round-N/`
- Final location: `06-tasks/tasks/infrastructure/infrastructure.md`

**For components (type = component):**
- Generator: `task-generator.md`
- Generator inputs: `05-components/specs/[component-name].md`, Foundations path, Cross-cutting spec path
- Extractor: `spec-item-extractor.md`
- Extractor inputs: `05-components/specs/[component-name].md`
- Extractor output: `round-1/00-spec-items.md` (always round 1, reused across rounds)
- Reviewer: `spec-item-reviewer.md`
- Reviewer inputs: `05-components/specs/[component-name].md`, Extractor output
- Reviewer output (findings): `round-1/00-spec-items-review.md`
- Corrector: `spec-item-corrector.md`
- Corrector inputs: Extractor output, Reviewer findings
- Corrector output (corrected items): `round-1/00-spec-items-reviewed.md`
- Coverage Checker spec items: `round-1/00-spec-items-reviewed.md` (corrected items, not raw extractor output)
- Coverage Checker sources: `05-components/specs/[component-name].md`
- Coherence Checker sources: `05-components/specs/[component-name].md`, Foundations path, Architecture path
- Other task files: all existing `06-tasks/tasks/components/*.md` files (glob to discover)
- Infrastructure file: `06-tasks/tasks/infrastructure/infrastructure.md`
- Version directory: `06-tasks/versions/[component-name]/round-N/`
- Final location: `06-tasks/tasks/components/[component-name].md`

### Step 5: Resume check

If the component status is GENERATING, CHECKING, or PROMOTING (interrupted mid-pipeline):

1. Read the current round number from the Round column
2. Check what output files exist in `versions/[component]/round-N/` (round 1) or `versions/[component]/round-1/` (for extractor/reviewer/corrector outputs, which are always in round-1):
   - No `01-draft-tasks.md` and no `00-spec-items.md` → resume at Generate (round 1 spawns extractor + generator)
   - No `01-draft-tasks.md`, has `00-spec-items.md`, no `00-spec-items-reviewed.md` → spawn reviewer + corrector + generator (extractor done, rest pending)
   - No `01-draft-tasks.md`, has `00-spec-items-reviewed.md` → spawn generator only (extractor/reviewer/corrector done)
   - Has `01-draft-tasks.md`, no `00-spec-items-reviewed.md` → run extractor → reviewer → corrector chain, then proceed to Check
   - Has `01-draft-tasks.md` and `00-spec-items-reviewed.md`, no `01-reference-verification.md` (components only) → resume at Verify References
   - Has `01-draft-tasks.md` and `00-spec-items-reviewed.md`, has `01-reference-verification.md` (or infra type), no `03-consolidated-report.md` → resume at Check
   - Has `03-consolidated-report.md` → read the consolidated status and route accordingly
3. For rounds > 1: extractor, reviewer, and corrector outputs are always at `versions/[component]/round-1/` (reused)
4. Report: "Resuming [component] from [step], round [N]"

If the component status is PENDING, start at Generate, round 1.

---

## Pipeline

### Generate

1. Update workflow state: component status = GENERATING, round = N
2. Create round directory: `versions/[component]/round-N/` (via `mkdir -p`)
3. **Round 1**: Three sequential steps:

   **Step 3a**: Spawn the generator and extractor **in parallel** (both in a single message using Task tool):

   **For infrastructure:**

   Generator prompt: `Read the infrastructure task generator at: [infrastructure-generator.md path]\n\nGenerate infrastructure tasks. Foundations: [path]. Architecture: [path]. Infrastructure spec: [path]. Task guide: [task-guide path]. Write to: [round-1/01-draft-tasks.md path]`

   Extractor prompt: `Read the spec-item extractor at: [spec-item-extractor.md path]\n\nExtract spec items for infrastructure. Foundations: [path]. Architecture: [path]. Infrastructure spec: [path]. Write to: [round-1/00-spec-items.md path]`

   **For components:**

   Generator prompt: `Read the task generator at: [task-generator.md path]\n\nGenerate tasks for [component-name]. Source document: [component spec path]. Foundations: [path]. Cross-cutting spec: [path]. Other task files: [glob pattern or list]. Infrastructure task file: [path]. Task guide: [task-guide path]. Write to: [round-1/01-draft-tasks.md path]`

   Extractor prompt: `Read the spec-item extractor at: [spec-item-extractor.md path]\n\nExtract spec items for [component-name]. Source document: [component spec path]. Write to: [round-1/00-spec-items.md path]`

   Wait for both to complete.

   **Step 3b**: Spawn the reviewer (needs extractor output from step 3a):

   **For infrastructure:**

   Reviewer prompt: `Read the spec-item reviewer at: [spec-item-reviewer.md path]\n\nReview spec items for infrastructure. Foundations: [path]. Architecture: [path]. Infrastructure spec: [path]. Extractor output: [round-1/00-spec-items.md path]. Write findings to: [round-1/00-spec-items-review.md path]`

   **For components:**

   Reviewer prompt: `Read the spec-item reviewer at: [spec-item-reviewer.md path]\n\nReview spec items for [component-name]. Source document: [component spec path]. Extractor output: [round-1/00-spec-items.md path]. Write findings to: [round-1/00-spec-items-review.md path]`

   Wait for completion.

   **Step 3c**: Spawn the corrector (needs both extractor output and reviewer findings):

   Corrector prompt: `Read the spec-item corrector at: [spec-item-corrector.md path]\n\nCorrect spec items for [component-name]. Extractor output: [round-1/00-spec-items.md path]. Review findings: [round-1/00-spec-items-review.md path]. Write corrected items to: [round-1/00-spec-items-reviewed.md path]`

   Wait for completion.

   **Round 2+**: Spawn the generator only. The extractor, reviewer, and corrector outputs from round 1 are reused (the spec hasn't changed — only the tasks are being revised).

   **For infrastructure:**

   Generator prompt (round 2+): `Read the infrastructure task generator at: [infrastructure-generator.md path]\n\nFix infrastructure tasks, round N. Foundations: [path]. Architecture: [path]. Infrastructure spec: [path]. Task guide: [task-guide path]. Feedback report: [round-(N-1)/03-consolidated-report.md path]. Previous draft: [round-(N-1)/01-draft-tasks.md path]. Write to: [round-N/01-draft-tasks.md path]`

   **For components:**

   Generator prompt (round 2+): `Read the task generator at: [task-generator.md path]\n\nFix tasks for [component-name], round N. Source document: [path]. Foundations: [path]. Cross-cutting spec: [path]. Other task files: [glob or list]. Infrastructure task file: [path]. Task guide: [task-guide path]. Feedback report: [round-(N-1)/03-consolidated-report.md path]. Previous draft: [round-(N-1)/01-draft-tasks.md path]. Write to: [round-N/01-draft-tasks.md path]`

4. Verify output exists: `round-N/01-draft-tasks.md`
5. Verify extractor output exists: `versions/[component]/round-1/00-spec-items.md` (round 1 confirms creation; round 2+ confirms round-1 file still present)
6. Verify corrected spec items exist: `versions/[component]/round-1/00-spec-items-reviewed.md` (round 1 confirms creation; round 2+ confirms round-1 file still present)

### Verify References

**Components only** (skip for infrastructure):

1. Spawn Reference Verifier:

   Verifier prompt: `Read the reference verifier at: [reference-verifier.md path]\n\nVerify references for [component-name]. Task file: [round-N/01-draft-tasks.md path]. Component task files: 06-tasks/tasks/components/. Infrastructure task file: [infrastructure task path]. Write report to: [round-N/01-reference-verification.md path]`

2. Verify report exists: `round-N/01-reference-verification.md`
3. Proceed to Check.

### Check

1. Update workflow state: component status = CHECKING
2. Run Coverage Checker and Coherence Checker **in parallel** (spawn both as subagents using Task tool):

   **For infrastructure:**

   Coverage checker prompt: `Read the coverage checker at: [coverage-checker.md path]\n\nCheck coverage for infrastructure. Spec items file: [round-1/00-spec-items-reviewed.md path]. Source documents: [foundations path], [architecture path], [infrastructure spec path]. Task file: [round-N/01-draft-tasks.md path]. Write report to: [round-N/02-coverage-report.md path]`

   Coherence checker prompt: `Read the coherence checker at: [coherence-checker.md path]\n\nCheck coherence for infrastructure. Task file: [round-N/01-draft-tasks.md path]. Source documents: [foundations path], [architecture path], [infrastructure spec path]. Write report to: [round-N/02-coherence-report.md path]`

   **For components:**

   Coverage checker prompt: `Read the coverage checker at: [coverage-checker.md path]\n\nCheck coverage for [component-name]. Spec items file: [round-1/00-spec-items-reviewed.md path]. Source document: [component spec path]. Task file: [round-N/01-draft-tasks.md path]. Other task files: [glob pattern or list]. Infrastructure task file: [infrastructure task path]. Write report to: [round-N/02-coverage-report.md path]`

   Coherence checker prompt: `Read the coherence checker at: [coherence-checker.md path]\n\nCheck coherence for [component-name]. Task file: [round-N/01-draft-tasks.md path]. Source documents: [component spec path], [foundations path], [architecture path]. Other task files: [glob pattern or list]. Infrastructure task file: [infrastructure task path]. Write report to: [round-N/02-coherence-report.md path]`

3. Run Checker Consolidator:

   Consolidator prompt: `Read the checker consolidator at: [checker-consolidator.md path]\n\nConsolidate reports for [component-name]. Coverage report: [round-N/02-coverage-report.md path]. Coherence report: [round-N/02-coherence-report.md path]. Write report to: [round-N/03-consolidated-report.md path]`

4. Read consolidated status and route:

   | Status | Action |
   |--------|--------|
   | FAIL | Return to Generate with all issues as feedback. Increment round. |
   | PASS (with advisory) | Proceed to Promote. Remaining LOW items are genuinely advisory. |
   | PASS | Proceed to Promote. |

### Promote

1. Update workflow state: component status = PROMOTING
2. Copy task file to final location (via `cp`):
   - Infrastructure: `06-tasks/tasks/infrastructure/infrastructure.md`
   - Component: `06-tasks/tasks/components/[component-name].md`
3. Update workflow state: component status = COMPLETE, add round count and advisory count to Notes
4. Present completion summary:

```
## [Component Name] Tasks Complete

**Status**: COMPLETE
**Rounds**: [N]
**Tasks**: [count from promoted file]
**Advisory items**: [N] (LOW only)
**Final location**: [path to promoted file]
```

### Max Rounds

If the component reaches 5 rounds without achieving PASS or PASS (with advisory):
- Update workflow state: component status = FAILED, Notes = "Exceeded max rounds (5)"
- Present failure summary with the last consolidated report's issues
- Stop

---

## Workflow State Updates

Update only your component's row in the Processing Order table. Use the Edit tool targeting the unique component name in the table row.

**Fields to update:**
- **Status**: At each pipeline step transition (GENERATING → CHECKING → PROMOTING → COMPLETE)
- **Round**: Current round number
- **Last Updated**: Current date (YYYY-MM-DD)
- **Notes**: Completion info or failure reason

**Do NOT modify:**
- Other components' rows
- The History section
- The workflow Status field (IN_PROGRESS/CROSS_CHECKING/COMPLETE — coordinator manages this)

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Component not in workflow state | Error: report and stop |
| Dependencies not satisfied | Report what's missing and stop |
| Generator agent fails | Retry once. If still fails, mark component FAILED with reason. |
| Reviewer agent fails | Retry once. If still fails, mark component FAILED with reason. |
| Corrector agent fails | Retry once. If still fails, mark component FAILED with reason. |
| Checker agent fails | Retry once. If still fails, mark component FAILED with reason. |
| Component exceeds 5 rounds | Mark FAILED: "Exceeded max rounds (5)" |
| Workflow state file not found | Error: "Workflow state not found. Run the coordinator to initialize first." |

---

## Constraints

- **Fully automated**: Execute the entire pipeline without pausing for confirmation. Do not stop between steps to ask whether to proceed. The pipeline is designed to run to completion autonomously.
- **Single component**: Process only the named component. Do not process other components.
- **File-first**: Pass file paths to worker agents, not file contents. Agents read files themselves.
- **No expert review**: Tasks don't need expert review. The specs they're derived from are already reviewed.
- **Coverage, dependencies, and coherence are the gate**: The automated quality checks are:
  1. Every spec item from the reviewed extractor output has a corresponding task (Coverage Checker validates against reviewer-corrected output)
  2. All task dependencies resolve correctly, no circular dependencies (Coverage Checker)
  3. Runtime resource dependencies are acknowledged (Coherence Checker)
  4. Inter-task data flows are documented (Coherence Checker)
  5. Cross-component code dependencies are noted (Coherence Checker)
  6. Items within a task share prerequisites (Coherence Checker)
- **Blocking issues**: Coverage gaps, dependency issues, and HIGH or MEDIUM coherence issues trigger re-generation.
- **Advisory items**: LOW coherence issues are accepted as genuinely advisory and do not trigger re-generation.
- **Auto-promote on PASS**: On PASS (or PASS with advisory) the task file is promoted automatically.
- **State before action**: Update workflow state before and after every step transition. This enables resume on interruption.

<!-- INJECT: tool-restrictions -->
