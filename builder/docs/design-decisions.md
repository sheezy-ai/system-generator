# System Builder Design Decisions

Design decisions for the system-builder framework. For how the system works, see `overview.md`, `workflow-create.md`, and `workflow-review.md`.

---

### DEC-001: Simplified Create Workflow (Superseded)

**Original decision:** Create workflow is simplified to: Setup → Generator → Human augments. No experts, consolidator, or author in Create. Review workflow handles all expert review.

**Original rationale:** "Gaps are just issues" - review experts can identify both missing decisions (gaps) and problems with existing decisions (issues). Separate Create experts duplicated Review expert domains. Simpler flow: Create produces a draft, human augments it, Review refines it.

**Superseded by stage-specific create workflows:**
- **Blueprint**: Explore phase (dimension identification → parallel explorers → enrichment review) + Decision Orchestrator + iterative rounds
- **PRD**: Explore phase (capability identification → parallel explorers → enrichment review) + Enrichment Applicator for round 2+
- **Foundations**: Assess step (technology assessment with inline human preferences) + structured gap analysis pipeline
- **Architecture**: Full explore phase + Enrichment Applicator + independent coverage verification + structured gap analysis pipeline
- **Components**: Independent coverage verification + structured gap analysis pipeline

**Rationale for supersession:** The original simplified flow produced too many gaps requiring blind proposals. Pre-generation exploration and assessment surface trade-offs and collect human direction before generation, producing better first drafts. Independent coverage verification catches silent omissions. The original principle ("gaps are just issues") remains true for the Review workflow.

---

### DEC-003: No Tiered Review Options

**Decision:** Framework encodes review depth per document type. No "light" vs "full" options.

**Rationale:** Human's role is to review content, not configure process. Different document types have appropriate depth designed in.

---

### DEC-004: Stage-Appropriate Expert Panels

**Decision:** Document-type-specific expert panels rather than one-size-fits-all:
- Architecture Overview: 5 system-level experts
- Component Specs: 7 implementation experts (Build + Ops)
- PRD: Added Compliance/Legal

**Rationale:** Right experts at right abstraction level. Architecture is decomposition; Specs are implementation.

---

### DEC-009: Universal Manual Agents (Technical Writer, Skeptic)

**Decision:** Technical Writer and Skeptic are universal agents, manually triggered rather than part of standard workflow.

**Rationale:**
- Not always needed - flexibility over rigidity
- Run after review rounds complete to avoid reviewing content that might change
- Keeps standard workflow lean

---

### DEC-010: Expert Issue/Gap Limits

**Decision:** Maximum 12 gaps/issues per expert. Primary control is scope discipline in prompts; cap is backstop.

**Rationale:** With 4-5 experts, worst case is 48-60 items per round. Multiple rounds catch overflow; experts prioritise HIGH severity first. Original cap of 7 was too restrictive — experts were forced to drop valid issues to stay under the limit, which delayed their discovery to later rounds.

**Supersedes:** Original cap of 7 per expert.

---

### DEC-011: Blueprint Expert Panel

**Decision:** Four review experts: Strategist, Commercial, Customer Advocate, Operator.

**Rationale:** Blueprint needs four lenses (strategy, commercial, user, operations). Review experts identify both missing information and problems with existing content.

---

### DEC-024: Three-Way Structural Separation

**Decision:** Separate directories:
- `agents/` - built agent prompts
- `system/` - project-specific output
- `guides/` - reference documentation

**Rationale:** Clear separation of framework vs output. Agents read guides and write to system.

---

### DEC-026: Scope Filter Agent

**Decision:** Dedicated Scope Filter after Consolidator, before human review. Filters wrong-level content.

**Rationale:** Single responsibility per agent. Human only sees appropriate-level content. Conservative filtering — when uncertain on topic, keep. When uncertain on depth, flag (see DEC-075).

---

### DEC-033: Hardcode vs Reference

**Decision:** Hardcode concrete content (themes, categories, IDs). Reference guides for judgment calls (abstraction level).

**Rationale:** Agent performance is higher with direct prompts. Concrete lists are stable; judgment calls need authoritative reference.

---

### DEC-034: Prompts Are Purely Functional

**Decision:** Remove non-functional content from prompts. Documentation belongs in docs/.

**Rationale:** Every prompt section should help the agent do its job. Invocation blocks don't affect agent behavior.

