#!/bin/bash
#      _           _   _       ____  _          _ _
#     (_)_   _ ___| |_(_)_ __ / ___|| |__   ___| | |
#     | | | | / __| __| | '_ \\___ \| '_ \ / _ \ | |
#   _ | | |_| \__ \ |_| | | | |___) | | | |  __/ | |
#  (_)/ |\__,_|___/\__|_|_| |_|____/|_| |_|\___|_|_|
#   |__/
#
# Common shell entry point. Sourced by shell/bashrc and shell/zshrc.
# See shell/README.md for the full layout and JNSHELL_* feature-flag reference.

dotfiles="$HOME/.dotfiles"

# Shared helpers
# shellcheck source=jnshell_utils.sh
source "$dotfiles/shell/jnshell_utils.sh"

# Utility functions
# shellcheck source=path_utils.sh
source "$dotfiles/shell/path_utils.sh"
# shellcheck source=bazel_utils.sh
source "$dotfiles/shell/bazel_utils.sh"

GPG_TTY=$(tty)
export GPG_TTY

if [[ "$(uname)" = "Darwin" ]]; then
  # shellcheck source=macos_gnu.sh
  source "$dotfiles/shell/macos_gnu.sh"
fi

# Per-host overrides (JNSHELL_* flags). Must precede every flag-gated section below.
# shellcheck source=/dev/null
[[ -f "$HOME/.localshell" ]] && source "$HOME/.localshell"

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

# fzf aliases — silent skip if fzf is missing, unless JNSHELL_USE_FZF=true
# (in which case warn with the install link).
if command -v fzf >/dev/null 2>&1; then
  # shellcheck source=fzf_aliases.sh
  source "$dotfiles/shell/fzf_aliases.sh"
elif jnshell_flag_enabled JNSHELL_USE_FZF; then
  jnshell_require_cmd fzf "https://github.com/junegunn/fzf#installation" >/dev/null
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

if jnshell_flag_enabled JNSHELL_USE_RUST; then
  # shellcheck source=modules/rust.sh
  source "$dotfiles/shell/modules/rust.sh"
fi

# Prompt is always sourced; the module dispatches on JNSHELL_PROMPT
# and is a no-op when unset.
# shellcheck source=modules/prompt.sh
source "$dotfiles/shell/modules/prompt.sh"

# Add ~/.local/bin to PATH for many pip or other local applications
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$PATH:$HOME/.local/bin" ;;
esac

# Add git-mv-changes to PATH
export PATH="$PATH:$HOME/.dotfiles/shell/git-mv-changes"
