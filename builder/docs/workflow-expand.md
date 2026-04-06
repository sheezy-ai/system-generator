# Expand Workflow

The Expand workflow adds new capability areas or scope changes to an existing, promoted document. Unlike Create (which generates from scratch) or Review (which critiques and refines existing content), Expand adds new content driven by a specific trigger — a downstream discovery, a scope decision, or a human-identified gap.

For a high-level overview, see `overview.md`.

---

## When to Use Expand

**Use Expand when:**
- A downstream stage discovers the document needs new capabilities (e.g., architecture review reveals the PRD needs a new component)
- A scope decision adds something that wasn't in the original document
- You identify an area that's underdeveloped and needs structured exploration

**Use Review instead when:**
- You want experts to check the document for issues in existing content
- A downstream stage needs to catch up after an upstream expansion (review experts naturally surface misalignment)
- The document needs corrections or refinements, not new capability areas

**Key principle**: Expand never promotes. Always follow an expand round with a review round before promotion.

---

## Flow Diagram

```
                    ┌─────────────────┐
                    │    Trigger      │
                    │ (pending issue, │
                    │  description,   │
                    │  conversation)  │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  Scope Analyst  │◄──── Step 1
                    │ (Expansion Brief│      HUMAN CHECKPOINT
                    │  with cap areas)│      (review/adjust brief)
                    └────────┬────────┘
                             │
                ┌────────────┼────────────┐
                ▼            ▼            ▼
          ┌──────────┐ ┌──────────┐ ┌──────────┐
          │ Explorer │ │ Explorer │ │ Explorer │◄──── Step 2
          │  CAP-1   │ │  CAP-2   │ │  CAP-N   │     (parallel)
          └────┬─────┘ └────┬─────┘ └────┬─────┘
               │            │            │
               └────────────┼────────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │   Consolidator  │◄──── (if 2+ capability areas)
                   └────────┬────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │ Proposal Filter │◄──── Step 3
                   └────────┬────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │  Human Review   │◄──── Step 4
                   │  (accept/reject │      HUMAN CHECKPOINT
                   │   per proposal) │      (discussion loop)
                   └────────┬────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │   Integration   │◄──── Step 5
                   │     Author      │
                   └────────┬────────┘
                            │
               ┌────────────┼────────────┬────────────┐
               ▼            ▼            ▼            ▼
         ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
         │  Change  │ │Alignment │ │Coherence │ │Enumerate │◄── Steps 6-9
         │ Verifier │ │ Verifier │ │ Checker  │ │ Verifier │    (parallel)
         └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘
              │            │            │            │
              └────────────┼────────────┼────────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │  Verification   │◄──── Step 10
                  │    Review       │      HUMAN CHECKPOINT
                  └────────┬────────┘      (if NEEDS_DECISIONS)
                           │
                           ▼
                  ┌─────────────────┐
                  │     Route       │◄──── Step 11
                  │  (done — run    │
                  │  Review next)   │
                  └─────────────────┘
```

---

## Phases

### Phase 1: Scope (Step 1)

The trigger is turned into a structured Expansion Brief.

**Input**: A trigger — pending issue file, human-written description, or conversation summary.

