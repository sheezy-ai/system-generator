# Component Retirement Orchestrator (ORPHANED)

Retires a single **ORPHANED** component — one 05 instantiated that the current Architecture §6 no longer requires — via a **guarded, reversible, reference-checked** procedure. Run this by name, against a specific component the decomposition-membership detector flagged ORPHANED, after that component has been dropped from §6 by an Architecture re-promote.

This is the defined action path for the detector's ORPHANED output. The detector **detects and proposes and HALTs** (`decomposition-membership-detector.md`); the 04-promote orchestrator surfaces the ORPHANED delta and says **"the human decides and triggers"** and **"Do NOT modify 05"** (`04-architecture/promote/orchestrator.md:523`). This orchestrator is what the human then triggers. It automates the judgement-free legwork (sweep, archive, index-edit, audit) and keeps the two genuine judgements human: **whether** to retire (the human triggers this) and **how to resolve a live dependent / contract** (the human decides on a HALT).

---

## Purpose

An ORPHANED component leaves realized artifacts behind that a destructive re-init would clobber (it resets every *other* component's state) and that ad-hoc file surgery would strand references to. This orchestrator provides the **non-destructive** path:
- **Blocking sweep** — the load-bearing safety surface: a whole-spec inbound-reference scan of every other component spec + a §8 producer/consumer check. Any live inbound reference or §8 role → HALT.
- **Archive, not delete** — the component's realized artifacts are moved to reserved retired namespaces (reversible), never deleted.
- **Index edit** — the `## Component Specs` row is removed (so the detector no longer sees it as instantiated → no re-flag) and recorded in a **status-less** `## Retired Components` audit section.
- **Direct re-coherence** — the human is told to re-run the coherence sign-off so the `## Frozen Components` manifest regenerates without the retiree.

Retirement touches only 05-owned realized artifacts; the 04-owned contract registry (§8) is **escalated, never edited**.

---

## When to Run

- **After** an Architecture re-promote drops a component from §6 and the Tier-2 decomposition-membership detector reports it **ORPHANED** (`DELTA_PROPOSED`), and the human has decided to **retire** it (rather than re-parent, or treat a missing+orphaned pair as a rename).
- **Not** for MISSING (that is per-component Create) and **not** for re-split / merge / re-parent (deferred — human-driven).

**Invocation:**
```
Read the Component Retirement Orchestrator at:
{{AGENTS_PATH}}/05-components/retire/orchestrator.md

Retire ORPHANED component: [component-name]
```

---

## Fixed Paths

**Stage state**: `system-design/05-components/versions/workflow-state.md`
**Current architecture (§6)**: `system-design/04-architecture/architecture.md`
**Component specs (live)**: `system-design/05-components/specs/`
**Cross-cutting spec (§8 registry)**: `system-design/05-components/specs/cross-cutting.md`
**Component versions**: `system-design/05-components/versions/`
**Retired versions namespace (reserved)**: `system-design/05-components/versions/retired/`
**Archived specs namespace (reserved)**: `system-design/05-components/specs/archived/`
**04 pending-issues (escalation target)**: `system-design/04-architecture/versions/pending-issues.md`
**Retirement reports**: `system-design/05-components/versions/retired/`

---

## Preconditions

All must hold, else **no-op / error** — do not archive or edit anything until every precondition passes.

1. **05 is initialized and the named component has an active row in the `## Component Specs` table** of the stage `workflow-state.md`. If 05 is uninitialized, or the named component is not a row in `## Component Specs`, → **Error** (nothing to retire).
2. **The component is genuinely ORPHANED against *current* §6.** Re-confirm at run time against the current published `architecture.md` §6 — **not** the detector's cached proposal (§6 may have changed since). Reuse the detector's **stateless current-§6 diff** (`decomposition-membership-detector.md` Method):
   - Extract the **current §6 component set** (the required set) from `architecture.md` §6.
   - Extract the **instantiated set** (the realized set) from the `## Component Specs` table rows (any status).
   - The named component is ORPHANED iff it is **in the instantiated set and NOT in current §6**. If it *is* still in current §6 → **Error**: "[component] is still required by current Architecture §6 — not ORPHANED. Nothing to retire."
3. **Possible-rename guard.** While computing the diff above, also compute **MISSING** (in current §6, not instantiated). If **≥1 MISSING exists**, retirement **refuses**: → **HALT**: "[N] MISSING component(s) coexist with this ORPHANED one — this may be a rename (§6 carries no rename-stable id, so a rename surfaces as missing+orphaned; the detector forbids auto-pairing). Adjudicate retire-vs-rename first; if it is a rename, resolve that instead." This guard is **decision-ordering**, not history preservation (archive-not-delete already preserves history). It is deliberately coarse (any coexisting MISSING blocks) and false-negatives across promote rounds (a MISSING resolved earlier via Create leaves the orphan appearing alone later). If the human confirms a rename despite the guard, record a `renamed-from` / `renamed-to` hint in the audit row (Step 3).

---

## Orchestration Flow

**Immediate execution**: The user invoking this orchestrator against a named component IS the instruction to execute. Proceed immediately with the Preconditions, then Step 1. **Present the sweep findings before archiving or editing anything** — a HALT surfaces to the human, never a silent mutation.

### Step 1 — Blocking sweep (inbound references + §8 producer *and* consumer role)

This is the load-bearing safety surface. It is **purpose-built, not borrowed** — the cross-boundary routing reconciler flags only the routing-claim subclass (and by design excludes data contracts + bare mentions — `coherence/cross-boundary-routing-reconciler.md:44,:114`), so it is at most a *contributing input* for that one subclass, never the sweep.

**Expected ordering (avoids a false-alarm HALT).** Immediately after 04 drops the component from §6, still-stale siblings legitimately reference it — their re-align against the new §6 has not run yet. So the natural order is: **re-Review the live dependents first** (their re-align drops the reference), **then** retire. Treat a Step-1 inbound-dependent HALT as "re-Review these, then re-trigger retire," **not** an error.

**(a) Inbound sibling references — one whole-spec name-occurrence scan.**
Scan **every *other* component spec** for **any occurrence of the retiring component's name, across the whole spec**. This is deliberately **one full-text name-occurrence scan, not three separable narrow passes** — a structured reference (a sibling's §3 Interfaces / §7 Integration row "Reads from: X", a data-contract consumption) is neither the Dependencies column nor narrative prose, so a prose-only pass would miss it. Cover:
- **Narrative prose** — any mention by name.
- **The Dependencies column** — a sibling's dependency entry naming the retiree.
- **Structured sections / tables** — §3 Interfaces, §7 Integration, "Reads from:" / "Writes to:" rows, data-contract consumption, and any other structured reference.

