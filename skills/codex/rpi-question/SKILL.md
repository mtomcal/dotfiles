---
name: rpi-question
description: Create a durable, neutral set of current-state codebase research questions. Use only when a human explicitly invokes $rpi-question to scope investigation before research; never use implicitly or for design questions.
---

# RPI Question

On entry, require the initiating human-authored message itself to contain `$rpi-question`; if an agent, automation, another skill, prior message, or implicit match initiated it, refuse without writing anything. Perform only the question phase; never invoke another skill, implement, or commit. Resolve the task slug from an explicit slug first, a matching Git branch second, and the current request last; ask only when multiple existing tasks under `.tasks/rpi/` are genuinely plausible, then use `.tasks/rpi/<task-slug>/`. If the human names a questions artifact, update it in place; otherwise allocate the next task-wide `NN-` number and create `NN-questions-<topic-slug>.md`. Read named tickets, links, paths, or images fully, inspect nearby code and tests, and write plain Markdown containing only a numbered list of neutrally worded questions about the current system, each with starting repository-relative `path:line` pointers when known. Include no context section, rationale, hypothesis, proposed solution, desired-state language, frontmatter, or status. Always save the artifact, report its path, and optionally suggest likely next explicit skills without calling them.
