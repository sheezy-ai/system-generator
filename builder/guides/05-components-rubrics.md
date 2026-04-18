# Component Spec Rubrics

Structural consistency rubrics applied to a Component Spec before expert review begins.

Rubrics are **mechanical consistency checks** — they enforce patterns that hold by inspection, not by judgment. Each rubric has a precondition (does this pattern exist in the spec?) and a check (does it hold everywhere it should?).

A rubric pre-pass runs the Rubric Auditor agent against a newly created spec. Gaps are surfaced to the human, who decides whether to apply fixes before expert review begins. This prevents mechanical gaps from consuming expert-review rounds.

---

## Design Principle: Universal by Construction

Every rubric in this catalogue is written to apply to any Component Spec in any project in any domain. To stay universal, rubrics key to **properties of the document**, not to the subject matter of the document.

What that means concretely:

- **Not allowed**: rubrics that reference specific section numbers (§3, §8, §11), specific column names ("Raised by"), specific named conventions ("Actor Identity Convention"), or specific tech-stack concepts (DDL CHECK, TEXT column, REST endpoint).
- **Allowed**: rubrics that reference structural patterns a spec can have regardless of domain — internal cross-references, enumerated sets, labelled identifiers, declared invariants, numeric self-descriptions.

When a rubric's check would require domain reasoning ("is this operation idempotent?", "is this log event redacted?"), the rubric is out of scope — those belong to expert review.

**Narrow-and-mechanical beats broad-and-judgy.** A rubric that covers fewer cases but always fires correctly is more valuable than one that covers more cases but sometimes misfires.

---

## Conditional Catalogues

Some patterns are universal *within a category* of components (e.g. database-backed, stateful, network-facing) but not across all components. These live in **conditional catalogues** whose top-level precondition gates their entire contents.

The auditor applies the universal catalogue plus any conditional catalogues whose top-level precondition is satisfied by the spec under audit.

Conditional catalogues known to exist:

| Catalogue | Applies when |
|-----------|--------------|
| `05-components-rubrics-database-backed.md` | Spec declares ownership of database schema (tables, columns, DDL) |

A pattern that isn't universal across all components but is reliably universal within a named category belongs in the relevant conditional catalogue, not in this file.

---

## Evidence Status

Each rubric carries a **Status** field indicating how well-supported it is by observed patterns in actual component reviews. Readers should weigh rubrics accordingly:

| Status | Meaning |
|--------|---------|
| `Grounded` | Pattern observed ≥3 times across rounds/components; rubric is evidence-driven |
| `Speculative` | Pattern observed 1-2 times; rubric is clean but awaits cross-component confirmation |
| `Hygiene baseline` | Not driven by a specific recurring finding; included because any structured document can harbour this class of error |

Speculative rubrics are retained because the pattern is clean and the check is cheap. If cross-component evidence later contradicts their value, they can be retired.

---

## How Rubrics Differ from Review

| Concern | Belongs to |
|---------|-----------|
| Is the algorithm correct? | Expert review |
| Is the error taxonomy the right set of rules? | Expert review |
| Does this reference resolve to something that exists? | **Rubric** |
| Does a convention declared in the spec hold for every subject it enumerates? | **Rubric** (if the property is structurally observable) |
| Does this upstream contract match the current spec? | Alignment Verifier |
| Is the algorithm fast enough? | Expert review |

Rubrics enforce local, structural consistency. They never replace expert judgment.

---

## Waiver Syntax

A rubric instance can be waived with an inline HTML comment adjacent to the flagged pattern:

```markdown
<!-- rubric:RUB-UNI-001 waived: forward reference, resolved in §4 -->
```

The Rubric Auditor honours waivers and does not flag the waived instance. Waivers must state a reason of at least 20 characters of substantive content.

---

## Rubric Catalogue

Rubrics are numbered `RUB-UNI-NNN`. The catalogue grows over time as new universal patterns emerge from review rounds across multiple components.

---

### RUB-UNI-001: Internal reference resolution

**Status**: Hygiene baseline

**Principle**: Every internal cross-reference in the spec resolves to a target that exists elsewhere in the spec.

**Rationale**: An unresolvable internal reference is a dangling pointer. Readers expect `see §4` or `per DD-001` to lead somewhere; if the target doesn't exist, the surrounding statement is load-bearing on a missing anchor.

**Precondition**: Spec contains at least one internal cross-reference. Internal references include:
- Section pointers: `§N`, `§N.M`, `Section N`, `Section N.M`.
- Labelled-element IDs: any `[prefix]-[id]` pattern (e.g. `DD-001`, `SPEC-042`, `REQ-17`, `M-HELLO`, `T4`, `S1`) used as a label in this spec.
- Named element references: code-formatted names (backtick-wrapped) for tables, operations, states, or similar elements defined in this spec.

External references (to other documents such as `Architecture §7`, `Foundations §8`) are **out of scope** for this rubric — they belong to the Alignment Verifier.

