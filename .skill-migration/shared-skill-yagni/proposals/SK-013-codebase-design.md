---
id: SK-013
target: codebase-design
status: verified
blocked-by: [SK-001]
source-verdict: retain
---

# Codebase Design: retain substance and route design mode first

## Why this item is next

SK-001 is verified and owns the canonical skill-body contract, so SK-013 is unblocked in the D4 direct-normalization sequence. The item is claimed at baseline `48cc537d21d8f4f1d12641c197568a2ac327bfda`; its exact file set is disjoint from the concurrently claimed SK-014.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` fixes a preserve-before-prune destination and excludes frontmatter redesign, deployment, and Pi visibility changes.
- WF-007 assigns `codebase-design` the **retain** verdict: preserve vocabulary, design tests, and both conditional references while moving direct-design, deepening, and Design It Twice route selection to the Workflow opening. Repository glossary language wins on overlap.
- The complete WF-003 target record supplies the behavior ledger: inspect specs/glossary/requirements/code; state owned capability and constraints; place seams and classify dependencies; compare alternatives by depth, locality, leverage, errors, and test surface; recommend one; route durable invariants to their owning spec or plan; and finish with the learned interface, hidden implementation, seams/adapters, and verification. It also requires the deletion test, interface-as-test-surface rule, real-variation adapter threshold, consequential-interface alternative gate, and both support branches.
- WF-008 confirms the exact definitions of Module, Interface, Implementation, Depth, Seam, Adapter, Leverage, and Locality. It distinguishes a seam from a DDD boundary and leaves project-domain vocabulary with the applicable project glossary.
- WF-006 makes `codebase-design` the owner of general architecture vocabulary. It preserves local design gates, requires in-process fallback when Herdr is unavailable, permits read-only delegates to share a checkout, and requires isolated checkouts for future editing delegates.
- `specs/ai-agent-config.md` 2.3.0 names this skill as the owner of deep-module vocabulary and progressively disclosed deepening/alternative-interface guidance. It requires canonical section order, routing first, local gates and completion, behavior-preservation coverage, transport fallback, and isolation before transport. `specs/UBIQUITOUS_LANGUAGE.md` 0.7.0 is authoritative for project terms and leaves skill-local definitions in the owning body; `specs/DESIGN_LANGUAGE.md` has no conflicting architecture vocabulary.
- Verified `shared/skills/write-a-skill/SKILL.md` requires a behavior-preservation ledger, one routed Workflow, conditional Reference pointers, checkable steps, semantic YAGNI, and provenance verification.
- The complete target and both support files are coherent. `DEEPENING.md` owns four dependency categories, the internal-seam/test rule, a six-step consolidation pass, and its completion evidence. `DESIGN-IT-TWICE.md` owns framing, at least three complete independent alternatives, optional adapter-led design, Herdr/read-only versus in-process parity, editing isolation, comparison, and a falsifiable recommendation. No support-file correction or move is warranted.
- Git history shows the target and support files were introduced together at local commit `3b59c13906d5d7922ed236b19cfe548138f429d7`. `THIRD_PARTY_NOTICES.md` records `codebase-design` as a locally maintained adaptation of `mattpocock/skills` revision `66898f60e8c744e269f8ce06c2b2b99ce7660d5f` under the reproduced MIT license. Attribution is complete and unchanged.
- Installed `herdr --help` confirms a current Herdr executable and agent/tab/pane command families. This item changes no executable syntax: the support contract composes the `herdr` skill rather than copying commands.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-013-codebase-design.md` — item-local authorization, behavior ledger, checks, and final worker state.
- `shared/skills/codebase-design/SKILL.md` — add confirmed definitions and normalize routing, principles, design pass, and pointers into the canonical body.

`shared/skills/codebase-design/DEEPENING.md` and `shared/skills/codebase-design/DESIGN-IT-TWICE.md` are verification-only support files and remain unchanged. No spec, notice, history, test, deployment, visibility, or settings file is authorized.

