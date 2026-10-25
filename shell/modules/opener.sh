#!/bin/bash
# Puts the superbrothers/opener open/xdg-open shims ahead of the system ones so
# URLs open in the local machine's browser over the forwarded ~/.opener.sock.
# Gated by JNSHELL_USE_OPENER=true in justinShell.sh.

if [[ ! -x "$HOME/.local/opener/bin/xdg-open" ]]; then
  jnshell_warn "JNSHELL_USE_OPENER=true but the opener shims are missing from ~/.local/opener/bin (run the ansible opener_remote role)"
  return 0
fi

jnshell_require_cmd nc || return 0

jnshell_path_prepend "$HOME/.local/opener/bin"
