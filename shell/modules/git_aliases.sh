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
#   {'label':.., 'file':.., 'setup':.., 'stat':.. [, 'status':.., 'orig_path':..,
#    'pinned': 1]}
# Args: label file setup stat [status] [orig_path] [pinned]. status (A/M/D/R/C),
# orig_path (the pre-rename path, for R/C), and the trailing pinned flag are each
# emitted only when non-empty; pinned marks a meta entry (commit description /
# notes) listed above the file tree.
_gdifftree_entry() {
    printf "{'label': %s, 'file': %s, 'setup': %s, 'stat': %s" \
        "$(_gdifftree_vstr "$1")" "$(_gdifftree_vstr "$2")" \
        "$(_gdifftree_vstr "$3")" "$(_gdifftree_vstr "$4")"
    [ -n "$5" ] && printf ", 'status': %s" "$(_gdifftree_vstr "$5")"
    [ -n "$6" ] && printf ", 'orig_path': %s" "$(_gdifftree_vstr "$6")"
    [ -n "$7" ] && printf ", 'pinned': 1"
    printf "}"
}

# Build one file's diff setup (the Ex command run in its tab) from its git status.
# Keeps the older side on the LEFT (fugitive's Gvdiffsplit opens its argument to
# the left), which git_diff_tree.vim's s:SetupDiffPaneColors relies on for
# red-left / green-right. Args: status lrev rrev right_wt old_path new_path.
# right_wt=1 means the tab's working-tree buffer is already the newer (right)
# pane; otherwise the newer side is the blob rrev:new_path. Added/deleted use a
# forced-empty scratch pane so they render as all-green / all-red.
_gdifftree_diff_setup() {
    local st="$1" lrev="$2" rrev="$3" right_wt="$4" oldp="$5" newp="$6"
    local scratch="setlocal buftype=nofile bufhidden=wipe noswapfile nomodifiable"
    local right body
    if [ "$right_wt" = 1 ]; then right=""; else right="Gedit $rrev:$newp | "; fi
    case "$st" in
        A)  body="${right}diffthis | leftabove vnew | $scratch | diffthis" ;;
        D)  body="Gedit $lrev:$newp | diffthis | rightbelow vnew | $scratch | diffthis" ;;
        R|C) body="${right}Gvdiffsplit $lrev:$oldp" ;;
        *)  body="${right}Gvdiffsplit $lrev:$newp" ;;
    esac
    printf 'try | %s | catch | endtry' "$body"
}

