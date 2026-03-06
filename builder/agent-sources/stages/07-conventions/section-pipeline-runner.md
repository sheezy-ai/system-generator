# Conventions Section Pipeline Runner

---

## Purpose

Runs the full conventions pipeline for a single section: generate → review → route, with source item extraction/review/correction on round 1. Self-contained — operates in its own session with no dependency on other active sessions.

**Invocation**: `Process section N (Section Name).` The runner reads the Processing Order table to derive all paths and runs the pipeline to completion.

---

## Fixed Paths

All project-relative paths below are relative to the system-design root directory (the directory containing `03-foundations/`, `04-architecture/`, `05-components/`, `06-tasks/`, `07-conventions/`).

**Source documents:**
- Architecture: `04-architecture/architecture.md`
- Foundations: `03-foundations/foundations.md`
- Component specs: `05-components/specs/`
- Task files: `06-tasks/tasks/`

**Conventions output:**
- Conventions sections: `07-conventions/conventions/sections/`

**Versions and state:**
- Workflow state: `07-conventions/versions/workflow-state.md`
- Per-section versions: `07-conventions/conventions/versions/section-NN/round-N/`
- Per-section source items: `07-conventions/conventions/versions/section-NN/source-items.md`
- Per-section source items review: `07-conventions/conventions/versions/section-NN/source-items-review.md`
- Per-section source items (reviewed): `07-conventions/conventions/versions/section-NN/source-items-reviewed.md`

**Conventions guide:** `{{GUIDES_PATH}}/07-conventions-guide.md`

**Worker agent prompts:**
- `{{AGENTS_PATH}}/07-conventions/source-item-extractor.md`
- `{{AGENTS_PATH}}/07-conventions/source-item-reviewer.md`
- `{{AGENTS_PATH}}/07-conventions/source-item-corrector.md`
- `{{AGENTS_PATH}}/07-conventions/conventions-generator.md`
- `{{AGENTS_PATH}}/07-conventions/conventions-reviewer.md`

---

## Runner Boundaries

- You READ the workflow state file to find your section's row and derive paths
- You SPAWN worker agents to do work (via Task tool)
- You UPDATE only your section's row in the Processing Order table (via Edit tool)
- You VERIFY file existence using `ls` (Bash) — do not Read files just to check they exist
  - **WARNING**: The Read tool may return git-cached content for files deleted from disk. Always confirm existence with `ls` before reading state files.
- You DO NOT read worker agent prompt files — pass the path, agents read their own instructions
- You DO NOT modify other sections' rows or the History section in workflow state
- You DO NOT generate or review conventions directly

Rule: If a file path appears in your agent invocation, don't read it yourself. Only pass file PATHS — agents read files themselves.

---

## Startup

### Step 1: Read workflow state

Read `07-conventions/versions/workflow-state.md`. Find the row for your section number in the Processing Order table.

- **If section not found**: Error — "Section [N] not found in workflow state."
- **If section status is COMPLETE**: Report "Section [N] ([Name]) already complete." Stop.
- **If section status is FAILED**: Report "Section [N] ([Name]) previously FAILED." Stop.

### Step 2: Resolve paths

Read the File Name column from your section's row. Derive all paths:

- Section number (NN): zero-padded from invocation (e.g., "01", "12")
- File stem: from the File Name column (e.g., "01-repository-structure")
- Section output: `07-conventions/conventions/sections/[file-stem].md`
- Version directory: `07-conventions/conventions/versions/section-NN/`
- Round directory: `07-conventions/conventions/versions/section-NN/round-R/`
- Source items: `07-conventions/conventions/versions/section-NN/source-items.md`
- Source items review: `07-conventions/conventions/versions/section-NN/source-items-review.md`
- Source items reviewed: `07-conventions/conventions/versions/section-NN/source-items-reviewed.md`

### Step 3: Resume check

Check what files exist in the version directory using `ls`:

