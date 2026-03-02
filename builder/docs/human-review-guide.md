# Human Review Guidelines

## Purpose

This document provides guidance for human review steps across all stages and workflows (Create and Review). When you receive a file with issues requiring your input, this guide explains your role and how to respond effectively.

---

## Your Role

You are the **decision maker**. Agents have identified gaps (Create workflow) or issues (Review workflow), asked questions, and flagged assumptions - but only you can provide the answers. Your responses will be used by the Author to produce the final document.

---

## Where Issues Live

Issues are in `03-issues-discussion.md` within the round folder. This file contains:
- Summary of each issue (ID, severity, section, description)
- A core question for you to answer
- Space for discussion (`>> HUMAN:` / `>> AGENT:` markers)

Full detail is available in `02-consolidated-issues.md` if you need more context.

---

## How to Respond

### Response Format

Each issue has a `>> HUMAN:` marker. Write your response directly after this marker.

**Answering a question:**
```markdown
**Question**: What is the primary revenue model?

>> HUMAN: Subscription-based, monthly billing. Freemium tier for individual users, paid tiers for teams.
```

**Making a decision:**
```markdown
**Question**: B2B or B2C focus for MVP?

>> HUMAN: B2B. Enterprise sales motion with pilot programs.
```

**Confirming an assumption:**
```markdown
**Question**: Confirm users are willing to pay for this.

>> HUMAN: Yes - validated through customer interviews.
```

**Modifying an assumption:**
```markdown
>> HUMAN: Partially. Users willing to pay, but only after seeing value - freemium required.
```

**Disagreeing with an issue:**
```markdown
>> HUMAN: Not a concern. The current wording works for our use case.
```

---

## Discussion Flow

Most issues follow this pattern:

1. **You respond** with `>> HUMAN:` to each issue
2. **Signal completion** to the orchestrator (e.g., "done", "ready", "I've responded")
3. **Orchestrator spawns Discussion Facilitators** for issues needing agent response
4. **Agents respond** with `>> AGENT:` - often proposing a solution
5. **You review and respond** with another `>> HUMAN:`
6. **Repeat** until you're satisfied
7. **Orchestrator marks `>> RESOLVED`** when you signal closure

### Signalling Closure

When you're satisfied with a resolution, respond clearly:
- "Yes", "Agreed", "That works", "Fine", "OK"
- "Makes sense", "Fair enough", "Understood"
- "Not a concern", "Skip", "N/A"

The orchestrator will add `>> RESOLVED` after responses like these.

### Continuing Discussion

If you need more discussion, respond with:
- Questions: "What about X?", "How would this work with Y?"
- Requests: "Can you show me an example?"
- Pushback: "I disagree because...", "But what about...?"

The orchestrator will spawn another Discussion Facilitator round.

---

## Priority Guidance

Issues are ordered by severity (HIGH → MEDIUM → LOW). Focus on HIGH issues first - these represent significant problems that need resolution before the document is ready.

---

## It's OK to Not Know

If you genuinely don't know the answer:
```markdown
>> HUMAN: Defer - need to validate with customer research first.
```

The Author will mark this as an open question rather than inventing an answer. Honest uncertainty is better than a guess.

---

## Disagreeing with an Issue

If you think an issue is invalid or based on a misunderstanding:
```markdown
>> HUMAN: N/A - this assumes we're doing X, but we're actually doing Y. No issue here.
```

The Discussion Facilitator may briefly explain why they raised it, but will respect your decision.

---

## Tips

- **Be specific**: "Enterprise companies" is less useful than "Mid-market SaaS companies (100-1000 employees) in regulated industries"
- **State your reasoning**: If helpful, briefly explain why - this helps the Author write better content
- **Flag uncertainty**: If you're guessing, say so - the document can acknowledge uncertainty
- **Don't over-engineer**: Answer what's asked. You don't need to write essays.
- **Don't worry about level**: If your answer includes detail that belongs in a downstream stage, just write it. The Author will extract and defer it appropriately.

---

## What Happens Next

Once you've completed your responses:
1. Save the file
2. Tell the orchestrator you're done (e.g., "done", "ready")
3. The orchestrator will process responses and spawn Discussion Facilitators if needed
4. Once all issues are resolved, the Author agent incorporates changes into the document

---

## Example Discussion

```markdown
### PRD-003: Success criteria unclear

**Severity**: HIGH | **Section**: §4 Success Criteria

**Summary**: Success criteria are vague and not measurable.

**Question**: What specific metrics define success for Phase 1?

>> HUMAN: Good question. We're focused on acquisition but I'm not sure what the right numbers are.

>> AGENT:

To define measurable success criteria, I need to understand:

1. What's the primary signal you're optimising for in Phase 1 — user acquisition, engagement, or revenue?
2. Do you have baseline numbers or targets in mind?

>> HUMAN: Acquisition first. We need 100 active users by end of phase.

>> AGENT:

I propose resolving this as follows:

**Proposed PRD change**:
> **Phase 1 Success Criteria**:
> - 100+ monthly active users by phase end
> - 50%+ user retention week-over-week
> - Core flow completion rate > 60%

**Rationale**: These metrics are specific, measurable, and focus on acquisition with basic engagement signals to ensure quality.

If this looks right, confirm and we can mark this resolved.

>> HUMAN: Yes, that works.

>> RESOLVED
```

---

## Context

You're helping improve a document through the Review workflow. Issues represent problems that experts have identified. Discussions drive toward solutions that will be applied by the Author.