# Populate _gdt_args (paths for `vim -p`) and _gdt_entries (comma-joined entry
# dict literals) from a git diff invocation -- rename/copy-aware and NUL-safe.
# Args: lrev rrev right_wt <git-invocation-prefix...>, where the prefix contains
# a literal %FMT% token marking where the output-format flag belongs (so it lands
# before any user `-- <paths>`). The prefix is run twice: %FMT% -> --numstat
# (counts) and %FMT% -> --name-status (status + old/new paths), each with -M -z
# (plus -C --find-copies-harder when GDIFFTREE_FIND_COPIES is set; it is
# O(files^2)). E.g. `git diff %FMT% "$@"` or
# `git diff-tree %FMT% --no-commit-id -r "$rev"`. Relies on the caller's local
# $toplevel. Directories/submodules are skipped (a diff can list a submodule).
_gdifftree_parse_changes() {
    local lrev="$1" rrev="$2" right_wt="$3"; shift 3
    local -a detect=(-M)
    [ -n "$GDIFFTREE_FIND_COPIES" ] && detect+=(-C --find-copies-harder)

    # Expand %FMT% into each pass's format flags, keeping every other token
    # (including a trailing `-- <paths>`) in place.
    local -a num_cmd=() ns_cmd=() tok
    for tok in "$@"; do
        if [ "$tok" = "%FMT%" ]; then
            num_cmd+=(--numstat "${detect[@]}" -z)
            ns_cmd+=(--name-status "${detect[@]}" -z)
        else
            num_cmd+=("$tok"); ns_cmd+=("$tok")
        fi
    done

    # Pass 1: counts keyed by the post-rename new path. With -z each numstat
    # record is NUL-terminated; a rename's path field is empty and is followed by
    # two extra NUL tokens (old, new), so the new-path key needs no `{old => new}`
    # parsing.
    typeset -A _gdt_counts
    local rec add del pathfield np
    while IFS= read -r -d '' rec; do
        add="${rec%%$'\t'*}"; rec="${rec#*$'\t'}"
        del="${rec%%$'\t'*}"; pathfield="${rec#*$'\t'}"
        if [ -z "$pathfield" ]; then
            IFS= read -r -d '' _        # old (discard)
            IFS= read -r -d '' np       # new
        else
            np="$pathfield"
        fi
        if [ "$add" = "-" ]; then _gdt_counts[$np]="bin"; else _gdt_counts[$np]="+$add -$del"; fi
    done < <("${num_cmd[@]}")

    # Pass 2: status + paths in git's order. A/M/D: "status\0path"; R/C:
    # "score\0old\0new" (score stripped to the bare letter).
    _gdt_args=(); _gdt_entries=""
    local st oldp newp setup stat
    while IFS= read -r -d '' tok; do
        case "$tok" in
            R*|C*) IFS= read -r -d '' oldp; IFS= read -r -d '' newp; st="${tok%%[0-9]*}" ;;
            *)     IFS= read -r -d '' newp; oldp=""; st="$tok" ;;
        esac
        [ -z "$newp" ] && continue
        [ -d "$toplevel/$newp" ] && continue
        stat="${_gdt_counts[$newp]}"
        setup=$(_gdifftree_diff_setup "$st" "$lrev" "$rrev" "$right_wt" "$oldp" "$newp")
        _gdt_args+=("$toplevel/$newp")
        _gdt_entries+="${_gdt_entries:+, }$(_gdifftree_entry "$newp" "$toplevel/$newp" "$setup" "$stat" "$st" "$oldp")"
    done < <("${ns_cmd[@]}")
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

    # Status-aware entries for every changed file (one commit vs its parent).
    # _gdifftree_parse_changes fills _gdt_args (buffers to open) and _gdt_entries
    # (the dict literals) with A/M/D/R/C status, correct old/new paths, and a
    # per-status diff setup; diff-tree honors -M/--name-status/-z.
    _gdifftree_parse_changes "$rev~1" "$rev" 0 git diff-tree %FMT% --no-commit-id -r "$rev"

    # Tab order: commit description, optional notes, then one tab per file. args
    # is what `vim -p` opens (one buffer per tab); entries is the parallel list of
    # dict literals the plugin uses to build the diffs, tag tabs, show stats, and
    # reopen a tab if it is closed.
    local args=("$tmpdir/COMMIT_DESCRIPTION")
    local entries="[$(_gdifftree_entry "Commit Description" "$tmpdir/COMMIT_DESCRIPTION" "setlocal readonly nomodifiable" "" "" "" "pinned")"
    for note_ns in "${note_namespaces[@]}"; do
        args+=("$tmpdir/notes/$note_ns")
        entries+=", $(_gdifftree_entry "Commit Notes/$note_ns" "$tmpdir/notes/$note_ns" "setlocal readonly nomodifiable" "" "" "" "pinned")"
    done
    args+=("${_gdt_args[@]}")
    [ -n "$_gdt_entries" ] && entries+=", $_gdt_entries"
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
    # pass an empty refresh command. Launch from the repo root in a subshell: if
    # the caller's cwd was removed (e.g. `git rm` deleting the last file in the
    # directory you are standing in), Vim would otherwise start in a dead cwd and
    # abort loading its config (source errors before GDiffTreeSetup is defined).
    ( cd "$toplevel" && vim --cmd "set tabpagemax=${#args[@]}" \
        --cmd "let g:NERDTreeHijackNetrw = 0" \
        --cmd "autocmd BufEnter * let b:coc_diagnostic_disable = 1" \
        --cmd "autocmd SwapExists * let v:swapchoice = 'o'" -p "${args[@]}" \
        +"cd $toplevel" \
        +"call GDiffTreeSetup($title, $entries, [])" )
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

    # Parse args: --staged/--cached compares the index to HEAD; otherwise the
    # non-flag args are revisions. Other flags (e.g. -w) still pass through to git
    # for file selection and stats but do not change the diff wiring.
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

    # Reduce the mode to an older/left rev (lrev) and a newer/right side: either a
    # rev (rrev) or the actual working-tree file (right_wt=1, so live edits and :w
    # refresh work). _gdifftree_diff_setup builds each file's status-aware setup
    # from these. A single rev arg may be a bare revision (rev vs working tree) or
    # a range; a range must diff its two endpoints (treating "A..B" as one object
    # would show every file as wholly new). An empty range endpoint defaults to
    # HEAD, matching git's own range semantics.
    local lrev rrev="" right_wt=0
    if [ "$staged" -eq 1 ]; then
        lrev="HEAD"; rrev=":0"
    elif [ "$rev_count" -eq 0 ]; then
        lrev=":0"; right_wt=1
    elif [ "$rev_count" -eq 1 ]; then
        case "$rev1" in
            *...*)
                local range_base="${rev1%%...*}" range_target="${rev1##*...}"
                [ -z "$range_base" ] && range_base="HEAD"
                [ -z "$range_target" ] && range_target="HEAD"
                lrev=$(git merge-base "$range_base" "$range_target"); rrev="$range_target"
                ;;
            *..*)
                local range_base="${rev1%%..*}" range_target="${rev1##*..}"
                [ -z "$range_base" ] && range_base="HEAD"
                [ -z "$range_target" ] && range_target="HEAD"
                lrev="$range_base"; rrev="$range_target"
                ;;
            *)
                lrev="$rev1"; right_wt=1
                ;;
        esac
    else
        lrev="$rev1"; rrev="$rev2"
    fi

    _gdifftree_parse_changes "$lrev" "$rrev" "$right_wt" git diff %FMT% "$@"
    if [ ${#_gdt_args[@]} -eq 0 ]; then
        echo "No differences found."
        return 0
    fi

    # args is what `vim -p` opens; entries is the parallel list of dict literals
    # the plugin uses to build the diffs, tag tabs, show stats, and reopen tabs.
    local args=("${_gdt_args[@]}") entries="[$_gdt_entries]"

    # When the diff involves the working tree (plain or single-revision), re-run
    # numstat on every :w so the sidebar stats track edits. Committed comparisons
    # (staged, or two revisions) never change, so skip the refresh.
    # -M so a renamed file keeps its stat on refresh; s:RefreshStats normalizes
    # the numstat `{old => new}` path form (Vim system() cannot carry -z NULs).
    local refresh
    if [ "$staged" -eq 0 ] && [ "$rev_count" -le 1 ]; then
        refresh="['git', '-C', $(_gdifftree_vstr "$toplevel"), 'diff', '-M', '--numstat'"
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
    # Launch from the repo root in a subshell so a removed cwd (e.g. `git rm`
    # deleting the last file in the directory you are standing in) cannot start
    # Vim in a dead cwd, which aborts config loading before GDiffTreeSetup exists.
    ( cd "$toplevel" && vim --cmd "set tabpagemax=${#args[@]}" \
        --cmd "let g:NERDTreeHijackNetrw = 0" \
        --cmd "autocmd BufEnter * let b:coc_diagnostic_disable = 1" \
        --cmd "autocmd SwapExists * let v:swapchoice = 'o'" -p "${args[@]}" \
        +"cd $toplevel" \
        +"call GDiffTreeSetup($title, $entries, $refresh)" )
}