---

### DEC-035: Alignment Verification

**Decision:** Alignment Verification runs in Review workflow after Author. Skipped for Blueprint (source is informal).

**Rationale:** Catching contradictions early is cheaper than catching them later. Blueprint's source is informal; all others have formal sources.

---

### DEC-037: Foundations Expert Panel

**Decision:** Four technical review experts: Infrastructure Architect, Data Engineer, Security Engineer, Platform Engineer.

**Rationale:**
- Foundations is entirely technical - needs technical experts
- Review experts identify both missing decisions and problems with existing decisions
- Security decisions need validation before downstream stages depend on them

---

### DEC-039: Architecture Expert Panel

**Decision:** Five review experts: Technical Reviewer, System Architect, Data Architect, Integration Architect, FinOps.

**Rationale:** Architecture needs system-level perspectives. FinOps catches cost implications. Security validated in Foundations; no dedicated security expert at Architecture level.

---

### DEC-040: Component Specs Expert Panel

**Decision:** Seven review experts in two stages:
- Build (4): Technical Lead, API Designer, Data Modeller, Integration Reviewer
- Ops (3): Security Reviewer, Test Engineer, Operations Reviewer

**Rationale:** Component specs need implementation-level review. Split into Build (can it be built?) and Ops (can it be run?) stages for focused review.

---

### DEC-043: Tasks Verification Pipeline

**Decision:** Multi-stage verification: Generate → Spec-Item Extraction + Coverage Check + Coherence Check → Consolidation → Cross-Component Consistency Check. No expert panels.

**Rationale:** Tasks decompose already-reviewed specs. Quality comes from mechanical verification (coverage against extracted items, coherence of internal structure, cross-component consistency) rather than subjective expert review. Human approval sufficient for judgment calls.

**Supersedes:** Previous simplified workflow (Generate → Coverage Check → Human Review).

---

### DEC-044: Dual Task Generators

**Decision:** Separate generators for infrastructure tasks and component tasks.

**Rationale:** Different sources, grouping, scope, and dependencies. Single generator would need complex conditional logic.

---

### DEC-046: Pending Issues Mechanism

**Decision:** Alignment Verifier identifies upstream issues. SHOWSTOPPER issues trigger HALT. Upstream Review workflow incorporates pending issues via Consolidator.

**Rationale:** Downstream work can reveal upstream problems. Leverages existing Review machinery for resolution.

---

### DEC-048: Maturity Calibration

**Decision:** Stage-specific maturity guides. Experts read their stage's guide to calibrate for MVP/Prod/Enterprise.

**Rationale:** Without calibration, experts raise enterprise concerns on MVP projects. Blueprint defines target; downstream calibrates.

---

### DEC-049: Guide Usage Pattern

**Decision:**
- Generator/Author/Scope Filter: Read stage guides
- Experts: No stage guides (guidance in prompt), read maturity guides only

**Rationale:** Stage guides are about structure. Experts need domain-specific abstraction guidance, which is in their prompts.

---

### DEC-050: Conventions-First Build with Human Checkpoint

**Decision:** Build stage generates a `build-conventions.md` from design documents (Foundations, Architecture, specs, task files) and requires human approval before any code is written. This is the only human checkpoint in the entire stage — all subsequent build processing is fully automated.

**Rationale:** Code generation requires consistent standards (directory layout, import patterns, test frameworks, commands) that can't be derived mechanically with full confidence. Human approval catches bad defaults before they propagate across every component. Once conventions are locked, the build pipeline can run autonomously because every decision point references the approved conventions.

---

### DEC-051: Broad Bash Access for Verifier

**Decision:** The verifier agent has broad Bash access (for running lint, type checks, and tests) — the only agent in the system with this level of shell access. All other agents are restricted to specific commands (`mkdir`, package installation) or have no Bash access at all. The verifier runs in stage 09 (build verification), not stage 08 (build). Stage 08 produces and reviews code against specs; stage 09 executes it.

**Rationale:** Verification requires running real test suites, linters, and type checkers. These are arbitrary shell commands determined by the project's conventions, not a fixed set the framework can enumerate. The security boundary is compensated by making the verifier read-only on code files — it can only write its verify report. It observes and reports; it cannot modify what it's checking.

---

### DEC-052: Code Output to Project Source Tree

