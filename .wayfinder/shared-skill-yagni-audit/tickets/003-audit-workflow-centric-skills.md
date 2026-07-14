---
id: WF-003
type: research
status: resolved
blocked-by: [WF-002]
---

# Audit workflow-centric skills

## Question
Which content in the workflow-centric skills should be retained inline, moved behind Reference, consolidated, split, or removed under the confirmed contract?

## Why it matters
These skills are the most natural fit for a single ordered Workflow, but normalization could still erase branches, ownership rules, and completion gates.

## Completion evidence
Comparable audit records and one evidenced recommendation exist for: `bootstrap-specs`, `codebase-design`, `code-review`, `create-plan`, `diagnosing-bugs`, `gameplay-asset-imagegen`, `grill-me`, `improve-codebase-architecture`, `research`, `resolving-merge-conflicts`, `tdd`, `teach`, `wayfinder`, and `write-a-skill`. Every existing branch, guardrail, output contract, and relevant spec obligation is accounted for.

## Resolution
Audit basis: the contract in `.wayfinder/shared-skill-yagni-audit/tickets/001-define-four-section-yagni-contract.md`, record format and rules in `.wayfinder/shared-skill-yagni-audit/tickets/002-define-audit-evidence-and-classification.md`, repository obligations in `specs/ai-agent-config.md`, terminology in `specs/UBIQUITOUS_LANGUAGE.md`, provenance in `THIRD_PARTY_NOTICES.md`, and Pi progressive-disclosure guidance in its installed `docs/skills.md`. Baselines use `wc` line/word semantics; headings exclude frontmatter and fences.

### bootstrap-specs
- Profile / disclosure: Routed workflow; progressively disclosed
- Authorities: Frontmatter triggers new-project, onboarding, and spec-suite initialization with greenfield/brownfield routing; generic shared-skill contract in `specs/ai-agent-config.md`; spec conventions in `specs/SPEC-OF-SPECS.md`; locally introduced at commit `e66ec24`; supporting files `shared/skills/bootstrap-specs/REFERENCE.md` and the currently unlinked `shared/skills/bootstrap-specs/EXAMPLES.md`.
- Baseline: 86 lines; 828 words; 7 level-two headings (`Quick start`, `Two modes`, `Process`, `Key conventions`, `Re-running`, `Relationship to other skills`, `Advanced features`); 2 Markdown references, both to `REFERENCE.md`.
- Behavior ledger:
  - Language: Greenfield, brownfield, spec suite, skeleton spec, meta-file, reading order, and dependency graph are execution-relevant. **Human-confirmation candidates:** `Greenfield`, `Brownfield`, `skeleton spec`, and `meta-file`, including the exact source-code-existence test and overwrite boundary.
  - Workflow/routing: Detect existing source, ask the user to confirm greenfield versus brownfield, conduct eight questions one at a time with follow-ups, propose systems using domain heuristics, surface term collisions, detect user-facing surfaces, confirm dependency graph and reading order, then wait for confirmation. Greenfield generates the meta-files, parameters, optional design language, system skeletons, and progress tracker; brownfield generates meta-files plus an extraction `PLAN.md` rather than system specs. Show the file list and graph, allow corrections, and preserve authored system specs on reruns.
  - Activities: None; interview questions and generation are ordered main-path behavior.
  - Inline contracts: No implementation code in specs; use prescriptive language, pseudocode/schema/decision tables; every constant needs rationale; test ids follow `TS-{PREFIX}-{NUMBER}`; never overwrite authored individual specs; user confirmation gates generation.
  - Reference: `REFERENCE.md` earns conditional loading for generated schemas and templates. `EXAMPLES.md` contains three substantial worked examples but has no pointer from `SKILL.md` or `REFERENCE.md`.
- YAGNI findings: `Quick start` restates the main workflow; `Advanced features` repeats the earlier template pointer. The post-generation “confirm and iterate” wording conflicts with the earlier requirement to confirm before generation and should be reduced to one unambiguous approval gate. The 293-line `EXAMPLES.md` is unreachable sediment unless a clear “load when an example is needed” pointer is added; otherwise it should be retired. The 627-line template reference is large but earns progressive disclosure.
- Recommendation: **simplify inline**. Proposed shape: `Language Definitions` for the mode and overwrite vocabulary; one `Workflow` beginning with mode selection and retaining all eight interview questions, approval gate, mode-specific outputs, validation, and rerun rules; no `Activities`; `Reference` with one conditional template pointer and either a conditional examples pointer or an explicit recommendation to remove the orphaned examples.
- Preservation and risk: Preserve every interview question, heuristic proposal, user approval, generated artifact, brownfield extraction behavior, language-agnostic contract, and non-overwrite guarantee in the Workflow. Keep all schemas in `REFERENCE.md`. Resolve the contradictory generation order rather than silently choosing one. No third-party attribution is currently declared for this locally introduced skill. Confidence: high.

