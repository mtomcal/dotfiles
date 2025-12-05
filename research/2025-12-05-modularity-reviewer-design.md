---
date: 2025-12-05T00:00:00Z
researcher: Claude (Sonnet 4.5)
topic: "Design a ReadyQ modularity reviewer prompt for detecting large monolithic files"
tags: [research, modularity, refactoring, code-quality, readyq]
status: complete
---

# Research: Design a ReadyQ Modularity Reviewer Prompt

**Date**: 2025-12-05
**Researcher**: Claude (Sonnet 4.5)

## Research Question

How do we create a modularity reviewer prompt that automatically analyzes codebases for large monolithic files and suggests sensible refactors that can be turned into ReadyQ issues? The goal is to improve AI agent coding capability and human reviewing efficiency as the codebase grows.

## Summary

Large monolithic files (both code and tests) negatively impact:
1. **AI Agent Effectiveness**: Large context windows reduce reasoning quality, increase hallucinations, and slow response times
2. **Human Reviewability**: Cognitive overload from trying to understand 1000+ line files
3. **Parallel Development**: Multiple agents/developers can't work on the same large file simultaneously
4. **Maintainability**: Changes have higher risk of unintended side effects

A modularity reviewer should analyze files based on multiple metrics (size, complexity, cohesion, coupling) and generate actionable refactoring proposals as ReadyQ issues. The reviewer should run periodically as codebases grow, similar to code-quality-guardian but focused specifically on structural modularity.

## Detailed Findings

### Industry Standard Metrics for Modularity

#### 1. Lines of Code (LOC) Thresholds

**Production Code Files:**
- **< 200 lines**: Ideal (excellent)
- **200-400 lines**: Acceptable (good)
- **400-600 lines**: Warning zone (consider refactoring)
- **> 600 lines**: Critical (refactor now)

**Test Files:**
- **< 300 lines**: Ideal (tests can be slightly longer due to setup/teardown)
- **300-500 lines**: Acceptable
- **500-800 lines**: Warning zone
- **> 800 lines**: Critical

**Rationale**: Research shows smaller files are easier to understand, test, and maintain. NASA's Software Assurance Technology Center found modules with both high complexity AND large size have the lowest reliability.

#### 2. Cyclomatic Complexity (CC) Thresholds

**Per Function/Method:**
- **1-4**: Low complexity (easy to test)
- **5-7**: Moderate complexity (still easy to understand)
- **8-10**: High complexity (consider refactoring to ease testing)
- **11-20**: Very complex (hard to understand, refactor recommended)
- **> 20**: Critical (testing will be painful, refactor immediately)

**Checkstyle default**: Max of 10 per method
**McCabe's original recommendation**: Max of 10
**Pragmatic threshold**: Up to 15 acceptable, avoid exceeding 20

**Per File (aggregate):**
If average complexity per function exceeds 10, or total file complexity exceeds 50, flag for review.

#### 3. Cohesion Metrics

**LCOM (Lack of Cohesion in Methods):**
- Measures how related a class's methods and instance variables are
- **Low LCOM** (< 0.5): Good cohesion (methods share instance variables)
- **High LCOM** (> 0.8): Poor cohesion (class doing too much, consider splitting)

**Connected Components (ConnComp):**
- Number of disjoint clusters of connected classes in a package/module
- **> 1**: Package/module can be split into multiple smaller modules
- Each connected component should be its own module

#### 4. Coupling Metrics

**CBO (Coupling Between Objects):**
- **< 5**: Low coupling (good)
- **5-10**: Moderate coupling (acceptable)
- **> 10**: High coupling (refactor to reduce dependencies)

**Dependencies per file:**
- **< 5 imports**: Ideal
- **5-10 imports**: Acceptable
- **> 10 imports**: Warning (file may be doing too much)

### Test File Modularity Best Practices

#### Single Responsibility Principle (SRP) for Tests

Each test file should test one logical unit:
- **Unit tests**: One test file per production file/class
- **Integration tests**: One test file per workflow/feature
- **E2E tests**: One test file per user journey

**Problem**: 1000+ line test files testing multiple unrelated components
**Solution**: Split into multiple focused test files, each with clear responsibility

#### Modularity-Driven Testing (MDT)

