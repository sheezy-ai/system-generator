# Design: Gate 02/03 Promote Behind Review (remove create's inline publish)

**Status:** DESIGN v2 — independent review complete; **approach validated (reviewers could not break it)**. Findings folded in: 01-blueprint scope correction (§5/§8), expanded cleanup scope (§5), false-today load-bearing statements (§3). One open decision: whether to include 01-blueprint now (§8).
**Date:** 2026-07-20
**Supersedes the approach in** `create-side-alignment-routing-scope.md` (Option A "route at create" — rejected; see §7).

---

## 1. Problem

The document-stage **create** workflows drop Alignment-Verifier `SYNC_UPSTREAM` findings on ACCEPT (they present FIX/ACCEPT and, on ACCEPT, proceed to finalise). The original concern was re-litigation. Investigation found the real defect is sharper and structural for **02-prd and 03-foundations specifically**:

**02/03 create promotes the canonical doc INLINE.** Their terminal step does `cp [draft] → prd.md` / `foundations.md` (`02/create/orchestrator.md:886`, `03/create/orchestrator.md:575`), publishing with `Status: COMPLETE` and **no review in between**. Downstream stages then consume it (`03 create` reads `prd.md`; `04` reads both). So a dropped `SYNC_UPSTREAM` finding at 02/03 create is **published and consumed before anything can re-detect it** — closer to loss than re-litigation.

This inline `cp` also **directly contradicts 02/03's own promote stage**, which claims to be the *"sole producer of prd.md / foundations.md"* (`02/03 promote:9`) and enforces a *"Review-mandatory guard — structural, not convention"* (`02 promote:134`). Create's inline write is a **second writer that defeats that structural guarantee.** This is an **incomplete migration** to the 04/05 model (where create finalises a draft and the review-gated Promote stage is the sole producer), not intentional design.

**04 and 05 do not have this problem:** `04 create` "does **not** produce a promoted `architecture.md` … the Promote stage's promoter is the sole producer, and Promote requires a completed Review round" (`04/create/orchestrator.md:980`); `05 create` "does **not** write `specs/[component].md`" (`05/create/orchestrator-router.md:470`). Their create-side drop is genuinely backstopped by the mandatory review (which — post the log-only fix — now routes the finding). So 04/05 need no change here.

---

## 2. Decision

**Complete the migration: 02/03 create finalises a draft and hands to Review; it does not publish.** The already-existing, already-review-gated 02/03 Promote stage becomes the actual sole producer (as it already claims to be). Then the created doc goes through review before it is canonical, and the **review-side alignment routing we already shipped** logs any `SYNC_UPSTREAM` findings to the upstream register — no create-side routing needed.

This fixes the create-side alignment gap for 02/03 **and** closes the latent correctness bug (the false "sole producer" / bypassed "structural review-mandatory guard").

