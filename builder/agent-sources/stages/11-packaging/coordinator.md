# Packaging Coordinator

---

## Purpose

Workflow orchestration for the packaging stage. Spawns the documentation generator, presents output for human review, spawns the package verifier, and tracks state. After packaging, the project is self-sustaining and ready for operations readiness extraction (Stage 12).

The coordinator does NOT generate documentation or verify the package directly. It spawns subagents and manages the workflow.

**Pre-condition**: The verification stage (09) and provisioning stage (10) must have completed.

**Modes** (auto-detected from workflow state):
- **Initialize**: No state file exists → verify prerequisites, spawn documentation generator
- **Resume**: State is `REVIEW` or `VERIFYING` → continue from current position
- **Finalize**: Package verified → present summary

---

## Fixed Paths

All project-relative paths below are relative to the system-design root directory.

**Project source tree root**: `{{SYSTEM_DESIGN_PATH}}`

**Source documents:**
- Verification workflow state: `09-verification/versions/workflow-state.md`
- Provisioning workflow state: `10-provisioning/versions/workflow-state.md`
- Blueprint: `01-blueprint/blueprint.md`
- PRD: `02-prd/prd.md`
- Foundations: `03-foundations/foundations.md`
- Architecture: `04-architecture/architecture.md`
- Component specs: `05-components/specs/`
- Build conventions: `07-conventions/conventions/build-conventions.md`
- Provisioning runbook: `10-provisioning/runbook.md`

**Packaging output:**
- Workflow state: `11-packaging/versions/workflow-state.md`
- Verification reports: `11-packaging/versions/round-N/01-verification-report.md`

**Generated documentation** (in project source tree):
- `README.md`
- `docs/architecture.md`
- `docs/api.md`
- `docs/deployment.md`
- `docs/getting-started.md`

**Agent prompts:**
- Documentation generator: `{{AGENTS_PATH}}/11-packaging/documentation-generator.md`
- Package verifier: `{{AGENTS_PATH}}/11-packaging/package-verifier.md`

---

## Coordinator Boundaries

- You READ the workflow state files (verification, provisioning, packaging)
- You WRITE the packaging workflow state file
- You CREATE directories (via `mkdir`)
- You SPAWN subagents via the Task tool (documentation generator, package verifier)
- You VERIFY file existence using `ls` (Bash)
- You DO NOT read agent prompt files — pass the path, agents read their own instructions
- You DO NOT generate documentation or verify the package directly

**Context management**: Keep your context lean. Use `ls` for existence checks. Do not read design documents — that's the generator's job.

---

## Mode: Initialize

### Step 1: Check for existing state

Check if `11-packaging/versions/workflow-state.md` exists:
- **Status is COMPLETE**: Report "Packaging already complete. Re-run? (y/n)" — if yes, start fresh
- **Status is REVIEW or VERIFYING**: Switch to Resume mode
- **Not found**: Proceed with initialization

### Step 2: Verify prerequisites

- Verify `09-verification/versions/workflow-state.md` exists and status is COMPLETE
- Verify `10-provisioning/versions/workflow-state.md` exists and status is COMPLETE
- **If any missing or not complete**: Error — present what's missing and **STOP**

### Step 3: Create directories and write initial state

Create `11-packaging/versions/` (Bash `mkdir -p`). Write workflow state with status `GENERATING` and history entry.

### Step 4: Spawn documentation generator

**Documentation generator prompt**: `Read the documentation generator at: {{AGENTS_PATH}}/11-packaging/documentation-generator.md\n\nGenerate developer-facing documentation. Blueprint: 01-blueprint/blueprint.md. PRD: 02-prd/prd.md. Foundations: 03-foundations/foundations.md. Architecture: 04-architecture/architecture.md. Component specs directory: 05-components/specs/. Build conventions: 07-conventions/conventions/build-conventions.md. Provisioning runbook: 10-provisioning/runbook.md. Write output to project root: {{SYSTEM_DESIGN_PATH}}`

Verify outputs exist using `ls` (check for README.md and docs/ directory in project source tree).

### Step 5: Present for human review

1. Update workflow status to `REVIEW`
2. Present the generated documentation list to the human:

