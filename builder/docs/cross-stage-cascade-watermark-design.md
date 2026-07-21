# Design Proposal: Cross-Stage Freshness — Extend Freeze-Identity to the Document Edges

**Status:** PROPOSAL v3.3 — pre-implementation review (two blind adversarial passes: correctness + integration/buildability) folded. It caught a **correctness BLOCKER the v3.2 reframe introduced** — "advance-on-clean" keyed on a verdict the AV doesn't emit: fixed to **advance iff `ALIGNED` (zero discrepancies) for that source, per-edge, never on the AV's `PROCEED` recommendation** (which permits non-showstopper discrepancies), with a **human dismiss/override** path so an accepted discrepancy can't permanently block a freeze (§3.3). Also folded: eager-detect re-attributed to the promote **orchestrator** (not the promoter agent) and reduced to a static direct-consumer list (§3.3); the AV-recheck **wrapper** made explicit (the AV only reports; the wrapper advances/routes/logs, §3.4); Tier-2 detector **preconditions** (skip FIRST_FREEZE / uninitialized-05; key on the §6 roster set-diff) and the **no-stable-§6-id** build gap → ships in the safe degraded form (§3.7, R7); and the **02 freshness edge is inert** (01-blueprint never stamps `Frozen-At`) — live edges are 03/04/05 (§3.3 scope note). Core confirmed sound + buildable by both reviewers. **v3.2 model (retained):** clearing is **auto-check / human-trigger / human-judge** — detect (version compare), the AV re-check, and advancing an `ALIGNED` edge are automatic; the human **triggers** the workflow and **judges** a discrepancy or a re-decomposition. Eager-detect reporting; Tier-2 detector built (auto-detect + auto-propose; automated *action* deferred). Prior history — v3.1: v3 added the stage-05 design; a focused re-review of the new material (two blind reviewers, both "adopt with fixes", all §3.7 citations verified TRUE) then folded five fixes into v3.1: (1) struck a stale line-86 claim that 05-init covers the 04-edge (a contradiction the fold introduced — the one the widened focused scope existed to catch); (2) added the zero-issues-fast-path caveat to the advance rule; (3) reframed Tier 2 honestly as a **detector sketch + HALT-to-human** (its detection wiring AND its action path are unbuilt; 05 has no Expand and re-init is destructive) — v3.1 does **not** claim to close missing/orphaned *(superseded by v3.2: the detector is now built; only the automated re-decomposition action is deferred)*; (4) elevated the coherence-sign-off freshness check to a first-class linchpin (it is the only backstop for an already-COMPLETE component); (5) corrected "a copy of the absent-from-freeze detector" to "a new agent at a new altitude." v3 also folds the v2 re-review (two blind reviewers, all load-bearing facts verified TRUE) and added the stage-05 design that v2 deferred. v3 changes from v2: (a) advance the freshness edge to the token the Alignment Verifier **actually read**, not "current at completion" (fixes a TOCTOU that reopened the silent middle); (b) stamp `Frozen-At` in the **promoter**, not the orchestrator publish; (c) an absent edge is cleared **only by an actual re-check** (v3 said a full Review round; v3.2 → the standalone AV-recheck), never a bare stamp; (d) soften "the AV flags it" → "the AV re-checks it"; (e) the 02/03 conservation gate is **committed** (`345ee45`), so the sequencing caveat is dropped; (f) **new §3.7 — the two-tier stage-05 design** (per-component content freshness + a decomposition-membership detector). Ready for re-review (the §3.7 material is new and unreviewed).
**Date:** 2026-07-21
**Author:** Claude (with Sean)
**Scope:** document stages 01–05. Builds on — does not modify — the log-only Pending Issue Resolver (`docs/pending-issue-resolver-log-only-design.md`), the review-gated Promote (`docs/02-03-promote-gating-fix-design.md`), the cross-boundary P2 methodology (`docs/cross-boundary-requirements.md`), the Slice-6 freeze-identity token (`2080a99`), and the 02/03 document-conservation gate (`345ee45`).

---

## 0. What the v1 reviews found, and how v2 responds

Two blind adversarial reviewers (one correctness/convergence, one integration/minimality) re-derived from source. Both landed the same headline, and v2 is a direct consequence.