Loci to scan (each "other component spec" = every instantiated component except the retiree):
- The published `specs/[sibling].md` where it exists.
- The sibling's latest in-flight draft (`versions/[sibling]/.../03-updated-spec.md`, or its current draft if no `03` exists) where it has not been promoted.
- The stage-index `## Component Dependencies` table (a Dependencies entry naming the retiree is an inbound reference too).

**HALT on any hit** (false positives are safe — the human adjudicates). Report every hit (which sibling, which locus/section, the surrounding line).

**(b) §8 producer *and* consumer role.**
Read `specs/cross-cutting.md` (the frozen §8 contract registry) and check for **any** contract naming the retiree in **either** its `Producer(s)` **or** its `Consumers` field. Do **not** rely on coherence Phase 4 to catch either:
- Phase 4 **explicitly skips** a `MATERIALIZED` contract whose sole producer is one real component (`coherence/orchestrator.md:137`) — a retired producer's contract would ride into the freeze **ownerless**.
- Phase 4's `DEFINED→VERIFIED` consumer-alignment rung (`coherence/orchestrator.md:138`, "owns ALL of them") would **error on** a retiree still listed as a consumer whose spec is now archived — **wedging the very re-freeze retirement depends on**.

The design distrusts 04 to have scrubbed §8 on the producer side; the identical distrust applies to the consumer side — so check both here.

**Disposition:**
- **Any live inbound dependent (a) → HALT.** Report them; the human resolves first (a sibling depending on something §6 says should not exist is itself a real defect — usually cleared by re-Reviewing that sibling against the new §6, per the expected ordering above). Retirement does not proceed.
- **A live §8 producer *or* consumer role (b) → HALT + escalate.** Write a `CROSS-BOUNDARY-UPSTREAM` entry to `system-design/04-architecture/versions/pending-issues.md` (`Status: AWAITS_UPSTREAM_REVISION`, per the existing `CROSS-BOUNDARY-UPSTREAM` shape — no new format) naming the retiree and the contract(s) whose producer/consumer entry the registry must drop or re-assign at the next 04 re-freeze. Report the escalation. Retirement does not proceed until 04 scrubs the entry and re-freezes.
- **Referenced by nothing live** → proceed to Step 2.

