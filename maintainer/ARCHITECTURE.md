# System-Maintainer Agent Architecture

Concrete agent design for the System-Maintainer framework. Defines what agents exist, how they coordinate, what artefacts and state they access, and how they interact with System-Builder, System-Operator, and humans.

**Prerequisite reading:** `OVERVIEW.md` defines the framework's purpose, workflows, change depth model, and graduated autonomy. This document makes those concrete.

**Relationship to System-Operator:** The integration contract (`INTEGRATION.md`) defines the signal formats and artefact ownership between the two frameworks. This architecture references those signals but does not redefine them.

**Relationship to System-Builder:** System-Maintainer invokes System-Builder's review pipeline for Evolve-depth changes. The invocation model is defined in § System-Builder Invocation Model. System-Builder's agent prompts are read by path reference, not duplicated.

---

## Agent Inventory

Eight agents: one dispatcher, one investigation agent, three workflow coordinators, one consistency verifier, one artefact sync worker, and one universal escalation agent.

| Agent | Type | Session model | Responsibility |
|-------|------|--------------|----------------|
| **Dispatcher** | Router | Long-running or frequently re-invoked | Classifies incoming signals by certainty and initial depth estimate, routes to Investigation or directly to workflow agents, manages concurrent change coordination |
| **Investigation Agent** | Research | Per-invocation (one per signal) | Traces through code, design docs, and production context. Produces: root cause, affected components, depth classification, blast radius, confidence. The framework's heavyweight first-class concern. |
| **Patch Agent** | Workflow coordinator | Per-invocation (one per patch) | Code-only fixes: propose fix, test, get approval, deploy, verify. Manages spec consistency checks and autonomy tier evaluation. |
| **Extend Agent** | Workflow coordinator | Per-invocation (one per extension) | New capability within existing architecture: spec update, consistency check, task generation, build, test, deploy. Manages human review at both spec and code stages. |
| **Evolve Agent** | Workflow coordinator | Per-invocation (one per evolution) | Architectural changes: impact analysis, System-Builder pipeline invocation, cascade management, build, test, deploy. The most complex workflow with multiple human checkpoints. |
| **Consistency Verifier** | Periodic | Per-invocation (scheduled) | Compares code against component specs. Reports drift as signals that enter the normal triage process. |
| **Artefact Sync Agent** | Worker | Per-invocation (spawned by workflow agents) | Updates operational artefacts (component map, contracts, risk profile, traceability, monitoring, runbooks, etc.) after changes. Sends Artefact Update signals to Operator. |
| **Escalation Agent** | Universal | Per-invocation (spawned by any agent) | Formats and sends structured notifications to Human or Operator (Deployment Request, Watch Request, Artefact Update). Same pattern as System-Operator's Escalation Agent. |

### Design rationale

**Investigation Agent is separate from workflow agents** because investigation is a research activity with a distinct access pattern (reads everything: code, specs, artefacts, production context) and a distinct output structure (classification + evidence, not action). Embedding investigation inside each workflow agent would triplicate the investigation logic and bloat each workflow agent's context with tools it only needs during the research phase.

**One agent per workflow depth** (Patch, Extend, Evolve) follows the System-Operator pattern (one agent per workflow). Each workflow reads different artefacts, writes different state, and involves different human checkpoints.

**Artefact Sync Agent is separate** because artefact updates occur in all three workflows (Patch updates traceability; Extend updates specs, contracts, traceability; Evolve updates everything). Extracting this avoids duplicating update logic and ensures consistent artefact formats.

**Consistency Verifier is periodic, not per-change.** Running consistency checks after every Patch would be wasteful — the Patch workflow already includes a spec consistency check. The periodic verifier catches drift that accumulates between formal workflows (manual hotfixes, config changes, etc.).

**Escalation Agent shares the pattern with System-Operator.** Escalation formatting is identical regardless of which workflow triggers it. Handles outbound signals to both Human and Operator, using the signal formats defined in `INTEGRATION.md`.

---

## Coordination Model

```
Signal Source
(bug reports, feature requests, dependency alerts,
 Operator escalations, spec drift, human directives)
         │
         ▼
   ┌─────────────┐
   │  Dispatcher  │  classifies signal: certainty + depth estimate
   └──────┬──────┘
          │
     ┌────┴─────┐
     │          │
     ▼          ▼
  Direct     Investigation
  Route       Agent
  (high       (low certainty,
  certainty,   deep changes,
  shallow)     ambiguous signals)
     │          │
     │     produces:
     │     classification,
     │     root cause,
     │     blast radius,
     │     confidence
     │          │
     └────┬─────┘
          │
     ┌────┴────┬──────────┐
     │         │          │
     ▼         ▼          ▼
   Patch    Extend     Evolve
   Agent     Agent      Agent
     │         │          │
     └────┬────┴────┬─────┘
          │         │
          ▼         ▼
   Artefact Sync  Escalation
      Agent         Agent
    (spawned by   (spawned by
     any workflow  any agent)
     agent)
```

### Signal routing

The Dispatcher classifies every incoming signal by two dimensions: **certainty** (high/low) and **initial depth estimate** (Patch/Extend/Evolve). It routes based on the certainty-depth matrix from OVERVIEW.md.