### codebase-design
- Profile / disclosure: Routed workflow; progressively disclosed
- Authorities: Frontmatter triggers interface, seam, module-shape, testability, and deep-module design; required behavior in `specs/ai-agent-config.md`; canonical project terminology in `specs/UBIQUITOUS_LANGUAGE.md`; Matt Pocock adaptation recorded in `THIRD_PARTY_NOTICES.md`; supporting files `shared/skills/codebase-design/DEEPENING.md` and `shared/skills/codebase-design/DESIGN-IT-TWICE.md`.
- Baseline: 49 lines; 461 words; 4 level-two headings (`Vocabulary`, `Principles`, `Design pass`, `Context pointers`); 2 Markdown references.
- Behavior ledger:
  - Language: Module, interface, implementation, depth/deep module, seam, adapter, leverage, and locality are all operational and currently defined. **Human-confirmation candidates:** all eight definitions, especially `interface` including errors/performance, `seam` versus DDD boundary, and the “two adapters justify a seam” threshold.
  - Workflow/routing: Read specifications, glossary, requirements, and nearby code; state owned capability and constraints; place seams and classify dependencies; compare alternatives using depth/locality/leverage/errors/test surface; recommend one and route durable invariants to the owning spec or plan. Route consolidation/dependency work to `DEEPENING.md`; route consequential interfaces or requested alternatives to `DESIGN-IT-TWICE.md`.
  - Activities: None; deepening and design-it-twice are conditional workflow branches, not independently advertised commands.
  - Inline contracts: Apply the deletion test; tests and callers cross the same interface; do not expose internal seams for testing; avoid hypothetical adapters; compare meaningfully different interfaces before consequential commitment; finish with explicit interface, hidden implementation, seam/adapters, and verification.
  - Reference: `DEEPENING.md` defines four dependency categories and a six-step consolidation path. `DESIGN-IT-TWICE.md` requires at least three complete independent interfaces, optional adapter-led design, Herdr/in-process execution parity, comparison, and falsifiable recommendation.
- YAGNI findings: No material sprawl. The vocabulary and principles directly change design choices, while both references have clear load conditions. The routing currently appears at the end rather than at the beginning.
- Recommendation: **retain**. Proposed shape: `Language Definitions` containing the existing vocabulary; one routed `Workflow` whose opening selects direct design, deepening, or design-it-twice; no `Activities`; `Reference` retaining both conditional pointers.
- Preservation and risk: Preserve the vocabulary verbatim pending human confirmation, deletion test, interface-as-test-surface rule, adapter threshold, dependency categories, three-alternative requirement, Herdr fallback, and all completion evidence. Reordering routing must not make alternative design optional when an interface is consequential. Confidence: high.

### code-review
- Profile / disclosure: Ordered workflow; self-contained
- Authorities: Frontmatter triggers review of branches, PRs, worktrees, WIP, and fixed-point diffs; required independent Standards/Spec behavior and delegation fallback in `specs/ai-agent-config.md`; Matt Pocock adaptation and MIT attribution in `THIRD_PARTY_NOTICES.md`; no supporting Markdown.
- Baseline: 48 lines; 409 words; 4 level-two headings (the four numbered steps); 0 Markdown references.
- Behavior ledger:
  - Language: Standards and Spec are distinct review axes; fixed point and three-dot diff are scope controls. **Human-confirmation candidates:** `Standards axis`, `Spec axis`, and `fixed point`, including the rule that neither axis may waive or rerank the other.
  - Workflow/routing: Resolve or request the baseline; capture commits and a stable diff; reject bad references or empty diffs; load repository standards and independently locate the originating requirement; report `No spec available` rather than inventing one; run separate Standards and Spec passes through Herdr or explicitly separated in-process checklists; ensure every changed file is considered; report separate severity-ordered sections and per-axis totals.
  - Activities: None.
  - Inline contracts: Formatting enforced by tools is not a review finding; documented-rule violations require location and citation; smells must be labelled judgement calls; every Spec finding cites its requirement; distinguish scope creep from harmless detail; every finding includes location, evidence, impact, and remedy; never name a cross-axis “winner.”
  - Reference: None; extraction would add more indirection than context savings.
- YAGNI findings: None. The smell list is compact decision support, not a second workflow.
- Recommendation: **retain**. Proposed shape: `Language Definitions` for the two axes and fixed point; one `Workflow` preserving all four steps and the Herdr/in-process branch; no `Activities`; no `Reference`.
- Preservation and risk: Preserve the ask-on-missing-baseline behavior, early failures, source authority rules, reviewer independence, smell labelling, every-file coverage criterion, and separate output sections/counts. Confidence: high.

