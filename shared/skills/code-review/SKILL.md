---
name: code-review
description: Review a diff independently along Standards and Spec axes, preserving the distinction between repository conformance and requirement fidelity. Use when reviewing a branch, pull request, worktree, work in progress, or changes since a fixed point.
metadata:
  short-description: Review standards and spec fidelity
allowed-tools: read,bash
---

# Code Review

Keep two axes independent:

- **Standards** — conformance to `AGENTS.md`, repository guidance, and judgement-labelled smell heuristics.
- **Spec** — fidelity to the originating requirement in `specs/`, a plan, an issue, or another user-named source.

## 1. Pin the review scope

Resolve the user-supplied commit, branch, tag, or merge base. If none is given, ask. Capture the commit list and one stable diff command, normally a three-dot diff against the fixed point. Fail early on a bad ref or empty diff.

## 2. Identify sources

For Standards, read `AGENTS.md` plus relevant contributor, test, style, and module guidance. Tool-enforced formatting is not a review finding.

For Spec, locate the requirement from the user, commit messages, branch context, `specs/`, plans, or issue references. If no source exists, report `No spec available`; do not invent one.

## 3. Run independent passes

### Herdr path

When `HERDR_ENV=1`, load the `herdr` skill and prefer two parallel read-only reviewers. They may share the checkout. Give both the same diff scope but only their own axis sources and criteria.

### In-process fallback

Outside Herdr, perform two explicitly separated passes. Finish and preserve Standards notes before reading them only for aggregation; then start a fresh Spec checklist from the requirement source. Do not let one axis excuse, suppress, or rerank the other.

### Standards criteria

Report documented-rule violations with file, hunk, and cited rule. Label all smell findings as judgement calls, not violations; repository guidance overrides them. Useful heuristics include mysterious names, duplication, feature envy, data clumps, primitive obsession, repeated switches, shotgun surgery, divergent change, speculative generality, message chains, middle men, and refused bequests.

### Spec criteria

Report missing or partial requirements, incorrect implementations, and unrequested behavior. Cite the requirement for every finding. Distinguish scope creep from harmless implementation detail.

Completion criterion: every changed file was considered independently on both available axes, and each finding includes location, evidence, impact, and a concrete remedy.

## 4. Report without collapsing axes

Use separate `## Standards` and `## Spec` sections. Order findings by severity within each axis; include pass/skip states when no findings exist. End with counts and the worst issue within each axis, never one winner across axes.
