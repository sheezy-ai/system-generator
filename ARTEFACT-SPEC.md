# Project-Specific Artefact Specification

Defines what System-Builder must generate for System-Maintainer and System-Operator to function. These artefacts are the contract between the three frameworks.

**Principle:** Most of this information already exists in System-Builder's design documents — it's embedded in prose across PRD, Architecture, Component Specs, etc. These artefacts extract and restructure it into formats that maintenance and operations agents can consume directly, without reading and interpreting full design documents.

**Location in project:**

```
<project>/
├── system-design/            # Existing System-Builder output
├── src/                      # Existing System-Builder output
├── maintenance/              # NEW — consumed by System-Maintainer agents
│   ├── component-map.md
│   ├── risk-profile.md
│   ├── traceability.md
│   └── contracts/
│       ├── <component-a>.md
│       └── <component-b>.md
└── operations/               # NEW — consumed by System-Operator agents
    ├── slos.md
    ├── monitoring.md
    ├── deployment.md
    ├── security-posture.md
    └── runbooks/
        ├── <component-a>.md
        └── <component-b>.md
```

**Format:** Markdown with structured sections, consistent with System-Builder's existing outputs. Machine-parseable where needed (tables, consistent heading patterns, explicit field labels) but human-readable for review.

---

## Artefact Generation Pipeline

Each artefact is generated at a specific point in System-Builder's pipeline, from the design documents available at that stage.

| Artefact | Primary source(s) | Generated at | Consumer |
|----------|-------------------|-------------|----------|
| Component Map | Architecture, Component Specs | After Stage 05 (Components) | Both |
| Contract Definitions | Component Specs, Cross-Cutting Spec | After Stage 05 | Maintainer |
| Risk Profile | PRD, Architecture, Component Specs | After Stage 05 | Both |
| Spec-to-Code Traceability | Component Specs, Build output | After Stage 08 (Build) | Maintainer |
| SLO Definitions | PRD, Foundations | After Stage 03 (Foundations), refined after Stage 05 | Operator |
| Monitoring Definitions | PRD, Architecture, Component Specs, Foundations | After Stage 08 | Operator |
| Deployment Topology | Architecture, Foundations, Build output | After Stage 08 | Operator |
| Runbooks | Component Specs, Architecture | After Stage 08 | Operator |
| Security Posture | Foundations, Component Specs | After Stage 05, refined after Stage 08 | Operator |

**Incremental generation:** Some artefacts can be partially generated early (e.g., SLOs from PRD) and refined as later stages complete. The specification below notes the minimum viable stage for each.

---

## Maintenance Artefacts

### 1. Component Map

**Purpose:** Enables impact analysis. When something changes, agents need to know what depends on it.

**Source:** Architecture doc (component decomposition, data flows) + Component Specs (interface definitions).

**Contents:**

```markdown
# Component Map

## Components

| Component | Type | Description | Critical path? |
|-----------|------|-------------|---------------|
| consumer-api | Service | Public-facing REST API | Yes |
| data-processing-job | Worker | Async event processing | Yes |
| admin-api | Service | Internal admin interface | No |

## Dependencies

Directed graph: A → B means A depends on B (A calls B, A reads B's data, A consumes B's events).

| From | To | Dependency type | Sync/Async | Failure impact |
|------|----|----------------|------------|----------------|
| consumer-api | data-processing-job | Event publish | Async | Degraded (events queued) |
| consumer-api | geocoding-module | Function call | Sync | Feature unavailable |
| admin-api | consumer-api | Shared database | Data | Read-after-write risk |

## Data Flows

| Flow | Source | Destination | Data | Trigger |
|------|--------|-------------|------|---------|
| Event ingestion | Email | data-processing-job | Raw event data | New email received |
| Event publication | data-processing-job | consumer-api DB | Processed event | Processing complete |

## Deployment Groups

Components that must be deployed together or in a specific order.

| Group | Components | Ordering constraint |
|-------|-----------|-------------------|
| API tier | consumer-api, admin-api | None (independent) |
| Processing | data-processing-job | After API tier (needs schema) |
```