### create-plan
- Profile / disclosure: Artifact workflow; progressively disclosed
- Authorities: Frontmatter triggers multi-context or parallel implementation planning; full Plan Workspace Contract in `specs/ai-agent-config.md`; `plan workspace`, `slice`, `frontier`, `verification artifact`, and `active-plan pointer` in `specs/UBIQUITOUS_LANGUAGE.md`; Matt Pocock adaptation in `THIRD_PARTY_NOTICES.md`; supporting schemas in `shared/skills/create-plan/PLAN-FORMAT.md`, `SLICE-FORMAT.md`, and `VERIFICATION-FORMAT.md`.
- Baseline: 123 lines; 1,203 words; 7 level-two headings (six numbered steps plus `Guardrails`); 3 Markdown references.
- Behavior ledger:
  - Language: Plan workspace, active-plan pointer, orchestration index, slice, frontier, fixed point, verification artifact, integration baseline, and parent are operational. **Human-confirmation candidates:** all of these, with explicit reconciliation against the overlapping definitions in `specs/UBIQUITOUS_LANGUAGE.md`.
  - Workflow/routing: Resolve `.plan`; stop on stale state; otherwise create the temporary workspace, local exclusion, and secret-safe pointer. Load and classify context; route unresolved implementation uncertainty to Wayfinder. Build parent-owned `PLAN.md` with immutable objective, Git topology, execution settings, DAG/frontier, states, verification matrix, acceptance, and recovery. Write fresh-context vertical TDD packets, with an explicit expand–migrate–contract exception and user approval for unapproved granularity. Select mandatory Standards/Spec plus risk-derived reviews. Execute only the integrated-blocker frontier using isolated editable worktrees, Herdr or in-process fallback, pinned read-only reviews, append-only fix attempts, parent cherry-pick, and parent integration checks. Finish with repository gates, final integration/acceptance, and resumable reconciliation.
  - Activities: None; opening, authoring, execution, verification, integration, and recovery are state-ordered.
  - Inline contracts: Parent alone writes control-plane state; pane ids are never durable identity; editable agents never share a checkout; worker claims are insufficient for verification; blockers require integration; failed work returns to the original branch; no merge, worktree deletion, or branch deletion without authorization; removed Pi profile/subagent surfaces stay removed.
  - Reference: The three references own complete `PLAN.md`, slice-packet, risk-matrix, verification-attempt, and final-review schemas and have mandatory load conditions.
- YAGNI findings: The behavioral density is justified by `specs/ai-agent-config.md`, but four rules repeat across the introduction, execution steps, and final Guardrails: parent ownership, editable-checkout isolation, non-durable pane ids, and independent Standards/Spec verification. The final Guardrails can be consolidated beside their governing steps without weakening them. References already earn disclosure and should not absorb required lifecycle gates.
- Recommendation: **simplify inline**. Proposed shape: `Language Definitions`; one `Workflow` preserving the six phases and all transitions; no `Activities`; `Reference` retaining the three mandatory schema pointers. Remove only duplicate restatements, leaving each ownership and transition rule at its governing step.
- Preservation and risk: Preserve every `.plan` failure branch, directory/path rule, context classification, objective immutability, DAG invariant, slice format, risk pass, state transition, worktree rule, review/fix history, cherry-pick gate, final review, recovery check, and authorization boundary. This skill is specification-constrained; over-compression could make recovery or ownership unsafe. Confidence: high.

### diagnosing-bugs
- Profile / disclosure: Ordered workflow; self-contained
- Authorities: Frontmatter triggers bugs, failures, flakiness, incorrect results, and performance regressions; required workflow in `specs/ai-agent-config.md`; Matt Pocock adaptation in `THIRD_PARTY_NOTICES.md`; no supporting Markdown.
- Baseline: 58 lines; 504 words; 6 level-two headings (the six numbered steps); 0 Markdown references.
- Behavior ledger:
  - Language: Tight command, red-capable, minimized reproduction, falsifiable hypothesis, causal explanation, and tagged instrumentation are operational. **Human-confirmation candidates:** `tight command`, `red-capable`, `minimized reproduction`, and `causal explanation`.
  - Workflow/routing: Build and run the smallest command that catches the exact symptom using the ordered reproduction preference. If impossible, stop theorizing and request missing access/artifacts. Reproduce repeatedly and remove inputs until minimal. Rank three to five falsifiable hypotheses and continue in evidence order. Probe one prediction at a time, tag temporary instrumentation, and establish performance baselines. Compose TDD to create a regression test and minimum fix; if no honest seam exists, record the architecture finding rather than a shallow test. Rerun original and regression commands, remove instrumentation, report cause/evidence/fix/seam/commands/risks, then optionally route architecture work after the fix.
  - Activities: None.
  - Inline contracts: Evidence precedes theory; the command must already have gone red; hypotheses predict observable results; instrumentation is removable; correlation is insufficient; tests use a pre-agreed honest seam; architecture work cannot replace fixing the requested bug.
  - Reference: None.
