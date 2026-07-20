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

Write the three documents to the **output paths provided at invocation** (the Promote orchestrator passes round-folder paths — `round-[N]-promote/foundations.md` / `future.md` / `decisions.md`; it publishes them to the live parent after the document-conservation gate returns CLEAN):
- Foundations — clean current-scope technical decisions, conventions, and policies
- Future planning — deferred items and future considerations
- Decisions — design rationale and trade-offs

---

## Separation Criteria

**§1–10 are verbatim-preserved — the narrowing rule that governs everything below.** The promoter's **only** edits to §1 Technology Choices … §10 Deployment & Infrastructure are **removal of `<!-- … -->` HTML comments**. It does **NOT** extract rationale, decisions, trade-offs, or future content, and does **NOT** brief-note-substitute, *within* §1–10 — inline rationale prose in a convention section **stays inline, byte-for-byte**. The **only** content the promoter MOVES is authored **outside** §1–10:
- the **standalone `## Design Decisions` section** (the `DD-NNN:` blocks the project authors *below* §11) → `decisions.md`; and
- **§11 Open Questions** → `future.md` (leaving the §11 header + a reference).

The content-type tables below describe the *shapes* of movable content, but per this rule the promoter **only acts on them when they appear outside §1–10** (in the standalone Design-Decisions section, or in §11). If a project authored no standalone Design-Decisions section and kept its rationale inline in §1–10, that rationale **stays inline** and `decisions.md` is an empty stub — a valid, guide-consistent outcome. §1–10 conventions are never transformed.

### Stays in Foundations

| Content Type | Example | Rationale |
|--------------|---------|-----------|
| All 11 guide sections with current-scope content | Technology Choices, Data Conventions, etc. | Core implementation guidance |
| **All of §1–10, verbatim** (incl. any inline rationale) | Any convention prose in §1–10 | §1–10 are byte-preserved; nothing is extracted from them |
| Brief accepted limitation notes **already authored in §1–10** | "Accepted limitation: X. See decisions.md for rationale." | Stays as authored — the promoter does not create or rewrite these |
| One-liner future flags **already authored in §1–10** | "Future consideration: Add X if Y exceeds threshold" | Stays as authored inline |
| Decision statements with or without inline rationale | "We use PostgreSQL 15" (+ any inline "because …") | Both the "what" and any inline "why" stay in §1–10; only the standalone Design-Decisions section moves |
| Cross-cutting conventions and policies | Naming conventions, error categories, log format | Developers need these to build |

### Moves to Future Planning

**Scope:** the promoter MOVES **§11 Open Questions** to `future.md`. The other shapes below move to `future.md` **only if they are authored outside §1–10** (e.g. within §11, or the standalone Design-Decisions section). Any future-flavoured content that appears *inside* §1–10 **stays inline, verbatim** (per the §1–10-verbatim rule) — it is not extracted.

| Content Type | Example | Rationale |
|--------------|---------|-----------|
| §11 Open Questions table | Deferred decisions with context and impact | Items needing future resolution |
| Multi-paragraph future blocks (outside §1–10) | "In Phase 1b, when traffic increases..." | Forward-looking, not needed now |
| Migration criteria (outside §1–10) | "Migrate to X when any of: A, B, C" | Planning concern |
| Effort estimates for future work (outside §1–10) | "Estimated effort: ~2-3 hours" | Planning concern |
| Deferred decision paragraphs (outside §1–10) | Items explicitly marked as deferred or future scope | Not actionable now |
| "Later phase" items (outside §1–10) | "In a future phase, consider adding..." | Forward-looking detail |

### Moves to Decisions

**Scope:** the promoter MOVES the **standalone `## Design Decisions` section** (authored below §11) wholesale to `decisions.md`. The rationale shapes below move **only as they appear inside that standalone section** — trade-offs, alternatives, and "why not" analyses that are inline within §1–10 **stay inline, verbatim** (per the §1–10-verbatim rule). The sole §1–10 edit is `<!-- … -->` HTML-comment removal.

