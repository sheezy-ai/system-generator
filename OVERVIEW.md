# System-Generator

A framework that takes a product concept and produces a self-sustaining software system — not just code, but the operational and maintenance infrastructure to run and evolve it autonomously, with human oversight.

The output is a system that operates and maintains itself. Humans provide direction and approve decisions; agents do the research, analysis, and execution.

---

## The Three Frameworks

System-Generator comprises three subsystems, each responsible for a phase of the software lifecycle.

### Builder

Creates the system. A 12-stage pipeline that transforms a product concept into working software with full operational readiness.

| Stages | What they produce | Abstraction level |
|--------|------------------|-------------------|
| 01-05 | Design documentation | Strategic → structural → implementation-ready |
| 06-08 | Tasks, conventions, code | Specification → implementation |
| 09-12 | Verified code, infrastructure, deliverable, operational artefacts | Execution → operationalisation |

Each stage enforces scope — content at the wrong abstraction level flows downstream via deferred items, not by leaking into the current document. Human judgment drives progression between stages.

Builder is mostly one-shot, but its review pipeline is re-invoked by Maintainer's Evolve workflow when architectural changes require design-level review.

→ Full detail: `builder/README.md`, `builder/docs/overview.md`

### Operator

Runs the system. Monitors health, responds to incidents, manages deployments, handles routine operations (certificate rotation, scaling, backups), and tracks capacity.

Operator's intelligence lives in artefacts — SLOs, runbooks, monitoring definitions, deployment topology — not in runtime reasoning. Agents consult these artefacts to decide how to respond. When an artefact doesn't cover a situation, the agent escalates rather than guesses.

Graduated autonomy: auto-resolve routine issues → human-assisted for novel situations → escalate to Maintainer for code/design problems → escalate to human for anything beyond framework scope.

→ Full detail: `operator/OVERVIEW.md`, `operator/ARCHITECTURE.md`

### Maintainer

Evolves the system. Investigates issues, patches bugs, extends features, and manages architectural changes.

