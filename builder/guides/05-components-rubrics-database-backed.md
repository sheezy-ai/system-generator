# Component Spec Rubrics: Database-Backed Components

Conditional rubric catalogue applied only when the spec declares ownership of database schema.

---

## Top-Level Precondition

**This catalogue applies when**: the spec under audit contains a Data Model section (or equivalent) that declares tables with columns, types, and constraints. If no such section exists, the entire catalogue is NOT_APPLICABLE.

---

## Waiver Syntax

Same as the universal catalogue:

```markdown
<!-- rubric:RUB-DB-001 waived: <reason> -->
```

Waivers must state a reason of at least 20 characters of substantive content.

---

## Rubric Catalogue

Rubrics are numbered `RUB-DB-NNN`.

---

### RUB-DB-001: Documented query pattern has supporting index

**Status**: Grounded (3 supporting instances across rounds 1, 3 of email-sources)
**Mechanicality**: Borderline — the auditor must parse query patterns from Behaviour sections, identify filtering/ordering columns, and match them to index declarations. Mark NOT_APPLICABLE on ambiguous query descriptions rather than guessing.

**Principle**: Every query pattern documented in the spec — whether in Behaviour, Interface, or Integration sections — that targets a specific table must have a corresponding index declared in the Data Model section, unless the query is on a primary key (which is indexed by definition).

**Rationale**: A documented query pattern without a declared index either silently relies on a sequential scan or assumes the implementer will infer the right index. In either case, the spec has a gap between what it prescribes (the query) and what it provides (the storage structure to support it).

**Precondition**: Spec documents query patterns (e.g. "look up X by Y", "list all Z ordered by W", `SELECT ... WHERE ... ORDER BY ...`) AND has a Data Model section with table definitions.

**Check**: For each documented query pattern:
1. Identify the table and the columns used in filtering / ordering / joining.
2. Check whether the Data Model section declares an index covering those columns — as an explicit index, a unique constraint (which creates an implicit index), or a primary key.
3. Flag queries whose columns are not covered.

**Fix template**: Add an index declaration to the Data Model section covering the flagged columns. Note the index type if relevant (e.g. partial index, composite index).

**Waiver**: `<!-- rubric:RUB-DB-001 waived: <reason> -->` on the query pattern. Valid reasons include "table size capped at N rows; sequential scan acceptable at this scale".

---

### RUB-DB-002: Enum-like column has DDL CHECK constraint

**Status**: Grounded (2+ supporting instances across rounds 3, 4 of email-sources)

**Principle**: Every column that stores a value from a fixed set of options (an enum, a status, a type discriminator, a category) must have a `CHECK (column IN (...))` constraint declared in the Data Model section.

**Rationale**: Application-layer enum validation is a defence, not an enforcement mechanism. Without a DDL CHECK, invalid values can enter via migrations, backfills, raw SQL, or future code paths that bypass the application layer.

**Precondition**: Data Model section declares a column described as storing values from a fixed set — evidenced by language like "one of", "values:", an inline enum list, or a reference to a named set of valid values.

**Check**: The column's constraint list includes a CHECK constraint that enumerates or references the valid values.

**Fix template**: Add `CHECK (column IN ('value1', 'value2', ...))` to the column's constraint list in the Data Model section.

**Waiver**: `<!-- rubric:RUB-DB-002 waived: <reason> -->` on the column.

---

### RUB-DB-003: Multi-step write declares transaction boundary

**Status**: Grounded (2 supporting instances across rounds 5, 6 of email-sources)
**Mechanicality**: Borderline — "two or more distinct write steps" requires parsing Behaviour descriptions to count writes. The auditor should only flag operations whose documentation explicitly describes sequential write steps (numbered steps, named sequential operations). Do not infer write counts from prose descriptions.

**Principle**: Every operation that performs multiple writes (inserts, updates, or deletes across one or more tables) must declare its transaction boundary — whether the writes are atomic (single transaction) or non-atomic (with stated consistency semantics).

**Rationale**: Without a declared transaction boundary, the implementer must infer atomicity. If they guess wrong, partial-write states leak into the database on failure. This is distinct from the universal pattern (RUB-UNI-006 invariant enforcement) because it applies specifically to multi-step database writes, not to general invariants.

**Precondition**: Spec documents an operation (in Interface or Behaviour sections) that performs two or more distinct write steps.

**Check**: The operation's documentation includes one of:
- An explicit atomicity declaration ("atomic", "single transaction", "all-or-nothing").
- An explicit non-atomicity declaration with stated consistency semantics ("writes are independent; partial completion is acceptable because...").

**Fix template**: Add an atomicity declaration to the operation's documentation.

**Waiver**: `<!-- rubric:RUB-DB-003 waived: <reason> -->` on the operation.

---

### RUB-DB-004: Conditional nullability has DDL enforcement

**Status**: Grounded (2 supporting instances across rounds 1, 3 of email-sources)

**Principle**: When a column is declared as conditionally required (nullable in general but required when another column has a specific value — a discriminator-dependent NOT NULL), the conditional constraint must have DDL-level enforcement via a CHECK constraint, not just application-layer validation.

**Rationale**: Application-layer validation of conditional nullability can be bypassed. The DDL CHECK is the only mechanism that holds under migrations, backfills, and raw SQL.

**Precondition**: Data Model section declares a column as nullable with a conditional requirement — typically expressed as "required when [discriminator] = 'value'" or "NOT NULL if [condition]".

**Check**: A CHECK constraint enforcing the conditional NOT NULL exists on the table — e.g. `CHECK (discriminator != 'value' OR nullable_column IS NOT NULL)`.

**Fix template**: Add the CHECK constraint to the table definition.

**Waiver**: `<!-- rubric:RUB-DB-004 waived: <reason> -->` on the column.

---

## Catalogue Growth

New database-backed rubrics are added when review rounds surface patterns that:
- Are universal across database-backed components (not specific to PostgreSQL, MySQL, etc.)
- Have at least 2 supporting instances across rounds or components
- Are mechanically checkable from the spec's Data Model and Behaviour sections

Rubric IDs are append-only. Retired rubrics are marked RETIRED rather than renumbered.