**Decision:** Build is the first stage that writes outside `system-design/`. Stages 01-07 produce documentation and conventions within the design folder; stage 08 produces code in the actual project source tree.

**Rationale:** The output of build is working code — application modules, tests, IaC configs — that belongs in the project's source structure, not in a documentation folder. The build conventions document defines where code lives; builders write to those locations. Version artifacts (build logs, verify reports, review reports) remain in `system-design/08-build/versions/`.

---

### DEC-053: Single Reviewer, No Expert Panel

**Decision:** Build review uses a single reviewer agent assessing code against task acceptance criteria and conventions compliance. No expert panel, no consolidation step.

**Rationale:** Task acceptance criteria (from stage 06) are the quality gate, derived from already-reviewed component specs. The reviewer checks whether code satisfies those criteria and follows approved conventions — both are concrete, checkable standards rather than judgment calls requiring domain expertise. Execution-based verification (tests, lint, types) is a separate concern handled in stage 09. This mirrors DEC-043's rationale: upstream review means downstream quality gates can be mechanical.

---

### DEC-054: Independent Item Extraction

**Decision:** A dedicated spec-item extractor runs before the coverage checker, producing a definitive list of implementable items from source documents. The coverage checker validates against this list rather than self-enumerating items.

**Rationale:** When an LLM agent both enumerates what should exist and checks whether it does, it tends to align the two — finding what it expects rather than what's actually specified. Separating extraction from checking makes completeness mechanical: the extractor reads source documents once and produces a numbered list; the checker matches tasks against that list item by item. Neither agent needs to exercise judgment about what the other should have found. This pattern (used in both the tasks pipeline and the conventions pipeline as "source-item extraction") converts a stochastic completeness check into a deterministic one.

---

### DEC-055: Fix-Round Contract (Copy + Edit, Not Regenerate)

**Decision:** Round 1 generates from scratch (Write). Round 2+ copies the previous output and applies only the corrections identified in the review report (Edit). Generators never regenerate entire files after round 1.

**Rationale:** Full regeneration is stochastic — an LLM asked to "regenerate with these fixes" will produce a different file each time, potentially introducing new issues while fixing old ones. This creates an unstable loop where rounds don't converge. Targeted editing (copy previous output, apply specific corrections) preserves working content and confines changes to what was actually flagged. The review-then-edit cycle converges because each round's delta is bounded by the review findings. Applied system-wide: task generators, conventions generators, build agents, and cross-reference fix rounds.

---

### DEC-056: Copy-Edit-Validate-Promote Pattern

**Decision:** Cross-reference and cross-component fixes never modify promoted (live) artifacts directly. Instead: (1) copy the promoted file to a version directory, (2) apply fixes to the copy, (3) re-validate the copy with the same checks that approved the original, (4) promote the validated copy back to the live location. Original artifacts are untouched until a validated replacement is ready.

**Rationale:** Cross-reference fixes touch multiple files simultaneously to resolve inter-file inconsistencies. If fixes are applied directly to live artifacts and validation fails partway through, the system is left in a partially-fixed state — some files updated, others not, consistency worse than before. Working on copies means a failed fix attempt leaves everything unchanged. The version directories also provide a complete audit trail: original → review report → fixed copy → re-validation report → promotion. This trail is essential for diagnosing convergence failures (when fixes introduce regressions) and for human intervention when automated rounds are exhausted.

---

### DEC-057: Cross-Component Spec-Fidelity Check

**Decision:** After all per-component build pipelines complete, a cross-component spec-fidelity checker validates that built code correctly implements the integration contracts defined in component specs. The checker uses reviewed specs as ground truth — not other components' code. Fixes are applied directly to code files in the project source tree (not copy-edit-validate-promote).

**Rationale:** Per-component build pipelines cannot detect cross-component issues — Component A's builder doesn't read Component B's code. Two components can pass individual review but break when integrated (mismatched API contracts, wrong field names, missing imports). The checker reads the reviewed specs (which define what each integration point should look like) and the built code (which implements it), verifying both sides match the spec. Direct Edit (rather than copy-edit-validate-promote) is appropriate because code files are scattered across the project source tree, making bulk copying impractical. The fixes are mechanical and bounded by the checker report; the re-run of the checker serves as validation; and a fix log provides the audit trail.

---