## Proposed changes

### Add

- Add `Language Definitions` containing all eight exact WF-008 architecture definitions. Retain the current deep-versus-shallow explanation and the `seam`/DDD-boundary distinction as execution consequences of those definitions.
- Open `Workflow` by selecting exactly one initial route, with composable support when triggers overlap:
  - Design It Twice for a consequential interface or requested alternatives; load Deepening too when consolidation or dependency classification also applies.
  - Deepening for consolidation or dependency classification when Design It Twice is not required.
  - Direct design otherwise.
- Give each routed design the existing evidence, design-test, comparison, recommendation, durable-owner, and completion gates inline.

### Change or move

- Rename `Vocabulary` to `Language Definitions` and replace wording with the human-confirmed definitions without changing the established architecture concepts.
- Fold `Principles`, `Design pass`, and route selection into one `Workflow`, placing each principle beside design evaluation rather than leaving a separate noncanonical section.
- Move the two existing conditional links into `Reference` and state why each support file must be loaded. The support documents retain ownership of their branch details.
- Preserve frontmatter byte-for-byte; all current invocation triggers and least-privilege `read,bash` grants remain.

### Remove

- Remove only the standalone introductory summary and old level-two headings after their unique substance is retained in definitions, Workflow goals/tests, and Reference pointers.
- Remove no route, principle, threshold, support contract, output, ownership rule, or completion condition.

## Proposed skill shape

1. `Language Definitions` — all eight confirmed architecture terms, deep/shallow consequence, project-glossary precedence, and seam/DDD distinction.
2. `Workflow` — present; route direct design versus Deepening versus Design It Twice first, then run one evidence-backed design pass with all design tests, output ownership, and completion evidence.
3. `Activities` — omitted; direct design and both support branches are modes of the required design process, not independently selected recipes.
4. `Reference` — present; conditional pointers to Deepening for consolidation/dependency classification and Design It Twice for consequential/requested alternatives.

## Behavior-preservation checklist

- [x] Invocation retains interface design/improvement, seam choice, module-shape comparison, testability improvement, and architecture-guidance composition triggers.
- [x] Module, Interface, Implementation, Depth, Seam, Adapter, Leverage, and Locality retain their complete human-confirmed meanings.
- [x] Project glossary terms remain authoritative, while `codebase-design` remains the owner of general architecture vocabulary.
- [x] Deep-module goals retain caller leverage, maintainer locality, hidden implementation, and tests resilient to implementation changes.
- [x] Direct design, consolidation/dependency deepening, and consequential/requested-alternative design are all reachable from routing at the Workflow opening; overlapping deepening and alternative triggers compose both supports.
- [x] Every route begins from relevant specs, glossary, requirements, and nearby code and states the domain capability and constraints the module owns.
- [x] Depth remains an interface property; private implementation seams need not become caller-visible.
- [x] The deletion test still distinguishes an earning module from pass-through indirection.
- [x] Callers and behavior tests still cross the same interface, and internal seams are not exposed merely for testing.
- [x] The adapter threshold remains: variation must be real, one adapter is usually hypothetical, and production plus a justified test adapter is a valid pair.
- [x] Consequential interfaces still require meaningfully different alternatives rather than treating Design It Twice as optional.
- [x] Every design compares depth, locality, leverage, errors, and test surface before recommendation.
- [x] The main completion output still names the caller-learned interface, hidden implementation, seam locations, justified adapters, and behavior verification.
- [x] Durable invariants still go to the spec or plan that owns them; composition does not transfer caller ownership.
- [x] Deepening retains all four dependency categories and their verification consequences: in-process, local-substitutable, remote-but-owned, and true external.
- [x] Deepening retains the six-step consolidation path, replacement of obsolete shallow-interface tests, deletion after green, and locality/leverage/behavior-test completion.
- [x] Design It Twice retains framing of capability, constraints, categories, invariants, errors, ordering, and friction before proposals.
- [x] Design It Twice retains at least three genuinely independent complete interfaces: minimal, flexible, and common-path, plus adapter-led when a real remote/external seam dominates.
- [x] Every alternative still includes the complete interface/invariants/errors, representative caller, hidden implementation, seam/adapters, testing, and depth/leverage/locality trade-offs.
- [x] Under `HERDR_ENV=1`, Design It Twice still loads `herdr` and prefers parallel read-only agents that may share the checkout; otherwise it completes alternatives independently in-process before comparison.
- [x] Any future editing delegate still requires an isolated clone or worktree; terminal separation alone does not transfer workflow ownership or provide isolation.
- [x] Alternative comparison retains depth, locality, leverage, seam placement, common-path ergonomics, migration cost, and a falsifiable recommendation or precise hybrid.
- [x] Existing support links remain resolving and provenance/license coverage remains intact.

