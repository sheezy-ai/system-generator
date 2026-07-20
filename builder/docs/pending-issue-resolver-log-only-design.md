# Design Proposal: Alignment-Sync as Log-Only (Design B)

**Status:** PROPOSAL v5 — READY TO IMPLEMENT. Round-1 review (R1/consumers), round-2 review (dedup/rename/field-shape), and the focused confirmation (R5 + Concern-key) all complete and folded. R5 CLOSED (removed the collapsed line → visible+tagged `[RE-RAISE]`, verbatim Consolidator); Concern-key synthesis confirmed well-formed. No open design questions remain.
**Date:** 2026-07-20
**Author:** Claude (with Sean)
**Scope:** `builder/agent-sources/universal-agents/pending-issue-resolver.md`, the alignment-sync menus in the four review-stage orchestrators (02/03/04 + 05), `builder/guides/pending-issues-format.md`, and `builder/agent-sources/universal-agents/alignment-verifier.md` (**now a real change — see §5.4**).

---

## 0. Independent review outcome (2026-07-20)

Two independent reviewers, blind to each other, entered from different angles (one traced consumers/R1; one verified the mechanism claims + coverage). Both re-derived from source, not from this doc.

**Validated (file:line evidence in the review):**
- **R1 (immediate-edit reliance) is SAFE** — no gate/promote/coherence/next-stage step HALTs or emits wrong output assuming the sync edited the upstream doc. The sync report is write-only (no readers); every upstream-doc consumer reads it as current authority with no latch on the sync.
- **CLAIM 1 (register→Consolidator→Author loop is how upstream fixes actually happen) — VERIFIED** across all four stages (Consolidator pulls UNRESOLVED at Step 2; Author fixes; 46b closes).
- **CLAIM 2 (edit-upstream is vestigial) — VERIFIED**, could not be refuted.
- **Scope boundaries correctly untouched** — HALT path writes the register directly (not via resolver); 05 issue-router already log-only; 46b independent.

**Coverage claim CORRECTED (round-2 review).** The round-1 "resolver invoked *only* in the four review orchestrators" was **wrong** — the round-1 grep searched `pending-issue-resolver` / `Pending Issue Resolver` and missed the **Expand** orchestrators (02/03/04), whose Step 45 says "Handle pending issue sync — *same pending issue resolver pattern as review*" (spaces, not hyphens — the **third predicate-spelling miss** this session). Expand emits no literal `APPLY` token (so no hard silent-drop) but inherits the rename + the "Sync = apply to upstream" framing, so it **is in scope**. Added as §5.5.

## 0b. Round-2 review outcome (2026-07-20) — the new slice was NOT sound as specified

Two blind reviewers (dedup/suppression correctness; rename+field-shape completeness) found the v3 mechanism reproduced the very non-convergence trap it exists to close, plus real field-shape and scope gaps. All folded into §5/§6/§8. Headlines:
- **Dedup/suppression invented a vaguer matcher than the proven one.** v3 matched on `target + gist` and silently dropped; the proven Consolidator/re-raise matcher uses **section-anchor + gist**, **never silent-drops**, has a **materiality/staleness gate**, and an **uncertain bucket**. v3 dropped all four → would silently suppress a genuinely-new same-target finding (dangerous) and re-suppress a WONT_FIX gone stale after upstream revision. **Fix: reuse the proven matcher verbatim; one shared definition; surface every skip.**
- **Silent no-op:** if the human says "Sync" but dedup skips, nothing surfaced it. **Fix: the sync report must list skipped-as-already-logged.**
- **Field-shape:** `WONT_FIX` **requires a `Concern key`** (format guide) — and the suppression matches on it — but nothing supplies it; the resolver **must synthesize** the Concern key + the `Source` field. (The G2 verifier extension alone was insufficient.)
- **Rename leaks** beyond the "isolated" set — into `docs/universal-agents.md`, `docs/05-components.md`, and format-guide token strings — none silently drop a decision, but they go false after the change.

