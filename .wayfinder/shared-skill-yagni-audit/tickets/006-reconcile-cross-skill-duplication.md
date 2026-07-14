---
id: WF-006
type: research
status: resolved
blocked-by: [WF-008]
---

# Reconcile cross-skill duplication and composition

## Question
Which repeated instructions should have one durable owner, and which apparent duplication is necessary local context for reliable execution?

## Why it matters
Per-file shortening can merely move duplication between skills or create brittle dependency chains unless ownership and composition boundaries are reviewed across the catalog.

## Completion evidence
Repeated Quick Starts, delegation mechanics, output templates, visual-review roles, test-review routing, and other clusters found by the audits are assigned one of: retain locally, delegate to an existing skill, move to shared Reference material, consolidate, or split into an independently invocable skill. Every proposed dependency remains discoverable and does not hide required main-path behavior.

## Resolution
Three independent read-only investigations covered orchestration/state, visual/review workflows, and authoring/artifact structure. The parent reconciled them against every resolved family audit and the human-confirmed language in WF-008.

### Ownership matrix

| Cluster | Durable owner | Minimum local context consumers retain | Disposition |
|---|---|---|---|
| Four-section body design, progressive disclosure, split tests, and YAGNI pruning | `write-a-skill` | Only a pointer when another workflow authors or materially rewrites a skill | Consolidate in owner |
| Repository frontmatter, isolation, state-workspace, and provenance policy | `specs/ai-agent-config.md` and `AGENTS.md` | The concrete gate applying at the consumer’s current step | Reference policy; do not copy full rules |
| Executable union-frontmatter validation | `audit-shared-skills` | Approved fix mode and repository audit command | Retain; do not misrepresent it as semantic/YAGNI review |
| Quick Starts | The owning skill’s Workflow opening; `playwright` may keep one minimal Activity | First route, required input, failure gate, and next step | Consolidate repeated summaries; no catalog-wide Quick Start section |
| Completion criteria | Each producing Workflow step or Activity | Observable finish and evidence at the point it gates | Retain locally; never move completion behind optional wording |
| Large templates and schemas | The producing skill’s owner-local Reference | Artifact path, ownership, approval/overwrite gate, and mandatory load condition | Move only literal/detail-heavy forms; retain compact contracts inline |
| Extended examples | The behavior owner | One inline example only when it disambiguates a required rule; otherwise a conditional pointer | Retain earned examples, link Bootstrap examples conditionally, retire duplicated `create-explainer/EXAMPLES.md` |
| Workflow-level delegation and editable isolation | `specs/ai-agent-config.md` for universal policy; caller for domain brief | Why delegate, read-only/editable classification, returned evidence, durable writer, and full in-process fallback | Consolidate mechanics by pointer while retaining local authority boundaries |
| Herdr terminal operations | `herdr` | `HERDR_ENV=1` trigger, caller-owned task/result, live-ID refresh, and in-process fallback | Consolidate all command syntax and split/run/read/wait recipes in owner |
| Tmux terminal/TUI operations | `tmux-agent-orchestration` | Explicit tmux selection, worker/task, editing authority, and expected result | Retain tmux launch/steer/monitor/cleanup; split generic delivery material |
| Read-only versus editable checkout topology | `specs/ai-agent-config.md`; `create-plan` owns plan-specific lifecycle | Each delegation gate states read-only/share or editable/isolate and authorized scope | Consolidate universal binary rule; retain one local sentence |
| Parent and durable state ownership | `specs/ai-agent-config.md` registry plus each stateful skill’s format files | Sole writer, delegate return channel, durable identity, and recovery rule | Retain at governing transitions; remove only duplicate restatements |
| Wayfinder, implementation plans, spec-extraction plans, and Ralph job plans | `wayfinder`, `create-plan`, `bootstrap-specs`, and `ralph` respectively; relationship governed by `specs/ai-agent-config.md` | Reciprocal initial routing and explicit artifact qualification | Keep workflows separate; never treat tickets/job plans/extraction plans as slices or plan workspaces |
| Research, prototype, and grilling processes | `research`, `prototype`, and `grill-me`; Wayfinder owns ticket-type dispatch | Caller question, tighter constraints, return contract, and durable destination | Delegate process without importing the composed skill’s default ownership accidentally |
| Generic fixed-point Standards/Spec review | `code-review` | When review runs, fixed point, specialist passes, recorder, and state-changing verdict | Consolidate generic axis semantics; retain specialist review contracts |
| TDD and test-quality review | `tdd` for test-first production; `test-quality-verifier` for assertion/coverage audit | Requested mode, behavior/seam/command or audit scope/thresholds | Keep distinct; risk/request-route test-quality review rather than run it on every TDD cycle |
| Browser command syntax and browser capture | `playwright` | Scenario, viewport/state, evidence checks, cleanup, and sensitive-state constraints | Move copied command mechanics to Playwright-owned references; callers own what to verify |
| Recording conversion | `video-to-contact-sheet` | Source path, intended moment, audio expectation, and returned artifact paths/limitations | Keep ffmpeg/ffprobe activities in owner; capture remains with active browser/tool owner |
| Neutral visual evidence | `image-diff-describer` | Paths and comparison scope; withhold criteria | Retain independent no-verdict contract inline |
| General visible-result QA | `visual-qa` | Human question, evidence surface, runtime context, and motion/still needs | Retain tool-agnostic routing and interpretation |
| Strict reference/candidate verdict | `image-comparison-judge` | Criteria, forbidden elements, comparison surface, and neutral diff when available | Retain scoped PASS/FAIL; never claim final human acceptance |
| Explainer production and factual review | `create-explainer` | Caller-specific persona, destination, mission/no-spoiler constraints, and reviewed artifact return | `teach` and `em-train` compose it; remove copied/weakening behavior from EM Train |
| Output/report contracts | Each producer/reviewer | Scope, evidence paths, context, limitations, result authority, and next owner | Retain locally; do not invent a universal PASS/FAIL or report template |
| Project language and spec form | Applicable project glossary and target `SPEC-OF-SPECS`; `ubiquitous-language` and `update-specs` own their workflows | Authority location, conflict handling, and route when terms/specs change | Delegate ongoing terminology; distinguish seed templates from live authority |
| Ranking models and checklists | Their domain workflow owner | Selection gate, failed-item consequence, and completion evidence | Keep domain-specific; move only long inventories to owner-local References |
| Provenance and licensing | `THIRD_PARTY_NOTICES.md`, governed by `specs/ai-agent-config.md` | Authoring gate to identify source/revision/license | Centralize legal text; do not duplicate it in skill bodies |

