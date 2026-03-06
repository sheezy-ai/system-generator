# Conventions Coordinator

---

## Purpose

Workflow orchestration for the conventions stage. Generate build conventions section-by-section, cross-reference review, and present for human approval.

The coordinator does NOT generate or review conventions directly. It manages the workflow, spawns section pipeline runners (batched in parallel) and the cross-reference reviewer as subagents.

**Modes** (auto-detected from workflow state):
- **Initialize**: No state file exists → generate conventions section-by-section, present for approval, stop
- **Resume**: State is `GENERATING` → resume from first incomplete batch. State is `CROSS_REFERENCING` → resume cross-reference review. State is `AWAITING_APPROVAL` → present status and stop.
- **Complete**: State is `APPROVED` → report "Conventions already approved."

---

## Fixed Paths

**Source documents:**
- Architecture: `04-architecture/architecture.md`
- Foundations: `03-foundations/foundations.md`
- Component specs: `05-components/specs/`
- Task files: `06-tasks/tasks/`

**Conventions output:**
- Conventions sections: `07-conventions/conventions/sections/`
- Assembled conventions: `07-conventions/conventions/build-conventions.md`

**Versions and state:**
- Workflow state: `07-conventions/versions/workflow-state.md`
- Per-section versions: `07-conventions/conventions/versions/section-NN/round-N/`
- Per-section source items: `07-conventions/conventions/versions/section-NN/source-items.md`
- Per-section source items review: `07-conventions/conventions/versions/section-NN/source-items-review.md`
- Per-section source items (reviewed): `07-conventions/conventions/versions/section-NN/source-items-reviewed.md`
- Post-cross-reference versions: `07-conventions/conventions/versions/section-NN/xref-round-N/`
- Cross-reference versions: `07-conventions/conventions/versions/cross-reference/round-N/`

**Guides:**
- Conventions guide: `{{GUIDES_PATH}}/07-conventions-guide.md`

**Agent prompts:**
- Section pipeline runner: `{{AGENTS_PATH}}/07-conventions/section-pipeline-runner.md`
- Section reviewer: `{{AGENTS_PATH}}/07-conventions/conventions-reviewer.md`
- Cross-reference reviewer: `{{AGENTS_PATH}}/07-conventions/cross-reference-reviewer.md`
- Cross-reference fixer: `{{AGENTS_PATH}}/07-conventions/cross-reference-fixer.md`

All project-relative paths above are relative to the system-design root directory (the directory containing `03-foundations/`, `04-architecture/`, `05-components/`, `06-tasks/`, `07-conventions/`).

---

## Coordinator Boundaries

- You READ the workflow state file and targeted sections of the Architecture (not the full document)
- You WRITE the workflow state file (initialization, section progress, and finalization)
- You CREATE directories (via `mkdir`), COPY files (via `cp`), and ASSEMBLE files (via `cat`)
- You SPAWN subagents via the Task tool (section pipeline runners, cross-reference reviewer, cross-reference fixer)
- You VERIFY file existence using `ls` (Bash) — do not Read files just to check they exist
  - **WARNING**: The Read tool may return git-cached content for files deleted from disk. Always confirm existence with `ls` before reading state files.
- You DO NOT read agent prompt files — pass the path, agents read their own instructions
- You DO NOT generate or review conventions directly
- You DO NOT edit convention section content directly — the fixer handles all content edits

**Context management**: The coordinator spawns subagents that inherit its conversation context. Keep your context lean — every document you Read stays in context for the rest of the session. Use Grep for targeted extraction. Use `ls` for existence checks. Use `cp` for file copies. Do NOT Read files whose content you do not need to process.

---

## Conventions Section List

The conventions document is composed of 13 sections, generated and reviewed individually:

| # | Section Name | File Name | Batch |
|---|-------------|-----------|-------|
| 01 | Repository Structure | 01-repository-structure | 1 |
| 02 | Language & Runtime | 02-language-runtime | 1 |
| 03 | Dependency Management | 03-dependency-management | 1 |
| 04 | Module Structure | 04-module-structure | 1 |
| 05 | Import Conventions | 05-import-conventions | 2 |
| 06 | Configuration | 06-configuration | 2 |
| 07 | Error Handling | 07-error-handling | 2 |
| 08 | Logging | 08-logging | 2 |
| 09 | Testing | 09-testing | 3 |
| 10 | Database | 10-database | 3 |
| 11 | API Patterns | 11-api-patterns | 3 |
| 12 | Build & Run Commands | 12-build-run-commands | 4 |
| 13 | Code Style | 13-code-style | 3 |

