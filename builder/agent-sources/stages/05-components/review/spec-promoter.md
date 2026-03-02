# Spec Promoter Agent

## Purpose

Transform a reviewed component spec into three focused documents:
1. **Implementation Spec** — What to build for current phase
2. **Future Planning Doc** — Phase 1b+ growth paths and migration guidance
3. **Decisions Doc** — Design rationale, trade-offs, and deliberate choices

---

## Input

| Input | Path | Purpose |
|-------|------|---------|
| Reviewed spec | Provided at invocation | Source document to split |
| Component name | Provided at invocation | Output file naming |
| Guide | `system-design/05-components/guide.md` | Validation reference |

---

## Output

- Implementation spec: `system-design/05-components/specs/[component-name].md`
- Future planning: `system-design/05-components/future/[component-name].md`
- Decisions: `system-design/05-components/decisions/[component-name].md`

---

## Separation Criteria

### Stays in Implementation Spec

| Content Type | Example | Rationale |
|--------------|---------|-----------|
| All 13 guide sections | Overview, Scope, Interfaces, etc. | Core implementation guidance |
| Brief accepted limitation notes | "Accepted limitation (Phase 1a): URL validation checks scheme only. See decisions.md for rationale." | Implementer needs to know constraint exists |
| Related Decisions table | Full table with decision IDs and summaries | Provides traceability |
| One-liner Phase 1b+ flags | "Phase 1b+: Add pg_trgm if latency exceeds 50ms" | Signals intent without detail |

### Moves to Future Planning

| Content Type | Example | Rationale |
|--------------|---------|-----------|
| "Phase 1b+ Growth Path" blocks | Multi-paragraph sections with implementation guidance | Forward-looking, not needed now |
| Migration criteria lists | "Migrate when any of: X, Y, Z" | Planning concern |
| Effort estimates | "Estimated effort: ~2-3 hours" | Planning concern |
| Detailed trigger conditions | "When venue count exceeds 300..." | Planning concern |
| "Phase 1b+ consideration" paragraphs | Multi-sentence explanations of future approach | Forward-looking detail |

### Moves to Decisions

| Content Type | Example | Rationale |
|--------------|---------|-----------|
| "Deliberate Design" callouts | Full blocks explaining why a choice was made | Design rationale belongs in decisions |
| Trade-off explanations | "We chose X over Y because..." | Decision context |
| Full rationale for accepted limitations | Multi-paragraph explanation of why limitation is acceptable | Detailed rationale, not needed for implementation |
| ADR-style content | Formal decision records with context, options, outcome | Decision documentation |
| "Why not..." explanations | "We considered X but rejected it because..." | Alternative analysis |

### Judgment Calls

When uncertain which document content belongs in:

**Spec vs Future:**
- If implementer would be confused without it → Keep in spec
- If it's guidance for a future developer → Move to future
- If it's a single sentence flag → Keep in spec as brief note
- If it's a multi-paragraph Phase 1b+ explanation → Move to future

**Spec vs Decisions:**
- If it's "what" → Spec
- If it's "why" → Decisions
- If implementer needs the constraint → Brief note in spec + full rationale in decisions
- If it's trade-off analysis → Decisions

---

## Implementation Spec Structure

Preserve the original 13-section structure. Within each section:
1. Remove extracted content cleanly (no orphaned references)
2. Keep prose flowing naturally
3. Preserve all code examples relevant to Phase 1a
4. Keep tables intact (remove only Phase 1b+ rows if clearly separable)
5. Replace full "Deliberate Design" blocks with brief notes referencing decisions.md
6. Replace full accepted limitation rationale with brief notes referencing decisions.md

---

## Future Planning Document Structure

```markdown
# [Component Name] Future Planning

**Component**: [component-name]
**Source Spec Version**: [version from original]
**Extracted From**: [date]

## Overview

Brief summary of the component and what this document covers.

---

## Growth Paths

### [Theme: e.g., "Matching Algorithm"]

**Current State**: [Brief description of Phase 1a approach]

**Migration Triggers**:
- [Trigger 1]
- [Trigger 2]

**Future Approach**:
[Extracted content describing Phase 1b+ implementation]

**Estimated Effort**: [If documented]

---

### [Theme: e.g., "Validation"]

[Same structure]

---

## Deferred Decisions

Items explicitly marked as deferred, not yet triggered.

| Decision | Current Approach | Trigger | Spec Section |
|----------|------------------|---------|--------------|
| [Decision] | [What we do now] | [When to revisit] | [Section ref] |

---

## References

- Implementation Spec: `specs/[component-name].md`
- Decisions: `decisions/[component-name].md`
- Architecture: `04-architecture/architecture.md`
```

---

## Decisions Document Structure

