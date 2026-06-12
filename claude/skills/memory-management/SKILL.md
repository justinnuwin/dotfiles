---
name: memory-management
description: Use when the user wants to wrap up a session, review their learnings, consolidate or promote auto-saved memories, manage skills/rules/CLAUDE.md, deduplicate directives across scopes, or curate the directives accumulated in ~/.claude/projects/<id>/memory/. Triggers include "wrap up", "memory management", "review my memories", "consolidate learnings", "promote memory", "deduplicate rules", "what did I learn", "process feedback memories", and "manage skills". Reads each memory file, extracts individual directives within it, then runs a consolidation pass that uses subagents to discover existing directives across global, project, and path scopes (resolving project roots from session transcripts) and surfaces duplicates. Interviews the user per directive and folds each one into a CLAUDE.md section, an existing or new skill, or a rule file at the chosen scope (global/project/path) - preferring the broadest scope and pruning narrower-scope duplicates. Rewrites or deletes the source memory based on which directives were promoted.
---

# Memory Management

Curate auto-saved memories at directive granularity. Each memory may
contain more than one rule; treat each as independent. For every
directive, the user picks: fold into an existing CLAUDE.md / skill /
rule, create a new skill or rule, decline, or delete.

Interactive throughout. Show a diff and get approval before every
write. Never auto-select a promotion path. Always offer "decline to
formalize" as a no-op.

## Paths

- Memory files: `~/.claude/projects/<project-id>/memory/*.md`
- Index: `~/.claude/projects/<project-id>/memory/MEMORY.md`
- Promotion targets:
  - global: `~/.claude/CLAUDE.md`, `~/.claude/rules/<name>.md`, `~/.claude/skills/<name>/SKILL.md`
  - project: `<project-root>/CLAUDE.md`, `<project-root>/.claude/rules/<name>.md`, `<project-root>/.claude/skills/<name>/SKILL.md`
  - path: `<project-root>/<subdir>/CLAUDE.md`

Memory frontmatter fields: `name`, `description`, `metadata.type`
(user / feedback / project / reference), `metadata.originSessionId`.

For background on what counts as a directive, how to split ambiguous
bodies, and how to resolve a project id to its filesystem root, see
[references/directives.md](references/directives.md). Read this file
before Phase C.

## Phase A: pick scope

Ask the user which memories to process: current project, all projects,
or specific projects.

For "current project", determine the project id from `cwd`. If `cwd` is
`~` or otherwise unmappable, list `~/.claude/projects/` and ask.

For "all projects", enumerate every `~/.claude/projects/*/memory/` that
contains at least one `*.md` file other than `MEMORY.md`.

For "specific projects", let the user pick from the same enumeration.

## Phase B: load and parse

For each in-scope memory directory, read `MEMORY.md` and every sibling
`*.md`. Parse each file's YAML frontmatter for `name`, `description`,
`metadata.type`, `metadata.originSessionId`.

If `MEMORY.md` lists entries whose files are missing (or files exist
without an index entry), treat the filesystem as truth, warn once, and
continue.

## Phase C: extract directives

Read `references/directives.md` for splitting rules. For each memory
file, split the body into directives and assign each one a stable id
`<memory-name>#<n>` starting at 1. Capture for each: verbatim text
span, one-line synopsis, inherited `metadata.type`.

If a file's directive count is ambiguous, surface the ambiguity and
ask the user before the summary table.

## Phase D: present summary

Render a table with columns:

```
# | project | source memory | type | synopsis | candidate target
```

