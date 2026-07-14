---
id: WF-005
type: research
status: resolved
blocked-by: [WF-002]
---

# Audit artifact, router, and compact skills

## Question
How should artifact contracts, routing choices, and compact processes fit the four-section contract without creating extra top-level sections or boilerplate?

## Why it matters
These skills are where structural normalization is most likely to hide output requirements, demote routing decisions, or lengthen already-small files.

## Completion evidence
Comparable audit records and one evidenced recommendation exist for: `audit-shared-skills`, `create-agents-md`, `curator`, `design-md`, `handoff`, `image-comparison-judge`, `image-diff-describer`, `test-quality-verifier`, `ubiquitous-language`, `update-specs`, `video-to-contact-sheet`, `create-explainer`, `em-train`, `prototype`, `tmux-agent-orchestration`, and `visual-qa`. Routing appears at the start of Workflow, output contracts remain beside their producing step or Activity, and compact skills are not padded.

## Resolution
Audit method follows `WF-002`: complete `SKILL.md`, directly linked Markdown, applicable specs, Pi skill-loading guidance, repository provenance, and supporting artifacts were inspected. Baselines use `wc -lw`; level-two headings exclude frontmatter and fenced examples.

### audit-shared-skills
- Profile / disclosure: Artifact workflow; self-contained
- Authorities: Frontmatter triggers audits after shared skills are added or changed; cross-agent requirements come from `specs/ai-agent-config.md`; discovery/progressive-disclosure behavior comes from Pi `docs/skills.md`; repo-local provenance with no attribution entry in `THIRD_PARTY_NOTICES.md`; supporting file: `shared/skills/audit-shared-skills/SKILL.md`
- Baseline: 65 lines; 378 words; level-two headings: `Union Schema`, `Process`, `Report Format`, `Fixing`; Markdown references: none
- Behavior ledger:
  - Language: “union schema” and error/warning/info severities are execution-relevant; **material Language Definition candidates requiring human confirmation**
  - Workflow/routing: discover every `shared/skills/*/SKILL.md`; parse frontmatter; check required fields, description constraints, trigger wording, and tool grants; report by skill; offer fixes; obtain approval before writing; rerun after changes
  - Activities: none independently selectable
  - Inline contracts: every skill must be covered; errors and warnings have specified conditions; report shape is fixed; fixes require interactive approval; final rerun must be clean
  - Reference: none warranted
- YAGNI findings: Compact and independently executable. `info` is named as a severity but no condition produces it. `Fixing` repeats some issue-to-remedy mapping from `Process`, but the duplication is small. Frontmatter behavior largely repeats `specs/ai-agent-config.md`, necessarily as an executable checklist.
- Recommendation: **simplify inline**. Proposed shape—Language Definitions: define “union schema” and supported severities; Workflow: retain the complete discover/check/report/approve/fix/rerun sequence with report and approval contracts beside their steps; Activities: none; Reference: none. Remove or define the currently no-op `info` severity rather than expanding the skill.
- Preservation and risk: Preserve exhaustive catalog coverage, severity conditions, least-tool checking, approval before edits, and the clean rerun. Do not move the schema behind a reference because it is required on every invocation. High confidence.

### create-agents-md
- Profile / disclosure: Routed artifact workflow; progressively disclosed
- Authorities: Frontmatter routes creation and maintenance of `AGENTS.md`; shared-skill rules come from `specs/ai-agent-config.md`; repository module vocabulary and ownership rules come from `AGENTS.md`; supporting files are `shared/skills/create-agents-md/TEMPLATE.md`, `shared/skills/create-agents-md/PRINCIPLES_CATALOG.md`, and `shared/skills/create-agents-md/scripts/detect-structure.sh`; repo-local provenance with no entry in `THIRD_PARTY_NOTICES.md`
- Baseline: 182 lines; 1,055 words; level-two headings: `Workflow`, `Full Generation (No Existing AGENTS.md)`, `Incremental Update (Existing AGENTS.md)`; Markdown references: `TEMPLATE.md`, `PRINCIPLES_CATALOG.md`
- Behavior ledger:
  - Language: “codebase map,” “hill climbing,” “tree hash,” “confidence marker,” and the skill’s operational meaning of “module” are **material Language Definition candidates requiring human confirmation**
  - Workflow/routing: first route on whether root `AGENTS.md` exists; generation runs structural detection, drafts from the template, confirms modules, conducts a grill-me pass, merges findings, and finalizes; update mode compares tree hashes, handles structural changes, preserves human-authored rules, confirms new modules, and optionally grills only new areas
  - Activities: none; detection is a supporting implementation, not a user-selected activity
  - Inline contracts: preserve human-authored content; mark uncertainty; ask before removals; use parent-owned edits; Herdr delegates remain read-only and may grill only when the user can interact; never persist pane IDs; report module/rule counts
  - Reference: template when drafting; principles catalog when preparing the deep pass; detection script when scanning