| v1 finding | Verdict | v2 response |
|---|---|---|
| **The `Frozen-At` freeze-identity token already IS a recorded-upstream-version watermark + freshness gate** — live at 04→05 (`05-components/initialize/orchestrator.md:44-47`, equality staleness check) and 05→06 (`06-tasks/coordinator.md:101`), and reliably re-stamped every promote under an explicit invariant (`04-architecture/promote/contract-materializer.md:103`). | CONFIRMED (both, independently) | v2 **extends `Frozen-At`** to the internal doc edges instead of inventing a "watermark." §2, §3. |
| v1 cited the wrong token — `Source Version` (`promoter.md:122`), which the source **explicitly says not to stamp** ("that is the Future Planning doc"). The real token is `**Frozen-At**` (`promoter.md:107,113,282,320`). | CONFIRMED | v2 uses `Frozen-At` throughout; the stale-header worry (v1-R4) is moot — `Frozen-At` is purpose-built to be reliable. |
| The **cascade controller** is the "no automatic consumer / no auto-actioning loop across completed stages" the P2 design deliberately declined (`cross-boundary-requirements.md:43`), and it is **not load-bearing** — a per-stage freshness gate closes the silent middle without it. | CONFIRMED | v2 **cuts the controller.** Propagation is emergent from per-stage gates (§3.3, §4). |
| v1's `>` **ordering** comparison reintroduces the "ledger machinery" `05-init` deliberately deferred; **equality** (`!=`) suffices. | CONFIRMED | v2 uses equality, matching `05-components/initialize/orchestrator.md:349` ("equality check only"). |
| **F2 (deep-node false-clean):** if 02 changes a detail 04 abstracts away, the scoped AV clears 04; v1's DAG routed 05's PRD dependency "via 04", so 05 — which cashes the detail out — was never re-checked. v1's §7 contradicted its own cited authority. | CONFIRMED, and load-bearing | v2 fixes the DAG: watermark edges **mirror the real alignment-source edges**, which are **direct** (`alignment-verifier.md:50`: 05 ← Architecture, Foundations, **PRD**). 05's direct 02-edge catches the deep node (§4.2). |
| **F4:** convergence was overstated — suppression matches only declined `WONT_FIX` (Concern key), so an owner-resolves-differently re-raise isn't first-pass-suppressed. | CONFIRMED | v2 claims only "convergence = the existing review loop's," and the no-controller design adds no new loop (§4.4). |
| v1's "no watermark exists / nothing re-validates 04" was overstated — `Frozen-At` exists on some edges, and 04's own next Review re-aligns via the Alignment Verifier against live upstream. | CONFIRMED | v2 problem statement (§1) is tightened: the detector (AV) exists; what's missing on the internal edges is the **record** and the **freshness gate/trigger**. |

Net: the **diagnosis holds** (a stage can freeze stale against a re-promoted upstream on the internal document edges), but the **mechanism is now an extension of a proven, purpose-built pattern**, not a new subsystem.

## 0b. What the v2 re-review found, and how v3 responds

Two more blind reviewers (correctness; integration/minimality) verified v2 from source. Both reached "adopt with fixes," and both independently confirmed every load-bearing fact (the direct-edge DAG `alignment-verifier.md:50`; the abstraction filter; the `Frozen-At` stamp + unconditional re-stamp invariant; the promote guard checking only "last round was Review"). The fixes, folded into v3:

| v2 finding | Severity | v3 fix |
|---|---|---|
| **Advance-rule TOCTOU.** v2 advanced an edge to the upstream's *current* `Frozen-At` "at review completion." If the upstream re-promotes *during* the consumer's review (esp. the unbounded Step-10 human wait), the edge is stamped to a version the Alignment Verifier never checked → the consumer promotes stale. Reopens the silent middle. | HIGH (correctness) | §3.2/§3.7: advance the edge to the token the **AV actually read** (captured at AV-run time), never "current at completion." |
| **Stamp mislocated.** v2 said stamp `Frozen-At` "at the publish step," but 04 stamps in the **promoter** (round-folder original) before the conservation gate; the orchestrator publish is a `cp` that must not author bodies (`02-prd/promote/orchestrator.md:125` "You DO NOT author the promoted documents"). | MEDIUM (integration) | §3.1: stamp in the **02/03 promoter**, mirroring 04 exactly. The header line sits **outside** every stage's verbatim-critical sections, so the conservation checker tolerates it (resolves R1/R7 favorably). |
| **Absent-edge false-clean.** v2's §3.3 ("re-promote to stamp") and §3.6 ("re-align to establish") were inconsistent; a bare promote-stamp on a drifted existing project would advance an edge the AV never compared. | MEDIUM (correctness) | §3.3/§3.6: an **absent** edge is cleared only by an actual AV re-check (never a bare promote-stamp). *(v3.2: the re-check is the standalone AV-recheck, not necessarily a full Review round.)* |
| **"The AV flags it" overstated.** The gate forces a re-check, but the AV is claim/string-level, so a token-preserving semantic change (redefine value "B", keep the string) slips it. | LOW (honesty) | §4.2: claims only "always re-**checked**," and names the AV's residual semantic blind spot explicitly. |
| **05 under-specified.** 05 has no single "Promote guard"; its freshness is per-component + coherence sign-off, and `05-init` runs once (never re-fires) so the 04→05 edge v2 called "already covered" is not backstopped mid-stage. | HIGH (design gap) | **New §3.7** — the two-tier stage-05 design (per-component content freshness + a decomposition-membership detector). |
| Stale sequencing (conservation gate "uncommitted"); 05→06 uses the sibling `Stage-Frozen-At`, not `Frozen-At`. | LOW (factual) | §6 sequencing dropped (committed `345ee45`); §2 notes the 05→06 token is the sibling `Stage-Frozen-At`. |

---

## 1. Problem (tightened)

The **detector already exists**: each stage's Review runs the Alignment Verifier against its live upstream sources (`alignment-verifier.md:43-53`; `04-architecture/review/orchestrator.md:449-451`), and it needs no pending issue to re-derive drift. What is missing on the **internal document edges (02→03, 02→04, 03→04, 02→05, 03→05)** is:

1. **A record** of which upstream version each stage last reconciled against. Nothing stores it; each stage re-reads the live current upstream. So "is 04 stale against the current 02?" is not a computable question on these edges.
2. **A freshness gate.** The review-mandatory Promote guard checks only that *a* Review completed (`04-architecture/promote/orchestrator.md:168-177`), **not** that it was against the *current* upstream. So a stage can freeze against an upstream that has since moved.