Sections within a batch are processed in parallel. Section 12 (Batch 4) depends on sections 01–11.

---

## Mode: Initialize

Runs when no workflow state file exists (or user confirms re-run).

#### Step 1: Check for existing state

Read `07-conventions/versions/workflow-state.md` if it exists:
- **Status is APPROVED**: Report "Conventions already approved. Re-run? (y/n)" — if yes, start fresh
- **Status is GENERATING or CROSS_REFERENCING**: Switch to Resume mode
- **Status is AWAITING_APPROVAL**: Switch to Resume mode
- **Not found**: Proceed with initialization

#### Step 2: Verify prerequisites

Use `ls` (Bash) to verify each file exists — do NOT Read files for existence checks:

- Verify `03-foundations/foundations.md` exists
- Verify `04-architecture/architecture.md` exists
- Verify `05-components/specs/` directory has spec files
- Verify `06-tasks/tasks/` directory has task files
- **If any missing**: Error — "Missing: [list]. Cannot proceed."

#### Step 3: Write workflow state

Create `07-conventions/versions/workflow-state.md`:

```markdown
# Conventions Workflow State

**Status**: GENERATING
**Started**: YYYY-MM-DD

## Processing Order

| # | Section | File Name | Batch | Status | Round | Last Updated | Notes |
|---|---------|-----------|-------|--------|-------|--------------|-------|
| 01 | Repository Structure | 01-repository-structure | 1 | PENDING | - | - | |
| 02 | Language & Runtime | 02-language-runtime | 1 | PENDING | - | - | |
| 03 | Dependency Management | 03-dependency-management | 1 | PENDING | - | - | |
| 04 | Module Structure | 04-module-structure | 1 | PENDING | - | - | |
| 05 | Import Conventions | 05-import-conventions | 2 | PENDING | - | - | |
| 06 | Configuration | 06-configuration | 2 | PENDING | - | - | |
| 07 | Error Handling | 07-error-handling | 2 | PENDING | - | - | |
| 08 | Logging | 08-logging | 2 | PENDING | - | - | |
| 09 | Testing | 09-testing | 3 | PENDING | - | - | |
| 10 | Database | 10-database | 3 | PENDING | - | - | |
| 11 | API Patterns | 11-api-patterns | 3 | PENDING | - | - | |
| 12 | Build & Run Commands | 12-build-run-commands | 4 | PENDING | - | - | Depends on 01-11 |
| 13 | Code Style | 13-code-style | 3 | PENDING | - | - | |

## History

- YYYY-MM-DD: Conventions generation started
```

#### Step 4: Create directories

Create all directories upfront (Bash `mkdir -p`):

- `07-conventions/conventions/`
- `07-conventions/conventions/sections/`
- `07-conventions/conventions/versions/`
- `07-conventions/versions/`
- Per-section version directories (all 13):
  `07-conventions/conventions/versions/section-01/` through `07-conventions/conventions/versions/section-13/`

#### Step 5: Batch Processing Loop

Process sections in batches. Each batch spawns pipeline runners for all eligible sections in parallel. Accept 2–3 rounds per section as normal convergence.

For each batch (1 through 4):

##### Step 5a: Identify eligible sections

Read the Processing Order table. For the current batch, identify sections whose Status is NOT terminal (i.e., not COMPLETE or FAILED).

- **All sections in batch are terminal**: Skip to next batch.
- **Batch 4 only (section 12)**: Before spawning, verify all sections 01–11 have Status = COMPLETE. If any section 01–11 is FAILED, mark section 12 as FAILED with Notes = "Dependency failed: section NN". Skip to batch completion.

##### Step 5b: Spawn pipeline runners

Spawn a pipeline runner for each eligible section **in a single message** (parallel execution via Task tool):

- Runner prompt: `Read the section pipeline runner at: {{AGENTS_PATH}}/07-conventions/section-pipeline-runner.md\n\nProcess section N (Section Name).`

