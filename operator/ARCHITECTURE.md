# System-Operator Agent Architecture

Concrete agent design for the System-Operator framework. Defines what agents exist, how they coordinate, what artefacts and state they access, and how they interact with external systems and humans.

**Prerequisite reading:** `OVERVIEW.md` defines the framework's purpose, workflows, response model, and autonomy tiers. This document makes those concrete.

**Relationship to System-Maintainer:** The integration contract (`INTEGRATION.md` at project root) defines the signal formats and artefact ownership between the two frameworks. This architecture references those signals but does not redefine them.

---

## Agent Inventory

Six agents: one dispatcher, four workflow coordinators, one universal agent.

| Agent | Type | Session model | Responsibility |
|-------|------|--------------|----------------|
| **Dispatcher** | Router | Long-running or frequently re-invoked | Classifies incoming signals, routes to workflow agents, tracks artefact versions, manages concurrent signal coordination |
| **Incident Response Agent** | Workflow coordinator | Per-invocation (one per incident) | Follows runbook decision trees: classify severity → mitigate (if urgent) → diagnose → resolve or escalate → verify → report |
| **Deployment Agent** | Workflow coordinator | Per-invocation (one per deployment) | Executes deployments: pre-flight checks → deploy in order → smoke test → monitor → confirm or rollback |
| **Routine Operations Agent** | Workflow coordinator | Per-invocation (one per task) | Runs scheduled maintenance tasks: cert renewal, backup verification, secret rotation, report generation |
| **Capacity Management Agent** | Workflow coordinator | Per-invocation (on threshold signal) | Monitors resources against thresholds, auto-scales within limits, escalates beyond limits, produces capacity forecasts |
| **Escalation Agent** | Universal | Per-invocation (spawned by any workflow agent) | Formats and sends structured notifications/escalations to Human or Maintainer, tracks acknowledgment |

### Design rationale

**One agent per workflow** (not finer-grained reusable agents like "Diagnostician" or "Executor") because the four workflows are genuinely distinct:

- Incident Response is reactive, time-critical, and follows runbook decision trees
- Deployment is request-driven, sequential, and follows a pre-flight/execute/verify pipeline
- Routine Operations is schedule-driven and task-oriented
- Capacity Management is continuous, threshold-driven, and involves trend analysis

Sharing agents between these would add coordination overhead without proportional benefit. Each workflow reads different artefacts and writes different state.

**The Escalation Agent is the only universal agent** because escalation formatting is identical regardless of which workflow triggers it. This mirrors System-Builder's universal agents (Alignment Verifier, Scope Filter) which provide consistent cross-cutting behaviour.

---

## Coordination Model

```
Signal Source
(alerts, deployment requests, schedules, metrics, human directives)
         │
         ▼
   ┌─────────────┐
   │  Dispatcher  │  classifies signal, routes to workflow agent
   └─────┬───────┘
         │
    ┌────┴────────────────────────────┐
    │         │          │            │
    ▼         ▼          ▼            ▼
Incident   Deployment  Routine    Capacity
  Agent      Agent      Agent      Agent
    │         │          │            │
    └─────────┴──────────┴────────────┘
              │
              ▼
       Escalation Agent
    (spawned when needed by
      any workflow agent)
```

### Signal routing

The Dispatcher classifies every incoming signal and routes it to the appropriate workflow agent. It does **not** make autonomy decisions — that's the workflow agent's job.

| Signal type | Route to | Dispatcher action |
|-------------|----------|-------------------|
| Health check failure | Incident Response Agent | Check Incident State for active incident on same component — correlate or create new |
| SLO budget burn | Incident Response Agent | Include current budget status in routing context |
| Metric threshold breach (alerting rule) | Incident Response Agent | Include alert definition from Monitoring Definitions |
| Deployment Request (from Maintainer) | Deployment Agent | Validate request format, acknowledge receipt |
| Scheduled task due | Routine Operations Agent | Include task definition and last run status |
| Capacity threshold approaching | Capacity Management Agent | Include current resource metrics |
| Artefact Update (from Maintainer) | — (Dispatcher handles directly) | Update Artefact State, notify relevant active agents |
| Watch Request (from Maintainer) | — (Dispatcher handles directly) | Add temporary monitoring rule, route alerts per Watch Request instructions |
| Human directive | Appropriate workflow agent | Parse intent, route to matching workflow |
| Human approval | Workflow agent that requested it | Match to pending approval request |
| Unclassifiable signal | Escalation Agent → Human | Include raw signal data for human interpretation |

