---
name: proposal-first
description: Create and maintain numbered feature proposals that preserve durable intent in shipped-feature announcement prose and decision FAQs with revisit triggers. Migrate bloated specs, PRDs, and requirement documents by separating durable intent from implementation detail. Use when starting a feature, epic, or project; discussing proposals, RFCs, working backwards, press releases, spec bloat, or "write the blog post first"; preserving decisions after grilling or planning; or closing linked work.
metadata:
  short-description: Preserve feature intent in proposals
allowed-tools: read,write,edit,bash
---

# Proposal First

## Language Definitions

- **Proposal** — permanent engineering artifact describing why a feature exists, who it helps, and what users can do, written as if the feature has shipped.
- **Announcement** — plain, present-tense proposal section describing user experience rather than implementation.
- **Decision FAQ** — question and resolved answer recording a consequential choice, rejected alternatives, rationale, and revisit trigger.
- **Revisit trigger** — observable condition that makes a recorded decision worth reconsidering.
- **Discard pile** — migration-source material proposed for removal because it is implementation detail rather than durable intent.

A proposal preserves intention; an engineering plan owns implementation detail. Proposals contain no pseudocode, schemas, function signatures, file paths, module layouts, task breakdowns, estimates, sequence diagrams, acceptance checklists, or numbered requirements.

## Workflow

### 1. Route the proposal work

Select one branch before editing:

- **Author** for a new feature, epic, or project.
- **Migrate** for an existing spec, PRD, requirement document, or spec-library artifact.
- **Maintain** for supersession, proposal status, or decisions learned during linked work.

Resolve repository guidance and the proposal directory. Use `proposals/` when no repository-owned convention overrides it. Enumerate existing proposal filenames before choosing a number; use the next unused four-digit sequence and never reuse a number.

Once the branch is known, load [`reference/proposal-template.md`](reference/proposal-template.md), because every branch must preserve the repository artifact contract. If multiple source documents are requested for migration, operate on only the first until the user confirms the result.

Completion criterion: one branch, one target proposal or first migration source, the governing proposal location, and any linked epic ID are known; the template is loaded; and a new proposal number does not collide with existing files.

### 2. Establish durable intent

For **Author**, gather existing conversation and repository evidence first, then establish without invention:

1. the specific user in their actual situation;
2. what that user can do after shipping that they could not do before;
3. deliberate exclusions and their rationale; and
4. decisions already made, rejected alternatives, and revisit triggers.

Ask only for material absent from available evidence. If the specific user or new capability remains unknown, stop and explain that the proposal is not ready to author.

For **Migrate**, read the complete source and account for every section in exactly one proposed pile:

- **Announcement:** user-facing behavior, motivation, beneficiaries, problem, and success expressed in user terms.
- **Decision FAQ:** resolved questions, choices with named alternatives, and constraints explaining choices. Supply a revisit trigger from evidence or leave the decision visibly unresolved; do not invent one.
- **Discard pile:** pseudocode, signatures, schemas, paths, layouts, checklists, task breakdowns, estimates, sequence diagrams, and numbered requirements.

Present the discard pile one line per item and obtain user confirmation before omitting that material from the migrated artifact. Do not delete or overwrite the source unless the user explicitly approves that separate action.

For **Maintain**, inspect the proposal and linked work. Before an epic closes, identify decisions that would surprise the proposal author six weeks later and propose them as Decision FAQ entries with revisit triggers. Changed intention requires a new proposal and a `Superseded by NNNN` link on the old one; never rewrite the old announcement to make history look consistent. Status, supersession links, and decisions discovered during linked work may be maintained without rewriting historical intent.

Completion criterion: authoring has all four intent inputs; migration accounts for every source section and has confirmation for every omission; or maintenance has classified each change as status, supersession, learned decision, or changed intention requiring a new proposal.

### 3. Write the proposal

Follow the loaded template. Write the Announcement in the voice of a capable engineer explaining a shipped feature to a colleague: plain, concrete, present tense, and specific about the user. Keep it 300–600 words and normally within two pages; excess length is a signal to remove implementation detail.

Avoid marketing language, inflated adverbs, rhetorical question-and-answer setups, “it is not X, it is Y” reframes, and chained fragments. Add only questions a reasonable engineer would ask. Every resolved decision entry must name what was chosen, relevant rejected alternatives, why, and at least one revisit trigger. Keep genuinely undecided matters in Open questions rather than inventing answers.

Write a new artifact as `proposals/NNNN-short-kebab-title.md` unless repository guidance selected another location. In migration mode, preserve the source until the user has confirmed the first migrated proposal reads correctly.

Completion criterion: the artifact follows the template, contains no implementation-detail categories, names a specific beneficiary and capability, keeps unresolved matters explicit, and gives every resolved decision a rationale and revisit trigger.

### 4. Verify and report

Reread the complete saved proposal and compare it with the gathered evidence or migration accounting. Confirm the sequence number is unique, status and supersession links are internally consistent, announcement voice and length satisfy the contract, exclusions are explicit, every FAQ question carries genuine tension, and no approved durable intent was lost.

Report the exact proposal path, branch used, and linked epic ID when one exists. For migration, also report whether the source was preserved and wait for confirmation before processing another document.

Completion criterion: the saved file passes every check, all changed artifacts are accounted for, and the final response identifies the proposal and any remaining open questions or unconfirmed migration work.
