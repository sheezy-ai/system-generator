# Blueprint Guide

## Purpose

The Blueprint is the foundational strategic document for a product or platform. It answers **why** we're building this, **who** it's for, and **what** we need to build first to validate the opportunity. It provides the context that shapes all subsequent decisions without constraining how those decisions are implemented.

A good Blueprint allows someone unfamiliar with the project to understand the vision, the opportunity, and what a viable first version looks like. It should be readable by non-technical stakeholders.

---

## What the Blueprint Should Contain

### 1. Vision and Problem Statement

**Questions to answer:**
- What problem are we solving?
- Why does this problem matter?
- Who experiences this problem?
- What does the world look like if we succeed?

**Level of detail:** Clear, concise articulation. One or two paragraphs, not pages. Avoid jargon.

---

### 2. Target Users

**Questions to answer:**
- Who are the primary users/customers?
- Are there distinct user types with different needs (e.g., consumers vs organisers, buyers vs sellers)?
- Which user type is the priority for MVP?
- What are their key characteristics, behaviours, or pain points?

**Level of detail:** Describe user segments meaningfully, not exhaustively. Enough to guide product decisions. Personas optional but can help if they're grounded in reality, not fiction.

---

### 3. Value Proposition

**Questions to answer:**
- What value do we provide to each user type?
- Why would someone use this instead of alternatives (including doing nothing)?
- What's the core insight or unfair advantage?

**Level of detail:** Sharp and specific. If the value proposition is vague ("we make things easier"), it's not ready.

---

### 4. Business Model

**Questions to answer:**
- How does this become a sustainable business?
- What are the potential revenue streams?
- Which revenue model applies (subscription, transaction fee, advertising, freemium, etc.)?
- What's the rough unit economics hypothesis (even if unvalidated)?
- Are there network effects or other scaling dynamics?

**Level of detail:** Identify the model(s) and rationale. Exact pricing, financial projections, and detailed modelling belong elsewhere (e.g., a business plan or financial model). The Blueprint states *how* we intend to make money, not *how much*.

---

### 5. Core Principles and Constraints

**Questions to answer:**
- What principles guide how we build and operate?
- What will we *not* do, even if it might be profitable?
- What external constraints shape the business (regulatory, ethical, technical)?
- What trade-offs have we already decided (e.g., privacy over personalisation, simplicity over features)?

**Level of detail:** Explicit statements that can guide future decisions. "When in doubt, we choose X over Y." These should be genuinely constraining, not platitudes.

---

### 6. Project Maturity Target

**Questions to answer:**
- What level of maturity are we targeting for this phase?
- Is this MVP (validate assumptions), Prod (production-ready), or Enterprise (compliance-heavy)?
- What's the rationale for this maturity level?
- Are there timeline or resource constraints driving this choice?
- What's the planned maturity progression (if any)?

**Level of detail:** State the target level and why. This guides all downstream stages - PRD requirements, technical decisions, architecture choices, and implementation details will all be calibrated to this target.

**Maturity Levels:**

| Level | Context | Mindset |
|-------|---------|---------|
| **MVP** | Startup/early validation | Speed over polish, conscious tech debt acceptable |
| **Prod** | Scaleup/production | Real users depend on it, reliability matters |
| **Enterprise** | Compliance-heavy | Audit trails, SLAs, formal processes required |

**Example:**
```
Target Maturity: MVP

Rationale: We need to validate the core hypothesis before investing in production hardening.
Timeline pressure: 8 weeks to first user feedback.
Planned progression: If validation succeeds, move to Prod maturity for public launch.
```

For detailed maturity expectations by stage, see `maturity-reference.md` and the stage-specific maturity guides.

---

### 7. Market Context

**Questions to answer:**
- What's the market landscape?
- Who are the existing players (competitors, adjacent products, substitutes)?
- What's our positioning relative to them?
- What market trends or shifts create the opportunity?

**Level of detail:** Enough to demonstrate awareness and justify the opportunity. Not a full competitive analysis or market research report - those can be separate documents if needed.

---

### 8. MVP Definition

**Questions to answer:**
- What must be true for the first release to be viable?
- What's the minimum that validates the core hypothesis?
- What capabilities are essential for MVP?
- What is explicitly NOT required for MVP?