- YAGNI findings: None. Each step has a distinct evidence gate and failure path.
- Recommendation: **retain**. Proposed shape: `Language Definitions`; one six-step `Workflow`; no `Activities`; no `Reference`.
- Preservation and risk: Preserve the reproduction preference order, inability-to-reproduce stop, minimization test, hypothesis count, tagged cleanup, performance baseline, TDD delegation, no-seam branch, dual rerun, and post-fix architecture route. Confidence: high.

### gameplay-asset-imagegen
- Profile / disclosure: Artifact workflow; self-contained
- Authorities: Frontmatter triggers generated raster runtime assets and integration; generic shared-skill obligations in `specs/ai-agent-config.md`; locally introduced at commit `337b637`; no supporting Markdown. `pi/skills/gameplay-asset-imagegen` correctly points to the shared skill, but no `imagegen` skill exists in the shared or Pi-visible catalogs.
- Baseline: 61 lines; 548 words; 4 level-two headings (`Quick Workflow`, `Prompting For Runtime Assets`, `Integration Checklist`, `Common Gotchas`); 0 Markdown references.
- Behavior ledger:
  - Language: Generated source, runtime asset, chroma key, matte spill, transparent padding, and gameplay scale are operational. **Human-confirmation candidates:** `generated source`, `runtime asset`, `chroma-key background`, `matte spill`, and `gameplay scale`.
  - Workflow/routing: Load manifests/loaders/docs/tests/reference image; delegate bitmap generation to `imagegen`; save traceable sources separately; crop/slice, key, resize, and preserve placement padding; update manifest/loader/docs/tests together; validate dimensions, alpha, coverage, fringe, placement, readability, and appearance against the real background; route browser/video validation to visual QA when available.
  - Activities: The reusable chroma-key prompt is independently selectable. Source-to-runtime transformation and in-context validation remain workflow steps because they are required for integration.
  - Inline contracts: Do not substitute procedural placeholders; use a non-conflicting key color; keep source and runtime files separate; keep names stable unless consumers change; do not load runtime art from external/temp locations; do not crop concept art unless explicitly authorized; account for shrink/recentering, reuse-scale mismatch, and spill that threshold tests miss.
  - Reference: None.
- YAGNI findings: Workflow steps 4–6 are restated in the Integration Checklist and Common Gotchas instead of having their validation and failure rules colocated. The chroma-key prompt does earn an Activity. The mandatory delegation target `imagegen` is absent from the repository catalog, creating an unresolved main-path dependency rather than removable prose.
- Recommendation: **simplify inline**. Proposed shape: `Language Definitions`; one `Workflow` with transformation checks and gotchas moved beside the relevant step; `Activities` containing the chroma-key prompting recipe; no `Reference`.
- Preservation and risk: Preserve source provenance, separate runtime outputs, every transformation, manifest/loader/docs/test synchronization, all alpha/dimension/fringe/readability checks, visual-QA routing, and concept-art prohibition. Later catalog reconciliation must either supply or explicitly redefine the missing `imagegen` delegation; this audit must not silently remove it. Confidence: high on structure, medium on the unresolved dependency.

### grill-me
- Profile / disclosure: Ordered workflow; self-contained
- Authorities: Frontmatter triggers decision/design stress-testing and explicit “grill me” requests; required glossary, evidence, edge-case, and no-edit behavior in `specs/ai-agent-config.md`; originally imported from `mattpocock/skills` at commit `80eafee` and substantially expanded later; no supporting Markdown.
- Baseline: 79 lines; 621 words; 4 level-two headings (the four numbered steps); 0 Markdown references.
- Behavior ledger:
  - Language: Decision branch, shared understanding, canonical term, term candidate, definition drift, and desired behavior are operational. **Human-confirmation candidates:** `decision branch`, `shared understanding`, `term candidate`, and `definition drift`.
  - Workflow/routing: Before asking, find the repo, read both glossary scopes, relevant specs/plans/research/code, and investigate discoverable facts. Ask one concrete question at a time with a recommendation and revisable progress estimate. Walk prerequisites before dependent choices; probe cardinality, lifecycle, ownership, boundaries, and scope; distinguish implemented/specified/desired behavior; track decisions, tensions, terms, and blockers. Flag new or drifting terms without editing glossaries. Close with a complete summary, obtain explicit confirmation, then route terminology, specs, implementation-ready work, or multi-session uncertainty to the owning skills.
  - Activities: None.
  - Inline contracts: No project edits during the interview; do not ask users for discoverable facts; surface source conflicts neutrally; every answer must resolve, sharpen, or request evidence; no vague agreement; term changes require a concrete edge case and boundary; no durable changes before summary confirmation.
  - Reference: None.
