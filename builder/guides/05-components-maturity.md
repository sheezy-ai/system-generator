# Component Specs Maturity Calibration

This document guides experts reviewing Component Specifications. Calibrate your expectations and severity ratings to the project's target maturity level (defined in Blueprint).

For the universal framework, see `maturity-reference.md`.

---

## How Maturity Applies to Implementation

Component Specs define HOW components will be implemented - interfaces, data models, error handling, testing. Maturity level affects the rigour and completeness of implementation:

- **MVP**: Working code that validates assumptions, conscious shortcuts acceptable
- **Prod**: Reliable, maintainable, well-tested code for real users
- **Enterprise**: Auditable, compliant, highly resilient code

---

## Dimension: Error Handling

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Failure modes** | Log and fail visibly | Defined recovery paths | Graceful degradation, fallbacks |
| **Retries** | None or simple | Exponential backoff | Circuit breakers, bulkheads |
| **Recovery** | Manual intervention OK | Automated retry, manual escalation | Fully automated recovery |
| **User feedback** | Generic error messages | Specific, actionable messages | Contextual help, support routing |

**Examples:**
- MVP: `except Exception: log.error("Failed"); raise`
- Prod: Retry 3x with backoff, alert on failure, clear error to user
- Enterprise: Circuit breaker opens after N failures, traffic routes to fallback

**Calibration:**
- MVP: Don't require circuit breakers, comprehensive retry logic, or graceful degradation
- Prod: Expect retry logic and clear error messages
- Enterprise: Expect comprehensive error handling

---

## Dimension: Security Implementation

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Authentication** | Basic auth or OAuth | Proper session management | MFA integration, token management |
| **Authorisation** | Simple role check | RBAC implementation | ABAC, least privilege |
| **Secrets** | Not in code, env vars OK | Secrets manager integration | Rotation, audit trails |
| **Input validation** | Basic sanitisation | Comprehensive validation | Schema validation, allowlists |
| **Audit** | None required | Key actions logged | Immutable audit trail |

**Examples:**
- MVP: API key in environment variable, basic input checks
- Prod: Secrets from AWS Secrets Manager, all user input validated
- Enterprise: Secrets rotated quarterly, all access logged to SIEM

**Calibration:**
- MVP: Don't require secrets rotation, comprehensive audit logging, or complex auth
- Prod: Expect proper secrets handling and input validation
- Enterprise: Expect comprehensive security implementation

---

## Dimension: Data Integrity

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Transactions** | Implicit/none | Explicit for critical operations | Saga patterns where needed |
| **Constraints** | Application-level OK | Database-enforced | Database + application + audit |
| **Migrations** | Break-and-rebuild OK | Backwards compatible | Zero-downtime, rollback tested |
| **Validation** | Basic type checking | Business rule validation | Comprehensive with audit |

**Examples:**
- MVP: Single SQL statement, rebuild DB if corrupted
- Prod: Transactions for multi-step operations, migration scripts tested
- Enterprise: All schema changes reviewed, rollback procedures documented

**Calibration:**
- MVP: Don't require saga patterns, zero-downtime migrations, or comprehensive constraints
- Prod: Expect transactions and backwards-compatible migrations
- Enterprise: Expect comprehensive data integrity

---

## Dimension: Observability

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Logging** | Console/stdout | Structured, centralised | Correlation IDs, distributed tracing |
| **Metrics** | None or basic counts | Key business + system metrics | SLIs defined, dashboards |
| **Alerting** | Manual monitoring | Alerts for critical issues | Tiered escalation, runbooks |
| **Health checks** | Basic HTTP 200 | Liveness + readiness probes | Deep health checks, dependency status |

**Examples:**
- MVP: `print()` statements, manual monitoring
- Prod: JSON logs to CloudWatch, Datadog metrics, Slack alerts
- Enterprise: OpenTelemetry tracing, SLO dashboards, automated incident creation

**Calibration:**
- MVP: Don't require structured logging, metrics, or health probes
- Prod: Expect structured logging and key metrics
- Enterprise: Expect comprehensive observability

---

## Dimension: Testing

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Unit tests** | Critical paths only | >70% coverage | >85% coverage |
| **Integration tests** | Manual verification | Automated in CI | Contract tests, E2E suites |
| **Performance** | "It works" | Load tested for expected traffic | Capacity planning, chaos engineering |
| **Security testing** | None | Dependency scanning | SAST, DAST, pen tests |

**Examples:**
- MVP: Happy path tests, manual QA before release
- Prod: Unit + integration in CI, load test before major releases
- Enterprise: Nightly E2E suite, quarterly pen test, chaos monkey in staging

**Calibration:**
- MVP: Don't require high coverage, automated E2E, or security testing
- Prod: Expect reasonable coverage and CI integration
- Enterprise: Expect comprehensive testing strategy

---

## Dimension: API Design

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Versioning** | None required | Version in URL or header | Formal versioning strategy |
| **Documentation** | Informal | OpenAPI/Swagger | Comprehensive with examples |
| **Backwards compatibility** | Breaking changes OK | Deprecation warnings | Formal deprecation policy |
| **Rate limiting** | None | Basic limits | Tiered, per-client limits |

**Calibration:**
- MVP: Don't require API versioning, formal docs, or rate limiting
- Prod: Expect versioning and documentation
- Enterprise: Expect comprehensive API governance

---

## Dimension: Operations

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Deployment** | Manual or simple script | CI/CD pipeline | Blue/green, canary |
| **Rollback** | Redeploy previous | One-click rollback | Automated rollback on SLO breach |
| **Configuration** | Hardcoded or env vars | Config service | Versioned config, change audit |
| **Feature flags** | None | Optional | Required for major features |

**Calibration:**
- MVP: Don't require CI/CD, feature flags, or sophisticated deployment
- Prod: Expect CI/CD and rollback capability
- Enterprise: Expect comprehensive deployment strategy

---

## Severity Calibration

When raising issues about implementation:

| Issue Type | MVP Severity | Prod Severity | Enterprise Severity |
|------------|--------------|---------------|---------------------|
| No error handling | MEDIUM | HIGH | HIGH |
| Secrets in code | HIGH | HIGH | HIGH |
| No input validation | MEDIUM | HIGH | HIGH |
| No unit tests | LOW | MEDIUM | HIGH |
| No logging | LOW | MEDIUM | HIGH |
| No API versioning | LOW | MEDIUM | HIGH |
| No circuit breakers | LOW | LOW | HIGH |
| No audit logging | LOW | LOW | HIGH |

---

## Growth Path Items

When you see implementation that's appropriate for current maturity but will need enhancement:

> "Acceptable for MVP. Note: Prod will require structured logging with correlation IDs for debugging production issues."

Mark as LOW severity. These go to "Future Developments" section.

---

## Common Mistakes

1. **Over-engineering MVP**: Requiring circuit breakers, comprehensive observability, or high test coverage for validation code
2. **Under-engineering Enterprise**: Accepting "we'll add audit logging later" for compliance-sensitive code
3. **Gold-plating**: Adding complexity that doesn't serve the maturity target
4. **Ignoring the obvious**: Missing basic security (secrets in code) while debating advanced patterns