**Key principles:**
1. Tests built using **small, independent, reusable modules**
2. Each module represents a **specific functionality or component**
3. Modules are **independent** (changes only affect relevant modules)
4. Test suite **scales effectively** without becoming chaotic

**Benefits:**
- Easier maintenance (update only affected modules)
- Better scalability (grows without chaos)
- Improved testability (smaller, focused tests)
- Parallel execution possible

### Refactoring Strategies for Large Files

#### Extract Method/Function
Break down large functions into smaller, well-named, focused methods.

**Before (Complex):**
```python
def process_user_data(data):
    # 100+ lines of validation, transformation, and storage
    pass
```

**After (Modular):**
```python
def process_user_data(data):
    validated = validate_user_data(data)
    transformed = transform_user_data(validated)
    store_user_data(transformed)
```

#### Extract Class/Module
Split large classes/modules into smaller, more focused ones.

**Indicators:**
- Class has > 10 methods
- Class has > 5 instance variables
- File has > 3 top-level classes/functions with unrelated purposes

#### Reduce Coupling via Interfaces
Minimize dependencies between modules using:
- Interfaces/protocols
- Dependency injection
- Abstract base classes

#### Improve Cohesion
Ensure each module has a clear, well-defined purpose:
- Group related functionality together
- Separate unrelated concerns into different modules
- Follow domain-driven design boundaries

### AI-Assisted Refactoring Insights (2025)

Recent research on LLMs and code refactoring shows:

**StarCoder2 Performance:**
- 19.7% reduction in instance variables
- 22.8% reduction in cohesion issues
- Improved code modularity and structure

**Claude 4 Sonnet:**
- Leads in clean code generation
- Highest scores in **maintainability, modularity, and documentation**
- Produces production-ready code aligned with **SOLID and DRY principles**

**Implication for dotfiles modularity reviewer:**
Claude (this agent) is well-suited to suggest modular refactorings that align with industry best practices.

### Comparison with Existing Review Commands

#### readyq:review.md (General Code Review)
**Focus**: Acceptance criteria, tests, type checking, linting, integration tests
**Workflow**: Phase-driven (7 phases)
**Critical requirements**: TDD, >90% coverage, type checking, linting
**Scope**: Single ReadyQ task review
**Output**: Pass/fail on acceptance criteria

**Location**: claude/commands/readyq:review.md:1-74

#### readyq:review-tests.md (Test Quality Review)
**Focus**: Test assertion quality, coverage metrics, integration test coverage
**Workflow**: Phase-driven (6 phases)
**Critical requirements**: TDD, >90% coverage, assertions match intent
**Scope**: Test files for a ReadyQ task
**Output**: Proposals to fix test quality issues

**Location**: claude/commands/readyq:review-tests.md:1-75

#### code-quality-guardian.md (Post-completion Review)
**Focus**: Comprehensive quality (tests, maintainability, security, modularity, complexity)
**Language support**: TypeScript, JS, Python, Go, Rust, Java, Kotlin
**Workflow**: Agent-based (7 focus areas)
**Scope**: Recently completed work (proactive invocation)
**Output**: Structured review with verdict (Approved / Approved with changes / Needs revision)

**Location**: claude/agents/code-quality-guardian.md:1-320

**Key insight**: code-quality-guardian DOES include modularity checks (section 3, lines 83-100), but it's post-hoc (after work is done) rather than proactive/periodic.

### Gap Analysis: What's Missing?

**Current state:**
- ✅ Post-implementation code review (code-quality-guardian)
- ✅ Task-specific review (readyq:review)
- ✅ Test quality review (readyq:review-tests)

**Missing:**
- ❌ **Proactive/periodic modularity scanning** across entire codebase
- ❌ **File-level structural analysis** (not tied to specific tasks)
- ❌ **Automatic generation of refactoring tasks** as ReadyQ issues
- ❌ **Trend tracking** (is modularity improving or degrading over time?)
- ❌ **Prioritization** (which large files cause the most pain?)

## Code References

### Existing Review Commands Structure

All ReadyQ commands follow a consistent pattern:

**Common elements:**
- `<critical>` tags for requirements (claude/commands/readyq:review.md:3-6)
- `<system-instructions>` with role and purpose (claude/commands/readyq:review.md:8-11)
- `<tool id="cli">` definition (claude/commands/readyq:review.md:13-15)
- `<workflow>` with numbered phases (claude/commands/readyq:review.md:17-73)
- Integration with `./readyq.py` CLI tool