- YAGNI findings: No workflow sprawl. Every edge-case category or tracking item changes interview coverage. **Provenance gap:** `THIRD_PARTY_NOTICES.md` does not list this skill despite the explicit import recorded by commit `80eafee`; the repository’s imported-material contract requires later correction.
- Recommendation: **retain**. Proposed shape: `Language Definitions`; one four-step `Workflow`; no `Activities`; no `Reference`.
- Preservation and risk: Preserve progress reporting, dual-glossary precedence, evidence-first questioning, all relationship probes, tracking obligations, exact term-candidate behavior, summary fields, human confirmation, and downstream routes. Resolve notice coverage later without changing behavior. Confidence: high.

### improve-codebase-architecture
- Profile / disclosure: Artifact workflow; progressively disclosed
- Authorities: Frontmatter triggers architecture deepening, consolidation, coupling reduction, and testability work; required temporary visual report in `specs/ai-agent-config.md`; architecture vocabulary delegated to `shared/skills/codebase-design/SKILL.md`; Matt Pocock adaptation in `THIRD_PARTY_NOTICES.md`; report schema in `shared/skills/improve-codebase-architecture/HTML-REPORT.md`.
- Baseline: 47 lines; 510 words; 4 level-two headings (the four numbered steps); 1 Markdown reference.
- Behavior ledger:
  - Language: Module/interface/depth/seam/adapter/leverage/locality are explicitly owned by the delegated design skill. Skill-local terms are hotspot evidence, architecture candidate, recommendation strength, and spec tension. **Human-confirmation candidates:** `hotspot evidence`, `architecture candidate`, and `spec tension`; imported design terms should not be redefined here.
  - Workflow/routing: Prefer user-named pain; otherwise use meaningful Git history to rank repeatedly changed areas. Read spec-suite entry points, glossary, relevant specs, and native design records. Explore shallow spread, leaking seams, duplicated orchestration, pass-throughs, internal-test coupling, and scattered edits; apply deletion/adaptor/test-surface tests, with Herdr or direct fallback. Always load the HTML schema and create/open/report a temporary comparison with evidence, candidate cards, before/after diagrams, spec tension, and top recommendation. Ask the user to select one candidate, then clarify constraints/invariants/migration/tests, optionally run Design It Twice, record durable decisions, and stop before implementation.
  - Activities: None.
  - Inline contracts: Scope needs evidence; every candidate names files/friction/spec constraints/gain; report must remain outside the repository and have an absolute path; each candidate gets readable visuals; no refactor before candidate and interface/plan approval.
  - Reference: `HTML-REPORT.md` earns mandatory loading when producing the report and owns HTML skeleton, badges, candidate-card fields, diagram patterns, and visual tone.
- YAGNI findings: The instruction to load the design skill appears at entry and again after selection. That repeated load can be consolidated, while the delegated vocabulary and report details remain necessary.
- Recommendation: **simplify inline**. Proposed shape: `Language Definitions` containing only skill-local report/candidate terms and delegating architecture vocabulary; one four-step `Workflow`; no `Activities`; `Reference` retaining the mandatory report-schema pointer.
- Preservation and risk: Preserve intent/history scoping, all friction signals, environment delegation, evidence criteria, temporary output, every report field and diagram, selection approval, Design It Twice branch, decision recording, and implementation stop. Confidence: high.

### research
- Profile / disclosure: Artifact workflow; self-contained
- Authorities: Frontmatter limits invocation to durable technical investigation rather than routine lookup; required primary-source artifact behavior in `specs/ai-agent-config.md`; Matt Pocock adaptation in `THIRD_PARTY_NOTICES.md`; no supporting Markdown.
- Baseline: 51 lines; 340 words; 4 level-two headings (the four numbered steps); 0 Markdown references.
- Behavior ledger:
  - Language: Primary source, secondary source, inference, stable citation, research artifact, freshness, and fixed version are operational. **Human-confirmation candidates:** `primary source`, `inference`, `research artifact`, and `required freshness`.
  - Workflow/routing: Frame question/decision, scope, freshness, completion, primary-evidence claims, and falsifier. Use existing artifact conventions; if absent, ask before creating repository structure and use an approved path or temporary draft. Investigate sources in authority order, preserving title/location/version/date/access date and separating fact from inference. Under Herdr delegate independent source areas read-only and verify citations; otherwise work source by source in-process. Reconcile conflicts by authority/version and write a cited artifact with findings, evidence, limitations, implications, and follow-ups; report the absolute path.
  - Activities: None.
  - Inline contracts: Secondary sources only discover or clearly interpret primary evidence; quote sparingly; citations sit adjacent to material claims; future delegated editing requires isolation; never invent a repository research convention.
  - Reference: None.
