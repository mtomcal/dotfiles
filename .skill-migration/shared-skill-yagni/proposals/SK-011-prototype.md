---
id: SK-011
target: prototype
status: ready-to-integrate
blocked-by: [SK-001]
source-verdict: simplify inline
---

# Prototype: simplify the router and align deliberate absorption

## Why this item is next

SK-001 is verified at baseline `6133d8b61f937b490ede7905c4ebfdd5702c53f5`, so the authoring contract blocks no further work on this claimed item. WF-007 places `prototype` in direct normalization after contradiction repair. Its target and two owner-local branch references are disjoint from the concurrently claimed SK-009 files.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` fixes the destination and excludes frontmatter redesign, deployment changes, and Pi visibility changes.
- WF-007 assigns `prototype` the **simplify inline** verdict and requires both branch references to use throwaway-by-default behavior with deliberate production absorption through normal implementation and verification.
- The complete WF-005 `prototype` record supplies the preservation ledger: route logic/state questions to `LOGIC.md`, appearance questions to `UI.md`, infer and disclose an assumption only when ambiguity cannot be resolved, retain one-command execution, no persistence by default, state visibility, durable conclusions, cleanup, provenance, and license.
- WF-008 confirms `Prototype`, `Logic prototype`, `UI variant`, `Durable answer`, and `Absorb`; it defines prototype code as throwaway by default and absorption as deliberate promotion through normal production implementation and verification.
- WF-006 requires this contradiction to be repaired before simplification and leaves the prototype process with `prototype`; composition does not transfer caller ownership.
- `specs/ai-agent-config.md` requires the canonical section order, behavior preservation, local completion contracts, and source/revision/license identification before rewriting imported material. `specs/UBIQUITOUS_LANGUAGE.md` leaves skill-local terms in the owning skill body.
- Verified `shared/skills/write-a-skill/SKILL.md` requires one routed Workflow, conditional context pointers, checkable completion, and semantic rather than line-count YAGNI.
- Current `shared/skills/prototype/SKILL.md`, `LOGIC.md`, and `UI.md` contain the complete live router and branch contracts. The contradiction is concrete: `SKILL.md` calls all prototype code throwaway and untested while allowing useful code to be absorbed; `LOGIC.md` says its logic module should not be throwaway and can be lifted directly; `UI.md` requires production rewriting but also says to fold/promote a winning variant.
- Git history identifies import commit `b822ca92a4f5582aac50623354aaf3309c7daa77` and later cross-agent adaptation commit `3b59c13906d5d7922ed236b19cfe548138f429d7`. `THIRD_PARTY_NOTICES.md` records the adapted source as `mattpocock/skills` revision `66898f60e8c744e269f8ce06c2b2b99ce7660d5f`, the one-time local-fork status, and Matt Pocock's MIT license.
- The skill ships no executable support script. Installed help confirms ordinary one-command shapes for Python 3.12 and GNU Make; package-specific commands remain selected from the host project's existing task runner. The rewrite will require reporting one exact host-supported run command rather than preserving malformed blank command examples.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-011-prototype.md` — item-local authorization, preservation ledger, checks, and final state.
- `shared/skills/prototype/SKILL.md` — canonical skill body, compact router, common executable contract, cleanup, and conditional Reference pointers.
- `shared/skills/prototype/LOGIC.md` — repair direct-lift language while retaining the pure portable logic seam and complete terminal branch.
- `shared/skills/prototype/UI.md` — align winner cleanup/promotion with throwaway-by-default and deliberate verified absorption while retaining the complete visual branch.

## Proposed changes

### Add

- Add the five human-confirmed skill-local definitions to `SKILL.md`, including the deliberate production implementation and verification meaning of `Absorb`.
- Add observable completion criteria to the router/build and capture/cleanup steps: the chosen branch is named, one exact run command works under the host's existing tooling, relevant state is visible, and the durable answer records question, verdict, evidence, and implications before cleanup.
- Add explicit branch-local wording in `LOGIC.md` and `UI.md` that a validated idea or useful code is not automatically production-ready; any code reuse is deliberate and passes normal production implementation and verification.

### Change or move

- Restructure `SKILL.md` from `Pick a branch`, `Rules that apply to both`, and `When done` into canonical `Language Definitions`, one routed `Workflow`, and `Reference`; omit `Activities` because no action is independently selected outside the workflow.
- Keep route selection first. Move the current common rules beside the build step and the durable-answer/cleanup contract beside the final step without moving branch detail into the router.
- Replace malformed generic run examples such as ``pnpm ``, ``python ``, and ``bun `` with the behavioral contract to add or document and report one exact command supported by the host project's existing task runner/runtime.
- In `LOGIC.md`, change “the logic module shouldn't be [throwaway]” and direct-lift claims to preserve pure-interface portability while making the module prototype code by default. Keep reducer/state-machine/function/class choices, thin TUI behavior, one-screen rendering, run-command handoff, answer capture, and anti-patterns.
- In `UI.md`, change winning-variant cleanup from unqualified “fold/promote” wording to implementing the selected design through normal production implementation and verification, with code reuse only as a deliberate absorption choice. Keep both sub-shapes, three-to-five variant bounds, URL switcher, state visibility, production-build gate, handoff, and deletion rules.