### DEC-058: Staged Verification (Build vs Execute)

**Decision:** Stage 08 produces code and validates it against specs and task acceptance criteria — no code execution. Stage 09 (build verification) handles execution: running tests, linters, type checkers, and integration tests. The build reviewer assesses code against acceptance criteria and conventions without a verification report.

**Rationale:** Tests written by the same builder that wrote the application code are not an independent check — they validate internal consistency ("does the code agree with itself") not correctness ("does the code match the spec"). Running LLM-generated tests on LLM-generated code before any spec-based validation conflates two distinct quality gates. Stage 08 answers "does the code implement what was specified?" Stage 09 answers "does the code actually work?" Separating these also means stage 08 can operate without the project's runtime environment installed.

---

### DEC-059: Task-Level Tiering in Build Pipeline

**Decision:** The pipeline runner computes task dependency tiers within each component and processes each tier independently through the build → review → route loop. Tier task files (subsets of the full task file) are written to tier directories. Max 3 rounds per tier.

**Rationale:** Large components (30-40 tasks) overwhelm the builder's context window when processed as a single unit. Task dependency tiers naturally partition tasks into groups of 2-6, each containing tasks whose internal dependencies are all satisfied by prior tiers. This reuses the same tier grouping algorithm the coordinator uses for components, applied one level down. The tier task file approach preserves the file-first principle and requires no changes to builder or reviewer agents — they read a task file regardless of whether it contains 3 or 30 tasks.

---

### DEC-060: Two-Phase Build Verification

**Decision:** Stage 09 splits verification into two sequential phases: Phase 1 (mechanical — lint, types, imports) with an automated fix loop, and Phase 2 (unit test execution) with a human-in-the-loop proposal workflow. Phase 1 must pass before Phase 2 begins.

**Rationale:** Lint errors and type errors are unambiguous — "lint error on line 45" means fix line 45. Test failures are ambiguous — a failing test could indicate a bug in the code or a bug in the test (both were LLM-generated). Automated fixing is safe for the first category but dangerous for the second, where the "fix" might silence a legitimate test rather than fix the real bug. Separating phases lets Phase 1 run fully automated while Phase 2 preserves human judgment over what gets changed. Integration and E2E testing are deferred to later stages after human/DevOps infrastructure setup.

---

### DEC-061: Project-Wide Verification

**Decision:** Stage 09 runs verification project-wide, not per-component. A single verifier runs lint/type/test commands against the entire project.

**Rationale:** Build tooling commands (`pytest`, `ruff check src/`, `mypy src/`) are project-scoped, not component-scoped. Running them per-component would either require splitting the project (impractical) or running the same project-wide command once per component (wasteful and redundant). A single run captures all issues. The verify report attributes each issue to a specific file path, preserving traceability.

---

### DEC-062: Proposal-Based Test Fix Workflow

**Decision:** When Phase 2 test execution fails, a proposal agent reads failures and code, writes a proposal document suggesting fixes for each failure, and the human decides what to apply. The proposal agent is read-only (writes only the proposal).

**Rationale:** Test failures from LLM-generated code are the highest-ambiguity errors in the system. The failing test might be wrong, the code might be wrong, or the spec might be wrong. An automated fixer would make a judgment call that should be the human's. The proposal document gives the human all the information needed to decide. Designed to become more automatable as confidence in test quality increases.

---

### DEC-063: Runbook-Based Provisioning

**Decision:** Stage 10 generates a structured provisioning runbook from infrastructure tasks and built IaC. Each runbook item includes an executable command, required inputs, verification criteria, and a recommended execution mode (auto/semi/manual). The human triages items before execution. The provisioning agent executes approved items.

**Rationale:** Provisioning is the first stage with real-world side effects — cloud resources that cost money and can't be undone with `git checkout`. Full automation is unsafe without human judgment about what already exists, what permissions are available, and what the environment looks like. Full manual execution wastes the IaC that was carefully generated. The runbook model gives the human control over triage while preserving automatability for items where the prerequisites are met.

---

### DEC-064: Provisioning Agent with Broad Bash Access

**Decision:** The provisioning agent has broad Bash access for running Terraform, scripts, and infrastructure commands — the second agent in the system with this level of shell access (after the stage 09 verifier).