### Concurrent signal handling

Multiple signals can arrive simultaneously. The Dispatcher handles concurrency by:

1. **Incident correlation** — before spawning a new Incident Response Agent, check Incident State for active incidents on the same component. If found, route the new signal to the existing incident (as additional context, not a new incident).
2. **Deployment locking** — only one deployment can be in progress at a time. New Deployment Requests are queued (acknowledged but not started) until the current deployment completes.
3. **Independence** — Routine Operations and Capacity Management are independent of each other and of Incident/Deployment workflows. They can run concurrently.
4. **Incident blocks deployment** — if an active CRITICAL/HIGH incident exists, new deployments are held (pre-flight check will fail).

---

## Workflow Interaction Diagrams

### Workflow 1: Incident Response

```
Alert Signal
     │
     ▼
┌─────────────┐
│  Dispatcher  │  reads: Monitoring Definitions (alert identification)
│              │  reads: Incident State (active incident check)
└─────┬───────┘
      │
      ▼
┌──────────────────────┐
│ Incident Response    │
│ Agent                │
└──────┬───────────────┘
       │
       ├── Step 1: Receive and log
       │   writes: Incident State (new incident, status: OPEN)
       │
       ├── Step 2: Classify severity
       │   reads: Risk Profile → component criticality
       │   reads: SLO Definitions → which SLOs affected, budget status
       │   reads: Monitoring Definitions → alert severity level
       │   produces: urgency assessment (CRITICAL / HIGH / MEDIUM / LOW)
       │
       ├── Step 3: Mitigate (if CRITICAL or HIGH)
       │   reads: Runbook → immediate mitigation actions for this scenario
       │   acts: restart / scale / failover (per runbook autonomy column)
       │   writes: Incident State (status: MITIGATING, actions taken)
       │   note: mitigation is pre-authorised — no human approval needed
       │
       ├── Step 4: Diagnose
       │   reads: Runbook → diagnosis decision tree for this alert
       │   acts: execute diagnosis steps in order:
       │         1. Check component health (Monitor tool)
       │         2. Check logs for errors (Monitor tool)
       │         3. Check dependency health (Monitor tool)
       │         4. Check recent deployments (Deployment State)
       │         5. Check resource utilisation (Monitor tool)
       │   reads: Component Map → blast radius (what else might be affected)
       │   produces: probable cause, affected components, impact assessment
       │
       ├── Step 5: Resolve or Escalate
       │   ┌─ Runbook has resolution for this cause
       │   │  reads: Runbook → resolution action + autonomy column
       │   │  reads: Risk Profile → component criticality (may override tier upward)
       │   │  ├─ Auto-resolve → execute action, go to Step 6
       │   │  ├─ Assisted → spawn Escalation Agent (approval request to Human), wait
       │   │  │              on approval → execute action, go to Step 6
       │   │  └─ Escalate to Maintainer → spawn Escalation Agent (escalation to Maintainer)
       │   │                              go to Step 7 (report only)
       │   │
       │   ├─ Cause is operational but no runbook coverage
       │   │  spawn Escalation Agent → Human (with full diagnosis)
       │   │
       │   └─ Cause is unclear
       │      spawn Escalation Agent → Human (with all diagnostic data)
       │
       ├── Step 6: Verify
       │   reads: Monitoring Definitions → health check criteria
       │   acts: confirm alert cleared (Monitor tool)
       │   acts: check SLO metrics returning to normal (Monitor tool)
       │   acts: monitor for recurrence (configurable watch period)
       │   writes: Incident State (status: RESOLVED)
       │
       └── Step 7: Report
           writes: Incident Log (permanent record):
                   signal, classification, actions taken, outcome,
                   time to detect, time to mitigate, time to resolve,
                   whether escalation was needed
           writes: Incident State (status: CLOSED)
```

### Workflow 2: Deployment