### Remove

- Remove the standalone opening definition in `SKILL.md` after relocating its meaning to `Language Definitions`.
- Remove only duplicated or contradictory promotion claims: `LOGIC.md`'s claim that its logic module is inherently non-throwaway/directly liftable, and `UI.md`'s implication that selection alone promotes prototype code. No branch, gate, failure, guardrail, output, ownership rule, or completion condition is removed.
- Remove malformed blank command fragments, not the one-command execution contract.

## Proposed skill shape

1. `Language Definitions` — the five WF-008-confirmed definitions: Prototype, Logic prototype, UI variant, Durable answer, and Absorb.
2. `Workflow` — present; route logic versus UI first, apply common throwaway/run/state guardrails while executing the selected branch, then capture the durable answer and delete, deliberately absorb, or exceptionally preserve off the main line.
3. `Activities` — omitted; branch operations are required parts of the routed workflow, not independently selected recipes.
4. `Reference` — present; load `LOGIC.md` only to answer state/business-rule/data-shape questions and `UI.md` only to answer appearance/layout questions, with why each branch document is needed.

## Behavior-preservation checklist

- [x] Frontmatter still triggers explicit prototyping, data-model/state-machine sanity checks, UI mockups, and multiple design explorations; existing union fields and grants remain unchanged.
- [x] The question is identified before implementation; logic/state/data/API feel routes to the terminal logic branch, while appearance/layout routes to visual variants.
- [x] Genuine ambiguity is resolved with the user when reachable; otherwise surrounding code determines the branch and the prototype states its assumption.
- [x] Both conditional references remain reachable, branch-specific, one level deep, and complete; neither branch is merged into the router.
- [x] Prototype code is clearly named/marked, located near its intended context, and uses existing project routing/tooling rather than inventing a new top-level structure, runtime, or package manager.
- [x] The user receives one exact command to run; logic keeps a project task-runner command or a documented direct command when no runner exists.
- [x] State remains in memory by default; persistence questions use a scratch database or clearly disposable local file rather than the real database.
- [x] Prototype constraints remain: one question, no speculative generalization, no tests, only runnable-level error handling, and no production polish or abstractions.
- [x] Relevant state remains visible after every logic action and UI variant switch.
- [x] Logic retains an explicit question, host-language choice, pure portable interface, reducer/machine/functions/stateful-module choices, thin full-frame TUI, keyboard/line loop, one-screen display, handoff, evolution, answer capture, and all anti-pattern boundaries.
- [x] UI retains wrong-branch routing, preferred existing-page and last-resort new-page sub-shapes, 3 default/5 maximum radically distinct variants, host styling/data constraints, URL-param switcher, arrows/keyboard/focus behavior, non-production gate, URL handoff, cleanup, and mutation stubs.
- [x] Completion records a durable answer containing question, verdict, evidence, and implications in an existing repository artifact before prototype cleanup.
- [x] Deletion remains the default. Absorption is deliberate and requires normal production implementation and verification; selection or pure structure alone never makes prototype code production-ready.
- [x] Exceptional source preservation remains confined to a clearly named throwaway branch outside the main line, only when other durable evidence is inadequate, with a durable owning-artifact pointer.
- [x] Source provenance, local-fork status, copyright, and MIT license remain owned and unchanged in `THIRD_PARTY_NOTICES.md`.

## Dependencies, provenance, and risks

- Dependency SK-001 is verified at the item baseline. No owner skill or concurrent target is modified.
- Contradiction repair precedes deletion: both branch references converge on WF-008's throwaway-by-default and deliberate verified absorption rule before redundant promotion wording is removed.
- The wording must distinguish preserving a portable pure seam from declaring prototype logic production-ready. Normal production verification may include tests/error handling appropriate to the host repository even though prototype construction itself intentionally omits them.
- `THIRD_PARTY_NOTICES.md` already identifies source, revision, local-fork status, copyright, and MIT terms, so notice editing is neither needed nor authorized.
- No executable support files exist. Host-project commands cannot be fixed globally; the skill instead requires one exact locally supported command and forbids invented tooling.

## Verification