**Two substantive gaps found and folded in below:**
- **G1 — duplicate re-logging regression.** Today's edit path is self-correcting (edits upstream → next round sees no discrepancy). Under B the upstream doc stays unchanged until its stage is revised, and the Alignment Verifier has **no register-awareness or re-raise suppression** (that lives in the Consolidator, which never runs on the alignment stream) and the resolver has **no dedup** — so the same discrepancy is re-detected and **re-logged as a duplicate** every subsequent same-stage round. Not a break (round still exits mature — maturity counts `03-issues-discussion.md`, not the alignment report), but real register pollution. → new §8 R3 rewrite + dedup requirement + §6 decision 4.
- **G2 — field-shape / PI→DISC join gap.** The resolver cannot build a well-formed `DISCREPANCY` register entry from the report's "Pending Issues to Log" section — that section lacks the exact-quote pair and per-side Section refs (they live in the separate `DISC-NNN` block, with no PI→DISC link). → §5.4 upgraded to a real Alignment-Verifier output change + §6 decision 5.

**Doc corrections folded in:** stale "Create or Review" claim in the resolver System Context (it is review-only); §7 wording that contradicted §5.2 on 05.

---

## 1. Problem

The universal **Pending Issue Resolver** is the odd one out in an otherwise consistent register-escalation model.

**The model the rest of the system uses.** A downstream stage that finds a problem in a frozen upstream document **logs it to that upstream stage's `pending-issues.md` register** (`Status: UNRESOLVED`, or `AWAITS_UPSTREAM_REVISION` for cross-boundary P2 items). The upstream document is **never edited from the downstream workflow** — it changes only through its own reviewed revision, whose Consolidator pulls unresolved register items into that review's issue stream (Step 2) and whose Author applies the fix. This is stated in the format guide ("upstream stage workflows action their own `AWAITS_UPSTREAM_REVISION` items when that stage is next revised") and is how the resolved history was actually produced (PI-025…042 were all logged-then-fixed-by-a-later-round). The 05 issue-router follows this model exactly.

**What the resolver does instead.** Its `APPLY` path (Step 2) **reads and edits the upstream document directly**, then marks the register entry `RESOLVED`. It also assumes the entry **already exists** in the register ("Read each upstream pending-issues.md to find the logged issues").

**Why both assumptions are wrong for what feeds it.** The Alignment Verifier writes only the **report** (`07-alignment-report.md`), not the register — so the entry the resolver expects to "find" was never created. And its classification table already says SYNC_UPSTREAM = "Log to pending-issues.md," which the resolver's edit-the-doc behavior contradicts.

