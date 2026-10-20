# System specific Rules/Guidelines/etc.

@~/.CLAUDE.local.md

# Personal coding rules

Applies to every session. Project `CLAUDE.md` and explicit in-session instructions override these rules when they conflict.

## Philosophy

**Core beliefs**
- Incremental progress over big bangs: small changes that compile and pass tests.
- Learn from existing code: study surrounding patterns before adding new ones.
- Clear intent over clever code.

**Simplicity**
- Single responsibility per function/class.
- No premature abstractions.
- If you have to explain it, it is too complex.
- Follow the DRY (Do not Repeat Yourself) principal, do not duplicate existing functionality.

Write the minimum that solves the problem. Nothing speculative, nothing decorative:
- No abstractions for one-off code.
- No configurability nobody asked for.
- No type or name aliases that mask the underlying type or value without good reason.
- No class hierarchy when a struct and two functions do the job.
- No error handling for fantasy scenarios.

_Keep diffs minimal._

**Lead with the data model**

Start with the data model. If the data shape is wrong, everything that follows will be wrong.
- State the data layout before the implementation.
- Prefer structures that make the common case obvious.
- Eliminate special cases by fixing the shape of the data.
- If the structure fights the algorithm, the structure is wrong.

**Surgical changes**

Touch only what you must. Clean up only your own mess.

When editing existing code:
- Do not refactor unrelated code.
- Do not rename for style points.
- Do not rewrite comments unless they became wrong.
- If something else is broken, mention it — no drive-by cleanups.

When your changes create orphans (unused imports/vars/helpers from code you removed), delete them.
Do not delete pre-existing dead code unless asked.
Every changed line should have a direct reason to exist; otherwise it's churn.

**Prove your work**

Code is cheap. Show the failing test, the numbers, the working patch.
Do not disable tests, assume race conditions, assume a hypothesis from context to achieve a specific outcome; ground statements with code references to back them up.
- Prefer a working patch over a beautiful plan.
- Define success in measurable terms.
- Verify with tests, benchmarks, or reproducible output.
- If you can not prove it, it is not done.
- Cite evidence for every claim, including supporting details; otherwise prefix it with "Unverified:".
- Before sending, check that each "so"/"because" claim has evidence attached.

For multi-step tasks, state a brief plan:
1. [step] -> verify: [check]
2. [step] -> verify: [check]
...

## Response style

Answer exactly what was asked. No unrequested extra options, caveats, or explanation of what you didn't do.

@~/.dotfiles/claude/coding_standards.md