Changes are classified by depth:
- **Patch** — code-only fix within existing design
- **Extend** — new capability within existing architecture (spec update + code)
- **Evolve** — architectural change (invokes Builder's review pipeline)
- **Pivot** — full rebuild (run Builder again from the start)

Maintainer both reads and writes artefacts — it updates specs, contracts, and operational documents as the system changes, then signals Operator to pick up the updates.

Graduated autonomy across 4 tiers, determined by: change depth × certainty × blast radius × risk domain. Autonomy can only be overridden upward (more cautious), never downward.

→ Full detail: `maintainer/OVERVIEW.md`, `maintainer/ARCHITECTURE.md`

---

## The Lifecycle

### Creation

```
Concept
  → Builder Stage 01-05: Design documentation (Blueprint → PRD → Foundations → Architecture → Component Specs)
  → Builder Stage 06-08: Tasks → Conventions → Code
  → Builder Stage 09-12: Verify → Provision infrastructure → Package → Extract operational artefacts
  → Output: Code + Design Docs + 9 Operational Artefacts
```

### Instantiation

With Builder's outputs in place:
1. Configure Operator (tool implementations, notification channels, monitoring endpoints)
2. Configure Maintainer (test runner, state store, Builder agent paths for Evolve)
3. Both frameworks consume the artefacts Builder generated and begin operating

### Steady State

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│   Operator monitors → detects issue                 │
│       ↓                                             │
│   Operational? → Operator resolves                  │
│       or                                            │
│   Code/design? → Escalates to Maintainer            │
│       ↓                                             │
│   Maintainer investigates → classifies → fixes      │
│       ↓                                             │
│   Maintainer signals Operator to deploy             │
│       ↓                                             │
│   Operator deploys → monitors → ───────────→ loop   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

Other signal sources feed into the same loop: bug reports, feature requests, dependency vulnerabilities, spec drift detection, and scheduled maintenance all enter as signals to Maintainer.

For Evolve-depth changes, Maintainer re-enters Builder's review pipeline — the lifecycle loops back to creation at the affected design stage, cascades the changes down, then returns to steady state.

---

## The Artefact Layer

Nine operational artefacts bridge the three frameworks. They are the connective tissue — structured documents that agents consume directly, without interpreting prose from design documents.

| Artefact | Generated by | Written by (ongoing) | Read by |
|----------|-------------|---------------------|---------|
| Component Map | Builder Stage 12 | Maintainer | Both |
| Contract Definitions | Builder Stage 12 | Maintainer | Maintainer |
| Risk Profile | Builder Stage 12 | Maintainer | Both |
| Spec-to-Code Traceability | Builder Stage 12 | Maintainer | Maintainer |
| SLO Definitions | Builder Stage 12 | Maintainer | Operator |
| Monitoring Definitions | Builder Stage 12 | Maintainer | Operator |
| Deployment Topology | Builder Stage 12 | Maintainer | Operator |
| Runbooks | Builder Stage 12 | Maintainer | Operator |
| Security Posture | Builder Stage 12 | Maintainer | Operator |

**Initial generation**: Builder's Stage 12 extracts these from design docs and code. Five parallel extractor agents read different source documents and produce artefacts in structured formats. A cross-reference checker validates consistency across all nine.

**Ongoing maintenance**: Maintainer updates artefacts as the system evolves. After every change (Patch, Extend, or Evolve), the Artefact Sync Agent determines what needs updating, applies targeted changes, and sends Artefact Update signals to Operator.

**Operator never writes these artefacts.** If Operator identifies a gap (e.g., a runbook missing a scenario it encountered), it escalates to Maintainer, which authors the update.

**Operator produces its own outputs** — Incident Log, Deployment Log, SLO Reports, Cost Reports, and Capacity Forecasts. These are Operator-owned and available to Maintainer on demand (e.g., investigation context, deployment correlation).

→ Format definitions: `ARTEFACT-SPEC.md`

---

## Signal Flow

### Between Frameworks

| Direction | Signal | When |
|-----------|--------|------|
| Maintainer → Operator | Deployment Request | Tested change ready to deploy |
| Maintainer → Operator | Watch Request | Post-change monitoring needed |
| Maintainer → Operator | Artefact Update | Operational artefacts updated |
| Operator → Maintainer | Escalation | Problem requires code/design change |
| Operator → Maintainer | Deployment Feedback | Deployment succeeded, failed, or rolled back |

Every signal carries full context — the receiver should be able to act without going back to ask. Signals are structured documents with defined formats, not free text.

### To and From Humans

Both frameworks escalate to humans when:
- Autonomy tier requires approval
- Confidence is low
- The situation exceeds framework scope

Humans provide:
- Direction (approve, reject, redirect)
- Classification overrides (e.g., "this is actually an Evolve, not a Patch")
- Domain knowledge the agents lack

→ Signal formats and protocols: `INTEGRATION.md`

---

## Shared Design Principles

These principles apply across all three frameworks.

**Human as principal.** Agents research, propose, and execute. Humans decide and approve. The framework does the work; the human steers.

**Graduated autonomy.** Routine actions auto-resolve. Novel or risky actions escalate for human approval. The autonomy tier can only be overridden upward (more cautious), never downward. Trust is earned through demonstrated reliability.

**Artefact-driven intelligence.** Agents consult structured artefacts rather than re-deriving knowledge from raw sources. SLOs tell Operator what "healthy" means. Risk profiles tell Maintainer how cautious to be. Runbooks tell Operator what to do. The intelligence lives in the documents.

**Structured signals.** Communication between frameworks uses defined formats. Context travels with the signal. The receiver never needs to go back and ask "what did you mean?"

**Design docs as source of truth.** When code and specs diverge, the spec is authoritative. Either the code is wrong (Patch to fix it) or the spec is incomplete (Extend to update it). Design docs are never rolled back — a failed deployment creates a new signal.

**Escalation over assumption.** When uncertain, escalate to a human rather than guess. The cost of pausing is low; the cost of a wrong autonomous decision can be high.

---

## Versioning and Compatibility

The three frameworks are versioned as a unit. Two documents form the compatibility contract:

**ARTEFACT-SPEC.md** — defines artefact formats. If these change, existing project artefacts need migration. Both Operator and Maintainer depend on these formats.

**INTEGRATION.md signal formats** — defines inter-framework communication. If these change, Operator and Maintainer must upgrade together.

Breaking change to either contract = major version. New capabilities with unchanged formats = minor version.

**Upgrade policy**: Complete active workflows before upgrading. No hot-swapping of agent prompts mid-workflow. A project pins to a specific version of System-Generator; upgrades are deliberate.

---

## Project Structure

```
system-generator/
  OVERVIEW.md                 ← this document
  ARTEFACT-SPEC.md            ← shared artefact format definitions
  INTEGRATION.md              ← Operator ↔ Maintainer signal contract
  builder/                    ← System-Builder (creates systems)
    README.md                    quick start and stage overview
    agent-sources/               source templates for agent prompts
    agents/                      built agent prompts
    docs/                        framework documentation
    guides/                      stage guides (abstraction levels)
  operator/
    OVERVIEW.md                  concept and workflows
    ARCHITECTURE.md              agent design and coordination
  maintainer/
    OVERVIEW.md                  concept and workflows
    ARCHITECTURE.md              agent design and coordination
```

---

## Reading Order

For someone new to the project:

1. **This document** — the big picture: what System-Generator is, how the lifecycle works
2. **ARTEFACT-SPEC.md** — the artefact layer that connects all three frameworks
3. **Builder**: `builder/README.md` → `builder/docs/overview.md` — how systems are created
4. **Operator**: `operator/OVERVIEW.md` — how systems are run
5. **Maintainer**: `maintainer/OVERVIEW.md` — how systems are evolved
6. **INTEGRATION.md** — how Operator and Maintainer communicate
7. **ARCHITECTURE.md** files — agent design, for implementation (Operator and Maintainer)
8. **Builder docs/** — framework internals, for modifying the build pipeline