**Key design decisions:**
- Dependency types are explicit (function call, event, shared data, shared infrastructure) because the failure modes differ
- "Failure impact" is from the perspective of the dependent component — what happens to A if B is down
- Critical path marking identifies components whose failure affects core user-facing functionality

---

### 2. Contract Definitions

**Purpose:** Enables automated contract testing and consistency verification. When a component changes, agents can verify it still honours its contracts.

**One file per component** in `maintenance/contracts/`.

**Source:** Component Specs (interface sections) + Cross-Cutting Spec.

**Contents:**

```markdown
# Contracts: [Component Name]

## Provided interfaces

### [Interface name, e.g., REST API, Event schema, Shared library]

**Consumers:** [list of components that depend on this interface]

#### Endpoints / Events / Functions

| ID | Signature | Request summary | Response summary | Error cases |
|----|-----------|----------------|-----------------|-------------|
| EP-001 | GET /api/events | Filters: date, location, category | Paginated event list | 400 (invalid filter), 404 (no results) |
| EP-002 | POST /api/events/{id}/rsvp | User ID, event ID | Confirmation | 404 (event), 409 (already RSVPd), 422 (capacity) |

#### Data schemas

| Schema | Fields summary | Validation rules summary | Used by |
|--------|---------------|------------------------|---------|
| Event | id, title, date, location, category, status | title: required, max 200; date: future only | EP-001, EP-002, EV-001 |

#### Behavioural contracts

Invariants that must hold regardless of implementation:

- Pagination returns consistent results across pages (no duplicates, no gaps for stable data)
- RSVP is idempotent for the same user+event
- Deleted events return 404, never 200 with stale data

## Consumed interfaces

| Provider | Interface | What this component uses |
|----------|-----------|------------------------|
| geocoding-module | Geocode function | Forward geocoding for event locations |
| shared-llm-client | LLM API | Text extraction and paraphrasing |
```

**Key design decisions:**
- Contracts are defined from the provider's perspective (what I guarantee) with consumer list (who relies on this)
- Behavioural contracts capture invariants that tests should verify — not just schema shape but semantic expectations
- Consumed interfaces track what this component depends on, enabling reverse-dependency lookup
- Summaries rather than full schemas — agents can read the full component spec if they need complete detail. This is the quick-reference for impact analysis.

---

### 3. Risk Profile

**Purpose:** Informs change classification and autonomy tier decisions. Agents use this to assess blast radius and determine how much human involvement a change needs.

**Source:** PRD (user impact, business criticality) + Architecture (failure modes, dependencies) + Component Specs (data sensitivity, error handling).

**Contents:**

```markdown
# Risk Profile

## Component Criticality

| Component | User-facing? | Data integrity? | Financial? | Availability target | Criticality |
|-----------|-------------|----------------|-----------|-------------------|-------------|
| consumer-api | Yes (primary) | Read-only | No | 99.9% | HIGH |
| data-processing-job | Indirect | Write (source of truth) | No | 99.5% | HIGH |
| admin-api | No (internal) | Read-write | No | 99% | MEDIUM |
| geocoding-module | Indirect | No | Cost (API calls) | Best-effort | LOW |

## Failure Modes

| Component | Failure mode | User impact | Data impact | Recovery |
|-----------|-------------|------------|-------------|----------|
| consumer-api | Service down | Full outage for consumers | None (stateless) | Restart / scale |
| data-processing-job | Processing stall | Events not updated | Queue backlog (recoverable) | Restart + drain queue |
| data-processing-job | Bad extraction | Incorrect event data published | Corrupted records | Reprocess from source |
| geocoding-module | API limit exceeded | No location data on new events | None | Wait for limit reset |

## Sensitive Data

| Data type | Location(s) | Classification | Encryption | Access control |
|-----------|-------------|---------------|-----------|----------------|
| User email addresses | consumer-api DB | PII | At rest + in transit | API auth required |
| Event source emails | data-processing-job storage | Business confidential | At rest | Admin only |

## Change Risk Heuristics

Guidelines for agents classifying change risk:

| Change touches... | Default risk | Autonomy ceiling |
|-------------------|-------------|-----------------|
| Consumer-facing endpoints | HIGH | Tier 3 (human chooses direction) |
| Data write paths | HIGH | Tier 3 |
| Authentication / authorisation | CRITICAL | Tier 4 (full human engagement) |
| Internal-only admin endpoints | MEDIUM | Tier 2 (propose, wait for approval) |
| Logging, metrics, non-functional | LOW | Tier 1 (auto-apply, notify) |
| Dependencies (shared libraries) | MEDIUM+ | Tier 2 minimum |
```

