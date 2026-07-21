# Design Proposal: 05 ORPHANED-Component Retirement (the retire slice of R8)

**Status:** PROPOSAL v4 — two review rounds folded. Round 1 (v1→v2): correctness + integration, both ADOPT-WITH-FIXES (§0). Round 2 (v3→v4): a fresh pass over the consolidated proposal — correctness returned ADOPT-WITH-FIXES, integration/buildability returned **ADOPT**; no HIGH survived, the round-1 folds were verified to hold, and the round-2 fixes (consumer-side registry symmetry, whole-spec sweep scope, LOW nits) are folded (§0b). v3 added §11 (the full decomposition/content-change map) and recorded the Tier-1 content-change path as **already built and human-flagged** (verified in source). **Ready for an implementation decision.**
**Date:** 2026-07-21
**Author:** Claude (with Sean)
**Scope:** the **ORPHANED** action path only. Provides the non-destructive retirement procedure the Tier-2 decomposition-membership detector's ORPHANED output currently HALTs to a human with **no defined procedure** (`04-architecture/promote/orchestrator.md:522-523`). MISSING is already actionable via per-component Create (verified — §2). Re-split / merge / re-parent remain deferred (§8). The rename-stable §6 id (C / R7) remains deferred (§8).

**Relationship to prior work.** This is the **retire slice** of the deferred R8 ("automated incremental 05 re-decomposition action") from `cross-stage-cascade-watermark-design.md` §3.7 / §8-R8. The shipped Tier-2 detector already **detects + auto-proposes** MISSING/ORPHANED and HALTs; this proposal defines what the human then *triggers* for the ORPHANED case. It builds on — does not modify the *behaviour* of — the detector, the contract-registry ownership model (04 owns §7/§8, 05 owns status), the coherence sign-off, and the freshness gates (two small **clarifying** edits to the detector and coherence are needed — §4.3/§6 — but they pin existing behaviour, they don't change it). **Read those in source, not from this doc's summary of them.**

---

## 0. Review history (v1 → v2)

Two blind reviewers, each re-deriving from source (not from v1's citations). Both ADOPT-WITH-FIXES; they **independently converged on the same headline HIGH** (the reference sweep) — folded here.

| Finding | Sev | Raised by | v2 fold |
|---|---|---|---|
| **Reference sweep can't use the routing reconciler** — it flags only outbound *routing claims* and **excludes** data contracts + bare peer/prose mentions (`cross-boundary-routing-reconciler.md:44,:114`), the exact classes that dangle. | HIGH | both (convergent) | §4.1 rewritten to a **purpose-built inbound-reference scan**; reconciler demoted to a contributing input for its one subclass; Phase 4 named as the contract-consumer backstop. Q3. |
| **Sole-producer contract self-heal is false** — Phase 4 **skips** single-real-component `MATERIALIZED` contracts (`coherence/orchestrator.md:137`); the retiree never re-promotes, so its contract is never flagged and can freeze ownerless. (Reviewers disagreed on Q4; adjudicated from `:137` — the skip is explicit.) | MED | R1 (R2 had it backwards) | §4.1 makes the **§8-producer check a *blocking* precondition** that escalates to 04, not a reliance on Phase 4. Q4. |
| **New `## Retired Components` section can re-open the loop** if the detector/coherence read it as instantiated. | HIGH | R2 | §4.3/§6: set-extraction **explicitly scoped to `## Component Specs`**; retired schema is status-less. Q1. |
| **A new `retire/` subdir is silently NOT built** — `build-prompts.sh` has per-subdir hard-coded build functions, no generic loop (verified). | HIGH | R2 | §4 placement decided (new `retire/` orchestrator **+ a `build_retire_workflow` loop**); `build-prompts.sh` added to §10. Q2. |
| **Archiving under `versions/[component]-…/` risks glob re-scan**; §7's "no new standing invariant" overstated. | MED | both | §4.2 archives to a **reserved `versions/retired/…` namespace**; §7 states the (weaker, precedented) invariant honestly. |
| Reference-sweep reuse over-claimed; missed contract-consumers backstopped by Phase 4. | MED | R2 | folded into §4.1 / Q3. |
| §10 incomplete (build-prompts.sh, docs tree, R8-note). | MED | R2 | §10 expanded. |
| Rename guard's "history loss" wrong (archive preserves history); guard is decision-ordering + false-negatives across runs. | LOW | R1 | §4 guard re-justified. Q6. |
| 06 manifest is not the fence (06 is §6-driven, ignores orphans); real fence is retirement→re-coherence all-STALE block. | LOW | R1 | §2/§4.4/Q5 reframed. |
| "re-run coherence regenerates manifest" only on a freeze run; re-init line is `:355` not `:345`. | LOW | R2/R1 | §4.4 wording; §1 citation. |

---

## 0b. Second review round (v3 → v4)

A fresh blind pass over the consolidated v3 (the round-1 folds — the purpose-built sweep and the §8-producer block — had never been reviewed; reviewers had only seen v1). Correctness = ADOPT-WITH-FIXES; integration/buildability = **ADOPT**. Both independently verified every round-1 fold actually closed its prior finding, and confirmed §11 is complete with the Tier-1 "run Review" flagging real (`coherence:328/330/359`, `promote:345`). Folds:

| Finding | Sev | v4 fold |
|---|---|---|
| **Consumer-side registry symmetry gap** — §4.1b checked the retiree only as a §8 **producer**; the same distrust of 04 applies to a stale **Consumers**-field entry. Left unswept, it surfaces as a Phase 4 `DEFINED→VERIFIED` error (`coherence:138`, "owns ALL") reading the archived consumer spec — **blocking the re-freeze retirement needs**, with no clean retirement-time signal. | MED | §4.1b checks the retiree in **both `Producer(s)` and `Consumers`**; escalates `CROSS-BOUNDARY-UPSTREAM` on either. §5/§7 updated. |
| **Sweep scan-scope under-specified** — a structured reference (a sibling's §3 Interfaces / §7 Integration table "Reads from: X") is neither the Dependencies column nor narrative prose; a narrowly-implemented "prose" pass would miss it. | MED | §4.1a specifies the reference sweep as **one whole-spec name-occurrence scan** (every section, structured tables included), HALT-on-any-hit (false positives are safe — human adjudicates). |
| Dependent-ordering unstated — retiring before dependents re-Review yields a HALT that reads as an error. | LOW | §4 Step 1 notes the expected order (re-Review live dependents first, then retire). |
| `promote:232` miscitation (that line is "Set Step 3"). | LOW | §11 cites `promote:345`. |
| `build_retire_workflow` estimate ~25 lines is ~half real. | LOW | §9-D1 restated as ~45 lines (function + clean loop + build loop). |
| Scope-pins oversold as strictly load-bearing (they are defense-in-depth atop the detector's existing "Component Specs table" wording + the status-less schema). | LOW | §6/§7 soften the claim. |
| §10 `overview.md` touch points at a "05 workflow list" that doesn't exist (overview shows 05 as a leaf). | LOW | §10 drops the overview touch. |

No finding reopened a round-1 HIGH; the design shape (remove-row, archive-not-delete, purpose-built sweep, human-triggered) is confirmed sound and buildable.

---

## 1. Problem

The Tier-2 detector flags an **ORPHANED** component — one 05 instantiated (a stage-index Component Specs row + per-component state, possibly a published `specs/[component].md`) that the newly-promoted Architecture §6 **no longer requires**. Today:

- The detector **auto-proposes** the delta and HALTs (`decomposition-membership-detector.md:78-89`); the 04-promote orchestrator surfaces it as "instantiated, no longer in §6 — human retires/re-parents" (`04-architecture/promote/orchestrator.md:522-523`) and explicitly says **"Do NOT modify 05"** and **"the human decides and triggers … by hand."**
- But there is **no defined "retire a component" procedure.** 05 has **no Expand workflow**, and re-initialization is **destructive** — `05-init` rebuilds the whole stage index from §6 and resets state (`initialize/orchestrator.md:355`, "Already initialized. Re-running will reset state").

So "retire by hand" means either a destructive re-init (unacceptable — clobbers every *other* component's state and freshness records) or ad-hoc manual file surgery (unspecified, error-prone, can strand references). The gap R8 named: **no clean, non-destructive action path for ORPHANED.**

**What an ORPHANED component leaves behind (the realized artifacts):**
1. A **stage-index Component Specs row** in `05-components/versions/workflow-state.md` (the detector's "instantiated set").
2. A **per-component state dir** `versions/[component]/`.
3. A **published spec** `specs/[component].md` (only if it reached Promote; written solely by the promoter, `create/orchestrator-router.md:161`).
4. Possible **inbound references** from *sibling* specs: a Dependencies-column entry, a prose/name mention, a routing claim, a **data-contract consumption**.
5. Possible **contract-registry entries** in `specs/cross-cutting.md` (§8) naming it as a **producer** — 04-owned obligations, but with a 05 failure mode if the producer vanishes (see §4.1).

---

## 2. Is this secretly another C? (the premise check)

C (rename-stable §6 id) is a disaster because it installs a **permanent, silently-breakable invariant** whose failure is *worse than the honest degrade it replaces*. The retire path differs on every axis:

| Axis | C (rejected) | ORPHANED retirement |
|---|---|---|
| Lifetime | Standing invariant, forever | **One-shot operation**, human-triggered |
| Failure mode | **Silent** | **Detected** by a purpose-built blocking sweep + existing gates |
| Blast radius | ~107 name-keyed sites + 04 author discipline | Realized artifacts only; contracts escalated to 04 |
| Reversibility | Re-mint corrupts identity | **Archive, not delete** — reversible |
| Judgement | Moves disambiguation into 04 authoring | Keeps the *decision* human; automates drudgery + checks |

**Verified de-risking facts:**
- **MISSING needs nothing here.** Per-component Create adds the component to the stage index (`create/orchestrator-router.md:211,:89,:200`). The stateless detector (`decomposition-membership-detector.md:40-47`) then sees it as instantiated and stops flagging. ORPHANED-only.
- **Contracts are escalated, not rewritten.** 05 owns contract *status*; a wrong/removed contract is an "authority-level (04) decision" via `CROSS-BOUNDARY-UPSTREAM` (`coherence/orchestrator.md:171`). Retirement does not edit §8.
- **Archival precedent exists** (`deferred-items-processor.md:63-66`, archive-by-rename with a header note).

**The honest caveat v1 got wrong.** v1 claimed the inbound-reference sweep was "the whole safety surface, checkable" *by reusing the routing reconciler*. The reconciler cannot do it (it flags only routing claims and excludes data contracts + bare mentions — `cross-boundary-routing-reconciler.md:44,:114`). So v2 **builds a real inbound-reference scan** (§4.1). With that, the claim holds: the residual (a sibling pointing at a retired ghost) is caught by a **blocking, purpose-built precondition**, with coherence Phase 4 as a secondary backstop for the contract-consumer subclass — not a silent invariant. That is still categorically unlike C.

**The real fence downstream is re-coherence, not the 06 manifest.** 06 derives its processing order from **current §6** (`06-tasks/coordinator.md:81-85`), so it ignores a non-§6 orphan regardless — the 06 manifest check is not what protects us here. The genuine fence is that retirement directs a **coherence re-sign-off**, whose Phase 1 freshness read flags every component STALE after the orphaning 04 re-promote (`coherence/orchestrator.md:67`) and **blocks the re-freeze** until re-review. 06 cannot consume the stage until it re-freezes.

---

## 3. Decision

**A guarded, reversible, reference-checked retirement — human-triggered and human-confirmed, agent-executed, as a new stage-level `retire/` orchestrator.** The human triggers retirement for a detector-proposed ORPHANED component; the orchestrator runs a **blocking sweep (whole-spec inbound-reference scan + §8 producer/consumer check)**, then **archives** (never deletes) the component's realized artifacts, **removes its stage-index row** (recording it in a status-less `## Retired Components` audit section + history), and directs the human to **re-run the coherence sign-off (freeze)** so the Frozen-Components manifest regenerates without it. If the sweep finds a live inbound dependent or a live §8 producer/consumer role, retirement **HALTs** for the human to resolve first.

Rationale: automate the judgement-free legwork (sweep, archive, index-edit, audit), keep the two genuine judgements human — *whether* to retire (the human triggers) and *how to resolve a live dependent/contract* (the human decides). Mirrors the detector's "detection loud, action human-owned" split and the `trigger-vs-judgement` discipline.

**Rejected alternatives:** destructive re-init (clobbers siblings); `RETIRED`-in-place status (would force the detector's any-status instantiated set *and* the all-COMPLETE gate to special-case a new status — removal touches neither, §4.3); auto-retire on detection (removes the human trigger; violates "Do NOT modify 05").

---

## 4. Mechanism — the `retire/` orchestrator

A new stage-level orchestrator (sibling of `initialize/` and `coherence/` — both standalone, human-invoked-by-name stage ops), **not** a per-component workflow and **not** a step inside an existing orchestrator (initialize is destructive; coherence is the gate retirement *feeds*; create/review/promote are per-component). It may internally spawn a focused sweep agent, as coherence spawns the reconciler. **Buildability:** a new subdir requires a new `build_retire_workflow` loop in `build-prompts.sh` (per-subdir functions are hard-coded; there is no generic loop) — see §10.

Triggered by the human against a specific ORPHANED component named in the detector's proposal.

**Preconditions (all must hold, else no-op / error):**
- 05 is initialized and the named component has an active row in the `## Component Specs` table.
- The component is **genuinely ORPHANED against *current* §6** — re-confirm against the current published `architecture.md` §6 at run time (not the detector's cached proposal), reusing the detector's stateless current-§6 diff logic.
- **Possible-rename guard:** if the current detector run also reports ≥1 MISSING (the possible-rename signal — `decomposition-membership-detector.md:51` forbids auto-pairing), retirement **refuses** and tells the human to adjudicate retire-vs-rename first. Its purpose is **decision-ordering**, not history preservation (archive-not-delete already preserves history). Known limits: it is coarse (any coexisting MISSING blocks) and false-negatives across promote rounds (a MISSING resolved earlier via Create leaves the orphan appearing alone later). When a coexisting MISSING exists, record a `renamed-from/renamed-to` hint in the audit row if the human confirms a rename.

**Step 1 — Blocking sweep (inbound references + §8 producer *and* consumer role).** This is the load-bearing safety surface; it is purpose-built, not borrowed.
- **(a) Inbound sibling references — one whole-spec name-occurrence scan.** Scan every *other* component spec for **any occurrence of the retiring component's name, across the whole spec** — narrative prose, the **Dependencies column**, and **structured sections/tables** (e.g. a §3 Interfaces or §7 Integration row "Reads from: X", a data-contract consumption). This is deliberately **one full-text name scan, not three separable narrow passes** — a structured reference is neither the Dependencies column nor narrative prose, so a prose-only pass would miss it. HALT on any hit (false positives are safe — the human adjudicates). The cross-boundary routing reconciler covers only the routing-claim subclass (and by design excludes data contracts + bare mentions — `cross-boundary-routing-reconciler.md:44,:114`), so it is at most a *contributing input* for that subclass, never the sweep.
- **(b) §8 producer *and* consumer role.** Check `specs/cross-cutting.md` for a contract naming the retiree in **either** its `Producer(s)` **or** its `Consumers` field. Do **not** rely on coherence Phase 4 to catch either: Phase 4 **explicitly skips** a `MATERIALIZED` contract whose sole producer is one real component (`coherence/orchestrator.md:137`), and its `DEFINED→VERIFIED` consumer-alignment rung (`:138`, "owns ALL of them") would *error on* a retiree still listed as a consumer whose spec is now archived — **blocking the very re-freeze retirement depends on**. So a retired producer's contract would ride into the freeze ownerless, and a retired consumer's contract would wedge the re-coherence — both silent-to-retirement unless checked here. (The design distrusts 04 to have scrubbed §8 on the producer side; the identical distrust applies to the consumer side.)
- **Disposition:** **any live inbound dependent → HALT** (report them; the human resolves — a sibling depending on something §6 says should not exist is itself a real defect). **A live §8 producer *or* consumer role → HALT + escalate** a `CROSS-BOUNDARY-UPSTREAM` entry to `04-architecture/versions/pending-issues.md` (the registry must drop/re-assign that producer or consumer entry at the next 04 re-freeze). Retirement proceeds only when the retiree is referenced by nothing live.
- **Expected ordering (avoids a false-alarm HALT):** immediately after 04 drops the component from §6, still-stale siblings legitimately reference it — so the natural order is **re-Review the live dependents first** (their re-align against the new §6 drops the reference), **then** retire. Treat a Step-1 inbound-dependent HALT as "re-Review these, then re-trigger retire," not an error.

**Step 2 — Archive the realized artifacts (reversible, reserved namespace).**
- Move `versions/[component]/` → **`versions/retired/[component]-YYYY-MM-DD/`** (a reserved sub-namespace, *not* a `versions/[component]-retired/` sibling — the sibling shape risks a `versions/*/` glob mis-reading it as a live component) with a header note.
- If `specs/[component].md` exists, move it to `specs/archived/[component]-retired-YYYY-MM-DD.md` (outside the `specs/*.md` live namespace) with a header note.

**Step 3 — Update the stage index.**
- **Remove** the component's row from the `## Component Specs` table (so the instantiated set no longer contains it → detector reports no delta for it → no re-flag).
- Add a **status-less** `## Retired Components` audit row: component, date, reason ("ORPHANED — removed from Architecture §6 at round-[N]-promote"), archive locations, optional rename hint. **Status-less by design** so no status-keyed reader mistakes it for a live component (§6).
- Add a stage history entry.

**Step 4 — Direct re-coherence.** Instruct the human to **re-run the coherence sign-off (freeze)** — a freeze run (all-COMPLETE, no blockers) regenerates `## Frozen Components` without the retiree (`coherence/orchestrator.md:317,306`); a checkpoint run does not (harmless — mid-stage there is no manifest yet). Retirement itself does not freeze.

**Output:** a retirement report (swept references, §8 escalations, archived artifacts, audit row) — never a silent mutation.

---

## 5. Blast radius & ownership

| Artifact | Owner | Retirement action |
|---|---|---|
| Stage-index row | 05 | **Remove** + status-less audit row (§4.3) |
| `versions/[component]/` | 05 | **Archive** → `versions/retired/…` (§4.2) |
| `specs/[component].md` | 05 (promoter-written) | **Archive** → `specs/archived/…` (§4.2) |
| §8 contract (retiree as producer **or consumer**) | **04** | **Sweep → HALT + escalate** (§4.1b); not edited here |
| Sibling references (Dependencies / prose / structured tables / routing / contract-consumption) | 05 (each sibling) | **Whole-spec name scan → HALT** if live (§4.1a); human resolves |
| `## Frozen Components` manifest | 05 coherence | Regenerated at next sign-off freeze (§4.4) |

Load-bearing claim: retirement touches only 05-owned realized artifacts, **blocks** on any live inbound reference or §8 producer/consumer role, and escalates the 04-owned concern via the existing path. No new cross-stage authority.

---

## 6. Integration points

- **Detector → action.** Update the 04-promote ORPHANED branch (`04-architecture/promote/orchestrator.md:523`) to name the `retire/` orchestrator as the defined action the human triggers (advisory pointer; the freeze stands; 04 does not modify 05). Optionally update the detector's ORPHANED "Action for human" cell (`decomposition-membership-detector.md:81`) likewise.
- **Set-extraction scoping (clarifying, defense-in-depth).** Pin — in `coherence/orchestrator.md` (Phase 1 status count/gate, `:58`) and `decomposition-membership-detector.md` (the instantiated-set read, `:43`) — that the component set is extracted from the **`## Component Specs` section only**, never any other table. Two existing mechanisms *already* protect this: the detector's `:43` wording already says "Component Specs table" (so the pin there is redundant hardening), and the `## Retired Components` schema is **status-less**, so a "count by status" reader and the all-COMPLETE gate ignore it regardless. The genuinely-unscoped reader is coherence `:58` ("count components by status" names no table). So the pins are cheap defense-in-depth on top of the status-less design — not the sole thing standing between a retired component and a re-flag. Pins existing behaviour; changes none.
- **Freshness gates.** Retirement writes no `## Upstream Freshness` record and stamps no `Frozen-At`; a retired component simply exits the per-component freshness population coherence reads (`:67`). No freshness edge can be falsely satisfied.
- **Coherence all-COMPLETE gate.** Because the row is *removed* (not `RETIRED`-in-place), "every component at COMPLETE" (`:318`) is unaffected — retired components are not in the set.

---

## 7. What is new vs reused

**Reused unchanged:** archive-by-rename; the `CROSS-BOUNDARY-UPSTREAM` escalation to 04 (existing `AWAITS_UPSTREAM_REVISION` shape — no new guide format); the coherence sign-off + manifest regeneration; the detector's stateless current-§6 diff. The routing reconciler's *matching discipline* is reused for its one subclass only (§4.1a).

**New (small):**
1. A `retire/` stage orchestrator (§4) + a `build_retire_workflow` loop in `build-prompts.sh`.
2. A **purpose-built whole-spec inbound-reference scan** (name-occurrence across prose + Dependencies column + structured tables; reconciler as a contributing input for the routing subclass only) and a **§8 producer/consumer check** — the real safety surface v1 wrongly assumed it could borrow.
3. A status-less `## Retired Components` audit section in the stage-index schema.
4. Two clarifying scope-pins (detector + coherence, §6) and a one-line 04→05 pointer.

**Standing-invariant honesty (folding R1 Finding 3).** This is *not* invariant-free. It relies on the invariant that **every live-component enumerator keys off the `## Component Specs` table / explicit names, never a `versions/*/` or recursive `specs/**` scan.** That invariant already holds today and is why archiving works — but it *can* rot if a future enumerator globs the filesystem. It is **materially weaker than C's**: a breach is **table-level detectable** (a spurious component appears in the set), not a silent name-key corruption, and the reserved `versions/retired/…` + `specs/archived/…` namespaces keep the archives out of the obvious glob paths. §6's scope-pin is the mitigation; this invariant is stated so it is not discovered later.

---

## 8. Scope boundaries — explicitly NOT in this proposal

- **MISSING** — already actionable via per-component Create (§2). Untouched.
- **Re-split / merge / re-parent** — genuine re-decomposition stays the deferred R8 remainder; human does it by hand. This proposal is *retire-only*. (Full decomposition/content-change map: §11.)
- **Same component, changed remit** — Tier-1 content freshness; already built and human-flagged (§11). Not a change here.
- **Rename-stable §6 id (C / R7)** — deferred; the possible-rename guard preserves the honest-degrade seam so nothing is lost by deferring it.
- **The registry (§8) itself** — 04-owned; retirement escalates, never edits.
- **Auto-triggering retirement** — stays human-triggered.

---

## 9. Open decisions & residual risks (for a confirm pass)

- **D1 — placement (was Q2, decided; confirm).** New stage-level `retire/` orchestrator + a `build_retire_workflow` loop in `build-prompts.sh`. Chosen over hosting inside the (already-built) `coherence/` orchestrator, which avoids the build-script edit but bloats the most complex file in 05 and conflates a stage gate with a stage mutation. **The one call worth a human confirm**: accept the **~45-line** `build-prompts.sh` addition (a `build_retire_workflow` function ~21 lines + a clean loop ~8 + a build loop ~15, mirroring the coherence block) for a clean home, or prefer the zero-build-change coherence-hosted variant. **Decided (human, this session): option (a) — the new `retire/` subdir.**
- **Q1 (remove vs RETIRED) — CONFIRMED:** removal is strictly cleaner; `RETIRED`-in-place would re-flag as ORPHANED every run (detector counts any-status rows, `:43`) *and* permanently HALT the freeze (all-COMPLETE gate, `:318`). Removal + status-less audit touches neither gate. Requires the §6 scope-pin.
- **Q3 (sweep completeness) — RESOLVED by §4.1a (v4):** the reconciler alone would miss Dependencies-column, structured-table, prose, and contract-consumer inbound classes; §4.1a replaces it with **one whole-spec name-occurrence scan** (all sections, structured tables included), HALT-on-any-hit. Verify at build that the scan is genuinely full-text, not a narrative-only pass.
- **Q4 (orphaned contract) — RESOLVED stricter, both sides (v4):** not self-healing for the sole-producer case (`:137` skip) *nor* the retiree-as-consumer case (`:138` `DEFINED→VERIFIED` would error on the archived consumer spec); §4.1b makes **both a blocking precondition** that escalates to 04. Confirm the multi-producer/ownerless producer case (which Phase 4 *does* reach) needs no extra handling.
- **Q5 (ordering) — RESOLVED:** the fence is retirement→re-coherence all-STALE block (`:67`), not the 06 manifest; no orphan-dangle window.
- **Q6 (retire-only too thin?) — accepted:** retire-only is a legitimate thin slice; the guard is decision-ordering (not history) and coarse. Reassess if ORPHANED-with-rename dominates in practice.
- **R-new — re-init durability:** the `## Retired Components` audit is not §6-derived, so a destructive re-init would not preserve it. Acceptable (re-init is already nuclear), noted so it is not a surprise.

---

## 10. Files touched (per-file plan — for the reviewed build, not this draft)

All in `agent-sources/` unless noted; **rebuild required** (`./build-prompts.sh`):
- **New:** `stages/05-components/retire/orchestrator.md` (+ any sweep sub-agent) — §4.
- **`build-prompts.sh`** (repo root — *source, not generated*): add a `build_retire_workflow` loop mirroring the coherence block, and a clean entry. **Without this the new subdir does not build.**
- `stages/05-components/initialize/orchestrator.md` — add the status-less `## Retired Components` audit section to the stage-index schema.
- `stages/04-architecture/promote/orchestrator.md:523` — point the ORPHANED branch at the `retire/` orchestrator (advisory).
- `universal-agents/decomposition-membership-detector.md` — scope-pin the instantiated-set read to `## Component Specs` (`:43`); optionally update the ORPHANED "Action for human" cell (`:81`).
- `stages/05-components/coherence/orchestrator.md` — scope-pin the Phase 1 status count/gate to `## Component Specs` (`:58`).
- `docs/05-components.md` — document the retirement action **and** add it to the directory-tree block (`:205-247`) so the tree doesn't go stale.
- `docs/cross-stage-cascade-watermark-design.md` §3.7 / §8-R8 — annotate that the *retire slice* of R8 shipped (re-split/merge still deferred).
- *(Not `docs/overview.md`: it shows 05 as a leaf and does not enumerate 05's stage ops, so nothing there goes stale — dropped from the touch list on review.)*

**Not touched:** the registry authoring; the freshness-gate behaviour; per-component create/review/promote; coherence conformance logic (reused as-is); `guides/pending-issues-format.md` (existing `CROSS-BOUNDARY-UPSTREAM` suffices).

---

## 11. The full decomposition/content-change map (retire is one leg)

Retirement (ORPHANED) is one of four ways a component set can change when Architecture re-promotes. This section maps the whole space so no case is left implicit, and records which are **built**, which is **this proposal**, and which stays **deferred**. Only the ORPHANED leg is a change here; the rest is documentation of existing behaviour (verified in source), added at review request so the space is mapped in one place.

| Change at 04 re-promote | Handled by | Status |
|---|---|---|
| **Same component, materially changed remit/function** (still in §6, same identity) | A new per-component **Review round** against the current 02/03/04 | **Built** (Tier-1 content freshness) |
| **§6 adds a component** (MISSING) | Per-component **Create** (adds the stage-index row; detector then stops flagging) | **Built** |
| **§6 drops a component** (ORPHANED) | The **retire** orchestrator | **This proposal** |
| **Remit splits / merges / moves** between components | Human-driven (Create the new + retire the old + Review the survivors); no automated action | **Deferred** (R8 remainder) |

**Tier-1 (content change) — why Review, and that it is already flagged.** A component whose remit changed but whose identity persists is **not** a membership change; it is Tier-1 content freshness. It is handled by re-running that component's **Review** — *not* Expand (05 has none by design — `overview.md:158`, Expand is 01–04) and *not* Create (bootstrap-only, type-guarded once a component reaches Review/Promote — `create/orchestrator-router.md:213`). The architectural reason: a 05 component **consumes** scope (its remit is pinned by §6 + its §7/§8 contracts) rather than **originating** it, so a Review round against the *current* authority re-derives the enlarged/changed spec (the AV reads current 02/03/04 — `review/orchestrator-router.md:217`; a COMPLETE component re-opens as a backward-edge re-review — `:87`). Expand exists at 01–04 precisely because those docs originate scope; the scope-growth *decision* happens upstream at 04, and 05 conforms.

**The human is explicitly told to run it (the acceptance condition).** The Tier-1 staleness is detected *and* the remedy is spelled out — this is not a silent stale-freeze:
- Per-component **Promote Step 1b** freshness gate: on a discrepancy, `WAITING_FOR_HUMAN` with the remedy "conform-down / sync-up a PI … re-run after that source's Review, or dismiss/override" (`promote/orchestrator.md:345`).
- **Coherence sign-off** (the backstop for an already-`COMPLETE` component staled by a mid-stage upstream re-promote — its own Promote guard never re-fires): a STALE edge is a **blocking issue**, and the HALT names the fix verbatim — "**re-run its Review (re-align) + Promote, then re-run coherence**" (`coherence/orchestrator.md:304,328,330,359`).
- **Eager-detect** at 04-promote names 05 as staled (advisory — `04-promote/orchestrator.md:493`). *(Optional nicety, not required: this advisory line says components "re-align at their next Promote"; it could echo the coherence remedy's explicit "run a Review round." The actionable path is already covered by the coherence HALT, so this is not a gap — noted only so it isn't mistaken for one.)*

**The one human-judgment seam.** Distinguishing "a large but single-component remit change" (Tier-1 → Review) from "this should really split into two" (deferred re-decomposition) has **no auto-detector**, by design — it is a decomposition design call the human makes mid-Review, the same class of judgement the detector's HALT and this proposal's retire-trigger already keep human. Named here so it is a known seam, not a surprise.

**Net:** with retire (this proposal) added, three of four legs are built/proposed and human-flagged; only split/merge/re-parent remains deliberately deferred and human-driven.
