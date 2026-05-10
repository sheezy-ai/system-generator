**Issue Demonstration Requirement**

For each issue, you must demonstrate concretely what goes wrong if it is not addressed in the document being reviewed (rather than deferred to a downstream stage or post-build remediation). Every issue must contain three parts:

1. **Document evidence**
   - If the gap is in what the document says: quote the specific words or passages that produce the problem.
   - If the gap is in what the document fails to say: identify exactly what is missing, name the section(s) where you searched and would have expected to find it, and state what its absence implies.

2. **Affected role and plausible action**
   - Name a specific real-world role that reads this content to act on it: a component spec author, an implementer building a module, an operator running a procedure, a founder making a decision. Pick whichever role actually consumes the affected content. Workflow agents that report rather than act are not valid roles.
   - Name the specific action the role would plausibly take under the problematic reading. The action must be concrete enough that you could later verify whether it happened (e.g., "the spec author would specify read access to attribution tables as direct events-table queries" — not "the spec author would build wrong").
   - **Internal contradictions**: when two sections directly contradict and readers cannot determine which is binding, name both readings and the conflicting actions each would produce. You do not need to predict which reading dominates.

3. **Wrong outcome**
   The action would produce one or more of:
   - **Upstream conflict**: cite the upstream requirement or convention violated, by section, with quoted or tightly paraphrased text sufficient to verify the conflict.
   - **Internal document conflict**: cite the specific other-section commitment the action contradicts, by section, with quoted text.
   - **Downstream rework**: name the specific downstream artifact (spec, component, integration contract) that would need to be redone and the specific change required. Generic "would be costly to fix later" does not pass.
   - **Risk realisation**: name the specific risk class for this issue (security risk, data loss, cost overrun, regulatory exposure, brand impact, performance degradation, or other — name your actual class) and trace the chain from the unaddressed gap through at least one threat actor or failure mode to the materialised harm.

If any of the three parts is missing or fails its criteria, the issue does not pass the threshold and is not raised.

**Uncertainty**

When uncertain whether an issue meets the threshold, err on the side of suppression. If the three-part demonstration is not sharp, the issue is not yet ready to raise. This is the opposite of the downstream scope filter's "when uncertain, keep" posture — at the issue-raising stage, the bar is quality, not coverage.

**Challenging upstream decisions**

If you believe an upstream decision (PRD, Foundations, or prior-stage commitment) is technically unsound or materially worse than an alternative, raise this. The three-part demonstration applies, adapted: the affected role is the architect or spec author inheriting the upstream decision; the plausible action is the architectural or spec commitment that follows from inheriting it; the wrong outcome names at least one specific downstream consequence (e.g., "three components inherit incompatible retention horizons"). Mark such issues explicitly as upstream-challenging so they can be routed.

**On document state**

Round number does not affect the threshold; only the issue's concrete consequence does. A round-1 document with many concrete consequences produces many issues. A round-22 document with few concrete consequences produces few issues. The criterion is intrinsic to each issue.

**On severity**

Issues that pass the threshold have at least MEDIUM impact (they have a named concrete consequence). Severity is assigned as follows:

- **HIGH**: the consequence is implementation-blocking, names a security risk class, or would require rework spanning multiple components or specs.
- **MEDIUM**: the consequence is real and named but addressable by a single component spec author or operator without rework cascade.
- **LOW**: the consequence is real but minor — typically a single sentence or row edit at the current document's level, with no downstream rework. If you cannot articulate the minor consequence concretely, do not raise the issue as LOW.

These definitions override any softer severity language elsewhere in your prompt (e.g., "would improve but not critical" is not sufficient to raise as LOW under this threshold).

**Active absence-search (before finalising)**

Absence-spotting is harder than contradiction-spotting. Contradictions are reactive — you find them while reading. Absences require you to construct what's missing and notice it isn't there. Before concluding your review, walk the document for orphaned commitments where one half of a pattern is specified and the other half is silent. In your domain, check at minimum:

- **Interface symmetry**: every named interface has both read and write surfaces specified, or explicit asymmetry rationale. If an interface has multiple operations, check each operation individually — operation A may be fully specified while operation B is half-specified.
- **Contract producer/consumer pairing**: every cross-component contract row has both producer and consumer named, even if one is "deferred" or "MVP-empty."
- **Ownership and consumers**: every component that owns data or behaviour has its expected consumers/callers enumerated at the architecture level, or "no consumer at MVP" stated.
- **Cross-component flow paths**: every cross-component data or control flow has an §4 row (or stage-equivalent) or explicit deferral note. Walk the §6 component rows and ask: for each dependency listed, does the corresponding integration appear in §4?
- **Commitment fan-out**: for every commitment in §5 Key Technical Decisions (or stage-equivalent), ask: what does §6 say about this? What does §8 say about this? What does §4 say about callers? An orphan commitment with no fan-out across sections is a candidate absence.

This list is not exhaustive. The principle is: walk the document constructing the *expected* content for each named commitment, then check what's there. Each absence you find is a candidate — apply the three-part demonstration to determine whether it passes the threshold.

Intentional asymmetry is not an absence. If the document explicitly states a one-sided commitment with rationale (e.g., "this interface is read-only because..."), the asymmetry is named, not missing. Absence is when the *expected complement* is silent without rationale.

**Pre-output self-check**

Before writing your output, for each issue:

- (1) Is document evidence quoted (if words present) or precisely located (if words absent)?
- (2) Is the affected role a real-world consumer of the content, and is the plausible action concrete enough to verify?
- (3) Does the wrong outcome cite specific evidence per its branch?

Remove any issue that fails any of the three. An empty review is a valid outcome — only issues that pass the threshold should appear in your output.

**Considered-but-not-raised list (conditional on low issue count)**

If your final issue count is ≤2 (zero, one, or two raised issues), include a "Considered but not raised" section in your output. List the principal candidate concerns you evaluated and why each did not pass the threshold — typically: which part of the three-part demonstration could not be completed, with reference to the specific document content that closes or rationalises the concern.

This requirement is conditional on low issue counts because low-volume reviews carry the highest risk of silent drops without it, an empty or near-empty review provides no audit trail for what the expert evaluated. Reviews with 3+ raised issues do not need this section, but you may include one if useful.

Include candidates you actively evaluated, not exhaustive scans of every possible concern. If you walked the absence-search procedure above and rejected candidates because they didn't pass the three-part test, those are the ones to list. Prior-round concerns in your domain that you confirmed as closed (with citation to the closing commitment) are also valid entries.
