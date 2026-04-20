## Derivation Test — Spec vs Codebase Decision Locus

Before producing content that could be seen as "over-specified," apply the **derivation test**:

> If the implementing agent had this component's contract, scope, responsibility surface, and Foundations conventions in context, could they derive this specific content themselves?

- **Yes** — content is IMPLEMENTATION_LATITUDE. The spec is pre-empting a decision that should sit with the implementer.
- **No** — content is a commitment the contract needs to pin (consumers depend on it, or no amount of component context would make it derivable). Appropriate to pin.

### Three failure modes

1. **Over-specified** — spec pre-decides what implementer could derive. Silent drift; compounds round-over-round.
2. **Silent under-specified** — spec omits content the implementer needs. AI implementers fill silently with plausible choices rather than halt on ambiguity. Not recoverable after the fact.
3. **Explicit latitude** (the target state) — spec pins what the implementer can't derive, and *names* what is delegated. Not by omitting, but by stating: contract commitment + named delegation + context pointer.

### Target — explicit latitude

When content is delegable, **do not omit it**. State the delegation explicitly. Shape:

> "Operation MUST [contract commitment]. [What the implementer decides] is derivable from [context pointer — specific spec section or upstream doc]; the spec does not pin [the delegated detail]."

Example contrast on a refusal log enumeration:
- **Over-specified**: "§9.2 refusal taxonomy: 7 structured reasons with exit codes mapped to each..." [enumerates all]
- **Silent**: [no mention of refusal logging]
- **Explicit latitude**: "§9.2 refusal logging: operation MUST emit a structured Cloud Logging entry on any refusal, carrying `event`, `actor`, `reason_refused`, and reason-specific fields. Implementer determines the enumeration of `reason_refused` values from the guardrails in §3.6; the spec does not pin the enumeration."

### Anti-patterns (drawn from Component Guide — Common Mistakes → Over-specification)

Do **not** produce:
- Python / SQL code blocks where tables or prose descriptions would suffice (dataclass definitions, function signatures with imports, ORM calls, algorithm implementations)
- Restated Foundations conventions (error envelope format, security headers, retry policies, correlation IDs) instead of references to the relevant Foundations section
- "Implementation Reference" sections containing complete or partial code
- Framework-specific annotations (Django `on_delete`, DRF serializer details, Pydantic `Config` classes) instead of schema-level constraint descriptions
- Internal-enumeration specifics whose count and content are derivable from other spec sections (e.g., enumerating guard-layer structures, listing refusal reasons that map 1:1 to earlier-declared guardrails)

### Pre-write self-check

Before finalising output, apply the derivation test to each detail element:

1. Could an implementer with this component's context + Foundations derive this?
2. If yes — convert to explicit-latitude phrasing: keep the contract commitment, name the delegation, point at the context the implementer consults.
3. If uncertain — err toward pinning (APPROPRIATE) rather than silent omission. Over-spec a reviewer chooses to trim is cheaper than under-spec the implementer fills silently.