The concrete failure ("silent middle"): an issue in **02** is found at **05** (the finest layer, where abstractions cash out — the `search_vector`/DD-010 shape), logged up, 02 revised and re-promoted. **04 also reads 02, but nothing records that 04 was aligned against the *old* 02, and no pending issue is ever filed against 04** (05 filed against 02). 04 can promote stale. The two boundaries that *do* have this protection — 04→05 and 05→06 — have it precisely because `Frozen-At` is stamped and gated there; the internal edges don't have `Frozen-At` at all.

**Why this is the right time:** the 02/03 promoters were just given a document-conservation gate (`guard → split → conservation-gate → publish → record`, committed `345ee45`). That change opened the promoter's publish path and added a `promote-metadata.md` (round + gate verdict) — a natural place to also stamp `Frozen-At` — so this is authored against committed source, not sequenced around in-flight work (§6).

---

## 2. The existing mechanism this extends (credit)

`Frozen-At` is a per-document freeze-identity token equal to the `round-[N]-promote` id, stamped by the promoter and checked by consumers:

- **Stamped:** 04's promoter writes `**Frozen-At**: round-[N]-promote` into `architecture.md`'s header (`04-architecture/promote/promoter.md:107,282,320`), and the contract-materializer stamps the **same** token into the registry (`contract-materializer.md:101,154`), **unconditionally on every promote** under an explicit non-skip invariant (`contract-materializer.md:103`).
- **Checked (equality):** 05-init errors if the registry's `Frozen-At` ≠ `architecture.md`'s `Frozen-At` ("stale — re-run Promote"), and treats an **absent** token as "not established → re-promote to stamp," **not** a staleness error (`05-components/initialize/orchestrator.md:44-47,349-350`). This is exactly a recorded-version freshness gate, deliberately equality-only ("ordering … would be ledger machinery, deferred").
- **Precedent gate:** 06-tasks invalidates on an upstream re-promote (`06-tasks/coordinator.md:94-101`) — note this keys on the **sibling** `**Stage-Frozen-At**` token (05's whole-stage freeze, `05-components/coherence/orchestrator.md:301,328`), not `Frozen-At`; it "mirrors 05-init's check" rather than reusing the same token.

The design is: **make the internal document edges look like the 04→05 edge already does** — and, for stage 05, respect that its freeze is per-component + a coherence sign-off, not a single Promote guard (§3.7).

---

## 3. Design

### 3.1 Stamp `Frozen-At` on the 02/03 (and confirm 04) document promoters

- 04 already stamps it in its **promoter** (`04-architecture/promote/promoter.md:107,113,282,320`), writing into the round-folder original **before** the conservation gate runs; the orchestrator then `cp`-publishes. **Add the identical stamp to the 02 and 03 promoters** (not their orchestrators — `02-prd/promote/orchestrator.md:125` "You DO NOT author the promoted documents"): write `**Frozen-At**: round-[N]-promote` into the round-folder `prd.md` / `foundations.md` header, mirroring 04's fallback (a minimal provenance line if no header block exists) and re-freeze behavior (overwrite, don't append).
- The stamped header line sits **outside** every stage's verbatim-critical sections (04 §6/§8/§7; 02 §5/§8/§9; 03 §1–10), so the just-committed document-conservation gate (`345ee45`) tolerates it — no race, no conflict.
- This is a small, pattern-copying change to two promoters, not new machinery.

### 3.2 Record per-edge reconciled-`Frozen-At` on each consumer

Each consumer stage records, in its `workflow-state.md`, the upstream `Frozen-At` it last reconciled against — **one entry per real alignment-source edge** (edges taken verbatim from `alignment-verifier.md:47-50`, which are all **direct**):

```
## Upstream Freshness (reconciled-against)
- 02-prd:          round-34-promote
- 03-foundations:  round-12-promote
```