**Rationale:** Provisioning requires running arbitrary infrastructure commands (terraform apply, gcloud, docker, etc.) determined by the project's conventions. The security boundary is compensated by the human triage loop — the agent only executes what the human explicitly approved. It writes execution logs but does not decide what to run.

---

### DEC-065: System-Builder Exit Point

**Decision:** Stage 11 (Packaging) produces a standalone deliverable: repo with code, IaC, runbook, and developer-facing documentation. Stage 12 (Operations Readiness) then extracts maintenance and operations artefacts (component map, contracts, risk profile, traceability, SLOs, monitoring definitions, deployment topology, runbooks, security posture) for consumption by System-Maintainer and System-Operator. After stage 12, the system-builder's role is complete.

**Rationale:** The system-builder's competency is "read specs, produce artifacts, verify quality." Stage 12 extends this to operational artefacts — extracting and restructuring information already present in design docs into formats that maintenance and operations agents can consume directly. Ongoing operations — deployment, monitoring, incident response — are handled by System-Operator; ongoing maintenance — bug fixes, features, evolution — are handled by System-Maintainer. Both consume Stage 12's output as their source of truth.

---

### DEC-066: Real-World Side Effects Boundary

**Decision:** Stages 01-09 produce files only (documents and code). Stage 10 is the first and only stage that creates external resources. This boundary is explicit: stages before 10 can be re-run freely; stage 10 requires human judgment about what exists and what to create.

**Rationale:** The file-only stages are inherently safe — re-running regenerates files. Stage 10's side effects (cloud resources, IAM changes, secret creation) are irreversible in ways that file operations are not. Making this boundary explicit prevents accidental resource creation and ensures the human is always in the loop for real-world changes.

---

### DEC-067: Specification Principles (Contracts, Not Code)

**Decision:** Component specs define contracts and constraints, not implementation. Three Scope Principles (renamed from "Specification Principles" for cross-stage consistency): (1) express interfaces as tables and behaviour as prose, not Python/SQL code blocks; (2) reference Foundations conventions rather than restating them; (3) no Implementation Reference sections. Enforced at generation (generator constraints and quality checks) and review (Technical Lead Abstraction Level scope, over-specification detection across all build and ops experts).

**Rationale:** 11/11 component specs contained implementation code (Python dataclasses, function signatures, ORM calls), 6/11 had §14 Implementation Reference sections (64-486 lines of Python), and 10/11 restated Foundations conventions verbatim. This bloated specs, inflated task counts, and blurred the boundary between design and code. Layered defence: guide establishes principles, generator constrains output, reviewers catch what leaks through.

---

### DEC-068: Tasks Scope What, Conventions Govern How

**Decision:** Tasks define the features, endpoints, and functionality to build. Build conventions (from Stage 07) define the implementation patterns — error handling, logging, API formats, module structure. The builder constraint "implement from tasks, nothing more" applies to scope (no extra features), not to implementation quality (conventions always apply). The reviewer enforces both: acceptance criteria (from tasks) and conventions compliance.

**Rationale:** With lighter specs (DEC-067), Foundations-level requirements flow through the conventions document rather than through task files. The builder's previous constraint ("nothing more") was ambiguous — it could be read as "skip conventions patterns if no task covers them." Clarifying the what/how split ensures Foundations requirements are implemented via conventions even when not restated in specs or extracted as tasks.

---

### DEC-069: Foundations Scope Principles

**Decision:** Foundations follows two scope principles enforced across the generator and all four review experts: (1) **Selections, not configuration** — Foundations names technologies and defines approaches; specific values (timeouts, retention periods, instance counts, coverage targets, header values) belong in Architecture Overview or Component Specs. (2) **Cross-cutting, not component-specific** — every Foundations decision must apply to multiple components; decisions affecting only one component belong in that component's spec. Review experts are instructed to flag scope violations (content at the wrong level) in addition to their existing domain-specific reviews.

**Rationale:** Review of the experiential-design Foundations output revealed systematic scope creep: session timeout values (§3), exact security header values and provider-specific OAuth configuration (§8), log levels, retention periods, metrics definitions and alerting thresholds (§7), instance counts (§2), and per-agent timeout values (§6) — all items that the guide's per-section "Level of detail" notes already said belong downstream. The root cause: experts were correctly scoped to ignore these areas ("NOT your focus"), but nobody was told to flag them. Content entered through review round resolutions and was never caught. Fix mirrors DEC-067's layered defence: guide establishes principles, generator constrains output, reviewers catch what leaks through.

