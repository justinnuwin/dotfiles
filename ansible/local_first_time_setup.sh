#!/bin/bash
# Interactive bootstrap: prompts for opt-in toolchain installs, then runs the
# first_time_setup.yml playbook against localhost.
#
# Usage:
#   ./local_first_time_setup.sh                       # interactive
#   ./local_first_time_setup.sh --no-prompt           # skip prompts (use defaults)
#   ./local_first_time_setup.sh -- -e install_rust=true   # forward args to ansible-playbook
#
# Defaults (applied in both interactive and --no-prompt mode):
#   install_rust:   no
#   install_nvm:    YES
#   starship/toolchain force-reinstall: no
#   long-lived host role: neither (skips the opener and long-lived session roles)
#
# Anything after a literal `--` is forwarded verbatim to ansible-playbook AFTER
# the prompt-derived -e flags, so explicit overrides win.

set -eo pipefail

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
cd "$(dirname "$script_path")"

# --- Clone Submodules -------------------------------------------------------
# Don't assume the user did `git clone --recursive`
git -C .. submodule update --init --recursive

# --- Arg parsing ------------------------------------------------------------
no_prompt=false
forward_args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-prompt)
      no_prompt=true
      shift
      ;;
    -h|--help)
      sed -n '2,18p' "$script_path" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    --)
      shift
      forward_args+=("$@")
      break
      ;;
    *)
      forward_args+=("$1")
      shift
      ;;
  esac
done

# Stdin not a tty (CI, piped input) -> skip prompts.
if [[ ! -t 0 ]]; then
  no_prompt=true
fi

# --- Venv setup -------------------------------------------------------------
# The playbook runs modules with the system python3 (see ansible_python_interpreter below).
target_python=/usr/bin/python3

# Prints the newest python3.N on PATH that can run an ansible-core supporting
# both the playbook and $target_python, or nothing if there is none.
pick_venv_python() {
  # ansible-core 2.20+ (controller py3.12+) dropped py3.8 targets, and
  # requirements.txt floors ansible-lint to core 2.20+ on py3.12+.
  local max_minor=99
  "$target_python" -c 'import sys; sys.exit(sys.version_info < (3, 9))' || max_minor=11
  local candidate minor
  for candidate in $(compgen -c python3. | grep -xE 'python3\.[0-9]+' | sort -u -t. -k2,2nr); do
    minor="${candidate#python3.}"
    if (( minor >= 9 && minor <= max_minor )); then
      echo "$candidate"
      return
    fi
  done
}

if [[ ! -d venv ]]; then
  venv_python="$(pick_venv_python)"
  if [[ -z "$venv_python" ]]; then
    echo "error: no python3.N on PATH can run ansible-core >= 2.14 against $target_python" >&2
    exit 1
  fi
  "$venv_python" -m venv venv
  # shellcheck source=/dev/null
  source venv/bin/activate
  pip install -r requirements.txt
else
  # shellcheck source=/dev/null
  source venv/bin/activate
fi

# ansible.builtin.systemd_service needs ansible-core 2.14+, which needs Python 3.9+.
if ! python - <<'EOF'
import sys
from ansible.release import __version__
from packaging.version import Version
if sys.version_info < (3, 9) or Version(__version__) < Version("2.14"):
    sys.exit(f"error: venv has Python {sys.version.split()[0]} / ansible-core {__version__}; "
             "the playbook needs Python >= 3.9 and ansible-core >= 2.14")
EOF
then
  echo "Remove $PWD/venv and rerun to rebuild it." >&2
  exit 1
fi

# --- Interactive prompts ----------------------------------------------------
prompt_yes_no() {
  # prompt_yes_no "Question?" [Y|N]    (default arg is the default answer)
  local question="$1"
  local default="${2:-N}"
  local hint reply
  if [[ "$default" == "Y" ]]; then hint="[Y/n]"; else hint="[y/N]"; fi
  read -r -p "$question $hint " reply
  if [[ -z "$reply" ]]; then
    [[ "$default" == "Y" ]]
  else
    [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
  fi
}

# Prints "ssh_local", "ssh_remote", or nothing (neither) based on the reply.
prompt_long_lived_host_role() {
  local question="$1"
  local reply
  read -r -p "$question [l/r/N] " reply
  case "$reply" in
    [Ll]|[Ll][Oo][Cc][Aa][Ll]) echo ssh_local ;;
    [Rr]|[Rr][Ee][Mm][Oo][Tt][Ee]) echo ssh_remote ;;
  esac
}

# Defaults applied in both interactive and --no-prompt modes. Edit these to
# change what happens when a user just presses Enter / runs --no-prompt.
default_install_rust=Y
default_install_nvm=Y
default_starship_force=Y
default_toolchain_force=N
default_long_lived_host_role=

# Resolved answers — start at defaults, then prompts may override.
install_rust="$default_install_rust"
install_nvm="$default_install_nvm"
starship_force="$default_starship_force"
toolchain_force="$default_toolchain_force"
long_lived_host_role="$default_long_lived_host_role"

if [[ "$no_prompt" != "true" ]]; then
  echo
  echo "Configure optional installs (press Enter to accept defaults):"
  prompt_yes_no "  Install rust toolchain (rustup, pinned to default version)?" "$default_install_rust" \
    && install_rust=Y || install_rust=N
  prompt_yes_no "  Install nvm (Node Version Manager)?" "$default_install_nvm" \
    && install_nvm=Y || install_nvm=N
  prompt_yes_no "  Install (or force-reinstall e.g. to upgrade) starship?" "$default_starship_force" \
    && starship_force=Y || starship_force=N
  prompt_yes_no "  Force-reinstall toolchains (rust/nvm if already present)?" "$default_toolchain_force" \
    && toolchain_force=Y || toolchain_force=N
  long_lived_host_role="$(prompt_long_lived_host_role "  long-lived host role: is this system local (you sit at it) or remote (you SSH into it)?")"
  echo
fi

extra_vars=()
[[ "$install_rust"    == "Y" ]] && extra_vars+=("-e" "install_rust=true")
[[ "$install_nvm"     == "Y" ]] && extra_vars+=("-e" "install_nvm=true")
[[ "$starship_force"  == "Y" ]] && extra_vars+=("-e" "starship_run_first_time_setup=true")
[[ "$toolchain_force" == "Y" ]] && extra_vars+=("-e" "toolchain_run_first_time_setup=true")
[[ -n "$long_lived_host_role" ]] && extra_vars+=("-e" "long_lived_host_role=$long_lived_host_role")
true   # ensure success exit-status before the playbook invocation

# --- Run --------------------------------------------------------------------
# --ask-become-pass: dotfiles_facts writes to /etc/ansible/facts.d/ which
# requires sudo. Skip with `-e ansible_become_pass=...` (after `--`) if you
# have NOPASSWD sudo configured.
ansible-playbook first_time_setup.yml \
  --connection=local --inventory 127.0.0.1, --limit 127.0.0.1 \
  --ask-become-pass \
  -e ansible_python_interpreter="$target_python" \
  "${extra_vars[@]+"${extra_vars[@]}"}" \
  "${forward_args[@]+"${forward_args[@]}"}"