**Key design decisions:**
- Criticality is a composite assessment, not a single dimension — user-facing, data integrity, and financial concerns are separate because they inform different risk responses
- Failure modes are concrete scenarios, not abstract ratings — agents need to understand what actually happens, not just "this is HIGH risk"
- Change risk heuristics give agents starting-point guidance for autonomy tier classification. Investigation agents can override with justification.

---

### 4. Spec-to-Code Traceability

**Purpose:** Enables investigation agents to navigate from design intent to implementation. When a bug is reported, agents can trace from the component spec to the relevant code.

**Source:** Generated during or after build stage by comparing spec structure to code structure.

**Contents:**

```markdown
# Spec-to-Code Traceability

## consumer-api

| Spec section | Spec reference | Code location | Test location |
|-------------|---------------|---------------|---------------|
| REST API: GET /events | consumer-api.md §3.1 | src/consumer-api/views/events.py:EventListView | tests/consumer-api/test_events.py:TestEventList |
| REST API: POST /events/{id}/rsvp | consumer-api.md §3.2 | src/consumer-api/views/rsvp.py:RSVPView | tests/consumer-api/test_rsvp.py:TestRSVP |
| Data model: Event | consumer-api.md §2.1 | src/consumer-api/models/event.py:Event | tests/consumer-api/test_models.py:TestEventModel |
| Error handling: Rate limiting | consumer-api.md §5.1 | src/consumer-api/middleware/rate_limit.py | tests/consumer-api/test_rate_limit.py |
| Auth: JWT validation | cross-cutting.md §2.1 | src/shared/auth/jwt.py:validate_token | tests/shared/test_auth.py:TestJWTValidation |

## data-processing-job

| Spec section | Spec reference | Code location | Test location |
|-------------|---------------|---------------|---------------|
| ... | ... | ... | ... |
```

**Key design decisions:**
- References use section numbers from component specs, enabling direct lookup
- Test locations are included — investigation agents checking a bug should see both implementation and existing test coverage
- Cross-cutting spec references are included where shared code implements cross-cutting concerns
- This artefact becomes stale as code evolves. System-Maintainer's consistency verification should flag drift. Regeneration is cheap (can be automated).

---

## Operations Artefacts

### 5. SLO Definitions

**Purpose:** Defines measurable service-level objectives. System-Operator uses these for alerting and reporting. System-Maintainer uses them to assess whether a change might violate SLOs.

**Source:** PRD (user expectations, business requirements) + Foundations (technology constraints).

**Contents:**