**ReadyQ CLI commands used:**
- `./readyq.py quickstart` - Learn ReadyQ system (readyq:review.md:19)
- `./readyq.py show {hashId}` - Read full story (readyq:review.md:23)
- `./readyq.py update {hashId} --status {status} --log {message}` - Update task (readyq:review.md:70)
- `./readyq.py new {title} {description} {blocker}` - Create new task (readyq:create-tasks.md:68)

### Code Quality Guardian Structure

Agent-based review with:
- Language detection logic (code-quality-guardian.md:16-20)
- Project standards detection (code-quality-guardian.md:21-26)
- 7 systematic review areas (code-quality-guardian.md:31-185)
- Structured markdown output template (code-quality-guardian.md:190-237)
- Decision-making principles (code-quality-guardian.md:253-262)

**Modularity section** (code-quality-guardian.md:83-100):
- Component isolation
- Interface design
- Parallel-friendly patterns
- Stateless functions, immutable data, explicit side effects

## Architecture Insights

### Pattern: Phase-Driven Workflow for Commands

ReadyQ commands use XML-style workflow definition:
```xml
<workflow>
    <phase num="1" title="Setup">
        <action>Do something</action>
        <reason>Why we do it</reason>
    </phase>
</workflow>
```

This pattern provides:
- Clear step-by-step progression
- Built-in documentation (reason tags)
- Easy user guidance
- Consistent structure across commands

### Pattern: Research-First, Act-Later

Commands like `research_codebase_v2.md` emphasize:
1. Read context files FULLY first
2. Analyze and decompose the question
3. Conduct research (codebase + web search)
4. Generate structured document
5. Present findings with follow-up option

This pattern ensures thorough analysis before action.

### Pattern: Proposal-Based User Interaction

Multiple commands use multi-select proposals:
```xml
<list>
    <list-item text="Proposal 1..." shortcut="1" />
    <list-item text="Proposal 2..." shortcut="2" />
</list>
<user-message>Accept one or more proposals (e.g. 1, 3, 5)</user-message>
```

This gives users control over which actions to take.

### Integration Point: ReadyQ Issue Generation

For modularity reviewer to generate ReadyQ issues, use:
```bash
./readyq.py new \
  --title "Refactor: Split {filename} into focused modules" \
  --description "{analysis and breakdown}" \
  --blocker {current_task_if_applicable}
```

## Proposed Modularity Reviewer Design

### Command Name
`readyq:review-modularity` (follows existing naming convention)

### Role and Purpose
**Role**: Senior Software Architect of 20 years
**Purpose**: Proactively identify large monolithic files and propose sensible refactorings to improve AI agent effectiveness, human reviewability, and parallel development capability

### Workflow Phases

**Phase 1: Initial Setup**
- Learn ReadyQ system (`./readyq.py quickstart`)
- Ask user for scope: single directory, entire codebase, or specific file extensions

**Phase 2: Language and Project Detection**
- Detect primary language(s) from file extensions and config files
- Read project standards (CLAUDE.md, AGENTS.md if present)
- Identify build system (package.json, pyproject.toml, go.mod, Cargo.toml)

**Phase 3: File Analysis**
- Scan all code and test files in scope
- Calculate metrics:
  - Lines of code (LOC)
  - Cyclomatic complexity (CC) per function and file
  - Number of functions/classes per file
  - Import/dependency count
  - LCOM (if class-based language)
- Identify files exceeding thresholds

**Phase 4: Complexity Analysis (for flagged files)**
- Analyze internal structure
- Identify connected components (clusters of related code)
- Detect Single Responsibility Principle violations
- Assess cohesion and coupling

**Phase 5: Generate Refactoring Proposals**
- For each problematic file, suggest specific refactoring strategies:
  - Extract method/function
  - Extract class/module
  - Split by connected components
  - Reduce coupling via interfaces
- Estimate effort (small/medium/large)
- Prioritize by impact (which files cause most pain?)

**Phase 6: User Selection**
- Present proposals with multi-select list
- Show file metrics and suggested breakdown
- Let user choose which refactorings to create as ReadyQ issues

