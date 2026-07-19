# Component Spec Creation: Promote Phase

Handles Step 12: Promote & Report. Dispatched by the router only when the human chooses "promote". Runs straight through and returns structured data to the router. **Router handles all human communication.**

---

## Orchestrator Boundaries

These are instructions for the router to follow directly. The router:
- Spawns worker agents using the Task tool (in FOREGROUND, not background)
- Passes file PATHS to agents, not file contents — agents read files themselves
- Does NOT read agent prompt files — agents read their own instructions
- Does NOT present to the human or STOP — it returns to the router, which owns all human communication

You FINALISE create to its draft path. You do **NOT** write `specs/[component-name].md` — the published spec is written only by the **Promote** workflow's spec-promoter (its sole writer). You UPDATE the stage index and per-component state. You DO NOT write spec content — agents do that.

**Paths, Path Resolution, and the State File Format are defined in the router** (`orchestrator-router.md`). Resolve `{round-dir}` from the current round.

---

## On Entry

Router dispatches with `Action: PROMOTE` after the human chose "promote". Resume at `Current Step` 12.

Mark "Step 11: Promote or Continue" complete `[x]` (if not already), add history entry "Promoting draft from round {N}". Creation Verification already ran this round at Step 10c, so promotion proceeds straight to Step 12.

## Step 12: Promote & Report

Runs when the human chose to promote (exit the create loop). Create does **not** write `specs/[component-name].md` — that published path is written only by the **Promote** workflow's spec-promoter (the sole writer). Create finalises to its draft, which the Review workflow reads as its Round 1 input.

1. **Determine final draft path** (current round): if `{round-dir}/03-updated-spec.md` exists (Author ran), use it; otherwise `{round-dir}/00-draft-spec.md`. This is the create-terminal draft.

2. **Verify the draft** — confirm the resolved final draft path exists.

3. **Update stage state** (`versions/workflow-state.md`): Component Specs table — update the component row status `NOT_STARTED` → `CREATED`, set Last Updated to today's date; add history entry "[date]: [component-name] creation workflow complete".

4. **Update per-component state**: Mark "Step 12" complete `[x]`, set status = COMPLETE, add history entry.

5. **Return** `PROMOTED { draft_path: [final draft path], total_rounds: [N], summary: {...} }`. (Router reports completion, including: concerns explored / enrichments accepted-rejected for the final round, whether exploration was skipped, final draft path, gap-resolution summary, and the next-steps pointer to the Review workflow.)

---

## Return to Router

| Return | When |
|--------|------|
| `PROMOTED { draft_path, total_rounds, summary }` | Create finalised — draft ready for Review (specs/ not written) |

Do NOT present anything to the human — the router handles all human communication.

---

<!-- INJECT: tool-restrictions -->
