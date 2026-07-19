# Component Spec Review: Post-Discussion Phase

Handles Steps 6-13: Apply Changes, Verification, Execute & Route, and Promote.

Runs straight through and returns structured data to router. Router handles human communication.

---

## Orchestrator Boundaries

These are instructions for the router to follow directly. The router:
- Spawns workflow agents (Author, Verifiers, etc.) using the Task tool (in FOREGROUND, not background)
- Passes file PATHS to agents, not file contents
- Does NOT read agent prompt files — agents read their own instructions
- Handles all human communication (not delegated)

---

## State File

**Path**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/workflow-state.md`

---

## Agent Prompt Locations

- Author: `{{AGENTS_PATH}}/05-components/review/author.md`
- Change Verifier: `{{AGENTS_PATH}}/05-components/review/change-verifier.md`
- Alignment Verifier: `{{AGENTS_PATH}}/universal-agents/alignment-verifier.md`
- Contract Verifier: `{{AGENTS_PATH}}/05-components/review/contract-verifier.md`
- Absent-From-Freeze Detector: `{{AGENTS_PATH}}/05-components/create/absent-from-freeze-detector.md` (the same body-driven detector spawned at create round-0; run here at **every review round**, since a review edit can introduce a new uncontracted cross-component read)
- Internal Coherence Checker: `{{AGENTS_PATH}}/universal-agents/internal-coherence-checker.md`
- Pending Issue Resolver: `{{AGENTS_PATH}}/universal-agents/pending-issue-resolver.md`
- Spec Promoter: `{{AGENTS_PATH}}/05-components/review/spec-promoter.md`

---

## On Entry: Check Action

Router dispatches with an Action parameter:

| Action | Behavior |
|--------|----------|
| `RUN` | Execute Steps 6-11, return status |
| `APPLY_DECISIONS` | Read decisions from state file, execute Step 12, return status |
| `PROMOTE` | Execute Step 13, return completion |

---

## Action: RUN (Steps 6-11)

### Step 6: Apply Changes

1. **Update state file**: Set Step 6, status = IN_PROGRESS

2. **Run Author agent** (spawn as Task agent):
   ```
   Follow the instructions in: {{AGENTS_PATH}}/05-components/review/author.md

   Input:
   - Current spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/00-spec.md
   - Issues discussion: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/03-issues-discussion.md
   - Consolidated issues: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/02-consolidated-issues.md

   Output:
   - Change log: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/04-author-output.md
   - Updated spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/05-updated-spec.md
   - Lateral pending-issues: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[target-component]/pending-issues.md (if any cross-component items identified)
   ```

3. **Update state file**: Mark Step 6 complete

4. **Proceed to Step 7**

### Steps 7-10: Verification (Parallel)

Run all five verification steps in parallel — they have no dependencies on each other.

5. **Update state file**: Set Steps 7-10, status = IN_PROGRESS

6. **Spawn all five verification agents in parallel**:

    **Change Verifier** (Step 7):
    ```
    Follow the instructions in: {{AGENTS_PATH}}/05-components/review/change-verifier.md

    Input:
    - Issues discussion: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/03-issues-discussion.md
    - Author output: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/04-author-output.md
    - Updated spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/05-updated-spec.md

    Output: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/06-change-verification-report.md
    ```

    **Alignment Verifier** (Step 8):
    ```
    Follow the instructions in: {{AGENTS_PATH}}/universal-agents/alignment-verifier.md

    Input:
    - Updated spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/05-updated-spec.md
    - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
    - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md
    - PRD: {{SYSTEM_DESIGN_PATH}}/system-design/02-prd/prd.md
    [If this is a non-core sub-spec (component path contains '/') AND core sub-spec exists:]
    - Core sub-spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/[parent-component]/core.md

    Output: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/07-alignment-report.md
    ```

    **Note on sub-spec alignment**: When reviewing a non-core sub-spec (e.g., `email-sources/quality-metrics`), include the core sub-spec as an additional upstream document. The Alignment Verifier will check that Shared Context references (entity schema, lifecycle state dependencies) match the current state of core.md. For the core sub-spec itself, no additional upstream is needed.

    **Contract Verifier** (Step 9):
    ```
    Follow the instructions in: {{AGENTS_PATH}}/05-components/review/contract-verifier.md

    Input:
    - Producer spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/05-updated-spec.md
    - Cross-cutting specification: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/cross-cutting.md
    - Pending issues: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/pending-issues.md

    Output: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/08-contract-verification.md
    ```

    **Absent-From-Freeze Detector** (Step 9b): body-driven — the `contract-verifier` above is producer-only and registry-driven, so nothing else catches a cross-component contract **absent from the frozen registry**, and a review edit can introduce a new uncontracted read. Scans the updated spec's produced **and** consumed cross-component interfaces and escalates any absence `CROSS-BOUNDARY-UPSTREAM`:
    ```
    Follow the instructions in: {{AGENTS_PATH}}/05-components/create/absent-from-freeze-detector.md

    Input:
    - Component body (updated spec): {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/05-updated-spec.md
    - Frozen cross-cutting registry: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/cross-cutting.md
    - Architecture pending-issues (escalation target): {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/versions/pending-issues.md

    Output: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/10-absent-from-freeze-report.md
    ```

    **Internal Coherence Checker** (Step 10):
    ```
    Follow the instructions in: {{AGENTS_PATH}}/universal-agents/internal-coherence-checker.md

    Document: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/05-updated-spec.md
    Stage guide: guides/05-components-guide.md
    Output: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/09-coherence-report.md
    ```

7. **Wait for all five agents to complete**

8. **Update state file**: Mark Steps 7, 8, 9, 9b, and 10 complete

9. **Proceed to Step 11**

### Step 11: Evaluate Verification Results

10. **Update state file**: Set Step 11, status = IN_PROGRESS

11. **Read all verification reports**:
    - `06-change-verification-report.md` — check for PARTIALLY_RESOLVED, NOT_RESOLVED, LEVEL_VIOLATION, or MISSING/WRONG lateral items
    - `07-alignment-report.md` — check for HALT recommendation, SYNC_UPSTREAM
    - `08-contract-verification.md` — check for failures or regressions
    - `10-absent-from-freeze-report.md` — the Absent-From-Freeze Detector verdict (COVERED | ABSENCES_ESCALATED). Its escalations are written **directly** to Architecture's pending-issues (a backward edge, `CROSS-BOUNDARY-UPSTREAM`); this is informational for the review round — record the escalated/suppressed counts but do **not** gate the round on them (they are upstream obligations, not local rework)
    - `09-coherence-report.md` — check for HIGH or MEDIUM coherence gaps

12. **Categorize overall status**:

    **NEEDS_REWORK**: NOT_RESOLVED or LEVEL_VIOLATION items exist
    - Changes were not applied correctly
    - Need to re-run Author

    **NEEDS_DECISIONS**: Any of:
    - PARTIALLY_RESOLVED items (accept or rework?)
    - HALT blockers (acknowledge or proceed?)
    - Pending issues to sync upstream (sync or defer?)
    - HIGH/MEDIUM coherence gaps (fix or accept?)

    **VERIFICATION_CLEAN**: All of:
    - All changes RESOLVED
    - No HALT blockers
    - No pending issues requiring decision
    - No contract regressions
    - No HIGH/MEDIUM coherence gaps (COHERENT or LOW only)

13. **Write verification summary** to `10-verification-summary.md` (for record keeping)

14. **Update state file**: Mark Step 11 complete

15. **Return to router based on status** (see Return to Router section)

---

## Action: APPLY_DECISIONS (Step 12)

Router re-dispatches after collecting human decisions.

### Read Decisions from State File

Read `## Pending Decisions` section:
```markdown
## Pending Decisions
- SPEC-001: ACCEPT
- SPEC-003: REWORK
- COH-001: FIX
- halt_action: PROCEED_ANYWAY
- sync_action: SYNC_ALL
```

### Step 12: Execute Decisions

16. **Update state file**: Set Step 12, status = IN_PROGRESS

17. **If any REWORK or FIX decisions**:
    - Return `{ status: "NEEDS_REWORK", items: [...] }`
    - Router will re-dispatch with Action: RUN (restarts from Step 6)

18. **Handle pending issue sync based on decision**:

    a. **If sync_action = DEFER_ALL**:
       - Skip sync — issues remain in alignment report for later

    b. **If sync_action = SYNC_ALL or SELECTIVE**:
       - Run Pending Issue Resolver agent:
         ```
         Follow the instructions in: {{AGENTS_PATH}}/universal-agents/pending-issue-resolver.md

         Alignment report: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/07-alignment-report.md

         Upstream pending-issues:
         - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/versions/pending-issues.md
         - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/versions/pending-issues.md
         - PRD: {{SYSTEM_DESIGN_PATH}}/system-design/02-prd/versions/pending-issues.md

         Decisions:
         [If SYNC_ALL: all issues get APPLY]
         [If SELECTIVE: per-issue decisions from state file]
         - PI-001: APPLY | DEFER | REJECT
         - PI-002: APPLY | DEFER | REJECT
         ...

         Output: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/11-pending-issue-sync.md
         ```

18b. **Close current-component pending-issues for entries resolved this round**:

    This step closes entries in the **current component's own** pending-issues file (`{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/pending-issues.md`). It is distinct from step 18's Pending Issue Resolver, which writes to **upstream** pending-issues files (Architecture / Foundations / PRD). Scope is per-component — only this component's pending-issues file is touched.

    Procedure:
    - Read `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/pending-issues.md`
    - Read this round's `02-consolidated-issues.md` to identify which Unresolved entries were merged into this round's issue stream by the Consolidator (Step 2) and routed by the Issue Router (Step 3) — these will be the entries with their original PI-NNN / SPEC-NNN IDs mapped to round-local issue IDs
    - Read this round's `03-issues-discussion.md` to identify the resolution outcome for each merged entry (APPLIED inline, close-with-no-change, close-as-stale, or close-as-resolved-by-prior-round)
    - For each merged-and-resolved entry:
      - Move it from the `## Unresolved Issues` section to the `## Resolved Issues` section (insert at the top of Resolved, in reverse-chronological order with a new dated subsection header for this round, scoped as `[component] Round [N] Review-[build|ops]`)
      - Add resolution metadata to the entry:
        - `**Status:** RESOLVED`
        - `**Resolved:** [date]`
        - `**Resolution Round:** [component] Round [N] Review-[build|ops] (issue tracked as [round-local ID])`
        - `**Resolution:** [one-paragraph note explaining how the round closed the entry — APPLIED edits reference the spec section; close-with-no-change references the human-approved recommendation; close-as-resolved-by-prior-round references the earlier round's issue ID that closed it]`
    - Update the Summary table counts (UNRESOLVED ↓, RESOLVED ↑)
    - **Do not touch entries that were not merged into this round's issue stream** (e.g., Unresolved entries logged after Step 2 but before Step 12) — those carry forward to the next round
    - **Per-component scope only**: do not touch other components' pending-issues files; cross-component issues are handled by the Pending Issue Resolver in step 18 (upstream sync) or by the components Coherence orchestrator separately
    - **Also record mainline dismissals (re-raise ledger)**: for each **expert-raised issue this round** (a round-local SPEC-NNN that was **not** already a pending-issue) whose resolution outcome in `03-issues-discussion.md` is **close-with-no-change** or **close-as-stale** (dismissed / won't-fix / working-as-intended — a resolution that leaves **no trace in the spec text**), **add a new entry** to the `## Resolved Issues` section with:
        - `**Status:** RESOLVED (dismissed — no spec change)`
        - `**Resolved:** [date]` · `**Resolution Round:** [component] Round [N] Review-[build|ops]`
        - `**Concern key:** [spec section anchor] — [one-line concern summary]` — this is the **stable key the Consolidator matches against to suppress re-raises**; use the spec section + concern gist, because round-local SPEC-NNN IDs do not persist across rounds
        - `**Resolution:** [why it was dismissed — the human-approved rationale]`
      APPLIED-inline resolutions do **not** need a ledger entry (the spec text changed, so a future round sees the fix directly). It is specifically the **no-spec-change dismissals** that must be recorded — otherwise the unchanged spec text invites the identical concern to be re-raised next round, which is the review loop's non-convergence trap.

    Rationale: this step ensures each component's own pending-issues file reflects the truth of what each round closed. Without it, downstream readers (other components, Coherence reviews, future rounds) see stale Unresolved entries that have actually been addressed. The orchestrator separates this from step 18's Pending Issue Resolver because the Resolver's semantic is "edit upstream documents (Architecture/Foundations/PRD)", whereas this step's semantic is "close entries in this component's own pending-issues register".

19. **If halt_action = ACKNOWLEDGE_AND_BLOCK**:
    - Write blocking issue to upstream pending-issues.md
    - Update state: Status = BLOCKED_UPSTREAM_ISSUE
    - Return `{ status: "BLOCKED", blocking_issue: {...} }`

20. **Update state file**: Mark Step 12 complete

21. **Determine recommendation** (for routing decision):
    - Current part: build or ops
    - **Blocking issues this round**: count the **HIGH and MEDIUM** issues this round surfaced and kept at spec level (from `03-issues-discussion.md`). LOW issues do **not** count toward maturity.
    - **Maturity**: mature if this round surfaced **no HIGH or MEDIUM** issues. This is the convergence criterion — a round that comes back with only LOW (or nothing) has stabilised this part. LOW items are **carried and recorded** (Step 18b), not chased round-over-round. This aligns the maturity threshold with the VERIFICATION_CLEAN gate and the create-stage Step 10c gate: exit on "no HIGH/MEDIUM", **not** "zero issues".

    Recommendation logic:
    - If build and not mature → CONTINUE_BUILD
    - If build and mature → TRANSITION_TO_OPS
    - If ops and not mature → CONTINUE_OPS
    - If ops and mature → EXIT
    - If ops found structural issues → KICK_BACK_TO_BUILD

22. **Return to router** with VERIFICATION_CLEAN status and recommendation

---

## Action: PROMOTE (Step 13)

Router dispatches after human confirms EXIT.

### Step 13: Promote Spec

23. **Update state file**: Set Step 13, status = IN_PROGRESS

24. **Run Spec Promoter agent**:
    ```
    Follow the instructions in: {{AGENTS_PATH}}/05-components/review/spec-promoter.md

    Input:
    - Reviewed spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-review-[build|ops]/05-updated-spec.md
    - Component name: [component]
    - Guide: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/guide.md

    Output:
    - Implementation spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/[component].md
    - Future planning: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/future/[component].md
    - Decisions: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/decisions/[component].md
    ```

25. **Verify outputs exist** at all three paths

26. **Update state file**: Mark Step 13 complete, Status = COMPLETE

27. **Return to router**:
    ```
    {
      status: "PROMOTED",
      implementation_spec: "{{SYSTEM_DESIGN_PATH}}/system-design/05-components/specs/[component].md",
      future_planning: "{{SYSTEM_DESIGN_PATH}}/system-design/05-components/future/[component].md",
      decisions: "{{SYSTEM_DESIGN_PATH}}/system-design/05-components/decisions/[component].md"
    }
    ```

---

## Return to Router

### After RUN (Steps 6-11)

**If NEEDS_REWORK:**
```
{
  status: "NEEDS_REWORK",
  not_resolved: [
    { id: "SPEC-001", summary: "..." },
    ...
  ]
}
```
Router informs human, re-dispatches with Action: RUN.

**If NEEDS_DECISIONS:**
```
{
  status: "NEEDS_DECISIONS",
  partially_resolved: [
    { id: "SPEC-001", summary: "..." },
    ...
  ],
  halt_blockers: [
    { id: "PI-001", target: "architecture", summary: "..." },
    ...
  ],
  pending_issue_sync: [
    { id: "PI-002", target: "foundations", summary: "...", certainty: "CERTAIN" },
    ...
  ]
}
```
Router stores in state file, presents to human, collects decisions, re-dispatches with Action: APPLY_DECISIONS.

**If VERIFICATION_CLEAN:**
```
{
  status: "VERIFICATION_CLEAN",
  current_part: "build",
  high_issues_remaining: 0,
  recommendation: "TRANSITION_TO_OPS"
}
```
Router presents routing options to human, collects decision.

### After APPLY_DECISIONS (Step 12)

**If BLOCKED:**
```
{
  status: "BLOCKED",
  blocking_issue: { id: "PI-001", target: "architecture", summary: "..." }
}
```
Router updates state, informs human, stops.

**If successful:**
```
{
  status: "VERIFICATION_CLEAN",
  current_part: "build",
  high_issues_remaining: 0,
  recommendation: "TRANSITION_TO_OPS"
}
```
Router presents routing options to human.

### After PROMOTE (Step 13)

```
{
  status: "PROMOTED",
  implementation_spec: "...",
  future_planning: "...",
  decisions: "..."
}
```
Router updates state to COMPLETE, reports to human.

---

<!-- INJECT: tool-restrictions -->
