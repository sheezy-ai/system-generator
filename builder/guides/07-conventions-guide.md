# Conventions Guide

## Purpose

A conventions section is a concrete, builder-ready reference for a specific aspect of the codebase (e.g., error handling, testing, database patterns). Each section should be:
- **Derived**: Every convention traces to a source document
- **Specific**: Concrete file paths, command names, and configuration values — not abstract descriptions
- **Self-contained**: A builder should not need to read source documents to understand the section
- **Builder-oriented**: Written for the audience that will implement code, not design rationale

---

## Scope Principles

1. **Derive, not invent** — Every convention must trace to a source document from its section's designated sources. Where source documents are ambiguous or silent, mark defaults clearly with `[DEFAULT — not specified in source documents]`.

2. **Specific, not abstract** — Use concrete file paths, command names, and configuration values. "Configure the linter" is abstract. "`ruff check --config pyproject.toml`" is specific.

3. **Builder-oriented** — Write for the developer who will implement code against these conventions. Avoid design rationale — that belongs in Component Specs and Foundations.

---

## Section Content Guide

Each of the 13 conventions sections covers a specific topic. Use this guide to understand the expected scope and content of each section.

### 1. Repository Structure
Where code lives, directory layout for application code, tests, configuration, infrastructure-as-code.

### 2. Language & Runtime
Language versions, interpreters, type checking configuration, runtime requirements.

### 3. Dependency Management
Package manager, lockfile policy, version pinning strategy, production and dev/test dependency lists, dependency scanning policy.

### 4. Module Structure
How each component is structured as a package or module. Internal layout (models, services, routes, tests). Django app vs plain module patterns.

### 5. Import Conventions
How components reference each other. Absolute vs relative imports. Cross-component import restrictions.

### 6. Configuration
Environment variables, config files, secrets access patterns. How configuration flows from environment to application code.

### 7. Error Handling
Error response format, exception hierarchy, error propagation, retry policies.

### 8. Logging
Structured logging setup, format, levels, what to log, correlation IDs, retention.

### 9. Testing
Test categories (unit, integration, E2E) and what each means for this project. Test framework and runner per category. Directory structure — separate directories per category (e.g., `tests/unit/`, `tests/integration/`). Naming conventions. Mock and test double strategy for unit tests — what gets mocked (databases, external APIs, message queues), which libraries. Test environment assumptions per category: unit tests run locally with no external dependencies, integration tests require live services, E2E tests require full stack. Coverage expectations. Fixture and factory patterns.

### 10. Database
Migration tooling, connection patterns, ORM conventions, transaction handling, schema conventions, table list.

### 11. API Patterns
Request/response handling, serialisation, validation, authentication, security headers, CORS, input validation.

### 12. Build & Run Commands
How to build, test, lint, type-check, and run locally. Exact commands. Aggregated from all previous sections and Foundations deployment section. Separate test commands per category — unit tests (local, no infrastructure), integration tests (requires services), E2E tests (requires full stack). The unit test command is what automated verification (Stage 09) will run.

### 13. Code Style
Formatting tool and configuration (e.g., Black, Prettier, rustfmt). Linter tool and configuration (e.g., Ruff, ESLint, Clippy). Type annotation expectations (fully typed, gradual, none). Naming conventions for files, classes, functions, variables, and constants. Docstring expectations (public API only, all functions, none) and format (e.g., Google style, NumPy style). Comment policy (when to comment, when not to). Function and module size guidance. Any project-specific style rules derived from source documents.

---

## Section Source Mapping

Each section reads only its designated sources. **Do NOT read sources outside this mapping.**

| Section | Sources |
|---------|---------|
| 1. Repository Structure | Foundations §1 (Technology Choices), Foundations §10 (Deployment & Infrastructure), Architecture §2 (Component Decomposition) |
| 2. Language & Runtime | Foundations §1 (Technology Choices) |
| 3. Dependency Management | Foundations §1 (Technology Choices), Foundations §8 (Security Baseline), component specs (Grep each for package/library/dependency mentions) |
| 4. Module Structure | Architecture §2 (Component Decomposition), Foundations §2 (Architecture Patterns) |
| 5. Import Conventions | Architecture §2 (Component Decomposition) |
| 6. Configuration | Foundations §1 (Technology Choices), Foundations §10 (Deployment & Infrastructure), Infrastructure spec (`05-components/specs/infrastructure.md`) |
| 7. Error Handling | Foundations §6 (Error Handling) |
| 8. Logging | Foundations §7 (Logging & Observability) |
| 9. Testing | Foundations §9 (Testing Conventions), task files (Grep `06-tasks/tasks/**/*.md` for test/testing patterns) |
| 10. Database | Foundations §4 (Data Conventions), Foundations §2 (Architecture Patterns), component specs (Grep each for table/schema/data model mentions) |
| 11. API Patterns | Foundations §5 (API Conventions), Foundations §3 (Authentication & Authorization), Foundations §8 (Security Baseline), Architecture §4 (Integration Points), `05-components/specs/admin-api.md`, `05-components/specs/consumer-api.md` |
| 12. Build & Run Commands | Foundations §10 (Deployment & Infrastructure), all completed section files in `07-conventions/conventions/sections/` |
| 13. Code Style | Foundations §1 (Technology Choices — linter/formatter/type-checker choices), Foundations §9 (Testing Conventions — naming patterns) |

### Reading Source Sections

For each Foundations or Architecture section in the mapping:

1. Grep the source file for the section header (e.g., `^## 1\. Technology Choices`) to get the line number
2. Grep for the next `^## ` header after that line to find the section end
3. Read with offset and limit to extract just that section

For component specs: Read the specific spec file, or Grep across all specs for the relevant pattern.

For task files: Grep across task files for patterns relevant to the section.

For completed sections (Section 12 only): Read each section file from `07-conventions/conventions/sections/`.

---

## Handling Ambiguity

Where source documents are ambiguous or silent on a convention:
1. State what the source documents say (or don't say)
2. Propose a sensible default with rationale
3. Mark the item clearly: `[DEFAULT — not specified in source documents]`

---

## Output Format

Each conventions section is written as a standalone markdown section. Start with the section heading. Do not include document-level metadata (that is added during assembly).

```markdown
## N. Section Title

[Content derived from source documents]
```

---

## Shared Quality Checks

Every agent should verify these before output, in addition to any agent-specific checks:

- [ ] Every convention traces to a source document from this section's mapping
- [ ] Source references are specific (e.g., "Foundations §6 (Error Handling)", not just "Foundations")
- [ ] No conventions invented without grounding — items where source is silent are marked `[DEFAULT]`
- [ ] The section is self-contained — a builder should not need to read source documents to understand it
- [ ] Specific file paths, command names, and configuration values — not abstract descriptions