**Level of detail:** Clear scope boundaries for what "viable first version" means. Not a feature list or PRD - just enough to define what's in and out for the first release. This section directly informs PRD creation.

Example:
- **Must have:** Users can discover events, view details, express interest
- **Not required for MVP:** Payments, organiser tools, recommendations engine

---

### 9. Success Criteria

**Questions to answer:**
- How do we know if the MVP succeeded?
- What are the key metrics that matter?
- What signals would indicate we should pivot or stop?
- What does "good enough to continue" look like?

**Level of detail:** Identify the metrics and why they matter. Specific targets can be stated if known, but even loosely defined criteria are valuable ("users return within a week" rather than "42% D7 retention"). The goal is to define what success looks like, not to set precise OKRs.

---

### 10. Key Risks and Assumptions

**Questions to answer:**
- What are the biggest risks to the venture?
- What assumptions are we making that, if wrong, would undermine the business?
- What do we *not* know that we need to learn?

**Level of detail:** Honest articulation of uncertainty. Not a full risk register with mitigations (that's operational) - just the critical risks and assumptions that shape strategy.

---

### 11. Why Now?

**Questions to answer:**
- Why is this the right time to build this?
- What's changed (technology, market, regulation, behaviour) that creates the opportunity?
- Why hasn't this been done before, or why did previous attempts fail?

**Level of detail:** Brief but compelling. This is often the "so what" that ties the opportunity together.

---

## Optional: Future Vision

If you have thoughts on what comes after MVP, you can include them in a separate section or document. This is **not required** and is **not used by the PRD creation workflow** - the PRD focuses solely on the MVP Definition and Success Criteria above.

Future vision might include:
- Potential expansion directions
- Features deferred from MVP
- Long-term strategic possibilities

Keep this separate from MVP scope to avoid confusion. A separate `future-vision.md` document is preferable to mixing it into the Blueprint.

---

## What Should NOT Be in the Blueprint

| Out of Scope | Where It Belongs |
|--------------|------------------|
| Feature lists | PRD |
| Technical architecture | Foundations / Component Specs |
| Data models (even conceptual) | PRD |
| Implementation approach | Component Specs |
| Timelines and deadlines | Project planning (separate) |
| Detailed financial projections | Business plan / financial model |
| Specific technology choices | Foundations |
| Security/compliance implementation details | Foundations / Component Specs |
| User stories or acceptance criteria | Tasks |
| API contracts, schemas, integrations | Component Specs |
| Operational processes | Runbooks / operational docs |

**The test:** If the content constrains *how* something is built rather than *what* or *why*, it probably doesn't belong in the Blueprint.

---

## Decision Source References

Strategic decisions in the Blueprint should include source references when they originate from review discussions:

**Format:**
```markdown
**Decision: [Brief title]**
- Rationale: [Why this decision was made]
- Source: Round N: ISSUE-ID
```

The source reference enables tracing back to the originating discussion in `versions/review/round-N/03-issues-discussion.md`.

---

## Tone and Style

- **Accessible:** Readable by anyone, technical or not
- **Confident but honest:** State the vision clearly; acknowledge uncertainty where it exists
- **Concise:** Long enough to be complete, short enough to be read. Aim for 5-15 pages depending on complexity.
- **Stable:** The Blueprint shouldn't change frequently. If it's changing often, either the vision is unclear or details are leaking in that belong elsewhere.

---

## Common Mistakes

**Too detailed:** Including feature specs, technical decisions, or implementation plans. This makes the document unwieldy and mixes strategic with tactical.

**Too vague:** Platitudes without substance. "We provide value to customers" says nothing. "We help X do Y, which they currently can't because Z" says something.

**No constraints:** A Blueprint that doesn't say "no" to anything isn't guiding decisions. Principles should be genuinely limiting.

**Ignoring business model:** A vision without a path to sustainability is a hobby, not a business. Even if uncertain, articulate the hypothesis.

**No MVP definition:** Describing the end-state vision without defining what a viable first version looks like. MVP Definition forces prioritisation and acknowledges that you can't build everything at once.

**Confusing vision with MVP:** The Blueprint describes where we're going AND what the first step looks like. These are related but distinct - the vision is the destination, the MVP is the minimum viable journey start.