### Composition boundaries

1. **Transport is not orchestration policy.** `herdr` and tmux own terminal mechanics. Callers own briefs, state, acceptance, and whether parallelism helps.
2. **Isolation is selected before transport.** Separate panes are not separate checkouts. Read-only delegates may share; editors require an isolated worktree or clone.
3. **State ownership remains workflow-specific.** Wayfinder tickets, plan verification artifacts, Ralph job plans, teaching state, and generated artifacts intentionally have different writers and transitions.
4. **Generic review has a narrow seam.** `code-review` owns fixed-point scope and independent Standards/Spec semantics. Test quality, explainer facts, spec cross-integrity, neutral visual differences, visual acceptance, and pedagogical curation remain specialist contracts.
5. **Visual work is a pipeline, not one reviewer:** `playwright` or another capture owner → `video-to-contact-sheet` when conversion is needed → `image-diff-describer` for neutral comparison evidence → `visual-qa` for general interpretation or `image-comparison-judge` for strict scoped comparison → human/caller acceptance.
6. **Composition imports process, not ownership.** Teach and EM Train may compose Create Explainer; Wayfinder may compose Research, Prototype, or Grill Me; the caller retains its artifact location, user gates, and return criteria.
7. **Format diversity is intentional.** Normalize authority and handoff fields, not every report into one schema.

### Independently invocable split justified

The strongest new-skill candidate is a **generic Git delivery workflow** for opening/updating pull requests, following CI to green, refreshing stale branches, and verifying pushed heads. This behavior currently lives inside `tmux-agent-orchestration/REFERENCE.md` despite being useful without tmux. No current skill correctly owns it.

A future Git-delivery owner should delegate in-progress conflict intent to `resolving-merge-conflicts` and independent diff assessment to `code-review`. Tmux retains only worker identity, TUI steering, monitoring, and scoped cleanup. `create-plan` retains its plan-specific parent cherry-pick and integration lifecycle. This split has an independently useful trigger and therefore passes the `write-a-skill` split test; implementation remains out of scope until WF-007 routes it.

### Contradictions that must be repaired before moving text

- **Herdr:** caller versus focused pane and opaque versus legacy ID semantics; unsafe static-ID recipes; missing destructive-operation ownership guards.
- **Playwright:** stale `network` and `run-code --file` syntax, mismatched allowed commands, copied command manuals, and missing provenance.
- **Create Explainer:** main/reference disagreement on serving versus validation order, tier requirements, and durable source versus temporary screenshot locations.
- **EM Train:** copied explainer behavior weakens mandatory factual review; nonexistent generic reviewer names; two-versus-three review-round conflict.
- **Test Quality Verifier:** audit trigger always enters editing behavior and relies on non-portable role naming.
- **Bootstrap Specs:** pre-generation approval conflicts with post-generation structural correction; brownfield extraction `PLAN.md` is not qualified; glossary rerun/overwrite semantics are unsafe.
- **Update Specs:** advertised command/range shape does not match a real executable/ref contract; direct terminology edits conflict with `ubiquitous-language` ownership; delegated editing lacks explicit isolation/writer authority.
- **Ralph:** unlimited runner default conflicts with 25, sentinel matching is not exact, failures continue, commit claims are unenforced, dangerous sandbox lacks approval, and the runner lacks an executable setup path.
- **Prototype:** branch references must converge on WF-008’s throwaway-by-default and deliberate verified absorption rule.
- **Ubiquitous Language:** canonical glossary location must follow repository authority rather than always creating a root file.
- **Provenance:** known Grill Me, Herdr, and Playwright adaptations are absent from `THIRD_PARTY_NOTICES.md`.

### Migration order

1. Update durable specifications and language ownership, including artifact qualification and central provenance obligations.
2. Update `write-a-skill` with the confirmed four-section contract before using it to restructure the catalog.
3. Repair behavioral and command contradictions before relocating any text.
4. Establish explicit composition pointers and verdict scopes in main skill bodies.
5. Migrate overloaded detail into owner-local References for Curator, Create AGENTS, Playwright, EM Train, and Tmux.
6. Consolidate Quick Starts, repeated checklists, orphaned examples, and duplicate guardrails only after their behavior ledgers are rechecked.
7. Add the independently invocable Git-delivery owner and reciprocal pointers only through a later approved implementation plan.
8. Validate links, executable support, frontmatter, provenance, composition fallbacks, and all 33 behavior ledgers catalog-wide.

Evidence: `/tmp/wf006-orchestration.md`, `/tmp/wf006-review.md`, and `/tmp/wf006-authoring.md` were independent source-backed investigations. Together they inspected all 33 skills, 36 supporting Markdown files, relevant scripts/command surfaces, applicable specs, and the resolved Wayfinder audit state. No production skill behavior was changed.
