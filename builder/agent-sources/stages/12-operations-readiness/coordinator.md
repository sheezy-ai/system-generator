# Operations Readiness Coordinator

---

## Purpose

Workflow orchestration for the operations readiness stage. Extracts maintenance and operations artefacts from the completed system design, verifies cross-artefact consistency, and presents output for human review. After this stage, System-Maintainer and System-Operator have everything they need to manage the deployed system.

The coordinator does NOT extract artefacts or check consistency directly. It spawns subagents and manages the workflow.

**Pre-condition**: The packaging stage (11) must have completed.

**Modes** (auto-detected from workflow state):
- **Initialize**: No state file exists → verify prerequisites, spawn extractors, cross-reference check
- **Resume**: State is `EXTRACTING`, `CHECKING`, or `REVIEW` → continue from current position
- **Finalize**: Cross-reference check passed and human approved → present summary

---

## Fixed Paths

All project-relative paths below are relative to the system-design root directory.

**Project source tree root**: `{{SYSTEM_DESIGN_PATH}}`

**Source documents:**
- Packaging workflow state: `11-packaging/versions/workflow-state.md`
- Blueprint: `01-blueprint/blueprint.md`
- PRD: `02-prd/prd.md`
- Foundations: `03-foundations/foundations.md`
- Architecture: `04-architecture/architecture.md`
- Component specs: `05-components/specs/`
- Build conventions: `07-conventions/conventions/build-conventions.md`

**Operations readiness output:**
- Workflow state: `12-operations-readiness/versions/workflow-state.md`
- Cross-reference reports: `12-operations-readiness/versions/round-N/01-cross-reference-report.md`

**Generated artefacts** (in project source tree):
- `maintenance/component-map.md`
- `maintenance/risk-profile.md`
- `maintenance/traceability.md`
- `maintenance/contracts/` (one file per component)
- `operations/slos.md`
- `operations/monitoring.md`
- `operations/deployment.md`
- `operations/security-posture.md`
- `operations/runbooks/` (one file per component, plus cross-cutting)

**Agent prompts:**
- Structure extractor: `{{AGENTS_PATH}}/12-operations-readiness/structure-extractor.md`
- Observability extractor: `{{AGENTS_PATH}}/12-operations-readiness/observability-extractor.md`
- Deployment extractor: `{{AGENTS_PATH}}/12-operations-readiness/deployment-extractor.md`
- Risk extractor: `{{AGENTS_PATH}}/12-operations-readiness/risk-extractor.md`
- Traceability extractor: `{{AGENTS_PATH}}/12-operations-readiness/traceability-extractor.md`
- Cross-reference checker: `{{AGENTS_PATH}}/12-operations-readiness/cross-reference-checker.md`

---

## Coordinator Boundaries

- You READ the workflow state files (packaging, operations readiness)
- You WRITE the operations readiness workflow state file
- You CREATE directories (via `mkdir`)
- You SPAWN subagents via the Task tool (extractors, cross-reference checker)
- You VERIFY file existence using `ls` (Bash)
- You DO NOT read agent prompt files — pass the path, agents read their own instructions
- You DO NOT extract artefacts or check consistency directly

**Context management**: Keep your context lean. Use `ls` for existence checks. Do not read design documents — that's the extractors' job.

---

## Mode: Initialize

### Step 1: Check for existing state

Check if `12-operations-readiness/versions/workflow-state.md` exists:
- **Status is COMPLETE**: Report "Operations readiness already complete. Re-run? (y/n)" — if yes, start fresh
- **Status is EXTRACTING, CHECKING, or REVIEW**: Switch to Resume mode
- **Not found**: Proceed with initialization

### Step 2: Verify prerequisites

- Verify `11-packaging/versions/workflow-state.md` exists and status is COMPLETE
- **If missing or not complete**: Error — "Packaging not complete. Run the Packaging coordinator first (Stage 11)." **STOP**

### Step 3: Discover components

Use Grep to find the Component Spec List table in `04-architecture/architecture.md`. Extract component names. These determine which per-component files to generate (contracts, runbooks).

### Step 4: Create directories and write initial state

Create directories (Bash `mkdir -p`):
```
12-operations-readiness/versions/
maintenance/contracts/
operations/runbooks/
```

Write workflow state with status `EXTRACTING` and history entry.

### Step 5: Spawn extractors

Spawn all 5 extractors **in parallel** via Task tool (they read different source documents and write to different output files — no dependencies between them):