---

### DEC-070: Architecture Scope Principles

**Decision:** Architecture Overview follows two scope principles enforced across the generator and four review experts: (1) **Structure, not implementation** — Architecture defines what components exist, their responsibilities, and how they relate; capability lists, algorithms, threshold values, database field names, entry point commands, SQL queries, and specific backoff values belong in Component Specs. Each component gets a one-sentence responsibility, not a feature list. (2) **Reference, don't restate** — reference Foundations for conventions (retry policies, secrets management, security headers) and note deferrals to Component Specs rather than pre-defining content. Three structural experts (System Architect, Data Architect, Integration Architect) have bidirectional "Respect Architecture Level" instructions: flag both missing structure AND excess implementation detail. Technical Reviewer flags Foundations restatement.

**Rationale:** Review of the experiential-design Architecture output (1136 lines) revealed systematic over-specification: 15-item capability lists instead of one-sentence responsibilities (§2), specific SQL queries and matching algorithm thresholds (§2), concrete gunicorn commands and Django settings paths (§5.1), specific backoff values and database flag names (§5.7, §5.8), restated Foundations retry policies and secrets lists (§7.3, §7.4), and per-pipeline-stage log field tables (§7.2). The root cause: experts' "Respect Architecture Level" bullets only said "don't flag missing detail" — they never said "flag excess detail." The generator's quality check ("No implementation details") was too generic to catch specific patterns. Same layered defence as DEC-067/DEC-069.

---

### DEC-071: Cross-Stage Pipeline Improvements

**Decision:** Four improvements cross-pollinated across stages: (1) Source-item review chain added to Conventions — extractor output is now reviewed and corrected by a 3-agent chain (extractor → reviewer → corrector) matching Tasks' existing pattern (DEC-054). (2) Citation self-verification added to Foundations, Architecture, and Components generators — a post-generation step that re-reads every cited source passage to confirm section numbers and quoted text, matching Conventions' existing pattern. (3) Context management guidance added to all expert-panel orchestrators (Foundations, Architecture, Components) — explicit instructions to keep orchestrator context lean by using Grep and `ls` rather than full reads, matching Tasks/Conventions coordinators. (4) Scope guidance naming standardised: Components renamed "Specification Principles" to "Scope Principles" (matching Foundations and Architecture), Tasks guide gained a new "Scope Principles" section (deriving from existing "What NOT to Include" content).

**Rationale:** Cross-stage review revealed good practices present in some stages but absent from others. Conventions' single-pass extraction was the only stage without a review step for its completeness baseline — the 3-agent chain catches over-extraction and missing items before they compound through review rounds. Citation errors (wrong §N references, misquoted values) were the most common generator failure mode in expert-panel stages — self-verification catches these before review. Context accumulation was documented only in newer stages. Scope guidance naming was inconsistent across all five guides.

---

### DEC-072: Spec/Decisions/Future Split for Foundations and Architecture

**Decision:** Added promoter agents to Foundations (stage 03) and Architecture (stage 04) that split reviewed documents into three files at exit, matching the Components (stage 05) pattern. Each stage now produces: (1) a clean current-scope spec (`foundations.md` / `architecture.md`) — consumed by downstream stages unchanged at the same path, (2) a decisions document (`decisions.md`) — design rationale, trade-offs, alternatives considered, and accepted limitations, and (3) a future planning document (`future.md`) — deferred items, open questions, and future considerations. The promoters are stage-specific agents (not a shared generic promoter) that key off existing content patterns in the reviewed documents: HTML rationale comments (`<!-- Rationale: ... -->`), Design Decisions sections (`DD-NNN:` blocks), Phase 1b+ content, and §11/§9 Open Questions. No changes to generators or authors — they already produce content with recognizable patterns the promoters can split on. No downstream consumer changes — clean specs stay at the same paths.

**Rationale:** Foundations and Architecture documents accumulated design rationale and future considerations inline, causing three problems: (1) downstream extraction stages (tasks, conventions) processed rationale and future content they didn't need, contributing to Phase 1b+ leakage and specification-level noise, (2) decision rationale was embedded in the spec rather than being a separate, referenceable document, making it harder to review settled decisions, and (3) re-running earlier stages required relitigating resolved decisions because there was no clean separation between the decisions themselves and their rationale. The Components stage already solved this with its spec-promoter (splitting into `specs/`, `decisions/`, `future/` subdirectories). Extending the pattern to Foundations and Architecture uses flat files in the stage root directory (since each stage has a single document, not multiple like Components).