```markdown
# Service Level Objectives

## Derived from PRD requirements

| ID | Component | Metric | Target | Measurement | PRD reference |
|----|-----------|--------|--------|-------------|---------------|
| SLO-001 | consumer-api | Availability | 99.9% monthly | Successful responses / total requests | PRD §4.1 |
| SLO-002 | consumer-api | Response time (p95) | < 200ms | Measured at load balancer | PRD §4.1 |
| SLO-003 | consumer-api | Response time (p99) | < 500ms | Measured at load balancer | PRD §4.1 |
| SLO-004 | data-processing-job | Processing latency | < 5 min from receipt | Time from email receipt to event available | PRD §3.2 |
| SLO-005 | data-processing-job | Processing accuracy | > 95% correct extraction | Verified by quality gate | PRD §3.2 |

## Error budgets

| SLO | Budget (monthly) | Current burn rate | Alert threshold |
|-----|-----------------|-------------------|-----------------|
| SLO-001 | 43.2 min downtime | (runtime value) | 50% budget in < 50% of window |
| SLO-002 | 5% of requests > 200ms | (runtime value) | Sustained p95 > 180ms |

## Dependency SLOs

External services this system depends on and their expected reliability:

| External dependency | Expected availability | Degradation strategy |
|--------------------|----------------------|---------------------|
| Email provider (IMAP) | 99.5% | Queue and retry |
| Geocoding API | 99% | Cache + fallback to approximate |
| LLM API | 99% | Queue and retry, degrade gracefully |
```

**Key design decisions:**
- Every SLO traces back to a PRD requirement — no invented targets
- Error budgets make SLOs actionable — agents can calculate whether a proposed change puts the budget at risk
- Dependency SLOs acknowledge that this system's reliability depends on external services, with explicit degradation strategies

---

### 6. Monitoring Definitions

**Purpose:** Defines what to monitor, how to alert, and what dashboards to create. Generated during build, consumed by System-Operator.

**Source:** SLOs + Architecture (component topology) + Component Specs (error modes) + Foundations (observability patterns).

**Contents:**

```markdown
# Monitoring Definitions

## Health checks

| Component | Endpoint / check | Healthy criteria | Check interval | Failure action |
|-----------|-----------------|-----------------|----------------|----------------|
| consumer-api | GET /health | 200 + DB connected + cache reachable | 10s | Restart after 3 failures |
| data-processing-job | Queue consumer heartbeat | Heartbeat within last 60s | 30s | Alert + restart |
| admin-api | GET /health | 200 + DB connected | 30s | Alert (non-critical) |

## Key metrics

| Metric | Component | Type | Labels | Alert condition |
|--------|-----------|------|--------|----------------|
| http_requests_total | consumer-api | Counter | method, path, status | Error rate > 5% sustained 5m |
| http_request_duration_seconds | consumer-api | Histogram | method, path | p95 > 200ms sustained 5m |
| events_processed_total | data-processing-job | Counter | status (success/fail) | Failure rate > 10% sustained 5m |
| event_processing_duration_seconds | data-processing-job | Histogram | stage | p95 > 300s |
| queue_depth | data-processing-job | Gauge | queue_name | Depth > 1000 sustained 10m |
| llm_requests_total | shared-llm-client | Counter | model, status | Error rate > 20% sustained 2m |
| geocoding_requests_total | geocoding-module | Counter | status | Error rate > 30% sustained 5m |

## Alerting rules

| Alert | Severity | Condition | Notification | Runbook |
|-------|----------|-----------|-------------|---------|
| ConsumerAPIDown | CRITICAL | Health check failing > 3 consecutive | Page on-call | runbooks/consumer-api.md §1 |
| HighErrorRate | HIGH | Error rate > 5% for 5 minutes | Page on-call | runbooks/consumer-api.md §2 |
| ProcessingStalled | HIGH | No events processed for 10 minutes | Page on-call | runbooks/data-processing-job.md §1 |
| QueueBacklog | MEDIUM | Queue depth > 1000 for 10 minutes | Notify channel | runbooks/data-processing-job.md §2 |
| LLMDegraded | MEDIUM | LLM error rate > 20% for 2 minutes | Notify channel | runbooks/shared-llm-client.md §1 |
| SLOBudgetBurn | HIGH | Error budget burn rate > 2x normal | Notify channel | runbooks/slo-budget.md |

## Dashboards

| Dashboard | Audience | Contents |
|-----------|----------|----------|
| System Overview | Ops, Engineering | Component health, request rates, error rates, queue depth |
| SLO Tracker | Ops, Product | SLO compliance, error budget remaining, trend |
| Processing Pipeline | Engineering | Event flow through stages, extraction accuracy, processing times |
| Dependencies | Ops | External API health, rate limit headroom, cache hit rates |

## Cost monitoring

| Resource | Baseline (monthly) | Alert threshold | Notification |
|----------|-------------------|-----------------|-------------|
| Compute (all components) | [per deployment] | > 20% above baseline | Notify channel |
| External APIs (LLM, geocoding) | [per deployment] | > 30% above baseline | Notify channel |
| Storage (DB, files, backups) | [per deployment] | > 20% above baseline | Notify channel |
| Total system cost | [per deployment] | > 20% above baseline sustained 7 days | Notify channel |
```