**Phase 7: Create ReadyQ Issues**
- For each selected refactoring, create a ReadyQ issue with:
  - Clear title: "Refactor: Split {filename} into focused modules"
  - Detailed description with current metrics and target structure
  - Acceptance criteria (target LOC, CC, etc.)
  - Subtasks for each extraction/split
- Optionally block current work if modularity is critical

**Phase 8: Generate Trend Report**
- Save metrics snapshot to `./modularity-reports/{timestamp}.json`
- Compare with previous reports (if available)
- Show trend: improving, stable, or degrading
- Suggest periodic review cadence

### Metrics and Thresholds (Language-Agnostic)

#### File Size Thresholds
```
Production code:
- Excellent: < 200 LOC
- Good: 200-400 LOC
- Warning: 400-600 LOC
- Critical: > 600 LOC

Test files:
- Excellent: < 300 LOC
- Good: 300-500 LOC
- Warning: 500-800 LOC
- Critical: > 800 LOC
```

#### Complexity Thresholds
```
Per function CC:
- Low: 1-4
- Moderate: 5-7
- High: 8-10
- Very High: 11-20
- Critical: > 20

Average file CC:
- Good: < 10 avg
- Warning: 10-15 avg
- Critical: > 15 avg
```

#### Structural Thresholds
```
Functions per file:
- Ideal: < 10
- Warning: 10-20
- Critical: > 20

Classes per file:
- Ideal: 1
- Acceptable: 2-3
- Warning: > 3

Imports per file:
- Good: < 5
- Acceptable: 5-10
- Warning: > 10
```

### Output Format

**Modularity Analysis Report:**
```markdown
# Modularity Review: {scope}

**Date**: {timestamp}
**Language(s)**: {detected languages}
**Files Analyzed**: {count}

## Summary
{High-level assessment: X files exceed thresholds, Y require refactoring}

## 📊 Codebase Metrics

| Metric | Min | Avg | Max | Threshold |
|--------|-----|-----|-----|-----------|
| LOC per file | ... | ... | ... | 400 |
| CC per file | ... | ... | ... | 50 |
| Functions per file | ... | ... | ... | 10 |

## 🚨 Files Requiring Refactoring

### Critical Priority (3 files)
1. **src/services/user_manager.py** (LOC: 847, CC: 78, Functions: 23)
   - **Impact**: Core service, touched in 45% of PRs
   - **Suggested refactoring**: Extract into UserValidator, UserRepository, UserNotifier
   - **Estimated effort**: Medium (2-3 days)
   - **Connected components**: 3 (validation, persistence, notifications)

### High Priority (5 files)
...

### Medium Priority (8 files)
...

## 📈 Trends (compared to last review)
- Average LOC per file: 245 → 267 (+9%) ⚠️ Degrading
- Files exceeding 400 LOC: 12 → 16 (+33%) ⚠️ Degrading
- Average CC: 8.2 → 7.9 (-4%) ✅ Improving

## 🎯 Recommended Actions
1. Prioritize refactoring of critical files (highest impact)
2. Establish file size guidelines in AGENTS.md
3. Run modularity review quarterly as codebase grows
4. Consider pre-commit hooks to flag large file additions

## 📝 Next Steps
Select refactorings to create as ReadyQ issues (1, 2, 3, ...):
```

### ReadyQ Issue Template for Refactoring

```markdown
# Refactor: Split {filename} into focused modules

## Current State
- **File**: {path}
- **LOC**: {count}
- **Complexity**: {CC}
- **Functions**: {count}
- **Issues**:
  - Violates Single Responsibility Principle
  - {X} connected components detected
  - Difficult for AI agents to reason about
  - Slows human code review

## Proposed Structure

### Module 1: {name}
- **Responsibility**: {description}
- **Functions**: {list}
- **Target LOC**: {estimate}

### Module 2: {name}
...

## Acceptance Criteria
1. Original file split into {N} focused modules
2. Each module has < 400 LOC
3. Average CC per function < 10
4. All existing tests pass (no functionality change)
5. Test coverage maintained at >90%
6. No circular dependencies introduced

## Tasks / Subtasks
- [ ] Extract {Module1Name} (AC: #1, #2)
  - [ ] Create new file {path}
  - [ ] Move functions {list}
  - [ ] Update imports in dependent files
  - [ ] Update tests
- [ ] Extract {Module2Name} (AC: #1, #2)
  ...
- [ ] Verify all tests pass (AC: #4)
- [ ] Verify coverage >90% (AC: #5)
- [ ] Verify no circular deps (AC: #6)

## Dev Notes
- This is a **refactoring task** (no behavior change)
- Run full test suite after each module extraction
- Consider using IDE refactoring tools (safer than manual edits)
- Update documentation if module structure is documented

## Impact
- **AI Agent Effectiveness**: Smaller files = better reasoning, fewer hallucinations
- **Human Reviewability**: Easier to understand focused modules
- **Parallel Development**: Multiple agents/devs can work on different modules
- **Maintainability**: Reduced risk of unintended side effects
```

