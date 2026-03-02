# Maturity Reference Framework

This document defines the maturity calibration framework used across stages 02-05. For stage-specific application, see the corresponding `XX-stage-maturity.md` file.

---

## Maturity Levels

| Level | Context | Mindset |
|-------|---------|---------|
| **MVP** | Startup/early validation | Validate assumptions, speed over polish, conscious technical debt acceptable |
| **Prod** | Scaleup/production | Real users depend on it, reliability matters, maintainability matters |
| **Enterprise** | Compliance-heavy environments | Audit trails, SLAs, formal processes, regulatory requirements |

**The target maturity level is defined in the Blueprint.**

---

## Dimensions

Maturity affects decisions across these dimensions:

| Dimension | What it covers |
|-----------|----------------|
| **Resilience** | Error handling, failure modes, recovery, retries |
| **Security** | Authentication, authorisation, secrets, input validation, audit |
| **Data Integrity** | Transactions, constraints, backups, migrations |
| **Observability** | Logging, metrics, alerting, health checks |
| **Operations** | Deployment, rollback, configuration, documentation |
| **Testing** | Unit, integration, performance, security testing |
| **Compliance** | Data privacy, retention, change management, governance |
| **Cost** | Awareness, optimisation, budgets, forecasting |

---

## Core Principles

### 1. Calibrate to Target

Assess against the target maturity level, not an absolute standard. What's acceptable for MVP may be unacceptable for Enterprise, and vice versa.

### 2. Don't Over-Spec

If target is MVP, don't raise Enterprise concerns as HIGH severity. An MVP doesn't need circuit breakers, audit trails, or 99.99% uptime SLAs.

### 3. Don't Under-Spec

If target is Enterprise, don't wave away compliance or reliability concerns. Enterprise systems have non-negotiable requirements.

### 4. Flag Growth Path

When you see something that's fine for current maturity but will need attention at the next level, flag it as LOW severity with a note:

> "Acceptable for MVP. Note: Prod will require [specific enhancement]."

These items go to the "Future Developments" section of the document.

### 5. Prioritise Within Maturity

Even within a maturity level, prioritise issues that matter most for that context:
- **MVP**: Focus on what blocks validation
- **Prod**: Focus on what affects reliability and user experience
- **Enterprise**: Focus on what affects compliance and auditability

---

## Where Maturity Target Lives

The **Blueprint** defines the project's target maturity level. All downstream stages (PRD, Foundations, Architecture, Specs) reference this.

Blueprint should include:
- Target Level (MVP / Prod / Enterprise)
- Rationale for this level
- Known constraints or timeline pressures
- Planned maturity progression (if any)

---

## Stage-Specific Application

Each stage applies maturity calibration differently:

| Stage | Maturity Doc | Focus |
|-------|--------------|-------|
| 02-PRD | `02-prd-maturity.md` | Requirements calibration |
| 03-Foundations | `03-foundations-maturity.md` | Technical decisions calibration |
| 04-Architecture | `04-architecture-maturity.md` | System design calibration |
| 05-Component Specs | `05-components-maturity.md` | Implementation calibration |

**Stage 01 (Blueprint)** defines the maturity target and does not need calibration.

**Stage 06 (Tasks)** derives from Specs where maturity is already applied.

---

## For Experts

1. **Read the Blueprint** to find the target maturity level
2. **Read your stage's maturity doc** to understand expectations
3. **Calibrate severity** based on target level
4. **Flag growth path items** as LOW with notes for future maturity
5. **Stay focused** - don't waste issue slots on out-of-scope concerns
