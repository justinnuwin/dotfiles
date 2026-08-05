## Technical standards

**Architecture**
- Composition over inheritance; dependency injection over globals.
- Interfaces over singletons — testability and flexibility.
- Explicit over implicit: clear data flow and dependencies.
- Test-driven when possible. Never disable tests; fix them.

**Errors**
- Fail fast at boundaries (user input, external I/O, untrusted data) with descriptive messages that include the relevant context.
- Inside trusted code, don't validate things that can't happen — let the invariant carry.
- Handle errors at the level that can do something useful about them.
- Never silently swallow exceptions.

**Comments/Documentation**
- Do not add/expand comments unnecessarily; especially with notes about the current prompt or previous state (the code itself shall be clearly self documenting, do not describe how we got here-version control solves this).
- Do not add comments or documentation on code which does *not* exist.
- Comments, where needed for clarity, should only describe the code at hand. Do not describe its callers.
- Keep each comment attached to the code it actually documents.
- A function's header comment describes its intended behavior — the contract a caller relies on - not how it is implemented. Push mechanism and implementation notes into the body, beside the code they explain, or drop them.
- In languages that don't declare parameters in the signature (shell, etc.), the header comment must document the arguments.
- Drop parentheticals (and asides) that just restate a detail visible in the code or a nearby comment; keep those carrying a non-obvious why, an external fact, or a gotcha.

**Function order**
- Order functions within a file definition-before-use: a callee appears before its callers, so top-level entry points land last. Group related functions, and sequence the groups the same way.
- Defer to a language's established convention when it dictates otherwise.

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
- If a linter enforces only ASCII, do not force unicode characters into comments by inserting unicode escape sequences. Use a longer ASCII alternative.
