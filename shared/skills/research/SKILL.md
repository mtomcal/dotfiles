---
name: research
description: Conduct durable, source-backed technical investigations using primary sources and preserve cited findings for later work. Use when a question needs sustained research, official documentation or source-code evidence, competing claims reconciled, or a reusable research artifact—not for routine factual web searches.
metadata:
  short-description: Produce durable source-backed research
allowed-tools: read,write,bash
---

# Research

Use this workflow for durable investigations, not a quick fact lookup.

## 1. Frame the question

State the decision or question, scope, required freshness, and completion criteria. Identify claims that need primary evidence and what would falsify the current assumption.

## 2. Choose artifact location

Follow an existing repository convention for research notes. If no convention exists, ask before creating a new repository directory; use a user-specified path or temporary draft while waiting. Name the final Markdown artifact for the question, not the session.

## 3. Investigate primary sources

Prefer, in order:

1. official specifications and standards
2. official documentation
3. upstream source code, tests, and release notes
4. first-party issue trackers or announcements

Use secondary sources only to discover primary material or clearly label an interpretation. Record source title, stable URL or repository path, version/date, and access date when freshness matters. Quote sparingly and distinguish sourced fact from inference.

### Herdr path

When `HERDR_ENV=1`, load the `herdr` skill and prefer background read-only delegation for independent source areas. Researchers may share the checkout. Aggregate only after checking their citations.

### Direct fallback

Outside Herdr, research directly in-process. Work source-by-source, preserving citation notes before synthesis. Any delegated editor in a later workflow requires an isolated clone or worktree.

## 4. Reconcile and write

For conflicting sources, explain authority, version, and unresolved ambiguity. Write a concise Markdown artifact containing:

- question and scope
- findings with citations adjacent to claims
- evidence table or source list
- conflicts, uncertainty, and limitations
- implications or recommendation
- follow-up questions

Completion criterion: every material factual claim is traceable to a primary source or labelled as inference, the artifact follows the agreed location convention, and the absolute path is reported.
