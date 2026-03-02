# Integration Contract: System-Maintainer ↔ System-Operator

Defines the signals, handoffs, and shared state between System-Maintainer and System-Operator. Both frameworks reference this document as the authoritative definition of their interface.

**Location note:** Lives at the System-Generator project root as a shared contract between System-Operator and System-Maintainer.

---

## Principles

1. **Signals are structured documents** — not free-text. Each signal type has a defined format so receiving agents can parse without interpretation.
2. **Context travels with signals** — the sender includes everything the receiver needs to act without going back to ask. Redundancy is acceptable; missing context is not.
3. **Every signal gets a response** — acknowledgment (received), resolution (handled), or rejection (can't/won't handle, with reason).
4. **Transport is implementation-specific** — signals could be files in a repo, messages in a queue, or agent-to-agent handoffs. This contract defines content, not delivery.

---

## Signal Types

### Maintainer → Operator

| Signal | When | Urgency |
|--------|------|---------|
| Deployment Request | Maintainer has a tested change ready to deploy | Planned (standard) or High (hotfix) |
| Watch Request | Maintainer wants specific post-change monitoring | Medium |
| Artefact Update | Maintainer has updated operational artefacts | Low |

### Operator → Maintainer

| Signal | When | Urgency |
|--------|------|---------|
| Escalation | Operator identified a problem requiring code/design change | Varies (carried from original alert) |
| Deployment Feedback | Deployment completed, failed, or was rolled back | High (failure) or Low (success) |

---

## Signal Formats

### Deployment Request (Maintainer → Operator)

Sent when Maintainer's workflow reaches the Deploy step (Patch step 5, Extend step 9, Evolve step 6).

```markdown
# Deployment Request

**ID**: DR-[timestamp]-[short-hash]
**Created**: [datetime]
**Priority**: standard | hotfix
**Source workflow**: Patch | Extend | Evolve
**Change reference**: [link to Maintainer's change record]

## What changed

| Component | Change summary | Risk level |
|-----------|---------------|------------|
| consumer-api | New endpoint: GET /events/nearby | MEDIUM |
| geocoding-module | Updated geocoding radius logic | LOW |

## Deployment notes

- Database migration required: Yes / No
  - If yes: migration description and rollback strategy
- New environment variables: [list, if any]
- Configuration changes: [list, if any]

## Test results

- Unit tests: PASS ([N] tests)
- Integration tests: PASS ([N] tests)
- Contract tests: PASS ([N] contracts verified)

## Post-deployment monitoring

Watch these metrics specifically:
- [metric name] — expected: [description], regression looks like: [description]

## Rollback criteria

Auto-rollback if:
- [specific condition]

Human-approval rollback if:
- [specific condition]
```

### Escalation (Operator → Maintainer)

Sent when Operator classifies a problem as code/design (Response Model: "Escalate to Maintainer").

```markdown
# Operator Escalation

**ID**: ESC-[timestamp]-[short-hash]
**Created**: [datetime]
**Severity**: CRITICAL | HIGH | MEDIUM | LOW
**Suggested signal type**: Bug | Performance regression | Dependency vulnerability | Capacity limit

## What was observed

**Alert**: [alert name from monitoring definitions]
**First detected**: [datetime]
**Duration**: [how long the issue has persisted]
**Affected component(s)**: [list]
**User impact**: [description]

## Metrics

| Metric | Expected | Actual | Since |
|--------|----------|--------|-------|
| [metric] | [value] | [value] | [datetime] |

## What Operator tried

| Action | Result | Time |
|--------|--------|------|
| Restart consumer-api pods | Error persisted | [datetime] |
| Scaled to 4 replicas | No improvement | [datetime] |

## Operator's assessment

**Probable cause**: [why this is code/design, not operational]
**Ruled out**: [operational causes that were eliminated]

## Current state

**Mitigation in place**: Yes / No — [description if yes]
**System status**: Healthy | Degraded | Partially down | Down
**SLO impact**: [which SLOs affected, budget burn rate]

## Context

- Recent deployments: [last 24 hours]
- Related incidents: [links to incident log entries]
```

### Deployment Feedback (Operator → Maintainer)

Sent after a deployment completes.

```markdown
# Deployment Feedback

**Deployment request**: [DR-xxx]
**Status**: SUCCESS | ROLLED_BACK | FAILED
**Completed**: [datetime]
**Duration**: [time from start to completion]

## If ROLLED_BACK or FAILED:

**Trigger**: [what caused it — metric, health check, pre-flight failure]
**Rollback scope**: [which components]
**Method**: auto-rollback | human-approved | pre-flight rejection
**Current state**: [system status after rollback]

| Metric | Expected | Actual |
|--------|----------|--------|
| [metric] | [value] | [value] |

**Action needed**: [what Maintainer should do]
```

