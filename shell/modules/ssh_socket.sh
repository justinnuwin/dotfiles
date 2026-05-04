#!/bin/bash
# Pin SSH_AUTH_SOCK to a stable path so long-lived sessions (tmux, etc.) don't
# end up with a stale socket from a disconnected ssh-agent.
# Gated by JNSHELL_LONG_LIVED_REMOTE=true in justinShell.sh.

export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"
