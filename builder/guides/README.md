# Guides

## Purpose

The files in this directory are **functional documents**, not just documentation. AI agents read them directly during workflow execution to understand:

1. **What belongs at each stage's abstraction level** - Generator and Author agents read the stage guides to structure documents correctly
2. **Format specifications** - Agents use these to structure deferred items and pending issues correctly

## Why This Matters

Because agents consume these files directly:

- **Changes have immediate effect** on agent behaviour
- **Accuracy is critical** - errors propagate into generated documents
- **Consistency with agent prompts** must be maintained - stage guides are the source of truth for document structure; expert prompts contain domain-specific abstraction guidance and reference maturity guides directly

Treat these as code, not prose.

## Contents

### Stage Guides

| File | Used By | Purpose |
|------|---------|---------|
| `01-blueprint-guide.md` | Generator, Author | What belongs in a Blueprint |
| `02-prd-guide.md` | Generator, Author | What belongs in a PRD |
| `03-foundations-guide.md` | Generator, Author | What belongs in Foundations |
| `04-architecture-guide.md` | Generator, Author | What belongs in Architecture Overview |
| `05-components-guide.md` | Generator, Author, Issue Router | What belongs in Component Specs |
| `06-tasks-guide.md` | Task Generator, Coverage Checker | What belongs in Tasks |
| `07-conventions-guide.md` | Section Generator, Source Item Extractor, Section Reviewer, Source Item Reviewer | Section source mapping, content guide, shared quality checks |

Stages 08–12 are automated coordinator-based pipelines and don't have guides. Their scope and structure are defined directly in their coordinator and agent prompts.

### Format Specifications

| File | Used By | Purpose |
|------|---------|---------|
| `deferred-items-format.md` | Scope Filter, Generator | How to structure deferred items entries |
| `pending-issues-format.md` | Alignment Verifier, Issue Router, Contract Verifier, Pending Issue Resolver, Coherence Orchestrator | How to structure pending issues |

### Maturity Reference

| File | Used By | Purpose |
|------|---------|---------|
| `maturity-reference.md` | All agents | Overview of MVP/Prod/Enterprise maturity levels |
| `02-prd-maturity.md` | PRD agents | PRD-specific maturity calibration |
| `03-foundations-maturity.md` | Foundations agents | Foundations-specific maturity calibration |
| `04-architecture-maturity.md` | Architecture agents | Architecture-specific maturity calibration |
| `05-components-maturity.md` | Component Spec agents | Component Spec-specific maturity calibration |

## Editing Guidelines

1. **Test changes** - After editing, verify agent behaviour is as expected
2. **Keep agent prompts in sync** - If a guide changes, check whether agent prompts that inline content from it need updating
3. **Maintain internal consistency** - Section headings in "What it Should Contain" define the document structure