**Symptom.** For a newly-surfaced, non-SHOWSTOPPER alignment finding there is no clean disposition: `APPLY` = edit the frozen upstream doc now (wrong model + bypasses that stage's review); `DEFER` = leave it only in the round report (a dead-letter); `REJECT` = won't-fix. The **normal** action — *log it to the upstream register as a new open item for that stage to action when next revised* — has no slot. In Architecture Round 32 the resolver **improvised** it (logged Foundations `PI-015 UNRESOLVED` for DISC-001 instead of editing `foundations.md`) — correct behavior, but unspecified, so a literal run would have edited Foundations.

---

## 2. Decision

**Design B — normalize alignment-sync to log-only.** The resolver never edits an upstream document. Its job becomes: **log each human-approved alignment finding to the target stage's register as a new `UNRESOLVED` entry, and set status per the human decision.** The actual fix happens the way it already does — the upstream stage's next review Consolidator pulls the entry in and its Author applies it.

Rationale (full options analysis in the conversation that produced this doc): the edit-upstream path is **vestigial** (not how fixes actually happen here), it is the **only** way a frozen document can change without passing its own review (a correctness hazard), and removing it is **mostly subtractive** because the register→Consolidator→Author loop that applies fixes already exists. Rejected Design A (keep edit-upstream + add a log disposition) because it entrenches two models permanently and leaves the bypass hazard open.

---

## 3. Target behavior (before → after)

| Aspect | Before | After (Design B) |
|--------|--------|------------------|
| Resolver on an approved SYNC_UPSTREAM finding | Edit the upstream document; mark register `RESOLVED` | **Append a new `UNRESOLVED` entry** to the target register (DISCREPANCY shape); do **not** touch the upstream document |
| Resolver assumption | Entry already in the register | Entry is **created** by the resolver from the alignment report's "Pending Issues to Log" section |
| Who applies the actual upstream fix | Resolver (immediately, unreviewed) | The upstream stage's **own next review** (Consolidator pulls the `UNRESOLVED` entry; Author fixes it; Step 46b closes it) — unchanged, existing mechanism |
| DEFER | Leave in report (dead-letter) | Unchanged in effect (not routed); wording already corrected |
| REJECT | Mark `WONT_FIX` | **Log the entry as `WONT_FIX` with a synthesized `Concern key`** (§6.2 + §5.1) — the dismissal record §5.2 suppression matches against |

Status/Kind for logged entries: **`Status: UNRESOLVED`, `Kind: DISCREPANCY`** (the default document-conflict shape). Its `This Document States` / `Downstream Document States` quote pair is supplied by the §5.4 verifier extension (round-2 correction — the verifier does **not** produce it today); `Source` / `Concern key` / `>> RESPONSE:` are resolver-synthesized (§5.1). `AWAITS_UPSTREAM_REVISION` / `CROSS-BOUNDARY-UPSTREAM` remains the 05 issue-router's separate P2 path and is **not** changed here.

---

## 4. Disposition vocabulary (naming sub-decision — see §6)

Today the menus use `SYNC_ALL / DEFER_ALL / SELECTIVE`, and the resolver uses per-issue `APPLY / DEFER / REJECT`. Under B, "APPLY/Sync" no longer *applies* anything — it **logs**. Keeping the token `APPLY` while changing its meaning re-creates the exact semantic ambiguity that caused this failure.

**DECIDED (§6.1 accepted):** rename the per-issue token `APPLY → LOG` (and the REVIEW_NEEDED `APPLY_UPSTREAM → LOG_UPSTREAM`, keeping the existing `APPLY_DOWNSTREAM → LOG_DOWNSTREAM` for symmetry — both now mean "append a new register entry to the named target"). Keep the human-facing menu verb **"Sync"** but define it precisely as *"log to the target stage's register for its next review to action."*

**Completeness obligation (round-2 review — the "isolated to 5 files" claim was WRONG).** The token-parse/silent-drop path IS the resolver + four spawn sites (complete). But the rename **leaks** into sites that go false after the change and must also be updated (they don't silently drop a decision, but they misdocument the system):
- `builder/docs/universal-agents.md:89,96,97` — human-facing resolver description ("applies surgical edits to the target document").
- `builder/docs/05-components.md:133` — resolver row (`APPLY/DEFER/REJECT`).
- `builder/guides/pending-issues-format.md:25` (`APPLY → RESOLVED` — the resolver no longer produces RESOLVED) and `:229-230` (`Author applies fix (APPLY)` — **ambiguous: this describes the Author, may legitimately stay** — needs an explicit keep/rename call, not silent inheritance).
- **Expand** orchestrators (§5.5) inherit the rename via "same resolver pattern."
Every site above must be found by exhaustive grep and changed together — and the grep predicate must cover naming variants (`APPLY`, `APPLY_UPSTREAM/DOWNSTREAM`, spaced "pending issue resolver" vs hyphenated), the exact class that has now missed three times this session.

---

## 5. Per-file change plan

### 5.1 `universal-agents/pending-issue-resolver.md` (core)
- **System Context / Task:** re-describe the role as "log human-approved alignment findings to the appropriate register and set status," removing "apply resolutions … to upstream documents" and "edit the upstream document." **Also drop the stale claim that it is "called at the end of Create or Review workflows"** — it is **review-only** (create runs the Alignment Verifier but never the resolver; see §7).
- **Step 2 (was APPLY, now LOG):** read the alignment report's "Pending Issues to Log" entry → **append a new `UNRESOLVED`, `Kind: DISCREPANCY` entry** to the target register in the format-guide shape → update the register Summary counts. **No upstream-document edit.**
- **Field synthesis (from round-2 G2+):** the extended report (§5.4) supplies the quote pair + Section refs. The resolver must additionally **synthesize** the register-required fields the report does *not* carry: **`Source`** (`[downstream stage] Review workflow, Round [N]`, from the invocation context) and — **for a `WONT_FIX` (REJECT) entry — a `Concern key`** (spec-section anchor + one-line concern gist, per format guide L147). The `Concern key` is **mandatory**: it is the stable string §5.2 suppression and future Consolidators match against; without it a settled dismissal is re-litigated (the trap this design closes). Insert a `>> RESPONSE:` placeholder too (Unresolved template).
- **Dedup (G1 — required, §6.4) — reuse the proven matcher, don't invent one:** before appending, check the target register for an existing entry using **the Consolidator/re-raise matcher discipline verbatim**, not a looser variant:
  - **Match key = `target-stage + section-anchor + concern-gist`** (NOT `target + gist` — the coarse key collides; the §5.4 Section refs make the anchor available).
  - **Materiality/staleness gate:** do **not** treat it as a match if the cited upstream section has *materially changed* since the existing entry (reuse the format guide's Staleness Detection) — the change may legitimately reopen the concern.
  - **Never silent-drop:** on a match, do not silently skip — record it in the sync report as `PI-NNN: skipped — already logged as PI-MMM (UNRESOLVED|WONT_FIX)`.
  - **Uncertain bucket:** close-but-not-clearly-same ⇒ **log it (show it), don't suppress** (reconciler discipline).
  - **Semantic match, never string-equality:** compare "same section + substantially-same concern" (as the Consolidator does), not literal `Concern key`/ID strings — the verifier re-authors gist/quotes every round, so a string match would false-negative and re-duplicate. (Confirmation review, TASK 2b: this is the invariant that makes cross-round matching work.)
  - This matcher definition is **shared** with §5.2 (one definition, referenced by both) so the two sites cannot drift.
- **REVIEW_NEEDED handling:** `APPLY_UPSTREAM` → `LOG_UPSTREAM` (append to the upstream register); `APPLY_DOWNSTREAM` → `LOG_DOWNSTREAM` (unchanged behavior, renamed); `DEFER` unchanged.
- **Sync report / Output / Quality Checks / File Output:** drop "Updated upstream document(s)"; the report lists *logged* entries (target register + PI-ID) **and a `Skipped — already logged` list** (never silent). Remove the "Documents Updated" table (or repurpose to "Registers Updated").
- **Constraints:** replace "Exact edits to upstream docs" with "Append well-formed register entries; never edit an upstream document."

### 5.2 The four review-stage orchestrator menus + menu-build suppression
- 02/03/04 Step 40 menu + Step 46 branch; 05 `orchestrator-router.md` menu + `orchestrator-post-discussion.md` branch.
- The **Sync** option wording changes from "apply to upstream documents" to "**log to the target stage's register** for its next review to action." Per-issue tokens become `LOG / DEFER / REJECT` (menu verb stays "Sync", precisely redefined per §4).
- **NEW — menu-build suppression (§6.4), using the §5.1 shared matcher:** before presenting the "Pending Issues to Sync Upstream" menu, cross-check each candidate against the target register with the **same shared matcher** (`target-stage + section-anchor + concern-gist` + staleness gate):
  - A finding matching a **`WONT_FIX`** entry (staleness-gate-passed) stays **visible and inline, tagged** `[RE-RAISE — dismissed Round N: <rationale>]` with **default disposition DROP** — exactly as the Consolidator renders a suppressed re-raise (`consolidator.md:65`: keep visible + tag, never delete/collapse). **Not collapsed** — a confidently-wrong match must still land in front of the human, not behind an expand. (This is the true verbatim reuse; the v4-draft "collapsed line" was the sole deviation and is removed — it was what left R5 open to attention-bypass.)
  - A finding matching an **`UNRESOLVED`** entry stays **visible**, annotated "already logged as PI-NNN, awaiting upstream" (legitimate self-limiting signal).
  - **Staleness reopens:** if the upstream cited section materially changed since the `WONT_FIX`/`UNRESOLVED` entry, treat as **not matched** — show it normally (the dismissal may be stale).
  - **Uncertain ⇒ show.**
- **Placement:** do the filter at orchestrator menu-build (keeps the verifier's input contract unchanged). Because concern-gist matching is delegated to dedicated agents everywhere else, the matcher spec must be explicit and shared with §5.1 — not two independent inline judgments that drift.
- **Note:** this supersedes the SYNC-side of the recent defer-framing commits (a26085d, 6e937bf); the defer-side wording those added stays.

### 5.3 `guides/pending-issues-format.md`
- **"Who Writes" (L25):** the Pending Issue Resolver now **logs new alignment-sync entries** (`UNRESOLVED`, or `WONT_FIX` on REJECT with a `Concern key`) and sets status; it does **not** edit upstream documents. The literal string `APPLY → RESOLVED, DEFER → DEFERRED, REJECT → WONT_FIX` must change — the resolver **no longer produces `RESOLVED`** under B.
- **Status Transitions (L229-230):** the diagram label `Author applies fix (APPLY)` describes the **upstream Author**, not the resolver token — **keep it** (explicit keep call), but confirm it can't be misread as the resolver's decision token now that the token is `LOG`.
- **Stale attribution (L238):** "DEFERRED/WONT_FIX are set by the Pending Issue Resolver **or Stage Coherence Review (Phase 2)**" — coherence edits inline and never calls the resolver (§5.5 note); this attribution is already stale and should be corrected while here.

### 5.4 `universal-agents/alignment-verifier.md` (now a real change — G2)
- Its classification table already says SYNC_UPSTREAM/REVIEW_NEEDED = "Log to pending-issues.md," which is *aligned* with B; and it writes only the report, never the register (assumption confirmed). Keep that.
- **G2 fix (field-shape):** the report's **"Pending Issues to Log"** section (`alignment-verifier.md` output format, ~L299-317) currently carries only Target / Severity / Summary / Issue / Evidence / Impact. The register `DISCREPANCY` shape needs the **exact-quote pair** (`This Document States` / `Downstream Document States`) **and per-side Section refs**, which today live only in the separate `DISC-NNN` block with **no PI→DISC link**. Fix by extending each "Pending Issues to Log" entry to carry: the two exact quotes + their Section refs + a `Derived from: DISC-NNN` back-link.
- **Note (round-2):** this extension is *necessary but not sufficient* — `Source`, the `>> RESPONSE:` marker, and (for REJECT→`WONT_FIX`) the `Concern key` are still not in the report and are **synthesized by the resolver** (§5.1), not carried by the verifier. So the verifier change closes the quote-pair join only; the resolver does the rest.

### 5.5 Expand orchestrators (02/03/04) — added in round-2
- `stages/{02,03,04}/expand/orchestrator.md` Step 45 ("Handle pending issue sync — same pending issue resolver pattern as review workflow") **inherits the change.** It emits no literal `APPLY` token (delegates "same pattern as review"), so the resolver rename flows through, but its human-facing "Sync = apply to upstream" framing must get the same correction as §5.2, and it must invoke the same log-only + shared-matcher behaviour. Verify each Expand orchestrator's sync step points at the corrected resolver and carries the corrected menu wording.

### 5.6 Documentation sites — added in round-2 (no behaviour, but go false otherwise)
- `builder/docs/universal-agents.md:89,96,97` and `builder/docs/05-components.md:133` — resolver descriptions that assert "applies surgical edits to the target document" / list `APPLY/DEFER/REJECT`. Update to the log-only + `LOG` vocabulary.
- **Out of scope but noted:** `stages/05-components/coherence/orchestrator.md` keeps its **own** inline `APPLY = edit target spec` on the lateral cross-component path (it does **not** call the resolver). This design does not change it; §5.3's L238 correction just stops the format guide mis-attributing coherence's inline edits to the resolver.

---

## 6. Decisions (ACCEPTED 2026-07-20)
1. **Naming — ACCEPTED: rename `APPLY → LOG`** (and `APPLY_UPSTREAM → LOG_UPSTREAM`, `APPLY_DOWNSTREAM → LOG_DOWNSTREAM`). The token must match behaviour; keeping `APPLY` to mean "log" re-creates the defect at the token layer. See §4 completeness obligation.
2. **REJECT — ACCEPTED: log rejected findings to the target register as `WONT_FIX`** (with reason). Load-bearing for convergence, not just audit: the `WONT_FIX` entry is the record decision 4's suppression reads to stop re-litigating a settled dismissal. **Coupled to decision 4.**
3. **Immediate-edit escape hatch — ACCEPTED: removed entirely.** No "trivial/certain" exception. Pure Design B; an exception re-opens the bypass hazard and the two-model complexity.
4. **Dedup + suppression — ACCEPTED, hardened in round-2:** resolver-side dedup (write backstop) + menu-build suppression (stops re-prompt), both using **one shared matcher that reuses the proven Consolidator/re-raise discipline verbatim** — `target-stage + section-anchor + concern-gist` key (not the coarse `target+gist`), a **materiality/staleness gate** (a changed upstream section reopens, not suppresses), **never silent-drop** (skips are listed in the sync report; suppressed WONT_FIX go to an expandable "already-adjudicated" line), and an **uncertain⇒show** bucket. `UNRESOLVED`-matched findings stay visible; `WONT_FIX`-matched (staleness-passed) stay **visible and tagged `[RE-RAISE]` inline, default-drop** (Consolidator-style — not collapsed; the confirmation review showed a collapsed line permits attention-bypass on a confidently-wrong match). The v2/v3 "invent a conservative matcher" framing is superseded — we adopt the existing one. **Invariant:** the match is **semantic** (same section + substantially-same concern), never string-equality on the Concern key/ID — the verifier re-authors gist each round, and the Consolidator already matches this way.
5. **G2 field-shape — ACCEPTED: extend the Alignment Verifier's "Pending Issues to Log" entries** to carry the quote pair + Section refs + `Derived from: DISC-NNN`. Round-2 addendum: this is necessary-not-sufficient — the resolver additionally **synthesizes `Source`, the `>> RESPONSE:` marker, and (for `WONT_FIX`) the mandatory `Concern key`** (§5.1). Without the Concern key, decision 4's suppression has nothing stable to match.

---

## 7. Scope boundaries — explicitly NOT changed
- **SHOWSTOPPER / HALT path:** the orchestrator writing a blocking issue upstream and setting `BLOCKED_UPSTREAM_ISSUE` is a separate route (format guide "Who Writes" line 21) — untouched.
- **05 issue-router / decision-triage:** the agent that writes `AWAITS_UPSTREAM_REVISION` and never edits upstream docs — untouched (it is the model we converge on). **Note:** this is *distinct* from 05's Step 18 resolver call (`orchestrator-post-discussion.md` + the router's `SYNC_ALL` menu), which drives the same edit-upstream resolver and **is in scope** per §5.2. Do not conflate the two.
- **Create-workflow alignment findings:** out of scope. Create runs the Alignment Verifier but never the resolver; its SYNC findings are surfaced with FIX/ACCEPT and dropped on ACCEPT. That is a **pre-existing gap** this design does not introduce and does not fix — noted so it isn't mistaken for in-scope.
- **Each stage's own 46b register-closing step:** unchanged.
- **The register→Consolidator→Author fix loop:** unchanged — B *relies* on it (verified to exist in all four stages).

---

## 8. Risks & required verification
- **R1 (load-bearing) — DISCHARGED by review.** Two independent reviewers confirmed no workflow proceeds on the premise that an alignment sync edited the upstream doc: the sync report is write-only (no readers), and every upstream-doc consumer (promote gate, materializer/fidelity checker, next-round alignment verifier, 05 create/init/review/coherence) reads the doc as current authority with no latch on the sync. Rounds route to Promote on `PROCEED` without reading back the synced doc.
- **R2:** prose-reconciliation across 4–5 files could introduce a new inconsistency while fixing this one → mitigate by landing it as one reviewed change.
- **R3 (G1): duplicate re-logging / re-litigation.** Mitigated by the §5.1/§5.2 shared matcher (mandatory). Note the residual is *not* "one entry" — on re-phrase across rounds a too-tight match still leaks duplicates, and a too-loose match suppresses new findings; the staleness gate + section-anchor key + uncertain⇒show manage that trade rather than eliminate it.
- **R4 (naming):** a missed rename site silently drops a decision (parse path) or misdocuments the system (doc sites). Mitigated by the §4 completeness obligation + variant-aware grep.
- **R5 (dangerous direction): false-positive suppression — CLOSED by the confirmation review.** The residual was v4-draft's *collapsed* "already-adjudicated" line (attention-bypass on a confidently-wrong match). Fixed by rendering WONT_FIX matches **visible + tagged `[RE-RAISE]` inline, default-drop** (verbatim Consolidator behavior, §5.2). A confidently-wrong match now lands in front of the human, not behind an expand — same bar the Consolidator already accepts. Two distinct concerns in the *same* section are separated by the semantic gist match + uncertain⇒show; if that mis-fires, the inline `[RE-RAISE]` tag is the catch.
- **R6 (round-2): the matcher is delegated to inline orchestrator prose** for the menu-build half, whereas the system elsewhere delegates concern matching to dedicated agents. Accept for now (bounded), but the shared-definition requirement (§5.1) is what keeps the two halves from drifting; a future option is a small shared matcher sub-agent.

---

## 9. Rollout sequence
1. ✅ Round-1 review (dependency re-trace + R1) → folded. ✅ Decisions §6 accepted. ✅ Round-2 review of the new slice (dedup/suppression + rename + field-shape) → folded (this v4).
2. ✅ **Light confirmation done** — R5 CLOSED (collapsed line → visible+tagged `[RE-RAISE]`); Concern-key synthesis well-formed (semantic-match invariant recorded). No open design questions.
3. **Implement across §5.1–§5.6 as one change** (variant-aware grep for the rename); re-run the builder to regenerate `agents/`.
4. No live workflow is mid-flight on this path, so no migration needed.