```
Deployment Request (from Maintainer via Dispatcher)
     │
     ▼
┌──────────────────────┐
│ Deployment Agent     │
└──────┬───────────────┘
       │
       ├── Step 1: Pre-flight checks
       │   reads: Incident State → no active CRITICAL/HIGH incidents?
       │   reads: Deployment State → no deployment in progress?
       │   reads: Deployment Topology → deployment order, prerequisites
       │   reads: Deployment Request → migrations, new env vars, config changes
       │   reads: Security Posture → secret injection requirements
       │   decision:
       │     ├─ All clear → proceed, write Deployment State (status: IN_PROGRESS)
       │     ├─ Active incident → reject request (Deployment Feedback: FAILED, reason: active incident)
       │     └─ Missing prerequisite → reject request (Deployment Feedback: FAILED, reason: prerequisite not met)
       │
       ├── Step 2: Execute deployment
       │   reads: Deployment Topology → component order, rollout strategy per component
       │   for each component (in dependency order):
       │     ├─ Apply database migration if needed (Orchestrator tool)
       │     │  backup before migration (Orchestrator tool)
       │     ├─ Deploy component (Orchestrator tool)
       │     │  follow rollout strategy: rolling / canary / recreate
       │     ├─ Gate on health checks (Monitor tool)
       │     │  reads: Monitoring Definitions → health check endpoint + criteria
       │     └─ Write Deployment State (component version updated)
       │   if any step fails → go to Rollback
       │
       ├── Step 3: Smoke test
       │   reads: Monitoring Definitions → health check endpoints for all deployed components
       │   acts: run health checks (Monitor tool)
       │   acts: verify key endpoints respond (Monitor tool)
       │   if failed → go to Rollback
       │
       ├── Step 4: Monitor (hold period)
       │   reads: Monitoring Definitions → baseline metrics
       │   reads: Deployment Request → specific metrics to watch
       │   reads: SLO Definitions → budget burn rate
       │   acts: compare current metrics against pre-deployment baseline (Monitor tool)
       │   duration: per Deployment Request (default: 15 min standard, 1 hour high-risk)
       │   writes: Deployment State (monitoring phase, metric snapshots)
       │
       ├── Step 5: Confirm or Rollback
       │   ├─ Monitoring clean → confirm
       │   │  writes: Deployment State (status: COMPLETE, versions updated)
       │   │  writes: Deployment Log (permanent record)
       │   │  sends: Deployment Feedback (SUCCESS) → Maintainer (via Escalation Agent)
       │   │
       │   ├─ Minor anomaly (non-SLO-threatening)
       │   │  spawn Escalation Agent → Human (alert, continue monitoring)
       │   │
       │   ├─ Significant anomaly (SLO threatened, not system-down)
       │   │  spawn Escalation Agent → Human (propose rollback, wait for approval)
       │   │  on approval → go to Rollback
       │   │
       │   └─ Critical failure (system down or data at risk)
       │      go to Rollback (auto, Tier 2)
       │      spawn Escalation Agent → Human + Maintainer (immediate notification)
       │
       └── Rollback
           reads: Deployment Topology → rollback procedure
           acts: revert to previous container images (Orchestrator tool)
           if migration was applied:
             ├─ Forward-fix preferred (rollback migrations are risky)
             └─ Escalate to Maintainer if forward-fix needed
           writes: Deployment State (status: ROLLED_BACK)
           writes: Deployment Log (permanent record)
           sends: Deployment Feedback (ROLLED_BACK) → Maintainer (via Escalation Agent)
```

### Workflow 3: Routine Operations

