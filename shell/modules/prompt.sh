#!/bin/bash
# Dispatches on JNSHELL_PROMPT to set up a prompt theme.
# Always sourced from justinShell.sh; an unset/empty value is a no-op.
#
# Supported values: zsh-p10k, starship, none (default: none).
#
# shellcheck disable=SC2154  # $dotfiles is exported by the caller (justinShell.sh)

case "${JNSHELL_PROMPT:-}" in
  "" | none)
    return 0
    ;;
  zsh-p10k)
    if ! jnshell_is_zsh; then
      jnshell_warn "JNSHELL_PROMPT=zsh-p10k requires zsh; skipping"
      return 0
    fi
    p10k_theme="$dotfiles/shell/zsh_plugins/powerlevel10k/powerlevel10k.zsh-theme"
    if [[ ! -f "$p10k_theme" ]]; then
      jnshell_warn "powerlevel10k submodule not initialized; run: git -C $dotfiles submodule update --init --recursive (https://github.com/romkatv/powerlevel10k)"
      return 0
    fi
    # shellcheck disable=SC1091,SC1094  # zsh syntax, shellcheck cannot parse
    source "$dotfiles/shell/p10k.zsh"
    initialize_powerlevel10k "$p10k_theme"
    ;;
  starship)
    if ! jnshell_require_cmd starship "https://starship.rs/installing/"; then
      return 0
    fi
    if jnshell_is_zsh; then
      eval "$(starship init zsh)"
    else
      eval "$(starship init bash)"
    fi
    ;;
  *)
    jnshell_warn "unknown JNSHELL_PROMPT value: '$JNSHELL_PROMPT' (expected: zsh-p10k, starship, none)"
    ;;
esac
