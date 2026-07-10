#!/bin/bash

alias gvis="git log --graph --oneline --color"
alias gvisualize="git log --graph --full-history --all --color --pretty=format:'%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s'"
alias gl="git log --oneline"
alias gls="git log --oneline --name-status"
alias glstat="git log --oneline --stat"
alias groot="git rev-parse --show-toplevel"
alias gs="git status --short --branch"
alias gsh="git show"
alias gc="git commit"
alias gcanoe="git commit --amend --no-edit"
alias gcurb="git branch --show-current"
alias grst="git reset"
alias grsthrd="git reset --hard"
grsthrdocurb() {
  git reset --hard "origin/$(git branch --show-current)"
}
alias grb="git rebase"
alias gwt="git worktree"
# Remove the current worktree and its check-ed out branch
git_remove_worktree_delete_local_branch() {
    if [[ ! -f "$(groot)/.git" ]]; then
        echo "Not in a git worktree" 2>&1
        return 1
    fi
    local worktree
    worktree="$(groot)"
    local branch
    branch="$(gcurb)"
    cd "$(dirname "$(git rev-parse --git-common-dir)")" || return 1
    git worktree remove "$worktree"
    # shellcheck disable=SC2181
    if [[ $? -gt 0 ]]; then
        cd "$worktree" || return 1
        return 1
    fi
    echo "Removed worktree $worktree"
    if [[ $branch != "" ]]; then
        git branch -D "$branch"
    fi
    cd "$(dirname "$worktree")" || return 1
    return 0
}
alias gwtrmb="git_remove_worktree_delete_local_branch"
alias gsw="git switch"
alias cdgroot="cd \$(groot)"
alias pushdgroot="pushd \$(groot)"
# Sometimes very large repos will have custom fetch refspecs to minimize on
# number of branches/tags pulled. Manually fetch before switching to the branch
gfsw() {
  git fetch --force --refmap="+$1:refs/remotes/origin/$1" origin "$1"
  if git rev-parse --quiet --verify "$1"; then
    git switch "$1"
  else
    git switch -c "$1" "origin/$1"
  fi
  return 0
}

# ==============================================================================
# Git vim-powered diff/show aliases
#
# gshow / gdiff open each changed file's diff in its own Vim tab (vertical
# split) and show a narrow sidebar listing exactly those files. The sidebar and
# its "select an entry -> jump to that file's existing diff tab" behavior are
# provided by vim/git_diff_tree.vim (function GDiffTreeSetup); no temporary
# Vimscript file is written or sourced.
#
# REQUIRED VIM PLUGIN:
#   - tpope/vim-fugitive   (:Gedit, :Gvdiffsplit)
# ==============================================================================

# Zoom the current tmux pane if we are in tmux and it is not already zoomed.
_gdifftree_tmux_zoom() {
    if [ -n "$TMUX" ] && [ "$(tmux display-message -p '#{window_zoomed_flag}')" -eq 0 ]; then
        tmux resize-pane -Z
    fi
}

# Emit a single-quoted Vimscript string literal, escaping embedded quotes by
# doubling them (sed keeps this identical across bash and zsh).
_gdifftree_vstr() {
    printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"
}

# Emit one Vimscript dict literal for a tab:
#   {'label':.., 'file':.., 'setup':.., 'stat':.. [, 'pinned': 1]}
# A non-empty 5th argument marks the entry as pinned: the sidebar lists it above
# the file tree (used for the commit description and notes) instead of within it.
_gdifftree_entry() {
    printf "{'label': %s, 'file': %s, 'setup': %s, 'stat': %s" \
        "$(_gdifftree_vstr "$1")" "$(_gdifftree_vstr "$2")" \
        "$(_gdifftree_vstr "$3")" "$(_gdifftree_vstr "$4")"
    [ -n "$5" ] && printf ", 'pinned': 1"
    printf "}"
}