```
Schedule Trigger (via Dispatcher)
     │
     ▼
┌──────────────────────┐
│ Routine Operations   │
│ Agent                │
└──────┬───────────────┘
       │
       ├── Step 1: Identify task
       │   reads: Schedule State → which task triggered, last run status
       │   reads: task-specific artefact:
       │     ├─ Certificate check → Security Posture (cert expiry dates)
       │     ├─ Backup verification → Deployment Topology (backup config)
       │     ├─ Secret rotation → Security Posture (rotation schedules)
       │     ├─ Vulnerability scan → Security Posture (dependencies)
       │     ├─ Database maintenance → Deployment Topology (data stores)
       │     ├─ SLO report → SLO Definitions (targets + current budgets)
       │     └─ Cost report → Monitoring Definitions (cost monitoring)
       │   writes: Schedule State (task status: RUNNING)
       │
       ├── Step 2: Execute task
       │   acts: task-specific execution:
       │     ├─ cert renewal → Certificate tool (check_expiry, renew)
       │     ├─ backup verification → Orchestrator tool (restore test to staging)
       │     ├─ secret rotation → Security tool (rotate_secret)
       │     ├─ vulnerability scan → Security tool (scan_vulnerabilities)
       │     ├─ database maintenance → Orchestrator tool (vacuum, reindex)
       │     ├─ SLO report → Monitor tool (query_metrics) + State tool (read SLO State)
       │     └─ cost report → Monitor tool (query_metrics)
       │   captures: task output / result
       │
       ├── Step 3: Verify
       │   checks task-specific success criteria:
       │     ├─ cert renewed → expiry date extended
       │     ├─ backup verified → restore completed, data integrity confirmed
       │     ├─ secret rotated → new secret active, services restarted with new secret
       │     ├─ vulnerability scan → results parsed, severities assessed
       │     ├─ maintenance → completed within time window, no errors
       │     └─ reports → generated and stored
       │
       └── Step 4: Route result
           ├─ Success → write Schedule State (last result: SUCCESS), log
           │
           ├─ Failure (auto-resolvable task) → retry once
           │  └─ Still fails → spawn Escalation Agent:
           │     ├─ Operational task → escalate to Human
           │     └─ Code-adjacent task (e.g., CVE found) → escalate to Maintainer
           │
           └─ Vulnerability scan results:
              ├─ CRITICAL CVE → spawn Escalation Agent → Maintainer (immediate)
              ├─ HIGH CVE → spawn Escalation Agent → Maintainer (batched daily)
              └─ MEDIUM/LOW CVE → log for next scheduled review
```

### Workflow 4: Capacity Management

```
Capacity Threshold Signal (via Dispatcher)
     │
     ▼
┌──────────────────────┐
│ Capacity Management  │
│ Agent                │
└──────┬───────────────┘
       │
       ├── Step 1: Assess
       │   reads: Deployment Topology → current scaling config (min/max replicas, resource limits)
       │   reads: Scaling State → recent scaling events (avoid thrashing)
       │   reads: SLO Definitions → budget impact of current resource pressure
       │   reads: Monitoring Definitions → metric definition and threshold
       │   acts: query current resource utilisation (Monitor tool)
       │   produces: assessment:
       │     ├─ Within-limits: can auto-scale per Deployment Topology
       │     ├─ Beyond-limits: would exceed configured max replicas or resource bounds
       │     └─ Architectural: capacity problem requires design change, not more resources
       │
       ├── Step 2: Act
       │   ├─ Within-limits (Tier 1: auto-resolve)
       │   │  acts: scale replicas / adjust resources (Orchestrator tool)
       │   │  writes: Scaling State (action taken, new replica count / resource limits)
       │   │  spawn Escalation Agent → Human (post-hoc notification)
       │   │
       │   ├─ Beyond-limits (Tier 3: propose, wait for approval)
       │   │  spawn Escalation Agent → Human:
       │   │    "Component X at max replicas ([N]), still under pressure.
       │   │     Recommend increasing max to [M]. Estimated cost impact: [amount]."
       │   │  on approval → scale (Orchestrator tool)
       │   │  writes: Scaling State
       │   │
       │   └─ Architectural (Tier 4: escalate to Maintainer)
       │      spawn Escalation Agent → Maintainer:
       │        "Component X hitting architectural scaling limit.
       │         Current: [metrics]. Trend: [projection].
       │         Likely needs: [sharding / redesign / new component]."
       │
       ├── Step 3: Verify
       │   acts: confirm scaling took effect (Monitor tool)
       │   acts: check metrics returning to normal range (Monitor tool)
       │   writes: SLO State (budget impact of capacity event)
       │
       └── Step 4: Forecast (periodic, not per-signal)
           reads: Scaling State → historical scaling events and resource trends
           reads: Deployment Topology → current limits
           produces: capacity projection:
             "At current growth rate, [component] will hit max replicas in ~[N] days."
           if projection < threshold (e.g., 30 days):
             spawn Escalation Agent → Human + Maintainer (early warning)
           writes: Capacity Forecasts
```

---

## State Management

### State categories