- YAGNI findings: None. The source hierarchy and output schema are both compact and behavior-changing.
- Recommendation: **retain**. Proposed shape: `Language Definitions`; one four-step `Workflow`; no `Activities`; no `Reference`.
- Preservation and risk: Preserve the durable-versus-quick routing boundary, artifact-location approval, full authority order, freshness metadata, fact/inference distinction, delegation parity, citation verification, conflict reconciliation, artifact fields, and absolute-path report. Confidence: high.

### resolving-merge-conflicts
- Profile / disclosure: Ordered workflow; self-contained
- Authorities: Frontmatter triggers in-progress merge, rebase, cherry-pick, or revert conflicts; required intent tracing, staged verification, and explicit continuation approval in `specs/ai-agent-config.md`; Matt Pocock adaptation in `THIRD_PARTY_NOTICES.md`; no supporting Markdown.
- Baseline: 47 lines; 355 words; 5 level-two headings (the five numbered steps); 0 Markdown references.
- Behavior ledger:
  - Language: Active Git operation, stage entry, source intent, authoritative source, combined result, and remaining operation are operational. **Human-confirmation candidates:** `source intent`, `authoritative source`, `combined result`, and `remaining operation`.
  - Workflow/routing: Inspect status, active operation, paths, stage entries, history, and ours/base/theirs commit identities while preserving unrelated changes. For every hunk, trace both introducing intents from commits/messages/history/issues/plans/specs. If authority or compatibility is unclear, stop and ask whether to choose, redesign, or abort. Resolve compatible intents together and conflicting ones according to goal and authority; remove markers and inspect semantic neighbors. Run focused then broader checks, fix only merge-induced failures, stage only verified resolutions, inspect staged diff, and report preserved intents, files, checks, operation, and exact remaining approved action.
  - Activities: None.
  - Inline contracts: Rebase labels can reverse meaning; every hunk needs two intent statements; do not abort silently; do not invent unrelated behavior or absorb cleanup; do not commit, continue, or abort without explicit request.
  - Reference: None.
- YAGNI findings: None.
- Recommendation: **retain**. Proposed shape: `Language Definitions`; one five-step `Workflow`; no `Activities`; no `Reference`.
- Preservation and risk: Preserve all operation types, stage/history inspection, unrelated-change protection, per-hunk dual intent, uncertainty stop, semantic-neighbor check, focused/broader verification, selective staging, and continuation authorization. Confidence: high.

### tdd
- Profile / disclosure: Routed workflow; progressively disclosed
- Authorities: Frontmatter triggers requested test-first implementation and diagnosed regression fixes; repository TDD contract in `AGENTS.md`; generic skill/provenance obligations in `specs/ai-agent-config.md`; Matt Pocock adaptation in `THIRD_PARTY_NOTICES.md`; supporting files `shared/skills/tdd/tests.md`, `mocking.md`, and `refactoring.md`.
- Baseline: 67 lines; 554 words; 7 level-two headings (`Guardrails`, `Discovered bug fast path`, and five numbered steps); 3 Markdown references.
- Behavior ledger:
  - Language: Tracer bullet, Red, Green, Refactor, agreed seam, independent oracle, tautological test, vertical slice, and discovered-bug fast path are operational. `Seam` is owned by the design skill. **Human-confirmation candidates:** `tracer bullet`, `Red`, `Green`, `Refactor`, `independent oracle`, `vertical slice`, and `discovered-bug fast path`; `seam` must reference rather than fork its canonical definition.
  - Workflow/routing: Read guidance/specs/glossary; load design guidance for interface changes. Route an already diagnosed, unambiguous bug through the short fast path; otherwise agree interface, seams, behavior order, expected result, and command. Write one behavior test and observe the intended failure. Implement only enough to pass and run focused/nearby checks. Repeat one red/green behavior at a time with the per-cycle checklist. Refactor only while green, rerunning after each change and requiring approval for seam changes.
  - Activities: None; Red, Green, and Refactor are phases of one required process.
  - Inline contracts: Tests use public interfaces and caller-observable outcomes; expectations need an independent source; no implementation-shaped tests or all-tests-first horizontal slicing; pre-agree seams except for the stated bug fast path; finish with all agreed behavior and broader checks green.
  - Reference: `tests.md` supplies earned good/bad examples and tautology examples. `mocking.md` supplies external-seam recipes but should align terminology with the design skill. The 10-line `refactoring.md` repeats main-step cleanup and design-smell ownership.