- **03** records: 02.
- **04** records: 02, 03.
- **05** records: 02, 03, 04 — but **per component**, not at the stage level (see §3.7; `05-init`'s registry check is a one-time setup precondition, **not** the mid-stage backstop, so the 04-edge is held and gated per component like the others).
- **When it advances (TOCTOU-safe):** whenever an Alignment Verifier run completes for that source — the standalone re-align check (§3.3) or a full Review round — set the edge to **the `Frozen-At` the AV read** for that source, captured at AV-run time — **not** the source's "current" value at completion. This matters because the source can re-promote *during* the consumer's review (the review sits at a human wait for an unbounded time): advancing to "current at completion" would stamp the edge to a version the AV never checked, silently reopening the silent middle. The advance says exactly "I reconciled against *this* version," which is the version the AV compared. This is the only new write; it needs no new agent (the AV already records which source files it read — extend it to record the `Frozen-At` it saw).
- **Zero-issues fast-path caveat:** a review round can complete *without running the AV* — the zero-issues path skips post-discussion (e.g. `05-components/review/orchestrator-router.md:255-265`). Such a completion **advances no edge** (there is no AV-read token). The edge therefore stays stale, and the Promote gate correctly forces a real review round before the stage can freeze. "Advance on the AV-read token" already encodes this (no read ⇒ no advance), but it must be stated so an implementer does not advance on *any* `COMPLETE`.

### 3.3 Freshness-gated promote (generalize the 05-init check)

Extend the review-mandatory Promote guard with an **equality** freshness clause, per direct edge:

> A stage may not promote while, for any of its direct alignment-source edges, the consumer's recorded `Frozen-At` ≠ that source's current `Frozen-At`.

**Scope note (the live edges).** The clause attaches at 03/04's Promote guards and 05's per-component Promote + coherence sign-off. **02's clause is forward-provision only** — 02's sole upstream is 01-blueprint, which has **no Promote workflow and never stamps `Frozen-At`** (`agents/01-blueprint/` is create/review/expand only), so 02's edge degrades permanently to the absent-source-token no-op (below) and never fires. So the *live* freshness edges are **03←02, 04←{02,03}, 05←{02,03,04}**; wiring the clause into 02 is harmless but buys nothing until 01 gains a promote/stamp.

Two "absent" cases, kept distinct (the v2 review found them conflated):
- **Source's `Frozen-At` absent** (an upstream never stamped — a pre-adoption artifact): "freeze identity not established → re-promote the *source* to stamp," not a staleness error — the exact `05-init` rule (`initialize/orchestrator.md:47`).
- **Consumer's recorded value absent** (the consumer never recorded this edge): cleared **only by an actual AV re-check** — the standalone AV-recheck of §3.3, or a full Review round — which compares against the source and records the AV-read token (§3.2), **never by a bare promote-stamp.** A bare stamp would advance the edge to "current" without the AV ever comparing the consumer against the (possibly drifted) source — a false-clean on exactly the existing-project drift this work exists to surface.

**Clearing a stale edge — the automate/trigger/judge split (the design model).** The gate does not simply block and send the human off to run a full Review round. It applies a division of labour aligned to what actually needs a human:
- **Detect** (is the edge stale? a `Frozen-At` version compare) — **automatic**, no human, no judgement.
- **Re-check** (is the consumer still consistent with the now-current source?) — **automatic**: run a **lightweight re-align check** — the Alignment Verifier alone (the full AV, read-only), **wrapped as a callable unit that advances/routes on the AV's verdict (§3.4)**. This is *not* a full Review round (too heavy) and *not* a section-scoped variant (that would risk a false-clean).
- **Advance on ALIGNED (per source, ZERO discrepancies) — not on `PROCEED`.** Auto-advance the edge **iff the AV reports zero discrepancies for that source** (Alignment Status `ALIGNED` for it; per-source discrepancy count = 0 in the AV Summary table). **Do NOT key on the AV's `PROCEED` recommendation** — `PROCEED` explicitly permits "discrepancies found but none SHOWSTOPPER" (`alignment-verifier.md:223`), so advancing on `PROCEED` would stamp an edge fresh over a *live* non-showstopper contradiction — a false-clean that reopens the exact silent middle this work closes. Two corollaries the spec must state: **(a) per-edge, not global** — a discrepancy against 03 must not block advancing a clean 02-edge, and a global `PROCEED` must not carry a 02-discrepancy through (use the AV's per-source Summary counts); **(b) "zero for this source", not "no *new* one"** — the standalone AV is stateless and re-derives *all* discrepancies each run, so there is no new-vs-known baseline; the predicate is zero-discrepancies-for-this-source.
- **Any discrepancy → human disposition (resolve or override).** A discrepancy — even a non-SHOWSTOPPER one — stops for a human, who either **resolves** it (conform-down / sync-up — genuine judgement, what the 05 pre-discussion skeptic already flags "must-engage") **or records a dismiss/override that advances the edge with a rationale**, mirroring the disposition path the existing Promote / conformance gates already give HIGH findings (Resolved / Deferred / Dismissed-Override). This is a deliberate *stricter-than-today* posture (today a non-SHOWSTOPPER rides as a logged PI while Promote proceeds): the freshness gate makes the human **decide** rather than let it ride silently — and the override is what stops an accepted, upstream-won't-change discrepancy from *permanently* blocking the downstream freeze (the liveness horn of the same ambiguity).

**Where the re-check runs (the hybrid — decision B).** The AV-recheck callable unit is invoked as a **gate-step inside Promote** (the workflow the human already triggers): stale edge → auto-AV → `ALIGNED`-for-source advances the edge and Promote proceeds (zero extra trigger for the clean case) → a discrepancy HALTs to human disposition. Because it is a standalone callable unit, it is also independently invokable and can later be **auto-triggered** (event/cron) without rework — today it fires inside the human-triggered Promote; the trigger itself is cheap and stays human for now (it lets the human own build cadence and modularity).

**Eager-detect, lazy-resolve (decision C).** Detection is surfaced *proactively but cheaply*: the upstream **promote orchestrator's closing report-to-user** (the orchestrator's report step — **not** the promoter agent, which authors only its own doc and cannot read downstream state) names **the direct downstream stages this re-promote just staled**, advising which to re-align. Under equality every direct consumer's edge is trivially stale the instant the token changes, so this is simply the **static list of direct downstream consumers** (03/04/05 for a 02 re-promote), not a per-token compute — cheap and advisory. The expensive AV-recheck still runs only when a stage is actually promoted (lazy), never auto-fired across completed stages.

### 3.4 The Alignment Verifier is the confirm-or-clear

