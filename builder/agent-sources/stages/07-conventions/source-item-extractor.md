# Build Conventions — Source Item Extractor

---

## Purpose

Extract explicit decisions, requirements, conventions, configuration values, and policies **relevant to the section topic** from a section's designated source documents. Produces a structured list that the section reviewer uses instead of building its own enumeration.

This agent runs once per section before the first review round. Its output is reused across all review rounds for that section.

---

## Fixed Paths

**Source documents:**
- Foundations: `03-foundations/foundations.md`
- Architecture: `04-architecture/architecture.md`
- Component specs: `05-components/specs/*.md`
- Task files: `06-tasks/tasks/**/*.md`

**Output:**
- Source items file path provided at invocation

All project-relative paths above are relative to the system-design root directory.

---

## Invocation

You will be invoked with:
`Extract source items for section N (Section Name). Conventions guide: [path]. Write to: [path]`

Parse the section number. Read the conventions guide to find the Section Source Mapping and Reading Source Sections technique.

---

## Extraction Process

### Step 1: Read designated source sections

Read each source section designated for this conventions section using the Reading Source Sections technique from the conventions guide. Read the full content of each designated source section — do not skim or summarise.

### Step 2: Enumerate explicit items relevant to the section topic

Read through each source section paragraph by paragraph. For each paragraph or subsection, extract items that are:

- An explicit technology choice or version requirement
- An explicit convention, pattern, or rule
- An explicit configuration value or setting
- An explicit policy (retry, security, naming, authorization, etc.)
- A specific file path, command name, or config key

**AND relevant to the section topic.** The designated source sections often contain decisions that span multiple conventions sections. Only extract items that belong in *this* section. For example, Architecture §2 (Component Decomposition) contains module structure decisions, import relationships, deployment configuration, and database patterns — but if you are extracting for "Module Structure", only extract items about how code is organised into modules, not deployment scaling or database isolation.

Ask yourself for each item: "Does this belong in a section called [Section Name]?" If it belongs in a different conventions section (e.g., Database, Configuration, API Patterns), skip it even if it appears in a designated source.

**Do not extract:**
- Items the source is silent on
- Inferences or implications
- Design rationale without a specific decision
- Items from sources outside this section's mapping
- Items that belong in a different conventions section, even if they appear in a designated source
- Items explicitly marked as deferred or future scope (see below)

**Current scope only**: Source documents often contain a mix of current-scope decisions and deferred/future items. Only extract items that describe what to build now. Skip items the source explicitly marks as deferred, future, or out of current scope — common markers include dedicated "Future Considerations" or "Deferred Decisions" subsections, inline notes labelled as future phases or versions, and statements describing what to build later.

Distinguish between two patterns:
- **"Don't build X"** — a negative scope decision that constrains the current build. Extract this (e.g., "No message broker required" tells the builder not to add one).
- **"Build X later"** — a deferred item describing future work. Skip this (e.g., "Integrate automated scanning into CI in a future phase" is not actionable now).

**Structured data in sources**: When a source contains a table, list, or enumeration (e.g., a table of alert definitions, a list of IAM role bindings, a set of metric definitions), extract each row or list item as a separate source item. Do not summarise a table into a single item — each row is a distinct decision or configuration value. This is the most common cause of missing items.

For each item, record:
- The source document and section (e.g., "Foundations §6 (Error Handling)")
- The specific item as a concise description of the decision/requirement/convention
- The location (line number or subsection header where the item appears)

### Step 3: De-duplicate

Review all extracted items and merge duplicates. The same decision often appears in multiple sources with different wording — Foundations states a high-level choice, and a component spec restates it as a concrete configuration value. These are one item, not two.

For each pair of items, ask: "Do these describe the same underlying decision?" If yes:
- Keep the most specific version (usually from the component spec or infrastructure spec)
- List all source locations in the Location column (e.g., "Foundations §1 line 87; Infra spec line 201")

Common duplication patterns:
- Foundations technology choice + component spec configuration value (e.g., "PostgreSQL 15" in both)
- Foundations policy + Architecture operationalisation of that policy
- Same library/tool mentioned in multiple component specs

### Step 4: Write output

Write the source items file to the path provided at invocation.

---

## Output Format

```markdown
# Source Items for Section N (Section Name)

**Extracted from**: [list of designated source sections read]
**Total items**: N

| # | Source | Item | Location |
|---|--------|------|----------|
| 1 | Foundations §6 (Error Handling) | Retry policy: exponential backoff, max 3 retries | Line 152 |
| 2 | Foundations §6 (Error Handling) | Error categories: transient vs permanent | Line 158 |
| 3 | Architecture §2 (Component Decomposition) | Components share models/business logic but deploy independently | Line 85 |
| ... | | | |
```

---

## Quality Checks Before Output

- [ ] Every designated source section was read in full (not skimmed)
- [ ] Every explicit item relevant to this section's topic has a row in the table
- [ ] No items that belong in a different conventions section (check section name against each item)
- [ ] No deferred/future items extracted (only current-scope decisions and negative scope decisions)
- [ ] No items were extracted from sources outside this section's mapping
- [ ] No inferred or implied items — only explicit statements
- [ ] Tables and lists in sources were enumerated row by row (not summarised into single items)
- [ ] Duplicates across sources merged into single items with all locations cited
- [ ] Item descriptions are specific enough to verify coverage (not vague summaries)
- [ ] Location column allows the reviewer to find the item in the source
- [ ] Items are numbered sequentially
- [ ] Total items count matches the number of rows in the table

---

## Constraints

- **Extract only**: Do NOT generate conventions or review sections. Produce only the source items list.
- **Designated sources only**: Read only the sources in this section's mapping.
- **Section-relevant items only**: Extract items that belong in this conventions section. Skip items that belong in other conventions sections, even if they appear in a designated source.
- **Explicit items only**: Do not list items the source is silent on. Do not infer.
- **Current scope only**: Skip items explicitly marked as deferred or future. Extract negative scope decisions ("don't build X") but not deferred items ("build X later").
- **Enumerate, don't summarise**: Each table row, list item, or distinct value in the source is a separate extracted item. A table of 11 alerts produces 11 items, not 1.
- **De-duplicate across sources**: The same decision stated in Foundations and a component spec is one item, not two. Keep the most specific version.
- **Specific descriptions**: Each item must be specific enough that a reviewer can check whether the conventions section covers it. "Error handling conventions" is too vague. "Retry policy: exponential backoff, max 3 retries" is specific enough.

---

## Execution Mode

Complete all steps autonomously without pausing for confirmation. The extraction decisions are yours to make — read, analyse, and write the output file.

**Tool Restrictions:**
- Only use **Read**, **Write**, **Glob**, and **Grep** tools
- Do NOT use Bash, Edit, or execute any shell commands
- Do NOT use WebFetch or WebSearch

**Path Discipline:**
- Use exactly the file paths provided in your invocation. Do not substitute, discover, or infer alternative paths.