---

### 7. Deployment Topology

**Purpose:** Defines how the system is deployed. System-Operator uses this for deployment, scaling, and incident response. System-Maintainer uses it for deployment planning.

**Source:** Architecture (component decomposition) + Foundations (infrastructure choices) + Build output (actual deployment configs).

**Contents:**

```markdown
# Deployment Topology

## Component deployment

| Component | Deployment unit | Replicas (min / max) | Scaling strategy | Rollout strategy | Resource profile |
|-----------|----------------|---------------------|-----------------|-----------------|-----------------|
| consumer-api | Container (K8s Deployment) | 2 / 8 | Horizontal (CPU > 70%) | Rolling (25% max unavailable) | 256Mi-512Mi RAM, 0.25-0.5 CPU |
| data-processing-job | Container (K8s Deployment) | 1 / 4 | Horizontal (queue depth > 500) | Rolling (1 at a time) | 512Mi-1Gi RAM, 0.5-1 CPU |
| admin-api | Container (K8s Deployment) | 1 / 1 | None (low traffic) | Recreate | 256Mi RAM, 0.25 CPU |

## Infrastructure dependencies

| Service | Provider | Configuration | Failure mode |
|---------|----------|--------------|-------------|
| PostgreSQL | Managed (e.g., RDS) | Primary + read replica | Failover to replica (automatic) |
| Redis | Managed (e.g., ElastiCache) | Single node | Cache miss fallback to DB |
| Message queue | Managed (e.g., SQS) | Standard queue | Retry with backoff |

## Deployment order

For full deployment:
1. Database migrations
2. Shared libraries / modules
3. data-processing-job (consumer of events — must handle new schema)
4. consumer-api, admin-api (independent, parallel)

For component-specific deployment:
- Changes to shared libraries → redeploy all consumers
- Changes to one service → deploy only that service
- Database schema changes → migration first, then affected services

## Environment topology

| Environment | Purpose | Differences from production |
|-------------|---------|---------------------------|
| Development | Local development | Single-container, SQLite, mocked externals |
| Staging | Pre-production validation | Reduced replicas, shared infrastructure |
| Production | Live | Full replicas, dedicated infrastructure |

## Rollback procedure

| Scenario | Action | Data considerations |
|----------|--------|-------------------|
| Bad deployment (immediate) | Revert to previous container image | None if no schema change |
| Bad deployment (post-migration) | Forward-fix preferred | Backward-compatible migrations required |
| Data corruption | Restore from backup + replay | Point-in-time recovery window: [per Foundations] |

## Backup configuration

| Data store | Backup method | Frequency | Retention | Storage | Verification |
|-----------|--------------|-----------|-----------|---------|-------------|
| PostgreSQL | Automated snapshots | Daily + continuous WAL | 30 days | [per Foundations] | Daily restore test to staging |
| File storage (source emails) | Incremental backup | Daily | 90 days | [per Foundations] | Weekly integrity check |

Recovery targets:
- **RPO** (Recovery Point Objective): [per PRD — maximum acceptable data loss]
- **RTO** (Recovery Time Objective): [per PRD — maximum acceptable downtime for recovery]
```

