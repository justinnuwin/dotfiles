#!/bin/bash
#      _           _   _       ____  _          _ _ 
#     (_)_   _ ___| |_(_)_ __ / ___|| |__   ___| | |
#     | | | | / __| __| | '_ \\___ \| '_ \ / _ \ | |
#   _ | | |_| \__ \ |_| | | | |___) | | | |  __/ | |
#  (_)/ |\__,_|___/\__|_|_| |_|____/|_| |_|\___|_|_|
#   |__/                                            
# 

local dotfiles="$HOME/.dotfiles"

# Source utility functions
source "$dotfiles/shell/path_utils.sh"
source "$dotfiles/shell/bazel_utils.sh"

enable_color="--color=always"

alias rm="rm -i"

alias l="ls"
alias ls="ls $enable_color"
alias la="ls -al $enable_color"
alias ll="ls -alhs $enable_color"

alias grep="grep --color=always"

alias vi="vim"

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
  git reset --hard origin/$(git branch --show-current)
}
alias grb="git rebase"
alias gwt="git worktree"
# Remove the current worktree and its check-ed out branch
git_remove_worktree_delete_local_branch() {
    if [[ ! -f "$(groot)/.git" ]]; then
        echo "Not in a git worktree" 2>&1
        return 1
    fi
    local worktree="$(groot)"
    local branch="$(gcurb)"
    cd "$(dirname "$(git rev-parse --git-common-dir)")"
    git worktree remove $worktree
    if [[ $? > 0 ]]; then
        cd $worktree
        return 1
    fi
    echo "Removed worktree $worktree"
    if [[ $branch != "" ]]; then
        git branch -D $branch
    fi
    cd "$(dirname $worktree)"
    return 0
}
alias gwtrmb="git_remove_worktree_delete_local_branch"
alias gdiff="git diff"
alias gsw="git switch"
alias cdgroot="cd \$(groot)"
alias pushdgroot="pushd \$(groot)"
# Sometimes very large repos will have custom fetch refspecs to minimize on
# number of branches/tags pulled. Maually fetch before switching to the branch
gfsw() {
  git fetch --force --refmap="+$1:refs/remotes/origin/$1" origin $1
  if git rev-parse --quiet --verify $1
  then
    git switch $1
  else
    git switch -c $1 origin/$1
  fi
  return 0
}
# TODO: Figure out why these have to be functions for completions to work instead of aliases
btest() {
    bazel test "$@"
}
bbuild() {
    bazel build "$@"
}
export GPG_TTY=$(tty)

if [[ "$(uname)" = "Darwin" ]]; then
  source "$dotfiles/shell/macos_gnu.sh"
fi

if [[ -f "$HOME/.localshell" ]]; then
    source $HOME/.localshell
fi

if [[ -n "$JNSHELL_LONG_LIVED_REMOTE" ]] && "$JNSHELL_LONG_LIVED_REMOTE"; then
  SSH_AUTH_SOCK=$HOME/.ssh/ssh_auth_sock
fi

if [[ -n "$(which fzf)" ]]; then
    source "$HOME/.dotfiles/shell/fzf_aliases.sh"
fi

# Node Version Manager
if [[ -n "$JNSHELL_USE_NVM" ]] && "$JNSHELL_USE_NVM"; then
  if [[ -z "$NVM_DIR" ]]; then
    export NVM_DIR="$HOME/.nvm"
  fi
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

# Rust
# This can be installed with: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --no-modify-path -y
if [[ -n "$JNSHELL_USE_RUST" ]] && "$JNSHELL_USE_RUST"; then
  if [[ -z "$CARGO_HOME" ]]; then
    export CARGO_HOME="$HOME/.cargo"
  fi
  export PATH="$PATH:$CARGO_HOME/bin"
fi

# Add ~/.local/bin to path for many pip or other local applications
if echo $PATH | grep --quiet --invert-match "$HOME/.local/bin"; then
  export PATH="$PATH:$HOME/.local/bin"
fi

# Add git-mv-changes to PATH
export PATH="$PATH:$HOME/.dotfiles/shell/git-mv-changes"
