# Component Spec Creation: Generate Phase

Handles Steps 9–10c: Generate/Apply Enrichments, Coverage/Depth/Excess verification, Gap Resolution, and per-round Creation Verification. Also computes the Step 11 convergence signal and, on the human's "another round" choice, performs the round-boundary bookkeeping (re-raise ledger + reset). Runs straight through between checkpoints and returns structured data to the router. **Router handles all human communication.**

---

## Orchestrator Boundaries

These are instructions for the router to follow directly. The router:
- Spawns worker agents using the Task tool (in FOREGROUND, not background)
- Passes file PATHS to agents, not file contents — agents read files themselves
- Does NOT read agent prompt files — agents read their own instructions
- Does NOT present to the human or STOP — it returns to the router, which owns all human communication

You READ output files only to extract statuses/counts and to inject TODO markers. You DO NOT write draft content — agents do that.

**Paths, Path Resolution, State File Format, and the Output Directory Structure are defined in the router** (`orchestrator-router.md`). Resolve `{primary-source}`, `{round-dir}` from the current round.

**Context management**: Keep context lean — `ls` for existence checks, Grep for targeted extraction. Do not Read working files you are passing to agents. Between automatic steps, do not read files unless a step explicitly directs you to.

---

## Agent Prompt Locations

- Generator: `{{AGENTS_PATH}}/05-components/create/generator.md`
- Enrichment Applicator: `{{AGENTS_PATH}}/05-components/create/enrichment-applicator.md`
- Requirements Extractor: `{{AGENTS_PATH}}/05-components/create/requirements-extractor.md`
- Coverage Checker: `{{AGENTS_PATH}}/05-components/create/coverage-checker.md`
- Absent-From-Freeze Detector: `{{AGENTS_PATH}}/05-components/create/absent-from-freeze-detector.md`
- Depth Checker: `{{AGENTS_PATH}}/05-components/create/depth-checker.md`
- Stage-Appropriateness Verifier: `{{AGENTS_PATH}}/universal-agents/stage-appropriateness-verifier.md`
- Gap Formatter: `{{AGENTS_PATH}}/universal-agents/gap-formatter.md`
- Gap Analyst: `{{AGENTS_PATH}}/universal-agents/gap-analyst.md`
- Discussion Facilitator: `{{AGENTS_PATH}}/universal-agents/discussion-facilitator.md`
- Author: `{{AGENTS_PATH}}/05-components/create/author.md`
- Alignment Verifier: `{{AGENTS_PATH}}/universal-agents/alignment-verifier.md`
- Internal Coherence Checker: `{{AGENTS_PATH}}/universal-agents/internal-coherence-checker.md`

---

## On Entry

Router dispatches with an Action:

| Action | Behavior |
|--------|----------|
| `RUN` | Resume from `Current Step` among {9, 9b, 9c, 9d, 10, 10c}; run through to a checkpoint return or `ROUND_COMPLETE`. On re-dispatch during the Step 10 loop, run one gap-resolution iteration; on re-dispatch after a Step 10c decision, act on `## Pending Decision: 10c: FIX|ACCEPT`. |
| `ANOTHER_ROUND` | The human chose "another round" at Step 11 — write the re-raise ledger, increment the round, reset steps, return `NEW_ROUND_READY`. |

**Resume specifics (Action: RUN):**
- **Step 9** is non-idempotent — if complete, verify `{round-dir}/00-draft-spec.md` exists and skip to Step 9b. For round 1 do NOT re-run the Generator (it appends to downstream deferred-items files and would duplicate).
- **Steps 9b / 9c / 9d** — if complete, skip to the next.
- **Step 10** — if complete, skip to Step 10c; if mid-loop, continue the discussion loop.
- **Step 10c** — if complete, compute the convergence signal and return `ROUND_COMPLETE`; if mid FIX/ACCEPT, act on `## Pending Decision`.

---

## Step 9: Generate or Apply Enrichments

