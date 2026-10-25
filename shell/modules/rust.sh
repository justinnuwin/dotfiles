#!/bin/bash
# Adds Rust toolchain (cargo) to PATH. Gated by JNSHELL_USE_RUST=true in justinShell.sh.

: "${CARGO_HOME:=$HOME/.cargo}"
export CARGO_HOME

if [[ ! -x "$CARGO_HOME/bin/cargo" ]]; then
  jnshell_warn "JNSHELL_USE_RUST=true but cargo not found at $CARGO_HOME/bin/cargo (https://rustup.rs)"
  return 0
fi

jnshell_path_append "$CARGO_HOME/bin"