# ------------------------------------------------------------------------------
# gshow - open a commit's diff in Vim.
#
#   1. Each changed file's diff opens in its own tab as a vertical split.
#   2. With no argument the revision defaults to HEAD.
#   3. Tab 1 shows the commit description (title and body), pinned above the
#      tree in the sidebar.
#   4. Any git notes attached to the commit appear in a collapsible "Commit
#      Notes" folder pinned below the commit description, one entry per namespace.
#   5. A sidebar lists every tab; selecting an entry jumps to that tab.
#   6. The tmux pane is zoomed while viewing when inside a tmux session.
# ------------------------------------------------------------------------------
gshow() {
    local rev="${1:-HEAD}"
    if ! git rev-parse --verify "$rev" >/dev/null 2>&1; then
        echo "Error: Revision '$rev' not found." >&2
        return 1
    fi

    local toplevel tmpdir
    toplevel=$(git rev-parse --show-toplevel)
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    # Commit description (title + body) shown in the first tab.
    git show --no-patch --pretty=fuller "$rev" > "$tmpdir/COMMIT_DESCRIPTION"

    # Collect any git notes attached to the commit, one file per namespace. Each
    # becomes a pinned "Commit Notes/<namespace>" entry, so the sidebar groups
    # them in a collapsible "Commit Notes" folder pinned above the diff tree.
    mkdir -p "$tmpdir/notes"
    local ref content note_ns
    local note_namespaces=()
    for ref in $(git for-each-ref --format='%(refname)' refs/notes); do
        content=$(git notes --ref="$ref" show "$rev" 2>/dev/null)
        if [ -n "$content" ]; then
            note_ns="${ref##*/}"
            echo "$content" > "$tmpdir/notes/$note_ns"
            note_namespaces+=("$note_ns")
        fi
    done

    # One entry per changed file (path relative to the repo root). Skip
    # submodules/directories: they cannot be shown as a vertical diff, and
    # opening a directory would otherwise trigger NERDTree's netrw hijack.
    local files=() changed_file
    while IFS= read -r changed_file; do
        [ -n "$changed_file" ] && [ ! -d "$toplevel/$changed_file" ] && files+=("$changed_file")
    done < <(git diff-tree --no-commit-id --name-only -r "$rev")

    # Per-file added/removed line counts for the sidebar (keyed by path; renamed
    # files simply get no stat).
    typeset -A stats
    local added deleted stat_path
    while IFS=$'\t' read -r added deleted stat_path; do
        [ -z "$stat_path" ] && continue
        if [ "$added" = "-" ]; then stats[$stat_path]="bin"; else stats[$stat_path]="+$added -$deleted"; fi
    done < <(git diff-tree --numstat --no-commit-id -r "$rev")

    # Tab order: commit description, optional notes, then one tab per file. args
    # is what `vim -p` opens (one buffer per tab); entries is the parallel list
    # of {label, file, setup, stat} the plugin uses to build the diffs, tag tabs,
    # show stats, and reopen a tab if it is closed. The per-file setup is wrapped
    # in try/catch so an added/deleted/binary file cannot abort setup or leak
    # errors.
    local diff_setup="try | Gedit $rev:% | Gvdiffsplit $rev~1 | catch | endtry"
    local args=("$tmpdir/COMMIT_DESCRIPTION")
    local entries="[$(_gdifftree_entry "Commit Description" "$tmpdir/COMMIT_DESCRIPTION" "setlocal readonly nomodifiable" "" "pinned")"
    for note_ns in "${note_namespaces[@]}"; do
        args+=("$tmpdir/notes/$note_ns")
        entries+=", $(_gdifftree_entry "Commit Notes/$note_ns" "$tmpdir/notes/$note_ns" "setlocal readonly nomodifiable" "" "pinned")"
    done
    for changed_file in "${files[@]}"; do
        args+=("$toplevel/$changed_file")
        entries+=", $(_gdifftree_entry "$changed_file" "$toplevel/$changed_file" "$diff_setup" "${stats[$changed_file]}")"
    done
    entries+="]"

    _gdifftree_tmux_zoom

    # --cmd runs before any file is loaded:
    #   - tabpagemax must cover every file or Vim's default of 10 silently drops
    #     the rest (only the first 10 diffs would open).
    #   - SwapExists opens files read-only instead of prompting when a file is
    #     already open elsewhere or has a stale swap file.
    #   - Disabling NERDTreeHijackNetrw stops NERDTree from taking over any
    #     directory buffer (e.g. the notes dir), which otherwise crashes its
    #     BufLeave autocmd with E121 in this multi-tab layout.
    #   - b:coc_diagnostic_disable turns off coc/clangd diagnostics per buffer
    #     (clangd cannot compile the diff buffers, so it paints spurious red
    #     diagnostics, e.g. on C++ '&') while keeping coc navigation/hover.
    #
    # GDiffTreeSetup applies each entry's diff setup, tags the tabs, and builds
    # the sidebar. The title string feeds the title bar.
    local title
    title=$(_gdifftree_vstr "Git Show $rev")
    # A commit's diff is against committed state, so its stats never change:
    # pass an empty refresh command.
    vim --cmd "set tabpagemax=${#args[@]}" \
        --cmd "let g:NERDTreeHijackNetrw = 0" \
        --cmd "autocmd BufEnter * let b:coc_diagnostic_disable = 1" \
        --cmd "autocmd SwapExists * let v:swapchoice = 'o'" -p "${args[@]}" \
        +"cd $toplevel" \
        +"call GDiffTreeSetup($title, $entries, [])"
}

