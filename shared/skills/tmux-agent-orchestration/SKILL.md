---
name: tmux-agent-orchestration
description: Launches, steers, and monitors multiple CLI agents in tmux with separate clones, explicit prompt submission, and progress checks. Use when running parallel Codex, Claude, or mixed CLI workers in tmux, coordinating one worker per plan/task, relaunching agents into isolated clones, or monitoring whether TUI prompts were actually submitted.
metadata:
  short-description: Orchestrate parallel CLI agents in tmux
allowed-tools: read,write,bash
---

# Tmux Agent Orchestration

## Quick Start

Use this skill when you need to:

- launch multiple `codex` workers in parallel
- launch multiple `claude` workers in parallel
- mix agent CLIs such as Codex orchestrating Claude or Claude orchestrating Codex
- give each worker its own clone
- steer existing TUI workers with `tmux`
- verify that a prompt was actually submitted
- monitor completion, commits, branches, and PR state
- handle post-merge drift by routing workers back onto stale PRs
- clean up tmux sessions and per-task clones after the work is merged

## First Question

Before launching workers, ask which CLI agent to use unless the user already specified it.

Examples:

- `codex`
- `claude`
- mixed setup such as `codex orchestrating claude`
- mixed setup such as `claude orchestrating codex`

## Core Rules

1. Default to one clone per worker for implementation tasks.
2. Name the `tmux` session and windows deterministically.
3. Confirm the exact CLI command shape before launch, because `codex`, `claude`, and other CLIs differ.
4. When steering an existing TUI pane, always verify the prompt was submitted.
5. Do not assume pasted text was sent just because it appears in the pane.
6. Prefer direct inspection with `tmux capture-pane` over guessing.
7. For PR work, prefer a clean branch from `origin/main` plus a cherry-pick of the intended implementation commit.
8. For CI follow-up, keep the original worker on the PR until checks are green, not just until a fix is pushed.

## Workflow

1. Create one clone per worker.
2. Ask which CLI agent to launch if the user did not specify one.
3. Launch one worker per clone in a named `tmux` window.
4. Put the full task in the initial prompt, including whether subagents are authorized.
5. Monitor panes with `tmux capture-pane` and branch state with `git`.
6. If you need follow-up work in an existing pane, paste the text, send `Enter`, then confirm the pane switches into active work.
7. Before asking a worker to refresh a PR, check the PR's current mergeability so you know whether the branch is actually stale.
8. After all PRs are merged, clean up the worker session and clone bundle.

See [REFERENCE.md](REFERENCE.md) for commands, failure modes, and monitoring patterns.