## Dependencies, provenance, and risks

- SK-001 is verified at the claimed baseline, and no unfinished owner decision blocks this retain migration. SK-022 and SK-025 consume this final architecture/seam ownership only after SK-013 is verified.
- No live contradiction exists among the current skill, supports, WF-008 definitions, or specs. The wording normalization uses the exact confirmed definitions and does not alter the adapter threshold or support modes.
- Route precedence protects the consequential-interface gate: Design It Twice wins when required, while Deepening is additionally loaded if dependency classification or consolidation also applies. The direct route is used only when neither specialized trigger applies.
- The two support files remain required progressive disclosure, not optional advice. Their compact executable contracts remain discoverable from `Reference` and unchanged.
- Provenance is already complete in `THIRD_PARTY_NOTICES.md`; changing that notice would exceed scope and duplicate no missing attribution.
- No executable command changes. The only environment-sensitive behavior delegates current command mechanics to the `herdr` skill and retains an in-process fallback.

## Verification

- Reread the complete resulting `SKILL.md`, `DEEPENING.md`, and `DESIGN-IT-TWICE.md` against the WF-003 ledger and exact WF-008 definitions — every checklist item has a retained inline or support-owned location.
- Inspect level-two headings — exactly `Language Definitions`, `Workflow`, then `Reference`; no unapproved section or Activity exists.
- Resolve every relative Markdown link one level deep and verify reciprocal support links — all three files exist and links remain local to the skill.
- Run a PyYAML-based complete union-frontmatter audit over every `shared/skills/*/SKILL.md` and compare with baseline `48cc537d21d8f4f1d12641c197568a2ac327bfda` — all files parse, the target is clean, and this item introduces no catalog finding.
- `herdr --help` — current executable help remains compatible with the unchanged Herdr composition contract; no copied syntax is introduced.
- `test -L pi/skills/codebase-design && test "$(readlink pi/skills/codebase-design)" = '../../shared/skills/codebase-design' && test -f pi/skills/codebase-design/SKILL.md` — Pi visibility remains the unchanged resolving symlink.
- Inspect target/support Git history and `THIRD_PARTY_NOTICES.md` — the recorded upstream revision and MIT attribution remain complete without a notice edit.
- `git diff --name-status 48cc537d21d8f4f1d12641c197568a2ac327bfda --` plus scoped diff inspection — only this proposal and target differ; protected and unrelated paths do not change.
- `git diff --check` — no whitespace errors.
- `bash tests/run.sh` — repository shell tests pass.
- `git status --short` after commit — worktree is clean.

## Implementation and verification record

