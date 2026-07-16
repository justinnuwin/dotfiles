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

# Git vim-powered diff/show aliases (gshow / gdiff)
[ -r "$dotfiles/vim/neodiff/shell/neodiff.sh" ] && source "$dotfiles/vim/neodiff/shell/neodiff.sh"