**Round 1** runs the Generator (creates the spec from scratch). **Round 2+** runs the Enrichment Applicator (applies accepted enrichments as targeted edits to the previous round's draft).

### Round 1: Run Generator

1. **Determine exploration summary path**: if `{explore-dir}/03-exploration-summary.md` exists, include it; else omit.

2. **Spawn Generator**:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/generator.md

   Input:
   - Component: [component-name]
   - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
   - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md
   - Component guide: {{GUIDES_PATH}}/05-components-guide.md
   - Deferred items: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/deferred-items.md
   - Cross-cutting spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/cross-cutting.md
   - Cross-cutting interface schema-specs (step-0; may be empty): {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/cross-cutting-interfaces/ — shared schema-specs for §7 cross-cutting interfaces; where this component writes/reads such an interface, adopt the frozen schema by reference (non-blocking — a component may adopt; it is not required)
   - Cross-cutting deferred items: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/cross-cutting/deferred-items.md
   - Brief: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/brief.md (if exists)
   [If exploration summary exists:]
   - Exploration summary: {explore-dir}/03-exploration-summary.md

   Output: {round-dir}/00-draft-spec.md
   ```

3. **Wait**; **verify** `{round-dir}/00-draft-spec.md` exists.

4. **Update state**: Mark "Step 9" complete `[x]`, add history entry.

### Round 2+: Apply Enrichments

1. **Copy previous round's draft** to `{round-dir}/00-draft-spec.md` (Bash cp from the previous round's latest draft per Path Resolution).

2. **Determine exploration summary path**: if `{explore-dir}/03-exploration-summary.md` does NOT exist (exploration skipped or no enrichments accepted), the draft is already copied — skip to step 5. Else continue.

3. **Spawn Enrichment Applicator**:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/enrichment-applicator.md

   Input:
   - Draft Spec: {round-dir}/00-draft-spec.md
   - Exploration summary: {explore-dir}/03-exploration-summary.md
   - Component guide: {{GUIDES_PATH}}/05-components-guide.md

   Output:
   - Updated Spec: {round-dir}/00-draft-spec.md (edit in place)
   - Change log: {round-dir}/00-enrichment-applicator-output.md
   ```

4. **Wait**; **verify** `{round-dir}/00-draft-spec.md` exists.

5. **Update state**: Mark "Step 9" complete `[x]`, add history entry.

Automatically proceed to Step 9b.

## Step 9b: Coverage Verification

Independently verify the draft addresses every requirement the Architecture assigns to this component. **On resume**: if complete, skip to Step 9c.

1. **Spawn Requirements Extractor** (if the checklist doesn't already exist):
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/requirements-extractor.md

   Input:
   - Component: [component-name]
   - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
   - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md
   - PRD (its §5 Conceptual Data Model — authoritative field list for owned entities): {{SYSTEM_DESIGN_PATH}}/system-design/02-prd/prd.md
   - Component guide: {{GUIDES_PATH}}/05-components-guide.md
   - Deferred items: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/deferred-items.md
   - Cross-cutting spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/cross-cutting.md
   - Cross-cutting interface schema-specs (step-0; may be empty): {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/cross-cutting-interfaces/ — shared schema-specs for §7 cross-cutting interfaces; where this component writes/reads such an interface, adopt the frozen schema by reference (non-blocking — a component may adopt; it is not required)

   Output: {round-dir}/00-requirements-checklist.md
   ```

2. **Wait**; **verify** `{round-dir}/00-requirements-checklist.md` exists.

3. **Spawn Coverage Checker**:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/coverage-checker.md

   Input:
   - Requirements checklist: {round-dir}/00-requirements-checklist.md
   - Draft Spec: {round-dir}/00-draft-spec.md
   - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md

   Output: {round-dir}/00-coverage-report.md
   ```

3b. **Spawn Absent-From-Freeze Detector** (sibling to the Coverage Checker — a body-driven scan that runs unavoidably at create round-0 and every subsequent round; it is **not** gated behind any optional phase). Unlike the Coverage Checker (registry/checklist-bounded — blind to a contract absent from the freeze), this reads the **body** and diffs its produced **and** consumed cross-component interfaces against the frozen registry:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/absent-from-freeze-detector.md

   Input:
   - Component body (draft): {round-dir}/00-draft-spec.md
   - Frozen cross-cutting registry: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/cross-cutting.md
   - Architecture pending-issues (escalation target): {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/versions/pending-issues.md

   Output: {round-dir}/00-absent-from-freeze-report.md
   ```

4. **Wait** for both the Coverage Checker and the Absent-From-Freeze Detector. Read the coverage report summary — extract PASS / GAPS_FOUND / CONFIRM_NEEDED and the GAP + CONFIRM-INTENTIONAL counts. Also read the detector report verdict (COVERED | ABSENCES_ESCALATED) and its escalated/suppressed counts — the detector writes any `CROSS-BOUNDARY-UPSTREAM` escalations **directly** to Architecture's pending-issues (a backward edge); record the counts in the Step 9b history entry but do **not** gate the round on them (they are upstream obligations, not local gaps).

5. **If GAPS_FOUND or CONFIRM_NEEDED**: add each GAP item as a `[TODO: Coverage gap — ...]` marker, and each CONFIRM-INTENTIONAL item (an owned-entity PRD §5 field absent from the draft where the Architecture is silent/refined) as a `[TODO: Coverage confirm — <Entity.field> (PRD §5): present in the PRD conceptual data model but absent from this spec. Confirm deliberate MVP scoping (record an explicit waiver) or add the field.]` marker, to the draft via targeted Edit, so the Gap Formatter extracts both alongside the Generator's own gap markers.
   - **Re-raise suppression (round 2+)**: before injecting a **Coverage-confirm** marker, consult the re-raise ledger `create-decisions.md` in the component directory (if it exists). If this exact field was **waived** in a prior round and its situation is unchanged (still Architecture-silent/refined and still absent), **do not re-inject** the marker — the waiver stands; note the suppression in the history entry. (GAP items and any field whose situation changed are still injected normally.)

6. **Update state**: Mark "Step 9b" complete `[x]`, add history entry with coverage counts. Proceed to Step 9c.

## Step 9c: Depth Verification

Verify the draft meets minimum specification depth. **On resume**: if complete, skip to Step 9d.

1. **Spawn Depth Checker**:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/depth-checker.md

   Input:
   - Draft Spec: {round-dir}/00-draft-spec.md
   - Component guide: {{GUIDES_PATH}}/05-components-guide.md
   - Project scale reference: {{SYSTEM_DESIGN_PATH}}/system-design/project-scale.md

   Output: {round-dir}/00-depth-report.md
   ```

2. **Wait**; read the depth report summary — extract SHALLOW count or PASS.

3. **If SHALLOW items found**: add each as `[TODO: Depth gap — ...]` markers to the draft via targeted Edit, so the Gap Formatter extracts them alongside other gap markers.
   - **Re-raise suppression (round 2+)**: before injecting a **Depth** marker, consult `create-decisions.md` (if it exists). If this element was **waived** in a prior round and remains unchanged, **do not re-inject** — the waiver stands; note the suppression. (Changed or newly-shallow elements are still injected.)

4. **Update state**: Mark "Step 9c" complete `[x]`, add history entry with depth counts. Proceed to Step 9d.

## Step 9d: Excess Verification (binding — maturity over-build gate)

Detect content that exceeds the project's maturity/phase target and route it into the **same binding gap-resolution loop** as coverage/depth gaps (Step 10). Runs **every round from round 1**. **On resume**: if complete, skip to Step 10.

1. **Determine draft path**: if `{round-dir}/03-updated-spec.md` exists, use it; otherwise `{round-dir}/00-draft-spec.md`.

2. **Spawn Stage-Appropriateness Verifier**:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/universal-agents/stage-appropriateness-verifier.md

   Input:
   - Target draft: [draft path]
   - Project scale reference: {{SYSTEM_DESIGN_PATH}}/system-design/project-scale.md
   - Stage guide: {{GUIDES_PATH}}/05-components-guide.md
   - PRD: {{SYSTEM_DESIGN_PATH}}/system-design/02-prd/prd.md
   - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md
   - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md

   Output: {round-dir}/06-stage-appropriateness-report.md
   ```

3. **Wait**; **verify** `{round-dir}/06-stage-appropriateness-report.md` exists.

4. **Read the report and inject excess gaps as TODO markers** (this is what makes the gate binding):
   - **Re-raise suppression (round 2+, do this first)**: consult `create-decisions.md` (if it exists). For any `IMPLEMENTATION_LATITUDE` / `RESTATES_UPSTREAM` finding the human chose to **KEEP** in a prior round whose flagged element is **unchanged**, **do not re-inject** — the KEEP stands; note the suppression. (Findings on changed elements, and new findings, are injected normally.)
   - For each `IMPLEMENTATION_LATITUDE` finding: add `[TODO: Excess (latitude) — <section>: <element_identifier>. Recommended: <recommendation — apply the explicit-latitude rewrite, or DEFER_FUTURE to the "Future Developments" section>]` at the flagged element via targeted Edit.
   - For each `RESTATES_UPSTREAM` finding with a concrete reference: add `[TODO: Excess (restates upstream) — <section>: replace restated content with a reference to <recommendation>]`.
   - For each `WRONG_STAGE` finding: add `[TODO: Excess (wrong stage) — <section>: belongs in <recommendation>; human decision]`.
   - `APPROPRIATE` findings: **do not mark** — these are correctly pinned commitments (criticality discipline: consumer-facing contracts and integrity invariants are never auto-removed).
   - These markers are picked up by the Gap Formatter in Step 10 alongside coverage/depth gaps; the Gap Analyst proposes the resolution and the human adjudicates each, exactly as for other gaps.

5. **Update state**: Mark "Step 9d" complete `[x]`, add history entry with per-classification counts (APPROPRIATE / IMPLEMENTATION_LATITUDE / RESTATES_UPSTREAM / WRONG_STAGE) and the number of excess TODO markers injected.

Automatically proceed to Step 10.

## Step 10: Gap Resolution (multi-iteration checkpoint)

**On resume**: if complete, skip to Step 10c. If mid-loop, continue the discussion loop.

**First entry:**
1. **Read the draft** `{round-dir}/00-draft-spec.md`. **Check for `## Gap Summary`**.
2. **If no Gap Summary, or all counts are 0**: Update state — set `Gaps Exist` = `false`, mark "Step 10" complete `[x]`, history entry "No gaps found". Proceed to Step 10c.
3. **Spawn Gap Formatter**:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/universal-agents/gap-formatter.md

   Input:
   - Draft: {round-dir}/00-draft-spec.md

   Output: {round-dir}/01-gap-discussion.md
   ```
4. **Wait**; **verify** `{round-dir}/01-gap-discussion.md` exists. Count gaps by severity.
5. **Spawn Gap Analyst agents** (batch by section, 2–3 batches):
   ```
   Follow the instructions in: {{AGENTS_PATH}}/universal-agents/gap-analyst.md

   Context documents:
   - Draft Spec: {round-dir}/00-draft-spec.md
   - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
   - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md
   - Brief: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component-name]/brief.md (if exists)

   Gap discussion file: {round-dir}/01-gap-discussion.md
   Gaps: [GAP-001, GAP-002, ...]
   ```
   Batch by spec section: B1 Sections 1–4 (Overview, Scope, Interfaces, Data Model); B2 Sections 5–8 (Behaviour, Dependencies, Integration, Error Handling); B3 Sections 9–12 (Observability, Security, Testing, Open Questions). Fewer than 4 gaps → fewer batches.
6. **Wait for all**. **Verify analyst responses were written** (MANDATORY): count `>> AGENT:` markers vs total gaps; if mismatch, re-invoke Gap Analyst for the missing gaps only.
7. **Update state**: Set `Gaps Exist` = `true`, set status = WAITING_FOR_HUMAN, add history entry with gap counts.
8. **Return** `GAPS_READY { gap_discussion_file: {round-dir}/01-gap-discussion.md, counts: {HIGH, MEDIUM, LOW} }`. (Router presents the gap review.)

**Discussion loop (each re-dispatch after the human responds):** do NOT process until the human has added actual content after `>> HUMAN:` markers.
   a. **Identify gaps needing agent response**: last entry is `>> HUMAN:` without a subsequent `>> AGENT:`.
   b. **For gaps where the human accepted** (clear agreement): add `>> RESOLVED`.
   c. **For gaps needing discussion**: spawn Discussion Facilitator agents (batched by section):
      ```
      Follow the instructions in: {{AGENTS_PATH}}/universal-agents/discussion-facilitator.md

      Context documents:
      - Draft Spec: {round-dir}/00-draft-spec.md
      - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
      - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md

      Issues file: {round-dir}/01-gap-discussion.md
      Issues: [GAP-001, GAP-002, ...]
      ```
   d. **Wait**; **verify** agent responses were written (MANDATORY).
   e. If Category-c facilitators ran → set status = WAITING_FOR_HUMAN, **return** `GAPS_NEED_HUMAN { issues_awaiting_human: [...] }`. (Router asks the human to reply to each gap.)
   f. **On the next re-dispatch**, for each gap: if last entry is `>> HUMAN:` after `>> AGENT:` and it indicates closure → add `>> RESOLVED`; if it is a question/pushback/request → leave open. If any gaps unresolved → loop to (a). If all resolved → run the Author (below).
   **Resolution indicators**: "Yes", "Agreed", "That works", "Fine", "OK", "Not a concern", "Not relevant", "Ignore", "Skip", "Makes sense", "Fair enough", "Understood". **Continue indicators** (do NOT resolve): "?", "What about", "How would", "Can you", "Please", "I'd like", "Show me", "I disagree", "That's not right", "But what about".

**When all gaps resolved — Spawn Author**:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/author.md

   Input:
   - Draft Spec: {round-dir}/00-draft-spec.md
   - Gap discussion: {round-dir}/01-gap-discussion.md
   - Component guide: {{GUIDES_PATH}}/05-components-guide.md

   Output:
   - Change log: {round-dir}/02-author-output.md
   - Updated Spec: {round-dir}/03-updated-spec.md
   ```
   Wait; verify outputs exist. **Update state**: Mark "Step 10" complete `[x]`, add history entry. Automatically proceed to Step 10c.

## Step 10c: Creation Verification (alignment + coherence — per-round gate)

Verify alignment with source documents and internal coherence **every round**, immediately after gap resolution and before the human's finalise/continue choice. Mirrors the Review workflow's post-author verification gate (its Steps 7–10 + the `VERIFICATION_CLEAN` predicate): each round ends alignment- and coherence-clean, so cross-section gaps cannot accrete across rounds and the finalise/continue decision is made on a fully-verified draft.

**On resume**: if complete, compute the convergence signal and return `ROUND_COMPLETE`. If a Step 10c decision is pending (`## Pending Decision: 10c: FIX|ACCEPT`), act on it (below).

1. **Determine draft path**: if `{round-dir}/03-updated-spec.md` exists (Author ran in Step 10), use it; otherwise `{round-dir}/00-draft-spec.md`.

2. **Spawn both verification agents in parallel**:

   **Alignment Verifier**:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/universal-agents/alignment-verifier.md

   Input:
   - Updated spec: [draft path from step 1]
   - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
   - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md
   - PRD: {{SYSTEM_DESIGN_PATH}}/system-design/02-prd/prd.md

   Output: {round-dir}/04-alignment-report.md
   ```

   **Internal Coherence Checker**:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/universal-agents/internal-coherence-checker.md

   Document: [draft path from step 1]
   Stage guide: {{GUIDES_PATH}}/05-components-guide.md
   Output: {round-dir}/05-coherence-report.md
   ```

3. **Wait for both**; **read both reports** and aggregate: alignment (HALT, SYNC_UPSTREAM, REVIEW_NEEDED); coherence (HIGH/MEDIUM gaps).

4. **Gate threshold** (matches the Review workflow's `VERIFICATION_CLEAN` bar): the round is **CLEAN** iff alignment is PROCEED with **no HALT** AND coherence has **no HIGH or MEDIUM gaps** (COHERENT or LOW only). LOW coherence and LOW/SYNC_UPSTREAM alignment items **do not gate** — carry them forward and note them.

5. **If CLEAN**: Update state — Mark "Step 10c" complete `[x]`, add history entry with the alignment/coherence summary. Proceed to compute the convergence signal and return `ROUND_COMPLETE` (below).

6. **Track rework pass count**: the first verification is pass 1; each FIX that returns to the Author and re-runs verification increments it.

7. **If issues found** (any HIGH/MEDIUM coherence gap, or an alignment HALT/REVIEW_NEEDED): set status = WAITING_FOR_HUMAN and **return** `VERIFY_DECISION { alignment_issues: [...], coherence_gaps: [...], rework_pass: [N] }`. (Router presents FIX/ACCEPT.)

**On re-dispatch — `## Pending Decision: 10c: FIX [findings]`**: write the accepted findings as resolved directives to `{round-dir}/01-coherence-fixes.md` (gap-discussion resolved format: each item `>> RESOLVED` with a precise "Apply:" instruction), then spawn the Author:
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/create/author.md

   Input:
   - Draft Spec: {round-dir}/03-updated-spec.md (or {round-dir}/00-draft-spec.md if no Author ran in Step 10)
   - Gap discussion (resolved coherence-fix directives): {round-dir}/01-coherence-fixes.md
   - Component guide: {{GUIDES_PATH}}/05-components-guide.md

   Output:
   - Change log: {round-dir}/02c-creation-verify-author-output.md
   - Updated Spec: {round-dir}/03-updated-spec.md (edit in place)
   ```
   Then **re-run verification** (loop to step 1). Apply the **no-HIGH/MEDIUM exit discipline**: stop the rework loop once no HIGH/MEDIUM remain; do not chase LOW residuals round-over-round (that is the non-convergence trap). Update state with per-pass counts.

**On re-dispatch — `## Pending Decision: 10c: ACCEPT`**: the accepted items carry forward unresolved. Mark "Step 10c" complete `[x]`, set status = IN_PROGRESS, add history entry. Proceed to compute the convergence signal and return `ROUND_COMPLETE`.

## Compute Convergence Signal and Return ROUND_COMPLETE

**Compute this round's convergence signal** (severity-gated round-exit — mirrors the review loop's "no HIGH/MEDIUM → mature" gate and the Step 10c threshold). Do **not** re-run any agent; read the counts already recorded this round:
- **Gaps resolved this round** by severity (from `{round-dir}/01-gap-discussion.md` + the Step 10 history entry): how many HIGH / MEDIUM / LOW.
- **Over-build (Step 9d)**: whether the IMPLEMENTATION_LATITUDE / RESTATES_UPSTREAM findings were **KEEP'd / confirmed** (no substantive change) or drove real edits (from the Step 9d history entry).
- **Creation Verification (Step 10c)**: whether it was **clean on the first pass** or required rework (from the Step 10c history entry).
- **Verdict** — a round is **diminishing-returns** if it resolved **no HIGH or MEDIUM gaps**, all excess findings were KEEP'd/confirmed, and Step 10c was clean first-pass (the round produced only LOW/polish refinement). Otherwise it made **substantive** change. This is a *recommendation to the human*, not an auto-terminate.

**Also carry forward the rigour-gap exit predicate** (a **separate, independent** exit signal from the severity-based `convergence_signal` above — do not conflate them). Read `Rigour-Gap Exit Predicate` from the `## Explore Details` section of the state file (the explore phase persisted it this round at Step 2). Do **not** recompute it — it reflects this round's Concern Identifier result (`MET` = the identifier surfaced zero rigour-gap-qualifying concerns). Pass it through unchanged as `rigour_gap_exit`. If the field is absent (e.g. a legacy in-flight state file), set `rigour_gap_exit = unknown`. This predicate is presented to the human at the finalise checkpoint alongside `convergence_signal`; it does **not** auto-terminate the loop.

**Set status = WAITING_FOR_HUMAN** and **return**:
```
ROUND_COMPLETE {
  convergence_signal: [substantive | diminishing-returns],
  rigour_gap_exit: [MET | not-met | unknown],   // B: explicit exit predicate — this round's Concern Identifier surfaced zero rigour-gap-qualifying concerns. Independent of convergence_signal; informs the human, never auto-exits.
  gaps_resolved: { HIGH, MEDIUM, LOW },     // or "none"
  overbuild: [all-KEEP'd/confirmed | drove-edits],
  verification_10c: [clean-first-pass | required-rework],
  gaps_existed: [true|false],
  draft_path: {round-dir}/00-draft-spec.md,
  updated_path: {round-dir}/03-updated-spec.md,   // if Author ran
  report_paths: { appropriateness: {round-dir}/06-stage-appropriateness-report.md,
                  alignment: {round-dir}/04-alignment-report.md,
                  coherence: {round-dir}/05-coherence-report.md }
}
```
(Router presents finalise / another-round. On "finalise" the router finalises inline; on "another round" it re-dispatches this phase with Action: ANOTHER_ROUND.)

---

## Action: ANOTHER_ROUND

The human chose "another round". Perform the round-boundary bookkeeping (no human communication):

1. **Determine the latest draft for this round**: if `{round-dir}/03-updated-spec.md` exists (Author ran), use it; otherwise `{round-dir}/00-draft-spec.md`.

2. **Record no-spec-change decisions into the re-raise ledger** (so the next round's verifiers do not re-flag settled waivers — the create-loop counterpart of the review loop's `## Resolved Issues` ledger): append to the per-component ledger `create-decisions.md` in the component directory (`versions/[component-name]/`, the parent of `{round-dir}`; create it with a `# Create Decisions (re-raise ledger)` header if absent) one entry per finding **resolved this round without a spec change** — a coverage **CONFIRM-INTENTIONAL** field the human **waived**, a depth item **waived**, or a stage-appropriateness **IMPLEMENTATION_LATITUDE / RESTATES_UPSTREAM** finding the human chose to **KEEP** (cross-reference the resolutions in `{round-dir}/01-gap-discussion.md` against `{round-dir}/00-coverage-report.md` and `{round-dir}/06-stage-appropriateness-report.md`). For each, write:
   - `**Concern key:** <spec section/element> — <finding type> (<Entity.field or identifier>)`
   - `**Round:** {N}` · `**Decision:** waived | KEEP` · `**Rationale:** <human-approved reason>`
   Record **only** findings whose Step 10 resolution left the draft text **unchanged** — APPLIED fixes self-suppress (the draft changed, so a re-scan sees the fix; it is the no-change waivers/KEEPs that would otherwise be re-flagged verbatim every round).

3. **Update state**:
   - Mark "Step 11: Finalise or Continue" complete `[x]`
   - Increment `Current Round`
   - Reset Steps 1–11 to unchecked `[ ]` (includes Step 10c)
   - Set phase = Explore, `Explore Phase` = active, `Gaps Exist` = unknown
   - Add history entry "Round {N} complete — starting round {N+1}"

4. **Return** `NEW_ROUND_READY { new_round: [N+1] }`. (Router re-resolves paths and dispatches the explore phase.)

---

## Return to Router

| Return | When |
|--------|------|
| `GAPS_READY { gap_discussion_file, counts }` | Step 10 first entry — gaps ready for review |
| `GAPS_NEED_HUMAN { issues_awaiting_human }` | Mid Step 10 loop — router asks the human to reply |
| `VERIFY_DECISION { alignment_issues, coherence_gaps, rework_pass }` | Step 10c found HIGH/MEDIUM or an alignment HALT |
| `ROUND_COMPLETE { convergence_signal, ... }` | Round gate passed — router presents finalise/continue |
| `NEW_ROUND_READY { new_round }` | After Action: ANOTHER_ROUND bookkeeping |

Do NOT present anything to the human — the router handles all human communication.

---

<!-- INJECT: tool-restrictions -->