## Open Questions

1. **Frequency**: How often should modularity review run?
   - Suggested: Quarterly for active projects, or after every 50 commits
   - Could be triggered manually: `/readyq:review-modularity`

2. **Automation**: Should this generate a pre-commit hook to prevent large file additions?
   - Suggested: Yes, but make it configurable (some files legitimately large)

3. **Integration with code-quality-guardian**:
   - Should modularity reviewer be invoked BY code-quality-guardian if it detects large files?
   - Or should they remain separate (one proactive, one reactive)?

4. **Language-specific thresholds**: Should Python have different LOC thresholds than Go?
   - Python tends to be more verbose than Go
   - But research shows similar complexity thresholds across languages

5. **Test file handling**: Should test files for complex features be allowed to be larger?
   - Integration/E2E tests naturally longer than unit tests
   - But modularity still beneficial

6. **Trend tracking**: What format for historical metrics?
   - JSON snapshots in `./modularity-reports/`?
   - Could enable charts/visualization over time

7. **Dependency on external tools**: Should we integrate with tools like:
   - SonarQube for metrics
   - CodeClimate for maintainability index
   - Radon (Python), gocyclo (Go), ESLint complexity (JS/TS)
   - Or implement our own simple metric calculation?

## Recommended Next Steps

1. **Create the command file**: `claude/commands/readyq:review-modularity.md`
   - Use phase-driven workflow pattern
   - Include all thresholds and metrics
   - Follow existing command structure

2. **Implement metric calculation logic**:
   - Use existing tools where possible (language-specific analyzers)
   - Fall back to simple LOC counting for unsupported languages

3. **Test on dotfiles repository**:
   - Run modularity review on this dotfiles repo
   - Validate output format and proposals
   - Refine thresholds based on real-world data

4. **Document in AGENTS.md**:
   - Add section on modularity reviewer
   - Explain when to use (periodic review vs. ad-hoc)
   - Link to research document

5. **Create OpenCode equivalent**:
   - Mirror to `opencode/commands/readyq-review-modularity.md`
   - Adapt for OpenCode syntax and patterns

6. **Set up periodic review cadence**:
   - Add to project maintenance checklist
   - Run quarterly or after major feature additions

## Sources

- [Code Refactoring Best Practices 2025](https://marutitech.com/code-refactoring-best-practices/)
- [The Ultimate Guide to Maintainability Index](https://www.numberanalytics.com/blog/ultimate-guide-to-maintainability-index)
- [Mastering Modularity Metrics](https://www.numberanalytics.com/blog/ultimate-guide-modularity-metrics-software-metrics)
- [Cyclomatic Complexity Thresholds - Microsoft Learn](https://learn.microsoft.com/en-us/visualstudio/code-quality/code-metrics-cyclomatic-complexity?view=vs-2022)
- [Cyclomatic Complexity Guide - Codacy](https://blog.codacy.com/cyclomatic-complexity)
- [Modular Software Development Best Practices - vFunction](https://vfunction.com/blog/modular-software/)
- [Modularity Driven Testing - H2K Infosys](https://www.h2kinfosys.com/blog/modularity-driven-testing/)
- [Single Responsibility Principle Guide - Medium](https://medium.com/@anderson.buenogod/understanding-the-single-responsibility-principle-srp-and-how-to-apply-it-in-c-net-projects-42d2c757d163)
- [AI Code Quality Testing 2025](https://www.allaboutai.com/resources/ai-for-coding-tools-test/)

---

**Research Complete**: This document provides a comprehensive foundation for implementing a modularity reviewer command that will help maintain healthy codebase structure as projects grow.
