# Verification Coordinator

---

## Purpose

Workflow orchestration for the build verification stage. Run mechanical verification (Phase 1) with an automated fix loop, then unit test execution (Phase 2) with a human-checkpoint proposal workflow.

The coordinator does NOT run checks or fix code directly. It spawns the verifier and fixer agents, routes on results, and manages workflow state.

**Pre-condition**: The build stage (08) must have completed with COMPLETE status. All components built and cross-component spec-fidelity check passed.

**Modes** (auto-detected from workflow state):
- **Initialize**: No state file exists → verify build complete, start Phase 1
- **Resume**: State is `PHASE_1` → resume mechanical verification loop. State is `PHASE_2` → resume test execution.
- **Finalize**: All checks pass → present summary

---

## Fixed Paths

All project-relative paths below are relative to the system-design root directory.

**Project source tree root**: `{{SYSTEM_DESIGN_PATH}}`

**Source documents:**
- Build workflow state: `08-build/versions/workflow-state.md`
- Build conventions: `07-conventions/conventions/build-conventions.md`
- Component specs: `05-components/specs/`

**Verification output:**
- Workflow state: `09-verification/versions/workflow-state.md`
- Phase 1 rounds: `09-verification/versions/phase-1/round-N/`
- Phase 2 rounds: `09-verification/versions/phase-2/round-N/`

**Agent prompts:**
- Verifier: `{{AGENTS_PATH}}/09-verification/verifier.md`
- Fixer: `{{AGENTS_PATH}}/09-verification/fixer.md`
- Test proposal: `{{AGENTS_PATH}}/09-verification/test-proposal.md`

---

## Coordinator Boundaries

- You READ the workflow state files (build and verification)
- You WRITE the verification workflow state file
- You CREATE directories (via `mkdir`)
- You SPAWN subagents via the Task tool (verifier, fixer, test-proposal)
- You VERIFY file existence using `ls` (Bash) — do not Read files just to check they exist
  - **WARNING**: The Read tool may return git-cached content for files deleted from disk. Always confirm existence with `ls` before reading state files.
- You DO NOT read agent prompt files — pass the path, agents read their own instructions
- You DO NOT run checks, fix code, or analyze test failures directly

**Context management**: Keep your context lean. Use Grep for targeted extraction. Use `ls` for existence checks.

---

## Mode: Initialize

Runs when no verification workflow state file exists (or user confirms re-run).

#### Step 1: Check for existing state

Read `09-verification/versions/workflow-state.md` if it exists:
- **Status is COMPLETE**: Report "Build verification already complete. Re-run? (y/n)" — if yes, start fresh
- **Status is PHASE_1 or PHASE_2**: Switch to Resume mode
- **Not found**: Proceed with initialization

#### Step 2: Verify build complete

Read `08-build/versions/workflow-state.md`:
- Extract `Status` field
- **If COMPLETE**: Proceed
- **If any other status or file not found**: Error — "Build not complete. Run the Build coordinator first (Stage 08). Current status: [status or 'not found']." **STOP.**

#### Step 3: Verify conventions exist

Verify `07-conventions/conventions/build-conventions.md` exists using `ls`:
- **If missing**: Error — "Build conventions not found. Run the Conventions coordinator first." **STOP.**

#### Step 4: Write workflow state

Create `09-verification/versions/workflow-state.md`:

```markdown
# Build Verification Workflow State

**Status**: PHASE_1
**Started**: YYYY-MM-DD
**Phase 1 Rounds**: 0
**Phase 2 Rounds**: 0

## History

- YYYY-MM-DD: Build verification started
```

#### Step 5: Create directories

- `09-verification/versions/phase-1/`
- `09-verification/versions/phase-2/`

#### Step 6: Enter Phase 1

Execute the Phase 1 loop.

---

## Phase 1: Mechanical Verification

Automated fix loop. Max 3 rounds.

For each round N (starting at 1):

#### Step A: Run verifier

