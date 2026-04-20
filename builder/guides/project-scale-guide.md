# Project Scale Guide

## Purpose

Describes the structure, content, and authoring rules for `system-design/project-scale.md` — the canonical project-scale context reference consumed by the Stage-Appropriateness Verifier and producer prompts.

This guide defines **what** `project-scale.md` should contain and **how** to populate it. It is consumed by the `project-scale-generator` agent (which produces a first draft) and by humans (who review and hand-author where generator extraction fails).

---

## What project-scale.md is for

Tooling agents apply the **derivation test** when evaluating spec content:

> Could the implementing agent derive this specific content from the component's contract, scope, responsibility surface, and Foundations conventions?

To apply the derivation test with judgement calibrated to project reality, the agent needs project-scale context — is this a solo-founder MVP with <1/week events, or a production system with 10k daily users? Different scale → different defaults for what "a reasonable implementer would derive."

`project-scale.md` is the single source of truth for that context.

---

## Structure

`project-scale.md` contains exactly these sections, in this order:

1. **Header** — single sentence stating the file's purpose.
2. **Context table** — scale signals with values and source citations.
3. **Component Type Taxonomy** — three-class definition (domain / utility / cross-cutting) mapped from the project's Architecture taxonomy.
4. **Per-Component Classification table** — each component mapped to its type with a brief note.
5. **Usage note** — one paragraph stating how downstream consumers use the file, and the no-ceiling rule.

Target length: **30–60 lines** total. Longer suggests the file is drifting into other stages' territory.

---

## Context table — signals and sources

The Context table carries the following signals. Each row cites the source document and section:

| Signal | Source document | Extraction guidance |
|---|---|---|
| **Phase** | PRD (§1 or §2 typically) | Current active phase. "Phase 1a (MVP)", "Phase 2", etc. If multi-phase, use what the PRD describes active work for. |
| **Operators** | PRD (team / personas / operations section) | Count of people operating the system. "1 (solo founder)", "small team (3–5)", "dedicated ops team". |
| **End users** | PRD (user section / volume projections) | Order-of-magnitude: "< 100", "100–1k", "1k–10k", ">100k". Prefer count + qualifier ("closed test cohort", "public launch"). |
| **Event volume** | PRD (operational section) | Whatever volumetric signal the PRD provides: events/week, requests/sec, emails/day. Preserve units. |
| **Cost envelope** | Architecture §7 or "cost"/"budget" section | Monthly cost ceiling or reference to the component-spec containment rule. Cite section. |
| **DB tier** | Architecture / Foundations | Concrete tier ("db-f1-micro", "db-n1-standard-2") if specified; otherwise "not specified — default cloud-vendor tier". |

**Extraction rule**: every value must cite a specific document section. If a signal is absent from PRD + Architecture + Foundations, record as "not specified" — do **not** infer from indirect evidence.

---

## Component Type Taxonomy

Three-class taxonomy `project-scale.md` commits to:

- **Domain**: Authoritative for entity-group state, invariants, and data integrity. Own persisted data.
- **Utility**: Workflow / orchestration / presentation components. Compose domain operations; own workflow state where applicable, not domain state.
- **Cross-cutting**: Shared interfaces or utilities consumed by multiple components.

**Architecture-to-taxonomy mapping**: the target project's Architecture may use different terms (e.g., Pipeline / Domain / Application + cross-cutting). The guide's canonical taxonomy is `domain / utility / cross-cutting`. Map Architecture's categories to these three:

- Architecture "Domain" components → `domain`
- Architecture "Application" components (admin views, consumer interface, workflow components) → `utility`
- Architecture "Pipeline" / worker-side components (orchestrators, fetchers) → `utility`
- Architecture "Cross-cutting" interfaces / shared utilities → `cross-cutting`

State the mapping explicitly in the output file so the reader can verify the mapping matches the source Architecture.

---

## Per-Component Classification table

Table with one row per component from Architecture §6 (or equivalent Component List section). Columns:

| Component | Type | Notes |
|---|---|---|

- **Component**: name from Architecture's component list.
- **Type**: `Domain` / `Utility` / `Cross-cutting` per the taxonomy above.
- **Notes**: one-line description of the component's role — enough context to verify the classification without consulting the Architecture.

Include cross-cutting interfaces/utilities (audit-trail, source-attribution, compliance-gate, etc.) even if they aren't full components in the Architecture's Component List — they are consumed by the verifier the same way.

---

## Usage note

Final section. Two paragraphs stating:

1. Verifier and producer prompts consume the Context table when applying the derivation test. Per-Component Classification differentiates defaults per type (domain components carry richer contract surfaces; utility components are lighter; cross-cutting interfaces are consumed-by-many and under tighter shape discipline).

2. **Explicit no-ceiling rule**: "No section-count ceilings. Level-of-abstraction is the evaluation axis, not content volume."

The no-ceiling rule is load-bearing. Earlier design iterations drafted numeric per-section ceilings; they were dropped because count is not the right axis. Any revision that reintroduces ceilings must be reviewed against this rule.

---

## Authoring principles

1. **Extract, don't infer.** Every value in the Context table cites a source section. If a signal is absent from upstream documents, record "not specified" — do not synthesise values from indirect evidence.

2. **Classify, don't re-decide.** The Per-Component Classification applies the three-class taxonomy to existing components. It does not re-argue Architecture-level decisions about what each component is for.

3. **No ceilings.** See the usage note. Level-of-abstraction is the axis.

4. **Preserve existing.** If `system-design/project-scale.md` already exists when the generator runs, skip — it may be a retrofit or a hand-authored/revised instance. Do not overwrite.

5. **Concise.** Target 30–60 lines. If the file grows beyond 60, check whether content has drifted into stage-specific territory (component-spec rules, observability conventions, etc.) that belongs elsewhere.

---

## Output template

The generator agent writes a file matching this template. Placeholder values `[...]` are populated from extraction.

```markdown
# Project Scale

Canonical scale-context reference consumed by the Stage-Appropriateness Verifier and producer prompts. Derived from PRD and Architecture. Stable reference across Component Specs.

---

## Context

| Signal | Value | Source |
|---|---|---|
| Phase | [phase] | [document §section] |
| Operators | [count + qualifier] | [document §section] |
| End users | [count + qualifier] | [document §section] |
| Event volume | [value + units] | [document §section] |
| Cost envelope | [value or reference] | [document §section] |
| DB tier | [tier or "not specified"] | [document §section] |

---

## Component Type Taxonomy

Three classifications, mapped from Architecture §[N] groupings:

- **Domain**: Authoritative for entity-group state, invariants, and data integrity. Own persisted data.
- **Utility**: Workflow / orchestration / presentation components. Compose domain operations; own workflow state where applicable, not domain state.
- **Cross-cutting**: Shared interfaces or utilities consumed by multiple components.

---

## Per-Component Classification

| Component | Type | Notes |
|---|---|---|
| [component-1] | [Domain/Utility/Cross-cutting] | [one-line description] |
| [component-2] | [type] | [description] |
| ... | ... | ... |

---

## Usage

Verifier and producer prompts consume the **Context** table when applying the derivation test — "could the implementing agent derive this from component context + Foundations?" — and consume the **Per-Component Classification** when bias defaults diverge per component type. Domain components carry richer contract surfaces than utility components; cross-cutting interfaces are consumed-by-many and under tighter shape discipline than either.

No section-count ceilings. Level-of-abstraction is the evaluation axis, not content volume.
```
