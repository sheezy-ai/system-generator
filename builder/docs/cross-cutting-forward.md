# Forward Commitments to Cross-Cutting Specs

This rule governs how downstream specs commit content to a cross-cutting spec that has not yet been authored. It applies across stages and is generator-wide methodology.

## Authority Direction

The system-generator holds **architecture → downstream** as the binding authority direction. Architecture decisions bind component specs. Component specs do not bind architecture, and a component spec's commitment to a not-yet-authored cross-cutting spec does not bind that future spec.

The reverse direction — **downstream → architecture** or **downstream → cross-cutting spec** — is **proposal-only**. A downstream spec may surface concrete content (constraints, contract obligations, seed material, pending decisions) intended as input to a future cross-cutting spec, but the future spec's author is the ratifying authority.

## Forward Commitment

A *forward commitment* is content authored in a downstream spec (typically a component spec) that is intended to be ratified by a cross-cutting spec which does not yet exist. Examples:

- Action-type taxonomies contributed to a future audit-trail spec.
- Contract obligations a future Source Attribution spec must carry.
- Posture decisions (e.g., transactional consistency, retention) a future cross-cutting spec must adjudicate.
- Cleanup obligations that fire when the future spec is authored.

A forward commitment is recognisable by being a claim about another spec's content, not the originating spec's own content.

## Recording Forward Commitments

Forward commitments are inventoried per-project at:

```
system-design/05-components/versions/forward-cross-cutting/[target-spec-name].md
```

One file per future cross-cutting spec. The file is created when the first commitment to that target is made. Each file carries a framing paragraph (proposal framing — see below), an `## Inputs to ratify` section, and a `## Cleanups when ratified` section.

The inventory does not duplicate canonical content — entries are pointers to originating spec sections with one-line summaries.

The standard `pending-issues.md` register is *not* the home for forward commitments. That register is a discrepancy log between existing documents (UNRESOLVED → RESOLVED). Forward commitments have a different lifecycle (created → ratified-or-rejected) and a different audience (the future spec author, not the upstream stage's author).

## Ratification

When the target cross-cutting spec is authored (per Architecture §6 spec creation order), the spec author opens the relevant inventory file and treats each entry as proposal input. For each entry, the author chooses to:

- **Ratify** — incorporate the proposal into the cross-cutting spec; mark the inventory entry retired with the authoring round ID.
- **Normalise** — adapt the proposal (e.g., rename a taxonomy convention) before incorporation; mark the entry retired with a note describing the normalisation; downstream specs whose originating commitment was normalised away are rewritten.
- **Reject** — decline the proposal; mark the entry rejected with a reason; the originating downstream spec is rewritten.

Ratification status is recorded in the inventory entry itself.

## Non-Ratification Fallback

If the cross-cutting spec author rejects (or normalises away from) a forward commitment, the originating downstream spec rewrites to match the ratified cross-cutting contract. The architecture document and the cross-cutting spec are *not* silently amended to honour an unratified downstream commitment.

This preserves the authority direction. Accepting an unratified downstream commitment would invert authority (downstream binds architecture) and is the failure mode this rule exists to prevent.

## Inventory Framing Paragraph

Each per-target inventory file should open with the proposal framing, e.g.:

> Entries below are proposals from originating component specs to the future author of this cross-cutting spec. Ratification is the future spec author's decision at authoring time. Non-ratification means the originating spec is rewritten, not that this inventory binds the future cross-cutting spec or the architecture.

## Cross-References

- `pending-issues-format.md` — the per-stage discrepancy register (separate concern).
- `agents/universal-agents/alignment-verifier.md` — SYNC_UPSTREAM / FIX_DOCUMENT classification (catches downstream-vs-upstream discrepancy for *existing* documents).
- `workflow-review.md` — the Review workflow that may surface forward commitments via expert review or alignment verification.
