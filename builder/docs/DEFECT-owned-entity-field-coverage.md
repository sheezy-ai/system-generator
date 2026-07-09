# Defect: Component coverage check misses PRD-delegated owned-entity fields

**Status**: RESOLVED — 2026-07-09 (builder fix applied; commit `30e3ab0`. See Resolution below.)
**Found**: 2026-07-09, during `participants` component-spec creation (round 2), at the Step 10 human review.
**Affects**: system-generator/builder — component-create **coverage verification** (`create/requirements-extractor.md`, `create/coverage-checker.md`, `create/orchestrator.md` Step 9b). Does **not** affect the correctness of the coverage machinery for architecture-assigned requirements — the blind spot is specifically **field-level coverage of entities a component owns**.

---

## Summary

The component-create coverage check (Step 9b) verifies the draft against a requirements checklist that the Requirements Extractor builds **only from the Architecture** (plus Foundations and the cross-cutting registry). But the Architecture **systematically delegates entity *field* specifications downward** — it names the entities a component owns and then defers their field lists to the PRD conceptual data model and the component spec ("field specifications: see PRD"; "Additional fields may be specified at the component-spec level"; §2 "the data model includes **fields defined in the PRD data model**").

So for an entity a component **owns**, the authoritative field list lives in **PRD §5**, which the coverage check never reads. A component spec can therefore **silently drop PRD-mandated fields of its own entity** and still pass coverage — the requirement vanishes at the architecture boundary and no downstream check looks back at the PRD.

## What's broken (for contrast with what works)

Architecture-assigned requirements — responsibilities, data ownership (entity *presence*), interfaces, integrations, CTR data contracts — are checked well. The gap is narrow and specific: **field-level completeness of owned entities**, where the Architecture's own delegation makes the PRD §5 conceptual model the authoritative source the coverage check does not consult.

## Evidence (how it surfaced)

`participants` round-2 modelled **Feedback Entry** as an opaque free-text `body` + timestamp ("no content-category taxonomy") and **Participant** as identity + track + contact. That dropped the PRD §5 fields:

- **Participant** (PRD §5): relationship proximity, discovery-behaviour baseline, consent acknowledgement, cohort marker.
- **Feedback Entry** (PRD §5): success dimension(s), signal type, period marker, transition marker, cohort marker — "tagged by participant relationship proximity for bias-aware interpretation".

These are **load-bearing for the Phase 1b go/no-go assessment** — the whole reason the component exists (PRD §2 "segment signals by relationship proximity", "feedback by dimension and proximity", "signal type breakdown"; PRD §7 Feedback Capture records dimension/signal-type/proximity/cohort; the Decision Point Assessment consumes them). The draft's CTR-015 decision-point read ("verbatim body, no taxonomy") **structurally cannot** produce those segmented decision products.

The Coverage Checker returned **29/29 COVERED / PASS** because it checked only against the Architecture (which delegates the fields down). The omission was caught only by the **stage-appropriateness verifier**, explicitly out of its scope — i.e. by luck, not by the check designed to catch omissions.

## Root cause

An **architecture-only** coverage check has a structural blind spot: a requirement dropped at the architecture boundary is invisible to every downstream check — and this is exactly where the Architecture *intends* the PRD conceptual model + component spec to carry the detail, so it is a systematic (not incidental) gap.

## Resolution (2026-07-09, commit `30e3ab0`)

A **scoped** extension — owned-entity field coverage only, **not** a full draft-vs-PRD re-audit at the component stage:

- **`requirements-extractor.md`** — new **Step 1b**: for each entity the component is *authoritative for* (from Architecture §6 data-ownership), extract its **PRD §5 field list** (owned entities only), each tagged Architecture **Carried / Refined / Silent**. New "Owned-Entity Data-Model Fields" checklist category; constraint reworded from "architecture-driven" to "**architecture-primary, with one scoped PRD exception**".
- **`coverage-checker.md`** — new **CONFIRM-INTENTIONAL** status and owned-entity-field rule: field absent + Silent/Refined ⇒ CONFIRM-INTENTIONAL (surface a deliberate-deferral confirmation, not a silent pass and not a false hard gap); absent + Carried ⇒ GAP; new **CONFIRM_NEEDED** overall verdict.
- **`orchestrator.md` Step 9b** — passes the **PRD** to the extractor and injects `[TODO: Coverage confirm — …]` markers into the draft so CONFIRM-INTENTIONAL items reach the human in the Step 10 gap loop.

Deliberately scoped to **owned-entity fields** to keep it architecture-primary and avoid false positives on other components' entities or on the Architecture's legitimate scoping decisions (which become human-confirmable, not auto-failed).

## Complement (noted, not fixed — for the owner)

The root cause is also **upstream**: the Architecture should issue *checkable* field delegations ("participants MUST model PRD §5 Participant/Feedback fields") rather than a vague gesture, and the architecture-stage PRD-alignment check should ensure every PRD entity field is either carried down or explicitly deferred with rationale. Fixing the component-stage check closes the immediate blind spot; hardening the architecture-stage handoff would close it at the source.

## Scope note

Builder-only fix; affects **future** Step 9b runs. It does **not** retroactively surface the omission in the in-flight `participants` round — that PRD §5 gap must be resolved manually this round (tracked as the pending "GAP-010" decision in the participants workflow-state).