The lightweight re-align check *is* the ordinary Alignment Verifier run standalone, comparing against the full current source: `ALIGNED` for the source → §3.2 advances the edge (auto); any discrepancy → surface to disposition (§3.3). **The "callable unit" is a thin wrapper, not just the AV** — the AV itself only *writes a report* (it does not advance edges, log PIs, or route resolution; in a normal round the orchestrator does those). So the unit is: run the AV → parse its per-source verdict → **on `ALIGNED`-for-source**, capture the `Frozen-At` the AV read + advance the edge + proceed → **on discrepancy**, HALT + route to human disposition + log the PI. That wrapper is real (small) work, not free. Running the full AV — not a section-scoped subset — is deliberate: the scoped variant's failure mode is a false-clean, exactly the silent drift this work exists to prevent, and it would depend on a changed-sections manifest we don't have. (A section-scoped optimization is explicitly **out of scope**.)

### 3.5 No cascade controller — automate the checks, human owns the mutations

There is no DAG-walking controller. Propagation is emergent: when 02 re-promotes, every stage with a direct 02-edge (03, 04, 05) has a stale edge, its upstream's closing report says so, and each stage's own Promote gate auto-rechecks and either auto-clears or surfaces when that stage is next promoted. The automate/human boundary is what keeps this safe *and* low-effort, and what reconciles it with `cross-boundary-requirements.md:43` ("no automatic consumer … an auto-actioning loop across completed stages is a non-convergence risk"): **the automatic parts are all read-only or metadata-only** (detect, run the AV, advance an `ALIGNED` edge). **Every mutation — applying a fix, re-promoting — stays human-triggered.** So there is no auto-fix→re-dirty→auto-fix loop; the thing :43 forbids (auto-*actioning* across completed stages) never happens, while the judgement-free drudgery (detect + re-check + clear) is automated away.

### 3.6 Equality, and bootstrapping, both mirror 05-init

- **Equality** (`recorded ≠ current`), not ordering — matching the deliberate `05-init` choice (`initialize/orchestrator.md:349`).
- **Bootstrapping / migration:** an **absent** recorded value is handled by §3.3 (cleared only by an actual AV re-check, never a bare stamp), so an existing drifted project surfaces its drift at the first re-align rather than being blessed. This avoids false-positives while guaranteeing the record is present going forward.

### 3.7 Stage 05 is a two-tier beast (per-component content freshness + a decomposition-membership detector)

05 has no single document and no single Promote guard, so §3.1–3.3 do not attach the way they do to 02–04. 05's freshness splits into two tiers.