- YAGNI findings: Routing is correctly first, but the routed branches escape the single `Workflow` under separate level-two headings. The long structured delegation briefing is branch-only detail and partially restates the principles catalog. The 498-line detection script correctly earns separation from the skill body.
- Recommendation: **move detail to Reference**. Proposed shape—Language Definitions: define the audit-local terms above; Workflow: one routed workflow with generation and incremental-update as level-three branches, retaining every approval and ownership rule; Activities: none; Reference: keep `TEMPLATE.md` and `PRINCIPLES_CATALOG.md`, and move the detailed grill briefing into conditional reference material loaded only for the deep pass.
- Preservation and risk: Preserve mode detection, hash behavior, low-confidence markers, human-content protection, delegation fallback, and final artifact counts. Do not move the branch choice or approval gates out of the main path. Relative links and `scripts/detect-structure.sh` must remain valid. High confidence.

### curator
- Profile / disclosure: Artifact workflow; overloaded
- Authorities: Frontmatter triggers retrospective-driven durable-state curation; shared-skill and runtime-availability rules come from `specs/ai-agent-config.md` and Pi `docs/skills.md`; project terms come from `specs/UBIQUITOUS_LANGUAGE.md`; repo-local provenance with no entry in `THIRD_PARTY_NOTICES.md`; no supporting Markdown
- Baseline: 346 lines; 2,922 words; level-two headings: `Operating Rules`, `Human Retrospective Intake`, `Evidence Scan`, `Worktree Triage`, `Recommendation Types`, `Skill Ecosystem Routing`, `Ranking Model`, `Default Sequential Proposal Format`, `Full Summary Format`, `Quality Bar`; Markdown references: none
- Behavior ledger:
  - Language: “durable agent state,” “human-steered evidence,” “tentative approval,” “runtime availability,” and “stuck moment” are **material Language Definition candidates requiring human confirmation**
  - Workflow/routing: optional retrospective intake; detect active agent; scan current context, history, Git, skills, docs/specs/plans, runtime discovery, stale guidance, cross-evidence mismatch, and the hardest stall; rank 3–5 recommendations; route sequential review by default or full summary only when explicitly requested; collect tentative decisions; obtain one final approval; apply only approved writes; report repository state
  - Activities: none independently invocable
  - Inline contracts: no writes before final confirmation; respect privacy and scope boundaries; preserve unrelated/generated/tool-owned files; always consider a new-skill candidate; rank by compound value; one recommendation at a time by default; stuck advice is ephemeral and never written
  - Reference: evidence-scan catalog, ranking factors, output templates, recommendation-type extensions, and stuck-point decision tree are conditional candidates
- YAGNI findings: The main path is obscured by fourteen evidence-scan rules, two large output schemas, routing catalogs, and a substantial ephemeral stuck-point subsystem. Much of this changes correctness and must remain, but it need not all load in the primary workflow. Cross-skill trigger summaries are legitimate routing data, though final ownership belongs to WF-006.
- Recommendation: **move detail to Reference**. Proposed shape—Language Definitions: define the material curator-local terms; Workflow: intake → bounded evidence scan → rank → route sequential/full presentation → tentative decisions → final approval → apply/report; Activities: none; Reference: conditionally load the detailed evidence checklist, ranking model, output templates, worktree triage, and stuck-point analysis.
- Preservation and risk: Keep privacy, runtime discoverability, worktree ownership, 3–5 recommendation count, new-skill consideration, sequential default, tentative approvals, final confirmation, and ephemeral advice in the executable path. Extraction must not make those rules appear optional. Medium-high confidence.

