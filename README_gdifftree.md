# gdifftree - Vim-powered `git show` / `git diff` viewer

A pair of shell aliases (`gshow`, `gdiff`) that open a commit or diff in Vim
with one tab per changed file (vertical diffs via fugitive), plus a custom Vim
sidebar (`gdifftree`) that lists exactly those files as a collapsible tree with
per-file change stats. Selecting a file jumps to (or reopens) its diff tab.

This document captures the design, the code structure, the conventions used, the
non-obvious implementation lessons, and the planned next steps.

This project is distinct from the diffview.nvim plugin which performs similar
functionality but is completely powered from within vim. This project actively
incorporates git from the shell to perform the heavy lifting.

---

## Goals / requirements

Accumulated over the course of building this:

1. `gshow [rev]` shows a commit (default `HEAD`): tab 1 = commit description,
   optional notes tab, then one vertical-diff tab per changed file.
2. `gdiff [args]` shows a diff: working-tree (no args), a single revision
   (rev vs working tree), two revisions (rev vs rev), or `--staged`/`--cached`
   (index vs HEAD - the *actual staged change*, not the whole file). Arbitrary
   `git diff` flags pass through for file selection.
3. A sidebar shows only the files involved, as a directory tree (like NERDTree
   scoped to the diff), shown identically in every tab.
4. Selecting a file switches to the tab already showing its diff (never clobbers
   the layout by loading it into the current window); selecting a directory
   toggles it; if a file's tab was closed, selecting it reopens the diff.
5. Closing a diff window (`:q`) closes the whole tab.
6. The two diff panes stay equalized on tab switch and window resize.
7. Matching diff folds on both panes (only the changed regions shown).
8. Per-file added/removed line counts in the sidebar, aligned into one column.
9. A gray **title bar** (not a tab bar): `Git Diff/Show <what> (N tabs open)`
   centered, with the previous file (`gT` target) at the far left and the next
   file (`gt` target) at the far right.
10. The sidebar pane is titled `gdifftree - Tabs Open`.
11. For working-tree diffs, the sidebar stats refresh on every `:w` (edits made
    in the diff update the stats live).
12. No prompts for swap files / already-open files (open read-only instead).
13. No spurious red clangd/clang-tidy diagnostics in the diff (coc navigation is
    kept; only diagnostics are disabled per buffer).
14. The tree auto-expands when it fits in ~150% of the screen height, else all
    directories start collapsed.
15. The sidebar is mouse-clickable (click a file to jump, a folder to toggle).

---

## Code structure

Three files (plus one line in the Vim config):

### `shell/modules/git_aliases.sh`

The user-facing entry points and the glue that launches Vim.

- `_gdifftree_tmux_zoom` - zoom the tmux pane if inside tmux.
- `_gdifftree_vstr <s>` - emit a single-quoted Vimscript string literal
  (doubles embedded `'`; uses `sed` so it behaves identically in bash and zsh).
- `_gdifftree_entry <label> <file> <setup> <stat>` - emit one Vimscript dict
  literal `{'label':.., 'file':.., 'setup':.., 'stat':..}`.
- `gshow [rev]` - collects the commit description, notes, and changed files;
  builds the `entries` list; launches Vim.
- `gdiff [args]` - parses args (staged/cached, revision count), picks the diff
  setup, collects files + numstat, builds `entries` and the `refresh` command;
  launches Vim.

Both build an `args` array (what `vim -p` opens: one buffer per tab) parallel to
an `entries` Vimscript list, then run:

```
vim --cmd "set tabpagemax=<N>" \
    --cmd "let g:NERDTreeHijackNetrw = 0" \
    --cmd "autocmd BufEnter * let b:coc_diagnostic_disable = 1" \
    --cmd "autocmd SwapExists * let v:swapchoice = 'o'" -p <files...> \
    +"cd <toplevel>" \
    +"call GDiffTreeSetup(<title>, <entries>, <refresh>)"
```

