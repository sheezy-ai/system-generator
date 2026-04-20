# Project Scale Generator

**Invocation**: This agent is spawned by the Component Specs Initializer using the Task tool. Do not run directly.

---

## Purpose

Produces a first-draft `system-design/project-scale.md` for the target project by extracting scale signals from the PRD and Architecture, applying the Project Scale Guide's structure and authoring principles.

The output is a draft for human review at an orchestrator-level review gate. Humans may edit or replace any value; the file's value is in the review, not the extraction.

---

## When to Use

Spawned once during Component Specs stage initialization (Step 3b of the initialize orchestrator), before the stage state file is written.

**Idempotency**: if `system-design/project-scale.md` already exists at the target path, preserve it and exit without writing. Existing files may be retrofits or manually-authored/revised instances — do not overwrite.

---

## Inputs

- **Project Scale Guide**: `{{GUIDES_PATH}}/project-scale-guide.md` — the structure, value-source mapping, and authoring principles
- **PRD**: `system-design/02-prd/prd.md` — source for phase, operators, end users, event volume
- **Architecture Overview**: `system-design/04-architecture/architecture.md` — source for cost envelope, DB tier, component type taxonomy, per-component classification
- **Foundations** (optional, secondary source): `system-design/03-foundations/foundations.md` — DB tier may be specified here if not in Architecture

---

## Outputs

- **Project scale reference**: `system-design/project-scale.md`

---

## File-First Operation

1. You will receive **file paths** as input, not file contents
2. **Check target existence** — if `system-design/project-scale.md` already exists, report and exit without writing
3. **Read the Project Scale Guide** — internalise structure, value-source mapping, taxonomy mapping rules, authoring principles (extract don't infer; no ceilings; preserve existing)
4. **Read the PRD** — extract phase, operators, end users, event volume; cite specific sections
5. **Read the Architecture Overview** — extract cost envelope, DB tier, component type taxonomy terms, per-component classification from Architecture §6 (or equivalent Component List section)
6. **Read Foundations** only if DB tier is absent from Architecture — otherwise skip
7. **Apply taxonomy mapping** — map Architecture's categories (Pipeline / Domain / Application + cross-cutting, or equivalent) to the canonical `domain / utility / cross-cutting` per the guide
8. **Write the output file** using the guide's template; cite source sections for every Context table row
9. **Report** summary to the orchestrator

---

## Extraction Rules

Follow the Project Scale Guide's Context-table mapping. Key reminders:

- **Cite sources explicitly**: every Context table row must include the source document and section. Not "PRD" — "PRD §1" or "PRD §2 Scope".
- **"Not specified" is valid**: if a signal is absent from upstream documents, record as "not specified" — do not synthesise from indirect evidence.
- **Preserve units**: event volume should carry units ("< 1/week per source", "~100 emails/day"). Stripping units hides scale information.
- **Count qualifiers matter**: "< 100 closed test-user cohort" carries more signal than "< 100 users". When the PRD specifies a qualifier, include it.

---

## Taxonomy Mapping Rules

Architecture terminology varies across projects. The guide's canonical taxonomy is `domain / utility / cross-cutting`. Apply the mapping:

| Architecture term | Canonical type |
|---|---|
| Domain component / Domain entity / authoritative-for-entity | **Domain** |
| Application component / workflow / admin view / consumer view | **Utility** |
| Pipeline component / worker-side / orchestrator / fetcher | **Utility** |
| Cross-cutting interface / shared utility / shared infrastructure | **Cross-cutting** |

When the Architecture's term is ambiguous (e.g., a component described as "application-level but authoritative for workflow state"), default to the side matching the component's primary responsibility. Workflow state ≠ domain state. Note the judgement call in the Per-Component Classification Notes column.

Include cross-cutting interfaces and utilities in the table even if the Architecture doesn't list them in its Component List — they are consumed by tooling the same way.

---

## Per-Component Classification

For each component in Architecture §6 (or the equivalent Component List):

1. Extract component name
2. Extract one-line responsibility summary (use Architecture's own phrasing, trimmed)
3. Apply taxonomy mapping → assign Type
4. If classification involved judgement (ambiguous architectural category), note it in the Notes column

Also include cross-cutting items even when not in the Component List:
- audit-trail / audit-trail interface
- source-attribution / source attribution
- compliance-gate / compliance-gate utility
- Any other shared interface or utility mentioned in Architecture §2 or §7

---

## Output Format

Use the output template from the Project Scale Guide. Target length: 30–60 lines.

Populate every placeholder; do not leave `[...]` markers in the output. If a value is "not specified", write it as "not specified" in the Value column with the source citation being the documents consulted.

---

## Report on Completion

Print a one-line summary for the orchestrator:

```
project-scale.md written at system-design/project-scale.md. [N] components classified ([N] domain, [N] utility, [N] cross-cutting). Phase detected: [phase].
```

If idempotency skip triggered:

```
project-scale.md already exists at system-design/project-scale.md — preserved, no changes written.
```

---

## Constraints

- **Extract, don't infer**: every Context table row cites a specific document section.
- **Do not edit upstream documents**: this agent reads PRD, Architecture, Foundations — it never edits them.
- **Preserve existing file**: if `project-scale.md` already exists, exit without writing.
- **No ceilings**: do not introduce numeric section-count thresholds. The guide's no-ceiling rule is load-bearing.
- **Guide-driven structure**: the output must match the guide's template — sections, column order, usage note wording.

---

## Execution Mode

Complete all steps autonomously without pausing for confirmation. Read inputs, apply extraction rules, write the output file, report.

The orchestrator that spawned this agent handles the downstream human review gate; this agent's job is producing the draft, not negotiating its content.

---

<!-- INJECT: tool-restrictions -->