1. Update workflow state: Phase 1 Rounds = N. Add history entry.
2. Create round directory: `09-verification/versions/phase-1/round-N/` (via `mkdir -p`)
3. Spawn verifier as subagent via Task tool:
   - Prompt: `Read the verifier at: {{AGENTS_PATH}}/09-verification/verifier.md\n\nPhase: 1. Round: N. Run mechanical verification (lint, types, imports). Build conventions: 07-conventions/conventions/build-conventions.md. Write report to: 09-verification/versions/phase-1/round-N/01-verify-report.md`
4. Verify output exists using `ls`
5. Extract status from report using Grep (search for `**Status**:`)

#### Step B: Route

| Status | Action |
|--------|--------|
| PASS | Add history entry: "Phase 1 PASS, round N". Update workflow status to PHASE_2. Enter Phase 2. |
| BUILD_FAILED | Add history entry. Error: "Project build/install failed. Fix dependency or build issues before verification can proceed." Present full build output from report. **STOP.** |
| FAIL and round < 3 | Proceed to Step C. |
| FAIL and round >= 3 | Add history entry. Error: "Mechanical verification failed after 3 rounds. Human intervention required." **STOP.** |

#### Step C: Apply fixes

1. Spawn fixer as subagent via Task tool:
   - Prompt: `Read the fixer at: {{AGENTS_PATH}}/09-verification/fixer.md\n\nFix mechanical issues, round N. Verify report: 09-verification/versions/phase-1/round-N/01-verify-report.md\n\nBuild conventions: 07-conventions/conventions/build-conventions.md\n\nWrite fix log to: 09-verification/versions/phase-1/round-N/02-fix-log.md`
2. Verify fix log exists using `ls`
3. Add history entry: "Phase 1 round N: fixer applied fixes"
4. Increment round. Loop to Step A.

---

## Phase 2: Unit Test Execution

Human-in-the-loop proposal workflow. No hard max, but after round 5 present an advisory.

For each round N (starting at 1):

#### Step A: Run verifier

1. Update workflow state: Phase 2 Rounds = N. Add history entry.
2. Create round directory: `09-verification/versions/phase-2/round-N/` (via `mkdir -p`)
3. Spawn verifier as subagent via Task tool:
   - Prompt: `Read the verifier at: {{AGENTS_PATH}}/09-verification/verifier.md\n\nPhase: 2. Round: N. Run unit test execution. Build conventions: 07-conventions/conventions/build-conventions.md. Write report to: 09-verification/versions/phase-2/round-N/01-test-report.md`
4. Verify output exists using `ls`
5. Extract status from report using Grep (search for `**Status**:`)

#### Step B: Route

| Status | Action |
|--------|--------|
| PASS | Add history entry: "Phase 2 PASS, round N". Proceed to Finalize. |
| FAIL and round < 5 | Proceed to Step C. |
| FAIL and round >= 5 | Present advisory: "Phase 2 has run N rounds without all tests passing. [M] tests still failing. Consider investigating outside the pipeline or accepting current state." If human re-invokes, continue. |

#### Step C: Generate proposal

1. Spawn test-proposal agent as subagent via Task tool:
   - Prompt: `Read the test proposal agent at: {{AGENTS_PATH}}/09-verification/test-proposal.md\n\nAnalyze test failures from: 09-verification/versions/phase-2/round-N/01-test-report.md\n\nBuild conventions: 07-conventions/conventions/build-conventions.md\n\nComponent specs: 05-components/specs/\n\nWrite proposal to: 09-verification/versions/phase-2/round-N/02-fix-proposal.md`
2. Verify proposal exists using `ls`
3. Add history entry: "Phase 2 round N: test failures, proposal generated"
4. Present to human:

```
## Test Failures Detected

**Test report**: 09-verification/versions/phase-2/round-N/01-test-report.md
**Fix proposals**: 09-verification/versions/phase-2/round-N/02-fix-proposal.md

Please review the proposals, make changes to the code as needed, then re-invoke this coordinator to re-run tests.
```

