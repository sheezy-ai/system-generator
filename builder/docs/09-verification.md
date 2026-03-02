# Build Verification Stage

Build verification takes the code produced by stage 08 and **executes it** to verify it actually works. This is fundamentally different from stage 08's review, which assessed code against specs without execution.

---

## Purpose

| Aspect | Description |
|--------|-------------|
| **Input** | Built code in project source tree, build conventions |
| **Output** | Verification reports, fix logs, fix proposals |
| **Abstraction Level** | Execution: real tool output from real commands |
| **Key Question** | "Does the code actually work?" |

---

## What Belongs Here

- Lint output and fix logs
- Type check output and fix logs
- Test execution results
- Fix proposals for test failures

---

## What Does NOT Belong Here

- Code review against specs (Stage 08)
- Code generation (Stage 08)
- Design documentation
- Build conventions (Stage 07)

---

## Pre-condition

The build stage (08) must have completed with COMPLETE status. All components built and cross-component spec-fidelity check passed.

---

## Workflow

Two sequential phases. Phase 1 must pass before Phase 2 begins.

```
Phase 1 (automated):  Verify → Fixer → Re-verify (max 3 rounds)
Phase 2 (human):      Run tests → Proposal → Human edits → Re-run
```

```
┌──────────────────────────────────────────────────────────────────────────┐
│              PHASE 1: MECHANICAL VERIFICATION (automated)                │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐               │
│  │   Verify     │───▶│    Route     │───▶│    Fixer     │               │
│  │ (lint/types) │    │  PASS/FAIL   │    │ (edit code)  │               │
│  └──────────────┘    └──────────────┘    └──────┬───────┘               │
│        ▲                                        │                       │
│        └────────────────────────────────────────┘                       │
│                    (re-verify, max 3 rounds)                            │
│                                                                          │
│  PASS ──▶ Phase 2                                                       │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│            PHASE 2: UNIT TEST EXECUTION (human checkpoint)               │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐               │
│  │  Run Tests   │───▶│    Route     │───▶│   Proposal   │               │
│  │  (execute)   │    │  PASS/FAIL   │    │ (analyze)    │               │
│  └──────────────┘    └──────────────┘    └──────┬───────┘               │
│        ▲                                        │                       │
│        │                                        ▼                       │
│        │                                 ┌──────────────┐               │
│        └─────────(re-invoke)─────────────│    Human     │               │
│                                          │  (decides)   │               │
│                                          └──────────────┘               │
│                                                                          │
│  PASS ──▶ COMPLETE                                                      │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Orchestration Model

Single coordinator — no pipeline runners, no tiers, no parallel spawning. Stage 09 runs project-wide.

- **Coordinator** (`coordinator.md`): Manages both phases, spawns agents, routes on results, manages workflow state. Simplest coordinator in the system.

- **Verifier** (`verifier.md`): Runs checks via Bash (broad access for running lint, type checks, and tests). Phase-aware: runs lint/types/imports in Phase 1, unit tests in Phase 2. Read-only on code, writes only reports.

- **Fixer** (`fixer.md`): Reads verify report, makes targeted code edits to fix mechanical issues. Phase 1 only. Does not modify test logic (assertions, expectations, setup), but can fix mechanical issues (lint, type annotations, imports) in test files.

- **Test Proposal** (`test-proposal.md`): Reads test failures, analyzes each one, classifies as code bug / test bug / setup issue / ambiguous, writes proposal for human review. Phase 2 only. Read-only on code, writes only the proposal.

---

## Phase 1: Mechanical Verification

**Checks**: Lint, type checking, import validation.

These are unambiguous — "lint error on line 45" means fix line 45. Fully automated fix loop.

1. Verifier runs lint, type check, and import validation
2. If PASS → transition to Phase 2
3. If FAIL → fixer applies targeted edits, re-verify (max 3 rounds)
4. If still failing after 3 rounds → human intervention required

---

## Phase 2: Unit Test Execution

**Checks**: Unit test suites (not integration or E2E — those are later stages).

Test failures are ambiguous — could be code or test that's wrong. Human decides.

1. Verifier runs unit test suites
2. If PASS → COMPLETE
3. If FAIL → proposal agent analyzes failures, writes proposal
4. Human reviews proposals, makes changes, re-invokes coordinator
5. Coordinator re-runs tests (new round)

---

## File Paths

**Stage documentation:** `docs/09-verification.md`

**Agent prompts:**
```
agents/09-verification/
├── coordinator.md       # Orchestrates both phases
├── verifier.md          # Runs checks (broad Bash access)
├── fixer.md             # Fixes mechanical issues (Phase 1)
└── test-proposal.md     # Proposes test fixes (Phase 2)
```

**Output locations:**
```
system-design/09-verification/
└── versions/
    ├── workflow-state.md
    ├── phase-1/
    │   └── round-N/
    │       ├── 01-verify-report.md       # Lint/type/import results
    │       └── 02-fix-log.md             # Fixes applied (FAIL rounds)
    └── phase-2/
        └── round-N/
            ├── 01-test-report.md         # Test execution results
            └── 02-fix-proposal.md        # Proposed fixes (FAIL rounds)
```

---

## Invocation

**Run build verification:**
```
Read the Verification coordinator at:
agents/09-verification/coordinator.md

Verify.
```

The coordinator verifies build is complete, runs Phase 1 (automated), then Phase 2 (human checkpoint). Re-invoke after making changes to continue.

---

## State Management

Track workflow state in `versions/workflow-state.md`:

```markdown
# Build Verification Workflow State

**Status**: PHASE_1 | PHASE_2 | COMPLETE
**Started**: YYYY-MM-DD
**Phase 1 Rounds**: [N]
**Phase 2 Rounds**: [N]

## History

- YYYY-MM-DD: Build verification started
```

---

## Key Principles

- **Phase-separated**: Mechanical fixes (automatable) separated from test fixes (judgment required)
- **Execution-based**: Real tool output from real commands, not static analysis
- **Verifier is read-only on code**: Writes only reports (DEC-051)
- **Human-in-the-loop for tests**: Test failures are ambiguous; human decides what to fix (DEC-062)
- **Project-wide**: Single verification pass, not per-component (DEC-061)
- **Designed to evolve**: Phase 2 human checkpoint can become more automated over time
