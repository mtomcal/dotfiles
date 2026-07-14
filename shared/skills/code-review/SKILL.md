---
name: code-review
description: Review a diff independently along Standards and Spec axes, preserving the distinction between repository conformance and requirement fidelity. Use when reviewing a branch, pull request, worktree, work in progress, or changes since a fixed point.
metadata:
  short-description: Review standards and spec fidelity
allowed-tools: read,bash
---

# Code Review

## Language Definitions

- **Standards axis** — conformance review against repository guidance and labelled quality judgments.
- **Spec axis** — independent fidelity review against the originating requirement.
- **Fixed point** — immutable resolved commit used as the review baseline.
- **Review scope** — commits and resulting diff between the fixed point and reviewed state.

Neither axis may waive, suppress, or rerank the other.

## Workflow

1. **Pin the review scope.** Resolve the user-supplied commit, branch, tag, or merge base to a fixed point. If none is given, ask rather than guessing. Capture the commit list and one stable diff command, normally a three-dot diff against the fixed point. Fail before source discovery or review execution if the ref is bad or the diff is empty.

   Completion criterion: the fixed point resolves, and the exact commit list and non-empty diff scope are recorded.

2. **Identify sources independently.** For Standards, read `AGENTS.md` plus relevant contributor, test, style, and module guidance. Tool-enforced formatting is not a review finding. For Spec, locate the originating requirement from the user, commit messages, branch context, `specs/`, plans, or issue references. If no source exists, record `No spec available`; do not invent one.

   Completion criterion: the Standards authorities and either the requirement source or the explicit no-spec state are recorded.

3. **Run independent passes.** When `HERDR_ENV=1`, load the `herdr` skill and prefer two parallel read-only reviewers. They may share the checkout. Give both the same captured scope but only their own axis sources and criteria. Outside Herdr, perform two explicitly separated in-process passes over the same captured scope: finish and preserve Standards notes, start a fresh Spec checklist from the requirement source, and read both sets of notes together only for aggregation. If no spec is available, skip that pass explicitly. In either route, one axis cannot excuse, suppress, or rerank the other.

   - **Standards criteria:** Report documented-rule violations with file, hunk, and cited rule. Label all smell findings as judgement calls, not violations; repository guidance overrides them. Useful heuristics include mysterious names, duplication, feature envy, data clumps, primitive obsession, repeated switches, shotgun surgery, divergent change, speculative generality, message chains, middle men, and refused bequests.
   - **Spec criteria:** Report missing or partial requirements, incorrect implementations, and unrequested behavior. Cite the requirement for every finding. Distinguish scope creep from harmless implementation detail.

   Completion criterion: every changed file was considered independently on both available axes, and each finding includes location, evidence, impact, and a concrete remedy.

4. **Report without collapsing axes.** Use separate `## Standards` and `## Spec` sections. Order findings by severity within each axis; report pass when an available axis has no findings and skip when an axis is unavailable.

   Completion criterion: the report ends with separate totals and the worst issue within each axis, never one winner across axes.