### Watch Request (Maintainer → Operator)

Sent after deployment when Maintainer wants extended monitoring beyond the standard hold period.

```markdown
# Watch Request

**ID**: WR-[timestamp]-[short-hash]
**Related deployment**: [DR-xxx]
**Duration**: [e.g., "48 hours", "until next SLO report"]

## What to watch

| Metric / behaviour | Normal range | Alert if | Component |
|-------------------|-------------|----------|-----------|
| [metric] | [range] | [condition] | [component] |

## Context

[Why extra monitoring is needed]

## On alert

- Notify Maintainer directly (not just standard channel)
- [Any specific data capture instructions]
```

### Artefact Update (Maintainer → Operator)

Sent when Maintainer updates operational artefacts as part of an Extend or Evolve workflow.

```markdown
# Artefact Update

**ID**: AU-[timestamp]-[short-hash]
**Source workflow**: [change reference]

## Updated artefacts

| Artefact | What changed | Action required |
|----------|-------------|----------------|
| runbooks/consumer-api.md | New section §4: Rate limit exceeded | New scenario to handle |
| monitoring.md | New alert: ConsumerAPIRateLimited | Configure alerting rule |
| slos.md | SLO-002 target: p95 < 150ms (was 200ms) | Update tracking threshold |
```

---

## Artefact Ownership

Both frameworks access the project's operational artefacts. Ownership determines who writes.

| Artefact | Owner (writes) | Reader | Update notification |
|----------|---------------|--------|-------------------|
| Component Map | Maintainer | Operator | Artefact Update signal |
| Contract Definitions | Maintainer | — | Internal to Maintainer |
| Risk Profile | Maintainer | Operator | Artefact Update signal |
| Spec-to-Code Traceability | Maintainer | — | Internal to Maintainer |
| SLO Definitions | Maintainer | Operator | Artefact Update signal |
| Monitoring Definitions | Maintainer | Operator | Artefact Update signal |
| Deployment Topology | Maintainer | Operator | Artefact Update signal |
| Runbooks | Maintainer | Operator | Artefact Update signal |
| Security Posture | Maintainer | Operator | Artefact Update signal |
| Incident Log | Operator | Maintainer | Read on demand (investigation context) |
| Deployment Log | Operator | Maintainer | Read on demand (deployment correlation) |
| SLO Reports | Operator | Human, Maintainer | Periodic |
| Cost Reports | Operator | Human | Periodic |
| Capacity Forecasts | Operator | Human, Maintainer | On generation |

**Key rule:** Operator never modifies design-derived artefacts (top 9 rows). If Operator identifies a gap (e.g., runbook missing a scenario), it escalates to Maintainer, which updates and sends an Artefact Update signal.

**Concurrent access:** Only one framework writes to any given artefact. No locking needed — ownership is exclusive.

---

## Signal Lifecycle

```
Created → Acknowledged → [In Progress] → Resolved
```

| State | Meaning | Who sets |
|-------|---------|---------|
| Created | Signal sent | Sender |
| Acknowledged | Receiver has accepted | Receiver |
| In Progress | Receiver is working on it | Receiver |
| Resolved | Complete, outcome recorded | Receiver |

**Acknowledgment timeout:** If no acknowledgment within a configurable window (e.g., 5 minutes for HIGH+, 1 hour for others), alert human.

**Resolution outcomes:**
- **Completed** — requested action performed successfully
- **Rejected** — signal invalid or unnecessary (with explanation)
- **Escalated** — receiver couldn't handle, forwarded (to human or back to sender)

---

## Error Handling

| Scenario | Response |
|----------|----------|
| Deployment Request received but system unhealthy | Operator rejects with pre-flight failure details. Maintainer re-evaluates timing. |
| Escalation received but Maintainer mid-workflow on same component | Maintainer acknowledges, queues for current workflow completion. |
| Deployment Request references unknown artefact version | Operator rejects — "artefact mismatch". Maintainer resends Artefact Update first. |
| Rollback fails | Operator escalates to human immediately (CRITICAL). |
| Acknowledgment times out | Alert human. Do not auto-retry. |

---

## Open Questions

1. **Signal transport** — files in a shared repo? Message queue? Direct agent invocation? Format is defined here; transport needs implementation design.

2. **Signal retention** — how long are resolved signals kept? Historical escalation data is valuable for Maintainer's investigation agent (pattern detection).

3. **Batching** — can Maintainer batch multiple components into one Deployment Request? The format supports it, but Operator's rollback logic may prefer atomic single-component deployments.

4. **Format versioning** — if signal formats evolve, how is backward compatibility handled?