1. **No round directories and no `source-items.md`**: Nothing started. Start at Pipeline round 1.
2. **`source-items.md` exists but no `source-items-review.md`**: Extractor completed but reviewer not started. Check if section file exists — spawn generator (if missing) and reviewer.
3. **`source-items.md` and `source-items-review.md` exist but no `source-items-reviewed.md`**: Reviewer completed but corrector not started. Spawn corrector.
4. **`source-items-reviewed.md` exists**: Source items chain complete. Check round directories:
   - **No round directories**: Generator was interrupted. Resume at Pipeline round 1 (generator only, source items already done).
   - **Highest round directory exists**: Check its contents with `ls`:
     - No `01-section.md`: Generation interrupted. Resume at Generate for this round.
     - `01-section.md` exists but no `02-review-report.md`: Review interrupted. Resume at Review.
     - Both exist: Extract status via Grep. If PASS, update status to COMPLETE and stop. If FAIL and round < 4, increment round, resume at Generate. If FAIL and round >= 4, mark FAILED and stop.

Report: "Resuming section [N] ([Name]) from [step], round [R]"

If status is PENDING, start at Pipeline round 1.

---

## Pipeline

### Generate (Round 1)

1. Update workflow state row: Status = GENERATING, Round = 1
2. Create round directory: `07-conventions/conventions/versions/section-NN/round-1/` (Bash `mkdir -p`)
3. **Step 3a**: Spawn the section generator and source item extractor **in parallel** (both in a single message using Task tool):
   - Generator prompt: `Read the conventions section generator at: {{AGENTS_PATH}}/07-conventions/conventions-generator.md\n\nGenerate section N (Section Name). Conventions guide: {{GUIDES_PATH}}/07-conventions-guide.md. Write to: 07-conventions/conventions/sections/[file-stem].md`
   - Extractor prompt: `Read the source item extractor at: {{AGENTS_PATH}}/07-conventions/source-item-extractor.md\n\nExtract source items for section N (Section Name). Conventions guide: {{GUIDES_PATH}}/07-conventions-guide.md. Write to: 07-conventions/conventions/versions/section-NN/source-items.md`
   - Verify outputs exist using `ls`:
     - `07-conventions/conventions/sections/[file-stem].md`
     - `07-conventions/conventions/versions/section-NN/source-items.md`

4. **Step 3b**: Spawn the source item reviewer (needs extractor output from step 3a):
   - Reviewer prompt: `Read the source item reviewer at: {{AGENTS_PATH}}/07-conventions/source-item-reviewer.md\n\nReview source items for section N (Section Name). Conventions guide: {{GUIDES_PATH}}/07-conventions-guide.md. Extractor output: 07-conventions/conventions/versions/section-NN/source-items.md. Write findings to: 07-conventions/conventions/versions/section-NN/source-items-review.md`
   - Verify output exists using `ls`: `07-conventions/conventions/versions/section-NN/source-items-review.md`

5. **Step 3c**: Spawn the source item corrector (needs extractor output + reviewer findings):
   - Corrector prompt: `Read the source item corrector at: {{AGENTS_PATH}}/07-conventions/source-item-corrector.md\n\nCorrect source items for section N (Section Name). Extractor output: 07-conventions/conventions/versions/section-NN/source-items.md. Review findings: 07-conventions/conventions/versions/section-NN/source-items-review.md. Write corrected items to: 07-conventions/conventions/versions/section-NN/source-items-reviewed.md`
   - Verify output exists using `ls`: `07-conventions/conventions/versions/section-NN/source-items-reviewed.md`

6. Copy section to version directory using Bash `cp`: `cp 07-conventions/conventions/sections/[file-stem].md 07-conventions/conventions/versions/section-NN/round-1/01-section.md`
7. Proceed to Review.

### Generate (Round 2+)

1. Update workflow state row: Status = GENERATING, Round = R
2. Create round directory: `07-conventions/conventions/versions/section-NN/round-R/` (Bash `mkdir -p`)
3. Spawn the section generator (source items already extracted, reviewed, and corrected):
   - Generator prompt: `Read the conventions section generator at: {{AGENTS_PATH}}/07-conventions/conventions-generator.md\n\nFix section N (Section Name), round R. Conventions guide: {{GUIDES_PATH}}/07-conventions-guide.md. Review report: 07-conventions/conventions/versions/section-NN/round-[R-1]/02-review-report.md. Write to: 07-conventions/conventions/sections/[file-stem].md`
   - Verify output exists using `ls`: `07-conventions/conventions/sections/[file-stem].md`
