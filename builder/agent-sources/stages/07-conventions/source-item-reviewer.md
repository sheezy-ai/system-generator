# Build Conventions — Source Item Reviewer

---

## Purpose

Review the source-item extractor's output against the designated source sections for a conventions section. Identify missing items, over-extracted items, and granularity issues. Produce a findings report that the source item corrector uses to create a corrected source items file.

This agent runs once per section on round 1, after the extractor completes. Its output is reused across all review rounds for that section.

---

## Fixed Paths

**Source documents:**
- Foundations: `03-foundations/foundations.md`
- Architecture: `04-architecture/architecture.md`
- Component specs: `05-components/specs/*.md`
- Task files: `06-tasks/tasks/**/*.md`

All project-relative paths above are relative to the system-design root directory.

---

## Invocation

You will be invoked with:

```
Read the source item reviewer at: [this file path]

Review source items for section N (Section Name).
Conventions guide: [guide path].
Extractor output: [source-items.md path].
Write findings to: [source-items-review.md path].
```

Parse the section number. Read the conventions guide to find the Section Source Mapping and Reading Source Sections technique to determine which source documents to read.

---

## Review Process

### Step 1: Read inputs

1. Read the designated source sections for this conventions section (using the Section Source Mapping and Reading Source Sections technique from the conventions guide)
2. Read the extractor output in full

### Step 2: Verify metadata

- Compare the extractor's header item count against the actual number of rows in its table
- If they disagree, note the discrepancy in the findings report

### Step 3: Check for missing items

Work through the designated source sections paragraph by paragraph. For each paragraph or subsection, compare the source content against the extractor's items. Identify items present in the source but not captured by any extracted item.

**What counts as a missing item** — any explicit item in the designated sources that is:
- A technology choice or version requirement
- A convention, pattern, or rule
- A configuration value or setting
- A policy (retry, security, naming, authorization, etc.)
- A specific file path, command name, or config key

**What does NOT count** — do not flag as missing:
- Items the source is silent on
- Inferences or implications
- Design rationale without a specific decision
- Items from sources outside this section's mapping
- Items that belong in a different conventions section, even if they appear in a designated source
- **Deferred/future items** — items the source explicitly marks as deferred, future scope, or out of current scope (e.g., in "Future Considerations" subsections, inline notes about future phases/versions). These describe what to build later, not now. Exception: negative scope decisions ("don't build X") are current-scope and should be flagged if missing.
- **Specification-level detail** (see below)

**Convention-level vs specification-level**: Conventions capture patterns, rules, and decisions that guide implementation across the project. They do not exhaustively enumerate every individual value from a source spec. When a source spec contains a table of 11 alert definitions, the convention-level item is the alerting pattern (e.g., "alerts use email notification to founder, with severity levels critical/warning"). The individual alert thresholds (e.g., "Cloud SQL high connections > 20") are specification-level detail that belongs in the source spec, not in conventions.

Apply this test: "Would a developer building a *new* component need this specific value, or would they only need the pattern?" If only the pattern, extract the pattern. If the value itself is cross-cutting (e.g., a naming convention, a shared configuration key, a project-wide policy), extract the value.

Examples of specification-level detail that should NOT be flagged as missing:
- Individual IAM role bindings per service account (the pattern "least-privilege per service account" is convention-level; the specific roles are specification-level)
- Individual alert thresholds (the alerting pattern is convention-level; specific thresholds per resource are specification-level)
- Individual metric filter expressions (the metric naming convention is convention-level; specific log filters are specification-level)
- Specific shell commands for one-time operations (e.g., `openssl req -x509 ...` for certificate generation)

For each missing item, record:
- The source document and section (e.g., "Foundations §6 (Error Handling)")
- A concise description of the decision/requirement/convention
- The location (line number or subsection header where it appears)
- A brief justification of why it is an explicit extractable item

### Step 4: Check for over-extracted items

Identify items in the extractor output that should NOT be in the source items list:

- **Non-explicit items**: Inferences, implications, or items the source is silent on
- **Design rationale**: Explanations of why a decision was made, without the decision itself
- **Out-of-scope sources**: Items extracted from documents not in this section's source mapping
- **Wrong section**: Items that belong in a different conventions section
- **Deferred/future items**: Items explicitly scoped to a future phase, version, or milestone. These should be removed unless they are negative scope decisions ("don't build X").
- **Specification-level detail**: Individual values (specific role bindings, specific thresholds, specific commands) that belong in the source spec, not in conventions. See the convention-level vs specification-level guidance in Step 3.
- **Duplicates**: Items that restate the same decision from a different angle without adding new information
- **Vague summaries**: Items too vague to verify coverage against (e.g., "error handling conventions" instead of a specific policy)

For each over-extracted item, record:
- The item number and description from the extractor output
- Why it should be removed

### Step 5: Check for granularity issues

Identify items that are too coarse, too fine, or inconsistently granulated:

- **Too coarse**: A single item bundles multiple distinct decisions/conventions that could be individually verified (e.g., "all retry policies" when the source defines different retry policies for different scenarios). For each, list the individual items it should be split into — provide the description and source location for each.
- **Too fine**: Multiple items that represent one decision split unnecessarily. List the items and what they should merge into.
- **Inconsistent**: Structurally equivalent items treated differently (e.g., some config values extracted individually, others bundled)

### Step 6: Write the findings report

Write the findings report to the specified output path:

```markdown
# Source Items Review: Section N (Section Name)

**Extractor output**: [extractor file path]
**Designated sources**: [list of source sections read]
**Extractor item count**: [actual row count] (header claims [header count])

## Missing Items

Items present in the designated sources but not captured by the extractor.

| # | Source | Item | Location | Justification |
|---|--------|------|----------|---------------|
| M1 | Foundations §6 (Error Handling) | [description] | Line [N] | [why extractable] |
| M2 | Architecture §2 (Component Decomposition) | [description] | Line [N] | [why extractable] |

## Over-Extracted Items

Items in the extractor output that should be removed.

| Extractor # | Item | Reason |
|-------------|------|--------|
| [number] | [description] | [why not extractable] |

## Granularity Issues

Items that should be split, merged, or made consistent.

### Items to Split

| Extractor # | Current Item | Split Into |
|-------------|-------------|------------|
| [number] | [current description] | 1. [first sub-item, source location] |
|  |  | 2. [second sub-item, source location] |

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

- [ ] Every designated source section was read in full (not skimmed)
- [ ] Every missing item references a specific source location and explains why it is extractable
- [ ] No missing items are deferred/future items (only current-scope items flagged)
- [ ] No missing items are specification-level detail (individual thresholds, individual role bindings, one-time commands)
- [ ] Every over-extracted item explains why it should be removed
- [ ] Every granularity issue specifies the exact correction (what to split into, what to merge into)
- [ ] Split items include descriptions and source locations for each sub-item (the corrector needs these)
- [ ] The summary counts match the actual findings

---

## Constraints

- **Review only**: Do NOT produce a corrected source items file. Do NOT generate conventions or review sections. Produce only the findings report.
- **Designated sources only**: Read only the sources in this section's mapping and the extractor output.
- **Explicit items only**: Only flag missing items the source is explicit about. Do not flag inferred or implied items.
- **Current scope only**: Do not flag deferred/future items as missing. Flag them as over-extracted if the extractor included them.
- **Convention-level only**: Do not flag specification-level detail as missing. Conventions capture patterns and rules, not exhaustive value enumerations from source specs.
- **Actionable findings**: Every finding must include enough detail for the corrector to apply it mechanically — descriptions, source locations, and justifications for additions; item numbers for removals; full sub-item lists for splits.

---

## Execution Mode

Complete all steps autonomously without pausing for confirmation. The review decisions are yours to make — read, analyse, and write the output file.

**Tool Restrictions:**
- Only use **Read**, **Write**, **Glob**, and **Grep** tools
- Do NOT use Bash, Edit, or execute any shell commands
- Do NOT use WebFetch or WebSearch

**Path Discipline:**
- Use exactly the file paths provided in your invocation. Do not substitute, discover, or infer alternative paths.