### design-md
- Profile / disclosure: Routed artifact workflow; self-contained
- Authorities: Frontmatter promises create, update, audit, and validate modes; shared-skill contract comes from `specs/ai-agent-config.md`; `specs/DESIGN_LANGUAGE.md` is repository interface vocabulary but is not the Google `DESIGN.md` artifact schema; repo-local provenance with no entry in `THIRD_PARTY_NOTICES.md`; no supporting Markdown
- Baseline: 67 lines; 467 words; level-two headings: `Quick Start`, `Workflow`, `Token Rules`, `Updating Existing DESIGN.md`, `Quality Bar`; Markdown references: none
- Behavior ledger:
  - Language: “design contract,” “token reference,” and “orphaned token” are **material Language Definition candidates requiring human confirmation**
  - Workflow/routing: inspect existing design evidence; extract rather than invent; create exact YAML tokens and canonical prose sections; update existing naming and intent carefully; audit against rendered evidence; validate with official lint/diff commands when available
  - Activities: lint and version diff are reusable commands, but they remain gates within create/update/audit modes rather than a separate catalog
  - Inline contracts: canonical artifact section order; exact token forms and references; no generic guidance, CSS dumps, invented style, or ungrounded tokens; update discovery guidance when necessary
  - Reference: none currently warranted
- YAGNI findings: Compact, but routing among create/update/audit/validate is implicit and the existing-update branch appears after the main workflow. The artifact’s eight canonical sections must not be confused with the four-section skill contract.
- Recommendation: **simplify inline**. Proposed shape—Language Definitions: define the three artifact-specific terms; Workflow: begin by choosing create, update, audit, or validate mode, then retain one evidence-grounded path with mode-specific gates; Activities: none; Reference: none. Keep the artifact section order inline beside artifact production.
- Preservation and risk: Do not lengthen this compact skill with schema commentary already enforced by the linter. Preserve extraction-before-invention, token constraints, lint/diff behavior, and quality rejection rules. High confidence.

### handoff
- Profile / disclosure: Artifact workflow; self-contained
- Authorities: Frontmatter triggers pauses, agent/session switches, and context compaction; `specs/ai-agent-config.md` explicitly requires a redacted timestamped Markdown file under the OS temporary handoff directory and an absolute-path report; adapted provenance and MIT attribution are recorded in `THIRD_PARTY_NOTICES.md`; no supporting Markdown
- Baseline: 33 lines; 231 words; level-two headings: `Process`; Markdown references: none
- Behavior ledger:
  - Language: no additional skill-specific terms are needed; “handoff” is adequately established by the title and opening sentence
  - Workflow/routing: resolve/create the temp directory; generate slug and timestamp; collect continuation state; redact sensitive material; reference rather than duplicate artifacts; write the specified sections; reread for self-containment and redaction
  - Activities: none
  - Inline contracts: artifact must remain outside the repository; redact enumerated sensitive classes; verify the saved file; fresh agent must identify the next action; absolute path must be the final response line
  - Reference: none
- YAGNI findings: No sediment or unsupported branch. Every instruction changes artifact safety, continuity, or the repository contract.
- Recommendation: **retain**. Proposed shape—Language Definitions: explicitly state that no skill-specific terms exist; Workflow: keep the current seven-step producer path and completion criterion together; Activities: none; Reference: none.
- Preservation and risk: Protect this compact skill from padding. Do not extract the artifact schema or final-line contract. Preserve provenance and MIT attribution. High confidence.

### image-comparison-judge
- Profile / disclosure: Artifact workflow; self-contained
- Authorities: Frontmatter triggers independent PASS/FAIL comparison after neutral diffing or capture; shared-skill contract comes from `specs/ai-agent-config.md`; repo-local provenance with no entry in `THIRD_PARTY_NOTICES.md`; related skills are `shared/skills/image-diff-describer/SKILL.md` and `shared/skills/visual-qa/SKILL.md`
- Baseline: 42 lines; 316 words; level-two headings: `Workflow`, `Delegation Brief`, `Fallback`; Markdown references: none
- Behavior ledger:
  - Language: “neutral diff artifact” and “visual acceptance” are **material Language Definition candidates requiring human confirmation** and overlap with adjacent visual skills
  - Workflow/routing: determine whether already running as the judge, whether a repo wrapper exists, and whether delegation is available; gather reference/candidates and verdict-changing constraints; prefer neutral diff evidence; perform or delegate comparison; return strict verdict and findings; limit PASS to the requested surface
  - Activities: none
  - Inline contracts: delegated brief must contain evidence paths, match target, review dimensions, forbidden elements, and comparison surface; fallback must disclose lack of independent delegation; final human acceptance is not replaced
  - Reference: none