**Tier 1 — content freshness (per component; the common case).** 05's freshness *cycle* is per component: each component runs Create → Review → Promote. The per-component **Review** runs the universal Alignment Verifier against the current Architecture / Foundations / PRD (`05-components/review/orchestrator-post-discussion.md:97`, Step 8), and the per-component **Promote** is the sole road to `specs/[component].md`, already carrying a **review-mandatory guard** on start (`05-components/promote/orchestrator.md:28-31`). So apply the §3.1–3.3 mechanism **per component**:
- Each component records, in its own per-component `workflow-state.md`, the reconciled `Frozen-At` per direct edge (02, 03, 04 — the AV's sources).
- Advance those edges at per-component **Review** completion to the **AV-read** token (§3.2, TOCTOU-safe).
- Add the equality freshness clause to the per-component **Promote** review-mandatory guard: a component may not freeze `specs/[component].md` while any of its 02/03/04 edges is stale.
- **The coherence sign-off carries a first-class freshness check (the linchpin — not a footnote).** The whole-stage freeze is the coherence sign-off's `Stage-Frozen-At` (`05-components/coherence/orchestrator.md:301,328`), which gates 06. Today its Phase 1 reads only component *status* and per-component `pending-issues.md` — it does **not** read the per-component `workflow-state.md` freshness blocks. This proposal **adds that read** and makes it blocking: the stage cannot sign off while **any** component's recorded edge ≠ its source's current `Frozen-At`. This is load-bearing, not incremental: it is the **only** backstop for a component that has *already* promoted COMPLETE and then goes stale on a mid-stage 04 re-promote (its own per-component Promote guard never re-fires). It is also the fix for the v2 gap that `05-init`'s freeze-identity check runs **once at stage start and never re-fires** (`05-components/initialize/orchestrator.md:44`). Omit or mis-wire this single check and per-component guards alone leave already-frozen components stale. (`05-init` stays as the *setup* precondition; it is not the mid-stage backstop.)

**Tier 2 — decomposition freshness (stage-level; rare). Decision D: BUILD the detector now (auto-detect + auto-propose); defer only the automated re-decomposition *action*.** Tier 1 makes each *existing* component re-align, but it structurally cannot see a **set-membership** change: a component the new Architecture §6 now *requires* but that was never instantiated (**missing**), or one §6 *removed* that still sits in the stage (**orphaned**). This class is covered by *nothing* today — the absent-from-freeze detector is body-driven (a missing component has no body to scan), and coherence Phase 4 only partially catches a missing producer *that has a contract* (`05-components/coherence/orchestrator.md:133-136`); a set change with no contract footprint (a new pure-consumer component, or any orphaned one) is invisible to both. So Tier 2 is genuinely needed, and D builds the detector so missing/orphaned becomes **loud, not silent**.
- **Detect — automatic (build this).** A new agent at a new altitude (set-first, stage-level, §6-roster-diffing — *not* a copy of the body-first absent-from-freeze detector). **Trigger (decision C):** fire after the 04-Promote publish, computing a **§6 roster set-diff** (prior published §6 vs new — 04-Promote already snapshots the prior published architecture, `04-promote/orchestrator.md:187`) — **not** "any §6 text touch" (a benign §6 reword would spawn a wasted run; the set-diff then finds no delta). It compares the instantiated component set (stage-index rows) against §6; `05-init` already extracts §6's list into those rows (`05-components/initialize/orchestrator.md:51-53`). **Preconditions (must no-op, or it misfires):** skip on **FIRST_FREEZE** (no prior published §6 to diff) and when **05 is uninitialized** (no stage index yet). **Identifier caveat (build gap, R7):** the design wants a stable id to key on, but §6 carries **no rename-stable identifier today** — the component slug (§6 "Spec" column) *is* the display name, exactly what a rename changes. Giving §6 a stable id is a follow-up schema change; **until then the detector ships in the safe degraded form** — a rename surfaces as simultaneous missing+orphaned, which the human disambiguates (matching the "human owns the re-decompose" split). Pure add/remove and split/merge are caught cleanly regardless.
- **Propose — automatic.** On a hit, the detector **auto-proposes the delta** (which components §6 added / removed / re-parented) and surfaces it, so the human decides with full context rather than from scratch. All the judgement-free legwork is done for them.
- **Act — human-triggered and human-judged (deferred as *automation*, not as detection).** Re-decomposition is a genuine design decision no agent should make, so the action is a **HALT-to-human**: the detector advises, the human decides the new decomposition and triggers it. The *automated* incremental re-decomposition path is the deferred piece — 05 uniquely has **no Expand workflow** (01–04 do; 05 does not) and re-initialization is **destructive** (`05-components/initialize/orchestrator.md:345`), so building a non-destructive 05 decomposition-reconciliation is a separate, larger follow-up. What the design delivers is: **detection closed (loud), the action human-owned** — which is the correct split, since the action is exactly the design judgement humans should keep.
- **Why bounded:** a silently-missing component is the worst failure mode, but Tier 2 is rare by construction — the 02/03/04 freshness gates + conservation + review-gating stabilize Architecture's decomposition before 05 consumes it, so a post-05 upstream change is far more likely to be a §5/§8 content refinement (Tier 1) than a §6 re-decomposition (Tier 2).

---

## 4. How the design closes the attack cases from the reviews

### 4.1 Silent middle (04 between 02 and 05)
04 has its **own direct 02-edge** (§3.2). When 02 re-promotes, 04's recorded 02-`Frozen-At` ≠ 02's current, so 04 is gate-blocked from promoting until it re-aligns against the new 02 — **independent of whether any PI was filed against 04.** The gate keys off the edge, not off PI-presence. Closed.

### 4.2 Deep node / F2 (04 abstracts a detail away that 05 cashes out)
05 has its **own direct 02-edge** (`alignment-verifier.md:50`; for stage 05, per-component, §3.7). Two independent facts close the *structural* failure: (a) 05's 02-edge goes stale on 02's re-promote regardless of what 04 did, so 05 is gate-blocked until *it* re-aligns against the new 02; (b) the abstraction filter (`alignment-verifier.md:83-95`) only spares a stage that **does not repeat** the detail — 04 (abstracted it away) is correctly cleared, while 05 (which repeated the concrete value) is where a changed value can show as a CONTRADICTION. The cleared middle never severs the deep node, because the deep node does not depend on the middle's freshness — it has its own edge.

**Honest bound (v2 review):** the gate guarantees 05 is **re-checked**, not that the AV **flags** every change. The AV is claim/string-level, so a *token-preserving semantic* change (02 redefines the meaning of value "B" while keeping the string "B", and 05 copied "B" verbatim) matches string-to-string and slips through — an `ALIGNED` (zero-discrepancy) re-align then advances the edge. That residual is the Alignment Verifier's existing blind spot, unchanged by this proposal; v3 does not claim to fix it, only to force the re-check that gives the AV its shot. Structurally closed; detection is as good as the AV.

### 4.3 Two-parent / ordering (F3)
No controller means no "reconcile 04 against changed-02-while-03-still-dirty" hazard: a Review round reads the **full current upstream set** at once (`04-architecture/review/orchestrator.md:449-451` passes both live paths), so 04 always reconciles against current-02 **and** current-03 together. If a later 03 re-promote re-dirties 04's 03-edge, 04 re-aligns again — ordinary iteration, bounded by the existing review-loop convergence. The ordering problem dissolves rather than needing a barrier.

### 4.4 Convergence (F4)
No new loop is introduced, so no new thrash surface. Convergence equals the existing Review loop's, using its existing suppression (`consolidator.md` re-raise matcher; `cross-boundary-requirements.md:45`). The honest bound from F4 stands: an owner-resolves-differently re-raise is only suppressed after the owner explicitly declines it once (`WONT_FIX` + Concern key) — unchanged from today, and not made worse here.

---

## 5. What is new vs reused (v3.3)

**Reused unchanged:** the `Frozen-At` token + equality staleness check (04→05, 05→06); the Alignment Verifier as the affected-check; Review as the rebuild-on-discrepancy; log-only escalation; re-raise suppression; the review-mandatory Promote guard.

**New (the buildable core — items 1–6):**
1. Stamp `Frozen-At` in the **02 and 03 promoters** (04 already does it). §3.1
2. Record **per-edge reconciled-`Frozen-At`** (the AV-read token) on consumers — 03/04 in their `workflow-state.md`, and **per component** for 05. §3.2, §3.7
3. Add the **equality freshness clause** to the review-mandatory Promote guard (03–04; 02 forward-provision only, §3.3 scope note), the **per-component** Promote guard, and the **coherence sign-off** (05). §3.3, §3.7
4. Extend the Alignment Verifier to **record the `Frozen-At` it read** for each source (output-schema TBD at build, R2), and build the **standalone callable "re-align" wrapper** invoked as a Promote gate-step: run AV → **advance the edge iff `ALIGNED` for that source** (not `PROCEED`) → else HALT to human disposition (resolve or override). The wrapper does the advance/route/log; the AV only reports. §3.2, §3.3, §3.4
5. Add an **eager-detect line to each promote *orchestrator's* closing report-to-user** (not the promoter agent) — name the direct downstream stages this re-promote staled (a static consumer list, advisory). §3.3
6. **[05 Tier 2]** a **decomposition-membership detector** — a genuinely-new agent at a new altitude (set-first, stage-level, §6-roster-diffing; *not* a copy of the body-first absent-from-freeze detector), **fired by a §6-roster set-diff at Architecture re-promote** (preconditions: skip FIRST_FREEZE / uninitialized-05; ships in the safe degraded form absent a stable §6 id — R7), which auto-proposes the decomposition delta and HALTs to the human. §3.7

No cascade controller, no auto-*mutation* loop, no new reconciliation *workflow*. **Deferred (explicit follow-up):** the *automated* incremental 05 re-decomposition action for a Tier-2 hit (detection ships now; the automated remediation does not — the re-decompose decision stays human). §3.7

---

## 6. Integration with adjacent committed work

- The **02/03 document-conservation gate is committed** (`345ee45`): the flow is `guard → split → conservation-gate → publish → record` with a `promote-metadata.md`. There is no uncommitted rework to sequence around — v3.2 is simply authored against committed source. The freshness gate is a Promote **precondition** (On Start, same class as the review-mandatory guard, `02/03 orchestrator.md:24-27`); the conservation gate is a **post-split** verbatim check. Different lifecycle points, different objects — they compose without racing (place the freshness clause at On Start, guard-first before state mutation, to preserve the no-stranding invariant).
- The `Frozen-At` **stamp** goes in the **promoter** (round-folder original), not the orchestrator publish (§3.1). The `promote-metadata.md` may additionally *record* the token for the audit trail, but the authoritative stamp is the promoter's header write, mirroring 04.
- Sources drift from generated `agents/` until rebuilt (edit `agent-sources/`, re-run the builder), so v3's edits go in `agent-sources/` and require a rebuild.

---

## 7. The dependency DAG (corrected — direct edges)

From `alignment-verifier.md:47-50` (the authority v1 mis-paraphrased):

- **02-prd** ← Blueprint (01)
- **03-foundations** ← 02
- **04-architecture** ← 02, 03
- **05-components** ← 04, 03, **02** *(all direct — not "02 via 04"; this directness is what closes F2)* + the frozen `cross-cutting.md` registry (already `Frozen-At`-gated). **For 05 these edges are held and gated per component** (§3.7 Tier 1), with a stage-level decomposition edge to Architecture §6 (§3.7 Tier 2).
- 06–12: automated, no PIs (`pending-issues-format.md:14`) — the 06 freeze-gate is the precedent, out of scope as a target.

Each edge above is one freshness-gate edge — except 02←01, which is inert until 01 gains a promote/`Frozen-At` stamp (§3.3 scope note). The gate is per-edge and local; there is no global ordering to maintain.

---

## 8. Risks & open questions (for re-review to attack)

- **R1 — token home in 02/03 (largely resolved).** Stamp in the promoter header, mirroring 04's unconditional overwrite (§3.1) — the promoter write is authoritative, and the header line is outside the conservation gate's verbatim-critical sections. Residual: confirm the `promote-metadata.md` audit copy (if kept) can't drift from the header stamp (make the header the single source; metadata is a copy, not a second authority).
- **R2 — consumer-side record + AV output schema (build-time decisions).** The reconciled-`Frozen-At` block lives in each consumer's `workflow-state.md` — for 05, in each **per-component** state file plus the stage index for the decomposition edge. Confirm the Review orchestrator writes it at round completion and the Promote guard reads it at gate time, with no state-schema collision (esp. 05's per-component vs stage-index split). **Also decide the AV's output schema** for the per-source `Frozen-At` it read (a structured field the gate wrapper parses, §3.4) — mechanical, but must be pinned before items 2/4 interlock.
- **R3 — cost of clearing a stale edge (RESOLVED, decision B/C).** Clearing is a **standalone AV-recheck** (single read-only agent; auto-advances only on `ALIGNED` for the source, else HALTs to human disposition), invoked as a Promote gate-step — *not* a full Review round, and *not* section-scoped (that risks a false-clean). The common empty-cascade (`ALIGNED`) case clears with zero human involvement; only a real discrepancy surfaces. Section-scoped optimization is explicitly out of scope.
- **R4 — is gating *promote* the right gate?** Verified against source: nothing reads a stage's *reviewed* (pre-promote) output across a stage boundary — downstream reads only promote-published docs (`04-promote:74`, `02-promote:69`, `05-promote/orchestrator.md:74`), so `promote` is the correct choke point and the transitive backstop holds.
- **R5 — 05's edges vs the registry (addressed in §3.7).** 05's 04→05 freshness is the contract-registry `Frozen-At` (contracts) *plus*, now, the per-component prose edges to 02/03/04. These are different objects (registry = contracts; direct edges = prose alignment) and the design does not add a redundant 04 prose-edge where the registry already gates. Confirm the two don't double-HALT confusingly at the same freeze.
- **R6 — backward audit (decision E — DONE 2026-07-21).** Audited the ~25 prior alignment-syncs across the PRD + Foundations registers (read-only, two parallel sweeps). **Systemic finding: 0/25 were owning-stage-validated** — 14/14 PRD and 11/11 Foundations entries were direct-edit-and-self-RESOLVED; the other 7 Foundations entries were *correctly* logged-UNRESOLVED (the improvised log-only path). Total unvalidated exposure — the empirical confirmation of this design's motivation. **Realized damage bounded:** 1 possibly-live alignment gap (Foundations Gmail-SMTP vs a claimed manual/no-SMTP edit — a *live-project-instance* concern, parked, not a builder issue), plus register/doc hygiene (a §5-for-§3 register mis-citation with the doc already correct; a superseded-not-reconciled entry; two incomplete supersession notes; a §8-for-§9 doc typo). **Two failure modes beyond the known wrong-section class surfaced:** *doc-vs-register drift* (a RESOLVED entry describing an edit not present in the doc) and *superseded-not-reconciled*. Every hit is a class the owning-stage review (the log-only path) would have caught — so the audit doubles as validation. Live-project hygiene fixes are tracked on the project side, not here.
- **R7 — 05 Tier-2 detector precision (trigger decided; one build hazard).** Trigger = §6-roster set-diff at Architecture re-promote (decision C). The remaining build concern: the set-diff must key on a **stable component identifier**, not the display name, or a §6 rename false-positives as missing+orphaned. Confirm §6 carries (or can be given) a stable id the stage-index rows also carry.
- **R8 — Tier-2 *action* deferred (decision D, accepted).** Detection ships now (loud missing/orphaned); the **automated** incremental re-decomposition does **not** — 05 has no Expand and re-init is destructive (§3.7), so the action is HALT-to-human (the re-decompose decision is human judgement anyway). Open follow-up: build a non-destructive 05 decomposition-reconciliation later so the *action* can also be triggered rather than hand-run.
- **R9 — AV token-preservation blind spot (§4.2).** The gate forces a re-check but the AV won't catch a token-preserving semantic change. This is pre-existing and out of scope, but flag whether it deserves its own follow-up (e.g., a semantic-diff signal on the upstream change), since this mechanism *advances the edge* on the AV's clean verdict and thereby trusts it.

