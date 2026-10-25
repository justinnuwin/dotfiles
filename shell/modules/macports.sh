#!/bin/bash
# Adds MacPorts to PATH. Sourced on Darwin by justinShell.sh.

[[ -x /opt/local/bin/port ]] || return 0

jnshell_path_prepend /opt/local/sbin
jnshell_path_prepend /opt/local/bin