- `git diff -- .skill-migration/shared-skill-yagni/proposals/SK-011-prototype.md shared/skills/prototype/SKILL.md shared/skills/prototype/LOGIC.md shared/skills/prototype/UI.md` — every production edit matches this revision and no behavior-ledger item disappears.
- Complete reread of all four scoped files — canonical body shape, local completion criteria, contradiction repair, and exact proposal state are present.
- `python3` Markdown-link/frontmatter/scope check over the complete target and support files — `LOGIC.md` and `UI.md` resolve one level deep, frontmatter has the union fields, and only authorized files differ from baseline.
- `rg` command/provenance checks plus installed `--help`/version evidence where available — no malformed blank run examples remain, one-command execution remains explicit, and the prototype notice/source revision/MIT license remain present.
- Run the baseline-aware union audit across every `shared/skills/*/SKILL.md`, distinguishing pre-existing findings from SK-011 regressions — the prototype has no new union-schema or least-tool warning.
- `test -L pi/skills/prototype && test "$(readlink pi/skills/prototype)" = '../../shared/skills/prototype' && test -f pi/skills/prototype/SKILL.md` — Pi visibility remains the unchanged resolving symlink.
- `git diff --check` — no whitespace errors.
- `bash tests/run.sh` — repository suite passes.
- `git status --short` and `git diff --name-only 6133d8b61f937b490ede7905c4ebfdd5702c53f5...HEAD` after commit — exactly the proposal and three target/support files are committed and the worktree is clean.

## Explicit exclusions

- No edits to `MIGRATION.md`, `.wayfinder/`, `specs/`, `THIRD_PARTY_NOTICES.md`, `AGENTS.md`, deployment/install files, Pi visibility symlinks, frontmatter schema, `pi/settings.json`, or unrelated skills.
- No merger of logic and UI branches, new support file, executable script, test framework, runtime, package manager, persistence layer, production feature, or generic prototyping handbook.
- No fixed line target and no claim that this worker performs coordinator integration or central verification.

## Implementation and verification record

- Final production diff matches revision 1 exactly: `SKILL.md` has 35 insertions/15 deletions, `LOGIC.md` 6/6, and `UI.md` 5/5. The proposal is the only additional changed file.
- Complete-file reread: PASS for the proposal, resulting skill, and both branch documents. The router retains every WF-005 behavior; the support files preserve their complete logic/UI branches while converging on throwaway-by-default and deliberate verified absorption.
- Canonical body/frontmatter: PASS. Level-two headings are exactly `Language Definitions`, `Workflow`, and `Reference`; `Activities` is correctly omitted; frontmatter is byte-identical to baseline; the 426-character description contains `Use when`.
- Link check: PASS for all four local links (`SKILL.md` to both branch files and each wrong-branch cross-link). Both Reference pointers state when and why to load support; no executable support file exists.
- One-command contract: PASS. Blank command fragments were removed, both the router and logic branch require one exact host-supported command, and installed Python 3.12/GNU Make help confirmed applicable direct/task-runner surfaces. Unavailable package managers were not assumed or introduced.
- Baseline-aware union audit: PASS across all 33 shared skills with 0 errors and 0 warnings before and after; `prototype` is clean and its `read,write,edit,bash` grants match inspect/build/edit/run behavior.
- Pi visibility: PASS. The tracked mode remains `120000`, target remains `../../shared/skills/prototype`, and `pi/skills/prototype/SKILL.md` resolves to the canonical shared skill.
- Provenance/history: PASS. Notice still names `prototype`, source revision `66898f60e8c744e269f8ce06c2b2b99ce7660d5f`, local-fork status, Matt Pocock copyright, and MIT license; Git history retains import commit `b822ca92a4f5582aac50623354aaf3309c7daa77` and adaptation commit `3b59c13906d5d7922ed236b19cfe548138f429d7`.
- Exact baseline scope/protected paths: PASS. Only this proposal and the three target/support files differ from `6133d8b61f937b490ede7905c4ebfdd5702c53f5`; specs, notices, settings, deployment, visibility, other skills/proposals, Wayfinder, AGENTS, and `MIGRATION.md` are unchanged.
- `git diff --check`: PASS. `bash tests/run.sh`: PASS (2 shell files, 12 tests).
- Resulting SHA-256: `SKILL.md` `e16517abea73e19d7aedaee78db66acab268e1b0dcd565edc862523de83ee261`; `LOGIC.md` `1a629eb3ece68bd02e9ab49bac297c05ac9b64507d7e9bc7e25e2f710152b0ce`; `UI.md` `5782b9fbbe22a954a89169621718e89e616f82ecd3b8780d39726e989b440613`.
- Residual risk: production verification is intentionally host-repository-specific. The skill enforces the gate without inventing a universal command or test suite; callers must apply the host's normal implementation and verification contract when absorbing code.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Scope check: `PASS — authority order, exact four-file scope, complete behavior ledger, contradiction repair, provenance/license ownership, command applicability, and verification criteria reviewed; production edits may proceed autonomously under the standing directive.`
