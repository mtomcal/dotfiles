# 0009 — Portable Skill Library

**Status:** Superseded by [0014](0014-model-native-agent-environment.md)

**Created:** 2026-08-08

## What shipped

The dotfiles owner can define a reusable coding-agent workflow once and make the same canonical skill available to every supported agent. Portable discovery metadata tells each harness what the skill does, when it should be invoked, and which tools it may use. Agent-specific metadata can refine integration without replacing the shared contract or creating a second skill definition.

Invoking a skill loads the smallest complete set of instructions required by every successful route. Skill-local language is defined first, one primary workflow owns end-to-end sequencing when needed, and independently reusable activities remain separate from that sequence. Guardrails, approvals, failure behavior, outputs, ownership, and completion criteria stay beside the step they govern rather than being displaced into distant supporting files.

Additional context appears only after an observable branch makes it necessary. A successful route must exist that does not load that context, and selecting the branch makes loading mandatory. This prevents a skill from hiding universally required behavior behind layers of links while still allowing modes, detected failures, integrations, examples, or requested detail to disclose focused support at the right time.

Skills can compose other skills for durable coordination, terminal transport, rendering, review, or specialized workflows. Composition imports a process, not ownership: the caller retains its artifact location, workflow state, user gates, acceptance authority, and return contract unless an explicit approved contract says otherwise. Engineering execution, authoring, research, teaching, visual communication, and terminal control keep distinct artifacts and verification models.

Material restructuring begins with an inventory of behavior that must survive. Every trigger, branch, gate, guardrail, failure, output, ownership rule, and completion condition remains with a known owner or receives an explicitly approved replacement. Semantic review removes duplication, stale sediment, speculation, and instructions that do not change execution instead of merely moving them elsewhere. Imported material carries source, revision, license, and attribution and is maintained locally rather than automatically synchronized upstream.

## Why it exists

Without a shared library, equivalent workflows drift across agent configurations, consume duplicate maintenance, and behave differently depending on which assistant is active. Large skill bodies create a different failure mode: agents load irrelevant branches, lose the primary process in commentary, and navigate multiple files to reconstruct instructions that every route needs.

The owner needs skills that are portable, compact, composable, and safe to revise. Portable discovery keeps invocation consistent, branch-based disclosure protects context, and explicit ownership prevents composition from taking control of a caller’s artifacts or approvals. Behavior-preservation review makes simplification auditable, while provenance keeps adapted external workflows legally and historically understandable.

## Out of scope

- Installing coding agents or deploying the catalog into each agent’s runtime directories.
- Maintaining separate canonical copies for different agents.
- Treating fixed line counts as evidence that a skill is semantically concise.
- Using supporting files to hide instructions required by every successful route.
- Automatically synchronizing locally adapted skills with upstream sources.
- Generalizing engineering execution workflows to prose authoring or other work without a testable verification model.
- Defining one universal artifact schema, acceptance checklist, or output location for unrelated workflows.

## FAQ

**Why does every supported agent use one canonical skill source?**

A shared source keeps workflow behavior and fixes consistent across harnesses. Independent per-agent copies were rejected because they drift and make users debug which version an agent discovered.

**Revisit if:** Supported agents require irreconcilably different workflow semantics rather than adapter-level discovery or tool metadata.

**Why require portable discovery metadata?**

Every harness needs a stable identifier, concrete invocation triggers, a short label, and bounded tool access. Agent-only metadata was rejected because another supported agent could not discover or safely execute the same skill.

**Revisit if:** The supported agents adopt a shared discovery standard that provides equivalent identity, triggering, presentation, and least-privilege information.

**Why grant only tools reachable from the workflow?**

Tool access should match behavior the skill can actually execute. Broad convenience grants were rejected because they increase capability without improving a supported route and make the contract harder to audit.

**Revisit if:** A harness enforces finer runtime authorization that reliably grants tools only at the exact step where they become necessary.

**Why do skill-body sections have fixed semantic roles?**

