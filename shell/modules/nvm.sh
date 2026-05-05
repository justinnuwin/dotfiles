#!/bin/bash
# Loads Node Version Manager. Gated by JNSHELL_USE_NVM=true in justinShell.sh.

: "${NVM_DIR:=$HOME/.nvm}"
export NVM_DIR

if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  jnshell_warn "JNSHELL_USE_NVM=true but nvm not found at $NVM_DIR/nvm.sh (https://github.com/nvm-sh/nvm#installing-and-updating)"
  return 0
fi

# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"
# shellcheck disable=SC1091
[[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