- YAGNI findings: Routing currently occurs after evidence gathering and is split across Workflow and Fallback. This is small but makes ownership and fallback less obvious. Visual terminology overlaps with `image-diff-describer` and `visual-qa`; ownership should be reconciled in WF-006.
- Recommendation: **simplify inline**. Proposed shape—Language Definitions: define neutral diff and scoped visual acceptance; Workflow: put role/wrapper/delegation routing first, then gather evidence and apply the verdict contract; Activities: none; Reference: none.
- Preservation and risk: Keep strict PASS/FAIL, blocking versus secondary findings, domain constraints, fallback disclosure, and human-acceptance boundary beside the judging step. Do not add visual-review theory. High confidence.

### image-diff-describer
- Profile / disclosure: Artifact workflow; self-contained
- Authorities: Frontmatter triggers bias-resistant visual description before judgment; shared-skill contract comes from `specs/ai-agent-config.md`; repo-local provenance with no entry in `THIRD_PARTY_NOTICES.md`; related skill: `shared/skills/image-comparison-judge/SKILL.md`
- Baseline: 45 lines; 258 words; level-two headings: `Workflow`, `Output rules`, `Required output`, `Delegation Brief`; Markdown references: none
- Behavior ledger:
  - Language: “neutral diff artifact,” “raw diffing,” and “verdict” are **material Language Definition candidates requiring human confirmation**
  - Workflow/routing: gather image paths; use a raw-comparison delegate when available without exposing acceptance criteria; compare observable evidence; save or return the structured artifact
  - Activities: none
  - Inline contracts: no PASS/FAIL, blocking classification, hidden-goal recommendation, or project-specific criteria; uncertainty must be explicit; five required output fields; wrapper takes precedence
  - Reference: none
- YAGNI findings: Compact and behaviorally sharp. Separate output headings are artifact contracts rather than independent workflows, but can be colocated without deletion. Terminology duplicates the judge skill and needs later ownership reconciliation.
- Recommendation: **retain**. Proposed shape—Language Definitions: define the neutral/no-verdict boundary; Workflow: retain the four-step flow with delegation brief and required output beside the producing step; Activities: none; Reference: none.
- Preservation and risk: Protect against padding and against weakening neutrality. Do not move prohibited-judgment rules into optional reference material. High confidence.

### test-quality-verifier
- Profile / disclosure: Artifact workflow; self-contained
- Authorities: Frontmatter triggers test-quality audits and coverage improvement; shared-skill contract comes from `specs/ai-agent-config.md`; repository TDD policy is in `AGENTS.md`; repo-local provenance with no entry in `THIRD_PARTY_NOTICES.md`; no supporting Markdown
- Baseline: 36 lines; 249 words; level-two headings: `Quick Use`, `Workflow`, `Output`; Markdown references: none
- Behavior ledger:
  - Language: “vague assertion” is a **material Language Definition candidate requiring human confirmation**
  - Workflow/routing: choose delegated verifier when available or solo fallback; identify runner/conventions; enumerate tests; identify language-specific weak assertions; run test/coverage commands; replace weak assertions and add branch tests; rerun; report
  - Activities: none
  - Inline contracts: assertions must validate actual values, shapes, and errors; report files scanned, findings/fixes, tests added, sourced coverage, and reasoned PASS/FAIL
  - Reference: none
- YAGNI findings: Compact and executable. The audit-versus-edit mode is implicit: the trigger includes both, while the workflow always proceeds to modifications. No approval or explicit audit-only route is stated.
- Recommendation: **retain**. Proposed shape—Language Definitions: define “vague assertion”; Workflow: begin with delegated/solo routing and make requested audit-only versus improve mode explicit without adding another process; Activities: none; Reference: none.
- Preservation and risk: Preserve language-specific examples, rerun requirement, coverage-source reporting, and concrete verdict reasons. Avoid expanding this into a testing handbook. Medium-high confidence because edit authorization needs human policy confirmation.

### ubiquitous-language
- Profile / disclosure: Routed artifact workflow; self-contained
- Authorities: Frontmatter triggers glossary creation or refinement; repository vocabulary contract is `specs/UBIQUITOUS_LANGUAGE.md`; spec placement and preamble status come from `specs/SPEC-OF-SPECS.md`; shared-skill contract comes from `specs/ai-agent-config.md`; repo-local provenance with no entry in `THIRD_PARTY_NOTICES.md`
- Baseline: 97 lines; 733 words; level-two headings: `Process`, `Output Format`, `Rules`, `Example dialogue`, `Re-running`; Markdown references: none
- Behavior ledger:
  - Language: “ubiquitous language,” “canonical term,” “alias to avoid,” and “flagged ambiguity” are **material Language Definition candidates requiring human confirmation**
  - Workflow/routing: determine whether creating or updating and locate the repository’s canonical glossary; scan conversation/specs/plans/code evidence; identify ambiguities, synonyms, and overloads; propose terms; write grouped tables, relationships, dialogue, and ambiguity section; summarize; on rerun merge new evidence and revise definitions/dialogue
  - Activities: none
  - Inline contracts: opinionated canonical choices; one-sentence definitions; domain-only inclusion; natural grouping; relationships/cardinality; 3–5-exchange dialogue; explicit conflicts
  - Reference: a detailed example could be conditional, but no new reference is necessary after deduplication