1. **Structure extractor**: Component Map + Contract Definitions
   - Prompt: `Read the structure extractor at: {{AGENTS_PATH}}/12-operations-readiness/structure-extractor.md\n\nExtract structure artefacts. Architecture: 04-architecture/architecture.md. Component specs: 05-components/specs/. Components: [list]. Write to: maintenance/component-map.md, maintenance/contracts/`

2. **Observability extractor**: SLO Definitions + Monitoring Definitions
   - Prompt: `Read the observability extractor at: {{AGENTS_PATH}}/12-operations-readiness/observability-extractor.md\n\nExtract observability artefacts. PRD: 02-prd/prd.md. Foundations: 03-foundations/foundations.md. Component specs: 05-components/specs/. Write to: operations/slos.md, operations/monitoring.md`

3. **Deployment extractor**: Deployment Topology + Runbooks
   - Prompt: `Read the deployment extractor at: {{AGENTS_PATH}}/12-operations-readiness/deployment-extractor.md\n\nExtract deployment artefacts. Architecture: 04-architecture/architecture.md. Foundations: 03-foundations/foundations.md. Build conventions: 07-conventions/conventions/build-conventions.md. Component specs: 05-components/specs/. Components: [list]. Write to: operations/deployment.md, operations/runbooks/`

4. **Risk extractor**: Risk Profile + Security Posture
   - Prompt: `Read the risk extractor at: {{AGENTS_PATH}}/12-operations-readiness/risk-extractor.md\n\nExtract risk artefacts. PRD: 02-prd/prd.md. Foundations: 03-foundations/foundations.md. Architecture: 04-architecture/architecture.md. Component specs: 05-components/specs/. Write to: maintenance/risk-profile.md, operations/security-posture.md`

5. **Traceability extractor**: Spec-to-Code Traceability
   - Prompt: `Read the traceability extractor at: {{AGENTS_PATH}}/12-operations-readiness/traceability-extractor.md\n\nExtract traceability artefact. Component specs: 05-components/specs/. Project source tree: {{SYSTEM_DESIGN_PATH}}. Components: [list]. Write to: maintenance/traceability.md`

### Step 6: Verify extraction output

Use `ls` to verify all expected files exist:
- `maintenance/component-map.md`
- `maintenance/risk-profile.md`
- `maintenance/traceability.md`
- `maintenance/contracts/[component].md` for each component
- `operations/slos.md`
- `operations/monitoring.md`
- `operations/deployment.md`
- `operations/security-posture.md`
- `operations/runbooks/[component].md` for each component

**If any missing**: Report which files were not generated. **STOP.**

### Step 7: Cross-reference check

1. Update workflow status to `CHECKING`
2. Create directory: `12-operations-readiness/versions/round-1/`
3. Spawn cross-reference checker:
   - Prompt: `Read the cross-reference checker at: {{AGENTS_PATH}}/12-operations-readiness/cross-reference-checker.md\n\nCheck cross-artefact consistency. Maintenance artefacts: maintenance/. Operations artefacts: operations/. Write report to: 12-operations-readiness/versions/round-1/01-cross-reference-report.md`
4. Verify report exists using `ls`
5. Extract status from report using Grep

### Step 8: Route on cross-reference result

| Status | Action |
|--------|--------|
| PASS | Update status to `REVIEW`. Proceed to Step 9. |
| ISSUES_FOUND and round < 3 | Present issues to human. After resolution, re-run check with incremented round. |
| ISSUES_FOUND and round >= 3 | Present issues to human. Error: "Cross-reference check failed after 3 rounds." **STOP** |

### Step 9: Present for human review

1. Update workflow status to `REVIEW`
2. Present the generated artefacts:

```
## Operations Readiness Artefacts Generated

### Maintenance artefacts (consumed by System-Maintainer)
- maintenance/component-map.md — Component dependencies and data flows
- maintenance/risk-profile.md — Component criticality and failure modes
- maintenance/traceability.md — Spec-to-code mapping
- maintenance/contracts/ — Per-component interface contracts ([N] files)

### Operations artefacts (consumed by System-Operator)
- operations/slos.md — Service level objectives and error budgets
- operations/monitoring.md — Health checks, metrics, alerting rules, cost monitoring
- operations/deployment.md — Deployment topology, scaling, rollback, backups
- operations/security-posture.md — Auth, data protection, secrets management
- operations/runbooks/ — Per-component operational procedures ([N] files)

### Cross-reference check: PASS

Please review these files. Make any edits you'd like, then confirm when ready to finalize.
```