# ------------------------------------------------------------------------------
# gdiff - open a diff in Vim.
#
#   1. Each changed file's diff opens in its own tab as a vertical split.
#   2. With no arguments the current unstaged changes are shown.
#   3. Diffing two revisions shows no commit/description noise.
#   4. A sidebar lists every tab; selecting an entry jumps to that tab.
#   5. The tmux pane is zoomed while viewing when inside a tmux session.
# ------------------------------------------------------------------------------
gdiff() {
    local toplevel
    toplevel=$(git rev-parse --show-toplevel)

    # Skip submodules/directories: they cannot be shown as a vertical diff, and
    # opening a directory would otherwise trigger NERDTree's netrw hijack.
    local files=() changed_file
    while IFS= read -r changed_file; do
        [ -n "$changed_file" ] && [ ! -d "$toplevel/$changed_file" ] && files+=("$changed_file")
    done < <(git diff --name-only "$@")

    if [ ${#files[@]} -eq 0 ]; then
        echo "No differences found."
        return 0
    fi

    # Parse args: --staged/--cached compares the index to HEAD; otherwise the
    # non-flag args are revisions. Other flags (e.g. -w) are still passed to git
    # for the file list and stats but do not change the diff wiring.
    local staged=0 rev_count=0 rev1="" rev2="" arg
    for arg in "$@"; do
        case "$arg" in
            --staged|--cached) staged=1 ;;
            --) ;;
            -*) ;;
            *) rev_count=$((rev_count + 1))
               if [ "$rev_count" -eq 1 ]; then rev1="$arg"; elif [ "$rev_count" -eq 2 ]; then rev2="$arg"; fi ;;
        esac
    done

    # Choose how each tab is diffed. Wrapped in try/catch so an added/deleted/
    # binary file cannot abort setup or leak errors.
    local diff_setup
    if [ "$staged" -eq 1 ]; then
        # Staged: HEAD vs the index (staged) contents, i.e. the actual staged
        # change - not the whole file.
        diff_setup="try | Gedit :0:% | Gvdiffsplit HEAD | catch | endtry"
    elif [ "$rev_count" -eq 0 ]; then
        # Working tree vs index.
        diff_setup="try | Gvdiffsplit | catch | endtry"
    elif [ "$rev_count" -eq 1 ]; then
        # A single rev arg is either a bare revision (rev vs working tree) or a
        # range revspec. A range must diff its two endpoints; treating it as one
        # revision makes fugitive diff against a nonexistent object literally
        # named "A..B", so every file shows up as wholly new. An empty endpoint
        # defaults to HEAD, matching git's own range semantics.
        case "$rev1" in
            *...*)
                # Symmetric range A...B: base is the merge-base of A and B.
                local range_base="${rev1%%...*}" range_target="${rev1##*...}"
                [ -z "$range_base" ] && range_base="HEAD"
                [ -z "$range_target" ] && range_target="HEAD"
                local merge_base
                merge_base=$(git merge-base "$range_base" "$range_target")
                diff_setup="try | Gedit $range_target:% | Gvdiffsplit $merge_base | catch | endtry"
                ;;
            *..*)
                # Range A..B: diff base A against target B.
                local range_base="${rev1%%..*}" range_target="${rev1##*..}"
                [ -z "$range_base" ] && range_base="HEAD"
                [ -z "$range_target" ] && range_target="HEAD"
                diff_setup="try | Gedit $range_target:% | Gvdiffsplit $range_base | catch | endtry"
                ;;
            *)
                # Given revision vs the working tree.
                diff_setup="try | Gvdiffsplit $rev1 | catch | endtry"
                ;;
        esac
    else
        # Two explicit revisions, no working-tree involvement.
        diff_setup="try | Gedit $rev2:% | Gvdiffsplit $rev1 | catch | endtry"
    fi

    # Per-file added/removed line counts for the sidebar (keyed by path; renamed
    # files simply get no stat).
    typeset -A stats
    local added deleted stat_path
    while IFS=$'\t' read -r added deleted stat_path; do
        [ -z "$stat_path" ] && continue
        if [ "$added" = "-" ]; then stats[$stat_path]="bin"; else stats[$stat_path]="+$added -$deleted"; fi
    done < <(git diff --numstat "$@")

    # args is what `vim -p` opens; entries is the parallel {label, file, setup,
    # stat} list the plugin uses to build the diffs, tag tabs, show stats, and
    # reopen closed tabs.
    local args=() entries="[" sep=""
    for changed_file in "${files[@]}"; do
        args+=("$toplevel/$changed_file")
        entries+="${sep}$(_gdifftree_entry "$changed_file" "$toplevel/$changed_file" "$diff_setup" "${stats[$changed_file]}")"
        sep=", "
    done
    entries+="]"

    # When the diff involves the working tree (plain or single-revision), re-run
    # numstat on every :w so the sidebar stats track edits. Committed comparisons
    # (staged, or two revisions) never change, so skip the refresh.
    local refresh
    if [ "$staged" -eq 0 ] && [ "$rev_count" -le 1 ]; then
        refresh="['git', '-C', $(_gdifftree_vstr "$toplevel"), 'diff', '--numstat'"
        for arg in "$@"; do refresh+=", $(_gdifftree_vstr "$arg")"; done
        refresh+="]"
    else
        refresh="[]"
    fi

    _gdifftree_tmux_zoom

    # --cmd runs before files load: cap tabpagemax to the file count (Vim's
    # default of 10 would silently drop the rest), open read-only rather than
    # prompt on a swap/already-open conflict, and disable NERDTree's netrw hijack
    # so a directory buffer can never spawn (and crash) NERDTree. GDiffTreeSetup
    # applies each entry's diff setup, tags the tabs, shows stats, and refreshes
    # them on save. The title string feeds the title bar.
    local title desc
    if [ $# -eq 0 ]; then
        desc="Git Diff (working tree)"
    else
        desc="Git Diff $*"
    fi
    title=$(_gdifftree_vstr "$desc")
    vim --cmd "set tabpagemax=${#args[@]}" \
        --cmd "let g:NERDTreeHijackNetrw = 0" \
        --cmd "autocmd BufEnter * let b:coc_diagnostic_disable = 1" \
        --cmd "autocmd SwapExists * let v:swapchoice = 'o'" -p "${args[@]}" \
        +"cd $toplevel" \
        +"call GDiffTreeSetup($title, $entries, $refresh)"
}
