#!/bin/bash
#      _           _   _       ____  _          _ _
#     (_)_   _ ___| |_(_)_ __ / ___|| |__   ___| | |
#     | | | | / __| __| | '_ \\___ \| '_ \ / _ \ | |
#   _ | | |_| \__ \ |_| | | | |___) | | | |  __/ | |
#  (_)/ |\__,_|___/\__|_|_| |_|____/|_| |_|\___|_|_|
#   |__/
#
# Common shell entry point. 
# See shell/README.md for the layout and call order across various shell
# setup files and variations across OSes.

dotfiles="$HOME/.dotfiles"

# Shared helpers
# shellcheck source=jnshell_utils.sh
source "$dotfiles/shell/jnshell_utils.sh"

# Environment for every shell, interactive or not (scripts, ssh).
# Must not depend on a terminal. Safe to call more than once.
jnshell_env_setup() {
  jnshell_path_append "$HOME/.local/bin"

  if [[ "$(uname)" = "Darwin" ]]; then
    # shellcheck source=modules/macports.sh
    source "$dotfiles/shell/modules/macports.sh"
  fi

  # Per-host overrides (JNSHELL_* flags). Must precede every flag-gated
  # section below and in jnshell_interactive_setup.
  # shellcheck source=/dev/null
  [[ -f "$HOME/.localshell" ]] && source "$HOME/.localshell"

  if jnshell_flag_enabled JNSHELL_USE_RUST; then
    # shellcheck source=modules/rust.sh
    source "$dotfiles/shell/modules/rust.sh"
  fi

  if jnshell_flag_enabled JNSHELL_USE_OPENER; then
    # shellcheck source=modules/opener.sh
    source "$dotfiles/shell/modules/opener.sh"
  fi

  jnshell_path_append "$dotfiles/shell/git-mv-changes"
}

# Aliases, functions, and prompt for interactive shells. Expects
# jnshell_env_setup to have run first.
jnshell_interactive_setup() {
  # Utility functions
  # shellcheck source=path_utils.sh
  source "$dotfiles/shell/path_utils.sh"
  # shellcheck source=bazel_utils.sh
  source "$dotfiles/shell/bazel_utils.sh"

  GPG_TTY=$(tty)
  export GPG_TTY

  # Default-on alias modules. Disable individually in ~/.localshell with
  # JNSHELL_USE_COMMON_ALIASES=false / JNSHELL_USE_GIT_ALIASES=false.
  if jnshell_flag_enabled JNSHELL_USE_COMMON_ALIASES true; then
    # shellcheck source=modules/common_aliases.sh
    source "$dotfiles/shell/modules/common_aliases.sh"
  fi

  if jnshell_flag_enabled JNSHELL_USE_GIT_ALIASES true; then
    # shellcheck source=modules/git_aliases.sh
    source "$dotfiles/shell/modules/git_aliases.sh"
  fi

  # Optional feature modules. Each module verifies its own prerequisites and
  # emits a warning if anything required is missing.
  if jnshell_flag_enabled JNSHELL_LONG_LIVED_REMOTE; then
    # shellcheck source=modules/ssh_socket.sh
    source "$dotfiles/shell/modules/ssh_socket.sh"
  fi

  if jnshell_flag_enabled JNSHELL_USE_NVM; then
    # shellcheck source=modules/nvm.sh
    source "$dotfiles/shell/modules/nvm.sh"
  fi

  # Prompt is always sourced; the module dispatches on JNSHELL_PROMPT
  # and is a no-op when unset.
  # shellcheck source=modules/prompt.sh
  source "$dotfiles/shell/modules/prompt.sh"
}
