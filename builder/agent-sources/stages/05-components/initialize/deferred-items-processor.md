# Deferred Items Processor

**Invocation**: This agent is spawned by the Component Specs Initializer using the Task tool. Do not run directly.

---

## Purpose

Categorises items from the monolithic Component Specs deferred items into component-specific deferred items files. This enables the Component Specs creation workflow to process manageable, relevant subsets of deferred items.

---

## When to Use

Run once at the start of Component Specs creation workflow, before any individual component work begins. Only runs if component-specific deferred items files don't already exist.

---

## Inputs

- **Monolithic deferred items**: `system-design/05-components/versions/deferred-items.md`
- **Architecture Overview**: `system-design/04-architecture/architecture.md` (for component list)

---

## Outputs

- **Component-specific deferred items**: `system-design/05-components/versions/[component-name]/deferred-items.md`
- **Cross-cutting deferred items**: `system-design/05-components/versions/cross-cutting/deferred-items.md`
- **Archived original**: `system-design/05-components/versions/deferred-items-archived-YYYY-MM-DD.md`

---

## Processing Strategy

The monolithic deferred items file may exceed token limits. Process in chunks:

### Step 1: Get Component List

Read the Architecture Overview to find the Component Spec List section. Extract the list of components with their responsibilities. Build a classification guide mapping keywords and signals to components based on each component's described responsibility and scope.

### Step 2: Index the Deferred Items

Use Grep to find all section headers (`## From`) to identify chunk boundaries. Each "From" section is typically small enough to process individually.

### Step 3: Process Each Section

For each `## From [Source]` section:

1. **Read the section** using offset/limit based on line numbers from Step 2
2. **For each item** (identified by `### [ITEM-ID]:`):
   - Analyse content to determine relevant component(s)
   - Classification signals:
     - Explicit component name mentions
     - Architecture section references (match section numbers to components)
     - Domain keywords matching component responsibilities from the classification guide built in Step 1
     - Data entity mentions that map to specific component scopes
   - If item applies to multiple components, mark as cross-cutting
3. **Append to appropriate deferred items file(s)**

### Step 4: Archive Original

Rename the monolithic deferred items file to `versions/deferred-items-archived-YYYY-MM-DD.md` and add header note:

```markdown
> **Archived**: Processed into component-specific deferred items on YYYY-MM-DD.
> See versions/[component]/deferred-items.md for active items.
```

---

## Component Classification Guide

Build this guide dynamically in Step 1 from the Architecture Overview. For each component, extract:
- Component name (used as the classification target)
- Responsibility description (provides domain keywords)
- Key data entities or capabilities (provides signal words)

Use the resulting mapping to classify deferred items. Items mentioning multiple components or cross-service concerns should be classified as cross-cutting.

---

## Output Format

Each component deferred items file should have this structure:

```markdown
# Deferred Items - [Component Name]

Items deferred from upstream stages, relevant to this component.

**Generated**: YYYY-MM-DD
**Source**: Processed from system-design/05-components/versions/deferred-items.md

---

## Items

### [ITEM-ID]: [Summary]

**Source**: [Original source stage/round]
**Severity**: [If available]

[Original content]

**Why Relevant**: [Brief explanation of why this applies to this component]

---
```

For cross-cutting items, add:

```markdown
**Cross-cutting**: Also relevant to: [list of other components]
```

---

## Execution Mode

Complete all steps autonomously without pausing for confirmation. Process each section, classify items, and write output files. Do not ask "Should I proceed?" or similar.

---

<!-- INJECT: tool-restrictions -->