### `vim/git_diff_tree.vim`

The sidebar plugin. Loaded once (guarded by `g:loaded_git_diff_tree`). Owns all
tab setup, the sidebar rendering, and the title bar.

**Data model (script-scoped state):**

- `s:entries` - list of `{'label','file','setup','stat', ['status','orig_path',
  'pinned']}`; the list **index is the stable tab id** (survives tab
  reordering/closing). `label` is the repo-relative (new) path; `file` is the
  buffer to open; `setup` is the Ex command that turns that buffer into the diff;
  `stat` is the display string (`+N -M`, `bin`, or empty); `status` is the git
  status letter (`A`/`M`/`D`/`R`/`C`) shown in the far-left column; `orig_path`
  is the pre-rename path (R/C, drives the diff); `pinned` lifts a meta entry
  (commit description / notes) above the tree.
- `s:tree` - nested `{'dirs': {name: node}, 'files': {name: id}, 'name','path'}`
  built from the entry labels; file leaves store the entry id.
- `s:collapsed` - set of collapsed directory paths.
- `s:line_to_node` - maps a sidebar line number to `{'type':'dir','path'}` or
  `{'type':'file','id'}` (rebuilt on every render; non-selectable lines like the
  header are simply absent).
- `s:refresh` - argv list for the numstat refresh command (empty = no refresh).
- `s:pending_close` - tab ids queued for deferred close.

**Public API (called from the shell):**

- `GDiffTreeSetup(title, entries, refresh)` - builds the tree, sets the title
  bar, applies each entry's `setup` to its already-open tab, tags each tab with
  `t:gdifftree_id` / `t:gdifftree_label`, opens the sidebar in every tab, and
  registers the autocmds.
- `GDiffTreeTitle()` - `tabline` function; renders the title bar.

**Internals (roughly in flow order):**

- `s:BuildTree`, `s:NewNode`, `s:CountNodes`, `s:CollapseAll` - tree construction
  and the auto-expand-vs-collapse decision.
- `s:PrepareTab(id)` - run one entry's setup, tag the tab, match diff folds, open
  the sidebar. Reused for reopening a closed tab.
- `s:SetupTitleBar`, `GDiffTreeTitle` - the gray centered title bar with
  prev/next file names.
- `s:OpenSidebar`, `s:SidebarWinnr`, `s:EnsureSidebar`, `s:SetupSyntax` - the
  sidebar window (a single reused scratch buffer shown in every tab).
- `s:BuildLines`, `s:Rebuild`, `s:Render` - build the tree lines, align the stat
  column, write the buffer, and park the cursor on the current tab's entry.
- `s:Select`, `s:GotoOrReopen` - handle `<CR>`/`o`/click: toggle a directory, or
  jump to / reopen a file's tab (by stable id).
- `s:RefreshStats` - re-run numstat on `:w`, update every entry's `stat`,
  re-render.
- `s:OnQuitPre`, `s:DrainClose` - close the whole tab when a diff window is
  quit (deferred via `timer_start(0, ...)`).

### `vim/vimrc` and `vim/plugins.vim`

- `vimrc`: one line sources `vim/git_diff_tree.vim` alongside the other helpers.
- `plugins.vim`: `jistr/vim-nerdtree-tabs` was removed (the sidebar replaced it).

---

## Data flow

```
gshow/gdiff (shell)
  |  git plumbing: diff-tree/diff --name-only, --numstat, notes, show
  |  build args[] (files, in tab order) and entries[] (parallel dicts)
  v
vim -p args...  +cd  +call GDiffTreeSetup(title, entries, refresh)
  |  vim opens one tab per file (tabpagemax raised to cover all files)
  v
GDiffTreeSetup (plugin)
  |  BuildTree(labels) ; per tab: PrepareTab(id) -> run setup, tag, open sidebar
  |  register autocmds (TabEnter/QuitPre/VimResized[/BufWritePost])
  v
interaction: Select -> GotoOrReopen ; :q -> OnQuitPre/DrainClose ; :w -> RefreshStats
```