Wait for all runners in the batch to complete.

##### Step 5c: Record batch completion

After all runners in the batch complete:

1. Read the workflow state to get updated statuses
2. Add a single history entry summarizing the batch: "Batch B complete: section NN (Name) STATUS (R rounds)[, section NN (Name) STATUS (R rounds), ...]"
3. Proceed to the next batch

#### Step 6: Assemble conventions document

After all batches complete, verify all 13 sections have Status = COMPLETE in the Processing Order table. If any section is FAILED, present the failure and **STOP** (see Error Handling).

After all 13 sections pass:

1. Write the document header to `07-conventions/conventions/build-conventions.md` using the Write tool:

```markdown
# Build Conventions

**Generated**: YYYY-MM-DD
**Sources**: Foundations, Architecture, Component Specs, Task Files
**Status**: DRAFT — requires human approval before build pipeline proceeds
```

2. Append each section in order using Bash:

```bash
for f in 07-conventions/conventions/sections/{01,02,03,04,05,06,07,08,09,10,11,12,13}-*.md; do printf '\n---\n\n' >> 07-conventions/conventions/build-conventions.md && cat "$f" >> 07-conventions/conventions/build-conventions.md; done
```

3. Verify the assembled file exists using `ls`
4. Update workflow status to `CROSS_REFERENCING`. Add history entry: "All 13 sections passed. Conventions assembled. Entering cross-reference review."

#### Step 7: Cross-Reference Review

##### Step 7a: Review cross-references

- Set round = 1
- Create version directory: `07-conventions/conventions/versions/cross-reference/round-R/` (Bash `mkdir -p`)
- Spawn the cross-reference reviewer as a subagent via Task tool:
  - **Round 1** prompt: `Read the conventions cross-reference reviewer at: {{AGENTS_PATH}}/07-conventions/cross-reference-reviewer.md\n\nReview cross-references across all convention sections. Write review report to: 07-conventions/conventions/versions/cross-reference/round-R/02-review-report.md`
  - **Round > 1** prompt: `Read the conventions cross-reference reviewer at: {{AGENTS_PATH}}/07-conventions/cross-reference-reviewer.md\n\nReview cross-references across all convention sections, round R. Write review report to: 07-conventions/conventions/versions/cross-reference/round-R/02-review-report.md`
- Verify output exists using `ls`
- Extract status using Grep

##### Step 7b: Route

- **PASS** → Add history entry: "Cross-reference review round R: PASS". Proceed to Step 8.
- **FAIL and round < 3** → Add history entry: "Cross-reference review round R: FAIL — [issue count] issues". Handle fixes (see Step 7c). Increment round. Loop to Step 7a.
- **FAIL and round >= 3** → Add history entry: "Cross-reference review failed after 3 rounds". Present failure to user and **STOP** (see Error Handling).

##### Step 7c: Copy and fix cross-reference issues

When the cross-reference review fails, copy affected files then spawn the fixer to apply edits. The original reviewed section files are NOT modified directly.

1. **Read the review report's Action Required list** — use Grep to find "### Action Required", then Read with offset to identify affected section numbers
2. **For each affected section**:
   - Create version directory: `07-conventions/conventions/versions/section-NN/xref-round-R/` (Bash `mkdir -p`)
   - Copy the current section file to the version directory: `cp 07-conventions/conventions/sections/NN-file-name.md 07-conventions/conventions/versions/section-NN/xref-round-R/01-section.md`
3. **Spawn cross-reference fixer as subagent via Task tool**:
   - Prompt: `Read the cross-reference fixer at: {{AGENTS_PATH}}/07-conventions/cross-reference-fixer.md\n\nFix cross-reference issues from report: 07-conventions/conventions/versions/cross-reference/round-R/02-review-report.md\n\nAffected copies:\n- 07-conventions/conventions/versions/section-NN/xref-round-R/01-section.md\n[...one line per affected section]\n\nWrite fix log to: 07-conventions/conventions/versions/cross-reference/round-R/03-fix-log.md`
4. Verify fix log exists using `ls`
5. Record which section numbers were modified

**Principle**: The original section files in `07-conventions/conventions/sections/` are untouched. All edits are applied to copies in the version directory by the fixer subagent.

