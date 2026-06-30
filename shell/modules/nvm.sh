#!/bin/bash
# Loads Node Version Manager. Gated by JNSHELL_USE_NVM=true in justinShell.sh.

: "${NVM_DIR:=$HOME/.nvm}"
export NVM_DIR

if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  jnshell_warn "JNSHELL_USE_NVM=true but nvm not found at $NVM_DIR/nvm.sh (https://github.com/nvm-sh/nvm#installing-and-updating)"
  return 0
fi

# Lazy load nvm, node, and npm to speed up terminal start
nvm() {
  unset -f nvm node npm npx
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
	[[ -n "$BASH_VERSION" && -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
  nvm "$@"
}

node() {
  unset -f nvm node npm npx
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
	[[ -n "$BASH_VERSION" && -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
  node "$@"
}

npm() {
  unset -f nvm node npm npx
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
	[[ -n "$BASH_VERSION" && -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
  npm "$@"
}

npx() {
  unset -f nvm node npm npx
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
	[[ -n "$BASH_VERSION" && -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
  npx "$@"
}

