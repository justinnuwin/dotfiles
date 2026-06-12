# What counts as a directive

A directive is a self-contained rule, fact, or preference inside a
memory body. The skill operates at directive granularity, not file
granularity - a single memory file may contain more than one
directive, and each one is interviewed independently in Phase F.

## Common shapes

**Structured feedback / project block** (the most common case):

```
<rule statement>

**Why:** <one-line motivation>

**How to apply:** <when and how the rule kicks in>
```

The whole block is one directive. The frontmatter `metadata.type` is
typically `feedback` or `project`.

**Bullet list:**

```
- <rule 1>
- <rule 2>
- <rule 3>
```

Each bullet is its own directive when the bullets are independent
rules. If the bullets together form a single grouped claim (e.g.,
sub-points under one heading), treat the heading + bullets as one
directive.

**Headed sections:**

```
## <topic A>
<body>

## <topic B>
<body>
```

Each section is one directive.

**Freeform paragraph:** treat as one directive.

**Multiple Why/How blocks in one file:**

```
<rule 1>
**Why:** ...
**How to apply:** ...

<rule 2>
**Why:** ...
**How to apply:** ...
```

Each `<rule> + Why + How` block is its own directive. This is the
multi-directive case the user cares about most - do not collapse them.

## Splitting heuristic

Split conservatively. A useful test: does each candidate directive
stand on its own as an instruction you could promote into a single
CLAUDE.md bullet or a single rule file? If yes, it is its own
directive. If two adjacent spans only make sense read together, they
are one directive.

## Ambiguous cases

Surface ambiguity to the user in Phase C rather than guessing.
Examples:

- Two bulleted lists nested under one heading: ask whether the heading
  binds them or whether they are independent.
- A long paragraph with multiple sentence-level rules: ask whether to
  split sentence by sentence or treat as one.
- A "Why" or "How to apply" block that mixes reasoning for several
  rules: surface verbatim and ask the user to mark boundaries.

When the user splits or merges directives during Phase C, use their
decision for the rest of the run.

## Stable ids

Assign each directive a stable id `<memory-name>#<n>` starting at 1,
in document order. Use the id in summaries (Phase D), the consolidation
worksheet (Phase E), the interview prompts (Phase F), and the final
report (Phase I) so the user can trace each row back to its source
span.

## Project-id to filesystem-root mapping

Project memory directories are named like `-home-justin--claude` -
the path is encoded by replacing separators with `-` and prefixing
with `-`. The encoding is lossy: `--` may stand in for `.` or `/`
(`-home-justin--claude` could be `/home/justin/.claude` or
`/home/justin/-claude` in principle). Do not invert the encoding by
string replacement.

Resolve the real filesystem root by reading recent session transcripts
at `~/.claude/projects/<id>/*.jsonl` and pulling the recorded `cwd`
field from a session-start record. Cache the mapping
`<project-id> -> <fs root>` for the rest of the run. If no transcript
records a `cwd` for a given project, skip it from consolidation
discovery and note this on the worksheet.