##### Step 7d: Re-review copies (source fidelity check)

For each section copy modified in Step 7c, verify the fix did not break source fidelity:

- Spawn the section reviewer as a subagent via Task tool:
  - Prompt: `Read the conventions section reviewer at: {{AGENTS_PATH}}/07-conventions/conventions-reviewer.md\n\nReview section N (Section Name), round 1. Conventions guide: {{GUIDES_PATH}}/07-conventions-guide.md. Section file: 07-conventions/conventions/versions/section-NN/xref-round-R/01-section.md. Source items file: 07-conventions/conventions/versions/section-NN/source-items-reviewed.md. Write review report to: 07-conventions/conventions/versions/section-NN/xref-round-R/02-review-report.md`
- Multiple section reviews can be spawned in parallel if they affect different sections
- Extract status from each review report using Grep

For each section copy that fails the re-review, run a targeted fix + re-review loop (round limit = 2):

- Copy the section to an incremented version directory for audit trail: `cp .../xref-round-R/01-section.md .../xref-round-R+1/01-section.md`
- Spawn cross-reference fixer as subagent with the re-review report and the new copy:
  - Prompt: `Read the cross-reference fixer at: {{AGENTS_PATH}}/07-conventions/cross-reference-fixer.md\n\nFix issues from report: 07-conventions/conventions/versions/section-NN/xref-round-R/02-review-report.md\n\nAffected copies:\n- 07-conventions/conventions/versions/section-NN/xref-round-R+1/01-section.md\n\nWrite fix log to: 07-conventions/conventions/versions/section-NN/xref-round-R+1/03-fix-log.md`
- Verify fix log exists using `ls`
- Re-run the section reviewer on the updated copy
- If PASS after fix: add history entry "Section NN (Section Name) post-cross-reference re-review: PASS". Proceed.
- If FAIL after 2 fix rounds: add history entry "Section NN source fidelity could not be restored after cross-reference fix — likely upstream source conflict". Present failure to user and **STOP** (see Error Handling).

##### Step 7e: Promote and re-assemble

After all modified section copies pass re-review:

1. **Promote**: Copy each validated version back to the live section location: `cp 07-conventions/conventions/versions/section-NN/xref-round-R/01-section.md 07-conventions/conventions/sections/NN-file-name.md`
2. **Re-assemble**: Re-assemble the conventions document (repeat Step 6 assembly command)
3. Add history entry: "Cross-reference fixes promoted for sections [list]. Conventions re-assembled."

#### Step 8: Present for approval

Update `Status` to `AWAITING_APPROVAL` in workflow state. Add history entry: "Conventions passed all reviews, awaiting human approval."

Present the conventions document to the user:
```
## Build Conventions Generated

The conventions document has been written to:
07-conventions/conventions/build-conventions.md

Automated review: All 13 sections PASS + cross-reference PASS
Section review reports: 07-conventions/conventions/versions/section-*/
Cross-reference report: 07-conventions/conventions/versions/cross-reference/

Please review the conventions document. When approved, re-invoke this coordinator to mark conventions as approved.

**To approve and continue:**
Re-run the coordinator — it will detect AWAITING_APPROVAL status and mark conventions as APPROVED.
```

**STOP** — do not proceed further. Wait for the human to review and approve.

---

### Resume from GENERATING

When the coordinator detects `GENERATING` status:

1. Read the Processing Order table from workflow state
2. Find the first batch (lowest batch number) that contains any non-terminal sections (Status is not COMPLETE or FAILED)
3. For that batch, spawn pipeline runners only for sections that are non-terminal — the runners handle their own file-existence-based resume logic internally
4. After the batch completes, add a history entry and continue with subsequent batches normally (Step 5)

### Resume from CROSS_REFERENCING

When the coordinator detects `CROSS_REFERENCING` status:

- Check `07-conventions/conventions/versions/cross-reference/` for the latest round directory
- Determine if review was completed or interrupted, and resume accordingly
- If cross-reference review failed and fixes were applied: check for `xref-round-R/` directories in modified sections to determine if per-section re-review was completed or interrupted

### Resume from AWAITING_APPROVAL

When the coordinator detects `AWAITING_APPROVAL` status:

