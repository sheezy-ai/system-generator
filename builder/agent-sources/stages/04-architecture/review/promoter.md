# Architecture Promoter Agent

## Purpose

Transform a reviewed Architecture Overview into three focused documents:
1. **Architecture Overview** — Clean current-scope system decomposition, data flows, and contracts
2. **Future Planning Doc** — Deferred items, future considerations, and open questions
3. **Decisions Doc** — Design rationale, trade-offs, and deliberate choices

---

## Input

| Input | Path | Purpose |
|-------|------|---------|
| Reviewed Architecture Overview | Provided at invocation | Source document to split |
| Guide | `guides/04-architecture-guide.md` | Validation reference |

---

## Output

- Architecture Overview: `system-design/04-architecture/architecture.md`
- Future planning: `system-design/04-architecture/future.md`
- Decisions: `system-design/04-architecture/decisions.md`

---

## Separation Criteria

### Stays in Architecture Overview

| Content Type | Example | Rationale |
|--------------|---------|-----------|
| All 9 guide sections with current-scope content | System Context, Component Decomposition, etc. | Core architecture guidance |
| Component Spec List (§6) | Full list with scope and dependencies | Drives next stage — always kept |
| Data Contracts (§8) | Full contract table with producers/consumers | Implementation guidance, not rationale |
| Brief decision statements in §5 | "Single PostgreSQL instance for all components" | The "what" stays; detailed "why" moves |
| Brief accepted limitation notes | "Accepted limitation: X. See decisions.md for rationale." | Implementer needs to know constraint exists |
| One-liner future flags | "Future consideration: Add X if Y exceeds threshold" | Signals intent without detail |
| Cross-Cutting Concerns (§7) | Auth, logging, error handling patterns | Implementation guidance |

### Moves to Future Planning

| Content Type | Example | Rationale |
|--------------|---------|-----------|
| §9 Open Questions | Unresolved questions with context and impact | Items needing future resolution |
| Multi-paragraph future blocks | "In Phase 1b, when traffic increases..." | Forward-looking, not needed now |
| Future component descriptions | "A future Notification Service would..." | Not part of current architecture |
| Migration criteria | "Migrate to microservices when any of: A, B, C" | Planning concern |
| Scaling considerations for future phases | "When request volume exceeds X, consider..." | Planning concern |
| Deferred architectural decisions | Items explicitly marked as deferred or future scope | Not actionable now |

### Moves to Decisions

| Content Type | Example | Rationale |
|--------------|---------|-----------|
| `<!-- Rationale: ... -->` HTML comments | `<!-- Rationale: ARCH-003 - Split into Ingestion and Store... -->` | Design rationale |
| Design Decisions section (`DD-NNN:` blocks) | `DD-001: Event Service Decomposition` with Decision/Rationale/Alternatives | Formal decision records |
| Detailed rationale in §5 Key Technical Decisions | Multi-sentence explanations of why a decision was made | Decision context (brief statement stays in architecture) |
| `Source: Round N: ISSUE-ID` references | `Source: Round 1: ARCH-003` | Traceability (moves with its decision) |
| Trade-off analyses | "We chose X over Y because..." | Decision context |
| "Alternatives considered/rejected" blocks | "Alternatives: 1. Option A — rejected because..." | Alternative analysis |
| Full rationale for accepted limitations | Multi-paragraph explanation of why a limitation is acceptable | Detailed reasoning |
| Decomposition justifications | "We split X into Y and Z because..." (detailed form) | Architectural rationale |

### Judgment Calls

When uncertain which document content belongs in:

**Architecture vs Future:**
- If implementer would be confused without it → Keep in architecture
- If it's guidance for a future architect → Move to future
- If it's a single sentence flag → Keep in architecture as brief note
- If it's a multi-paragraph future explanation → Move to future

**Architecture vs Decisions:**
- If it's "what" → Architecture
- If it's "why" → Decisions
- If implementer needs the constraint → Brief note in architecture + full rationale in decisions
- If it's trade-off analysis → Decisions

**§5 Key Technical Decisions — special handling:**
- Keep the decision statement (one sentence) in architecture.md
- Move detailed rationale, alternatives considered, and trade-off analysis to decisions.md
- Add brief note: "See decisions.md for full rationale."

---

## Architecture Overview Structure

Preserve the original 9-section structure. Within each section:
1. Remove extracted content cleanly (no orphaned references)
2. Keep prose flowing naturally
3. Preserve all current-scope component definitions, data flows, and contracts
4. Remove HTML rationale comments (they move to decisions.md)
5. Simplify §5 Key Technical Decisions to brief statements with decisions.md references
6. Replace full Design Decisions section (if present) with brief notes referencing decisions.md
7. Keep §9 Open Questions as a section header with a reference to future.md

---

## Future Planning Document Structure

```markdown
# Architecture Future Planning

**Source Version**: [version from original]
**Extracted From**: [date]

## Overview

Deferred decisions, future considerations, and open questions from the Architecture Overview.

---

## Open Questions

| Question | Context | Impact |
|----------|---------|--------|
| [From §9] | [context] | [impact] |

---

## Future Components

### [Component Name]

**Purpose**: [What it would do]

**Trigger**: [When to add it]

**Integration**: [How it would fit with existing components]

---

## Deferred Decisions

Items explicitly marked as deferred, not yet triggered.

| Decision | Current Approach | Trigger | Architecture Section |
|----------|------------------|---------|----------------------|
| [Decision] | [What we do now] | [When to revisit] | [Section ref] |

---

## Scaling Considerations

### [Theme: e.g., "Database Scaling"]

**Current State**: [Current approach]

**Migration Triggers**:
- [Trigger 1]
- [Trigger 2]

**Future Approach**:
[Extracted content describing future architecture]

---

## References

- Architecture Overview: `architecture.md`
- Decisions: `decisions.md`
```

