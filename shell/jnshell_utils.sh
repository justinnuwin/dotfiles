#!/bin/bash

# Print a warning to stderr. Colored yellow when stderr is a terminal.
jnshell_warn() {
  if [[ -t 2 ]]; then
    printf '\033[33mjnshell: warning: %s\033[0m\n' "$*" >&2
  else
    printf 'jnshell: warning: %s\n' "$*" >&2
  fi
}

# Return 0 iff the named variable resolves to the literal string "true".
# Usage:
#   jnshell_flag_enabled JNSHELL_USE_FOO             # default disabled
#   jnshell_flag_enabled JNSHELL_USE_BAR true        # default enabled
jnshell_flag_enabled() {
  local varname="$1"
  local default="${2:-false}"
  local val
  # 'eval' for indirect expansion because bash uses ${!var} and zsh uses ${(P)var}.
  eval "val=\${$varname:-$default}"
  [[ "$val" == "true" ]]
}

# Verify a command is on PATH. Warn (with optional install URL) and return 1 if missing.
# Usage: jnshell_require_cmd foo "https://foo.bar/#installation"
jnshell_require_cmd() {
  local cmd="$1"
  local url="${2:-}"
  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  fi
  if [[ -n "$url" ]]; then
    jnshell_warn "'$cmd' not found on PATH ($url)"
  else
    jnshell_warn "'$cmd' not found on PATH"
  fi
  return 1
}

jnshell_is_zsh() {
  [[ -n "${ZSH_VERSION:-}" ]]
}

jnshell_is_bash() {
  [[ -n "${BASH_VERSION:-}" ]]
}
