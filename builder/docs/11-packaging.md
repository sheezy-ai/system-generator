# Packaging Stage

Packaging distils the design documents into developer-facing documentation and verifies the project is a complete, self-contained deliverable. After packaging, the project is self-sustaining — no dependency on the system-builder or knowledge of the design pipeline that created it. The Operations Readiness stage (12) follows, extracting maintenance and operations artefacts.

---

## Purpose

| Aspect | Description |
|--------|-------------|
| **Input** | Design documents (stages 01-05), build conventions, provisioning runbook |
| **Output** | Developer-facing documentation in the project source tree |
| **Abstraction Level** | Developer handoff: README, guides, API reference |
| **Key Question** | "Can someone clone this repo and understand how to use it?" |

---

## What Belongs Here

- Developer-facing README
- Architecture overview (distilled for developers)
- API reference
- Deployment guide
- Getting-started guide
- Package verification reports

---

## What Does NOT Belong Here

- Design documents (stages 01-05 — those are process artifacts)
- Code generation (Stage 08)
- Infrastructure provisioning (Stage 10)
- Test execution (Stage 09)

---

## Pre-condition

The verification stage (09) and provisioning stage (10) must have completed.

---

## Workflow

Linear flow: generate documentation, human reviews, verify package completeness.

```
Generate → Review → Verify → Complete
```

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    DOCUMENTATION GENERATION                              │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌────────────────────────┐                                              │
│  │ Documentation Generator │──▶  README.md, docs/*.md                    │
│  └────────────────────────┘                                              │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                    HUMAN REVIEW                                          │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Human reviews generated docs, makes edits, confirms ready               │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                    PACKAGE VERIFICATION                                  │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────┐    ┌──────────────┐                                │
│  │ Package Verifier  │───▶│    Route     │                                │
│  │ (completeness)   │    │  PASS/ISSUES │                                │
│  └──────────────────┘    └──────┬───────┘                                │
│                                 │                                        │
│  PASS ──▶ COMPLETE              │                                        │
│  ISSUES ──▶ Human fixes ──▶ Re-verify (max 3 rounds)                    │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Orchestration Model

Single coordinator with two subagents. Human review checkpoint between generation and verification.

- **Coordinator** (`coordinator.md`): Spawns generator, presents docs for review, spawns verifier, routes on results. Simplest coordinator in the pipeline.

- **Documentation Generator** (`documentation-generator.md`): One-shot agent. Reads design documents selectively (Grep + targeted Read), produces five documentation files in the project source tree. Read-only — no Bash, no execution.

- **Package Verifier** (`package-verifier.md`): Validates completeness — file references exist, commands match conventions, all components documented, no dangling `system-design/` references. Read-only on code, writes only the report.

---

## Generated Documentation

| File | Content | Primary Sources |
|------|---------|-----------------|
| `README.md` | Project overview, quick start, structure | Blueprint, PRD, Architecture, conventions |
| `docs/architecture.md` | Components, data flows, tech stack | Architecture, Foundations |
| `docs/api.md` | Endpoint reference, schemas | Component specs |
| `docs/deployment.md` | Infrastructure, provisioning, deployment | Runbook, conventions, Foundations |
| `docs/getting-started.md` | Dev setup, workflow, conventions | Conventions, Foundations |

---

## File Paths

**Stage documentation:** `docs/11-packaging.md`

**Agent prompts:**
```
agents/11-packaging/
├── coordinator.md               # Orchestrates generation and verification
├── documentation-generator.md   # Produces developer-facing docs
└── package-verifier.md          # Validates package completeness
```

**Output locations:**
```
[project source tree]/
├── README.md
└── docs/
    ├── architecture.md
    ├── api.md
    ├── deployment.md
    └── getting-started.md

system-design/11-packaging/
└── versions/
    ├── workflow-state.md
    └── round-N/
        └── 01-verification-report.md
```

---

## Invocation

**Run packaging:**
```
Read the Packaging coordinator at:
agents/11-packaging/coordinator.md

Package.
```

The coordinator generates developer documentation, presents it for human review, then verifies package completeness.

---

## State Management

Track state in `versions/workflow-state.md`:

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

## Key Principles

- **Developer audience**: Documentation is for someone cloning the repo, not someone who built it. No references to the design pipeline.
- **Distilled, not copied**: Design documents are distilled into developer-appropriate views. Don't reproduce verbatim.
- **Self-sustaining deliverable**: After packaging, the project stands alone. The Operations Readiness stage (12) then extracts artefacts for System-Maintainer and System-Operator.
- **Human review**: Generated docs are presented for human review before verification — the human knows their audience best.
- **Completeness check**: Every file reference in docs must exist, every command must match conventions, every component must be documented.
