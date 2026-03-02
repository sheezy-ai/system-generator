# Architecture Maturity Calibration

This document guides experts reviewing Architecture Overview documents. Calibrate your expectations and severity ratings to the project's target maturity level (defined in Blueprint).

For the universal framework, see `maturity-reference.md`.

---

## How Maturity Applies to System Design

Architecture defines the system's structure - components, boundaries, interactions. Maturity level affects the sophistication and rigour of design:

- **MVP**: Simple, monolithic, fast to change - validate before decomposing
- **Prod**: Well-structured, maintainable, scalable where needed
- **Enterprise**: Resilient, auditable, formally governed

---

## Dimension: Decomposition

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Component structure** | Monolith acceptable | Modular monolith or services where justified | Service-oriented, clear boundaries |
| **Separation of concerns** | Basic separation | Clear module boundaries | Formal domain boundaries |
| **Coupling** | Tight coupling acceptable | Loose coupling preferred | Loose coupling required |

**Calibration:**
- MVP: Don't require microservices, formal domain boundaries, or complex decomposition
- Prod: Expect reasonable modularity and separation
- Enterprise: Expect well-defined service boundaries

---

## Dimension: Resilience Patterns

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Failure isolation** | None required | Basic isolation | Bulkheads, circuit breakers |
| **Redundancy** | Single points of failure OK | Critical path redundancy | Comprehensive redundancy |
| **Graceful degradation** | Full failure acceptable | Preferred for key features | Required for all user-facing |

**Calibration:**
- MVP: Don't require circuit breakers, bulkheads, or complex resilience patterns
- Prod: Expect failure handling for critical paths
- Enterprise: Expect comprehensive resilience design

---

## Dimension: Integration Patterns

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Communication** | Synchronous OK | Async where beneficial | Event-driven where appropriate |
| **Contracts** | Implicit acceptable | Defined interfaces | Formal contracts, versioning |
| **Dependencies** | Direct calls OK | Managed dependencies | Dependency injection, abstraction |

**Calibration:**
- MVP: Don't require event-driven architecture, formal contracts, or complex integration
- Prod: Expect defined interfaces between components
- Enterprise: Expect formal integration patterns

---

## Dimension: Data Architecture

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Data ownership** | Shared database OK | Clear ownership preferred | Strict data ownership |
| **Consistency** | Eventual or strong as convenient | Appropriate to use case | Formally defined consistency |
| **Data flows** | Ad-hoc acceptable | Documented flows | Governed data flows |

**Calibration:**
- MVP: Don't require strict data ownership or formal data governance
- Prod: Expect clear data ownership for core entities
- Enterprise: Expect comprehensive data architecture

---

## Dimension: Data Contracts

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Contract identification** | Implicit OK | All cross-component flows identified | Formal contract registry |
| **Contract clarity** | Producer/consumer implied | Explicit producer/consumer | Versioned contracts |
| **Contract verification** | Manual | Automated verification | CI/CD contract testing |

**Calibration:**
- MVP: Don't require exhaustive contract identification; major data flows should be captured
- Prod: Expect all cross-component data flows to have explicit contracts
- Enterprise: Expect formal contract management and verification

---

## Dimension: Security Architecture

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Trust boundaries** | Implicit OK | Defined for external | Comprehensive trust model |
| **Auth architecture** | Simple, centralised | Proper auth flow | Zero trust, least privilege |
| **Data protection** | Basic encryption | Encryption in transit/rest | Comprehensive data protection |

**Calibration:**
- MVP: Don't require zero trust, formal trust boundaries, or complex auth architecture
- Prod: Expect defined security boundaries
- Enterprise: Expect comprehensive security architecture

---

## Dimension: Scalability Design

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Scaling approach** | Vertical OK | Horizontal for bottlenecks | Comprehensive scaling strategy |
| **Bottleneck handling** | Accept limitations | Identified and addressed | Proactively designed out |
| **Capacity planning** | None required | Basic projections | Formal capacity planning |

**Calibration:**
- MVP: Don't require horizontal scaling, capacity planning, or complex scaling design
- Prod: Expect scaling strategy for known bottlenecks
- Enterprise: Expect comprehensive scalability design

---

## Dimension: Operational Design

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Deployability** | Manual deployment OK | Automated, reversible | Blue/green, canary |
| **Observability** | Basic logging | Metrics, logging, traces | Comprehensive observability |
| **Maintainability** | Tech debt acceptable | Manageable complexity | Formal complexity management |

**Calibration:**
- MVP: Don't require sophisticated deployment strategies or comprehensive observability
- Prod: Expect automated deployment and basic observability
- Enterprise: Expect comprehensive operational design

---

## Severity Calibration

When raising issues about architecture:

| Issue Type | MVP Severity | Prod Severity | Enterprise Severity |
|------------|--------------|---------------|---------------------|
| Unclear component boundaries | LOW | MEDIUM | HIGH |
| No failure isolation | LOW | MEDIUM | HIGH |
| Undefined data ownership | LOW | MEDIUM | HIGH |
| No scaling strategy | LOW | MEDIUM | HIGH |
| Missing trust boundaries | LOW | MEDIUM | HIGH |
| Tight coupling everywhere | MEDIUM | HIGH | HIGH |
| Missing data contracts | LOW | MEDIUM | HIGH |
| Unclear producer/consumer | LOW | MEDIUM | HIGH |

---

## Growth Path Items

Use the "Don't over-spec" and "Don't under-spec" guidelines above to calibrate severity. The maturity tables define what is expected at each level — experts should raise issues through the normal closed-scope criteria (a/b/c) and calibrate severity accordingly.

---

## Common Mistakes

1. **Premature decomposition**: Requiring microservices for an MVP that should validate with a monolith
2. **Under-designing Enterprise**: Accepting "we'll add resilience later" for systems that need it from the start
3. **Complexity without justification**: Adding patterns (CQRS, event sourcing) without clear benefit
4. **Ignoring operational reality**: Designing without considering who will operate it