1. Verify `07-conventions/conventions/build-conventions.md` exists
2. Update workflow state: set `Status` to `APPROVED`
3. Add history entry: "Conventions approved."

Present:
```
## Conventions Approved

Conventions marked as APPROVED. The build pipeline can now proceed.

To start the build pipeline, invoke the Build coordinator.
```

---

## State Management

Track workflow state in `07-conventions/versions/workflow-state.md`:

```markdown
# Conventions Workflow State

**Status**: GENERATING | CROSS_REFERENCING | AWAITING_APPROVAL | APPROVED
**Started**: YYYY-MM-DD

## Processing Order

| # | Section | File Name | Batch | Status | Round | Last Updated | Notes |
|---|---------|-----------|-------|--------|-------|--------------|-------|
| 01 | Repository Structure | 01-repository-structure | 1 | PENDING | - | - | |
...
| 13 | Code Style | 13-code-style | 3 | PENDING | - | - | |

## History

- YYYY-MM-DD: Conventions generation started
```

**Top-level Status values** (managed by coordinator):
- `GENERATING`: Per-section generation in progress
- `CROSS_REFERENCING`: All sections passed, cross-reference review in progress
- `AWAITING_APPROVAL`: All reviews passed, waiting for human approval
- `APPROVED`: Human approved, build pipeline can proceed

**Per-section Status values** (managed by pipeline runners):
- `PENDING`: Not yet started
- `GENERATING`: Section generation in progress
- `REVIEWING`: Section review in progress
- `COMPLETE`: Section passed review
- `FAILED`: Section could not pass review (terminal)

**Row-level ownership**: Each pipeline runner updates only its own section's row. The coordinator manages the top-level Status field and the History section. This avoids write conflicts when multiple runners execute in parallel.

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Architecture not found | Error: "Architecture Overview not found at `04-architecture/architecture.md`" |
| Foundations not found | Error: "Foundations not found at `03-foundations/foundations.md`" |
| Conventions file missing on resume | Error: "Conventions not found. Re-run assembly." |
| Pipeline runner marks section FAILED | The runner updates the section's row to FAILED. The coordinator reads this after batch completion, includes it in the history entry, and continues processing remaining batches. Assembly (Step 6) requires all 13 sections COMPLETE — if any are FAILED, present: "Section(s) NN failed. Review reports are in `07-conventions/conventions/versions/section-NN/round-*/02-review-report.md`. Human intervention required." **STOP.** |
| Cross-reference review failed after 3 rounds | Update workflow state with history entry. Present: "Cross-reference review could not pass after 3 rounds. Review reports are in `07-conventions/conventions/versions/cross-reference/round-*/02-review-report.md`. Human intervention required." **STOP.** |
| Per-section re-review failed after 2 rounds (post-cross-reference) | Update workflow state with history entry. Present: "Section NN (Section Name) source fidelity could not be restored after cross-reference fix. This indicates a conflict between source documents: the cross-reference review requires a change that contradicts the designated source requirements for this section. Review the cross-reference report at `07-conventions/conventions/versions/cross-reference/round-R/02-review-report.md` and the per-section review at `07-conventions/conventions/versions/section-NN/xref-round-*/02-review-report.md` to identify the conflicting requirements. Human resolution required." **STOP.** |

---

## Constraints

- **Orchestration**: The coordinator plans, spawns, and monitors. It does not generate or review conventions directly.
- **Human checkpoint**: Conventions require human approval. This is the purpose of the stage.
- **File-first**: Pass agent prompt paths to Task tool, not prompt content.
- **State before action**: Update workflow-state.md before and after every coordinator action.
- **Batched parallel processing**: Sections are processed in batches of up to 4. Each pipeline runner handles a single section autonomously. Assemble after all sections pass. Cross-reference review catches cross-section issues.

**Tool Restrictions:**
- Only use **Read**, **Write**, **Glob**, **Grep**, and **Task** tools
- Do NOT use Edit — content edits are delegated to the fixer subagent
- Do NOT use Bash or execute any shell commands
  - Exception: **Bash** allowed for `ls`, `mkdir`, `cp`, and `cat` only
  - Do NOT use git commands
- Do NOT use WebFetch or WebSearch

**Path Discipline:**
- Use exactly the file paths provided in your invocation. Do not substitute, discover, or infer alternative paths.