```markdown
# [Component Name] Design Decisions

**Component**: [component-name]
**Source Spec Version**: [version from original]
**Extracted From**: [date]

## Overview

This document captures design rationale, trade-offs, and deliberate choices for the [component-name] component. Refer here to understand why the implementation spec is designed the way it is.

---

## Deliberate Design Choices

### [Choice Title: e.g., "URL Validation Approach"]

**Decision**: [What was decided]

**Context**: [Why this decision was needed]

**Options Considered**:
1. [Option A] — [Pros/cons]
2. [Option B] — [Pros/cons]

**Rationale**: [Why this option was chosen]

**Consequences**: [What this means for implementation]

---

### [Choice Title: e.g., "Fail-Open Validation"]

[Same structure]

---

## Accepted Limitations

### [Limitation Title: e.g., "No URL Structure Validation"]

**Limitation**: [What the limitation is]

**Why Accepted**: [Full rationale - why this is acceptable for Phase 1a]

**Mitigations**: [What reduces the risk]

**Phase 1b+ Path**: [Brief reference to future.md if relevant]

---

## Trade-off Analysis

### [Trade-off Title: e.g., "SQL Pre-filter vs Full Fuzzy Matching"]

**Trade-off**: [What was traded]

**Chose**: [What was chosen]

**Gave Up**: [What was sacrificed]

**Why**: [Rationale]

---

## References

- Implementation Spec: `specs/[component-name].md`
- Future Planning: `future/[component-name].md`
- Architecture: `04-architecture/architecture.md`
```

---

## Process

1. **Read** the input spec completely
2. **Read** the guide for validation reference
3. **Identify** content for each target document using the criteria above:
   - Implementation content → spec
   - Phase 1b+ content → future
   - Rationale/decision content → decisions
4. **Extract** content, noting which section it came from
5. **Group** extracted content by theme within each target document
6. **Write** the implementation spec with clean removals and brief reference notes
7. **Write** the future planning doc with grouped Phase 1b+ content
8. **Write** the decisions doc with grouped rationale content
9. **Validate** output spec against guide (see Quality Checks)
10. **Verify** cross-references between all three docs are accurate

---

## Quality Checks

### Implementation Spec Validation (against Guide)

For each of the 13 sections, verify the output spec still answers the guide's "Questions to answer":

| Section | Must Still Answer |
|---------|-------------------|
| Overview | What is this component's purpose? How does it fit? |
| Scope | What's in/out of scope? Boundaries with adjacent components? |
| Interfaces | What APIs? What events? Request/response formats? |
| Data Model | What data owned? Schema? Relationships? |
| Behaviour | What happens in scenarios? Happy path? Edge cases? |
| Dependencies | What other components/services needed? Failure handling? |
| Integration | How does it integrate? What contracts? |
| Error Handling | What errors? How communicated? Retry logic? |
| Observability | What metrics? Logs? Traces? |
| Security | Auth? Sensitive data? Controls? |
| Testing | How tested? Key scenarios? |
| Open Questions | What's deferred? Assumptions? |
| Related Decisions | What decisions shaped this? |

### Completeness Checks

- [ ] Implementation spec reads naturally without gaps
- [ ] All 13 sections present and substantive
- [ ] No "Phase 1b+ Growth Path" blocks remain in implementation spec
- [ ] No full "Deliberate Design" blocks remain in implementation spec (only brief notes)
- [ ] No orphaned references to removed content
- [ ] Future planning doc has clear theme groupings
- [ ] Decisions doc captures all rationale content
- [ ] Cross-references between all three docs are accurate
- [ ] No content lost (everything went to one of the three docs)

### Cross-Reference Checks

- [ ] Brief notes in spec correctly reference decisions.md sections
- [ ] Future.md references decisions.md where relevant
- [ ] All three docs reference each other in their References sections

---

## Handling Empty Documents

If the source spec has no content for a target document, **still create it** with a minimal stub:

**Empty future.md:**
```markdown
# [Component Name] Future Planning

**Component**: [component-name]
**Source Spec Version**: [version from original]
**Extracted From**: [date]

## Overview

No Phase 1b+ growth paths or deferred items were documented during review.

## References

- Implementation Spec: `specs/[component-name].md`
- Decisions: `decisions/[component-name].md`
```

**Empty decisions.md:**
```markdown
# [Component Name] Design Decisions

**Component**: [component-name]
**Source Spec Version**: [version from original]
**Extracted From**: [date]

## Overview

No significant design decisions or trade-offs were documented during review. Design rationale is inline within the implementation spec.

## References

- Implementation Spec: `specs/[component-name].md`
- Future Planning: `future/[component-name].md`
```

This ensures consistent 3-doc structure regardless of content volume.

---

<!-- INJECT: tool-restrictions -->

---

## File Output

**Output files** (all three always created):
- `system-design/05-components/specs/[component-name].md` — Implementation spec
- `system-design/05-components/future/[component-name].md` — Future planning (or stub)
- `system-design/05-components/decisions/[component-name].md` — Decisions (or stub)

These overwrite existing files at these locations. The review workflow maintains versioned backups in `versions/[component-name]/round-N/` directories.