The shell never writes a temporary Vimscript file; everything is passed as
`--cmd`/`+cmd` arguments and a single `GDiffTreeSetup(...)` call.

---

## Coding preferences / conventions

- **ASCII only** in code, comments, and strings (arrows written `->`, `<-`).
- **Descriptive variable names** - no single-letter locals or loop variables in
  either file (e.g. `changed_file`, `rev_count`, `stat_path`, `l:entry_id`,
  `l:sidebar_winnr`, `l:prev_win`).
- **Legacy Vimscript** (`function!`, `let l:...`) to match the repo's existing
  `.vim` helpers (`bazel_utils.vim`, `cpp_utils.vim`); the plugin is `source`d,
  not a `vim9script`.
- **Portable shell** - the module has a `#!/bin/bash` shebang but is sourced by
  zsh, so anything shell-specific is validated against zsh (`zsh -n`) and quoting
  uses `sed`/`printf` rather than `${//}` (which differs between bash and zsh).
- **Minimal, surgical changes**; comments explain *why*, especially the
  non-obvious workarounds below.

---

## Non-obvious implementation notes (lessons learned)

These are the traps that cost real debugging time; keep them in mind before
"simplifying":

- **`tabpagemax` defaults to 10.** `vim -p` silently drops tabs past 10, so a
  34-file commit showed only 10 diffs. We raise it to the file count via
  `--cmd "set tabpagemax=N"`.
- **NERDTree netrw hijack -> E121.** `g:NERDTreeHijackNetrw` (on by default)
  turns any *directory* buffer into a NERDTree window tree; in this multi-tab
  layout its `BufLeave` autocmd crashes with `E121: Undefined variable:
  b:NERDTree`. A modified **submodule** is a directory, so it triggered this. We
  (a) skip directories/submodules from the file list and (b) set
  `g:NERDTreeHijackNetrw = 0` for the session.
- **Red C++ `&` = coc/clangd diagnostics**, not syntax and not the diff colors.
  clangd can't compile the diff buffers, so it paints spurious diagnostics. We
  set `b:coc_diagnostic_disable = 1` per buffer (keeps navigation/hover).
- **`--staged` is a flag, not a revision.** Treating it as a rev
  (`Gvdiffsplit --staged`) showed the whole file. Staged now maps to
  `Gedit :0:% | Gvdiffsplit HEAD` (index vs HEAD).
- **Fold asymmetry** was a foldlevel difference; both diff windows are forced to
  `foldmethod=diff foldlevel=0`.
- **Stable tab ids** (`t:gdifftree_id`, = entry index) are what make "jump to
  tab", "reopen closed tab", and "close-tab-on-quit" robust against tab
  reordering. Do not key off tab numbers or buffer names (diff buffers become
  `fugitive://...` blobs).
- **Can't close a tab from inside `QuitPre`** while the `:q` is unwinding; we
  defer via `timer_start(0, ...)`.
- **Testing artifacts:** headless `vim -u ~/.vimrc -es` runs in **'compatible'
  mode**, which makes coc/fugitive/quick-scope throw noise (`E10`, `E15`, ...)
  that does *not* occur in a real terminal. Always test with `-N` (nocompatible)
  and ignore coc's `-es`-only errors.

---

## File statuses

Every changed file carries a git status, sourced from `git diff[-tree]
--name-status -M -z` (paired with `--numstat -M -z` for line counts; both are
NUL-parsed, so spaces and renames are handled). A colored symbol sits in a
far-left column:

| Status | Meaning | Default color |
| --- | --- | --- |
| `A` | added | green |
| `M` | modified | yellow |
| `D` | deleted | red |
| `R` | renamed / moved | magenta |
| `C` | copied | cyan |

