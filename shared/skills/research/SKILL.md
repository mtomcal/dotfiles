---
name: research
description: Conduct durable, source-backed technical investigations using primary sources and preserve cited findings for later work. Use when a question needs sustained research, official documentation or source-code evidence, competing claims reconciled, or a reusable research artifact—not for routine factual web searches.
metadata:
  short-description: Produce durable source-backed research
allowed-tools: read,write,bash
---

# Research

## Language Definitions

- **Primary source** — direct authority such as an official specification, documentation, source, test, release note, or first-party announcement.
- **Secondary source** — interpretation or discovery aid rather than authority for the underlying claim.
- **Inference** — conclusion derived from evidence but not explicitly stated by a source.
- **Research artifact** — durable cited investigation with findings, conflicts, limitations, implications, and follow-ups.
- **Required freshness** — version/date currency needed for safe use.
- **Stable citation** — pointer specific enough to recover supporting evidence later.

## Workflow

Route the request first. For a routine factual lookup, answer through proportionate normal lookup and do not create a research artifact unless the user requests one. Continue with this workflow when the question needs a durable investigation.

### 1. Frame the question

State the decision or question, scope, required freshness, and completion criteria. Identify the claims that need primary evidence and what would falsify the current assumption.

Completion criterion: the question or decision, scope boundary, freshness requirement, completion evidence, primary-evidence claims, and falsifier are explicit.

### 2. Choose the artifact location

Follow an existing repository convention for research notes. If no convention exists, never invent one or create repository structure without approval; ask for a destination and use a user-approved path or temporary draft while waiting. Name the final Markdown artifact for the question, not the session.

Completion criterion: the final location follows an existing convention or has user approval, and any temporary draft is identified as temporary.

### 3. Investigate primary sources

Use sources in this authority order:

1. official specifications and standards;
2. official documentation;
3. upstream source code, tests, and release notes;
4. first-party issue trackers or announcements.

Use secondary sources only to discover primary material or as clearly labelled interpretation. For each source, record its title, stable URL or repository path, version/date, and access date when freshness matters. Quote sparingly, keep citations adjacent to material claims, and distinguish sourced fact from inference.

When `HERDR_ENV=1`, load the `herdr` skill and use background read-only delegation when independent source areas benefit from it. Read-only researchers may share the checkout, but they do not edit the artifact or repository. Check every returned citation against its claim before synthesis.

Outside Herdr—or when delegation is unavailable or not useful—complete the full investigation in-process, source by source, preserving citation notes before synthesis. This workflow delegates no editing; any later workflow that authorizes delegated edits must use an isolated clone or worktree.

Completion criterion: every required source area has been investigated through the Herdr path or the full in-process fallback, source metadata is captured, and delegated citations have been checked.

### 4. Reconcile and write

Reconcile conflicting sources by explaining their authority and applicable version. Report unresolved ambiguity instead of silently choosing. Write a concise Markdown artifact containing:

- question and scope;
- findings with citations adjacent to claims;
- evidence table or source list with source metadata;
- conflicts, uncertainty, and limitations;
- implications or recommendation; and
- follow-up questions.

Completion criterion: every material factual claim is traceable to a primary source or labelled as inference, citations support their adjacent claims, conflicts are reconciled or explicitly unresolved, the artifact uses the agreed location, and its absolute path is reported.