4. Copy section to version directory using Bash `cp`: `cp 07-conventions/conventions/sections/[file-stem].md 07-conventions/conventions/versions/section-NN/round-R/01-section.md`
5. Proceed to Review.

### Review

1. Update workflow state row: Status = REVIEWING
2. Spawn the section reviewer as a subagent via Task tool:
   - Prompt: `Read the conventions section reviewer at: {{AGENTS_PATH}}/07-conventions/conventions-reviewer.md\n\nReview section N (Section Name), round R. Conventions guide: {{GUIDES_PATH}}/07-conventions-guide.md. Section file: 07-conventions/conventions/sections/[file-stem].md. Source items file: 07-conventions/conventions/versions/section-NN/source-items-reviewed.md. Write review report to: 07-conventions/conventions/versions/section-NN/round-R/02-review-report.md`
   - Verify output exists using `ls`: `07-conventions/conventions/versions/section-NN/round-R/02-review-report.md`
3. Extract the overall status using Grep (search for `**Status**:` in the review report) — do NOT Read the full review report into context
4. Proceed to Route.

### Route

- **PASS** → Update workflow state row: Status = COMPLETE, Notes = "Round R: PASS". Present: "Section [N] ([Name]) COMPLETE after [R] round(s)." Stop.
- **FAIL and round < 4** → Increment round. Loop to Generate (Round 2+).
- **FAIL and round >= 4** → Update workflow state row: Status = FAILED, Notes = "Failed after 4 rounds". Present: "Section [N] ([Name]) could not pass review after 4 rounds." Stop.

### Max Rounds

If the section reaches round 4 without achieving PASS:
- Update workflow state row: Status = FAILED, Notes = "Failed after 4 rounds"
- Present failure summary
- Stop

---

## Workflow State Updates

Update only your section's row in the Processing Order table. Use the Edit tool targeting the unique section number in the table row.

**Fields to update:**
- **Status**: At each pipeline step transition (PENDING → GENERATING → REVIEWING → COMPLETE)
- **Round**: Current round number (use `-` for PENDING)
- **Last Updated**: Current date (YYYY-MM-DD)
- **Notes**: Completion info or failure reason

**Do NOT modify:**
- Other sections' rows
- The History section
- The top-level workflow Status field (GENERATING/CROSS_REFERENCING/AWAITING_APPROVAL/APPROVED — coordinator manages this)

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Section not in workflow state | Error: report and stop |
| Generator agent fails | Retry once. If still fails, mark section FAILED with reason. |
| Extractor agent fails | Retry once. If still fails, mark section FAILED with reason. |
| Reviewer agent fails | Retry once. If still fails, mark section FAILED with reason. |
| Corrector agent fails | Retry once. If still fails, mark section FAILED with reason. |
| Section reviewer agent fails | Retry once. If still fails, mark section FAILED with reason. |
| Section exceeds 4 rounds | Mark FAILED: "Failed after 4 rounds" |
| Workflow state file not found | Error: "Workflow state not found. Run the coordinator to initialize first." |

---

## Constraints

- **Fully automated**: Execute the entire pipeline without pausing for confirmation. Do not stop between steps to ask whether to proceed. The pipeline is designed to run to completion autonomously.
- **Single section**: Process only the named section. Do not process other sections.
- **File-first**: Pass file paths to worker agents, not file contents. Agents read files themselves.
- **State before action**: Update workflow state before and after every step transition. This enables resume on interruption.

**Tool Restrictions:**
- Only use **Read**, **Write**, **Edit**, **Glob**, **Grep**, and **Task** tools
- Do NOT use Bash or execute any shell commands
  - Exception: **Bash** allowed for `ls`, `cp`, and `mkdir` only (file existence checks and orchestration)
  - Do NOT use git commands
- Do NOT use WebFetch or WebSearch

**Path Discipline:**
- Use exactly the file paths provided in your invocation. Do not substitute, discover, or infer alternative paths.