- YAGNI findings: The full output example already contains an example dialogue, followed by a second standalone dialogue example. More importantly, unconditional root `UBIQUITOUS_LANGUAGE.md` output conflicts with the repository’s canonical `specs/UBIQUITOUS_LANGUAGE.md` when refining this spec suite.
- Recommendation: **simplify inline**. Proposed shape—Language Definitions: define the four DDD/output terms; Workflow: route create versus update and select the existing canonical location first, then preserve one artifact-producing path; Activities: none; Reference: none. Keep one compact output schema and remove the duplicate dialogue illustration.
- Preservation and risk: Do not silently relocate glossaries in repositories with an established convention; location selection must be explicit. Preserve all domain-filtering and ambiguity rules. High confidence.

### update-specs
- Profile / disclosure: Artifact workflow; progressively disclosed
- Authorities: Frontmatter triggers spec synchronization after code or reasoning changes; spec structure/versioning authority is `specs/SPEC-OF-SPECS.md`; suite reading/dependency guidance is `specs/README.md`; terminology authority is `specs/UBIQUITOUS_LANGUAGE.md`; shared-skill contract is `specs/ai-agent-config.md`; supporting file: `shared/skills/update-specs/REFERENCE.md`; repo-local provenance with no entry in `THIRD_PARTY_NOTICES.md`
- Baseline: 71 lines; 444 words; level-two headings: `Quick Start`, `Workflow`, `Reasoning Gaps`, `Review Standard`, `Reference`; Markdown references: `REFERENCE.md`
- Behavior ledger:
  - Language: `coverage gap`, `violation`, `checklist drift`, `reasoning gap`, and `in-spec change` are existing **material Language Definition candidates requiring human confirmation**
  - Workflow/routing: require clean tree, explicit resolvable ref, and non-empty diff; read project and spec authority; classify discrepancies; present table and execution plan before edits; delegate when available or use equivalent in-process flow; run contract, cross-spec, and mechanical reviews; roll back partial edits on guardrail failure
  - Activities: none
  - Inline contracts: do not invent behavior; specs remain prescriptive and language-agnostic; update versions/changelogs; route terminology changes to the glossary; run shared-skill audit when skill behavior changes
  - Reference: full discrepancy definitions, delegation pattern, authoring rules, review checklists, and rollback procedure; load during classification and review
- YAGNI findings: Progressive disclosure already earns its indirection. The main file and reference intentionally overlap at summary/detail level; no substantial sediment is evident. The discrepancy definitions should have one semantic owner rather than being partially defined in both places.
- Recommendation: **retain**. Proposed shape—Language Definitions: place the five discrepancy classes in one compact authoritative definition set; Workflow: retain the full gated producer/reviewer sequence; Activities: none; Reference: retain detailed tables and checklists with explicit load points.
- Preservation and risk: Keep preflight gates, pre-edit plan, in-process fallback, all three reviews, rollback, spec versioning, and glossary routing. Required behavior must remain visible even if detailed checklists stay in `REFERENCE.md`. High confidence.

### video-to-contact-sheet
- Profile / disclosure: Artifact workflow; self-contained
- Authorities: Frontmatter triggers conversion of recordings into review evidence; shared-skill contract comes from `specs/ai-agent-config.md`; repo-local provenance with no entry in `THIRD_PARTY_NOTICES.md`; downstream router: `shared/skills/visual-qa/SKILL.md`
- Baseline: 73 lines; 429 words; level-two headings: `Inputs`, `Workflow`, `Review Rules`; Markdown references: none
- Behavior ledger:
  - Language: “contact sheet,” “focused evidence,” and “source evidence” are **material Language Definition candidates requiring human confirmation**
  - Workflow/routing: locate the video/evidence bundle; inspect nearby structured evidence; probe duration, size, streams, and audio; create overview; branch to trim when startup obscures action; branch to higher-frequency or cropped output for brief/small behavior; return artifacts to visual QA
  - Activities: overview contact sheet, trimmed clip/sheet, high-frequency sheet, and cropped sheet are independently selectable ffmpeg recipes
  - Inline contracts: do not mistake missing audio for a product bug; sheet must show meaningful behavior; escalate fighter-scale or motion issues to focused evidence; preserve raw video; preserve machine/visual mismatches
  - Reference: none