**Key design decisions:**
- Scaling bounds (min/max replicas, resource profile) define the envelope within which System-Operator can auto-scale without human approval. Scaling beyond these limits requires Tier 3 (human approval).
- Rollout strategy is per-component because risk profiles differ — a stateless API can roll faster than a stateful worker
- Backup configuration includes verification method — an unverified backup is not a backup. System-Operator's routine operations workflow uses this for daily verification.
- Recovery targets (RPO/RTO) are derived from PRD requirements and connect to SLO definitions

---

### 8. Runbooks

**Purpose:** Operational procedures for common scenarios. System-Operator agents follow these; human operators use them as reference.

**One file per component** in `operations/runbooks/`, plus cross-cutting runbooks.

**Source:** Component Specs (error modes, recovery procedures) + Architecture (dependencies, failure modes).

**Contents:**

```markdown
# Runbook: [Component Name]

## 1. Service not responding

**Symptoms:** Health check failing, HTTP 502/503 from load balancer
**Severity:** CRITICAL

**Diagnosis steps:**
1. Check pod status: are pods running?
2. Check pod logs: OOM? Crash loop? Dependency timeout?
3. Check dependencies: DB reachable? Cache reachable? External APIs responding?

**Resolution by cause:**
| Cause | Action | Autonomy |
|-------|--------|----------|
| OOM killed | Increase memory limit, investigate leak | Auto-restart, alert for investigation |
| DB unreachable | Check DB health, check network | Alert — likely infrastructure issue |
| Crash loop (code error) | Rollback to last known good | Auto-rollback after 3 restarts, alert |
| Dependency timeout | Check dependency health | Wait + retry if transient, alert if sustained |

## 2. High error rate

**Symptoms:** Error rate > 5% sustained, SLO budget burning
**Severity:** HIGH

**Diagnosis steps:**
1. Which endpoints are erroring? (Check per-path error rates)
2. What error codes? (4xx vs 5xx pattern)
3. Correlate with recent deployments (deployed in last 2 hours?)
4. Correlate with dependency health

**Resolution by cause:**
| Cause | Action | Autonomy |
|-------|--------|----------|
| Recent deployment | Rollback candidate — check if errors started at deploy time | Propose rollback, human approves |
| Dependency failure | Check dependency runbook | Follow dependency runbook |
| Traffic spike | Scale horizontally | Auto-scale if within limits |
| Data issue | Investigate specific failing requests | Alert for investigation |

## 3. [Component-specific scenarios]

...
```

**Key design decisions:**
- Runbooks are structured for agent consumption: diagnosis is a decision tree, resolution is a lookup table by cause
- Autonomy column explicitly states what the agent can do alone vs what needs human approval — this connects to System-Maintainer's graduated autonomy tiers
- Runbooks are per-component because failure modes are component-specific, but cross-cutting runbooks exist for infrastructure-level scenarios (DB failover, certificate rotation, etc.)

---

### 9. Security Posture

**Purpose:** Defines the security boundaries and requirements. System-Operator uses this for security monitoring and compliance. System-Maintainer uses it to flag changes that touch security-sensitive areas.

**Source:** Foundations (security decisions) + Component Specs (auth, data handling).

**Contents:**