`diff_setup` is built per status (by `_gdifftree_diff_setup`) so each diff is
meaningful: added shows empty-vs-new, deleted old-vs-empty, renamed/copied the
old blob at the old path vs the new content, modified the same path on both
sides. The older side is always on the left.

- Symbols are configurable via `g:gdifftree_status_symbols` (defaults are Nerd
  Font octicon diff glyphs); set it to `{'A':'A','M':'M','D':'D','R':'R','C':'C'}`
  for plain letters.
- Copy detection (`C`) is off by default; set `GDIFFTREE_FIND_COPIES=1` to enable
  `-C --find-copies-harder` (O(files^2) on large trees).

---

## Next steps

### 1. Add tests

Currently verified only by manual headless runs (`vim -Nu NONE -es -S probe.vim`)
and `zsh -n`. We want a real, repeatable suite.

- Consider [`vader.vim`](https://github.com/junegunn/vader.vim) for the Vimscript
  side, or a hand-rolled headless runner that sources `git_diff_tree.vim`, calls
  `GDiffTreeSetup(...)` with fixtures, and asserts on buffer contents / tab
  state.
- Run with `-N` (nocompatible); do **not** load the full `~/.vimrc` (coc etc.
  are `-es`-hostile). Source only the plugin.
- Cases to cover: tree build + sort order; auto-expand vs collapse threshold;
  directory toggle; select-to-tab; reopen-after-close; close-tab-on-`:q` (drive
  the `timer` with `:sleep`); stat-column alignment; title bar prev/next +
  wraparound + pluralization; `RefreshStats` against a temp git repo.
- Shell side: a small bats-style or plain-sh harness asserting on the generated
  `entries`/`refresh`/`diff_setup` strings for each arg pattern (`""`,
  `--staged`, `<rev>`, `<rev1> <rev2>`), and the submodule/dir filtering.

### 2. Conversion to a real Vim plugin

Today it is a single `source`d file wired to the shell aliases. Promote it to a
standalone, installable plugin:

- Layout: `plugin/gdifftree.vim` (guards + commands + default maps),
  `autoload/gdifftree.vim` (move `GDiffTreeSetup` and internals under an
  `gdifftree#` autoload namespace for lazy loading), `doc/gdifftree.txt` (help).
- Expose a documented public API so the shell aliases (and others) call
  `gdifftree#Setup(...)` instead of a global function.
- Make it installable via vim-plug from its own repo (or a local path), and have
  the dotfiles depend on it rather than sourcing a file.
- Keep the shell aliases as the "launcher"; the plugin should be usable on its
  own given a title + entries + refresh spec.

### 3. Built-in hotkeys for easy navigation

Right now navigation relies on `gt`/`gT` (tabs) and the sidebar
`<CR>`/`o`/click. Add first-class, discoverable, configurable mappings:

- Global (in the diff session): next/prev file, focus sidebar, toggle sidebar
  visibility, close current tab, expand-all / collapse-all, jump to next/prev
  change (`]c`/`[c` are built-in in diff mode - document them).
- Sidebar-local: expand/collapse under cursor, open in the other pane, quit all.
- Make the mapping set opt-in/overridable (`g:gdifftree_no_default_maps`,
  `<Plug>` mappings) so users can rebind. Document in `doc/gdifftree.txt`.

---

## Quick reference

| Action | Key / command |
| --- | --- |
| Open commit | `gshow [rev]` |
| Open working diff | `gdiff` |
| Open staged diff | `gdiff --staged` |
| Diff revisions | `gdiff <rev>` or `gdiff <rev1> <rev2>` |
| Next / prev file tab | `gt` / `gT` |
| Select file / toggle dir (sidebar) | `<CR>`, `o`, or mouse click |
| Close a file's tab | `:q` in a diff pane |
| Next / prev change in file | `]c` / `[c` (built-in diff) |

Config: `g:gdifftree_width` (sidebar width, default 52);
`g:gdifftree_status_symbols` (status glyphs); `GDIFFTREE_FIND_COPIES=1` (enable
copy detection).