- YAGNI findings: The commands are legitimate reusable activities, not prose sediment. Output handoff is underspecified: the skill says to hand artifacts back but does not explicitly require reporting each resulting path and its purpose.
- Recommendation: **simplify inline**. Proposed shape—Language Definitions: define the evidence artifacts; Workflow: diagnose and select transformations; Activities: retain the four ffmpeg recipes with their local guardrails; Reference: none. Add only a compact output-path handoff contract, not a larger report schema.
- Preservation and risk: Preserve source video, evidence inspection, audio disclosure, trim/rebuild behavior, focused-crop escalation, and mismatch reporting. Keep this file compact rather than moving a few commands behind another document. High confidence.

### create-explainer
- Profile / disclosure: Routed artifact workflow; progressively disclosed
- Authorities: Frontmatter triggers codebase explainers and onboarding materials; shared-skill contract comes from `specs/ai-agent-config.md`; teaching composition is also referenced there; supporting Markdown is `shared/skills/create-explainer/REFERENCE.md` and `shared/skills/create-explainer/lab/README.md`; `shared/skills/create-explainer/EXAMPLES.md` was also inspected; repo-local provenance with no entry in `THIRD_PARTY_NOTICES.md`
- Baseline: 71 lines; 824 words; level-two headings: `Quick start`, `Output tiers`, `Core principles`, `Reviewer pass (mandatory)`, `Serving`; Markdown references: `REFERENCE.md` and `lab/README.md` with multiple anchors
- Behavior ledger:
  - Language: “output tier,” “source-grounded reviewer pass,” “claim checklist,” and “lab template” are **material Language Definition candidates requiring human confirmation**
  - Workflow/routing: collect or infer concept/persona/depth; route to Condensed, Guided, or Full Lab; obtain one scope checkpoint; discover source truth; draft the tier artifact; optionally delegate large Full Lab drafting; self-fix; obtain approval before reviewer delegation or review locally; correct findings; serve on a verified free port; visually validate appropriate tiers
  - Activities: lab-template selection and browser validation are reusable operations, but they serve the artifact workflow
  - Inline contracts: source-first claims; persona adaptation; server/state ownership; self-contained output; no external dependencies; mandatory reviewer pass; user approval before reviewer delegation; port identity verification; responsive/expanded-state checks; temporary screenshot location
  - Reference: intake, persona matrix, tier structures, delegation, review checklists, serving, visual validation, HTML/JS patterns, and lab selection
- YAGNI findings: Main and reference duplicate tier, reviewer, serving, and validation guidance. They also conflict: the main file says generated files should never be in the explainer folder while the reference creates the explainer there; main requires Playwright validation before serving, while the reference serves first and calls validation recommended/optional for smaller tiers. The reference contains extensive hand-built browser-validation and component guidance that overlaps `playwright`, `visual-qa`, and reusable lab assets; ownership is deferred to WF-006.
- Recommendation: **simplify inline**. Proposed shape—Language Definitions: define tiers, reviewer pass, and lab template; Workflow: route tier immediately after intake, retain scope approval and one ordered producer/reviewer/serve/validate path; Activities: none in the main skill; Reference: retain conditional persona, tier, lab, review, and implementation details after reconciling contradictions and removing duplicate summaries.
- Preservation and risk: Mandatory factual review, approval before reviewer delegation, source discovery, artifact shapes, free-port verification, and responsive checks must survive. Clarify that explainer source files may live in the chosen explainer directory while screenshots and transient validation artifacts remain temporary. High confidence.

