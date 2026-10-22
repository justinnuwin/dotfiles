#!/bin/bash
# Adds MacPorts to PATH. Sourced on Darwin by justinShell.sh.

[[ -x /opt/local/bin/port ]] || return 0

case ":$PATH:" in
  *":/opt/local/bin:"*) ;;
  *) export PATH="/opt/local/bin:/opt/local/sbin:$PATH" ;;
esac
