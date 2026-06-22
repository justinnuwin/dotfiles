# Additional Rules/Guidelines/etc.

@~/local.CLAUDE.md

# Personal coding rules

Applies to every session. Project `CLAUDE.md` and explicit in-session
instructions override these when they conflict.

## Philosophy

**Core beliefs**
- Incremental progress over big bangs: small changes that compile and pass tests.
- Learn from existing code: study surrounding patterns before adding new ones.
- Pragmatic over dogmatic: adapt to project reality.
- Clear intent over clever code: be boring and obvious.

**Simplicity**
- Single responsibility per function/class.
- No premature abstractions. Three similar lines beat a wrong abstraction.
- No clever tricks; choose the boring solution.
- If you have to explain it, it's too complex.

Write the minimum that solves the problem. Nothing speculative, nothing
decorative, nothing "enterprise":
- No abstractions for one-off code.
- No configurability nobody asked for.
- No class hierarchy when a struct and two functions do the job.
- No error handling for fantasy scenarios.
- If 50 lines do it, don't write 500.

Keep diffs minimal.

**Lead with the data model**

Start with the data model. If the data shape is wrong, the rest is
performance-hostile theater.
- State the data layout before the implementation.
- Prefer structures that make the common case obvious.
- Eliminate special cases by fixing the shape of the data.
- If the structure fights the algorithm, the structure is wrong.

**Surgical changes**

Touch only what you must. Clean up only your own mess.

When editing existing code:
- Don't refactor unrelated code.
- Don't rename for style points.
- Don't rewrite comments unless they became wrong.
- If something else is broken, mention it — no drive-by cleanups.

When your changes create orphans (unused imports/vars/helpers from code you
removed), delete them. Don't delete pre-existing dead code unless asked.

Every changed line should have a direct reason to exist; otherwise it's
churn.

**Prove your work**

Code is cheap. Show the failing test, the numbers, the working patch.
- Prefer a working patch over a beautiful plan.
- Define success in measurable terms.
- Verify with tests, benchmarks, or reproducible output.
- If you can't prove it, it's not done.

For multi-step tasks, state a brief plan:
1. [step] -> verify: [check]
2. [step] -> verify: [check]

## Technical standards

**Architecture**
- Composition over inheritance; dependency injection over globals.
- Interfaces over singletons — testability and flexibility.
- Explicit over implicit: clear data flow and dependencies.
- Test-driven when possible. Never disable tests; fix them.

**Errors**
- Fail fast at boundaries (user input, external I/O, untrusted data) with
  descriptive messages that include the relevant context.
- Inside trusted code, don't validate things that can't happen — let the
  invariant carry.
- Handle errors at the level that can do something useful about them.
- Never silently swallow exceptions.

## Project integration

**Learn the codebase**
- Find similar features/components first; mirror their patterns.
- Reuse the project's libraries, utilities, and test patterns.

**Tooling**
- Use the project's existing build system, test framework, formatter, linter.
- Respect `.editorconfig` and linter configs.
- Don't introduce new tools without strong justification.

**Style**
- Follow existing conventions in the project.
- ASCII only in code files. No unicode characters anywhere in source —
  including comments and string literals. If a string semantically needs a
  unicode character, use the escape (`"→"`, `"é"`), not the literal
  byte. Unicode in markdown/docs is fine.