### em-train
- Profile / disclosure: Artifact workflow; overloaded
- Authorities: Frontmatter triggers real-codebase training; shared-skill and runtime rules come from `specs/ai-agent-config.md`; supporting file: `shared/skills/em-train/REFERENCE.md`; composed workflow: `shared/skills/create-explainer/SKILL.md`; repo-local provenance with no entry in `THIRD_PARTY_NOTICES.md`
- Baseline: 39 lines; 324 words; level-two headings: `Quick start`, `Core principles`, `Workflows`; Markdown references: `REFERENCE.md` and its lifecycle anchors
- Behavior ledger:
  - Language: “training ticket,” “temporary guidance skill,” “no-spoiler rule,” and “review round” are **material Language Definition candidates requiring human confirmation**
  - Workflow/routing: interview for goal/level/role/time/knowledge; inspect plans/specs/history; negotiate a real right-sized ticket; generate ticket and explainer; create training branch and temporary guidance artifacts; user implements; run CI and delegated review; curate 2–3 educational findings; iterate within the round cap; produce report; remove temporary skill; offer merge
  - Activities: none
  - Inline contracts: guidance never supplies implementation; examples must come from existing code; one scope checkpoint; real CI; honest failures; no Round-1 rubber stamp; capped review rounds; cleanup temporary runtime artifacts; branch remains unless user chooses otherwise
  - Reference: detailed lifecycle and temporary-skill template
- YAGNI findings: `REFERENCE.md` duplicates a large portion of `create-explainer`, including persona mapping, HTML conventions, lab selection, serving, and review. It weakens the composed skill’s mandatory reviewer pass to optional, creating behavioral drift. It also embeds generic review-agent routing rather than preserving only training-specific feedback curation.
- Recommendation: **consolidate/delegate**. Proposed shape—Language Definitions: define training-specific artifacts and no-spoiler behavior; Workflow: retain the complete EM lifecycle and explicitly invoke `create-explainer` for explainer production/review instead of copying it; Activities: none; Reference: keep only ticket schema, training setup, guidance template, review-round rules, session report, and cleanup.
- Preservation and risk: Preserve user ticket negotiation, no spoilers, real CI, educational feedback curation, round cap, branch ownership, temp-skill cleanup, and merge choice. Candidate owners for explainer and generic review mechanics must be confirmed in WF-006 before implementation. High confidence.

### prototype
- Profile / disclosure: Routed workflow; progressively disclosed
- Authorities: Frontmatter routes state/business-logic questions versus visual-design questions; supporting files are `shared/skills/prototype/LOGIC.md` and `shared/skills/prototype/UI.md`; adapted provenance and MIT attribution are recorded in `THIRD_PARTY_NOTICES.md`; shared-skill contract comes from `specs/ai-agent-config.md`
- Baseline: 33 lines; 562 words; level-two headings: `Pick a branch`, `Rules that apply to both`, `When done`; Markdown references: `LOGIC.md`, `UI.md`
- Behavior ledger:
  - Language: “prototype,” “logic prototype,” “UI variant,” and “durable answer” are **material Language Definition candidates requiring human confirmation**
  - Workflow/routing: identify the question first; route logic/state to `LOGIC.md` or appearance to `UI.md`; if ambiguity cannot be resolved, infer from surrounding code and state the assumption; execute the chosen branch; record question, verdict, evidence, and implications; delete, absorb, or exceptionally preserve on a throwaway branch
  - Activities: none in the router
  - Inline contracts: clearly mark throwaway code; one run command; no persistence by default; no production polish; expose state; capture the answer before cleanup; preserve code only when prose/screenshots/implementation cannot preserve primary evidence
  - Reference: load `LOGIC.md` only for state/business-logic questions; load `UI.md` only for visual questions
- YAGNI findings: This is strong progressive disclosure with routing first and a compact main file. A material tension remains: the shared rules call code throwaway and untested, while `LOGIC.md` says the pure logic module “shouldn’t be” throwaway and may be lifted into production; `UI.md` instead requires rewriting prototype code before production.
- Recommendation: **simplify inline**. Proposed shape—Language Definitions: define the prototype and durable-answer boundary; Workflow: retain routing first, common guardrails, and cleanup; Activities: none; Reference: retain the two conditional branch documents, aligning both on whether validated code may be absorbed or must be rewritten.
- Preservation and risk: Do not merge the branches or copy their detail into the compact router. Preserve one-command execution, no-persistence default, state visibility, explicit assumptions, durable conclusion, cleanup, provenance, and license. Human confirmation is needed on production promotion semantics. High confidence.

