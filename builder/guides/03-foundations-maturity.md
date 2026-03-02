# Foundations Maturity Calibration

This document guides experts reviewing Foundations documents. Calibrate your expectations and severity ratings to the project's target maturity level (defined in Blueprint).

For the universal framework, see `maturity-reference.md`.

---

## How Maturity Applies to Technical Decisions

Foundations defines HOW the system will be built at the infrastructure and platform level. Maturity level affects the sophistication and rigour of technical choices:

- **MVP**: Simple, fast, cheap - validate before investing
- **Prod**: Reliable, maintainable, scalable - real users depend on it
- **Enterprise**: Compliant, auditable, resilient - formal requirements

---

## Dimension: Infrastructure Choices

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Compute** | Single server, simple hosting | Auto-scaling, multi-AZ | Multi-region, redundant |
| **Database** | Managed single instance | Managed with replicas | Multi-region, dedicated |
| **Networking** | Simple setup | Proper VPC, security groups | Network segmentation, WAF |

**Calibration:**
- MVP: Don't require multi-region, complex networking, or enterprise infrastructure
- Prod: Expect production-grade managed services with redundancy
- Enterprise: Expect comprehensive infrastructure with compliance controls

---

## Dimension: Resilience Choices

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Redundancy** | None required | Multi-AZ | Multi-region |
| **Backup strategy** | Manual or basic | Automated daily | Point-in-time, geo-redundant |
| **Disaster recovery** | Rebuild acceptable | Defined DR plan | Tested DR with RTO/RPO |

**Calibration:**
- MVP: Don't require formal DR plans or multi-region setup
- Prod: Expect backup strategy and basic redundancy
- Enterprise: Expect comprehensive DR with testing

---

## Dimension: Security Infrastructure

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Secrets management** | Environment variables OK | Dedicated secrets manager | Rotation, audit, break-glass |
| **Identity** | Simple auth provider | Proper IAM | Federated identity, MFA everywhere |
| **Network security** | Basic firewall | Security groups, private subnets | Zero trust, network segmentation |

**Calibration:**
- MVP: Don't require secrets rotation, zero trust, or complex IAM
- Prod: Expect proper secrets management and network security
- Enterprise: Expect comprehensive security infrastructure

---

## Dimension: Observability Stack

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Logging** | Console/stdout | Centralised logging | Structured, compliant retention |
| **Metrics** | Basic or none | Application and infra metrics | SLIs/SLOs, anomaly detection |
| **Alerting** | Manual monitoring | Automated alerts | Tiered escalation, runbooks |
| **Tracing** | None | Optional | Distributed tracing required |

**Calibration:**
- MVP: Don't require centralised logging, metrics platforms, or tracing
- Prod: Expect logging, metrics, and alerting
- Enterprise: Expect comprehensive observability with compliance

---

## Dimension: Development Infrastructure

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **CI/CD** | Manual deployment OK | Automated pipeline | Full pipeline with gates |
| **Environments** | Local + prod | Dev, staging, prod | Full environment parity |
| **Testing infra** | Manual testing OK | Automated in CI | Comprehensive test suites |

**Calibration:**
- MVP: Don't require full CI/CD pipelines or multiple environments
- Prod: Expect CI/CD and staging environment
- Enterprise: Expect comprehensive deployment infrastructure

---

## Dimension: Compliance Infrastructure

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Audit logging** | None required | Key events | Comprehensive, tamper-proof |
| **Data residency** | Any region | Appropriate region | Specific regions, controls |
| **Certifications** | None | As needed | SOC2, ISO27001, etc. |

**Calibration:**
- MVP: Don't require compliance infrastructure unless legally mandatory
- Prod: Expect basic compliance appropriate to data handled
- Enterprise: Expect formal compliance infrastructure

---

## Severity Calibration

When raising issues about technical decisions:

| Issue Type | MVP Severity | Prod Severity | Enterprise Severity |
|------------|--------------|---------------|---------------------|
| No secrets management | MEDIUM | HIGH | HIGH |
| No backup strategy | LOW | HIGH | HIGH |
| No CI/CD pipeline | LOW | MEDIUM | HIGH |
| No multi-AZ | LOW | MEDIUM | HIGH |
| No audit logging | LOW | LOW | HIGH |
| No DR plan | LOW | MEDIUM | HIGH |

---

## Growth Path Items

When you see decisions that are appropriate for current maturity but will need enhancement:

> "Acceptable for MVP. Note: Prod will require proper secrets management (suggest AWS Secrets Manager or similar)."

Mark as LOW severity. These go to "Future Developments" section.

---

## Common Mistakes

1. **Over-engineering MVP**: Requiring multi-region, comprehensive observability, or enterprise CI/CD for a validation exercise
2. **Under-engineering Enterprise**: Accepting "we'll add compliance later" for regulated environments
3. **Premature optimisation**: Choosing complex infrastructure for hypothetical scale
4. **Ignoring operational burden**: Choosing self-managed over managed services without justification
