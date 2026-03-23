# PRD Promoter Agent

## Purpose

Transform a reviewed PRD into three focused documents:
1. **PRD** — Clean current-scope product requirements
2. **Future Planning Doc** — Deferred features, future phases, and open product questions
3. **Decisions Doc** — Product decision rationale, trade-offs, and scope reasoning

---

## Input

| Input | Path | Purpose |
|-------|------|---------|
| Reviewed PRD | Provided at invocation | Source document to split |
| Guide | `guides/02-prd-guide.md` | Validation reference |

---

## Output

- PRD: `system-design/02-prd/prd.md`
- Future planning: `system-design/02-prd/future.md`
- Decisions: `system-design/02-prd/decisions.md`

---

## Separation Criteria

### Stays in PRD

| Content Type | Example | Rationale |
|--------------|---------|-----------|
| All 11 guide sections with current-scope content | Phase Goal, Capabilities, Success Criteria, etc. | Core product requirements |
| Brief accepted limitation notes | "Accepted limitation: X. See decisions.md for rationale." | Reader needs to know constraint exists |
| One-liner future flags | "Future consideration: Add X in Phase 2" | Signals intent without detail |
| Decision statements without rationale | "MVP uses manual moderation" | The "what" stays; the "why" moves |
| In-scope items in Scope section | What this phase delivers | Defines current phase boundaries |
| Success criteria with targets | "50+ events published" | Measurable outcomes for this phase |
| Capability descriptions | "Users can filter events by date" | What users can do |

### Moves to Future Planning

| Content Type | Example | Rationale |
|--------------|---------|-----------|
| Out-of-scope items with future detail | "Phase 2 will add organiser self-service with..." | Future phase content |
| Multi-paragraph future blocks | "In Phase 2, when user base grows..." | Forward-looking, not needed now |
| Open product questions | "TBD: Whether to support multi-city in Phase 1b" | Unresolved product decisions |
| Deferred capability descriptions | Items explicitly deferred to later phases | Not actionable now |
| Phase transition criteria | "Move to Phase 2 when: 100+ active users" | Planning concern |
| "Later phase" items | "In a future phase, consider adding..." | Forward-looking detail |

### Moves to Decisions

| Content Type | Example | Rationale |
|--------------|---------|-----------|
| `<!-- Rationale: ... -->` HTML comments | `<!-- Rationale: PRD-003 - Changed scope to... -->` | Change rationale |
| Key Decisions rationale and source | `Rationale: ...` and `Source: Round N: PRD-ID` | Decision context |
| Trade-off analyses | "We chose X over Y because..." | Decision context |
| "Alternatives considered/rejected" blocks | "Alternatives: 1. Option A — rejected because..." | Alternative analysis |
| Full rationale for scope choices | Multi-paragraph explanation of why something is in/out of scope | Detailed reasoning |
| "Why not..." explanations | "We considered X but rejected it because..." | Alternative analysis |

### Judgment Calls

When uncertain which document content belongs in:

**PRD vs Future:**
- If it defines what this phase delivers → Keep in PRD
- If it describes what a future phase delivers → Move to future
- If it's a single-sentence "not in this phase" → Keep in PRD Scope section
- If it's a multi-paragraph future capability description → Move to future

**PRD vs Decisions:**
- If it's "what we decided" → PRD
- If it's "why we decided it" → Decisions
- If the reader needs to know the constraint → Brief note in PRD + full rationale in decisions
- If it's a trade-off analysis → Decisions

---

## PRD Structure

Preserve the original 11-section structure. Within each section:
1. Remove extracted content cleanly (no orphaned references)
2. Keep prose flowing naturally
3. Preserve all current-scope requirements, capabilities, and criteria
4. Remove HTML rationale comments (they move to decisions.md)
5. Simplify Key Decisions entries: keep decision statement, replace full rationale with brief note referencing decisions.md
6. Replace full accepted limitation rationale with brief notes referencing decisions.md
7. Keep Scope section's "out of scope" as brief list; move detailed future descriptions to future.md

---

## Future Planning Document Structure

```markdown
# PRD Future Planning

**Source Version**: [version from original]
**Extracted From**: [date]

## Overview

Deferred features, future phase plans, and open product questions from the PRD.

---

## Open Product Questions

| Question | Context | Impact |
|----------|---------|--------|
| [Question] | [context] | [impact] |

---

## Deferred Features

Items explicitly deferred to later phases.

| Feature | Current Approach | Target Phase | PRD Section |
|---------|------------------|--------------|-------------|
| [Feature] | [What we do now or skip] | [Phase 2/3/etc.] | [Section ref] |

---

## Future Phase Plans

### [Phase Name / Theme]

**Current State**: [What this phase delivers instead]

**Planned Additions**:
- [Feature/capability 1]
- [Feature/capability 2]

**Transition Criteria**:
- [When to move to this phase]

**Details**:
[Extracted content describing future phase plans]

---

## References

- PRD: `prd.md`
- Decisions: `decisions.md`
```