- YAGNI findings: `Guardrails` repeats rules later enforced by the numbered steps and should be colocated with those steps. `refactoring.md` is too small and duplicative to earn a separate pointer; its only live content is already represented by the Refactor step or the architecture skill. Cross-skill ownership of seam/mock/refactor guidance should be reconciled in WF-006 rather than decided here.
- Recommendation: **simplify inline**. Proposed shape: `Language Definitions`; one routed `Workflow` beginning with normal versus discovered-bug routing and colocating guardrails; no `Activities`; `Reference` retaining examples and external-seam guidance, while recommending consolidation or retirement of the duplicative refactoring note after ownership review.
- Preservation and risk: Preserve pre-agreement, fast-path disclosure, independent expectations, intended-red requirement, minimal green, one-test cycles, checklist, green-only refactoring, seam approval, and all command gates. Do not remove `refactoring.md` until its remaining heuristics are mapped to the design owner. Confidence: high.

### teach
- Profile / disclosure: Artifact workflow; progressively disclosed
- Authorities: Frontmatter triggers sustained structured learning and personal-course work; full Teaching Workspace Contract in `specs/ai-agent-config.md`; Matt Pocock adaptation in `THIRD_PARTY_NOTICES.md`; supporting artifact schemas in `MISSION-FORMAT.md`, `RESOURCES-FORMAT.md`, `LEARNING-RECORD-FORMAT.md`, and `GLOSSARY-FORMAT.md`.
- Baseline: 96 lines; 849 words; 6 level-two headings (the six numbered steps); 4 Markdown references.
- Behavior ledger:
  - Language: Teaching workspace, mission, zone of proximal development, knowledge, skill, wisdom, storage strength, retrieval practice, learning record, and demonstrated understanding are operational. **Human-confirmation candidates:** all of these, especially the Knowledge/Skill/Wisdom distinction, `zone of proximal development`, `storage strength`, and the evidence threshold for `demonstrated understanding`.
  - Workflow/routing: Ask for and receive approval for a dedicated path and scaffold; do not silently use a code checkout; inspect existing state and create lazily. Agree mission, observable success, constraints, and scope before writing; confirm mission changes and record them; estimate the next challenge from records/performance/prior knowledge/misconceptions. Compose Research for trustworthy resources and preserve gaps/preferences. Produce one self-contained mission-linked HTML lesson with citations, retrieval/practice, feedback, success signal, and optional codebase-accurate explainer composition while retaining workspace ownership. Reuse shared assets, create printable references, and only promote understood terms. Observe unaided application, record only durable learning evidence, supersede rather than delete, preview, report the absolute path, and identify the next step.
  - Activities: None; lesson design, reference compression, and observation are ordered parts of the stateful teaching cycle.
  - Inline contracts: Path and scaffold approval precede writes; no parametric factual claims; every substantive lesson claim is cited or labelled exercise/hypothesis; respect community refusal; one tangible lesson win; no quiz answer clues; reusable behavior has one home; coverage is not learning; records are not session logs.
  - Reference: Four conditionally loaded files own mission, curated-resource, sequential-learning-record, and understood-term glossary schemas and their artifact-specific invariants.
- YAGNI findings: The schemas earn disclosure. The dense learning-science rules in lesson design are required behavior but interrupt the control path and include material claims without an adjacent source-backed skill reference; license provenance is not factual evidence. They would earn a mandatory “load when designing a lesson” reference, while the main Workflow retains the non-negotiable retrieval/practice/feedback contract.
- Recommendation: **move detail to Reference**. Proposed shape: `Language Definitions`; one six-step `Workflow` retaining approvals, artifact ownership, citations, lesson outcome, evidence gates, and completion; no `Activities`; `Reference` retaining the four schemas and adding a conditionally mandatory, source-backed teaching-practice reference for detailed retrieval/spacing/interleaving guidance.
- Preservation and risk: Preserve every workspace artifact, approval, mission-change rule, ZPD input, source standard, Knowledge/Skill/Wisdom distinction, lesson requirement, explainer ownership rule, reusable-asset rule, glossary threshold, record/supersession rule, rendering check, and next-step evidence. Moving pedagogy must not make it optional. Confidence: medium-high because source selection needs separate research.

