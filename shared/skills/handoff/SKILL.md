---
name: handoff
description: Create a redacted, timestamped Markdown handoff so another agent can continue the current work without replaying the conversation. Use when pausing work, switching sessions or agents, compacting context, or explicitly asking for a handoff.
metadata:
  short-description: Create a redacted session handoff
allowed-tools: read,write,bash
---

# Handoff

Create a compact continuation artifact outside the repository.

## Process

1. Resolve `${TMPDIR:-/tmp}/agent-handoffs/` and create it if needed.
2. Build a filesystem-safe topic slug and UTC or local timestamp.
3. Review current goals, decisions, completed work, working-tree state, verification, blockers, and next actions.
4. Redact credentials, tokens, private keys, personal data, sensitive URLs, and unnecessary machine-specific details. Replace them with descriptive placeholders.
5. Reference existing specs, plans, issues, commits, diffs, logs, screenshots, and generated artifacts by path or URL rather than duplicating their content.
6. Write `<topic>-<YYYYMMDD-HHMMSS>.md` with:
   - objective and requested next-session focus
   - constraints and decisions
   - completed work
   - current repository/Git state
   - verification already run
   - remaining steps and blockers
   - relevant artifact references
   - suggested skills and why they apply
7. Read the saved file once to verify that it is self-contained, redacted, and points only to useful artifacts.

Completion criterion: the file exists under the handoff temp directory, contains no known secrets, and a fresh agent can identify the next concrete action without the original conversation.

Always report the absolute path as the final line.