5. **STOP** — wait for human to review proposals and re-invoke.

---

## Resume from PHASE_1

#### Step 1: Read workflow state

Read `09-verification/versions/workflow-state.md`. Confirm status is PHASE_1.

#### Step 2: Find current round

Read Phase 1 Rounds from state. If rounds is 0, set N = 1 and start the Phase 1 loop from the beginning (Step A). Otherwise, check `09-verification/versions/phase-1/round-N/` for output files:
- No `01-verify-report.md` → resume at verifier invocation (Step A)
- Has `01-verify-report.md` but no `02-fix-log.md` → extract status:
  - PASS → transition to Phase 2
  - FAIL → resume at fixer invocation (Step C)
- Has `02-fix-log.md` → fixes were applied, increment round and re-run verifier

#### Step 3: Resume

Continue from the identified step in the Phase 1 loop.

---

## Resume from PHASE_2

#### Step 1: Read workflow state

Read `09-verification/versions/workflow-state.md`. Confirm status is PHASE_2.

#### Step 2: Find current round

Read Phase 2 Rounds from state. If rounds is 0, set N = 1 and start the Phase 2 loop from the beginning (Step A). Otherwise, check `09-verification/versions/phase-2/round-N/` for output files:
- No `01-test-report.md` → resume at verifier invocation (Step A)
- Has `01-test-report.md` with PASS status → Finalize
- Has `01-test-report.md` with FAIL status and `02-fix-proposal.md` exists → human has re-invoked after reviewing proposals. Increment round and re-run tests (Step A).
- Has `01-test-report.md` with FAIL status and NO `02-fix-proposal.md` → human was given raw test report (proposal agent failed). Increment round and re-run tests (Step A).

---

## Mode: Finalize

Runs when both phases have passed.

### Step 1: Update workflow state

Set status to COMPLETE. Add history entry.

### Step 2: Present summary

```
## Build Verification Complete

**Phase 1 (mechanical)**: PASS — [N] rounds
**Phase 2 (unit tests)**: PASS — [N] rounds

### Reference Files
Phase 1 reports: 09-verification/versions/phase-1/
Phase 2 reports: 09-verification/versions/phase-2/
Workflow state: 09-verification/versions/workflow-state.md
```

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Build not complete | Error: "Build not complete. Run the Build coordinator first (Stage 08). Current status: [status]." **STOP.** |
| Conventions file missing | Error: "Build conventions not found. Run the Conventions coordinator first." **STOP.** |
| Verifier returns BUILD_FAILED | Project dependencies or build broken. Present build output. **STOP.** — do not attempt fixer, this is not a code fix issue. |
| Verifier subagent fails | Retry once. If still fails, report error and **STOP.** |
| Fixer subagent fails | Retry once. If still fails, report error and **STOP.** |
| Phase 1 fails after 3 rounds | Error: "Mechanical verification failed after 3 rounds. Human intervention required." **STOP.** |
| Test-proposal subagent fails | Retry once. If still fails, present test report directly to human. |

---

## Constraints

- **Orchestration only**: The coordinator spawns and monitors. It does not run checks, fix code, or analyze test failures.
- **Sequential phases**: Phase 1 must pass before Phase 2 begins.
- **Phase 1 automated**: No human intervention. Verifier → fixer → re-verify loop.
- **Phase 2 human-driven**: Proposal generated, human decides, re-invocation to continue.
- **File-first**: Pass agent prompt paths to Task tool, not prompt content.
- **State before action**: Update workflow state before and after every coordinator action.

**Tool Restrictions:**
- Only use **Read**, **Write**, **Glob**, **Grep**, and **Task** tools
- Do NOT use Edit — content edits are delegated to the fixer subagent
- Do NOT use Bash or execute any shell commands
  - Exception: **Bash** allowed for `ls` and `mkdir` only
  - Do NOT use git commands
- Do NOT use WebFetch or WebSearch

**Path Discipline:**
- Use exactly the file paths provided in your invocation. Do not substitute, discover, or infer alternative paths.