### Step 2 — Archive the realized artifacts (reversible, reserved namespace)

Move (never delete) the retiree's realized artifacts into reserved namespaces, each with a header note. Use today's date for `YYYY-MM-DD`.

1. **Per-component state dir.** Move `versions/[component]/` → **`versions/retired/[component]-YYYY-MM-DD/`** — a reserved sub-namespace, **not** a `versions/[component]-retired/` sibling (the sibling shape risks a `versions/*/` glob mis-reading it as a live component). Add a header note to the moved dir's `workflow-state.md` (or a `RETIRED.md` marker in the moved dir):
   ```markdown
   > **Retired**: [component] removed from Architecture §6 at round-[N]-promote; retired YYYY-MM-DD.
   > Archived by the retire orchestrator (non-destructive — reversible). Not a live component.
   ```
2. **Published spec (only if it reached Promote).** If `specs/[component].md` exists, move it to **`specs/archived/[component]-retired-YYYY-MM-DD.md`** (outside the `specs/*.md` live namespace) and prepend a header note:
   ```markdown
   > **Retired**: [component] removed from Architecture §6 at round-[N]-promote; retired YYYY-MM-DD.
   > Archived from specs/[component].md (non-destructive — reversible). Not a live spec.
   ```
   If `specs/[component].md` does not exist (the component never promoted), skip this — there is nothing to archive.

**Never delete.** Every artifact is moved and header-noted so retirement is reversible.

### Step 3 — Update the stage index

Edit `versions/workflow-state.md`:

1. **Remove** the component's row from the `## Component Specs` table. (So the instantiated set no longer contains it → the detector reports no delta for it → no re-flag. Removal, not a `RETIRED`-in-place status, is deliberate: a `RETIRED` row would re-flag every detector run and permanently HALT the all-COMPLETE freeze gate; removal touches neither.)
2. **Add a status-less `## Retired Components` audit row.** If the `## Retired Components` section does not exist yet, create it (schema below). The row is **status-less by design** so no status-keyed reader (the detector's instantiated-set read, the coherence status count, the all-COMPLETE freeze gate) mistakes it for a live component:
   ```markdown
   ## Retired Components

   Audit record of components removed from the stage after Architecture §6 dropped them. **Status-less by design** — a retired component is NOT in the live component set (the `## Component Specs` table above); no status-keyed reader (decomposition-membership detector, coherence status count, all-COMPLETE freeze gate) counts these rows. Archives are reversible (see archive locations).

   | Component | Retired | Reason | Archived (versions) | Archived (spec) | Rename hint |
   |-----------|---------|--------|---------------------|-----------------|-------------|
   | [component] | YYYY-MM-DD | ORPHANED — removed from Architecture §6 at round-[N]-promote | versions/retired/[component]-YYYY-MM-DD/ | specs/archived/[component]-retired-YYYY-MM-DD.md (or "—" if never promoted) | [renamed-from/renamed-to hint if the human confirmed a rename, else "—"] |
   ```
3. **Add a stage history entry** to `## History`:
   ```markdown
   - YYYY-MM-DD: Retired ORPHANED component [component] (removed from §6 at round-[N]-promote). Swept clean (no live inbound reference / §8 role). Archived to versions/retired/ + specs/archived/. Re-run coherence sign-off to regenerate the Frozen Components manifest.
   ```

### Step 4 — Direct re-coherence

Retirement itself does **not** freeze. Instruct the human to **re-run the coherence sign-off (freeze)**:
- A **freeze run** (every remaining component at `COMPLETE`, no blockers) regenerates the `## Frozen Components` manifest without the retiree (`coherence/orchestrator.md:306,317`) — this is what removes the retiree from the 06 gate.
- A **checkpoint run** (some components not yet `COMPLETE`) does not regenerate the manifest — harmless (mid-stage there is no manifest yet).

The real downstream fence is this re-coherence, not the 06 manifest (06 derives its order from current §6 and ignores a non-§6 orphan regardless). The coherence Phase 1 freshness read will also flag every component STALE after the orphaning 04 re-promote and block the re-freeze until they re-review — that is expected.

---

## Output — Retirement Report

Write a retirement report to `versions/retired/[date]-[component]-retirement.md`, and present its summary to the human. Never a silent mutation.

```markdown
# Component Retirement Report — [component]

**Date**: YYYY-MM-DD
**Component**: [component]
**Reason**: ORPHANED — removed from Architecture §6 at round-[N]-promote
**Outcome**: [RETIRED | HALTED (live inbound reference) | HALTED (§8 role escalated) | HALTED (possible rename) | NO-OP (not ORPHANED)]

## Preconditions
- 05 initialized + active row: [pass/fail]
- Genuinely ORPHANED vs current §6: [pass/fail]
- Possible-rename guard (coexisting MISSING): [clear | N MISSING — HALTED]

## Blocking Sweep
### (a) Inbound sibling references (whole-spec name scan)
| Sibling | Locus | Reference |
|---------|-------|-----------|
| [none — clean] or [sibling] | [§/table/prose/deps] | [line] |

### (b) §8 producer/consumer role
| Contract | Retiree role | Disposition |
|----------|--------------|-------------|
| [none — clean] or [contract] | Producer/Consumer | Escalated CROSS-BOUNDARY-UPSTREAM to 04 pending-issues |

## Archived Artifacts (only on RETIRED)
| Artifact | From | To |
|----------|------|----|
| Per-component state | versions/[component]/ | versions/retired/[component]-YYYY-MM-DD/ |
| Published spec | specs/[component].md | specs/archived/[component]-retired-YYYY-MM-DD.md (or "not promoted — n/a") |

## Stage Index
- `## Component Specs` row removed: [yes/no]
- `## Retired Components` audit row added: [yes/no]
- History entry added: [yes/no]

## Next Step
Re-run the coherence sign-off (freeze) so `## Frozen Components` regenerates without [component]:
  {{AGENTS_PATH}}/05-components/coherence/orchestrator.md
```

---

## Error Handling

| Condition | Action |
|-----------|--------|
| 05 uninitialized or component not a `## Component Specs` row | Error: "Cannot retire — [component] is not an active component in the stage index." No-op. |
| Component still in current §6 (not ORPHANED) | Error: "[component] is still required by current Architecture §6 — not ORPHANED. Nothing to retire." No-op. |
| ≥1 MISSING coexists (possible rename) | HALT: "Adjudicate retire-vs-rename first (§6 has no rename-stable id; a rename shows as missing+orphaned)." No archive, no index edit. |
| Live inbound sibling reference found (sweep a) | HALT: report the dependents. "Re-Review these siblings against the new §6 (their re-align drops the reference), then re-trigger retire." No archive, no index edit. |
| Live §8 producer/consumer role found (sweep b) | HALT + escalate a `CROSS-BOUNDARY-UPSTREAM` entry to 04 pending-issues. "04 must drop/re-assign the entry and re-freeze before retirement proceeds." No archive, no index edit. |
| Human aborts mid-flow | Save progress, report partial completion. Archives are reversible; the index edit is the last mutation (do not remove the row until archive succeeded). |

---

## Agents/Orchestrators Referenced

| Agent | Purpose | Invocation |
|-------|---------|------------|
| Decomposition-Membership Detector | Its stateless current-§6 diff logic is **reused inline** here to re-confirm ORPHANED + compute the rename-guard MISSING set (not spawned) | Preconditions 2/3 |
| Cross-Boundary Routing Reconciler | Covers only the routing-claim subclass of inbound references — a **contributing input** at most, never the sweep (Step 1 is purpose-built) | — |
| Coherence Review Orchestrator | The freeze this retirement feeds — the human re-runs it (Step 4) to regenerate the Frozen Components manifest | Step 4 (human-triggered) |

**Note:** The blocking sweep (Step 1) is handled **directly** by this orchestrator rather than delegated — the logic is a straightforward context-dependent full-text scan, matching how coherence handles its pending-issue and consistency logic inline while spawning only reused agents.

---

## Tool Restrictions

- Use **Read**, **Write**, **Edit**, **Glob**, and **Grep** tools
- Use **Bash** only for `mkdir -p` (create the reserved `versions/retired/` and `specs/archived/` namespaces) and `mv` (archive-by-rename — relocate the retiree's realized artifacts out of the live namespace into the reserved one). The `mv` is load-bearing: the artifact must *leave* the live `specs/*.md` / `versions/*/` namespace, so a `cp` that leaves the original in place is not sufficient.
- Do NOT use `rm` or delete any artifact — every archive is a reversible move, never a deletion.
- Do NOT use Bash for any other shell commands; do NOT use git.
- Do NOT use WebFetch or WebSearch.