### wayfinder
- Profile / disclosure: Routed workflow; progressively disclosed
- Authorities: Frontmatter triggers uncertainty too broad for one implementation plan; full Wayfinder State Contract in `specs/ai-agent-config.md`; overlapping canonical terms in `specs/UBIQUITOUS_LANGUAGE.md`; Matt Pocock adaptation in `THIRD_PARTY_NOTICES.md`; state schemas in `shared/skills/wayfinder/FORMATS.md`.
- Baseline: 95 lines; 889 words; 6 level-two headings (`Core model` plus five numbered steps); 1 Markdown reference.
- Behavior ledger:
  - Language: Destination, effort, decision ticket, fog of war, frontier, and out of scope are operational. **Human-confirmation candidates:** all six, with `decision ticket` and `frontier` reconciled against `specs/UBIQUITOUS_LANGUAGE.md`.
  - Workflow/routing: Open an existing map or use grilling and breadth-first exploration to establish destination/scope; route directly to planning if uncertainty already fits one context; ask before creating state; write map/tickets and blockers. Derive the frontier from resolved blockers and claim exactly one non-research decision, allowing independent research in parallel. Route ticket types to Research, Prototype, Grill Me, or prerequisite task behavior; delegate read-only through Herdr when useful; isolate editors; stop before production implementation. Parent records resolution, status, map gist, new tickets/edges, graduated fog, invalidated edges, and ruled-out scope with one durable home. Complete only when destination is clear and no open tickets or in-scope fog remain, then route terminology/specs and implementation to their owners.
  - Activities: None; ticket-type composition is routing within one uncertainty-resolution workflow.
  - Inline contracts: Parent alone writes state; out-of-scope does not satisfy blockers; no blocker bypass; one non-research ticket per session; no production implementation; no durable pane ids; map stays low-resolution; sections remain mutually exclusive; empty frontier does not prove completion.
  - Reference: `FORMATS.md` earns mandatory loading for map/ticket creation or changes and owns exact sections, frontmatter, statuses, blocker semantics, and state rules.
- YAGNI findings: None. The core model is required Language Definitions, and each lifecycle/ownership rule is also explicitly contracted by `specs/ai-agent-config.md`.
- Recommendation: **retain**. Proposed shape: rename `Core model` to `Language Definitions`; retain one five-step routed `Workflow`; no `Activities`; `Reference` retaining the mandatory format pointer.
- Preservation and risk: Preserve every route, approval, state path, blocker criterion, ownership boundary, delegation rule, implementation stop, resolution update, fog transition, one-home rule, completion test, and onward route. Align duplicate glossary definitions rather than creating competing wording. Confidence: high.

### write-a-skill
- Profile / disclosure: Artifact workflow; self-contained
- Authorities: Frontmatter triggers creation, revision, splitting, and audit of skills; generic frontmatter/provenance/visibility obligations in `specs/ai-agent-config.md` and `AGENTS.md`; Pi freeform-body and progressive-disclosure behavior in installed `docs/skills.md`; Matt Pocock adaptation in `THIRD_PARTY_NOTICES.md`; no supporting Markdown.
- Baseline: 71 lines; 545 words; 5 level-two headings (the five numbered steps); 0 Markdown references.
- Behavior ledger:
  - Language: Branch, leading word, context load, human cognitive load, context pointer, progressive disclosure, sediment, sprawl, and no-op are operational. **Human-confirmation candidates:** `branch`, `leading word`, `context pointer`, `progressive disclosure`, `sediment`, `sprawl`, and `no-op`.
  - Workflow/routing: Identify task, branches, artifacts, tools, failures, and a strong leading word; balance automatic discovery against explicit invocation and write portable `Use when` descriptions. Design one source of truth, keeping always-needed rules inline, moving only branch/detail material behind conditional pointers, and adding deterministic scripts only when earned. Split only for independent invocation/reuse or premature-completion control. Give every step actions, branches/failures, and checkable completion. Apply directory/frontmatter/description/provenance requirements. Prune duplication/sediment/sprawl/no-ops; validate names, links, scripts, examples, completion criteria, audit command, and visibility.
  - Activities: None; skill design and verification are ordered.
  - Inline contracts: Do not rely solely on harness-specific explicit-only metadata; descriptions stay within 1,024 characters; required instructions cannot hide behind optional wording; relative links resolve from the skill directory; prohibitions need positive alternatives; preserve license/provenance; shared skills use union frontmatter.
  - Reference: None. The current body is compact enough to stay self-contained.
- YAGNI findings: Branch/splitting criteria are distributed across the first two steps and can be consolidated at routing. More importantly, the skill does not yet teach the confirmed four-section contract, so retaining its current hierarchy would reproduce the structure this audit is replacing. Frontmatter redesign remains out of scope.
- Recommendation: **simplify inline**. Proposed shape: `Language Definitions` for skill-authoring terms; one `Workflow` covering invocation, routing, four-section hierarchy, checkable writing, cross-agent structure, and pruning; no `Activities`; no `Reference` unless future examples or schemas earn a load condition. Explicitly teach mandatory `Language Definitions`, optional single `Workflow`, optional `Activities`, and optional `Reference`, with guardrails colocated.
- Preservation and risk: Preserve discovery trade-offs, leading-word guidance, all split tests, conditional disclosure, deterministic-script threshold, completion-criterion schema, union frontmatter, description limit, provenance rule, pruning categories, one-level reference validation, repository audit, and visibility checks. The four-section addition must not imply artificial headings beyond the confirmed optionality rules. Confidence: high.

**Coverage count: 14/14 workflow-centric skills audited exactly once; 14/14 have a primary verdict, complete behavior ledger, proposed four-section shape, provenance assessment, and Language Definition review; 0 implementations performed.**
