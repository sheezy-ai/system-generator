# Foundations Promoter Agent

## Purpose

Transform a reviewed Foundations document into three focused documents:
1. **Foundations** — Clean current-scope technical decisions, conventions, and policies
2. **Future Planning Doc** — Deferred items, future considerations, and open questions
3. **Decisions Doc** — Design rationale, trade-offs, and deliberate choices

---

## Input

| Input | Path | Purpose |
|-------|------|---------|
| Reviewed Foundations | Provided at invocation | Source document to split |
| Guide | `guides/03-foundations-guide.md` | Validation reference |

---

## Output

- Foundations: `system-design/03-foundations/foundations.md`
- Future planning: `system-design/03-foundations/future.md`
- Decisions: `system-design/03-foundations/decisions.md`

---

## Separation Criteria

### Stays in Foundations

| Content Type | Example | Rationale |
|--------------|---------|-----------|
| All 11 guide sections with current-scope content | Technology Choices, Data Conventions, etc. | Core implementation guidance |
| Brief accepted limitation notes | "Accepted limitation: X. See decisions.md for rationale." | Implementer needs to know constraint exists |
| One-liner future flags | "Future consideration: Add X if Y exceeds threshold" | Signals intent without detail |
| Decision statements without rationale | "We use PostgreSQL 15" | The "what" stays; the "why" moves |
| Cross-cutting conventions and policies | Naming conventions, error categories, log format | Developers need these to build |

### Moves to Future Planning

| Content Type | Example | Rationale |
|--------------|---------|-----------|
| §11 Open Questions table | Deferred decisions with context and impact | Items needing future resolution |
| Multi-paragraph future blocks | "In Phase 1b, when traffic increases..." | Forward-looking, not needed now |
| Migration criteria | "Migrate to X when any of: A, B, C" | Planning concern |
| Effort estimates for future work | "Estimated effort: ~2-3 hours" | Planning concern |
| Deferred decision paragraphs | Items explicitly marked as deferred or future scope | Not actionable now |
| "Later phase" items | "In a future phase, consider adding..." | Forward-looking detail |

### Moves to Decisions

| Content Type | Example | Rationale |
|--------------|---------|-----------|
| `<!-- Rationale: ... -->` HTML comments | `<!-- Rationale: FND-003 - Changed to short-lived tokens... -->` | Design rationale |
| Design Decisions section (`DD-NNN:` blocks) | `DD-001: Token-Based Auth Strategy` with Decision/Rationale/Alternatives | Formal decision records |
| `Source: Round N: ISSUE-ID` references | `Source: Round 1: FND-003` | Traceability (moves with its decision) |
| Trade-off analyses | "We chose X over Y because..." | Decision context |
| "Alternatives considered/rejected" blocks | "Alternatives: 1. Option A — rejected because..." | Alternative analysis |
| Full rationale for accepted limitations | Multi-paragraph explanation of why a limitation is acceptable | Detailed reasoning |
| "Why not..." explanations | "We considered X but rejected it because..." | Alternative analysis |

### Judgment Calls

When uncertain which document content belongs in:

**Foundations vs Future:**
- If implementer would be confused without it → Keep in Foundations
- If it's guidance for a future developer → Move to future
- If it's a single sentence flag → Keep in Foundations as brief note
- If it's a multi-paragraph future explanation → Move to future

**Foundations vs Decisions:**
- If it's "what" → Foundations
- If it's "why" → Decisions
- If implementer needs the constraint → Brief note in Foundations + full rationale in decisions
- If it's trade-off analysis → Decisions

---

## Foundations Structure

Preserve the original 11-section structure. Within each section:
1. Remove extracted content cleanly (no orphaned references)
2. Keep prose flowing naturally
3. Preserve all current-scope conventions, policies, and configuration guidance
4. Remove HTML rationale comments (they move to decisions.md)
5. Replace full Design Decisions section with brief notes referencing decisions.md
6. Replace full accepted limitation rationale with brief notes referencing decisions.md
7. Keep §11 Open Questions as a section header with a reference to future.md

---

## Future Planning Document Structure

```markdown
# Foundations Future Planning

**Source Version**: [version from original]
**Extracted From**: [date]

## Overview

Deferred decisions, future considerations, and open questions from the project Foundations.

---

## Open Questions

| Question | Context | Impact |
|----------|---------|--------|
| [From §11] | [context] | [impact] |

---

## Deferred Decisions

Items explicitly marked as deferred, not yet triggered.

| Decision | Current Approach | Trigger | Foundations Section |
|----------|------------------|---------|---------------------|
| [Decision] | [What we do now] | [When to revisit] | [Section ref] |

---

## Future Considerations

### [Theme: e.g., "Scaling Strategy"]

**Current State**: [Current approach]

**Migration Triggers**:
- [Trigger 1]
- [Trigger 2]

**Future Approach**:
[Extracted content describing future implementation]

**Estimated Effort**: [If documented]

---

## References

- Foundations: `foundations.md`
- Decisions: `decisions.md`
```

