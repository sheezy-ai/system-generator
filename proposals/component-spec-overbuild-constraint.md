# Proposal: Constraining Spec Generation Against Over-Build

**Status:** DRAFT FOR APPROVAL — nothing in the workflow has been changed.
**Scope:** The Component Spec **create** and **review** workflows (`agents/05-components/*` + the universal agents they call). Generalises to all components; not entities-specific.
**Author:** Claude, 2026-06-30

---

## 1. Problem (evidence-grounded recap)

The workflow has a **net-positive growth equilibrium**: additions are unconditional and start at round 1; the one subtraction force is advisory, starts late, and decays.

| Force | Status today | Evidence |
|---|---|---|
| **Additions** (concern→enrichment→generate; depth-checker "make deeper") | Mandatory, every round from round 1 | entities grew 929 → 2,090 lines; 11 → 34 exception classes; 16 → 35 error codes |
| **Subtraction** (stage-appropriateness verifier → remediator) | **Advisory**, first appears round 4, **decaying** | applied removals fell 15 → 11 → 6 → 2 across rounds 4–7; §9 ~40-row table flagged over-spec in R6 *and* R7, retained both times |
| **Inflow gate** (`enrichment-scope-filter`) | Altitude-only, no maturity/phase axis | "0 deferred, 0 filtered out" for obs/error in **every** round |
| **Maturity awareness on generation side** | Absent | only 2 of ~13 create agents read the maturity guide; only the advisory verifier reads `project-scale.md` |

**Two findings that frame the fix:**

1. **Weight ≠ critical-input coverage.** The 2,090-line spec still *missed* a genuine consumer contract (review SPEC-013: `NotFound` return type undefined). Heaviness did not buy completeness on the thing that mattered. The two are independent axes.
2. **The maximalism is agent-authored, human-ratified** (0 enrichments rejected, rounds 1–7). So the lever is **not** "the operator should ask for less" — even a neutral operator lands at the same equilibrium. The fix must be structural.

**Root cause, one line:** *the workflow models "incomplete" as a mandatory defect and "overbuilt" as an optional suggestion.*

---

## 2. Design principles

1. **Symmetry.** "Overbuilt" must be a first-class, **binding** defect with the same force and the same timing (round 1) as "incomplete."
2. **Defer, don't delete.** Disposal of over-scope content is **relocation with a record**, never silent loss. This is what makes aggressive constraint safe — the worst case of a mis-deferral is "it's in an inbox," not "it's gone."
3. **Criticality discipline.** Never defer (or delete) a **consumer-binding contract** or a **corruption/data-integrity invariant**. These are protected by the derivation test. Deferral is for *derivable* / *internal* / *later-phase* content only.
4. **Generalise via existing artifacts.** Anchor every gate on the maturity guide, `project-scale.md`, the PRD phase/scope model, and the pending-issues plumbing — all of which exist for every component.

---

## 3. The disposal taxonomy (bias to defer over delete)

Every candidate addition (create-side enrichment) and every raised issue (review-side) is routed to exactly one of:

| Route | Destination | Use when | Guard |
|---|---|---|---|
| **KEEP** | this spec, this phase | consumer-binding contract, corruption invariant, or implementer-non-derivable commitment | default for consumer-facing content |
| **DEFER_UPSTREAM** | Architecture / Foundations `pending-issues.md` | content changes component boundaries / system conventions | already exists |
| **DEFER_FUTURE** | an in-draft **"Future Developments"** section of the spec (extracted to a central `future.md` by the spec-promoter at promotion) | genuine future need, not this phase (per PRD "Not in Scope for MVP") | **new** on create side; reuses Author + promoter, no mid-pipeline file plumbing |
| **DELEGATE_IMPLEMENTER** | nowhere (stays out of design docs); spec carries an *explicit-latitude* note | implementer can derive it from context (derivation test = Yes) | convert, don't drop: state contract commitment + named delegation + pointer |
| **FILTER_CODE** | discarded | raw code / pseudo-code | already exists |
| **DELETE** | discarded | genuinely valueless | rare; requires explicit justification |

**The criticality test gates the whole table:** an item is eligible for any DEFER/DELEGATE/DELETE route **only if** it is not a consumer-binding contract and not a corruption invariant. If it is, it's KEEP regardless of weight.