---

## Decisions Document Structure

```markdown
# Architecture Design Decisions

**Source Version**: [version from original]
**Extracted From**: [date]

## Overview

This document captures design rationale, trade-offs, and deliberate architectural choices. Refer here to understand why the architecture is designed the way it is.

---

## Architectural Decisions

### DD-001: [Choice Title] (ARCH-ID)

**Decision**: [What was decided]

**Context**: [Why this decision was needed]

**Options Considered**:
1. [Option A] — [Pros/cons]
2. [Option B] — [Pros/cons]

**Rationale**: [Why this option was chosen]

**Consequences**: [What this means for the system]

**Source**: Round N: ARCH-ID

---

### DD-002: [Choice Title] (ARCH-ID)

[Same structure]

---

## Component Decomposition Rationale

### [Decomposition Decision]

**Decision**: [How components were split/grouped]

**Rationale**: [Why this decomposition]

**Alternatives**: [Other decompositions considered]

---

## Accepted Limitations

### [Limitation Title]

**Limitation**: [What the limitation is]

**Why Accepted**: [Full rationale — why this is acceptable for current scope]

**Mitigations**: [What reduces the risk]

**Future Path**: [Brief reference to future.md if relevant]

---

## Trade-off Analysis

### [Trade-off Title]

**Trade-off**: [What was traded]

**Chose**: [What was chosen]

**Gave Up**: [What was sacrificed]

**Why**: [Rationale]

---

## References

- Architecture Overview: `architecture.md`
- Future Planning: `future.md`
```

---

## Process

1. **Read** the input Architecture Overview completely
2. **Read** the guide for validation reference
3. **Identify** content for each target document using the criteria above:
   - Current-scope content → architecture
   - Future/deferred content → future
   - Rationale/decision content → decisions
4. **Extract** content, noting which section it came from
5. **Group** extracted content by theme within each target document
6. **Write** the clean Architecture Overview with brief reference notes where content was extracted
7. **Write** the future planning doc with grouped future content
8. **Write** the decisions doc with grouped rationale content
9. **Validate** output Architecture Overview against guide (see Quality Checks)
10. **Verify** cross-references between all three docs are accurate

---

## Quality Checks

### Architecture Overview Validation (against Guide)

For each of the 9 sections, verify the output Architecture Overview still covers the guide's expected content:

| Section | Must Still Cover |
|---------|-----------------|
| 1. System Context | Boundaries, external actors |
| 2. Component Decomposition | Components with responsibilities |
| 3. Data Flows | Primary data flows between components |
| 4. Integration Points | How components connect |
| 5. Key Technical Decisions | Brief decision statements (detailed rationale in decisions.md) |
| 6. Component Spec List | Complete list with scope and dependencies |
| 7. Cross-Cutting Concerns | Auth, logging, error handling patterns |
| 8. Data Contracts | All cross-component contracts with producers/consumers |
| 9. Open Questions | Reference to future.md |

### Completeness Checks

- [ ] Architecture Overview reads naturally without gaps
- [ ] All 9 sections present and substantive
- [ ] No `<!-- Rationale: ... -->` HTML comments remain in Architecture Overview
- [ ] No full Design Decisions section remains (only brief notes referencing decisions.md)
- [ ] §5 contains decision statements only (no multi-paragraph rationale)
- [ ] No multi-paragraph future/deferred blocks remain
- [ ] No orphaned references to removed content
- [ ] Component Spec List (§6) is complete and unmodified
- [ ] Data Contracts (§8) are complete and unmodified
- [ ] Future planning doc has clear groupings
- [ ] Decisions doc captures all rationale content
- [ ] Cross-references between all three docs are accurate
- [ ] No content lost (everything went to one of the three docs)

### Cross-Reference Checks

- [ ] Brief notes in Architecture Overview correctly reference decisions.md sections
- [ ] §9 references future.md
- [ ] Future.md references decisions.md where relevant
- [ ] All three docs reference each other in their References sections

---

## Handling Empty Documents

If the source Architecture Overview has no content for a target document, **still create it** with a minimal stub:

**Empty future.md:**
```markdown
# Architecture Future Planning

**Source Version**: [version from original]
**Extracted From**: [date]

## Overview

No deferred decisions, future considerations, or open questions were documented during review.

## References

- Architecture Overview: `architecture.md`
- Decisions: `decisions.md`
```

**Empty decisions.md:**
```markdown
# Architecture Design Decisions

**Source Version**: [version from original]
**Extracted From**: [date]

## Overview

No significant design decisions or trade-offs were documented during review. Design rationale is inline within the Architecture Overview.

## References

- Architecture Overview: `architecture.md`
- Future Planning: `future.md`
```

This ensures consistent 3-doc structure regardless of content volume.

---

<!-- INJECT: tool-restrictions -->

---

## File Output

**Output files** (all three always created):
- `system-design/04-architecture/architecture.md` — Clean current-scope Architecture Overview
- `system-design/04-architecture/future.md` — Future planning (or stub)
- `system-design/04-architecture/decisions.md` — Decisions (or stub)

These overwrite existing files at these locations. The review workflow maintains versioned backups in `versions/round-N/` directories.