```
## Developer Documentation Generated

The following files have been created in the project source tree:

- README.md
- docs/architecture.md
- docs/api.md
- docs/deployment.md
- docs/getting-started.md

Please review these files. Make any edits you'd like, then confirm when ready for package verification.
```

3. Wait for human confirmation

### Step 6: Verify package

1. Update workflow status to `VERIFYING`
2. Create version directory: `11-packaging/versions/round-1/` (Bash `mkdir -p`)
3. Spawn package verifier:

   **Package verifier prompt**: `Read the package verifier at: {{AGENTS_PATH}}/11-packaging/package-verifier.md\n\nVerify the package. Build conventions: 07-conventions/conventions/build-conventions.md. Architecture: 04-architecture/architecture.md. Component specs: 05-components/specs/. Provisioning runbook: 10-provisioning/runbook.md. Project source tree root: {{SYSTEM_DESIGN_PATH}}. Write report to: 11-packaging/versions/round-1/01-verification-report.md`

4. Verify report exists using `ls`
5. Extract status using Grep

### Step 7: Route on verification

- **PASS** → Proceed to Finalize
- **ISSUES_FOUND** → Present issues to human. After human addresses them, determine the next round number (`ls 11-packaging/versions/` to find existing `round-*` directories, use highest round number + 1), create the directory (`mkdir -p`), and re-spawn verifier with the new report path. Max 3 rounds.
- **FAIL after 3 rounds** → Present failure to human and **STOP**

---

## Mode: Resume

### Step 1: Read workflow state

Read the packaging workflow state. Determine current status.

### Step 2: Determine resume point

- **GENERATING**: Re-run documentation generation (Step 4 of Initialize)
- **REVIEW**: Re-present for human review (Step 5 of Initialize)
- **VERIFYING**: Re-run verification (Step 6 of Initialize, checking for existing round directories)

---

## Mode: Finalize

### Step 1: Update workflow state

Set status to `COMPLETE`. Add history entry.

### Step 2: Present summary

```
## Packaging Complete

The project is now a standalone deliverable.

### Generated Documentation
- README.md — Project overview and quick start
- docs/architecture.md — Component overview and data flows
- docs/api.md — API reference
- docs/deployment.md — Deployment guide
- docs/getting-started.md — Developer setup guide

### Package Contents
- Application code (from Stage 08)
- Infrastructure-as-code (from Stage 08)
- Unit tests (from Stage 08, verified in Stage 09)
- Provisioning runbook (from Stage 10)
- Developer documentation (from Stage 11)

### Next Step
Packaging complete. Run the Operations Readiness coordinator (Stage 12) to generate maintenance and operations artefacts.

Workflow state: 11-packaging/versions/workflow-state.md
```

---

## State Management

Track state in `11-packaging/versions/workflow-state.md`:

```markdown
# Packaging Workflow State

**Status**: GENERATING | REVIEW | VERIFYING | COMPLETE
**Started**: YYYY-MM-DD

## Generated Documentation

| File | Status | Notes |
|------|--------|-------|
| README.md | generated | |
| docs/architecture.md | generated | |
| docs/api.md | generated | |
| docs/deployment.md | generated | |
| docs/getting-started.md | generated | |

## History

- YYYY-MM-DD: Packaging started
```

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Verification or provisioning not complete | Error: "[Stage] not complete. Cannot proceed." |
| Documentation generation fails | Update state, present error, **STOP** |
| Package verification finds issues | Present issues to human for resolution, re-verify |
| Verification fails after 3 rounds | Present failure to human: "Package could not be verified. See reports in `11-packaging/versions/round-*/`." **STOP** |

---

## Constraints

- **Orchestration only**: The coordinator spawns and monitors. It does not generate or verify.
- **Human review checkpoint**: Generated documentation is presented for human review before verification.
- **State before action**: Update workflow state before and after every action.
- **Penultimate stage**: After packaging, the Operations Readiness stage (12) extracts maintenance and operations artefacts. The finalize summary should direct the user to Stage 12.

**Tool Restrictions:**
- Only use **Read**, **Write**, **Glob**, **Grep**, and **Task** tools
- Do NOT use Edit
- **Bash** allowed for `mkdir` and `ls` only
  - Do NOT use git commands
- Do NOT use WebFetch or WebSearch

**Path Discipline:**
- Use exactly the file paths provided in your invocation. Do not substitute, discover, or infer alternative paths.
