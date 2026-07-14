# Coding Principles Catalog

Reference for the grill-me deep pass — probing questions for each principle category.

---

## A. Test Methodology

**Probing questions:**
- Do you practice TDD (test-first), test-last, or something else?
- If TDD: red/green/refactor? Does every change start with a failing test?
- What test framework(s) do you use? (pytest, Jest, Go testing, etc.)
- Are there modules where testing is required vs optional?
- What's the test coverage expectation?
- Do you use test doubles? Preference for mocks, fakes, stubs, or real dependencies?
- Are integration tests separate from unit tests? Where do they live?
- Is there a CI gate that blocks merge on test failure?

**Common variants:**
- Strict TDD (red/green/refactor)
- BDD (Given/When/Then, Cucumber/Gherkin)
- Test-last with coverage targets
- Property-based testing (fast-check, Hypothesis)
- Snapshot testing for UI

---

## B. Design Principles

**Probing questions:**
- Do you follow SOLID? Which principles are most important here?
- Single Responsibility: how small is a "module" or "class" expected to be?
- Interface Segregation: do you use narrow interfaces or broad ones?
- Dependency Inversion: do high-level modules depend on abstractions?
- Composition over inheritance: is this enforced?
- Any architectural patterns in play? (hexagonal, clean architecture, MVC, etc.)
- Are there specific design patterns the team favors or avoids?

**Common variants:**
- SOLID (full or partial)
- DRY (Don't Repeat Yourself) — with nuance about premature abstraction
- KISS (Keep It Simple, Stupid)
- YAGNI (You Ain't Gonna Need It)
- GRASP patterns

---

## C. Code Organization

**Probing questions:**
- Package-by-feature or package-by-layer?
- What determines when something becomes its own module/package?
- Are there rules about file size or function length?
- Single export at module boundary: do you expose internal details?
- Are facades used to limit what other modules can import?
- Is there a convention for where new code goes? (e.g., "controllers in handlers/, business logic in services/")
- Are there shared/utility directories? What's allowed in them?

**Common variants:**
- Package-by-feature (domain-driven)
- Package-by-layer (handlers, services, repos)
- Domain-driven design (bounded contexts)
- Modular monolith

---

## D. Error Handling

**Probing questions:**
- What's the error handling philosophy? Fail-fast or graceful degradation?
- Do you use typed/structured errors or string-based?
- Is there a rule about never swallowing errors silently?
- Are error boundaries defined? (e.g., "errors are converted at the API boundary")
- How are errors logged? What level for what kind of error?
- Are there retry policies for transient failures?

**Common variants:**
- Result types (Rust-like Ok/Err, Go multi-return)
- Try/catch with typed exceptions
- Error codes with central registry
- Circuit breakers for external calls

---

## E. Mutation Rules

**Probing questions:**
- Immutability by default: do you prefer immutable data structures?
- Are pure functions preferred where possible?
- Do side-effects belong at the edges (API handlers, DB layer, file I/O)?
- Is there a convention for state management? (Redux, context, singletons?)
- Are there rules about shared mutable state or global variables?
- Functional vs imperative style preference?

**Common variants:**
- Immutable data, pure functions at core
- Mutable by default with conventions
- Functional core, imperative shell
- Actor model / message passing

---

## F. Naming Conventions

**Probing questions:**
- Do you use ubiquitous language in code? (domain terms, not implementation terms)
- File naming: kebab-case, snake_case, PascalCase?
- Function naming: verbNoun? (e.g., `getUser`, `validateToken`)
- Are abbreviations allowed or forbidden?
- Is there a glossary of domain terms?
- How are boolean functions named? (`isX`, `hasX`, `canX`)?
- Constructor/factory naming conventions?

**Common variants:**
- Strict ubiquitous language from domain model
- Language-idiomatic conventions (Go style, PEP 8, Airbnb JS)
- Custom team conventions documented in CONTRIBUTING.md

---

## G. Review Gates

**Probing questions:**
- Is code review required before merge?
- Are there specific reviewers for certain modules?
- What does the PR checklist include? (tests, docs, linting, etc.)
- Is there a CI pipeline? What gates does it enforce?
- Are there pre-commit hooks? What do they check?
- Is pair programming used for certain types of changes?
- How are breaking changes communicated?

**Common variants:**
- Mandatory PR + approval
- Pair programming replaces review
- Automated gates only (lint, test, build)
- CODEOWNERS for module-level review
