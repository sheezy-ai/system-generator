# System-Maintainer

Agentic framework for maintaining and evolving software systems built by System-Builder. Agents research, propose, and build; humans decide and approve.

**Relationship to System-Builder:** System-Builder creates the system (design docs + code + monitoring + deployment). System-Maintainer evolves it. System-Builder's outputs are System-Maintainer's source of truth. When maintenance requires design-level changes, System-Maintainer invokes System-Builder's review pipeline at the appropriate stage.

**Relationship to System-Operator:** System-Operator runs the system (monitoring, scaling, incident response). System-Operator feeds signals to System-Maintainer (performance regression → investigate root cause). System-Maintainer feeds changes to System-Operator (new deployment → monitor rollout). They share infrastructure but have different workflows, cadence, and autonomy profiles.

---

## Core Concept

A signal arrives (bug, feature request, dependency update, performance issue). The framework:

1. **Investigates** — agents trace through code, design docs, and production context
2. **Classifies** — determines change depth and blast radius
3. **Routes** — sends to the appropriate workflow
4. **Executes** — agents make the change with appropriate verification
5. **Syncs** — keeps design docs current with reality
6. **Deploys** — gets the change live with appropriate checks

The depth of process scales with the depth of change. A bug fix doesn't need an expert review panel. An architectural change does.

---

## Change Depth Model

The primary classification axis. Determines which workflow handles the change and how much process is applied.

| Depth | Definition | Design stages affected | Examples |
|-------|-----------|----------------------|----------|
| **Patch** | Code-only fix within existing design | None (spec annotation at most) | Bug fix, dependency update, performance tuning, security patch |
| **Extend** | New capability within existing architecture | Component spec(s) → Tasks → Build | New endpoint, new field, new validation, new integration consumer |
| **Evolve** | Change to architectural or foundational decisions | Enter System-Builder pipeline at affected stage, cascade down | New component, changed data flow, new auth strategy, DB migration pattern |
| **Pivot** | Strategic direction change | Full System-Builder pipeline from Blueprint | Product pivot, new market, fundamental rethink |

**Pivot** is rare enough that it doesn't need special framework support — you run System-Builder again. The framework focuses on Patch, Extend, and Evolve.

### Secondary axis: Certainty

Some changes are unambiguous (dependency CVE with patch available). Others need investigation (intermittent error under load). The combination determines the starting point:

| | High certainty | Low certainty |
|---|---|---|
| **Shallow** (Patch) | Propose fix → approve → deploy | Investigate → propose → approve → deploy |
| **Deep** (Extend/Evolve) | Enter workflow at proposal stage | Investigate → classify depth → enter workflow |

---

## Signal Types

What triggers the maintenance framework. Each signal type has a natural entry point and typical depth.

| Signal | Source | Typical depth | Urgency |
|--------|--------|--------------|---------|
| Bug report | Users, QA, monitoring | Patch (usually) | Varies (critical → immediate, minor → queued) |
| Feature request | Users, product, business | Extend or Evolve | Planned |
| Performance regression | Monitoring, alerts | Patch or Evolve | High |
| Dependency vulnerability | Security scanning | Patch | High (severity-dependent) |
| Dependency update | Dependabot, manual audit | Patch | Low (unless breaking) |
| Tech debt | Engineering review | Patch or Extend | Low |
| Spec drift detected | Consistency verification | Patch (fix code) or Extend (update spec) | Medium |
| Upstream design change | System-Builder pipeline rerun | Evolve (cascade) | Planned |

---

## Workflows

### Investigation (shared entry point)

All signals pass through investigation unless certainty is high and depth is shallow.

**Investigation Agent** receives:
- The signal (bug report, feature request, alert, etc.)
- Access to: codebase, design docs (all system-builder outputs), production context (logs, metrics if available)

**Investigation Agent produces:**
- Root cause or requirements analysis
- Affected components (which component specs, which code modules)
- Proposed change depth classification (Patch / Extend / Evolve)
- Blast radius assessment (what else could be affected)
- Confidence level (high / medium / low — low triggers human review of classification)

**Human checkpoint:** If confidence is low, or if the proposed depth is Evolve, present classification to human for confirmation before routing.

---

### Workflow 1: Patch

Code-only changes. No design doc modifications (at most, a spec annotation like "see patch P-xxx for edge case handling").

```
Signal → Investigate → Propose Fix → Test → Human Approve → Deploy → Verify
```

**Steps:**

1. **Investigate** — trace the issue through code and design docs. Understand intended behaviour from component spec. Identify root cause.