| Category | Contents | Writers | Readers | Freshness |
|----------|----------|---------|---------|-----------|
| **Incident State** | Active incidents: ID, component, severity, status (OPEN / MITIGATING / RESOLVED / CLOSED), classification, actions taken, timeline | Incident Response Agent | Dispatcher (routing, correlation), all agents (context) | Real-time |
| **Deployment State** | Current versions per component, deployment history, in-progress deployments, rollback availability | Deployment Agent | Incident Agent (deployment correlation), Capacity Agent (version context), Dispatcher (deployment locking) | Near-real-time |
| **SLO State** | Budget status per SLO per window, current burn rate, historical compliance | Capacity Agent, Incident Agent | Dispatcher (severity assessment), all agents (context) | Updated per evaluation cycle |
| **Scaling State** | Current replicas per component, resource allocations, recent scaling events (with timestamps to detect thrashing) | Capacity Agent | Incident Agent (resource context), Deployment Agent (pre-flight) | Near-real-time |
| **Schedule State** | Task list, per-task: last run timestamp, next run, last result, retry count | Routine Operations Agent | Dispatcher (trigger scheduling) | Per minute |
| **Artefact State** | Version/hash per consumed artefact, last update timestamp | Dispatcher (on Artefact Update signal) | All agents (stale artefact detection) | On change |

### Storage abstraction

The framework defines the state schema and access interface, not the storage implementation.

**Interface:**
- `State.read(category)` — returns current state for a category
- `State.read(category, filter)` — returns filtered state (e.g., active incidents for a component)
- `State.write(category, data)` — writes/updates state for a category
- `State.append(category, entry)` — appends to a log-type category

