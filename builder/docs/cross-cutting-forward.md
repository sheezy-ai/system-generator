# Forward Commitments to Cross-Cutting Specs — RETIRED

**This methodology is retired.** It presupposed a step-0 cross-cutting-**spec authoring/ratification** pass that was never built and is not intended: cross-cutting *design* is authored upstream in Architecture §7 / Foundations, and `cross-cutting.md` is a downstream **contract registry** only (populated post-hoc by the cross-cutting population workflow).

The problem this rule reached for — how a component spec places a **non-contract requirement across a boundary** — is now handled by two first-class dispositions plus the contract registry:

- **Push up to Architecture / Foundations** — cross-cutting invariants and shared design decisions that no single component owns (`CROSS-BOUNDARY-UPSTREAM`, `AWAITS_UPSTREAM_REVISION`).
- **Document as a component-stage integration requirement** — a non-contract requirement on a peer component, recorded as components are developed (`CROSS-BOUNDARY-PEER`, lateral to the peer's `pending-issues.md`, consumed at its review).
- **Data contracts** — the `cross-cutting.md` registry / CTR machinery (unchanged).

The one thing that disappears is the *step-0 cross-cutting-spec author* as a distinct ratifying party — it never existed. Its two real audiences (the Architecture author at the next revision; the owning component's review) are exactly the two dispositions above. The retired `forward-cross-cutting/[target-spec-name].md` inventory (created → ratified/normalised/rejected) is no longer used; any surviving references in project data are legacy.

See **`cross-boundary-requirements.md`** for the current model, and `DEFECT-cross-boundary-requirements.md` for the history.