```markdown
# Security Posture

## Authentication and authorisation

| Surface | Auth method | Token type | Expiry | Refresh |
|---------|-----------|-----------|--------|---------|
| Consumer API | JWT Bearer | Access token | [per Foundations] | Refresh token flow |
| Admin API | JWT Bearer + role check | Access token | [per Foundations] | Same |
| Inter-service | Service token / mTLS | [per Foundations] | [per Foundations] | Auto-rotation |

## Exposed surfaces

| Surface | Exposure | Protection | Rate limiting |
|---------|----------|-----------|---------------|
| Consumer API | Public internet | JWT auth, CORS, rate limiting | [per Component Spec] |
| Admin API | Internal network only | JWT auth + admin role, IP allowlist | [per Component Spec] |
| Health endpoints | Internal network only | No auth (health only, no data) | None |

## Data protection

| Data category | At rest | In transit | Access control | Retention |
|---------------|---------|-----------|----------------|-----------|
| User PII | Encrypted (AES-256) | TLS 1.2+ | API auth required | [per PRD] |
| Event data | Encrypted (AES-256) | TLS 1.2+ | Public (read), Auth (write) | Indefinite |
| Source emails | Encrypted (AES-256) | TLS 1.2+ | Admin only | [per PRD] |
| Logs | [per Foundations] | TLS 1.2+ | Ops team | 90 days |

## Secrets management

| Secret | Storage | Rotation frequency | Rotation method |
|--------|---------|-------------------|----------------|
| DB credentials | Secrets manager | 90 days | Automated rotation |
| JWT signing key | Secrets manager | 180 days | Key rotation with grace period |
| External API keys | Secrets manager | Per provider policy | Manual (alert before expiry) |
| TLS certificates | Cert manager | 90 days (auto-renew at 30 days) | Automated (cert-manager) |

## Security-sensitive code paths

Changes to these areas require Tier 4 (full human engagement) in System-Maintainer:

- Authentication middleware
- Authorisation checks (role/permission validation)
- Data encryption/decryption
- Input validation and sanitisation
- CORS configuration
- Rate limiting configuration
- Secret access patterns
```

---

## Generation Approach

### Option A: Dedicated generation stage

Add a new System-Builder stage (e.g., Stage 09 or post-build) that reads all design documents and generates these artefacts. Pros: clean separation, single generation point. Cons: another stage to maintain, may duplicate logic.

### Option B: Distributed generation

Each existing stage generates its contribution:
- Stage 02 (PRD) → initial SLO definitions
- Stage 04 (Architecture) → component map, deployment topology sketch
- Stage 05 (Components) → contract definitions, risk profile, security posture
- Stage 08 (Build) → traceability, monitoring configs, runbooks, final deployment topology

Pros: information generated closest to its source. Cons: coordination needed, artefacts assembled across multiple stages.

### Option C: Post-build extraction

A single extraction pass after build is complete. Reads all design documents and build output, generates all artefacts. Pros: simplest to implement, all information available. Cons: extraction logic must understand all document formats.

**Recommendation:** Option C for initial implementation. A single post-build extraction agent reads the full design chain and generates all artefacts. This is the simplest to build and test. If extraction quality is insufficient (agent struggles to find information in prose), migrate specific artefacts to Option B (generated inline by the stage that has the best context).

---

## Staleness and Refresh

These artefacts are generated once by System-Builder and then maintained by System-Maintainer as changes are made.

| Artefact | Staleness risk | Refresh trigger |
|----------|---------------|----------------|
| Component Map | Low (architecture rarely changes) | Any Evolve-depth change |
| Contract Definitions | Medium (endpoints change with Extensions) | Any Extend or Evolve change to affected component |
| Risk Profile | Low (criticality rarely changes) | New component added, SLO change |
| Traceability | High (code changes frequently) | Any code change (can be automated) |
| SLO Definitions | Low (SLOs are stable) | PRD update, business requirement change |
| Monitoring | Medium (new metrics for new features) | Any Extend or Evolve change |
| Deployment | Low-Medium | New component, infrastructure change |
| Runbooks | Medium (new failure modes with new features) | Any Extend or Evolve change to affected component |
| Security Posture | Low (security model is stable) | Auth changes, new exposed surface, new data type |

**Traceability** is the highest-risk for staleness. Consider automating its regeneration as part of CI/CD (parse code structure, compare to spec references, flag drift).