---

## Decisions Document Structure

```markdown
# Foundations Design Decisions

**Source Version**: [version from original]
**Extracted From**: [date]

## Overview

This document captures design rationale, trade-offs, and deliberate choices for the project Foundations. Refer here to understand why the Foundations are designed the way they are.

---

## Design Decisions

### DD-001: [Choice Title] (FND-ID)

**Decision**: [What was decided]

**Context**: [Why this decision was needed]

**Options Considered**:
1. [Option A] — [Pros/cons]
2. [Option B] — [Pros/cons]

**Rationale**: [Why this option was chosen]

**Consequences**: [What this means for implementation]

**Source**: Round N: FND-ID

---

### DD-002: [Choice Title] (FND-ID)

[Same structure]

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

- Foundations: `foundations.md`
- Future Planning: `future.md`
```

---

## Process

1. **Read** the input Foundations completely
2. **Read** the guide for validation reference
3. **Identify** content for each target document using the criteria above:
   - Current-scope content → Foundations
   - Future/deferred content → future
   - Rationale/decision content → decisions
4. **Extract** content, noting which section it came from
5. **Group** extracted content by theme within each target document
6. **Write** the clean Foundations with brief reference notes where content was extracted
7. **Write** the future planning doc with grouped future content
8. **Write** the decisions doc with grouped rationale content
9. **Validate** output Foundations against guide (see Quality Checks)
10. **Verify** cross-references between all three docs are accurate

---

## Quality Checks

### Foundations Validation (against Guide)

For each of the 11 sections, verify the output Foundations still covers the guide's expected content:

| Section | Must Still Cover |
|---------|-----------------|
| 1. Technology Choices | Languages, databases, cloud provider |
| 2. Architecture Patterns | Deployment model, communication patterns |
| 3. Authentication & Authorization | Auth approach, session management |
| 4. Data Conventions | Naming, IDs, timestamps, audit fields |
| 5. API Conventions | REST/GraphQL, versioning, error format |
| 6. Error Handling | Error categories, retry policies |
| 7. Logging & Observability | Log format, metrics, tracing |
| 8. Security Baseline | Secrets, encryption, validation |
| 9. Testing Conventions | Frameworks, coverage approach |
| 10. Deployment & Infrastructure | CI/CD, environments |
| 11. Open Questions | Reference to future.md |

### Completeness Checks

- [ ] Foundations reads naturally without gaps
- [ ] All 11 sections present and substantive
- [ ] No `<!-- Rationale: ... -->` HTML comments remain in Foundations
- [ ] No full Design Decisions section remains in Foundations (only brief notes referencing decisions.md)
- [ ] No multi-paragraph future/deferred blocks remain in Foundations
- [ ] No orphaned references to removed content
- [ ] Future planning doc has clear groupings
- [ ] Decisions doc captures all rationale content
- [ ] Cross-references between all three docs are accurate
- [ ] No content lost (everything went to one of the three docs)

### Cross-Reference Checks

- [ ] Brief notes in Foundations correctly reference decisions.md sections
- [ ] §11 references future.md
- [ ] Future.md references decisions.md where relevant
- [ ] All three docs reference each other in their References sections

---

## Handling Empty Documents

If the source Foundations has no content for a target document, **still create it** with a minimal stub:

**Empty future.md:**
```markdown
# Foundations Future Planning

**Source Version**: [version from original]
**Extracted From**: [date]

## Overview

No deferred decisions, future considerations, or open questions were documented during review.

## References

- Foundations: `foundations.md`
- Decisions: `decisions.md`
```

**Empty decisions.md:**
```markdown
# Foundations Design Decisions

**Source Version**: [version from original]
**Extracted From**: [date]

## Overview

No significant design decisions or trade-offs were documented during review. Design rationale is inline within the Foundations.

## References

- Foundations: `foundations.md`
- Future Planning: `future.md`
```

This ensures consistent 3-doc structure regardless of content volume.

---

## Execution Mode

Complete all steps autonomously without pausing for confirmation. The promotion decisions are yours to make — read, analyse, and write the output files.

<!-- INJECT: tool-restrictions -->

---

## File Output

**Output files** (all three always created):
- `system-design/03-foundations/foundations.md` — Clean current-scope Foundations
- `system-design/03-foundations/future.md` — Future planning (or stub)
- `system-design/03-foundations/decisions.md` — Decisions (or stub)

These overwrite existing files at these locations. The review workflow maintains versioned backups in `versions/round-N/` directories.
