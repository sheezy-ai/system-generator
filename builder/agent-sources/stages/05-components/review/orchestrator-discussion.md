# Component Spec Review: Discussion Phase

Handles Step 5: Single iteration of discussion processing. Router invokes this repeatedly until all issues are resolved.

---

## Orchestrator Boundaries

These are instructions for the router to follow directly. The router:
- Spawns discussion facilitator agents using the Task tool (in FOREGROUND, not background)
- Passes file PATHS to agents, not file contents
- Does NOT read agent prompt files — agents read their own instructions
- Handles all human communication (not delegated)

---

## State File

**Path**: `{{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/workflow-state.md`

Current step should be 5 when this phase runs.

---

## Agent Prompt Location

- Discussion Facilitator: `{{AGENTS_PATH}}/universal-agents/discussion-facilitator.md`

---

## Single Iteration Model

Each invocation processes one round of the discussion:
1. Mark resolutions from human responses
2. Spawn facilitators for issues needing agent response
3. Return status to router

Router handles human communication and re-invokes as needed.

---

## Discussion Markers

- `>> HUMAN:` — Human response marker
- `>> AGENT:` — Agent response marker
- `>> RESOLVED` — Discussion complete (added by this orchestrator)

---

## Iteration Steps

### Step 1: Read Issues File

Read `03-issues-discussion.md` and categorize each issue:

For each issue, check the discussion thread:

**Category A — Needs resolution marking:**
- Last entry is `>> HUMAN:` after `>> AGENT:`
- Human response indicates closure (see Resolution Indicators below)
- Action: Mark `>> RESOLVED`

**Category B — Needs agent response:**
- Has `>> HUMAN:` without subsequent `>> AGENT:`
- Human response is a question, request, or pushback (see Continue Indicators below)
- Action: Add to facilitator batch

**Category C — Already resolved:**
- Has `>> RESOLVED` marker
- Action: Skip

**Category D — Awaiting human (first response):**
- Has `>> HUMAN:` placeholder but no actual response content yet
- Action: Skip (will be in issues_awaiting_human)

### Step 2: Mark Resolutions

For each Category A issue:
- Add `>> RESOLVED` marker after the human's closing response

### Step 3: Spawn Discussion Facilitators

If Category B issues exist:

1. **Group into batches**:
   - Group by spec section or concern
   - Aim for ~5-7 issues per batch maximum
   - If fewer than 4 issues, use fewer batches

2. **Spawn Discussion Facilitator agents** using Task tool (one per batch, in parallel):
   ```
   Follow the instructions in: {{AGENTS_PATH}}/universal-agents/discussion-facilitator.md

   Context documents:
   - Spec: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-[build|ops]/00-spec.md
   - Architecture: {{SYSTEM_DESIGN_PATH}}/system-design/04-architecture/architecture.md
   - Foundations: {{SYSTEM_DESIGN_PATH}}/system-design/03-foundations/foundations.md
   - PRD: {{SYSTEM_DESIGN_PATH}}/system-design/02-prd/prd.md

   Issues file: {{SYSTEM_DESIGN_PATH}}/system-design/05-components/versions/[component]/round-[N]-[build|ops]/03-issues-discussion.md
   Issues: [ID1, ID2, ID3, ...]
   ```

3. **Wait for all agents to complete**

4. **Verify responses written**:
   - Count `>> AGENT:` markers for the assigned issues
   - If any missing, re-invoke facilitators for missing issues only
   - Repeat until all assigned issues have responses

### Step 4: Count Status

After processing:
- Count issues with `>> RESOLVED`
- Count issues still unresolved (no `>> RESOLVED` marker)
- Identify issues awaiting human response

---

## Resolution Indicators

Human response after `>> AGENT:` that signals closure:
- Agreement: "Yes", "Agreed", "That works", "Fine", "OK", "Sounds good"
- Dismissal: "Not a concern", "Not relevant", "Ignore", "Skip", "N/A"
- Acceptance: "Makes sense", "Fair enough", "Understood", "Got it"

Mark these `>> RESOLVED`.

---

## Continue Discussion Indicators

Do NOT mark resolved:
- Questions: "?", "What about", "How would", "Can you", "Why"
- Requests: "Please", "Can you", "I'd like", "Show me", "Explain"
- Pushback: "I disagree", "That's not right", "But what about", "However"
- Incomplete: Empty response, just whitespace

These need agent response.

---

## Return to Router

After iteration completes, return structured data:

**If unresolved issues remain:**
```
{
  status: "NEEDS_HUMAN_RESPONSE",
  newly_resolved: [count of issues marked resolved this iteration],
  agent_responses_added: [count of agent responses added],
  issues_awaiting_human: ["SPEC-001", "SPEC-003", ...]
}
```

**If all issues resolved:**
```
{
  status: "ALL_RESOLVED",
  total_resolved: [total count]
}
```

Do NOT present anything to human — router handles all human communication.

---

<!-- INJECT: tool-restrictions -->