| Content Type | Example | Rationale |
|--------------|---------|-----------|
| `<!-- Rationale: ... -->` HTML comments | `<!-- Rationale: FND-003 - Changed to short-lived tokens... -->` | Removed from §1–10 (the sole sanctioned §1–10 edit); the design rationale lives in the standalone Design-Decisions section |
| Standalone Design Decisions section (`DD-NNN:` blocks) | `DD-001: Token-Based Auth Strategy` with Decision/Rationale/Alternatives | Formal decision records — the primary movable unit |
| `Source: Round N: ISSUE-ID` references | `Source: Round 1: FND-003` | Traceability (moves with its DD block) |
| Trade-off analyses (within the standalone section) | "We chose X over Y because..." | Decision context |
| "Alternatives considered/rejected" blocks (within the standalone section) | "Alternatives: 1. Option A — rejected because..." | Alternative analysis |
| Full rationale for accepted limitations (within the standalone section) | Multi-paragraph explanation of why a limitation is acceptable | Detailed reasoning |
| "Why not..." explanations (within the standalone section) | "We considered X but rejected it because..." | Alternative analysis |

### Judgment Calls

**These judgment calls do NOT apply to §1–10** — those ten sections are verbatim-preserved and are never weighed for extraction. Use the calls below only to place content that is already **outside** §1–10 (the standalone Design-Decisions section, and §11).

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

**§1–10 are verbatim-preserved.** These ten sections (§1 Technology Choices … §10 Deployment & Infrastructure) are copied **byte-for-byte** into `foundations.md` so the document-conservation gate can verify them. The promoter does **NOT** re-flow, re-order, re-word, condense, split, or extract rationale/decisions/future from them — inline rationale prose in a convention section **stays inline, byte-for-byte**. The **only** content the promoter MOVES is authored **outside** §1–10:
- the **standalone `## Design Decisions` section** (the `DD-NNN:` blocks the project authors *below* §11) → `decisions.md`; and
- **§11 Open Questions** → `future.md`.

Preserve the original 11-section structure. The promoter's edits are therefore limited to:
1. **Remove `<!-- … -->` HTML comments from §1–10** (the sole sanctioned edit to those sections); keep everything else in §1–10 byte-identical to the reviewed source.
2. **Extract the standalone `## Design Decisions` section** (below §11) to `decisions.md` — move the `DD-NNN:` blocks with their `Source:` references intact. If no such standalone section exists, extract nothing (decisions.md is an empty stub) and leave §1–10 untouched.
3. **Move §11 Open Questions content to `future.md`**, keeping §11 in `foundations.md` as a section header with a reference to future.md.

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
- [ ] The standalone `## Design Decisions` section has been extracted to decisions.md (it does not remain in foundations.md); §1–10 are otherwise unchanged
- [ ] §11 Open Questions content has been moved to future.md (only the §11 header + reference to future.md remain in foundations.md)
- [ ] §1 Technology Choices is **byte-identical** to the reviewed source (modulo HTML-comment removal)
- [ ] §2 Architecture Patterns is **byte-identical** to the reviewed source (modulo HTML-comment removal)
- [ ] §3 Authentication & Authorization is **byte-identical** to the reviewed source (modulo HTML-comment removal)
- [ ] §4 Data Conventions is **byte-identical** to the reviewed source (modulo HTML-comment removal)
- [ ] §5 API Conventions is **byte-identical** to the reviewed source (modulo HTML-comment removal)
- [ ] §6 Error Handling is **byte-identical** to the reviewed source (modulo HTML-comment removal)
- [ ] §7 Logging & Observability is **byte-identical** to the reviewed source (modulo HTML-comment removal)
- [ ] §8 Security Baseline is **byte-identical** to the reviewed source (modulo HTML-comment removal)
- [ ] §9 Testing Conventions is **byte-identical** to the reviewed source (modulo HTML-comment removal)
- [ ] §10 Deployment & Infrastructure is **byte-identical** to the reviewed source (modulo HTML-comment removal)
- [ ] No orphaned references to removed content
- [ ] Future planning doc has clear groupings
- [ ] Decisions doc captures all rationale content
- [ ] Cross-references between all three docs are accurate
- [ ] No content lost (everything went to one of the three docs)

### Cross-Reference Checks

- [ ] Any reference to decisions.md that already existed inline in §1–10 still resolves (the promoter does not add new brief-note references to §1–10)
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

**Output files** (all three always created): Write the three documents to the **output paths passed at invocation** (the round-folder originals: `round-[N]-promote/foundations.md` / `future.md` / `decisions.md`):
- Foundations (clean current-scope Foundations, §1–10 verbatim)
- Future planning (or stub)
- Decisions (or stub)

The Promote orchestrator publishes them to the live paths (`system-design/03-foundations/foundations.md` / `future.md` / `decisions.md`) only after the document-conservation gate returns CLEAN. Do not write to the live paths directly.