**Implementation is project-specific:**
- Simple systems: structured files in `operations/state/` (like System-Builder's markdown state files)
- Production systems: database or external state store
- The agent prompts reference the abstract interface; the tool implementation provides the concrete binding

### Logs (permanent records)

Separate from state (which is current/mutable), logs are append-only permanent records:

| Log | Contents | Writer | Consumers |
|-----|----------|--------|-----------|
| **Incident Log** | Timestamped record of all incidents, responses, outcomes | Incident Response Agent | Human review, Maintainer (investigation context), trend analysis |
| **Deployment Log** | Record of all deployments, results, rollbacks | Deployment Agent | Maintainer (deployment correlation), human audit |
| **Signal Log** | Every signal received by Dispatcher (raw) | Dispatcher | Debugging, audit, pattern analysis |

Logs live alongside state but are never modified after writing. Consumers read historical logs for context and pattern detection.

---

## Artefact Consumption

Per-agent mapping of which operational artefacts (generated by System-Builder Stage 12) are read and how they're used.

### Dispatcher

| Artefact | How used |
|----------|----------|
| Monitoring Definitions | Match incoming alerts to defined alerting rules. Identify alert severity and component. |
| Component Map | Understand component relationships for signal classification. Identify which component a signal relates to. |
| Incident State | Check for active incidents to correlate new signals rather than creating duplicates. |
| Deployment State | Check for in-progress deployments to enforce deployment locking. |

### Incident Response Agent

| Artefact | How used |
|----------|----------|
| Runbooks | Primary decision driver. Follow diagnosis steps. Look up resolution by cause. Read autonomy column for action authorization. |
| Monitoring Definitions | Understand alert details: what metric triggered, what threshold was breached, what health checks apply. |
| SLO Definitions | Assess SLO impact: which SLOs are affected, current budget status, whether budget exhaustion is imminent. |
| Risk Profile | Determine component criticality. HIGH/CRITICAL components get more aggressive mitigation. Criticality can override runbook autonomy tier upward (never downward). |
| Component Map | Blast radius analysis: what other components depend on the affected one? What data flows through it? |
| Deployment State | Deployment correlation: was anything deployed recently that could explain this? (Timestamps, changed components.) |

### Deployment Agent

| Artefact | How used |
|----------|----------|
| Deployment Topology | Deployment order (dependency sequence). Per-component: rollout strategy, replica configuration, resource profile. Rollback procedure. |
| Monitoring Definitions | Health check endpoints and criteria for deployment gates. Baseline metrics for anomaly detection during monitoring hold period. |
| Security Posture | Secret injection requirements for deployed components. Certificate requirements. |
| Incident State | Pre-flight check: are there active incidents that should block deployment? |
| SLO Definitions | Pre-deployment SLO budget check (don't deploy if budget is near exhaustion — deployment monitoring is unreliable with a depleted budget). |

### Routine Operations Agent

| Artefact | How used |
|----------|----------|
| Security Posture | Certificate expiry dates (what to check), secret rotation schedules (when to rotate, what method), security scanning requirements. |
| SLO Definitions | SLO report generation: targets, current compliance, budget status, trend. |
| Deployment Topology | Backup configuration: what to verify, frequency, verification method. Data store details for database maintenance. |
| Monitoring Definitions | Cost monitoring section: resource baselines, alert thresholds for cost reports. |

### Capacity Management Agent

| Artefact | How used |
|----------|----------|
| Deployment Topology | Scaling limits: min/max replicas, resource bounds (RAM, CPU). These define the auto-scale envelope — scaling within these limits is Tier 1, beyond is Tier 3. |
| Monitoring Definitions | Metric definitions and thresholds that trigger scaling assessment. Queue depth metrics for worker scaling. |
| SLO Definitions | Budget impact assessment: will this capacity event burn SLO budget? Is the capacity issue itself an SLO violation? |

### Escalation Agent

| Artefact | How used |
|----------|----------|
| Component Map | Include affected component context in escalation: what type, what depends on it, data flow impact. |
| Risk Profile | Include component criticality in escalation priority. CRITICAL components get higher escalation urgency. |

---

## External System Integration

System-Operator needs to interact with infrastructure, monitoring systems, and notification channels. The architecture defines abstract tool interfaces — project-specific implementations are injected at instantiation.

### Tool definitions

| Tool | Operations | Used by |
|------|-----------|---------|
| **Monitor** | `query_metrics(component, metric, time_range)` — returns metric values | Dispatcher, Incident, Capacity |
| | `query_logs(component, filter, time_range)` — returns log entries | Incident |
| | `check_health(component)` — returns health check result | Incident, Deployment |
| **Orchestrator** | `restart(component)` — restart component instances | Incident |
| | `scale(component, replicas)` — set replica count | Incident, Capacity |
| | `deploy(component, image, config)` — deploy new version | Deployment |
| | `rollback(component, target_version)` — revert to previous version | Deployment, Incident |
| | `failover(component)` — switch to secondary/standby | Incident |
| | `run_migration(migration, backup_first)` — execute database migration | Deployment |
| **Notifier** | `send_notification(channel, severity, message)` — send to notification channel | Escalation |
| | `request_approval(channel, proposal, options)` — send approval request, await response | Escalation |
| **Scheduler** | `get_schedule()` — return task schedule with due tasks | Dispatcher |
| | `update_schedule(task, next_run, last_result)` — update task timing and result | Routine |
| | `execute_task(task_type, params)` — run a scheduled task | Routine |
| **Certificate** | `check_expiry(domain)` — return certificate expiry date | Routine |
| | `renew(domain)` — trigger certificate renewal | Routine |
| **Security** | `rotate_secret(secret_name, method)` — rotate a secret using defined method | Routine |
| | `scan_vulnerabilities(scope)` — run dependency vulnerability scan | Routine |
| **Read** | Read file contents (artefacts, state, runbooks) | All agents |
| **Write** | Create or overwrite files (state, logs) | Dispatcher, Incident, Deployment, Capacity |
| **Edit** | Modify file sections | (not used — Operator does not modify artefacts) |
| **Glob** | Find files by pattern | Dispatcher, Incident, Deployment, Escalation, Capacity |
| **Grep** | Search file contents | Dispatcher, Incident, Deployment, Escalation, Capacity |
| **Task** | Spawn subagents for parallel or delegated work | Dispatcher, Incident, Deployment, Capacity, Escalation |

### Implementation notes

- Tool implementations are **project-specific**. A Kubernetes-based project implements `Orchestrator.restart` as `kubectl rollout restart`. A Docker Compose project implements it as `docker-compose restart [service]`.
- The agent prompts reference the abstract tool name and operation. The tool implementation is provided at framework instantiation.
- Tools are **the only way agents interact with external systems**. Agents never execute raw shell commands or make direct API calls. This constraint ensures all external interactions are auditable and can be restricted per-agent.
- Each agent's tool access is restricted to only the tools it needs (see Agent Inventory). An Incident Response Agent cannot deploy; a Deployment Agent cannot rotate secrets.

---

## Human Interaction Model

All outbound communication to humans flows through the Escalation Agent. Inbound communication from humans is received by the Dispatcher.

### Outbound formats

#### Post-hoc notification (Tier 1 actions)

For auto-resolved incidents, completed routine tasks, and within-limits scaling. Informational — no response needed.

```
[RESOLVED] [component] — [what happened] — [action taken] — [outcome]
Time: [timestamp]. Duration: [N minutes].
```

#### Approval request (Tier 3 actions)

For non-urgent actions that need human judgment: rollback on non-critical anomalies, resource limit increases, standard deployment execution.

```
[APPROVAL REQUIRED] [workflow] — [component]

Situation: [what's happening — concrete metrics/observations]
Proposed action: [what the agent wants to do]
Risk: [what could go wrong if proposed action is taken]
Alternative: [other options the agent considered]
SLO impact: [current budget status and projected impact]

→ Approve / Reject / Modify
```

#### Escalation to Human (Tier 4 — novel situation)

For situations outside the runbook, unclear causes, or decisions that require human investigation.

```
[ESCALATION] [severity] — [component]

Observed: [what monitoring shows — metrics, alerts, symptoms]
Tried: [what Operator attempted and the result]
Ruled out: [operational causes that were eliminated]
Current state: [system status now — healthy/degraded/down]
Diagnostic data: [relevant logs, metrics timeline, recent events]

Needs: [what human should investigate or decide]
```

#### Escalation to Maintainer

For problems identified as code/design issues. Uses the Escalation signal format defined in `INTEGRATION.md` (at project root).

### Inbound handling

| Inbound signal | Source | Dispatcher action |
|---------------|--------|-------------------|
| Approval response (approve/reject/modify) | Human | Route to the workflow agent that requested it, matched by request ID |
| Directive ("scale X to N", "restart Y") | Human | Parse intent, route to appropriate workflow agent with directive context |
| Override ("ignore alert Z", "hold deployment") | Human | Apply override to Dispatcher's routing rules (temporary) |
| Deployment Request | Maintainer | Route to Deployment Agent |
| Watch Request | Maintainer | Add temporary monitoring rule to Dispatcher's signal processing |
| Artefact Update | Maintainer | Update Artefact State, notify active agents that consume the updated artefact |

---

## Escalation Paths

Each workflow has defined paths for escalating beyond what the workflow agent can handle.

### Incident Response escalation

| Situation | Escalate to | Context included |
|-----------|-------------|------------------|
| Runbook resolution says "Assisted" | Human (approval request) | Diagnosis, proposed action, risk, alternatives |
| Runbook resolution says "Escalate to Maintainer" | Maintainer (Escalation signal) | Observations, actions tried, probable cause, current mitigation |
| No matching runbook scenario | Human (escalation) | Full diagnosis, what was tried, what's unknown |
| Cause is unclear | Human (escalation) | All diagnostic data, candidate causes |
| Mitigation failed (system still down after restart/scale/failover) | Human (CRITICAL escalation) | What mitigation was attempted, current state |

### Deployment escalation

| Situation | Escalate to | Context included |
|-----------|-------------|------------------|
| Pre-flight check fails | Maintainer (Deployment Feedback: FAILED) | Which check failed, why, current system state |
| Health check fails after deploy | Human (propose rollback) | Which checks failing, metric values, deployment details |
| Critical failure during deploy | Human + Maintainer (CRITICAL notification) | Auto-rollback performed, what went wrong, current state |
| Migration rollback needed | Maintainer (Deployment Feedback: ROLLED_BACK) | Forward-fix needed, migration details |

### Routine Operations escalation

| Situation | Escalate to | Context included |
|-----------|-------------|------------------|
| Operational task failed after retry | Human | Task details, failure reason, retry results |
| CRITICAL CVE found | Maintainer (immediate) | CVE details, affected dependencies, severity assessment |
| Cert renewal failed | Human (HIGH priority) | Which cert, expiry date, renewal error |
| Backup verification failed | Human (CRITICAL) | Which data store, what failed, last successful backup |

### Capacity Management escalation

| Situation | Escalate to | Context included |
|-----------|-------------|------------------|
| Beyond configured limits | Human (approval request) | Current metrics, recommended new limits, cost projection |
| Architectural scaling limit | Maintainer | Current metrics, trend projection, suggested architectural change |
| Capacity forecast warning | Human + Maintainer | Projection data, timeline, recommended action |

---

## Autonomy Decision Model

How workflow agents determine the autonomy tier for a given action.

### Decision process

```
1. Does the Runbook specify an autonomy level for this resolution?
   ├─ Yes → use the Runbook's autonomy column as the STARTING tier
   └─ No → default to Tier 3 (propose, wait for approval)

2. Check component criticality (Risk Profile):
   ├─ CRITICAL component → tier cannot be lower than Tier 2
   ├─ HIGH component → tier cannot be lower than Tier 2 for data-affecting actions
   └─ MEDIUM/LOW → no override

3. Check current SLO budget:
   ├─ Budget < 20% remaining → escalate one tier (urgency increases)
   └─ Budget healthy → no override

4. Final tier = max(runbook tier, criticality override, SLO override)
```

### Key principle

**Tier can only be overridden upward (more cautious), never downward.** A runbook saying "Auto-resolve" for a CRITICAL component gets overridden to at minimum Tier 2. A runbook saying "Propose, human approves" is never overridden down to "Auto-resolve" regardless of component criticality.

### Tier-to-action mapping

| Tier | Agent action | Human involvement |
|------|-------------|-------------------|
| **1** (Auto-resolve) | Execute immediately. Log action. Send post-hoc notification. | None during action. Notification after. |
| **2** (Auto-resolve + alert) | Execute immediately (time-critical mitigation). Send immediate notification. | Notified immediately. Can countermand. |
| **3** (Propose, wait) | Format proposal with situation, action, risk, alternatives. Wait for human response. | Must approve, reject, or modify before agent acts. |
| **4** (Escalate) | Format escalation with full diagnostic context. Do not attempt resolution. | Human (or Maintainer) takes ownership of resolution. |

---

## Instantiation

What a project provides to use the System-Operator framework.

### Required configuration

| Configuration | Purpose | Example |
|--------------|---------|---------|
| **Artefact paths** | Where Stage 12 outputs live | `maintenance/`, `operations/` |
| **Tool implementations** | Project-specific bindings for Monitor, Orchestrator, Notifier, etc. | K8s kubectl wrapper, Datadog API client, Slack webhook |
| **State store** | Where operational state is read/written | File path, database connection, external state service |
| **Notification channels** | How to reach humans and Maintainer | Slack channel, PagerDuty, email, Maintainer signal endpoint |
| **Schedule configuration** | Task schedules for routine operations | Task list with frequencies (from Security Posture and Deployment Topology) |

### Optional configuration

| Configuration | Purpose | Default |
|--------------|---------|---------|
| **Deployment hold period** | How long to monitor after deployment | 15 min (standard), 1 hour (high-risk) |
| **Scaling thrash protection** | Minimum interval between scaling events | 5 minutes |
| **Alert correlation window** | Time window for grouping related alerts | 5 minutes |
| **Capacity forecast threshold** | Days ahead to warn about capacity limits | 30 days |
| **Acknowledgment timeout** | How long to wait for signal acknowledgment | 5 min (HIGH+), 1 hour (others) |

### Instantiation checklist

1. Artefacts exist (Stage 12 has run, `maintenance/` and `operations/` populated)
2. Tool implementations provided for all tools used by each agent
3. State store accessible and writable
4. Notification channels tested (can reach humans)
5. Maintainer signal endpoint configured (if Maintainer is deployed)
6. Schedule configuration derived from Security Posture (rotation schedules) and Deployment Topology (backup schedules)

---

## Resolved Design Decisions

These were open questions during initial design. Resolved decisions are recorded in OVERVIEW.md § Design Decisions. Summary of decisions relevant to the architecture:

- **Multi-environment**: Separate Operator instance per environment. Shared agent prompts, different artefact paths/tool implementations/state stores.
- **Alert deduplication**: Dispatcher uses Component Map dependency graph for root-cause-first grouping. Correlates dependent component alerts into the root cause incident. **[REFINE DURING IMPLEMENTATION]** — edge cases around non-dependency correlations and cascading failure ordering.
- **Observability bootstrapping**: First deployment enters baseline collection phase with absolute-threshold-only alerting. Normal alerting activates after configurable stable period (default: 7 days). **[REFINE DURING IMPLEMENTATION]** — definition of "stable", transition mechanism.
- **Runbook evolution**: Operator records novel resolutions in Incident Log → signals Maintainer "runbook gap" → Maintainer authors new section → Artefact Update back to Operator.
- **Cross-system**: One Operator per system. Independent artefacts, state, and tools.
- **State persistence**: Abstract interface, project-specific storage (files for simple, database for production).

---

## Open Questions

1. **Capacity forecast accuracy** — what data is needed for meaningful capacity projections? Simple linear extrapolation is often misleading. May need seasonality awareness, event correlation, or explicit "this is just a trend line" disclaimers. This is a stretch goal — defer until someone implements capacity forecasting.
