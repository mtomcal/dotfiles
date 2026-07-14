# Reference: Create Explainer

## Intake and persona

Use the ordered intake only when the concept, audience, and depth are not already clear. If the request supplies those facts, state the inferred answers and ask only about missing or risky details.

### Ordered intake

1. **Concept:** “What concept or flow should the explainer cover?” Accept a feature, message type, architecture question, or debugging scenario. If vague, ask whether the scope is input, protocol, backend logic, rendering, or the full end-to-end flow.
2. **Experience:** “What's your experience level with this codebase's tech stack?” Offer `beginner`, `intermediate`, or `advanced`.
3. **Specialty:** “What's your primary role or specialty?” Examples include frontend, backend, SRE, product, and new-hire onboarding.
4. **Time:** “How much time do you want to spend with this explainer?” Route `≤ 5 minutes` to Condensed, `5–15 minutes` to Guided, and `> 15 minutes` or “as long as it takes” to Full Lab.
5. **Prior knowledge, optional:** “Any domain concepts you already understand that I should skip?”

### Experience matrix

| Level | Code style | Analogy style | Assumed knowledge |
|-------|------------|---------------|-------------------|
| `beginner` | Pseudocode plus one real snippet | Everyday or familiar-application analogies | None |
| `intermediate` | Real code with inline comments | Framework-to-framework analogies | Language syntax |
| `advanced` | Full real code blocks | Architecture-pattern analogies | Patterns and concurrency |

### Specialty matrix

| Specialty | Emphasize | De-emphasize |
|-----------|-----------|--------------|
| `frontend` | Client input, rendering, state synchronization, UI feedback | Backend tick internals and language-specific locking details |
| `backend` | Validation gates, processing loops, business logic, broadcast | Scene lifecycle and visual effects |
| `SRE` | Message rates, timing, compression, network failure modes | Rendering and product aesthetics |
| `product` | User-visible outcomes, error states, UX flow | Implementation detail |

Cross-map the matrices rather than applying either mechanically. A frontend beginner benefits from familiar UI/state analogies and toggleable conditions. An advanced backend learner may need validation order, locking, scheduling, and broadcast semantics while skipping rendering. An intermediate new hire needs architectural reasons and ownership boundaries even when syntax is familiar.

### Cross-language matrix

| Known language → codebase language | Adaptation |
|------------------------------------|------------|
| JavaScript → Python | Compare decorators with higher-order wrappers, Pydantic with Zod, and context managers with `try/finally`; include a translation exercise. |
| TypeScript → Go | Compare structs/interfaces, explicit error returns/try-catch, and goroutines/async-await. |
| Python → JavaScript | Compare decorators/higher-order functions, comprehensions/`map` and `filter`, and generators/iterators. |
| Any → another | Put an 8–12-card side-by-side syntax quick reference before the main flow and use split-code comparisons throughout. |

### Scope checkpoint template

Present exactly one checkpoint before source mapping or drafting:

```text
I'll build a [tier] explainer for “[concept]” targeting a [level] [specialty].

Planned sections:
1. [section]
2. [section]
...

Skip: [known material or out-of-scope boundaries]
Extra depth: [persona-specific emphasis]
Reading time: [estimate]
Proceed, adjust, or cancel?
```

Apply requested adjustments and present the revised checkpoint; stop on cancellation. Approval covers the concept boundary, persona, tier, section list, omissions, and reading-time expectation.