### tmux-agent-orchestration
- Profile / disclosure: Ordered workflow; overloaded
- Authorities: Frontmatter explicitly triggers tmux-based multi-agent orchestration; tmux remains a repository fallback under `AGENTS.md`, while Herdr is the default; shared delegation/isolation rules come from `specs/ai-agent-config.md`; supporting file: `shared/skills/tmux-agent-orchestration/REFERENCE.md`; repo-local provenance with no entry in `THIRD_PARTY_NOTICES.md`
- Baseline: 58 lines; 438 words; level-two headings: `Quick Start`, `First Question`, `Core Rules`, `Workflow`; Markdown references: `REFERENCE.md`
- Behavior ledger:
  - Language: “worker clone,” “orchestration session,” “TUI steering,” and “prompt submission” are **material Language Definition candidates requiring human confirmation**
  - Workflow/routing: ask which CLI unless supplied; inspect exact CLI command shape; create one clone per worker; launch deterministic tmux session/windows with complete prompts; monitor pane and Git state; steer with explicit Enter/C-m and verify activity; inspect PR mergeability before refresh; follow CI until green; clean session and clone bundle
  - Activities: launch, steer, monitor, PR follow-through, merge-drift recovery, and cleanup are independently reusable operations
  - Inline contracts: isolated editable workers; no assumed CLI flags; visible pasted text is not submission; verify clone path/branch/remote; clean PR branches; “fix pushed” is not done; preserve unrelated sessions; verify cleanup
  - Reference: commands, failure modes, PR/CI patterns, and monitoring checklist
- YAGNI findings: Tmux-specific launch, steering, monitoring, and cleanup earn retention. The reference has accumulated broad PR construction, CI remediation, merge-conflict semantics, semantic-drift review, and anecdotal cleanup checks that overlap other workflow owners and obscure the tmux seam. Catalog-wide ownership remains for WF-006.
- Recommendation: **consolidate/delegate**. Proposed shape—Language Definitions: define the tmux orchestration terms; Workflow: retain CLI selection and the end-to-end tmux lifecycle; Activities: expose launch, verified steering, monitoring, and cleanup; Reference: keep tmux command recipes and tmux-specific failures, while routing generic PR, CI, review, and conflict work to confirmed owners.
- Preservation and risk: Never remove clone isolation, submission verification, command-shape inspection, mergeability checks before stale-PR work, CI completion evidence, or scoped cleanup. Do not retire the skill merely because Herdr is the default; tmux is still an explicit fallback. Medium-high confidence pending WF-006 ownership.

### visual-qa
- Profile / disclosure: Routed artifact workflow; self-contained
- Authorities: Frontmatter triggers browser/app/recording visual QA; related routers and producers are `shared/skills/playwright/SKILL.md` and `shared/skills/video-to-contact-sheet/SKILL.md`; shared-skill contract comes from `specs/ai-agent-config.md`; repo-local provenance with no entry in `THIRD_PARTY_NOTICES.md`
- Baseline: 61 lines; 480 words; level-two headings: `Routing`, `Workflow`, `Checklist-Based QA (Orchestrated)`; Markdown references: none
- Behavior ledger:
  - Language: “human-visible result,” “evidence surface,” “runtime context,” and “artifact limitation” are **material Language Definition candidates requiring human confirmation**
  - Workflow/routing: first choose orchestrated checklist mode versus ad hoc QA; identify the human question; route to Playwright, available browser control, or video conversion according to surface and authentication needs; choose still/multi-viewport/motion evidence; gather console/network/scenario context; escalate when stills are untrustworthy; report in human terms
  - Activities: ad hoc visual investigation and execution of an orchestrator-provided checklist are distinct selectable modes within one routed workflow
  - Inline contracts: trust visible complaints over conflicting machine evidence; distinguish product failure, capture setup, and artifact limitation; verify each checklist action; capture failed-step evidence; report per-step PASS/FAIL plus final verdict and console/network status
  - Reference: none currently warranted
- YAGNI findings: Tool routing appears before the general workflow, but orchestrated-mode routing appears after it under a separate top-level section. Some named browser routes are runtime-specific and may be unavailable; availability must be checked rather than assumed. The skill remains compact enough to stay self-contained.
- Recommendation: **simplify inline**. Proposed shape—Language Definitions: define evidence and artifact-limit terms; Workflow: route orchestrated versus ad hoc mode first, then select the available evidence tool and execute the chosen branch; Activities: retain checklist execution as an independently selected activity only if the mode distinction remains explicit; Reference: none.
- Preservation and risk: Keep human-question-first framing, motion escalation, console/network context, machine/visual mismatch handling, per-step evidence, and final verdict. Do not add browser-tool manuals or duplicate `video-to-contact-sheet`. High confidence.

**Coverage count: 16/16 assigned skills audited exactly once.**