Stable roles make it clear where vocabulary, the primary process, reusable activities, and branch-selected context belong. Arbitrary structures were rejected because agents must infer whether headings are sequential, optional, reusable, or merely explanatory.

**Revisit if:** Evidence shows another portable structure produces more reliable execution across all supported agents.

**Why does every skill begin with Language Definitions?**

Each skill defines the execution terms that carry a precise meaning inside its workflow, following the DDD practice of making the language of a bounded context explicit. This prevents agents from silently assigning different meanings to terms such as artifact, owner, branch, or completion. Skills with no local vocabulary say so directly. Leaving terminology implicit was rejected because ambiguity changes execution; copying project-wide definitions into every skill was rejected because shared domain language belongs in the project glossary rather than competing local copies.

**Revisit if:** Every supported agent can reliably inject the applicable project glossary and skill-local vocabulary with clear bounded-context precedence and no additional discovery burden.

**Why must universally required instructions remain in the invoked body?**

An agent should not traverse supporting files to reconstruct the contract every successful route needs. Moving universal behavior out of line was rejected because it creates hill climbing while providing no context savings.

**Revisit if:** Every supported harness can automatically assemble required modules with proven ordering and no additional discovery burden.

**Why are Reference files limited to genuine branches?**

Branch-selected context saves attention when at least one successful route does not need it. Files loaded by every successful route were rejected as false progressive disclosure, while optional wording after branch selection was rejected because required instructions could be skipped.

**Revisit if:** Agent context loading becomes effectively free and complete without making workflow priority or ownership harder to understand.

**Why reject nested Reference chains?**

Once a branch selects added context, that context should be complete for its purpose. A second support traversal was rejected because it recreates avoidable navigation and makes branch correctness difficult to inspect.

**Revisit if:** A supported harness provides bounded transitive loading with reliable cycle, completeness, and relevance validation.

**Why use semantic YAGNI rather than a line limit?**

An instruction earns retention when it changes routing, correctness, safety, ownership, output, or completion evidence. Fixed limits were rejected because they can remove essential behavior or encourage relocating unnecessary prose instead of deleting it.

**Revisit if:** Empirical execution data establishes a size boundary that predicts failure independently of semantic completeness.

**Why require behavior preservation before material restructuring?**

Simplification can accidentally remove rare branches, failure recovery, or ownership constraints. Informal comparison was rejected because visually cleaner prose can hide a behavioral regression. An explicit inventory makes every retained or transferred behavior reviewable.

**Revisit if:** Tooling can derive and compare the complete executable behavior contract with equivalent semantic accuracy.

**Why are frontmatter audit and semantic review separate?**

Mechanical validation can prove required fields and portable syntax but cannot prove a genuine no-load route, correct ownership, or complete failure behavior. Treating schema success as semantic quality was rejected because a malformed workflow can have perfect metadata.

**Revisit if:** Automated analysis can reliably prove branch reachability, ownership, behavioral preservation, and completion semantics.

**Why does composition not transfer ownership?**

A caller may reuse transport, rendering, review, or durable mechanics while still owning where artifacts go and what acceptance means. Implicit transfer was rejected because a callee could override user gates, mutate unrelated state, or claim final acceptance outside its domain.

**Revisit if:** A composition contract explicitly names and receives approval for a replacement owner.

**Why are engineering planning and authoring kept separate?**

Engineering execution relies on failing tests, Git candidates, integration, and independent review. Prose and skill authoring use review and audit rather than a red-green implementation loop. Forcing both through one workflow was rejected because it would weaken verification or invent meaningless tracer cycles.

**Revisit if:** A separate authoring execution model provides observable failure, durable state, and acceptance gates appropriate to non-engineering work.

**Why are imported skills maintained as local forks?**

Local adaptation creates responsibility for behavior, compatibility, and licensing. Automatic upstream synchronization was rejected because it can overwrite repository-specific contracts or introduce changes without semantic review.

**Revisit if:** An upstream source offers a reviewed compatibility channel that preserves local ownership, provenance, and behavior-preservation gates.

## Open questions

None