---

## 9. Scope boundaries — explicitly NOT changed

- Log-only upward escalation, P2 triage, the review-mandatory guard, the conservation gate — all assumed/untouched.
- 01-blueprint: no upstream → a `Frozen-At` **source** only (once it too promotes), never a consumer.
- 06–12: out of scope for the doc-edge freshness gate; the 06 gate is the precedent.
- No cascade controller, no auto-*mutation* loop, no new reconciliation workflow — deliberately.

---

## 10. Decisions made (2026-07-21) and remaining follow-ups

**Decided (human sign-off):**
- **A — Adopt** the core mechanism.
- **B — Clearing = a standalone AV-recheck callable unit, invoked as a Promote gate-step** (hybrid): auto-advance only on `ALIGNED` (per-source, zero discrepancies — not on `PROCEED`), else HALT to human disposition (resolve or override). Human triggers the workflow; the check runs inside it.
- **C — Eager-detect, lazy-resolve**: each promote *orchestrator's* closing report-to-user names the direct downstream stages this re-promote staled (static consumer list, advisory); the AV-recheck runs lazily when a stage is promoted. Tier-2 detector fires on a §6-roster-diff at Architecture re-promote.
- **D — Build the Tier-2 detector now** (auto-detect + auto-propose delta + HALT-to-human); defer only the *automated* re-decomposition action.
- **E — Run the backward audit** (R6) — **done 2026-07-21**: 0/25 syncs were owning-stage-validated (exposure confirmed); realized damage bounded to register/doc hygiene + one parked live-project alignment question. See R6.
- **Mechanical (author's call):** token home = promoter header line, single source; per-edge record = `workflow-state.md` block; **equality** compare, not ordering; section-scoped re-align optimization dropped.

**Remaining follow-ups (not blocking the core build):**
- The **automated** 05 re-decomposition action for a Tier-2 hit (a non-destructive decomposition-reconciliation; 05 has no Expand) — R8.
- The **AV token-preservation blind spot** (R9) — a token-preserving semantic upstream change slips the string-level AV; pre-existing, may deserve its own semantic-diff follow-up.
- Build-time confirmations: state-schema for the freshness block (R2), a stable §6 component id for the Tier-2 set-diff (R7), no confusing double-HALT between 05's registry gate and its prose edges (R5).