**Check**:
1. Enumerate all internal references in the spec body.
2. For each reference, determine its expected target:
   - `§N` → a heading matching section N exists in the spec.
   - `[prefix]-[id]` → an element labelled with that exact ID is defined somewhere in the spec.
   - Code-formatted named element → the named element is defined (in a table, heading, or declaration) in the spec.
3. Flag references whose target cannot be located.

**Fix template**:
- If the target was renamed: update the reference to the new identifier.
- If the target was removed: either remove the reference or restore the target.
- If the reference is genuinely to an external document: reword it to make the externality explicit (e.g. `§7` → `Architecture §7`).

**Waiver**: `<!-- rubric:RUB-UNI-001 waived: <reason> -->` adjacent to the reference.

---

### RUB-UNI-002: Labelled-count matches enumeration

**Status**: Speculative (1 supporting instance in email-sources)

**Principle**: When the spec self-describes a procedure, set, or structure with an explicit count or ordinal label, the enumeration that follows must contain exactly that many items.

**Rationale**: `Two-phase procedure` followed by three enumerated phases is a plain documentation bug. It undermines any determinism or completeness claim that the label implies.

**Precondition**: Spec contains a numerical or ordinal self-description immediately preceding or accompanying an enumeration. Patterns that trigger:
- `N-step`, `N-phase`, `N-pass`, `N-stage`, `N-part`
- `The following M cases / reasons / categories`
- `There are K classes of X`

The accompanying enumeration must be identifiable as an ordered list, numbered subsections, or a table with one row per item.

**Check**: The enumeration contains exactly the count declared in the label.

**Fix template**: Either update the label to match the enumeration count, or add/remove enumeration items to match the label.

**Waiver**: `<!-- rubric:RUB-UNI-002 waived: <reason> -->` on the labelled statement.

---

### ~~RUB-UNI-003~~: RETIRED — Enumerated-set completeness via explicit pointer