---

### DEC-073: Optional Brief Input for Create Generators

**Decision:** Added an optional `brief.md` input to the create generators for Foundations (stage 03), Architecture (stage 04), and Components (stage 05). The brief can contain settled decisions, prescriptive technical direction, or a partial draft in any format (structured sections, flat decision list, or freeform prose). Generators incorporate brief content directly using prescriptive tone rather than marking it as gaps. Out-of-scope brief content is deferred downstream using existing deferred items mechanisms. Conflicts between the brief and upstream documents (PRD, Foundations, Architecture) are flagged as `[CLARIFY: ...]` gaps for human resolution. Components briefs are per-component only — cross-cutting decisions belong in Foundations/Architecture briefs.

**Rationale:** Generators previously derived all content from upstream documents and marked gaps where decisions were needed. This was inefficient for three scenarios: (1) re-running stages where decisions had already been made and validated — settled decisions were re-opened as gaps, requiring the human to re-fill them, (2) prescriptive projects where a company has standard technology choices or architectural patterns — these had to be entered manually after draft generation, and (3) partial work where someone had already written sections of a spec — the generator couldn't build on existing content. The brief input addresses all three by allowing prior work to inform generation. The naming "brief" (as in design brief) was chosen over "seed" or "prior-decisions" because it covers all use cases without implying a narrow format.

---

### DEC-074: Three-Phase Component Spec Review Orchestrator

**Decision:** Component Spec review (stage 05) splits its orchestrator into three separate phases managed by a router: pre-discussion (steps 1-5), discussion (single iteration per invocation), and post-discussion (steps 6-12 with action dispatch). Stages 01-04 use a single orchestrator with an inline discussion loop. The discussion phase is architecturally identical in both patterns — the split is not driven by discussion complexity.

**Rationale:** Component specs are the most detailed documents in the system, with the largest expert panels (7 experts across build and ops phases) and the most back-and-forth per review round. In a single orchestrator, the discussion loop accumulates context across iterations as facilitator responses and human replies are read, processed, and carried forward. This context growth caused reliability issues. Splitting into three phases gives each invocation a fresh context window: pre-discussion reads expert output and produces the issues file, discussion reads only the current state of the issues file for one iteration, post-discussion reads the resolved issues and applies changes. The router manages per-component lifecycle (which component, build vs ops, which round) and action dispatch for post-discussion (RUN, APPLY_DECISIONS, PROMOTE) without accumulating discussion context. Stages 01-04 get away with the inline loop because their documents are smaller and produce fewer issues per round.

---

### DEC-075: Three-Tier Depth Filtering

**Decision:** The Enrichment Scope Filter uses three tiers for depth handling: (1) **auto-defer** clear depth violations to downstream deferred-items (preserving the strategic insight), (2) **flag** borderline cases for informed human review, (3) **keep** content clearly at the right depth. The Operator review expert is widened to flag operational/procedural over-specification (not just implementation detail). Issue Analyst and Discussion Facilitator default to recommending deferral for depth-flagged content, delegating to human only when genuinely unsure.

**Rationale:** Blueprint review round 2 discovered substantial operational/procedural detail (specific process frameworks, metrics targets with diagnostic logic, decision procedures) that survived the entire creation pipeline and wasn't caught until expert review. Root cause analysis identified five filtering points, all permissive by design: the Enrichment Scope Filter's binary keep/drop with a keep bias, the Enrichment Author's deference to human acceptance, the Generator's assumption that enrichments are pre-vetted, the Operator expert's blind spot for operational (vs implementation) detail, and the Change Verifier's focus on current-round changes only. The fix adds information rather than gates: clear violations are auto-deferred (routing content, not dropping it), borderline cases surface the depth concern to the human explicitly, and downstream agents bias toward deferral for flagged content. This keeps false positives near zero while making it much harder for depth violations to silently accumulate.

**Supersedes:** DEC-026's "when uncertain, keep" — now: when uncertain on topic, keep; when uncertain on depth, flag.
