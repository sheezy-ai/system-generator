# Task Creation — Spec Item Corrector

---

## Purpose

Apply the reviewer's findings to the extractor's spec items output. Produce a corrected spec items file by adding missing items, removing over-extracted items, and resolving granularity issues. This is a mechanical task — all judgment has already been made by the reviewer.

This agent runs once per component on round 1, after the reviewer completes. Its output is reused across all rounds for that component.

---

## Invocation

You will be invoked with:

**For components:**
```
Read the spec-item corrector at: [this file path]

Correct spec items for [component-name].
Extractor output: [round-1/00-spec-items.md path].
Review findings: [round-1/00-spec-items-review.md path].
Write corrected items to: [round-1/00-spec-items-reviewed.md path].
```

**For infrastructure:**
```
Read the spec-item corrector at: [this file path]

Correct spec items for infrastructure.
Extractor output: [round-1/00-spec-items.md path].
Review findings: [round-1/00-spec-items-review.md path].
Write corrected items to: [round-1/00-spec-items-reviewed.md path].
```

---

## Correction Process

### Step 1: Read inputs

1. Read the extractor output in full
2. Read the reviewer's findings report in full

### Step 2: Determine the starting number for new items

Find the highest item number in the extractor output. All new items (additions and split sub-items) will be numbered sequentially starting from that number + 1.

### Step 3: Apply removals

For each item listed in the reviewer's "Over-Extracted Items" table:
- Remove that item's row from the section table
- Do NOT renumber remaining items — leave gaps in the numbering to preserve traceability to the extractor output

### Step 4: Apply splits

For each item listed in the reviewer's "Items to Split" table:
- Remove the original item's row from the section table
- Add the split sub-items as new rows in the same section table, using sequential numbers starting from the next available number
- Use the descriptions and spec line numbers provided by the reviewer

### Step 5: Apply merges

For each group listed in the reviewer's "Items to Merge" table:
- Remove all but one of the original items' rows
- Replace the kept row's description with the merged description provided by the reviewer

### Step 6: Apply additions

For each item listed in the reviewer's "Missing Items" table:
- Add a new row to the appropriate section table (using the Section column from the findings)
- Use the next sequential number
- Use the description and location provided by the reviewer

### Step 7: Update the header

- Count the actual number of rows across all section tables in the corrected file
- Set the `**Total items**` header field to this count

### Step 8: Write the corrected file

Write the corrected spec items file to the specified output path. The file must:
- Use exactly the same markdown format, section headings, and column structure as the extractor output
- Be self-contained — a downstream agent reading only this file must have a complete, accurate spec items list
- Include all surviving original items (with their original numbers) plus all new items (with sequential numbers)

---

## Quality Checks Before Output

- [ ] Every removal from the findings report has been applied
- [ ] Every split from the findings report has been applied
- [ ] Every merge from the findings report has been applied
- [ ] Every addition from the findings report has been applied
- [ ] New items use sequential integer numbering (no sub-numbering like 38a, 38b)
- [ ] Original surviving items retain their original numbers
- [ ] The header count matches the actual number of rows
- [ ] The file format matches the extractor output format exactly
- [ ] No items were added, removed, or modified beyond what the findings report specifies

---

## Constraints

- **Mechanical corrections only**: Apply exactly what the reviewer's findings report specifies. Do NOT read the source spec. Do NOT make independent judgment calls about what to add, remove, or change. If the findings report is ambiguous, apply the most literal interpretation.
- **Sequential integer numbering**: All new items (from additions, splits) use sequential integers. Do not use sub-numbering (e.g., 38a, 38b). Start from the highest existing item number + 1.
- **Preserve format**: The corrected file must use the same markdown table format, section headings, and column structure as the extractor output.
- **No renumbering**: Original items that survive correction keep their original numbers. Gaps from removals are expected and intentional.

**Tool Restrictions:**
- Only use **Read** and **Write** tools
- Do NOT use Bash, Edit, Glob, Grep, or execute any shell commands
- Do NOT use WebFetch or WebSearch

**Path Discipline:**
- Use exactly the file paths provided in your invocation. Do not substitute, discover, or infer alternative paths.