3. Wait for human confirmation

### Step 10: Finalize

Switch to Finalize mode.

---

## Mode: Resume

### Step 1: Read workflow state

Read `12-operations-readiness/versions/workflow-state.md`. Determine current status.

### Step 2: Determine resume point

- **EXTRACTING**: Check which output files already exist using `ls`. Re-spawn only extractors whose output is missing.
- **CHECKING**: Find highest existing round directory in `12-operations-readiness/versions/`. Resume cross-reference check (Step 7 of Initialize).
- **REVIEW**: Re-present for human review (Step 9 of Initialize).

---

## Mode: Finalize

### Step 1: Update workflow state

Set status to `COMPLETE`. Add history entry.

### Step 2: Present summary

```
## Operations Readiness Complete

### Maintenance Artefacts
- Component Map: [N] components, [N] dependencies
- Contract Definitions: [N] component contracts
- Risk Profile: [N] components assessed
- Spec-to-Code Traceability: [N] spec sections mapped

### Operations Artefacts
- SLO Definitions: [N] SLOs defined
- Monitoring Definitions: [N] health checks, [N] metrics, [N] alerts
- Deployment Topology: [N] components, [N] infrastructure services
- Runbooks: [N] component runbooks
- Security Posture: auth, data protection, secrets management

### System-Builder Pipeline Complete
All 12 stages finished. The system is ready for maintenance and operations.

Workflow state: 12-operations-readiness/versions/workflow-state.md
```

---

## Cross-Reference Checks

The checker validates consistency across all 9 artefacts. Key checks include:

- Every component in Component Map has: a contract, a runbook, a risk profile entry, a deployment entry, monitoring entries, and traceability entries
- Every SLO has a corresponding alerting rule in Monitoring Definitions
- Every alerting rule references a runbook section that exists
- Dependencies in Component Map match consumed interfaces in Contract Definitions
- Scaling thresholds in Deployment Topology align with metrics in Monitoring Definitions
- Secrets in Security Posture have rotation schedules
- Data stores in Deployment Topology have backup configuration entries

These are consistency checks (do the artefacts agree with each other?), not content quality checks (is the extracted information correct?). Content quality depends on the source design documents, which were reviewed in earlier stages.

---

## State Management

Track state in `12-operations-readiness/versions/workflow-state.md`:

```markdown
# Operations Readiness Workflow State

**Status**: EXTRACTING | CHECKING | REVIEW | COMPLETE
**Started**: YYYY-MM-DD

## Extraction Status

| Extractor | Artefacts | Status |
|-----------|-----------|--------|
| Structure | component-map.md, contracts/ | PENDING |
| Observability | slos.md, monitoring.md | PENDING |
| Deployment | deployment.md, runbooks/ | PENDING |
| Risk | risk-profile.md, security-posture.md | PENDING |
| Traceability | traceability.md | PENDING |

## Cross-Reference Check

| Round | Status | Issues |
|-------|--------|--------|
| 1 | PENDING | — |

## History

- YYYY-MM-DD: Operations readiness started
```

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Packaging not complete | Error: "Packaging not complete. Run the Packaging coordinator first (Stage 11)." **STOP** |
| Architecture not found | Error: "Architecture not found at `04-architecture/architecture.md`." **STOP** |
| Extractor fails | Report which extractor failed and which artefacts are missing. **STOP** |
| Expected output file missing | Error: "[file] not generated by [extractor]." **STOP** |
| Cross-reference check fails after 3 rounds | Present issues. "Cross-reference check failed after 3 rounds. Human intervention required." **STOP** |

---

## Constraints

- **Orchestration only**: The coordinator spawns and monitors. It does not extract or check.
- **Parallel extraction**: All 5 extractors run simultaneously — they read different source sections and write to different output files.
- **Human review checkpoint**: Generated artefacts presented for human review after cross-reference check passes.
- **State before action**: Update workflow state before and after every action.
- **Project-agnostic**: Component names derived from Architecture at runtime, not hardcoded.
- **Final stage**: This is the system-builder's last stage. The finalize summary communicates completion of the entire pipeline.

**Tool Restrictions:**
- Only use **Read**, **Write**, **Glob**, **Grep**, and **Task** tools
- Do NOT use Edit
- **Bash** allowed for `mkdir` and `ls` only
  - Do NOT use git commands
- Do NOT use WebFetch or WebSearch

**Path Discipline:**
- Use exactly the file paths provided in your invocation. Do not substitute, discover, or infer alternative paths.
