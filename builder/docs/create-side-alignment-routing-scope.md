# Scope: Routing Create-Side Alignment Findings (not dropping them on ACCEPT)

**Status:** SUPERSEDED (2026-07-20) — Option A ("route at create") was rejected after independent review found it BROKEN (staleness cleanup blind to a downstream FIX → inverted re-litigation; 05 AFF double-log) plus resolver-provenance and missing-REJECT gaps. The chosen approach is in **`02-03-promote-gating-fix-design.md`** (gate 02/03 promote behind review — no create-side register write). This doc is retained as the record of why Option A was rejected.
**Date:** 2026-07-20
**Related:** builds on `pending-issue-resolver-log-only-design.md` (the review-side fix). This is the create-side sibling.

---

## 1. Problem

The document-stage **create** workflows (02-prd, 03-foundations, 04-architecture) run the Alignment Verifier during "Creation Verification," which classifies discrepancies `FIX_DOCUMENT` / `SYNC_UPSTREAM` / `REVIEW_NEEDED`. But create presents them to the human as a **binary FIX / ACCEPT**, and on **ACCEPT the finding is dropped** — no register write, no routing:

- 04 create: Step 11b — "For each: FIX (return to Author) or ACCEPT (finalise as-is)? … If ACCEPT: Proceed to Step 12" (`04/create/orchestrator.md:970-973`).
- 03 create: identical — "ACCEPT (promote as-is) … If ACCEPT: Proceed to Step 8" (`03/create/orchestrator.md:561-564`).
- 02 create: identical — "ACCEPT (promote as-is)" (`02/create/orchestrator.md:866`).

The defect: create's binary **collapses the verifier's `FIX_DOCUMENT` vs `SYNC_UPSTREAM` distinction.** A `SYNC_UPSTREAM` finding means "this doc is right, the *upstream* is out of step." ACCEPTing it is a deliberate human judgment that the upstream should change — but that judgment has nowhere to go, so it's discarded.

**This is re-litigation, not data loss.** The mandatory `Create → Review → Promote` gate (Promote errors on an unreviewed draft — `04/promote/orchestrator.md:169-172`) means the created doc goes through review, whose Alignment Verifier re-detects the same persisting discrepancy and — post the log-only fix — routes it. So the finding isn't lost; it resurfaces one stage later and the human **re-decides what they already decided at create.** That wasted decision is the improvement target — the same re-litigation this project keeps working to eliminate.

---

## 2. The precedent that (mostly) settles the design

**05 create already does the right thing for one class of finding.** The **Absent-From-Freeze Detector** (`05/create/absent-from-freeze-detector.md`) handles the contract-absence class by:
- reading the body first, diffing against the frozen registry, and **escalating each absent contract to Architecture's `pending-issues.md` as `CROSS-BOUNDARY-UPSTREAM`** (L17, L61);
- **reading the register to suppress duplicates** (L22) — the same dedup discipline we just built for review;
- on an explicit principle (L11): *"You never register locally … 05 owns status; 04 owns obligations. You escalate upstream via the existing CROSS-BOUNDARY-UPSTREAM channel"* — i.e. the finding is the owning stage's to adjudicate.

So "create-side finding → escalate to the upstream register → read-to-suppress-duplicates → owning stage adjudicates" is a **proven, in-tree pattern**, not a new mechanism. The gap is that the **document-stage creates (02/03/04) have no equivalent** for the general Alignment-Verifier `SYNC_UPSTREAM` class — they drop it. (This mirrors how the log-only fix reused the Consolidator matcher rather than inventing one.)

---

## 3. Design options

**A. Route at create ACCEPT (recommended).** Split create's binary into a three-way disposition for a `SYNC_UPSTREAM` finding — **FIX** (change this doc) / **SYNC** (log to the upstream register, reusing the log-only resolver's `LOG` path) / **DEFER** — mirroring both the review-side vocabulary and the AFF-detector precedent.
- **Pros:** matches the established AFF pattern; reuses the log-only resolver + the review-side menu-build suppression we just built, which *already* handles the create→review double-detection (review sees the create-logged `UNRESOLVED` entry and annotates "already logged", so the human is not re-asked). Immediate upstream visibility.
- **Cons:** 02/03/04 create would write to an upstream register — new for them (though precedented by AFF for 05). Needs the shared matcher available at create.
- **Risk:** if the human later **FIXes** the doc at review (divergence resolved), the create-logged upstream entry goes stale. Mitigated by the staleness gate + the owning stage's Consolidator adjudicating it (it will find the discrepancy no longer holds and close it). Worth confirming this cleanup is graceful.

