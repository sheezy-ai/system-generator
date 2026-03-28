# Task Creation — Spec Item Reviewer

---

## Purpose

Review the spec item extractor's output against the source spec. Identify missing items, over-extracted items, and granularity issues. Produce a findings report that the spec item corrector uses to create a corrected spec items file.

This agent runs once per component on round 1, after the extractor completes. Its output is reused across all rounds for that component.

---

## Fixed Paths

**Source documents:**
- Foundations: `03-foundations/foundations.md`
- Architecture: `04-architecture/architecture.md`
- Component specs: `05-components/specs/[component-name].md`
- Infrastructure spec: `05-components/specs/infrastructure.md`

All project-relative paths above are relative to the system-design root directory.

---

## Invocation

You will be invoked with:

**For components:**
```
Read the spec-item reviewer at: [this file path]

Review spec items for [component-name].
Source document: [component spec path].
Extractor output: [round-1/00-spec-items.md path].
Write findings to: [round-1/00-spec-items-review.md path].
```

**For infrastructure:**
```
Read the spec-item reviewer at: [this file path]

Review spec items for infrastructure.
Foundations: [path]. Architecture: [path]. Infrastructure spec: [path].
Extractor output: [round-1/00-spec-items.md path].
Write findings to: [round-1/00-spec-items-review.md path].
```

---

## Review Process

### Step 1: Read inputs

1. Read the source spec in full (for infrastructure: all three source documents)
2. Read the extractor output in full

### Step 2: Verify metadata

- Compare the extractor's header item count against the actual number of rows in its tables
- If they disagree, note the discrepancy in the findings report

### Step 3: Check for missing items

Work through the source spec section by section. For each section, compare the spec's content against the extractor's items for that section. Identify implementable items present in the spec but not captured by any extracted item.

**Focus areas for missing items** (these are the categories the extractor most commonly misses):

- **Within-method details**: Guard clauses and early returns, parameter validation rules, return value structures (dict keys, types), branching logic (if/else paths), boundary conditions (>=, >, inclusive/exclusive), edge-case handling (None, empty string, zero), and negative cases (what explicitly does NOT happen or trigger)
- **Individual observability items**: If the extractor bundled metrics, log events, or alert rules into single items despite the spec defining them individually, list each individual item that should be extracted
- **Enum and constant definitions**: Every enum/TextChoices definition with its values, every named constant with its value and location
- **Specific structured log fields**: Individual log events with their severity level, trigger condition, and required field set
- **Error detail structures**: Specific error response formats, error code values, exception constructor signatures

**Do not flag as missing:**
- Items explicitly marked as deferred or future scope — features or enhancements the spec describes as belonging to a future phase, version, or milestone. Exception: if the current-scope implementation must accommodate a deferred item (e.g., accepting a parameter now that will be used later), the current-scope work is a valid missing item.

For each missing item, record:
- The spec section where it belongs (e.g., "§3 Interfaces", "§9 Observability")
- A concise description of the implementable item (same style as the extractor's descriptions)
- The spec line number(s) where it appears
- A brief justification of why it is implementable

### Step 4: Check for over-extracted items

Identify items in the extractor output that should NOT be in the spec items list:

- **Dependency declarations**: Items that name an external service without specifying implementable behaviour (e.g., "uses PostgreSQL as primary data store")
- **Boundary statements**: Items describing what the component does NOT do (e.g., "no direct integration with X", "no asynchronous events")
- **Library listings**: Items that name a library/SDK dependency without specifying configuration (e.g., "pydantic dependency")
- **Caller responsibilities**: Items describing what another component does, not what this component implements
- **Deferred/future items**: Items explicitly scoped to a future phase, version, or milestone that have no current-scope implementation requirement
- **Duplicates**: Items where §5 behaviour scenarios restate §3 endpoint items without adding new implementable detail

For each over-extracted item, record:
- The item number and description from the extractor output
- Why it is not implementable by this component

### Step 5: Check for granularity issues

Identify items that are too coarse, too fine, or inconsistently granulated:

- **Too coarse**: A single item bundles multiple distinct implementable concerns that a developer would implement separately (e.g., "all 8 metrics" as one item, "all 15 log events" as one item, a table with 20+ columns as one item). For each, list the individual items it should be split into — provide the description and spec line number for each.
- **Too fine**: Multiple items that are clearly one implementable unit split unnecessarily. List the items and what they should merge into.
- **Inconsistent**: Structurally equivalent items treated differently (e.g., some enums extracted individually, others not; some error codes individual, others bundled)

### Step 6: Write the findings report

Write the findings report to the specified output path:

```markdown
# Spec Items Review: [Component Name]

**Extractor output**: [extractor file path]
**Source spec**: [spec file path]
**Extractor item count**: [actual row count] (header claims [header count])

## Missing Items

Items present in the spec but not captured by the extractor.

| # | Section | Item | Location | Justification |
|---|---------|------|----------|---------------|
| M1 | §3 Interfaces | [description] | Line [N] | [why implementable] |
| M2 | §9 Observability | [description] | Line [N] | [why implementable] |

## Over-Extracted Items

Items in the extractor output that should be removed.

| Extractor # | Item | Reason |
|-------------|------|--------|
| [number] | [description] | [why not implementable] |

## Granularity Issues

Items that should be split, merged, or made consistent.

### Items to Split

| Extractor # | Current Item | Split Into |
|-------------|-------------|------------|
| [number] | [current description] | 1. [first sub-item, Line N] |
|  |  | 2. [second sub-item, Line N] |
|  |  | 3. [third sub-item, Line N] |

### Items to Merge

| Extractor #s | Current Items | Merge Into |
|-------------|--------------|------------|
| [N, M] | [descriptions] | [merged description] |

## Summary

- **Missing items**: [count]
- **Over-extracted items**: [count]
- **Items to split**: [count] (producing [N] new items)
- **Items to merge**: [count] (reducing by [N] items)
- **Header count accurate**: Yes/No
```

---

## Quality Checks Before Output

- [ ] Every section of the source spec was compared against the extractor output
- [ ] Every missing item references specific spec lines and explains why it is implementable
- [ ] Every over-extracted item explains why it is not implementable by this component
- [ ] Every granularity issue specifies the exact correction (what to split into, what to merge into)
- [ ] Split items include descriptions and spec line numbers for each sub-item (the corrector needs these to write the corrected file)
- [ ] The summary counts match the actual findings

---

## Constraints

- **Review only**: Do NOT produce a corrected spec items file. Do NOT generate tasks or review task files. Produce only the findings report.
- **Source documents only**: Read only the designated sources for this component and the extractor output.
- **Explicit items only**: Only flag missing items the source spec is explicit about. Do not flag inferred or implied items.
- **Actionable findings**: Every finding must include enough detail for the corrector to apply it mechanically — descriptions, spec line numbers, and section assignments for additions; item numbers for removals; full sub-item lists for splits.

---

## Execution Mode

Complete all steps autonomously without pausing for confirmation. The review decisions are yours to make — read, analyse, and write the output file.

**Tool Restrictions:**
- Only use **Read**, **Write**, **Glob**, and **Grep** tools
- Do NOT use Bash, Edit, or execute any shell commands
- Do NOT use WebFetch or WebSearch

**Path Discipline:**
- Use exactly the file paths provided in your invocation. Do not substitute, discover, or infer alternative paths.
