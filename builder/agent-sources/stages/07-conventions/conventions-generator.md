# Build Conventions — Section Generator

---

## Purpose

Generate a single section of the build conventions document. Each section is derived from a focused set of source documents — not the full corpus. This prevents context overload and ensures accurate source tracing.

---

## Fixed Paths

**Source documents:**
- Foundations: `03-foundations/foundations.md`
- Architecture: `04-architecture/architecture.md`
- Component specs: `05-components/specs/*.md`
- Task files: `06-tasks/tasks/**/*.md`

**Output:**
- Section file path provided at invocation (e.g., `07-conventions/conventions/sections/07-error-handling.md`)

All project-relative paths above are relative to the system-design root directory.

---

## Invocation

You will be invoked with one of:
- **Generate**: `Generate section N (Section Name). Conventions guide: [path]. Write to: [path]`
- **Fix**: `Fix section N (Section Name), round R. Conventions guide: [path]. Review report: [path]. Write to: [path]`

Parse the section number from the invocation. Read the conventions guide to find the Section Source Mapping, Section Content Guide, and other shared references.

---

## File-First Operation

1. **Read the conventions guide** at the path provided in the invocation
2. Look up this section's designated sources in the Section Source Mapping
3. Read the Section Content Guide to understand expected scope
4. Read the designated source sections using the Reading Source Sections technique
5. Generate the section (or apply fixes for round 2+)
6. Run Coverage Self-Review
7. Run Citation Self-Verification
8. Run the Shared Quality Checks from the guide
9. Write output

---

## Coverage Self-Review

**Run this step after drafting content, before citation self-verification.** This catches items where the generator failed to address a guide requirement for this section — either with content or an explicit `[DEFAULT]` tag.

1. **Re-read the Section Content Guide** for this section — focus on the expected scope and items listed
2. **For each expected item**, verify the section addresses it with either:
   - Substantive content derived from a source document, OR
   - A `[DEFAULT]` tagged convention with rationale
3. **Check designated source coverage** — re-scan the source sections read in step 4. For each explicit decision, convention, or configuration value in the sources that falls within this section's topic, verify it appears in the section.
4. **Add missing items** — For any unaddressed guide requirement or source item, add it before proceeding. This is cheaper than waiting for the reviewer to flag it as a GAP.

Do NOT skip this step. A section that covers all guide requirements and source items on the first round avoids unnecessary fix rounds.

---

## Citation Self-Verification

**Run this step after coverage self-review, before writing the output file.** This catches wrong section numbers and misquoted source text — the two most common generator errors.

For every citation in the section (every `§N` reference, every quoted value attributed to a source, every "per Foundations/Architecture" claim):

1. **Re-read the cited source passage** — Grep for the specific value or term in the source file and read the surrounding context
2. **Confirm the section number matches** — verify the `§N` in the citation corresponds to the actual section header in the source document
3. **Confirm quoted text matches** — verify any quoted values, field names, or configuration values match the source text exactly (not paraphrased from memory)
4. **Fix before writing** — if any citation is wrong, correct it in the section content before writing the output file

Do NOT skip this step. It takes a few extra Grep calls but prevents the most common review failures.

---

## Fix Rounds

When invoked for a fix round (review report path provided):

1. **Read the review report** at the provided path
2. **Read the current section file** at the output path
3. **Re-read the designated sources** for this section (see Section Source Mapping in the conventions guide)
4. **Make targeted edits** using the Edit tool — apply each correction from the review report's Action Required section to the existing section file. Do not rewrite the file.
5. **Re-verify ALL citations in the section** — not just the ones flagged. The reviewer may have missed some on prior rounds, and your edits may have introduced new citations. Run the Citation Self-Verification step on the entire section. Use Edit to correct any citation issues found.
6. **Re-run quality checks**

**Principle**: Fix rounds edit in place, they do not regenerate. The previous round's section file is the starting point. Only the issues raised in the review report are addressed. Unrelated content is not touched.

---

## Constraints

- **Focused reads**: Read only the sources designated for this section (per the guide's Section Source Mapping). Do not read other documents.
- **Guide-driven**: Follow the Scope Principles, Handling Ambiguity, and Output Format from the conventions guide.

---

## Execution Mode

Complete all steps autonomously without pausing for confirmation. The generation decisions are yours to make — read, analyse, and write the output file.

**Tool Restrictions:**
- Only use **Read**, **Write**, **Edit**, **Glob**, and **Grep** tools
- Use **Write** for round 1 (creating the section file from scratch)
- Use **Edit** for fix rounds (targeted corrections to existing section file)
- Do NOT use Bash or execute any shell commands
- Do NOT use WebFetch or WebSearch

**Path Discipline:**
- Use exactly the file paths provided in your invocation. Do not substitute, discover, or infer alternative paths.
