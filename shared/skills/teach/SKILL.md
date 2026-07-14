---
name: teach
description: Build a durable, mission-grounded teaching workspace with researched resources, reusable HTML lessons, retrieval practice, and learning records. Use when the user wants to learn a topic or skill over multiple sessions, create a personal course, or continue structured teaching from an existing workspace.
metadata:
  short-description: Build durable mission-grounded learning
allowed-tools: read,write,edit,bash
---

# Teach

## Language Definitions

- **Teaching workspace** — dedicated durable directory holding one learner’s mission, resources, lessons, references, assets, and evidence.
- **Mission** — agreed real-world outcome, observable success, constraints, and scope.
- **Zone of proximal development** — next challenge requiring effort without unknown prerequisites.
- **Knowledge** — trustworthy concepts required for the mission.
- **Skill** — durable flexible performance from practice and feedback.
- **Wisdom** — judgment tested with practitioners, communities, and real situations.
- **Storage strength** — durability of learning over time rather than immediate fluency.
- **Retrieval practice** — unaided recall or application before rereading.
- **Learning record** — evidence-backed insight changing future teaching, not a session log.
- **Demonstrated understanding** — correct unaided retrieval or application.

## Workflow

Treat teaching as a stateful, multi-session practice. Route first between continuing an existing teaching workspace and creating a new one; do not treat a code checkout or generic workspace as teaching state without explicit approval.

### 1. Confirm the dedicated teaching workspace

Ask for a dedicated workspace path. If the proposed path is an existing code checkout, explain that teaching state is durable and ask the user to choose a separate location or explicitly approve that checkout. Inspect an existing teaching workspace read-only before proposing changes.

For a new workspace, present the intended initial scaffold and obtain approval for both the path and exact first-lesson files/directories before writing:

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

Create only the approved first-lesson state; create all other artifacts lazily. Completion criterion: the user has approved one dedicated path and its exact initial scaffold before any workspace write occurs.

### 2. Ground the mission and learner evidence

Read existing mission, records, notes, glossary, and relevant lessons before selecting the next lesson. Interview for the real-world outcome, observable success, constraints, and out-of-scope topics. Write or revise `MISSION.md` only after agreement. A mission change requires user confirmation and a learning record explaining how the change affects future teaching.

Estimate the learner’s zone of proximal development from:

- existing learning records and demonstrated performance;
- prior knowledge the learner reports, including its depth;
- mission requirements and constraints; and
- misconceptions or retrieval failures from earlier lessons.

Record demonstrated non-trivial understanding or stated prior-knowledge depth, not mere exposure. Completion criterion: the next lesson traces to the agreed mission, uses the available learner evidence, requires effort, and depends on no unknown prerequisite.

### 3. Build trustworthy resources

Compose `research` to gather and reconcile primary sources, official documentation, upstream source, recognized experts, and high-quality communities. Research owns its evidence process; Teach retains the teaching-workspace location, approved source set, `RESOURCES.md`, lesson claims, citations, and acceptance. Never use parametric recall as evidence for a material claim. Keep resources curated and annotated with what each source supports, and expose gaps instead of filling them with weak links.

Plan separately for:

- **Knowledge** — trustworthy concepts required for the mission;
- **Skill** — durable flexible performance from practice and feedback; and
- **Wisdom** — judgment tested with practitioners, communities, and real situations.

Respect a learner’s choice not to join communities and record it in `RESOURCES.md` or `NOTES.md`. Completion criterion: every substantive factual lesson claim has an adjacent citation to an approved source or is clearly labelled as an exercise or hypothesis.

### 4. Design one small lesson

Load the teaching-practice Reference for every lesson design. Before drafting, inspect `assets/` and `reference/` for reusable styles, widgets, simulators, diagrams, and established visual language.

Create one self-contained, attractive `lessons/NNNN-<slug>.html` lesson page with one tangible win tied to the mission. Teach only prerequisite knowledge needed for the target skill. Require unaided retrieval or application before reveal or rereading, a relevant practice attempt, corrective feedback, and a clear success signal. Make feedback prompt and preferably automatic when correctness can be judged reliably, while choosing timing for the task. Schedule important retrieval in later lessons, and interleave only related skills whose foundations are already known. Remove formatting, answer-length, and other answer clues. End with a primary-source recommendation and an invitation for follow-up questions.

When an interactive codebase-accurate lesson fits, compose `create-explainer` without weakening its source mapping, mandatory factual review, serving, or browser-validation process. Teach retains the mission, numbered lesson destination, workspace state, approved citations, lesson size, reusable assets, learner evidence, and acceptance; integrate the reviewed result as a teaching lesson rather than an unrelated explainer.

Completion criterion: the lesson has one mission-linked outcome, one retrieval/practice/feedback loop, trustworthy citations, reusable assets where applicable, no answer clues, and an observable success signal.

### 5. Reuse assets and compress understood knowledge

Place behavior another lesson could reuse in `assets/` rather than duplicating it inline. Create attractive, printable HTML references for durable compressed knowledge such as cheat sheets, algorithms, syntax, sequences, and diagrams. Link lessons and references with relative HTML anchors.

Add or revise a `GLOSSARY.md` term only after the learner demonstrates understanding by using it correctly. Completion criterion: existing assets are reused where applicable, every new reusable behavior has one shared home, and glossary entries cross the understood-term threshold.

### 6. Observe, record, render, and choose the next step

After practice, ask the learner to retrieve or apply the idea unaided, without copying the lesson. Write a sequential learning record only when evidence establishes demonstrated understanding, prior-knowledge depth, a corrected misconception, or an approved mission shift. Supersede contradicted records rather than deleting history. Put teaching preferences and temporary observations in `NOTES.md`; learning records are not session logs. If understanding is not demonstrated, do not record it as learned—use the observed gap to choose support or the next lesson.

Render-check the lesson locally. If rendering cannot be checked, report that limitation and do not claim it passed. Report the lesson’s absolute path and give the learner one concrete unaided practice action. Completion criterion: the current artifact renders, the absolute path and practice action are reported, evidence is stored at the correct durability, and the next step is selected from the mission plus learning records.

## Reference

- Load [MISSION.md format](MISSION-FORMAT.md) before creating or changing `MISSION.md` so the mandatory one-mission, concrete-outcome, observable-success, constraints, scope, and brevity rules govern the write.
- Load [RESOURCES.md format](RESOURCES-FORMAT.md) before creating or changing `RESOURCES.md` so source annotations, Knowledge/Wisdom grouping, gaps, pruning, and community preferences use the owned schema.
- Load [Learning record format](LEARNING-RECORD-FORMAT.md) before creating, updating, or superseding a learning record so qualification, numbering, evidence, implications, and retained history follow the durable schema.
- Load [GLOSSARY.md format](GLOSSARY-FORMAT.md) before creating or changing `GLOSSARY.md` so only demonstrated understanding is promoted and canonical terms, avoided aliases, ambiguities, and revisions remain consistent.
- Load [Teaching practice](TEACHING-PRACTICE.md) during step 4 for every lesson design; this mandatory Reference supplies the source-backed retrieval, spacing, interleaving, prerequisite guidance, feedback, no-clue, and lesson-acceptance rules that must not become optional after disclosure.