**Agent**: **Scope Analyst** reads the trigger, current document, upstream documents, and stage guide. Produces:
- **Expansion thesis**: What's being added and why
- **Capability areas**: 1–4 focused investigation areas (like Create's capability/concern identification)
- **Affected sections**: Which document sections need new or modified content
- **Current state**: What the document already says about this area
- **Scope boundaries**: What's in/out of scope for this expansion
- **Key questions**: What explorers should investigate

**Human checkpoint**: Review and adjust the brief before exploration begins. The human owns the scope boundaries.

### Phase 2: Explore (Steps 2–3)

Each capability area is investigated in parallel.

**Agents**: One **Expansion Explorer** per capability area. Unlike Create explorers (which generate content from scratch), Expand explorers work with an existing document. Each produces an **Expansion Proposal** with:
- **New content**: Proposed additions with target section
- **Modified content**: Existing content that needs changing, with current text and replacement
- **Cross-section implications**: Changes in other sections triggered by the primary change
- **Rationale**: Why each change is needed

If multiple capability areas produce proposals, the **Exploration Consolidator** (universal agent) merges them.

The **Proposal Filter** then checks level-appropriateness against the stage guide and formats proposals for human review. Unlike the Scope Filter (which strips content to summaries for review issues), the Proposal Filter preserves full proposal content — rationale, trade-offs, proposed text, and cross-section implications. The human needs this detail to make informed accept/reject decisions.

### Phase 3: Integrate (Steps 4–5)

Approved proposals are applied to the document.

**Human checkpoint** (Step 4): Review each proposal. Accept, reject, or discuss. Discussion uses the same `>> HUMAN:` / `>> AGENT:` / `>> RESOLVED` protocol as Review.

**Agent** (Step 5): **Integration Author** applies all accepted proposals. The key quality requirement is **no seams** — the document should read as if the expanded capability was always in scope. This may require restructuring paragraphs, reordering lists, or adjusting framing beyond simple insertion.

### Phase 4: Verify (Steps 6–11)

Same verification pipeline as Review:
- **Change Verifier**: Were all accepted proposals applied correctly?
- **Alignment Verifier**: Does the document still align with upstream? (Skipped for Blueprint)
- **Internal Coherence Checker**: Do all sections agree after the expansion?
- **Enumeration Verifier**: Are enumeration sections complete for the new content?

If verification finds issues, the same FIX/ACCEPT/rework loop as Review applies.

---

## Agents

### Stage-Specific Agents (per stage)

| Agent | Role | Input | Output |
|-------|------|-------|--------|
| Scope Analyst | Produces Expansion Brief from trigger | Trigger, document, upstream docs, guide | `01-expansion-brief.md` |
| Expansion Explorer | Investigates one capability area | Brief, document, upstream docs, guide | `02-explorer-{cap-name}.md` |
| Proposal Filter | Filters by level, formats for review | Consolidated proposals, guide | `03-expansion-review.md` |
| Integration Author | Applies approved changes seamlessly | Document, approved proposals, guide | `04-integration-output.md`, `05-updated-*.md` |

### Universal Agents (reused from other workflows)

| Agent | Role |
|-------|------|
| Exploration Consolidator | Merges proposals across multiple explorers |
| Discussion Facilitator | Facilitates human-agent discussions on proposals |
| Alignment Verifier | Checks alignment with upstream documents |
| Internal Coherence Checker | Checks cross-section consistency |
| Enumeration Verifier | Checks enumeration completeness |
| Change Verifier | Checks approved changes were applied (uses Review's change-verifier) |

---

## Output Files

```
versions/round-[N]-expand/
├── 00-[document].md               # Snapshot of input (copied at round start)
├── 00-trigger.md                  # Trigger input
├── 01-expansion-brief.md          # Scope Analyst output
├── 02-explorer-{cap-name}.md      # One per capability area
├── 03-consolidated-proposals.md   # Merged proposals (raw, no discussion markers)
├── 03-expansion-review.md         # Filtered proposals with >> HUMAN: markers
├── 04-integration-output.md       # Change log
├── 05-updated-[document].md       # Updated document with expansion applied
├── 06-change-verification.md
├── 07-alignment-report.md
├── 08-coherence-report.md
├── 09-enumeration-report.md
└── 10-verification-summary.md
```

---

## Human Checkpoints

| Step | What | Human Action |
|------|------|-------------|
| Step 1 | Expansion Brief | Review scope, capability areas, boundaries. Approve, adjust, or cancel. |
| Step 4 | Proposals | Accept/reject each proposal. Discuss with facilitator if needed. |
| Step 10 | Verification (if NEEDS_DECISIONS) | FIX or ACCEPT per item. |

---

## Differences from Create and Review

| Aspect | Create | Review | Expand |
|--------|--------|--------|--------|
| **Purpose** | Generate from scratch | Critique and refine | Add new capability areas |
| **Input** | Upstream documents | Existing document | Existing document + trigger |
| **Exploration** | Yes — from blank page | No | Yes — from existing document |
| **Expert review** | No | Yes (parallel experts) | No |
| **Proposals** | Enrichments (new content) | Issues (problems with existing) | Change sets (new + modified) |
| **Integration** | Generator or Applicator | Author (surgical fixes) | Integration Author (seamless) |
| **Promotes** | Yes | Yes | No — always follow with Review |
| **Available stages** | All (01–05) | All (01–05) | 01–04 |

---

## Stage-Specific Notes

### Blueprint (01)
- No upstream documents — Scope Analyst and Explorers work from the document and stage guide only
- No alignment verification — only change, coherence, and enumeration checks (3 parallel, not 4)
- No pending issue sync (no upstream to sync to)

### PRD (02)
- Upstream: Blueprint
- Full verification (4 parallel agents)
- Pending issue sync to Blueprint if alignment issues found

### Foundations (03)
- Upstream: Blueprint
- Full verification
- Pending issue sync to Blueprint

### Architecture (04)
- Two upstream documents: PRD and Foundations
- Full verification against both
- Pending issue sync to both PRD and Foundations