`candidate target` is a *suggestion only* derived from the directive's
type and content (for example: "new rule", "fold into CLAUDE.md >
Philosophy", "merge into existing skill X").

Flag overlapping directives across files in a note below the table
(for example, "#3 and #7 both say 'verify before asserting' - merge
during interview?"). Ask the user to proceed or reorder/skip.

## Phase E: consolidation analysis

Build a map of directives already codified across scopes and use it to
detect duplication and propose hoisting. Run this as background research
so the Phase F interview has each directive's matches and consolidation
options attached.

Spawn one or more `Explore` subagents in parallel - one per scope tier
is a reasonable split. Each subagent's job:

1. Resolve project ids to filesystem roots using the transcript
   technique described in `references/directives.md`.

2. For each project root in scope, locate:
   - `<root>/CLAUDE.md` and any nested `*/CLAUDE.md` one level deep
     (path-scope candidates),
   - `<root>/.claude/skills/*/SKILL.md`,
   - `<root>/.claude/rules/*.md`.

3. Also enumerate global surfaces:
   - `~/.claude/CLAUDE.md`,
   - `~/.claude/skills/*/SKILL.md`,
   - `~/.claude/rules/*.md`.

4. For each discovered file, extract its rule statements (CLAUDE.md
   bullets and section names; SKILL.md frontmatter `description` plus
   body headings; rule files' rule sentences). Report back as a
   structured list with `scope`, `path`, `synopsis`, `verbatim span`.

Once results return, judge semantic similarity between each candidate
directive and the discovered corpus directly - no fuzzy-string library
required. Produce a consolidation worksheet with one entry per
directive, labeled with one of:

- `none` - no existing match; promote normally.
- `redundant-with-broader` - already covered at a broader scope (the
  candidate would land at project but global already states the rule).
  Recommendation: drop the candidate; do not promote.
- `same-scope-duplicate` - an equivalent already exists at the target
  scope. Recommendation: merge into the existing file rather than
  create new.
- `hoist-candidate` - duplicates of this rule exist at narrow scopes
  across multiple places. Recommendation: promote the candidate to the
  broadest covering scope and remove the narrow-scope copies.

Present the worksheet to the user before Phase F, ordered by directive
id.

## Phase F: per-directive interview

For each directive in order:

1. Print the directive's verbatim text plus its source memory location.
2. Print the Phase E recommendation, including the path(s) of any
   existing matches and their scope.
3. Ask the action. Always present these six options verbatim, in this
   order, regardless of what Phase E recommended:

   - (a) fold into an existing CLAUDE.md / skill / rule,
   - (b) create a new skill,
   - (c) create a new rule file,
   - (d) decline to formalize - leave the directive in the memory file
     as-is, no promotion, no deletion,
   - (e) delete the directive (no promotion; remove it from memory),
   - (f) apply the Phase E consolidation recommendation as-is.

   When Phase E flagged a consolidation, mark (f) as the default but
   never auto-select it. The user must explicitly choose. Option (d) is
   always offered; never coerce the user into picking a promotion path.

4. If a/b/c/f, ask scope: global, project, or path. If path, ask which
   subdir. Pre-select the broadest scope the consolidation analysis
   supports; warn before letting the user pick a narrower scope that
   would duplicate an existing broader rule.

5. If (a) or (f), list candidate targets in that scope (every CLAUDE.md,
   every SKILL.md with frontmatter `name` plus `description`, every
   `rules/*.md`) one level deep under the scope root, with the Phase E
   matches pinned at the top. User picks or types a path.

6. If (b) or (c), propose `name` and `description` by stripping the
   `feedback-` / `user-` / `project-` prefix from the memory's
   frontmatter `name` and appending a disambiguator if multiple
   directives came from the same file. User confirms or edits.

7. Record the decision and any consolidation side-effects (files to
   prune). Do not act yet. A (d) decline excludes the directive from
   Phase G; Phase H treats it as "kept" and preserves its verbatim span
   when the memory file is rewritten.

## Phase G: preview and apply

For each directive marked for promotion, show the exact change as a
diff or full file content, get approval, then write.

- CLAUDE.md fold: condense the directive's `**Why:**` and
  `**How to apply:**` into one or two lines. Always ask which section
  to append under; suggest a default by `metadata.type`
  (feedback / user -> Philosophy, project -> Project integration,
  reference -> Technical standards) but never auto-pick.
- New skill: scaffold `<scope>/skills/<name>/SKILL.md` with `name` and
  `description` frontmatter and a body adapted from the directive.
- New rule: write `<scope>/rules/<name>.md` with the directive's
  content, lightly cleaned (strip `originSessionId`, neutralize
  first-person session references). Create the rules dir if missing.
- Existing skill or rule: append a new section drawn from the
  directive's synopsis.
- Consolidation prune: for each existing narrow-scope file flagged by
  Phase E for removal, show the deletion or in-file removal as part of
  the same preview. Apply only after approval.

## Phase H: rewrite or delete source memories

For each affected memory file, look at the disposition of its
directives:

- All directives promoted or deleted: remove the `.md` file and its
  line in `MEMORY.md`.
- Some directives kept (declined): rewrite the file with only the kept
  directive spans preserved verbatim. Keep the original frontmatter; if
  the kept set no longer matches the original `description`, regenerate
  `description` and ask the user to confirm before writing.
- All directives kept: leave the file untouched.

If `MEMORY.md` becomes empty, leave the empty file in place.

## Phase I: final report

Print three blocks:

- Per directive:
  `<directive-id> -> <destination | kept | deleted | consolidated-into:<path>>`
- Per memory file: `<memory> -> <rewritten | deleted | untouched>`
- Per pruned file: `<path> -> <deleted | section-removed>`

Note any failures.

## Edge cases

- Empty memory dir: say "no memories to process" and exit.
- `cwd` not mappable: list projects, ask the user.
- `MEMORY.md` missing but files exist (or reverse): treat filesystem as
  truth; warn once; continue.
- Fold target file does not exist (project CLAUDE.md absent): offer to
  create it with a stub header, then append.
- Two directives overlap across files: flag in Phase D; ask whether to
  merge during the interview.
- Rules dir does not exist: create on demand. Do not pre-create.
- User aborts mid-run: do not partially mutate. Only delete or rewrite
  a memory file after all of its directives' promotion writes are
  confirmed.
- Subagent cannot resolve a project id to a filesystem root (no session
  transcript on disk, or transcripts have no `cwd` record): skip that
  project from consolidation discovery; note it in the worksheet so the
  user can supply the path manually.
- Phase E finds a duplicate but the two rules differ in wording (same
  intent, different phrasing): surface both verbatim and ask the user
  whether to treat them as the same directive. Never auto-merge.
- A candidate is redundant-with-broader but the broader rule lives in a
  file the user wants to delete in the same run: detect the order
  dependency and apply the broader-scope edits first.

## Conventions

- ASCII only.
- Imperative voice.
- Minimal diffs. Do not invent unrelated cleanups.
- No name-drop framing (no "Torvalds test", "Hickey says...", etc.).
- Verify before asserting. Do not claim a target file exists without
  reading it first.
- Always show a diff or full file preview before writing.
- Always offer "decline to formalize" as a no-op option.
