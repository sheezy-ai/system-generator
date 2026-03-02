# PRD Maturity Calibration

This document guides experts reviewing Product Requirements Documents. Calibrate your expectations and severity ratings to the project's target maturity level (defined in Blueprint).

For the universal framework, see `maturity-reference.md`.

---

## How Maturity Applies to Requirements

PRD defines WHAT the system must do. Maturity level affects the scope and rigour of requirements:

- **MVP**: Minimal viable requirements to validate core assumptions
- **Prod**: Complete requirements for reliable, maintainable production system
- **Enterprise**: Comprehensive requirements including compliance, audit, governance

---

## Dimension: Resilience Requirements

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Availability** | Best effort, some downtime acceptable | 99.9% target, planned maintenance windows | 99.99%+, zero-downtime deployments |
| **Recovery** | Manual recovery acceptable | Defined RTO/RPO | Stringent RTO/RPO with testing |
| **Degradation** | Full failure acceptable | Graceful degradation preferred | Graceful degradation required |

**Calibration:**
- MVP: Don't require SLAs or formal availability targets
- Prod: Expect availability requirements but not extreme
- Enterprise: Expect formal SLAs with consequences

---

## Dimension: Security Requirements

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Authentication** | Basic login sufficient | Proper session management, MFA optional | MFA required, SSO, federation |
| **Authorisation** | Simple roles sufficient | Defined RBAC | Formal RBAC/ABAC, access reviews |
| **Data protection** | Don't store unnecessary sensitive data | Encryption at rest/transit | Comprehensive data classification |

**Calibration:**
- MVP: Don't require MFA, SSO, or complex auth flows
- Prod: Expect reasonable security requirements
- Enterprise: Expect comprehensive security requirements

---

## Dimension: Data Requirements

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Integrity** | Application-level validation sufficient | Database constraints expected | Full integrity with audit |
| **Backup** | Manual backup acceptable | Automated backup required | Point-in-time recovery, geo-redundant |
| **Retention** | Undefined acceptable | Defined policy | Formal policy with legal compliance |

**Calibration:**
- MVP: Don't require formal data retention policies
- Prod: Expect backup and basic retention requirements
- Enterprise: Expect comprehensive data governance

---

## Dimension: Compliance Requirements

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Privacy** | Basic awareness | GDPR/CCPA compliance | Privacy by design, DPIAs |
| **Audit** | None required | Key actions logged | Comprehensive audit trail |
| **Regulatory** | None unless mandatory | Industry-specific basics | Full regulatory compliance |

**Calibration:**
- MVP: Don't require formal compliance frameworks unless legally mandatory
- Prod: Expect privacy compliance for user data
- Enterprise: Expect comprehensive compliance requirements

---

## Dimension: Operational Requirements

| Concern | MVP | Prod | Enterprise |
|---------|-----|------|------------|
| **Monitoring** | Basic health check | Monitoring and alerting | Comprehensive observability |
| **Support** | Best effort | Defined support hours | 24/7 support, escalation paths |
| **Documentation** | Minimal | User and admin docs | Comprehensive documentation |

**Calibration:**
- MVP: Don't require formal support SLAs or comprehensive docs
- Prod: Expect monitoring and reasonable support requirements
- Enterprise: Expect formal operational requirements

---

## Severity Calibration

When raising issues about missing or inadequate requirements:

| Issue Type | MVP Severity | Prod Severity | Enterprise Severity |
|------------|--------------|---------------|---------------------|
| Missing basic functionality | HIGH | HIGH | HIGH |
| Missing availability SLA | LOW | MEDIUM | HIGH |
| Missing MFA requirement | LOW | LOW | HIGH |
| Missing audit trail requirement | LOW | MEDIUM | HIGH |
| Missing compliance framework | LOW | MEDIUM | HIGH |
| Missing formal support SLA | LOW | LOW | HIGH |

---

## Growth Path Items

When you see requirements that are appropriate for current maturity but will need enhancement:

> "Acceptable for MVP. Note: Prod will require formal availability SLA (suggest 99.9%)."

Mark as LOW severity. These go to "Future Developments" section.

---

## Common Mistakes

1. **Over-specifying MVP**: Requiring enterprise-grade SLAs, compliance frameworks, or security controls for a validation exercise
2. **Under-specifying Enterprise**: Accepting "we'll add compliance later" for a system that will handle regulated data
3. **Confusing requirements with implementation**: PRD says WHAT, not HOW - leave implementation details to later stages