**Retired**: the tightened precondition (requiring an explicit structural pointer from the exhaustion reference to the defining enumeration) is necessary for mechanicality but too narrow to match real spec structure. Specs use prose exhaustion claims ("this test covers all rule values"), not explicit pointers ("this test asserts the vocabulary from §8 Table 3"). The rubric would return NOT_APPLICABLE on most specs. The underlying pattern (exhaustion claims that don't exhaust) is real but not mechanically enforceable without domain reasoning.

---

### RUB-UNI-004: Orphan and dangling identifiers

**Status**: Hygiene baseline

**Principle**: Every identifier assigned in the spec is either referenced at least once elsewhere in the spec, or explicitly marked as a stable external handle. Every reference to an identifier resolves to an assignment.

**Rationale**: Orphan labels are debt — they were created for a reason that no longer applies, and the reader cannot tell. Dangling references are bugs.

**Precondition**: Spec uses a labelling convention, evidenced by at least two labels sharing the same prefix (e.g. `DD-001` and `DD-002`).

**Check**:
1. Enumerate all assigned labels in the spec (any `[prefix]-[id]` that appears in a definition or heading position).
2. Enumerate all label references in the spec body.
3. Flag assigned labels that are never referenced (orphans).
4. Flag references that do not resolve to an assigned label (dangling).

Note: this rubric overlaps with RUB-UNI-001 on the dangling-reference side; the overlap is acceptable because RUB-UNI-004 catches typos like `DD-001` vs `DD-01` by insisting on exact label match.

**Fix template**:
- Orphan: reference the label where it's relevant, or remove the label if the element is unused.
- Dangling: repair the reference to a valid label.

**Waiver**: `<!-- rubric:RUB-UNI-004 waived: stable external handle -->` on the assigned label.

---

### RUB-UNI-005: Declared-convention compliance for structurally-observable properties

**Status**: Grounded (4+ supporting instances across rounds 1, 2, 6, 7 of email-sources)

**Principle**: When the spec declares a convention of the form "every X has property Y", enumerates the X-instances, and Y is a named structural attribute, every enumerated X must exhibit Y in its definition.

**Rationale**: A convention the spec declares universally must actually hold for every enumerated subject. Otherwise the convention is a lie the reader will discover by surprise.

**Precondition**: All four must hold:
1. Spec contains a convention statement with universal language (`every`, `all`, `each`) and an enumerable subject set X.
2. The convention names a property Y that each X must have.
3. Y is **structurally observable**: it is a named column in a table, a named field in a declared schema, a named subsection that subjects should contain, or a declared label/marker that subjects should carry.
4. Each subject X has a structured definition in the spec (its own table row, its own subsection, its own schema block).

**Conventions whose property lives only in prose are NOT_APPLICABLE** — checking them requires inference, which is expert-review territory.

**Check**: For each enumerated subject X, locate its structured definition; confirm Y is present in its named structural position.

**Fix template**:
- Add Y to the subject's structured definition, OR
- Remove the subject from the convention's enumeration, OR
- Weaken the convention's universal claim to match reality.

**Waiver**: `<!-- rubric:RUB-UNI-005 waived: <reason> -->` on the enumerated subject.

---

### ~~RUB-UNI-006~~: RETIRED — Structurally-declared invariant has named enforcement

**Retired**: the tightened precondition (requiring invariants in a designated structural position like an Invariants section or labelled block) excludes the finding that inspired it — the actual instance was a timestamp-equivalence statement in narrative prose. Specs state invariants in prose, not in designated Invariants sections. The rubric solves a problem that doesn't occur in practice.

---

### RUB-UNI-007: Deferral statements identify resolver

**Status**: Grounded (3-4 supporting instances across rounds 2, 3, 4 of email-sources)

**Principle**: Every deferral statement in the spec — where the spec explicitly defers a contract, shape, decision, or implementation to another spec or future work — must identify what resolves the deferral.

**Rationale**: A deferral without a resolver is a loose end. The reader knows something is unfinished but not who finishes it, when, or where the resolution will appear. Over time, unresolved deferrals accumulate silently because no one knows which upstream to check.

**Precondition**: Spec contains deferral language in a structural position. Deferral statements take forms such as:
- `deferred to [target]`
- `pending [target]`
- `to be defined by [target]`
- `will be resolved by [target]`
- An explicit `DEFERRED:` or `TBD:` marker

The deferral must appear in a structured position: a table cell, a labelled block, a list item in an Open Questions / Deferred section, or inline with a marker. Casual prose references to future work (e.g. "we may add X later") are NOT_APPLICABLE.

**Check**: For each deferral statement in a structural position, verify it includes a **resolver pointer** — a named target that identifies what resolves the deferral. The pointer must be specific enough to locate: a named spec, a named decision, a numbered creation-order step, a named cross-cutting document, or a specific future phase.

Fail: deferral statements with no resolver ("deferred", "TBD", "pending") or with vague resolvers ("to be determined later", "future work").

**Fix template**: Add the resolver pointer — e.g., change `deferred` to `deferred to cross-cutting Source Attribution spec (Architecture S6 creation order step 0)`.

**Waiver**: `<!-- rubric:RUB-UNI-007 waived: <reason> -->` on the deferral statement.

---

### RUB-UNI-008: Operation return documented as structured shape

**Status**: Grounded (5 supporting instances across rounds 1, 3, 4, 7 of email-sources)

**Principle**: Every operation with a non-void, non-primitive return must document its return value as a structured shape, not as a prose description.

**Rationale**: Prose-described returns ("Confirmation", "Updated entity", "Success indicator") are ambiguous contracts — callers cannot write assertions against them, and two implementers may return different structures for the same prose description. This pattern appeared more frequently than any other across review rounds.

**Precondition**: Spec defines operations (functions, API endpoints, methods, commands) with documented return values. Operations returning void/none, or returning a single named primitive (bool, int, string, UUID, timestamp), are out of scope.

**Check**: For each operation with a non-void, non-primitive return, the return documentation takes one of these forms:
- **(a) Structured shape table**: a table or schema block with named fields and types.
- **(b) Named type reference**: an explicit reference to a named type, table, or shape defined elsewhere in the spec (e.g. "returns the persisted `QualityMetrics` row per §4", "returns `SessionState` as defined above").
- **(c) Typed composite**: inline but typed — e.g. `{source: EmailSource, state_change: StateChangeRecord}`.

Fail: returns described only in prose without a named shape — "Confirmation", "Updated trust status", "Success response", "The created entity".

**Fix template**: Replace the prose return with one of forms (a), (b), or (c). If the return is genuinely a simple acknowledgment with no structure, declare it as a named primitive (e.g. `returns void` or `returns bool`).

**Waiver**: `<!-- rubric:RUB-UNI-008 waived: <reason> -->` on the operation.

---

## Not in the universal catalogue, and why

Several patterns emerged in review rounds but were excluded from the universal catalogue. Some belong in conditional catalogues; others require judgment.

| Excluded pattern | Disposition |
|------------------|-------------|
| Error-rule discriminator test completeness | Not mechanically enforceable without domain reasoning (RUB-UNI-003 was retired for the same reason) |
| Pagination defaults and bounds | Presumes a `limit` parameter pattern — not universal |
| TEXT-column length caps on write-once tables | Database-specific → see `05-components-rubrics-database-backed.md` |
| Enum columns without CHECK constraints | Database-specific → see `05-components-rubrics-database-backed.md` |
| Index supporting documented query pattern | Database-specific → see `05-components-rubrics-database-backed.md` |
| Transaction-boundary declarations | Database-specific → see `05-components-rubrics-database-backed.md` |
| Bidirectional relationship symmetry | Requires domain reasoning about what counts as a "relationship" |

Project-specific conventions can still be enforced via RUB-UNI-005 when the spec expresses them as conventions with structurally-observable properties.

---

## Catalogue Growth

New rubrics are added when review rounds across multiple components surface a pattern that:
- Is observable from document structure alone (no domain reasoning required)
- Has a precondition that distinguishes applicability from non-applicability cleanly
- Has a fix template that does not require design decisions
- Applies meaningfully to at least two components from different domains (stress-tested)

Rubric IDs are append-only. Retired rubrics are marked RETIRED rather than renumbered, with an explanation of why.