**Note — there is no design-stage "downstream" for component specs.** Component Specs are the lowest design stage; their only stage-downstream is the codebase, which is `DELEGATE_IMPLEMENTER` (explicit-latitude). Deferring to *another component's* spec (a lateral peer, e.g. entities→pipeline) is a separate, pre-existing mechanism — the `pending-issues.md` lateral inbox — that resolves **misplaced ownership**, not over-build. It is out of scope for this proposal and left unchanged. For the over-build problem, over-scope content routes overwhelmingly to `DELEGATE_IMPLEMENTER` (the implementer decides the internal enum / test mechanism) or `DEFER_FUTURE` (a real later-phase need).

---

## 4. The changes

### A. Inflow gate gets a maturity/phase axis + deferral routes

**`create/enrichment-scope-filter.md`** and **`review/issue-router.md`**:
- Read `project-scale.md`, the maturity guide, and the PRD phase/scope section (currently none do).
- Replace the altitude-only classification with the §3 disposal taxonomy.
- Flip the bias for *internal-only, non-critical, above-phase* content from "uncertain → KEEP" to "uncertain → DEFER (to the cheapest-to-recover route)" — **while keeping** "uncertain → KEEP" for consumer-facing content. Criticality discipline preserved.
- Output: per-item route + reason; DEFER_FUTURE items are written into the draft's "Future Developments" section (§6).

### B. Make excess a binding defect, symmetric with coverage/depth

Two options (recommend B1):

- **B1 (reuse):** Promote the existing `stage-appropriateness-verifier` from *advisory lens* to a **binding excess-gate**: run it **every round from round 1** (not round 4+), and route its `IMPLEMENTATION_LATITUDE` / `RESTATES_UPSTREAM` findings into the gap-resolution loop as **removal-gaps the Author MUST act on** (apply = convert to explicit-latitude or defer per §3), with the same status as coverage/depth gaps. Flip its "APPROPRIATE-when-uncertain" default to "IMPLEMENTATION_LATITUDE-when-uncertain" **for internal-only content only**; keep APPROPRIATE-default for consumer-facing.
- **B2 (new agent):** Add a dedicated `excess-checker` symmetric with `coverage-checker` / `depth-checker`. More moving parts; only if we want excess kept separate from altitude.

### C. Give the depth-checker a ceiling

**`create/depth-checker.md`**: today it only has a floor (`SHALLOW` vs `DEEP_ENOUGH`). Add a **maturity-aware ceiling**: a `TOO_DEEP` / `OVER_SPECIFIED` verdict for elements deepened past what the phase requires (e.g. exhaustive internal enum enumeration, per-row emission tests at MVP). Wire in `project-scale.md`. This stops the "deeper is always better" ratchet on *existing* elements (deferral only caps *new* inflow).

### D. Two-sided exit condition

**`create/orchestrator.md`** and the **review router**: promotion requires **"no gaps AND no excess AND no unrouted deferrable items"** — not the current one-sided "no gaps." This is the structural change that ends the ratchet.

### E. Generation-side maturity wiring

Give **`generator`**, **`coverage-checker`**, and **`concern-identifier`** (already round-aware) the maturity/phase context so over-scope content isn't generated in the first place — cheaper than removing it later.

### F. Existing doctrine stands (no reversal needed)

`issue-router`'s rule — *"escalate upstream, not deferred downstream"* — is **left intact**. `DEFER_FUTURE` is a phase/time deferral, not a downstream-stage deferral, so it doesn't conflict with that doctrine. (An earlier draft proposed reversing this for a `DEFER_DOWNSTREAM` route; that route has been dropped — see §3 note.)

---

## 5. Risks & mitigations