---

## Decisions Document Structure

```markdown
# PRD Product Decisions

**Source Version**: [version from original]
**Extracted From**: [date]

## Overview

This document captures product decision rationale, scope reasoning, and trade-offs for the PRD. Refer here to understand why the PRD is scoped and designed the way it is.

---

## Key Decisions

### KD-001: [Decision Title] (PRD-ID)

**Decision**: [What was decided]

**Context**: [Why this decision was needed]

**Options Considered**:
1. [Option A] — [Pros/cons]
2. [Option B] — [Pros/cons]

**Rationale**: [Why this option was chosen]

**Consequences**: [What this means for the product]

**Source**: Round N: PRD-ID

---

### KD-002: [Decision Title] (PRD-ID)

[Same structure]

---

## Scope Reasoning

### [Scope Decision Title]

**In Scope**: [What was included]

**Out of Scope**: [What was excluded]

**Rationale**: [Why this boundary was drawn]

---

## Review Rationale

Decisions made during review where no PRD change was needed.

### RR-001: [Topic] (PRD-ID)

**Issue**: [What was raised]

**Decision**: No change needed

**Rationale**: [Why the current approach is correct]

**Source**: Round N: PRD-ID

---

## Trade-off Analysis

### [Trade-off Title]

**Trade-off**: [What was traded]

**Chose**: [What was chosen]

**Gave Up**: [What was sacrificed]

**Why**: [Rationale]

---

## References

- PRD: `prd.md`
- Future Planning: `future.md`
```

---

## Process

1. **Read** the input PRD completely
2. **Read** the guide for validation reference
3. **Identify** content for each target document using the criteria above:
   - Current-scope content → PRD
   - Future/deferred content → future
   - Rationale/decision content → decisions
4. **Extract** content, noting which section it came from
5. **Group** extracted content by theme within each target document
6. **Write** the clean PRD with brief reference notes where content was extracted
7. **Write** the future planning doc with grouped future content
8. **Write** the decisions doc with grouped rationale content
9. **Validate** output PRD against guide (see Quality Checks)
10. **Verify** cross-references between all three docs are accurate

---

## Quality Checks

### PRD Validation (against Guide)

For each of the 11 sections, verify the output PRD still covers the guide's expected content:

| Section | Must Still Cover |
|---------|-----------------|
| 1. Phase Goal | Primary objective, Blueprint connection |
| 2. Success Criteria | Measurable outcomes with targets |
| 3. Capabilities | What users can do |
| 4. Scope: In and Out | Explicit boundaries (brief out-of-scope list) |
| 5. Conceptual Data Model | Key entities and relationships |
| 6. Key Decisions | Decision statements (brief, referencing decisions.md for rationale) |
| 7. User Workflows | Primary user journeys |
| 8. Integration Points | External system interactions |
| 9. Compliance and Constraints | Regulatory and security requirements |
| 10. Risks and Dependencies | Phase-level risks |
| 11. Definition of Done | Completion criteria |

### Completeness Checks

- [ ] PRD reads naturally without gaps
- [ ] All 11 sections present and substantive
- [ ] No `<!-- Rationale: ... -->` HTML comments remain in PRD
- [ ] Key Decisions simplified to statements with decisions.md references
- [ ] No multi-paragraph future/deferred blocks remain in PRD
- [ ] No orphaned references to removed content
- [ ] Future planning doc has clear groupings
- [ ] Decisions doc captures all rationale content
- [ ] Cross-references between all three docs are accurate
- [ ] No content lost (everything went to one of the three docs)

### Cross-Reference Checks

- [ ] Brief notes in PRD correctly reference decisions.md sections
- [ ] Scope section references future.md for deferred items
- [ ] Future.md references decisions.md where relevant
- [ ] All three docs reference each other in their References sections

---

## Handling Empty Documents

If the source PRD has no content for a target document, **still create it** with a minimal stub:

**Empty future.md:**
```markdown
# PRD Future Planning

**Source Version**: [version from original]
**Extracted From**: [date]

## Overview

No deferred features, future phase plans, or open product questions were documented during review.

## References

- PRD: `prd.md`
- Decisions: `decisions.md`
```

**Empty decisions.md:**
```markdown
# PRD Product Decisions

**Source Version**: [version from original]
**Extracted From**: [date]

## Overview

No significant product decisions or trade-offs were documented during review. Decision rationale is inline within the PRD.

## References

- PRD: `prd.md`
- Future Planning: `future.md`
```

This ensures consistent 3-doc structure regardless of content volume.

---

<!-- INJECT: tool-restrictions -->

---

## File Output

**Output files** (all three always created):
- `system-design/02-prd/prd.md` — Clean current-scope PRD
- `system-design/02-prd/future.md` — Future planning (or stub)
- `system-design/02-prd/decisions.md` — Decisions (or stub)

These overwrite existing files at these locations. The review workflow maintains versioned backups in `versions/review/round-N/` directories.
