#!/bin/bash
# Ensure fzf is on the PATH to source this

local dotfile="$HOME/.dotfiles"
source "$dotfile/shell/path_utils.sh"

which fzf > /dev/null
if [[ "$?" -gt 0 ]]; then
    echo "fzf was not found on the PATH"
    return 1
fi

export FZF_DEFAULT_COMMAND="find . -type f \\( -path ./.git -o -name ./node_modules \\) -o -print"
export FZF_DEFAULT_OPTS="--reverse --preview-window=right,60%"

local DEBUG_FZF_ALIASES=false

# Select the correct mode (tmux/no tmux) to run fzf
# Arg 1: Set to "tm", "tmux", "p", "pop", "popup", "f", "float" for a popup;
#   "s", "spl", "split" for default split (down). If not set to any of the
#   above, fzf will run in the current TTY.
# Arg 2: General fzf options
# Arg 3: Optional number of entries. Used to help determine split size. Can be
#   left blank
fzf_cmd() {
    local tmux_mode="$1"
    local fzf_opts="$2"
    local num_entries="$3"

    if $DEBUG_FZF_ALIASES; then
        echo "fzf_cmd" >&2
        echo "  tmux_mode=$tmux_mode" >&2
        echo "  fzf_opts=$fzf_opts" >&2
        echo "  num_entries=$num_entries" >&2
    fi
    
    local fzf_cmd
    if [[ -z "$tmux_mode" ]]; then
        fzf_cmd="fzf"
    else
        case "$tmux_mode" in
            tm|tmux|p|pop|popup|f|float)
                local win_width=$(tmux display -p \#{window_width})
                if (( $win_width > 300)); then
                    fzf_cmd="fzf-tmux -p 48%"
                elif (( $win_width > 150)); then
                    fzf_cmd="fzf-tmux -p 66%"
                else
                    fzf_cmd="fzf-tmux -p 75%"
                fi
                ;;
            s|spl|split)
                fzf_cmd="fzf-tmux -d $(($num_entries + 2))";;
            *)
                fzf_cmd="fzf";;
        esac
    fi
    eval "$fzf_cmd $fzf_opts"
}

fzf_vim_files() {
    selected_file=$(fzf_cmd " " "--multi") \
    && vim $selected_file
}
alias vfz=fzf_vim_files

fzf_vim_git_files() {
    pushd $(git rev-parse --show-toplevel)
    selected_file=$(fzf_cmd " " "--multi") \
    && vim $selected_file
}
alias vgfz=fzf_vim_git_files

# Execute bazel command with fast fuzzy completion using grep'ed targets from
# BUILD files
# Arg 1: Bazel command (run, test, etc)
# Arg 2: See get_bazel_targets:arg1
# Args 3..: Bazel options
fzf_bazel() {
    local bazel_cmd="$1"
    local targets=$(get_bazel_targets "$2")
    local selected
    if [[ "$bazel_cmd" = "test" ]]; then
        selected="$(echo "$targets" \
                    | fzf_cmd " " "--multi")"
    else
        selected="$(echo "$targets" \
                    | fzf_cmd " " "--no-multi")"
    fi
    bazel $1 "${@:3}" "$selected"
}
alias baz=fzf_bazel
alias br="fzf_bazel run"
alias bt="fzf_bazel test"

# Fuzzy select a git branch
# Arg 1: See select_fzf_tmux
fzf_git_branch() {
    local branches num_branches
    branches=$(git branch --all | grep -v HEAD)
    if [[ $? -gt 0 ]]; then
        return
    fi
    num_branches=$(wc --lines <<< "$branches")
    if [[ "$num_branches" -gt 20 ]]; then
        num_branches=20
    else
        num_branches=$(($num_branches + 2))
    fi
    local fzf_preview_cmd="echo {} | sed \"s/.* //\" | xargs git log --oneline --max-count=300"
    local fzf_opt="--no-multi --preview='$fzf_preview_cmd' --preview-window=nohidden"
    set -o pipefail
    echo "$branches" \
    | fzf_cmd "$1" "$fzf_opt" "$num_branches" \
    | sed "s/.* //"
}
alias fzgbr=fzf_git_branch

# Fuzzy git branch
# Args: Forward to git branch
alias gbr="git branch \$@ \$(fzgbr)"

# Fuzzy git checkout branches
# Arg 1: See select_fzf_tmux
fzf_git_checkout() {
    local branch
    branch=$(fzgbr $1) \
    && git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}
alias gco=fzf_git_checkout
alias gcob=gco

# Fuzzy git checkout files
# Arg 1: See select_fzf_tmux
fzf_git_checkout_file() {
    pushd $(git rev-parse --show-toplevel) > /dev/null
    local files="$(git ls-files --modified)"
    if [[ -z "$files" ]]; then
        popd > /dev/null
        return
    fi
    local dirs="$(echo "$files" | xargs dirname | xargs -I{} echo "{}/")"
    local options=$(echo "$files\n$dirs" | uniq | sort)
    local num_options=$(wc --lines <<< "$options")
    local fzf_opt="--multi --preview='git diff --minimal {}' --preview-window=nohidden"
    local selected
    selected=$(echo $options \
               | fzf_cmd "$1" "$fzf_opt" "$num_options") \
    && echo "$selected" \
    | xargs git checkout 
    popd > /dev/null
}
alias gcof=fzf_git_checkout_file







# Get placement for tmux popup based on window size
# Arg 1: Side to place popup. "l", "r", "u", "d", "t", "b", "c", "m", or full
#   name. Empty or invalid argument will default to center
# Arg 2: Margin from window edges
place_tmux_popup() {
    local direction="$1"
    local margin="$2"

    local win_height=$(tmux display -p \#{window_height})
    local win_width=$(tmux display -p \#{window_width})

    local full_width_half_height="$(($win_width - 2 * $margin)),$(($win_height / 2 - 2 * $margin))"
    local half_width_full_height="$(($win_width / 2 - 2 * $margin)),$(($win_height - 2 * $margin))"

    local xarg yarg p
    case "direction" in
        l|left)
            xarg="-x $margin"
            yarg="-x $margin"
            p="$half_width_full_height";;
        r|right)
            xarg="-x $(($win_width / 2 + $margin))"
            yarg="-y $margin"
            p="$half_width_full_height";;
        u|up|t|top)
            xarg="-x $margin"
            yarg="-y $margin"
            p="$full_width_half_height";;
        d|down|b|bottom)
            xarg="-x $margin"
            yarg="-y $(($win_height / 2 + $margin))"
            p="$full_width_half_height";;
        *)
            xarg=""
            yarg=""
            if [[ "$win_width" -gt 150 ]]; then
                p="48%"
            else
                p="75%"
            fi
            ;;
    esac
    echo "-p $p $xarg $yarg"
}