**Rejected: Option A ("route at create")** — see the superseded scope doc. Its independent review found it BROKEN in two ways (the staleness cleanup can't see a downstream FIX → inverted re-litigation at the frozen upstream; the 05 AFF-detector double-log) plus resolver-reuse provenance issues and a missing REJECT disposition. Direction 1 sidesteps **all** of those because it adds no create-side register write.

---

## 3. Why it's safe (verified)

- **02/03 review sources the create DRAFT, not the published doc.** `02 review:22` sources `versions/round-{N}-create/03-updated-prd.md` (or `00-draft-prd.md`) and `:26` says *"Never use the promoted file (`prd.md`) as input."* Same for 03 review. So removing the inline `cp` does **not** break review's input — the create→review→promote chain is already fully built for 02/03, identical to 04.
- **Downstream consumers are unchanged** — they still read the published `prd.md`/`foundations.md`; it is simply produced by Promote (after review) instead of by create. No consumer edit needed.

---

## 4. The one behavior change (human-approved)

After this, **02/03 review + promote become mandatory before `prd.md`/`foundations.md` exists and is consumable downstream.** Today the inline `cp` lets a user skip review and proceed to the next stage on an unreviewed doc; the fix closes that. This is precisely the *"structural, not convention"* enforcement the promote guard already intends — but it is a workflow change (no more create-then-immediately-proceed without reviewing). **Signed off by the human on 2026-07-20.**

---

## 5. Change plan
- **`02/create/orchestrator.md` Step 11 "Promote"** (`~:874-895`): replace "determine final draft → `cp` → verify → COMPLETE" with **"Finalise & Hand to Review"** — determine the final draft path, set `Status: COMPLETE` (Current Workflow: Create), **no `cp`**. Mirror `04 create` Step 12. **Preserve** the step's non-cp work: the "**Check downstream deferred items**" (`02:893`) and the human-facing summary.
- **`03/create/orchestrator.md` Step 8 "Promote & Report"** (`~:567-591`): same, preserving `03:582` "Check downstream deferred items".
- **Language cleanup (bigger than orchestrators — grep-driven, must be complete):**
  - **Load-bearing corrections (FALSE TODAY, not merely stale):** `02 create:927` and `:989`, `03 create:611` and `:659` all say *"The Review workflow reads from `prd.md`/`foundations.md` … MUST exist before Review."* This is **already false** — review sources the create draft and explicitly forbids reading the published file. Correct these to the truth; a reader trusting them preserves exactly the wrong invariant.
  - **Orchestrator prose/state-step names:** every "Promote" step title, "Promoted output", "You COPY … (promotion)", output-dir "# Promoted from create", and the dead "Failed to copy … to prd.md" error rows in `02/03 create`.
  - **docs/ layer (must extend here too):** `docs/02-prd.md:81,86,94,96` and `docs/03-foundations.md:198` still say create promotes. Note `docs/02-prd.md:169` is **already migrated** to the new model — so that file is currently self-contradictory; reconcile it.
- **Unchanged:** the 02/03 Promote stage (already sole-producer + review-gated), 02/03 Review (already sources the create draft), all downstream consumers, 04/05 (verified: they already hand to review, no inline publish).

---

## 6. Open questions for the reviewer (verify against the code — do not trust this doc)
1. **Completeness of writers:** is the inline `cp` at 02/03 create the *only* place create/expand publishes `prd.md`/`foundations.md`? Do the **02/03 EXPAND** workflows also `cp`-publish inline (same bug, and thus in scope), or do they hand to review like 04 expand? Enumerate every writer of the two canonical paths.
2. **Terminal-step residue:** does 02/03 create's terminal step do anything besides `cp` + verify + state-update that must be preserved when it becomes "hand to review" (e.g., a report, a downstream trigger, a state field other stages read)?
3. **Is the 02/03 Promote stage actually exercised / complete?** If create always published inline, the 02/03 Promote workflow may rarely/never have run. Does it end-to-end source the review output (`05-updated-prd.md`) and publish correctly, or does it have latent gaps (paths, split logic) that this change would newly expose?
4. **Dangling references after removing `cp`:** does anything (state machine, error messages, another stage's precondition check, docs) assume 02/03 `prd.md`/`foundations.md` exists immediately after create rather than after promote?
5. **First-run bootstrapping:** on a brand-new project, 03 create's precondition is "Check PRD exists at `prd.md`" (`03 create:182`). After the fix, `prd.md` exists only after 02 create→review→promote. Confirm there's no chicken-and-egg (e.g., a first-run path that expected create to publish).
6. **01-blueprint:** ~~confirm out of scope~~ — **RESOLVED by review: mis-classified.** 01 HAS a review-gated promote (folded into review as Step 9, `01 review:527,543`) AND 01 create inline-publishes (`01 create:950 cp → blueprint.md`) — the **same second-writer bypass** as 02/03, minus the alignment half (01 has no upstream/alignment). See the §8 decision.

---

## 7. Why not Option A (for the record)
Option A routed the finding at create (reusing the log-only resolver). Its review found: the Consolidator staleness cleanup keys on the *upstream* quote and cannot see a *downstream* FIX, so a create-logged entry orphans live and re-litigates at the frozen upstream (BROKEN); 05's general-alignment route double-logs with the AFF detector (BROKEN); the resolver hardcodes "Review workflow" provenance and has a dead `LOG_DOWNSTREAM` branch at create (WEAK); and create had no REJECT/WONT_FIX disposition for the verifier's expected over-flagging (gap). Direction 1 avoids every one of these by not writing to a register from create at all.

---

## 8. Open decision: include 01-blueprint now, or defer it?

Review found 01-blueprint has the **same inline-publish-bypasses-review-gate bug** as 02/03 (`01 create:950` writes `blueprint.md`; `01 review:527` Step 9 is the review-gated promote). It differs in two ways: (a) 01 has **no upstream/alignment**, so the *alignment-finding-loss* motivation does not apply — only the *"user can skip review and build downstream on an unreviewed doc"* half (02 create reads `blueprint.md` as its Round-1 upstream, so an unreviewed Blueprint propagates); (b) 01's promote is a **review step (Step 9)**, not a separate `promote/` stage — so the fix mechanics differ slightly (remove `01 create:950 cp`; make create hand to review; 01 review Step 9 stays the sole publisher).

**Options:**
- **Include 01 now** — removes *every* inline-publish bypass; no lone exception; uniform "create never publishes; review-gated promote is sole producer" invariant across 01-05. Slightly more surface (01's different structure).
- **Defer 01 (explicitly, with reasoning)** — 01 lacks the alignment motivation and is the bootstrap stage (seed from informal `concept.md`); fix 02/03 now, log 01 as a known sibling instance.

**Recommendation: include 01** — leaving one inline-publisher is the kind of lone inconsistency that gets rediscovered and re-litigated later (and this whole thread exists because of one such incomplete migration). But it is genuinely the human's call, since 01 carries only the correctness half of the bug and is the entry stage.

**DECISION (2026-07-20): DEFER 01 — it cannot be done cleanly.** Investigation found 01 create's Step 11 (cp publish) is **not terminal**: **Step 12 "Scope Extract" reads the *published* `blueprint.md`** (`01 create:964`) to produce `scope-brief.md` + the downstream deferred-items that seed the whole pipeline, and scope-extract is duplicated in 01 review Step 9 (`01 review:96`). Removing the `cp` breaks Step 12; fixing it requires re-pointing Scope Extract to the draft or relocating it into review — touching downstream-pipeline-seeding semantics, a materially larger change than the pure terminal-`cp` removal for 02/03. Per the human's "include only if clean" condition, 01 is **deferred** and logged here as a known sibling instance (it carries only the correctness half of the bug — no alignment findings — so the urgency is lower). A future pass can address 01 + the Scope-Extract relocation together.

**Final scope: 02-prd and 03-foundations only.**
