#!/bin/bash

enable_color="--color=always"

alias rm="rm -i"

alias l="ls"
# shellcheck disable=SC2139  # expand $enable_color at definition time on purpose
alias ls="ls $enable_color"
# shellcheck disable=SC2139
alias la="ls -al $enable_color"
# shellcheck disable=SC2139
alias ll="ls -alhs $enable_color"

# shellcheck disable=SC2032  # alias body refers to /usr/bin/grep, not the alias
alias grep="grep --color=always"

# neovim installs its binary as `nvim`; keep muscle-memory `vim`/`vi` working
alias vim="nvim"
alias vi="vim"

# TODO: Figure out why these have to be functions for completions to work instead of aliases
btest() {
    bazel test "$@"
}
bbuild() {
    bazel build "$@"
}