**B. Record-and-defer.** Capture the create-side ACCEPT decision in a create artifact; have review read it and route/pre-decide without re-asking.
- **Pros:** no register write from a draft-in-flux; the register entry lands at the more-settled review.
- **Cons:** a new create→review decision-handoff mechanism (artifact + reader) — more machinery, and it **deviates from the AFF precedent** (which routes immediately). Doesn't reuse the warm review-side suppression as cleanly.

**Recommendation: A.** It reuses proven, in-tree machinery (AFF escalation pattern + the log-only resolver + the review-side suppression) rather than inventing a handoff, and the double-detection it would otherwise cause is exactly what the suppression we just shipped absorbs. The draft-churn worry that argued for B is weak here: a `SYNC_UPSTREAM` **ACCEPT is a human-ratified decision**, not auto-detected noise on shifting text.

---

## 4. Change plan (Option A)
- **02/03/04 create orchestrators** — the Creation Verification step's alignment handling (`04:970-973`, `03:561-564`, `02:866`): replace binary **FIX/ACCEPT** with **FIX / SYNC / DEFER** for `SYNC_UPSTREAM` (and `REVIEW_NEEDED`) findings. `FIX_DOCUMENT` findings stay FIX-only (no route — correct). SHOWSTOPPER still HALTs (do not disturb).
- **05 create-generate** (`orchestrator-generate.md:330-355`) — same treatment for its general Alignment-Verifier `SYNC_UPSTREAM` findings (which currently "carry forward and note", i.e. drop). Separate from the AFF detector (contract-absence class, already escalated).
- **The SYNC branch routes** to the target upstream register — see the §5 decision on *how* (resolver-reuse vs direct escalation).
- **Reuses unchanged:** the shared matcher, the review-side menu-build suppression (absorbs the create→review double-detection), the Consolidator staleness detection (handles a later-invalidated entry), the HALT path.

---

## 5. Design questions — RESOLVED against the code (one live decision remains)
1. **Route vs record — RESOLVED: route (Option A).** Matches the AFF-detector precedent (`05/create/absent-from-freeze-detector.md:11` — "escalate upstream, the owning stage adjudicates"). The record-and-defer alternative needs a new create→review handoff and deviates from that precedent.
2. **Resolver-reuse vs direct escalation — LIVE DECISION.** Create invokes the resolver **nowhere** today (grep: no `pending-issue-resolver` under `stages/*/create/`). Two options:
   - **(a) Reuse the log-only resolver** from create's SYNC branch. DRY — gets the shared matcher, field synthesis, WONT_FIX/Concern-key, never-silent for free; avoids the *duplicate-matcher drift* round-2 review flagged as the danger. Cost: expands the resolver's invocation surface from review-only to create.
   - **(b) Direct escalation, AFF-style** — create writes the register entry itself (orchestrator step or a small agent), mirroring the AFF detector. Cost: **re-implements** the register-write + dedup logic the resolver already has → the exact drift risk. *Recommendation: (a) reuse the resolver* — the anti-drift lesson from round-2 is the deciding factor; the AFF detector is a separate class (auto-detected, no human decision) so its being direct isn't a reason for create's human-decided findings to be.
3. **Stale-entry cleanup — RESOLVED: handled.** If a create-logged `UNRESOLVED` entry is later invalidated by a review FIX, the owning stage's next-review Consolidator staleness check (`consolidator.md:48-50`, `pending-issues-format.md:203-213`) flags `[QUOTE NOT FOUND]` and it is adjudicated/closed. No new mechanism needed.
4. **05 create — RESOLVED: in scope.** `orchestrator-generate.md:332` carries `SYNC_UPSTREAM` items "do not gate — carry forward and note them" (dropped). In scope for the general-alignment class (the AFF contract-absence class is already handled).
5. **Disposition semantics — RESOLVED.** Only `SYNC_UPSTREAM` and `REVIEW_NEEDED` gain the SYNC/route option; `FIX_DOCUMENT` stays FIX-only (routing a "this doc is wrong" finding upstream would be incorrect).

**The one thing left for the human:** decision 2 (resolver-reuse vs direct escalation). Everything else is settled.

---

## 6. Honest framing
This is a **real improvement, not a correctness hole** — the mandatory review gate backstops loss; what's saved is the re-litigation of a create-time decision. It is lower-value than the review-side fix (no data was being lost) but is the same class of defect and has a proven in-tree pattern to reuse. It deserves its own scope→design→review→implement pass, not a reflexive bolt-on — but the precedent (AFF detector) and the warm machinery make it cheaper than it first looked.