| Signal type | Certainty assessment | Route |
|-------------|---------------------|-------|
| Dependency security patch (CVE with fix available) | High certainty, Patch | Patch Agent directly |
| Dependency non-security update | High certainty, Patch | Patch Agent directly |
| Bug report (clear reproduction, isolated) | High certainty, Patch | Patch Agent directly |
| Bug report (intermittent, unclear cause) | Low certainty | Investigation Agent |
| Feature request (clear, within architecture) | High certainty, Extend | Extend Agent (with lightweight investigation embedded) |
| Feature request (unclear scope or architectural implications) | Low certainty | Investigation Agent |
| Performance regression | Low certainty | Investigation Agent |
| Operator escalation (code/design issue) | Low certainty | Investigation Agent (with Operator's diagnostic context) |
| Spec drift detected (from Consistency Verifier) | Medium certainty | Dispatcher classifies: code is wrong → Patch; spec is incomplete → Extend |
| Upstream design change (from System-Builder) | High certainty, Evolve | Evolve Agent directly |
| Human directive | Per directive | Route per human's explicit classification |
| Deployment Feedback: ROLLED_BACK (from Operator) | Low certainty | Investigation Agent (code change caused issues) |
| Deployment Feedback: SUCCESS (from Operator) | N/A | Log, close change record |
| Unclassifiable signal | Unknown | Escalation Agent → Human |

### Concurrent change handling

Multiple changes can be in flight simultaneously. The Dispatcher coordinates using the Change Registry:

1. **Component-level awareness** — when a new signal arrives for a component with an active change:
   - **Same root cause** → correlate into the existing change (additional context, not new workflow)
   - **Independent concern** → allow parallel workflows (different aspects of the same component)
   - **Conflicting scope** → queue the new signal until the active change completes

2. **Depth conflict** — if a Patch is in-flight and an Extend arrives for the same component, the Extend takes priority. The Patch is absorbed (if related) or queued (if independent).

3. **Evolve blocks all** — if an Evolve is in-flight for a component, all Patch and Extend changes for that component are queued. Evolve changes are too broad to allow concurrent modification.

4. **Cross-component independence** — changes to different components with no dependency relationship can always run in parallel.

The model is **pessimistic for overlapping components, optimistic for independent components**. Conflicts are detected at routing time (Dispatcher), not at merge time. This prevents wasted work.

---

## Workflow Interaction Diagrams

### Investigation Workflow

```
Signal (via Dispatcher)
     │
     ▼
┌──────────────────────┐
│ Investigation Agent   │
└──────┬───────────────┘
       │
       ├── Step 1: Receive and log
       │   writes: Change Record (new, status: INVESTIGATING)
       │
       ├── Step 2: Gather context
       │   reads: Component Map → identify affected component(s)
       │   reads: Traceability → find code locations for affected spec sections
       │   reads: Risk Profile → component criticality, data sensitivity
       │   reads: Component Specs → intended behaviour (relevant sections via Traceability)
       │   reads: Source code → actual implementation (via Traceability paths)
       │   reads: Test code → existing test coverage
       │   if Operator escalation:
       │     reads: Operator's diagnostic context (embedded in Escalation signal)
       │
       ├── Step 3: Analyse
       │   for bugs: trace execution path, identify root cause
       │   for features: map to architecture, check feasibility within boundaries
       │   for performance: identify bottleneck, determine if code or architecture
       │   for vulnerabilities: assess patch availability, breaking changes
       │
       ├── Step 4: Classify
       │   produces:
       │     - Root cause / requirements analysis
       │     - Affected components (with spec section references)
       │     - Proposed depth: Patch | Extend | Evolve
       │     - Blast radius (from Component Map dependencies)
       │     - Confidence: HIGH | MEDIUM | LOW
       │     - Evidence: specific code locations, spec references, metrics
       │
       └── Step 5: Route
           if confidence HIGH and depth Patch:
             writes: Change Record (depth: Patch, status: CLASSIFIED)
             → Dispatcher routes to Patch Agent
           if confidence HIGH and depth Extend:
             writes: Change Record (depth: Extend, status: CLASSIFIED)
             → Dispatcher routes to Extend Agent
           if confidence HIGH and depth Evolve:
             writes: Change Record (depth: Evolve, status: AWAITING_HUMAN)
             spawn Escalation Agent → Human (present classification for confirmation)
             on confirmation → Dispatcher routes to Evolve Agent
           if confidence LOW or MEDIUM:
             writes: Change Record (status: AWAITING_HUMAN)
             spawn Escalation Agent → Human:
               present analysis, proposed depth, confidence, uncertainties
             on response → Dispatcher routes accordingly
```

### Workflow 1: Patch

```
Investigation output (or direct signal for high-certainty patches)
     │
     ▼
┌──────────────────────┐
│ Patch Agent           │
└──────┬───────────────┘
       │
       ├── Step 1: Verify classification
       │   reads: Change Record (investigation output if available)
       │   reads: Component Spec → intended behaviour for affected area
       │   reads: Risk Profile → change risk heuristics
       │   decision: confirm Patch depth (or escalate if misclassified)
       │   determines: autonomy tier
       │
       ├── Step 2: Propose fix
       │   reads: Source code (via Traceability paths)
       │   reads: Test code (existing coverage)
       │   reads: Component Spec (intended behaviour — spec is the truth)
       │   produces:
       │     - Code changes (diff)
       │     - Test changes (regression tests, fix verification tests)
       │     - Impact assessment (other code paths affected)
       │     - Spec consistency check: does the fix align with spec?
       │       if spec gap detected → flag for potential reclassification to Extend
       │   writes: Change Record (status: FIX_PROPOSED)
       │
       ├── Step 3: Test
       │   acts: run existing test suite + new tests (Test tool)
       │   produces: test results (pass/fail, coverage delta)
       │   writes: Change Record (test results)
       │
       ├── Step 4: Autonomy decision
       │   ├─ Tier 1 (auto-apply):
       │   │  criteria: dependency security patch + all tests pass +
       │   │           no cross-component impact + LOW/MEDIUM risk
       │   │  acts: apply fix, proceed to Step 6
       │   │  spawn Escalation Agent → Human (post-hoc notification)
       │   │
       │   ├─ Tier 2 (propose, wait):
       │   │  spawn Escalation Agent → Human (approval request):
       │   │    signal, root cause, proposed fix, test results,
       │   │    impact assessment, spec consistency check
       │   │  writes: Change Record (status: AWAITING_APPROVAL)
       │   │  on approval → Step 5
       │   │  on reject → close change
       │   │  on reclassify → route to appropriate workflow
       │   │
       │   └─ Tier 3/4: should not occur for Patch — if it does,
       │      reclassify to Extend or Evolve
       │
       ├── Step 5: Apply fix
       │   acts: apply code changes (Edit/Write tools)
       │   acts: apply test changes (Edit/Write tools)
       │   writes: Change Record (status: APPLIED)
       │
       ├── Step 6: Deploy
       │   spawns Artefact Sync Agent:
       │     updates: Traceability (new/changed code locations)
       │   spawns Escalation Agent → Operator:
       │     Deployment Request signal (what changed, test results, monitoring focus)
       │   writes: Change Record (status: DEPLOYING)
       │   waits: Deployment Feedback from Operator
       │
       └── Step 7: Verify
           on Deployment Feedback:
             SUCCESS → writes: Change Record (status: COMPLETE)
                       optionally spawns Watch Request to Operator
             ROLLED_BACK → writes: Change Record (status: ROLLED_BACK)
                          new signal: investigate rollback cause
             FAILED → writes: Change Record (status: DEPLOY_FAILED)
                     investigate pre-flight failure
```

### Workflow 2: Extend

```
Investigation output (with depth = Extend)
     │
     ▼
┌──────────────────────┐
│ Extend Agent          │
└──────┬───────────────┘
       │
       ├── Step 1: Verify classification
       │   reads: Change Record, Component Spec(s), Architecture
       │   confirm: change fits within existing architecture
       │   if architecture boundary would be crossed → reclassify to Evolve
       │   writes: Change Record (status: SPEC_UPDATE)
       │
       ├── Step 2: Propose spec update
       │   reads: affected Component Spec(s) (full read)
       │   reads: Architecture (boundary context)
       │   reads: Foundations (pattern/convention context)
       │   reads: Contract Definitions (interface context)
       │   produces:
       │     - Spec changes (diff against current component spec)
       │     - New/changed endpoints, fields, validations, error cases
       │     - Updated contracts (if interfaces change)
       │   writes: Change Record (proposed spec changes)
       │
       ├── Step 3: Consistency check (lightweight)
       │   reads: Architecture → does spec change conflict?
       │   reads: other Component Specs → does it break contracts?
       │   reads: Foundations → does it respect patterns?
       │   reads: Contract Definitions → cross-component impact?
       │   produces: consistency report
       │   writes: Change Record (consistency check results)
       │
       ├── Step 4: Human review spec changes        ◄─── HUMAN CHECKPOINT 1
       │   spawn Escalation Agent → Human:
       │     proposed spec update, consistency check results,
       │     blast radius, affected contracts
       │   writes: Change Record (status: AWAITING_SPEC_APPROVAL)
       │   on approval → Step 5
       │   on modification → revise spec, return to Step 3
       │   on reclassify (to Evolve) → route to Evolve Agent
       │
       ├── Step 5: Apply spec update
       │   acts: update Component Spec(s) (Edit tool)
       │   writes: Change Record (status: SPEC_UPDATED)
       │
       ├── Step 6: Generate tasks
       │   reads: spec delta (what changed)
       │   produces: implementation tasks
       │     (reuses System-Builder task generation pattern, scoped to delta)
       │   writes: Change Record (tasks)
       │
       ├── Step 7: Build
       │   implements: code changes per tasks
       │     (reuses System-Builder build agents, scoped to delta)
       │   writes: Change Record (status: BUILT)
       │
       ├── Step 8: Test
       │   acts: full test suite + new tests + contract tests
       │        for changed interfaces (Test tool)
       │   produces: test results
       │   writes: Change Record (test results)
       │
       ├── Step 9: Human approve implementation     ◄─── HUMAN CHECKPOINT 2
       │   spawn Escalation Agent → Human:
       │     implementation, test results, spec-code consistency verification
       │   writes: Change Record (status: AWAITING_CODE_APPROVAL)
       │   on approval → Step 10
       │
       ├── Step 10: Deploy
       │   spawns Artefact Sync Agent:
       │     updates: Traceability, Contract Definitions,
       │             and any affected operational artefacts
       │   spawns Escalation Agent → Operator:
       │     Artefact Update (for changed operational artefacts)
       │     then Deployment Request
       │   writes: Change Record (status: DEPLOYING)
       │   waits: Deployment Feedback
       │
       └── Step 11: Verify
           same as Patch Step 7
```

### Workflow 3: Evolve

```
Investigation output (with depth = Evolve, human-confirmed)
     │
     ▼
┌──────────────────────┐
│ Evolve Agent          │
└──────┬───────────────┘
       │
       ├── Step 1: Impact analysis
       │   reads: investigation output (root cause, affected components)
       │   reads: Architecture (full)
       │   reads: Foundations
       │   reads: Component Map (full dependency graph)
       │   reads: Contract Definitions (all affected components)
       │   produces:
       │     - Entry stage: Foundations (03) | Architecture (04) | Components (05)
       │     - Downstream cascade: which stages and documents are affected
       │     - Existing functionality at risk
       │     - Deployment considerations (data migration, API versioning)
       │   writes: Change Record (impact analysis)
       │
       ├── Step 2: Human review scope              ◄─── HUMAN CHECKPOINT 1
       │   spawn Escalation Agent → Human:
       │     impact analysis, entry stage, cascade scope,
       │     risk assessment
       │   writes: Change Record (status: AWAITING_SCOPE_APPROVAL)
       │   on approval → Step 3
       │   on modification → revise scope, present again
       │   on reject → close change
       │
       ├── Step 3: Prepare System-Builder invocation
       │   produces: change proposal document:
       │     - What needs to change and why
       │     - Scope constraint: review the proposed change, not full document
       │     - Affected sections identified
       │   writes: change proposal to system-design staging area
       │   writes: Change Record (status: SYSTEM_BUILDER_INVOKED)
       │
       ├── Step 4: Invoke System-Builder review pipeline
       │   *** Critical integration point — see § System-Builder Invocation Model ***
       │
       │   Spawns subagent with System-Builder review orchestrator
       │   for the entry stage. The pipeline runs with its own human
       │   checkpoints (expert review, discussion, author, verification).
       │
       │   On completion:
       │     - Updated design doc at entry stage
       │     - Potentially: pending issues or deferred items
       │   writes: Change Record (entry stage review complete)
       │
       ├── Step 5: Cascade to downstream stages     ◄─── HUMAN CHECKPOINT 2
       │   Human confirms cascade approach before proceeding.
       │   For each downstream stage affected:
       │     ├─ Substantial changes → invoke System-Builder review pipeline
       │     └─ Mechanical changes → Evolve Agent updates directly,
       │                             runs lightweight consistency check
       │   writes: Change Record (cascade complete)
       │
       ├── Step 6: Generate tasks + Build
       │   reuses System-Builder task generation + build agents
       │   scoped to the delta from the cascade
       │   writes: Change Record (status: BUILT)
       │
       ├── Step 7: Test
       │   acts: full test suite + integration tests across affected
       │        components + contract tests for all changed interfaces
       │   writes: Change Record (test results)
       │
       ├── Step 8: Human approve implementation     ◄─── HUMAN CHECKPOINT 3
       │   spawn Escalation Agent → Human:
       │     full change summary (design + code), test results,
       │     cross-component impact verification
       │   on approval → Step 9
       │
       ├── Step 9: Deploy
       │   spawns Artefact Sync Agent:
       │     updates: ALL affected artefacts (component map, contracts,
       │             risk profile, traceability, monitoring, runbooks,
       │             deployment topology, security posture, SLOs)
       │   spawns Escalation Agent → Operator:
       │     Artefact Update (for all changed artefacts)
       │     then Deployment Request (potentially multi-component)
       │   writes: Change Record (status: DEPLOYING)
       │
       └── Step 10: Verify
           same as Patch Step 7, but with extended monitoring
           (Evolve changes default to 1-hour hold period)
```

### Consistency Verification (periodic)

```
Schedule trigger
     │
     ▼
┌──────────────────────┐
│ Consistency Verifier  │
└──────┬───────────────┘
       │
       ├── Step 1: Scope
       │   reads: Component Map → list of all components
       │   reads: Traceability → spec-to-code mappings
       │
       ├── Step 2: Per-component verification
       │   for each component:
       │     reads: Component Spec
       │     reads: Contract Definitions
       │     reads: Source code (via Traceability paths + Grep)
       │     checks:
       │       - Are all specified endpoints implemented?
       │       - Do data models match the spec?
       │       - Are contracts between components honoured?
       │       - Are error handling patterns consistent with spec?
       │       - Does code structure match traceability mappings?
       │     produces: drift report per component
       │
       ├── Step 3: Report
       │   aggregates per-component drift into system-wide report
       │   for each drift item, classifies:
       │     - Code is wrong → Patch signal
       │     - Spec is incomplete → Extend signal
       │     - Traceability stale → refresh needed
       │
       └── Step 4: Generate signals
           for each actionable drift item:
             writes: signal to Dispatcher (spec drift type)
           for stale traceability:
             spawns: Artefact Sync Agent to refresh traceability
```

---

## State Management

### State categories

| Category | Contents | Writers | Readers | Freshness |
|----------|----------|---------|---------|-----------|
| **Change Registry** | Active changes: ID, signal, component(s), depth, status, assigned workflow agent, timestamps | Dispatcher, all workflow agents | Dispatcher (concurrency check), all agents (context) | Real-time |
| **Change Records** | Per-change detail: investigation output, proposed fix/spec changes, test results, approval history, deployment feedback | Workflow agents (Patch/Extend/Evolve) | Investigation Agent (pattern analysis), human review | Per-change lifecycle |
| **Artefact State** | Version/hash per consumed artefact, last update timestamp | Artefact Sync Agent | All agents (stale artefact detection), Dispatcher (Artefact Update routing) | On change |
| **Verification State** | Last consistency check timestamp, per-component drift status, scheduled next run | Consistency Verifier | Dispatcher (scheduling) | Per verification cycle |

### Storage abstraction

Identical pattern to System-Operator. The framework defines the state schema and access interface, not the storage implementation.

**Interface:**
- `State.read(category)` — returns current state for a category
- `State.read(category, filter)` — returns filtered state (e.g., active changes for a component)
- `State.write(category, data)` — writes/updates state for a category
- `State.append(category, entry)` — appends to a log-type category

**Implementation is project-specific:** files for simple systems, database for production.

### Logs (permanent records)

| Log | Contents | Writer | Consumers |
|-----|----------|--------|-----------|
| **Change Log** | Complete record of all changes: signal, investigation, classification, fix/spec changes, test results, approval decisions, deployment outcome | All workflow agents | Human audit, pattern analysis, Consistency Verifier |
| **Signal Log** | Every signal received by Dispatcher (raw) | Dispatcher | Debugging, trend analysis |

---

## Artefact Consumption

Per-agent mapping of which artefacts are read and how they're used. Key difference from System-Operator: several agents both read AND write artefacts.

### Dispatcher

| Artefact | How used |
|----------|----------|
| Component Map | Identify which component a signal relates to. Check for in-flight changes on the same component (via Change Registry). |
| Risk Profile | Initial risk assessment for routing decisions. Change risk heuristics inform certainty/depth estimation. |

### Investigation Agent

| Artefact | How used |
|----------|----------|
| Component Map | Blast radius analysis: what depends on the affected component? What data flows through it? |
| Traceability | Navigate from design intent to implementation: find code and test locations for spec sections. Primary navigation tool. |
| Contract Definitions | Component interfaces: what the affected component exposes, what depends on it, behavioural invariants. |
| Risk Profile | Component criticality for depth classification. Sensitive data areas that elevate risk. |
| Component Specs | Intended behaviour: what the code SHOULD do. Read relevant sections (via Traceability references) to understand design intent. |
| Source code | Actual implementation: what the code DOES. Accessed via Traceability paths, supplemented by Grep/Glob. |
| Operator diagnostic context | When investigating an Operator escalation: observations, actions tried, metrics. Embedded in the Escalation signal. |

### Patch Agent

| Artefact | How used |
|----------|----------|
| Component Specs | Source of truth for intended behaviour. Spec consistency check: does the proposed fix align with the spec? |
| Traceability | Find code and test locations for the affected area. |
| Risk Profile | Change risk heuristics for autonomy tier determination. |
| Contract Definitions | Verify fix doesn't break contracts with other components. |

### Extend Agent

| Artefact | How used |
|----------|----------|
| Component Specs | **Reads and writes.** Target for spec updates. Read fully for affected component(s). |
| Architecture | Boundary check: does the extension stay within architectural boundaries? |
| Foundations | Convention check: does the extension respect technology patterns? |
| Contract Definitions | Cross-component impact: does the extension affect interfaces consumed by others? **Updated** if interfaces change. |
| Traceability | Find existing code structure to build on. **Updated** after code is written. |
| Risk Profile | Change risk heuristics for autonomy tier at spec and code approval stages. |

### Evolve Agent

| Artefact | How used |
|----------|----------|
| Architecture | **Full read** for impact analysis. Identifies entry stage and cascade scope. May be the entry stage document. |
| Foundations | **Full read** for impact analysis. May be the entry stage document. |
| Component Map | Full dependency graph for cascade scope determination. |
| Contract Definitions | All affected components for cross-component impact. |
| Component Specs | All affected specs for cascade scope. |
| Risk Profile | Overall risk assessment for the evolution. |
| All operational artefacts | Via Artefact Sync Agent — determines what needs updating. |

### Consistency Verifier

| Artefact | How used |
|----------|----------|
| Component Map | List of all components to verify. |
| Traceability | Spec-to-code mappings to validate. Primary input for drift detection. |
| Component Specs | Intended behaviour to compare against code. |
| Contract Definitions | Interface contracts to verify in code. |

### Artefact Sync Agent

| Artefact | How used |
|----------|----------|
| All maintenance artefacts | **Reads and writes.** Reads current state, applies targeted updates based on the change, writes updated versions. |
| All operations artefacts | **Reads and writes.** Particularly monitoring definitions and runbooks for Extend/Evolve changes. |

### Escalation Agent

| Artefact | How used |
|----------|----------|
| Component Map | Include affected component context in escalation messages. |
| Risk Profile | Include component criticality in escalation urgency. |

---

## External System Integration

System-Maintainer's tool set is thinner than System-Operator's. Most interaction is with files (code, specs, design docs) using standard tools. The project-specific parts are narrower.

### Tool definitions

| Tool | Operations | Used by |
|------|-----------|---------|
| **Read** | Read file contents (code, specs, artefacts) | All agents |
| **Write** | Create or overwrite files (code, specs, artefacts) | Dispatcher, Investigation, Patch, Extend, Evolve, Artefact Sync, Consistency Verifier |
| **Edit** | Modify file sections (spec updates, code changes) | Patch, Extend, Evolve, Artefact Sync |
| **Grep** | Search code and doc contents | All agents |
| **Glob** | Find files by pattern | All agents |
| **Test** | `run_tests(scope)` — run test suite (all, component, file) | Patch, Extend, Evolve |
| | `run_tests(component, type)` — run specific test type (unit, integration, contract) | Patch, Extend, Evolve |
| **Notifier** | `send_notification(channel, severity, message)` — send to notification channel | Escalation |
| | `request_approval(channel, proposal, options)` — send approval request, await response | Escalation |
| **Signal** | `send_signal(target, signal)` — send structured signal to Operator | Escalation (Deployment Request, Watch Request, Artefact Update) |
| | `receive_signal()` — receive signal from Operator (Escalation, Deployment Feedback) | Dispatcher |
| **SystemBuilder** | `invoke_review(stage, context)` — spawn System-Builder review pipeline at a stage | Evolve |
| **Task** | `spawn_subagent(prompt, context)` — spawn a subagent for parallel or delegated work | All coordinators |

### Implementation notes

- **Read, Write, Edit, Grep, Glob** are standard tools. No project-specific binding needed.
- **Test** is project-specific. The implementation wraps the project's test runner (e.g., `pytest`, `npm test`). The agent specifies scope; the tool translates to the correct command.
- **Notifier** follows the same pattern as System-Operator. Project-specific bindings (Slack, PagerDuty, email).
- **Signal** is the transport for INTEGRATION.md signals. Implementation-specific (file-based, queue, direct invocation).
- **SystemBuilder** reads a System-Builder orchestrator prompt and spawns it as a subagent. The Evolve Agent uses this to invoke the review pipeline at a specific stage.
- Tools are **the only way agents interact with external systems**. Same constraint as Operator: all external interactions are auditable and restricted per-agent.

---

## Human Interaction Model

All outbound communication to humans flows through the Escalation Agent. Inbound communication from humans is received by the Dispatcher.

### Outbound formats

#### Post-hoc notification (Tier 1 auto-applied patches)

For auto-applied dependency patches, trivial fixes.

```
[PATCH APPLIED] [component] — [what changed] — [test results] — [deploying]
Change: [CR-xxx]. Signal: [signal summary].
```

#### Investigation report (Tier 3 — presenting options)

For low-certainty signals or ambiguous classifications.

```
[INVESTIGATION COMPLETE] [signal type] — [component]

Root cause: [analysis]
Affected components: [list with blast radius]
Proposed depth: [Patch / Extend / Evolve]
Confidence: [HIGH / MEDIUM / LOW]

Evidence:
- [spec reference]: [what spec says]
- [code location]: [what code does]
- [observation]: [metrics/logs/reproduction]

Options:
1. [option with implications]
2. [option with implications]

Recommended: [option N] because [reasoning]

→ Approve classification / Choose option / Redirect
```

#### Spec change approval request (Extend workflow)

```
[SPEC REVIEW] [component] — [change summary]

Proposed spec changes:
[diff or summary of additions/modifications]

Consistency check: [PASS / issues found]
Contract impact: [affected consumers or "none"]
Blast radius: [components affected]

→ Approve / Modify / Reclassify as Evolve
```

#### Code change approval request (Patch/Extend)

```
[CODE REVIEW] [component] — [change summary]

Code changes: [summary or diff]
Tests: [N new, M modified, all passing]
Spec consistency: [PASS — code matches spec]

→ Approve for deployment / Request changes
```

#### Evolve scope review

```
[EVOLVE SCOPE] [change description]

Impact analysis:
- Entry stage: [Foundations / Architecture / Components]
- Downstream cascade: [list of affected stages and documents]
- Components affected: [list]
- Existing functionality at risk: [description]
- Deployment considerations: [migrations, versioning]

→ Approve scope / Modify scope / Reject
```

#### Escalation to Operator

Uses the signal formats defined in `INTEGRATION.md` (Deployment Request, Watch Request, Artefact Update).

### Inbound handling

| Inbound signal | Source | Dispatcher action |
|---------------|--------|-------------------|
| Approval response | Human | Route to the workflow agent that requested it, matched by change ID |
| Reclassification ("this is actually an Evolve") | Human | Re-route to appropriate workflow agent |
| New signal (bug report, feature request) | Human | Classify and route per signal routing table |
| Priority override ("handle this first") | Human | Adjust queue priority for affected change |
| Escalation from Operator | Operator | Route to Investigation Agent with diagnostic context |
| Deployment Feedback | Operator | Route to workflow agent that sent the Deployment Request |

---

## Escalation Paths

### Investigation escalation

| Situation | Escalate to | Context included |
|-----------|-------------|------------------|
| Low confidence classification | Human (options presentation) | Analysis, options, evidence, recommendation |
| Evolve depth detected | Human (scope confirmation) | Impact analysis, cascade scope, risk |
| Cannot reproduce / insufficient evidence | Human (request more context) | What was tried, what's missing |
| Cross-system impact detected | Human (scope decision) | Which systems affected, coordination needs |

### Patch escalation

| Situation | Escalate to | Context included |
|-----------|-------------|------------------|
| Spec gap detected (fix would diverge from spec) | Human (reclassify to Extend?) | Spec reference, code reality, proposed options |
| Tests fail after fix | Human (review fix approach) | Test failures, proposed fix, alternatives |
| Deployment rolled back | Investigation Agent (new signal) | Operator's feedback, rollback details |

### Extend escalation

| Situation | Escalate to | Context included |
|-----------|-------------|------------------|
| Consistency check finds conflicts | Human (resolve conflicts) | Conflicts with architecture/foundations/contracts |
| Architecture boundary would be crossed | Human (reclassify to Evolve) | What boundary, why extension doesn't fit |
| Contract changes affect multiple consumers | Human (broader impact review) | Which consumers, what changes |
| Deployment rolled back | Investigation Agent (new signal) | Operator's feedback, rollback details |

### Evolve escalation

| Situation | Escalate to | Context included |
|-----------|-------------|------------------|
| System-Builder review raises blockers | Human (resolve within review pipeline) | Expert issues, proposed resolutions |
| Cascade scope larger than expected | Human (confirm expanded scope) | Revised impact analysis |
| Cross-component test failures | Human (integration issues) | Test results, component interactions |
| Deployment rolled back | Investigation Agent (new signal) | Operator's feedback, full cascade context |

---

## Autonomy Decision Model

How workflow agents determine the autonomy tier for a given change.

### Decision process

```
1. Start with change risk heuristics from Risk Profile:
   - What area of the system does this change touch?
   - Risk Profile provides default risk level and autonomy ceiling

2. Apply depth modifier:
   ├─ Patch → starting tier from Risk Profile heuristics (Tier 1–3)
   ├─ Extend → minimum Tier 2 (spec changes always need review)
   └─ Evolve → always Tier 4 (no automation for architectural changes)

3. Apply certainty modifier:
   ├─ HIGH certainty → no change
   ├─ MEDIUM certainty → escalate one tier
   └─ LOW certainty → escalate one tier + present options

4. Apply blast radius modifier:
   ├─ Single component, no consumers → no change
   ├─ Multiple components or has consumers → escalate one tier
   └─ Critical path component → escalate one tier

5. Apply risk domain modifier:
   ├─ Security/auth changes → Tier 4 (always)
   ├─ Data integrity changes → minimum Tier 3
   ├─ User-facing behaviour changes → minimum Tier 3
   └─ Internal-only, non-data → no additional override

6. Final tier = max(all modifiers applied)
```

### Key principle

**Tier can only be overridden upward (more cautious), never downward.** Same as System-Operator. A Risk Profile heuristic saying "Tier 1" for logging changes, combined with Patch depth and HIGH certainty, stays at Tier 1. But if blast radius shows the change affects a shared library used by 5 components, it escalates to Tier 2.

### Tier-to-action mapping

| Tier | Agent action | Human involvement | Applicable workflows |
|------|-------------|-------------------|---------------------|
| **1** (Auto-apply, notify) | Apply fix, run tests, deploy. Post-hoc notification. | None during action. Notification after. | Patch only |
| **2** (Propose, wait) | Produce complete proposal (fix + tests + impact). Wait for approval. | Must approve before agent acts. | Patch, Extend |
| **3** (Investigate, present options) | Produce analysis and multiple options. Wait for direction. | Must choose direction before agent proceeds. | Patch (if reclassified), Extend |
| **4** (Full human engagement) | Investigation, scope review, design review, code review, deployment approval — human at every checkpoint. | Involved throughout. | Evolve (always), plus any change touching security/data/user-facing |

---

## System-Builder Invocation Model

This section is unique to System-Maintainer. It defines how the Evolve workflow invokes System-Builder's review pipeline.

### Entry point determination

The Investigation Agent determines the entry stage based on the type of change:

| Change type | Entry stage | Example |
|-------------|-------------|---------|
| Technology/convention change | Stage 03 (Foundations) | Switch from REST to GraphQL, change auth strategy |
| Component boundary change | Stage 04 (Architecture) | Add a new component, change data flow between components |
| Component structural change | Stage 05 (Components) | Fundamentally restructure a component's internals, change its role |

### Invocation protocol

1. **The Evolve Agent prepares a change proposal document** containing:
   - Signal that triggered this evolution
   - Investigation output (root cause, affected components, blast radius)
   - Human-approved scope (entry stage, cascade boundaries)
   - The specific change being proposed

2. **The Evolve Agent spawns a subagent** with the System-Builder review orchestrator for the entry stage:
   ```
   Read the [Stage] review orchestrator at:
   [builder]/agents/[NN-stage]/review/orchestrator.md

   Review the [document] with this change context:
   - Change proposal: [path to change proposal document]
   ```

3. **The System-Builder review pipeline runs** with these modifications:
   - Expert agents receive the change proposal as additional context
   - Review is scoped to the proposed change and its implications (not full document re-review)
   - Human participates in the discussion loop as normal — this IS the Evolve workflow's design-level human engagement
   - The pipeline produces updated design documents

4. **On completion**, the Evolve Agent receives:
   - Updated design document at the entry stage
   - Any pending issues or deferred items generated during review

5. **Cascade**: for each downstream stage affected:
   - Substantial changes → invoke System-Builder review at that stage
   - Mechanical changes → Evolve Agent updates directly, runs lightweight consistency check

### Key design decisions

- **System-Builder is invoked as a subagent, not an external service.** Spawned via Task tool with the orchestrator prompt path. Keeps the interaction within the same agent framework.
- **The review pipeline is reused, not duplicated.** System-Builder's review workflow provides exactly the rigour needed for Evolve changes. Building a parallel review process would be redundant.
- **Human checkpoints within System-Builder serve as the Evolve workflow's design review.** The human isn't reviewing twice — the System-Builder pipeline IS the design review step.
- **Cascade depth is bounded by human confirmation.** Evolve Agent presents cascade scope for approval before proceeding through each downstream stage.

---

## Design Doc Sync Model

This section defines how design documents stay in sync with code across all workflows.

### Sync rules by workflow

| Workflow | Spec change? | Sync mechanism | Artefact updates |
|----------|-------------|----------------|-----------------|
| Patch | No (annotation at most) | Code fixed to match spec. Traceability updated if code locations change. | Traceability |
| Extend | Yes (before code) | Spec updated first (human-approved), then code written to match. Contracts updated. | Traceability, Contract Definitions, affected operational artefacts |
| Evolve | Yes (through System-Builder) | Full review pipeline updates specs at entry stage + cascade. Code follows. | All affected artefacts (potentially all 9) |

### Artefact Sync Agent protocol

The Artefact Sync Agent is spawned by workflow agents at the deploy step:

1. **Determines which artefacts need updating** based on the change:
   - Patch: always Traceability; rarely anything else
   - Extend: Traceability + Contract Definitions + affected operational artefacts (monitoring if new endpoints, runbooks if new failure modes, etc.)
   - Evolve: all affected artefacts (potentially all 9 from ARTEFACT-SPEC.md)

2. **Reads current artefact state** and applies targeted updates (not full regeneration). Reads ARTEFACT-SPEC.md for format specifications to ensure consistency.

3. **Writes updated artefacts** to the standard locations (`maintenance/`, `operations/`).

4. **Sends Artefact Update signal to Operator** (via Escalation Agent) for any operational artefacts that changed.

### Design doc rollback policy

When a deployed change fails and Operator rolls back code:

- **Design docs are NOT rolled back.** The spec represents what we intended. If the code failed to achieve the intention, that's a new Patch signal (fix the code to match the spec).
- **If the design itself was wrong** (spec change led to an unworkable design), that's a new signal — likely Extend (revise spec) or Evolve (if architectural).
- **Operational artefacts** updated for the failed change are left in place — they describe the intended end state. The Patch that fixes the code deploys against the same artefacts.
- **Traceability** may need a minor update to reflect the rollback (code at previous version, spec describes intended version).

This is a deliberate design choice: design docs track intention, not current deployment state. Code tracks current deployment state. Traceability bridges the two.

---

## Instantiation

What a project provides to use the System-Maintainer framework.

### Required configuration

| Configuration | Purpose | Example |
|--------------|---------|---------|
| **Design doc paths** | Where System-Builder's outputs live | `system-design/` root with stage subdirectories |
| **Artefact paths** | Where Stage 12 outputs live | `maintenance/`, `operations/` |
| **Source code paths** | Where the codebase lives | `src/`, `tests/` |
| **System-Builder agent paths** | Where System-Builder orchestrators and agents live | `/path/to/system-generator/builder/agents/` |
| **Test tool implementation** | How to run tests | `pytest` wrapper, `npm test` wrapper |
| **State store** | Where change state is read/written | File path, database connection |
| **Notification channels** | How to reach humans | Slack channel, email, etc. |
| **Operator signal endpoint** | How to send signals to System-Operator | File drop, queue, direct invocation |

### Optional configuration

| Configuration | Purpose | Default |
|--------------|---------|---------|
| **Consistency check schedule** | How often the Consistency Verifier runs | Weekly |
| **Tier 1 auto-apply criteria** | What qualifies for auto-apply | Dependency security patches + passing tests + no cross-component impact |
| **Investigation timeout** | Max time for Investigation Agent before escalating | 30 minutes |
| **Deployment hold period** | Forwarded to Operator in Deployment Request | 15 min (standard), 1 hour (Evolve) |
| **Concurrent change policy** | How to handle overlapping component changes | Queue conflicting, allow independent |

### Instantiation checklist

1. Design documents exist (System-Builder completed at least through Stage 05)
2. Operational artefacts exist (Stage 12 has run, `maintenance/` and `operations/` populated)
3. Source code exists (Stage 08 has built code, or code exists from other means)
4. System-Builder agent prompts accessible (for Evolve workflow)
5. Test tool implementation provided and working
6. State store accessible and writable
7. Notification channels tested (can reach humans)
8. Operator signal endpoint configured (if System-Operator is deployed)
9. Consistency Verifier schedule configured

---

## Resolved Design Decisions

These were open questions in OVERVIEW.md.

### Concurrent change handling (OVERVIEW #1)

Component-level awareness with pessimistic locking for overlapping scopes. The Dispatcher tracks active changes per component in the Change Registry. Conflicting changes are queued; independent component changes run in parallel. Evolve blocks all Patch/Extend on the same component. See § Coordination Model.

### Design doc rollback (OVERVIEW #2)

Design docs are never rolled back. A failed deployment creates a new Patch signal to fix the code. If the design was wrong, that's a new Extend or Evolve signal. See § Design Doc Sync Model.

### Versioning (OVERVIEW #3)

Design docs use inline version numbers (matching System-Builder's existing pattern). Code uses git commits. Change Records link a specific design doc version to a specific git commit range. Traceability maps between them.

### Testing strategy (OVERVIEW #4)

Framework assumes System-Builder's generated tests as baseline. Workflow agents add tests for each specific change: Patch adds regression tests, Extend adds feature + contract tests, Evolve adds integration + contract tests. No separate "maintenance-specific" test generation beyond what each change requires.

### Multi-system (OVERVIEW #5)

One Maintainer per system. Same approach as System-Operator. Independent artefacts, state, and tools per system.

### Learning (OVERVIEW #6)

Deferred. The Change Log provides raw material for pattern detection (historical signals, classifications, resolutions). Building an active learning agent is a future enhancement.

---

## Open Questions

1. **System-Builder "targeted review" mode** — the Evolve workflow needs scoped review, not full document re-review. May need minor modification to System-Builder expert prompts (accepting change proposal context) or may work as-is if the change proposal document is provided as additional context. **[REFINE DURING IMPLEMENTATION]**

2. **Cascade automation level** — the boundary between "lightweight cascade" (Evolve Agent applies directly) and "full cascade" (invoke System-Builder review pipeline) needs clearer criteria. Current proposal: if cascade changes affect more than 2 sections of a downstream document, use full review. **[REFINE DURING IMPLEMENTATION]**

3. **Investigation Agent context management** — complex bugs may require reading large amounts of code and multiple design documents. Context window management is critical. Current design uses Traceability for targeted navigation, but complex investigations may need multi-step with intermediate state rather than single-pass. **[REFINE DURING IMPLEMENTATION]**
