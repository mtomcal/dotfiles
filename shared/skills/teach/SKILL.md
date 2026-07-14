---
name: teach
description: Build a durable, mission-grounded teaching workspace with researched resources, reusable HTML lessons, retrieval practice, and learning records. Use when the user wants to learn a topic or skill over multiple sessions, create a personal course, or continue structured teaching from an existing workspace.
metadata:
  short-description: Build durable mission-grounded learning
allowed-tools: read,write,edit,bash
---

# Teach

Treat teaching as a stateful, multi-session practice. Knowledge comes from trusted sources, skills from tight feedback loops, and wisdom from real-world practice and communities.

## 1. Confirm a dedicated teaching workspace

Ask the user for a dedicated workspace path. Do not silently scaffold the current code repository. If the proposed path is an existing code checkout, explain that teaching state is durable and ask them to confirm a separate location or explicitly approve that checkout.

Inspect an existing teaching workspace before proposing changes. For a new workspace, explain the initial structure and ask before creating it:

```text
<teaching-workspace>/
├── MISSION.md
├── RESOURCES.md
├── NOTES.md
├── GLOSSARY.md                 # created when understood terms emerge
├── lessons/
│   └── 0001-<lesson>.html
├── reference/
│   └── <quick-reference>.html
├── learning-records/
│   └── 0001-<insight>.md
└── assets/
    └── course.css
```

Create directories lazily except for the files/directories approved for the first lesson. Read [MISSION-FORMAT.md](MISSION-FORMAT.md), [RESOURCES-FORMAT.md](RESOURCES-FORMAT.md), [LEARNING-RECORD-FORMAT.md](LEARNING-RECORD-FORMAT.md), and [GLOSSARY-FORMAT.md](GLOSSARY-FORMAT.md) only when creating or changing those artifacts.

Completion criterion: the user approved one dedicated path and approved the initial scaffold before any workspace files are written.

## 2. Ground the mission and current level

Interview for the concrete outcome, observable success, constraints, and out-of-scope topics. Write or revise `MISSION.md` only after agreement. A mission change requires user confirmation and a learning record explaining why the new mission changes future teaching.

Estimate the user's **zone of proximal development** from:

- existing learning records and demonstrated performance
- prior knowledge the user reports, including depth
- mission requirements and constraints
- misconceptions or retrieval failures from earlier lessons

Record prior knowledge or demonstrated non-trivial understanding, not mere exposure. Completion criterion: the next lesson traces to the mission and is challenging enough to require effort without depending on unknown prerequisites.

## 3. Build trustworthy resources

Compose the `research` skill to gather primary sources, official documentation, upstream source, recognized experts, and high-quality communities. Never rely on parametric recall for material claims. Keep `RESOURCES.md` curated and annotated with what each source supports; expose gaps rather than filling them with weak links.

Distinguish:

- **Knowledge**: trustworthy concepts needed for the mission
- **Skill**: durable, flexible performance built through practice and feedback
- **Wisdom**: judgement tested with practitioners, communities, and real situations

Respect a user's choice not to join communities and record that preference in `RESOURCES.md` or `NOTES.md`.

Completion criterion: every substantive lesson claim has an adjacent citation to an approved source, or is clearly presented as an exercise/hypothesis rather than fact.

## 4. Design one small lesson

Each `lessons/NNNN-<slug>.html` is a self-contained, attractive HTML lesson that gives one tangible win tied to the mission. Keep working-memory load low. Teach only the knowledge required for the target skill, then tighten the feedback loop around practice.

Build storage strength rather than mistaking current fluency for mastery:

- use retrieval practice before re-explanation
- space important ideas across later lessons
- interleave related skills once each has a basic foundation
- use desirable difficulty for skill practice, not for initial knowledge acquisition
- give immediate, ideally automatic, feedback

For multiple-choice quizzes, avoid formatting or answer-length clues. End with a primary-source recommendation and an invitation to ask follow-up questions.

When an interactive codebase-accurate lesson fits, compose `create-explainer`; its source-first and reviewer rules still apply, while this skill owns the mission, workspace paths, citations, lesson size, and reusable assets. Save the result as a teaching lesson, not as an unrelated repository explainer.

Completion criterion: the lesson has one mission-linked outcome, one retrieval/practice loop, trustworthy citations, and a clear success signal.

## 5. Reuse assets and compress knowledge

Before authoring a lesson, inspect `assets/` and `reference/`. Reuse the shared stylesheet, quiz widgets, simulators, diagram helpers, and established visual language. Put a component in `assets/` when another lesson could reuse it; do not duplicate it inline.

Create beautiful, printable HTML references for durable compressed knowledge: cheat sheets, algorithms, syntax, sequences, diagrams, and glossaries. Add a term to `GLOSSARY.md` only after the user can use it correctly. Link lessons and references with relative HTML anchors.

Completion criterion: the lesson uses existing reusable assets where applicable, and any new reusable behavior has one shared home.

## 6. Observe, record, and choose the next step

After practice, ask the user to retrieve or apply the idea without copying the lesson. Write a sequential learning record only when evidence shows understanding, prior knowledge, corrected misconception, or a mission shift. Supersede contradicted records rather than deleting history. Put teaching preferences and temporary observations in `NOTES.md`; do not turn learning records into session logs.

Preview the lesson locally when possible and report its absolute path. The session is complete when the artifact renders, the user has a concrete practice action, evidence has been recorded at the right durability, and the next lesson can be selected from mission plus learning records.
