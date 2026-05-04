#!/bin/bash
# Adds Rust toolchain (cargo) to PATH. Gated by JNSHELL_USE_RUST=true in justinShell.sh.

: "${CARGO_HOME:=$HOME/.cargo}"
export CARGO_HOME

if [[ ! -x "$CARGO_HOME/bin/cargo" ]]; then
  jnshell_warn "JNSHELL_USE_RUST=true but cargo not found at $CARGO_HOME/bin/cargo (https://rustup.rs)"
  return 0 2>/dev/null || exit 0
fi

case ":$PATH:" in
  *":$CARGO_HOME/bin:"*) ;;
  *) export PATH="$PATH:$CARGO_HOME/bin" ;;
esac