- Worker verification timestamp: `2026-07-14T17:18:03+00:00`.
- Exact scope: PASS. Relative to baseline `48cc537d21d8f4f1d12641c197568a2ac327bfda`, only this proposal and `shared/skills/codebase-design/SKILL.md` differ. Protected paths, including the migration ledger, specs, notices, support files, tests, deployment, all Pi paths, `pi/settings.json`, AGENTS, and Wayfinder records, are unchanged.
- Complete-file and preservation review: PASS. The resulting target and both unchanged support files preserve every WF-003 trigger, route, design test, output, ownership boundary, support branch, and completion gate. Route selection is first; consequential/requested alternatives select Design It Twice, overlapping consolidation/dependency work additionally selects Deepening, and direct design remains the fallback.
- Canonical shape and language: PASS. Level-two headings are exactly `Language Definitions`, `Workflow`, and `Reference`; no Activity is invented. All eight WF-008 definitions are present, with project-glossary precedence and the deep/shallow and seam/DDD distinctions retained.
- Architecture tests and output: PASS. The deletion test, interface-as-test-surface rule, no internal test seam, two-adapter threshold, meaningfully different consequential alternatives, comparison axes, durable-owner route, and explicit recommendation completion evidence remain inline.
- Deepening support: PASS. All four dependency categories, real-variation rule, six-step consolidation path, green deletion gate, and locality/leverage/behavior-test completion remain reachable through a mandatory conditional pointer.
- Design It Twice support: PASS. Framing, three required independent alternatives, optional adapter-led alternative, complete-alternative fields, Herdr read-only/direct fallback parity, editing isolation, comparison axes, and falsifiable recommendation remain reachable through a mandatory conditional pointer.
- Links and visibility: PASS. All relative Markdown links across the three complete files resolve one level deep, reciprocal links remain valid, and `pi/skills/codebase-design` still resolves through `../../shared/skills/codebase-design`.
- Baseline-aware union audit: PASS. PyYAML parsed all 33 baseline and all 33 current skill frontmatters; both report zero errors and zero warnings, with no finding delta. Target `read,bash` grants remain used for source/spec reading and code/history/search inspection; no frontmatter bytes changed.
- Provenance/history/help: PASS. The target/support introduction commit remains `3b59c13906d5d7922ed236b19cfe548138f429d7`; the existing Matt Pocock revision and reproduced MIT license remain complete in `THIRD_PARTY_NOTICES.md`. Installed `herdr --help` confirms current Herdr command families; no executable syntax is copied or changed.
- Repository checks: PASS. `git diff --check` is clean and `bash tests/run.sh` passes 2 shell files and all 12 tests.
- Resulting target SHA-256: `121962348d6feef5d696473a06703cd91a04a835f047ac4662ba33d90b956c3b`.
- Residual risk: none beyond the deliberate progressive-disclosure dependency on the two unchanged local support files; link and complete-contract checks passed.

## Integrated verification

- Coordinator verification timestamp: `2026-07-14T17:20:08+00:00`.
- Exact scope, complete target and support review, canonical shape, eight definitions, route precedence, design tests, support links, and provenance passed independent review.
- Repository shell tests passed 12/12; `git diff --check` and Pi visibility passed; `pi/settings.json` retained its recorded hashes and remained unstaged.

## Explicit exclusions

- No edits to `.skill-migration/shared-skill-yagni/MIGRATION.md`, `.wayfinder/`, specs/glossaries, `THIRD_PARTY_NOTICES.md`, `AGENTS.md`, tests, scripts, install/deployment files, agent config/discovery, Pi visibility links, `pi/settings.json`, support files, unrelated skills, or unrelated proposals.
- No frontmatter/schema/grant redesign, new architecture term, changed adapter threshold, support-file extraction, executable helper, implementation design for a particular codebase, or fixed line-count target.
- No change to Herdr command mechanics, parallelism policy, isolation policy, or caller ownership.
- No claim that this worker performs coordinator integration or central verification.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Authorization revision: standing directive applied to proposal revision 1 and only the exact two-file set above.
- Scope check: `PASS — MAP → WF-007 → complete WF-003 target record → WF-008 → WF-006 → current specs/glossaries → verified write-a-skill → complete target/support files → provenance/notices/history → executable help were read in order; exact files, complete behavior ledger, routing precedence, ownership, contradiction review, provenance/license coverage, exclusions, and verification criteria were checked. Production editing may continue autonomously under the standing directive.`