| Risk | Mitigation |
|---|---|
| **Deferral becomes a dumping ground** → under-spec critical inputs | Criticality test gates every defer route (§3 guard). Never defer a consumer contract / invariant. Audit: a deferral that later returns as a HIGH under-spec finding is a calibration miss to review. |
| **Over-correction into under-spec** (the operator's stated fear) | Convert-to-explicit-latitude (DELEGATE) instead of delete; defer (recoverable) over delete; keep APPROPRIATE-default for consumer-facing content. |
| **Phase model drift** | Single source of truth = PRD "Not in Scope for MVP" + `project-scale.md`; gates cite it, don't re-derive it. |

---

## 6. Future-backlog plumbing (for DEFER_FUTURE)

Lightweight, and aligned to the existing promotion step (per the operator's design note):

- **During the create pipeline**, DEFER_FUTURE content is written to a dedicated **"Future Developments"** section *inside the draft spec* — not an external file. The Author already owns the draft, so there's no new mid-pipeline file plumbing, and deferred items stay visible/reviewable in-context each round.
- **On promotion**, the `spec-promoter` **extracts** that section into a central `future.md` (created on first promotion, appended thereafter), carrying provenance: source spec, round, ENR/issue ID, reason. So `future.md` is an *output of promotion*, not something the rounds write to directly.
- It is a backlog reviewed at **phase boundaries** (Phase 1a→1b, etc.) — no inter-spec consumption check needed.
- The lateral `pending-issues.md` mechanism is unchanged (ownership routing only — see §3 note).

*Confirm at implementation:* whether the component guide already defines a "Future Developments" / growth-path section convention (the maturity guide references one), and add the extraction step to `spec-promoter`.

---

## 7. Implementation mechanics (when approved)

- **Edit `agent-sources/`, not `agents/`.** The prompt files I read under `agents/05-components/...` are **build outputs**; the editable sources live in `agent-sources/` and are compiled by `build-prompts.sh`. All prompt edits in §4 go to the source files, then rebuild. *(To confirm at implementation time: that each of these create/universal agents has a corresponding `agent-sources/` entry.)*
- Orchestrator/exit-condition changes (§D) and plumbing (§6) likewise edit sources + rebuild.
- No edits to any promoted spec as part of this proposal — this changes the *generator*, not the *output*.

---

## 8. Rollout & validation

**Strategy: regenerate the component-spec layer from scratch through the fixed workflow** (component-only — §10.3). Preconditions: `project-scale.md` exists ✓; a central `future.md` must be **established** (DEFER_FUTURE target — does not exist yet); component inventory taken from the **current Architecture**. Existing promoted specs are **archived, not deleted** (institutional memory + old-vs-new comparison). The in-flight entities Round-9 review is **superseded** by the regenerate decision.

1. **Entities first = the proof gate.** Regenerate entities through the fixed workflow and compare against the known-heavy baseline (the 2,090-line promoted spec). Only proceed to the rest if the success metric holds.
2. **Success metric (empirical, falsifiable):**
   - Net spec growth goes **flat or negative** round-over-round, **and**
   - consumer-contract coverage stays complete — **no increase in under-spec HIGH findings** (the SPEC-013 class). If deferral starts producing new under-spec HIGHs, the bias is too aggressive — tighten the criticality gate.
3. **Calibration loop:** track per-route deferral decisions and whether deferred items later return as real needs (good) or were genuinely unnecessary (also good) vs were critical and mis-deferred (the failure to catch).

---

## 9. Recommended sequencing

1. **Core (highest leverage):** §A inflow maturity/phase axis + §B1 binding excess-gate + §D two-sided exit. This alone flips the equilibrium.
2. **Then:** §C depth ceiling + §E generation-side wiring (reduce inflow at source).
3. **Then:** §6 in-draft "Future Developments" section + `spec-promoter` extraction to `future.md`.

---

## 10. Decisions (resolved 2026-06-30)

1. **Excess-gate mechanism: B1** — promote the existing universal `stage-appropriateness-verifier` to binding (run every round from round 1; findings become removal-gaps the Author must act on). Chosen over a new agent because the verifier is already universal and only invoked by components today, so promotion is contained *and* reusable at other stages later.
2. **Deferral aggressiveness: conservative** — lean KEEP; defer only clear-cut above-phase content; tighten with calibration data.
3. **Scope: component specs only, from scratch** — regenerate the component-spec layer through the fixed workflow; do **not** touch upstream stages (Architecture R30 / Foundations / PRD), which have not been diagnosed as over-built. Inventory of components to regenerate is driven by the **current (Round 30) Architecture**, not the legacy promoted-spec set (e.g. `internal-source` was dissolved and is not regenerated).
4. **Home: `system-generator/`** — proposal + changes live with the workflow they modify.