2. **Propose fix** — agent produces:
   - Code changes (diff)
   - Test changes (new tests covering the fix, regression tests)
   - Impact assessment (what other code paths are affected)
   - Spec consistency check (does the fix align with the component spec's intended behaviour, or does it reveal a spec gap?)

3. **Test** — run existing test suite + new tests. Report results.

4. **Human approve** — present: the signal, root cause analysis, proposed fix, test results, impact assessment. Human approves, requests changes, or reclassifies (e.g., "this is actually an Extend, the spec needs updating").

5. **Deploy** — push to staging, run integration tests, promote to production.

6. **Verify** — confirm the fix resolves the original signal. Monitor for regressions.

**Graduated autonomy:** For high-certainty, low-risk patches (dependency security patch with passing tests, trivial bug fix in isolated code), the framework can auto-apply and notify human post-hoc rather than waiting for approval. The criteria for "auto-approvable" should be conservative and explicitly defined.

---

### Workflow 2: Extend

New capability within existing architecture. Requires component spec update(s) and downstream code changes.

```
Signal → Investigate → Spec Update → Consistency Check → Tasks → Build → Test → Human Approve → Deploy → Verify
```

**Steps:**

1. **Investigate** — understand the request. Map to affected component(s). Check if the architecture supports this extension without modification (if not, reclassify as Evolve).

2. **Propose spec update** — agent drafts changes to affected component spec(s):
   - New endpoints, fields, validations, error cases
   - Updated contracts (if the change affects component interfaces)
   - Stays within the existing architectural boundaries

3. **Consistency check** (lightweight, not full expert review):
   - Does the spec change conflict with the architecture doc?
   - Does it break any existing contracts (cross-reference with other component specs)?
   - Does it respect the foundations (technology choices, patterns)?
   - This is an agent check, not a human review panel — speed matters for extensions.

4. **Human review of spec changes** — present the proposed spec update with consistency check results. Human approves the design before any code is written.

5. **Tasks** — generate implementation tasks from the spec delta (reuse System-Builder's task generation).

6. **Build** — implement the changes (reuse System-Builder's build agents).

7. **Test** — run full test suite. Include contract tests for any changed interfaces.

8. **Human approve** — present: the implementation, test results, spec-code consistency verification. Human approves for deployment.

9. **Deploy + Verify** — same as Patch.

---

### Workflow 3: Evolve

Changes to architectural or foundational decisions. Invokes System-Builder's review pipeline at the affected stage.

```
Signal → Investigate → Identify entry stage → System-Builder review pipeline → Cascade to affected downstream stages → Build → Test → Human Approve → Deploy → Verify
```

**Steps:**

1. **Investigate** — understand the change. Identify which system-builder stage is the entry point:
   - Foundations-level change → enter at Stage 03
   - Architecture-level change → enter at Stage 04
   - Component-level structural change → enter at Stage 05 (not Extend because it changes component boundaries, adds new components, or changes data flows)

2. **Impact analysis** — agent traces the change through the design doc chain:
   - Which downstream documents are affected?
   - Which components need spec updates?
   - What existing functionality could break?
   - What deployment considerations exist (data migration, API versioning)?

3. **Human review of scope** — present impact analysis. Human confirms the scope and entry stage before invoking the pipeline.

4. **Enter System-Builder pipeline** — run the review workflow for the affected stage:
   - Expert review of the proposed change (scoped to the change, not a full document review)
   - Discussion loop for issues raised
   - Author applies changes
   - Verification (change + alignment)
   - This is the existing System-Builder review machinery, potentially with a "targeted review" mode

5. **Cascade** — for each downstream stage affected:
   - Update the design document at that stage
   - Run a lightweight consistency review (not full expert panel unless the cascade changes are substantial)
   - Continue until all affected stages are updated

6. **Build + Test + Deploy** — same as Extend but with broader test scope (integration tests across affected components, contract tests for all changed interfaces).

**Note:** Evolve changes are the riskiest. The framework should default to more human checkpoints, not fewer. Graduated autonomy doesn't apply here.

---

## Design Doc Sync

**Principle: Design docs are the source of truth, not the code.**

If code and specs diverge, one of two things happened:
- The code is wrong (fix the code) — this is a Patch
- The spec is incomplete (update the spec) — this is an Extend

The framework includes a periodic **consistency verification** that compares code against component specs and flags drift. This runs as a background process, not on every change.

### Sync rules by workflow:

| Workflow | Spec change? | Sync mechanism |
|----------|-------------|----------------|
| Patch | No (annotation at most) | Spec unchanged. Code is fixed to match spec. |
| Extend | Yes (before code) | Spec updated first, then code written to match. Spec reviewed by human before build. |
| Evolve | Yes (through System-Builder) | Full review pipeline updates specs. Code follows. |

### Consistency verification (periodic):

Agent reads each component spec and compares against the implemented code:
- Are all specified endpoints implemented?
- Do data models match the spec?
- Are contracts between components honoured?
- Are error handling patterns consistent with spec?

Drift is reported as signals that enter the normal triage process.

---

## System-Builder Output Requirements

What System-Maintainer needs from System-Builder's outputs to function effectively.

### Already produced (no changes needed):
- Design documents at each stage (Blueprint through Component Specs)
- Implementation code with tests
- Task definitions linking specs to implementation

### Needed (System-Builder changes):
- **Component dependency map** — which components depend on which others, derived from Architecture + Component Specs. Needed for blast radius analysis.
- **Contract definitions** — machine-readable interface contracts between components (not just prose in specs). Needed for automated contract testing and consistency verification.
- **Monitoring definitions** — health checks, SLOs, alerting rules derived from PRD requirements and component specs. Needed for System-Operator and for System-Maintainer's verification step.
- **Deployment configuration** — how each component is deployed, dependencies, startup order, rollback procedure. Currently implicit in build output; needs to be explicit.
- **Spec-to-code traceability** — mapping from spec sections to code locations. Enables investigation agents to trace from design intent to implementation. Could be generated during build.

### Informing System-Builder design stages:
- **PRD** should specify SLAs/SLOs (System-Operator needs these for alerting)
- **Architecture** should explicitly define the component dependency graph (System-Maintainer needs this for impact analysis)
- **Component Specs** should include machine-readable contract definitions alongside the prose (or a section that can be parsed)
- **Foundations** should specify monitoring and observability patterns (so build stage knows what to generate)

---

## Graduated Autonomy

Not all changes need the same level of human involvement. The framework defines autonomy tiers:

### Tier 1: Auto-apply, notify post-hoc
- Dependency security patches with passing tests
- Trivially deterministic fixes (e.g., typo in error message matching a bug report)
- Criteria: Patch depth, high certainty, isolated change (no cross-component impact), all tests pass

### Tier 2: Propose, wait for approval
- Most Patches (bug fixes, performance tuning)
- Extensions with clear requirements
- Criteria: Agent produces complete proposal, human reviews before execution

### Tier 3: Investigate, present options, wait for direction
- Low-certainty signals (need investigation before proposing)
- Extensions where requirements are ambiguous
- Criteria: Agent presents analysis and options, human chooses direction

### Tier 4: Full human engagement
- All Evolve changes
- Changes affecting security, data integrity, or user-facing behaviour
- Any change where agents express low confidence
- Criteria: Human involved at investigation, proposal, and approval stages

The tier is determined by: change depth × certainty × blast radius × risk domain. The framework should err on the side of more human involvement until trust is established.

---

## Design Decisions

1. **Concurrent changes** — Component-level pessimistic locking. Conflicting changes queued; independent components proceed in parallel. Evolve blocks Patch/Extend on the same component. **[REFINE DURING IMPLEMENTATION]** — optimistic locking with conflict detection may prove better if changes rarely overlap.

2. **Rollback** — Design docs are never rolled back. Failed deployment creates a new Patch signal. If the design was wrong, that's a new Extend or Evolve signal.

3. **Versioning** — Inline version numbers in design docs + git commits for code. Change Records link specific doc versions to specific commit ranges. **[REFINE DURING IMPLEMENTATION]** — linking mechanism between doc versions and commit ranges needs validation; git tags or a version manifest may work better.

4. **Testing strategy** — System-Builder's generated tests as baseline. Each change adds its own: Patch adds regression tests, Extend adds feature + contract tests, Evolve adds integration + contract tests. **[REFINE DURING IMPLEMENTATION]** — may need more structure around expected test types per workflow.

5. **Multi-system** — One Maintainer per system. Independent artefacts, state, and tools.

6. **Learning** — Deferred. Change Log provides raw material for future pattern detection.

---

## What's NOT in System-Maintainer

- **Infrastructure operations** (scaling, monitoring, incident response) → System-Operator
- **Initial system creation** → System-Builder
- **Strategic product decisions** → Human (with System-Builder for execution)
- **CI/CD pipeline management** → System-Operator or platform tooling
- **User communication** (release notes, changelogs) → could be a System-Maintainer output, but the content is human-reviewed
